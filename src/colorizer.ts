//import { config } from './config'
const readline = require('readline');
import * as chalk from 'chalk';
import * as _ from 'lodash';
import * as parser from './parser/log.lang';
import * as logger from 'winston';
logger.level = process.env.LOG_LEVEL

export class Colorizer {

    contextStack: string[] = [];
    context: string = 'info';

    config: any = {
        patterns: {
            debug: {
                color: chalk.white
            },
            trace: {
                color: chalk.grey
            },
            info: {
                color: chalk.green
            },
            error: {
                color: chalk.red
            },
            special: {
                color: chalk.magenta
            }
        }
    }

    public start(): void {
        var rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            terminal: false
        });

        rl.on('line', this.handleLine.bind(this))

    }

    private handleLine(line) {


        let res = line;
        let parsed:any;

        try {

            parsed = parser.parse(line);
            if (parsed) {
                delete parsed.value
                logger.debug(parsed);
                if (!_.isNil(parsed.level)){
                    this.context = parsed.level;//keep context for lines without level
                }
            }
        } catch (e) {
            logger.debug(e);
            // console.error(e);
        }

        if (this.context) {

            res = this.config.patterns[this.context].color(line);
        }
        //reset
        if (parsed && parsed.unique === true) {
            this.context = 'debug';
        }

        console.log(res);

    }

}