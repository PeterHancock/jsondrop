# Since docco does not produce xhtml, we have to resort to string replacements :-(

SPEC=$1

sed -e 's/<\/head>/<link rel="stylesheet" href="lib\/jasmine.css"\/><script src="lib\/jasmine.js"><\/script><script src="lib\/jasmine-html.js"><\/script><script src="..\/node_modules\/async\/lib\/async.js"><\/script><script src="..\/node_modules\/underscore\/underscore-min.js"><\/script><script src="..\/build\/jsondrop.js"><\/script><script src="lib\/'$SPEC'.js"><\/script><script src="lib\/jasmine-runner.js"><\/script><\/head>/' docs/$SPEC.html > /tmp/_x.html

sed -e 's/<\/body>/<span class="version">FILLED IN AT RUNTIME<\/span><\/body>/' /tmp/_x.html > docs/${SPEC}Runner.html

rm /tmp/_x.html
