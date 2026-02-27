// @firebase/util@1.13.0 downloaded from https://ga.jspm.io/npm:@firebase/util@1.13.0/dist/index.esm.js

import{g as t}from"../_/ixVQ85Ds.js";
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
 */const e={NODE_CLIENT:false,NODE_ADMIN:false,SDK_VERSION:"${JSCORE_VERSION}"};
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
 */const n=function(t,e){if(!t)throw r(e)};const r=function(t){return new Error("Firebase Database ("+e.SDK_VERSION+") INTERNAL ASSERT FAILED: "+t)};
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
 */const o=function(t){const e=[];let n=0;for(let r=0;r<t.length;r++){let o=t.charCodeAt(r);if(o<128)e[n++]=o;else if(o<2048){e[n++]=o>>6|192;e[n++]=o&63|128}else if((o&64512)===55296&&r+1<t.length&&(t.charCodeAt(r+1)&64512)===56320){o=65536+((o&1023)<<10)+(t.charCodeAt(++r)&1023);e[n++]=o>>18|240;e[n++]=o>>12&63|128;e[n++]=o>>6&63|128;e[n++]=o&63|128}else{e[n++]=o>>12|224;e[n++]=o>>6&63|128;e[n++]=o&63|128}}return e};
/**
 * Turns an array of numbers into the string given by the concatenation of the
 * characters to which the numbers correspond.
 * @param bytes Array of numbers representing characters.
 * @return Stringification of the array.
 */const s=function(t){const e=[];let n=0,r=0;while(n<t.length){const o=t[n++];if(o<128)e[r++]=String.fromCharCode(o);else if(o>191&&o<224){const s=t[n++];e[r++]=String.fromCharCode((o&31)<<6|s&63)}else if(o>239&&o<365){const s=t[n++];const i=t[n++];const c=t[n++];const a=((o&7)<<18|(s&63)<<12|(i&63)<<6|c&63)-65536;e[r++]=String.fromCharCode(55296+(a>>10));e[r++]=String.fromCharCode(56320+(a&1023))}else{const s=t[n++];const i=t[n++];e[r++]=String.fromCharCode((o&15)<<12|(s&63)<<6|i&63)}}return e.join("")};const i={byteToCharMap_:null,charToByteMap_:null,byteToCharMapWebSafe_:null,charToByteMapWebSafe_:null,ENCODED_VALS_BASE:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",get ENCODED_VALS(){return this.ENCODED_VALS_BASE+"+/="},get ENCODED_VALS_WEBSAFE(){return this.ENCODED_VALS_BASE+"-_."},HAS_NATIVE_SUPPORT:typeof atob==="function",
/**
     * Base64-encode an array of bytes.
     *
     * @param input An array of bytes (numbers with
     *     value in [0, 255]) to encode.
     * @param webSafe Boolean indicating we should use the
     *     alternative alphabet.
     * @return The base64 encoded string.
     */
encodeByteArray(t,e){if(!Array.isArray(t))throw Error("encodeByteArray takes an array as a parameter");this.init_();const n=e?this.byteToCharMapWebSafe_:this.byteToCharMap_;const r=[];for(let e=0;e<t.length;e+=3){const o=t[e];const s=e+1<t.length;const i=s?t[e+1]:0;const c=e+2<t.length;const a=c?t[e+2]:0;const u=o>>2;const h=(o&3)<<4|i>>4;let f=(i&15)<<2|a>>6;let l=a&63;if(!c){l=64;s||(f=64)}r.push(n[u],n[h],n[f],n[l])}return r.join("")},
/**
     * Base64-encode a string.
     *
     * @param input A string to encode.
     * @param webSafe If true, we should use the
     *     alternative alphabet.
     * @return The base64 encoded string.
     */
encodeString(t,e){return this.HAS_NATIVE_SUPPORT&&!e?btoa(t):this.encodeByteArray(o(t),e)},
/**
     * Base64-decode a string.
     *
     * @param input to decode.
     * @param webSafe True if we should use the
     *     alternative alphabet.
     * @return string representing the decoded value.
     */
decodeString(t,e){return this.HAS_NATIVE_SUPPORT&&!e?atob(t):s(this.decodeStringToByteArray(t,e))},
/**
     * Base64-decode a string.
     *
     * In base-64 decoding, groups of four characters are converted into three
     * bytes.  If the encoder did not apply padding, the input length may not
     * be a multiple of 4.
     *
     * In this case, the last group will have fewer than 4 characters, and
     * padding will be inferred.  If the group has one or two characters, it decodes
     * to one byte.  If the group has three characters, it decodes to two bytes.
     *
     * @param input Input to decode.
     * @param webSafe True if we should use the web-safe alphabet.
     * @return bytes representing the decoded value.
     */
decodeStringToByteArray(t,e){this.init_();const n=e?this.charToByteMapWebSafe_:this.charToByteMap_;const r=[];for(let e=0;e<t.length;){const o=n[t.charAt(e++)];const s=e<t.length;const i=s?n[t.charAt(e)]:0;++e;const c=e<t.length;const a=c?n[t.charAt(e)]:64;++e;const u=e<t.length;const h=u?n[t.charAt(e)]:64;++e;if(o==null||i==null||a==null||h==null)throw new DecodeBase64StringError;const f=o<<2|i>>4;r.push(f);if(a!==64){const t=i<<4&240|a>>2;r.push(t);if(h!==64){const t=a<<6&192|h;r.push(t)}}}return r},init_(){if(!this.byteToCharMap_){this.byteToCharMap_={};this.charToByteMap_={};this.byteToCharMapWebSafe_={};this.charToByteMapWebSafe_={};for(let t=0;t<this.ENCODED_VALS.length;t++){this.byteToCharMap_[t]=this.ENCODED_VALS.charAt(t);this.charToByteMap_[this.byteToCharMap_[t]]=t;this.byteToCharMapWebSafe_[t]=this.ENCODED_VALS_WEBSAFE.charAt(t);this.charToByteMapWebSafe_[this.byteToCharMapWebSafe_[t]]=t;if(t>=this.ENCODED_VALS_BASE.length){this.charToByteMap_[this.ENCODED_VALS_WEBSAFE.charAt(t)]=t;this.charToByteMapWebSafe_[this.ENCODED_VALS.charAt(t)]=t}}}}};class DecodeBase64StringError extends Error{constructor(){super(...arguments);this.name="DecodeBase64StringError"}}const c=function(t){const e=o(t);return i.encodeByteArray(e,true)};const a=function(t){return c(t).replace(/\./g,"")};
/**
 * URL-safe base64 decoding
 *
 * NOTE: DO NOT use the global atob() function - it does NOT support the
 * base64Url variant encoding.
 *
 * @param str To be decoded
 * @return Decoded result, if possible
 */const u=function(t){try{return i.decodeString(t,true)}catch(t){console.error("base64Decode failed: ",t)}return null};
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
 */function h(t){return f(void 0,t)}function f(t,e){if(!(e instanceof Object))return e;switch(e.constructor){case Date:const n=e;return new Date(n.getTime());case Object:t===void 0&&(t={});break;case Array:t=[];break;default:return e}for(const n in e)e.hasOwnProperty(n)&&l(n)&&(t[n]=f(t[n],e[n]));return t}function l(t){return t!=="__proto__"}
/**
 * @license
 * Copyright 2022 Google LLC
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
/**
 * Polyfill for `globalThis` object.
 * @returns the `globalThis` object for the given environment.
 * @public
 */function d(){if(typeof self!=="undefined")return self;if(typeof window!=="undefined")return window;if(typeof global!=="undefined")return global;throw new Error("Unable to locate global object.")}
/**
 * @license
 * Copyright 2022 Google LLC
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
 */const p=()=>d().__FIREBASE_DEFAULTS__;const b=()=>{if(typeof process==="undefined"||typeof process.env==="undefined")return;const t=process.env.__FIREBASE_DEFAULTS__;return t?JSON.parse(t):void 0};const _=()=>{if(typeof document==="undefined")return;let t;try{t=document.cookie.match(/__FIREBASE_DEFAULTS__=([^;]+)/)}catch(t){return}const e=t&&u(t[1]);return e&&JSON.parse(e)};const y=()=>{try{return t()||p()||b()||_()}catch(t){console.info(`Unable to get __FIREBASE_DEFAULTS__ due to: ${t}`);return}};
/**
 * Returns emulator host stored in the __FIREBASE_DEFAULTS__ object
 * for the given product.
 * @returns a URL host formatted like `127.0.0.1:9999` or `[::1]:4000` if available
 * @public
 */const g=t=>y()?.emulatorHosts?.[t]
/**
 * Returns emulator hostname and port stored in the __FIREBASE_DEFAULTS__ object
 * for the given product.
 * @returns a pair of hostname and port like `["::1", 4000]` if available
 * @public
 */;const m=t=>{const e=g(t);if(!e)return;const n=e.lastIndexOf(":");if(n<=0||n+1===e.length)throw new Error(`Invalid host ${e} with no separate hostname and port!`);const r=parseInt(e.substring(n+1),10);return e[0]==="["?[e.substring(1,n-1),r]:[e.substring(0,n),r]};const E=()=>y()?.config;const C=t=>y()?.[`_${t}`]
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
 */;class Deferred{constructor(){this.reject=()=>{};this.resolve=()=>{};this.promise=new Promise(((t,e)=>{this.resolve=t;this.reject=e}))}wrapCallback(t){return(e,n)=>{e?this.reject(e):this.resolve(n);if(typeof t==="function"){this.promise.catch((()=>{}));t.length===1?t(e):t(e,n)}}}}
/**
 * @license
 * Copyright 2025 Google LLC
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
 */function v(t){try{const e=t.startsWith("http://")||t.startsWith("https://")?new URL(t).hostname:t;return e.endsWith(".cloudworkstations.dev")}catch{return false}}async function S(t){const e=await fetch(t,{credentials:"include"});return e.ok}
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
 */function w(t,e){if(t.uid)throw new Error('The "uid" field is no longer supported by mockUserToken. Please use "sub" instead for Firebase Auth User ID.');const n={alg:"none",type:"JWT"};const r=e||"demo-project";const o=t.iat||0;const s=t.sub||t.user_id;if(!s)throw new Error("mockUserToken must contain 'sub' or 'user_id' field!");const i={iss:`https://securetoken.google.com/${r}`,aud:r,iat:o,exp:o+3600,auth_time:o,sub:s,user_id:s,firebase:{sign_in_provider:"custom",identities:{}},...t};const c="";return[a(JSON.stringify(n)),a(JSON.stringify(i)),c].join(".")}const A={};function O(){const t={prod:[],emulator:[]};for(const e of Object.keys(A))A[e]?t.emulator.push(e):t.prod.push(e);return t}function D(t){let e=document.getElementById(t);let n=false;if(!e){e=document.createElement("div");e.setAttribute("id",t);n=true}return{created:n,element:e}}let T=false;
/**
 * Updates Emulator Banner. Primarily used for Firebase Studio
 * @param name
 * @param isRunningEmulator
 * @public
 */function k(t,e){if(typeof window==="undefined"||typeof document==="undefined"||!v(window.location.host)||A[t]===e||A[t]||T)return;A[t]=e;function n(t){return`__firebase__banner__${t}`}const r="__firebase__banner";const o=O();const s=o.prod.length>0;function i(){const t=document.getElementById(r);t&&t.remove()}function c(t){t.style.display="flex";t.style.background="#7faaf0";t.style.position="fixed";t.style.bottom="5px";t.style.left="5px";t.style.padding=".5em";t.style.borderRadius="5px";t.style.alignItems="center"}function a(t,e){t.setAttribute("width","24");t.setAttribute("id",e);t.setAttribute("height","24");t.setAttribute("viewBox","0 0 24 24");t.setAttribute("fill","none");t.style.marginLeft="-6px"}function u(){const t=document.createElement("span");t.style.cursor="pointer";t.style.marginLeft="16px";t.style.fontSize="24px";t.innerHTML=" &times;";t.onclick=()=>{T=true;i()};return t}function h(t,e){t.setAttribute("id",e);t.innerText="Learn more";t.href="https://firebase.google.com/docs/studio/preview-apps#preview-backend";t.setAttribute("target","__blank");t.style.paddingLeft="5px";t.style.textDecoration="underline"}function f(){const t=D(r);const e=n("text");const o=document.getElementById(e)||document.createElement("span");const i=n("learnmore");const f=document.getElementById(i)||document.createElement("a");const l=n("preprendIcon");const d=document.getElementById(l)||document.createElementNS("http://www.w3.org/2000/svg","svg");if(t.created){const e=t.element;c(e);h(f,i);const n=u();a(d,l);e.append(d,o,f,n);document.body.appendChild(e)}if(s){o.innerText="Preview backend disconnected.";d.innerHTML='<g clip-path="url(#clip0_6013_33858)">\n<path d="M4.8 17.6L12 5.6L19.2 17.6H4.8ZM6.91667 16.4H17.0833L12 7.93333L6.91667 16.4ZM12 15.6C12.1667 15.6 12.3056 15.5444 12.4167 15.4333C12.5389 15.3111 12.6 15.1667 12.6 15C12.6 14.8333 12.5389 14.6944 12.4167 14.5833C12.3056 14.4611 12.1667 14.4 12 14.4C11.8333 14.4 11.6889 14.4611 11.5667 14.5833C11.4556 14.6944 11.4 14.8333 11.4 15C11.4 15.1667 11.4556 15.3111 11.5667 15.4333C11.6889 15.5444 11.8333 15.6 12 15.6ZM11.4 13.6H12.6V10.4H11.4V13.6Z" fill="#212121"/>\n</g>\n<defs>\n<clipPath id="clip0_6013_33858">\n<rect width="24" height="24" fill="white"/>\n</clipPath>\n</defs>'}else{d.innerHTML='<g clip-path="url(#clip0_6083_34804)">\n<path d="M11.4 15.2H12.6V11.2H11.4V15.2ZM12 10C12.1667 10 12.3056 9.94444 12.4167 9.83333C12.5389 9.71111 12.6 9.56667 12.6 9.4C12.6 9.23333 12.5389 9.09444 12.4167 8.98333C12.3056 8.86111 12.1667 8.8 12 8.8C11.8333 8.8 11.6889 8.86111 11.5667 8.98333C11.4556 9.09444 11.4 9.23333 11.4 9.4C11.4 9.56667 11.4556 9.71111 11.5667 9.83333C11.6889 9.94444 11.8333 10 12 10ZM12 18.4C11.1222 18.4 10.2944 18.2333 9.51667 17.9C8.73889 17.5667 8.05556 17.1111 7.46667 16.5333C6.88889 15.9444 6.43333 15.2611 6.1 14.4833C5.76667 13.7056 5.6 12.8778 5.6 12C5.6 11.1111 5.76667 10.2833 6.1 9.51667C6.43333 8.73889 6.88889 8.06111 7.46667 7.48333C8.05556 6.89444 8.73889 6.43333 9.51667 6.1C10.2944 5.76667 11.1222 5.6 12 5.6C12.8889 5.6 13.7167 5.76667 14.4833 6.1C15.2611 6.43333 15.9389 6.89444 16.5167 7.48333C17.1056 8.06111 17.5667 8.73889 17.9 9.51667C18.2333 10.2833 18.4 11.1111 18.4 12C18.4 12.8778 18.2333 13.7056 17.9 14.4833C17.5667 15.2611 17.1056 15.9444 16.5167 16.5333C15.9389 17.1111 15.2611 17.5667 14.4833 17.9C13.7167 18.2333 12.8889 18.4 12 18.4ZM12 17.2C13.4444 17.2 14.6722 16.6944 15.6833 15.6833C16.6944 14.6722 17.2 13.4444 17.2 12C17.2 10.5556 16.6944 9.32778 15.6833 8.31667C14.6722 7.30555 13.4444 6.8 12 6.8C10.5556 6.8 9.32778 7.30555 8.31667 8.31667C7.30556 9.32778 6.8 10.5556 6.8 12C6.8 13.4444 7.30556 14.6722 8.31667 15.6833C9.32778 16.6944 10.5556 17.2 12 17.2Z" fill="#212121"/>\n</g>\n<defs>\n<clipPath id="clip0_6083_34804">\n<rect width="24" height="24" fill="white"/>\n</clipPath>\n</defs>';o.innerText="Preview backend running in this workspace."}o.setAttribute("id",e)}document.readyState==="loading"?window.addEventListener("DOMContentLoaded",f):f()}
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
 */function M(){return typeof navigator!=="undefined"&&typeof navigator.userAgent==="string"?navigator.userAgent:""}function x(){return typeof window!=="undefined"&&!!(window.cordova||window.phonegap||window.PhoneGap)&&/ios|iphone|ipod|ipad|android|blackberry|iemobile/i.test(M())}function N(){const t=y()?.forceEnvironment;if(t==="node")return true;if(t==="browser")return false;try{return Object.prototype.toString.call(global.process)==="[object process]"}catch(t){return false}}function B(){return typeof window!=="undefined"||j()}function j(){return typeof WorkerGlobalScope!=="undefined"&&typeof self!=="undefined"&&self instanceof WorkerGlobalScope}function I(){return typeof navigator!=="undefined"&&navigator.userAgent==="Cloudflare-Workers"}function L(){const t=typeof chrome==="object"?chrome.runtime:typeof browser==="object"?browser.runtime:void 0;return typeof t==="object"&&t.id!==void 0}function P(){return typeof navigator==="object"&&navigator.product==="ReactNative"}function W(){return M().indexOf("Electron/")>=0}function F(){const t=M();return t.indexOf("MSIE ")>=0||t.indexOf("Trident/")>=0}function R(){return M().indexOf("MSAppHost/")>=0}function V(){return e.NODE_CLIENT===true||e.NODE_ADMIN===true}function U(){return!N()&&!!navigator.userAgent&&navigator.userAgent.includes("Safari")&&!navigator.userAgent.includes("Chrome")}function $(){return!N()&&!!navigator.userAgent&&(navigator.userAgent.includes("Safari")||navigator.userAgent.includes("WebKit"))&&!navigator.userAgent.includes("Chrome")}function z(){try{return typeof indexedDB==="object"}catch(t){return false}}function H(){return new Promise(((t,e)=>{try{let n=true;const r="validate-browser-context-for-indexeddb-analytics-module";const o=self.indexedDB.open(r);o.onsuccess=()=>{o.result.close();n||self.indexedDB.deleteDatabase(r);t(true)};o.onupgradeneeded=()=>{n=false};o.onerror=()=>{e(o.error?.message||"")}}catch(t){e(t)}}))}function J(){return!(typeof navigator==="undefined"||!navigator.cookieEnabled)}
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
 */const Z="FirebaseError";class FirebaseError extends Error{constructor(t,e,n){super(e);this.code=t;this.customData=n;this.name=Z;Object.setPrototypeOf(this,FirebaseError.prototype);Error.captureStackTrace&&Error.captureStackTrace(this,ErrorFactory.prototype.create)}}class ErrorFactory{constructor(t,e,n){this.service=t;this.serviceName=e;this.errors=n}create(t,...e){const n=e[0]||{};const r=`${this.service}/${t}`;const o=this.errors[t];const s=o?G(o,n):"Error";const i=`${this.serviceName}: ${s} (${r}).`;const c=new FirebaseError(r,i,n);return c}}function G(t,e){return t.replace(K,((t,n)=>{const r=e[n];return r!=null?String(r):`<${n}?>`}))}const K=/\{\$([^}]+)}/g;
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
/**
 * Evaluates a JSON string into a javascript object.
 *
 * @param {string} str A string containing JSON.
 * @return {*} The javascript object representing the specified JSON.
 */function q(t){return JSON.parse(t)}
/**
 * Returns JSON representing a javascript object.
 * @param {*} data JavaScript object to be stringified.
 * @return {string} The JSON contents of the object.
 */function Q(t){return JSON.stringify(t)}
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
 */const X=function(t){let e={},n={},r={},o="";try{const s=t.split(".");e=q(u(s[0])||"");n=q(u(s[1])||"");o=s[2];r=n.d||{};delete n.d}catch(t){}return{header:e,claims:n,data:r,signature:o}};const Y=function(t){const e=X(t).claims;const n=Math.floor((new Date).getTime()/1e3);let r=0,o=0;if(typeof e==="object"){e.hasOwnProperty("nbf")?r=e.nbf:e.hasOwnProperty("iat")&&(r=e.iat);o=e.hasOwnProperty("exp")?e.exp:r+86400}return!!n&&!!r&&!!o&&n>=r&&n<=o};const tt=function(t){const e=X(t).claims;return typeof e==="object"&&e.hasOwnProperty("iat")?e.iat:null};const et=function(t){const e=X(t),n=e.claims;return!!n&&typeof n==="object"&&n.hasOwnProperty("iat")};const nt=function(t){const e=X(t).claims;return typeof e==="object"&&e.admin===true};
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
 */function rt(t,e){return Object.prototype.hasOwnProperty.call(t,e)}function ot(t,e){return Object.prototype.hasOwnProperty.call(t,e)?t[e]:void 0}function st(t){for(const e in t)if(Object.prototype.hasOwnProperty.call(t,e))return false;return true}function it(t,e,n){const r={};for(const o in t)Object.prototype.hasOwnProperty.call(t,o)&&(r[o]=e.call(n,t[o],o,t));return r}function ct(t,e){if(t===e)return true;const n=Object.keys(t);const r=Object.keys(e);for(const o of n){if(!r.includes(o))return false;const n=t[o];const s=e[o];if(at(n)&&at(s)){if(!ct(n,s))return false}else if(n!==s)return false}for(const t of r)if(!n.includes(t))return false;return true}function at(t){return t!==null&&typeof t==="object"}
/**
 * @license
 * Copyright 2022 Google LLC
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
 */function ut(t,e=2e3){const n=new Deferred;setTimeout((()=>n.reject("timeout!")),e);t.then(n.resolve,n.reject);return n.promise}
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
 */function ht(t){const e=[];for(const[n,r]of Object.entries(t))Array.isArray(r)?r.forEach((t=>{e.push(encodeURIComponent(n)+"="+encodeURIComponent(t))})):e.push(encodeURIComponent(n)+"="+encodeURIComponent(r));return e.length?"&"+e.join("&"):""}function ft(t){const e={};const n=t.replace(/^\?/,"").split("&");n.forEach((t=>{if(t){const[n,r]=t.split("=");e[decodeURIComponent(n)]=decodeURIComponent(r)}}));return e}function lt(t){const e=t.indexOf("?");if(!e)return"";const n=t.indexOf("#",e);return t.substring(e,n>0?n:void 0)}
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
 */class Sha1{constructor(){this.chain_=[];this.buf_=[];this.W_=[];this.pad_=[];this.inbuf_=0;this.total_=0;this.blockSize=64;this.pad_[0]=128;for(let t=1;t<this.blockSize;++t)this.pad_[t]=0;this.reset()}reset(){this.chain_[0]=1732584193;this.chain_[1]=4023233417;this.chain_[2]=2562383102;this.chain_[3]=271733878;this.chain_[4]=3285377520;this.inbuf_=0;this.total_=0}
/**
     * Internal compress helper function.
     * @param buf Block to compress.
     * @param offset Offset of the block in the buffer.
     * @private
     */compress_(t,e){e||(e=0);const n=this.W_;if(typeof t==="string")for(let r=0;r<16;r++){n[r]=t.charCodeAt(e)<<24|t.charCodeAt(e+1)<<16|t.charCodeAt(e+2)<<8|t.charCodeAt(e+3);e+=4}else for(let r=0;r<16;r++){n[r]=t[e]<<24|t[e+1]<<16|t[e+2]<<8|t[e+3];e+=4}for(let t=16;t<80;t++){const e=n[t-3]^n[t-8]^n[t-14]^n[t-16];n[t]=4294967295&(e<<1|e>>>31)}let r=this.chain_[0];let o=this.chain_[1];let s=this.chain_[2];let i=this.chain_[3];let c=this.chain_[4];let a,u;for(let t=0;t<80;t++){if(t<40)if(t<20){a=i^o&(s^i);u=1518500249}else{a=o^s^i;u=1859775393}else if(t<60){a=o&s|i&(o|s);u=2400959708}else{a=o^s^i;u=3395469782}const e=(r<<5|r>>>27)+a+c+u+n[t]&4294967295;c=i;i=s;s=4294967295&(o<<30|o>>>2);o=r;r=e}this.chain_[0]=this.chain_[0]+r&4294967295;this.chain_[1]=this.chain_[1]+o&4294967295;this.chain_[2]=this.chain_[2]+s&4294967295;this.chain_[3]=this.chain_[3]+i&4294967295;this.chain_[4]=this.chain_[4]+c&4294967295}update(t,e){if(t==null)return;e===void 0&&(e=t.length);const n=e-this.blockSize;let r=0;const o=this.buf_;let s=this.inbuf_;while(r<e){if(s===0)while(r<=n){this.compress_(t,r);r+=this.blockSize}if(typeof t==="string")while(r<e){o[s]=t.charCodeAt(r);++s;++r;if(s===this.blockSize){this.compress_(o);s=0;break}}else while(r<e){o[s]=t[r];++s;++r;if(s===this.blockSize){this.compress_(o);s=0;break}}}this.inbuf_=s;this.total_+=e}digest(){const t=[];let e=this.total_*8;this.inbuf_<56?this.update(this.pad_,56-this.inbuf_):this.update(this.pad_,this.blockSize-(this.inbuf_-56));for(let t=this.blockSize-1;t>=56;t--){this.buf_[t]=e&255;e/=256}this.compress_(this.buf_);let n=0;for(let e=0;e<5;e++)for(let r=24;r>=0;r-=8){t[n]=this.chain_[e]>>r&255;++n}return t}}
/**
 * Helper to make a Subscribe function (just like Promise helps make a
 * Thenable).
 *
 * @param executor Function which can make calls to a single Observer
 *     as a proxy.
 * @param onNoObservers Callback when count of Observers goes to zero.
 */function dt(t,e){const n=new ObserverProxy(t,e);return n.subscribe.bind(n)}class ObserverProxy{
/**
     * @param executor Function which can make calls to a single Observer
     *     as a proxy.
     * @param onNoObservers Callback when count of Observers goes to zero.
     */
constructor(t,e){this.observers=[];this.unsubscribes=[];this.observerCount=0;this.task=Promise.resolve();this.finalized=false;this.onNoObservers=e;this.task.then((()=>{t(this)})).catch((t=>{this.error(t)}))}next(t){this.forEachObserver((e=>{e.next(t)}))}error(t){this.forEachObserver((e=>{e.error(t)}));this.close(t)}complete(){this.forEachObserver((t=>{t.complete()}));this.close()}subscribe(t,e,n){let r;if(t===void 0&&e===void 0&&n===void 0)throw new Error("Missing Observer.");r=bt(t,["next","error","complete"])?t:{next:t,error:e,complete:n};r.next===void 0&&(r.next=_t);r.error===void 0&&(r.error=_t);r.complete===void 0&&(r.complete=_t);const o=this.unsubscribeOne.bind(this,this.observers.length);this.finalized&&this.task.then((()=>{try{this.finalError?r.error(this.finalError):r.complete()}catch(t){}}));this.observers.push(r);return o}unsubscribeOne(t){if(this.observers!==void 0&&this.observers[t]!==void 0){delete this.observers[t];this.observerCount-=1;this.observerCount===0&&this.onNoObservers!==void 0&&this.onNoObservers(this)}}forEachObserver(t){if(!this.finalized)for(let e=0;e<this.observers.length;e++)this.sendOne(e,t)}sendOne(t,e){this.task.then((()=>{if(this.observers!==void 0&&this.observers[t]!==void 0)try{e(this.observers[t])}catch(t){typeof console!=="undefined"&&console.error&&console.error(t)}}))}close(t){if(!this.finalized){this.finalized=true;t!==void 0&&(this.finalError=t);this.task.then((()=>{this.observers=void 0;this.onNoObservers=void 0}))}}}function pt(t,e){return(...n)=>{Promise.resolve(true).then((()=>{t(...n)})).catch((t=>{e&&e(t)}))}}function bt(t,e){if(typeof t!=="object"||t===null)return false;for(const n of e)if(n in t&&typeof t[n]==="function")return true;return false}function _t(){}
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
/**
 * Check to make sure the appropriate number of arguments are provided for a public function.
 * Throws an error if it fails.
 *
 * @param fnName The function name
 * @param minCount The minimum number of arguments to allow for the function call
 * @param maxCount The maximum number of argument to allow for the function call
 * @param argCount The actual number of arguments provided.
 */const yt=function(t,e,n,r){let o;r<e?o="at least "+e:r>n&&(o=n===0?"none":"no more than "+n);if(o){const e=t+" failed: Was called with "+r+(r===1?" argument.":" arguments.")+" Expects "+o+".";throw new Error(e)}};
/**
 * Generates a string to prefix an error message about failed argument validation
 *
 * @param fnName The function name
 * @param argName The name of the argument
 * @return The prefix to add to the error thrown for validation.
 */function gt(t,e){return`${t} failed: ${e} argument `}
/**
 * @param fnName
 * @param argumentNumber
 * @param namespace
 * @param optional
 */function mt(t,e,n){if((!n||e)&&typeof e!=="string")throw new Error(gt(t,"namespace")+"must be a valid firebase namespace.")}function Et(t,e,n,r){if((!r||n)&&typeof n!=="function")throw new Error(gt(t,e)+"must be a valid function.")}function Ct(t,e,n,r){if((!r||n)&&(typeof n!=="object"||n===null))throw new Error(gt(t,e)+"must be a valid context object.")}
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
/**
 * @param {string} str
 * @return {Array}
 */const vt=function(t){const e=[];let r=0;for(let o=0;o<t.length;o++){let s=t.charCodeAt(o);if(s>=55296&&s<=56319){const e=s-55296;o++;n(o<t.length,"Surrogate pair missing trail surrogate.");const r=t.charCodeAt(o)-56320;s=65536+(e<<10)+r}if(s<128)e[r++]=s;else if(s<2048){e[r++]=s>>6|192;e[r++]=s&63|128}else if(s<65536){e[r++]=s>>12|224;e[r++]=s>>6&63|128;e[r++]=s&63|128}else{e[r++]=s>>18|240;e[r++]=s>>12&63|128;e[r++]=s>>6&63|128;e[r++]=s&63|128}}return e};
/**
 * Calculate length without actually converting; useful for doing cheaper validation.
 * @param {string} str
 * @return {number}
 */const St=function(t){let e=0;for(let n=0;n<t.length;n++){const r=t.charCodeAt(n);if(r<128)e++;else if(r<2048)e+=2;else if(r>=55296&&r<=56319){e+=4;n++}else e+=3}return e};
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
 */const wt=1e3;const At=2;const Ot=144e5;const Dt=.5;function Tt(t,e=wt,n=At){const r=e*Math.pow(n,t);const o=Math.round(Dt*r*(Math.random()-.5)*2);return Math.min(Ot,r+o)}
/**
 * @license
 * Copyright 2020 Google LLC
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
 */function kt(t){return Number.isFinite(t)?t+Mt(t):`${t}`}function Mt(t){t=Math.abs(t);const e=t%100;if(e>=10&&e<=20)return"th";const n=t%10;return n===1?"st":n===2?"nd":n===3?"rd":"th"}
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
 */function xt(t){return t&&t._delegate?t._delegate:t}export{e as CONSTANTS,DecodeBase64StringError,Deferred,ErrorFactory,FirebaseError,Ot as MAX_VALUE_MILLIS,Dt as RANDOM_FACTOR,Sha1,J as areCookiesEnabled,n as assert,r as assertionError,pt as async,i as base64,u as base64Decode,c as base64Encode,a as base64urlEncodeWithoutPadding,Tt as calculateBackoffMillis,rt as contains,w as createMockUserToken,dt as createSubscribe,X as decode,h as deepCopy,ct as deepEqual,f as deepExtend,gt as errorPrefix,lt as extractQuerystring,E as getDefaultAppConfig,g as getDefaultEmulatorHost,m as getDefaultEmulatorHostnameAndPort,y as getDefaults,C as getExperimentalSetting,d as getGlobal,xt as getModularInstance,M as getUA,nt as isAdmin,B as isBrowser,L as isBrowserExtension,v as isCloudWorkstation,I as isCloudflareWorker,W as isElectron,st as isEmpty,F as isIE,z as isIndexedDBAvailable,x as isMobileCordova,N as isNode,V as isNodeSdk,P as isReactNative,U as isSafari,$ as isSafariOrWebkit,R as isUWP,et as isValidFormat,Y as isValidTimestamp,j as isWebWorker,tt as issuedAtTime,q as jsonEval,it as map,kt as ordinal,S as pingServer,ut as promiseWithTimeout,ht as querystring,ft as querystringDecode,ot as safeGet,St as stringLength,vt as stringToByteArray,Q as stringify,k as updateEmulatorBanner,yt as validateArgCount,Et as validateCallback,Ct as validateContextObject,H as validateIndexedDBOpenable,mt as validateNamespace};

