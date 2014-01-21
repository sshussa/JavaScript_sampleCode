	binder = {
		vars:{
			debug:false,
			debugType:false,
			onlyOneQuickViewTO:false,
			isLoggedIn:false,
			launchHappyHour:false,
			creationLog:[],
			bodyIsClosed:false,
			slPlugin:false
		},
		components:{},
		make:{
			commonEvents:function(elm, events, self, params, bubble){
				var self = self;
				var elm = elm;
				var params = params;
				var bubble = bubble;
				this.event = function(evt){
					if(!evt) evt = event;
					self.top.common.eventBubble(bubble, evt, self, elm, params);
				}
			}
		},
		common:{
			createSLscript:function(){
				if(this.top.vars.slPlugin){
					var slScript = document.createElement('script');
					slScript.async = true;
					slScript.src = ('https:' == window.location.protocol ? 'https://s3.amazonaws.com/' : 'http://') + this.top.vars.slPlugin;
					document.getElementsByTagName('head')[0].appendChild(slScript);
				}
			},
			baseEventCopy:function(evt){
				var ev = {}
				for(var e in evt){
					ev[e] = evt[e]
				}
				return ev
			},
			create:function(name, params, group){
				if(!this.vars) this.vars = {};
				if(!this.vars.children) this.vars.children = {};
				this.group = group;
				this.top.vars.creationLog.push(this.name+":"+name)
				if(location.search.search("binderNoCreate=true") != -1) return false
				this.vars.children[name] = new this.make.main();
				if(!this.vars.children[name].init) this.vars.children[name].init = this.top.common.packageInit;
				this.vars.children[name].init(name, this, this.top, group);
				if(this.vars.children[name].constructor(params)){
					delete this.vars.children[name];
					return false;
				}
				return this.vars.children[name];
			},
			packageInit:function(name, parent, top, group){
				this.name = name;
				this.parent = parent;
				this.top = top;
				this.group = group;
			},
			init:function(name, parent, top){
				this.name = name;
				this.parent = parent;
				this.top = top;
			},
			commonBubble:function(func, self, params){
				if(self.parent.common[func]){
					self.top.common.log(self, "call to common intercepted by parrent, "+self.parent.name+".common."+func, "common");
					return self.parent.common[func](params);
				} else {
					if(self.group && self.group.common[func]){
						self.top.common.log(self, "call to common intercepted by group "+self.group.name+".common."+func, "common");
						return self.group.common[func](params);
					} else {
						self.top.common.log(self, "call to common handled by instance, "+self.name+".common."+func, "common");
						if(self.top.common[func]) self.top.common[func](params)
					}
				}
			},
			functionBubble:function(func, self, params, bubble){
				if(!bubble) bubble = {group:true, parent:true};
				if(bubble.group && self.group && self.group[func]){
					self.top.common.log(self.group, "function intercepted by group, "+self.group.name+"."+func, "function");
					self.group[func](self, params);
					return true;
				} else {
					if(bubble.parent && self.parent && self.parent[func]){
						self.top.common.log(self.parent, "function intercepted by parent. "+self.parent.name+"."+func, "function");
						self.parent(self, params);
						return true;
					}
				}
				self.top.common.log(self, "function handled by instance. function = "+self.name+"."+func, "function");
				return false;
			},
			eventBubble:function(bubble, evt, self, elm, params){
				if(bubble.group && self.group && self.group.events && self.group.events[evt.type]){
					self.top.common.log(self.group, ".events."+evt.type, "event");
					self.group.events[evt.type](elm, evt, self, params);
				} else {
					if(bubble.parent && self.parent && self.parent.events && self.parent.events[evt.type]){
						self.top.common.log(self.parent, ".events."+evt.type, "event");
						self.parent.events[evt.type](elm, evt, self, params);
					} else {
						self.top.common.log(self, ".events."+evt.type, "event");
						self.events[evt.type](elm, evt, self, params);
					}
				}
			},
			addEvents:function(elm, events, self, params, bubble){
				if(!bubble) bubble = {group:true, parent:true};
				var f = new this.top.make.commonEvents(elm, events, self, params, bubble);
				for(var i=0;i<events.length;i++){
					if(elm.attachEvent){
						elm.attachEvent("on"+events[i], f.event);
					} else {
						elm.addEventListener(events[i],f.event,0);
					}
				}
				return f;
			},
			removeEvents:function(elm, events, func){
				if(!elm || !events || !events.length || !func) return
				for(var i =0;i<events.length;i++){
					if(elm.detachEvent){
						elm.detachEvent("on"+events[i], func);
					} else {
						elm.removeEventListener(events[i],func,false);
					}
				}
			},
			log:function(script, log, sType){
				if((this.top.vars.debug || (this.top.vars.debugType && this.top.vars.debugType == sType)) && console){
					var out = script.name;
					var p = script.parent;
					while(p != this.top){
						if(p.vars.children[out]){
							out = p.name+".vars.children."+out;
						} else {
							out = p.name+"."+out
						}
						p = p.parent;
					}
					console.log(this.top.name+"."+out+log);
				}
			}
		},
		extend:function(functions){
			if(this.components){
				if(!functions){
					functions = [];
					for(var e in this.components) functions.push(e);
				}
				if(typeof(functions) == "string") functions = functions.split(",")
				for(var i=0;i<functions.length;i++){
					var f = functions[i];
					if(this.components[f]){
						this[f] = this.components[f];
						delete this.components[f];
						if(!this[f].init) this[f].init = this.top.init;
						this[f].init(f, this.parent, this.top);
						if(!this[f].create) this[f].create = this.top.common.create;
					}
				}
			}
		},
		init:function(name, parent, top){
			this.name = name;
			this.parent = parent;
			if(!top){
				this.top = this;
			} else {
				this.top = top;
			}
			if(this.common){
				if(!this.common.init) this.common.init = this.top.common.init
				this.common.init("common", this, this.top);
			}
			if(!this.extend) this.extend = this.top.extend
			if(this.components) this.extend();
		}
	};

	binder.init("binder", binder)

	binder.components.mysteryMeatNav = {
		vars:{
			innerhtml: [
				"<div class='shaddow'></div>"
			]

		},
		common:{
			overOutClick:function(params){
				params.elm.className = params.elm.className.replace(/\b(mouseover|mouseout|click)\b/gi, '')+" "+params.type;
			}
		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						meatClass:"meatSprite",
						meatBarId:"mysteryMeatNavBar",
						meatMoverId:"mysteryMeatNav",
						targID:"mysteryMeatContainer",
						titles:false,
						totalMeat:4,
						start:0,
						bAllowMouseOver:false,
						bHasClickedState:true,
						bAutoClick:true,
						createMeatBalls:false,
						autoCenter:false,
						swatchId:"swatches",
						swatchEl:"li"
					}
					for(var e in params) this.params[e] = params[e];
					this.elm = document.getElementById(this.params.targID);
					this.divs = [];
					this.eventAry = [];

					if (this.params.createMeatBalls) {
						for(var i=0;i<this.params.totalMeat;i++){
							var div = this.elm.appendChild(document.createElement("div"));
							div.innerHTML = this.parent.vars.innerhtml.join("");
							div.className = this.params.meatClass;
							div.id = this.name + "_" + i;
							if(this.params.titles) div.title = this.params.titles[i];

							this.eventAry[i] = this.top.common.addEvents(div, ["mouseover", "mouseout", "click"], this, {iInt:i});
							this.divs[i] = div;
						}
					} else {
						var targs = document.getElementById(this.params.swatchId).getElementsByTagName(this.params.swatchEl);

						for(i=0; i<targs.length; i++) {
							this.eventAry[i] = this.top.common.addEvents(targs[i], ["mouseover", "mouseout", "click"], this, {iInt:i});
							this.divs[i] = targs[i];
						}
					}

					this.curOnInt = this.params.start;
					if(this.params.bHasClickedState && this.params.bAutoClick ){
						this.curOn = this.divs[this.params.start];
						this.parent.common.overOutClick(
							{
								elm:this.curOn,
								type:"click"
							}
						)
					}
					if (this.params.autoCenter) {
						this.meatBar = document.getElementById(this.params.meatBarId);
						this.meatMover = document.getElementById(this.params.meatMoverId);
						this.meatMover.style.left = (this.meatBar.offsetWidth/2)-(this.meatMover.offsetWidth/2);
						this.meatMover.style.visibility = "inherit";
					}

				}
				this.getDiv= function(params){
					return this.divs[params.iInt];
				}
				this.getEventObject = function(params) {
					var iInt = params.iInt;
					if(iInt < 0) iInt = this.eventAry.length-1;
					if(iInt > this.eventAry.length -1) iInt = 0;
					return this.eventAry[iInt];

				}
				this.events = {
					mouseover:function(elm, evt, me, params){
						if(elm == me.curOn && !me.params.bAllowMouseOver) return
						me.parent.common.overOutClick(
							{
								elm:elm,
								type:evt.type
							}
						)
					},
					mouseout:function(elm, evt, me, params){
						if(elm == me.curOn && !me.params.bAllowMouseOver) return
						var type = evt.type;
						if(elm == me.curOn) type = "click"

						me.parent.common.overOutClick(
							{
								elm:elm,
								type:type
							}
						)
					},
					click:function(elm, evt, me, params){
						if(elm == me.curOn || !me.params.bHasClickedState) return
						if(me.curOn){
							me.parent.common.overOutClick(
								{
									elm:me.curOn,
									type:"mouseout"
								}
							)
						}
						me.curOn = elm;
						me.curOnInt = params.iInt;
						me.parent.common.overOutClick(
							{
								elm:elm,
								type:evt.type
							}
						)
					}
				}
			}
		},
		getDiv:function(sChild, params){
			/*
				returns an individual mysteryMeat element

				sChild	str	name of instance

				params
					iInt	int	integer of the mysteryMeat div you want to get
			*/
			return this.vars.children[sChild].getDiv(params);
		},
		getCurOnInt:function(sChild){
			/*
				returns the integer of the curently highlighted mysteryMeat div

				sChild	str	name of instance

			*/
			return this.vars.children[sChild].curOnInt;
		},
		getEventObject:function(sChild, params){
			/*
				returns the event object for a particular mysteryMeat div

				sChild	str	name of instance

				params
					iInt	int	Integer of the particular mysteryMeat event object

			*/
			return this.vars.children[sChild].getEventObject(params);
		}
	}

	binder.components.simpleXslider = {
		vars:{ },
		common:{
			overOutClick:function(params){
				params.elm.className = params.elm.className.replace(/\b(mouseover|mouseout|click)\b/gi, '')+" "+params.type;
			},
			easeInOutQuad:function(t, b, c, d) {
				t /= d/2;
				if (t < 1) return c/2*t*t + b;
				t--;
				return -c/2 * (t*(t-2) - 1) + b;
			} ,
			metrics:function(oAry){

			}
		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						sliderParent:false,
						uniformItemWidth:true,
						startX:0,
						time:500,
						distanceX:-1,
						cellWidth:false
					}
					for(var e in params) this.params[e] = params[e]
					if(!this.params.sliderParent){
						this.top.common.log(this, "need a slider to slide");
						return true;
					}
					this.canMoveNegative = true;
					this.canMovePositive = false;
					this.slider = this.params.sliderParent.getElementsByTagName("table")[0];
					this.children = []
					if(!this.slider){
						this.slider = this.params.sliderParent.getElementsByTagName("ul")[0]

						var c = this.slider.getElementsByTagName("li")
						for(var i=0;i<c.length;i++){
							if(c[i].parentNode == this.slider) this.children.push(c[i])

						}
						var cellWidth = this.params.cellWidth
						if(!cellWidth) this.children[0].offsetWidth
						this.slider.style.width =  cellWidth * this.children.length+"px"
					} else {
						this.children = this.slider.rows[0].cells
					}
					var rect = this.slider.getBoundingClientRect()
					var vW = this.params.sliderParent.getBoundingClientRect()
					this.x = this.params.startX;
					this.slider.style.left = this.x+"px";
					this.distanceX = this.params.distanceX;
					this.viewWidth = vW.width;
					this.sliderWidth = rect.width //this.slider.offsetWidth //-this.viewWidth;
					//this.slider.style.height = rect.height + "px";
					this.slider.style.position = "absolute"
					
					//this.params.sliderParent.style.height = rect.height+"px"
					this.params.sliderParent.style.width = vW.width+"px"
					
					this.params.sliderParent.style.position = "relative"
					this.curView = {start:1, end:0};
					if(this.sliderWidth < this.viewWidth) this.isAtEnd = true;
					this.bAnimating = false;
					this.TO = 0;
				},

				this.addMouseOverOut = function(){
					var rows = this.slider.rows;
					for(var y=0;r<rows.length;y++){
						var cells = r.rows[y].cells;
						for(var x = 0;x<cells.length;x++){
							this.top.common.addEvents(cells[i], ["mouseover", "mouseout"], this)
						}
					}
				},

				this.findDistance = function(){
					var targs = this.children //this.slider.rows[0].cells;
					var w = this.viewWidth;
					var cw = 0;
					if(this.params.cellWidth) {
						this.baseWidth = this.params.cellWidth
					} else {
						this.baseWidth = targs[0].offsetWidth;
					}
					this.curView.end = Math.ceil(w/this.baseWidth);
					this.distanceX = Math.floor(w/this.baseWidth)*this.baseWidth;
					this.offset = 0
				},
				this.slideBy = function(params){
					if(this.bAnimating) return false;
					if(this.distanceX < 0) this.findDistance();
					this.x = parseInt(this.slider.style.left);
					var dX = this.distanceX * params.x;
					var endX =  this.x + dX;
					this.canMovePositive = this.canMoveNegative = true;
					if(endX >= 0) {
						this.canMovePositive = false;
						dX -= endX;
					}
					if(this.sliderWidth + endX <= this.viewWidth){
						this.canMoveNegative = false;
						if(this.sliderWidth + endX < this.viewWidth) dX += (this.viewWidth - (this.sliderWidth + endX));
					}
					this.finish = {
						x:dX
					}
					this.moveInt = -(dX/this.baseWidth);
					this.curView.start+= this.moveInt;
					this.curView.end += this.moveInt;
					this.bAnimating = true;
					var me = this;
					this.startTime = (new Date()).getTime();
					this.TO = setInterval(
						function(){
							me.animate();
						}, 50
					)
				},
				this.getView = function(){
					var targs = this.children //this.slider.rows[0].cells;
					var arr = {
						start:this.curView.start,
						end:this.curView.end,
						cells:[],
						allcells:targs,
						table:this.slider
					};
					if(arr.start < arr.end){
						for(var i=arr.start-1; i<arr.end; i++){
							arr.cells.push(targs[i]);
						}
					}
					return arr
				},
				this.animate = function(){
					var dTime = ((new Date()).getTime()) - this.startTime;
					if(dTime > this.params.time){
						dTime = this.params.time;
						clearTimeout(this.TO);
						this.bAnimating = false;
					}
					this.slider.style.left = this.x+(this.parent.common.easeInOutQuad(dTime, 0, this.finish.x, this.params.time))+"px";
				},

				this.events = {
					mouseover:function(elm, evt, me, params){
						if(elm != me.curOn){
							me.top.common.commonBubble("overOutClick", me, {elm:elm,type:evt.type});
						}
					},
					mouseout:function(elm, evt, me, params){
						if(elm != me.curOn){
							me.top.common.commonBubble("overOutClick", me, {elm:elm,type:evt.type});
						}
					}
				}
			}
		},
		slideBy:function(sName, params){
			/*
				move the slider by a positive or negative direction along x

				sName string name of the slider instance

				params
					x:	int	a number greater then or less then 0 -x slides left, pos slides right.
			*/
			this.vars.children[sName].slideBy(params);
		},
		getCanMoveNegative:function(sName){
			/*
				returns true/false indicating the ability to move -x

				sName string name of the slider instance
			*/
			return this.vars.children[sName].canMoveNegative;
		},
		getCanMovePositive:function(sName){

			/*
				returns true/false indicating the ability to move +x

				sName string name of the slider instance
			*/

			return this.vars.children[sName].canMovePositive;
		},
		getView:function(sName){

			/*
				start:integer,
				end:integer,
				cells:array of visible cells <td> elements,
				allcells: all cells in row 1,
				table:table
				sName string name of the slider instance
			*/

			return this.vars.children[sName].getView;
		}
	}

	binder.components.arrows = {
		vars:{ },
		common:{
			overOutClick:function(params){
				params.elm.className = params.elm.className.replace(/\b(mouseover|mouseout|click)\b/gi, '')+" "+params.type;
			}
		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						x:0,
						y:0,
						elm:false
					}
					for(var e in params) this.params[e] = params[e]

					this.classLoc = false;
					if(!this.params.elm){
						this.top.common.log(this, "need a button to tie an event to");
						return true;
					}
					var pass = {
						x:this.params.x,
						y:this.params.y
					}
					this.trigger = this.top.common.addEvents(this.params.elm, ["click", "mouseover", "mouseout"], this, pass);
				}
				this.changeMessage = function(params){
					this.params.message = params.message;
				}
				this.events = {
					mouseover:function(elm, evt, me, params){
						params = {
							elm:elm,
							type:evt.type
						}
						me.top.common.commonBubble("overOutClick", me, params);
					},
					mouseout:function(elm, evt, me, params){
						params = {
							elm:elm,
							type:evt.type
						}
						me.top.common.commonBubble("overOutClick", me, params);
					},
					click:function(elm, evt, me, params){

					}
				}
			}
		}
	}

	binder.components.slideout = {
		vars:{},
		common:{},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						selectors:[
							"#wtb",
							"#ig",
							"#vid",
							".js_closeButton"
						]
					}
					for(var e in params) this.params[e] = params[e];
					
					this.curOn = false
					
					this.triggers = []
					
					for(var i=0;i<this.params.selectors.length;i++){
						var targ =  $(this.params.selectors[i])
						for(var j=0;j<targ.length;j++){
							this.triggers.push(
								this.top.common.addEvents(
									targ[j], 
									["click"], 
									this,
									{}
								)
							)
						}
					}
					
				}
				
				this.hide = function(){
					
					if(this.curOn){
						var me = this
						TweenMax.to(this.curOn, .5, {width:0});
						TweenMax.to($("#cat-pro-top-blocker"), .5, {css:{autoAlpha:0}, onComplete:function(){document.getElementById("cat-pro-top-blocker").style.display='none'}});
					}
					this.curOn = false;
				}
				
				
				this.show = function(params){
					this.hide()
					this.curOn = $("."+params.elm.id+"-panel")
					TweenMax.fromTo(this.curOn, .5,{width:0}, {width:700, ease:Power0.easeOut, delay:.5});
					TweenMax.fromTo($(".fadeElement"), .5, {autoAlpha:0}, {autoAlpha:1, delay:1});
					//TweenMax.fromTo($("#cat-pro-top-blocker"), .5, {autoAlpha:50}, {autoAlpha:1, delay:0});
					TweenMax.to($("#cat-pro-top-blocker"), .5, {autoAlpha:.5, delay:1, onStart:function(){document.getElementById("cat-pro-top-blocker").style.display='block'}});
				}
				
				this.events = {
					click:function(elm, evt, me, params){
						if(me.curOn && me.curOn[0].id == elm.id+"-panel") return
						if(elm.className && (elm.className.search("js_closeButton") != -1) ){
							me.hide()
						} else {
							me.show(
								{
									elm:elm
								}
							)
						}
					}
				}
			}
		},
		hide:function(sName){
			/* this will close the current pannel that is open
				sName	sStr	instance of component you want to close
			*/
			var targ = this.vars.children[sName]
			if(targ) targ.hide()
		}
	}
			
			
	/*
	binder.components.colorSwatchNavGroup = {
		vars:{

		},
		common:{

		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						prodInfo:false
					}
					for(var e in params) this.params[e] = params[e];

					this.prodInfo = this.params.prodInfo;
					this.meat = this.top.mysteryMeatNav.create(this.name, {start:this.params.curOn}, this);
					this.reelTarg = $('#image-360-small')
					this.reel = false;
					this.setReel()
					
				}

				this.updateProductData = function(params) {
					var targ = this.prodInfo[params.iInt].html;
					document.getElementById('model').innerHTML = targ.model;
					document.getElementById('price').innerHTML = targ.price;
					document.getElementById('height').innerHTML = targ.dims.height;
					document.getElementById('depth').innerHTML = targ.dims.depth;
					document.getElementById('width').innerHTML = targ.dims.width;
					document.getElementById('wtb').href = targ.wtb;
					document.getElementById('ig').href = targ.ig;
					this.setReel();
					this.curData = targ
					this.reelTarg[0].src = "/assets/amana/images/360/size-test-small-reel.jpeg"
					debugger;
					//document.getElementById('productImage').getElementsByTagName('img')[0].src = targ.largeImage;
				}

				this.setReel = function(){
					if(this.reel) this.reelTarg.unreel()
					this.reel = this.reelTarg.reel({
					  footage:		43,
					  frames:		43,
					  rows:			0,
					  cursor:		'hand',
					  cw:			false,
					  horizontal:	true,
					  loops:		false,
					  frame:		25,
					  opening:		.55,
					  entry:		.75,
					  throwable:	true
					});
					
					var me = this
					this.reelTarg.on(
						'loaded', 
						function(){
							me.realLoaded();
						}
					)
						
				}
				
				this.realLoaded = function(){
				
				}
				
				this.events = {
					click:function(elm, evt, that, params){
						me = that.group;

						me.updateProductData({iInt:params.iInt});
						
						that.events.click(elm, evt, that, params)
					}
				}
			}
		}
	}
*/
	binder.components.view360 = {
		vars:{},
		common:{},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						
						largeTarg:'#image-360-large',
						smallTarg:'#image-360-small',
						zoomButton:"reelZoomInButton",
						smallImg:false,
						bigImg:false
					}
					for(var e in params) this.params[e] = params[e];
					this.reelTarg = $(this.params.smallTarg)
					this.largeReelTarg = $(this.params.largeTarg)
					this.reel = false;
					this.largeReel = false;
					this.setReel({img:this.params.smallImg})
					this.zoomButton = document.getElementById(this.params.zoomButton)
				}

				this.setReel = function(params){
					if(this.reel) this.reelTarg.unreel()
					this.reelTarg[0].src = params.img
					this.reel = this.reelTarg.reel({
					  footage:		43,
					  frames:		43,
					  rows:			0,
					  cursor:		'hand',
					  cw:			false,
					  horizontal:	true,
					  loops:		false,
					  frame:		25,
					  opening:		.55,
					  entry:		.75,
					  throwable:	true
					});
					
					var me = this
					this.reelTarg.on(
						'loaded', 
						function(){
						alert(2)
							//me.realLoaded();
						}
					)
						
				}
				
				this.setLargeReel = function(){
					if(this.largeReel) this.largeReelTarg.unreel()
					this.reel = this.largeReelTarg.reel({
					  footage:		43,
					  frames:		43,
					  rows:			0,
					  cursor:		'hand',
					  cw:			false,
					  horizontal:	true,
					  loops:		false,
					  frame:		25,
					  opening:		.55,
					  entry:		.75,
					  throwable:	true
					});
					
					var me = this
					this.largeReelTarg.on(
						'loaded', 
						function(){
							me.realLargeLoaded();
						}
					)
				
				}
				
				this.realLoaded = function(){
					
				}
				
				this.realLargeLoaded = function(){
					this.zoomButton.style.display = "block"
				}
				
			}
		}
	}
	binder.components.productInfoGroup = {
		vars:{},
		common:{},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						selectors:[
							"#wtb",
							"#ig",
							"#vid",
							".js_closeButton"
						],
						largeTarg:'#image-360-large',
						smallTarg:'#image-360-small',
						zoomButton:"reelZoomInButton",
						zoomOutButton:"reelZoomOutButton",
						prodInfo:false,
						curOn:0,
						videoButton:"vid"
					}
					for(var e in params) this.params[e] = params[e];
					
					
					this.prodInfo = this.params.prodInfo;
					this.curData = this.prodInfo[this.params.curOn].html;
					
					this.videos = []
					for(var i=0;i<this.prodInfo.length;i++){
						this.videos.push(this.prodInfo[i].html.video)
					}
					
					//this.video = this.top.ytVideoPlayer.create(this.name, {playList:this.videos}, this);
					this.meat = this.top.mysteryMeatNav.create(this.name, {start:this.params.curOn}, this);
					
					this.reelTarg = $(this.params.smallTarg)
					this.largeReelTarg = $(this.params.largeTarg)
					this.reel = false;
					this.largeReel = false;
					
					this.zoomButton = document.getElementById(this.params.zoomButton)
					this.zoomOutButton = document.getElementById(this.params.zoomOutButton)
					
					this.top.common.addEvents(this.zoomButton, ["click"], this, {});
					this.top.common.addEvents(this.zoomOutButton, ["click"], this, {});
					
					var me = this
					
					this.reelTarg.bind(
						'frameChange', 
						this.updateFrame = function(e, frame){
							me.curFrame = $(this).data('frame')
						}
					);
					this.largeReelTarg.bind(
						'frameChange', 
						this.updateFrame = function(e, frame){
							me.curFrame = $(this).data('frame')
						}
					);
					this.updateProductData({iInt:this.params.curOn})
					this.setReel()
					
					
					this.slideout = binder.slideout.create(
						this.name+"_sliderout0",
						{
							selectors:this.params.selectors
						},
						this
					);
					
				}
				this.print = function(){
					window.open(this.curData.print, 'product_print', 'height=565,width=615,status=yes,toolbar=no,menubar=no,location=no,directories=no,resizable=no,scrollbars=yes,titlebar=no');
				}
				this.email = function(){
					eval(this.curData.email)
				}
				
				this.updateProductData = function(params) {
					var targ = this.prodInfo[params.iInt].html;
					document.getElementById('model').innerHTML = targ.model;
					document.getElementById('price').innerHTML = targ.price;
					document.getElementById('height').innerHTML = targ.dims.height;
					document.getElementById('depth').innerHTML = targ.dims.depth;
					document.getElementById('width').innerHTML = targ.dims.width;
					document.getElementById('wtb').href = targ.wtb;
					document.getElementById('ig').href = targ.ig;
					this.reelTarg[0].src = targ.base360Dir+targ.model+"-small/"+targ.model+"-360-small-01.jpg" //targ.small360 //"/assets/amana/images/360/size-test-small-reel.jpeg"
					this.setReel();
					this.curData = targ
					var d = "block"
					if(!targ.video) d = "none"
					document.getElementById('vid').style.display = d
					//document.getElementById('productImage').getElementsByTagName('img')[0].src = targ.largeImage;
				}

				this.setReel = function(){
					this.zoomButton.style.display = "none"
					if(this.reel) {
						this.reelTarg.unreel()
					}
					this.reel = this.reelTarg.reel({
					  footage:		44,
					  frames:		44,
					  rows:			0,
					  cursor:		'hand',
					  cw:			false,
					  horizontal:	true,
					  loops:		false,
					  frame:		44,
					  opening:		.55,
					  entry:		.75,
					  throwable:	true,
					  suffix:		"",
					  images:this.curData.base360Dir+this.curData.model+"-small/"+this.curData.model+"-360-small-##.jpg",
					  wheelable:false
					});
					
					var me = this
					this.reelTarg.on(
						'loaded', 
						function(){
							me.realLoaded();
						}
					)
						
				}
				
				this.setLargeReel = function(){
					if(this.largeReel) this.largeReelTarg.unreel()
					this.largeReelTarg = this.largeReelTarg.reel({
					  footage:		43,
					  frames:		43,
					  rows:			0,
					  cursor:		'hand',
					  cw:			false,
					  horizontal:	true,
					  loops:		false,
					  frame:		25,
					  opening:		.55,
					  entry:		.75,
					  throwable:	true,
					  suffix:		"",
					  images:this.curData.base360Dir+this.curData.model+"-large/"+this.curData.model+"-360-large-##.jpg",
					  wheelable:false
					});
					
					var me = this
					this.largeReelTarg.on(
						'loaded', 
						function(){
							me.realLargeLoaded();
						}
					)
				
				}
				
				this.realLoaded = function(){
					this.largeReelTarg[0].src = this.curData.base360Dir+this.curData.model+"-large/"+this.curData.model+"-360-large-01.jpg"  //this.curData.large360
					this.setLargeReel()
				}
				
				this.realLargeLoaded = function(){
					this.zoomButton.style.display = "block"
				}
				
				this.showHide360 = function(params){
					if(this.zoomButton == params.elm){
						document.getElementById("pro-info-nav-wraper").style.display = "none"
						document.getElementById("cat-pro-feat-logos").style.display = "none"
						document.getElementById("image360_small_wrap").style.display = "none"
						//this.reelTarg
						this.largeReelTarg.trigger('frameChange', this.curFrame);
						document.getElementById("image360_large_wrap").style.display = "block"
						
						
						document.getElementById("cat-pro-top-wrapper-content").style.height = "800px"
						
						document.getElementById("cat-pro-top-background").style.height = "850px"
						
						
					} else {
						
						document.getElementById("pro-info-nav-wraper").style.display = "block"
						document.getElementById("cat-pro-feat-logos").style.display = "block"
						document.getElementById("image360_small_wrap").style.display = "block"
						
						//this.reelTarg
						this.reel.trigger('frameChange', this.curFrame);
						document.getElementById("image360_large_wrap").style.display = "none"
						
						
						document.getElementById("cat-pro-top-wrapper-content").style.height = ""
						
						document.getElementById("cat-pro-top-background").style.height = ""
					}
				}
				
				this.events = {
					click:function(elm, evt, that, params){
						
						if(that.group){
							var me = that.group
							if(that != me.video){
								me.video.parent.pauseVideo(me.video.name)
							}
							if(that == me.meat){
								me.slideout.parent.hide(me.slideout.name)
								me.updateProductData({iInt:params.iInt});
							} else {
								if(elm.id == "wtb") {
									//openNamedWindow(me.curData.wtb,800,600,'scrollbars')
									open(me.curData.wtb, "_blank")
									return
								}
							}
							that.events.click(elm, evt, that, params)
						} else {
							var me = that
							me.showHide360({elm:elm})
						}
					}
				
				}
				
				
			}
		},
		print:function(sName){
			if(this.vars.children && this.vars.children[sName]) this.vars.children[sName].print()
		},
		email:function(sName){
			if(this.vars.children && this.vars.children[sName]) this.vars.children[sName].email()
		}
	
	}
	
	binder.components.ytVideoPlayer = {
		vars:{
			bOnlyOne:true,
			curOn:false
		},
		common:{
		
		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						playList:[],
						divID:"videoDiv",
						width:"700",
						height:"394",
						curOn:0
					}
					for(var e in params) this.params[e] = params[e]
					this.curOn = this.params.curOn
					this.curVid = this.params.playList[this.curOn]
					var me = this
					
					this.player = new YT.Player(this.params.divID, {
					  height: this.params.height,
					  width: this.params.width,
					  videoId: this.curVid,
					  events: {
						'onReady': function(params){
							me.onPlayerReady(params)
						},
						'onStateChange':function(params){
							me.onPlayerStateChange(params)
						}
					  }
					});
				}
				this.pauseVideo = function(){
					if(this.player.pauseVideo) this.player.pauseVideo()
				}
				this.onPlayerReady = function(params){
					
				}
				this.onPlayerStateChange = function(params){
					if(params.data == 1) {
						if(this.parent.vars.bOnlyOne){
							for(var e in this.parent.vars.children){
								var targ = this.parent.vars.children[e]
								//if(targ != this) 
								//targ.stopVideo()
								//this.parent.stopVideo(e)
							}
						}
					}
				}
			}
		},
		pauseVideo:function(sName){
			this.vars.children[sName].pauseVideo()
		}
	}
	
	binder.components.group_arrows_simpleXslider = {
		vars:{ },
		common:{
			overOutClick:function(params){
				params.elm.className = params.elm.className.replace(/\b(mouseover|mouseout|click)\b/gi, '')+" "+params.type;
			}
		},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						sliderParent:"miniProductViewPort",
						leftArrow:"mpLeftArrow",
						rightArrow:"mpRightArrow",
						startOpen:0,
						heightBuffer:2,
						cellWidth:false
					}
					for(var e in params) this.params[e] = params[e]

					this.leftArrowElm = document.getElementById(this.params.leftArrow)
					this.rightArrowElm = document.getElementById(this.params.rightArrow)
					this.sliderParent = document.getElementById(this.params.sliderParent)
					//debugger;
					this.sliderParent.style.height = this.sliderParent.scrollHeight+this.params.heightBuffer+"px";
					if($("#" + this.params.sliderParent + " table").width() <= $("#" + this.params.sliderParent).width()) {
						this.rightArrowElm.style.visibility = "hidden";
						this.leftArrowElm.style.visibility = "hidden";
						return;
					}

					this.leftArrow = this.top.arrows.create(
						this.name+"_arrowLeft",
						{
							x:1,
							elm:this.leftArrowElm
						},
						this
					)

					this.rightArrow = this.top.arrows.create(
						this.name+"_arrowRight",
						{
							x:-1,
							elm:this.rightArrowElm
						},
						this
					)

					this.slider = this.top.simpleXslider.create(
						this.name+"_slider",
						{
							sliderParent:this.sliderParent,
							cellWidth:this.params.cellWidth
						},
						this
					)
					this.showHideArrows()
				}
				this.showHideArrows = function(){
					if(this.slider.parent.getCanMovePositive(this.slider.name)){
						this.leftArrowElm.style.visibility = "visible"
					} else {
					   this.leftArrowElm.style.visibility = "hidden"
					}
					if(this.slider.parent.getCanMoveNegative(this.slider.name)){
						this.rightArrowElm.style.visibility = "visible"
					} else{
						this.rightArrowElm.style.visibility = "hidden"
					}

				}
				this.events = {
					click:function(elm, evt, that, params){
						var me = that.group;
						if(that.parent.name == "arrows"){
							me.slider.parent.slideBy(me.slider.name, params);
							me.showHideArrows();
						}
					}
				}
			}
		}
	}

	binder.components.disolveGroup = {
	
		vars:{},
		common:{},
		make:{
			main:function(){
				this.constructor = function(params){
					this.params = {
						arrowLeft:"productGalery_arrowLeft",
						arrowRight:"productGalery_arrowRight",
						elm:false,
						imgAry:[],
						time:500
					}
					for(var e in params) this.params[e] = params[e]
					this.arrowLeft = this.top.arrows.create(
						this.name+"_arrowLeft",
						{
							x:-1,
							elm:document.getElementById(this.params.arrowLeft)
						},
						this
					)
					this.arrowRight = this.top.arrows.create(
						this.name+"_arrowLeft",
						{
							x:1,
							elm:document.getElementById(this.params.arrowRight)
						},
						this
					)
					this.meat = this.top.mysteryMeatNav.create(
						this.name+"_meatNav",
						{
							swatchId:"productGalery_thumbnails",
							swatchEl:"li"
						},
						this
					)
					
					this.disolver = this.top.simpleDisolveSlider.create(
						this.name+"_disolver",
						{
							imgAry:this.params.imgAry,
							time:this.params.time
						}
					)
					
					this.events = {
						click:function(elm, evt, that, params){
							var me = that.group
							var curOn = false
							if(that == me.meat){
								curOn = me.disolver.moveTo({iInt:params.iInt})
								//me.slideout.parent.hide(me.slideout.name)
								//me.updateProductData({iInt:params.iInt});
							} else {
								//curOn = me.disolver.moveBy({iInt:params.x})
								me.meat.parent.getEventObject(me.meat.name, {iInt:me.meat.parent.getCurOnInt(me.meat.name)+params.x}).event({type:"click"})
							}
							
							if(curOn !== false){
								that.events.click(elm, evt, that, params)
							}
						}
					
					}
				}
			}
		}
	}
binder.components.simpleDisolveSlider = {
	vars:{
		useFilters:navigator.userAgent.toLowerCase().search("msie") != -1, //(navigator.userAgent.toLowerCase().search("msie") != -1 && parseInt(navigator.userAgent.split("MSIE").pop()) < 9),
	},
	common:{
		easeInOutQuad:function(t, b, c, d) {
			t /= d/2;
			if (t < 1) return c/2*t*t + b;
			t--;
			return -c/2 * (t*(t-2) - 1) + b;
		}
	},
	make:{
		main:function(){
			this.constructor = function(params){
				this.params = {
					imgTo:"productImageTransition_to",
					imgFrom:"productImageTransition_from",
					time:500,
					imgAry:[],
					curOn:0
				}
				for(var e in params) this.params[e] = params[e]
				this.animationTO = false;
				this.imgTo = document.getElementById(this.params.imgTo);
				this.imgFrom = document.getElementById(this.params.imgFrom);
				this.imgAry = this.params.imgAry;
				this.curOn = this.params.curOn
				this.imgFrom.src = this.imgAry[this.curOn],
				this.time = this.params.time
				if(this.parent.vars.useFilters){
					this.imgTo.style.filter =  "progid:DXImageTransform.Microsoft.Alpha(opacity=0)"
					this.imgFrom.style.filter =  "progid:DXImageTransform.Microsoft.Alpha(opacity=100)"
				}
			}
			this.moveTo = function(params){
				if(this.animationTO || params.iInt >= this.imgAry.length || params.iInt < 0 || params.iInt == this.curOn) return false
				this.curOn = params.iInt
				this.startAnimation()
				return this.curOn
			}
			this.moveBy = function(params){
				if(this.animationTO) return false
				this.curOn += params.iInt
				if(this.curOn < 0) this.curOn = this.imgAry.length-1
				if(this.curOn >= this.imgAry.length) this.curOn = 0
				this.startAnimation()
				return this.curOn
			}
			this.startAnimation = function(){
				this.imgTo.src = this.imgAry[this.curOn]
				var me = this
				this.start = (new Date).getTime()
				this.animationTO = setInterval(
					function(){
						me.animate()
					},50
				)
			}
			this.animate = function(){
				var dTime = (new Date).getTime() - this.start
				if(dTime > this.time){
					dTime = this.time
					clearTimeout(this.animationTO)
					this.animationTO = false
				}
				var o = this.parent.common.easeInOutQuad(dTime, 0, 100, this.time)
				var fo = o/100
				if(this.parent.vars.useFilters){
					this.imgTo.filters.item("DXImageTransform.Microsoft.Alpha").opacity = o
					this.imgFrom.filters.item("DXImageTransform.Microsoft.Alpha").opacity = 100-o
				} else {
					
					this.imgTo.style.opacity = fo
					this.imgFrom.style.opacity = 1-fo
				}
				if(!this.animationTO){
					this.imgFrom.src = this.imgTo.src
					if(this.parent.vars.useFilters){
						this.imgTo.filters.item("DXImageTransform.Microsoft.Alpha").opacity = 0
						this.imgFrom.filters.item("DXImageTransform.Microsoft.Alpha").opacity = 100
					} else {
						this.imgTo.style.opacity = 0
						this.imgFrom.style.opacity = 1
					}
				}
			}
		}
	}
}


	function tableStripe(){ 
		
		var specs = document.getElementById("specifications");
		
		if(specs) {
			var tbody = $("#specifications .spec-table tbody"),
				counter = 0;
			for(i = 0; i < tbody.length; i++) {
				var  curTbody = $(tbody)[i],
					rows = $(curTbody).children();
				for(j = 0; j < rows.length; j++) {
					if(counter % 2 != 0) {
						rows[j].className = "even";
					} else {
						rows[j].className = "odd";
					}
					counter++;
				}
			counter = 0;
			}
		} 
	}
	//window.onload = tableStripe;