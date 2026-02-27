// @firebase/logger@0.5.0 downloaded from https://ga.jspm.io/npm:@firebase/logger@0.5.0/dist/esm/index.esm.js

/**
 * @license
 * Copyright 2017 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
const e=[];var r;(function(e){e[e.DEBUG=0]="DEBUG";e[e.VERBOSE=1]="VERBOSE";e[e.INFO=2]="INFO";e[e.WARN=3]="WARN";e[e.ERROR=4]="ERROR";e[e.SILENT=5]="SILENT"})(r||(r={}));const t={debug:r.DEBUG,verbose:r.VERBOSE,info:r.INFO,warn:r.WARN,error:r.ERROR,silent:r.SILENT};const o=r.INFO;const n={[r.DEBUG]:"log",[r.VERBOSE]:"log",[r.INFO]:"info",[r.WARN]:"warn",[r.ERROR]:"error"};const l=(e,r,...t)=>{if(r<e.logLevel)return;const o=(new Date).toISOString();const l=n[r];if(!l)throw new Error(`Attempted to log a message with an invalid logType (value: ${r})`);console[l](`[${o}]  ${e.name}:`,...t)};class Logger{
/**
     * Gives you an instance of a Logger to capture messages according to
     * Firebase's logging scheme.
     *
     * @param name The name that the logs will be associated with
     */
constructor(r){this.name=r;this._logLevel=o;this._logHandler=l;this._userLogHandler=null;e.push(this)}get logLevel(){return this._logLevel}set logLevel(e){if(!(e in r))throw new TypeError(`Invalid value "${e}" assigned to \`logLevel\``);this._logLevel=e}setLogLevel(e){this._logLevel=typeof e==="string"?t[e]:e}get logHandler(){return this._logHandler}set logHandler(e){if(typeof e!=="function")throw new TypeError("Value assigned to `logHandler` must be a function");this._logHandler=e}get userLogHandler(){return this._userLogHandler}set userLogHandler(e){this._userLogHandler=e}debug(...e){this._userLogHandler&&this._userLogHandler(this,r.DEBUG,...e);this._logHandler(this,r.DEBUG,...e)}log(...e){this._userLogHandler&&this._userLogHandler(this,r.VERBOSE,...e);this._logHandler(this,r.VERBOSE,...e)}info(...e){this._userLogHandler&&this._userLogHandler(this,r.INFO,...e);this._logHandler(this,r.INFO,...e)}warn(...e){this._userLogHandler&&this._userLogHandler(this,r.WARN,...e);this._logHandler(this,r.WARN,...e)}error(...e){this._userLogHandler&&this._userLogHandler(this,r.ERROR,...e);this._logHandler(this,r.ERROR,...e)}}function s(r){e.forEach((e=>{e.setLogLevel(r)}))}function i(o,n){for(const l of e){let e=null;n&&n.level&&(e=t[n.level]);l.userLogHandler=o===null?null:(t,n,...l)=>{const s=l.map((e=>{if(e==null)return null;if(typeof e==="string")return e;if(typeof e==="number"||typeof e==="boolean")return e.toString();if(e instanceof Error)return e.message;try{return JSON.stringify(e)}catch(e){return null}})).filter((e=>e)).join(" ");n>=(e??t.logLevel)&&o({level:r[n].toLowerCase(),message:s,args:l,type:t.name})}}}export{r as LogLevel,Logger,s as setLogLevel,i as setUserLogHandler};

