//import { config } from './config'
const readline = require('readline');
import * as chalk from 'chalk';
import * as _ from 'lodash';
import * as parser from './parser/log.lang';
import * as winston from 'winston';
import * as patternConfig from './config.patterns.default';
import * as Q from 'q';

import {Utils} from './utils';

const logger = new (winston.Logger)({
    level: process.env.LOG_LEVEL,
    transports: [
        // colorize the output to the console
        new (winston.transports.Console)({ colorize: true })
    ]
});
const AUTHOR_LINE = chalk.yellow('atg-color ') + chalk.cyan('v'+process.env.npm_package_version) + chalk.yellow(' by ') + chalk.white('Joël TROUSSET ') + chalk.green('- https://github.com/troussej/atg-log-colorizer');



export class Colorizer {

    private utils: Utils;
    contextStack: string[] = [];
    context: string = 'default';


    config: any = {
        
    }

    constructor(){
        this.config.patterns = patternConfig;
        this.utils = new Utils();
    }


    public start(): void {

        this.readConfig().then(()=>{

        console.log('config: %j', this.config);
        this.printAuthorInfo();

        var rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            terminal: false
        });

        rl.on('line', this.handleLine.bind(this))
        })

    }

    private handleLine(line) {

        line = this.cleanup(line);

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
            this.context = 'default';
        }

        console.log(res);

    }

    private cleanup(line: string): string {
        if (line) {
            return line.replace(/\0/g,' ').trim();
        }
        return '';
    }

    private applyColor(msg: string, level: string):string{
        let format = this.config.patterns[level];
        if (!!format && !!chalk[format]) {
            return chalk[format](msg);
        } else {
            return msg;
        }
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
                            return accumulator + subRet

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
        if(_.isNil(ret)){
            ret = '';
        }
        return ret;

    }

    private readConfig(): Q.Promise<any> {
        return this.utils.readConfigFile().then((localConfig:any)=>{
            console.log('localConfig : %j',localConfig)
            if(!_.isNil(localConfig)){
            _.merge(this.config,localConfig)
            }
        })
    }

    private printAuthorInfo():void{
        console.log(AUTHOR_LINE);
    }

}