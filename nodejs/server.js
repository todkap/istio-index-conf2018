const http = require('http');
const Etcd = require('node-etcd');
const express = require('express')
const app = express()

const bodyParser = require('body-parser');
app.use(bodyParser.json()); // for parsing application/json

const scheme = "http";
const ipAddress = "etcd-service";
const port = "2379";
// const ipAddress = "192.168.64.42";
// const port = "32012";

const connectionAddress = scheme +"://" + ipAddress +":" + port;
const etcd = new Etcd([connectionAddress] /*, options */);

app.get('/', function (request, response) {
  response.send('Simple test for liveliness of the application!');
});

app.get('/storage', function (request, response) {
	etcd.get("/", { recursive: true }, function(err, res){
		if(!err){
			response.writeHead(200);
			response.write(JSON.stringify(res) ) ;
			response.end();
		}else{
			response.writeHead(500);
			response.write("nodeAppTesting failed("+ ipAddress+") ->"+ JSON.stringify(err) ) ;
			response.end();
		}
	});
});


app.delete('/storage/:key', function (request, response) {
	etcd.del(request.params.key, { recursive: true }, function(err, res){
		if(!err){
			response.writeHead(200);
			response.end();
		}else{
			response.writeHead(500);
			response.write("nodeAppTesting failed("+ ipAddress+") ->"+ JSON.stringify(err) ) ;
			response.end();
		}
	});
});


app.get('/storage/:key', function (request, response) {
	etcd.get(request.params.key, { recursive: true }, function(err, res){
		if(!err){
			response.writeHead(200);
			response.write(JSON.stringify(res) ) ;
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
			response.write("nodeAppTesting created") ;
			response.end();
		}
	});
});


app.use('/web', express.static('web'))

app.listen(9080, function () {
  console.log('Example app listening on port 9080!')
});