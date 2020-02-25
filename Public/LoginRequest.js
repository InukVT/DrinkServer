
function updateName(){
    let loginForm = new FormData()
    loginForm.set("mail", "simon.bjergoe@gmail.com")
    loginForm.set("password", "P455w0rd")
    let xhr= new XMLHttpRequest()
    xhr.open('post','/user/register',true)
    xhr.send(loginForm)
    xhr.onload=function() {
        alert(this.response)
    };
}
