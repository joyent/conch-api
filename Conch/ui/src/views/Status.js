var m = require("mithril");
var t = require("i18n4v");

var Device = require("../models/Device");
var Table  = require("./component/Table");


module.exports = {

    view : function(vnode) {
        return m("h1.text-center", "Status");
    }

}; 
