#!/usr/bin/env node
require('coffee-script/register');
var through = require('../index.coffee');
process.stdin.pipe(through).pipe(process.stdout);