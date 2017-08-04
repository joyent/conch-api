var m = require("mithril");

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
            url: "/login",
            data: {user: Auth.username, password: Auth.password}
        }).then(function(data) {
            console.log("logged in successfully and got ");
            console.log(data);
            m.route.set("/racks");
        }).catch(function(e) {
            console.log("An error fired: ");
            console.log(e);
        });
    },
    logout: function() {
        return m.request({method: "POST", url: "/logout" });
    }
}

module.exports = Auth;
