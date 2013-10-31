var JsonDrop = require('../jsondrop.js');
var Dropbox = require('dropbox');

function withJsonDrop(callback) {
    var dropbox = new Dropbox.Client({
        key: 'xddkqsy965r8sir',
        secret: 'ud3xw50hm8zgbhm',
        sandbox: true
    });
    var jsonDrop = JsonDrop.forDropbox(dropbox);
    dropbox.authDriver(new Dropbox.AuthDriver.NodeServer(8080));
    dropbox.authenticate(function(err, data) {
        if (err) {
            throw new Error(err);
        }
        return callback(jsonDrop);

    });
}

function failOr(callback) {
    return function(err){
        if(err) {
            throw err;
        }
        return callback.apply(this, Array.prototype.splice.call(arguments, 1));
    }
}

withJsonDrop(function(jsonDrop){
    var root = jsonDrop.get('node-test');
    var scalar = root.child('scalar');
    scalar.set(123, failOr(function(){
        scalar.get(failOr(function(val) {
           console.log('\n\nSuccessful Scalar Test\n    ' + scalar.path + ' = ', val);         
        }));  
    }));
    var object = root.child('object');
    object.set({key: 'value'}, failOr(function(){
        object.get(failOr(function(val) {
           console.log('\n\nSuccessful Object Test\n    ' + object.path + ' = ',  val);         
        }));  
    }));
    var list = root.child('list');
    list.remove(function() {
        list.pushAll('Item 0', 'Item 1', 'Item 2', function(){
            var buf = [];
            list.each(
                function(val, child, index) {
                    buf.push(list.path + '[' + index +']' + ' = ' + child.path + ' = ' + val);         
                },
                failOr(function(){
                    console.log('\n\nSuccessful List Test')
                    console.log('    List ' + list.path)
                    console.log('\n    ' + buf.join('\n    '));
                })
            );
        });
    });

});
