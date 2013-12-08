J S O N D R O P ![Travis CI status](https://api.travis-ci.org/PeterHancock/jsondrop.png)
==============

Object persistence with Dropbox.

Browser setup
---------

     var dropbox = new Dropbox.Client({
       key: 'xddkqsy965r8sir', //Dropbox App key
       sandbox: true
     });
     dropbox.authenticate(function(err, data) {
       if (err) {
         throw new Error(err);
       }
       var jsonDrop = JsonDrop.forDropbox(dropbox);
       // initialize JsonDrop App...
     });
     
See [Quickstart](http://peterhancock.github.io/jsondrop/) for a demo.




