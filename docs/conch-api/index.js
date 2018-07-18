#!/usr/bin/env node

'use strict';
var fs = require('fs');
var yaml = require('js-yaml');

var converter = require('widdershins');
var shins = require('shins');

var yamlSpec = fs.readFileSync('./openapi-spec.yaml');
var jsonSpec;

try {
    jsonSpec = yaml.safeLoad(yamlSpec);
}
catch(ex) {
    console.error('Failed to parse YAML');
    console.error(ex.message);
    process.exit(1);
}

var convertOptions = { };

converter.convert(jsonSpec, convertOptions, function(err, md){
    var renderOptions = {
        inline: true
    };
    shins.render(md, renderOptions, function(err, html) {
        fs.writeFileSync('./index.html', html ,'utf8');
    });
});
