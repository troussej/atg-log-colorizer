import * as Q from 'q';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

export class Utils {

    private  getConfigPath(): string {
        return path.join(os.homedir(), '.atgcolor.config.json');

    }


    public  readConfigFile(): Q.Promise<any> {
        var deferred: Q.Deferred<any> = Q.defer<any>();

        let filepath = this.getConfigPath();

        fs.readFile(filepath, 'utf8', (error: any, obj: any) =>{
            if (error) {
                console.error(error)
                deferred.resolve({});
            }
            else {
                deferred.resolve(JSON.parse(obj));

            };
        });

        return deferred.promise;
    }
}