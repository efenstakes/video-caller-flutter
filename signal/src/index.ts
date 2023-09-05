import cors from "cors"
import express from "express"
import { createServer } from "http"
import morgan from "morgan"
import { Server } from "socket.io"
import dotenv from 'dotenv'


// load environment variables
dotenv.config()


// store this in redis or an appropriate db
let users: string[] = []



// create server
const app = express()
const httpServer = createServer(app)

// create socket io server
const io = new Server(httpServer, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
})


app.use(cors())
app.use(morgan('combined'))
app.use(express.json())


app.get("/users", (req, res) => {
    
    res.json({
        users,
    })
})



// when user connects the first time,..
// we can authenticate them using
//          socket.handshake.auth
//      we can add a token jwt in { token: "JWT" }
//      and get it using 
//          socket.handshake.auth.token
// we check if valid then call next or
// call next(error) with any error otherwise
// in this case we just get users id, which we call callerId
// no auth is done but this can be added later
io.use((socket, next)=> {
    if( socket.handshake.query?.callerId ) {
        socket['user'] = socket.handshake.query?.callerId
        next()
    } else {
        console.log("No token found")
        next(new Error("No token found"))
    }
})

// listen for socket connections & events
io.on('connection', (socket)=> {
    console.log("new connection on socker server user is ", socket['user'])

    socket.join(socket['user'])

    // notify this user of online users
    io.to(socket['user']).emit("new-users", { users, })
    
    // notify existent users that a new user just joined
    if( !users.includes(socket['user']) ) {
        
        users.map((user)=> {
            
            io.to(user).emit("new-user", { user: socket['user'], })
        })
        users.push(socket['user'])
    }



    // when we get a call to start a call
    socket.on('start-call', ({ to })=> {
        console.log("initiating call request to ", to)

        io.to(to).emit("incoming-call", { from: socket['user'] })
    })

    // when an incoming call is accepted
    socket.on("accept-call", ({ to })=> {
        console.log("call accepted by ", socket['user'], " from ", to)

        io.to(to).emit("call-accepted", { to })
    })
    
    // when an incoming call is denied
    socket.on("deny-call", ({ to })=> {
        console.log("call denied by ", socket['user'], " from ", to)

        io.to(to).emit("call-denied", { to })
    })
    
    // when a party leaves the call
    socket.on("leave-call", ({ to })=> {
        console.log("left call mesg by ", socket['user'], " from ", to)

        io.to(to).emit("left-call", { to })
    })

    // when an incoming call is accepted,..
    // caller sends their webrtc offer
    socket.on("offer", ({ to, offer })=> {
        console.log("offer from ", socket['user'], " to ", to)

        io.to(to).emit("offer", { to, offer })
    })

    // when an offer is received,..
    // receiver sends a webrtc offer-answer
    socket.on("offer-answer", ({ to, answer })=> {
        console.log("offer answer from ", socket['user'], " to ", to)

        io.to(to).emit("offer-answer", { to, answer })
    })
    

    // when an ice candidate is sent
    socket.on("ice-candidate", ({ to, candidate })=> {
        console.log("ice candidate from ", socket['user'], " to ", to)

        io.to(to).emit("ice-candidate", { to, candidate })
    })


    // when a socker disconnects
    socket.on("disconnect", (reason)=> {
        users = users.filter((u)=> u != socket['user'])

        users.map((user)=> {
            
            io.to(user).emit("user-left", { user: socket['user'], })
        })
        console.log("a socker disconnected ", socket['user'])
    })

})



// create index route endpoint
app.get('/', (_req, res) => {
    res.json({
        server: 'Signal #T90',
        running: true,
    })
})


// get server port
const PORT = process.env.PORT || 8088

// start server
httpServer.listen(PORT, ()=> {
    console.log(`listening on port ${PORT}`)
})

