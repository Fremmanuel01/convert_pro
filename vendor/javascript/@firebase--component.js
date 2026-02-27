// @firebase/component@0.7.0 downloaded from https://ga.jspm.io/npm:@firebase/component@0.7.0/dist/esm/index.esm.js

import{Deferred as t}from"@firebase/util";class Component{
/**
     *
     * @param name The public service name, e.g. app, auth, firestore, database
     * @param instanceFactory Service factory responsible for creating the public interface
     * @param type whether the service provided by the component is public or private
     */
constructor(t,e,n){this.name=t;this.instanceFactory=e;this.type=n;this.multipleInstances=false;this.serviceProps={};this.instantiationMode="LAZY";this.onInstanceCreated=null}setInstantiationMode(t){this.instantiationMode=t;return this}setMultipleInstances(t){this.multipleInstances=t;return this}setServiceProps(t){this.serviceProps=t;return this}setInstanceCreatedCallback(t){this.onInstanceCreated=t;return this}}
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
 */const e="[DEFAULT]";
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
 */class Provider{constructor(t,e){this.name=t;this.container=e;this.component=null;this.instances=new Map;this.instancesDeferred=new Map;this.instancesOptions=new Map;this.onInitCallbacks=new Map}
/**
     * @param identifier A provider can provide multiple instances of a service
     * if this.component.multipleInstances is true.
     */get(e){const n=this.normalizeInstanceIdentifier(e);if(!this.instancesDeferred.has(n)){const e=new t;this.instancesDeferred.set(n,e);if(this.isInitialized(n)||this.shouldAutoInitialize())try{const t=this.getOrInitializeService({instanceIdentifier:n});t&&e.resolve(t)}catch(t){}}return this.instancesDeferred.get(n).promise}getImmediate(t){const e=this.normalizeInstanceIdentifier(t?.identifier);const n=t?.optional??false;if(!this.isInitialized(e)&&!this.shouldAutoInitialize()){if(n)return null;throw Error(`Service ${this.name} is not available`)}try{return this.getOrInitializeService({instanceIdentifier:e})}catch(t){if(n)return null;throw t}}getComponent(){return this.component}setComponent(t){if(t.name!==this.name)throw Error(`Mismatching Component ${t.name} for Provider ${this.name}.`);if(this.component)throw Error(`Component for ${this.name} has already been provided`);this.component=t;if(this.shouldAutoInitialize()){if(i(t))try{this.getOrInitializeService({instanceIdentifier:e})}catch(t){}for(const[t,e]of this.instancesDeferred.entries()){const n=this.normalizeInstanceIdentifier(t);try{const t=this.getOrInitializeService({instanceIdentifier:n});e.resolve(t)}catch(t){}}}}clearInstance(t=e){this.instancesDeferred.delete(t);this.instancesOptions.delete(t);this.instances.delete(t)}async delete(){const t=Array.from(this.instances.values());await Promise.all([...t.filter((t=>"INTERNAL"in t)).map((t=>t.INTERNAL.delete())),...t.filter((t=>"_delete"in t)).map((t=>t._delete()))])}isComponentSet(){return this.component!=null}isInitialized(t=e){return this.instances.has(t)}getOptions(t=e){return this.instancesOptions.get(t)||{}}initialize(t={}){const{options:e={}}=t;const n=this.normalizeInstanceIdentifier(t.instanceIdentifier);if(this.isInitialized(n))throw Error(`${this.name}(${n}) has already been initialized`);if(!this.isComponentSet())throw Error(`Component ${this.name} has not been registered yet`);const i=this.getOrInitializeService({instanceIdentifier:n,options:e});for(const[t,e]of this.instancesDeferred.entries()){const s=this.normalizeInstanceIdentifier(t);n===s&&e.resolve(i)}return i}
/**
     *
     * @param callback - a function that will be invoked  after the provider has been initialized by calling provider.initialize().
     * The function is invoked SYNCHRONOUSLY, so it should not execute any longrunning tasks in order to not block the program.
     *
     * @param identifier An optional instance identifier
     * @returns a function to unregister the callback
     */onInit(t,e){const n=this.normalizeInstanceIdentifier(e);const i=this.onInitCallbacks.get(n)??new Set;i.add(t);this.onInitCallbacks.set(n,i);const s=this.instances.get(n);s&&t(s,n);return()=>{i.delete(t)}}
/**
     * Invoke onInit callbacks synchronously
     * @param instance the service instance`
     */invokeOnInitCallbacks(t,e){const n=this.onInitCallbacks.get(e);if(n)for(const i of n)try{i(t,e)}catch{}}getOrInitializeService({instanceIdentifier:t,options:e={}}){let i=this.instances.get(t);if(!i&&this.component){i=this.component.instanceFactory(this.container,{instanceIdentifier:n(t),options:e});this.instances.set(t,i);this.instancesOptions.set(t,e);this.invokeOnInitCallbacks(i,t);if(this.component.onInstanceCreated)try{this.component.onInstanceCreated(this.container,t,i)}catch{}}return i||null}normalizeInstanceIdentifier(t=e){return this.component?this.component.multipleInstances?t:e:t}shouldAutoInitialize(){return!!this.component&&this.component.instantiationMode!=="EXPLICIT"}}function n(t){return t===e?void 0:t}function i(t){return t.instantiationMode==="EAGER"}
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
 */class ComponentContainer{constructor(t){this.name=t;this.providers=new Map}
/**
     *
     * @param component Component being added
     * @param overwrite When a component with the same name has already been registered,
     * if overwrite is true: overwrite the existing component with the new component and create a new
     * provider with the new component. It can be useful in tests where you want to use different mocks
     * for different tests.
     * if overwrite is false: throw an exception
     */addComponent(t){const e=this.getProvider(t.name);if(e.isComponentSet())throw new Error(`Component ${t.name} has already been registered with ${this.name}`);e.setComponent(t)}addOrOverwriteComponent(t){const e=this.getProvider(t.name);e.isComponentSet()&&this.providers.delete(t.name);this.addComponent(t)}getProvider(t){if(this.providers.has(t))return this.providers.get(t);const e=new Provider(t,this);this.providers.set(t,e);return e}getProviders(){return Array.from(this.providers.values())}}export{Component,ComponentContainer,Provider};

