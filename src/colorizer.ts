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
            },
            keyword: {
                color: chalk.yellow
            },
            component: {
                color: chalk.blue
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
        let parsed: any;

        try {

            parsed = parser.parse(line);
            if (parsed) {
                if (!_.isNil(parsed.level)) {
                    this.context = parsed.level;//keep context for lines without level
                }
                line = this.getValue(parsed);
                //     delete parsed.text //remove lon for easier log
                logger.debug(JSON.stringify(parsed));
            }
        } catch (e) {
            logger.debug(e);
            // console.error(e);
        }

        if (this.context) {

            res = this.applyColor(line, this.context);
        }
        //reset
        if (parsed && parsed.unique === true) {
            this.context = 'debug';
        }

        console.log(res);

    }

    private applyColor(msg: string, level: string) {
        return this.config.patterns[level].color(msg);
    }

    private getValue(parsed: any): string {
        logger.silly('parsed %s', JSON.stringify(parsed));
        let ret = '';
        if (parsed) {

            if (typeof parsed == 'string') {
                ret = parsed;
            } else if (parsed instanceof String) {
                ret = parsed.toString();
            } else if (Array.isArray(parsed)) {
                ret = _.reduce<any, string>(parsed,
                    (accumulator: string, val: any) => {
                        let subRet = this.getValue(val);
                        if (accumulator) {
                            return accumulator + '\t' + subRet

                        } else {
                            return subRet;
                        }
                    },
                    null
                )
            } else {
                ret = this.getValue(parsed.value)
                let level = parsed.level;
                if (level) {
                    ret = this.applyColor(ret, level);
                }
            }
        } else {
            ret = '';
        }
        logger.silly('ret = %s', ret);
        return ret;

    }

}