import os
from flask import Flask, jsonify, request
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv

# Carrega as variáveis do arquivo .env (a chave da API)
load_dotenv()
GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

# --- Configuração do App e Banco de Dados ---
basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False
# Define o banco de dados como um arquivo 'eventflow.db' na mesma pasta
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'eventflow.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# --- Modelos do Banco de Dados (A Estrutura das Tabelas) ---

class Usuario(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False)
    senha = db.Column(db.String(100), nullable=False)
    token = db.Column(db.String(200), unique=True, nullable=False)

class Evento(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    data = db.Column(db.String(50))
    preco = db.Column(db.Float)
    categoria = db.Column(db.String(100))
    miniatura_url = db.Column(db.String(500))
    descricao_longa = db.Column(db.String(1000))
    localizacao_nome = db.Column(db.String(100))

class Local(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    endereco = db.Column(db.String(200))
    bairro = db.Column(db.String(100))
    cidade = db.Column(db.String(100))
    cep = db.Column(db.String(20))
    numero = db.Column(db.String(20))
    latitude = db.Column(db.Float)
    longitude = db.Column(db.Float)

class Categoria(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(100), unique=True, nullable=False)

# --- Funções Auxiliares ---

def get_static_map_url(latitude, longitude):
    if not GOOGLE_MAPS_KEY:
        return "https://via.placeholder.com/500x180.png?text=API_KEY_Faltando"
    return (
        f"https://maps.googleapis.com/maps/api/staticmap"
        f"?center={latitude},{longitude}"
        f"&zoom=15"
        f"&size=500x180"
        f"&markers=color:red%7C{latitude},{longitude}"
        f"&key={GOOGLE_MAPS_KEY}"
    )

def local_to_dict(local):
    return {
        "id": local.id,
        "nome": local.nome,
        "endereco": local.endereco,
        "bairro": local.bairro,
        "cidade": local.cidade,
        "cep": local.cep,
        "numero": local.numero,
        "latitude": local.latitude,
        "longitude": local.longitude
    }

def evento_to_dict(evento):
    return {
        "id": evento.id,
        "nome": evento.nome,
        "data": evento.data,
        "preco": evento.preco,
        "categoria": evento.categoria,
        "miniatura_url": evento.miniatura_url,
        "descricao_longa": evento.descricao_longa,
        "localizacao_nome": evento.localizacao_nome
    }

def categoria_to_dict(categoria):
    return {"id": categoria.id, "nome": categoria.nome}

def usuario_to_dict(usuario):
    return {
        "id": usuario.id,
        "nome": usuario.nome,
        "email": usuario.email,
        "token": usuario.token
    }

# --- Endpoints da API (Agora usam o Banco de Dados) ---

@app.route('/eventos', methods=['GET'])
def get_eventos():
    eventos = Evento.query.all()
    return jsonify([evento_to_dict(e) for e in eventos])

@app.route('/eventos/<int:evento_id>', methods=['GET'])
def get_evento_por_id(evento_id):
    evento = Evento.query.get(evento_id)
    if not evento:
        return jsonify({"erro": "Evento não encontrado"}), 404
    
    # Busca o local para adicionar lat/lng
    local_do_evento = Local.query.filter_by(nome=evento.localizacao_nome).first()
    evento_dict = evento_to_dict(evento)
    
    if local_do_evento:
        evento_dict['latitude'] = local_do_evento.latitude
        evento_dict['longitude'] = local_do_evento.longitude
        evento_dict['endereco'] = local_do_evento.endereco
        evento_dict['bairro'] = local_do_evento.bairro
        evento_dict['cidade'] = local_do_evento.cidade
        
    return jsonify(evento_dict)

@app.route('/eventos', methods=['POST'])
def create_evento():
    dados = request.json
    local_nome = dados.get('local_nome')
    latitude = 0.0
    longitude = 0.0

    local_encontrado = Local.query.filter_by(nome=local_nome).first()
    if local_encontrado:
        latitude = local_encontrado.latitude
        longitude = local_encontrado.longitude
            
    nova_imagem_url = get_static_map_url(latitude, longitude)
    
    novo_evento = Evento(
        nome=dados.get('nome'),
        data=dados.get('data'),
        preco=dados.get('preco'),
        categoria=dados.get('categoria_nome'),
        miniatura_url=nova_imagem_url,
        descricao_longa=dados.get('descricao'),
        localizacao_nome=local_nome
    )
    db.session.add(novo_evento)
    db.session.commit()
    return jsonify(evento_to_dict(novo_evento)), 201

@app.route('/eventos/<int:evento_id>', methods=['PUT'])
def update_evento(evento_id):
    evento = Evento.query.get(evento_id)
    if not evento:
        return jsonify({"erro": "Evento não encontrado"}), 404
        
    dados = request.json
    local_nome = dados.get('local_nome', evento.localizacao_nome)
    latitude = 0.0
    longitude = 0.0
    
    local_encontrado = Local.query.filter_by(nome=local_nome).first()
    if local_encontrado:
        latitude = local_encontrado.latitude
        longitude = local_encontrado.longitude
            
    nova_imagem_url = get_static_map_url(latitude, longitude)
    
    evento.nome = dados.get('nome', evento.nome)
    evento.data = dados.get('data', evento.data)
    evento.preco = dados.get('preco', evento.preco)
    evento.categoria = dados.get('categoria_nome', evento.categoria)
    evento.descricao_longa = dados.get('descricao', evento.descricao_longa)
    evento.localizacao_nome = local_nome
    evento.miniatura_url = nova_imagem_url
    
    db.session.commit()
    return jsonify(evento_to_dict(evento))

@app.route('/locais', methods=['GET'])
def get_locais():
    locais = Local.query.all()
    return jsonify([local_to_dict(l) for l in locais])

@app.route('/locais', methods=['POST'])
def create_local():
    dados = request.json
    novo_local = Local(
        nome=dados.get('nome', 'Nome não fornecido'), 
        endereco=dados.get('endereco'),
        bairro=dados.get('bairro'),
        cidade=dados.get('cidade'),
        cep=dados.get('cep'),
        numero=dados.get('numero'),
        latitude=dados.get('latitude'),
        longitude=dados.get('longitude')
    )
    db.session.add(novo_local)
    db.session.commit()
    return jsonify(local_to_dict(novo_local)), 201

@app.route('/locais/<int:local_id>', methods=['PUT'])
def update_local(local_id):
    local = Local.query.get(local_id)
    if not local:
        return jsonify({"erro": "Local não encontrado"}), 404
    
    dados = request.json
    local.nome = dados.get('nome', local.nome)
    local.endereco = dados.get('endereco', local.endereco)
    local.bairro = dados.get('bairro', local.bairro)
    local.cidade = dados.get('cidade', local.cidade)
    local.cep = dados.get('cep', local.cep)
    local.numero = dados.get('numero', local.numero)
    local.latitude = dados.get('latitude', local.latitude)
    local.longitude = dados.get('longitude', local.longitude)
    
    db.session.commit()
    return jsonify(local_to_dict(local))

@app.route('/locais/<int:local_id>', methods=['DELETE'])
def delete_local(local_id):
    local = Local.query.get(local_id)
    if not local:
        return jsonify({"erro": "Local não encontrado"}), 404
    
    db.session.delete(local)
    db.session.commit()
    return jsonify({"mensagem": "Local deletado com sucesso"}), 200

@app.route('/categorias', methods=['GET'])
def get_categorias():
    categorias = Categoria.query.all()
    return jsonify([categoria_to_dict(c) for c in categorias])

@app.route('/categorias', methods=['POST'])
def create_categoria():
    dados = request.json
    nova_categoria = Categoria(
        nome=dados.get('nome', 'Nome não fornecido')
    )
    db.session.add(nova_categoria)
    db.session.commit()
    return jsonify(categoria_to_dict(nova_categoria)), 201

@app.route('/categorias/<int:categoria_id>', methods=['PUT'])
def update_categoria(categoria_id):
    categoria = Categoria.query.get(categoria_id)
    if not categoria:
        return jsonify({"erro": "Categoria não encontrada"}), 404
    
    dados = request.json
    categoria.nome = dados.get('nome', categoria.nome)
    
    db.session.commit()
    return jsonify(categoria_to_dict(categoria))

@app.route('/categorias/<int:categoria_id>', methods=['DELETE'])
def delete_categoria(categoria_id):
    categoria = Categoria.query.get(categoria_id)
    if not categoria:
        return jsonify({"erro": "Categoria não encontrada"}), 404
    
    db.session.delete(categoria)
    db.session.commit()
    return jsonify({"mensagem": "Categoria deletada com sucesso"}), 200

@app.route('/login', methods=['POST'])
def login():
    dados = request.json
    usuario = Usuario.query.filter_by(email=dados.get('email')).first()
    
    if usuario and usuario.senha == dados.get('senha'):
        return jsonify(usuario_to_dict(usuario))
    else:
        return jsonify({"erro": "Usuário não cadastrado ou senha incorreta"}), 401

@app.route('/perfil', methods=['GET'])
def get_perfil():
    # Simplesmente pega o primeiro usuário. 
    # Em um app real, você usaria o Token de autenticação.
    usuario = Usuario.query.first()
    if usuario:
        return jsonify({
            "id": usuario.id,
            "nome": usuario.nome,
            "email": usuario.email
        })
    else:
        return jsonify({"erro": "Nenhum usuário configurado"}), 404

# --- Função de Setup do Banco de Dados ---
def setup_database(app):
    db_path = os.path.join(basedir, 'eventflow.db')
    if not os.path.exists(db_path):
        print("Criando o banco de dados e populando com dados iniciais...")
        with app.app_context():
            db.create_all()
            
            # Adiciona usuário mock
            if not Usuario.query.first():
                usuario_yara = Usuario(
                    nome="Yara de Oliveira Matos",
                    email="yara@email.com",
                    senha="123",
                    token="fake-jwt-token-for-yara-12345"
                )
                db.session.add(usuario_yara)
            
            # Adiciona categorias mock
            if not Categoria.query.first():
                categorias_iniciais = [
                    Categoria(nome="Palestra"),
                    Categoria(nome="Show"),
                    Categoria(nome="Feira"),
                    Categoria(nome="Conferência"),
                    Categoria(nome="Workshop")
                ]
                db.session.bulk_save_objects(categorias_iniciais)

            # Adiciona locais mock
            if not Local.query.first():
                locais_iniciais = [
                    Local(nome="Centro de Convenções Principal", latitude=-23.550520, longitude=-46.633308, endereco="Avenida Central, 1234", bairro="Centro", cidade="Solaris City"),
                    Local(nome="Arena Music Hall", latitude=-23.561574, longitude=-46.655981, endereco="Rua das Palmeiras, 500", bairro="Aurora", cidade="Solaris City"),
                    Local(nome="Parque da Cidade", latitude=-23.551600, longitude=-46.638000, endereco="Av. do Parque, s/n", bairro="Jardins", cidade="Solaris City")
                ]
                db.session.bulk_save_objects(locais_iniciais)
            
            # Adiciona eventos mock
            if not Evento.query.first():
                eventos_iniciais = [
                    Evento(nome="Lorem ipsum dolor sit amet...", data="10/12/2025", preco=0.00, categoria="Palestra", miniatura_url=get_static_map_url(-23.550520, -46.633308), descricao_longa="Esta é uma palestra incrível...", localizacao_nome="Centro de Convenções Principal"),
                    Evento(nome="Show de Lançamento 'EventFlow'", data="15/11/2025", preco=120.50, categoria="Show", miniatura_url=get_static_map_url(-23.561574, -46.655981), descricao_longa="O show de lançamento oficial...", localizacao_nome="Arena Music Hall"),
                    Evento(nome="Feira de Gastronomia Local", data="20/11/2025", preco=25.00, categoria="Feira", miniatura_url=get_static_map_url(-23.551600, -46.638000), descricao_longa="Prove o melhor da culinária...", localizacao_nome="Parque da Cidade")
                ]
                db.session.bulk_save_objects(eventos_iniciais)
            
            db.session.commit()
            print("Banco de dados criado e populado com sucesso.")

# --- Roda a Aplicação ---
if __name__ == '__main__':
    setup_database(app)
    app.run(debug=True, port=5000)