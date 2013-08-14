/*
WSSH Javascript Client

Usage:

var client = new WSSHClient();

client.connect({
    // Connection and authentication parameters
    username: 'root',
    hostname: 'localhost',
    authentication_method: 'password', // can either be password or private_key
    password: 'secretpassword', // do not provide when using private_key
    key_passphrase: 'secretpassphrase', // *may* be provided if the private_key is encrypted

    // Callbacks
    onError: function(error) {
        // Called upon an error
        console.error(error);
    },
    onConnect: function() {
        // Called after a successful connection to the server
        console.debug('Connected!');

        client.send('ls\n'); // You can send data back to the server by using WSSHClient.send()
    },
    onClose: function() {
        // Called when the remote closes the connection
        console.debug('Connection Reset By Peer');
    },
    onData: function(data) {
        // Called when data is received from the server
        console.debug('Received: ' + data);
    }
});

*/

function WSSHClient(uuid) {
  this.uuid=uuid;
};

WSSHClient.prototype._generateEndpoint = function(options) {
    if (window.location.protocol == 'https:') {
        var protocol = 'wss://';
    } else {
        var protocol = 'ws://';
    }
    var endpoint = protocol + window.location.host +
        '/socket?uuid=' + this.uuid; ///' + encodeURIComponent(options.hostname) + '/' +
        //encodeURIComponent(options.username);
    /*if (options.authentication_method == 'password') {
        endpoint += '?password=' + encodeURIComponent(options.password);
    } else if (options.authentication_method == 'private_key') {
        endpoint += '?private_key=' + encodeURIComponent(options.private_key);
        if (options.key_passphrase !== undefined)
            endpoint += '&key_passphrase=' + encodeURIComponent(
                options.key_passphrase);
    }*/
    return endpoint;
};

WSSHClient.prototype.startSocket = function() {

    var ping;
    var _self = this;
    var connected = true;

    if (window.WebSocket) {
        this._connection = new WebSocket(this.endpoint);
    }
    else if (window.MozWebSocket) {
        this._connection = MozWebSocket(this.endpoint);
    }
    else {
        this.options.onError('WebSocket Not Supported');
        return ;
    }

    this._connection.onopen = function() {
        console.log("connected");
        ping = window.setInterval(function() {
          _self._connection.send('p');
        }, 10000);
        _self.options.onConnect();
    };

    this._connection.onmessage = function (evt) {
        console.log(evt.data);
        var data = JSON.parse(evt.data.toString());
        if (data.error !== undefined) {
            _self.options.onError(data.error);
        } else if (data.close !== undefined) {
          connected = false;
        } else {
            _self.options.onData(data.data);
        }
    };

    this._connection.onclose = function(evt) {
      if (connected) {
        window.clearInterval(ping);
        _self.reconnect();
      } else {
        _self.options.onClose();
      }
    };

};

WSSHClient.prototype.connect = function(options) {

    this.endpoint = this._generateEndpoint(options);
    this.options = options;

    this.startSocket();

};

WSSHClient.prototype.send = function(data) {
    this._connection.send('d' + data);
};

WSSHClient.prototype.start = function(width, height) {
    this._connection.send('s' + width + ',' + height);
};

WSSHClient.prototype.resize = function(width, height) {
    this._connection.send('r' + width + ',' + height);
};

WSSHClient.prototype.reconnect = function() {
    this.startSocket();
};
