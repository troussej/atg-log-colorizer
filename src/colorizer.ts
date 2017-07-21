//import { config } from './config'
const readline = require('readline');
import * as chalk from 'chalk';
import * as _ from 'lodash';
export class Colorizer {

    contextStack: string[] = [];

    config:any = {
        patterns : [
            {
                name:'debug',
                pattern: /debug/,
                color: chalk.white
            },
            {
                name: 'trace',
                pattern: /trace/,
                color: chalk.grey
            },
            {
                name: 'info',
                pattern: /info/,
                color: chalk.green
            },
            {
                name: 'error',
                pattern: /error/,
                color: chalk.red
            }
        ]
    }

    public start(): void {
        var rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            terminal: false
        });

        let self = this;
        rl.on('line', function(line) {
            self.handleLine(line);
        })

    }

    private handleLine(line){

       let pattern =  _.find(this.config.patterns,(p:any)=>{
           return p.pattern.test(line);
        })
       if(pattern){
           console.log(pattern.color(line));
       }else{
           console.log(line)
       }
    }

}