var m = require("mithril");
//var localStorage = require("localStorage");


// GET wrapper around m.request()
// function Gt(uri){
//     var gt = {};
//     gt.data = null;
//     gt.loading = false;
//     gt.get = function() { start(); return req('GET', uri).then(set).then(done); };

//     function start(){ gt.loading = true; m.redraw(); }
//     function done(){ gt.loading = false; }
//     function set(data){ gt.data = data; }
//     function config(){ }
//     function req(method, uri, data){
//         return m.request({
//             method: method,
//             url: uri,
//             data: data,
//             withCredentials: true,
//             config: config
//         });
//     };

//     return gt;
// }

var Auth = {
    username: "",
    password: "",

    setUsername: function(value) {
        Auth.username = value;
    },
    setPassword: function(value) {
        Auth.password = value;
    },
    login: function() {
        m.request({
            method: "POST",
            url: "http://10.64.223.75:80/login",
            data: {user: Auth.username, password: Auth.password}
        }).then(function(data) {
            console.log("logged in successfully and got ");
            console.log(data);
            //localStorage.setItem("auth-token", data.token);
            //m.route.set("/racks");
        }).catch(function(error) {
            console.log("An error fired: ");
            console.log(error);
        });
    }
}

var Login = {
    view: function() {
        return m("form", [
            m("input[type=text]", {
                oninput: m.withAttr("value", Auth.setUsername),
                value: Auth.username}),
            m("input[type=password]", {
                oninput: m.withAttr("value", Auth.setPassword),
                value: Auth.password}),
            m("button[type=button]", {
                onclick: Auth.login},
              "Login blah")]);
    }
};



var RackList = require("./views/RackList");
var Layout = require("./views/Layout");

m.route(document.body, "/racks", {
    "/racks": {
        render: function() {
            return m(Layout, m(RackList));
        }
    },
    "/login": Login
});
