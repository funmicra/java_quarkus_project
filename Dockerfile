from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/sample', methods=['GET'])
def sample():
    param = request.args.get('param', 'default')
    return jsonify({'param': param})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
