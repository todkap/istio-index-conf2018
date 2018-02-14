const http = require('http');
const Etcd = require('node-etcd');
const express = require('express')
const app = express()

const bodyParser = require('body-parser');
app.use(bodyParser.json()); // for parsing application/json

const scheme = "http";
const ipAddress = "etcd-service";
const port = "2379";
const connectionAddress = scheme +"://" + ipAddress +":" + port;
const etcd = new Etcd([connectionAddress] /*, options */);

app.get('/', function (request, response) {
  response.send('Simple test for liveliness of the application!');
});


app.get('/storage/:key', function (request, response) {
	etcd.get(request.params.key, function(err, res){
		if(!err){
			response.writeHead(200);
			response.write("nodeAppTesting("+ ipAddress+") ->"+ JSON.stringify(res) ) ;
			response.end();
		}else{
			response.writeHead(500);
			response.write("nodeAppTesting failed("+ ipAddress+") ->"+ JSON.stringify(err) ) ;
			response.end();
		}
	});
});


app.put('/storage', function (request, response) {
	var jsonData = request.body;
	etcd.set(jsonData.key, jsonData.value, function(err, res){
		if(err){
			response.writeHead(500);
			response.write (JSON.stringify(err) );
			response.end();
		}else{
			response.writeHead(201);
			response.write("nodeAppTesting created("+ ipAddress+") ->"+ JSON.stringify(jsonData)  + ":" + JSON.stringify(res)) ;
			response.end();
		}
	});
});

app.listen(9080, function () {
  console.log('Example app listening on port 9080!')
});