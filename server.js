require('make-promises-safe');
const fastify = require('fastify')({
  logger: true
});

fastify.get('/', async (request, reply)=>{
  reply.send("Matters up and running!")
});

const start = async ()=>{
  await fastify.listen(process.env.PORT || 3000, '0.0.0.0', (err, address)=>{
    if(err){
      fastify.log.error(err);
      process.exit(1);
    }
    fastify.log.info(`Server listening on ${address}, port ${process.env.PORT}}`);
  });
};

start();