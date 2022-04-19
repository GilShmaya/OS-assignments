
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	bec78793          	addi	a5,a5,-1044 # 80005c50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	382080e7          	jalr	898(ra) # 800024ae <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7f4080e7          	jalr	2036(ra) # 800019b8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ee0080e7          	jalr	-288(ra) # 800020b4 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	248080e7          	jalr	584(ra) # 80002458 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	212080e7          	jalr	530(ra) # 80002504 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dfa080e7          	jalr	-518(ra) # 80002240 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	9a0080e7          	jalr	-1632(ra) # 80002240 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	788080e7          	jalr	1928(ra) # 800020b4 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e1e080e7          	jalr	-482(ra) # 8000199c <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dec080e7          	jalr	-532(ra) # 8000199c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	de0080e7          	jalr	-544(ra) # 8000199c <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc8080e7          	jalr	-568(ra) # 8000199c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d88080e7          	jalr	-632(ra) # 8000199c <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d5c080e7          	jalr	-676(ra) # 8000199c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	af6080e7          	jalr	-1290(ra) # 8000198c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ada080e7          	jalr	-1318(ra) # 8000198c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	810080e7          	jalr	-2032(ra) # 800026e4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	db4080e7          	jalr	-588(ra) # 80005c90 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	09e080e7          	jalr	158(ra) # 80001f82 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	990080e7          	jalr	-1648(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	768080e7          	jalr	1896(ra) # 800026bc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00001097          	auipc	ra,0x1
    80000f60:	788080e7          	jalr	1928(ra) # 800026e4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	d16080e7          	jalr	-746(ra) # 80005c7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	d24080e7          	jalr	-732(ra) # 80005c90 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	efe080e7          	jalr	-258(ra) # 80002e72 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	58e080e7          	jalr	1422(ra) # 8000350a <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	538080e7          	jalr	1336(ra) # 800044bc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	e26080e7          	jalr	-474(ra) # 80005db2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	cfc080e7          	jalr	-772(ra) # 80001c90 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00010497          	auipc	s1,0x10
    80001860:	e7448493          	addi	s1,s1,-396 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00016a17          	auipc	s4,0x16
    8000187a:	85aa0a13          	addi	s4,s4,-1958 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
    if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	16848493          	addi	s1,s1,360
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
  }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
      panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018f0:	00007597          	auipc	a1,0x7
    800018f4:	8f058593          	addi	a1,a1,-1808 # 800081e0 <digits+0x1a0>
    800018f8:	00010517          	auipc	a0,0x10
    800018fc:	9a850513          	addi	a0,a0,-1624 # 800112a0 <pid_lock>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	254080e7          	jalr	596(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8e058593          	addi	a1,a1,-1824 # 800081e8 <digits+0x1a8>
    80001910:	00010517          	auipc	a0,0x10
    80001914:	9a850513          	addi	a0,a0,-1624 # 800112b8 <wait_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	23c080e7          	jalr	572(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00010497          	auipc	s1,0x10
    80001924:	db048493          	addi	s1,s1,-592 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001928:	00007b17          	auipc	s6,0x7
    8000192c:	8d0b0b13          	addi	s6,s6,-1840 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001930:	8aa6                	mv	s5,s1
    80001932:	00006a17          	auipc	s4,0x6
    80001936:	6cea0a13          	addi	s4,s4,1742 # 80008000 <etext>
    8000193a:	04000937          	lui	s2,0x4000
    8000193e:	197d                	addi	s2,s2,-1
    80001940:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	00015997          	auipc	s3,0x15
    80001946:	78e98993          	addi	s3,s3,1934 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85da                	mv	a1,s6
    8000194c:	8526                	mv	a0,s1
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	206080e7          	jalr	518(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001956:	415487b3          	sub	a5,s1,s5
    8000195a:	878d                	srai	a5,a5,0x3
    8000195c:	000a3703          	ld	a4,0(s4)
    80001960:	02e787b3          	mul	a5,a5,a4
    80001964:	2785                	addiw	a5,a5,1
    80001966:	00d7979b          	slliw	a5,a5,0xd
    8000196a:	40f907b3          	sub	a5,s2,a5
    8000196e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001970:	16848493          	addi	s1,s1,360
    80001974:	fd349be3          	bne	s1,s3,8000194a <procinit+0x6e>
  }
}
    80001978:	70e2                	ld	ra,56(sp)
    8000197a:	7442                	ld	s0,48(sp)
    8000197c:	74a2                	ld	s1,40(sp)
    8000197e:	7902                	ld	s2,32(sp)
    80001980:	69e2                	ld	s3,24(sp)
    80001982:	6a42                	ld	s4,16(sp)
    80001984:	6aa2                	ld	s5,8(sp)
    80001986:	6b02                	ld	s6,0(sp)
    80001988:	6121                	addi	sp,sp,64
    8000198a:	8082                	ret

000000008000198c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000198c:	1141                	addi	sp,sp,-16
    8000198e:	e422                	sd	s0,8(sp)
    80001990:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001992:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001994:	2501                	sext.w	a0,a0
    80001996:	6422                	ld	s0,8(sp)
    80001998:	0141                	addi	sp,sp,16
    8000199a:	8082                	ret

000000008000199c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
    800019a2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019a4:	2781                	sext.w	a5,a5
    800019a6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a8:	00010517          	auipc	a0,0x10
    800019ac:	92850513          	addi	a0,a0,-1752 # 800112d0 <cpus>
    800019b0:	953e                	add	a0,a0,a5
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b8:	1101                	addi	sp,sp,-32
    800019ba:	ec06                	sd	ra,24(sp)
    800019bc:	e822                	sd	s0,16(sp)
    800019be:	e426                	sd	s1,8(sp)
    800019c0:	1000                	addi	s0,sp,32
  push_off();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1d6080e7          	jalr	470(ra) # 80000b98 <push_off>
    800019ca:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019cc:	2781                	sext.w	a5,a5
    800019ce:	079e                	slli	a5,a5,0x7
    800019d0:	00010717          	auipc	a4,0x10
    800019d4:	8d070713          	addi	a4,a4,-1840 # 800112a0 <pid_lock>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	7b84                	ld	s1,48(a5)
  pop_off();
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	25c080e7          	jalr	604(ra) # 80000c38 <pop_off>
  return p;
}
    800019e4:	8526                	mv	a0,s1
    800019e6:	60e2                	ld	ra,24(sp)
    800019e8:	6442                	ld	s0,16(sp)
    800019ea:	64a2                	ld	s1,8(sp)
    800019ec:	6105                	addi	sp,sp,32
    800019ee:	8082                	ret

00000000800019f0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019f0:	1141                	addi	sp,sp,-16
    800019f2:	e406                	sd	ra,8(sp)
    800019f4:	e022                	sd	s0,0(sp)
    800019f6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	fc0080e7          	jalr	-64(ra) # 800019b8 <myproc>
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	298080e7          	jalr	664(ra) # 80000c98 <release>

  if (first) {
    80001a08:	00007797          	auipc	a5,0x7
    80001a0c:	e387a783          	lw	a5,-456(a5) # 80008840 <first.1689>
    80001a10:	eb89                	bnez	a5,80001a22 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a12:	00001097          	auipc	ra,0x1
    80001a16:	cea080e7          	jalr	-790(ra) # 800026fc <usertrapret>
}
    80001a1a:	60a2                	ld	ra,8(sp)
    80001a1c:	6402                	ld	s0,0(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret
    first = 0;
    80001a22:	00007797          	auipc	a5,0x7
    80001a26:	e007af23          	sw	zero,-482(a5) # 80008840 <first.1689>
    fsinit(ROOTDEV);
    80001a2a:	4505                	li	a0,1
    80001a2c:	00002097          	auipc	ra,0x2
    80001a30:	a5e080e7          	jalr	-1442(ra) # 8000348a <fsinit>
    80001a34:	bff9                	j	80001a12 <forkret+0x22>

0000000080001a36 <allocpid>:
allocpid() {
    80001a36:	1101                	addi	sp,sp,-32
    80001a38:	ec06                	sd	ra,24(sp)
    80001a3a:	e822                	sd	s0,16(sp)
    80001a3c:	e426                	sd	s1,8(sp)
    80001a3e:	e04a                	sd	s2,0(sp)
    80001a40:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a42:	00010917          	auipc	s2,0x10
    80001a46:	85e90913          	addi	s2,s2,-1954 # 800112a0 <pid_lock>
    80001a4a:	854a                	mv	a0,s2
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a54:	00007797          	auipc	a5,0x7
    80001a58:	df078793          	addi	a5,a5,-528 # 80008844 <nextpid>
    80001a5c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a5e:	0014871b          	addiw	a4,s1,1
    80001a62:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a64:	854a                	mv	a0,s2
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
}
    80001a6e:	8526                	mv	a0,s1
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6902                	ld	s2,0(sp)
    80001a78:	6105                	addi	sp,sp,32
    80001a7a:	8082                	ret

0000000080001a7c <proc_pagetable>:
{
    80001a7c:	1101                	addi	sp,sp,-32
    80001a7e:	ec06                	sd	ra,24(sp)
    80001a80:	e822                	sd	s0,16(sp)
    80001a82:	e426                	sd	s1,8(sp)
    80001a84:	e04a                	sd	s2,0(sp)
    80001a86:	1000                	addi	s0,sp,32
    80001a88:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	8b8080e7          	jalr	-1864(ra) # 80001342 <uvmcreate>
    80001a92:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a94:	c121                	beqz	a0,80001ad4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a96:	4729                	li	a4,10
    80001a98:	00005697          	auipc	a3,0x5
    80001a9c:	56868693          	addi	a3,a3,1384 # 80007000 <_trampoline>
    80001aa0:	6605                	lui	a2,0x1
    80001aa2:	040005b7          	lui	a1,0x4000
    80001aa6:	15fd                	addi	a1,a1,-1
    80001aa8:	05b2                	slli	a1,a1,0xc
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	60e080e7          	jalr	1550(ra) # 800010b8 <mappages>
    80001ab2:	02054863          	bltz	a0,80001ae2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab6:	4719                	li	a4,6
    80001ab8:	05893683          	ld	a3,88(s2)
    80001abc:	6605                	lui	a2,0x1
    80001abe:	020005b7          	lui	a1,0x2000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b6                	slli	a1,a1,0xd
    80001ac6:	8526                	mv	a0,s1
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	5f0080e7          	jalr	1520(ra) # 800010b8 <mappages>
    80001ad0:	02054163          	bltz	a0,80001af2 <proc_pagetable+0x76>
}
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	60e2                	ld	ra,24(sp)
    80001ad8:	6442                	ld	s0,16(sp)
    80001ada:	64a2                	ld	s1,8(sp)
    80001adc:	6902                	ld	s2,0(sp)
    80001ade:	6105                	addi	sp,sp,32
    80001ae0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae2:	4581                	li	a1,0
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	00000097          	auipc	ra,0x0
    80001aea:	a58080e7          	jalr	-1448(ra) # 8000153e <uvmfree>
    return 0;
    80001aee:	4481                	li	s1,0
    80001af0:	b7d5                	j	80001ad4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af2:	4681                	li	a3,0
    80001af4:	4605                	li	a2,1
    80001af6:	040005b7          	lui	a1,0x4000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b2                	slli	a1,a1,0xc
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	77e080e7          	jalr	1918(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000153e <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	bf7d                	j	80001ad4 <proc_pagetable+0x58>

0000000080001b18 <proc_freepagetable>:
{
    80001b18:	1101                	addi	sp,sp,-32
    80001b1a:	ec06                	sd	ra,24(sp)
    80001b1c:	e822                	sd	s0,16(sp)
    80001b1e:	e426                	sd	s1,8(sp)
    80001b20:	e04a                	sd	s2,0(sp)
    80001b22:	1000                	addi	s0,sp,32
    80001b24:	84aa                	mv	s1,a0
    80001b26:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	74a080e7          	jalr	1866(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b52:	85ca                	mv	a1,s2
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	9e8080e7          	jalr	-1560(ra) # 8000153e <uvmfree>
}
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret

0000000080001b6a <freeproc>:
{
    80001b6a:	1101                	addi	sp,sp,-32
    80001b6c:	ec06                	sd	ra,24(sp)
    80001b6e:	e822                	sd	s0,16(sp)
    80001b70:	e426                	sd	s1,8(sp)
    80001b72:	1000                	addi	s0,sp,32
    80001b74:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b76:	6d28                	ld	a0,88(a0)
    80001b78:	c509                	beqz	a0,80001b82 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	e7e080e7          	jalr	-386(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b82:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b86:	68a8                	ld	a0,80(s1)
    80001b88:	c511                	beqz	a0,80001b94 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8a:	64ac                	ld	a1,72(s1)
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	f8c080e7          	jalr	-116(ra) # 80001b18 <proc_freepagetable>
  p->pagetable = 0;
    80001b94:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b98:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ba0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ba4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bac:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bb0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bb4:	0004ac23          	sw	zero,24(s1)
}
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <allocproc>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	e04a                	sd	s2,0(sp)
    80001bcc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	00010497          	auipc	s1,0x10
    80001bd2:	b0248493          	addi	s1,s1,-1278 # 800116d0 <proc>
    80001bd6:	00015917          	auipc	s2,0x15
    80001bda:	4fa90913          	addi	s2,s2,1274 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be8:	4c9c                	lw	a5,24(s1)
    80001bea:	cf81                	beqz	a5,80001c02 <allocproc+0x40>
      release(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf6:	16848493          	addi	s1,s1,360
    80001bfa:	ff2492e3          	bne	s1,s2,80001bde <allocproc+0x1c>
  return 0;
    80001bfe:	4481                	li	s1,0
    80001c00:	a889                	j	80001c52 <allocproc+0x90>
  p->pid = allocpid();
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	e34080e7          	jalr	-460(ra) # 80001a36 <allocpid>
    80001c0a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c0c:	4785                	li	a5,1
    80001c0e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	ee4080e7          	jalr	-284(ra) # 80000af4 <kalloc>
    80001c18:	892a                	mv	s2,a0
    80001c1a:	eca8                	sd	a0,88(s1)
    80001c1c:	c131                	beqz	a0,80001c60 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	e5c080e7          	jalr	-420(ra) # 80001a7c <proc_pagetable>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2c:	c531                	beqz	a0,80001c78 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c2e:	07000613          	li	a2,112
    80001c32:	4581                	li	a1,0
    80001c34:	06048513          	addi	a0,s1,96
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0a8080e7          	jalr	168(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c40:	00000797          	auipc	a5,0x0
    80001c44:	db078793          	addi	a5,a5,-592 # 800019f0 <forkret>
    80001c48:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4a:	60bc                	ld	a5,64(s1)
    80001c4c:	6705                	lui	a4,0x1
    80001c4e:	97ba                	add	a5,a5,a4
    80001c50:	f4bc                	sd	a5,104(s1)
}
    80001c52:	8526                	mv	a0,s1
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret
    freeproc(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	f08080e7          	jalr	-248(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	02c080e7          	jalr	44(ra) # 80000c98 <release>
    return 0;
    80001c74:	84ca                	mv	s1,s2
    80001c76:	bff1                	j	80001c52 <allocproc+0x90>
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ef0080e7          	jalr	-272(ra) # 80001b6a <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	014080e7          	jalr	20(ra) # 80000c98 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b7d1                	j	80001c52 <allocproc+0x90>

0000000080001c90 <userinit>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	f28080e7          	jalr	-216(ra) # 80001bc2 <allocproc>
    80001ca2:	84aa                	mv	s1,a0
  initproc = p;
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	38a7b623          	sd	a0,908(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cac:	03400613          	li	a2,52
    80001cb0:	00007597          	auipc	a1,0x7
    80001cb4:	ba058593          	addi	a1,a1,-1120 # 80008850 <initcode>
    80001cb8:	6928                	ld	a0,80(a0)
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	6b6080e7          	jalr	1718(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cc2:	6785                	lui	a5,0x1
    80001cc4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ccc:	6cb8                	ld	a4,88(s1)
    80001cce:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd0:	4641                	li	a2,16
    80001cd2:	00006597          	auipc	a1,0x6
    80001cd6:	52e58593          	addi	a1,a1,1326 # 80008200 <digits+0x1c0>
    80001cda:	15848513          	addi	a0,s1,344
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	154080e7          	jalr	340(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001ce6:	00006517          	auipc	a0,0x6
    80001cea:	52a50513          	addi	a0,a0,1322 # 80008210 <digits+0x1d0>
    80001cee:	00002097          	auipc	ra,0x2
    80001cf2:	1ca080e7          	jalr	458(ra) # 80003eb8 <namei>
    80001cf6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfa:	478d                	li	a5,3
    80001cfc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	f98080e7          	jalr	-104(ra) # 80000c98 <release>
}
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6105                	addi	sp,sp,32
    80001d10:	8082                	ret

0000000080001d12 <growproc>:
{
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	e04a                	sd	s2,0(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	c98080e7          	jalr	-872(ra) # 800019b8 <myproc>
    80001d28:	892a                	mv	s2,a0
  sz = p->sz;
    80001d2a:	652c                	ld	a1,72(a0)
    80001d2c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d30:	00904f63          	bgtz	s1,80001d4e <growproc+0x3c>
  } else if(n < 0){
    80001d34:	0204cc63          	bltz	s1,80001d6c <growproc+0x5a>
  p->sz = sz;
    80001d38:	1602                	slli	a2,a2,0x20
    80001d3a:	9201                	srli	a2,a2,0x20
    80001d3c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d40:	4501                	li	a0,0
}
    80001d42:	60e2                	ld	ra,24(sp)
    80001d44:	6442                	ld	s0,16(sp)
    80001d46:	64a2                	ld	s1,8(sp)
    80001d48:	6902                	ld	s2,0(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d4e:	9e25                	addw	a2,a2,s1
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	1582                	slli	a1,a1,0x20
    80001d56:	9181                	srli	a1,a1,0x20
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d0080e7          	jalr	1744(ra) # 8000142a <uvmalloc>
    80001d62:	0005061b          	sext.w	a2,a0
    80001d66:	fa69                	bnez	a2,80001d38 <growproc+0x26>
      return -1;
    80001d68:	557d                	li	a0,-1
    80001d6a:	bfe1                	j	80001d42 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6c:	9e25                	addw	a2,a2,s1
    80001d6e:	1602                	slli	a2,a2,0x20
    80001d70:	9201                	srli	a2,a2,0x20
    80001d72:	1582                	slli	a1,a1,0x20
    80001d74:	9181                	srli	a1,a1,0x20
    80001d76:	6928                	ld	a0,80(a0)
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	66a080e7          	jalr	1642(ra) # 800013e2 <uvmdealloc>
    80001d80:	0005061b          	sext.w	a2,a0
    80001d84:	bf55                	j	80001d38 <growproc+0x26>

0000000080001d86 <fork>:
{
    80001d86:	7179                	addi	sp,sp,-48
    80001d88:	f406                	sd	ra,40(sp)
    80001d8a:	f022                	sd	s0,32(sp)
    80001d8c:	ec26                	sd	s1,24(sp)
    80001d8e:	e84a                	sd	s2,16(sp)
    80001d90:	e44e                	sd	s3,8(sp)
    80001d92:	e052                	sd	s4,0(sp)
    80001d94:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	c22080e7          	jalr	-990(ra) # 800019b8 <myproc>
    80001d9e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e22080e7          	jalr	-478(ra) # 80001bc2 <allocproc>
    80001da8:	10050b63          	beqz	a0,80001ebe <fork+0x138>
    80001dac:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dae:	04893603          	ld	a2,72(s2)
    80001db2:	692c                	ld	a1,80(a0)
    80001db4:	05093503          	ld	a0,80(s2)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	7be080e7          	jalr	1982(ra) # 80001576 <uvmcopy>
    80001dc0:	04054663          	bltz	a0,80001e0c <fork+0x86>
  np->sz = p->sz;
    80001dc4:	04893783          	ld	a5,72(s2)
    80001dc8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dcc:	05893683          	ld	a3,88(s2)
    80001dd0:	87b6                	mv	a5,a3
    80001dd2:	0589b703          	ld	a4,88(s3)
    80001dd6:	12068693          	addi	a3,a3,288
    80001dda:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dde:	6788                	ld	a0,8(a5)
    80001de0:	6b8c                	ld	a1,16(a5)
    80001de2:	6f90                	ld	a2,24(a5)
    80001de4:	01073023          	sd	a6,0(a4)
    80001de8:	e708                	sd	a0,8(a4)
    80001dea:	eb0c                	sd	a1,16(a4)
    80001dec:	ef10                	sd	a2,24(a4)
    80001dee:	02078793          	addi	a5,a5,32
    80001df2:	02070713          	addi	a4,a4,32
    80001df6:	fed792e3          	bne	a5,a3,80001dda <fork+0x54>
  np->trapframe->a0 = 0;
    80001dfa:	0589b783          	ld	a5,88(s3)
    80001dfe:	0607b823          	sd	zero,112(a5)
    80001e02:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e06:	15000a13          	li	s4,336
    80001e0a:	a03d                	j	80001e38 <fork+0xb2>
    freeproc(np);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	d5c080e7          	jalr	-676(ra) # 80001b6a <freeproc>
    release(&np->lock);
    80001e16:	854e                	mv	a0,s3
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
    return -1;
    80001e20:	5a7d                	li	s4,-1
    80001e22:	a069                	j	80001eac <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	72a080e7          	jalr	1834(ra) # 8000454e <filedup>
    80001e2c:	009987b3          	add	a5,s3,s1
    80001e30:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e32:	04a1                	addi	s1,s1,8
    80001e34:	01448763          	beq	s1,s4,80001e42 <fork+0xbc>
    if(p->ofile[i])
    80001e38:	009907b3          	add	a5,s2,s1
    80001e3c:	6388                	ld	a0,0(a5)
    80001e3e:	f17d                	bnez	a0,80001e24 <fork+0x9e>
    80001e40:	bfcd                	j	80001e32 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e42:	15093503          	ld	a0,336(s2)
    80001e46:	00002097          	auipc	ra,0x2
    80001e4a:	87e080e7          	jalr	-1922(ra) # 800036c4 <idup>
    80001e4e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e52:	4641                	li	a2,16
    80001e54:	15890593          	addi	a1,s2,344
    80001e58:	15898513          	addi	a0,s3,344
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	fd6080e7          	jalr	-42(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e64:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e68:	854e                	mv	a0,s3
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e72:	0000f497          	auipc	s1,0xf
    80001e76:	44648493          	addi	s1,s1,1094 # 800112b8 <wait_lock>
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	d68080e7          	jalr	-664(ra) # 80000be4 <acquire>
  np->parent = p;
    80001e84:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001e92:	854e                	mv	a0,s3
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001e9c:	478d                	li	a5,3
    80001e9e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
}
    80001eac:	8552                	mv	a0,s4
    80001eae:	70a2                	ld	ra,40(sp)
    80001eb0:	7402                	ld	s0,32(sp)
    80001eb2:	64e2                	ld	s1,24(sp)
    80001eb4:	6942                	ld	s2,16(sp)
    80001eb6:	69a2                	ld	s3,8(sp)
    80001eb8:	6a02                	ld	s4,0(sp)
    80001eba:	6145                	addi	sp,sp,48
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	5a7d                	li	s4,-1
    80001ec0:	b7f5                	j	80001eac <fork+0x126>

0000000080001ec2 <scheduler_default>:
{
    80001ec2:	715d                	addi	sp,sp,-80
    80001ec4:	e486                	sd	ra,72(sp)
    80001ec6:	e0a2                	sd	s0,64(sp)
    80001ec8:	fc26                	sd	s1,56(sp)
    80001eca:	f84a                	sd	s2,48(sp)
    80001ecc:	f44e                	sd	s3,40(sp)
    80001ece:	f052                	sd	s4,32(sp)
    80001ed0:	ec56                	sd	s5,24(sp)
    80001ed2:	e85a                	sd	s6,16(sp)
    80001ed4:	e45e                	sd	s7,8(sp)
    80001ed6:	e062                	sd	s8,0(sp)
    80001ed8:	0880                	addi	s0,sp,80
    80001eda:	8792                	mv	a5,tp
  int id = r_tp();
    80001edc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ede:	00779c13          	slli	s8,a5,0x7
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	3be70713          	addi	a4,a4,958 # 800112a0 <pid_lock>
    80001eea:	9762                	add	a4,a4,s8
    80001eec:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    80001ef0:	0000f717          	auipc	a4,0xf
    80001ef4:	3e870713          	addi	a4,a4,1000 # 800112d8 <cpus+0x8>
    80001ef8:	9c3a                	add	s8,s8,a4
        if(ticks >= pause_ticks){ // check if pause signal was called
    80001efa:	00007a17          	auipc	s4,0x7
    80001efe:	13ea0a13          	addi	s4,s4,318 # 80009038 <ticks>
    80001f02:	00007997          	auipc	s3,0x7
    80001f06:	12698993          	addi	s3,s3,294 # 80009028 <pause_ticks>
          if(p->state == RUNNABLE) {
    80001f0a:	4a8d                	li	s5,3
            c->proc = p;
    80001f0c:	079e                	slli	a5,a5,0x7
    80001f0e:	0000fb17          	auipc	s6,0xf
    80001f12:	392b0b13          	addi	s6,s6,914 # 800112a0 <pid_lock>
    80001f16:	9b3e                	add	s6,s6,a5
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f18:	00015917          	auipc	s2,0x15
    80001f1c:	1b890913          	addi	s2,s2,440 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f28:	10079073          	csrw	sstatus,a5
    80001f2c:	0000f497          	auipc	s1,0xf
    80001f30:	7a448493          	addi	s1,s1,1956 # 800116d0 <proc>
            p->state = RUNNING;
    80001f34:	4b91                	li	s7,4
    80001f36:	a03d                	j	80001f64 <scheduler_default+0xa2>
    80001f38:	0174ac23          	sw	s7,24(s1)
            c->proc = p;
    80001f3c:	029b3823          	sd	s1,48(s6)
            swtch(&c->context, &p->context);
    80001f40:	06048593          	addi	a1,s1,96
    80001f44:	8562                	mv	a0,s8
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	70c080e7          	jalr	1804(ra) # 80002652 <swtch>
            c->proc = 0;
    80001f4e:	020b3823          	sd	zero,48(s6)
          release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
      for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	16848493          	addi	s1,s1,360
    80001f60:	fd2480e3          	beq	s1,s2,80001f20 <scheduler_default+0x5e>
        if(ticks >= pause_ticks){ // check if pause signal was called
    80001f64:	000a2703          	lw	a4,0(s4)
    80001f68:	0009a783          	lw	a5,0(s3)
    80001f6c:	fef768e3          	bltu	a4,a5,80001f5c <scheduler_default+0x9a>
          acquire(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	c72080e7          	jalr	-910(ra) # 80000be4 <acquire>
          if(p->state == RUNNABLE) {
    80001f7a:	4c9c                	lw	a5,24(s1)
    80001f7c:	fd579be3          	bne	a5,s5,80001f52 <scheduler_default+0x90>
    80001f80:	bf65                	j	80001f38 <scheduler_default+0x76>

0000000080001f82 <scheduler>:
{
    80001f82:	1141                	addi	sp,sp,-16
    80001f84:	e406                	sd	ra,8(sp)
    80001f86:	e022                	sd	s0,0(sp)
    80001f88:	0800                	addi	s0,sp,16
    printf("default scheduler mode\n");
    80001f8a:	00006517          	auipc	a0,0x6
    80001f8e:	28e50513          	addi	a0,a0,654 # 80008218 <digits+0x1d8>
    80001f92:	ffffe097          	auipc	ra,0xffffe
    80001f96:	5f6080e7          	jalr	1526(ra) # 80000588 <printf>
    scheduler_default();
    80001f9a:	00000097          	auipc	ra,0x0
    80001f9e:	f28080e7          	jalr	-216(ra) # 80001ec2 <scheduler_default>

0000000080001fa2 <sched>:
{
    80001fa2:	7179                	addi	sp,sp,-48
    80001fa4:	f406                	sd	ra,40(sp)
    80001fa6:	f022                	sd	s0,32(sp)
    80001fa8:	ec26                	sd	s1,24(sp)
    80001faa:	e84a                	sd	s2,16(sp)
    80001fac:	e44e                	sd	s3,8(sp)
    80001fae:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	a08080e7          	jalr	-1528(ra) # 800019b8 <myproc>
    80001fb8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	bb0080e7          	jalr	-1104(ra) # 80000b6a <holding>
    80001fc2:	c93d                	beqz	a0,80002038 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc6:	2781                	sext.w	a5,a5
    80001fc8:	079e                	slli	a5,a5,0x7
    80001fca:	0000f717          	auipc	a4,0xf
    80001fce:	2d670713          	addi	a4,a4,726 # 800112a0 <pid_lock>
    80001fd2:	97ba                	add	a5,a5,a4
    80001fd4:	0a87a703          	lw	a4,168(a5)
    80001fd8:	4785                	li	a5,1
    80001fda:	06f71763          	bne	a4,a5,80002048 <sched+0xa6>
  if(p->state == RUNNING)
    80001fde:	4c98                	lw	a4,24(s1)
    80001fe0:	4791                	li	a5,4
    80001fe2:	06f70b63          	beq	a4,a5,80002058 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fea:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fec:	efb5                	bnez	a5,80002068 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fee:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff0:	0000f917          	auipc	s2,0xf
    80001ff4:	2b090913          	addi	s2,s2,688 # 800112a0 <pid_lock>
    80001ff8:	2781                	sext.w	a5,a5
    80001ffa:	079e                	slli	a5,a5,0x7
    80001ffc:	97ca                	add	a5,a5,s2
    80001ffe:	0ac7a983          	lw	s3,172(a5)
    80002002:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002004:	2781                	sext.w	a5,a5
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	0000f597          	auipc	a1,0xf
    8000200c:	2d058593          	addi	a1,a1,720 # 800112d8 <cpus+0x8>
    80002010:	95be                	add	a1,a1,a5
    80002012:	06048513          	addi	a0,s1,96
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	63c080e7          	jalr	1596(ra) # 80002652 <swtch>
    8000201e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002020:	2781                	sext.w	a5,a5
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	97ca                	add	a5,a5,s2
    80002026:	0b37a623          	sw	s3,172(a5)
}
    8000202a:	70a2                	ld	ra,40(sp)
    8000202c:	7402                	ld	s0,32(sp)
    8000202e:	64e2                	ld	s1,24(sp)
    80002030:	6942                	ld	s2,16(sp)
    80002032:	69a2                	ld	s3,8(sp)
    80002034:	6145                	addi	sp,sp,48
    80002036:	8082                	ret
    panic("sched p->lock");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f850513          	addi	a0,a0,504 # 80008230 <digits+0x1f0>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	4fe080e7          	jalr	1278(ra) # 8000053e <panic>
    panic("sched locks");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	1f850513          	addi	a0,a0,504 # 80008240 <digits+0x200>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4ee080e7          	jalr	1262(ra) # 8000053e <panic>
    panic("sched running");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	1f850513          	addi	a0,a0,504 # 80008250 <digits+0x210>
    80002060:	ffffe097          	auipc	ra,0xffffe
    80002064:	4de080e7          	jalr	1246(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002068:	00006517          	auipc	a0,0x6
    8000206c:	1f850513          	addi	a0,a0,504 # 80008260 <digits+0x220>
    80002070:	ffffe097          	auipc	ra,0xffffe
    80002074:	4ce080e7          	jalr	1230(ra) # 8000053e <panic>

0000000080002078 <yield>:
{
    80002078:	1101                	addi	sp,sp,-32
    8000207a:	ec06                	sd	ra,24(sp)
    8000207c:	e822                	sd	s0,16(sp)
    8000207e:	e426                	sd	s1,8(sp)
    80002080:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	936080e7          	jalr	-1738(ra) # 800019b8 <myproc>
    8000208a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b58080e7          	jalr	-1192(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002094:	478d                	li	a5,3
    80002096:	cc9c                	sw	a5,24(s1)
  sched();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	f0a080e7          	jalr	-246(ra) # 80001fa2 <sched>
  release(&p->lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	bf6080e7          	jalr	-1034(ra) # 80000c98 <release>
}
    800020aa:	60e2                	ld	ra,24(sp)
    800020ac:	6442                	ld	s0,16(sp)
    800020ae:	64a2                	ld	s1,8(sp)
    800020b0:	6105                	addi	sp,sp,32
    800020b2:	8082                	ret

00000000800020b4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020b4:	7179                	addi	sp,sp,-48
    800020b6:	f406                	sd	ra,40(sp)
    800020b8:	f022                	sd	s0,32(sp)
    800020ba:	ec26                	sd	s1,24(sp)
    800020bc:	e84a                	sd	s2,16(sp)
    800020be:	e44e                	sd	s3,8(sp)
    800020c0:	1800                	addi	s0,sp,48
    800020c2:	89aa                	mv	s3,a0
    800020c4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	8f2080e7          	jalr	-1806(ra) # 800019b8 <myproc>
    800020ce:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  release(lk);
    800020d8:	854a                	mv	a0,s2
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bbe080e7          	jalr	-1090(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020e2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e6:	4789                	li	a5,2
    800020e8:	cc9c                	sw	a5,24(s1)

  sched();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	eb8080e7          	jalr	-328(ra) # 80001fa2 <sched>

  // Tidy up.
  p->chan = 0;
    800020f2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
  acquire(lk);
    80002100:	854a                	mv	a0,s2
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae2080e7          	jalr	-1310(ra) # 80000be4 <acquire>
}
    8000210a:	70a2                	ld	ra,40(sp)
    8000210c:	7402                	ld	s0,32(sp)
    8000210e:	64e2                	ld	s1,24(sp)
    80002110:	6942                	ld	s2,16(sp)
    80002112:	69a2                	ld	s3,8(sp)
    80002114:	6145                	addi	sp,sp,48
    80002116:	8082                	ret

0000000080002118 <wait>:
{
    80002118:	715d                	addi	sp,sp,-80
    8000211a:	e486                	sd	ra,72(sp)
    8000211c:	e0a2                	sd	s0,64(sp)
    8000211e:	fc26                	sd	s1,56(sp)
    80002120:	f84a                	sd	s2,48(sp)
    80002122:	f44e                	sd	s3,40(sp)
    80002124:	f052                	sd	s4,32(sp)
    80002126:	ec56                	sd	s5,24(sp)
    80002128:	e85a                	sd	s6,16(sp)
    8000212a:	e45e                	sd	s7,8(sp)
    8000212c:	e062                	sd	s8,0(sp)
    8000212e:	0880                	addi	s0,sp,80
    80002130:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002132:	00000097          	auipc	ra,0x0
    80002136:	886080e7          	jalr	-1914(ra) # 800019b8 <myproc>
    8000213a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000213c:	0000f517          	auipc	a0,0xf
    80002140:	17c50513          	addi	a0,a0,380 # 800112b8 <wait_lock>
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
    havekids = 0;
    8000214c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000214e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	f8098993          	addi	s3,s3,-128 # 800170d0 <tickslock>
        havekids = 1;
    80002158:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000215a:	0000fc17          	auipc	s8,0xf
    8000215e:	15ec0c13          	addi	s8,s8,350 # 800112b8 <wait_lock>
    havekids = 0;
    80002162:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002164:	0000f497          	auipc	s1,0xf
    80002168:	56c48493          	addi	s1,s1,1388 # 800116d0 <proc>
    8000216c:	a0bd                	j	800021da <wait+0xc2>
          pid = np->pid;
    8000216e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002172:	000b0e63          	beqz	s6,8000218e <wait+0x76>
    80002176:	4691                	li	a3,4
    80002178:	02c48613          	addi	a2,s1,44
    8000217c:	85da                	mv	a1,s6
    8000217e:	05093503          	ld	a0,80(s2)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	4f8080e7          	jalr	1272(ra) # 8000167a <copyout>
    8000218a:	02054563          	bltz	a0,800021b4 <wait+0x9c>
          freeproc(np);
    8000218e:	8526                	mv	a0,s1
    80002190:	00000097          	auipc	ra,0x0
    80002194:	9da080e7          	jalr	-1574(ra) # 80001b6a <freeproc>
          release(&np->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
          release(&wait_lock);
    800021a2:	0000f517          	auipc	a0,0xf
    800021a6:	11650513          	addi	a0,a0,278 # 800112b8 <wait_lock>
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
          return pid;
    800021b2:	a09d                	j	80002218 <wait+0x100>
            release(&np->lock);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
            release(&wait_lock);
    800021be:	0000f517          	auipc	a0,0xf
    800021c2:	0fa50513          	addi	a0,a0,250 # 800112b8 <wait_lock>
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
            return -1;
    800021ce:	59fd                	li	s3,-1
    800021d0:	a0a1                	j	80002218 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021d2:	16848493          	addi	s1,s1,360
    800021d6:	03348463          	beq	s1,s3,800021fe <wait+0xe6>
      if(np->parent == p){
    800021da:	7c9c                	ld	a5,56(s1)
    800021dc:	ff279be3          	bne	a5,s2,800021d2 <wait+0xba>
        acquire(&np->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021ea:	4c9c                	lw	a5,24(s1)
    800021ec:	f94781e3          	beq	a5,s4,8000216e <wait+0x56>
        release(&np->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	aa6080e7          	jalr	-1370(ra) # 80000c98 <release>
        havekids = 1;
    800021fa:	8756                	mv	a4,s5
    800021fc:	bfd9                	j	800021d2 <wait+0xba>
    if(!havekids || p->killed){
    800021fe:	c701                	beqz	a4,80002206 <wait+0xee>
    80002200:	02892783          	lw	a5,40(s2)
    80002204:	c79d                	beqz	a5,80002232 <wait+0x11a>
      release(&wait_lock);
    80002206:	0000f517          	auipc	a0,0xf
    8000220a:	0b250513          	addi	a0,a0,178 # 800112b8 <wait_lock>
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
      return -1;
    80002216:	59fd                	li	s3,-1
}
    80002218:	854e                	mv	a0,s3
    8000221a:	60a6                	ld	ra,72(sp)
    8000221c:	6406                	ld	s0,64(sp)
    8000221e:	74e2                	ld	s1,56(sp)
    80002220:	7942                	ld	s2,48(sp)
    80002222:	79a2                	ld	s3,40(sp)
    80002224:	7a02                	ld	s4,32(sp)
    80002226:	6ae2                	ld	s5,24(sp)
    80002228:	6b42                	ld	s6,16(sp)
    8000222a:	6ba2                	ld	s7,8(sp)
    8000222c:	6c02                	ld	s8,0(sp)
    8000222e:	6161                	addi	sp,sp,80
    80002230:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002232:	85e2                	mv	a1,s8
    80002234:	854a                	mv	a0,s2
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e7e080e7          	jalr	-386(ra) # 800020b4 <sleep>
    havekids = 0;
    8000223e:	b715                	j	80002162 <wait+0x4a>

0000000080002240 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002240:	7139                	addi	sp,sp,-64
    80002242:	fc06                	sd	ra,56(sp)
    80002244:	f822                	sd	s0,48(sp)
    80002246:	f426                	sd	s1,40(sp)
    80002248:	f04a                	sd	s2,32(sp)
    8000224a:	ec4e                	sd	s3,24(sp)
    8000224c:	e852                	sd	s4,16(sp)
    8000224e:	e456                	sd	s5,8(sp)
    80002250:	0080                	addi	s0,sp,64
    80002252:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002254:	0000f497          	auipc	s1,0xf
    80002258:	47c48493          	addi	s1,s1,1148 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000225c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000225e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002260:	00015917          	auipc	s2,0x15
    80002264:	e7090913          	addi	s2,s2,-400 # 800170d0 <tickslock>
    80002268:	a821                	j	80002280 <wakeup+0x40>
        p->state = RUNNABLE;
    8000226a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002278:	16848493          	addi	s1,s1,360
    8000227c:	03248463          	beq	s1,s2,800022a4 <wakeup+0x64>
    if(p != myproc()){
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	738080e7          	jalr	1848(ra) # 800019b8 <myproc>
    80002288:	fea488e3          	beq	s1,a0,80002278 <wakeup+0x38>
      acquire(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	956080e7          	jalr	-1706(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002296:	4c9c                	lw	a5,24(s1)
    80002298:	fd379be3          	bne	a5,s3,8000226e <wakeup+0x2e>
    8000229c:	709c                	ld	a5,32(s1)
    8000229e:	fd4798e3          	bne	a5,s4,8000226e <wakeup+0x2e>
    800022a2:	b7e1                	j	8000226a <wakeup+0x2a>
    }
  }
}
    800022a4:	70e2                	ld	ra,56(sp)
    800022a6:	7442                	ld	s0,48(sp)
    800022a8:	74a2                	ld	s1,40(sp)
    800022aa:	7902                	ld	s2,32(sp)
    800022ac:	69e2                	ld	s3,24(sp)
    800022ae:	6a42                	ld	s4,16(sp)
    800022b0:	6aa2                	ld	s5,8(sp)
    800022b2:	6121                	addi	sp,sp,64
    800022b4:	8082                	ret

00000000800022b6 <reparent>:
{
    800022b6:	7179                	addi	sp,sp,-48
    800022b8:	f406                	sd	ra,40(sp)
    800022ba:	f022                	sd	s0,32(sp)
    800022bc:	ec26                	sd	s1,24(sp)
    800022be:	e84a                	sd	s2,16(sp)
    800022c0:	e44e                	sd	s3,8(sp)
    800022c2:	e052                	sd	s4,0(sp)
    800022c4:	1800                	addi	s0,sp,48
    800022c6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c8:	0000f497          	auipc	s1,0xf
    800022cc:	40848493          	addi	s1,s1,1032 # 800116d0 <proc>
      pp->parent = initproc;
    800022d0:	00007a17          	auipc	s4,0x7
    800022d4:	d60a0a13          	addi	s4,s4,-672 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d8:	00015997          	auipc	s3,0x15
    800022dc:	df898993          	addi	s3,s3,-520 # 800170d0 <tickslock>
    800022e0:	a029                	j	800022ea <reparent+0x34>
    800022e2:	16848493          	addi	s1,s1,360
    800022e6:	01348d63          	beq	s1,s3,80002300 <reparent+0x4a>
    if(pp->parent == p){
    800022ea:	7c9c                	ld	a5,56(s1)
    800022ec:	ff279be3          	bne	a5,s2,800022e2 <reparent+0x2c>
      pp->parent = initproc;
    800022f0:	000a3503          	ld	a0,0(s4)
    800022f4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	f4a080e7          	jalr	-182(ra) # 80002240 <wakeup>
    800022fe:	b7d5                	j	800022e2 <reparent+0x2c>
}
    80002300:	70a2                	ld	ra,40(sp)
    80002302:	7402                	ld	s0,32(sp)
    80002304:	64e2                	ld	s1,24(sp)
    80002306:	6942                	ld	s2,16(sp)
    80002308:	69a2                	ld	s3,8(sp)
    8000230a:	6a02                	ld	s4,0(sp)
    8000230c:	6145                	addi	sp,sp,48
    8000230e:	8082                	ret

0000000080002310 <exit>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	e052                	sd	s4,0(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	696080e7          	jalr	1686(ra) # 800019b8 <myproc>
    8000232a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000232c:	00007797          	auipc	a5,0x7
    80002330:	d047b783          	ld	a5,-764(a5) # 80009030 <initproc>
    80002334:	0d050493          	addi	s1,a0,208
    80002338:	15050913          	addi	s2,a0,336
    8000233c:	02a79363          	bne	a5,a0,80002362 <exit+0x52>
    panic("init exiting");
    80002340:	00006517          	auipc	a0,0x6
    80002344:	f3850513          	addi	a0,a0,-200 # 80008278 <digits+0x238>
    80002348:	ffffe097          	auipc	ra,0xffffe
    8000234c:	1f6080e7          	jalr	502(ra) # 8000053e <panic>
      fileclose(f);
    80002350:	00002097          	auipc	ra,0x2
    80002354:	250080e7          	jalr	592(ra) # 800045a0 <fileclose>
      p->ofile[fd] = 0;
    80002358:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000235c:	04a1                	addi	s1,s1,8
    8000235e:	01248563          	beq	s1,s2,80002368 <exit+0x58>
    if(p->ofile[fd]){
    80002362:	6088                	ld	a0,0(s1)
    80002364:	f575                	bnez	a0,80002350 <exit+0x40>
    80002366:	bfdd                	j	8000235c <exit+0x4c>
  begin_op();
    80002368:	00002097          	auipc	ra,0x2
    8000236c:	d6c080e7          	jalr	-660(ra) # 800040d4 <begin_op>
  iput(p->cwd);
    80002370:	1509b503          	ld	a0,336(s3)
    80002374:	00001097          	auipc	ra,0x1
    80002378:	548080e7          	jalr	1352(ra) # 800038bc <iput>
  end_op();
    8000237c:	00002097          	auipc	ra,0x2
    80002380:	dd8080e7          	jalr	-552(ra) # 80004154 <end_op>
  p->cwd = 0;
    80002384:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002388:	0000f497          	auipc	s1,0xf
    8000238c:	f3048493          	addi	s1,s1,-208 # 800112b8 <wait_lock>
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	852080e7          	jalr	-1966(ra) # 80000be4 <acquire>
  reparent(p);
    8000239a:	854e                	mv	a0,s3
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	f1a080e7          	jalr	-230(ra) # 800022b6 <reparent>
  wakeup(p->parent);
    800023a4:	0389b503          	ld	a0,56(s3)
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	e98080e7          	jalr	-360(ra) # 80002240 <wakeup>
  acquire(&p->lock);
    800023b0:	854e                	mv	a0,s3
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	832080e7          	jalr	-1998(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023ba:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023be:	4795                	li	a5,5
    800023c0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d2080e7          	jalr	-1838(ra) # 80000c98 <release>
  sched();
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	bd4080e7          	jalr	-1068(ra) # 80001fa2 <sched>
  panic("zombie exit");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	eb250513          	addi	a0,a0,-334 # 80008288 <digits+0x248>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	160080e7          	jalr	352(ra) # 8000053e <panic>

00000000800023e6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e6:	7179                	addi	sp,sp,-48
    800023e8:	f406                	sd	ra,40(sp)
    800023ea:	f022                	sd	s0,32(sp)
    800023ec:	ec26                	sd	s1,24(sp)
    800023ee:	e84a                	sd	s2,16(sp)
    800023f0:	e44e                	sd	s3,8(sp)
    800023f2:	1800                	addi	s0,sp,48
    800023f4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f6:	0000f497          	auipc	s1,0xf
    800023fa:	2da48493          	addi	s1,s1,730 # 800116d0 <proc>
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	cd298993          	addi	s3,s3,-814 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7dc080e7          	jalr	2012(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002410:	589c                	lw	a5,48(s1)
    80002412:	01278d63          	beq	a5,s2,8000242c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	880080e7          	jalr	-1920(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002420:	16848493          	addi	s1,s1,360
    80002424:	ff3491e3          	bne	s1,s3,80002406 <kill+0x20>
  }
  return -1;
    80002428:	557d                	li	a0,-1
    8000242a:	a829                	j	80002444 <kill+0x5e>
      p->killed = 1;
    8000242c:	4785                	li	a5,1
    8000242e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002430:	4c98                	lw	a4,24(s1)
    80002432:	4789                	li	a5,2
    80002434:	00f70f63          	beq	a4,a5,80002452 <kill+0x6c>
      release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	85e080e7          	jalr	-1954(ra) # 80000c98 <release>
      return 0;
    80002442:	4501                	li	a0,0
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6145                	addi	sp,sp,48
    80002450:	8082                	ret
        p->state = RUNNABLE;
    80002452:	478d                	li	a5,3
    80002454:	cc9c                	sw	a5,24(s1)
    80002456:	b7cd                	j	80002438 <kill+0x52>

0000000080002458 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	84aa                	mv	s1,a0
    8000246a:	892e                	mv	s2,a1
    8000246c:	89b2                	mv	s3,a2
    8000246e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	548080e7          	jalr	1352(ra) # 800019b8 <myproc>
  if(user_dst){
    80002478:	c08d                	beqz	s1,8000249a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247a:	86d2                	mv	a3,s4
    8000247c:	864e                	mv	a2,s3
    8000247e:	85ca                	mv	a1,s2
    80002480:	6928                	ld	a0,80(a0)
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	1f8080e7          	jalr	504(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6a02                	ld	s4,0(sp)
    80002496:	6145                	addi	sp,sp,48
    80002498:	8082                	ret
    memmove((char *)dst, src, len);
    8000249a:	000a061b          	sext.w	a2,s4
    8000249e:	85ce                	mv	a1,s3
    800024a0:	854a                	mv	a0,s2
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	89e080e7          	jalr	-1890(ra) # 80000d40 <memmove>
    return 0;
    800024aa:	8526                	mv	a0,s1
    800024ac:	bff9                	j	8000248a <either_copyout+0x32>

00000000800024ae <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	892a                	mv	s2,a0
    800024c0:	84ae                	mv	s1,a1
    800024c2:	89b2                	mv	s3,a2
    800024c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	4f2080e7          	jalr	1266(ra) # 800019b8 <myproc>
  if(user_src){
    800024ce:	c08d                	beqz	s1,800024f0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d0:	86d2                	mv	a3,s4
    800024d2:	864e                	mv	a2,s3
    800024d4:	85ca                	mv	a1,s2
    800024d6:	6928                	ld	a0,80(a0)
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	22e080e7          	jalr	558(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6a02                	ld	s4,0(sp)
    800024ec:	6145                	addi	sp,sp,48
    800024ee:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f0:	000a061b          	sext.w	a2,s4
    800024f4:	85ce                	mv	a1,s3
    800024f6:	854a                	mv	a0,s2
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	848080e7          	jalr	-1976(ra) # 80000d40 <memmove>
    return 0;
    80002500:	8526                	mv	a0,s1
    80002502:	bff9                	j	800024e0 <either_copyin+0x32>

0000000080002504 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002504:	715d                	addi	sp,sp,-80
    80002506:	e486                	sd	ra,72(sp)
    80002508:	e0a2                	sd	s0,64(sp)
    8000250a:	fc26                	sd	s1,56(sp)
    8000250c:	f84a                	sd	s2,48(sp)
    8000250e:	f44e                	sd	s3,40(sp)
    80002510:	f052                	sd	s4,32(sp)
    80002512:	ec56                	sd	s5,24(sp)
    80002514:	e85a                	sd	s6,16(sp)
    80002516:	e45e                	sd	s7,8(sp)
    80002518:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	bae50513          	addi	a0,a0,-1106 # 800080c8 <digits+0x88>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	066080e7          	jalr	102(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252a:	0000f497          	auipc	s1,0xf
    8000252e:	2fe48493          	addi	s1,s1,766 # 80011828 <proc+0x158>
    80002532:	00015917          	auipc	s2,0x15
    80002536:	cf690913          	addi	s2,s2,-778 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000253c:	00006997          	auipc	s3,0x6
    80002540:	d5c98993          	addi	s3,s3,-676 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    80002544:	00006a97          	auipc	s5,0x6
    80002548:	d5ca8a93          	addi	s5,s5,-676 # 800082a0 <digits+0x260>
    printf("\n");
    8000254c:	00006a17          	auipc	s4,0x6
    80002550:	b7ca0a13          	addi	s4,s4,-1156 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002554:	00006b97          	auipc	s7,0x6
    80002558:	d84b8b93          	addi	s7,s7,-636 # 800082d8 <states.1726>
    8000255c:	a00d                	j	8000257e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255e:	ed86a583          	lw	a1,-296(a3)
    80002562:	8556                	mv	a0,s5
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	024080e7          	jalr	36(ra) # 80000588 <printf>
    printf("\n");
    8000256c:	8552                	mv	a0,s4
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	01a080e7          	jalr	26(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002576:	16848493          	addi	s1,s1,360
    8000257a:	03248163          	beq	s1,s2,8000259c <procdump+0x98>
    if(p->state == UNUSED)
    8000257e:	86a6                	mv	a3,s1
    80002580:	ec04a783          	lw	a5,-320(s1)
    80002584:	dbed                	beqz	a5,80002576 <procdump+0x72>
      state = "???";
    80002586:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002588:	fcfb6be3          	bltu	s6,a5,8000255e <procdump+0x5a>
    8000258c:	1782                	slli	a5,a5,0x20
    8000258e:	9381                	srli	a5,a5,0x20
    80002590:	078e                	slli	a5,a5,0x3
    80002592:	97de                	add	a5,a5,s7
    80002594:	6390                	ld	a2,0(a5)
    80002596:	f661                	bnez	a2,8000255e <procdump+0x5a>
      state = "???";
    80002598:	864e                	mv	a2,s3
    8000259a:	b7d1                	j	8000255e <procdump+0x5a>
  }
}
    8000259c:	60a6                	ld	ra,72(sp)
    8000259e:	6406                	ld	s0,64(sp)
    800025a0:	74e2                	ld	s1,56(sp)
    800025a2:	7942                	ld	s2,48(sp)
    800025a4:	79a2                	ld	s3,40(sp)
    800025a6:	7a02                	ld	s4,32(sp)
    800025a8:	6ae2                	ld	s5,24(sp)
    800025aa:	6b42                	ld	s6,16(sp)
    800025ac:	6ba2                	ld	s7,8(sp)
    800025ae:	6161                	addi	sp,sp,80
    800025b0:	8082                	ret

00000000800025b2 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    800025b2:	1141                	addi	sp,sp,-16
    800025b4:	e406                	sd	ra,8(sp)
    800025b6:	e022                	sd	s0,0(sp)
    800025b8:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    800025ba:	0025179b          	slliw	a5,a0,0x2
    800025be:	9fa9                	addw	a5,a5,a0
    800025c0:	0017979b          	slliw	a5,a5,0x1
    800025c4:	00007517          	auipc	a0,0x7
    800025c8:	a7452503          	lw	a0,-1420(a0) # 80009038 <ticks>
    800025cc:	9fa9                	addw	a5,a5,a0
    800025ce:	00007717          	auipc	a4,0x7
    800025d2:	a4f72d23          	sw	a5,-1446(a4) # 80009028 <pause_ticks>
  yield();
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	aa2080e7          	jalr	-1374(ra) # 80002078 <yield>

  return 0;
}
    800025de:	4501                	li	a0,0
    800025e0:	60a2                	ld	ra,8(sp)
    800025e2:	6402                	ld	s0,0(sp)
    800025e4:	0141                	addi	sp,sp,16
    800025e6:	8082                	ret

00000000800025e8 <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    800025e8:	7179                	addi	sp,sp,-48
    800025ea:	f406                	sd	ra,40(sp)
    800025ec:	f022                	sd	s0,32(sp)
    800025ee:	ec26                	sd	s1,24(sp)
    800025f0:	e84a                	sd	s2,16(sp)
    800025f2:	e44e                	sd	s3,8(sp)
    800025f4:	e052                	sd	s4,0(sp)
    800025f6:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025f8:	0000f497          	auipc	s1,0xf
    800025fc:	0d848493          	addi	s1,s1,216 # 800116d0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    80002600:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002602:	00015997          	auipc	s3,0x15
    80002606:	ace98993          	addi	s3,s3,-1330 # 800170d0 <tickslock>
    8000260a:	a029                	j	80002614 <kill_system+0x2c>
    8000260c:	16848493          	addi	s1,s1,360
    80002610:	03348863          	beq	s1,s3,80002640 <kill_system+0x58>
      acquire(&p->lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	5ce080e7          	jalr	1486(ra) # 80000be4 <acquire>
      pid = p->pid;
    8000261e:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	674080e7          	jalr	1652(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    8000262c:	fff9079b          	addiw	a5,s2,-1
    80002630:	fcfa7ee3          	bgeu	s4,a5,8000260c <kill_system+0x24>
        kill(pid);
    80002634:	854a                	mv	a0,s2
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	db0080e7          	jalr	-592(ra) # 800023e6 <kill>
    8000263e:	b7f9                	j	8000260c <kill_system+0x24>
  }
  return 0;
}
    80002640:	4501                	li	a0,0
    80002642:	70a2                	ld	ra,40(sp)
    80002644:	7402                	ld	s0,32(sp)
    80002646:	64e2                	ld	s1,24(sp)
    80002648:	6942                	ld	s2,16(sp)
    8000264a:	69a2                	ld	s3,8(sp)
    8000264c:	6a02                	ld	s4,0(sp)
    8000264e:	6145                	addi	sp,sp,48
    80002650:	8082                	ret

0000000080002652 <swtch>:
    80002652:	00153023          	sd	ra,0(a0)
    80002656:	00253423          	sd	sp,8(a0)
    8000265a:	e900                	sd	s0,16(a0)
    8000265c:	ed04                	sd	s1,24(a0)
    8000265e:	03253023          	sd	s2,32(a0)
    80002662:	03353423          	sd	s3,40(a0)
    80002666:	03453823          	sd	s4,48(a0)
    8000266a:	03553c23          	sd	s5,56(a0)
    8000266e:	05653023          	sd	s6,64(a0)
    80002672:	05753423          	sd	s7,72(a0)
    80002676:	05853823          	sd	s8,80(a0)
    8000267a:	05953c23          	sd	s9,88(a0)
    8000267e:	07a53023          	sd	s10,96(a0)
    80002682:	07b53423          	sd	s11,104(a0)
    80002686:	0005b083          	ld	ra,0(a1)
    8000268a:	0085b103          	ld	sp,8(a1)
    8000268e:	6980                	ld	s0,16(a1)
    80002690:	6d84                	ld	s1,24(a1)
    80002692:	0205b903          	ld	s2,32(a1)
    80002696:	0285b983          	ld	s3,40(a1)
    8000269a:	0305ba03          	ld	s4,48(a1)
    8000269e:	0385ba83          	ld	s5,56(a1)
    800026a2:	0405bb03          	ld	s6,64(a1)
    800026a6:	0485bb83          	ld	s7,72(a1)
    800026aa:	0505bc03          	ld	s8,80(a1)
    800026ae:	0585bc83          	ld	s9,88(a1)
    800026b2:	0605bd03          	ld	s10,96(a1)
    800026b6:	0685bd83          	ld	s11,104(a1)
    800026ba:	8082                	ret

00000000800026bc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026bc:	1141                	addi	sp,sp,-16
    800026be:	e406                	sd	ra,8(sp)
    800026c0:	e022                	sd	s0,0(sp)
    800026c2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c4:	00006597          	auipc	a1,0x6
    800026c8:	c4458593          	addi	a1,a1,-956 # 80008308 <states.1726+0x30>
    800026cc:	00015517          	auipc	a0,0x15
    800026d0:	a0450513          	addi	a0,a0,-1532 # 800170d0 <tickslock>
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	480080e7          	jalr	1152(ra) # 80000b54 <initlock>
}
    800026dc:	60a2                	ld	ra,8(sp)
    800026de:	6402                	ld	s0,0(sp)
    800026e0:	0141                	addi	sp,sp,16
    800026e2:	8082                	ret

00000000800026e4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e4:	1141                	addi	sp,sp,-16
    800026e6:	e422                	sd	s0,8(sp)
    800026e8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ea:	00003797          	auipc	a5,0x3
    800026ee:	4d678793          	addi	a5,a5,1238 # 80005bc0 <kernelvec>
    800026f2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f6:	6422                	ld	s0,8(sp)
    800026f8:	0141                	addi	sp,sp,16
    800026fa:	8082                	ret

00000000800026fc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026fc:	1141                	addi	sp,sp,-16
    800026fe:	e406                	sd	ra,8(sp)
    80002700:	e022                	sd	s0,0(sp)
    80002702:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	2b4080e7          	jalr	692(ra) # 800019b8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002710:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002712:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002716:	00005617          	auipc	a2,0x5
    8000271a:	8ea60613          	addi	a2,a2,-1814 # 80007000 <_trampoline>
    8000271e:	00005697          	auipc	a3,0x5
    80002722:	8e268693          	addi	a3,a3,-1822 # 80007000 <_trampoline>
    80002726:	8e91                	sub	a3,a3,a2
    80002728:	040007b7          	lui	a5,0x4000
    8000272c:	17fd                	addi	a5,a5,-1
    8000272e:	07b2                	slli	a5,a5,0xc
    80002730:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002732:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002738:	180026f3          	csrr	a3,satp
    8000273c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273e:	6d38                	ld	a4,88(a0)
    80002740:	6134                	ld	a3,64(a0)
    80002742:	6585                	lui	a1,0x1
    80002744:	96ae                	add	a3,a3,a1
    80002746:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002748:	6d38                	ld	a4,88(a0)
    8000274a:	00000697          	auipc	a3,0x0
    8000274e:	13868693          	addi	a3,a3,312 # 80002882 <usertrap>
    80002752:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002754:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002756:	8692                	mv	a3,tp
    80002758:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002762:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002766:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000276a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000276c:	6f18                	ld	a4,24(a4)
    8000276e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002772:	692c                	ld	a1,80(a0)
    80002774:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002776:	00005717          	auipc	a4,0x5
    8000277a:	91a70713          	addi	a4,a4,-1766 # 80007090 <userret>
    8000277e:	8f11                	sub	a4,a4,a2
    80002780:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002782:	577d                	li	a4,-1
    80002784:	177e                	slli	a4,a4,0x3f
    80002786:	8dd9                	or	a1,a1,a4
    80002788:	02000537          	lui	a0,0x2000
    8000278c:	157d                	addi	a0,a0,-1
    8000278e:	0536                	slli	a0,a0,0xd
    80002790:	9782                	jalr	a5
}
    80002792:	60a2                	ld	ra,8(sp)
    80002794:	6402                	ld	s0,0(sp)
    80002796:	0141                	addi	sp,sp,16
    80002798:	8082                	ret

000000008000279a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279a:	1101                	addi	sp,sp,-32
    8000279c:	ec06                	sd	ra,24(sp)
    8000279e:	e822                	sd	s0,16(sp)
    800027a0:	e426                	sd	s1,8(sp)
    800027a2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a4:	00015497          	auipc	s1,0x15
    800027a8:	92c48493          	addi	s1,s1,-1748 # 800170d0 <tickslock>
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	436080e7          	jalr	1078(ra) # 80000be4 <acquire>
  ticks++;
    800027b6:	00007517          	auipc	a0,0x7
    800027ba:	88250513          	addi	a0,a0,-1918 # 80009038 <ticks>
    800027be:	411c                	lw	a5,0(a0)
    800027c0:	2785                	addiw	a5,a5,1
    800027c2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c4:	00000097          	auipc	ra,0x0
    800027c8:	a7c080e7          	jalr	-1412(ra) # 80002240 <wakeup>
  release(&tickslock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
}
    800027d6:	60e2                	ld	ra,24(sp)
    800027d8:	6442                	ld	s0,16(sp)
    800027da:	64a2                	ld	s1,8(sp)
    800027dc:	6105                	addi	sp,sp,32
    800027de:	8082                	ret

00000000800027e0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027e0:	1101                	addi	sp,sp,-32
    800027e2:	ec06                	sd	ra,24(sp)
    800027e4:	e822                	sd	s0,16(sp)
    800027e6:	e426                	sd	s1,8(sp)
    800027e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ea:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ee:	00074d63          	bltz	a4,80002808 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f2:	57fd                	li	a5,-1
    800027f4:	17fe                	slli	a5,a5,0x3f
    800027f6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027fa:	06f70363          	beq	a4,a5,80002860 <devintr+0x80>
  }
}
    800027fe:	60e2                	ld	ra,24(sp)
    80002800:	6442                	ld	s0,16(sp)
    80002802:	64a2                	ld	s1,8(sp)
    80002804:	6105                	addi	sp,sp,32
    80002806:	8082                	ret
     (scause & 0xff) == 9){
    80002808:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000280c:	46a5                	li	a3,9
    8000280e:	fed792e3          	bne	a5,a3,800027f2 <devintr+0x12>
    int irq = plic_claim();
    80002812:	00003097          	auipc	ra,0x3
    80002816:	4b6080e7          	jalr	1206(ra) # 80005cc8 <plic_claim>
    8000281a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281c:	47a9                	li	a5,10
    8000281e:	02f50763          	beq	a0,a5,8000284c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002822:	4785                	li	a5,1
    80002824:	02f50963          	beq	a0,a5,80002856 <devintr+0x76>
    return 1;
    80002828:	4505                	li	a0,1
    } else if(irq){
    8000282a:	d8f1                	beqz	s1,800027fe <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282c:	85a6                	mv	a1,s1
    8000282e:	00006517          	auipc	a0,0x6
    80002832:	ae250513          	addi	a0,a0,-1310 # 80008310 <states.1726+0x38>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	d52080e7          	jalr	-686(ra) # 80000588 <printf>
      plic_complete(irq);
    8000283e:	8526                	mv	a0,s1
    80002840:	00003097          	auipc	ra,0x3
    80002844:	4ac080e7          	jalr	1196(ra) # 80005cec <plic_complete>
    return 1;
    80002848:	4505                	li	a0,1
    8000284a:	bf55                	j	800027fe <devintr+0x1e>
      uartintr();
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	15c080e7          	jalr	348(ra) # 800009a8 <uartintr>
    80002854:	b7ed                	j	8000283e <devintr+0x5e>
      virtio_disk_intr();
    80002856:	00004097          	auipc	ra,0x4
    8000285a:	976080e7          	jalr	-1674(ra) # 800061cc <virtio_disk_intr>
    8000285e:	b7c5                	j	8000283e <devintr+0x5e>
    if(cpuid() == 0){
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	12c080e7          	jalr	300(ra) # 8000198c <cpuid>
    80002868:	c901                	beqz	a0,80002878 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000286a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002870:	14479073          	csrw	sip,a5
    return 2;
    80002874:	4509                	li	a0,2
    80002876:	b761                	j	800027fe <devintr+0x1e>
      clockintr();
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	f22080e7          	jalr	-222(ra) # 8000279a <clockintr>
    80002880:	b7ed                	j	8000286a <devintr+0x8a>

0000000080002882 <usertrap>:
{
    80002882:	1101                	addi	sp,sp,-32
    80002884:	ec06                	sd	ra,24(sp)
    80002886:	e822                	sd	s0,16(sp)
    80002888:	e426                	sd	s1,8(sp)
    8000288a:	e04a                	sd	s2,0(sp)
    8000288c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002892:	1007f793          	andi	a5,a5,256
    80002896:	e3ad                	bnez	a5,800028f8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002898:	00003797          	auipc	a5,0x3
    8000289c:	32878793          	addi	a5,a5,808 # 80005bc0 <kernelvec>
    800028a0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	114080e7          	jalr	276(ra) # 800019b8 <myproc>
    800028ac:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ae:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b0:	14102773          	csrr	a4,sepc
    800028b4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ba:	47a1                	li	a5,8
    800028bc:	04f71c63          	bne	a4,a5,80002914 <usertrap+0x92>
    if(p->killed)
    800028c0:	551c                	lw	a5,40(a0)
    800028c2:	e3b9                	bnez	a5,80002908 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028c4:	6cb8                	ld	a4,88(s1)
    800028c6:	6f1c                	ld	a5,24(a4)
    800028c8:	0791                	addi	a5,a5,4
    800028ca:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d4:	10079073          	csrw	sstatus,a5
    syscall();
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	2e0080e7          	jalr	736(ra) # 80002bb8 <syscall>
  if(p->killed)
    800028e0:	549c                	lw	a5,40(s1)
    800028e2:	ebc1                	bnez	a5,80002972 <usertrap+0xf0>
  usertrapret();
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	e18080e7          	jalr	-488(ra) # 800026fc <usertrapret>
}
    800028ec:	60e2                	ld	ra,24(sp)
    800028ee:	6442                	ld	s0,16(sp)
    800028f0:	64a2                	ld	s1,8(sp)
    800028f2:	6902                	ld	s2,0(sp)
    800028f4:	6105                	addi	sp,sp,32
    800028f6:	8082                	ret
    panic("usertrap: not from user mode");
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a3850513          	addi	a0,a0,-1480 # 80008330 <states.1726+0x58>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>
      exit(-1);
    80002908:	557d                	li	a0,-1
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	a06080e7          	jalr	-1530(ra) # 80002310 <exit>
    80002912:	bf4d                	j	800028c4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002914:	00000097          	auipc	ra,0x0
    80002918:	ecc080e7          	jalr	-308(ra) # 800027e0 <devintr>
    8000291c:	892a                	mv	s2,a0
    8000291e:	c501                	beqz	a0,80002926 <usertrap+0xa4>
  if(p->killed)
    80002920:	549c                	lw	a5,40(s1)
    80002922:	c3a1                	beqz	a5,80002962 <usertrap+0xe0>
    80002924:	a815                	j	80002958 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002926:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000292a:	5890                	lw	a2,48(s1)
    8000292c:	00006517          	auipc	a0,0x6
    80002930:	a2450513          	addi	a0,a0,-1500 # 80008350 <states.1726+0x78>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	c54080e7          	jalr	-940(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002940:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002944:	00006517          	auipc	a0,0x6
    80002948:	a3c50513          	addi	a0,a0,-1476 # 80008380 <states.1726+0xa8>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	c3c080e7          	jalr	-964(ra) # 80000588 <printf>
    p->killed = 1;
    80002954:	4785                	li	a5,1
    80002956:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002958:	557d                	li	a0,-1
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	9b6080e7          	jalr	-1610(ra) # 80002310 <exit>
  if(which_dev == 2)
    80002962:	4789                	li	a5,2
    80002964:	f8f910e3          	bne	s2,a5,800028e4 <usertrap+0x62>
    yield();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	710080e7          	jalr	1808(ra) # 80002078 <yield>
    80002970:	bf95                	j	800028e4 <usertrap+0x62>
  int which_dev = 0;
    80002972:	4901                	li	s2,0
    80002974:	b7d5                	j	80002958 <usertrap+0xd6>

0000000080002976 <kerneltrap>:
{
    80002976:	7179                	addi	sp,sp,-48
    80002978:	f406                	sd	ra,40(sp)
    8000297a:	f022                	sd	s0,32(sp)
    8000297c:	ec26                	sd	s1,24(sp)
    8000297e:	e84a                	sd	s2,16(sp)
    80002980:	e44e                	sd	s3,8(sp)
    80002982:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002984:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002988:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000298c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002990:	1004f793          	andi	a5,s1,256
    80002994:	cb85                	beqz	a5,800029c4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000299a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000299c:	ef85                	bnez	a5,800029d4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	e42080e7          	jalr	-446(ra) # 800027e0 <devintr>
    800029a6:	cd1d                	beqz	a0,800029e4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a8:	4789                	li	a5,2
    800029aa:	06f50a63          	beq	a0,a5,80002a1e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ae:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b2:	10049073          	csrw	sstatus,s1
}
    800029b6:	70a2                	ld	ra,40(sp)
    800029b8:	7402                	ld	s0,32(sp)
    800029ba:	64e2                	ld	s1,24(sp)
    800029bc:	6942                	ld	s2,16(sp)
    800029be:	69a2                	ld	s3,8(sp)
    800029c0:	6145                	addi	sp,sp,48
    800029c2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	9dc50513          	addi	a0,a0,-1572 # 800083a0 <states.1726+0xc8>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	b72080e7          	jalr	-1166(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9f450513          	addi	a0,a0,-1548 # 800083c8 <states.1726+0xf0>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b62080e7          	jalr	-1182(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029e4:	85ce                	mv	a1,s3
    800029e6:	00006517          	auipc	a0,0x6
    800029ea:	a0250513          	addi	a0,a0,-1534 # 800083e8 <states.1726+0x110>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b9a080e7          	jalr	-1126(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029fa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	9fa50513          	addi	a0,a0,-1542 # 800083f8 <states.1726+0x120>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b82080e7          	jalr	-1150(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	a0250513          	addi	a0,a0,-1534 # 80008410 <states.1726+0x138>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	f9a080e7          	jalr	-102(ra) # 800019b8 <myproc>
    80002a26:	d541                	beqz	a0,800029ae <kerneltrap+0x38>
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	f90080e7          	jalr	-112(ra) # 800019b8 <myproc>
    80002a30:	4d18                	lw	a4,24(a0)
    80002a32:	4791                	li	a5,4
    80002a34:	f6f71de3          	bne	a4,a5,800029ae <kerneltrap+0x38>
    yield();
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	640080e7          	jalr	1600(ra) # 80002078 <yield>
    80002a40:	b7bd                	j	800029ae <kerneltrap+0x38>

0000000080002a42 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	e426                	sd	s1,8(sp)
    80002a4a:	1000                	addi	s0,sp,32
    80002a4c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	f6a080e7          	jalr	-150(ra) # 800019b8 <myproc>
  switch (n) {
    80002a56:	4795                	li	a5,5
    80002a58:	0497e163          	bltu	a5,s1,80002a9a <argraw+0x58>
    80002a5c:	048a                	slli	s1,s1,0x2
    80002a5e:	00006717          	auipc	a4,0x6
    80002a62:	9ea70713          	addi	a4,a4,-1558 # 80008448 <states.1726+0x170>
    80002a66:	94ba                	add	s1,s1,a4
    80002a68:	409c                	lw	a5,0(s1)
    80002a6a:	97ba                	add	a5,a5,a4
    80002a6c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a6e:	6d3c                	ld	a5,88(a0)
    80002a70:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a72:	60e2                	ld	ra,24(sp)
    80002a74:	6442                	ld	s0,16(sp)
    80002a76:	64a2                	ld	s1,8(sp)
    80002a78:	6105                	addi	sp,sp,32
    80002a7a:	8082                	ret
    return p->trapframe->a1;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	7fa8                	ld	a0,120(a5)
    80002a80:	bfcd                	j	80002a72 <argraw+0x30>
    return p->trapframe->a2;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	63c8                	ld	a0,128(a5)
    80002a86:	b7f5                	j	80002a72 <argraw+0x30>
    return p->trapframe->a3;
    80002a88:	6d3c                	ld	a5,88(a0)
    80002a8a:	67c8                	ld	a0,136(a5)
    80002a8c:	b7dd                	j	80002a72 <argraw+0x30>
    return p->trapframe->a4;
    80002a8e:	6d3c                	ld	a5,88(a0)
    80002a90:	6bc8                	ld	a0,144(a5)
    80002a92:	b7c5                	j	80002a72 <argraw+0x30>
    return p->trapframe->a5;
    80002a94:	6d3c                	ld	a5,88(a0)
    80002a96:	6fc8                	ld	a0,152(a5)
    80002a98:	bfe9                	j	80002a72 <argraw+0x30>
  panic("argraw");
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	98650513          	addi	a0,a0,-1658 # 80008420 <states.1726+0x148>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	a9c080e7          	jalr	-1380(ra) # 8000053e <panic>

0000000080002aaa <fetchaddr>:
{
    80002aaa:	1101                	addi	sp,sp,-32
    80002aac:	ec06                	sd	ra,24(sp)
    80002aae:	e822                	sd	s0,16(sp)
    80002ab0:	e426                	sd	s1,8(sp)
    80002ab2:	e04a                	sd	s2,0(sp)
    80002ab4:	1000                	addi	s0,sp,32
    80002ab6:	84aa                	mv	s1,a0
    80002ab8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	efe080e7          	jalr	-258(ra) # 800019b8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ac2:	653c                	ld	a5,72(a0)
    80002ac4:	02f4f863          	bgeu	s1,a5,80002af4 <fetchaddr+0x4a>
    80002ac8:	00848713          	addi	a4,s1,8
    80002acc:	02e7e663          	bltu	a5,a4,80002af8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ad0:	46a1                	li	a3,8
    80002ad2:	8626                	mv	a2,s1
    80002ad4:	85ca                	mv	a1,s2
    80002ad6:	6928                	ld	a0,80(a0)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	c2e080e7          	jalr	-978(ra) # 80001706 <copyin>
    80002ae0:	00a03533          	snez	a0,a0
    80002ae4:	40a00533          	neg	a0,a0
}
    80002ae8:	60e2                	ld	ra,24(sp)
    80002aea:	6442                	ld	s0,16(sp)
    80002aec:	64a2                	ld	s1,8(sp)
    80002aee:	6902                	ld	s2,0(sp)
    80002af0:	6105                	addi	sp,sp,32
    80002af2:	8082                	ret
    return -1;
    80002af4:	557d                	li	a0,-1
    80002af6:	bfcd                	j	80002ae8 <fetchaddr+0x3e>
    80002af8:	557d                	li	a0,-1
    80002afa:	b7fd                	j	80002ae8 <fetchaddr+0x3e>

0000000080002afc <fetchstr>:
{
    80002afc:	7179                	addi	sp,sp,-48
    80002afe:	f406                	sd	ra,40(sp)
    80002b00:	f022                	sd	s0,32(sp)
    80002b02:	ec26                	sd	s1,24(sp)
    80002b04:	e84a                	sd	s2,16(sp)
    80002b06:	e44e                	sd	s3,8(sp)
    80002b08:	1800                	addi	s0,sp,48
    80002b0a:	892a                	mv	s2,a0
    80002b0c:	84ae                	mv	s1,a1
    80002b0e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b10:	fffff097          	auipc	ra,0xfffff
    80002b14:	ea8080e7          	jalr	-344(ra) # 800019b8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b18:	86ce                	mv	a3,s3
    80002b1a:	864a                	mv	a2,s2
    80002b1c:	85a6                	mv	a1,s1
    80002b1e:	6928                	ld	a0,80(a0)
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	c72080e7          	jalr	-910(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002b28:	00054763          	bltz	a0,80002b36 <fetchstr+0x3a>
  return strlen(buf);
    80002b2c:	8526                	mv	a0,s1
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	336080e7          	jalr	822(ra) # 80000e64 <strlen>
}
    80002b36:	70a2                	ld	ra,40(sp)
    80002b38:	7402                	ld	s0,32(sp)
    80002b3a:	64e2                	ld	s1,24(sp)
    80002b3c:	6942                	ld	s2,16(sp)
    80002b3e:	69a2                	ld	s3,8(sp)
    80002b40:	6145                	addi	sp,sp,48
    80002b42:	8082                	ret

0000000080002b44 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	1000                	addi	s0,sp,32
    80002b4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	ef2080e7          	jalr	-270(ra) # 80002a42 <argraw>
    80002b58:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b5a:	4501                	li	a0,0
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	64a2                	ld	s1,8(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret

0000000080002b66 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b66:	1101                	addi	sp,sp,-32
    80002b68:	ec06                	sd	ra,24(sp)
    80002b6a:	e822                	sd	s0,16(sp)
    80002b6c:	e426                	sd	s1,8(sp)
    80002b6e:	1000                	addi	s0,sp,32
    80002b70:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	ed0080e7          	jalr	-304(ra) # 80002a42 <argraw>
    80002b7a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b7c:	4501                	li	a0,0
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b88:	1101                	addi	sp,sp,-32
    80002b8a:	ec06                	sd	ra,24(sp)
    80002b8c:	e822                	sd	s0,16(sp)
    80002b8e:	e426                	sd	s1,8(sp)
    80002b90:	e04a                	sd	s2,0(sp)
    80002b92:	1000                	addi	s0,sp,32
    80002b94:	84ae                	mv	s1,a1
    80002b96:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	eaa080e7          	jalr	-342(ra) # 80002a42 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ba0:	864a                	mv	a2,s2
    80002ba2:	85a6                	mv	a1,s1
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	f58080e7          	jalr	-168(ra) # 80002afc <fetchstr>
}
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	64a2                	ld	s1,8(sp)
    80002bb2:	6902                	ld	s2,0(sp)
    80002bb4:	6105                	addi	sp,sp,32
    80002bb6:	8082                	ret

0000000080002bb8 <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002bb8:	1101                	addi	sp,sp,-32
    80002bba:	ec06                	sd	ra,24(sp)
    80002bbc:	e822                	sd	s0,16(sp)
    80002bbe:	e426                	sd	s1,8(sp)
    80002bc0:	e04a                	sd	s2,0(sp)
    80002bc2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bc4:	fffff097          	auipc	ra,0xfffff
    80002bc8:	df4080e7          	jalr	-524(ra) # 800019b8 <myproc>
    80002bcc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bce:	05853903          	ld	s2,88(a0)
    80002bd2:	0a893783          	ld	a5,168(s2)
    80002bd6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bda:	37fd                	addiw	a5,a5,-1
    80002bdc:	4759                	li	a4,22
    80002bde:	00f76f63          	bltu	a4,a5,80002bfc <syscall+0x44>
    80002be2:	00369713          	slli	a4,a3,0x3
    80002be6:	00006797          	auipc	a5,0x6
    80002bea:	87a78793          	addi	a5,a5,-1926 # 80008460 <syscalls>
    80002bee:	97ba                	add	a5,a5,a4
    80002bf0:	639c                	ld	a5,0(a5)
    80002bf2:	c789                	beqz	a5,80002bfc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bf4:	9782                	jalr	a5
    80002bf6:	06a93823          	sd	a0,112(s2)
    80002bfa:	a839                	j	80002c18 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bfc:	15848613          	addi	a2,s1,344
    80002c00:	588c                	lw	a1,48(s1)
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	82650513          	addi	a0,a0,-2010 # 80008428 <states.1726+0x150>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97e080e7          	jalr	-1666(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c12:	6cbc                	ld	a5,88(s1)
    80002c14:	577d                	li	a4,-1
    80002c16:	fbb8                	sd	a4,112(a5)
  }
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c2c:	fec40593          	addi	a1,s0,-20
    80002c30:	4501                	li	a0,0
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	f12080e7          	jalr	-238(ra) # 80002b44 <argint>
    return -1;
    80002c3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c3c:	00054963          	bltz	a0,80002c4e <sys_exit+0x2a>
  exit(n);
    80002c40:	fec42503          	lw	a0,-20(s0)
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	6cc080e7          	jalr	1740(ra) # 80002310 <exit>
  return 0;  // not reached
    80002c4c:	4781                	li	a5,0
}
    80002c4e:	853e                	mv	a0,a5
    80002c50:	60e2                	ld	ra,24(sp)
    80002c52:	6442                	ld	s0,16(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c58:	1141                	addi	sp,sp,-16
    80002c5a:	e406                	sd	ra,8(sp)
    80002c5c:	e022                	sd	s0,0(sp)
    80002c5e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d58080e7          	jalr	-680(ra) # 800019b8 <myproc>
}
    80002c68:	5908                	lw	a0,48(a0)
    80002c6a:	60a2                	ld	ra,8(sp)
    80002c6c:	6402                	ld	s0,0(sp)
    80002c6e:	0141                	addi	sp,sp,16
    80002c70:	8082                	ret

0000000080002c72 <sys_fork>:

uint64
sys_fork(void)
{
    80002c72:	1141                	addi	sp,sp,-16
    80002c74:	e406                	sd	ra,8(sp)
    80002c76:	e022                	sd	s0,0(sp)
    80002c78:	0800                	addi	s0,sp,16
  return fork();
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	10c080e7          	jalr	268(ra) # 80001d86 <fork>
}
    80002c82:	60a2                	ld	ra,8(sp)
    80002c84:	6402                	ld	s0,0(sp)
    80002c86:	0141                	addi	sp,sp,16
    80002c88:	8082                	ret

0000000080002c8a <sys_wait>:

uint64
sys_wait(void)
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c92:	fe840593          	addi	a1,s0,-24
    80002c96:	4501                	li	a0,0
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	ece080e7          	jalr	-306(ra) # 80002b66 <argaddr>
    80002ca0:	87aa                	mv	a5,a0
    return -1;
    80002ca2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ca4:	0007c863          	bltz	a5,80002cb4 <sys_wait+0x2a>
  return wait(p);
    80002ca8:	fe843503          	ld	a0,-24(s0)
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	46c080e7          	jalr	1132(ra) # 80002118 <wait>
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	6105                	addi	sp,sp,32
    80002cba:	8082                	ret

0000000080002cbc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cbc:	7179                	addi	sp,sp,-48
    80002cbe:	f406                	sd	ra,40(sp)
    80002cc0:	f022                	sd	s0,32(sp)
    80002cc2:	ec26                	sd	s1,24(sp)
    80002cc4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cc6:	fdc40593          	addi	a1,s0,-36
    80002cca:	4501                	li	a0,0
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	e78080e7          	jalr	-392(ra) # 80002b44 <argint>
    80002cd4:	87aa                	mv	a5,a0
    return -1;
    80002cd6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cd8:	0207c063          	bltz	a5,80002cf8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	cdc080e7          	jalr	-804(ra) # 800019b8 <myproc>
    80002ce4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ce6:	fdc42503          	lw	a0,-36(s0)
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	028080e7          	jalr	40(ra) # 80001d12 <growproc>
    80002cf2:	00054863          	bltz	a0,80002d02 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cf6:	8526                	mv	a0,s1
}
    80002cf8:	70a2                	ld	ra,40(sp)
    80002cfa:	7402                	ld	s0,32(sp)
    80002cfc:	64e2                	ld	s1,24(sp)
    80002cfe:	6145                	addi	sp,sp,48
    80002d00:	8082                	ret
    return -1;
    80002d02:	557d                	li	a0,-1
    80002d04:	bfd5                	j	80002cf8 <sys_sbrk+0x3c>

0000000080002d06 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d06:	7139                	addi	sp,sp,-64
    80002d08:	fc06                	sd	ra,56(sp)
    80002d0a:	f822                	sd	s0,48(sp)
    80002d0c:	f426                	sd	s1,40(sp)
    80002d0e:	f04a                	sd	s2,32(sp)
    80002d10:	ec4e                	sd	s3,24(sp)
    80002d12:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d14:	fcc40593          	addi	a1,s0,-52
    80002d18:	4501                	li	a0,0
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	e2a080e7          	jalr	-470(ra) # 80002b44 <argint>
    return -1;
    80002d22:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d24:	06054563          	bltz	a0,80002d8e <sys_sleep+0x88>
  acquire(&tickslock);
    80002d28:	00014517          	auipc	a0,0x14
    80002d2c:	3a850513          	addi	a0,a0,936 # 800170d0 <tickslock>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	eb4080e7          	jalr	-332(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d38:	00006917          	auipc	s2,0x6
    80002d3c:	30092903          	lw	s2,768(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002d40:	fcc42783          	lw	a5,-52(s0)
    80002d44:	cf85                	beqz	a5,80002d7c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d46:	00014997          	auipc	s3,0x14
    80002d4a:	38a98993          	addi	s3,s3,906 # 800170d0 <tickslock>
    80002d4e:	00006497          	auipc	s1,0x6
    80002d52:	2ea48493          	addi	s1,s1,746 # 80009038 <ticks>
    if(myproc()->killed){
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	c62080e7          	jalr	-926(ra) # 800019b8 <myproc>
    80002d5e:	551c                	lw	a5,40(a0)
    80002d60:	ef9d                	bnez	a5,80002d9e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d62:	85ce                	mv	a1,s3
    80002d64:	8526                	mv	a0,s1
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	34e080e7          	jalr	846(ra) # 800020b4 <sleep>
  while(ticks - ticks0 < n){
    80002d6e:	409c                	lw	a5,0(s1)
    80002d70:	412787bb          	subw	a5,a5,s2
    80002d74:	fcc42703          	lw	a4,-52(s0)
    80002d78:	fce7efe3          	bltu	a5,a4,80002d56 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d7c:	00014517          	auipc	a0,0x14
    80002d80:	35450513          	addi	a0,a0,852 # 800170d0 <tickslock>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	f14080e7          	jalr	-236(ra) # 80000c98 <release>
  return 0;
    80002d8c:	4781                	li	a5,0
}
    80002d8e:	853e                	mv	a0,a5
    80002d90:	70e2                	ld	ra,56(sp)
    80002d92:	7442                	ld	s0,48(sp)
    80002d94:	74a2                	ld	s1,40(sp)
    80002d96:	7902                	ld	s2,32(sp)
    80002d98:	69e2                	ld	s3,24(sp)
    80002d9a:	6121                	addi	sp,sp,64
    80002d9c:	8082                	ret
      release(&tickslock);
    80002d9e:	00014517          	auipc	a0,0x14
    80002da2:	33250513          	addi	a0,a0,818 # 800170d0 <tickslock>
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	ef2080e7          	jalr	-270(ra) # 80000c98 <release>
      return -1;
    80002dae:	57fd                	li	a5,-1
    80002db0:	bff9                	j	80002d8e <sys_sleep+0x88>

0000000080002db2 <sys_kill>:

uint64
sys_kill(void)
{
    80002db2:	1101                	addi	sp,sp,-32
    80002db4:	ec06                	sd	ra,24(sp)
    80002db6:	e822                	sd	s0,16(sp)
    80002db8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dba:	fec40593          	addi	a1,s0,-20
    80002dbe:	4501                	li	a0,0
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	d84080e7          	jalr	-636(ra) # 80002b44 <argint>
    80002dc8:	87aa                	mv	a5,a0
    return -1;
    80002dca:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dcc:	0007c863          	bltz	a5,80002ddc <sys_kill+0x2a>
  return kill(pid);
    80002dd0:	fec42503          	lw	a0,-20(s0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	612080e7          	jalr	1554(ra) # 800023e6 <kill>
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret

0000000080002de4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	e426                	sd	s1,8(sp)
    80002dec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dee:	00014517          	auipc	a0,0x14
    80002df2:	2e250513          	addi	a0,a0,738 # 800170d0 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	dee080e7          	jalr	-530(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002dfe:	00006497          	auipc	s1,0x6
    80002e02:	23a4a483          	lw	s1,570(s1) # 80009038 <ticks>
  release(&tickslock);
    80002e06:	00014517          	auipc	a0,0x14
    80002e0a:	2ca50513          	addi	a0,a0,714 # 800170d0 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e8a080e7          	jalr	-374(ra) # 80000c98 <release>
  return xticks;
}
    80002e16:	02049513          	slli	a0,s1,0x20
    80002e1a:	9101                	srli	a0,a0,0x20
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    80002e2e:	fec40593          	addi	a1,s0,-20
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	d10080e7          	jalr	-752(ra) # 80002b44 <argint>
    80002e3c:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    80002e3e:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    80002e40:	0007d663          	bgez	a5,80002e4c <sys_pause_system+0x26>
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret
    return pause_system(seconds);
    80002e4c:	fec42503          	lw	a0,-20(s0)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	762080e7          	jalr	1890(ra) # 800025b2 <pause_system>
    80002e58:	b7f5                	j	80002e44 <sys_pause_system+0x1e>

0000000080002e5a <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002e5a:	1141                	addi	sp,sp,-16
    80002e5c:	e406                	sd	ra,8(sp)
    80002e5e:	e022                	sd	s0,0(sp)
    80002e60:	0800                	addi	s0,sp,16
  return kill_system();
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	786080e7          	jalr	1926(ra) # 800025e8 <kill_system>
    80002e6a:	60a2                	ld	ra,8(sp)
    80002e6c:	6402                	ld	s0,0(sp)
    80002e6e:	0141                	addi	sp,sp,16
    80002e70:	8082                	ret

0000000080002e72 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e72:	7179                	addi	sp,sp,-48
    80002e74:	f406                	sd	ra,40(sp)
    80002e76:	f022                	sd	s0,32(sp)
    80002e78:	ec26                	sd	s1,24(sp)
    80002e7a:	e84a                	sd	s2,16(sp)
    80002e7c:	e44e                	sd	s3,8(sp)
    80002e7e:	e052                	sd	s4,0(sp)
    80002e80:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e82:	00005597          	auipc	a1,0x5
    80002e86:	69e58593          	addi	a1,a1,1694 # 80008520 <syscalls+0xc0>
    80002e8a:	00014517          	auipc	a0,0x14
    80002e8e:	25e50513          	addi	a0,a0,606 # 800170e8 <bcache>
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	cc2080e7          	jalr	-830(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e9a:	0001c797          	auipc	a5,0x1c
    80002e9e:	24e78793          	addi	a5,a5,590 # 8001f0e8 <bcache+0x8000>
    80002ea2:	0001c717          	auipc	a4,0x1c
    80002ea6:	4ae70713          	addi	a4,a4,1198 # 8001f350 <bcache+0x8268>
    80002eaa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eae:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb2:	00014497          	auipc	s1,0x14
    80002eb6:	24e48493          	addi	s1,s1,590 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002eba:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ebc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ebe:	00005a17          	auipc	s4,0x5
    80002ec2:	66aa0a13          	addi	s4,s4,1642 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ec6:	2b893783          	ld	a5,696(s2)
    80002eca:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ecc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ed0:	85d2                	mv	a1,s4
    80002ed2:	01048513          	addi	a0,s1,16
    80002ed6:	00001097          	auipc	ra,0x1
    80002eda:	4bc080e7          	jalr	1212(ra) # 80004392 <initsleeplock>
    bcache.head.next->prev = b;
    80002ede:	2b893783          	ld	a5,696(s2)
    80002ee2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ee4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee8:	45848493          	addi	s1,s1,1112
    80002eec:	fd349de3          	bne	s1,s3,80002ec6 <binit+0x54>
  }
}
    80002ef0:	70a2                	ld	ra,40(sp)
    80002ef2:	7402                	ld	s0,32(sp)
    80002ef4:	64e2                	ld	s1,24(sp)
    80002ef6:	6942                	ld	s2,16(sp)
    80002ef8:	69a2                	ld	s3,8(sp)
    80002efa:	6a02                	ld	s4,0(sp)
    80002efc:	6145                	addi	sp,sp,48
    80002efe:	8082                	ret

0000000080002f00 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f00:	7179                	addi	sp,sp,-48
    80002f02:	f406                	sd	ra,40(sp)
    80002f04:	f022                	sd	s0,32(sp)
    80002f06:	ec26                	sd	s1,24(sp)
    80002f08:	e84a                	sd	s2,16(sp)
    80002f0a:	e44e                	sd	s3,8(sp)
    80002f0c:	1800                	addi	s0,sp,48
    80002f0e:	89aa                	mv	s3,a0
    80002f10:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f12:	00014517          	auipc	a0,0x14
    80002f16:	1d650513          	addi	a0,a0,470 # 800170e8 <bcache>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	cca080e7          	jalr	-822(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f22:	0001c497          	auipc	s1,0x1c
    80002f26:	47e4b483          	ld	s1,1150(s1) # 8001f3a0 <bcache+0x82b8>
    80002f2a:	0001c797          	auipc	a5,0x1c
    80002f2e:	42678793          	addi	a5,a5,1062 # 8001f350 <bcache+0x8268>
    80002f32:	02f48f63          	beq	s1,a5,80002f70 <bread+0x70>
    80002f36:	873e                	mv	a4,a5
    80002f38:	a021                	j	80002f40 <bread+0x40>
    80002f3a:	68a4                	ld	s1,80(s1)
    80002f3c:	02e48a63          	beq	s1,a4,80002f70 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f40:	449c                	lw	a5,8(s1)
    80002f42:	ff379ce3          	bne	a5,s3,80002f3a <bread+0x3a>
    80002f46:	44dc                	lw	a5,12(s1)
    80002f48:	ff2799e3          	bne	a5,s2,80002f3a <bread+0x3a>
      b->refcnt++;
    80002f4c:	40bc                	lw	a5,64(s1)
    80002f4e:	2785                	addiw	a5,a5,1
    80002f50:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f52:	00014517          	auipc	a0,0x14
    80002f56:	19650513          	addi	a0,a0,406 # 800170e8 <bcache>
    80002f5a:	ffffe097          	auipc	ra,0xffffe
    80002f5e:	d3e080e7          	jalr	-706(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f62:	01048513          	addi	a0,s1,16
    80002f66:	00001097          	auipc	ra,0x1
    80002f6a:	466080e7          	jalr	1126(ra) # 800043cc <acquiresleep>
      return b;
    80002f6e:	a8b9                	j	80002fcc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f70:	0001c497          	auipc	s1,0x1c
    80002f74:	4284b483          	ld	s1,1064(s1) # 8001f398 <bcache+0x82b0>
    80002f78:	0001c797          	auipc	a5,0x1c
    80002f7c:	3d878793          	addi	a5,a5,984 # 8001f350 <bcache+0x8268>
    80002f80:	00f48863          	beq	s1,a5,80002f90 <bread+0x90>
    80002f84:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f86:	40bc                	lw	a5,64(s1)
    80002f88:	cf81                	beqz	a5,80002fa0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f8a:	64a4                	ld	s1,72(s1)
    80002f8c:	fee49de3          	bne	s1,a4,80002f86 <bread+0x86>
  panic("bget: no buffers");
    80002f90:	00005517          	auipc	a0,0x5
    80002f94:	5a050513          	addi	a0,a0,1440 # 80008530 <syscalls+0xd0>
    80002f98:	ffffd097          	auipc	ra,0xffffd
    80002f9c:	5a6080e7          	jalr	1446(ra) # 8000053e <panic>
      b->dev = dev;
    80002fa0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fa4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fa8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fac:	4785                	li	a5,1
    80002fae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb0:	00014517          	auipc	a0,0x14
    80002fb4:	13850513          	addi	a0,a0,312 # 800170e8 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fc0:	01048513          	addi	a0,s1,16
    80002fc4:	00001097          	auipc	ra,0x1
    80002fc8:	408080e7          	jalr	1032(ra) # 800043cc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fcc:	409c                	lw	a5,0(s1)
    80002fce:	cb89                	beqz	a5,80002fe0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fd0:	8526                	mv	a0,s1
    80002fd2:	70a2                	ld	ra,40(sp)
    80002fd4:	7402                	ld	s0,32(sp)
    80002fd6:	64e2                	ld	s1,24(sp)
    80002fd8:	6942                	ld	s2,16(sp)
    80002fda:	69a2                	ld	s3,8(sp)
    80002fdc:	6145                	addi	sp,sp,48
    80002fde:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fe0:	4581                	li	a1,0
    80002fe2:	8526                	mv	a0,s1
    80002fe4:	00003097          	auipc	ra,0x3
    80002fe8:	f12080e7          	jalr	-238(ra) # 80005ef6 <virtio_disk_rw>
    b->valid = 1;
    80002fec:	4785                	li	a5,1
    80002fee:	c09c                	sw	a5,0(s1)
  return b;
    80002ff0:	b7c5                	j	80002fd0 <bread+0xd0>

0000000080002ff2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ff2:	1101                	addi	sp,sp,-32
    80002ff4:	ec06                	sd	ra,24(sp)
    80002ff6:	e822                	sd	s0,16(sp)
    80002ff8:	e426                	sd	s1,8(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ffe:	0541                	addi	a0,a0,16
    80003000:	00001097          	auipc	ra,0x1
    80003004:	466080e7          	jalr	1126(ra) # 80004466 <holdingsleep>
    80003008:	cd01                	beqz	a0,80003020 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000300a:	4585                	li	a1,1
    8000300c:	8526                	mv	a0,s1
    8000300e:	00003097          	auipc	ra,0x3
    80003012:	ee8080e7          	jalr	-280(ra) # 80005ef6 <virtio_disk_rw>
}
    80003016:	60e2                	ld	ra,24(sp)
    80003018:	6442                	ld	s0,16(sp)
    8000301a:	64a2                	ld	s1,8(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret
    panic("bwrite");
    80003020:	00005517          	auipc	a0,0x5
    80003024:	52850513          	addi	a0,a0,1320 # 80008548 <syscalls+0xe8>
    80003028:	ffffd097          	auipc	ra,0xffffd
    8000302c:	516080e7          	jalr	1302(ra) # 8000053e <panic>

0000000080003030 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	e426                	sd	s1,8(sp)
    80003038:	e04a                	sd	s2,0(sp)
    8000303a:	1000                	addi	s0,sp,32
    8000303c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303e:	01050913          	addi	s2,a0,16
    80003042:	854a                	mv	a0,s2
    80003044:	00001097          	auipc	ra,0x1
    80003048:	422080e7          	jalr	1058(ra) # 80004466 <holdingsleep>
    8000304c:	c92d                	beqz	a0,800030be <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000304e:	854a                	mv	a0,s2
    80003050:	00001097          	auipc	ra,0x1
    80003054:	3d2080e7          	jalr	978(ra) # 80004422 <releasesleep>

  acquire(&bcache.lock);
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	09050513          	addi	a0,a0,144 # 800170e8 <bcache>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	b84080e7          	jalr	-1148(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003068:	40bc                	lw	a5,64(s1)
    8000306a:	37fd                	addiw	a5,a5,-1
    8000306c:	0007871b          	sext.w	a4,a5
    80003070:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003072:	eb05                	bnez	a4,800030a2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003074:	68bc                	ld	a5,80(s1)
    80003076:	64b8                	ld	a4,72(s1)
    80003078:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000307a:	64bc                	ld	a5,72(s1)
    8000307c:	68b8                	ld	a4,80(s1)
    8000307e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003080:	0001c797          	auipc	a5,0x1c
    80003084:	06878793          	addi	a5,a5,104 # 8001f0e8 <bcache+0x8000>
    80003088:	2b87b703          	ld	a4,696(a5)
    8000308c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000308e:	0001c717          	auipc	a4,0x1c
    80003092:	2c270713          	addi	a4,a4,706 # 8001f350 <bcache+0x8268>
    80003096:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003098:	2b87b703          	ld	a4,696(a5)
    8000309c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000309e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030a2:	00014517          	auipc	a0,0x14
    800030a6:	04650513          	addi	a0,a0,70 # 800170e8 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	bee080e7          	jalr	-1042(ra) # 80000c98 <release>
}
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6902                	ld	s2,0(sp)
    800030ba:	6105                	addi	sp,sp,32
    800030bc:	8082                	ret
    panic("brelse");
    800030be:	00005517          	auipc	a0,0x5
    800030c2:	49250513          	addi	a0,a0,1170 # 80008550 <syscalls+0xf0>
    800030c6:	ffffd097          	auipc	ra,0xffffd
    800030ca:	478080e7          	jalr	1144(ra) # 8000053e <panic>

00000000800030ce <bpin>:

void
bpin(struct buf *b) {
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030da:	00014517          	auipc	a0,0x14
    800030de:	00e50513          	addi	a0,a0,14 # 800170e8 <bcache>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	b02080e7          	jalr	-1278(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030ea:	40bc                	lw	a5,64(s1)
    800030ec:	2785                	addiw	a5,a5,1
    800030ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f0:	00014517          	auipc	a0,0x14
    800030f4:	ff850513          	addi	a0,a0,-8 # 800170e8 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
}
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	64a2                	ld	s1,8(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <bunpin>:

void
bunpin(struct buf *b) {
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	e426                	sd	s1,8(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003116:	00014517          	auipc	a0,0x14
    8000311a:	fd250513          	addi	a0,a0,-46 # 800170e8 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	ac6080e7          	jalr	-1338(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003126:	40bc                	lw	a5,64(s1)
    80003128:	37fd                	addiw	a5,a5,-1
    8000312a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312c:	00014517          	auipc	a0,0x14
    80003130:	fbc50513          	addi	a0,a0,-68 # 800170e8 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	b64080e7          	jalr	-1180(ra) # 80000c98 <release>
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6105                	addi	sp,sp,32
    80003144:	8082                	ret

0000000080003146 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003154:	00d5d59b          	srliw	a1,a1,0xd
    80003158:	0001c797          	auipc	a5,0x1c
    8000315c:	66c7a783          	lw	a5,1644(a5) # 8001f7c4 <sb+0x1c>
    80003160:	9dbd                	addw	a1,a1,a5
    80003162:	00000097          	auipc	ra,0x0
    80003166:	d9e080e7          	jalr	-610(ra) # 80002f00 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000316a:	0074f713          	andi	a4,s1,7
    8000316e:	4785                	li	a5,1
    80003170:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003174:	14ce                	slli	s1,s1,0x33
    80003176:	90d9                	srli	s1,s1,0x36
    80003178:	00950733          	add	a4,a0,s1
    8000317c:	05874703          	lbu	a4,88(a4)
    80003180:	00e7f6b3          	and	a3,a5,a4
    80003184:	c69d                	beqz	a3,800031b2 <bfree+0x6c>
    80003186:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003188:	94aa                	add	s1,s1,a0
    8000318a:	fff7c793          	not	a5,a5
    8000318e:	8ff9                	and	a5,a5,a4
    80003190:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003194:	00001097          	auipc	ra,0x1
    80003198:	118080e7          	jalr	280(ra) # 800042ac <log_write>
  brelse(bp);
    8000319c:	854a                	mv	a0,s2
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	e92080e7          	jalr	-366(ra) # 80003030 <brelse>
}
    800031a6:	60e2                	ld	ra,24(sp)
    800031a8:	6442                	ld	s0,16(sp)
    800031aa:	64a2                	ld	s1,8(sp)
    800031ac:	6902                	ld	s2,0(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret
    panic("freeing free block");
    800031b2:	00005517          	auipc	a0,0x5
    800031b6:	3a650513          	addi	a0,a0,934 # 80008558 <syscalls+0xf8>
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	384080e7          	jalr	900(ra) # 8000053e <panic>

00000000800031c2 <balloc>:
{
    800031c2:	711d                	addi	sp,sp,-96
    800031c4:	ec86                	sd	ra,88(sp)
    800031c6:	e8a2                	sd	s0,80(sp)
    800031c8:	e4a6                	sd	s1,72(sp)
    800031ca:	e0ca                	sd	s2,64(sp)
    800031cc:	fc4e                	sd	s3,56(sp)
    800031ce:	f852                	sd	s4,48(sp)
    800031d0:	f456                	sd	s5,40(sp)
    800031d2:	f05a                	sd	s6,32(sp)
    800031d4:	ec5e                	sd	s7,24(sp)
    800031d6:	e862                	sd	s8,16(sp)
    800031d8:	e466                	sd	s9,8(sp)
    800031da:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031dc:	0001c797          	auipc	a5,0x1c
    800031e0:	5d07a783          	lw	a5,1488(a5) # 8001f7ac <sb+0x4>
    800031e4:	cbd1                	beqz	a5,80003278 <balloc+0xb6>
    800031e6:	8baa                	mv	s7,a0
    800031e8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031ea:	0001cb17          	auipc	s6,0x1c
    800031ee:	5beb0b13          	addi	s6,s6,1470 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031f4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f8:	6c89                	lui	s9,0x2
    800031fa:	a831                	j	80003216 <balloc+0x54>
    brelse(bp);
    800031fc:	854a                	mv	a0,s2
    800031fe:	00000097          	auipc	ra,0x0
    80003202:	e32080e7          	jalr	-462(ra) # 80003030 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003206:	015c87bb          	addw	a5,s9,s5
    8000320a:	00078a9b          	sext.w	s5,a5
    8000320e:	004b2703          	lw	a4,4(s6)
    80003212:	06eaf363          	bgeu	s5,a4,80003278 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003216:	41fad79b          	sraiw	a5,s5,0x1f
    8000321a:	0137d79b          	srliw	a5,a5,0x13
    8000321e:	015787bb          	addw	a5,a5,s5
    80003222:	40d7d79b          	sraiw	a5,a5,0xd
    80003226:	01cb2583          	lw	a1,28(s6)
    8000322a:	9dbd                	addw	a1,a1,a5
    8000322c:	855e                	mv	a0,s7
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	cd2080e7          	jalr	-814(ra) # 80002f00 <bread>
    80003236:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003238:	004b2503          	lw	a0,4(s6)
    8000323c:	000a849b          	sext.w	s1,s5
    80003240:	8662                	mv	a2,s8
    80003242:	faa4fde3          	bgeu	s1,a0,800031fc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003246:	41f6579b          	sraiw	a5,a2,0x1f
    8000324a:	01d7d69b          	srliw	a3,a5,0x1d
    8000324e:	00c6873b          	addw	a4,a3,a2
    80003252:	00777793          	andi	a5,a4,7
    80003256:	9f95                	subw	a5,a5,a3
    80003258:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000325c:	4037571b          	sraiw	a4,a4,0x3
    80003260:	00e906b3          	add	a3,s2,a4
    80003264:	0586c683          	lbu	a3,88(a3)
    80003268:	00d7f5b3          	and	a1,a5,a3
    8000326c:	cd91                	beqz	a1,80003288 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326e:	2605                	addiw	a2,a2,1
    80003270:	2485                	addiw	s1,s1,1
    80003272:	fd4618e3          	bne	a2,s4,80003242 <balloc+0x80>
    80003276:	b759                	j	800031fc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	2f850513          	addi	a0,a0,760 # 80008570 <syscalls+0x110>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	2be080e7          	jalr	702(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003288:	974a                	add	a4,a4,s2
    8000328a:	8fd5                	or	a5,a5,a3
    8000328c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00001097          	auipc	ra,0x1
    80003296:	01a080e7          	jalr	26(ra) # 800042ac <log_write>
        brelse(bp);
    8000329a:	854a                	mv	a0,s2
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	d94080e7          	jalr	-620(ra) # 80003030 <brelse>
  bp = bread(dev, bno);
    800032a4:	85a6                	mv	a1,s1
    800032a6:	855e                	mv	a0,s7
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	c58080e7          	jalr	-936(ra) # 80002f00 <bread>
    800032b0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032b2:	40000613          	li	a2,1024
    800032b6:	4581                	li	a1,0
    800032b8:	05850513          	addi	a0,a0,88
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	a24080e7          	jalr	-1500(ra) # 80000ce0 <memset>
  log_write(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	fe6080e7          	jalr	-26(ra) # 800042ac <log_write>
  brelse(bp);
    800032ce:	854a                	mv	a0,s2
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	d60080e7          	jalr	-672(ra) # 80003030 <brelse>
}
    800032d8:	8526                	mv	a0,s1
    800032da:	60e6                	ld	ra,88(sp)
    800032dc:	6446                	ld	s0,80(sp)
    800032de:	64a6                	ld	s1,72(sp)
    800032e0:	6906                	ld	s2,64(sp)
    800032e2:	79e2                	ld	s3,56(sp)
    800032e4:	7a42                	ld	s4,48(sp)
    800032e6:	7aa2                	ld	s5,40(sp)
    800032e8:	7b02                	ld	s6,32(sp)
    800032ea:	6be2                	ld	s7,24(sp)
    800032ec:	6c42                	ld	s8,16(sp)
    800032ee:	6ca2                	ld	s9,8(sp)
    800032f0:	6125                	addi	sp,sp,96
    800032f2:	8082                	ret

00000000800032f4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032f4:	7179                	addi	sp,sp,-48
    800032f6:	f406                	sd	ra,40(sp)
    800032f8:	f022                	sd	s0,32(sp)
    800032fa:	ec26                	sd	s1,24(sp)
    800032fc:	e84a                	sd	s2,16(sp)
    800032fe:	e44e                	sd	s3,8(sp)
    80003300:	e052                	sd	s4,0(sp)
    80003302:	1800                	addi	s0,sp,48
    80003304:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003306:	47ad                	li	a5,11
    80003308:	04b7fe63          	bgeu	a5,a1,80003364 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000330c:	ff45849b          	addiw	s1,a1,-12
    80003310:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003314:	0ff00793          	li	a5,255
    80003318:	0ae7e363          	bltu	a5,a4,800033be <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000331c:	08052583          	lw	a1,128(a0)
    80003320:	c5ad                	beqz	a1,8000338a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003322:	00092503          	lw	a0,0(s2)
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	bda080e7          	jalr	-1062(ra) # 80002f00 <bread>
    8000332e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003330:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003334:	02049593          	slli	a1,s1,0x20
    80003338:	9181                	srli	a1,a1,0x20
    8000333a:	058a                	slli	a1,a1,0x2
    8000333c:	00b784b3          	add	s1,a5,a1
    80003340:	0004a983          	lw	s3,0(s1)
    80003344:	04098d63          	beqz	s3,8000339e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003348:	8552                	mv	a0,s4
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	ce6080e7          	jalr	-794(ra) # 80003030 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003352:	854e                	mv	a0,s3
    80003354:	70a2                	ld	ra,40(sp)
    80003356:	7402                	ld	s0,32(sp)
    80003358:	64e2                	ld	s1,24(sp)
    8000335a:	6942                	ld	s2,16(sp)
    8000335c:	69a2                	ld	s3,8(sp)
    8000335e:	6a02                	ld	s4,0(sp)
    80003360:	6145                	addi	sp,sp,48
    80003362:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003364:	02059493          	slli	s1,a1,0x20
    80003368:	9081                	srli	s1,s1,0x20
    8000336a:	048a                	slli	s1,s1,0x2
    8000336c:	94aa                	add	s1,s1,a0
    8000336e:	0504a983          	lw	s3,80(s1)
    80003372:	fe0990e3          	bnez	s3,80003352 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003376:	4108                	lw	a0,0(a0)
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	e4a080e7          	jalr	-438(ra) # 800031c2 <balloc>
    80003380:	0005099b          	sext.w	s3,a0
    80003384:	0534a823          	sw	s3,80(s1)
    80003388:	b7e9                	j	80003352 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000338a:	4108                	lw	a0,0(a0)
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	e36080e7          	jalr	-458(ra) # 800031c2 <balloc>
    80003394:	0005059b          	sext.w	a1,a0
    80003398:	08b92023          	sw	a1,128(s2)
    8000339c:	b759                	j	80003322 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000339e:	00092503          	lw	a0,0(s2)
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	e20080e7          	jalr	-480(ra) # 800031c2 <balloc>
    800033aa:	0005099b          	sext.w	s3,a0
    800033ae:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033b2:	8552                	mv	a0,s4
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	ef8080e7          	jalr	-264(ra) # 800042ac <log_write>
    800033bc:	b771                	j	80003348 <bmap+0x54>
  panic("bmap: out of range");
    800033be:	00005517          	auipc	a0,0x5
    800033c2:	1ca50513          	addi	a0,a0,458 # 80008588 <syscalls+0x128>
    800033c6:	ffffd097          	auipc	ra,0xffffd
    800033ca:	178080e7          	jalr	376(ra) # 8000053e <panic>

00000000800033ce <iget>:
{
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	e052                	sd	s4,0(sp)
    800033dc:	1800                	addi	s0,sp,48
    800033de:	89aa                	mv	s3,a0
    800033e0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033e2:	0001c517          	auipc	a0,0x1c
    800033e6:	3e650513          	addi	a0,a0,998 # 8001f7c8 <itable>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
  empty = 0;
    800033f2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033f4:	0001c497          	auipc	s1,0x1c
    800033f8:	3ec48493          	addi	s1,s1,1004 # 8001f7e0 <itable+0x18>
    800033fc:	0001e697          	auipc	a3,0x1e
    80003400:	e7468693          	addi	a3,a3,-396 # 80021270 <log>
    80003404:	a039                	j	80003412 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003406:	02090b63          	beqz	s2,8000343c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000340a:	08848493          	addi	s1,s1,136
    8000340e:	02d48a63          	beq	s1,a3,80003442 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003412:	449c                	lw	a5,8(s1)
    80003414:	fef059e3          	blez	a5,80003406 <iget+0x38>
    80003418:	4098                	lw	a4,0(s1)
    8000341a:	ff3716e3          	bne	a4,s3,80003406 <iget+0x38>
    8000341e:	40d8                	lw	a4,4(s1)
    80003420:	ff4713e3          	bne	a4,s4,80003406 <iget+0x38>
      ip->ref++;
    80003424:	2785                	addiw	a5,a5,1
    80003426:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003428:	0001c517          	auipc	a0,0x1c
    8000342c:	3a050513          	addi	a0,a0,928 # 8001f7c8 <itable>
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
      return ip;
    80003438:	8926                	mv	s2,s1
    8000343a:	a03d                	j	80003468 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343c:	f7f9                	bnez	a5,8000340a <iget+0x3c>
    8000343e:	8926                	mv	s2,s1
    80003440:	b7e9                	j	8000340a <iget+0x3c>
  if(empty == 0)
    80003442:	02090c63          	beqz	s2,8000347a <iget+0xac>
  ip->dev = dev;
    80003446:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000344a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000344e:	4785                	li	a5,1
    80003450:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003454:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003458:	0001c517          	auipc	a0,0x1c
    8000345c:	37050513          	addi	a0,a0,880 # 8001f7c8 <itable>
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
}
    80003468:	854a                	mv	a0,s2
    8000346a:	70a2                	ld	ra,40(sp)
    8000346c:	7402                	ld	s0,32(sp)
    8000346e:	64e2                	ld	s1,24(sp)
    80003470:	6942                	ld	s2,16(sp)
    80003472:	69a2                	ld	s3,8(sp)
    80003474:	6a02                	ld	s4,0(sp)
    80003476:	6145                	addi	sp,sp,48
    80003478:	8082                	ret
    panic("iget: no inodes");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	12650513          	addi	a0,a0,294 # 800085a0 <syscalls+0x140>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>

000000008000348a <fsinit>:
fsinit(int dev) {
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	1800                	addi	s0,sp,48
    80003498:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000349a:	4585                	li	a1,1
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	a64080e7          	jalr	-1436(ra) # 80002f00 <bread>
    800034a4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034a6:	0001c997          	auipc	s3,0x1c
    800034aa:	30298993          	addi	s3,s3,770 # 8001f7a8 <sb>
    800034ae:	02000613          	li	a2,32
    800034b2:	05850593          	addi	a1,a0,88
    800034b6:	854e                	mv	a0,s3
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	888080e7          	jalr	-1912(ra) # 80000d40 <memmove>
  brelse(bp);
    800034c0:	8526                	mv	a0,s1
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	b6e080e7          	jalr	-1170(ra) # 80003030 <brelse>
  if(sb.magic != FSMAGIC)
    800034ca:	0009a703          	lw	a4,0(s3)
    800034ce:	102037b7          	lui	a5,0x10203
    800034d2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034d6:	02f71263          	bne	a4,a5,800034fa <fsinit+0x70>
  initlog(dev, &sb);
    800034da:	0001c597          	auipc	a1,0x1c
    800034de:	2ce58593          	addi	a1,a1,718 # 8001f7a8 <sb>
    800034e2:	854a                	mv	a0,s2
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	b4c080e7          	jalr	-1204(ra) # 80004030 <initlog>
}
    800034ec:	70a2                	ld	ra,40(sp)
    800034ee:	7402                	ld	s0,32(sp)
    800034f0:	64e2                	ld	s1,24(sp)
    800034f2:	6942                	ld	s2,16(sp)
    800034f4:	69a2                	ld	s3,8(sp)
    800034f6:	6145                	addi	sp,sp,48
    800034f8:	8082                	ret
    panic("invalid file system");
    800034fa:	00005517          	auipc	a0,0x5
    800034fe:	0b650513          	addi	a0,a0,182 # 800085b0 <syscalls+0x150>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	03c080e7          	jalr	60(ra) # 8000053e <panic>

000000008000350a <iinit>:
{
    8000350a:	7179                	addi	sp,sp,-48
    8000350c:	f406                	sd	ra,40(sp)
    8000350e:	f022                	sd	s0,32(sp)
    80003510:	ec26                	sd	s1,24(sp)
    80003512:	e84a                	sd	s2,16(sp)
    80003514:	e44e                	sd	s3,8(sp)
    80003516:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003518:	00005597          	auipc	a1,0x5
    8000351c:	0b058593          	addi	a1,a1,176 # 800085c8 <syscalls+0x168>
    80003520:	0001c517          	auipc	a0,0x1c
    80003524:	2a850513          	addi	a0,a0,680 # 8001f7c8 <itable>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	62c080e7          	jalr	1580(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003530:	0001c497          	auipc	s1,0x1c
    80003534:	2c048493          	addi	s1,s1,704 # 8001f7f0 <itable+0x28>
    80003538:	0001e997          	auipc	s3,0x1e
    8000353c:	d4898993          	addi	s3,s3,-696 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003540:	00005917          	auipc	s2,0x5
    80003544:	09090913          	addi	s2,s2,144 # 800085d0 <syscalls+0x170>
    80003548:	85ca                	mv	a1,s2
    8000354a:	8526                	mv	a0,s1
    8000354c:	00001097          	auipc	ra,0x1
    80003550:	e46080e7          	jalr	-442(ra) # 80004392 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003554:	08848493          	addi	s1,s1,136
    80003558:	ff3498e3          	bne	s1,s3,80003548 <iinit+0x3e>
}
    8000355c:	70a2                	ld	ra,40(sp)
    8000355e:	7402                	ld	s0,32(sp)
    80003560:	64e2                	ld	s1,24(sp)
    80003562:	6942                	ld	s2,16(sp)
    80003564:	69a2                	ld	s3,8(sp)
    80003566:	6145                	addi	sp,sp,48
    80003568:	8082                	ret

000000008000356a <ialloc>:
{
    8000356a:	715d                	addi	sp,sp,-80
    8000356c:	e486                	sd	ra,72(sp)
    8000356e:	e0a2                	sd	s0,64(sp)
    80003570:	fc26                	sd	s1,56(sp)
    80003572:	f84a                	sd	s2,48(sp)
    80003574:	f44e                	sd	s3,40(sp)
    80003576:	f052                	sd	s4,32(sp)
    80003578:	ec56                	sd	s5,24(sp)
    8000357a:	e85a                	sd	s6,16(sp)
    8000357c:	e45e                	sd	s7,8(sp)
    8000357e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003580:	0001c717          	auipc	a4,0x1c
    80003584:	23472703          	lw	a4,564(a4) # 8001f7b4 <sb+0xc>
    80003588:	4785                	li	a5,1
    8000358a:	04e7fa63          	bgeu	a5,a4,800035de <ialloc+0x74>
    8000358e:	8aaa                	mv	s5,a0
    80003590:	8bae                	mv	s7,a1
    80003592:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003594:	0001ca17          	auipc	s4,0x1c
    80003598:	214a0a13          	addi	s4,s4,532 # 8001f7a8 <sb>
    8000359c:	00048b1b          	sext.w	s6,s1
    800035a0:	0044d593          	srli	a1,s1,0x4
    800035a4:	018a2783          	lw	a5,24(s4)
    800035a8:	9dbd                	addw	a1,a1,a5
    800035aa:	8556                	mv	a0,s5
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	954080e7          	jalr	-1708(ra) # 80002f00 <bread>
    800035b4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035b6:	05850993          	addi	s3,a0,88
    800035ba:	00f4f793          	andi	a5,s1,15
    800035be:	079a                	slli	a5,a5,0x6
    800035c0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035c2:	00099783          	lh	a5,0(s3)
    800035c6:	c785                	beqz	a5,800035ee <ialloc+0x84>
    brelse(bp);
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	a68080e7          	jalr	-1432(ra) # 80003030 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d0:	0485                	addi	s1,s1,1
    800035d2:	00ca2703          	lw	a4,12(s4)
    800035d6:	0004879b          	sext.w	a5,s1
    800035da:	fce7e1e3          	bltu	a5,a4,8000359c <ialloc+0x32>
  panic("ialloc: no inodes");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	ffa50513          	addi	a0,a0,-6 # 800085d8 <syscalls+0x178>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035ee:	04000613          	li	a2,64
    800035f2:	4581                	li	a1,0
    800035f4:	854e                	mv	a0,s3
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	6ea080e7          	jalr	1770(ra) # 80000ce0 <memset>
      dip->type = type;
    800035fe:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003602:	854a                	mv	a0,s2
    80003604:	00001097          	auipc	ra,0x1
    80003608:	ca8080e7          	jalr	-856(ra) # 800042ac <log_write>
      brelse(bp);
    8000360c:	854a                	mv	a0,s2
    8000360e:	00000097          	auipc	ra,0x0
    80003612:	a22080e7          	jalr	-1502(ra) # 80003030 <brelse>
      return iget(dev, inum);
    80003616:	85da                	mv	a1,s6
    80003618:	8556                	mv	a0,s5
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	db4080e7          	jalr	-588(ra) # 800033ce <iget>
}
    80003622:	60a6                	ld	ra,72(sp)
    80003624:	6406                	ld	s0,64(sp)
    80003626:	74e2                	ld	s1,56(sp)
    80003628:	7942                	ld	s2,48(sp)
    8000362a:	79a2                	ld	s3,40(sp)
    8000362c:	7a02                	ld	s4,32(sp)
    8000362e:	6ae2                	ld	s5,24(sp)
    80003630:	6b42                	ld	s6,16(sp)
    80003632:	6ba2                	ld	s7,8(sp)
    80003634:	6161                	addi	sp,sp,80
    80003636:	8082                	ret

0000000080003638 <iupdate>:
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	e04a                	sd	s2,0(sp)
    80003642:	1000                	addi	s0,sp,32
    80003644:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003646:	415c                	lw	a5,4(a0)
    80003648:	0047d79b          	srliw	a5,a5,0x4
    8000364c:	0001c597          	auipc	a1,0x1c
    80003650:	1745a583          	lw	a1,372(a1) # 8001f7c0 <sb+0x18>
    80003654:	9dbd                	addw	a1,a1,a5
    80003656:	4108                	lw	a0,0(a0)
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	8a8080e7          	jalr	-1880(ra) # 80002f00 <bread>
    80003660:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003662:	05850793          	addi	a5,a0,88
    80003666:	40c8                	lw	a0,4(s1)
    80003668:	893d                	andi	a0,a0,15
    8000366a:	051a                	slli	a0,a0,0x6
    8000366c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000366e:	04449703          	lh	a4,68(s1)
    80003672:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003676:	04649703          	lh	a4,70(s1)
    8000367a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000367e:	04849703          	lh	a4,72(s1)
    80003682:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003686:	04a49703          	lh	a4,74(s1)
    8000368a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000368e:	44f8                	lw	a4,76(s1)
    80003690:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003692:	03400613          	li	a2,52
    80003696:	05048593          	addi	a1,s1,80
    8000369a:	0531                	addi	a0,a0,12
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	6a4080e7          	jalr	1700(ra) # 80000d40 <memmove>
  log_write(bp);
    800036a4:	854a                	mv	a0,s2
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	c06080e7          	jalr	-1018(ra) # 800042ac <log_write>
  brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	980080e7          	jalr	-1664(ra) # 80003030 <brelse>
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret

00000000800036c4 <idup>:
{
    800036c4:	1101                	addi	sp,sp,-32
    800036c6:	ec06                	sd	ra,24(sp)
    800036c8:	e822                	sd	s0,16(sp)
    800036ca:	e426                	sd	s1,8(sp)
    800036cc:	1000                	addi	s0,sp,32
    800036ce:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036d0:	0001c517          	auipc	a0,0x1c
    800036d4:	0f850513          	addi	a0,a0,248 # 8001f7c8 <itable>
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	50c080e7          	jalr	1292(ra) # 80000be4 <acquire>
  ip->ref++;
    800036e0:	449c                	lw	a5,8(s1)
    800036e2:	2785                	addiw	a5,a5,1
    800036e4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036e6:	0001c517          	auipc	a0,0x1c
    800036ea:	0e250513          	addi	a0,a0,226 # 8001f7c8 <itable>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	5aa080e7          	jalr	1450(ra) # 80000c98 <release>
}
    800036f6:	8526                	mv	a0,s1
    800036f8:	60e2                	ld	ra,24(sp)
    800036fa:	6442                	ld	s0,16(sp)
    800036fc:	64a2                	ld	s1,8(sp)
    800036fe:	6105                	addi	sp,sp,32
    80003700:	8082                	ret

0000000080003702 <ilock>:
{
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	e04a                	sd	s2,0(sp)
    8000370c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000370e:	c115                	beqz	a0,80003732 <ilock+0x30>
    80003710:	84aa                	mv	s1,a0
    80003712:	451c                	lw	a5,8(a0)
    80003714:	00f05f63          	blez	a5,80003732 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003718:	0541                	addi	a0,a0,16
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	cb2080e7          	jalr	-846(ra) # 800043cc <acquiresleep>
  if(ip->valid == 0){
    80003722:	40bc                	lw	a5,64(s1)
    80003724:	cf99                	beqz	a5,80003742 <ilock+0x40>
}
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6902                	ld	s2,0(sp)
    8000372e:	6105                	addi	sp,sp,32
    80003730:	8082                	ret
    panic("ilock");
    80003732:	00005517          	auipc	a0,0x5
    80003736:	ebe50513          	addi	a0,a0,-322 # 800085f0 <syscalls+0x190>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	e04080e7          	jalr	-508(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003742:	40dc                	lw	a5,4(s1)
    80003744:	0047d79b          	srliw	a5,a5,0x4
    80003748:	0001c597          	auipc	a1,0x1c
    8000374c:	0785a583          	lw	a1,120(a1) # 8001f7c0 <sb+0x18>
    80003750:	9dbd                	addw	a1,a1,a5
    80003752:	4088                	lw	a0,0(s1)
    80003754:	fffff097          	auipc	ra,0xfffff
    80003758:	7ac080e7          	jalr	1964(ra) # 80002f00 <bread>
    8000375c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000375e:	05850593          	addi	a1,a0,88
    80003762:	40dc                	lw	a5,4(s1)
    80003764:	8bbd                	andi	a5,a5,15
    80003766:	079a                	slli	a5,a5,0x6
    80003768:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000376a:	00059783          	lh	a5,0(a1)
    8000376e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003772:	00259783          	lh	a5,2(a1)
    80003776:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000377a:	00459783          	lh	a5,4(a1)
    8000377e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003782:	00659783          	lh	a5,6(a1)
    80003786:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000378a:	459c                	lw	a5,8(a1)
    8000378c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000378e:	03400613          	li	a2,52
    80003792:	05b1                	addi	a1,a1,12
    80003794:	05048513          	addi	a0,s1,80
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	5a8080e7          	jalr	1448(ra) # 80000d40 <memmove>
    brelse(bp);
    800037a0:	854a                	mv	a0,s2
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	88e080e7          	jalr	-1906(ra) # 80003030 <brelse>
    ip->valid = 1;
    800037aa:	4785                	li	a5,1
    800037ac:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037ae:	04449783          	lh	a5,68(s1)
    800037b2:	fbb5                	bnez	a5,80003726 <ilock+0x24>
      panic("ilock: no type");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	e4450513          	addi	a0,a0,-444 # 800085f8 <syscalls+0x198>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>

00000000800037c4 <iunlock>:
{
    800037c4:	1101                	addi	sp,sp,-32
    800037c6:	ec06                	sd	ra,24(sp)
    800037c8:	e822                	sd	s0,16(sp)
    800037ca:	e426                	sd	s1,8(sp)
    800037cc:	e04a                	sd	s2,0(sp)
    800037ce:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037d0:	c905                	beqz	a0,80003800 <iunlock+0x3c>
    800037d2:	84aa                	mv	s1,a0
    800037d4:	01050913          	addi	s2,a0,16
    800037d8:	854a                	mv	a0,s2
    800037da:	00001097          	auipc	ra,0x1
    800037de:	c8c080e7          	jalr	-884(ra) # 80004466 <holdingsleep>
    800037e2:	cd19                	beqz	a0,80003800 <iunlock+0x3c>
    800037e4:	449c                	lw	a5,8(s1)
    800037e6:	00f05d63          	blez	a5,80003800 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	c36080e7          	jalr	-970(ra) # 80004422 <releasesleep>
}
    800037f4:	60e2                	ld	ra,24(sp)
    800037f6:	6442                	ld	s0,16(sp)
    800037f8:	64a2                	ld	s1,8(sp)
    800037fa:	6902                	ld	s2,0(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret
    panic("iunlock");
    80003800:	00005517          	auipc	a0,0x5
    80003804:	e0850513          	addi	a0,a0,-504 # 80008608 <syscalls+0x1a8>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>

0000000080003810 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003810:	7179                	addi	sp,sp,-48
    80003812:	f406                	sd	ra,40(sp)
    80003814:	f022                	sd	s0,32(sp)
    80003816:	ec26                	sd	s1,24(sp)
    80003818:	e84a                	sd	s2,16(sp)
    8000381a:	e44e                	sd	s3,8(sp)
    8000381c:	e052                	sd	s4,0(sp)
    8000381e:	1800                	addi	s0,sp,48
    80003820:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003822:	05050493          	addi	s1,a0,80
    80003826:	08050913          	addi	s2,a0,128
    8000382a:	a021                	j	80003832 <itrunc+0x22>
    8000382c:	0491                	addi	s1,s1,4
    8000382e:	01248d63          	beq	s1,s2,80003848 <itrunc+0x38>
    if(ip->addrs[i]){
    80003832:	408c                	lw	a1,0(s1)
    80003834:	dde5                	beqz	a1,8000382c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003836:	0009a503          	lw	a0,0(s3)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	90c080e7          	jalr	-1780(ra) # 80003146 <bfree>
      ip->addrs[i] = 0;
    80003842:	0004a023          	sw	zero,0(s1)
    80003846:	b7dd                	j	8000382c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003848:	0809a583          	lw	a1,128(s3)
    8000384c:	e185                	bnez	a1,8000386c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000384e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003852:	854e                	mv	a0,s3
    80003854:	00000097          	auipc	ra,0x0
    80003858:	de4080e7          	jalr	-540(ra) # 80003638 <iupdate>
}
    8000385c:	70a2                	ld	ra,40(sp)
    8000385e:	7402                	ld	s0,32(sp)
    80003860:	64e2                	ld	s1,24(sp)
    80003862:	6942                	ld	s2,16(sp)
    80003864:	69a2                	ld	s3,8(sp)
    80003866:	6a02                	ld	s4,0(sp)
    80003868:	6145                	addi	sp,sp,48
    8000386a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000386c:	0009a503          	lw	a0,0(s3)
    80003870:	fffff097          	auipc	ra,0xfffff
    80003874:	690080e7          	jalr	1680(ra) # 80002f00 <bread>
    80003878:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000387a:	05850493          	addi	s1,a0,88
    8000387e:	45850913          	addi	s2,a0,1112
    80003882:	a811                	j	80003896 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003884:	0009a503          	lw	a0,0(s3)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	8be080e7          	jalr	-1858(ra) # 80003146 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003890:	0491                	addi	s1,s1,4
    80003892:	01248563          	beq	s1,s2,8000389c <itrunc+0x8c>
      if(a[j])
    80003896:	408c                	lw	a1,0(s1)
    80003898:	dde5                	beqz	a1,80003890 <itrunc+0x80>
    8000389a:	b7ed                	j	80003884 <itrunc+0x74>
    brelse(bp);
    8000389c:	8552                	mv	a0,s4
    8000389e:	fffff097          	auipc	ra,0xfffff
    800038a2:	792080e7          	jalr	1938(ra) # 80003030 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038a6:	0809a583          	lw	a1,128(s3)
    800038aa:	0009a503          	lw	a0,0(s3)
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	898080e7          	jalr	-1896(ra) # 80003146 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038b6:	0809a023          	sw	zero,128(s3)
    800038ba:	bf51                	j	8000384e <itrunc+0x3e>

00000000800038bc <iput>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ca:	0001c517          	auipc	a0,0x1c
    800038ce:	efe50513          	addi	a0,a0,-258 # 8001f7c8 <itable>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	312080e7          	jalr	786(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038da:	4498                	lw	a4,8(s1)
    800038dc:	4785                	li	a5,1
    800038de:	02f70363          	beq	a4,a5,80003904 <iput+0x48>
  ip->ref--;
    800038e2:	449c                	lw	a5,8(s1)
    800038e4:	37fd                	addiw	a5,a5,-1
    800038e6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038e8:	0001c517          	auipc	a0,0x1c
    800038ec:	ee050513          	addi	a0,a0,-288 # 8001f7c8 <itable>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6902                	ld	s2,0(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003904:	40bc                	lw	a5,64(s1)
    80003906:	dff1                	beqz	a5,800038e2 <iput+0x26>
    80003908:	04a49783          	lh	a5,74(s1)
    8000390c:	fbf9                	bnez	a5,800038e2 <iput+0x26>
    acquiresleep(&ip->lock);
    8000390e:	01048913          	addi	s2,s1,16
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	ab8080e7          	jalr	-1352(ra) # 800043cc <acquiresleep>
    release(&itable.lock);
    8000391c:	0001c517          	auipc	a0,0x1c
    80003920:	eac50513          	addi	a0,a0,-340 # 8001f7c8 <itable>
    80003924:	ffffd097          	auipc	ra,0xffffd
    80003928:	374080e7          	jalr	884(ra) # 80000c98 <release>
    itrunc(ip);
    8000392c:	8526                	mv	a0,s1
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	ee2080e7          	jalr	-286(ra) # 80003810 <itrunc>
    ip->type = 0;
    80003936:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000393a:	8526                	mv	a0,s1
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	cfc080e7          	jalr	-772(ra) # 80003638 <iupdate>
    ip->valid = 0;
    80003944:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	ad8080e7          	jalr	-1320(ra) # 80004422 <releasesleep>
    acquire(&itable.lock);
    80003952:	0001c517          	auipc	a0,0x1c
    80003956:	e7650513          	addi	a0,a0,-394 # 8001f7c8 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	28a080e7          	jalr	650(ra) # 80000be4 <acquire>
    80003962:	b741                	j	800038e2 <iput+0x26>

0000000080003964 <iunlockput>:
{
    80003964:	1101                	addi	sp,sp,-32
    80003966:	ec06                	sd	ra,24(sp)
    80003968:	e822                	sd	s0,16(sp)
    8000396a:	e426                	sd	s1,8(sp)
    8000396c:	1000                	addi	s0,sp,32
    8000396e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003970:	00000097          	auipc	ra,0x0
    80003974:	e54080e7          	jalr	-428(ra) # 800037c4 <iunlock>
  iput(ip);
    80003978:	8526                	mv	a0,s1
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	f42080e7          	jalr	-190(ra) # 800038bc <iput>
}
    80003982:	60e2                	ld	ra,24(sp)
    80003984:	6442                	ld	s0,16(sp)
    80003986:	64a2                	ld	s1,8(sp)
    80003988:	6105                	addi	sp,sp,32
    8000398a:	8082                	ret

000000008000398c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000398c:	1141                	addi	sp,sp,-16
    8000398e:	e422                	sd	s0,8(sp)
    80003990:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003992:	411c                	lw	a5,0(a0)
    80003994:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003996:	415c                	lw	a5,4(a0)
    80003998:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000399a:	04451783          	lh	a5,68(a0)
    8000399e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039a2:	04a51783          	lh	a5,74(a0)
    800039a6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039aa:	04c56783          	lwu	a5,76(a0)
    800039ae:	e99c                	sd	a5,16(a1)
}
    800039b0:	6422                	ld	s0,8(sp)
    800039b2:	0141                	addi	sp,sp,16
    800039b4:	8082                	ret

00000000800039b6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039b6:	457c                	lw	a5,76(a0)
    800039b8:	0ed7e963          	bltu	a5,a3,80003aaa <readi+0xf4>
{
    800039bc:	7159                	addi	sp,sp,-112
    800039be:	f486                	sd	ra,104(sp)
    800039c0:	f0a2                	sd	s0,96(sp)
    800039c2:	eca6                	sd	s1,88(sp)
    800039c4:	e8ca                	sd	s2,80(sp)
    800039c6:	e4ce                	sd	s3,72(sp)
    800039c8:	e0d2                	sd	s4,64(sp)
    800039ca:	fc56                	sd	s5,56(sp)
    800039cc:	f85a                	sd	s6,48(sp)
    800039ce:	f45e                	sd	s7,40(sp)
    800039d0:	f062                	sd	s8,32(sp)
    800039d2:	ec66                	sd	s9,24(sp)
    800039d4:	e86a                	sd	s10,16(sp)
    800039d6:	e46e                	sd	s11,8(sp)
    800039d8:	1880                	addi	s0,sp,112
    800039da:	8baa                	mv	s7,a0
    800039dc:	8c2e                	mv	s8,a1
    800039de:	8ab2                	mv	s5,a2
    800039e0:	84b6                	mv	s1,a3
    800039e2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039e4:	9f35                	addw	a4,a4,a3
    return 0;
    800039e6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039e8:	0ad76063          	bltu	a4,a3,80003a88 <readi+0xd2>
  if(off + n > ip->size)
    800039ec:	00e7f463          	bgeu	a5,a4,800039f4 <readi+0x3e>
    n = ip->size - off;
    800039f0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f4:	0a0b0963          	beqz	s6,80003aa6 <readi+0xf0>
    800039f8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039fa:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039fe:	5cfd                	li	s9,-1
    80003a00:	a82d                	j	80003a3a <readi+0x84>
    80003a02:	020a1d93          	slli	s11,s4,0x20
    80003a06:	020ddd93          	srli	s11,s11,0x20
    80003a0a:	05890613          	addi	a2,s2,88
    80003a0e:	86ee                	mv	a3,s11
    80003a10:	963a                	add	a2,a2,a4
    80003a12:	85d6                	mv	a1,s5
    80003a14:	8562                	mv	a0,s8
    80003a16:	fffff097          	auipc	ra,0xfffff
    80003a1a:	a42080e7          	jalr	-1470(ra) # 80002458 <either_copyout>
    80003a1e:	05950d63          	beq	a0,s9,80003a78 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	60c080e7          	jalr	1548(ra) # 80003030 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2c:	013a09bb          	addw	s3,s4,s3
    80003a30:	009a04bb          	addw	s1,s4,s1
    80003a34:	9aee                	add	s5,s5,s11
    80003a36:	0569f763          	bgeu	s3,s6,80003a84 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a3a:	000ba903          	lw	s2,0(s7)
    80003a3e:	00a4d59b          	srliw	a1,s1,0xa
    80003a42:	855e                	mv	a0,s7
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	8b0080e7          	jalr	-1872(ra) # 800032f4 <bmap>
    80003a4c:	0005059b          	sext.w	a1,a0
    80003a50:	854a                	mv	a0,s2
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	4ae080e7          	jalr	1198(ra) # 80002f00 <bread>
    80003a5a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a5c:	3ff4f713          	andi	a4,s1,1023
    80003a60:	40ed07bb          	subw	a5,s10,a4
    80003a64:	413b06bb          	subw	a3,s6,s3
    80003a68:	8a3e                	mv	s4,a5
    80003a6a:	2781                	sext.w	a5,a5
    80003a6c:	0006861b          	sext.w	a2,a3
    80003a70:	f8f679e3          	bgeu	a2,a5,80003a02 <readi+0x4c>
    80003a74:	8a36                	mv	s4,a3
    80003a76:	b771                	j	80003a02 <readi+0x4c>
      brelse(bp);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	fffff097          	auipc	ra,0xfffff
    80003a7e:	5b6080e7          	jalr	1462(ra) # 80003030 <brelse>
      tot = -1;
    80003a82:	59fd                	li	s3,-1
  }
  return tot;
    80003a84:	0009851b          	sext.w	a0,s3
}
    80003a88:	70a6                	ld	ra,104(sp)
    80003a8a:	7406                	ld	s0,96(sp)
    80003a8c:	64e6                	ld	s1,88(sp)
    80003a8e:	6946                	ld	s2,80(sp)
    80003a90:	69a6                	ld	s3,72(sp)
    80003a92:	6a06                	ld	s4,64(sp)
    80003a94:	7ae2                	ld	s5,56(sp)
    80003a96:	7b42                	ld	s6,48(sp)
    80003a98:	7ba2                	ld	s7,40(sp)
    80003a9a:	7c02                	ld	s8,32(sp)
    80003a9c:	6ce2                	ld	s9,24(sp)
    80003a9e:	6d42                	ld	s10,16(sp)
    80003aa0:	6da2                	ld	s11,8(sp)
    80003aa2:	6165                	addi	sp,sp,112
    80003aa4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa6:	89da                	mv	s3,s6
    80003aa8:	bff1                	j	80003a84 <readi+0xce>
    return 0;
    80003aaa:	4501                	li	a0,0
}
    80003aac:	8082                	ret

0000000080003aae <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aae:	457c                	lw	a5,76(a0)
    80003ab0:	10d7e863          	bltu	a5,a3,80003bc0 <writei+0x112>
{
    80003ab4:	7159                	addi	sp,sp,-112
    80003ab6:	f486                	sd	ra,104(sp)
    80003ab8:	f0a2                	sd	s0,96(sp)
    80003aba:	eca6                	sd	s1,88(sp)
    80003abc:	e8ca                	sd	s2,80(sp)
    80003abe:	e4ce                	sd	s3,72(sp)
    80003ac0:	e0d2                	sd	s4,64(sp)
    80003ac2:	fc56                	sd	s5,56(sp)
    80003ac4:	f85a                	sd	s6,48(sp)
    80003ac6:	f45e                	sd	s7,40(sp)
    80003ac8:	f062                	sd	s8,32(sp)
    80003aca:	ec66                	sd	s9,24(sp)
    80003acc:	e86a                	sd	s10,16(sp)
    80003ace:	e46e                	sd	s11,8(sp)
    80003ad0:	1880                	addi	s0,sp,112
    80003ad2:	8b2a                	mv	s6,a0
    80003ad4:	8c2e                	mv	s8,a1
    80003ad6:	8ab2                	mv	s5,a2
    80003ad8:	8936                	mv	s2,a3
    80003ada:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003adc:	00e687bb          	addw	a5,a3,a4
    80003ae0:	0ed7e263          	bltu	a5,a3,80003bc4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ae4:	00043737          	lui	a4,0x43
    80003ae8:	0ef76063          	bltu	a4,a5,80003bc8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aec:	0c0b8863          	beqz	s7,80003bbc <writei+0x10e>
    80003af0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003af6:	5cfd                	li	s9,-1
    80003af8:	a091                	j	80003b3c <writei+0x8e>
    80003afa:	02099d93          	slli	s11,s3,0x20
    80003afe:	020ddd93          	srli	s11,s11,0x20
    80003b02:	05848513          	addi	a0,s1,88
    80003b06:	86ee                	mv	a3,s11
    80003b08:	8656                	mv	a2,s5
    80003b0a:	85e2                	mv	a1,s8
    80003b0c:	953a                	add	a0,a0,a4
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	9a0080e7          	jalr	-1632(ra) # 800024ae <either_copyin>
    80003b16:	07950263          	beq	a0,s9,80003b7a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b1a:	8526                	mv	a0,s1
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	790080e7          	jalr	1936(ra) # 800042ac <log_write>
    brelse(bp);
    80003b24:	8526                	mv	a0,s1
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	50a080e7          	jalr	1290(ra) # 80003030 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b2e:	01498a3b          	addw	s4,s3,s4
    80003b32:	0129893b          	addw	s2,s3,s2
    80003b36:	9aee                	add	s5,s5,s11
    80003b38:	057a7663          	bgeu	s4,s7,80003b84 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b3c:	000b2483          	lw	s1,0(s6)
    80003b40:	00a9559b          	srliw	a1,s2,0xa
    80003b44:	855a                	mv	a0,s6
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	7ae080e7          	jalr	1966(ra) # 800032f4 <bmap>
    80003b4e:	0005059b          	sext.w	a1,a0
    80003b52:	8526                	mv	a0,s1
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	3ac080e7          	jalr	940(ra) # 80002f00 <bread>
    80003b5c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b5e:	3ff97713          	andi	a4,s2,1023
    80003b62:	40ed07bb          	subw	a5,s10,a4
    80003b66:	414b86bb          	subw	a3,s7,s4
    80003b6a:	89be                	mv	s3,a5
    80003b6c:	2781                	sext.w	a5,a5
    80003b6e:	0006861b          	sext.w	a2,a3
    80003b72:	f8f674e3          	bgeu	a2,a5,80003afa <writei+0x4c>
    80003b76:	89b6                	mv	s3,a3
    80003b78:	b749                	j	80003afa <writei+0x4c>
      brelse(bp);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	4b4080e7          	jalr	1204(ra) # 80003030 <brelse>
  }

  if(off > ip->size)
    80003b84:	04cb2783          	lw	a5,76(s6)
    80003b88:	0127f463          	bgeu	a5,s2,80003b90 <writei+0xe2>
    ip->size = off;
    80003b8c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b90:	855a                	mv	a0,s6
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	aa6080e7          	jalr	-1370(ra) # 80003638 <iupdate>

  return tot;
    80003b9a:	000a051b          	sext.w	a0,s4
}
    80003b9e:	70a6                	ld	ra,104(sp)
    80003ba0:	7406                	ld	s0,96(sp)
    80003ba2:	64e6                	ld	s1,88(sp)
    80003ba4:	6946                	ld	s2,80(sp)
    80003ba6:	69a6                	ld	s3,72(sp)
    80003ba8:	6a06                	ld	s4,64(sp)
    80003baa:	7ae2                	ld	s5,56(sp)
    80003bac:	7b42                	ld	s6,48(sp)
    80003bae:	7ba2                	ld	s7,40(sp)
    80003bb0:	7c02                	ld	s8,32(sp)
    80003bb2:	6ce2                	ld	s9,24(sp)
    80003bb4:	6d42                	ld	s10,16(sp)
    80003bb6:	6da2                	ld	s11,8(sp)
    80003bb8:	6165                	addi	sp,sp,112
    80003bba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bbc:	8a5e                	mv	s4,s7
    80003bbe:	bfc9                	j	80003b90 <writei+0xe2>
    return -1;
    80003bc0:	557d                	li	a0,-1
}
    80003bc2:	8082                	ret
    return -1;
    80003bc4:	557d                	li	a0,-1
    80003bc6:	bfe1                	j	80003b9e <writei+0xf0>
    return -1;
    80003bc8:	557d                	li	a0,-1
    80003bca:	bfd1                	j	80003b9e <writei+0xf0>

0000000080003bcc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bcc:	1141                	addi	sp,sp,-16
    80003bce:	e406                	sd	ra,8(sp)
    80003bd0:	e022                	sd	s0,0(sp)
    80003bd2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bd4:	4639                	li	a2,14
    80003bd6:	ffffd097          	auipc	ra,0xffffd
    80003bda:	1e2080e7          	jalr	482(ra) # 80000db8 <strncmp>
}
    80003bde:	60a2                	ld	ra,8(sp)
    80003be0:	6402                	ld	s0,0(sp)
    80003be2:	0141                	addi	sp,sp,16
    80003be4:	8082                	ret

0000000080003be6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003be6:	7139                	addi	sp,sp,-64
    80003be8:	fc06                	sd	ra,56(sp)
    80003bea:	f822                	sd	s0,48(sp)
    80003bec:	f426                	sd	s1,40(sp)
    80003bee:	f04a                	sd	s2,32(sp)
    80003bf0:	ec4e                	sd	s3,24(sp)
    80003bf2:	e852                	sd	s4,16(sp)
    80003bf4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bf6:	04451703          	lh	a4,68(a0)
    80003bfa:	4785                	li	a5,1
    80003bfc:	00f71a63          	bne	a4,a5,80003c10 <dirlookup+0x2a>
    80003c00:	892a                	mv	s2,a0
    80003c02:	89ae                	mv	s3,a1
    80003c04:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c06:	457c                	lw	a5,76(a0)
    80003c08:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c0a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c0c:	e79d                	bnez	a5,80003c3a <dirlookup+0x54>
    80003c0e:	a8a5                	j	80003c86 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c10:	00005517          	auipc	a0,0x5
    80003c14:	a0050513          	addi	a0,a0,-1536 # 80008610 <syscalls+0x1b0>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c20:	00005517          	auipc	a0,0x5
    80003c24:	a0850513          	addi	a0,a0,-1528 # 80008628 <syscalls+0x1c8>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	916080e7          	jalr	-1770(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c30:	24c1                	addiw	s1,s1,16
    80003c32:	04c92783          	lw	a5,76(s2)
    80003c36:	04f4f763          	bgeu	s1,a5,80003c84 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c3a:	4741                	li	a4,16
    80003c3c:	86a6                	mv	a3,s1
    80003c3e:	fc040613          	addi	a2,s0,-64
    80003c42:	4581                	li	a1,0
    80003c44:	854a                	mv	a0,s2
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	d70080e7          	jalr	-656(ra) # 800039b6 <readi>
    80003c4e:	47c1                	li	a5,16
    80003c50:	fcf518e3          	bne	a0,a5,80003c20 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c54:	fc045783          	lhu	a5,-64(s0)
    80003c58:	dfe1                	beqz	a5,80003c30 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c5a:	fc240593          	addi	a1,s0,-62
    80003c5e:	854e                	mv	a0,s3
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	f6c080e7          	jalr	-148(ra) # 80003bcc <namecmp>
    80003c68:	f561                	bnez	a0,80003c30 <dirlookup+0x4a>
      if(poff)
    80003c6a:	000a0463          	beqz	s4,80003c72 <dirlookup+0x8c>
        *poff = off;
    80003c6e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c72:	fc045583          	lhu	a1,-64(s0)
    80003c76:	00092503          	lw	a0,0(s2)
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	754080e7          	jalr	1876(ra) # 800033ce <iget>
    80003c82:	a011                	j	80003c86 <dirlookup+0xa0>
  return 0;
    80003c84:	4501                	li	a0,0
}
    80003c86:	70e2                	ld	ra,56(sp)
    80003c88:	7442                	ld	s0,48(sp)
    80003c8a:	74a2                	ld	s1,40(sp)
    80003c8c:	7902                	ld	s2,32(sp)
    80003c8e:	69e2                	ld	s3,24(sp)
    80003c90:	6a42                	ld	s4,16(sp)
    80003c92:	6121                	addi	sp,sp,64
    80003c94:	8082                	ret

0000000080003c96 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c96:	711d                	addi	sp,sp,-96
    80003c98:	ec86                	sd	ra,88(sp)
    80003c9a:	e8a2                	sd	s0,80(sp)
    80003c9c:	e4a6                	sd	s1,72(sp)
    80003c9e:	e0ca                	sd	s2,64(sp)
    80003ca0:	fc4e                	sd	s3,56(sp)
    80003ca2:	f852                	sd	s4,48(sp)
    80003ca4:	f456                	sd	s5,40(sp)
    80003ca6:	f05a                	sd	s6,32(sp)
    80003ca8:	ec5e                	sd	s7,24(sp)
    80003caa:	e862                	sd	s8,16(sp)
    80003cac:	e466                	sd	s9,8(sp)
    80003cae:	1080                	addi	s0,sp,96
    80003cb0:	84aa                	mv	s1,a0
    80003cb2:	8b2e                	mv	s6,a1
    80003cb4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cb6:	00054703          	lbu	a4,0(a0)
    80003cba:	02f00793          	li	a5,47
    80003cbe:	02f70363          	beq	a4,a5,80003ce4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cc2:	ffffe097          	auipc	ra,0xffffe
    80003cc6:	cf6080e7          	jalr	-778(ra) # 800019b8 <myproc>
    80003cca:	15053503          	ld	a0,336(a0)
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	9f6080e7          	jalr	-1546(ra) # 800036c4 <idup>
    80003cd6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cd8:	02f00913          	li	s2,47
  len = path - s;
    80003cdc:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cde:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ce0:	4c05                	li	s8,1
    80003ce2:	a865                	j	80003d9a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ce4:	4585                	li	a1,1
    80003ce6:	4505                	li	a0,1
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	6e6080e7          	jalr	1766(ra) # 800033ce <iget>
    80003cf0:	89aa                	mv	s3,a0
    80003cf2:	b7dd                	j	80003cd8 <namex+0x42>
      iunlockput(ip);
    80003cf4:	854e                	mv	a0,s3
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	c6e080e7          	jalr	-914(ra) # 80003964 <iunlockput>
      return 0;
    80003cfe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d00:	854e                	mv	a0,s3
    80003d02:	60e6                	ld	ra,88(sp)
    80003d04:	6446                	ld	s0,80(sp)
    80003d06:	64a6                	ld	s1,72(sp)
    80003d08:	6906                	ld	s2,64(sp)
    80003d0a:	79e2                	ld	s3,56(sp)
    80003d0c:	7a42                	ld	s4,48(sp)
    80003d0e:	7aa2                	ld	s5,40(sp)
    80003d10:	7b02                	ld	s6,32(sp)
    80003d12:	6be2                	ld	s7,24(sp)
    80003d14:	6c42                	ld	s8,16(sp)
    80003d16:	6ca2                	ld	s9,8(sp)
    80003d18:	6125                	addi	sp,sp,96
    80003d1a:	8082                	ret
      iunlock(ip);
    80003d1c:	854e                	mv	a0,s3
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	aa6080e7          	jalr	-1370(ra) # 800037c4 <iunlock>
      return ip;
    80003d26:	bfe9                	j	80003d00 <namex+0x6a>
      iunlockput(ip);
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	c3a080e7          	jalr	-966(ra) # 80003964 <iunlockput>
      return 0;
    80003d32:	89d2                	mv	s3,s4
    80003d34:	b7f1                	j	80003d00 <namex+0x6a>
  len = path - s;
    80003d36:	40b48633          	sub	a2,s1,a1
    80003d3a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d3e:	094cd463          	bge	s9,s4,80003dc6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d42:	4639                	li	a2,14
    80003d44:	8556                	mv	a0,s5
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	ffa080e7          	jalr	-6(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d4e:	0004c783          	lbu	a5,0(s1)
    80003d52:	01279763          	bne	a5,s2,80003d60 <namex+0xca>
    path++;
    80003d56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d58:	0004c783          	lbu	a5,0(s1)
    80003d5c:	ff278de3          	beq	a5,s2,80003d56 <namex+0xc0>
    ilock(ip);
    80003d60:	854e                	mv	a0,s3
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	9a0080e7          	jalr	-1632(ra) # 80003702 <ilock>
    if(ip->type != T_DIR){
    80003d6a:	04499783          	lh	a5,68(s3)
    80003d6e:	f98793e3          	bne	a5,s8,80003cf4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d72:	000b0563          	beqz	s6,80003d7c <namex+0xe6>
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	d3cd                	beqz	a5,80003d1c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d7c:	865e                	mv	a2,s7
    80003d7e:	85d6                	mv	a1,s5
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	e64080e7          	jalr	-412(ra) # 80003be6 <dirlookup>
    80003d8a:	8a2a                	mv	s4,a0
    80003d8c:	dd51                	beqz	a0,80003d28 <namex+0x92>
    iunlockput(ip);
    80003d8e:	854e                	mv	a0,s3
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	bd4080e7          	jalr	-1068(ra) # 80003964 <iunlockput>
    ip = next;
    80003d98:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d9a:	0004c783          	lbu	a5,0(s1)
    80003d9e:	05279763          	bne	a5,s2,80003dec <namex+0x156>
    path++;
    80003da2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da4:	0004c783          	lbu	a5,0(s1)
    80003da8:	ff278de3          	beq	a5,s2,80003da2 <namex+0x10c>
  if(*path == 0)
    80003dac:	c79d                	beqz	a5,80003dda <namex+0x144>
    path++;
    80003dae:	85a6                	mv	a1,s1
  len = path - s;
    80003db0:	8a5e                	mv	s4,s7
    80003db2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003db4:	01278963          	beq	a5,s2,80003dc6 <namex+0x130>
    80003db8:	dfbd                	beqz	a5,80003d36 <namex+0xa0>
    path++;
    80003dba:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dbc:	0004c783          	lbu	a5,0(s1)
    80003dc0:	ff279ce3          	bne	a5,s2,80003db8 <namex+0x122>
    80003dc4:	bf8d                	j	80003d36 <namex+0xa0>
    memmove(name, s, len);
    80003dc6:	2601                	sext.w	a2,a2
    80003dc8:	8556                	mv	a0,s5
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	f76080e7          	jalr	-138(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003dd2:	9a56                	add	s4,s4,s5
    80003dd4:	000a0023          	sb	zero,0(s4)
    80003dd8:	bf9d                	j	80003d4e <namex+0xb8>
  if(nameiparent){
    80003dda:	f20b03e3          	beqz	s6,80003d00 <namex+0x6a>
    iput(ip);
    80003dde:	854e                	mv	a0,s3
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	adc080e7          	jalr	-1316(ra) # 800038bc <iput>
    return 0;
    80003de8:	4981                	li	s3,0
    80003dea:	bf19                	j	80003d00 <namex+0x6a>
  if(*path == 0)
    80003dec:	d7fd                	beqz	a5,80003dda <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dee:	0004c783          	lbu	a5,0(s1)
    80003df2:	85a6                	mv	a1,s1
    80003df4:	b7d1                	j	80003db8 <namex+0x122>

0000000080003df6 <dirlink>:
{
    80003df6:	7139                	addi	sp,sp,-64
    80003df8:	fc06                	sd	ra,56(sp)
    80003dfa:	f822                	sd	s0,48(sp)
    80003dfc:	f426                	sd	s1,40(sp)
    80003dfe:	f04a                	sd	s2,32(sp)
    80003e00:	ec4e                	sd	s3,24(sp)
    80003e02:	e852                	sd	s4,16(sp)
    80003e04:	0080                	addi	s0,sp,64
    80003e06:	892a                	mv	s2,a0
    80003e08:	8a2e                	mv	s4,a1
    80003e0a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e0c:	4601                	li	a2,0
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	dd8080e7          	jalr	-552(ra) # 80003be6 <dirlookup>
    80003e16:	e93d                	bnez	a0,80003e8c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e18:	04c92483          	lw	s1,76(s2)
    80003e1c:	c49d                	beqz	s1,80003e4a <dirlink+0x54>
    80003e1e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e20:	4741                	li	a4,16
    80003e22:	86a6                	mv	a3,s1
    80003e24:	fc040613          	addi	a2,s0,-64
    80003e28:	4581                	li	a1,0
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	b8a080e7          	jalr	-1142(ra) # 800039b6 <readi>
    80003e34:	47c1                	li	a5,16
    80003e36:	06f51163          	bne	a0,a5,80003e98 <dirlink+0xa2>
    if(de.inum == 0)
    80003e3a:	fc045783          	lhu	a5,-64(s0)
    80003e3e:	c791                	beqz	a5,80003e4a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e40:	24c1                	addiw	s1,s1,16
    80003e42:	04c92783          	lw	a5,76(s2)
    80003e46:	fcf4ede3          	bltu	s1,a5,80003e20 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e4a:	4639                	li	a2,14
    80003e4c:	85d2                	mv	a1,s4
    80003e4e:	fc240513          	addi	a0,s0,-62
    80003e52:	ffffd097          	auipc	ra,0xffffd
    80003e56:	fa2080e7          	jalr	-94(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e5a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5e:	4741                	li	a4,16
    80003e60:	86a6                	mv	a3,s1
    80003e62:	fc040613          	addi	a2,s0,-64
    80003e66:	4581                	li	a1,0
    80003e68:	854a                	mv	a0,s2
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	c44080e7          	jalr	-956(ra) # 80003aae <writei>
    80003e72:	872a                	mv	a4,a0
    80003e74:	47c1                	li	a5,16
  return 0;
    80003e76:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e78:	02f71863          	bne	a4,a5,80003ea8 <dirlink+0xb2>
}
    80003e7c:	70e2                	ld	ra,56(sp)
    80003e7e:	7442                	ld	s0,48(sp)
    80003e80:	74a2                	ld	s1,40(sp)
    80003e82:	7902                	ld	s2,32(sp)
    80003e84:	69e2                	ld	s3,24(sp)
    80003e86:	6a42                	ld	s4,16(sp)
    80003e88:	6121                	addi	sp,sp,64
    80003e8a:	8082                	ret
    iput(ip);
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	a30080e7          	jalr	-1488(ra) # 800038bc <iput>
    return -1;
    80003e94:	557d                	li	a0,-1
    80003e96:	b7dd                	j	80003e7c <dirlink+0x86>
      panic("dirlink read");
    80003e98:	00004517          	auipc	a0,0x4
    80003e9c:	7a050513          	addi	a0,a0,1952 # 80008638 <syscalls+0x1d8>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	69e080e7          	jalr	1694(ra) # 8000053e <panic>
    panic("dirlink");
    80003ea8:	00005517          	auipc	a0,0x5
    80003eac:	8a050513          	addi	a0,a0,-1888 # 80008748 <syscalls+0x2e8>
    80003eb0:	ffffc097          	auipc	ra,0xffffc
    80003eb4:	68e080e7          	jalr	1678(ra) # 8000053e <panic>

0000000080003eb8 <namei>:

struct inode*
namei(char *path)
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ec0:	fe040613          	addi	a2,s0,-32
    80003ec4:	4581                	li	a1,0
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	dd0080e7          	jalr	-560(ra) # 80003c96 <namex>
}
    80003ece:	60e2                	ld	ra,24(sp)
    80003ed0:	6442                	ld	s0,16(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed6:	1141                	addi	sp,sp,-16
    80003ed8:	e406                	sd	ra,8(sp)
    80003eda:	e022                	sd	s0,0(sp)
    80003edc:	0800                	addi	s0,sp,16
    80003ede:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ee0:	4585                	li	a1,1
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	db4080e7          	jalr	-588(ra) # 80003c96 <namex>
}
    80003eea:	60a2                	ld	ra,8(sp)
    80003eec:	6402                	ld	s0,0(sp)
    80003eee:	0141                	addi	sp,sp,16
    80003ef0:	8082                	ret

0000000080003ef2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ef2:	1101                	addi	sp,sp,-32
    80003ef4:	ec06                	sd	ra,24(sp)
    80003ef6:	e822                	sd	s0,16(sp)
    80003ef8:	e426                	sd	s1,8(sp)
    80003efa:	e04a                	sd	s2,0(sp)
    80003efc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003efe:	0001d917          	auipc	s2,0x1d
    80003f02:	37290913          	addi	s2,s2,882 # 80021270 <log>
    80003f06:	01892583          	lw	a1,24(s2)
    80003f0a:	02892503          	lw	a0,40(s2)
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	ff2080e7          	jalr	-14(ra) # 80002f00 <bread>
    80003f16:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f18:	02c92683          	lw	a3,44(s2)
    80003f1c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f1e:	02d05763          	blez	a3,80003f4c <write_head+0x5a>
    80003f22:	0001d797          	auipc	a5,0x1d
    80003f26:	37e78793          	addi	a5,a5,894 # 800212a0 <log+0x30>
    80003f2a:	05c50713          	addi	a4,a0,92
    80003f2e:	36fd                	addiw	a3,a3,-1
    80003f30:	1682                	slli	a3,a3,0x20
    80003f32:	9281                	srli	a3,a3,0x20
    80003f34:	068a                	slli	a3,a3,0x2
    80003f36:	0001d617          	auipc	a2,0x1d
    80003f3a:	36e60613          	addi	a2,a2,878 # 800212a4 <log+0x34>
    80003f3e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f40:	4390                	lw	a2,0(a5)
    80003f42:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f44:	0791                	addi	a5,a5,4
    80003f46:	0711                	addi	a4,a4,4
    80003f48:	fed79ce3          	bne	a5,a3,80003f40 <write_head+0x4e>
  }
  bwrite(buf);
    80003f4c:	8526                	mv	a0,s1
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	0a4080e7          	jalr	164(ra) # 80002ff2 <bwrite>
  brelse(buf);
    80003f56:	8526                	mv	a0,s1
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	0d8080e7          	jalr	216(ra) # 80003030 <brelse>
}
    80003f60:	60e2                	ld	ra,24(sp)
    80003f62:	6442                	ld	s0,16(sp)
    80003f64:	64a2                	ld	s1,8(sp)
    80003f66:	6902                	ld	s2,0(sp)
    80003f68:	6105                	addi	sp,sp,32
    80003f6a:	8082                	ret

0000000080003f6c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f6c:	0001d797          	auipc	a5,0x1d
    80003f70:	3307a783          	lw	a5,816(a5) # 8002129c <log+0x2c>
    80003f74:	0af05d63          	blez	a5,8000402e <install_trans+0xc2>
{
    80003f78:	7139                	addi	sp,sp,-64
    80003f7a:	fc06                	sd	ra,56(sp)
    80003f7c:	f822                	sd	s0,48(sp)
    80003f7e:	f426                	sd	s1,40(sp)
    80003f80:	f04a                	sd	s2,32(sp)
    80003f82:	ec4e                	sd	s3,24(sp)
    80003f84:	e852                	sd	s4,16(sp)
    80003f86:	e456                	sd	s5,8(sp)
    80003f88:	e05a                	sd	s6,0(sp)
    80003f8a:	0080                	addi	s0,sp,64
    80003f8c:	8b2a                	mv	s6,a0
    80003f8e:	0001da97          	auipc	s5,0x1d
    80003f92:	312a8a93          	addi	s5,s5,786 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f96:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f98:	0001d997          	auipc	s3,0x1d
    80003f9c:	2d898993          	addi	s3,s3,728 # 80021270 <log>
    80003fa0:	a035                	j	80003fcc <install_trans+0x60>
      bunpin(dbuf);
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	166080e7          	jalr	358(ra) # 8000310a <bunpin>
    brelse(lbuf);
    80003fac:	854a                	mv	a0,s2
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	082080e7          	jalr	130(ra) # 80003030 <brelse>
    brelse(dbuf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	078080e7          	jalr	120(ra) # 80003030 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc0:	2a05                	addiw	s4,s4,1
    80003fc2:	0a91                	addi	s5,s5,4
    80003fc4:	02c9a783          	lw	a5,44(s3)
    80003fc8:	04fa5963          	bge	s4,a5,8000401a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fcc:	0189a583          	lw	a1,24(s3)
    80003fd0:	014585bb          	addw	a1,a1,s4
    80003fd4:	2585                	addiw	a1,a1,1
    80003fd6:	0289a503          	lw	a0,40(s3)
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	f26080e7          	jalr	-218(ra) # 80002f00 <bread>
    80003fe2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fe4:	000aa583          	lw	a1,0(s5)
    80003fe8:	0289a503          	lw	a0,40(s3)
    80003fec:	fffff097          	auipc	ra,0xfffff
    80003ff0:	f14080e7          	jalr	-236(ra) # 80002f00 <bread>
    80003ff4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ff6:	40000613          	li	a2,1024
    80003ffa:	05890593          	addi	a1,s2,88
    80003ffe:	05850513          	addi	a0,a0,88
    80004002:	ffffd097          	auipc	ra,0xffffd
    80004006:	d3e080e7          	jalr	-706(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	fe6080e7          	jalr	-26(ra) # 80002ff2 <bwrite>
    if(recovering == 0)
    80004014:	f80b1ce3          	bnez	s6,80003fac <install_trans+0x40>
    80004018:	b769                	j	80003fa2 <install_trans+0x36>
}
    8000401a:	70e2                	ld	ra,56(sp)
    8000401c:	7442                	ld	s0,48(sp)
    8000401e:	74a2                	ld	s1,40(sp)
    80004020:	7902                	ld	s2,32(sp)
    80004022:	69e2                	ld	s3,24(sp)
    80004024:	6a42                	ld	s4,16(sp)
    80004026:	6aa2                	ld	s5,8(sp)
    80004028:	6b02                	ld	s6,0(sp)
    8000402a:	6121                	addi	sp,sp,64
    8000402c:	8082                	ret
    8000402e:	8082                	ret

0000000080004030 <initlog>:
{
    80004030:	7179                	addi	sp,sp,-48
    80004032:	f406                	sd	ra,40(sp)
    80004034:	f022                	sd	s0,32(sp)
    80004036:	ec26                	sd	s1,24(sp)
    80004038:	e84a                	sd	s2,16(sp)
    8000403a:	e44e                	sd	s3,8(sp)
    8000403c:	1800                	addi	s0,sp,48
    8000403e:	892a                	mv	s2,a0
    80004040:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004042:	0001d497          	auipc	s1,0x1d
    80004046:	22e48493          	addi	s1,s1,558 # 80021270 <log>
    8000404a:	00004597          	auipc	a1,0x4
    8000404e:	5fe58593          	addi	a1,a1,1534 # 80008648 <syscalls+0x1e8>
    80004052:	8526                	mv	a0,s1
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	b00080e7          	jalr	-1280(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000405c:	0149a583          	lw	a1,20(s3)
    80004060:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004062:	0109a783          	lw	a5,16(s3)
    80004066:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004068:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000406c:	854a                	mv	a0,s2
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	e92080e7          	jalr	-366(ra) # 80002f00 <bread>
  log.lh.n = lh->n;
    80004076:	4d3c                	lw	a5,88(a0)
    80004078:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	02f05563          	blez	a5,800040a4 <initlog+0x74>
    8000407e:	05c50713          	addi	a4,a0,92
    80004082:	0001d697          	auipc	a3,0x1d
    80004086:	21e68693          	addi	a3,a3,542 # 800212a0 <log+0x30>
    8000408a:	37fd                	addiw	a5,a5,-1
    8000408c:	1782                	slli	a5,a5,0x20
    8000408e:	9381                	srli	a5,a5,0x20
    80004090:	078a                	slli	a5,a5,0x2
    80004092:	06050613          	addi	a2,a0,96
    80004096:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004098:	4310                	lw	a2,0(a4)
    8000409a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000409c:	0711                	addi	a4,a4,4
    8000409e:	0691                	addi	a3,a3,4
    800040a0:	fef71ce3          	bne	a4,a5,80004098 <initlog+0x68>
  brelse(buf);
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	f8c080e7          	jalr	-116(ra) # 80003030 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040ac:	4505                	li	a0,1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	ebe080e7          	jalr	-322(ra) # 80003f6c <install_trans>
  log.lh.n = 0;
    800040b6:	0001d797          	auipc	a5,0x1d
    800040ba:	1e07a323          	sw	zero,486(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	e34080e7          	jalr	-460(ra) # 80003ef2 <write_head>
}
    800040c6:	70a2                	ld	ra,40(sp)
    800040c8:	7402                	ld	s0,32(sp)
    800040ca:	64e2                	ld	s1,24(sp)
    800040cc:	6942                	ld	s2,16(sp)
    800040ce:	69a2                	ld	s3,8(sp)
    800040d0:	6145                	addi	sp,sp,48
    800040d2:	8082                	ret

00000000800040d4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040d4:	1101                	addi	sp,sp,-32
    800040d6:	ec06                	sd	ra,24(sp)
    800040d8:	e822                	sd	s0,16(sp)
    800040da:	e426                	sd	s1,8(sp)
    800040dc:	e04a                	sd	s2,0(sp)
    800040de:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040e0:	0001d517          	auipc	a0,0x1d
    800040e4:	19050513          	addi	a0,a0,400 # 80021270 <log>
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040f0:	0001d497          	auipc	s1,0x1d
    800040f4:	18048493          	addi	s1,s1,384 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f8:	4979                	li	s2,30
    800040fa:	a039                	j	80004108 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040fc:	85a6                	mv	a1,s1
    800040fe:	8526                	mv	a0,s1
    80004100:	ffffe097          	auipc	ra,0xffffe
    80004104:	fb4080e7          	jalr	-76(ra) # 800020b4 <sleep>
    if(log.committing){
    80004108:	50dc                	lw	a5,36(s1)
    8000410a:	fbed                	bnez	a5,800040fc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000410c:	509c                	lw	a5,32(s1)
    8000410e:	0017871b          	addiw	a4,a5,1
    80004112:	0007069b          	sext.w	a3,a4
    80004116:	0027179b          	slliw	a5,a4,0x2
    8000411a:	9fb9                	addw	a5,a5,a4
    8000411c:	0017979b          	slliw	a5,a5,0x1
    80004120:	54d8                	lw	a4,44(s1)
    80004122:	9fb9                	addw	a5,a5,a4
    80004124:	00f95963          	bge	s2,a5,80004136 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004128:	85a6                	mv	a1,s1
    8000412a:	8526                	mv	a0,s1
    8000412c:	ffffe097          	auipc	ra,0xffffe
    80004130:	f88080e7          	jalr	-120(ra) # 800020b4 <sleep>
    80004134:	bfd1                	j	80004108 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004136:	0001d517          	auipc	a0,0x1d
    8000413a:	13a50513          	addi	a0,a0,314 # 80021270 <log>
    8000413e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	b58080e7          	jalr	-1192(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004148:	60e2                	ld	ra,24(sp)
    8000414a:	6442                	ld	s0,16(sp)
    8000414c:	64a2                	ld	s1,8(sp)
    8000414e:	6902                	ld	s2,0(sp)
    80004150:	6105                	addi	sp,sp,32
    80004152:	8082                	ret

0000000080004154 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004154:	7139                	addi	sp,sp,-64
    80004156:	fc06                	sd	ra,56(sp)
    80004158:	f822                	sd	s0,48(sp)
    8000415a:	f426                	sd	s1,40(sp)
    8000415c:	f04a                	sd	s2,32(sp)
    8000415e:	ec4e                	sd	s3,24(sp)
    80004160:	e852                	sd	s4,16(sp)
    80004162:	e456                	sd	s5,8(sp)
    80004164:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004166:	0001d497          	auipc	s1,0x1d
    8000416a:	10a48493          	addi	s1,s1,266 # 80021270 <log>
    8000416e:	8526                	mv	a0,s1
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	a74080e7          	jalr	-1420(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004178:	509c                	lw	a5,32(s1)
    8000417a:	37fd                	addiw	a5,a5,-1
    8000417c:	0007891b          	sext.w	s2,a5
    80004180:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004182:	50dc                	lw	a5,36(s1)
    80004184:	efb9                	bnez	a5,800041e2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004186:	06091663          	bnez	s2,800041f2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	0e648493          	addi	s1,s1,230 # 80021270 <log>
    80004192:	4785                	li	a5,1
    80004194:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004196:	8526                	mv	a0,s1
    80004198:	ffffd097          	auipc	ra,0xffffd
    8000419c:	b00080e7          	jalr	-1280(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041a0:	54dc                	lw	a5,44(s1)
    800041a2:	06f04763          	bgtz	a5,80004210 <end_op+0xbc>
    acquire(&log.lock);
    800041a6:	0001d497          	auipc	s1,0x1d
    800041aa:	0ca48493          	addi	s1,s1,202 # 80021270 <log>
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	a34080e7          	jalr	-1484(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041b8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	082080e7          	jalr	130(ra) # 80002240 <wakeup>
    release(&log.lock);
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	ad0080e7          	jalr	-1328(ra) # 80000c98 <release>
}
    800041d0:	70e2                	ld	ra,56(sp)
    800041d2:	7442                	ld	s0,48(sp)
    800041d4:	74a2                	ld	s1,40(sp)
    800041d6:	7902                	ld	s2,32(sp)
    800041d8:	69e2                	ld	s3,24(sp)
    800041da:	6a42                	ld	s4,16(sp)
    800041dc:	6aa2                	ld	s5,8(sp)
    800041de:	6121                	addi	sp,sp,64
    800041e0:	8082                	ret
    panic("log.committing");
    800041e2:	00004517          	auipc	a0,0x4
    800041e6:	46e50513          	addi	a0,a0,1134 # 80008650 <syscalls+0x1f0>
    800041ea:	ffffc097          	auipc	ra,0xffffc
    800041ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
    wakeup(&log);
    800041f2:	0001d497          	auipc	s1,0x1d
    800041f6:	07e48493          	addi	s1,s1,126 # 80021270 <log>
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffe097          	auipc	ra,0xffffe
    80004200:	044080e7          	jalr	68(ra) # 80002240 <wakeup>
  release(&log.lock);
    80004204:	8526                	mv	a0,s1
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
  if(do_commit){
    8000420e:	b7c9                	j	800041d0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004210:	0001da97          	auipc	s5,0x1d
    80004214:	090a8a93          	addi	s5,s5,144 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004218:	0001da17          	auipc	s4,0x1d
    8000421c:	058a0a13          	addi	s4,s4,88 # 80021270 <log>
    80004220:	018a2583          	lw	a1,24(s4)
    80004224:	012585bb          	addw	a1,a1,s2
    80004228:	2585                	addiw	a1,a1,1
    8000422a:	028a2503          	lw	a0,40(s4)
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	cd2080e7          	jalr	-814(ra) # 80002f00 <bread>
    80004236:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004238:	000aa583          	lw	a1,0(s5)
    8000423c:	028a2503          	lw	a0,40(s4)
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	cc0080e7          	jalr	-832(ra) # 80002f00 <bread>
    80004248:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000424a:	40000613          	li	a2,1024
    8000424e:	05850593          	addi	a1,a0,88
    80004252:	05848513          	addi	a0,s1,88
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	aea080e7          	jalr	-1302(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000425e:	8526                	mv	a0,s1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	d92080e7          	jalr	-622(ra) # 80002ff2 <bwrite>
    brelse(from);
    80004268:	854e                	mv	a0,s3
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	dc6080e7          	jalr	-570(ra) # 80003030 <brelse>
    brelse(to);
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	dbc080e7          	jalr	-580(ra) # 80003030 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000427c:	2905                	addiw	s2,s2,1
    8000427e:	0a91                	addi	s5,s5,4
    80004280:	02ca2783          	lw	a5,44(s4)
    80004284:	f8f94ee3          	blt	s2,a5,80004220 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	c6a080e7          	jalr	-918(ra) # 80003ef2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004290:	4501                	li	a0,0
    80004292:	00000097          	auipc	ra,0x0
    80004296:	cda080e7          	jalr	-806(ra) # 80003f6c <install_trans>
    log.lh.n = 0;
    8000429a:	0001d797          	auipc	a5,0x1d
    8000429e:	0007a123          	sw	zero,2(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	c50080e7          	jalr	-944(ra) # 80003ef2 <write_head>
    800042aa:	bdf5                	j	800041a6 <end_op+0x52>

00000000800042ac <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	e426                	sd	s1,8(sp)
    800042b4:	e04a                	sd	s2,0(sp)
    800042b6:	1000                	addi	s0,sp,32
    800042b8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042ba:	0001d917          	auipc	s2,0x1d
    800042be:	fb690913          	addi	s2,s2,-74 # 80021270 <log>
    800042c2:	854a                	mv	a0,s2
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	920080e7          	jalr	-1760(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042cc:	02c92603          	lw	a2,44(s2)
    800042d0:	47f5                	li	a5,29
    800042d2:	06c7c563          	blt	a5,a2,8000433c <log_write+0x90>
    800042d6:	0001d797          	auipc	a5,0x1d
    800042da:	fb67a783          	lw	a5,-74(a5) # 8002128c <log+0x1c>
    800042de:	37fd                	addiw	a5,a5,-1
    800042e0:	04f65e63          	bge	a2,a5,8000433c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e4:	0001d797          	auipc	a5,0x1d
    800042e8:	fac7a783          	lw	a5,-84(a5) # 80021290 <log+0x20>
    800042ec:	06f05063          	blez	a5,8000434c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042f0:	4781                	li	a5,0
    800042f2:	06c05563          	blez	a2,8000435c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f6:	44cc                	lw	a1,12(s1)
    800042f8:	0001d717          	auipc	a4,0x1d
    800042fc:	fa870713          	addi	a4,a4,-88 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004300:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004302:	4314                	lw	a3,0(a4)
    80004304:	04b68c63          	beq	a3,a1,8000435c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004308:	2785                	addiw	a5,a5,1
    8000430a:	0711                	addi	a4,a4,4
    8000430c:	fef61be3          	bne	a2,a5,80004302 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004310:	0621                	addi	a2,a2,8
    80004312:	060a                	slli	a2,a2,0x2
    80004314:	0001d797          	auipc	a5,0x1d
    80004318:	f5c78793          	addi	a5,a5,-164 # 80021270 <log>
    8000431c:	963e                	add	a2,a2,a5
    8000431e:	44dc                	lw	a5,12(s1)
    80004320:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	daa080e7          	jalr	-598(ra) # 800030ce <bpin>
    log.lh.n++;
    8000432c:	0001d717          	auipc	a4,0x1d
    80004330:	f4470713          	addi	a4,a4,-188 # 80021270 <log>
    80004334:	575c                	lw	a5,44(a4)
    80004336:	2785                	addiw	a5,a5,1
    80004338:	d75c                	sw	a5,44(a4)
    8000433a:	a835                	j	80004376 <log_write+0xca>
    panic("too big a transaction");
    8000433c:	00004517          	auipc	a0,0x4
    80004340:	32450513          	addi	a0,a0,804 # 80008660 <syscalls+0x200>
    80004344:	ffffc097          	auipc	ra,0xffffc
    80004348:	1fa080e7          	jalr	506(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000434c:	00004517          	auipc	a0,0x4
    80004350:	32c50513          	addi	a0,a0,812 # 80008678 <syscalls+0x218>
    80004354:	ffffc097          	auipc	ra,0xffffc
    80004358:	1ea080e7          	jalr	490(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000435c:	00878713          	addi	a4,a5,8
    80004360:	00271693          	slli	a3,a4,0x2
    80004364:	0001d717          	auipc	a4,0x1d
    80004368:	f0c70713          	addi	a4,a4,-244 # 80021270 <log>
    8000436c:	9736                	add	a4,a4,a3
    8000436e:	44d4                	lw	a3,12(s1)
    80004370:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004372:	faf608e3          	beq	a2,a5,80004322 <log_write+0x76>
  }
  release(&log.lock);
    80004376:	0001d517          	auipc	a0,0x1d
    8000437a:	efa50513          	addi	a0,a0,-262 # 80021270 <log>
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
}
    80004386:	60e2                	ld	ra,24(sp)
    80004388:	6442                	ld	s0,16(sp)
    8000438a:	64a2                	ld	s1,8(sp)
    8000438c:	6902                	ld	s2,0(sp)
    8000438e:	6105                	addi	sp,sp,32
    80004390:	8082                	ret

0000000080004392 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004392:	1101                	addi	sp,sp,-32
    80004394:	ec06                	sd	ra,24(sp)
    80004396:	e822                	sd	s0,16(sp)
    80004398:	e426                	sd	s1,8(sp)
    8000439a:	e04a                	sd	s2,0(sp)
    8000439c:	1000                	addi	s0,sp,32
    8000439e:	84aa                	mv	s1,a0
    800043a0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043a2:	00004597          	auipc	a1,0x4
    800043a6:	2f658593          	addi	a1,a1,758 # 80008698 <syscalls+0x238>
    800043aa:	0521                	addi	a0,a0,8
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	7a8080e7          	jalr	1960(ra) # 80000b54 <initlock>
  lk->name = name;
    800043b4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043bc:	0204a423          	sw	zero,40(s1)
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	64a2                	ld	s1,8(sp)
    800043c6:	6902                	ld	s2,0(sp)
    800043c8:	6105                	addi	sp,sp,32
    800043ca:	8082                	ret

00000000800043cc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043cc:	1101                	addi	sp,sp,-32
    800043ce:	ec06                	sd	ra,24(sp)
    800043d0:	e822                	sd	s0,16(sp)
    800043d2:	e426                	sd	s1,8(sp)
    800043d4:	e04a                	sd	s2,0(sp)
    800043d6:	1000                	addi	s0,sp,32
    800043d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043da:	00850913          	addi	s2,a0,8
    800043de:	854a                	mv	a0,s2
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	804080e7          	jalr	-2044(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043e8:	409c                	lw	a5,0(s1)
    800043ea:	cb89                	beqz	a5,800043fc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043ec:	85ca                	mv	a1,s2
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffe097          	auipc	ra,0xffffe
    800043f4:	cc4080e7          	jalr	-828(ra) # 800020b4 <sleep>
  while (lk->locked) {
    800043f8:	409c                	lw	a5,0(s1)
    800043fa:	fbed                	bnez	a5,800043ec <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043fc:	4785                	li	a5,1
    800043fe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	5b8080e7          	jalr	1464(ra) # 800019b8 <myproc>
    80004408:	591c                	lw	a5,48(a0)
    8000440a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000440c:	854a                	mv	a0,s2
    8000440e:	ffffd097          	auipc	ra,0xffffd
    80004412:	88a080e7          	jalr	-1910(ra) # 80000c98 <release>
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6902                	ld	s2,0(sp)
    8000441e:	6105                	addi	sp,sp,32
    80004420:	8082                	ret

0000000080004422 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004422:	1101                	addi	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	e04a                	sd	s2,0(sp)
    8000442c:	1000                	addi	s0,sp,32
    8000442e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004430:	00850913          	addi	s2,a0,8
    80004434:	854a                	mv	a0,s2
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	7ae080e7          	jalr	1966(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000443e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004442:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004446:	8526                	mv	a0,s1
    80004448:	ffffe097          	auipc	ra,0xffffe
    8000444c:	df8080e7          	jalr	-520(ra) # 80002240 <wakeup>
  release(&lk->lk);
    80004450:	854a                	mv	a0,s2
    80004452:	ffffd097          	auipc	ra,0xffffd
    80004456:	846080e7          	jalr	-1978(ra) # 80000c98 <release>
}
    8000445a:	60e2                	ld	ra,24(sp)
    8000445c:	6442                	ld	s0,16(sp)
    8000445e:	64a2                	ld	s1,8(sp)
    80004460:	6902                	ld	s2,0(sp)
    80004462:	6105                	addi	sp,sp,32
    80004464:	8082                	ret

0000000080004466 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004466:	7179                	addi	sp,sp,-48
    80004468:	f406                	sd	ra,40(sp)
    8000446a:	f022                	sd	s0,32(sp)
    8000446c:	ec26                	sd	s1,24(sp)
    8000446e:	e84a                	sd	s2,16(sp)
    80004470:	e44e                	sd	s3,8(sp)
    80004472:	1800                	addi	s0,sp,48
    80004474:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004476:	00850913          	addi	s2,a0,8
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004484:	409c                	lw	a5,0(s1)
    80004486:	ef99                	bnez	a5,800044a4 <holdingsleep+0x3e>
    80004488:	4481                	li	s1,0
  release(&lk->lk);
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	80c080e7          	jalr	-2036(ra) # 80000c98 <release>
  return r;
}
    80004494:	8526                	mv	a0,s1
    80004496:	70a2                	ld	ra,40(sp)
    80004498:	7402                	ld	s0,32(sp)
    8000449a:	64e2                	ld	s1,24(sp)
    8000449c:	6942                	ld	s2,16(sp)
    8000449e:	69a2                	ld	s3,8(sp)
    800044a0:	6145                	addi	sp,sp,48
    800044a2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a4:	0284a983          	lw	s3,40(s1)
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	510080e7          	jalr	1296(ra) # 800019b8 <myproc>
    800044b0:	5904                	lw	s1,48(a0)
    800044b2:	413484b3          	sub	s1,s1,s3
    800044b6:	0014b493          	seqz	s1,s1
    800044ba:	bfc1                	j	8000448a <holdingsleep+0x24>

00000000800044bc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044bc:	1141                	addi	sp,sp,-16
    800044be:	e406                	sd	ra,8(sp)
    800044c0:	e022                	sd	s0,0(sp)
    800044c2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044c4:	00004597          	auipc	a1,0x4
    800044c8:	1e458593          	addi	a1,a1,484 # 800086a8 <syscalls+0x248>
    800044cc:	0001d517          	auipc	a0,0x1d
    800044d0:	eec50513          	addi	a0,a0,-276 # 800213b8 <ftable>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	680080e7          	jalr	1664(ra) # 80000b54 <initlock>
}
    800044dc:	60a2                	ld	ra,8(sp)
    800044de:	6402                	ld	s0,0(sp)
    800044e0:	0141                	addi	sp,sp,16
    800044e2:	8082                	ret

00000000800044e4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ee:	0001d517          	auipc	a0,0x1d
    800044f2:	eca50513          	addi	a0,a0,-310 # 800213b8 <ftable>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	6ee080e7          	jalr	1774(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044fe:	0001d497          	auipc	s1,0x1d
    80004502:	ed248493          	addi	s1,s1,-302 # 800213d0 <ftable+0x18>
    80004506:	0001e717          	auipc	a4,0x1e
    8000450a:	e6a70713          	addi	a4,a4,-406 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000450e:	40dc                	lw	a5,4(s1)
    80004510:	cf99                	beqz	a5,8000452e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004512:	02848493          	addi	s1,s1,40
    80004516:	fee49ce3          	bne	s1,a4,8000450e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000451a:	0001d517          	auipc	a0,0x1d
    8000451e:	e9e50513          	addi	a0,a0,-354 # 800213b8 <ftable>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
  return 0;
    8000452a:	4481                	li	s1,0
    8000452c:	a819                	j	80004542 <filealloc+0x5e>
      f->ref = 1;
    8000452e:	4785                	li	a5,1
    80004530:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004532:	0001d517          	auipc	a0,0x1d
    80004536:	e8650513          	addi	a0,a0,-378 # 800213b8 <ftable>
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	75e080e7          	jalr	1886(ra) # 80000c98 <release>
}
    80004542:	8526                	mv	a0,s1
    80004544:	60e2                	ld	ra,24(sp)
    80004546:	6442                	ld	s0,16(sp)
    80004548:	64a2                	ld	s1,8(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	1000                	addi	s0,sp,32
    80004558:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	e5e50513          	addi	a0,a0,-418 # 800213b8 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000456a:	40dc                	lw	a5,4(s1)
    8000456c:	02f05263          	blez	a5,80004590 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004570:	2785                	addiw	a5,a5,1
    80004572:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004574:	0001d517          	auipc	a0,0x1d
    80004578:	e4450513          	addi	a0,a0,-444 # 800213b8 <ftable>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	71c080e7          	jalr	1820(ra) # 80000c98 <release>
  return f;
}
    80004584:	8526                	mv	a0,s1
    80004586:	60e2                	ld	ra,24(sp)
    80004588:	6442                	ld	s0,16(sp)
    8000458a:	64a2                	ld	s1,8(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret
    panic("filedup");
    80004590:	00004517          	auipc	a0,0x4
    80004594:	12050513          	addi	a0,a0,288 # 800086b0 <syscalls+0x250>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	fa6080e7          	jalr	-90(ra) # 8000053e <panic>

00000000800045a0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045a0:	7139                	addi	sp,sp,-64
    800045a2:	fc06                	sd	ra,56(sp)
    800045a4:	f822                	sd	s0,48(sp)
    800045a6:	f426                	sd	s1,40(sp)
    800045a8:	f04a                	sd	s2,32(sp)
    800045aa:	ec4e                	sd	s3,24(sp)
    800045ac:	e852                	sd	s4,16(sp)
    800045ae:	e456                	sd	s5,8(sp)
    800045b0:	0080                	addi	s0,sp,64
    800045b2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045b4:	0001d517          	auipc	a0,0x1d
    800045b8:	e0450513          	addi	a0,a0,-508 # 800213b8 <ftable>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	628080e7          	jalr	1576(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045c4:	40dc                	lw	a5,4(s1)
    800045c6:	06f05163          	blez	a5,80004628 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045ca:	37fd                	addiw	a5,a5,-1
    800045cc:	0007871b          	sext.w	a4,a5
    800045d0:	c0dc                	sw	a5,4(s1)
    800045d2:	06e04363          	bgtz	a4,80004638 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d6:	0004a903          	lw	s2,0(s1)
    800045da:	0094ca83          	lbu	s5,9(s1)
    800045de:	0104ba03          	ld	s4,16(s1)
    800045e2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ea:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	dca50513          	addi	a0,a0,-566 # 800213b8 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800045fe:	4785                	li	a5,1
    80004600:	04f90d63          	beq	s2,a5,8000465a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004604:	3979                	addiw	s2,s2,-2
    80004606:	4785                	li	a5,1
    80004608:	0527e063          	bltu	a5,s2,80004648 <fileclose+0xa8>
    begin_op();
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	ac8080e7          	jalr	-1336(ra) # 800040d4 <begin_op>
    iput(ff.ip);
    80004614:	854e                	mv	a0,s3
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	2a6080e7          	jalr	678(ra) # 800038bc <iput>
    end_op();
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	b36080e7          	jalr	-1226(ra) # 80004154 <end_op>
    80004626:	a00d                	j	80004648 <fileclose+0xa8>
    panic("fileclose");
    80004628:	00004517          	auipc	a0,0x4
    8000462c:	09050513          	addi	a0,a0,144 # 800086b8 <syscalls+0x258>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	f0e080e7          	jalr	-242(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004638:	0001d517          	auipc	a0,0x1d
    8000463c:	d8050513          	addi	a0,a0,-640 # 800213b8 <ftable>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
  }
}
    80004648:	70e2                	ld	ra,56(sp)
    8000464a:	7442                	ld	s0,48(sp)
    8000464c:	74a2                	ld	s1,40(sp)
    8000464e:	7902                	ld	s2,32(sp)
    80004650:	69e2                	ld	s3,24(sp)
    80004652:	6a42                	ld	s4,16(sp)
    80004654:	6aa2                	ld	s5,8(sp)
    80004656:	6121                	addi	sp,sp,64
    80004658:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000465a:	85d6                	mv	a1,s5
    8000465c:	8552                	mv	a0,s4
    8000465e:	00000097          	auipc	ra,0x0
    80004662:	34c080e7          	jalr	844(ra) # 800049aa <pipeclose>
    80004666:	b7cd                	j	80004648 <fileclose+0xa8>

0000000080004668 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004668:	715d                	addi	sp,sp,-80
    8000466a:	e486                	sd	ra,72(sp)
    8000466c:	e0a2                	sd	s0,64(sp)
    8000466e:	fc26                	sd	s1,56(sp)
    80004670:	f84a                	sd	s2,48(sp)
    80004672:	f44e                	sd	s3,40(sp)
    80004674:	0880                	addi	s0,sp,80
    80004676:	84aa                	mv	s1,a0
    80004678:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000467a:	ffffd097          	auipc	ra,0xffffd
    8000467e:	33e080e7          	jalr	830(ra) # 800019b8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004682:	409c                	lw	a5,0(s1)
    80004684:	37f9                	addiw	a5,a5,-2
    80004686:	4705                	li	a4,1
    80004688:	04f76763          	bltu	a4,a5,800046d6 <filestat+0x6e>
    8000468c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000468e:	6c88                	ld	a0,24(s1)
    80004690:	fffff097          	auipc	ra,0xfffff
    80004694:	072080e7          	jalr	114(ra) # 80003702 <ilock>
    stati(f->ip, &st);
    80004698:	fb840593          	addi	a1,s0,-72
    8000469c:	6c88                	ld	a0,24(s1)
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	2ee080e7          	jalr	750(ra) # 8000398c <stati>
    iunlock(f->ip);
    800046a6:	6c88                	ld	a0,24(s1)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	11c080e7          	jalr	284(ra) # 800037c4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046b0:	46e1                	li	a3,24
    800046b2:	fb840613          	addi	a2,s0,-72
    800046b6:	85ce                	mv	a1,s3
    800046b8:	05093503          	ld	a0,80(s2)
    800046bc:	ffffd097          	auipc	ra,0xffffd
    800046c0:	fbe080e7          	jalr	-66(ra) # 8000167a <copyout>
    800046c4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c8:	60a6                	ld	ra,72(sp)
    800046ca:	6406                	ld	s0,64(sp)
    800046cc:	74e2                	ld	s1,56(sp)
    800046ce:	7942                	ld	s2,48(sp)
    800046d0:	79a2                	ld	s3,40(sp)
    800046d2:	6161                	addi	sp,sp,80
    800046d4:	8082                	ret
  return -1;
    800046d6:	557d                	li	a0,-1
    800046d8:	bfc5                	j	800046c8 <filestat+0x60>

00000000800046da <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046da:	7179                	addi	sp,sp,-48
    800046dc:	f406                	sd	ra,40(sp)
    800046de:	f022                	sd	s0,32(sp)
    800046e0:	ec26                	sd	s1,24(sp)
    800046e2:	e84a                	sd	s2,16(sp)
    800046e4:	e44e                	sd	s3,8(sp)
    800046e6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e8:	00854783          	lbu	a5,8(a0)
    800046ec:	c3d5                	beqz	a5,80004790 <fileread+0xb6>
    800046ee:	84aa                	mv	s1,a0
    800046f0:	89ae                	mv	s3,a1
    800046f2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046f4:	411c                	lw	a5,0(a0)
    800046f6:	4705                	li	a4,1
    800046f8:	04e78963          	beq	a5,a4,8000474a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046fc:	470d                	li	a4,3
    800046fe:	04e78d63          	beq	a5,a4,80004758 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004702:	4709                	li	a4,2
    80004704:	06e79e63          	bne	a5,a4,80004780 <fileread+0xa6>
    ilock(f->ip);
    80004708:	6d08                	ld	a0,24(a0)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	ff8080e7          	jalr	-8(ra) # 80003702 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004712:	874a                	mv	a4,s2
    80004714:	5094                	lw	a3,32(s1)
    80004716:	864e                	mv	a2,s3
    80004718:	4585                	li	a1,1
    8000471a:	6c88                	ld	a0,24(s1)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	29a080e7          	jalr	666(ra) # 800039b6 <readi>
    80004724:	892a                	mv	s2,a0
    80004726:	00a05563          	blez	a0,80004730 <fileread+0x56>
      f->off += r;
    8000472a:	509c                	lw	a5,32(s1)
    8000472c:	9fa9                	addw	a5,a5,a0
    8000472e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	092080e7          	jalr	146(ra) # 800037c4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000473a:	854a                	mv	a0,s2
    8000473c:	70a2                	ld	ra,40(sp)
    8000473e:	7402                	ld	s0,32(sp)
    80004740:	64e2                	ld	s1,24(sp)
    80004742:	6942                	ld	s2,16(sp)
    80004744:	69a2                	ld	s3,8(sp)
    80004746:	6145                	addi	sp,sp,48
    80004748:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000474a:	6908                	ld	a0,16(a0)
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	3c8080e7          	jalr	968(ra) # 80004b14 <piperead>
    80004754:	892a                	mv	s2,a0
    80004756:	b7d5                	j	8000473a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004758:	02451783          	lh	a5,36(a0)
    8000475c:	03079693          	slli	a3,a5,0x30
    80004760:	92c1                	srli	a3,a3,0x30
    80004762:	4725                	li	a4,9
    80004764:	02d76863          	bltu	a4,a3,80004794 <fileread+0xba>
    80004768:	0792                	slli	a5,a5,0x4
    8000476a:	0001d717          	auipc	a4,0x1d
    8000476e:	bae70713          	addi	a4,a4,-1106 # 80021318 <devsw>
    80004772:	97ba                	add	a5,a5,a4
    80004774:	639c                	ld	a5,0(a5)
    80004776:	c38d                	beqz	a5,80004798 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004778:	4505                	li	a0,1
    8000477a:	9782                	jalr	a5
    8000477c:	892a                	mv	s2,a0
    8000477e:	bf75                	j	8000473a <fileread+0x60>
    panic("fileread");
    80004780:	00004517          	auipc	a0,0x4
    80004784:	f4850513          	addi	a0,a0,-184 # 800086c8 <syscalls+0x268>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	db6080e7          	jalr	-586(ra) # 8000053e <panic>
    return -1;
    80004790:	597d                	li	s2,-1
    80004792:	b765                	j	8000473a <fileread+0x60>
      return -1;
    80004794:	597d                	li	s2,-1
    80004796:	b755                	j	8000473a <fileread+0x60>
    80004798:	597d                	li	s2,-1
    8000479a:	b745                	j	8000473a <fileread+0x60>

000000008000479c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000479c:	715d                	addi	sp,sp,-80
    8000479e:	e486                	sd	ra,72(sp)
    800047a0:	e0a2                	sd	s0,64(sp)
    800047a2:	fc26                	sd	s1,56(sp)
    800047a4:	f84a                	sd	s2,48(sp)
    800047a6:	f44e                	sd	s3,40(sp)
    800047a8:	f052                	sd	s4,32(sp)
    800047aa:	ec56                	sd	s5,24(sp)
    800047ac:	e85a                	sd	s6,16(sp)
    800047ae:	e45e                	sd	s7,8(sp)
    800047b0:	e062                	sd	s8,0(sp)
    800047b2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047b4:	00954783          	lbu	a5,9(a0)
    800047b8:	10078663          	beqz	a5,800048c4 <filewrite+0x128>
    800047bc:	892a                	mv	s2,a0
    800047be:	8aae                	mv	s5,a1
    800047c0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c2:	411c                	lw	a5,0(a0)
    800047c4:	4705                	li	a4,1
    800047c6:	02e78263          	beq	a5,a4,800047ea <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ca:	470d                	li	a4,3
    800047cc:	02e78663          	beq	a5,a4,800047f8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d0:	4709                	li	a4,2
    800047d2:	0ee79163          	bne	a5,a4,800048b4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047d6:	0ac05d63          	blez	a2,80004890 <filewrite+0xf4>
    int i = 0;
    800047da:	4981                	li	s3,0
    800047dc:	6b05                	lui	s6,0x1
    800047de:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047e2:	6b85                	lui	s7,0x1
    800047e4:	c00b8b9b          	addiw	s7,s7,-1024
    800047e8:	a861                	j	80004880 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047ea:	6908                	ld	a0,16(a0)
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	22e080e7          	jalr	558(ra) # 80004a1a <pipewrite>
    800047f4:	8a2a                	mv	s4,a0
    800047f6:	a045                	j	80004896 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047f8:	02451783          	lh	a5,36(a0)
    800047fc:	03079693          	slli	a3,a5,0x30
    80004800:	92c1                	srli	a3,a3,0x30
    80004802:	4725                	li	a4,9
    80004804:	0cd76263          	bltu	a4,a3,800048c8 <filewrite+0x12c>
    80004808:	0792                	slli	a5,a5,0x4
    8000480a:	0001d717          	auipc	a4,0x1d
    8000480e:	b0e70713          	addi	a4,a4,-1266 # 80021318 <devsw>
    80004812:	97ba                	add	a5,a5,a4
    80004814:	679c                	ld	a5,8(a5)
    80004816:	cbdd                	beqz	a5,800048cc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004818:	4505                	li	a0,1
    8000481a:	9782                	jalr	a5
    8000481c:	8a2a                	mv	s4,a0
    8000481e:	a8a5                	j	80004896 <filewrite+0xfa>
    80004820:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004824:	00000097          	auipc	ra,0x0
    80004828:	8b0080e7          	jalr	-1872(ra) # 800040d4 <begin_op>
      ilock(f->ip);
    8000482c:	01893503          	ld	a0,24(s2)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	ed2080e7          	jalr	-302(ra) # 80003702 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004838:	8762                	mv	a4,s8
    8000483a:	02092683          	lw	a3,32(s2)
    8000483e:	01598633          	add	a2,s3,s5
    80004842:	4585                	li	a1,1
    80004844:	01893503          	ld	a0,24(s2)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	266080e7          	jalr	614(ra) # 80003aae <writei>
    80004850:	84aa                	mv	s1,a0
    80004852:	00a05763          	blez	a0,80004860 <filewrite+0xc4>
        f->off += r;
    80004856:	02092783          	lw	a5,32(s2)
    8000485a:	9fa9                	addw	a5,a5,a0
    8000485c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004860:	01893503          	ld	a0,24(s2)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	f60080e7          	jalr	-160(ra) # 800037c4 <iunlock>
      end_op();
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	8e8080e7          	jalr	-1816(ra) # 80004154 <end_op>

      if(r != n1){
    80004874:	009c1f63          	bne	s8,s1,80004892 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004878:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000487c:	0149db63          	bge	s3,s4,80004892 <filewrite+0xf6>
      int n1 = n - i;
    80004880:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004884:	84be                	mv	s1,a5
    80004886:	2781                	sext.w	a5,a5
    80004888:	f8fb5ce3          	bge	s6,a5,80004820 <filewrite+0x84>
    8000488c:	84de                	mv	s1,s7
    8000488e:	bf49                	j	80004820 <filewrite+0x84>
    int i = 0;
    80004890:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004892:	013a1f63          	bne	s4,s3,800048b0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004896:	8552                	mv	a0,s4
    80004898:	60a6                	ld	ra,72(sp)
    8000489a:	6406                	ld	s0,64(sp)
    8000489c:	74e2                	ld	s1,56(sp)
    8000489e:	7942                	ld	s2,48(sp)
    800048a0:	79a2                	ld	s3,40(sp)
    800048a2:	7a02                	ld	s4,32(sp)
    800048a4:	6ae2                	ld	s5,24(sp)
    800048a6:	6b42                	ld	s6,16(sp)
    800048a8:	6ba2                	ld	s7,8(sp)
    800048aa:	6c02                	ld	s8,0(sp)
    800048ac:	6161                	addi	sp,sp,80
    800048ae:	8082                	ret
    ret = (i == n ? n : -1);
    800048b0:	5a7d                	li	s4,-1
    800048b2:	b7d5                	j	80004896 <filewrite+0xfa>
    panic("filewrite");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	e2450513          	addi	a0,a0,-476 # 800086d8 <syscalls+0x278>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>
    return -1;
    800048c4:	5a7d                	li	s4,-1
    800048c6:	bfc1                	j	80004896 <filewrite+0xfa>
      return -1;
    800048c8:	5a7d                	li	s4,-1
    800048ca:	b7f1                	j	80004896 <filewrite+0xfa>
    800048cc:	5a7d                	li	s4,-1
    800048ce:	b7e1                	j	80004896 <filewrite+0xfa>

00000000800048d0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d0:	7179                	addi	sp,sp,-48
    800048d2:	f406                	sd	ra,40(sp)
    800048d4:	f022                	sd	s0,32(sp)
    800048d6:	ec26                	sd	s1,24(sp)
    800048d8:	e84a                	sd	s2,16(sp)
    800048da:	e44e                	sd	s3,8(sp)
    800048dc:	e052                	sd	s4,0(sp)
    800048de:	1800                	addi	s0,sp,48
    800048e0:	84aa                	mv	s1,a0
    800048e2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048e4:	0005b023          	sd	zero,0(a1)
    800048e8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	bf8080e7          	jalr	-1032(ra) # 800044e4 <filealloc>
    800048f4:	e088                	sd	a0,0(s1)
    800048f6:	c551                	beqz	a0,80004982 <pipealloc+0xb2>
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	bec080e7          	jalr	-1044(ra) # 800044e4 <filealloc>
    80004900:	00aa3023          	sd	a0,0(s4)
    80004904:	c92d                	beqz	a0,80004976 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	1ee080e7          	jalr	494(ra) # 80000af4 <kalloc>
    8000490e:	892a                	mv	s2,a0
    80004910:	c125                	beqz	a0,80004970 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004912:	4985                	li	s3,1
    80004914:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004918:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000491c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004920:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004924:	00004597          	auipc	a1,0x4
    80004928:	dc458593          	addi	a1,a1,-572 # 800086e8 <syscalls+0x288>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	228080e7          	jalr	552(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000494c:	000a3783          	ld	a5,0(s4)
    80004950:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004954:	000a3783          	ld	a5,0(s4)
    80004958:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000495c:	000a3783          	ld	a5,0(s4)
    80004960:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004964:	000a3783          	ld	a5,0(s4)
    80004968:	0127b823          	sd	s2,16(a5)
  return 0;
    8000496c:	4501                	li	a0,0
    8000496e:	a025                	j	80004996 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004970:	6088                	ld	a0,0(s1)
    80004972:	e501                	bnez	a0,8000497a <pipealloc+0xaa>
    80004974:	a039                	j	80004982 <pipealloc+0xb2>
    80004976:	6088                	ld	a0,0(s1)
    80004978:	c51d                	beqz	a0,800049a6 <pipealloc+0xd6>
    fileclose(*f0);
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	c26080e7          	jalr	-986(ra) # 800045a0 <fileclose>
  if(*f1)
    80004982:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004986:	557d                	li	a0,-1
  if(*f1)
    80004988:	c799                	beqz	a5,80004996 <pipealloc+0xc6>
    fileclose(*f1);
    8000498a:	853e                	mv	a0,a5
    8000498c:	00000097          	auipc	ra,0x0
    80004990:	c14080e7          	jalr	-1004(ra) # 800045a0 <fileclose>
  return -1;
    80004994:	557d                	li	a0,-1
}
    80004996:	70a2                	ld	ra,40(sp)
    80004998:	7402                	ld	s0,32(sp)
    8000499a:	64e2                	ld	s1,24(sp)
    8000499c:	6942                	ld	s2,16(sp)
    8000499e:	69a2                	ld	s3,8(sp)
    800049a0:	6a02                	ld	s4,0(sp)
    800049a2:	6145                	addi	sp,sp,48
    800049a4:	8082                	ret
  return -1;
    800049a6:	557d                	li	a0,-1
    800049a8:	b7fd                	j	80004996 <pipealloc+0xc6>

00000000800049aa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049aa:	1101                	addi	sp,sp,-32
    800049ac:	ec06                	sd	ra,24(sp)
    800049ae:	e822                	sd	s0,16(sp)
    800049b0:	e426                	sd	s1,8(sp)
    800049b2:	e04a                	sd	s2,0(sp)
    800049b4:	1000                	addi	s0,sp,32
    800049b6:	84aa                	mv	s1,a0
    800049b8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	22a080e7          	jalr	554(ra) # 80000be4 <acquire>
  if(writable){
    800049c2:	02090d63          	beqz	s2,800049fc <pipeclose+0x52>
    pi->writeopen = 0;
    800049c6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ca:	21848513          	addi	a0,s1,536
    800049ce:	ffffe097          	auipc	ra,0xffffe
    800049d2:	872080e7          	jalr	-1934(ra) # 80002240 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d6:	2204b783          	ld	a5,544(s1)
    800049da:	eb95                	bnez	a5,80004a0e <pipeclose+0x64>
    release(&pi->lock);
    800049dc:	8526                	mv	a0,s1
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2ba080e7          	jalr	698(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049e6:	8526                	mv	a0,s1
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	010080e7          	jalr	16(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049f0:	60e2                	ld	ra,24(sp)
    800049f2:	6442                	ld	s0,16(sp)
    800049f4:	64a2                	ld	s1,8(sp)
    800049f6:	6902                	ld	s2,0(sp)
    800049f8:	6105                	addi	sp,sp,32
    800049fa:	8082                	ret
    pi->readopen = 0;
    800049fc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a00:	21c48513          	addi	a0,s1,540
    80004a04:	ffffe097          	auipc	ra,0xffffe
    80004a08:	83c080e7          	jalr	-1988(ra) # 80002240 <wakeup>
    80004a0c:	b7e9                	j	800049d6 <pipeclose+0x2c>
    release(&pi->lock);
    80004a0e:	8526                	mv	a0,s1
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	288080e7          	jalr	648(ra) # 80000c98 <release>
}
    80004a18:	bfe1                	j	800049f0 <pipeclose+0x46>

0000000080004a1a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a1a:	7159                	addi	sp,sp,-112
    80004a1c:	f486                	sd	ra,104(sp)
    80004a1e:	f0a2                	sd	s0,96(sp)
    80004a20:	eca6                	sd	s1,88(sp)
    80004a22:	e8ca                	sd	s2,80(sp)
    80004a24:	e4ce                	sd	s3,72(sp)
    80004a26:	e0d2                	sd	s4,64(sp)
    80004a28:	fc56                	sd	s5,56(sp)
    80004a2a:	f85a                	sd	s6,48(sp)
    80004a2c:	f45e                	sd	s7,40(sp)
    80004a2e:	f062                	sd	s8,32(sp)
    80004a30:	ec66                	sd	s9,24(sp)
    80004a32:	1880                	addi	s0,sp,112
    80004a34:	84aa                	mv	s1,a0
    80004a36:	8aae                	mv	s5,a1
    80004a38:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a3a:	ffffd097          	auipc	ra,0xffffd
    80004a3e:	f7e080e7          	jalr	-130(ra) # 800019b8 <myproc>
    80004a42:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	19e080e7          	jalr	414(ra) # 80000be4 <acquire>
  while(i < n){
    80004a4e:	0d405163          	blez	s4,80004b10 <pipewrite+0xf6>
    80004a52:	8ba6                	mv	s7,s1
  int i = 0;
    80004a54:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a56:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a58:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a5c:	21c48c13          	addi	s8,s1,540
    80004a60:	a08d                	j	80004ac2 <pipewrite+0xa8>
      release(&pi->lock);
    80004a62:	8526                	mv	a0,s1
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
      return -1;
    80004a6c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a6e:	854a                	mv	a0,s2
    80004a70:	70a6                	ld	ra,104(sp)
    80004a72:	7406                	ld	s0,96(sp)
    80004a74:	64e6                	ld	s1,88(sp)
    80004a76:	6946                	ld	s2,80(sp)
    80004a78:	69a6                	ld	s3,72(sp)
    80004a7a:	6a06                	ld	s4,64(sp)
    80004a7c:	7ae2                	ld	s5,56(sp)
    80004a7e:	7b42                	ld	s6,48(sp)
    80004a80:	7ba2                	ld	s7,40(sp)
    80004a82:	7c02                	ld	s8,32(sp)
    80004a84:	6ce2                	ld	s9,24(sp)
    80004a86:	6165                	addi	sp,sp,112
    80004a88:	8082                	ret
      wakeup(&pi->nread);
    80004a8a:	8566                	mv	a0,s9
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	7b4080e7          	jalr	1972(ra) # 80002240 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a94:	85de                	mv	a1,s7
    80004a96:	8562                	mv	a0,s8
    80004a98:	ffffd097          	auipc	ra,0xffffd
    80004a9c:	61c080e7          	jalr	1564(ra) # 800020b4 <sleep>
    80004aa0:	a839                	j	80004abe <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aa2:	21c4a783          	lw	a5,540(s1)
    80004aa6:	0017871b          	addiw	a4,a5,1
    80004aaa:	20e4ae23          	sw	a4,540(s1)
    80004aae:	1ff7f793          	andi	a5,a5,511
    80004ab2:	97a6                	add	a5,a5,s1
    80004ab4:	f9f44703          	lbu	a4,-97(s0)
    80004ab8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004abc:	2905                	addiw	s2,s2,1
  while(i < n){
    80004abe:	03495d63          	bge	s2,s4,80004af8 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ac2:	2204a783          	lw	a5,544(s1)
    80004ac6:	dfd1                	beqz	a5,80004a62 <pipewrite+0x48>
    80004ac8:	0289a783          	lw	a5,40(s3)
    80004acc:	fbd9                	bnez	a5,80004a62 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ace:	2184a783          	lw	a5,536(s1)
    80004ad2:	21c4a703          	lw	a4,540(s1)
    80004ad6:	2007879b          	addiw	a5,a5,512
    80004ada:	faf708e3          	beq	a4,a5,80004a8a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ade:	4685                	li	a3,1
    80004ae0:	01590633          	add	a2,s2,s5
    80004ae4:	f9f40593          	addi	a1,s0,-97
    80004ae8:	0509b503          	ld	a0,80(s3)
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	c1a080e7          	jalr	-998(ra) # 80001706 <copyin>
    80004af4:	fb6517e3          	bne	a0,s6,80004aa2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004af8:	21848513          	addi	a0,s1,536
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	744080e7          	jalr	1860(ra) # 80002240 <wakeup>
  release(&pi->lock);
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	192080e7          	jalr	402(ra) # 80000c98 <release>
  return i;
    80004b0e:	b785                	j	80004a6e <pipewrite+0x54>
  int i = 0;
    80004b10:	4901                	li	s2,0
    80004b12:	b7dd                	j	80004af8 <pipewrite+0xde>

0000000080004b14 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b14:	715d                	addi	sp,sp,-80
    80004b16:	e486                	sd	ra,72(sp)
    80004b18:	e0a2                	sd	s0,64(sp)
    80004b1a:	fc26                	sd	s1,56(sp)
    80004b1c:	f84a                	sd	s2,48(sp)
    80004b1e:	f44e                	sd	s3,40(sp)
    80004b20:	f052                	sd	s4,32(sp)
    80004b22:	ec56                	sd	s5,24(sp)
    80004b24:	e85a                	sd	s6,16(sp)
    80004b26:	0880                	addi	s0,sp,80
    80004b28:	84aa                	mv	s1,a0
    80004b2a:	892e                	mv	s2,a1
    80004b2c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	e8a080e7          	jalr	-374(ra) # 800019b8 <myproc>
    80004b36:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b38:	8b26                	mv	s6,s1
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b44:	2184a703          	lw	a4,536(s1)
    80004b48:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b50:	02f71463          	bne	a4,a5,80004b78 <piperead+0x64>
    80004b54:	2244a783          	lw	a5,548(s1)
    80004b58:	c385                	beqz	a5,80004b78 <piperead+0x64>
    if(pr->killed){
    80004b5a:	028a2783          	lw	a5,40(s4)
    80004b5e:	ebc1                	bnez	a5,80004bee <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b60:	85da                	mv	a1,s6
    80004b62:	854e                	mv	a0,s3
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	550080e7          	jalr	1360(ra) # 800020b4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6c:	2184a703          	lw	a4,536(s1)
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	fef700e3          	beq	a4,a5,80004b54 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b78:	09505263          	blez	s5,80004bfc <piperead+0xe8>
    80004b7c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b7e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b80:	2184a783          	lw	a5,536(s1)
    80004b84:	21c4a703          	lw	a4,540(s1)
    80004b88:	02f70d63          	beq	a4,a5,80004bc2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b8c:	0017871b          	addiw	a4,a5,1
    80004b90:	20e4ac23          	sw	a4,536(s1)
    80004b94:	1ff7f793          	andi	a5,a5,511
    80004b98:	97a6                	add	a5,a5,s1
    80004b9a:	0187c783          	lbu	a5,24(a5)
    80004b9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ba2:	4685                	li	a3,1
    80004ba4:	fbf40613          	addi	a2,s0,-65
    80004ba8:	85ca                	mv	a1,s2
    80004baa:	050a3503          	ld	a0,80(s4)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	acc080e7          	jalr	-1332(ra) # 8000167a <copyout>
    80004bb6:	01650663          	beq	a0,s6,80004bc2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bba:	2985                	addiw	s3,s3,1
    80004bbc:	0905                	addi	s2,s2,1
    80004bbe:	fd3a91e3          	bne	s5,s3,80004b80 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bc2:	21c48513          	addi	a0,s1,540
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	67a080e7          	jalr	1658(ra) # 80002240 <wakeup>
  release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0c8080e7          	jalr	200(ra) # 80000c98 <release>
  return i;
}
    80004bd8:	854e                	mv	a0,s3
    80004bda:	60a6                	ld	ra,72(sp)
    80004bdc:	6406                	ld	s0,64(sp)
    80004bde:	74e2                	ld	s1,56(sp)
    80004be0:	7942                	ld	s2,48(sp)
    80004be2:	79a2                	ld	s3,40(sp)
    80004be4:	7a02                	ld	s4,32(sp)
    80004be6:	6ae2                	ld	s5,24(sp)
    80004be8:	6b42                	ld	s6,16(sp)
    80004bea:	6161                	addi	sp,sp,80
    80004bec:	8082                	ret
      release(&pi->lock);
    80004bee:	8526                	mv	a0,s1
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>
      return -1;
    80004bf8:	59fd                	li	s3,-1
    80004bfa:	bff9                	j	80004bd8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bfc:	4981                	li	s3,0
    80004bfe:	b7d1                	j	80004bc2 <piperead+0xae>

0000000080004c00 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c00:	df010113          	addi	sp,sp,-528
    80004c04:	20113423          	sd	ra,520(sp)
    80004c08:	20813023          	sd	s0,512(sp)
    80004c0c:	ffa6                	sd	s1,504(sp)
    80004c0e:	fbca                	sd	s2,496(sp)
    80004c10:	f7ce                	sd	s3,488(sp)
    80004c12:	f3d2                	sd	s4,480(sp)
    80004c14:	efd6                	sd	s5,472(sp)
    80004c16:	ebda                	sd	s6,464(sp)
    80004c18:	e7de                	sd	s7,456(sp)
    80004c1a:	e3e2                	sd	s8,448(sp)
    80004c1c:	ff66                	sd	s9,440(sp)
    80004c1e:	fb6a                	sd	s10,432(sp)
    80004c20:	f76e                	sd	s11,424(sp)
    80004c22:	0c00                	addi	s0,sp,528
    80004c24:	84aa                	mv	s1,a0
    80004c26:	dea43c23          	sd	a0,-520(s0)
    80004c2a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	d8a080e7          	jalr	-630(ra) # 800019b8 <myproc>
    80004c36:	892a                	mv	s2,a0

  begin_op();
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	49c080e7          	jalr	1180(ra) # 800040d4 <begin_op>

  if((ip = namei(path)) == 0){
    80004c40:	8526                	mv	a0,s1
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	276080e7          	jalr	630(ra) # 80003eb8 <namei>
    80004c4a:	c92d                	beqz	a0,80004cbc <exec+0xbc>
    80004c4c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	ab4080e7          	jalr	-1356(ra) # 80003702 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c56:	04000713          	li	a4,64
    80004c5a:	4681                	li	a3,0
    80004c5c:	e5040613          	addi	a2,s0,-432
    80004c60:	4581                	li	a1,0
    80004c62:	8526                	mv	a0,s1
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	d52080e7          	jalr	-686(ra) # 800039b6 <readi>
    80004c6c:	04000793          	li	a5,64
    80004c70:	00f51a63          	bne	a0,a5,80004c84 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c74:	e5042703          	lw	a4,-432(s0)
    80004c78:	464c47b7          	lui	a5,0x464c4
    80004c7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c80:	04f70463          	beq	a4,a5,80004cc8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c84:	8526                	mv	a0,s1
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	cde080e7          	jalr	-802(ra) # 80003964 <iunlockput>
    end_op();
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	4c6080e7          	jalr	1222(ra) # 80004154 <end_op>
  }
  return -1;
    80004c96:	557d                	li	a0,-1
}
    80004c98:	20813083          	ld	ra,520(sp)
    80004c9c:	20013403          	ld	s0,512(sp)
    80004ca0:	74fe                	ld	s1,504(sp)
    80004ca2:	795e                	ld	s2,496(sp)
    80004ca4:	79be                	ld	s3,488(sp)
    80004ca6:	7a1e                	ld	s4,480(sp)
    80004ca8:	6afe                	ld	s5,472(sp)
    80004caa:	6b5e                	ld	s6,464(sp)
    80004cac:	6bbe                	ld	s7,456(sp)
    80004cae:	6c1e                	ld	s8,448(sp)
    80004cb0:	7cfa                	ld	s9,440(sp)
    80004cb2:	7d5a                	ld	s10,432(sp)
    80004cb4:	7dba                	ld	s11,424(sp)
    80004cb6:	21010113          	addi	sp,sp,528
    80004cba:	8082                	ret
    end_op();
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	498080e7          	jalr	1176(ra) # 80004154 <end_op>
    return -1;
    80004cc4:	557d                	li	a0,-1
    80004cc6:	bfc9                	j	80004c98 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cc8:	854a                	mv	a0,s2
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	db2080e7          	jalr	-590(ra) # 80001a7c <proc_pagetable>
    80004cd2:	8baa                	mv	s7,a0
    80004cd4:	d945                	beqz	a0,80004c84 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd6:	e7042983          	lw	s3,-400(s0)
    80004cda:	e8845783          	lhu	a5,-376(s0)
    80004cde:	c7ad                	beqz	a5,80004d48 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ce0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ce2:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004ce4:	6c85                	lui	s9,0x1
    80004ce6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cea:	def43823          	sd	a5,-528(s0)
    80004cee:	a42d                	j	80004f18 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cf0:	00004517          	auipc	a0,0x4
    80004cf4:	a0050513          	addi	a0,a0,-1536 # 800086f0 <syscalls+0x290>
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d00:	8756                	mv	a4,s5
    80004d02:	012d86bb          	addw	a3,s11,s2
    80004d06:	4581                	li	a1,0
    80004d08:	8526                	mv	a0,s1
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	cac080e7          	jalr	-852(ra) # 800039b6 <readi>
    80004d12:	2501                	sext.w	a0,a0
    80004d14:	1aaa9963          	bne	s5,a0,80004ec6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d18:	6785                	lui	a5,0x1
    80004d1a:	0127893b          	addw	s2,a5,s2
    80004d1e:	77fd                	lui	a5,0xfffff
    80004d20:	01478a3b          	addw	s4,a5,s4
    80004d24:	1f897163          	bgeu	s2,s8,80004f06 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d28:	02091593          	slli	a1,s2,0x20
    80004d2c:	9181                	srli	a1,a1,0x20
    80004d2e:	95ea                	add	a1,a1,s10
    80004d30:	855e                	mv	a0,s7
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	344080e7          	jalr	836(ra) # 80001076 <walkaddr>
    80004d3a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d3c:	d955                	beqz	a0,80004cf0 <exec+0xf0>
      n = PGSIZE;
    80004d3e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d40:	fd9a70e3          	bgeu	s4,s9,80004d00 <exec+0x100>
      n = sz - i;
    80004d44:	8ad2                	mv	s5,s4
    80004d46:	bf6d                	j	80004d00 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d48:	4901                	li	s2,0
  iunlockput(ip);
    80004d4a:	8526                	mv	a0,s1
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	c18080e7          	jalr	-1000(ra) # 80003964 <iunlockput>
  end_op();
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	400080e7          	jalr	1024(ra) # 80004154 <end_op>
  p = myproc();
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	c5c080e7          	jalr	-932(ra) # 800019b8 <myproc>
    80004d64:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d66:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d6a:	6785                	lui	a5,0x1
    80004d6c:	17fd                	addi	a5,a5,-1
    80004d6e:	993e                	add	s2,s2,a5
    80004d70:	757d                	lui	a0,0xfffff
    80004d72:	00a977b3          	and	a5,s2,a0
    80004d76:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d7a:	6609                	lui	a2,0x2
    80004d7c:	963e                	add	a2,a2,a5
    80004d7e:	85be                	mv	a1,a5
    80004d80:	855e                	mv	a0,s7
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	6a8080e7          	jalr	1704(ra) # 8000142a <uvmalloc>
    80004d8a:	8b2a                	mv	s6,a0
  ip = 0;
    80004d8c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d8e:	12050c63          	beqz	a0,80004ec6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d92:	75f9                	lui	a1,0xffffe
    80004d94:	95aa                	add	a1,a1,a0
    80004d96:	855e                	mv	a0,s7
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	8b0080e7          	jalr	-1872(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004da0:	7c7d                	lui	s8,0xfffff
    80004da2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004da4:	e0043783          	ld	a5,-512(s0)
    80004da8:	6388                	ld	a0,0(a5)
    80004daa:	c535                	beqz	a0,80004e16 <exec+0x216>
    80004dac:	e9040993          	addi	s3,s0,-368
    80004db0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004db4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	0ae080e7          	jalr	174(ra) # 80000e64 <strlen>
    80004dbe:	2505                	addiw	a0,a0,1
    80004dc0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dc4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dc8:	13896363          	bltu	s2,s8,80004eee <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dcc:	e0043d83          	ld	s11,-512(s0)
    80004dd0:	000dba03          	ld	s4,0(s11)
    80004dd4:	8552                	mv	a0,s4
    80004dd6:	ffffc097          	auipc	ra,0xffffc
    80004dda:	08e080e7          	jalr	142(ra) # 80000e64 <strlen>
    80004dde:	0015069b          	addiw	a3,a0,1
    80004de2:	8652                	mv	a2,s4
    80004de4:	85ca                	mv	a1,s2
    80004de6:	855e                	mv	a0,s7
    80004de8:	ffffd097          	auipc	ra,0xffffd
    80004dec:	892080e7          	jalr	-1902(ra) # 8000167a <copyout>
    80004df0:	10054363          	bltz	a0,80004ef6 <exec+0x2f6>
    ustack[argc] = sp;
    80004df4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004df8:	0485                	addi	s1,s1,1
    80004dfa:	008d8793          	addi	a5,s11,8
    80004dfe:	e0f43023          	sd	a5,-512(s0)
    80004e02:	008db503          	ld	a0,8(s11)
    80004e06:	c911                	beqz	a0,80004e1a <exec+0x21a>
    if(argc >= MAXARG)
    80004e08:	09a1                	addi	s3,s3,8
    80004e0a:	fb3c96e3          	bne	s9,s3,80004db6 <exec+0x1b6>
  sz = sz1;
    80004e0e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e12:	4481                	li	s1,0
    80004e14:	a84d                	j	80004ec6 <exec+0x2c6>
  sp = sz;
    80004e16:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e18:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e1a:	00349793          	slli	a5,s1,0x3
    80004e1e:	f9040713          	addi	a4,s0,-112
    80004e22:	97ba                	add	a5,a5,a4
    80004e24:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004e28:	00148693          	addi	a3,s1,1
    80004e2c:	068e                	slli	a3,a3,0x3
    80004e2e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e32:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e36:	01897663          	bgeu	s2,s8,80004e42 <exec+0x242>
  sz = sz1;
    80004e3a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e3e:	4481                	li	s1,0
    80004e40:	a059                	j	80004ec6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e42:	e9040613          	addi	a2,s0,-368
    80004e46:	85ca                	mv	a1,s2
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	830080e7          	jalr	-2000(ra) # 8000167a <copyout>
    80004e52:	0a054663          	bltz	a0,80004efe <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e56:	058ab783          	ld	a5,88(s5)
    80004e5a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e5e:	df843783          	ld	a5,-520(s0)
    80004e62:	0007c703          	lbu	a4,0(a5)
    80004e66:	cf11                	beqz	a4,80004e82 <exec+0x282>
    80004e68:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e6a:	02f00693          	li	a3,47
    80004e6e:	a039                	j	80004e7c <exec+0x27c>
      last = s+1;
    80004e70:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e74:	0785                	addi	a5,a5,1
    80004e76:	fff7c703          	lbu	a4,-1(a5)
    80004e7a:	c701                	beqz	a4,80004e82 <exec+0x282>
    if(*s == '/')
    80004e7c:	fed71ce3          	bne	a4,a3,80004e74 <exec+0x274>
    80004e80:	bfc5                	j	80004e70 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e82:	4641                	li	a2,16
    80004e84:	df843583          	ld	a1,-520(s0)
    80004e88:	158a8513          	addi	a0,s5,344
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	fa6080e7          	jalr	-90(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e94:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e98:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e9c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ea0:	058ab783          	ld	a5,88(s5)
    80004ea4:	e6843703          	ld	a4,-408(s0)
    80004ea8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004eaa:	058ab783          	ld	a5,88(s5)
    80004eae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eb2:	85ea                	mv	a1,s10
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	c64080e7          	jalr	-924(ra) # 80001b18 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ebc:	0004851b          	sext.w	a0,s1
    80004ec0:	bbe1                	j	80004c98 <exec+0x98>
    80004ec2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ec6:	e0843583          	ld	a1,-504(s0)
    80004eca:	855e                	mv	a0,s7
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	c4c080e7          	jalr	-948(ra) # 80001b18 <proc_freepagetable>
  if(ip){
    80004ed4:	da0498e3          	bnez	s1,80004c84 <exec+0x84>
  return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	bb7d                	j	80004c98 <exec+0x98>
    80004edc:	e1243423          	sd	s2,-504(s0)
    80004ee0:	b7dd                	j	80004ec6 <exec+0x2c6>
    80004ee2:	e1243423          	sd	s2,-504(s0)
    80004ee6:	b7c5                	j	80004ec6 <exec+0x2c6>
    80004ee8:	e1243423          	sd	s2,-504(s0)
    80004eec:	bfe9                	j	80004ec6 <exec+0x2c6>
  sz = sz1;
    80004eee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef2:	4481                	li	s1,0
    80004ef4:	bfc9                	j	80004ec6 <exec+0x2c6>
  sz = sz1;
    80004ef6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004efa:	4481                	li	s1,0
    80004efc:	b7e9                	j	80004ec6 <exec+0x2c6>
  sz = sz1;
    80004efe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f02:	4481                	li	s1,0
    80004f04:	b7c9                	j	80004ec6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f06:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f0a:	2b05                	addiw	s6,s6,1
    80004f0c:	0389899b          	addiw	s3,s3,56
    80004f10:	e8845783          	lhu	a5,-376(s0)
    80004f14:	e2fb5be3          	bge	s6,a5,80004d4a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f18:	2981                	sext.w	s3,s3
    80004f1a:	03800713          	li	a4,56
    80004f1e:	86ce                	mv	a3,s3
    80004f20:	e1840613          	addi	a2,s0,-488
    80004f24:	4581                	li	a1,0
    80004f26:	8526                	mv	a0,s1
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	a8e080e7          	jalr	-1394(ra) # 800039b6 <readi>
    80004f30:	03800793          	li	a5,56
    80004f34:	f8f517e3          	bne	a0,a5,80004ec2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f38:	e1842783          	lw	a5,-488(s0)
    80004f3c:	4705                	li	a4,1
    80004f3e:	fce796e3          	bne	a5,a4,80004f0a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f42:	e4043603          	ld	a2,-448(s0)
    80004f46:	e3843783          	ld	a5,-456(s0)
    80004f4a:	f8f669e3          	bltu	a2,a5,80004edc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f4e:	e2843783          	ld	a5,-472(s0)
    80004f52:	963e                	add	a2,a2,a5
    80004f54:	f8f667e3          	bltu	a2,a5,80004ee2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f58:	85ca                	mv	a1,s2
    80004f5a:	855e                	mv	a0,s7
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	4ce080e7          	jalr	1230(ra) # 8000142a <uvmalloc>
    80004f64:	e0a43423          	sd	a0,-504(s0)
    80004f68:	d141                	beqz	a0,80004ee8 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f6a:	e2843d03          	ld	s10,-472(s0)
    80004f6e:	df043783          	ld	a5,-528(s0)
    80004f72:	00fd77b3          	and	a5,s10,a5
    80004f76:	fba1                	bnez	a5,80004ec6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f78:	e2042d83          	lw	s11,-480(s0)
    80004f7c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f80:	f80c03e3          	beqz	s8,80004f06 <exec+0x306>
    80004f84:	8a62                	mv	s4,s8
    80004f86:	4901                	li	s2,0
    80004f88:	b345                	j	80004d28 <exec+0x128>

0000000080004f8a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f8a:	7179                	addi	sp,sp,-48
    80004f8c:	f406                	sd	ra,40(sp)
    80004f8e:	f022                	sd	s0,32(sp)
    80004f90:	ec26                	sd	s1,24(sp)
    80004f92:	e84a                	sd	s2,16(sp)
    80004f94:	1800                	addi	s0,sp,48
    80004f96:	892e                	mv	s2,a1
    80004f98:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f9a:	fdc40593          	addi	a1,s0,-36
    80004f9e:	ffffe097          	auipc	ra,0xffffe
    80004fa2:	ba6080e7          	jalr	-1114(ra) # 80002b44 <argint>
    80004fa6:	04054063          	bltz	a0,80004fe6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004faa:	fdc42703          	lw	a4,-36(s0)
    80004fae:	47bd                	li	a5,15
    80004fb0:	02e7ed63          	bltu	a5,a4,80004fea <argfd+0x60>
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	a04080e7          	jalr	-1532(ra) # 800019b8 <myproc>
    80004fbc:	fdc42703          	lw	a4,-36(s0)
    80004fc0:	01a70793          	addi	a5,a4,26
    80004fc4:	078e                	slli	a5,a5,0x3
    80004fc6:	953e                	add	a0,a0,a5
    80004fc8:	611c                	ld	a5,0(a0)
    80004fca:	c395                	beqz	a5,80004fee <argfd+0x64>
    return -1;
  if(pfd)
    80004fcc:	00090463          	beqz	s2,80004fd4 <argfd+0x4a>
    *pfd = fd;
    80004fd0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fd4:	4501                	li	a0,0
  if(pf)
    80004fd6:	c091                	beqz	s1,80004fda <argfd+0x50>
    *pf = f;
    80004fd8:	e09c                	sd	a5,0(s1)
}
    80004fda:	70a2                	ld	ra,40(sp)
    80004fdc:	7402                	ld	s0,32(sp)
    80004fde:	64e2                	ld	s1,24(sp)
    80004fe0:	6942                	ld	s2,16(sp)
    80004fe2:	6145                	addi	sp,sp,48
    80004fe4:	8082                	ret
    return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	bfcd                	j	80004fda <argfd+0x50>
    return -1;
    80004fea:	557d                	li	a0,-1
    80004fec:	b7fd                	j	80004fda <argfd+0x50>
    80004fee:	557d                	li	a0,-1
    80004ff0:	b7ed                	j	80004fda <argfd+0x50>

0000000080004ff2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ff2:	1101                	addi	sp,sp,-32
    80004ff4:	ec06                	sd	ra,24(sp)
    80004ff6:	e822                	sd	s0,16(sp)
    80004ff8:	e426                	sd	s1,8(sp)
    80004ffa:	1000                	addi	s0,sp,32
    80004ffc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	9ba080e7          	jalr	-1606(ra) # 800019b8 <myproc>
    80005006:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005008:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000500c:	4501                	li	a0,0
    8000500e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005010:	6398                	ld	a4,0(a5)
    80005012:	cb19                	beqz	a4,80005028 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005014:	2505                	addiw	a0,a0,1
    80005016:	07a1                	addi	a5,a5,8
    80005018:	fed51ce3          	bne	a0,a3,80005010 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000501c:	557d                	li	a0,-1
}
    8000501e:	60e2                	ld	ra,24(sp)
    80005020:	6442                	ld	s0,16(sp)
    80005022:	64a2                	ld	s1,8(sp)
    80005024:	6105                	addi	sp,sp,32
    80005026:	8082                	ret
      p->ofile[fd] = f;
    80005028:	01a50793          	addi	a5,a0,26
    8000502c:	078e                	slli	a5,a5,0x3
    8000502e:	963e                	add	a2,a2,a5
    80005030:	e204                	sd	s1,0(a2)
      return fd;
    80005032:	b7f5                	j	8000501e <fdalloc+0x2c>

0000000080005034 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005034:	715d                	addi	sp,sp,-80
    80005036:	e486                	sd	ra,72(sp)
    80005038:	e0a2                	sd	s0,64(sp)
    8000503a:	fc26                	sd	s1,56(sp)
    8000503c:	f84a                	sd	s2,48(sp)
    8000503e:	f44e                	sd	s3,40(sp)
    80005040:	f052                	sd	s4,32(sp)
    80005042:	ec56                	sd	s5,24(sp)
    80005044:	0880                	addi	s0,sp,80
    80005046:	89ae                	mv	s3,a1
    80005048:	8ab2                	mv	s5,a2
    8000504a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000504c:	fb040593          	addi	a1,s0,-80
    80005050:	fffff097          	auipc	ra,0xfffff
    80005054:	e86080e7          	jalr	-378(ra) # 80003ed6 <nameiparent>
    80005058:	892a                	mv	s2,a0
    8000505a:	12050f63          	beqz	a0,80005198 <create+0x164>
    return 0;

  ilock(dp);
    8000505e:	ffffe097          	auipc	ra,0xffffe
    80005062:	6a4080e7          	jalr	1700(ra) # 80003702 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005066:	4601                	li	a2,0
    80005068:	fb040593          	addi	a1,s0,-80
    8000506c:	854a                	mv	a0,s2
    8000506e:	fffff097          	auipc	ra,0xfffff
    80005072:	b78080e7          	jalr	-1160(ra) # 80003be6 <dirlookup>
    80005076:	84aa                	mv	s1,a0
    80005078:	c921                	beqz	a0,800050c8 <create+0x94>
    iunlockput(dp);
    8000507a:	854a                	mv	a0,s2
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	8e8080e7          	jalr	-1816(ra) # 80003964 <iunlockput>
    ilock(ip);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	67c080e7          	jalr	1660(ra) # 80003702 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000508e:	2981                	sext.w	s3,s3
    80005090:	4789                	li	a5,2
    80005092:	02f99463          	bne	s3,a5,800050ba <create+0x86>
    80005096:	0444d783          	lhu	a5,68(s1)
    8000509a:	37f9                	addiw	a5,a5,-2
    8000509c:	17c2                	slli	a5,a5,0x30
    8000509e:	93c1                	srli	a5,a5,0x30
    800050a0:	4705                	li	a4,1
    800050a2:	00f76c63          	bltu	a4,a5,800050ba <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050a6:	8526                	mv	a0,s1
    800050a8:	60a6                	ld	ra,72(sp)
    800050aa:	6406                	ld	s0,64(sp)
    800050ac:	74e2                	ld	s1,56(sp)
    800050ae:	7942                	ld	s2,48(sp)
    800050b0:	79a2                	ld	s3,40(sp)
    800050b2:	7a02                	ld	s4,32(sp)
    800050b4:	6ae2                	ld	s5,24(sp)
    800050b6:	6161                	addi	sp,sp,80
    800050b8:	8082                	ret
    iunlockput(ip);
    800050ba:	8526                	mv	a0,s1
    800050bc:	fffff097          	auipc	ra,0xfffff
    800050c0:	8a8080e7          	jalr	-1880(ra) # 80003964 <iunlockput>
    return 0;
    800050c4:	4481                	li	s1,0
    800050c6:	b7c5                	j	800050a6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050c8:	85ce                	mv	a1,s3
    800050ca:	00092503          	lw	a0,0(s2)
    800050ce:	ffffe097          	auipc	ra,0xffffe
    800050d2:	49c080e7          	jalr	1180(ra) # 8000356a <ialloc>
    800050d6:	84aa                	mv	s1,a0
    800050d8:	c529                	beqz	a0,80005122 <create+0xee>
  ilock(ip);
    800050da:	ffffe097          	auipc	ra,0xffffe
    800050de:	628080e7          	jalr	1576(ra) # 80003702 <ilock>
  ip->major = major;
    800050e2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050e6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050ea:	4785                	li	a5,1
    800050ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050f0:	8526                	mv	a0,s1
    800050f2:	ffffe097          	auipc	ra,0xffffe
    800050f6:	546080e7          	jalr	1350(ra) # 80003638 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050fa:	2981                	sext.w	s3,s3
    800050fc:	4785                	li	a5,1
    800050fe:	02f98a63          	beq	s3,a5,80005132 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005102:	40d0                	lw	a2,4(s1)
    80005104:	fb040593          	addi	a1,s0,-80
    80005108:	854a                	mv	a0,s2
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	cec080e7          	jalr	-788(ra) # 80003df6 <dirlink>
    80005112:	06054b63          	bltz	a0,80005188 <create+0x154>
  iunlockput(dp);
    80005116:	854a                	mv	a0,s2
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	84c080e7          	jalr	-1972(ra) # 80003964 <iunlockput>
  return ip;
    80005120:	b759                	j	800050a6 <create+0x72>
    panic("create: ialloc");
    80005122:	00003517          	auipc	a0,0x3
    80005126:	5ee50513          	addi	a0,a0,1518 # 80008710 <syscalls+0x2b0>
    8000512a:	ffffb097          	auipc	ra,0xffffb
    8000512e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005132:	04a95783          	lhu	a5,74(s2)
    80005136:	2785                	addiw	a5,a5,1
    80005138:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000513c:	854a                	mv	a0,s2
    8000513e:	ffffe097          	auipc	ra,0xffffe
    80005142:	4fa080e7          	jalr	1274(ra) # 80003638 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005146:	40d0                	lw	a2,4(s1)
    80005148:	00003597          	auipc	a1,0x3
    8000514c:	5d858593          	addi	a1,a1,1496 # 80008720 <syscalls+0x2c0>
    80005150:	8526                	mv	a0,s1
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	ca4080e7          	jalr	-860(ra) # 80003df6 <dirlink>
    8000515a:	00054f63          	bltz	a0,80005178 <create+0x144>
    8000515e:	00492603          	lw	a2,4(s2)
    80005162:	00003597          	auipc	a1,0x3
    80005166:	5c658593          	addi	a1,a1,1478 # 80008728 <syscalls+0x2c8>
    8000516a:	8526                	mv	a0,s1
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	c8a080e7          	jalr	-886(ra) # 80003df6 <dirlink>
    80005174:	f80557e3          	bgez	a0,80005102 <create+0xce>
      panic("create dots");
    80005178:	00003517          	auipc	a0,0x3
    8000517c:	5b850513          	addi	a0,a0,1464 # 80008730 <syscalls+0x2d0>
    80005180:	ffffb097          	auipc	ra,0xffffb
    80005184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005188:	00003517          	auipc	a0,0x3
    8000518c:	5b850513          	addi	a0,a0,1464 # 80008740 <syscalls+0x2e0>
    80005190:	ffffb097          	auipc	ra,0xffffb
    80005194:	3ae080e7          	jalr	942(ra) # 8000053e <panic>
    return 0;
    80005198:	84aa                	mv	s1,a0
    8000519a:	b731                	j	800050a6 <create+0x72>

000000008000519c <sys_dup>:
{
    8000519c:	7179                	addi	sp,sp,-48
    8000519e:	f406                	sd	ra,40(sp)
    800051a0:	f022                	sd	s0,32(sp)
    800051a2:	ec26                	sd	s1,24(sp)
    800051a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051a6:	fd840613          	addi	a2,s0,-40
    800051aa:	4581                	li	a1,0
    800051ac:	4501                	li	a0,0
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	ddc080e7          	jalr	-548(ra) # 80004f8a <argfd>
    return -1;
    800051b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051b8:	02054363          	bltz	a0,800051de <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051bc:	fd843503          	ld	a0,-40(s0)
    800051c0:	00000097          	auipc	ra,0x0
    800051c4:	e32080e7          	jalr	-462(ra) # 80004ff2 <fdalloc>
    800051c8:	84aa                	mv	s1,a0
    return -1;
    800051ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051cc:	00054963          	bltz	a0,800051de <sys_dup+0x42>
  filedup(f);
    800051d0:	fd843503          	ld	a0,-40(s0)
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	37a080e7          	jalr	890(ra) # 8000454e <filedup>
  return fd;
    800051dc:	87a6                	mv	a5,s1
}
    800051de:	853e                	mv	a0,a5
    800051e0:	70a2                	ld	ra,40(sp)
    800051e2:	7402                	ld	s0,32(sp)
    800051e4:	64e2                	ld	s1,24(sp)
    800051e6:	6145                	addi	sp,sp,48
    800051e8:	8082                	ret

00000000800051ea <sys_read>:
{
    800051ea:	7179                	addi	sp,sp,-48
    800051ec:	f406                	sd	ra,40(sp)
    800051ee:	f022                	sd	s0,32(sp)
    800051f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f2:	fe840613          	addi	a2,s0,-24
    800051f6:	4581                	li	a1,0
    800051f8:	4501                	li	a0,0
    800051fa:	00000097          	auipc	ra,0x0
    800051fe:	d90080e7          	jalr	-624(ra) # 80004f8a <argfd>
    return -1;
    80005202:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005204:	04054163          	bltz	a0,80005246 <sys_read+0x5c>
    80005208:	fe440593          	addi	a1,s0,-28
    8000520c:	4509                	li	a0,2
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	936080e7          	jalr	-1738(ra) # 80002b44 <argint>
    return -1;
    80005216:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005218:	02054763          	bltz	a0,80005246 <sys_read+0x5c>
    8000521c:	fd840593          	addi	a1,s0,-40
    80005220:	4505                	li	a0,1
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	944080e7          	jalr	-1724(ra) # 80002b66 <argaddr>
    return -1;
    8000522a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522c:	00054d63          	bltz	a0,80005246 <sys_read+0x5c>
  return fileread(f, p, n);
    80005230:	fe442603          	lw	a2,-28(s0)
    80005234:	fd843583          	ld	a1,-40(s0)
    80005238:	fe843503          	ld	a0,-24(s0)
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	49e080e7          	jalr	1182(ra) # 800046da <fileread>
    80005244:	87aa                	mv	a5,a0
}
    80005246:	853e                	mv	a0,a5
    80005248:	70a2                	ld	ra,40(sp)
    8000524a:	7402                	ld	s0,32(sp)
    8000524c:	6145                	addi	sp,sp,48
    8000524e:	8082                	ret

0000000080005250 <sys_write>:
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005258:	fe840613          	addi	a2,s0,-24
    8000525c:	4581                	li	a1,0
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	d2a080e7          	jalr	-726(ra) # 80004f8a <argfd>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526a:	04054163          	bltz	a0,800052ac <sys_write+0x5c>
    8000526e:	fe440593          	addi	a1,s0,-28
    80005272:	4509                	li	a0,2
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	8d0080e7          	jalr	-1840(ra) # 80002b44 <argint>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	02054763          	bltz	a0,800052ac <sys_write+0x5c>
    80005282:	fd840593          	addi	a1,s0,-40
    80005286:	4505                	li	a0,1
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	8de080e7          	jalr	-1826(ra) # 80002b66 <argaddr>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	00054d63          	bltz	a0,800052ac <sys_write+0x5c>
  return filewrite(f, p, n);
    80005296:	fe442603          	lw	a2,-28(s0)
    8000529a:	fd843583          	ld	a1,-40(s0)
    8000529e:	fe843503          	ld	a0,-24(s0)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	4fa080e7          	jalr	1274(ra) # 8000479c <filewrite>
    800052aa:	87aa                	mv	a5,a0
}
    800052ac:	853e                	mv	a0,a5
    800052ae:	70a2                	ld	ra,40(sp)
    800052b0:	7402                	ld	s0,32(sp)
    800052b2:	6145                	addi	sp,sp,48
    800052b4:	8082                	ret

00000000800052b6 <sys_close>:
{
    800052b6:	1101                	addi	sp,sp,-32
    800052b8:	ec06                	sd	ra,24(sp)
    800052ba:	e822                	sd	s0,16(sp)
    800052bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052be:	fe040613          	addi	a2,s0,-32
    800052c2:	fec40593          	addi	a1,s0,-20
    800052c6:	4501                	li	a0,0
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	cc2080e7          	jalr	-830(ra) # 80004f8a <argfd>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052d2:	02054463          	bltz	a0,800052fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	6e2080e7          	jalr	1762(ra) # 800019b8 <myproc>
    800052de:	fec42783          	lw	a5,-20(s0)
    800052e2:	07e9                	addi	a5,a5,26
    800052e4:	078e                	slli	a5,a5,0x3
    800052e6:	97aa                	add	a5,a5,a0
    800052e8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052ec:	fe043503          	ld	a0,-32(s0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	2b0080e7          	jalr	688(ra) # 800045a0 <fileclose>
  return 0;
    800052f8:	4781                	li	a5,0
}
    800052fa:	853e                	mv	a0,a5
    800052fc:	60e2                	ld	ra,24(sp)
    800052fe:	6442                	ld	s0,16(sp)
    80005300:	6105                	addi	sp,sp,32
    80005302:	8082                	ret

0000000080005304 <sys_fstat>:
{
    80005304:	1101                	addi	sp,sp,-32
    80005306:	ec06                	sd	ra,24(sp)
    80005308:	e822                	sd	s0,16(sp)
    8000530a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000530c:	fe840613          	addi	a2,s0,-24
    80005310:	4581                	li	a1,0
    80005312:	4501                	li	a0,0
    80005314:	00000097          	auipc	ra,0x0
    80005318:	c76080e7          	jalr	-906(ra) # 80004f8a <argfd>
    return -1;
    8000531c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000531e:	02054563          	bltz	a0,80005348 <sys_fstat+0x44>
    80005322:	fe040593          	addi	a1,s0,-32
    80005326:	4505                	li	a0,1
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	83e080e7          	jalr	-1986(ra) # 80002b66 <argaddr>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005332:	00054b63          	bltz	a0,80005348 <sys_fstat+0x44>
  return filestat(f, st);
    80005336:	fe043583          	ld	a1,-32(s0)
    8000533a:	fe843503          	ld	a0,-24(s0)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	32a080e7          	jalr	810(ra) # 80004668 <filestat>
    80005346:	87aa                	mv	a5,a0
}
    80005348:	853e                	mv	a0,a5
    8000534a:	60e2                	ld	ra,24(sp)
    8000534c:	6442                	ld	s0,16(sp)
    8000534e:	6105                	addi	sp,sp,32
    80005350:	8082                	ret

0000000080005352 <sys_link>:
{
    80005352:	7169                	addi	sp,sp,-304
    80005354:	f606                	sd	ra,296(sp)
    80005356:	f222                	sd	s0,288(sp)
    80005358:	ee26                	sd	s1,280(sp)
    8000535a:	ea4a                	sd	s2,272(sp)
    8000535c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000535e:	08000613          	li	a2,128
    80005362:	ed040593          	addi	a1,s0,-304
    80005366:	4501                	li	a0,0
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	820080e7          	jalr	-2016(ra) # 80002b88 <argstr>
    return -1;
    80005370:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005372:	10054e63          	bltz	a0,8000548e <sys_link+0x13c>
    80005376:	08000613          	li	a2,128
    8000537a:	f5040593          	addi	a1,s0,-176
    8000537e:	4505                	li	a0,1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	808080e7          	jalr	-2040(ra) # 80002b88 <argstr>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000538a:	10054263          	bltz	a0,8000548e <sys_link+0x13c>
  begin_op();
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	d46080e7          	jalr	-698(ra) # 800040d4 <begin_op>
  if((ip = namei(old)) == 0){
    80005396:	ed040513          	addi	a0,s0,-304
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	b1e080e7          	jalr	-1250(ra) # 80003eb8 <namei>
    800053a2:	84aa                	mv	s1,a0
    800053a4:	c551                	beqz	a0,80005430 <sys_link+0xde>
  ilock(ip);
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	35c080e7          	jalr	860(ra) # 80003702 <ilock>
  if(ip->type == T_DIR){
    800053ae:	04449703          	lh	a4,68(s1)
    800053b2:	4785                	li	a5,1
    800053b4:	08f70463          	beq	a4,a5,8000543c <sys_link+0xea>
  ip->nlink++;
    800053b8:	04a4d783          	lhu	a5,74(s1)
    800053bc:	2785                	addiw	a5,a5,1
    800053be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053c2:	8526                	mv	a0,s1
    800053c4:	ffffe097          	auipc	ra,0xffffe
    800053c8:	274080e7          	jalr	628(ra) # 80003638 <iupdate>
  iunlock(ip);
    800053cc:	8526                	mv	a0,s1
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	3f6080e7          	jalr	1014(ra) # 800037c4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053d6:	fd040593          	addi	a1,s0,-48
    800053da:	f5040513          	addi	a0,s0,-176
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	af8080e7          	jalr	-1288(ra) # 80003ed6 <nameiparent>
    800053e6:	892a                	mv	s2,a0
    800053e8:	c935                	beqz	a0,8000545c <sys_link+0x10a>
  ilock(dp);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	318080e7          	jalr	792(ra) # 80003702 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053f2:	00092703          	lw	a4,0(s2)
    800053f6:	409c                	lw	a5,0(s1)
    800053f8:	04f71d63          	bne	a4,a5,80005452 <sys_link+0x100>
    800053fc:	40d0                	lw	a2,4(s1)
    800053fe:	fd040593          	addi	a1,s0,-48
    80005402:	854a                	mv	a0,s2
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	9f2080e7          	jalr	-1550(ra) # 80003df6 <dirlink>
    8000540c:	04054363          	bltz	a0,80005452 <sys_link+0x100>
  iunlockput(dp);
    80005410:	854a                	mv	a0,s2
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	552080e7          	jalr	1362(ra) # 80003964 <iunlockput>
  iput(ip);
    8000541a:	8526                	mv	a0,s1
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	4a0080e7          	jalr	1184(ra) # 800038bc <iput>
  end_op();
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	d30080e7          	jalr	-720(ra) # 80004154 <end_op>
  return 0;
    8000542c:	4781                	li	a5,0
    8000542e:	a085                	j	8000548e <sys_link+0x13c>
    end_op();
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	d24080e7          	jalr	-732(ra) # 80004154 <end_op>
    return -1;
    80005438:	57fd                	li	a5,-1
    8000543a:	a891                	j	8000548e <sys_link+0x13c>
    iunlockput(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	526080e7          	jalr	1318(ra) # 80003964 <iunlockput>
    end_op();
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	d0e080e7          	jalr	-754(ra) # 80004154 <end_op>
    return -1;
    8000544e:	57fd                	li	a5,-1
    80005450:	a83d                	j	8000548e <sys_link+0x13c>
    iunlockput(dp);
    80005452:	854a                	mv	a0,s2
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	510080e7          	jalr	1296(ra) # 80003964 <iunlockput>
  ilock(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	2a4080e7          	jalr	676(ra) # 80003702 <ilock>
  ip->nlink--;
    80005466:	04a4d783          	lhu	a5,74(s1)
    8000546a:	37fd                	addiw	a5,a5,-1
    8000546c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	1c6080e7          	jalr	454(ra) # 80003638 <iupdate>
  iunlockput(ip);
    8000547a:	8526                	mv	a0,s1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	4e8080e7          	jalr	1256(ra) # 80003964 <iunlockput>
  end_op();
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	cd0080e7          	jalr	-816(ra) # 80004154 <end_op>
  return -1;
    8000548c:	57fd                	li	a5,-1
}
    8000548e:	853e                	mv	a0,a5
    80005490:	70b2                	ld	ra,296(sp)
    80005492:	7412                	ld	s0,288(sp)
    80005494:	64f2                	ld	s1,280(sp)
    80005496:	6952                	ld	s2,272(sp)
    80005498:	6155                	addi	sp,sp,304
    8000549a:	8082                	ret

000000008000549c <sys_unlink>:
{
    8000549c:	7151                	addi	sp,sp,-240
    8000549e:	f586                	sd	ra,232(sp)
    800054a0:	f1a2                	sd	s0,224(sp)
    800054a2:	eda6                	sd	s1,216(sp)
    800054a4:	e9ca                	sd	s2,208(sp)
    800054a6:	e5ce                	sd	s3,200(sp)
    800054a8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054aa:	08000613          	li	a2,128
    800054ae:	f3040593          	addi	a1,s0,-208
    800054b2:	4501                	li	a0,0
    800054b4:	ffffd097          	auipc	ra,0xffffd
    800054b8:	6d4080e7          	jalr	1748(ra) # 80002b88 <argstr>
    800054bc:	18054163          	bltz	a0,8000563e <sys_unlink+0x1a2>
  begin_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	c14080e7          	jalr	-1004(ra) # 800040d4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054c8:	fb040593          	addi	a1,s0,-80
    800054cc:	f3040513          	addi	a0,s0,-208
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	a06080e7          	jalr	-1530(ra) # 80003ed6 <nameiparent>
    800054d8:	84aa                	mv	s1,a0
    800054da:	c979                	beqz	a0,800055b0 <sys_unlink+0x114>
  ilock(dp);
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	226080e7          	jalr	550(ra) # 80003702 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054e4:	00003597          	auipc	a1,0x3
    800054e8:	23c58593          	addi	a1,a1,572 # 80008720 <syscalls+0x2c0>
    800054ec:	fb040513          	addi	a0,s0,-80
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	6dc080e7          	jalr	1756(ra) # 80003bcc <namecmp>
    800054f8:	14050a63          	beqz	a0,8000564c <sys_unlink+0x1b0>
    800054fc:	00003597          	auipc	a1,0x3
    80005500:	22c58593          	addi	a1,a1,556 # 80008728 <syscalls+0x2c8>
    80005504:	fb040513          	addi	a0,s0,-80
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	6c4080e7          	jalr	1732(ra) # 80003bcc <namecmp>
    80005510:	12050e63          	beqz	a0,8000564c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005514:	f2c40613          	addi	a2,s0,-212
    80005518:	fb040593          	addi	a1,s0,-80
    8000551c:	8526                	mv	a0,s1
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	6c8080e7          	jalr	1736(ra) # 80003be6 <dirlookup>
    80005526:	892a                	mv	s2,a0
    80005528:	12050263          	beqz	a0,8000564c <sys_unlink+0x1b0>
  ilock(ip);
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	1d6080e7          	jalr	470(ra) # 80003702 <ilock>
  if(ip->nlink < 1)
    80005534:	04a91783          	lh	a5,74(s2)
    80005538:	08f05263          	blez	a5,800055bc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000553c:	04491703          	lh	a4,68(s2)
    80005540:	4785                	li	a5,1
    80005542:	08f70563          	beq	a4,a5,800055cc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005546:	4641                	li	a2,16
    80005548:	4581                	li	a1,0
    8000554a:	fc040513          	addi	a0,s0,-64
    8000554e:	ffffb097          	auipc	ra,0xffffb
    80005552:	792080e7          	jalr	1938(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005556:	4741                	li	a4,16
    80005558:	f2c42683          	lw	a3,-212(s0)
    8000555c:	fc040613          	addi	a2,s0,-64
    80005560:	4581                	li	a1,0
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	54a080e7          	jalr	1354(ra) # 80003aae <writei>
    8000556c:	47c1                	li	a5,16
    8000556e:	0af51563          	bne	a0,a5,80005618 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005572:	04491703          	lh	a4,68(s2)
    80005576:	4785                	li	a5,1
    80005578:	0af70863          	beq	a4,a5,80005628 <sys_unlink+0x18c>
  iunlockput(dp);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	3e6080e7          	jalr	998(ra) # 80003964 <iunlockput>
  ip->nlink--;
    80005586:	04a95783          	lhu	a5,74(s2)
    8000558a:	37fd                	addiw	a5,a5,-1
    8000558c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005590:	854a                	mv	a0,s2
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	0a6080e7          	jalr	166(ra) # 80003638 <iupdate>
  iunlockput(ip);
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	3c8080e7          	jalr	968(ra) # 80003964 <iunlockput>
  end_op();
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	bb0080e7          	jalr	-1104(ra) # 80004154 <end_op>
  return 0;
    800055ac:	4501                	li	a0,0
    800055ae:	a84d                	j	80005660 <sys_unlink+0x1c4>
    end_op();
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	ba4080e7          	jalr	-1116(ra) # 80004154 <end_op>
    return -1;
    800055b8:	557d                	li	a0,-1
    800055ba:	a05d                	j	80005660 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055bc:	00003517          	auipc	a0,0x3
    800055c0:	19450513          	addi	a0,a0,404 # 80008750 <syscalls+0x2f0>
    800055c4:	ffffb097          	auipc	ra,0xffffb
    800055c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055cc:	04c92703          	lw	a4,76(s2)
    800055d0:	02000793          	li	a5,32
    800055d4:	f6e7f9e3          	bgeu	a5,a4,80005546 <sys_unlink+0xaa>
    800055d8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055dc:	4741                	li	a4,16
    800055de:	86ce                	mv	a3,s3
    800055e0:	f1840613          	addi	a2,s0,-232
    800055e4:	4581                	li	a1,0
    800055e6:	854a                	mv	a0,s2
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	3ce080e7          	jalr	974(ra) # 800039b6 <readi>
    800055f0:	47c1                	li	a5,16
    800055f2:	00f51b63          	bne	a0,a5,80005608 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055f6:	f1845783          	lhu	a5,-232(s0)
    800055fa:	e7a1                	bnez	a5,80005642 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055fc:	29c1                	addiw	s3,s3,16
    800055fe:	04c92783          	lw	a5,76(s2)
    80005602:	fcf9ede3          	bltu	s3,a5,800055dc <sys_unlink+0x140>
    80005606:	b781                	j	80005546 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005608:	00003517          	auipc	a0,0x3
    8000560c:	16050513          	addi	a0,a0,352 # 80008768 <syscalls+0x308>
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005618:	00003517          	auipc	a0,0x3
    8000561c:	16850513          	addi	a0,a0,360 # 80008780 <syscalls+0x320>
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	f1e080e7          	jalr	-226(ra) # 8000053e <panic>
    dp->nlink--;
    80005628:	04a4d783          	lhu	a5,74(s1)
    8000562c:	37fd                	addiw	a5,a5,-1
    8000562e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005632:	8526                	mv	a0,s1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	004080e7          	jalr	4(ra) # 80003638 <iupdate>
    8000563c:	b781                	j	8000557c <sys_unlink+0xe0>
    return -1;
    8000563e:	557d                	li	a0,-1
    80005640:	a005                	j	80005660 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005642:	854a                	mv	a0,s2
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	320080e7          	jalr	800(ra) # 80003964 <iunlockput>
  iunlockput(dp);
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	316080e7          	jalr	790(ra) # 80003964 <iunlockput>
  end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	afe080e7          	jalr	-1282(ra) # 80004154 <end_op>
  return -1;
    8000565e:	557d                	li	a0,-1
}
    80005660:	70ae                	ld	ra,232(sp)
    80005662:	740e                	ld	s0,224(sp)
    80005664:	64ee                	ld	s1,216(sp)
    80005666:	694e                	ld	s2,208(sp)
    80005668:	69ae                	ld	s3,200(sp)
    8000566a:	616d                	addi	sp,sp,240
    8000566c:	8082                	ret

000000008000566e <sys_open>:

uint64
sys_open(void)
{
    8000566e:	7131                	addi	sp,sp,-192
    80005670:	fd06                	sd	ra,184(sp)
    80005672:	f922                	sd	s0,176(sp)
    80005674:	f526                	sd	s1,168(sp)
    80005676:	f14a                	sd	s2,160(sp)
    80005678:	ed4e                	sd	s3,152(sp)
    8000567a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000567c:	08000613          	li	a2,128
    80005680:	f5040593          	addi	a1,s0,-176
    80005684:	4501                	li	a0,0
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	502080e7          	jalr	1282(ra) # 80002b88 <argstr>
    return -1;
    8000568e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005690:	0c054163          	bltz	a0,80005752 <sys_open+0xe4>
    80005694:	f4c40593          	addi	a1,s0,-180
    80005698:	4505                	li	a0,1
    8000569a:	ffffd097          	auipc	ra,0xffffd
    8000569e:	4aa080e7          	jalr	1194(ra) # 80002b44 <argint>
    800056a2:	0a054863          	bltz	a0,80005752 <sys_open+0xe4>

  begin_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	a2e080e7          	jalr	-1490(ra) # 800040d4 <begin_op>

  if(omode & O_CREATE){
    800056ae:	f4c42783          	lw	a5,-180(s0)
    800056b2:	2007f793          	andi	a5,a5,512
    800056b6:	cbdd                	beqz	a5,8000576c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056b8:	4681                	li	a3,0
    800056ba:	4601                	li	a2,0
    800056bc:	4589                	li	a1,2
    800056be:	f5040513          	addi	a0,s0,-176
    800056c2:	00000097          	auipc	ra,0x0
    800056c6:	972080e7          	jalr	-1678(ra) # 80005034 <create>
    800056ca:	892a                	mv	s2,a0
    if(ip == 0){
    800056cc:	c959                	beqz	a0,80005762 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056ce:	04491703          	lh	a4,68(s2)
    800056d2:	478d                	li	a5,3
    800056d4:	00f71763          	bne	a4,a5,800056e2 <sys_open+0x74>
    800056d8:	04695703          	lhu	a4,70(s2)
    800056dc:	47a5                	li	a5,9
    800056de:	0ce7ec63          	bltu	a5,a4,800057b6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	e02080e7          	jalr	-510(ra) # 800044e4 <filealloc>
    800056ea:	89aa                	mv	s3,a0
    800056ec:	10050263          	beqz	a0,800057f0 <sys_open+0x182>
    800056f0:	00000097          	auipc	ra,0x0
    800056f4:	902080e7          	jalr	-1790(ra) # 80004ff2 <fdalloc>
    800056f8:	84aa                	mv	s1,a0
    800056fa:	0e054663          	bltz	a0,800057e6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056fe:	04491703          	lh	a4,68(s2)
    80005702:	478d                	li	a5,3
    80005704:	0cf70463          	beq	a4,a5,800057cc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005708:	4789                	li	a5,2
    8000570a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000570e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005712:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005716:	f4c42783          	lw	a5,-180(s0)
    8000571a:	0017c713          	xori	a4,a5,1
    8000571e:	8b05                	andi	a4,a4,1
    80005720:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005724:	0037f713          	andi	a4,a5,3
    80005728:	00e03733          	snez	a4,a4
    8000572c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005730:	4007f793          	andi	a5,a5,1024
    80005734:	c791                	beqz	a5,80005740 <sys_open+0xd2>
    80005736:	04491703          	lh	a4,68(s2)
    8000573a:	4789                	li	a5,2
    8000573c:	08f70f63          	beq	a4,a5,800057da <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005740:	854a                	mv	a0,s2
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	082080e7          	jalr	130(ra) # 800037c4 <iunlock>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	a0a080e7          	jalr	-1526(ra) # 80004154 <end_op>

  return fd;
}
    80005752:	8526                	mv	a0,s1
    80005754:	70ea                	ld	ra,184(sp)
    80005756:	744a                	ld	s0,176(sp)
    80005758:	74aa                	ld	s1,168(sp)
    8000575a:	790a                	ld	s2,160(sp)
    8000575c:	69ea                	ld	s3,152(sp)
    8000575e:	6129                	addi	sp,sp,192
    80005760:	8082                	ret
      end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	9f2080e7          	jalr	-1550(ra) # 80004154 <end_op>
      return -1;
    8000576a:	b7e5                	j	80005752 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000576c:	f5040513          	addi	a0,s0,-176
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	748080e7          	jalr	1864(ra) # 80003eb8 <namei>
    80005778:	892a                	mv	s2,a0
    8000577a:	c905                	beqz	a0,800057aa <sys_open+0x13c>
    ilock(ip);
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	f86080e7          	jalr	-122(ra) # 80003702 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005784:	04491703          	lh	a4,68(s2)
    80005788:	4785                	li	a5,1
    8000578a:	f4f712e3          	bne	a4,a5,800056ce <sys_open+0x60>
    8000578e:	f4c42783          	lw	a5,-180(s0)
    80005792:	dba1                	beqz	a5,800056e2 <sys_open+0x74>
      iunlockput(ip);
    80005794:	854a                	mv	a0,s2
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	1ce080e7          	jalr	462(ra) # 80003964 <iunlockput>
      end_op();
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	9b6080e7          	jalr	-1610(ra) # 80004154 <end_op>
      return -1;
    800057a6:	54fd                	li	s1,-1
    800057a8:	b76d                	j	80005752 <sys_open+0xe4>
      end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	9aa080e7          	jalr	-1622(ra) # 80004154 <end_op>
      return -1;
    800057b2:	54fd                	li	s1,-1
    800057b4:	bf79                	j	80005752 <sys_open+0xe4>
    iunlockput(ip);
    800057b6:	854a                	mv	a0,s2
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	1ac080e7          	jalr	428(ra) # 80003964 <iunlockput>
    end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	994080e7          	jalr	-1644(ra) # 80004154 <end_op>
    return -1;
    800057c8:	54fd                	li	s1,-1
    800057ca:	b761                	j	80005752 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057cc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057d0:	04691783          	lh	a5,70(s2)
    800057d4:	02f99223          	sh	a5,36(s3)
    800057d8:	bf2d                	j	80005712 <sys_open+0xa4>
    itrunc(ip);
    800057da:	854a                	mv	a0,s2
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	034080e7          	jalr	52(ra) # 80003810 <itrunc>
    800057e4:	bfb1                	j	80005740 <sys_open+0xd2>
      fileclose(f);
    800057e6:	854e                	mv	a0,s3
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	db8080e7          	jalr	-584(ra) # 800045a0 <fileclose>
    iunlockput(ip);
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	172080e7          	jalr	370(ra) # 80003964 <iunlockput>
    end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	95a080e7          	jalr	-1702(ra) # 80004154 <end_op>
    return -1;
    80005802:	54fd                	li	s1,-1
    80005804:	b7b9                	j	80005752 <sys_open+0xe4>

0000000080005806 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005806:	7175                	addi	sp,sp,-144
    80005808:	e506                	sd	ra,136(sp)
    8000580a:	e122                	sd	s0,128(sp)
    8000580c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	8c6080e7          	jalr	-1850(ra) # 800040d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005816:	08000613          	li	a2,128
    8000581a:	f7040593          	addi	a1,s0,-144
    8000581e:	4501                	li	a0,0
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	368080e7          	jalr	872(ra) # 80002b88 <argstr>
    80005828:	02054963          	bltz	a0,8000585a <sys_mkdir+0x54>
    8000582c:	4681                	li	a3,0
    8000582e:	4601                	li	a2,0
    80005830:	4585                	li	a1,1
    80005832:	f7040513          	addi	a0,s0,-144
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	7fe080e7          	jalr	2046(ra) # 80005034 <create>
    8000583e:	cd11                	beqz	a0,8000585a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	124080e7          	jalr	292(ra) # 80003964 <iunlockput>
  end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	90c080e7          	jalr	-1780(ra) # 80004154 <end_op>
  return 0;
    80005850:	4501                	li	a0,0
}
    80005852:	60aa                	ld	ra,136(sp)
    80005854:	640a                	ld	s0,128(sp)
    80005856:	6149                	addi	sp,sp,144
    80005858:	8082                	ret
    end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	8fa080e7          	jalr	-1798(ra) # 80004154 <end_op>
    return -1;
    80005862:	557d                	li	a0,-1
    80005864:	b7fd                	j	80005852 <sys_mkdir+0x4c>

0000000080005866 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005866:	7135                	addi	sp,sp,-160
    80005868:	ed06                	sd	ra,152(sp)
    8000586a:	e922                	sd	s0,144(sp)
    8000586c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	866080e7          	jalr	-1946(ra) # 800040d4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005876:	08000613          	li	a2,128
    8000587a:	f7040593          	addi	a1,s0,-144
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	308080e7          	jalr	776(ra) # 80002b88 <argstr>
    80005888:	04054a63          	bltz	a0,800058dc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000588c:	f6c40593          	addi	a1,s0,-148
    80005890:	4505                	li	a0,1
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	2b2080e7          	jalr	690(ra) # 80002b44 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000589a:	04054163          	bltz	a0,800058dc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000589e:	f6840593          	addi	a1,s0,-152
    800058a2:	4509                	li	a0,2
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	2a0080e7          	jalr	672(ra) # 80002b44 <argint>
     argint(1, &major) < 0 ||
    800058ac:	02054863          	bltz	a0,800058dc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058b0:	f6841683          	lh	a3,-152(s0)
    800058b4:	f6c41603          	lh	a2,-148(s0)
    800058b8:	458d                	li	a1,3
    800058ba:	f7040513          	addi	a0,s0,-144
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	776080e7          	jalr	1910(ra) # 80005034 <create>
     argint(2, &minor) < 0 ||
    800058c6:	c919                	beqz	a0,800058dc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	09c080e7          	jalr	156(ra) # 80003964 <iunlockput>
  end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	884080e7          	jalr	-1916(ra) # 80004154 <end_op>
  return 0;
    800058d8:	4501                	li	a0,0
    800058da:	a031                	j	800058e6 <sys_mknod+0x80>
    end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	878080e7          	jalr	-1928(ra) # 80004154 <end_op>
    return -1;
    800058e4:	557d                	li	a0,-1
}
    800058e6:	60ea                	ld	ra,152(sp)
    800058e8:	644a                	ld	s0,144(sp)
    800058ea:	610d                	addi	sp,sp,160
    800058ec:	8082                	ret

00000000800058ee <sys_chdir>:

uint64
sys_chdir(void)
{
    800058ee:	7135                	addi	sp,sp,-160
    800058f0:	ed06                	sd	ra,152(sp)
    800058f2:	e922                	sd	s0,144(sp)
    800058f4:	e526                	sd	s1,136(sp)
    800058f6:	e14a                	sd	s2,128(sp)
    800058f8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058fa:	ffffc097          	auipc	ra,0xffffc
    800058fe:	0be080e7          	jalr	190(ra) # 800019b8 <myproc>
    80005902:	892a                	mv	s2,a0
  
  begin_op();
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	7d0080e7          	jalr	2000(ra) # 800040d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000590c:	08000613          	li	a2,128
    80005910:	f6040593          	addi	a1,s0,-160
    80005914:	4501                	li	a0,0
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	272080e7          	jalr	626(ra) # 80002b88 <argstr>
    8000591e:	04054b63          	bltz	a0,80005974 <sys_chdir+0x86>
    80005922:	f6040513          	addi	a0,s0,-160
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	592080e7          	jalr	1426(ra) # 80003eb8 <namei>
    8000592e:	84aa                	mv	s1,a0
    80005930:	c131                	beqz	a0,80005974 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	dd0080e7          	jalr	-560(ra) # 80003702 <ilock>
  if(ip->type != T_DIR){
    8000593a:	04449703          	lh	a4,68(s1)
    8000593e:	4785                	li	a5,1
    80005940:	04f71063          	bne	a4,a5,80005980 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	e7e080e7          	jalr	-386(ra) # 800037c4 <iunlock>
  iput(p->cwd);
    8000594e:	15093503          	ld	a0,336(s2)
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	f6a080e7          	jalr	-150(ra) # 800038bc <iput>
  end_op();
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	7fa080e7          	jalr	2042(ra) # 80004154 <end_op>
  p->cwd = ip;
    80005962:	14993823          	sd	s1,336(s2)
  return 0;
    80005966:	4501                	li	a0,0
}
    80005968:	60ea                	ld	ra,152(sp)
    8000596a:	644a                	ld	s0,144(sp)
    8000596c:	64aa                	ld	s1,136(sp)
    8000596e:	690a                	ld	s2,128(sp)
    80005970:	610d                	addi	sp,sp,160
    80005972:	8082                	ret
    end_op();
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	7e0080e7          	jalr	2016(ra) # 80004154 <end_op>
    return -1;
    8000597c:	557d                	li	a0,-1
    8000597e:	b7ed                	j	80005968 <sys_chdir+0x7a>
    iunlockput(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	fe2080e7          	jalr	-30(ra) # 80003964 <iunlockput>
    end_op();
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	7ca080e7          	jalr	1994(ra) # 80004154 <end_op>
    return -1;
    80005992:	557d                	li	a0,-1
    80005994:	bfd1                	j	80005968 <sys_chdir+0x7a>

0000000080005996 <sys_exec>:

uint64
sys_exec(void)
{
    80005996:	7145                	addi	sp,sp,-464
    80005998:	e786                	sd	ra,456(sp)
    8000599a:	e3a2                	sd	s0,448(sp)
    8000599c:	ff26                	sd	s1,440(sp)
    8000599e:	fb4a                	sd	s2,432(sp)
    800059a0:	f74e                	sd	s3,424(sp)
    800059a2:	f352                	sd	s4,416(sp)
    800059a4:	ef56                	sd	s5,408(sp)
    800059a6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059a8:	08000613          	li	a2,128
    800059ac:	f4040593          	addi	a1,s0,-192
    800059b0:	4501                	li	a0,0
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	1d6080e7          	jalr	470(ra) # 80002b88 <argstr>
    return -1;
    800059ba:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059bc:	0c054a63          	bltz	a0,80005a90 <sys_exec+0xfa>
    800059c0:	e3840593          	addi	a1,s0,-456
    800059c4:	4505                	li	a0,1
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	1a0080e7          	jalr	416(ra) # 80002b66 <argaddr>
    800059ce:	0c054163          	bltz	a0,80005a90 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059d2:	10000613          	li	a2,256
    800059d6:	4581                	li	a1,0
    800059d8:	e4040513          	addi	a0,s0,-448
    800059dc:	ffffb097          	auipc	ra,0xffffb
    800059e0:	304080e7          	jalr	772(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059e4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059e8:	89a6                	mv	s3,s1
    800059ea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059ec:	02000a13          	li	s4,32
    800059f0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059f4:	00391513          	slli	a0,s2,0x3
    800059f8:	e3040593          	addi	a1,s0,-464
    800059fc:	e3843783          	ld	a5,-456(s0)
    80005a00:	953e                	add	a0,a0,a5
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	0a8080e7          	jalr	168(ra) # 80002aaa <fetchaddr>
    80005a0a:	02054a63          	bltz	a0,80005a3e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a0e:	e3043783          	ld	a5,-464(s0)
    80005a12:	c3b9                	beqz	a5,80005a58 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a14:	ffffb097          	auipc	ra,0xffffb
    80005a18:	0e0080e7          	jalr	224(ra) # 80000af4 <kalloc>
    80005a1c:	85aa                	mv	a1,a0
    80005a1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a22:	cd11                	beqz	a0,80005a3e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a24:	6605                	lui	a2,0x1
    80005a26:	e3043503          	ld	a0,-464(s0)
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	0d2080e7          	jalr	210(ra) # 80002afc <fetchstr>
    80005a32:	00054663          	bltz	a0,80005a3e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a36:	0905                	addi	s2,s2,1
    80005a38:	09a1                	addi	s3,s3,8
    80005a3a:	fb491be3          	bne	s2,s4,800059f0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3e:	10048913          	addi	s2,s1,256
    80005a42:	6088                	ld	a0,0(s1)
    80005a44:	c529                	beqz	a0,80005a8e <sys_exec+0xf8>
    kfree(argv[i]);
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	fb2080e7          	jalr	-78(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4e:	04a1                	addi	s1,s1,8
    80005a50:	ff2499e3          	bne	s1,s2,80005a42 <sys_exec+0xac>
  return -1;
    80005a54:	597d                	li	s2,-1
    80005a56:	a82d                	j	80005a90 <sys_exec+0xfa>
      argv[i] = 0;
    80005a58:	0a8e                	slli	s5,s5,0x3
    80005a5a:	fc040793          	addi	a5,s0,-64
    80005a5e:	9abe                	add	s5,s5,a5
    80005a60:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a64:	e4040593          	addi	a1,s0,-448
    80005a68:	f4040513          	addi	a0,s0,-192
    80005a6c:	fffff097          	auipc	ra,0xfffff
    80005a70:	194080e7          	jalr	404(ra) # 80004c00 <exec>
    80005a74:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a76:	10048993          	addi	s3,s1,256
    80005a7a:	6088                	ld	a0,0(s1)
    80005a7c:	c911                	beqz	a0,80005a90 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a7e:	ffffb097          	auipc	ra,0xffffb
    80005a82:	f7a080e7          	jalr	-134(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a86:	04a1                	addi	s1,s1,8
    80005a88:	ff3499e3          	bne	s1,s3,80005a7a <sys_exec+0xe4>
    80005a8c:	a011                	j	80005a90 <sys_exec+0xfa>
  return -1;
    80005a8e:	597d                	li	s2,-1
}
    80005a90:	854a                	mv	a0,s2
    80005a92:	60be                	ld	ra,456(sp)
    80005a94:	641e                	ld	s0,448(sp)
    80005a96:	74fa                	ld	s1,440(sp)
    80005a98:	795a                	ld	s2,432(sp)
    80005a9a:	79ba                	ld	s3,424(sp)
    80005a9c:	7a1a                	ld	s4,416(sp)
    80005a9e:	6afa                	ld	s5,408(sp)
    80005aa0:	6179                	addi	sp,sp,464
    80005aa2:	8082                	ret

0000000080005aa4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aa4:	7139                	addi	sp,sp,-64
    80005aa6:	fc06                	sd	ra,56(sp)
    80005aa8:	f822                	sd	s0,48(sp)
    80005aaa:	f426                	sd	s1,40(sp)
    80005aac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	f0a080e7          	jalr	-246(ra) # 800019b8 <myproc>
    80005ab6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ab8:	fd840593          	addi	a1,s0,-40
    80005abc:	4501                	li	a0,0
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0a8080e7          	jalr	168(ra) # 80002b66 <argaddr>
    return -1;
    80005ac6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ac8:	0e054063          	bltz	a0,80005ba8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005acc:	fc840593          	addi	a1,s0,-56
    80005ad0:	fd040513          	addi	a0,s0,-48
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	dfc080e7          	jalr	-516(ra) # 800048d0 <pipealloc>
    return -1;
    80005adc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ade:	0c054563          	bltz	a0,80005ba8 <sys_pipe+0x104>
  fd0 = -1;
    80005ae2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ae6:	fd043503          	ld	a0,-48(s0)
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	508080e7          	jalr	1288(ra) # 80004ff2 <fdalloc>
    80005af2:	fca42223          	sw	a0,-60(s0)
    80005af6:	08054c63          	bltz	a0,80005b8e <sys_pipe+0xea>
    80005afa:	fc843503          	ld	a0,-56(s0)
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	4f4080e7          	jalr	1268(ra) # 80004ff2 <fdalloc>
    80005b06:	fca42023          	sw	a0,-64(s0)
    80005b0a:	06054863          	bltz	a0,80005b7a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b0e:	4691                	li	a3,4
    80005b10:	fc440613          	addi	a2,s0,-60
    80005b14:	fd843583          	ld	a1,-40(s0)
    80005b18:	68a8                	ld	a0,80(s1)
    80005b1a:	ffffc097          	auipc	ra,0xffffc
    80005b1e:	b60080e7          	jalr	-1184(ra) # 8000167a <copyout>
    80005b22:	02054063          	bltz	a0,80005b42 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b26:	4691                	li	a3,4
    80005b28:	fc040613          	addi	a2,s0,-64
    80005b2c:	fd843583          	ld	a1,-40(s0)
    80005b30:	0591                	addi	a1,a1,4
    80005b32:	68a8                	ld	a0,80(s1)
    80005b34:	ffffc097          	auipc	ra,0xffffc
    80005b38:	b46080e7          	jalr	-1210(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b3c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b3e:	06055563          	bgez	a0,80005ba8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b42:	fc442783          	lw	a5,-60(s0)
    80005b46:	07e9                	addi	a5,a5,26
    80005b48:	078e                	slli	a5,a5,0x3
    80005b4a:	97a6                	add	a5,a5,s1
    80005b4c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b50:	fc042503          	lw	a0,-64(s0)
    80005b54:	0569                	addi	a0,a0,26
    80005b56:	050e                	slli	a0,a0,0x3
    80005b58:	9526                	add	a0,a0,s1
    80005b5a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b5e:	fd043503          	ld	a0,-48(s0)
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	a3e080e7          	jalr	-1474(ra) # 800045a0 <fileclose>
    fileclose(wf);
    80005b6a:	fc843503          	ld	a0,-56(s0)
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	a32080e7          	jalr	-1486(ra) # 800045a0 <fileclose>
    return -1;
    80005b76:	57fd                	li	a5,-1
    80005b78:	a805                	j	80005ba8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b7a:	fc442783          	lw	a5,-60(s0)
    80005b7e:	0007c863          	bltz	a5,80005b8e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b82:	01a78513          	addi	a0,a5,26
    80005b86:	050e                	slli	a0,a0,0x3
    80005b88:	9526                	add	a0,a0,s1
    80005b8a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b8e:	fd043503          	ld	a0,-48(s0)
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	a0e080e7          	jalr	-1522(ra) # 800045a0 <fileclose>
    fileclose(wf);
    80005b9a:	fc843503          	ld	a0,-56(s0)
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	a02080e7          	jalr	-1534(ra) # 800045a0 <fileclose>
    return -1;
    80005ba6:	57fd                	li	a5,-1
}
    80005ba8:	853e                	mv	a0,a5
    80005baa:	70e2                	ld	ra,56(sp)
    80005bac:	7442                	ld	s0,48(sp)
    80005bae:	74a2                	ld	s1,40(sp)
    80005bb0:	6121                	addi	sp,sp,64
    80005bb2:	8082                	ret
	...

0000000080005bc0 <kernelvec>:
    80005bc0:	7111                	addi	sp,sp,-256
    80005bc2:	e006                	sd	ra,0(sp)
    80005bc4:	e40a                	sd	sp,8(sp)
    80005bc6:	e80e                	sd	gp,16(sp)
    80005bc8:	ec12                	sd	tp,24(sp)
    80005bca:	f016                	sd	t0,32(sp)
    80005bcc:	f41a                	sd	t1,40(sp)
    80005bce:	f81e                	sd	t2,48(sp)
    80005bd0:	fc22                	sd	s0,56(sp)
    80005bd2:	e0a6                	sd	s1,64(sp)
    80005bd4:	e4aa                	sd	a0,72(sp)
    80005bd6:	e8ae                	sd	a1,80(sp)
    80005bd8:	ecb2                	sd	a2,88(sp)
    80005bda:	f0b6                	sd	a3,96(sp)
    80005bdc:	f4ba                	sd	a4,104(sp)
    80005bde:	f8be                	sd	a5,112(sp)
    80005be0:	fcc2                	sd	a6,120(sp)
    80005be2:	e146                	sd	a7,128(sp)
    80005be4:	e54a                	sd	s2,136(sp)
    80005be6:	e94e                	sd	s3,144(sp)
    80005be8:	ed52                	sd	s4,152(sp)
    80005bea:	f156                	sd	s5,160(sp)
    80005bec:	f55a                	sd	s6,168(sp)
    80005bee:	f95e                	sd	s7,176(sp)
    80005bf0:	fd62                	sd	s8,184(sp)
    80005bf2:	e1e6                	sd	s9,192(sp)
    80005bf4:	e5ea                	sd	s10,200(sp)
    80005bf6:	e9ee                	sd	s11,208(sp)
    80005bf8:	edf2                	sd	t3,216(sp)
    80005bfa:	f1f6                	sd	t4,224(sp)
    80005bfc:	f5fa                	sd	t5,232(sp)
    80005bfe:	f9fe                	sd	t6,240(sp)
    80005c00:	d77fc0ef          	jal	ra,80002976 <kerneltrap>
    80005c04:	6082                	ld	ra,0(sp)
    80005c06:	6122                	ld	sp,8(sp)
    80005c08:	61c2                	ld	gp,16(sp)
    80005c0a:	7282                	ld	t0,32(sp)
    80005c0c:	7322                	ld	t1,40(sp)
    80005c0e:	73c2                	ld	t2,48(sp)
    80005c10:	7462                	ld	s0,56(sp)
    80005c12:	6486                	ld	s1,64(sp)
    80005c14:	6526                	ld	a0,72(sp)
    80005c16:	65c6                	ld	a1,80(sp)
    80005c18:	6666                	ld	a2,88(sp)
    80005c1a:	7686                	ld	a3,96(sp)
    80005c1c:	7726                	ld	a4,104(sp)
    80005c1e:	77c6                	ld	a5,112(sp)
    80005c20:	7866                	ld	a6,120(sp)
    80005c22:	688a                	ld	a7,128(sp)
    80005c24:	692a                	ld	s2,136(sp)
    80005c26:	69ca                	ld	s3,144(sp)
    80005c28:	6a6a                	ld	s4,152(sp)
    80005c2a:	7a8a                	ld	s5,160(sp)
    80005c2c:	7b2a                	ld	s6,168(sp)
    80005c2e:	7bca                	ld	s7,176(sp)
    80005c30:	7c6a                	ld	s8,184(sp)
    80005c32:	6c8e                	ld	s9,192(sp)
    80005c34:	6d2e                	ld	s10,200(sp)
    80005c36:	6dce                	ld	s11,208(sp)
    80005c38:	6e6e                	ld	t3,216(sp)
    80005c3a:	7e8e                	ld	t4,224(sp)
    80005c3c:	7f2e                	ld	t5,232(sp)
    80005c3e:	7fce                	ld	t6,240(sp)
    80005c40:	6111                	addi	sp,sp,256
    80005c42:	10200073          	sret
    80005c46:	00000013          	nop
    80005c4a:	00000013          	nop
    80005c4e:	0001                	nop

0000000080005c50 <timervec>:
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	e10c                	sd	a1,0(a0)
    80005c56:	e510                	sd	a2,8(a0)
    80005c58:	e914                	sd	a3,16(a0)
    80005c5a:	6d0c                	ld	a1,24(a0)
    80005c5c:	7110                	ld	a2,32(a0)
    80005c5e:	6194                	ld	a3,0(a1)
    80005c60:	96b2                	add	a3,a3,a2
    80005c62:	e194                	sd	a3,0(a1)
    80005c64:	4589                	li	a1,2
    80005c66:	14459073          	csrw	sip,a1
    80005c6a:	6914                	ld	a3,16(a0)
    80005c6c:	6510                	ld	a2,8(a0)
    80005c6e:	610c                	ld	a1,0(a0)
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	30200073          	mret
	...

0000000080005c7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c7a:	1141                	addi	sp,sp,-16
    80005c7c:	e422                	sd	s0,8(sp)
    80005c7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c80:	0c0007b7          	lui	a5,0xc000
    80005c84:	4705                	li	a4,1
    80005c86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c88:	c3d8                	sw	a4,4(a5)
}
    80005c8a:	6422                	ld	s0,8(sp)
    80005c8c:	0141                	addi	sp,sp,16
    80005c8e:	8082                	ret

0000000080005c90 <plicinithart>:

void
plicinithart(void)
{
    80005c90:	1141                	addi	sp,sp,-16
    80005c92:	e406                	sd	ra,8(sp)
    80005c94:	e022                	sd	s0,0(sp)
    80005c96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	cf4080e7          	jalr	-780(ra) # 8000198c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ca0:	0085171b          	slliw	a4,a0,0x8
    80005ca4:	0c0027b7          	lui	a5,0xc002
    80005ca8:	97ba                	add	a5,a5,a4
    80005caa:	40200713          	li	a4,1026
    80005cae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cb2:	00d5151b          	slliw	a0,a0,0xd
    80005cb6:	0c2017b7          	lui	a5,0xc201
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	00052023          	sw	zero,0(a0)
}
    80005cc0:	60a2                	ld	ra,8(sp)
    80005cc2:	6402                	ld	s0,0(sp)
    80005cc4:	0141                	addi	sp,sp,16
    80005cc6:	8082                	ret

0000000080005cc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	cbc080e7          	jalr	-836(ra) # 8000198c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cd8:	00d5179b          	slliw	a5,a0,0xd
    80005cdc:	0c201537          	lui	a0,0xc201
    80005ce0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ce2:	4148                	lw	a0,4(a0)
    80005ce4:	60a2                	ld	ra,8(sp)
    80005ce6:	6402                	ld	s0,0(sp)
    80005ce8:	0141                	addi	sp,sp,16
    80005cea:	8082                	ret

0000000080005cec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cec:	1101                	addi	sp,sp,-32
    80005cee:	ec06                	sd	ra,24(sp)
    80005cf0:	e822                	sd	s0,16(sp)
    80005cf2:	e426                	sd	s1,8(sp)
    80005cf4:	1000                	addi	s0,sp,32
    80005cf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	c94080e7          	jalr	-876(ra) # 8000198c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d00:	00d5151b          	slliw	a0,a0,0xd
    80005d04:	0c2017b7          	lui	a5,0xc201
    80005d08:	97aa                	add	a5,a5,a0
    80005d0a:	c3c4                	sw	s1,4(a5)
}
    80005d0c:	60e2                	ld	ra,24(sp)
    80005d0e:	6442                	ld	s0,16(sp)
    80005d10:	64a2                	ld	s1,8(sp)
    80005d12:	6105                	addi	sp,sp,32
    80005d14:	8082                	ret

0000000080005d16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d16:	1141                	addi	sp,sp,-16
    80005d18:	e406                	sd	ra,8(sp)
    80005d1a:	e022                	sd	s0,0(sp)
    80005d1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d1e:	479d                	li	a5,7
    80005d20:	06a7c963          	blt	a5,a0,80005d92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d24:	0001d797          	auipc	a5,0x1d
    80005d28:	2dc78793          	addi	a5,a5,732 # 80023000 <disk>
    80005d2c:	00a78733          	add	a4,a5,a0
    80005d30:	6789                	lui	a5,0x2
    80005d32:	97ba                	add	a5,a5,a4
    80005d34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d38:	e7ad                	bnez	a5,80005da2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d3a:	00451793          	slli	a5,a0,0x4
    80005d3e:	0001f717          	auipc	a4,0x1f
    80005d42:	2c270713          	addi	a4,a4,706 # 80025000 <disk+0x2000>
    80005d46:	6314                	ld	a3,0(a4)
    80005d48:	96be                	add	a3,a3,a5
    80005d4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d4e:	6314                	ld	a3,0(a4)
    80005d50:	96be                	add	a3,a3,a5
    80005d52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d56:	6314                	ld	a3,0(a4)
    80005d58:	96be                	add	a3,a3,a5
    80005d5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d5e:	6318                	ld	a4,0(a4)
    80005d60:	97ba                	add	a5,a5,a4
    80005d62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d66:	0001d797          	auipc	a5,0x1d
    80005d6a:	29a78793          	addi	a5,a5,666 # 80023000 <disk>
    80005d6e:	97aa                	add	a5,a5,a0
    80005d70:	6509                	lui	a0,0x2
    80005d72:	953e                	add	a0,a0,a5
    80005d74:	4785                	li	a5,1
    80005d76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d7a:	0001f517          	auipc	a0,0x1f
    80005d7e:	29e50513          	addi	a0,a0,670 # 80025018 <disk+0x2018>
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	4be080e7          	jalr	1214(ra) # 80002240 <wakeup>
}
    80005d8a:	60a2                	ld	ra,8(sp)
    80005d8c:	6402                	ld	s0,0(sp)
    80005d8e:	0141                	addi	sp,sp,16
    80005d90:	8082                	ret
    panic("free_desc 1");
    80005d92:	00003517          	auipc	a0,0x3
    80005d96:	9fe50513          	addi	a0,a0,-1538 # 80008790 <syscalls+0x330>
    80005d9a:	ffffa097          	auipc	ra,0xffffa
    80005d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005da2:	00003517          	auipc	a0,0x3
    80005da6:	9fe50513          	addi	a0,a0,-1538 # 800087a0 <syscalls+0x340>
    80005daa:	ffffa097          	auipc	ra,0xffffa
    80005dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>

0000000080005db2 <virtio_disk_init>:
{
    80005db2:	1101                	addi	sp,sp,-32
    80005db4:	ec06                	sd	ra,24(sp)
    80005db6:	e822                	sd	s0,16(sp)
    80005db8:	e426                	sd	s1,8(sp)
    80005dba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dbc:	00003597          	auipc	a1,0x3
    80005dc0:	9f458593          	addi	a1,a1,-1548 # 800087b0 <syscalls+0x350>
    80005dc4:	0001f517          	auipc	a0,0x1f
    80005dc8:	36450513          	addi	a0,a0,868 # 80025128 <disk+0x2128>
    80005dcc:	ffffb097          	auipc	ra,0xffffb
    80005dd0:	d88080e7          	jalr	-632(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd4:	100017b7          	lui	a5,0x10001
    80005dd8:	4398                	lw	a4,0(a5)
    80005dda:	2701                	sext.w	a4,a4
    80005ddc:	747277b7          	lui	a5,0x74727
    80005de0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005de4:	0ef71163          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005de8:	100017b7          	lui	a5,0x10001
    80005dec:	43dc                	lw	a5,4(a5)
    80005dee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df0:	4705                	li	a4,1
    80005df2:	0ce79a63          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005df6:	100017b7          	lui	a5,0x10001
    80005dfa:	479c                	lw	a5,8(a5)
    80005dfc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dfe:	4709                	li	a4,2
    80005e00:	0ce79363          	bne	a5,a4,80005ec6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e04:	100017b7          	lui	a5,0x10001
    80005e08:	47d8                	lw	a4,12(a5)
    80005e0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e0c:	554d47b7          	lui	a5,0x554d4
    80005e10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e14:	0af71963          	bne	a4,a5,80005ec6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e18:	100017b7          	lui	a5,0x10001
    80005e1c:	4705                	li	a4,1
    80005e1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e20:	470d                	li	a4,3
    80005e22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e26:	c7ffe737          	lui	a4,0xc7ffe
    80005e2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e34:	472d                	li	a4,11
    80005e36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e38:	473d                	li	a4,15
    80005e3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e3c:	6705                	lui	a4,0x1
    80005e3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e44:	5bdc                	lw	a5,52(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e48:	c7d9                	beqz	a5,80005ed6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005e4a:	471d                	li	a4,7
    80005e4c:	08f77d63          	bgeu	a4,a5,80005ee6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e50:	100014b7          	lui	s1,0x10001
    80005e54:	47a1                	li	a5,8
    80005e56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e58:	6609                	lui	a2,0x2
    80005e5a:	4581                	li	a1,0
    80005e5c:	0001d517          	auipc	a0,0x1d
    80005e60:	1a450513          	addi	a0,a0,420 # 80023000 <disk>
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	e7c080e7          	jalr	-388(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e6c:	0001d717          	auipc	a4,0x1d
    80005e70:	19470713          	addi	a4,a4,404 # 80023000 <disk>
    80005e74:	00c75793          	srli	a5,a4,0xc
    80005e78:	2781                	sext.w	a5,a5
    80005e7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e7c:	0001f797          	auipc	a5,0x1f
    80005e80:	18478793          	addi	a5,a5,388 # 80025000 <disk+0x2000>
    80005e84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e86:	0001d717          	auipc	a4,0x1d
    80005e8a:	1fa70713          	addi	a4,a4,506 # 80023080 <disk+0x80>
    80005e8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e90:	0001e717          	auipc	a4,0x1e
    80005e94:	17070713          	addi	a4,a4,368 # 80024000 <disk+0x1000>
    80005e98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e9a:	4705                	li	a4,1
    80005e9c:	00e78c23          	sb	a4,24(a5)
    80005ea0:	00e78ca3          	sb	a4,25(a5)
    80005ea4:	00e78d23          	sb	a4,26(a5)
    80005ea8:	00e78da3          	sb	a4,27(a5)
    80005eac:	00e78e23          	sb	a4,28(a5)
    80005eb0:	00e78ea3          	sb	a4,29(a5)
    80005eb4:	00e78f23          	sb	a4,30(a5)
    80005eb8:	00e78fa3          	sb	a4,31(a5)
}
    80005ebc:	60e2                	ld	ra,24(sp)
    80005ebe:	6442                	ld	s0,16(sp)
    80005ec0:	64a2                	ld	s1,8(sp)
    80005ec2:	6105                	addi	sp,sp,32
    80005ec4:	8082                	ret
    panic("could not find virtio disk");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	8fa50513          	addi	a0,a0,-1798 # 800087c0 <syscalls+0x360>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	670080e7          	jalr	1648(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	90a50513          	addi	a0,a0,-1782 # 800087e0 <syscalls+0x380>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	660080e7          	jalr	1632(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ee6:	00003517          	auipc	a0,0x3
    80005eea:	91a50513          	addi	a0,a0,-1766 # 80008800 <syscalls+0x3a0>
    80005eee:	ffffa097          	auipc	ra,0xffffa
    80005ef2:	650080e7          	jalr	1616(ra) # 8000053e <panic>

0000000080005ef6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ef6:	7159                	addi	sp,sp,-112
    80005ef8:	f486                	sd	ra,104(sp)
    80005efa:	f0a2                	sd	s0,96(sp)
    80005efc:	eca6                	sd	s1,88(sp)
    80005efe:	e8ca                	sd	s2,80(sp)
    80005f00:	e4ce                	sd	s3,72(sp)
    80005f02:	e0d2                	sd	s4,64(sp)
    80005f04:	fc56                	sd	s5,56(sp)
    80005f06:	f85a                	sd	s6,48(sp)
    80005f08:	f45e                	sd	s7,40(sp)
    80005f0a:	f062                	sd	s8,32(sp)
    80005f0c:	ec66                	sd	s9,24(sp)
    80005f0e:	e86a                	sd	s10,16(sp)
    80005f10:	1880                	addi	s0,sp,112
    80005f12:	892a                	mv	s2,a0
    80005f14:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f16:	00c52c83          	lw	s9,12(a0)
    80005f1a:	001c9c9b          	slliw	s9,s9,0x1
    80005f1e:	1c82                	slli	s9,s9,0x20
    80005f20:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f24:	0001f517          	auipc	a0,0x1f
    80005f28:	20450513          	addi	a0,a0,516 # 80025128 <disk+0x2128>
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	cb8080e7          	jalr	-840(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f34:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f36:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f38:	0001db97          	auipc	s7,0x1d
    80005f3c:	0c8b8b93          	addi	s7,s7,200 # 80023000 <disk>
    80005f40:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f42:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f44:	8a4e                	mv	s4,s3
    80005f46:	a051                	j	80005fca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f48:	00fb86b3          	add	a3,s7,a5
    80005f4c:	96da                	add	a3,a3,s6
    80005f4e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f52:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f54:	0207c563          	bltz	a5,80005f7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f58:	2485                	addiw	s1,s1,1
    80005f5a:	0711                	addi	a4,a4,4
    80005f5c:	25548063          	beq	s1,s5,8000619c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005f60:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f62:	0001f697          	auipc	a3,0x1f
    80005f66:	0b668693          	addi	a3,a3,182 # 80025018 <disk+0x2018>
    80005f6a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f6c:	0006c583          	lbu	a1,0(a3)
    80005f70:	fde1                	bnez	a1,80005f48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f72:	2785                	addiw	a5,a5,1
    80005f74:	0685                	addi	a3,a3,1
    80005f76:	ff879be3          	bne	a5,s8,80005f6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f7a:	57fd                	li	a5,-1
    80005f7c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f7e:	02905a63          	blez	s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f82:	f9042503          	lw	a0,-112(s0)
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	d90080e7          	jalr	-624(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005f8e:	4785                	li	a5,1
    80005f90:	0297d163          	bge	a5,s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f94:	f9442503          	lw	a0,-108(s0)
    80005f98:	00000097          	auipc	ra,0x0
    80005f9c:	d7e080e7          	jalr	-642(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005fa0:	4789                	li	a5,2
    80005fa2:	0097d863          	bge	a5,s1,80005fb2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fa6:	f9842503          	lw	a0,-104(s0)
    80005faa:	00000097          	auipc	ra,0x0
    80005fae:	d6c080e7          	jalr	-660(ra) # 80005d16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fb2:	0001f597          	auipc	a1,0x1f
    80005fb6:	17658593          	addi	a1,a1,374 # 80025128 <disk+0x2128>
    80005fba:	0001f517          	auipc	a0,0x1f
    80005fbe:	05e50513          	addi	a0,a0,94 # 80025018 <disk+0x2018>
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	0f2080e7          	jalr	242(ra) # 800020b4 <sleep>
  for(int i = 0; i < 3; i++){
    80005fca:	f9040713          	addi	a4,s0,-112
    80005fce:	84ce                	mv	s1,s3
    80005fd0:	bf41                	j	80005f60 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005fd2:	20058713          	addi	a4,a1,512
    80005fd6:	00471693          	slli	a3,a4,0x4
    80005fda:	0001d717          	auipc	a4,0x1d
    80005fde:	02670713          	addi	a4,a4,38 # 80023000 <disk>
    80005fe2:	9736                	add	a4,a4,a3
    80005fe4:	4685                	li	a3,1
    80005fe6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005fea:	20058713          	addi	a4,a1,512
    80005fee:	00471693          	slli	a3,a4,0x4
    80005ff2:	0001d717          	auipc	a4,0x1d
    80005ff6:	00e70713          	addi	a4,a4,14 # 80023000 <disk>
    80005ffa:	9736                	add	a4,a4,a3
    80005ffc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006000:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006004:	7679                	lui	a2,0xffffe
    80006006:	963e                	add	a2,a2,a5
    80006008:	0001f697          	auipc	a3,0x1f
    8000600c:	ff868693          	addi	a3,a3,-8 # 80025000 <disk+0x2000>
    80006010:	6298                	ld	a4,0(a3)
    80006012:	9732                	add	a4,a4,a2
    80006014:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006016:	6298                	ld	a4,0(a3)
    80006018:	9732                	add	a4,a4,a2
    8000601a:	4541                	li	a0,16
    8000601c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000601e:	6298                	ld	a4,0(a3)
    80006020:	9732                	add	a4,a4,a2
    80006022:	4505                	li	a0,1
    80006024:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006028:	f9442703          	lw	a4,-108(s0)
    8000602c:	6288                	ld	a0,0(a3)
    8000602e:	962a                	add	a2,a2,a0
    80006030:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006034:	0712                	slli	a4,a4,0x4
    80006036:	6290                	ld	a2,0(a3)
    80006038:	963a                	add	a2,a2,a4
    8000603a:	05890513          	addi	a0,s2,88
    8000603e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006040:	6294                	ld	a3,0(a3)
    80006042:	96ba                	add	a3,a3,a4
    80006044:	40000613          	li	a2,1024
    80006048:	c690                	sw	a2,8(a3)
  if(write)
    8000604a:	140d0063          	beqz	s10,8000618a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000604e:	0001f697          	auipc	a3,0x1f
    80006052:	fb26b683          	ld	a3,-78(a3) # 80025000 <disk+0x2000>
    80006056:	96ba                	add	a3,a3,a4
    80006058:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000605c:	0001d817          	auipc	a6,0x1d
    80006060:	fa480813          	addi	a6,a6,-92 # 80023000 <disk>
    80006064:	0001f517          	auipc	a0,0x1f
    80006068:	f9c50513          	addi	a0,a0,-100 # 80025000 <disk+0x2000>
    8000606c:	6114                	ld	a3,0(a0)
    8000606e:	96ba                	add	a3,a3,a4
    80006070:	00c6d603          	lhu	a2,12(a3)
    80006074:	00166613          	ori	a2,a2,1
    80006078:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000607c:	f9842683          	lw	a3,-104(s0)
    80006080:	6110                	ld	a2,0(a0)
    80006082:	9732                	add	a4,a4,a2
    80006084:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006088:	20058613          	addi	a2,a1,512
    8000608c:	0612                	slli	a2,a2,0x4
    8000608e:	9642                	add	a2,a2,a6
    80006090:	577d                	li	a4,-1
    80006092:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006096:	00469713          	slli	a4,a3,0x4
    8000609a:	6114                	ld	a3,0(a0)
    8000609c:	96ba                	add	a3,a3,a4
    8000609e:	03078793          	addi	a5,a5,48
    800060a2:	97c2                	add	a5,a5,a6
    800060a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800060a6:	611c                	ld	a5,0(a0)
    800060a8:	97ba                	add	a5,a5,a4
    800060aa:	4685                	li	a3,1
    800060ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060ae:	611c                	ld	a5,0(a0)
    800060b0:	97ba                	add	a5,a5,a4
    800060b2:	4809                	li	a6,2
    800060b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060b8:	611c                	ld	a5,0(a0)
    800060ba:	973e                	add	a4,a4,a5
    800060bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800060c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060c8:	6518                	ld	a4,8(a0)
    800060ca:	00275783          	lhu	a5,2(a4)
    800060ce:	8b9d                	andi	a5,a5,7
    800060d0:	0786                	slli	a5,a5,0x1
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060dc:	6518                	ld	a4,8(a0)
    800060de:	00275783          	lhu	a5,2(a4)
    800060e2:	2785                	addiw	a5,a5,1
    800060e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060ec:	100017b7          	lui	a5,0x10001
    800060f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060f4:	00492703          	lw	a4,4(s2)
    800060f8:	4785                	li	a5,1
    800060fa:	02f71163          	bne	a4,a5,8000611c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800060fe:	0001f997          	auipc	s3,0x1f
    80006102:	02a98993          	addi	s3,s3,42 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006106:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006108:	85ce                	mv	a1,s3
    8000610a:	854a                	mv	a0,s2
    8000610c:	ffffc097          	auipc	ra,0xffffc
    80006110:	fa8080e7          	jalr	-88(ra) # 800020b4 <sleep>
  while(b->disk == 1) {
    80006114:	00492783          	lw	a5,4(s2)
    80006118:	fe9788e3          	beq	a5,s1,80006108 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000611c:	f9042903          	lw	s2,-112(s0)
    80006120:	20090793          	addi	a5,s2,512
    80006124:	00479713          	slli	a4,a5,0x4
    80006128:	0001d797          	auipc	a5,0x1d
    8000612c:	ed878793          	addi	a5,a5,-296 # 80023000 <disk>
    80006130:	97ba                	add	a5,a5,a4
    80006132:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006136:	0001f997          	auipc	s3,0x1f
    8000613a:	eca98993          	addi	s3,s3,-310 # 80025000 <disk+0x2000>
    8000613e:	00491713          	slli	a4,s2,0x4
    80006142:	0009b783          	ld	a5,0(s3)
    80006146:	97ba                	add	a5,a5,a4
    80006148:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000614c:	854a                	mv	a0,s2
    8000614e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006152:	00000097          	auipc	ra,0x0
    80006156:	bc4080e7          	jalr	-1084(ra) # 80005d16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000615a:	8885                	andi	s1,s1,1
    8000615c:	f0ed                	bnez	s1,8000613e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000615e:	0001f517          	auipc	a0,0x1f
    80006162:	fca50513          	addi	a0,a0,-54 # 80025128 <disk+0x2128>
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
}
    8000616e:	70a6                	ld	ra,104(sp)
    80006170:	7406                	ld	s0,96(sp)
    80006172:	64e6                	ld	s1,88(sp)
    80006174:	6946                	ld	s2,80(sp)
    80006176:	69a6                	ld	s3,72(sp)
    80006178:	6a06                	ld	s4,64(sp)
    8000617a:	7ae2                	ld	s5,56(sp)
    8000617c:	7b42                	ld	s6,48(sp)
    8000617e:	7ba2                	ld	s7,40(sp)
    80006180:	7c02                	ld	s8,32(sp)
    80006182:	6ce2                	ld	s9,24(sp)
    80006184:	6d42                	ld	s10,16(sp)
    80006186:	6165                	addi	sp,sp,112
    80006188:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000618a:	0001f697          	auipc	a3,0x1f
    8000618e:	e766b683          	ld	a3,-394(a3) # 80025000 <disk+0x2000>
    80006192:	96ba                	add	a3,a3,a4
    80006194:	4609                	li	a2,2
    80006196:	00c69623          	sh	a2,12(a3)
    8000619a:	b5c9                	j	8000605c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000619c:	f9042583          	lw	a1,-112(s0)
    800061a0:	20058793          	addi	a5,a1,512
    800061a4:	0792                	slli	a5,a5,0x4
    800061a6:	0001d517          	auipc	a0,0x1d
    800061aa:	f0250513          	addi	a0,a0,-254 # 800230a8 <disk+0xa8>
    800061ae:	953e                	add	a0,a0,a5
  if(write)
    800061b0:	e20d11e3          	bnez	s10,80005fd2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061b4:	20058713          	addi	a4,a1,512
    800061b8:	00471693          	slli	a3,a4,0x4
    800061bc:	0001d717          	auipc	a4,0x1d
    800061c0:	e4470713          	addi	a4,a4,-444 # 80023000 <disk>
    800061c4:	9736                	add	a4,a4,a3
    800061c6:	0a072423          	sw	zero,168(a4)
    800061ca:	b505                	j	80005fea <virtio_disk_rw+0xf4>

00000000800061cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061cc:	1101                	addi	sp,sp,-32
    800061ce:	ec06                	sd	ra,24(sp)
    800061d0:	e822                	sd	s0,16(sp)
    800061d2:	e426                	sd	s1,8(sp)
    800061d4:	e04a                	sd	s2,0(sp)
    800061d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061d8:	0001f517          	auipc	a0,0x1f
    800061dc:	f5050513          	addi	a0,a0,-176 # 80025128 <disk+0x2128>
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e8:	10001737          	lui	a4,0x10001
    800061ec:	533c                	lw	a5,96(a4)
    800061ee:	8b8d                	andi	a5,a5,3
    800061f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061f6:	0001f797          	auipc	a5,0x1f
    800061fa:	e0a78793          	addi	a5,a5,-502 # 80025000 <disk+0x2000>
    800061fe:	6b94                	ld	a3,16(a5)
    80006200:	0207d703          	lhu	a4,32(a5)
    80006204:	0026d783          	lhu	a5,2(a3)
    80006208:	06f70163          	beq	a4,a5,8000626a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000620c:	0001d917          	auipc	s2,0x1d
    80006210:	df490913          	addi	s2,s2,-524 # 80023000 <disk>
    80006214:	0001f497          	auipc	s1,0x1f
    80006218:	dec48493          	addi	s1,s1,-532 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000621c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006220:	6898                	ld	a4,16(s1)
    80006222:	0204d783          	lhu	a5,32(s1)
    80006226:	8b9d                	andi	a5,a5,7
    80006228:	078e                	slli	a5,a5,0x3
    8000622a:	97ba                	add	a5,a5,a4
    8000622c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000622e:	20078713          	addi	a4,a5,512
    80006232:	0712                	slli	a4,a4,0x4
    80006234:	974a                	add	a4,a4,s2
    80006236:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000623a:	e731                	bnez	a4,80006286 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000623c:	20078793          	addi	a5,a5,512
    80006240:	0792                	slli	a5,a5,0x4
    80006242:	97ca                	add	a5,a5,s2
    80006244:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006246:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000624a:	ffffc097          	auipc	ra,0xffffc
    8000624e:	ff6080e7          	jalr	-10(ra) # 80002240 <wakeup>

    disk.used_idx += 1;
    80006252:	0204d783          	lhu	a5,32(s1)
    80006256:	2785                	addiw	a5,a5,1
    80006258:	17c2                	slli	a5,a5,0x30
    8000625a:	93c1                	srli	a5,a5,0x30
    8000625c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006260:	6898                	ld	a4,16(s1)
    80006262:	00275703          	lhu	a4,2(a4)
    80006266:	faf71be3          	bne	a4,a5,8000621c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000626a:	0001f517          	auipc	a0,0x1f
    8000626e:	ebe50513          	addi	a0,a0,-322 # 80025128 <disk+0x2128>
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	a26080e7          	jalr	-1498(ra) # 80000c98 <release>
}
    8000627a:	60e2                	ld	ra,24(sp)
    8000627c:	6442                	ld	s0,16(sp)
    8000627e:	64a2                	ld	s1,8(sp)
    80006280:	6902                	ld	s2,0(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret
      panic("virtio_disk_intr status");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	59a50513          	addi	a0,a0,1434 # 80008820 <syscalls+0x3c0>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
