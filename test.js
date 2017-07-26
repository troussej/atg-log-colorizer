let chalk = require('chalk')

let s1 = chalk.red('test1');

console.log(s1)

let s2 = 'wrapp ' + s1 + 'end';

s2 = chalk.blue(s2);
console.log(s2)