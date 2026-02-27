// @firebase/app@0.14.8 downloaded from https://ga.jspm.io/npm:@firebase/app@0.14.8/dist/esm/index.esm.js

import{Component as e,ComponentContainer as t}from"@firebase/component";import{Logger as a,setUserLogHandler as r,setLogLevel as n}from"@firebase/logger";import{ErrorFactory as i,base64Decode as s,getDefaultAppConfig as o,deepEqual as c,isBrowser as h,isWebWorker as l,FirebaseError as p,base64urlEncodeWithoutPadding as f,isIndexedDBAvailable as d,validateIndexedDBOpenable as u}from"@firebase/util";export{FirebaseError}from"@firebase/util";import{openDB as b}from"idb";
/**
 * @license
 * Copyright 2019 Google LLC
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
 */class PlatformLoggerServiceImpl{constructor(e){this.container=e}getPlatformInfoString(){const e=this.container.getProviders();return e.map((e=>{if(m(e)){const t=e.getImmediate();return`${t.library}/${t.version}`}return null})).filter((e=>e)).join(" ")}}
/**
 *
 * @param provider check if this provider provides a VersionService
 *
 * NOTE: Using Provider<'app-version'> is a hack to indicate that the provider
 * provides VersionService. The provider is not necessarily a 'app-version'
 * provider.
 */function m(e){const t=e.getComponent();return t?.type==="VERSION"}const g="@firebase/app";const v="0.14.8";
/**
 * @license
 * Copyright 2019 Google LLC
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
 */const w=new a("@firebase/app");const C="@firebase/app-compat";const _="@firebase/analytics-compat";const D="@firebase/analytics";const y="@firebase/app-check-compat";const S="@firebase/app-check";const I="@firebase/auth";const E="@firebase/auth-compat";const k="@firebase/database";const A="@firebase/data-connect";const F="@firebase/database-compat";const O="@firebase/functions";const $="@firebase/functions-compat";const N="@firebase/installations";const P="@firebase/installations-compat";const x="@firebase/messaging";const R="@firebase/messaging-compat";const T="@firebase/performance";const H="@firebase/performance-compat";const M="@firebase/remote-config";const z="@firebase/remote-config-compat";const B="@firebase/storage";const j="@firebase/storage-compat";const L="@firebase/firestore";const U="@firebase/ai";const J="@firebase/firestore-compat";const V="firebase";const K="12.9.0";
/**
 * @license
 * Copyright 2019 Google LLC
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
 */const Y="[DEFAULT]";const q={[g]:"fire-core",[C]:"fire-core-compat",[D]:"fire-analytics",[_]:"fire-analytics-compat",[S]:"fire-app-check",[y]:"fire-app-check-compat",[I]:"fire-auth",[E]:"fire-auth-compat",[k]:"fire-rtdb",[A]:"fire-data-connect",[F]:"fire-rtdb-compat",[O]:"fire-fn",[$]:"fire-fn-compat",[N]:"fire-iid",[P]:"fire-iid-compat",[x]:"fire-fcm",[R]:"fire-fcm-compat",[T]:"fire-perf",[H]:"fire-perf-compat",[M]:"fire-rc",[z]:"fire-rc-compat",[B]:"fire-gcs",[j]:"fire-gcs-compat",[L]:"fire-fst",[J]:"fire-fst-compat",[U]:"fire-vertex","fire-js":"fire-js",[V]:"fire-js-all"};
/**
 * @license
 * Copyright 2019 Google LLC
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
 */const G=new Map;const Q=new Map;const W=new Map;
/**
 * @param component - the component being added to this app's container
 *
 * @internal
 */function X(e,t){try{e.container.addComponent(t)}catch(a){w.debug(`Component ${t.name} failed to register with FirebaseApp ${e.name}`,a)}}function Z(e,t){e.container.addOrOverwriteComponent(t)}
/**
 *
 * @param component - the component to register
 * @returns whether or not the component is registered successfully
 *
 * @internal
 */function ee(e){const t=e.name;if(W.has(t)){w.debug(`There were multiple attempts to register component ${t}.`);return false}W.set(t,e);for(const t of G.values())X(t,e);for(const t of Q.values())X(t,e);return true}
/**
 *
 * @param app - FirebaseApp instance
 * @param name - service name
 *
 * @returns the provider for the service with the matching name
 *
 * @internal
 */function te(e,t){const a=e.container.getProvider("heartbeat").getImmediate({optional:true});a&&void a.triggerHeartbeat();return e.container.getProvider(t)}
/**
 *
 * @param app - FirebaseApp instance
 * @param name - service name
 * @param instanceIdentifier - service instance identifier in case the service supports multiple instances
 *
 * @internal
 */function ae(e,t,a=Y){te(e,t).clearInstance(a)}
/**
 *
 * @param obj - an object of type FirebaseApp, FirebaseOptions or FirebaseAppSettings.
 *
 * @returns true if the provide object is of type FirebaseApp.
 *
 * @internal
 */function re(e){return e.options!==void 0}
/**
 *
 * @param obj - an object of type FirebaseApp, FirebaseOptions or FirebaseAppSettings.
 *
 * @returns true if the provided object is of type FirebaseServerAppImpl.
 *
 * @internal
 */function ne(e){return!re(e)&&("authIdToken"in e||"appCheckToken"in e||"releaseOnDeref"in e||"automaticDataCollectionEnabled"in e)}
/**
 *
 * @param obj - an object of type FirebaseApp.
 *
 * @returns true if the provided object is of type FirebaseServerAppImpl.
 *
 * @internal
 */function ie(e){return e!==null&&e!==void 0&&e.settings!==void 0}function se(){W.clear()}
/**
 * @license
 * Copyright 2019 Google LLC
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
 */const oe={"no-app":"No Firebase App '{$appName}' has been created - call initializeApp() first","bad-app-name":"Illegal App name: '{$appName}'","duplicate-app":"Firebase App named '{$appName}' already exists with different options or config","app-deleted":"Firebase App named '{$appName}' already deleted","server-app-deleted":"Firebase Server App has been deleted","no-options":"Need to provide options, when not being deployed to hosting via source.","invalid-app-argument":"firebase.{$appName}() takes either no argument or a Firebase App instance.","invalid-log-argument":"First argument to `onLog` must be null or a function.","idb-open":"Error thrown when opening IndexedDB. Original error: {$originalErrorMessage}.","idb-get":"Error thrown when reading from IndexedDB. Original error: {$originalErrorMessage}.","idb-set":"Error thrown when writing to IndexedDB. Original error: {$originalErrorMessage}.","idb-delete":"Error thrown when deleting from IndexedDB. Original error: {$originalErrorMessage}.","finalization-registry-not-supported":"FirebaseServerApp deleteOnDeref field defined but the JS runtime does not support FinalizationRegistry.","invalid-server-app-environment":"FirebaseServerApp is not for use in browser environments."};const ce=new i("app","Firebase",oe);
/**
 * @license
 * Copyright 2019 Google LLC
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
 */class FirebaseAppImpl{constructor(t,a,r){this._isDeleted=false;this._options={...t};this._config={...a};this._name=a.name;this._automaticDataCollectionEnabled=a.automaticDataCollectionEnabled;this._container=r;this.container.addComponent(new e("app",(()=>this),"PUBLIC"))}get automaticDataCollectionEnabled(){this.checkDestroyed();return this._automaticDataCollectionEnabled}set automaticDataCollectionEnabled(e){this.checkDestroyed();this._automaticDataCollectionEnabled=e}get name(){this.checkDestroyed();return this._name}get options(){this.checkDestroyed();return this._options}get config(){this.checkDestroyed();return this._config}get container(){return this._container}get isDeleted(){return this._isDeleted}set isDeleted(e){this._isDeleted=e}checkDestroyed(){if(this.isDeleted)throw ce.create("app-deleted",{appName:this._name})}}
/**
 * @license
 * Copyright 2023 Google LLC
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
 */function he(e,t){const a=s(e.split(".")[1]);if(a===null){console.error(`FirebaseServerApp ${t} is invalid: second part could not be parsed.`);return}const r=JSON.parse(a).exp;if(r===void 0){console.error(`FirebaseServerApp ${t} is invalid: expiration claim could not be parsed`);return}const n=JSON.parse(a).exp*1e3;const i=(new Date).getTime();const o=n-i;o<=0&&console.error(`FirebaseServerApp ${t} is invalid: the token has expired.`)}class FirebaseServerAppImpl extends FirebaseAppImpl{constructor(e,t,a,r){const n=t.automaticDataCollectionEnabled===void 0||t.automaticDataCollectionEnabled;const i={name:a,automaticDataCollectionEnabled:n};if(e.apiKey!==void 0)super(e,i,r);else{const t=e;super(t.options,i,r)}this._serverConfig={automaticDataCollectionEnabled:n,...t};this._serverConfig.authIdToken&&he(this._serverConfig.authIdToken,"authIdToken");this._serverConfig.appCheckToken&&he(this._serverConfig.appCheckToken,"appCheckToken");this._finalizationRegistry=null;typeof FinalizationRegistry!=="undefined"&&(this._finalizationRegistry=new FinalizationRegistry((()=>{this.automaticCleanup()})));this._refCount=0;this.incRefCount(this._serverConfig.releaseOnDeref);this._serverConfig.releaseOnDeref=void 0;t.releaseOnDeref=void 0;me(g,v,"serverapp")}toJSON(){}get refCount(){return this._refCount}incRefCount(e){if(!this.isDeleted){this._refCount++;e!==void 0&&this._finalizationRegistry!==null&&this._finalizationRegistry.register(e,this)}}decRefCount(){return this.isDeleted?0:--this._refCount}automaticCleanup(){void be(this)}get settings(){this.checkDestroyed();return this._serverConfig}checkDestroyed(){if(this.isDeleted)throw ce.create("server-app-deleted")}}
/**
 * @license
 * Copyright 2019 Google LLC
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
 */const le=K;function pe(e,a={}){let r=e;if(typeof a!=="object"){const e=a;a={name:e}}const n={name:Y,automaticDataCollectionEnabled:true,...a};const i=n.name;if(typeof i!=="string"||!i)throw ce.create("bad-app-name",{appName:String(i)});r||(r=o());if(!r)throw ce.create("no-options");const s=G.get(i);if(s){if(c(r,s.options)&&c(n,s.config))return s;throw ce.create("duplicate-app",{appName:i})}const h=new t(i);for(const e of W.values())h.addComponent(e);const l=new FirebaseAppImpl(r,n,h);G.set(i,l);return l}function fe(e,a={}){if(h()&&!l())throw ce.create("invalid-server-app-environment");let r;let n=a||{};e&&(re(e)?r=e.options:ne(e)?n=e:r=e);n.automaticDataCollectionEnabled===void 0&&(n.automaticDataCollectionEnabled=true);r||(r=o());if(!r)throw ce.create("no-options");const i={...n,...r};i.releaseOnDeref!==void 0&&delete i.releaseOnDeref;const s=e=>[...e].reduce(((e,t)=>Math.imul(31,e)+t.charCodeAt(0)|0),0);if(n.releaseOnDeref!==void 0&&typeof FinalizationRegistry==="undefined")throw ce.create("finalization-registry-not-supported",{});const c=""+s(JSON.stringify(i));const p=Q.get(c);if(p){p.incRefCount(n.releaseOnDeref);return p}const f=new t(c);for(const e of W.values())f.addComponent(e);const d=new FirebaseServerAppImpl(r,n,c,f);Q.set(c,d);return d}
/**
 * Retrieves a {@link @firebase/app#FirebaseApp} instance.
 *
 * When called with no arguments, the default app is returned. When an app name
 * is provided, the app corresponding to that name is returned.
 *
 * An exception is thrown if the app being retrieved has not yet been
 * initialized.
 *
 * @example
 * ```javascript
 * // Return the default app
 * const app = getApp();
 * ```
 *
 * @example
 * ```javascript
 * // Return a named app
 * const otherApp = getApp("otherApp");
 * ```
 *
 * @param name - Optional name of the app to return. If no name is
 *   provided, the default is `"[DEFAULT]"`.
 *
 * @returns The app corresponding to the provided app name.
 *   If no app name is provided, the default app is returned.
 *
 * @public
 */function de(e=Y){const t=G.get(e);if(!t&&e===Y&&o())return pe();if(!t)throw ce.create("no-app",{appName:e});return t}function ue(){return Array.from(G.values())}async function be(e){let t=false;const a=e.name;if(G.has(a)){t=true;G.delete(a)}else if(Q.has(a)){const r=e;if(r.decRefCount()<=0){Q.delete(a);t=true}}if(t){await Promise.all(e.container.getProviders().map((e=>e.delete())));e.isDeleted=true}}
/**
 * Registers a library's name and version for platform logging purposes.
 * @param library - Name of 1p or 3p library (e.g. firestore, angularfire)
 * @param version - Current version of that library.
 * @param variant - Bundle variant, e.g., node, rn, etc.
 *
 * @public
 */function me(t,a,r){let n=q[t]??t;r&&(n+=`-${r}`);const i=n.match(/\s|\//);const s=a.match(/\s|\//);if(i||s){const e=[`Unable to register library "${n}" with version "${a}":`];i&&e.push(`library name "${n}" contains illegal characters (whitespace or "/")`);i&&s&&e.push("and");s&&e.push(`version name "${a}" contains illegal characters (whitespace or "/")`);w.warn(e.join(" "))}else ee(new e(`${n}-version`,(()=>({library:n,version:a})),"VERSION"))}
/**
 * Sets log handler for all Firebase SDKs.
 * @param logCallback - An optional custom log handler that executes user code whenever
 * the Firebase SDK makes a logging call.
 *
 * @public
 */function ge(e,t){if(e!==null&&typeof e!=="function")throw ce.create("invalid-log-argument");r(e,t)}function ve(e){n(e)}
/**
 * @license
 * Copyright 2021 Google LLC
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
 */const we="firebase-heartbeat-database";const Ce=1;const _e="firebase-heartbeat-store";let De=null;function ye(){De||(De=b(we,Ce,{upgrade:(e,t)=>{switch(t){case 0:try{e.createObjectStore(_e)}catch(e){console.warn(e)}}}}).catch((e=>{throw ce.create("idb-open",{originalErrorMessage:e.message})})));return De}async function Se(e){try{const t=await ye();const a=t.transaction(_e);const r=await a.objectStore(_e).get(Ee(e));await a.done;return r}catch(e){if(e instanceof p)w.warn(e.message);else{const t=ce.create("idb-get",{originalErrorMessage:e?.message});w.warn(t.message)}}}async function Ie(e,t){try{const a=await ye();const r=a.transaction(_e,"readwrite");const n=r.objectStore(_e);await n.put(t,Ee(e));await r.done}catch(e){if(e instanceof p)w.warn(e.message);else{const t=ce.create("idb-set",{originalErrorMessage:e?.message});w.warn(t.message)}}}function Ee(e){return`${e.name}!${e.options.appId}`}
/**
 * @license
 * Copyright 2021 Google LLC
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
 */const ke=1024;const Ae=30;class HeartbeatServiceImpl{constructor(e){this.container=e;this._heartbeatsCache=null;const t=this.container.getProvider("app").getImmediate();this._storage=new HeartbeatStorageImpl(t);this._heartbeatsCachePromise=this._storage.read().then((e=>{this._heartbeatsCache=e;return e}))}async triggerHeartbeat(){try{const e=this.container.getProvider("platform-logger").getImmediate();const t=e.getPlatformInfoString();const a=Fe();if(this._heartbeatsCache?.heartbeats==null){this._heartbeatsCache=await this._heartbeatsCachePromise;if(this._heartbeatsCache?.heartbeats==null)return}if(this._heartbeatsCache.lastSentHeartbeatDate===a||this._heartbeatsCache.heartbeats.some((e=>e.date===a)))return;this._heartbeatsCache.heartbeats.push({date:a,agent:t});if(this._heartbeatsCache.heartbeats.length>Ae){const e=Ne(this._heartbeatsCache.heartbeats);this._heartbeatsCache.heartbeats.splice(e,1)}return this._storage.overwrite(this._heartbeatsCache)}catch(e){w.warn(e)}}async getHeartbeatsHeader(){try{this._heartbeatsCache===null&&await this._heartbeatsCachePromise;if(this._heartbeatsCache?.heartbeats==null||this._heartbeatsCache.heartbeats.length===0)return"";const e=Fe();const{heartbeatsToSend:t,unsentEntries:a}=Oe(this._heartbeatsCache.heartbeats);const r=f(JSON.stringify({version:2,heartbeats:t}));this._heartbeatsCache.lastSentHeartbeatDate=e;if(a.length>0){this._heartbeatsCache.heartbeats=a;await this._storage.overwrite(this._heartbeatsCache)}else{this._heartbeatsCache.heartbeats=[];void this._storage.overwrite(this._heartbeatsCache)}return r}catch(e){w.warn(e);return""}}}function Fe(){const e=new Date;return e.toISOString().substring(0,10)}function Oe(e,t=ke){const a=[];let r=e.slice();for(const n of e){const e=a.find((e=>e.agent===n.agent));if(e){e.dates.push(n.date);if($e(a)>t){e.dates.pop();break}}else{a.push({agent:n.agent,dates:[n.date]});if($e(a)>t){a.pop();break}}r=r.slice(1)}return{heartbeatsToSend:a,unsentEntries:r}}class HeartbeatStorageImpl{constructor(e){this.app=e;this._canUseIndexedDBPromise=this.runIndexedDBEnvironmentCheck()}async runIndexedDBEnvironmentCheck(){return!!d()&&u().then((()=>true)).catch((()=>false))}async read(){const e=await this._canUseIndexedDBPromise;if(e){const e=await Se(this.app);return e?.heartbeats?e:{heartbeats:[]}}return{heartbeats:[]}}async overwrite(e){const t=await this._canUseIndexedDBPromise;if(t){const t=await this.read();return Ie(this.app,{lastSentHeartbeatDate:e.lastSentHeartbeatDate??t.lastSentHeartbeatDate,heartbeats:e.heartbeats})}}async add(e){const t=await this._canUseIndexedDBPromise;if(t){const t=await this.read();return Ie(this.app,{lastSentHeartbeatDate:e.lastSentHeartbeatDate??t.lastSentHeartbeatDate,heartbeats:[...t.heartbeats,...e.heartbeats]})}}}function $e(e){return f(JSON.stringify({version:2,heartbeats:e})).length}function Ne(e){if(e.length===0)return-1;let t=0;let a=e[0].date;for(let r=1;r<e.length;r++)if(e[r].date<a){a=e[r].date;t=r}return t}
/**
 * @license
 * Copyright 2019 Google LLC
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
 */function Pe(t){ee(new e("platform-logger",(e=>new PlatformLoggerServiceImpl(e)),"PRIVATE"));ee(new e("heartbeat",(e=>new HeartbeatServiceImpl(e)),"PRIVATE"));me(g,v,t);me(g,v,"esm2020");me("fire-js","")}Pe("");export{le as SDK_VERSION,Y as _DEFAULT_ENTRY_NAME,X as _addComponent,Z as _addOrOverwriteComponent,G as _apps,se as _clearComponents,W as _components,te as _getProvider,re as _isFirebaseApp,ie as _isFirebaseServerApp,ne as _isFirebaseServerAppSettings,ee as _registerComponent,ae as _removeServiceInstance,Q as _serverApps,be as deleteApp,de as getApp,ue as getApps,pe as initializeApp,fe as initializeServerApp,ge as onLog,me as registerVersion,ve as setLogLevel};

