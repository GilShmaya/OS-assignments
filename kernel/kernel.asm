
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a0013103          	ld	sp,-1536(sp) # 80008a00 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	2cc78793          	addi	a5,a5,716 # 80006330 <timervec>
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
    80000130:	618080e7          	jalr	1560(ra) # 80002744 <either_copyin>
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
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	c72080e7          	jalr	-910(ra) # 80001e36 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	30a080e7          	jalr	778(ra) # 800024de <sleep>
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
    80000214:	4de080e7          	jalr	1246(ra) # 800026ee <either_copyout>
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
    800002f6:	4a8080e7          	jalr	1192(ra) # 8000279a <procdump>
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
    8000044a:	686080e7          	jalr	1670(ra) # 80002acc <wakeup>
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
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	a2078793          	addi	a5,a5,-1504 # 80021e98 <devsw>
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
    800008a4:	22c080e7          	jalr	556(ra) # 80002acc <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	bb2080e7          	jalr	-1102(ra) # 800024de <sleep>
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
    80000b82:	296080e7          	jalr	662(ra) # 80001e14 <mycpu>
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
    80000bb4:	264080e7          	jalr	612(ra) # 80001e14 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	258080e7          	jalr	600(ra) # 80001e14 <mycpu>
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
    80000bd8:	240080e7          	jalr	576(ra) # 80001e14 <mycpu>
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
    80000c18:	200080e7          	jalr	512(ra) # 80001e14 <mycpu>
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
    80000c44:	1d4080e7          	jalr	468(ra) # 80001e14 <mycpu>
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
    80000e9a:	f6e080e7          	jalr	-146(ra) # 80001e04 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	f52080e7          	jalr	-174(ra) # 80001e04 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	ec4080e7          	jalr	-316(ra) # 80002d98 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	494080e7          	jalr	1172(ra) # 80006370 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	3e6080e7          	jalr	998(ra) # 800022ca <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	dbe080e7          	jalr	-578(ra) # 80001d02 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	e24080e7          	jalr	-476(ra) # 80002d70 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	e44080e7          	jalr	-444(ra) # 80002d98 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3fe080e7          	jalr	1022(ra) # 8000635a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	40c080e7          	jalr	1036(ra) # 80006370 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5ea080e7          	jalr	1514(ra) # 80003556 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c7a080e7          	jalr	-902(ra) # 80003bee <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c24080e7          	jalr	-988(ra) # 80004ba0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	50e080e7          	jalr	1294(ra) # 80006492 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	236080e7          	jalr	566(ra) # 800021c2 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00001097          	auipc	ra,0x1
    80001244:	a2c080e7          	jalr	-1492(ra) # 80001c6c <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <print_list>:
struct _list unused_list = {-1};   // contains all UNUSED process entries.
struct _list sleeping_list = {-1}; // contains all SLEEPING processes.
struct _list zombie_list = {-1};   // contains all ZOMBIE processes.

void
print_list(struct _list lst){
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	0080                	addi	s0,sp,64
  int curr = lst.head;
    80001850:	4104                	lw	s1,0(a0)
  printf("\n[ ");
    80001852:	00007517          	auipc	a0,0x7
    80001856:	98650513          	addi	a0,a0,-1658 # 800081d8 <digits+0x198>
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	d2e080e7          	jalr	-722(ra) # 80000588 <printf>
  while(curr != -1){
    80001862:	57fd                	li	a5,-1
    80001864:	02f48a63          	beq	s1,a5,80001898 <print_list+0x5a>
    printf(" %d,", curr);
    80001868:	00007a97          	auipc	s5,0x7
    8000186c:	978a8a93          	addi	s5,s5,-1672 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_index;
    80001870:	00010a17          	auipc	s4,0x10
    80001874:	fe0a0a13          	addi	s4,s4,-32 # 80011850 <proc>
    80001878:	19000993          	li	s3,400
  while(curr != -1){
    8000187c:	597d                	li	s2,-1
    printf(" %d,", curr);
    8000187e:	85a6                	mv	a1,s1
    80001880:	8556                	mv	a0,s5
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	d06080e7          	jalr	-762(ra) # 80000588 <printf>
    curr = proc[curr].next_index;
    8000188a:	033484b3          	mul	s1,s1,s3
    8000188e:	94d2                	add	s1,s1,s4
    80001890:	1744a483          	lw	s1,372(s1)
  while(curr != -1){
    80001894:	ff2495e3          	bne	s1,s2,8000187e <print_list+0x40>
  }
  printf(" ]\n");
    80001898:	00007517          	auipc	a0,0x7
    8000189c:	95050513          	addi	a0,a0,-1712 # 800081e8 <digits+0x1a8>
    800018a0:	fffff097          	auipc	ra,0xfffff
    800018a4:	ce8080e7          	jalr	-792(ra) # 80000588 <printf>
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6121                	addi	sp,sp,64
    800018b8:	8082                	ret

00000000800018ba <initialize_list>:


void initialize_list(struct _list *lst){
    800018ba:	1101                	addi	sp,sp,-32
    800018bc:	ec06                	sd	ra,24(sp)
    800018be:	e822                	sd	s0,16(sp)
    800018c0:	e426                	sd	s1,8(sp)
    800018c2:	e04a                	sd	s2,0(sp)
    800018c4:	1000                	addi	s0,sp,32
    800018c6:	84aa                	mv	s1,a0
  acquire(&lst->head_lock);
    800018c8:	00850913          	addi	s2,a0,8
    800018cc:	854a                	mv	a0,s2
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	316080e7          	jalr	790(ra) # 80000be4 <acquire>
  lst->head = -1;
    800018d6:	57fd                	li	a5,-1
    800018d8:	c09c                	sw	a5,0(s1)
  acquire(&lst->head_lock);
    800018da:	854a                	mv	a0,s2
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
}
    800018e4:	60e2                	ld	ra,24(sp)
    800018e6:	6442                	ld	s0,16(sp)
    800018e8:	64a2                	ld	s1,8(sp)
    800018ea:	6902                	ld	s2,0(sp)
    800018ec:	6105                	addi	sp,sp,32
    800018ee:	8082                	ret

00000000800018f0 <initialize_lists>:

void initialize_lists(void){
    800018f0:	7179                	addi	sp,sp,-48
    800018f2:	f406                	sd	ra,40(sp)
    800018f4:	f022                	sd	s0,32(sp)
    800018f6:	ec26                	sd	s1,24(sp)
    800018f8:	e84a                	sd	s2,16(sp)
    800018fa:	e44e                	sd	s3,8(sp)
    800018fc:	e052                	sd	s4,0(sp)
    800018fe:	1800                	addi	s0,sp,48
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001900:	00010497          	auipc	s1,0x10
    80001904:	9a048493          	addi	s1,s1,-1632 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1};
    80001908:	5a7d                	li	s4,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000190a:	00007997          	auipc	s3,0x7
    8000190e:	8e698993          	addi	s3,s3,-1818 # 800081f0 <digits+0x1b0>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    80001912:	00010917          	auipc	s2,0x10
    80001916:	f0e90913          	addi	s2,s2,-242 # 80011820 <pid_lock>
    c->runnable_list = (struct _list){-1};
    8000191a:	0804b023          	sd	zero,128(s1)
    8000191e:	0804b423          	sd	zero,136(s1)
    80001922:	0804b823          	sd	zero,144(s1)
    80001926:	0804bc23          	sd	zero,152(s1)
    8000192a:	0944a023          	sw	s4,128(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    8000192e:	85ce                	mv	a1,s3
    80001930:	08848513          	addi	a0,s1,136
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	220080e7          	jalr	544(ra) # 80000b54 <initlock>
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    8000193c:	0b048493          	addi	s1,s1,176
    80001940:	fd249de3          	bne	s1,s2,8000191a <initialize_lists+0x2a>
  }
  initlock(&unused_list.head_lock, "unused_list - head lock");
    80001944:	00007597          	auipc	a1,0x7
    80001948:	8cc58593          	addi	a1,a1,-1844 # 80008210 <digits+0x1d0>
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	01c50513          	addi	a0,a0,28 # 80008968 <unused_list+0x8>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	200080e7          	jalr	512(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    8000195c:	00007597          	auipc	a1,0x7
    80001960:	8cc58593          	addi	a1,a1,-1844 # 80008228 <digits+0x1e8>
    80001964:	00007517          	auipc	a0,0x7
    80001968:	02450513          	addi	a0,a0,36 # 80008988 <sleeping_list+0x8>
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	1e8080e7          	jalr	488(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    80001974:	00007597          	auipc	a1,0x7
    80001978:	8d458593          	addi	a1,a1,-1836 # 80008248 <digits+0x208>
    8000197c:	00007517          	auipc	a0,0x7
    80001980:	02c50513          	addi	a0,a0,44 # 800089a8 <zombie_list+0x8>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	1d0080e7          	jalr	464(ra) # 80000b54 <initlock>
}
    8000198c:	70a2                	ld	ra,40(sp)
    8000198e:	7402                	ld	s0,32(sp)
    80001990:	64e2                	ld	s1,24(sp)
    80001992:	6942                	ld	s2,16(sp)
    80001994:	69a2                	ld	s3,8(sp)
    80001996:	6a02                	ld	s4,0(sp)
    80001998:	6145                	addi	sp,sp,48
    8000199a:	8082                	ret

000000008000199c <initialize_proc>:

void
initialize_proc(struct proc *p){
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
  p->next_index = -1;
    800019a2:	57fd                	li	a5,-1
    800019a4:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    800019a8:	16f52823          	sw	a5,368(a0)
}
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <isEmpty>:

int
isEmpty(struct _list *lst){
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
  return lst->head == -1;
    800019b8:	4108                	lw	a0,0(a0)
    800019ba:	0505                	addi	a0,a0,1
}
    800019bc:	00153513          	seqz	a0,a0
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <get_head>:

int 
get_head(struct _list *lst){
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	e04a                	sd	s2,0(sp)
    800019d0:	1000                	addi	s0,sp,32
    800019d2:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    800019d4:	00850913          	addi	s2,a0,8
    800019d8:	854a                	mv	a0,s2
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  int output = lst->head;
    800019e2:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    800019e4:	854a                	mv	a0,s2
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
  return output;
}
    800019ee:	8526                	mv	a0,s1
    800019f0:	60e2                	ld	ra,24(sp)
    800019f2:	6442                	ld	s0,16(sp)
    800019f4:	64a2                	ld	s1,8(sp)
    800019f6:	6902                	ld	s2,0(sp)
    800019f8:	6105                	addi	sp,sp,32
    800019fa:	8082                	ret

00000000800019fc <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e422                	sd	s0,8(sp)
    80001a00:	0800                	addi	s0,sp,16
  p->prev_index = value; 
    80001a02:	16b52823          	sw	a1,368(a0)
}
    80001a06:	6422                	ld	s0,8(sp)
    80001a08:	0141                	addi	sp,sp,16
    80001a0a:	8082                	ret

0000000080001a0c <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e422                	sd	s0,8(sp)
    80001a10:	0800                	addi	s0,sp,16
  p->next_index = value; 
    80001a12:	16b52a23          	sw	a1,372(a0)
}
    80001a16:	6422                	ld	s0,8(sp)
    80001a18:	0141                	addi	sp,sp,16
    80001a1a:	8082                	ret

0000000080001a1c <insert_proc_to_list>:

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    80001a1c:	7139                	addi	sp,sp,-64
    80001a1e:	fc06                	sd	ra,56(sp)
    80001a20:	f822                	sd	s0,48(sp)
    80001a22:	f426                	sd	s1,40(sp)
    80001a24:	f04a                	sd	s2,32(sp)
    80001a26:	ec4e                	sd	s3,24(sp)
    80001a28:	e852                	sd	s4,16(sp)
    80001a2a:	e456                	sd	s5,8(sp)
    80001a2c:	0080                	addi	s0,sp,64
    80001a2e:	84aa                	mv	s1,a0
    80001a30:	8a2e                	mv	s4,a1
  //printf("before insert: \n");
  //print_list(*lst); // delete

  acquire(&lst->head_lock);
    80001a32:	00850913          	addi	s2,a0,8
    80001a36:	854a                	mv	a0,s2
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	1ac080e7          	jalr	428(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001a40:	4088                	lw	a0,0(s1)
  if(isEmpty(lst)){
    80001a42:	57fd                	li	a5,-1
    80001a44:	00f51b63          	bne	a0,a5,80001a5a <insert_proc_to_list+0x3e>
    lst->head = p->index;
    80001a48:	16ca2783          	lw	a5,364(s4)
    80001a4c:	c09c                	sw	a5,0(s1)
    release(&lst->head_lock);
    80001a4e:	854a                	mv	a0,s2
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	248080e7          	jalr	584(ra) # 80000c98 <release>
    80001a58:	a849                	j	80001aea <insert_proc_to_list+0xce>
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001a5a:	19000793          	li	a5,400
    80001a5e:	02f50533          	mul	a0,a0,a5
    80001a62:	00010797          	auipc	a5,0x10
    80001a66:	dee78793          	addi	a5,a5,-530 # 80011850 <proc>
    80001a6a:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001a6e:	17850513          	addi	a0,a0,376
    80001a72:	953e                	add	a0,a0,a5
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	170080e7          	jalr	368(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
    while(curr->next_index != -1){ // search tail
    80001a86:	1744a503          	lw	a0,372(s1)
    80001a8a:	57fd                	li	a5,-1
    80001a8c:	04f50163          	beq	a0,a5,80001ace <insert_proc_to_list+0xb2>
      acquire(&proc[curr->next_index].node_lock);
    80001a90:	19000993          	li	s3,400
    80001a94:	00010917          	auipc	s2,0x10
    80001a98:	dbc90913          	addi	s2,s2,-580 # 80011850 <proc>
    while(curr->next_index != -1){ // search tail
    80001a9c:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001a9e:	03350533          	mul	a0,a0,s3
    80001aa2:	17850513          	addi	a0,a0,376
    80001aa6:	954a                	add	a0,a0,s2
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	13c080e7          	jalr	316(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001ab0:	17848513          	addi	a0,s1,376
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	1e4080e7          	jalr	484(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001abc:	1744a483          	lw	s1,372(s1)
    80001ac0:	033484b3          	mul	s1,s1,s3
    80001ac4:	94ca                	add	s1,s1,s2
    while(curr->next_index != -1){ // search tail
    80001ac6:	1744a503          	lw	a0,372(s1)
    80001aca:	fd551ae3          	bne	a0,s5,80001a9e <insert_proc_to_list+0x82>
    }
    set_next_proc(curr, p->index);  // update next proc of the curr tail
    80001ace:	16ca2783          	lw	a5,364(s4)
  p->next_index = value; 
    80001ad2:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(p, curr->index); // update the prev proc of the new proc
    80001ad6:	16c4a783          	lw	a5,364(s1)
  p->prev_index = value; 
    80001ada:	16fa2823          	sw	a5,368(s4)
    release(&curr->node_lock);
    80001ade:	17848513          	addi	a0,s1,376
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	1b6080e7          	jalr	438(ra) # 80000c98 <release>
  }
  //printf("after insert: \n");
  //print_list(*lst); // delete
}
    80001aea:	70e2                	ld	ra,56(sp)
    80001aec:	7442                	ld	s0,48(sp)
    80001aee:	74a2                	ld	s1,40(sp)
    80001af0:	7902                	ld	s2,32(sp)
    80001af2:	69e2                	ld	s3,24(sp)
    80001af4:	6a42                	ld	s4,16(sp)
    80001af6:	6aa2                	ld	s5,8(sp)
    80001af8:	6121                	addi	sp,sp,64
    80001afa:	8082                	ret

0000000080001afc <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001afc:	7139                	addi	sp,sp,-64
    80001afe:	fc06                	sd	ra,56(sp)
    80001b00:	f822                	sd	s0,48(sp)
    80001b02:	f426                	sd	s1,40(sp)
    80001b04:	f04a                	sd	s2,32(sp)
    80001b06:	ec4e                	sd	s3,24(sp)
    80001b08:	e852                	sd	s4,16(sp)
    80001b0a:	e456                	sd	s5,8(sp)
    80001b0c:	0080                	addi	s0,sp,64
    80001b0e:	84aa                	mv	s1,a0
    80001b10:	892e                	mv	s2,a1
  //printf("before remove: \n");
  //print_list(*lst); // delete

  acquire(&lst->head_lock);
    80001b12:	00850993          	addi	s3,a0,8
    80001b16:	854e                	mv	a0,s3
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	0cc080e7          	jalr	204(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001b20:	409c                	lw	a5,0(s1)
  if(isEmpty(lst)){
    80001b22:	577d                	li	a4,-1
    80001b24:	02e78f63          	beq	a5,a4,80001b62 <remove_proc_to_list+0x66>
    panic("Fails in removing the process from the list: the list is empty\n");
  }

  if(lst->head == p->index){ // the required proc is the head
    80001b28:	16c92703          	lw	a4,364(s2)
    80001b2c:	06f71063          	bne	a4,a5,80001b8c <remove_proc_to_list+0x90>
    lst->head = p->next_index;
    80001b30:	17492783          	lw	a5,372(s2)
    80001b34:	c09c                	sw	a5,0(s1)
    if(p->next_index != -1)
    80001b36:	577d                	li	a4,-1
    80001b38:	02e79d63          	bne	a5,a4,80001b72 <remove_proc_to_list+0x76>
      set_prev_proc(&proc[p->next_index], -1);
    release(&lst->head_lock);
    80001b3c:	854e                	mv	a0,s3
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	15a080e7          	jalr	346(ra) # 80000c98 <release>
  p->next_index = -1;
    80001b46:	57fd                	li	a5,-1
    80001b48:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001b4c:	16f92823          	sw	a5,368(s2)
  }
  initialize_proc(p);

  //printf("after remove: \n");
  //print_list(*lst); // delete
}
    80001b50:	70e2                	ld	ra,56(sp)
    80001b52:	7442                	ld	s0,48(sp)
    80001b54:	74a2                	ld	s1,40(sp)
    80001b56:	7902                	ld	s2,32(sp)
    80001b58:	69e2                	ld	s3,24(sp)
    80001b5a:	6a42                	ld	s4,16(sp)
    80001b5c:	6aa2                	ld	s5,8(sp)
    80001b5e:	6121                	addi	sp,sp,64
    80001b60:	8082                	ret
    panic("Fails in removing the process from the list: the list is empty\n");
    80001b62:	00006517          	auipc	a0,0x6
    80001b66:	6fe50513          	addi	a0,a0,1790 # 80008260 <digits+0x220>
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	9d4080e7          	jalr	-1580(ra) # 8000053e <panic>
  p->prev_index = value; 
    80001b72:	19000713          	li	a4,400
    80001b76:	02e787b3          	mul	a5,a5,a4
    80001b7a:	00010717          	auipc	a4,0x10
    80001b7e:	cd670713          	addi	a4,a4,-810 # 80011850 <proc>
    80001b82:	97ba                	add	a5,a5,a4
    80001b84:	577d                	li	a4,-1
    80001b86:	16e7a823          	sw	a4,368(a5)
}
    80001b8a:	bf4d                	j	80001b3c <remove_proc_to_list+0x40>
    struct proc *curr = &proc[lst->head];
    80001b8c:	19000513          	li	a0,400
    80001b90:	02a787b3          	mul	a5,a5,a0
    80001b94:	00010517          	auipc	a0,0x10
    80001b98:	cbc50513          	addi	a0,a0,-836 # 80011850 <proc>
    80001b9c:	00a784b3          	add	s1,a5,a0
    acquire(&curr->node_lock);
    80001ba0:	17878793          	addi	a5,a5,376
    80001ba4:	953e                	add	a0,a0,a5
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	03e080e7          	jalr	62(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001bae:	854e                	mv	a0,s3
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	0e8080e7          	jalr	232(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001bb8:	1744a503          	lw	a0,372(s1)
    80001bbc:	16c92783          	lw	a5,364(s2)
    80001bc0:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001bc2:	19000a13          	li	s4,400
    80001bc6:	00010997          	auipc	s3,0x10
    80001bca:	c8a98993          	addi	s3,s3,-886 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001bce:	08a78563          	beq	a5,a0,80001c58 <remove_proc_to_list+0x15c>
    80001bd2:	09550563          	beq	a0,s5,80001c5c <remove_proc_to_list+0x160>
      acquire(&proc[curr->next_index].node_lock);
    80001bd6:	03450533          	mul	a0,a0,s4
    80001bda:	17850513          	addi	a0,a0,376
    80001bde:	954e                	add	a0,a0,s3
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001be8:	17848513          	addi	a0,s1,376
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	0ac080e7          	jalr	172(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001bf4:	1744a483          	lw	s1,372(s1)
    80001bf8:	034484b3          	mul	s1,s1,s4
    80001bfc:	94ce                	add	s1,s1,s3
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001bfe:	1744a503          	lw	a0,372(s1)
    80001c02:	16c92783          	lw	a5,364(s2)
    80001c06:	fcf516e3          	bne	a0,a5,80001bd2 <remove_proc_to_list+0xd6>
    if(curr->next_index == -1){
    80001c0a:	577d                	li	a4,-1
    80001c0c:	04e78863          	beq	a5,a4,80001c5c <remove_proc_to_list+0x160>
    acquire(&p->node_lock); // curr is p->prev
    80001c10:	17890993          	addi	s3,s2,376
    80001c14:	854e                	mv	a0,s3
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	fce080e7          	jalr	-50(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001c1e:	17492783          	lw	a5,372(s2)
  p->next_index = value; 
    80001c22:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(&proc[p->next_index], curr->index);
    80001c26:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001c2a:	19000713          	li	a4,400
    80001c2e:	02e787b3          	mul	a5,a5,a4
    80001c32:	00010717          	auipc	a4,0x10
    80001c36:	c1e70713          	addi	a4,a4,-994 # 80011850 <proc>
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	16d7a823          	sw	a3,368(a5)
    release(&curr->node_lock);
    80001c40:	17848513          	addi	a0,s1,376
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	054080e7          	jalr	84(ra) # 80000c98 <release>
    release(&p->node_lock);
    80001c4c:	854e                	mv	a0,s3
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	04a080e7          	jalr	74(ra) # 80000c98 <release>
    80001c56:	bdc5                	j	80001b46 <remove_proc_to_list+0x4a>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c58:	87aa                	mv	a5,a0
    80001c5a:	bf45                	j	80001c0a <remove_proc_to_list+0x10e>
      panic("Fails in removing the process from the list: process is not found in the list\n");
    80001c5c:	00006517          	auipc	a0,0x6
    80001c60:	64450513          	addi	a0,a0,1604 # 800082a0 <digits+0x260>
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>

0000000080001c6c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001c6c:	7139                	addi	sp,sp,-64
    80001c6e:	fc06                	sd	ra,56(sp)
    80001c70:	f822                	sd	s0,48(sp)
    80001c72:	f426                	sd	s1,40(sp)
    80001c74:	f04a                	sd	s2,32(sp)
    80001c76:	ec4e                	sd	s3,24(sp)
    80001c78:	e852                	sd	s4,16(sp)
    80001c7a:	e456                	sd	s5,8(sp)
    80001c7c:	e05a                	sd	s6,0(sp)
    80001c7e:	0080                	addi	s0,sp,64
    80001c80:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c82:	00010497          	auipc	s1,0x10
    80001c86:	bce48493          	addi	s1,s1,-1074 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001c8a:	8b26                	mv	s6,s1
    80001c8c:	00006a97          	auipc	s5,0x6
    80001c90:	374a8a93          	addi	s5,s5,884 # 80008000 <etext>
    80001c94:	04000937          	lui	s2,0x4000
    80001c98:	197d                	addi	s2,s2,-1
    80001c9a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9c:	00016a17          	auipc	s4,0x16
    80001ca0:	fb4a0a13          	addi	s4,s4,-76 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	e50080e7          	jalr	-432(ra) # 80000af4 <kalloc>
    80001cac:	862a                	mv	a2,a0
    if(pa == 0)
    80001cae:	c131                	beqz	a0,80001cf2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001cb0:	416485b3          	sub	a1,s1,s6
    80001cb4:	8591                	srai	a1,a1,0x4
    80001cb6:	000ab783          	ld	a5,0(s5)
    80001cba:	02f585b3          	mul	a1,a1,a5
    80001cbe:	2585                	addiw	a1,a1,1
    80001cc0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cc4:	4719                	li	a4,6
    80001cc6:	6685                	lui	a3,0x1
    80001cc8:	40b905b3          	sub	a1,s2,a1
    80001ccc:	854e                	mv	a0,s3
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	482080e7          	jalr	1154(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd6:	19048493          	addi	s1,s1,400
    80001cda:	fd4495e3          	bne	s1,s4,80001ca4 <proc_mapstacks+0x38>
  }
}
    80001cde:	70e2                	ld	ra,56(sp)
    80001ce0:	7442                	ld	s0,48(sp)
    80001ce2:	74a2                	ld	s1,40(sp)
    80001ce4:	7902                	ld	s2,32(sp)
    80001ce6:	69e2                	ld	s3,24(sp)
    80001ce8:	6a42                	ld	s4,16(sp)
    80001cea:	6aa2                	ld	s5,8(sp)
    80001cec:	6b02                	ld	s6,0(sp)
    80001cee:	6121                	addi	sp,sp,64
    80001cf0:	8082                	ret
      panic("kalloc");
    80001cf2:	00006517          	auipc	a0,0x6
    80001cf6:	5fe50513          	addi	a0,a0,1534 # 800082f0 <digits+0x2b0>
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>

0000000080001d02 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001d02:	711d                	addi	sp,sp,-96
    80001d04:	ec86                	sd	ra,88(sp)
    80001d06:	e8a2                	sd	s0,80(sp)
    80001d08:	e4a6                	sd	s1,72(sp)
    80001d0a:	e0ca                	sd	s2,64(sp)
    80001d0c:	fc4e                	sd	s3,56(sp)
    80001d0e:	f852                	sd	s4,48(sp)
    80001d10:	f456                	sd	s5,40(sp)
    80001d12:	f05a                	sd	s6,32(sp)
    80001d14:	ec5e                	sd	s7,24(sp)
    80001d16:	e862                	sd	s8,16(sp)
    80001d18:	e466                	sd	s9,8(sp)
    80001d1a:	e06a                	sd	s10,0(sp)
    80001d1c:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	bd2080e7          	jalr	-1070(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001d26:	00006597          	auipc	a1,0x6
    80001d2a:	5d258593          	addi	a1,a1,1490 # 800082f8 <digits+0x2b8>
    80001d2e:	00010517          	auipc	a0,0x10
    80001d32:	af250513          	addi	a0,a0,-1294 # 80011820 <pid_lock>
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	e1e080e7          	jalr	-482(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001d3e:	00006597          	auipc	a1,0x6
    80001d42:	5c258593          	addi	a1,a1,1474 # 80008300 <digits+0x2c0>
    80001d46:	00010517          	auipc	a0,0x10
    80001d4a:	af250513          	addi	a0,a0,-1294 # 80011838 <wait_lock>
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	e06080e7          	jalr	-506(ra) # 80000b54 <initlock>

  int i = 0;
    80001d56:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d58:	00010497          	auipc	s1,0x10
    80001d5c:	af848493          	addi	s1,s1,-1288 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001d60:	00006d17          	auipc	s10,0x6
    80001d64:	5b0d0d13          	addi	s10,s10,1456 # 80008310 <digits+0x2d0>
      initlock(&p->lock, "node_lock");
    80001d68:	00006c97          	auipc	s9,0x6
    80001d6c:	5b0c8c93          	addi	s9,s9,1456 # 80008318 <digits+0x2d8>
      p->kstack = KSTACK((int) (p - proc));
    80001d70:	8c26                	mv	s8,s1
    80001d72:	00006b97          	auipc	s7,0x6
    80001d76:	28eb8b93          	addi	s7,s7,654 # 80008000 <etext>
    80001d7a:	04000a37          	lui	s4,0x4000
    80001d7e:	1a7d                	addi	s4,s4,-1
    80001d80:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001d82:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      //printf("insert procinit unused %d\n", p->index); //delete
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001d84:	00007b17          	auipc	s6,0x7
    80001d88:	bdcb0b13          	addi	s6,s6,-1060 # 80008960 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8c:	00016a97          	auipc	s5,0x16
    80001d90:	ec4a8a93          	addi	s5,s5,-316 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    80001d94:	85ea                	mv	a1,s10
    80001d96:	8526                	mv	a0,s1
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	dbc080e7          	jalr	-580(ra) # 80000b54 <initlock>
      initlock(&p->lock, "node_lock");
    80001da0:	85e6                	mv	a1,s9
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	db0080e7          	jalr	-592(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001dac:	418487b3          	sub	a5,s1,s8
    80001db0:	8791                	srai	a5,a5,0x4
    80001db2:	000bb703          	ld	a4,0(s7)
    80001db6:	02e787b3          	mul	a5,a5,a4
    80001dba:	2785                	addiw	a5,a5,1
    80001dbc:	00d7979b          	slliw	a5,a5,0xd
    80001dc0:	40fa07b3          	sub	a5,s4,a5
    80001dc4:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001dc6:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001dca:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001dce:	1734a823          	sw	s3,368(s1)
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001dd2:	85a6                	mv	a1,s1
    80001dd4:	855a                	mv	a0,s6
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	c46080e7          	jalr	-954(ra) # 80001a1c <insert_proc_to_list>
      i++;
    80001dde:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de0:	19048493          	addi	s1,s1,400
    80001de4:	fb5498e3          	bne	s1,s5,80001d94 <procinit+0x92>
  }
}
    80001de8:	60e6                	ld	ra,88(sp)
    80001dea:	6446                	ld	s0,80(sp)
    80001dec:	64a6                	ld	s1,72(sp)
    80001dee:	6906                	ld	s2,64(sp)
    80001df0:	79e2                	ld	s3,56(sp)
    80001df2:	7a42                	ld	s4,48(sp)
    80001df4:	7aa2                	ld	s5,40(sp)
    80001df6:	7b02                	ld	s6,32(sp)
    80001df8:	6be2                	ld	s7,24(sp)
    80001dfa:	6c42                	ld	s8,16(sp)
    80001dfc:	6ca2                	ld	s9,8(sp)
    80001dfe:	6d02                	ld	s10,0(sp)
    80001e00:	6125                	addi	sp,sp,96
    80001e02:	8082                	ret

0000000080001e04 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e04:	1141                	addi	sp,sp,-16
    80001e06:	e422                	sd	s0,8(sp)
    80001e08:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e0a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001e0c:	2501                	sext.w	a0,a0
    80001e0e:	6422                	ld	s0,8(sp)
    80001e10:	0141                	addi	sp,sp,16
    80001e12:	8082                	ret

0000000080001e14 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001e14:	1141                	addi	sp,sp,-16
    80001e16:	e422                	sd	s0,8(sp)
    80001e18:	0800                	addi	s0,sp,16
    80001e1a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001e1c:	2781                	sext.w	a5,a5
    80001e1e:	0b000513          	li	a0,176
    80001e22:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001e26:	0000f517          	auipc	a0,0xf
    80001e2a:	47a50513          	addi	a0,a0,1146 # 800112a0 <cpus>
    80001e2e:	953e                	add	a0,a0,a5
    80001e30:	6422                	ld	s0,8(sp)
    80001e32:	0141                	addi	sp,sp,16
    80001e34:	8082                	ret

0000000080001e36 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001e36:	1101                	addi	sp,sp,-32
    80001e38:	ec06                	sd	ra,24(sp)
    80001e3a:	e822                	sd	s0,16(sp)
    80001e3c:	e426                	sd	s1,8(sp)
    80001e3e:	1000                	addi	s0,sp,32
  push_off();
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	d58080e7          	jalr	-680(ra) # 80000b98 <push_off>
    80001e48:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001e4a:	2781                	sext.w	a5,a5
    80001e4c:	0b000713          	li	a4,176
    80001e50:	02e787b3          	mul	a5,a5,a4
    80001e54:	0000f717          	auipc	a4,0xf
    80001e58:	44c70713          	addi	a4,a4,1100 # 800112a0 <cpus>
    80001e5c:	97ba                	add	a5,a5,a4
    80001e5e:	6384                	ld	s1,0(a5)
  pop_off();
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	dd8080e7          	jalr	-552(ra) # 80000c38 <pop_off>
  return p;
}
    80001e68:	8526                	mv	a0,s1
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6105                	addi	sp,sp,32
    80001e72:	8082                	ret

0000000080001e74 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001e74:	1141                	addi	sp,sp,-16
    80001e76:	e406                	sd	ra,8(sp)
    80001e78:	e022                	sd	s0,0(sp)
    80001e7a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	fba080e7          	jalr	-70(ra) # 80001e36 <myproc>
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e14080e7          	jalr	-492(ra) # 80000c98 <release>

  if (first) {
    80001e8c:	00007797          	auipc	a5,0x7
    80001e90:	ac47a783          	lw	a5,-1340(a5) # 80008950 <first.1776>
    80001e94:	eb89                	bnez	a5,80001ea6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001e96:	00001097          	auipc	ra,0x1
    80001e9a:	f1a080e7          	jalr	-230(ra) # 80002db0 <usertrapret>
}
    80001e9e:	60a2                	ld	ra,8(sp)
    80001ea0:	6402                	ld	s0,0(sp)
    80001ea2:	0141                	addi	sp,sp,16
    80001ea4:	8082                	ret
    first = 0;
    80001ea6:	00007797          	auipc	a5,0x7
    80001eaa:	aa07a523          	sw	zero,-1366(a5) # 80008950 <first.1776>
    fsinit(ROOTDEV);
    80001eae:	4505                	li	a0,1
    80001eb0:	00002097          	auipc	ra,0x2
    80001eb4:	cbe080e7          	jalr	-834(ra) # 80003b6e <fsinit>
    80001eb8:	bff9                	j	80001e96 <forkret+0x22>

0000000080001eba <allocpid>:
allocpid() {
    80001eba:	1101                	addi	sp,sp,-32
    80001ebc:	ec06                	sd	ra,24(sp)
    80001ebe:	e822                	sd	s0,16(sp)
    80001ec0:	e426                	sd	s1,8(sp)
    80001ec2:	e04a                	sd	s2,0(sp)
    80001ec4:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001ec6:	00007917          	auipc	s2,0x7
    80001eca:	a8e90913          	addi	s2,s2,-1394 # 80008954 <nextpid>
    80001ece:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001ed2:	0014861b          	addiw	a2,s1,1
    80001ed6:	85a6                	mv	a1,s1
    80001ed8:	854a                	mv	a0,s2
    80001eda:	00005097          	auipc	ra,0x5
    80001ede:	a9c080e7          	jalr	-1380(ra) # 80006976 <cas>
    80001ee2:	2501                	sext.w	a0,a0
    80001ee4:	f56d                	bnez	a0,80001ece <allocpid+0x14>
}
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	60e2                	ld	ra,24(sp)
    80001eea:	6442                	ld	s0,16(sp)
    80001eec:	64a2                	ld	s1,8(sp)
    80001eee:	6902                	ld	s2,0(sp)
    80001ef0:	6105                	addi	sp,sp,32
    80001ef2:	8082                	ret

0000000080001ef4 <proc_pagetable>:
{
    80001ef4:	1101                	addi	sp,sp,-32
    80001ef6:	ec06                	sd	ra,24(sp)
    80001ef8:	e822                	sd	s0,16(sp)
    80001efa:	e426                	sd	s1,8(sp)
    80001efc:	e04a                	sd	s2,0(sp)
    80001efe:	1000                	addi	s0,sp,32
    80001f00:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	438080e7          	jalr	1080(ra) # 8000133a <uvmcreate>
    80001f0a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001f0c:	c121                	beqz	a0,80001f4c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f0e:	4729                	li	a4,10
    80001f10:	00005697          	auipc	a3,0x5
    80001f14:	0f068693          	addi	a3,a3,240 # 80007000 <_trampoline>
    80001f18:	6605                	lui	a2,0x1
    80001f1a:	040005b7          	lui	a1,0x4000
    80001f1e:	15fd                	addi	a1,a1,-1
    80001f20:	05b2                	slli	a1,a1,0xc
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	18e080e7          	jalr	398(ra) # 800010b0 <mappages>
    80001f2a:	02054863          	bltz	a0,80001f5a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f2e:	4719                	li	a4,6
    80001f30:	05893683          	ld	a3,88(s2)
    80001f34:	6605                	lui	a2,0x1
    80001f36:	020005b7          	lui	a1,0x2000
    80001f3a:	15fd                	addi	a1,a1,-1
    80001f3c:	05b6                	slli	a1,a1,0xd
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	170080e7          	jalr	368(ra) # 800010b0 <mappages>
    80001f48:	02054163          	bltz	a0,80001f6a <proc_pagetable+0x76>
}
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	60e2                	ld	ra,24(sp)
    80001f50:	6442                	ld	s0,16(sp)
    80001f52:	64a2                	ld	s1,8(sp)
    80001f54:	6902                	ld	s2,0(sp)
    80001f56:	6105                	addi	sp,sp,32
    80001f58:	8082                	ret
    uvmfree(pagetable, 0);
    80001f5a:	4581                	li	a1,0
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	5d8080e7          	jalr	1496(ra) # 80001536 <uvmfree>
    return 0;
    80001f66:	4481                	li	s1,0
    80001f68:	b7d5                	j	80001f4c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f6a:	4681                	li	a3,0
    80001f6c:	4605                	li	a2,1
    80001f6e:	040005b7          	lui	a1,0x4000
    80001f72:	15fd                	addi	a1,a1,-1
    80001f74:	05b2                	slli	a1,a1,0xc
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	2fe080e7          	jalr	766(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f80:	4581                	li	a1,0
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	5b2080e7          	jalr	1458(ra) # 80001536 <uvmfree>
    return 0;
    80001f8c:	4481                	li	s1,0
    80001f8e:	bf7d                	j	80001f4c <proc_pagetable+0x58>

0000000080001f90 <proc_freepagetable>:
{
    80001f90:	1101                	addi	sp,sp,-32
    80001f92:	ec06                	sd	ra,24(sp)
    80001f94:	e822                	sd	s0,16(sp)
    80001f96:	e426                	sd	s1,8(sp)
    80001f98:	e04a                	sd	s2,0(sp)
    80001f9a:	1000                	addi	s0,sp,32
    80001f9c:	84aa                	mv	s1,a0
    80001f9e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fa0:	4681                	li	a3,0
    80001fa2:	4605                	li	a2,1
    80001fa4:	040005b7          	lui	a1,0x4000
    80001fa8:	15fd                	addi	a1,a1,-1
    80001faa:	05b2                	slli	a1,a1,0xc
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	2ca080e7          	jalr	714(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fb4:	4681                	li	a3,0
    80001fb6:	4605                	li	a2,1
    80001fb8:	020005b7          	lui	a1,0x2000
    80001fbc:	15fd                	addi	a1,a1,-1
    80001fbe:	05b6                	slli	a1,a1,0xd
    80001fc0:	8526                	mv	a0,s1
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	2b4080e7          	jalr	692(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fca:	85ca                	mv	a1,s2
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	568080e7          	jalr	1384(ra) # 80001536 <uvmfree>
}
    80001fd6:	60e2                	ld	ra,24(sp)
    80001fd8:	6442                	ld	s0,16(sp)
    80001fda:	64a2                	ld	s1,8(sp)
    80001fdc:	6902                	ld	s2,0(sp)
    80001fde:	6105                	addi	sp,sp,32
    80001fe0:	8082                	ret

0000000080001fe2 <freeproc>:
{
    80001fe2:	1101                	addi	sp,sp,-32
    80001fe4:	ec06                	sd	ra,24(sp)
    80001fe6:	e822                	sd	s0,16(sp)
    80001fe8:	e426                	sd	s1,8(sp)
    80001fea:	1000                	addi	s0,sp,32
    80001fec:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001fee:	6d28                	ld	a0,88(a0)
    80001ff0:	c509                	beqz	a0,80001ffa <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	a06080e7          	jalr	-1530(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ffa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ffe:	68a8                	ld	a0,80(s1)
    80002000:	c511                	beqz	a0,8000200c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002002:	64ac                	ld	a1,72(s1)
    80002004:	00000097          	auipc	ra,0x0
    80002008:	f8c080e7          	jalr	-116(ra) # 80001f90 <proc_freepagetable>
  p->pagetable = 0;
    8000200c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002010:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002014:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002018:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    8000201c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002020:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002024:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002028:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000202c:	0004ac23          	sw	zero,24(s1)
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80002030:	85a6                	mv	a1,s1
    80002032:	00007517          	auipc	a0,0x7
    80002036:	96e50513          	addi	a0,a0,-1682 # 800089a0 <zombie_list>
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	ac2080e7          	jalr	-1342(ra) # 80001afc <remove_proc_to_list>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002042:	85a6                	mv	a1,s1
    80002044:	00007517          	auipc	a0,0x7
    80002048:	91c50513          	addi	a0,a0,-1764 # 80008960 <unused_list>
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	9d0080e7          	jalr	-1584(ra) # 80001a1c <insert_proc_to_list>
}
    80002054:	60e2                	ld	ra,24(sp)
    80002056:	6442                	ld	s0,16(sp)
    80002058:	64a2                	ld	s1,8(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret

000000008000205e <allocproc>:
{
    8000205e:	715d                	addi	sp,sp,-80
    80002060:	e486                	sd	ra,72(sp)
    80002062:	e0a2                	sd	s0,64(sp)
    80002064:	fc26                	sd	s1,56(sp)
    80002066:	f84a                	sd	s2,48(sp)
    80002068:	f44e                	sd	s3,40(sp)
    8000206a:	f052                	sd	s4,32(sp)
    8000206c:	ec56                	sd	s5,24(sp)
    8000206e:	e85a                	sd	s6,16(sp)
    80002070:	e45e                	sd	s7,8(sp)
    80002072:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    80002074:	00007717          	auipc	a4,0x7
    80002078:	8ec72703          	lw	a4,-1812(a4) # 80008960 <unused_list>
    8000207c:	57fd                	li	a5,-1
    8000207e:	14f70063          	beq	a4,a5,800021be <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    80002082:	00007a17          	auipc	s4,0x7
    80002086:	8dea0a13          	addi	s4,s4,-1826 # 80008960 <unused_list>
    8000208a:	19000b13          	li	s6,400
    8000208e:	0000fa97          	auipc	s5,0xf
    80002092:	7c2a8a93          	addi	s5,s5,1986 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    80002096:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    80002098:	8552                	mv	a0,s4
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	92c080e7          	jalr	-1748(ra) # 800019c6 <get_head>
    800020a2:	892a                	mv	s2,a0
    800020a4:	036509b3          	mul	s3,a0,s6
    800020a8:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	b36080e7          	jalr	-1226(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    800020b6:	4c9c                	lw	a5,24(s1)
    800020b8:	c79d                	beqz	a5,800020e6 <allocproc+0x88>
      release(&p->lock);
    800020ba:	8526                	mv	a0,s1
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	bdc080e7          	jalr	-1060(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    800020c4:	000a2783          	lw	a5,0(s4)
    800020c8:	fd7798e3          	bne	a5,s7,80002098 <allocproc+0x3a>
  return 0;
    800020cc:	4481                	li	s1,0
}
    800020ce:	8526                	mv	a0,s1
    800020d0:	60a6                	ld	ra,72(sp)
    800020d2:	6406                	ld	s0,64(sp)
    800020d4:	74e2                	ld	s1,56(sp)
    800020d6:	7942                	ld	s2,48(sp)
    800020d8:	79a2                	ld	s3,40(sp)
    800020da:	7a02                	ld	s4,32(sp)
    800020dc:	6ae2                	ld	s5,24(sp)
    800020de:	6b42                	ld	s6,16(sp)
    800020e0:	6ba2                	ld	s7,8(sp)
    800020e2:	6161                	addi	sp,sp,80
    800020e4:	8082                	ret
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800020e6:	85a6                	mv	a1,s1
    800020e8:	00007517          	auipc	a0,0x7
    800020ec:	87850513          	addi	a0,a0,-1928 # 80008960 <unused_list>
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	a0c080e7          	jalr	-1524(ra) # 80001afc <remove_proc_to_list>
  p->pid = allocpid();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	dc2080e7          	jalr	-574(ra) # 80001eba <allocpid>
    80002100:	19000a13          	li	s4,400
    80002104:	034907b3          	mul	a5,s2,s4
    80002108:	0000fa17          	auipc	s4,0xf
    8000210c:	748a0a13          	addi	s4,s4,1864 # 80011850 <proc>
    80002110:	9a3e                	add	s4,s4,a5
    80002112:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80002116:	4785                	li	a5,1
    80002118:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	9d8080e7          	jalr	-1576(ra) # 80000af4 <kalloc>
    80002124:	8aaa                	mv	s5,a0
    80002126:	04aa3c23          	sd	a0,88(s4)
    8000212a:	c135                	beqz	a0,8000218e <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    8000212c:	8526                	mv	a0,s1
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	dc6080e7          	jalr	-570(ra) # 80001ef4 <proc_pagetable>
    80002136:	8a2a                	mv	s4,a0
    80002138:	19000793          	li	a5,400
    8000213c:	02f90733          	mul	a4,s2,a5
    80002140:	0000f797          	auipc	a5,0xf
    80002144:	71078793          	addi	a5,a5,1808 # 80011850 <proc>
    80002148:	97ba                	add	a5,a5,a4
    8000214a:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    8000214c:	cd29                	beqz	a0,800021a6 <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    8000214e:	06098513          	addi	a0,s3,96
    80002152:	0000f997          	auipc	s3,0xf
    80002156:	6fe98993          	addi	s3,s3,1790 # 80011850 <proc>
    8000215a:	07000613          	li	a2,112
    8000215e:	4581                	li	a1,0
    80002160:	954e                	add	a0,a0,s3
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b7e080e7          	jalr	-1154(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000216a:	19000793          	li	a5,400
    8000216e:	02f90933          	mul	s2,s2,a5
    80002172:	994e                	add	s2,s2,s3
    80002174:	00000797          	auipc	a5,0x0
    80002178:	d0078793          	addi	a5,a5,-768 # 80001e74 <forkret>
    8000217c:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002180:	04093783          	ld	a5,64(s2)
    80002184:	6705                	lui	a4,0x1
    80002186:	97ba                	add	a5,a5,a4
    80002188:	06f93423          	sd	a5,104(s2)
  return p;
    8000218c:	b789                	j	800020ce <allocproc+0x70>
    freeproc(p);
    8000218e:	8526                	mv	a0,s1
    80002190:	00000097          	auipc	ra,0x0
    80002194:	e52080e7          	jalr	-430(ra) # 80001fe2 <freeproc>
    release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
    return 0;
    800021a2:	84d6                	mv	s1,s5
    800021a4:	b72d                	j	800020ce <allocproc+0x70>
    freeproc(p);
    800021a6:	8526                	mv	a0,s1
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	e3a080e7          	jalr	-454(ra) # 80001fe2 <freeproc>
    release(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
    return 0;
    800021ba:	84d2                	mv	s1,s4
    800021bc:	bf09                	j	800020ce <allocproc+0x70>
  return 0;
    800021be:	4481                	li	s1,0
    800021c0:	b739                	j	800020ce <allocproc+0x70>

00000000800021c2 <userinit>:
{
    800021c2:	1101                	addi	sp,sp,-32
    800021c4:	ec06                	sd	ra,24(sp)
    800021c6:	e822                	sd	s0,16(sp)
    800021c8:	e426                	sd	s1,8(sp)
    800021ca:	1000                	addi	s0,sp,32
  p = allocproc();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	e92080e7          	jalr	-366(ra) # 8000205e <allocproc>
    800021d4:	84aa                	mv	s1,a0
  initproc = p;
    800021d6:	00007797          	auipc	a5,0x7
    800021da:	e4a7b923          	sd	a0,-430(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800021de:	03400613          	li	a2,52
    800021e2:	00006597          	auipc	a1,0x6
    800021e6:	7de58593          	addi	a1,a1,2014 # 800089c0 <initcode>
    800021ea:	6928                	ld	a0,80(a0)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	17c080e7          	jalr	380(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    800021f4:	6785                	lui	a5,0x1
    800021f6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800021f8:	6cb8                	ld	a4,88(s1)
    800021fa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800021fe:	6cb8                	ld	a4,88(s1)
    80002200:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002202:	4641                	li	a2,16
    80002204:	00006597          	auipc	a1,0x6
    80002208:	12458593          	addi	a1,a1,292 # 80008328 <digits+0x2e8>
    8000220c:	15848513          	addi	a0,s1,344
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	c22080e7          	jalr	-990(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002218:	00006517          	auipc	a0,0x6
    8000221c:	12050513          	addi	a0,a0,288 # 80008338 <digits+0x2f8>
    80002220:	00002097          	auipc	ra,0x2
    80002224:	37c080e7          	jalr	892(ra) # 8000459c <namei>
    80002228:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000222c:	478d                	li	a5,3
    8000222e:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002230:	85a6                	mv	a1,s1
    80002232:	0000f517          	auipc	a0,0xf
    80002236:	0ee50513          	addi	a0,a0,238 # 80011320 <cpus+0x80>
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	7e2080e7          	jalr	2018(ra) # 80001a1c <insert_proc_to_list>
  release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a54080e7          	jalr	-1452(ra) # 80000c98 <release>
}
    8000224c:	60e2                	ld	ra,24(sp)
    8000224e:	6442                	ld	s0,16(sp)
    80002250:	64a2                	ld	s1,8(sp)
    80002252:	6105                	addi	sp,sp,32
    80002254:	8082                	ret

0000000080002256 <growproc>:
{
    80002256:	1101                	addi	sp,sp,-32
    80002258:	ec06                	sd	ra,24(sp)
    8000225a:	e822                	sd	s0,16(sp)
    8000225c:	e426                	sd	s1,8(sp)
    8000225e:	e04a                	sd	s2,0(sp)
    80002260:	1000                	addi	s0,sp,32
    80002262:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002264:	00000097          	auipc	ra,0x0
    80002268:	bd2080e7          	jalr	-1070(ra) # 80001e36 <myproc>
    8000226c:	892a                	mv	s2,a0
  sz = p->sz;
    8000226e:	652c                	ld	a1,72(a0)
    80002270:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002274:	00904f63          	bgtz	s1,80002292 <growproc+0x3c>
  } else if(n < 0){
    80002278:	0204cc63          	bltz	s1,800022b0 <growproc+0x5a>
  p->sz = sz;
    8000227c:	1602                	slli	a2,a2,0x20
    8000227e:	9201                	srli	a2,a2,0x20
    80002280:	04c93423          	sd	a2,72(s2)
  return 0;
    80002284:	4501                	li	a0,0
}
    80002286:	60e2                	ld	ra,24(sp)
    80002288:	6442                	ld	s0,16(sp)
    8000228a:	64a2                	ld	s1,8(sp)
    8000228c:	6902                	ld	s2,0(sp)
    8000228e:	6105                	addi	sp,sp,32
    80002290:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002292:	9e25                	addw	a2,a2,s1
    80002294:	1602                	slli	a2,a2,0x20
    80002296:	9201                	srli	a2,a2,0x20
    80002298:	1582                	slli	a1,a1,0x20
    8000229a:	9181                	srli	a1,a1,0x20
    8000229c:	6928                	ld	a0,80(a0)
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	184080e7          	jalr	388(ra) # 80001422 <uvmalloc>
    800022a6:	0005061b          	sext.w	a2,a0
    800022aa:	fa69                	bnez	a2,8000227c <growproc+0x26>
      return -1;
    800022ac:	557d                	li	a0,-1
    800022ae:	bfe1                	j	80002286 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800022b0:	9e25                	addw	a2,a2,s1
    800022b2:	1602                	slli	a2,a2,0x20
    800022b4:	9201                	srli	a2,a2,0x20
    800022b6:	1582                	slli	a1,a1,0x20
    800022b8:	9181                	srli	a1,a1,0x20
    800022ba:	6928                	ld	a0,80(a0)
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	11e080e7          	jalr	286(ra) # 800013da <uvmdealloc>
    800022c4:	0005061b          	sext.w	a2,a0
    800022c8:	bf55                	j	8000227c <growproc+0x26>

00000000800022ca <scheduler>:
{
    800022ca:	711d                	addi	sp,sp,-96
    800022cc:	ec86                	sd	ra,88(sp)
    800022ce:	e8a2                	sd	s0,80(sp)
    800022d0:	e4a6                	sd	s1,72(sp)
    800022d2:	e0ca                	sd	s2,64(sp)
    800022d4:	fc4e                	sd	s3,56(sp)
    800022d6:	f852                	sd	s4,48(sp)
    800022d8:	f456                	sd	s5,40(sp)
    800022da:	f05a                	sd	s6,32(sp)
    800022dc:	ec5e                	sd	s7,24(sp)
    800022de:	e862                	sd	s8,16(sp)
    800022e0:	e466                	sd	s9,8(sp)
    800022e2:	1080                	addi	s0,sp,96
    800022e4:	8712                	mv	a4,tp
  int id = r_tp();
    800022e6:	2701                	sext.w	a4,a4
  c->proc = 0;
    800022e8:	0000fb97          	auipc	s7,0xf
    800022ec:	fb8b8b93          	addi	s7,s7,-72 # 800112a0 <cpus>
    800022f0:	0b000793          	li	a5,176
    800022f4:	02f707b3          	mul	a5,a4,a5
    800022f8:	00fb86b3          	add	a3,s7,a5
    800022fc:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002300:	08078b13          	addi	s6,a5,128 # 1080 <_entry-0x7fffef80>
    80002304:	9b5e                	add	s6,s6,s7
          swtch(&c->context, &p->context);
    80002306:	07a1                	addi	a5,a5,8
    80002308:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    8000230a:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    8000230c:	0000fa17          	auipc	s4,0xf
    80002310:	544a0a13          	addi	s4,s4,1348 # 80011850 <proc>
    80002314:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002318:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002320:	10079073          	csrw	sstatus,a5
    80002324:	4c0d                	li	s8,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002326:	54fd                	li	s1,-1
    80002328:	0809a783          	lw	a5,128(s3)
    8000232c:	fe9786e3          	beq	a5,s1,80002318 <scheduler+0x4e>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002330:	855a                	mv	a0,s6
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	694080e7          	jalr	1684(ra) # 800019c6 <get_head>
      if(p->state == RUNNABLE) {
    8000233a:	035507b3          	mul	a5,a0,s5
    8000233e:	97d2                	add	a5,a5,s4
    80002340:	4f9c                	lw	a5,24(a5)
    80002342:	ff8793e3          	bne	a5,s8,80002328 <scheduler+0x5e>
    80002346:	03550cb3          	mul	s9,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000234a:	014c84b3          	add	s1,s9,s4
        acquire(&p->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    80002358:	4c9c                	lw	a5,24(s1)
    8000235a:	01878863          	beq	a5,s8,8000236a <scheduler+0xa0>
        release(&p->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
    80002368:	bf7d                	j	80002326 <scheduler+0x5c>
          remove_proc_to_list(&(c->runnable_list), p);
    8000236a:	85a6                	mv	a1,s1
    8000236c:	855a                	mv	a0,s6
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	78e080e7          	jalr	1934(ra) # 80001afc <remove_proc_to_list>
          p->state = RUNNING;
    80002376:	4711                	li	a4,4
    80002378:	cc98                	sw	a4,24(s1)
          c->proc = p;
    8000237a:	0099b023          	sd	s1,0(s3)
          p->last_cpu = c->cpu_id;
    8000237e:	0a09a703          	lw	a4,160(s3)
    80002382:	16e4a423          	sw	a4,360(s1)
          swtch(&c->context, &p->context);
    80002386:	060c8593          	addi	a1,s9,96
    8000238a:	95d2                	add	a1,a1,s4
    8000238c:	855e                	mv	a0,s7
    8000238e:	00001097          	auipc	ra,0x1
    80002392:	978080e7          	jalr	-1672(ra) # 80002d06 <swtch>
          c->proc = 0;
    80002396:	0009b023          	sd	zero,0(s3)
    8000239a:	b7d1                	j	8000235e <scheduler+0x94>

000000008000239c <sched>:
{
    8000239c:	7179                	addi	sp,sp,-48
    8000239e:	f406                	sd	ra,40(sp)
    800023a0:	f022                	sd	s0,32(sp)
    800023a2:	ec26                	sd	s1,24(sp)
    800023a4:	e84a                	sd	s2,16(sp)
    800023a6:	e44e                	sd	s3,8(sp)
    800023a8:	e052                	sd	s4,0(sp)
    800023aa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023ac:	00000097          	auipc	ra,0x0
    800023b0:	a8a080e7          	jalr	-1398(ra) # 80001e36 <myproc>
    800023b4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023b6:	ffffe097          	auipc	ra,0xffffe
    800023ba:	7b4080e7          	jalr	1972(ra) # 80000b6a <holding>
    800023be:	c141                	beqz	a0,8000243e <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023c0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023c2:	2781                	sext.w	a5,a5
    800023c4:	0b000713          	li	a4,176
    800023c8:	02e787b3          	mul	a5,a5,a4
    800023cc:	0000f717          	auipc	a4,0xf
    800023d0:	ed470713          	addi	a4,a4,-300 # 800112a0 <cpus>
    800023d4:	97ba                	add	a5,a5,a4
    800023d6:	5fb8                	lw	a4,120(a5)
    800023d8:	4785                	li	a5,1
    800023da:	06f71a63          	bne	a4,a5,8000244e <sched+0xb2>
  if(p->state == RUNNING)
    800023de:	4c98                	lw	a4,24(s1)
    800023e0:	4791                	li	a5,4
    800023e2:	06f70e63          	beq	a4,a5,8000245e <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023e6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023ea:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023ec:	e3c9                	bnez	a5,8000246e <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ee:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023f0:	0000f917          	auipc	s2,0xf
    800023f4:	eb090913          	addi	s2,s2,-336 # 800112a0 <cpus>
    800023f8:	2781                	sext.w	a5,a5
    800023fa:	0b000993          	li	s3,176
    800023fe:	033787b3          	mul	a5,a5,s3
    80002402:	97ca                	add	a5,a5,s2
    80002404:	07c7aa03          	lw	s4,124(a5)
    80002408:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000240a:	2581                	sext.w	a1,a1
    8000240c:	033585b3          	mul	a1,a1,s3
    80002410:	05a1                	addi	a1,a1,8
    80002412:	95ca                	add	a1,a1,s2
    80002414:	06048513          	addi	a0,s1,96
    80002418:	00001097          	auipc	ra,0x1
    8000241c:	8ee080e7          	jalr	-1810(ra) # 80002d06 <swtch>
    80002420:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002422:	2781                	sext.w	a5,a5
    80002424:	033787b3          	mul	a5,a5,s3
    80002428:	993e                	add	s2,s2,a5
    8000242a:	07492e23          	sw	s4,124(s2)
}
    8000242e:	70a2                	ld	ra,40(sp)
    80002430:	7402                	ld	s0,32(sp)
    80002432:	64e2                	ld	s1,24(sp)
    80002434:	6942                	ld	s2,16(sp)
    80002436:	69a2                	ld	s3,8(sp)
    80002438:	6a02                	ld	s4,0(sp)
    8000243a:	6145                	addi	sp,sp,48
    8000243c:	8082                	ret
    panic("sched p->lock");
    8000243e:	00006517          	auipc	a0,0x6
    80002442:	f0250513          	addi	a0,a0,-254 # 80008340 <digits+0x300>
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	0f8080e7          	jalr	248(ra) # 8000053e <panic>
    panic("sched locks");
    8000244e:	00006517          	auipc	a0,0x6
    80002452:	f0250513          	addi	a0,a0,-254 # 80008350 <digits+0x310>
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	0e8080e7          	jalr	232(ra) # 8000053e <panic>
    panic("sched running");
    8000245e:	00006517          	auipc	a0,0x6
    80002462:	f0250513          	addi	a0,a0,-254 # 80008360 <digits+0x320>
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	0d8080e7          	jalr	216(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000246e:	00006517          	auipc	a0,0x6
    80002472:	f0250513          	addi	a0,a0,-254 # 80008370 <digits+0x330>
    80002476:	ffffe097          	auipc	ra,0xffffe
    8000247a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>

000000008000247e <yield>:
{
    8000247e:	1101                	addi	sp,sp,-32
    80002480:	ec06                	sd	ra,24(sp)
    80002482:	e822                	sd	s0,16(sp)
    80002484:	e426                	sd	s1,8(sp)
    80002486:	e04a                	sd	s2,0(sp)
    80002488:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	9ac080e7          	jalr	-1620(ra) # 80001e36 <myproc>
    80002492:	84aa                	mv	s1,a0
    80002494:	8912                	mv	s2,tp
  acquire(&p->lock);
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	74e080e7          	jalr	1870(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000249e:	478d                	li	a5,3
    800024a0:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    800024a2:	2901                	sext.w	s2,s2
    800024a4:	0b000513          	li	a0,176
    800024a8:	02a90933          	mul	s2,s2,a0
    800024ac:	85a6                	mv	a1,s1
    800024ae:	0000f517          	auipc	a0,0xf
    800024b2:	e7250513          	addi	a0,a0,-398 # 80011320 <cpus+0x80>
    800024b6:	954a                	add	a0,a0,s2
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	564080e7          	jalr	1380(ra) # 80001a1c <insert_proc_to_list>
  sched();
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	edc080e7          	jalr	-292(ra) # 8000239c <sched>
  release(&p->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7ce080e7          	jalr	1998(ra) # 80000c98 <release>
}
    800024d2:	60e2                	ld	ra,24(sp)
    800024d4:	6442                	ld	s0,16(sp)
    800024d6:	64a2                	ld	s1,8(sp)
    800024d8:	6902                	ld	s2,0(sp)
    800024da:	6105                	addi	sp,sp,32
    800024dc:	8082                	ret

00000000800024de <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024de:	7179                	addi	sp,sp,-48
    800024e0:	f406                	sd	ra,40(sp)
    800024e2:	f022                	sd	s0,32(sp)
    800024e4:	ec26                	sd	s1,24(sp)
    800024e6:	e84a                	sd	s2,16(sp)
    800024e8:	e44e                	sd	s3,8(sp)
    800024ea:	1800                	addi	s0,sp,48
    800024ec:	89aa                	mv	s3,a0
    800024ee:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	946080e7          	jalr	-1722(ra) # 80001e36 <myproc>
    800024f8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  release(lk);
    80002502:	854a                	mv	a0,s2
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	794080e7          	jalr	1940(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000250c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002510:	4789                	li	a5,2
    80002512:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  insert_proc_to_list(&sleeping_list, p);
    80002514:	85a6                	mv	a1,s1
    80002516:	00006517          	auipc	a0,0x6
    8000251a:	46a50513          	addi	a0,a0,1130 # 80008980 <sleeping_list>
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	4fe080e7          	jalr	1278(ra) # 80001a1c <insert_proc_to_list>

  sched();
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	e76080e7          	jalr	-394(ra) # 8000239c <sched>

  // Tidy up.
  p->chan = 0;
    8000252e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002532:	8526                	mv	a0,s1
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	764080e7          	jalr	1892(ra) # 80000c98 <release>
  acquire(lk);
    8000253c:	854a                	mv	a0,s2
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6a6080e7          	jalr	1702(ra) # 80000be4 <acquire>
}
    80002546:	70a2                	ld	ra,40(sp)
    80002548:	7402                	ld	s0,32(sp)
    8000254a:	64e2                	ld	s1,24(sp)
    8000254c:	6942                	ld	s2,16(sp)
    8000254e:	69a2                	ld	s3,8(sp)
    80002550:	6145                	addi	sp,sp,48
    80002552:	8082                	ret

0000000080002554 <wait>:
{
    80002554:	715d                	addi	sp,sp,-80
    80002556:	e486                	sd	ra,72(sp)
    80002558:	e0a2                	sd	s0,64(sp)
    8000255a:	fc26                	sd	s1,56(sp)
    8000255c:	f84a                	sd	s2,48(sp)
    8000255e:	f44e                	sd	s3,40(sp)
    80002560:	f052                	sd	s4,32(sp)
    80002562:	ec56                	sd	s5,24(sp)
    80002564:	e85a                	sd	s6,16(sp)
    80002566:	e45e                	sd	s7,8(sp)
    80002568:	e062                	sd	s8,0(sp)
    8000256a:	0880                	addi	s0,sp,80
    8000256c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	8c8080e7          	jalr	-1848(ra) # 80001e36 <myproc>
    80002576:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002578:	0000f517          	auipc	a0,0xf
    8000257c:	2c050513          	addi	a0,a0,704 # 80011838 <wait_lock>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	664080e7          	jalr	1636(ra) # 80000be4 <acquire>
    havekids = 0;
    80002588:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000258a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000258c:	00015997          	auipc	s3,0x15
    80002590:	6c498993          	addi	s3,s3,1732 # 80017c50 <tickslock>
        havekids = 1;
    80002594:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002596:	0000fc17          	auipc	s8,0xf
    8000259a:	2a2c0c13          	addi	s8,s8,674 # 80011838 <wait_lock>
    havekids = 0;
    8000259e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025a0:	0000f497          	auipc	s1,0xf
    800025a4:	2b048493          	addi	s1,s1,688 # 80011850 <proc>
    800025a8:	a0bd                	j	80002616 <wait+0xc2>
          pid = np->pid;
    800025aa:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025ae:	000b0e63          	beqz	s6,800025ca <wait+0x76>
    800025b2:	4691                	li	a3,4
    800025b4:	02c48613          	addi	a2,s1,44
    800025b8:	85da                	mv	a1,s6
    800025ba:	05093503          	ld	a0,80(s2)
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	0b4080e7          	jalr	180(ra) # 80001672 <copyout>
    800025c6:	02054563          	bltz	a0,800025f0 <wait+0x9c>
          freeproc(np);
    800025ca:	8526                	mv	a0,s1
    800025cc:	00000097          	auipc	ra,0x0
    800025d0:	a16080e7          	jalr	-1514(ra) # 80001fe2 <freeproc>
          release(&np->lock);
    800025d4:	8526                	mv	a0,s1
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
          release(&wait_lock);
    800025de:	0000f517          	auipc	a0,0xf
    800025e2:	25a50513          	addi	a0,a0,602 # 80011838 <wait_lock>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
          return pid;
    800025ee:	a09d                	j	80002654 <wait+0x100>
            release(&np->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
            release(&wait_lock);
    800025fa:	0000f517          	auipc	a0,0xf
    800025fe:	23e50513          	addi	a0,a0,574 # 80011838 <wait_lock>
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	696080e7          	jalr	1686(ra) # 80000c98 <release>
            return -1;
    8000260a:	59fd                	li	s3,-1
    8000260c:	a0a1                	j	80002654 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000260e:	19048493          	addi	s1,s1,400
    80002612:	03348463          	beq	s1,s3,8000263a <wait+0xe6>
      if(np->parent == p){
    80002616:	7c9c                	ld	a5,56(s1)
    80002618:	ff279be3          	bne	a5,s2,8000260e <wait+0xba>
        acquire(&np->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	5c6080e7          	jalr	1478(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002626:	4c9c                	lw	a5,24(s1)
    80002628:	f94781e3          	beq	a5,s4,800025aa <wait+0x56>
        release(&np->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
        havekids = 1;
    80002636:	8756                	mv	a4,s5
    80002638:	bfd9                	j	8000260e <wait+0xba>
    if(!havekids || p->killed){
    8000263a:	c701                	beqz	a4,80002642 <wait+0xee>
    8000263c:	02892783          	lw	a5,40(s2)
    80002640:	c79d                	beqz	a5,8000266e <wait+0x11a>
      release(&wait_lock);
    80002642:	0000f517          	auipc	a0,0xf
    80002646:	1f650513          	addi	a0,a0,502 # 80011838 <wait_lock>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	64e080e7          	jalr	1614(ra) # 80000c98 <release>
      return -1;
    80002652:	59fd                	li	s3,-1
}
    80002654:	854e                	mv	a0,s3
    80002656:	60a6                	ld	ra,72(sp)
    80002658:	6406                	ld	s0,64(sp)
    8000265a:	74e2                	ld	s1,56(sp)
    8000265c:	7942                	ld	s2,48(sp)
    8000265e:	79a2                	ld	s3,40(sp)
    80002660:	7a02                	ld	s4,32(sp)
    80002662:	6ae2                	ld	s5,24(sp)
    80002664:	6b42                	ld	s6,16(sp)
    80002666:	6ba2                	ld	s7,8(sp)
    80002668:	6c02                	ld	s8,0(sp)
    8000266a:	6161                	addi	sp,sp,80
    8000266c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000266e:	85e2                	mv	a1,s8
    80002670:	854a                	mv	a0,s2
    80002672:	00000097          	auipc	ra,0x0
    80002676:	e6c080e7          	jalr	-404(ra) # 800024de <sleep>
    havekids = 0;
    8000267a:	b715                	j	8000259e <wait+0x4a>

000000008000267c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	1800                	addi	s0,sp,48
    8000268a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000268c:	0000f497          	auipc	s1,0xf
    80002690:	1c448493          	addi	s1,s1,452 # 80011850 <proc>
    80002694:	00015997          	auipc	s3,0x15
    80002698:	5bc98993          	addi	s3,s3,1468 # 80017c50 <tickslock>
    acquire(&p->lock);
    8000269c:	8526                	mv	a0,s1
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	546080e7          	jalr	1350(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800026a6:	589c                	lw	a5,48(s1)
    800026a8:	01278d63          	beq	a5,s2,800026c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026ac:	8526                	mv	a0,s1
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b6:	19048493          	addi	s1,s1,400
    800026ba:	ff3491e3          	bne	s1,s3,8000269c <kill+0x20>
  }
  return -1;
    800026be:	557d                	li	a0,-1
    800026c0:	a829                	j	800026da <kill+0x5e>
      p->killed = 1;
    800026c2:	4785                	li	a5,1
    800026c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800026c6:	4c98                	lw	a4,24(s1)
    800026c8:	4789                	li	a5,2
    800026ca:	00f70f63          	beq	a4,a5,800026e8 <kill+0x6c>
      release(&p->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5c8080e7          	jalr	1480(ra) # 80000c98 <release>
      return 0;
    800026d8:	4501                	li	a0,0
}
    800026da:	70a2                	ld	ra,40(sp)
    800026dc:	7402                	ld	s0,32(sp)
    800026de:	64e2                	ld	s1,24(sp)
    800026e0:	6942                	ld	s2,16(sp)
    800026e2:	69a2                	ld	s3,8(sp)
    800026e4:	6145                	addi	sp,sp,48
    800026e6:	8082                	ret
        p->state = RUNNABLE;
    800026e8:	478d                	li	a5,3
    800026ea:	cc9c                	sw	a5,24(s1)
    800026ec:	b7cd                	j	800026ce <kill+0x52>

00000000800026ee <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026ee:	7179                	addi	sp,sp,-48
    800026f0:	f406                	sd	ra,40(sp)
    800026f2:	f022                	sd	s0,32(sp)
    800026f4:	ec26                	sd	s1,24(sp)
    800026f6:	e84a                	sd	s2,16(sp)
    800026f8:	e44e                	sd	s3,8(sp)
    800026fa:	e052                	sd	s4,0(sp)
    800026fc:	1800                	addi	s0,sp,48
    800026fe:	84aa                	mv	s1,a0
    80002700:	892e                	mv	s2,a1
    80002702:	89b2                	mv	s3,a2
    80002704:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	730080e7          	jalr	1840(ra) # 80001e36 <myproc>
  if(user_dst){
    8000270e:	c08d                	beqz	s1,80002730 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002710:	86d2                	mv	a3,s4
    80002712:	864e                	mv	a2,s3
    80002714:	85ca                	mv	a1,s2
    80002716:	6928                	ld	a0,80(a0)
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	f5a080e7          	jalr	-166(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002720:	70a2                	ld	ra,40(sp)
    80002722:	7402                	ld	s0,32(sp)
    80002724:	64e2                	ld	s1,24(sp)
    80002726:	6942                	ld	s2,16(sp)
    80002728:	69a2                	ld	s3,8(sp)
    8000272a:	6a02                	ld	s4,0(sp)
    8000272c:	6145                	addi	sp,sp,48
    8000272e:	8082                	ret
    memmove((char *)dst, src, len);
    80002730:	000a061b          	sext.w	a2,s4
    80002734:	85ce                	mv	a1,s3
    80002736:	854a                	mv	a0,s2
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	608080e7          	jalr	1544(ra) # 80000d40 <memmove>
    return 0;
    80002740:	8526                	mv	a0,s1
    80002742:	bff9                	j	80002720 <either_copyout+0x32>

0000000080002744 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002744:	7179                	addi	sp,sp,-48
    80002746:	f406                	sd	ra,40(sp)
    80002748:	f022                	sd	s0,32(sp)
    8000274a:	ec26                	sd	s1,24(sp)
    8000274c:	e84a                	sd	s2,16(sp)
    8000274e:	e44e                	sd	s3,8(sp)
    80002750:	e052                	sd	s4,0(sp)
    80002752:	1800                	addi	s0,sp,48
    80002754:	892a                	mv	s2,a0
    80002756:	84ae                	mv	s1,a1
    80002758:	89b2                	mv	s3,a2
    8000275a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	6da080e7          	jalr	1754(ra) # 80001e36 <myproc>
  if(user_src){
    80002764:	c08d                	beqz	s1,80002786 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002766:	86d2                	mv	a3,s4
    80002768:	864e                	mv	a2,s3
    8000276a:	85ca                	mv	a1,s2
    8000276c:	6928                	ld	a0,80(a0)
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	f90080e7          	jalr	-112(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002776:	70a2                	ld	ra,40(sp)
    80002778:	7402                	ld	s0,32(sp)
    8000277a:	64e2                	ld	s1,24(sp)
    8000277c:	6942                	ld	s2,16(sp)
    8000277e:	69a2                	ld	s3,8(sp)
    80002780:	6a02                	ld	s4,0(sp)
    80002782:	6145                	addi	sp,sp,48
    80002784:	8082                	ret
    memmove(dst, (char*)src, len);
    80002786:	000a061b          	sext.w	a2,s4
    8000278a:	85ce                	mv	a1,s3
    8000278c:	854a                	mv	a0,s2
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	5b2080e7          	jalr	1458(ra) # 80000d40 <memmove>
    return 0;
    80002796:	8526                	mv	a0,s1
    80002798:	bff9                	j	80002776 <either_copyin+0x32>

000000008000279a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    8000279a:	715d                	addi	sp,sp,-80
    8000279c:	e486                	sd	ra,72(sp)
    8000279e:	e0a2                	sd	s0,64(sp)
    800027a0:	fc26                	sd	s1,56(sp)
    800027a2:	f84a                	sd	s2,48(sp)
    800027a4:	f44e                	sd	s3,40(sp)
    800027a6:	f052                	sd	s4,32(sp)
    800027a8:	ec56                	sd	s5,24(sp)
    800027aa:	e85a                	sd	s6,16(sp)
    800027ac:	e45e                	sd	s7,8(sp)
    800027ae:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027b0:	00006517          	auipc	a0,0x6
    800027b4:	91850513          	addi	a0,a0,-1768 # 800080c8 <digits+0x88>
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	dd0080e7          	jalr	-560(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c0:	0000f497          	auipc	s1,0xf
    800027c4:	1e848493          	addi	s1,s1,488 # 800119a8 <proc+0x158>
    800027c8:	00015917          	auipc	s2,0x15
    800027cc:	5e090913          	addi	s2,s2,1504 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800027d2:	00006997          	auipc	s3,0x6
    800027d6:	bb698993          	addi	s3,s3,-1098 # 80008388 <digits+0x348>
    printf("%d %s %s", p->pid, state, p->name);
    800027da:	00006a97          	auipc	s5,0x6
    800027de:	bb6a8a93          	addi	s5,s5,-1098 # 80008390 <digits+0x350>
    printf("\n");
    800027e2:	00006a17          	auipc	s4,0x6
    800027e6:	8e6a0a13          	addi	s4,s4,-1818 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ea:	00006b97          	auipc	s7,0x6
    800027ee:	bfeb8b93          	addi	s7,s7,-1026 # 800083e8 <states.1815>
    800027f2:	a00d                	j	80002814 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027f4:	ed86a583          	lw	a1,-296(a3)
    800027f8:	8556                	mv	a0,s5
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d8e080e7          	jalr	-626(ra) # 80000588 <printf>
    printf("\n");
    80002802:	8552                	mv	a0,s4
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	d84080e7          	jalr	-636(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000280c:	19048493          	addi	s1,s1,400
    80002810:	03248163          	beq	s1,s2,80002832 <procdump+0x98>
    if(p->state == UNUSED)
    80002814:	86a6                	mv	a3,s1
    80002816:	ec04a783          	lw	a5,-320(s1)
    8000281a:	dbed                	beqz	a5,8000280c <procdump+0x72>
      state = "???"; 
    8000281c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281e:	fcfb6be3          	bltu	s6,a5,800027f4 <procdump+0x5a>
    80002822:	1782                	slli	a5,a5,0x20
    80002824:	9381                	srli	a5,a5,0x20
    80002826:	078e                	slli	a5,a5,0x3
    80002828:	97de                	add	a5,a5,s7
    8000282a:	6390                	ld	a2,0(a5)
    8000282c:	f661                	bnez	a2,800027f4 <procdump+0x5a>
      state = "???"; 
    8000282e:	864e                	mv	a2,s3
    80002830:	b7d1                	j	800027f4 <procdump+0x5a>
  }
}
    80002832:	60a6                	ld	ra,72(sp)
    80002834:	6406                	ld	s0,64(sp)
    80002836:	74e2                	ld	s1,56(sp)
    80002838:	7942                	ld	s2,48(sp)
    8000283a:	79a2                	ld	s3,40(sp)
    8000283c:	7a02                	ld	s4,32(sp)
    8000283e:	6ae2                	ld	s5,24(sp)
    80002840:	6b42                	ld	s6,16(sp)
    80002842:	6ba2                	ld	s7,8(sp)
    80002844:	6161                	addi	sp,sp,80
    80002846:	8082                	ret

0000000080002848 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002848:	1101                	addi	sp,sp,-32
    8000284a:	ec06                	sd	ra,24(sp)
    8000284c:	e822                	sd	s0,16(sp)
    8000284e:	e426                	sd	s1,8(sp)
    80002850:	e04a                	sd	s2,0(sp)
    80002852:	1000                	addi	s0,sp,32
    80002854:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002856:	fffff097          	auipc	ra,0xfffff
    8000285a:	5e0080e7          	jalr	1504(ra) # 80001e36 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    8000285e:	0004871b          	sext.w	a4,s1
    80002862:	479d                	li	a5,7
    80002864:	02e7e963          	bltu	a5,a4,80002896 <set_cpu+0x4e>
    80002868:	892a                	mv	s2,a0
    acquire(&p->lock);
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002872:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002876:	854a                	mv	a0,s2
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	420080e7          	jalr	1056(ra) # 80000c98 <release>

    yield();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	bfe080e7          	jalr	-1026(ra) # 8000247e <yield>

    return cpu_num;
    80002888:	8526                	mv	a0,s1
  }
  return -1;
}
    8000288a:	60e2                	ld	ra,24(sp)
    8000288c:	6442                	ld	s0,16(sp)
    8000288e:	64a2                	ld	s1,8(sp)
    80002890:	6902                	ld	s2,0(sp)
    80002892:	6105                	addi	sp,sp,32
    80002894:	8082                	ret
  return -1;
    80002896:	557d                	li	a0,-1
    80002898:	bfcd                	j	8000288a <set_cpu+0x42>

000000008000289a <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    8000289a:	1141                	addi	sp,sp,-16
    8000289c:	e406                	sd	ra,8(sp)
    8000289e:	e022                	sd	s0,0(sp)
    800028a0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	594080e7          	jalr	1428(ra) # 80001e36 <myproc>
  return p->last_cpu;
}
    800028aa:	16852503          	lw	a0,360(a0)
    800028ae:	60a2                	ld	ra,8(sp)
    800028b0:	6402                	ld	s0,0(sp)
    800028b2:	0141                	addi	sp,sp,16
    800028b4:	8082                	ret

00000000800028b6 <min_cpu>:

int
min_cpu(void){
    800028b6:	1141                	addi	sp,sp,-16
    800028b8:	e422                	sd	s0,8(sp)
    800028ba:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
// should add an if to insure numberOfCpus>0
  min_cpu = cpus;
    800028bc:	0000f617          	auipc	a2,0xf
    800028c0:	9e460613          	addi	a2,a2,-1564 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    800028c4:	0000f797          	auipc	a5,0xf
    800028c8:	a8c78793          	addi	a5,a5,-1396 # 80011350 <cpus+0xb0>
    800028cc:	0000f597          	auipc	a1,0xf
    800028d0:	f5458593          	addi	a1,a1,-172 # 80011820 <pid_lock>
    800028d4:	a029                	j	800028de <min_cpu+0x28>
    800028d6:	0b078793          	addi	a5,a5,176
    800028da:	00b78863          	beq	a5,a1,800028ea <min_cpu+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    800028de:	77d4                	ld	a3,168(a5)
    800028e0:	7658                	ld	a4,168(a2)
    800028e2:	fee6fae3          	bgeu	a3,a4,800028d6 <min_cpu+0x20>
    800028e6:	863e                	mv	a2,a5
    800028e8:	b7fd                	j	800028d6 <min_cpu+0x20>
        min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    800028ea:	0a062503          	lw	a0,160(a2)
    800028ee:	6422                	ld	s0,8(sp)
    800028f0:	0141                	addi	sp,sp,16
    800028f2:	8082                	ret

00000000800028f4 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    800028f4:	1141                	addi	sp,sp,-16
    800028f6:	e422                	sd	s0,8(sp)
    800028f8:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    800028fa:	fff5071b          	addiw	a4,a0,-1
    800028fe:	4799                	li	a5,6
    80002900:	02e7e063          	bltu	a5,a4,80002920 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002904:	0b000793          	li	a5,176
    80002908:	02f50533          	mul	a0,a0,a5
    8000290c:	0000f797          	auipc	a5,0xf
    80002910:	99478793          	addi	a5,a5,-1644 # 800112a0 <cpus>
    80002914:	953e                	add	a0,a0,a5
    80002916:	0a852503          	lw	a0,168(a0)
  return -1;
}
    8000291a:	6422                	ld	s0,8(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret
  return -1;
    80002920:	557d                	li	a0,-1
    80002922:	bfe5                	j	8000291a <cpu_process_count+0x26>

0000000080002924 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002924:	1101                	addi	sp,sp,-32
    80002926:	ec06                	sd	ra,24(sp)
    80002928:	e822                	sd	s0,16(sp)
    8000292a:	e426                	sd	s1,8(sp)
    8000292c:	e04a                	sd	s2,0(sp)
    8000292e:	1000                	addi	s0,sp,32
    80002930:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002932:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    80002936:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002938:	0015861b          	addiw	a2,a1,1
    8000293c:	2581                	sext.w	a1,a1
    8000293e:	854a                	mv	a0,s2
    80002940:	00004097          	auipc	ra,0x4
    80002944:	036080e7          	jalr	54(ra) # 80006976 <cas>
    80002948:	2501                	sext.w	a0,a0
    8000294a:	f575                	bnez	a0,80002936 <increment_cpu_process_count+0x12>
}
    8000294c:	60e2                	ld	ra,24(sp)
    8000294e:	6442                	ld	s0,16(sp)
    80002950:	64a2                	ld	s1,8(sp)
    80002952:	6902                	ld	s2,0(sp)
    80002954:	6105                	addi	sp,sp,32
    80002956:	8082                	ret

0000000080002958 <fork>:
{
    80002958:	7139                	addi	sp,sp,-64
    8000295a:	fc06                	sd	ra,56(sp)
    8000295c:	f822                	sd	s0,48(sp)
    8000295e:	f426                	sd	s1,40(sp)
    80002960:	f04a                	sd	s2,32(sp)
    80002962:	ec4e                	sd	s3,24(sp)
    80002964:	e852                	sd	s4,16(sp)
    80002966:	e456                	sd	s5,8(sp)
    80002968:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	4cc080e7          	jalr	1228(ra) # 80001e36 <myproc>
    80002972:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	6ea080e7          	jalr	1770(ra) # 8000205e <allocproc>
    8000297c:	14050663          	beqz	a0,80002ac8 <fork+0x170>
    80002980:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002982:	04893603          	ld	a2,72(s2)
    80002986:	692c                	ld	a1,80(a0)
    80002988:	05093503          	ld	a0,80(s2)
    8000298c:	fffff097          	auipc	ra,0xfffff
    80002990:	be2080e7          	jalr	-1054(ra) # 8000156e <uvmcopy>
    80002994:	04054663          	bltz	a0,800029e0 <fork+0x88>
  np->sz = p->sz;
    80002998:	04893783          	ld	a5,72(s2)
    8000299c:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    800029a0:	05893683          	ld	a3,88(s2)
    800029a4:	87b6                	mv	a5,a3
    800029a6:	0589b703          	ld	a4,88(s3)
    800029aa:	12068693          	addi	a3,a3,288
    800029ae:	0007b803          	ld	a6,0(a5)
    800029b2:	6788                	ld	a0,8(a5)
    800029b4:	6b8c                	ld	a1,16(a5)
    800029b6:	6f90                	ld	a2,24(a5)
    800029b8:	01073023          	sd	a6,0(a4)
    800029bc:	e708                	sd	a0,8(a4)
    800029be:	eb0c                	sd	a1,16(a4)
    800029c0:	ef10                	sd	a2,24(a4)
    800029c2:	02078793          	addi	a5,a5,32
    800029c6:	02070713          	addi	a4,a4,32
    800029ca:	fed792e3          	bne	a5,a3,800029ae <fork+0x56>
  np->trapframe->a0 = 0;
    800029ce:	0589b783          	ld	a5,88(s3)
    800029d2:	0607b823          	sd	zero,112(a5)
    800029d6:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800029da:	15000a13          	li	s4,336
    800029de:	a03d                	j	80002a0c <fork+0xb4>
    freeproc(np);
    800029e0:	854e                	mv	a0,s3
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	600080e7          	jalr	1536(ra) # 80001fe2 <freeproc>
    release(&np->lock);
    800029ea:	854e                	mv	a0,s3
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	2ac080e7          	jalr	684(ra) # 80000c98 <release>
    return -1;
    800029f4:	5afd                	li	s5,-1
    800029f6:	a87d                	j	80002ab4 <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    800029f8:	00002097          	auipc	ra,0x2
    800029fc:	23a080e7          	jalr	570(ra) # 80004c32 <filedup>
    80002a00:	009987b3          	add	a5,s3,s1
    80002a04:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002a06:	04a1                	addi	s1,s1,8
    80002a08:	01448763          	beq	s1,s4,80002a16 <fork+0xbe>
    if(p->ofile[i])
    80002a0c:	009907b3          	add	a5,s2,s1
    80002a10:	6388                	ld	a0,0(a5)
    80002a12:	f17d                	bnez	a0,800029f8 <fork+0xa0>
    80002a14:	bfcd                	j	80002a06 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002a16:	15093503          	ld	a0,336(s2)
    80002a1a:	00001097          	auipc	ra,0x1
    80002a1e:	38e080e7          	jalr	910(ra) # 80003da8 <idup>
    80002a22:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002a26:	4641                	li	a2,16
    80002a28:	15890593          	addi	a1,s2,344
    80002a2c:	15898513          	addi	a0,s3,344
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	402080e7          	jalr	1026(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002a38:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002a3c:	854e                	mv	a0,s3
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a46:	0000fa17          	auipc	s4,0xf
    80002a4a:	85aa0a13          	addi	s4,s4,-1958 # 800112a0 <cpus>
    80002a4e:	0000f497          	auipc	s1,0xf
    80002a52:	dea48493          	addi	s1,s1,-534 # 80011838 <wait_lock>
    80002a56:	8526                	mv	a0,s1
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	18c080e7          	jalr	396(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a60:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002a64:	8526                	mv	a0,s1
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	232080e7          	jalr	562(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a6e:	854e                	mv	a0,s3
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	174080e7          	jalr	372(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002a78:	478d                	li	a5,3
    80002a7a:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002a7e:	16892483          	lw	s1,360(s2)
    80002a82:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    80002a86:	0b000513          	li	a0,176
    80002a8a:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    80002a8e:	009a0533          	add	a0,s4,s1
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	e92080e7          	jalr	-366(ra) # 80002924 <increment_cpu_process_count>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002a9a:	08048513          	addi	a0,s1,128
    80002a9e:	85ce                	mv	a1,s3
    80002aa0:	9552                	add	a0,a0,s4
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f7a080e7          	jalr	-134(ra) # 80001a1c <insert_proc_to_list>
  release(&np->lock);
    80002aaa:	854e                	mv	a0,s3
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	1ec080e7          	jalr	492(ra) # 80000c98 <release>
}
    80002ab4:	8556                	mv	a0,s5
    80002ab6:	70e2                	ld	ra,56(sp)
    80002ab8:	7442                	ld	s0,48(sp)
    80002aba:	74a2                	ld	s1,40(sp)
    80002abc:	7902                	ld	s2,32(sp)
    80002abe:	69e2                	ld	s3,24(sp)
    80002ac0:	6a42                	ld	s4,16(sp)
    80002ac2:	6aa2                	ld	s5,8(sp)
    80002ac4:	6121                	addi	sp,sp,64
    80002ac6:	8082                	ret
    return -1;
    80002ac8:	5afd                	li	s5,-1
    80002aca:	b7ed                	j	80002ab4 <fork+0x15c>

0000000080002acc <wakeup>:
{
    80002acc:	7159                	addi	sp,sp,-112
    80002ace:	f486                	sd	ra,104(sp)
    80002ad0:	f0a2                	sd	s0,96(sp)
    80002ad2:	eca6                	sd	s1,88(sp)
    80002ad4:	e8ca                	sd	s2,80(sp)
    80002ad6:	e4ce                	sd	s3,72(sp)
    80002ad8:	e0d2                	sd	s4,64(sp)
    80002ada:	fc56                	sd	s5,56(sp)
    80002adc:	f85a                	sd	s6,48(sp)
    80002ade:	f45e                	sd	s7,40(sp)
    80002ae0:	f062                	sd	s8,32(sp)
    80002ae2:	ec66                	sd	s9,24(sp)
    80002ae4:	e86a                	sd	s10,16(sp)
    80002ae6:	e46e                	sd	s11,8(sp)
    80002ae8:	1880                	addi	s0,sp,112
    80002aea:	8c2a                	mv	s8,a0
  int curr = get_head(&sleeping_list);
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	e9450513          	addi	a0,a0,-364 # 80008980 <sleeping_list>
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	ed2080e7          	jalr	-302(ra) # 800019c6 <get_head>
  while(curr != -1) {
    80002afc:	57fd                	li	a5,-1
    80002afe:	08f50e63          	beq	a0,a5,80002b9a <wakeup+0xce>
    80002b02:	892a                	mv	s2,a0
    p = &proc[curr];
    80002b04:	19000a93          	li	s5,400
    80002b08:	0000fa17          	auipc	s4,0xf
    80002b0c:	d48a0a13          	addi	s4,s4,-696 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002b10:	4b89                	li	s7,2
        p->state = RUNNABLE;
    80002b12:	4d8d                	li	s11,3
    80002b14:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002b18:	0000ec97          	auipc	s9,0xe
    80002b1c:	788c8c93          	addi	s9,s9,1928 # 800112a0 <cpus>
  while(curr != -1) {
    80002b20:	5b7d                	li	s6,-1
    80002b22:	a801                	j	80002b32 <wakeup+0x66>
      release(&p->lock);
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	172080e7          	jalr	370(ra) # 80000c98 <release>
  while(curr != -1) {
    80002b2e:	07690663          	beq	s2,s6,80002b9a <wakeup+0xce>
    p = &proc[curr];
    80002b32:	035904b3          	mul	s1,s2,s5
    80002b36:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002b38:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	2fa080e7          	jalr	762(ra) # 80001e36 <myproc>
    80002b44:	fea485e3          	beq	s1,a0,80002b2e <wakeup+0x62>
      acquire(&p->lock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002b52:	4c9c                	lw	a5,24(s1)
    80002b54:	fd7798e3          	bne	a5,s7,80002b24 <wakeup+0x58>
    80002b58:	709c                	ld	a5,32(s1)
    80002b5a:	fd8795e3          	bne	a5,s8,80002b24 <wakeup+0x58>
        remove_proc_to_list(&sleeping_list, p);
    80002b5e:	85a6                	mv	a1,s1
    80002b60:	00006517          	auipc	a0,0x6
    80002b64:	e2050513          	addi	a0,a0,-480 # 80008980 <sleeping_list>
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	f94080e7          	jalr	-108(ra) # 80001afc <remove_proc_to_list>
        p->state = RUNNABLE;
    80002b70:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002b74:	1684a983          	lw	s3,360(s1)
    80002b78:	03a989b3          	mul	s3,s3,s10
        increment_cpu_process_count(c);
    80002b7c:	013c8533          	add	a0,s9,s3
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	da4080e7          	jalr	-604(ra) # 80002924 <increment_cpu_process_count>
        insert_proc_to_list(&(c->runnable_list), p);
    80002b88:	08098513          	addi	a0,s3,128
    80002b8c:	85a6                	mv	a1,s1
    80002b8e:	9566                	add	a0,a0,s9
    80002b90:	fffff097          	auipc	ra,0xfffff
    80002b94:	e8c080e7          	jalr	-372(ra) # 80001a1c <insert_proc_to_list>
    80002b98:	b771                	j	80002b24 <wakeup+0x58>
}
    80002b9a:	70a6                	ld	ra,104(sp)
    80002b9c:	7406                	ld	s0,96(sp)
    80002b9e:	64e6                	ld	s1,88(sp)
    80002ba0:	6946                	ld	s2,80(sp)
    80002ba2:	69a6                	ld	s3,72(sp)
    80002ba4:	6a06                	ld	s4,64(sp)
    80002ba6:	7ae2                	ld	s5,56(sp)
    80002ba8:	7b42                	ld	s6,48(sp)
    80002baa:	7ba2                	ld	s7,40(sp)
    80002bac:	7c02                	ld	s8,32(sp)
    80002bae:	6ce2                	ld	s9,24(sp)
    80002bb0:	6d42                	ld	s10,16(sp)
    80002bb2:	6da2                	ld	s11,8(sp)
    80002bb4:	6165                	addi	sp,sp,112
    80002bb6:	8082                	ret

0000000080002bb8 <reparent>:
{
    80002bb8:	7179                	addi	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	ec26                	sd	s1,24(sp)
    80002bc0:	e84a                	sd	s2,16(sp)
    80002bc2:	e44e                	sd	s3,8(sp)
    80002bc4:	e052                	sd	s4,0(sp)
    80002bc6:	1800                	addi	s0,sp,48
    80002bc8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bca:	0000f497          	auipc	s1,0xf
    80002bce:	c8648493          	addi	s1,s1,-890 # 80011850 <proc>
      pp->parent = initproc;
    80002bd2:	00006a17          	auipc	s4,0x6
    80002bd6:	456a0a13          	addi	s4,s4,1110 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bda:	00015997          	auipc	s3,0x15
    80002bde:	07698993          	addi	s3,s3,118 # 80017c50 <tickslock>
    80002be2:	a029                	j	80002bec <reparent+0x34>
    80002be4:	19048493          	addi	s1,s1,400
    80002be8:	01348d63          	beq	s1,s3,80002c02 <reparent+0x4a>
    if(pp->parent == p){
    80002bec:	7c9c                	ld	a5,56(s1)
    80002bee:	ff279be3          	bne	a5,s2,80002be4 <reparent+0x2c>
      pp->parent = initproc;
    80002bf2:	000a3503          	ld	a0,0(s4)
    80002bf6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	ed4080e7          	jalr	-300(ra) # 80002acc <wakeup>
    80002c00:	b7d5                	j	80002be4 <reparent+0x2c>
}
    80002c02:	70a2                	ld	ra,40(sp)
    80002c04:	7402                	ld	s0,32(sp)
    80002c06:	64e2                	ld	s1,24(sp)
    80002c08:	6942                	ld	s2,16(sp)
    80002c0a:	69a2                	ld	s3,8(sp)
    80002c0c:	6a02                	ld	s4,0(sp)
    80002c0e:	6145                	addi	sp,sp,48
    80002c10:	8082                	ret

0000000080002c12 <exit>:
{
    80002c12:	7179                	addi	sp,sp,-48
    80002c14:	f406                	sd	ra,40(sp)
    80002c16:	f022                	sd	s0,32(sp)
    80002c18:	ec26                	sd	s1,24(sp)
    80002c1a:	e84a                	sd	s2,16(sp)
    80002c1c:	e44e                	sd	s3,8(sp)
    80002c1e:	e052                	sd	s4,0(sp)
    80002c20:	1800                	addi	s0,sp,48
    80002c22:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	212080e7          	jalr	530(ra) # 80001e36 <myproc>
    80002c2c:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c2e:	00006797          	auipc	a5,0x6
    80002c32:	3fa7b783          	ld	a5,1018(a5) # 80009028 <initproc>
    80002c36:	0d050493          	addi	s1,a0,208
    80002c3a:	15050913          	addi	s2,a0,336
    80002c3e:	02a79363          	bne	a5,a0,80002c64 <exit+0x52>
    panic("init exiting");
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	75e50513          	addi	a0,a0,1886 # 800083a0 <digits+0x360>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	8f4080e7          	jalr	-1804(ra) # 8000053e <panic>
      fileclose(f);
    80002c52:	00002097          	auipc	ra,0x2
    80002c56:	032080e7          	jalr	50(ra) # 80004c84 <fileclose>
      p->ofile[fd] = 0;
    80002c5a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c5e:	04a1                	addi	s1,s1,8
    80002c60:	01248563          	beq	s1,s2,80002c6a <exit+0x58>
    if(p->ofile[fd]){
    80002c64:	6088                	ld	a0,0(s1)
    80002c66:	f575                	bnez	a0,80002c52 <exit+0x40>
    80002c68:	bfdd                	j	80002c5e <exit+0x4c>
  begin_op();
    80002c6a:	00002097          	auipc	ra,0x2
    80002c6e:	b4e080e7          	jalr	-1202(ra) # 800047b8 <begin_op>
  iput(p->cwd);
    80002c72:	1509b503          	ld	a0,336(s3)
    80002c76:	00001097          	auipc	ra,0x1
    80002c7a:	32a080e7          	jalr	810(ra) # 80003fa0 <iput>
  end_op();
    80002c7e:	00002097          	auipc	ra,0x2
    80002c82:	bba080e7          	jalr	-1094(ra) # 80004838 <end_op>
  p->cwd = 0;
    80002c86:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002c8a:	0000f497          	auipc	s1,0xf
    80002c8e:	bae48493          	addi	s1,s1,-1106 # 80011838 <wait_lock>
    80002c92:	8526                	mv	a0,s1
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  reparent(p);
    80002c9c:	854e                	mv	a0,s3
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f1a080e7          	jalr	-230(ra) # 80002bb8 <reparent>
  wakeup(p->parent);
    80002ca6:	0389b503          	ld	a0,56(s3)
    80002caa:	00000097          	auipc	ra,0x0
    80002cae:	e22080e7          	jalr	-478(ra) # 80002acc <wakeup>
  acquire(&p->lock);
    80002cb2:	854e                	mv	a0,s3
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	f30080e7          	jalr	-208(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002cbc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002cc0:	4795                	li	a5,5
    80002cc2:	00f9ac23          	sw	a5,24(s3)
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002cc6:	85ce                	mv	a1,s3
    80002cc8:	00006517          	auipc	a0,0x6
    80002ccc:	cd850513          	addi	a0,a0,-808 # 800089a0 <zombie_list>
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	d4c080e7          	jalr	-692(ra) # 80001a1c <insert_proc_to_list>
  release(&wait_lock);
    80002cd8:	8526                	mv	a0,s1
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>
  sched();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	6ba080e7          	jalr	1722(ra) # 8000239c <sched>
  panic("zombie exit");
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	6c650513          	addi	a0,a0,1734 # 800083b0 <digits+0x370>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>

0000000080002cfa <steal_process>:


void
steal_process(struct cpu *curr_c){  /*
    80002cfa:	1141                	addi	sp,sp,-16
    80002cfc:	e422                	sd	s0,8(sp)
    80002cfe:	0800                	addi	s0,sp,16
  }
  p = proc[stolen_process];
  insert_proc_to_list(&c->runnable_list, p);
  p->last_cpu = c->cpu_id;
  increment_cpu_process_count(c); */
    80002d00:	6422                	ld	s0,8(sp)
    80002d02:	0141                	addi	sp,sp,16
    80002d04:	8082                	ret

0000000080002d06 <swtch>:
    80002d06:	00153023          	sd	ra,0(a0)
    80002d0a:	00253423          	sd	sp,8(a0)
    80002d0e:	e900                	sd	s0,16(a0)
    80002d10:	ed04                	sd	s1,24(a0)
    80002d12:	03253023          	sd	s2,32(a0)
    80002d16:	03353423          	sd	s3,40(a0)
    80002d1a:	03453823          	sd	s4,48(a0)
    80002d1e:	03553c23          	sd	s5,56(a0)
    80002d22:	05653023          	sd	s6,64(a0)
    80002d26:	05753423          	sd	s7,72(a0)
    80002d2a:	05853823          	sd	s8,80(a0)
    80002d2e:	05953c23          	sd	s9,88(a0)
    80002d32:	07a53023          	sd	s10,96(a0)
    80002d36:	07b53423          	sd	s11,104(a0)
    80002d3a:	0005b083          	ld	ra,0(a1)
    80002d3e:	0085b103          	ld	sp,8(a1)
    80002d42:	6980                	ld	s0,16(a1)
    80002d44:	6d84                	ld	s1,24(a1)
    80002d46:	0205b903          	ld	s2,32(a1)
    80002d4a:	0285b983          	ld	s3,40(a1)
    80002d4e:	0305ba03          	ld	s4,48(a1)
    80002d52:	0385ba83          	ld	s5,56(a1)
    80002d56:	0405bb03          	ld	s6,64(a1)
    80002d5a:	0485bb83          	ld	s7,72(a1)
    80002d5e:	0505bc03          	ld	s8,80(a1)
    80002d62:	0585bc83          	ld	s9,88(a1)
    80002d66:	0605bd03          	ld	s10,96(a1)
    80002d6a:	0685bd83          	ld	s11,104(a1)
    80002d6e:	8082                	ret

0000000080002d70 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002d70:	1141                	addi	sp,sp,-16
    80002d72:	e406                	sd	ra,8(sp)
    80002d74:	e022                	sd	s0,0(sp)
    80002d76:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d78:	00005597          	auipc	a1,0x5
    80002d7c:	6a058593          	addi	a1,a1,1696 # 80008418 <states.1815+0x30>
    80002d80:	00015517          	auipc	a0,0x15
    80002d84:	ed050513          	addi	a0,a0,-304 # 80017c50 <tickslock>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	dcc080e7          	jalr	-564(ra) # 80000b54 <initlock>
}
    80002d90:	60a2                	ld	ra,8(sp)
    80002d92:	6402                	ld	s0,0(sp)
    80002d94:	0141                	addi	sp,sp,16
    80002d96:	8082                	ret

0000000080002d98 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d98:	1141                	addi	sp,sp,-16
    80002d9a:	e422                	sd	s0,8(sp)
    80002d9c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d9e:	00003797          	auipc	a5,0x3
    80002da2:	50278793          	addi	a5,a5,1282 # 800062a0 <kernelvec>
    80002da6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002daa:	6422                	ld	s0,8(sp)
    80002dac:	0141                	addi	sp,sp,16
    80002dae:	8082                	ret

0000000080002db0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002db0:	1141                	addi	sp,sp,-16
    80002db2:	e406                	sd	ra,8(sp)
    80002db4:	e022                	sd	s0,0(sp)
    80002db6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	07e080e7          	jalr	126(ra) # 80001e36 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002dc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002dca:	00004617          	auipc	a2,0x4
    80002dce:	23660613          	addi	a2,a2,566 # 80007000 <_trampoline>
    80002dd2:	00004697          	auipc	a3,0x4
    80002dd6:	22e68693          	addi	a3,a3,558 # 80007000 <_trampoline>
    80002dda:	8e91                	sub	a3,a3,a2
    80002ddc:	040007b7          	lui	a5,0x4000
    80002de0:	17fd                	addi	a5,a5,-1
    80002de2:	07b2                	slli	a5,a5,0xc
    80002de4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002de6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002dea:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002dec:	180026f3          	csrr	a3,satp
    80002df0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002df2:	6d38                	ld	a4,88(a0)
    80002df4:	6134                	ld	a3,64(a0)
    80002df6:	6585                	lui	a1,0x1
    80002df8:	96ae                	add	a3,a3,a1
    80002dfa:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002dfc:	6d38                	ld	a4,88(a0)
    80002dfe:	00000697          	auipc	a3,0x0
    80002e02:	13868693          	addi	a3,a3,312 # 80002f36 <usertrap>
    80002e06:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e08:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e0a:	8692                	mv	a3,tp
    80002e0c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e12:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e16:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e1a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e1e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e20:	6f18                	ld	a4,24(a4)
    80002e22:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e26:	692c                	ld	a1,80(a0)
    80002e28:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e2a:	00004717          	auipc	a4,0x4
    80002e2e:	26670713          	addi	a4,a4,614 # 80007090 <userret>
    80002e32:	8f11                	sub	a4,a4,a2
    80002e34:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e36:	577d                	li	a4,-1
    80002e38:	177e                	slli	a4,a4,0x3f
    80002e3a:	8dd9                	or	a1,a1,a4
    80002e3c:	02000537          	lui	a0,0x2000
    80002e40:	157d                	addi	a0,a0,-1
    80002e42:	0536                	slli	a0,a0,0xd
    80002e44:	9782                	jalr	a5
}
    80002e46:	60a2                	ld	ra,8(sp)
    80002e48:	6402                	ld	s0,0(sp)
    80002e4a:	0141                	addi	sp,sp,16
    80002e4c:	8082                	ret

0000000080002e4e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e58:	00015497          	auipc	s1,0x15
    80002e5c:	df848493          	addi	s1,s1,-520 # 80017c50 <tickslock>
    80002e60:	8526                	mv	a0,s1
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	d82080e7          	jalr	-638(ra) # 80000be4 <acquire>
  ticks++;
    80002e6a:	00006517          	auipc	a0,0x6
    80002e6e:	1c650513          	addi	a0,a0,454 # 80009030 <ticks>
    80002e72:	411c                	lw	a5,0(a0)
    80002e74:	2785                	addiw	a5,a5,1
    80002e76:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	c54080e7          	jalr	-940(ra) # 80002acc <wakeup>
  release(&tickslock);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e16080e7          	jalr	-490(ra) # 80000c98 <release>
}
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e9e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ea2:	00074d63          	bltz	a4,80002ebc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ea6:	57fd                	li	a5,-1
    80002ea8:	17fe                	slli	a5,a5,0x3f
    80002eaa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002eac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002eae:	06f70363          	beq	a4,a5,80002f14 <devintr+0x80>
  }
}
    80002eb2:	60e2                	ld	ra,24(sp)
    80002eb4:	6442                	ld	s0,16(sp)
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	6105                	addi	sp,sp,32
    80002eba:	8082                	ret
     (scause & 0xff) == 9){
    80002ebc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ec0:	46a5                	li	a3,9
    80002ec2:	fed792e3          	bne	a5,a3,80002ea6 <devintr+0x12>
    int irq = plic_claim();
    80002ec6:	00003097          	auipc	ra,0x3
    80002eca:	4e2080e7          	jalr	1250(ra) # 800063a8 <plic_claim>
    80002ece:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ed0:	47a9                	li	a5,10
    80002ed2:	02f50763          	beq	a0,a5,80002f00 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ed6:	4785                	li	a5,1
    80002ed8:	02f50963          	beq	a0,a5,80002f0a <devintr+0x76>
    return 1;
    80002edc:	4505                	li	a0,1
    } else if(irq){
    80002ede:	d8f1                	beqz	s1,80002eb2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ee0:	85a6                	mv	a1,s1
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	53e50513          	addi	a0,a0,1342 # 80008420 <states.1815+0x38>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	69e080e7          	jalr	1694(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ef2:	8526                	mv	a0,s1
    80002ef4:	00003097          	auipc	ra,0x3
    80002ef8:	4d8080e7          	jalr	1240(ra) # 800063cc <plic_complete>
    return 1;
    80002efc:	4505                	li	a0,1
    80002efe:	bf55                	j	80002eb2 <devintr+0x1e>
      uartintr();
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	aa8080e7          	jalr	-1368(ra) # 800009a8 <uartintr>
    80002f08:	b7ed                	j	80002ef2 <devintr+0x5e>
      virtio_disk_intr();
    80002f0a:	00004097          	auipc	ra,0x4
    80002f0e:	9a2080e7          	jalr	-1630(ra) # 800068ac <virtio_disk_intr>
    80002f12:	b7c5                	j	80002ef2 <devintr+0x5e>
    if(cpuid() == 0){
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	ef0080e7          	jalr	-272(ra) # 80001e04 <cpuid>
    80002f1c:	c901                	beqz	a0,80002f2c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f1e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f24:	14479073          	csrw	sip,a5
    return 2;
    80002f28:	4509                	li	a0,2
    80002f2a:	b761                	j	80002eb2 <devintr+0x1e>
      clockintr();
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	f22080e7          	jalr	-222(ra) # 80002e4e <clockintr>
    80002f34:	b7ed                	j	80002f1e <devintr+0x8a>

0000000080002f36 <usertrap>:
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	e426                	sd	s1,8(sp)
    80002f3e:	e04a                	sd	s2,0(sp)
    80002f40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f42:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f46:	1007f793          	andi	a5,a5,256
    80002f4a:	e3ad                	bnez	a5,80002fac <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f4c:	00003797          	auipc	a5,0x3
    80002f50:	35478793          	addi	a5,a5,852 # 800062a0 <kernelvec>
    80002f54:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	ede080e7          	jalr	-290(ra) # 80001e36 <myproc>
    80002f60:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f62:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f64:	14102773          	csrr	a4,sepc
    80002f68:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f6a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f6e:	47a1                	li	a5,8
    80002f70:	04f71c63          	bne	a4,a5,80002fc8 <usertrap+0x92>
    if(p->killed)
    80002f74:	551c                	lw	a5,40(a0)
    80002f76:	e3b9                	bnez	a5,80002fbc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f78:	6cb8                	ld	a4,88(s1)
    80002f7a:	6f1c                	ld	a5,24(a4)
    80002f7c:	0791                	addi	a5,a5,4
    80002f7e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f88:	10079073          	csrw	sstatus,a5
    syscall();
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	2e0080e7          	jalr	736(ra) # 8000326c <syscall>
  if(p->killed)
    80002f94:	549c                	lw	a5,40(s1)
    80002f96:	ebc1                	bnez	a5,80003026 <usertrap+0xf0>
  usertrapret();
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	e18080e7          	jalr	-488(ra) # 80002db0 <usertrapret>
}
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	64a2                	ld	s1,8(sp)
    80002fa6:	6902                	ld	s2,0(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret
    panic("usertrap: not from user mode");
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	49450513          	addi	a0,a0,1172 # 80008440 <states.1815+0x58>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	58a080e7          	jalr	1418(ra) # 8000053e <panic>
      exit(-1);
    80002fbc:	557d                	li	a0,-1
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	c54080e7          	jalr	-940(ra) # 80002c12 <exit>
    80002fc6:	bf4d                	j	80002f78 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002fc8:	00000097          	auipc	ra,0x0
    80002fcc:	ecc080e7          	jalr	-308(ra) # 80002e94 <devintr>
    80002fd0:	892a                	mv	s2,a0
    80002fd2:	c501                	beqz	a0,80002fda <usertrap+0xa4>
  if(p->killed)
    80002fd4:	549c                	lw	a5,40(s1)
    80002fd6:	c3a1                	beqz	a5,80003016 <usertrap+0xe0>
    80002fd8:	a815                	j	8000300c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fda:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002fde:	5890                	lw	a2,48(s1)
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	48050513          	addi	a0,a0,1152 # 80008460 <states.1815+0x78>
    80002fe8:	ffffd097          	auipc	ra,0xffffd
    80002fec:	5a0080e7          	jalr	1440(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ff0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ff4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	49850513          	addi	a0,a0,1176 # 80008490 <states.1815+0xa8>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	588080e7          	jalr	1416(ra) # 80000588 <printf>
    p->killed = 1;
    80003008:	4785                	li	a5,1
    8000300a:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000300c:	557d                	li	a0,-1
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	c04080e7          	jalr	-1020(ra) # 80002c12 <exit>
  if(which_dev == 2)
    80003016:	4789                	li	a5,2
    80003018:	f8f910e3          	bne	s2,a5,80002f98 <usertrap+0x62>
    yield();
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	462080e7          	jalr	1122(ra) # 8000247e <yield>
    80003024:	bf95                	j	80002f98 <usertrap+0x62>
  int which_dev = 0;
    80003026:	4901                	li	s2,0
    80003028:	b7d5                	j	8000300c <usertrap+0xd6>

000000008000302a <kerneltrap>:
{
    8000302a:	7179                	addi	sp,sp,-48
    8000302c:	f406                	sd	ra,40(sp)
    8000302e:	f022                	sd	s0,32(sp)
    80003030:	ec26                	sd	s1,24(sp)
    80003032:	e84a                	sd	s2,16(sp)
    80003034:	e44e                	sd	s3,8(sp)
    80003036:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003038:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000303c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003040:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003044:	1004f793          	andi	a5,s1,256
    80003048:	cb85                	beqz	a5,80003078 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000304a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000304e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003050:	ef85                	bnez	a5,80003088 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003052:	00000097          	auipc	ra,0x0
    80003056:	e42080e7          	jalr	-446(ra) # 80002e94 <devintr>
    8000305a:	cd1d                	beqz	a0,80003098 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000305c:	4789                	li	a5,2
    8000305e:	06f50a63          	beq	a0,a5,800030d2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003062:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003066:	10049073          	csrw	sstatus,s1
}
    8000306a:	70a2                	ld	ra,40(sp)
    8000306c:	7402                	ld	s0,32(sp)
    8000306e:	64e2                	ld	s1,24(sp)
    80003070:	6942                	ld	s2,16(sp)
    80003072:	69a2                	ld	s3,8(sp)
    80003074:	6145                	addi	sp,sp,48
    80003076:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003078:	00005517          	auipc	a0,0x5
    8000307c:	43850513          	addi	a0,a0,1080 # 800084b0 <states.1815+0xc8>
    80003080:	ffffd097          	auipc	ra,0xffffd
    80003084:	4be080e7          	jalr	1214(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003088:	00005517          	auipc	a0,0x5
    8000308c:	45050513          	addi	a0,a0,1104 # 800084d8 <states.1815+0xf0>
    80003090:	ffffd097          	auipc	ra,0xffffd
    80003094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003098:	85ce                	mv	a1,s3
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	45e50513          	addi	a0,a0,1118 # 800084f8 <states.1815+0x110>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	4e6080e7          	jalr	1254(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030aa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030ae:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030b2:	00005517          	auipc	a0,0x5
    800030b6:	45650513          	addi	a0,a0,1110 # 80008508 <states.1815+0x120>
    800030ba:	ffffd097          	auipc	ra,0xffffd
    800030be:	4ce080e7          	jalr	1230(ra) # 80000588 <printf>
    panic("kerneltrap");
    800030c2:	00005517          	auipc	a0,0x5
    800030c6:	45e50513          	addi	a0,a0,1118 # 80008520 <states.1815+0x138>
    800030ca:	ffffd097          	auipc	ra,0xffffd
    800030ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	d64080e7          	jalr	-668(ra) # 80001e36 <myproc>
    800030da:	d541                	beqz	a0,80003062 <kerneltrap+0x38>
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	d5a080e7          	jalr	-678(ra) # 80001e36 <myproc>
    800030e4:	4d18                	lw	a4,24(a0)
    800030e6:	4791                	li	a5,4
    800030e8:	f6f71de3          	bne	a4,a5,80003062 <kerneltrap+0x38>
    yield();
    800030ec:	fffff097          	auipc	ra,0xfffff
    800030f0:	392080e7          	jalr	914(ra) # 8000247e <yield>
    800030f4:	b7bd                	j	80003062 <kerneltrap+0x38>

00000000800030f6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030f6:	1101                	addi	sp,sp,-32
    800030f8:	ec06                	sd	ra,24(sp)
    800030fa:	e822                	sd	s0,16(sp)
    800030fc:	e426                	sd	s1,8(sp)
    800030fe:	1000                	addi	s0,sp,32
    80003100:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	d34080e7          	jalr	-716(ra) # 80001e36 <myproc>
  switch (n) {
    8000310a:	4795                	li	a5,5
    8000310c:	0497e163          	bltu	a5,s1,8000314e <argraw+0x58>
    80003110:	048a                	slli	s1,s1,0x2
    80003112:	00005717          	auipc	a4,0x5
    80003116:	44670713          	addi	a4,a4,1094 # 80008558 <states.1815+0x170>
    8000311a:	94ba                	add	s1,s1,a4
    8000311c:	409c                	lw	a5,0(s1)
    8000311e:	97ba                	add	a5,a5,a4
    80003120:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003122:	6d3c                	ld	a5,88(a0)
    80003124:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6105                	addi	sp,sp,32
    8000312e:	8082                	ret
    return p->trapframe->a1;
    80003130:	6d3c                	ld	a5,88(a0)
    80003132:	7fa8                	ld	a0,120(a5)
    80003134:	bfcd                	j	80003126 <argraw+0x30>
    return p->trapframe->a2;
    80003136:	6d3c                	ld	a5,88(a0)
    80003138:	63c8                	ld	a0,128(a5)
    8000313a:	b7f5                	j	80003126 <argraw+0x30>
    return p->trapframe->a3;
    8000313c:	6d3c                	ld	a5,88(a0)
    8000313e:	67c8                	ld	a0,136(a5)
    80003140:	b7dd                	j	80003126 <argraw+0x30>
    return p->trapframe->a4;
    80003142:	6d3c                	ld	a5,88(a0)
    80003144:	6bc8                	ld	a0,144(a5)
    80003146:	b7c5                	j	80003126 <argraw+0x30>
    return p->trapframe->a5;
    80003148:	6d3c                	ld	a5,88(a0)
    8000314a:	6fc8                	ld	a0,152(a5)
    8000314c:	bfe9                	j	80003126 <argraw+0x30>
  panic("argraw");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	3e250513          	addi	a0,a0,994 # 80008530 <states.1815+0x148>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3e8080e7          	jalr	1000(ra) # 8000053e <panic>

000000008000315e <fetchaddr>:
{
    8000315e:	1101                	addi	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	e426                	sd	s1,8(sp)
    80003166:	e04a                	sd	s2,0(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
    8000316c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	cc8080e7          	jalr	-824(ra) # 80001e36 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003176:	653c                	ld	a5,72(a0)
    80003178:	02f4f863          	bgeu	s1,a5,800031a8 <fetchaddr+0x4a>
    8000317c:	00848713          	addi	a4,s1,8
    80003180:	02e7e663          	bltu	a5,a4,800031ac <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003184:	46a1                	li	a3,8
    80003186:	8626                	mv	a2,s1
    80003188:	85ca                	mv	a1,s2
    8000318a:	6928                	ld	a0,80(a0)
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	572080e7          	jalr	1394(ra) # 800016fe <copyin>
    80003194:	00a03533          	snez	a0,a0
    80003198:	40a00533          	neg	a0,a0
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret
    return -1;
    800031a8:	557d                	li	a0,-1
    800031aa:	bfcd                	j	8000319c <fetchaddr+0x3e>
    800031ac:	557d                	li	a0,-1
    800031ae:	b7fd                	j	8000319c <fetchaddr+0x3e>

00000000800031b0 <fetchstr>:
{
    800031b0:	7179                	addi	sp,sp,-48
    800031b2:	f406                	sd	ra,40(sp)
    800031b4:	f022                	sd	s0,32(sp)
    800031b6:	ec26                	sd	s1,24(sp)
    800031b8:	e84a                	sd	s2,16(sp)
    800031ba:	e44e                	sd	s3,8(sp)
    800031bc:	1800                	addi	s0,sp,48
    800031be:	892a                	mv	s2,a0
    800031c0:	84ae                	mv	s1,a1
    800031c2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	c72080e7          	jalr	-910(ra) # 80001e36 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800031cc:	86ce                	mv	a3,s3
    800031ce:	864a                	mv	a2,s2
    800031d0:	85a6                	mv	a1,s1
    800031d2:	6928                	ld	a0,80(a0)
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	5b6080e7          	jalr	1462(ra) # 8000178a <copyinstr>
  if(err < 0)
    800031dc:	00054763          	bltz	a0,800031ea <fetchstr+0x3a>
  return strlen(buf);
    800031e0:	8526                	mv	a0,s1
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	c82080e7          	jalr	-894(ra) # 80000e64 <strlen>
}
    800031ea:	70a2                	ld	ra,40(sp)
    800031ec:	7402                	ld	s0,32(sp)
    800031ee:	64e2                	ld	s1,24(sp)
    800031f0:	6942                	ld	s2,16(sp)
    800031f2:	69a2                	ld	s3,8(sp)
    800031f4:	6145                	addi	sp,sp,48
    800031f6:	8082                	ret

00000000800031f8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800031f8:	1101                	addi	sp,sp,-32
    800031fa:	ec06                	sd	ra,24(sp)
    800031fc:	e822                	sd	s0,16(sp)
    800031fe:	e426                	sd	s1,8(sp)
    80003200:	1000                	addi	s0,sp,32
    80003202:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003204:	00000097          	auipc	ra,0x0
    80003208:	ef2080e7          	jalr	-270(ra) # 800030f6 <argraw>
    8000320c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000320e:	4501                	li	a0,0
    80003210:	60e2                	ld	ra,24(sp)
    80003212:	6442                	ld	s0,16(sp)
    80003214:	64a2                	ld	s1,8(sp)
    80003216:	6105                	addi	sp,sp,32
    80003218:	8082                	ret

000000008000321a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	1000                	addi	s0,sp,32
    80003224:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	ed0080e7          	jalr	-304(ra) # 800030f6 <argraw>
    8000322e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003230:	4501                	li	a0,0
    80003232:	60e2                	ld	ra,24(sp)
    80003234:	6442                	ld	s0,16(sp)
    80003236:	64a2                	ld	s1,8(sp)
    80003238:	6105                	addi	sp,sp,32
    8000323a:	8082                	ret

000000008000323c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	e426                	sd	s1,8(sp)
    80003244:	e04a                	sd	s2,0(sp)
    80003246:	1000                	addi	s0,sp,32
    80003248:	84ae                	mv	s1,a1
    8000324a:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	eaa080e7          	jalr	-342(ra) # 800030f6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003254:	864a                	mv	a2,s2
    80003256:	85a6                	mv	a1,s1
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	f58080e7          	jalr	-168(ra) # 800031b0 <fetchstr>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	64a2                	ld	s1,8(sp)
    80003266:	6902                	ld	s2,0(sp)
    80003268:	6105                	addi	sp,sp,32
    8000326a:	8082                	ret

000000008000326c <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    8000326c:	1101                	addi	sp,sp,-32
    8000326e:	ec06                	sd	ra,24(sp)
    80003270:	e822                	sd	s0,16(sp)
    80003272:	e426                	sd	s1,8(sp)
    80003274:	e04a                	sd	s2,0(sp)
    80003276:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	bbe080e7          	jalr	-1090(ra) # 80001e36 <myproc>
    80003280:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003282:	05853903          	ld	s2,88(a0)
    80003286:	0a893783          	ld	a5,168(s2)
    8000328a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000328e:	37fd                	addiw	a5,a5,-1
    80003290:	475d                	li	a4,23
    80003292:	00f76f63          	bltu	a4,a5,800032b0 <syscall+0x44>
    80003296:	00369713          	slli	a4,a3,0x3
    8000329a:	00005797          	auipc	a5,0x5
    8000329e:	2d678793          	addi	a5,a5,726 # 80008570 <syscalls>
    800032a2:	97ba                	add	a5,a5,a4
    800032a4:	639c                	ld	a5,0(a5)
    800032a6:	c789                	beqz	a5,800032b0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032a8:	9782                	jalr	a5
    800032aa:	06a93823          	sd	a0,112(s2)
    800032ae:	a839                	j	800032cc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032b0:	15848613          	addi	a2,s1,344
    800032b4:	588c                	lw	a1,48(s1)
    800032b6:	00005517          	auipc	a0,0x5
    800032ba:	28250513          	addi	a0,a0,642 # 80008538 <states.1815+0x150>
    800032be:	ffffd097          	auipc	ra,0xffffd
    800032c2:	2ca080e7          	jalr	714(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032c6:	6cbc                	ld	a5,88(s1)
    800032c8:	577d                	li	a4,-1
    800032ca:	fbb8                	sd	a4,112(a5)
  }
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6902                	ld	s2,0(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800032e0:	fec40593          	addi	a1,s0,-20
    800032e4:	4501                	li	a0,0
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	f12080e7          	jalr	-238(ra) # 800031f8 <argint>
    return -1;
    800032ee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032f0:	00054963          	bltz	a0,80003302 <sys_exit+0x2a>
  exit(n);
    800032f4:	fec42503          	lw	a0,-20(s0)
    800032f8:	00000097          	auipc	ra,0x0
    800032fc:	91a080e7          	jalr	-1766(ra) # 80002c12 <exit>
  return 0;  // not reached
    80003300:	4781                	li	a5,0
}
    80003302:	853e                	mv	a0,a5
    80003304:	60e2                	ld	ra,24(sp)
    80003306:	6442                	ld	s0,16(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret

000000008000330c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000330c:	1141                	addi	sp,sp,-16
    8000330e:	e406                	sd	ra,8(sp)
    80003310:	e022                	sd	s0,0(sp)
    80003312:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003314:	fffff097          	auipc	ra,0xfffff
    80003318:	b22080e7          	jalr	-1246(ra) # 80001e36 <myproc>
}
    8000331c:	5908                	lw	a0,48(a0)
    8000331e:	60a2                	ld	ra,8(sp)
    80003320:	6402                	ld	s0,0(sp)
    80003322:	0141                	addi	sp,sp,16
    80003324:	8082                	ret

0000000080003326 <sys_fork>:

uint64
sys_fork(void)
{
    80003326:	1141                	addi	sp,sp,-16
    80003328:	e406                	sd	ra,8(sp)
    8000332a:	e022                	sd	s0,0(sp)
    8000332c:	0800                	addi	s0,sp,16
  return fork();
    8000332e:	fffff097          	auipc	ra,0xfffff
    80003332:	62a080e7          	jalr	1578(ra) # 80002958 <fork>
}
    80003336:	60a2                	ld	ra,8(sp)
    80003338:	6402                	ld	s0,0(sp)
    8000333a:	0141                	addi	sp,sp,16
    8000333c:	8082                	ret

000000008000333e <sys_wait>:

uint64
sys_wait(void)
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003346:	fe840593          	addi	a1,s0,-24
    8000334a:	4501                	li	a0,0
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	ece080e7          	jalr	-306(ra) # 8000321a <argaddr>
    80003354:	87aa                	mv	a5,a0
    return -1;
    80003356:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003358:	0007c863          	bltz	a5,80003368 <sys_wait+0x2a>
  return wait(p);
    8000335c:	fe843503          	ld	a0,-24(s0)
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	1f4080e7          	jalr	500(ra) # 80002554 <wait>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	6105                	addi	sp,sp,32
    8000336e:	8082                	ret

0000000080003370 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003370:	7179                	addi	sp,sp,-48
    80003372:	f406                	sd	ra,40(sp)
    80003374:	f022                	sd	s0,32(sp)
    80003376:	ec26                	sd	s1,24(sp)
    80003378:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000337a:	fdc40593          	addi	a1,s0,-36
    8000337e:	4501                	li	a0,0
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e78080e7          	jalr	-392(ra) # 800031f8 <argint>
    80003388:	87aa                	mv	a5,a0
    return -1;
    8000338a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000338c:	0207c063          	bltz	a5,800033ac <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	aa6080e7          	jalr	-1370(ra) # 80001e36 <myproc>
    80003398:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000339a:	fdc42503          	lw	a0,-36(s0)
    8000339e:	fffff097          	auipc	ra,0xfffff
    800033a2:	eb8080e7          	jalr	-328(ra) # 80002256 <growproc>
    800033a6:	00054863          	bltz	a0,800033b6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800033aa:	8526                	mv	a0,s1
}
    800033ac:	70a2                	ld	ra,40(sp)
    800033ae:	7402                	ld	s0,32(sp)
    800033b0:	64e2                	ld	s1,24(sp)
    800033b2:	6145                	addi	sp,sp,48
    800033b4:	8082                	ret
    return -1;
    800033b6:	557d                	li	a0,-1
    800033b8:	bfd5                	j	800033ac <sys_sbrk+0x3c>

00000000800033ba <sys_sleep>:

uint64
sys_sleep(void)
{
    800033ba:	7139                	addi	sp,sp,-64
    800033bc:	fc06                	sd	ra,56(sp)
    800033be:	f822                	sd	s0,48(sp)
    800033c0:	f426                	sd	s1,40(sp)
    800033c2:	f04a                	sd	s2,32(sp)
    800033c4:	ec4e                	sd	s3,24(sp)
    800033c6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800033c8:	fcc40593          	addi	a1,s0,-52
    800033cc:	4501                	li	a0,0
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	e2a080e7          	jalr	-470(ra) # 800031f8 <argint>
    return -1;
    800033d6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033d8:	06054563          	bltz	a0,80003442 <sys_sleep+0x88>
  acquire(&tickslock);
    800033dc:	00015517          	auipc	a0,0x15
    800033e0:	87450513          	addi	a0,a0,-1932 # 80017c50 <tickslock>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	800080e7          	jalr	-2048(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800033ec:	00006917          	auipc	s2,0x6
    800033f0:	c4492903          	lw	s2,-956(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800033f4:	fcc42783          	lw	a5,-52(s0)
    800033f8:	cf85                	beqz	a5,80003430 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033fa:	00015997          	auipc	s3,0x15
    800033fe:	85698993          	addi	s3,s3,-1962 # 80017c50 <tickslock>
    80003402:	00006497          	auipc	s1,0x6
    80003406:	c2e48493          	addi	s1,s1,-978 # 80009030 <ticks>
    if(myproc()->killed){
    8000340a:	fffff097          	auipc	ra,0xfffff
    8000340e:	a2c080e7          	jalr	-1492(ra) # 80001e36 <myproc>
    80003412:	551c                	lw	a5,40(a0)
    80003414:	ef9d                	bnez	a5,80003452 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003416:	85ce                	mv	a1,s3
    80003418:	8526                	mv	a0,s1
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	0c4080e7          	jalr	196(ra) # 800024de <sleep>
  while(ticks - ticks0 < n){
    80003422:	409c                	lw	a5,0(s1)
    80003424:	412787bb          	subw	a5,a5,s2
    80003428:	fcc42703          	lw	a4,-52(s0)
    8000342c:	fce7efe3          	bltu	a5,a4,8000340a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003430:	00015517          	auipc	a0,0x15
    80003434:	82050513          	addi	a0,a0,-2016 # 80017c50 <tickslock>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	860080e7          	jalr	-1952(ra) # 80000c98 <release>
  return 0;
    80003440:	4781                	li	a5,0
}
    80003442:	853e                	mv	a0,a5
    80003444:	70e2                	ld	ra,56(sp)
    80003446:	7442                	ld	s0,48(sp)
    80003448:	74a2                	ld	s1,40(sp)
    8000344a:	7902                	ld	s2,32(sp)
    8000344c:	69e2                	ld	s3,24(sp)
    8000344e:	6121                	addi	sp,sp,64
    80003450:	8082                	ret
      release(&tickslock);
    80003452:	00014517          	auipc	a0,0x14
    80003456:	7fe50513          	addi	a0,a0,2046 # 80017c50 <tickslock>
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	83e080e7          	jalr	-1986(ra) # 80000c98 <release>
      return -1;
    80003462:	57fd                	li	a5,-1
    80003464:	bff9                	j	80003442 <sys_sleep+0x88>

0000000080003466 <sys_kill>:

uint64
sys_kill(void)
{
    80003466:	1101                	addi	sp,sp,-32
    80003468:	ec06                	sd	ra,24(sp)
    8000346a:	e822                	sd	s0,16(sp)
    8000346c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000346e:	fec40593          	addi	a1,s0,-20
    80003472:	4501                	li	a0,0
    80003474:	00000097          	auipc	ra,0x0
    80003478:	d84080e7          	jalr	-636(ra) # 800031f8 <argint>
    8000347c:	87aa                	mv	a5,a0
    return -1;
    8000347e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003480:	0007c863          	bltz	a5,80003490 <sys_kill+0x2a>
  return kill(pid);
    80003484:	fec42503          	lw	a0,-20(s0)
    80003488:	fffff097          	auipc	ra,0xfffff
    8000348c:	1f4080e7          	jalr	500(ra) # 8000267c <kill>
}
    80003490:	60e2                	ld	ra,24(sp)
    80003492:	6442                	ld	s0,16(sp)
    80003494:	6105                	addi	sp,sp,32
    80003496:	8082                	ret

0000000080003498 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003498:	1101                	addi	sp,sp,-32
    8000349a:	ec06                	sd	ra,24(sp)
    8000349c:	e822                	sd	s0,16(sp)
    8000349e:	e426                	sd	s1,8(sp)
    800034a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034a2:	00014517          	auipc	a0,0x14
    800034a6:	7ae50513          	addi	a0,a0,1966 # 80017c50 <tickslock>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	73a080e7          	jalr	1850(ra) # 80000be4 <acquire>
  xticks = ticks;
    800034b2:	00006497          	auipc	s1,0x6
    800034b6:	b7e4a483          	lw	s1,-1154(s1) # 80009030 <ticks>
  release(&tickslock);
    800034ba:	00014517          	auipc	a0,0x14
    800034be:	79650513          	addi	a0,a0,1942 # 80017c50 <tickslock>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
  return xticks;
}
    800034ca:	02049513          	slli	a0,s1,0x20
    800034ce:	9101                	srli	a0,a0,0x20
    800034d0:	60e2                	ld	ra,24(sp)
    800034d2:	6442                	ld	s0,16(sp)
    800034d4:	64a2                	ld	s1,8(sp)
    800034d6:	6105                	addi	sp,sp,32
    800034d8:	8082                	ret

00000000800034da <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800034da:	1101                	addi	sp,sp,-32
    800034dc:	ec06                	sd	ra,24(sp)
    800034de:	e822                	sd	s0,16(sp)
    800034e0:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800034e2:	fec40593          	addi	a1,s0,-20
    800034e6:	4501                	li	a0,0
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	d10080e7          	jalr	-752(ra) # 800031f8 <argint>
    800034f0:	87aa                	mv	a5,a0
    return -1;
    800034f2:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    800034f4:	0007c863          	bltz	a5,80003504 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    800034f8:	fec42503          	lw	a0,-20(s0)
    800034fc:	fffff097          	auipc	ra,0xfffff
    80003500:	34c080e7          	jalr	844(ra) # 80002848 <set_cpu>
}
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret

000000008000350c <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000350c:	1141                	addi	sp,sp,-16
    8000350e:	e406                	sd	ra,8(sp)
    80003510:	e022                	sd	s0,0(sp)
    80003512:	0800                	addi	s0,sp,16
  return get_cpu();
    80003514:	fffff097          	auipc	ra,0xfffff
    80003518:	386080e7          	jalr	902(ra) # 8000289a <get_cpu>
}
    8000351c:	60a2                	ld	ra,8(sp)
    8000351e:	6402                	ld	s0,0(sp)
    80003520:	0141                	addi	sp,sp,16
    80003522:	8082                	ret

0000000080003524 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003524:	1101                	addi	sp,sp,-32
    80003526:	ec06                	sd	ra,24(sp)
    80003528:	e822                	sd	s0,16(sp)
    8000352a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000352c:	fec40593          	addi	a1,s0,-20
    80003530:	4501                	li	a0,0
    80003532:	00000097          	auipc	ra,0x0
    80003536:	cc6080e7          	jalr	-826(ra) # 800031f8 <argint>
    8000353a:	87aa                	mv	a5,a0
    return -1;
    8000353c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000353e:	0007c863          	bltz	a5,8000354e <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    80003542:	fec42503          	lw	a0,-20(s0)
    80003546:	fffff097          	auipc	ra,0xfffff
    8000354a:	3ae080e7          	jalr	942(ra) # 800028f4 <cpu_process_count>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	6105                	addi	sp,sp,32
    80003554:	8082                	ret

0000000080003556 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003556:	7179                	addi	sp,sp,-48
    80003558:	f406                	sd	ra,40(sp)
    8000355a:	f022                	sd	s0,32(sp)
    8000355c:	ec26                	sd	s1,24(sp)
    8000355e:	e84a                	sd	s2,16(sp)
    80003560:	e44e                	sd	s3,8(sp)
    80003562:	e052                	sd	s4,0(sp)
    80003564:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003566:	00005597          	auipc	a1,0x5
    8000356a:	0d258593          	addi	a1,a1,210 # 80008638 <syscalls+0xc8>
    8000356e:	00014517          	auipc	a0,0x14
    80003572:	6fa50513          	addi	a0,a0,1786 # 80017c68 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	5de080e7          	jalr	1502(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000357e:	0001c797          	auipc	a5,0x1c
    80003582:	6ea78793          	addi	a5,a5,1770 # 8001fc68 <bcache+0x8000>
    80003586:	0001d717          	auipc	a4,0x1d
    8000358a:	94a70713          	addi	a4,a4,-1718 # 8001fed0 <bcache+0x8268>
    8000358e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003592:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003596:	00014497          	auipc	s1,0x14
    8000359a:	6ea48493          	addi	s1,s1,1770 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    8000359e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035a0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035a2:	00005a17          	auipc	s4,0x5
    800035a6:	09ea0a13          	addi	s4,s4,158 # 80008640 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035aa:	2b893783          	ld	a5,696(s2)
    800035ae:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035b0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035b4:	85d2                	mv	a1,s4
    800035b6:	01048513          	addi	a0,s1,16
    800035ba:	00001097          	auipc	ra,0x1
    800035be:	4bc080e7          	jalr	1212(ra) # 80004a76 <initsleeplock>
    bcache.head.next->prev = b;
    800035c2:	2b893783          	ld	a5,696(s2)
    800035c6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035c8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035cc:	45848493          	addi	s1,s1,1112
    800035d0:	fd349de3          	bne	s1,s3,800035aa <binit+0x54>
  }
}
    800035d4:	70a2                	ld	ra,40(sp)
    800035d6:	7402                	ld	s0,32(sp)
    800035d8:	64e2                	ld	s1,24(sp)
    800035da:	6942                	ld	s2,16(sp)
    800035dc:	69a2                	ld	s3,8(sp)
    800035de:	6a02                	ld	s4,0(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret

00000000800035e4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035e4:	7179                	addi	sp,sp,-48
    800035e6:	f406                	sd	ra,40(sp)
    800035e8:	f022                	sd	s0,32(sp)
    800035ea:	ec26                	sd	s1,24(sp)
    800035ec:	e84a                	sd	s2,16(sp)
    800035ee:	e44e                	sd	s3,8(sp)
    800035f0:	1800                	addi	s0,sp,48
    800035f2:	89aa                	mv	s3,a0
    800035f4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035f6:	00014517          	auipc	a0,0x14
    800035fa:	67250513          	addi	a0,a0,1650 # 80017c68 <bcache>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003606:	0001d497          	auipc	s1,0x1d
    8000360a:	91a4b483          	ld	s1,-1766(s1) # 8001ff20 <bcache+0x82b8>
    8000360e:	0001d797          	auipc	a5,0x1d
    80003612:	8c278793          	addi	a5,a5,-1854 # 8001fed0 <bcache+0x8268>
    80003616:	02f48f63          	beq	s1,a5,80003654 <bread+0x70>
    8000361a:	873e                	mv	a4,a5
    8000361c:	a021                	j	80003624 <bread+0x40>
    8000361e:	68a4                	ld	s1,80(s1)
    80003620:	02e48a63          	beq	s1,a4,80003654 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003624:	449c                	lw	a5,8(s1)
    80003626:	ff379ce3          	bne	a5,s3,8000361e <bread+0x3a>
    8000362a:	44dc                	lw	a5,12(s1)
    8000362c:	ff2799e3          	bne	a5,s2,8000361e <bread+0x3a>
      b->refcnt++;
    80003630:	40bc                	lw	a5,64(s1)
    80003632:	2785                	addiw	a5,a5,1
    80003634:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003636:	00014517          	auipc	a0,0x14
    8000363a:	63250513          	addi	a0,a0,1586 # 80017c68 <bcache>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	65a080e7          	jalr	1626(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003646:	01048513          	addi	a0,s1,16
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	466080e7          	jalr	1126(ra) # 80004ab0 <acquiresleep>
      return b;
    80003652:	a8b9                	j	800036b0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003654:	0001d497          	auipc	s1,0x1d
    80003658:	8c44b483          	ld	s1,-1852(s1) # 8001ff18 <bcache+0x82b0>
    8000365c:	0001d797          	auipc	a5,0x1d
    80003660:	87478793          	addi	a5,a5,-1932 # 8001fed0 <bcache+0x8268>
    80003664:	00f48863          	beq	s1,a5,80003674 <bread+0x90>
    80003668:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000366a:	40bc                	lw	a5,64(s1)
    8000366c:	cf81                	beqz	a5,80003684 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000366e:	64a4                	ld	s1,72(s1)
    80003670:	fee49de3          	bne	s1,a4,8000366a <bread+0x86>
  panic("bget: no buffers");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	fd450513          	addi	a0,a0,-44 # 80008648 <syscalls+0xd8>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
      b->dev = dev;
    80003684:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003688:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000368c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003690:	4785                	li	a5,1
    80003692:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003694:	00014517          	auipc	a0,0x14
    80003698:	5d450513          	addi	a0,a0,1492 # 80017c68 <bcache>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	5fc080e7          	jalr	1532(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036a4:	01048513          	addi	a0,s1,16
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	408080e7          	jalr	1032(ra) # 80004ab0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036b0:	409c                	lw	a5,0(s1)
    800036b2:	cb89                	beqz	a5,800036c4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036b4:	8526                	mv	a0,s1
    800036b6:	70a2                	ld	ra,40(sp)
    800036b8:	7402                	ld	s0,32(sp)
    800036ba:	64e2                	ld	s1,24(sp)
    800036bc:	6942                	ld	s2,16(sp)
    800036be:	69a2                	ld	s3,8(sp)
    800036c0:	6145                	addi	sp,sp,48
    800036c2:	8082                	ret
    virtio_disk_rw(b, 0);
    800036c4:	4581                	li	a1,0
    800036c6:	8526                	mv	a0,s1
    800036c8:	00003097          	auipc	ra,0x3
    800036cc:	f0e080e7          	jalr	-242(ra) # 800065d6 <virtio_disk_rw>
    b->valid = 1;
    800036d0:	4785                	li	a5,1
    800036d2:	c09c                	sw	a5,0(s1)
  return b;
    800036d4:	b7c5                	j	800036b4 <bread+0xd0>

00000000800036d6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036d6:	1101                	addi	sp,sp,-32
    800036d8:	ec06                	sd	ra,24(sp)
    800036da:	e822                	sd	s0,16(sp)
    800036dc:	e426                	sd	s1,8(sp)
    800036de:	1000                	addi	s0,sp,32
    800036e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036e2:	0541                	addi	a0,a0,16
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	466080e7          	jalr	1126(ra) # 80004b4a <holdingsleep>
    800036ec:	cd01                	beqz	a0,80003704 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036ee:	4585                	li	a1,1
    800036f0:	8526                	mv	a0,s1
    800036f2:	00003097          	auipc	ra,0x3
    800036f6:	ee4080e7          	jalr	-284(ra) # 800065d6 <virtio_disk_rw>
}
    800036fa:	60e2                	ld	ra,24(sp)
    800036fc:	6442                	ld	s0,16(sp)
    800036fe:	64a2                	ld	s1,8(sp)
    80003700:	6105                	addi	sp,sp,32
    80003702:	8082                	ret
    panic("bwrite");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	f5c50513          	addi	a0,a0,-164 # 80008660 <syscalls+0xf0>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e32080e7          	jalr	-462(ra) # 8000053e <panic>

0000000080003714 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	e04a                	sd	s2,0(sp)
    8000371e:	1000                	addi	s0,sp,32
    80003720:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003722:	01050913          	addi	s2,a0,16
    80003726:	854a                	mv	a0,s2
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	422080e7          	jalr	1058(ra) # 80004b4a <holdingsleep>
    80003730:	c92d                	beqz	a0,800037a2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003732:	854a                	mv	a0,s2
    80003734:	00001097          	auipc	ra,0x1
    80003738:	3d2080e7          	jalr	978(ra) # 80004b06 <releasesleep>

  acquire(&bcache.lock);
    8000373c:	00014517          	auipc	a0,0x14
    80003740:	52c50513          	addi	a0,a0,1324 # 80017c68 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	4a0080e7          	jalr	1184(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000374c:	40bc                	lw	a5,64(s1)
    8000374e:	37fd                	addiw	a5,a5,-1
    80003750:	0007871b          	sext.w	a4,a5
    80003754:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003756:	eb05                	bnez	a4,80003786 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003758:	68bc                	ld	a5,80(s1)
    8000375a:	64b8                	ld	a4,72(s1)
    8000375c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000375e:	64bc                	ld	a5,72(s1)
    80003760:	68b8                	ld	a4,80(s1)
    80003762:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003764:	0001c797          	auipc	a5,0x1c
    80003768:	50478793          	addi	a5,a5,1284 # 8001fc68 <bcache+0x8000>
    8000376c:	2b87b703          	ld	a4,696(a5)
    80003770:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003772:	0001c717          	auipc	a4,0x1c
    80003776:	75e70713          	addi	a4,a4,1886 # 8001fed0 <bcache+0x8268>
    8000377a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000377c:	2b87b703          	ld	a4,696(a5)
    80003780:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003782:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003786:	00014517          	auipc	a0,0x14
    8000378a:	4e250513          	addi	a0,a0,1250 # 80017c68 <bcache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	50a080e7          	jalr	1290(ra) # 80000c98 <release>
}
    80003796:	60e2                	ld	ra,24(sp)
    80003798:	6442                	ld	s0,16(sp)
    8000379a:	64a2                	ld	s1,8(sp)
    8000379c:	6902                	ld	s2,0(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret
    panic("brelse");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	ec650513          	addi	a0,a0,-314 # 80008668 <syscalls+0xf8>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	d94080e7          	jalr	-620(ra) # 8000053e <panic>

00000000800037b2 <bpin>:

void
bpin(struct buf *b) {
    800037b2:	1101                	addi	sp,sp,-32
    800037b4:	ec06                	sd	ra,24(sp)
    800037b6:	e822                	sd	s0,16(sp)
    800037b8:	e426                	sd	s1,8(sp)
    800037ba:	1000                	addi	s0,sp,32
    800037bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037be:	00014517          	auipc	a0,0x14
    800037c2:	4aa50513          	addi	a0,a0,1194 # 80017c68 <bcache>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	41e080e7          	jalr	1054(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037ce:	40bc                	lw	a5,64(s1)
    800037d0:	2785                	addiw	a5,a5,1
    800037d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d4:	00014517          	auipc	a0,0x14
    800037d8:	49450513          	addi	a0,a0,1172 # 80017c68 <bcache>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	4bc080e7          	jalr	1212(ra) # 80000c98 <release>
}
    800037e4:	60e2                	ld	ra,24(sp)
    800037e6:	6442                	ld	s0,16(sp)
    800037e8:	64a2                	ld	s1,8(sp)
    800037ea:	6105                	addi	sp,sp,32
    800037ec:	8082                	ret

00000000800037ee <bunpin>:

void
bunpin(struct buf *b) {
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037fa:	00014517          	auipc	a0,0x14
    800037fe:	46e50513          	addi	a0,a0,1134 # 80017c68 <bcache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	3e2080e7          	jalr	994(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000380a:	40bc                	lw	a5,64(s1)
    8000380c:	37fd                	addiw	a5,a5,-1
    8000380e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003810:	00014517          	auipc	a0,0x14
    80003814:	45850513          	addi	a0,a0,1112 # 80017c68 <bcache>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	480080e7          	jalr	1152(ra) # 80000c98 <release>
}
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	64a2                	ld	s1,8(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret

000000008000382a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	e04a                	sd	s2,0(sp)
    80003834:	1000                	addi	s0,sp,32
    80003836:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003838:	00d5d59b          	srliw	a1,a1,0xd
    8000383c:	0001d797          	auipc	a5,0x1d
    80003840:	b087a783          	lw	a5,-1272(a5) # 80020344 <sb+0x1c>
    80003844:	9dbd                	addw	a1,a1,a5
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	d9e080e7          	jalr	-610(ra) # 800035e4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000384e:	0074f713          	andi	a4,s1,7
    80003852:	4785                	li	a5,1
    80003854:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003858:	14ce                	slli	s1,s1,0x33
    8000385a:	90d9                	srli	s1,s1,0x36
    8000385c:	00950733          	add	a4,a0,s1
    80003860:	05874703          	lbu	a4,88(a4)
    80003864:	00e7f6b3          	and	a3,a5,a4
    80003868:	c69d                	beqz	a3,80003896 <bfree+0x6c>
    8000386a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000386c:	94aa                	add	s1,s1,a0
    8000386e:	fff7c793          	not	a5,a5
    80003872:	8ff9                	and	a5,a5,a4
    80003874:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003878:	00001097          	auipc	ra,0x1
    8000387c:	118080e7          	jalr	280(ra) # 80004990 <log_write>
  brelse(bp);
    80003880:	854a                	mv	a0,s2
    80003882:	00000097          	auipc	ra,0x0
    80003886:	e92080e7          	jalr	-366(ra) # 80003714 <brelse>
}
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6902                	ld	s2,0(sp)
    80003892:	6105                	addi	sp,sp,32
    80003894:	8082                	ret
    panic("freeing free block");
    80003896:	00005517          	auipc	a0,0x5
    8000389a:	dda50513          	addi	a0,a0,-550 # 80008670 <syscalls+0x100>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	ca0080e7          	jalr	-864(ra) # 8000053e <panic>

00000000800038a6 <balloc>:
{
    800038a6:	711d                	addi	sp,sp,-96
    800038a8:	ec86                	sd	ra,88(sp)
    800038aa:	e8a2                	sd	s0,80(sp)
    800038ac:	e4a6                	sd	s1,72(sp)
    800038ae:	e0ca                	sd	s2,64(sp)
    800038b0:	fc4e                	sd	s3,56(sp)
    800038b2:	f852                	sd	s4,48(sp)
    800038b4:	f456                	sd	s5,40(sp)
    800038b6:	f05a                	sd	s6,32(sp)
    800038b8:	ec5e                	sd	s7,24(sp)
    800038ba:	e862                	sd	s8,16(sp)
    800038bc:	e466                	sd	s9,8(sp)
    800038be:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038c0:	0001d797          	auipc	a5,0x1d
    800038c4:	a6c7a783          	lw	a5,-1428(a5) # 8002032c <sb+0x4>
    800038c8:	cbd1                	beqz	a5,8000395c <balloc+0xb6>
    800038ca:	8baa                	mv	s7,a0
    800038cc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038ce:	0001db17          	auipc	s6,0x1d
    800038d2:	a5ab0b13          	addi	s6,s6,-1446 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038d6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038d8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038da:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038dc:	6c89                	lui	s9,0x2
    800038de:	a831                	j	800038fa <balloc+0x54>
    brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	e32080e7          	jalr	-462(ra) # 80003714 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038ea:	015c87bb          	addw	a5,s9,s5
    800038ee:	00078a9b          	sext.w	s5,a5
    800038f2:	004b2703          	lw	a4,4(s6)
    800038f6:	06eaf363          	bgeu	s5,a4,8000395c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038fa:	41fad79b          	sraiw	a5,s5,0x1f
    800038fe:	0137d79b          	srliw	a5,a5,0x13
    80003902:	015787bb          	addw	a5,a5,s5
    80003906:	40d7d79b          	sraiw	a5,a5,0xd
    8000390a:	01cb2583          	lw	a1,28(s6)
    8000390e:	9dbd                	addw	a1,a1,a5
    80003910:	855e                	mv	a0,s7
    80003912:	00000097          	auipc	ra,0x0
    80003916:	cd2080e7          	jalr	-814(ra) # 800035e4 <bread>
    8000391a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000391c:	004b2503          	lw	a0,4(s6)
    80003920:	000a849b          	sext.w	s1,s5
    80003924:	8662                	mv	a2,s8
    80003926:	faa4fde3          	bgeu	s1,a0,800038e0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000392a:	41f6579b          	sraiw	a5,a2,0x1f
    8000392e:	01d7d69b          	srliw	a3,a5,0x1d
    80003932:	00c6873b          	addw	a4,a3,a2
    80003936:	00777793          	andi	a5,a4,7
    8000393a:	9f95                	subw	a5,a5,a3
    8000393c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003940:	4037571b          	sraiw	a4,a4,0x3
    80003944:	00e906b3          	add	a3,s2,a4
    80003948:	0586c683          	lbu	a3,88(a3)
    8000394c:	00d7f5b3          	and	a1,a5,a3
    80003950:	cd91                	beqz	a1,8000396c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003952:	2605                	addiw	a2,a2,1
    80003954:	2485                	addiw	s1,s1,1
    80003956:	fd4618e3          	bne	a2,s4,80003926 <balloc+0x80>
    8000395a:	b759                	j	800038e0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000395c:	00005517          	auipc	a0,0x5
    80003960:	d2c50513          	addi	a0,a0,-724 # 80008688 <syscalls+0x118>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000396c:	974a                	add	a4,a4,s2
    8000396e:	8fd5                	or	a5,a5,a3
    80003970:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	01a080e7          	jalr	26(ra) # 80004990 <log_write>
        brelse(bp);
    8000397e:	854a                	mv	a0,s2
    80003980:	00000097          	auipc	ra,0x0
    80003984:	d94080e7          	jalr	-620(ra) # 80003714 <brelse>
  bp = bread(dev, bno);
    80003988:	85a6                	mv	a1,s1
    8000398a:	855e                	mv	a0,s7
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	c58080e7          	jalr	-936(ra) # 800035e4 <bread>
    80003994:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003996:	40000613          	li	a2,1024
    8000399a:	4581                	li	a1,0
    8000399c:	05850513          	addi	a0,a0,88
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	340080e7          	jalr	832(ra) # 80000ce0 <memset>
  log_write(bp);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	fe6080e7          	jalr	-26(ra) # 80004990 <log_write>
  brelse(bp);
    800039b2:	854a                	mv	a0,s2
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	d60080e7          	jalr	-672(ra) # 80003714 <brelse>
}
    800039bc:	8526                	mv	a0,s1
    800039be:	60e6                	ld	ra,88(sp)
    800039c0:	6446                	ld	s0,80(sp)
    800039c2:	64a6                	ld	s1,72(sp)
    800039c4:	6906                	ld	s2,64(sp)
    800039c6:	79e2                	ld	s3,56(sp)
    800039c8:	7a42                	ld	s4,48(sp)
    800039ca:	7aa2                	ld	s5,40(sp)
    800039cc:	7b02                	ld	s6,32(sp)
    800039ce:	6be2                	ld	s7,24(sp)
    800039d0:	6c42                	ld	s8,16(sp)
    800039d2:	6ca2                	ld	s9,8(sp)
    800039d4:	6125                	addi	sp,sp,96
    800039d6:	8082                	ret

00000000800039d8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039d8:	7179                	addi	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	e052                	sd	s4,0(sp)
    800039e6:	1800                	addi	s0,sp,48
    800039e8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039ea:	47ad                	li	a5,11
    800039ec:	04b7fe63          	bgeu	a5,a1,80003a48 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039f0:	ff45849b          	addiw	s1,a1,-12
    800039f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039f8:	0ff00793          	li	a5,255
    800039fc:	0ae7e363          	bltu	a5,a4,80003aa2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a00:	08052583          	lw	a1,128(a0)
    80003a04:	c5ad                	beqz	a1,80003a6e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a06:	00092503          	lw	a0,0(s2)
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	bda080e7          	jalr	-1062(ra) # 800035e4 <bread>
    80003a12:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a14:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a18:	02049593          	slli	a1,s1,0x20
    80003a1c:	9181                	srli	a1,a1,0x20
    80003a1e:	058a                	slli	a1,a1,0x2
    80003a20:	00b784b3          	add	s1,a5,a1
    80003a24:	0004a983          	lw	s3,0(s1)
    80003a28:	04098d63          	beqz	s3,80003a82 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a2c:	8552                	mv	a0,s4
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	ce6080e7          	jalr	-794(ra) # 80003714 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a36:	854e                	mv	a0,s3
    80003a38:	70a2                	ld	ra,40(sp)
    80003a3a:	7402                	ld	s0,32(sp)
    80003a3c:	64e2                	ld	s1,24(sp)
    80003a3e:	6942                	ld	s2,16(sp)
    80003a40:	69a2                	ld	s3,8(sp)
    80003a42:	6a02                	ld	s4,0(sp)
    80003a44:	6145                	addi	sp,sp,48
    80003a46:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a48:	02059493          	slli	s1,a1,0x20
    80003a4c:	9081                	srli	s1,s1,0x20
    80003a4e:	048a                	slli	s1,s1,0x2
    80003a50:	94aa                	add	s1,s1,a0
    80003a52:	0504a983          	lw	s3,80(s1)
    80003a56:	fe0990e3          	bnez	s3,80003a36 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a5a:	4108                	lw	a0,0(a0)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	e4a080e7          	jalr	-438(ra) # 800038a6 <balloc>
    80003a64:	0005099b          	sext.w	s3,a0
    80003a68:	0534a823          	sw	s3,80(s1)
    80003a6c:	b7e9                	j	80003a36 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a6e:	4108                	lw	a0,0(a0)
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	e36080e7          	jalr	-458(ra) # 800038a6 <balloc>
    80003a78:	0005059b          	sext.w	a1,a0
    80003a7c:	08b92023          	sw	a1,128(s2)
    80003a80:	b759                	j	80003a06 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a82:	00092503          	lw	a0,0(s2)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	e20080e7          	jalr	-480(ra) # 800038a6 <balloc>
    80003a8e:	0005099b          	sext.w	s3,a0
    80003a92:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a96:	8552                	mv	a0,s4
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	ef8080e7          	jalr	-264(ra) # 80004990 <log_write>
    80003aa0:	b771                	j	80003a2c <bmap+0x54>
  panic("bmap: out of range");
    80003aa2:	00005517          	auipc	a0,0x5
    80003aa6:	bfe50513          	addi	a0,a0,-1026 # 800086a0 <syscalls+0x130>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>

0000000080003ab2 <iget>:
{
    80003ab2:	7179                	addi	sp,sp,-48
    80003ab4:	f406                	sd	ra,40(sp)
    80003ab6:	f022                	sd	s0,32(sp)
    80003ab8:	ec26                	sd	s1,24(sp)
    80003aba:	e84a                	sd	s2,16(sp)
    80003abc:	e44e                	sd	s3,8(sp)
    80003abe:	e052                	sd	s4,0(sp)
    80003ac0:	1800                	addi	s0,sp,48
    80003ac2:	89aa                	mv	s3,a0
    80003ac4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ac6:	0001d517          	auipc	a0,0x1d
    80003aca:	88250513          	addi	a0,a0,-1918 # 80020348 <itable>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	116080e7          	jalr	278(ra) # 80000be4 <acquire>
  empty = 0;
    80003ad6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad8:	0001d497          	auipc	s1,0x1d
    80003adc:	88848493          	addi	s1,s1,-1912 # 80020360 <itable+0x18>
    80003ae0:	0001e697          	auipc	a3,0x1e
    80003ae4:	31068693          	addi	a3,a3,784 # 80021df0 <log>
    80003ae8:	a039                	j	80003af6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aea:	02090b63          	beqz	s2,80003b20 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aee:	08848493          	addi	s1,s1,136
    80003af2:	02d48a63          	beq	s1,a3,80003b26 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003af6:	449c                	lw	a5,8(s1)
    80003af8:	fef059e3          	blez	a5,80003aea <iget+0x38>
    80003afc:	4098                	lw	a4,0(s1)
    80003afe:	ff3716e3          	bne	a4,s3,80003aea <iget+0x38>
    80003b02:	40d8                	lw	a4,4(s1)
    80003b04:	ff4713e3          	bne	a4,s4,80003aea <iget+0x38>
      ip->ref++;
    80003b08:	2785                	addiw	a5,a5,1
    80003b0a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b0c:	0001d517          	auipc	a0,0x1d
    80003b10:	83c50513          	addi	a0,a0,-1988 # 80020348 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
      return ip;
    80003b1c:	8926                	mv	s2,s1
    80003b1e:	a03d                	j	80003b4c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b20:	f7f9                	bnez	a5,80003aee <iget+0x3c>
    80003b22:	8926                	mv	s2,s1
    80003b24:	b7e9                	j	80003aee <iget+0x3c>
  if(empty == 0)
    80003b26:	02090c63          	beqz	s2,80003b5e <iget+0xac>
  ip->dev = dev;
    80003b2a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b2e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b32:	4785                	li	a5,1
    80003b34:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b38:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b3c:	0001d517          	auipc	a0,0x1d
    80003b40:	80c50513          	addi	a0,a0,-2036 # 80020348 <itable>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	154080e7          	jalr	340(ra) # 80000c98 <release>
}
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	70a2                	ld	ra,40(sp)
    80003b50:	7402                	ld	s0,32(sp)
    80003b52:	64e2                	ld	s1,24(sp)
    80003b54:	6942                	ld	s2,16(sp)
    80003b56:	69a2                	ld	s3,8(sp)
    80003b58:	6a02                	ld	s4,0(sp)
    80003b5a:	6145                	addi	sp,sp,48
    80003b5c:	8082                	ret
    panic("iget: no inodes");
    80003b5e:	00005517          	auipc	a0,0x5
    80003b62:	b5a50513          	addi	a0,a0,-1190 # 800086b8 <syscalls+0x148>
    80003b66:	ffffd097          	auipc	ra,0xffffd
    80003b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>

0000000080003b6e <fsinit>:
fsinit(int dev) {
    80003b6e:	7179                	addi	sp,sp,-48
    80003b70:	f406                	sd	ra,40(sp)
    80003b72:	f022                	sd	s0,32(sp)
    80003b74:	ec26                	sd	s1,24(sp)
    80003b76:	e84a                	sd	s2,16(sp)
    80003b78:	e44e                	sd	s3,8(sp)
    80003b7a:	1800                	addi	s0,sp,48
    80003b7c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b7e:	4585                	li	a1,1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	a64080e7          	jalr	-1436(ra) # 800035e4 <bread>
    80003b88:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8a:	0001c997          	auipc	s3,0x1c
    80003b8e:	79e98993          	addi	s3,s3,1950 # 80020328 <sb>
    80003b92:	02000613          	li	a2,32
    80003b96:	05850593          	addi	a1,a0,88
    80003b9a:	854e                	mv	a0,s3
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	1a4080e7          	jalr	420(ra) # 80000d40 <memmove>
  brelse(bp);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	b6e080e7          	jalr	-1170(ra) # 80003714 <brelse>
  if(sb.magic != FSMAGIC)
    80003bae:	0009a703          	lw	a4,0(s3)
    80003bb2:	102037b7          	lui	a5,0x10203
    80003bb6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bba:	02f71263          	bne	a4,a5,80003bde <fsinit+0x70>
  initlog(dev, &sb);
    80003bbe:	0001c597          	auipc	a1,0x1c
    80003bc2:	76a58593          	addi	a1,a1,1898 # 80020328 <sb>
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00001097          	auipc	ra,0x1
    80003bcc:	b4c080e7          	jalr	-1204(ra) # 80004714 <initlog>
}
    80003bd0:	70a2                	ld	ra,40(sp)
    80003bd2:	7402                	ld	s0,32(sp)
    80003bd4:	64e2                	ld	s1,24(sp)
    80003bd6:	6942                	ld	s2,16(sp)
    80003bd8:	69a2                	ld	s3,8(sp)
    80003bda:	6145                	addi	sp,sp,48
    80003bdc:	8082                	ret
    panic("invalid file system");
    80003bde:	00005517          	auipc	a0,0x5
    80003be2:	aea50513          	addi	a0,a0,-1302 # 800086c8 <syscalls+0x158>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	958080e7          	jalr	-1704(ra) # 8000053e <panic>

0000000080003bee <iinit>:
{
    80003bee:	7179                	addi	sp,sp,-48
    80003bf0:	f406                	sd	ra,40(sp)
    80003bf2:	f022                	sd	s0,32(sp)
    80003bf4:	ec26                	sd	s1,24(sp)
    80003bf6:	e84a                	sd	s2,16(sp)
    80003bf8:	e44e                	sd	s3,8(sp)
    80003bfa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bfc:	00005597          	auipc	a1,0x5
    80003c00:	ae458593          	addi	a1,a1,-1308 # 800086e0 <syscalls+0x170>
    80003c04:	0001c517          	auipc	a0,0x1c
    80003c08:	74450513          	addi	a0,a0,1860 # 80020348 <itable>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	f48080e7          	jalr	-184(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c14:	0001c497          	auipc	s1,0x1c
    80003c18:	75c48493          	addi	s1,s1,1884 # 80020370 <itable+0x28>
    80003c1c:	0001e997          	auipc	s3,0x1e
    80003c20:	1e498993          	addi	s3,s3,484 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c24:	00005917          	auipc	s2,0x5
    80003c28:	ac490913          	addi	s2,s2,-1340 # 800086e8 <syscalls+0x178>
    80003c2c:	85ca                	mv	a1,s2
    80003c2e:	8526                	mv	a0,s1
    80003c30:	00001097          	auipc	ra,0x1
    80003c34:	e46080e7          	jalr	-442(ra) # 80004a76 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c38:	08848493          	addi	s1,s1,136
    80003c3c:	ff3498e3          	bne	s1,s3,80003c2c <iinit+0x3e>
}
    80003c40:	70a2                	ld	ra,40(sp)
    80003c42:	7402                	ld	s0,32(sp)
    80003c44:	64e2                	ld	s1,24(sp)
    80003c46:	6942                	ld	s2,16(sp)
    80003c48:	69a2                	ld	s3,8(sp)
    80003c4a:	6145                	addi	sp,sp,48
    80003c4c:	8082                	ret

0000000080003c4e <ialloc>:
{
    80003c4e:	715d                	addi	sp,sp,-80
    80003c50:	e486                	sd	ra,72(sp)
    80003c52:	e0a2                	sd	s0,64(sp)
    80003c54:	fc26                	sd	s1,56(sp)
    80003c56:	f84a                	sd	s2,48(sp)
    80003c58:	f44e                	sd	s3,40(sp)
    80003c5a:	f052                	sd	s4,32(sp)
    80003c5c:	ec56                	sd	s5,24(sp)
    80003c5e:	e85a                	sd	s6,16(sp)
    80003c60:	e45e                	sd	s7,8(sp)
    80003c62:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c64:	0001c717          	auipc	a4,0x1c
    80003c68:	6d072703          	lw	a4,1744(a4) # 80020334 <sb+0xc>
    80003c6c:	4785                	li	a5,1
    80003c6e:	04e7fa63          	bgeu	a5,a4,80003cc2 <ialloc+0x74>
    80003c72:	8aaa                	mv	s5,a0
    80003c74:	8bae                	mv	s7,a1
    80003c76:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c78:	0001ca17          	auipc	s4,0x1c
    80003c7c:	6b0a0a13          	addi	s4,s4,1712 # 80020328 <sb>
    80003c80:	00048b1b          	sext.w	s6,s1
    80003c84:	0044d593          	srli	a1,s1,0x4
    80003c88:	018a2783          	lw	a5,24(s4)
    80003c8c:	9dbd                	addw	a1,a1,a5
    80003c8e:	8556                	mv	a0,s5
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	954080e7          	jalr	-1708(ra) # 800035e4 <bread>
    80003c98:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c9a:	05850993          	addi	s3,a0,88
    80003c9e:	00f4f793          	andi	a5,s1,15
    80003ca2:	079a                	slli	a5,a5,0x6
    80003ca4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca6:	00099783          	lh	a5,0(s3)
    80003caa:	c785                	beqz	a5,80003cd2 <ialloc+0x84>
    brelse(bp);
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	a68080e7          	jalr	-1432(ra) # 80003714 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb4:	0485                	addi	s1,s1,1
    80003cb6:	00ca2703          	lw	a4,12(s4)
    80003cba:	0004879b          	sext.w	a5,s1
    80003cbe:	fce7e1e3          	bltu	a5,a4,80003c80 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cc2:	00005517          	auipc	a0,0x5
    80003cc6:	a2e50513          	addi	a0,a0,-1490 # 800086f0 <syscalls+0x180>
    80003cca:	ffffd097          	auipc	ra,0xffffd
    80003cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cd2:	04000613          	li	a2,64
    80003cd6:	4581                	li	a1,0
    80003cd8:	854e                	mv	a0,s3
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	006080e7          	jalr	6(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ce2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	ca8080e7          	jalr	-856(ra) # 80004990 <log_write>
      brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	a22080e7          	jalr	-1502(ra) # 80003714 <brelse>
      return iget(dev, inum);
    80003cfa:	85da                	mv	a1,s6
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	db4080e7          	jalr	-588(ra) # 80003ab2 <iget>
}
    80003d06:	60a6                	ld	ra,72(sp)
    80003d08:	6406                	ld	s0,64(sp)
    80003d0a:	74e2                	ld	s1,56(sp)
    80003d0c:	7942                	ld	s2,48(sp)
    80003d0e:	79a2                	ld	s3,40(sp)
    80003d10:	7a02                	ld	s4,32(sp)
    80003d12:	6ae2                	ld	s5,24(sp)
    80003d14:	6b42                	ld	s6,16(sp)
    80003d16:	6ba2                	ld	s7,8(sp)
    80003d18:	6161                	addi	sp,sp,80
    80003d1a:	8082                	ret

0000000080003d1c <iupdate>:
{
    80003d1c:	1101                	addi	sp,sp,-32
    80003d1e:	ec06                	sd	ra,24(sp)
    80003d20:	e822                	sd	s0,16(sp)
    80003d22:	e426                	sd	s1,8(sp)
    80003d24:	e04a                	sd	s2,0(sp)
    80003d26:	1000                	addi	s0,sp,32
    80003d28:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2a:	415c                	lw	a5,4(a0)
    80003d2c:	0047d79b          	srliw	a5,a5,0x4
    80003d30:	0001c597          	auipc	a1,0x1c
    80003d34:	6105a583          	lw	a1,1552(a1) # 80020340 <sb+0x18>
    80003d38:	9dbd                	addw	a1,a1,a5
    80003d3a:	4108                	lw	a0,0(a0)
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	8a8080e7          	jalr	-1880(ra) # 800035e4 <bread>
    80003d44:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d46:	05850793          	addi	a5,a0,88
    80003d4a:	40c8                	lw	a0,4(s1)
    80003d4c:	893d                	andi	a0,a0,15
    80003d4e:	051a                	slli	a0,a0,0x6
    80003d50:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d52:	04449703          	lh	a4,68(s1)
    80003d56:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d5a:	04649703          	lh	a4,70(s1)
    80003d5e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d62:	04849703          	lh	a4,72(s1)
    80003d66:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d6a:	04a49703          	lh	a4,74(s1)
    80003d6e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d72:	44f8                	lw	a4,76(s1)
    80003d74:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d76:	03400613          	li	a2,52
    80003d7a:	05048593          	addi	a1,s1,80
    80003d7e:	0531                	addi	a0,a0,12
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	fc0080e7          	jalr	-64(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00001097          	auipc	ra,0x1
    80003d8e:	c06080e7          	jalr	-1018(ra) # 80004990 <log_write>
  brelse(bp);
    80003d92:	854a                	mv	a0,s2
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	980080e7          	jalr	-1664(ra) # 80003714 <brelse>
}
    80003d9c:	60e2                	ld	ra,24(sp)
    80003d9e:	6442                	ld	s0,16(sp)
    80003da0:	64a2                	ld	s1,8(sp)
    80003da2:	6902                	ld	s2,0(sp)
    80003da4:	6105                	addi	sp,sp,32
    80003da6:	8082                	ret

0000000080003da8 <idup>:
{
    80003da8:	1101                	addi	sp,sp,-32
    80003daa:	ec06                	sd	ra,24(sp)
    80003dac:	e822                	sd	s0,16(sp)
    80003dae:	e426                	sd	s1,8(sp)
    80003db0:	1000                	addi	s0,sp,32
    80003db2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db4:	0001c517          	auipc	a0,0x1c
    80003db8:	59450513          	addi	a0,a0,1428 # 80020348 <itable>
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	e28080e7          	jalr	-472(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dc4:	449c                	lw	a5,8(s1)
    80003dc6:	2785                	addiw	a5,a5,1
    80003dc8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dca:	0001c517          	auipc	a0,0x1c
    80003dce:	57e50513          	addi	a0,a0,1406 # 80020348 <itable>
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	ec6080e7          	jalr	-314(ra) # 80000c98 <release>
}
    80003dda:	8526                	mv	a0,s1
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	64a2                	ld	s1,8(sp)
    80003de2:	6105                	addi	sp,sp,32
    80003de4:	8082                	ret

0000000080003de6 <ilock>:
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df2:	c115                	beqz	a0,80003e16 <ilock+0x30>
    80003df4:	84aa                	mv	s1,a0
    80003df6:	451c                	lw	a5,8(a0)
    80003df8:	00f05f63          	blez	a5,80003e16 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dfc:	0541                	addi	a0,a0,16
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	cb2080e7          	jalr	-846(ra) # 80004ab0 <acquiresleep>
  if(ip->valid == 0){
    80003e06:	40bc                	lw	a5,64(s1)
    80003e08:	cf99                	beqz	a5,80003e26 <ilock+0x40>
}
    80003e0a:	60e2                	ld	ra,24(sp)
    80003e0c:	6442                	ld	s0,16(sp)
    80003e0e:	64a2                	ld	s1,8(sp)
    80003e10:	6902                	ld	s2,0(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret
    panic("ilock");
    80003e16:	00005517          	auipc	a0,0x5
    80003e1a:	8f250513          	addi	a0,a0,-1806 # 80008708 <syscalls+0x198>
    80003e1e:	ffffc097          	auipc	ra,0xffffc
    80003e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e26:	40dc                	lw	a5,4(s1)
    80003e28:	0047d79b          	srliw	a5,a5,0x4
    80003e2c:	0001c597          	auipc	a1,0x1c
    80003e30:	5145a583          	lw	a1,1300(a1) # 80020340 <sb+0x18>
    80003e34:	9dbd                	addw	a1,a1,a5
    80003e36:	4088                	lw	a0,0(s1)
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	7ac080e7          	jalr	1964(ra) # 800035e4 <bread>
    80003e40:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e42:	05850593          	addi	a1,a0,88
    80003e46:	40dc                	lw	a5,4(s1)
    80003e48:	8bbd                	andi	a5,a5,15
    80003e4a:	079a                	slli	a5,a5,0x6
    80003e4c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e4e:	00059783          	lh	a5,0(a1)
    80003e52:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e56:	00259783          	lh	a5,2(a1)
    80003e5a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e5e:	00459783          	lh	a5,4(a1)
    80003e62:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e66:	00659783          	lh	a5,6(a1)
    80003e6a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e6e:	459c                	lw	a5,8(a1)
    80003e70:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e72:	03400613          	li	a2,52
    80003e76:	05b1                	addi	a1,a1,12
    80003e78:	05048513          	addi	a0,s1,80
    80003e7c:	ffffd097          	auipc	ra,0xffffd
    80003e80:	ec4080e7          	jalr	-316(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e84:	854a                	mv	a0,s2
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	88e080e7          	jalr	-1906(ra) # 80003714 <brelse>
    ip->valid = 1;
    80003e8e:	4785                	li	a5,1
    80003e90:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e92:	04449783          	lh	a5,68(s1)
    80003e96:	fbb5                	bnez	a5,80003e0a <ilock+0x24>
      panic("ilock: no type");
    80003e98:	00005517          	auipc	a0,0x5
    80003e9c:	87850513          	addi	a0,a0,-1928 # 80008710 <syscalls+0x1a0>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	69e080e7          	jalr	1694(ra) # 8000053e <panic>

0000000080003ea8 <iunlock>:
{
    80003ea8:	1101                	addi	sp,sp,-32
    80003eaa:	ec06                	sd	ra,24(sp)
    80003eac:	e822                	sd	s0,16(sp)
    80003eae:	e426                	sd	s1,8(sp)
    80003eb0:	e04a                	sd	s2,0(sp)
    80003eb2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb4:	c905                	beqz	a0,80003ee4 <iunlock+0x3c>
    80003eb6:	84aa                	mv	s1,a0
    80003eb8:	01050913          	addi	s2,a0,16
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00001097          	auipc	ra,0x1
    80003ec2:	c8c080e7          	jalr	-884(ra) # 80004b4a <holdingsleep>
    80003ec6:	cd19                	beqz	a0,80003ee4 <iunlock+0x3c>
    80003ec8:	449c                	lw	a5,8(s1)
    80003eca:	00f05d63          	blez	a5,80003ee4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00001097          	auipc	ra,0x1
    80003ed4:	c36080e7          	jalr	-970(ra) # 80004b06 <releasesleep>
}
    80003ed8:	60e2                	ld	ra,24(sp)
    80003eda:	6442                	ld	s0,16(sp)
    80003edc:	64a2                	ld	s1,8(sp)
    80003ede:	6902                	ld	s2,0(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret
    panic("iunlock");
    80003ee4:	00005517          	auipc	a0,0x5
    80003ee8:	83c50513          	addi	a0,a0,-1988 # 80008720 <syscalls+0x1b0>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	652080e7          	jalr	1618(ra) # 8000053e <panic>

0000000080003ef4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef4:	7179                	addi	sp,sp,-48
    80003ef6:	f406                	sd	ra,40(sp)
    80003ef8:	f022                	sd	s0,32(sp)
    80003efa:	ec26                	sd	s1,24(sp)
    80003efc:	e84a                	sd	s2,16(sp)
    80003efe:	e44e                	sd	s3,8(sp)
    80003f00:	e052                	sd	s4,0(sp)
    80003f02:	1800                	addi	s0,sp,48
    80003f04:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f06:	05050493          	addi	s1,a0,80
    80003f0a:	08050913          	addi	s2,a0,128
    80003f0e:	a021                	j	80003f16 <itrunc+0x22>
    80003f10:	0491                	addi	s1,s1,4
    80003f12:	01248d63          	beq	s1,s2,80003f2c <itrunc+0x38>
    if(ip->addrs[i]){
    80003f16:	408c                	lw	a1,0(s1)
    80003f18:	dde5                	beqz	a1,80003f10 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f1a:	0009a503          	lw	a0,0(s3)
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	90c080e7          	jalr	-1780(ra) # 8000382a <bfree>
      ip->addrs[i] = 0;
    80003f26:	0004a023          	sw	zero,0(s1)
    80003f2a:	b7dd                	j	80003f10 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f2c:	0809a583          	lw	a1,128(s3)
    80003f30:	e185                	bnez	a1,80003f50 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f32:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f36:	854e                	mv	a0,s3
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	de4080e7          	jalr	-540(ra) # 80003d1c <iupdate>
}
    80003f40:	70a2                	ld	ra,40(sp)
    80003f42:	7402                	ld	s0,32(sp)
    80003f44:	64e2                	ld	s1,24(sp)
    80003f46:	6942                	ld	s2,16(sp)
    80003f48:	69a2                	ld	s3,8(sp)
    80003f4a:	6a02                	ld	s4,0(sp)
    80003f4c:	6145                	addi	sp,sp,48
    80003f4e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f50:	0009a503          	lw	a0,0(s3)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	690080e7          	jalr	1680(ra) # 800035e4 <bread>
    80003f5c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f5e:	05850493          	addi	s1,a0,88
    80003f62:	45850913          	addi	s2,a0,1112
    80003f66:	a811                	j	80003f7a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f68:	0009a503          	lw	a0,0(s3)
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	8be080e7          	jalr	-1858(ra) # 8000382a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f74:	0491                	addi	s1,s1,4
    80003f76:	01248563          	beq	s1,s2,80003f80 <itrunc+0x8c>
      if(a[j])
    80003f7a:	408c                	lw	a1,0(s1)
    80003f7c:	dde5                	beqz	a1,80003f74 <itrunc+0x80>
    80003f7e:	b7ed                	j	80003f68 <itrunc+0x74>
    brelse(bp);
    80003f80:	8552                	mv	a0,s4
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	792080e7          	jalr	1938(ra) # 80003714 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f8a:	0809a583          	lw	a1,128(s3)
    80003f8e:	0009a503          	lw	a0,0(s3)
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	898080e7          	jalr	-1896(ra) # 8000382a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f9a:	0809a023          	sw	zero,128(s3)
    80003f9e:	bf51                	j	80003f32 <itrunc+0x3e>

0000000080003fa0 <iput>:
{
    80003fa0:	1101                	addi	sp,sp,-32
    80003fa2:	ec06                	sd	ra,24(sp)
    80003fa4:	e822                	sd	s0,16(sp)
    80003fa6:	e426                	sd	s1,8(sp)
    80003fa8:	e04a                	sd	s2,0(sp)
    80003faa:	1000                	addi	s0,sp,32
    80003fac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fae:	0001c517          	auipc	a0,0x1c
    80003fb2:	39a50513          	addi	a0,a0,922 # 80020348 <itable>
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	c2e080e7          	jalr	-978(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fbe:	4498                	lw	a4,8(s1)
    80003fc0:	4785                	li	a5,1
    80003fc2:	02f70363          	beq	a4,a5,80003fe8 <iput+0x48>
  ip->ref--;
    80003fc6:	449c                	lw	a5,8(s1)
    80003fc8:	37fd                	addiw	a5,a5,-1
    80003fca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fcc:	0001c517          	auipc	a0,0x1c
    80003fd0:	37c50513          	addi	a0,a0,892 # 80020348 <itable>
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	cc4080e7          	jalr	-828(ra) # 80000c98 <release>
}
    80003fdc:	60e2                	ld	ra,24(sp)
    80003fde:	6442                	ld	s0,16(sp)
    80003fe0:	64a2                	ld	s1,8(sp)
    80003fe2:	6902                	ld	s2,0(sp)
    80003fe4:	6105                	addi	sp,sp,32
    80003fe6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fe8:	40bc                	lw	a5,64(s1)
    80003fea:	dff1                	beqz	a5,80003fc6 <iput+0x26>
    80003fec:	04a49783          	lh	a5,74(s1)
    80003ff0:	fbf9                	bnez	a5,80003fc6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff2:	01048913          	addi	s2,s1,16
    80003ff6:	854a                	mv	a0,s2
    80003ff8:	00001097          	auipc	ra,0x1
    80003ffc:	ab8080e7          	jalr	-1352(ra) # 80004ab0 <acquiresleep>
    release(&itable.lock);
    80004000:	0001c517          	auipc	a0,0x1c
    80004004:	34850513          	addi	a0,a0,840 # 80020348 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	c90080e7          	jalr	-880(ra) # 80000c98 <release>
    itrunc(ip);
    80004010:	8526                	mv	a0,s1
    80004012:	00000097          	auipc	ra,0x0
    80004016:	ee2080e7          	jalr	-286(ra) # 80003ef4 <itrunc>
    ip->type = 0;
    8000401a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000401e:	8526                	mv	a0,s1
    80004020:	00000097          	auipc	ra,0x0
    80004024:	cfc080e7          	jalr	-772(ra) # 80003d1c <iupdate>
    ip->valid = 0;
    80004028:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000402c:	854a                	mv	a0,s2
    8000402e:	00001097          	auipc	ra,0x1
    80004032:	ad8080e7          	jalr	-1320(ra) # 80004b06 <releasesleep>
    acquire(&itable.lock);
    80004036:	0001c517          	auipc	a0,0x1c
    8000403a:	31250513          	addi	a0,a0,786 # 80020348 <itable>
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	ba6080e7          	jalr	-1114(ra) # 80000be4 <acquire>
    80004046:	b741                	j	80003fc6 <iput+0x26>

0000000080004048 <iunlockput>:
{
    80004048:	1101                	addi	sp,sp,-32
    8000404a:	ec06                	sd	ra,24(sp)
    8000404c:	e822                	sd	s0,16(sp)
    8000404e:	e426                	sd	s1,8(sp)
    80004050:	1000                	addi	s0,sp,32
    80004052:	84aa                	mv	s1,a0
  iunlock(ip);
    80004054:	00000097          	auipc	ra,0x0
    80004058:	e54080e7          	jalr	-428(ra) # 80003ea8 <iunlock>
  iput(ip);
    8000405c:	8526                	mv	a0,s1
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	f42080e7          	jalr	-190(ra) # 80003fa0 <iput>
}
    80004066:	60e2                	ld	ra,24(sp)
    80004068:	6442                	ld	s0,16(sp)
    8000406a:	64a2                	ld	s1,8(sp)
    8000406c:	6105                	addi	sp,sp,32
    8000406e:	8082                	ret

0000000080004070 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004070:	1141                	addi	sp,sp,-16
    80004072:	e422                	sd	s0,8(sp)
    80004074:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004076:	411c                	lw	a5,0(a0)
    80004078:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000407a:	415c                	lw	a5,4(a0)
    8000407c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000407e:	04451783          	lh	a5,68(a0)
    80004082:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004086:	04a51783          	lh	a5,74(a0)
    8000408a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000408e:	04c56783          	lwu	a5,76(a0)
    80004092:	e99c                	sd	a5,16(a1)
}
    80004094:	6422                	ld	s0,8(sp)
    80004096:	0141                	addi	sp,sp,16
    80004098:	8082                	ret

000000008000409a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409a:	457c                	lw	a5,76(a0)
    8000409c:	0ed7e963          	bltu	a5,a3,8000418e <readi+0xf4>
{
    800040a0:	7159                	addi	sp,sp,-112
    800040a2:	f486                	sd	ra,104(sp)
    800040a4:	f0a2                	sd	s0,96(sp)
    800040a6:	eca6                	sd	s1,88(sp)
    800040a8:	e8ca                	sd	s2,80(sp)
    800040aa:	e4ce                	sd	s3,72(sp)
    800040ac:	e0d2                	sd	s4,64(sp)
    800040ae:	fc56                	sd	s5,56(sp)
    800040b0:	f85a                	sd	s6,48(sp)
    800040b2:	f45e                	sd	s7,40(sp)
    800040b4:	f062                	sd	s8,32(sp)
    800040b6:	ec66                	sd	s9,24(sp)
    800040b8:	e86a                	sd	s10,16(sp)
    800040ba:	e46e                	sd	s11,8(sp)
    800040bc:	1880                	addi	s0,sp,112
    800040be:	8baa                	mv	s7,a0
    800040c0:	8c2e                	mv	s8,a1
    800040c2:	8ab2                	mv	s5,a2
    800040c4:	84b6                	mv	s1,a3
    800040c6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c8:	9f35                	addw	a4,a4,a3
    return 0;
    800040ca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040cc:	0ad76063          	bltu	a4,a3,8000416c <readi+0xd2>
  if(off + n > ip->size)
    800040d0:	00e7f463          	bgeu	a5,a4,800040d8 <readi+0x3e>
    n = ip->size - off;
    800040d4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d8:	0a0b0963          	beqz	s6,8000418a <readi+0xf0>
    800040dc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040de:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e2:	5cfd                	li	s9,-1
    800040e4:	a82d                	j	8000411e <readi+0x84>
    800040e6:	020a1d93          	slli	s11,s4,0x20
    800040ea:	020ddd93          	srli	s11,s11,0x20
    800040ee:	05890613          	addi	a2,s2,88
    800040f2:	86ee                	mv	a3,s11
    800040f4:	963a                	add	a2,a2,a4
    800040f6:	85d6                	mv	a1,s5
    800040f8:	8562                	mv	a0,s8
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	5f4080e7          	jalr	1524(ra) # 800026ee <either_copyout>
    80004102:	05950d63          	beq	a0,s9,8000415c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004106:	854a                	mv	a0,s2
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	60c080e7          	jalr	1548(ra) # 80003714 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004110:	013a09bb          	addw	s3,s4,s3
    80004114:	009a04bb          	addw	s1,s4,s1
    80004118:	9aee                	add	s5,s5,s11
    8000411a:	0569f763          	bgeu	s3,s6,80004168 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000411e:	000ba903          	lw	s2,0(s7)
    80004122:	00a4d59b          	srliw	a1,s1,0xa
    80004126:	855e                	mv	a0,s7
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	8b0080e7          	jalr	-1872(ra) # 800039d8 <bmap>
    80004130:	0005059b          	sext.w	a1,a0
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	4ae080e7          	jalr	1198(ra) # 800035e4 <bread>
    8000413e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004140:	3ff4f713          	andi	a4,s1,1023
    80004144:	40ed07bb          	subw	a5,s10,a4
    80004148:	413b06bb          	subw	a3,s6,s3
    8000414c:	8a3e                	mv	s4,a5
    8000414e:	2781                	sext.w	a5,a5
    80004150:	0006861b          	sext.w	a2,a3
    80004154:	f8f679e3          	bgeu	a2,a5,800040e6 <readi+0x4c>
    80004158:	8a36                	mv	s4,a3
    8000415a:	b771                	j	800040e6 <readi+0x4c>
      brelse(bp);
    8000415c:	854a                	mv	a0,s2
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	5b6080e7          	jalr	1462(ra) # 80003714 <brelse>
      tot = -1;
    80004166:	59fd                	li	s3,-1
  }
  return tot;
    80004168:	0009851b          	sext.w	a0,s3
}
    8000416c:	70a6                	ld	ra,104(sp)
    8000416e:	7406                	ld	s0,96(sp)
    80004170:	64e6                	ld	s1,88(sp)
    80004172:	6946                	ld	s2,80(sp)
    80004174:	69a6                	ld	s3,72(sp)
    80004176:	6a06                	ld	s4,64(sp)
    80004178:	7ae2                	ld	s5,56(sp)
    8000417a:	7b42                	ld	s6,48(sp)
    8000417c:	7ba2                	ld	s7,40(sp)
    8000417e:	7c02                	ld	s8,32(sp)
    80004180:	6ce2                	ld	s9,24(sp)
    80004182:	6d42                	ld	s10,16(sp)
    80004184:	6da2                	ld	s11,8(sp)
    80004186:	6165                	addi	sp,sp,112
    80004188:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000418a:	89da                	mv	s3,s6
    8000418c:	bff1                	j	80004168 <readi+0xce>
    return 0;
    8000418e:	4501                	li	a0,0
}
    80004190:	8082                	ret

0000000080004192 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004192:	457c                	lw	a5,76(a0)
    80004194:	10d7e863          	bltu	a5,a3,800042a4 <writei+0x112>
{
    80004198:	7159                	addi	sp,sp,-112
    8000419a:	f486                	sd	ra,104(sp)
    8000419c:	f0a2                	sd	s0,96(sp)
    8000419e:	eca6                	sd	s1,88(sp)
    800041a0:	e8ca                	sd	s2,80(sp)
    800041a2:	e4ce                	sd	s3,72(sp)
    800041a4:	e0d2                	sd	s4,64(sp)
    800041a6:	fc56                	sd	s5,56(sp)
    800041a8:	f85a                	sd	s6,48(sp)
    800041aa:	f45e                	sd	s7,40(sp)
    800041ac:	f062                	sd	s8,32(sp)
    800041ae:	ec66                	sd	s9,24(sp)
    800041b0:	e86a                	sd	s10,16(sp)
    800041b2:	e46e                	sd	s11,8(sp)
    800041b4:	1880                	addi	s0,sp,112
    800041b6:	8b2a                	mv	s6,a0
    800041b8:	8c2e                	mv	s8,a1
    800041ba:	8ab2                	mv	s5,a2
    800041bc:	8936                	mv	s2,a3
    800041be:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041c0:	00e687bb          	addw	a5,a3,a4
    800041c4:	0ed7e263          	bltu	a5,a3,800042a8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041c8:	00043737          	lui	a4,0x43
    800041cc:	0ef76063          	bltu	a4,a5,800042ac <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d0:	0c0b8863          	beqz	s7,800042a0 <writei+0x10e>
    800041d4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041d6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041da:	5cfd                	li	s9,-1
    800041dc:	a091                	j	80004220 <writei+0x8e>
    800041de:	02099d93          	slli	s11,s3,0x20
    800041e2:	020ddd93          	srli	s11,s11,0x20
    800041e6:	05848513          	addi	a0,s1,88
    800041ea:	86ee                	mv	a3,s11
    800041ec:	8656                	mv	a2,s5
    800041ee:	85e2                	mv	a1,s8
    800041f0:	953a                	add	a0,a0,a4
    800041f2:	ffffe097          	auipc	ra,0xffffe
    800041f6:	552080e7          	jalr	1362(ra) # 80002744 <either_copyin>
    800041fa:	07950263          	beq	a0,s9,8000425e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041fe:	8526                	mv	a0,s1
    80004200:	00000097          	auipc	ra,0x0
    80004204:	790080e7          	jalr	1936(ra) # 80004990 <log_write>
    brelse(bp);
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	50a080e7          	jalr	1290(ra) # 80003714 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004212:	01498a3b          	addw	s4,s3,s4
    80004216:	0129893b          	addw	s2,s3,s2
    8000421a:	9aee                	add	s5,s5,s11
    8000421c:	057a7663          	bgeu	s4,s7,80004268 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004220:	000b2483          	lw	s1,0(s6)
    80004224:	00a9559b          	srliw	a1,s2,0xa
    80004228:	855a                	mv	a0,s6
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	7ae080e7          	jalr	1966(ra) # 800039d8 <bmap>
    80004232:	0005059b          	sext.w	a1,a0
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	3ac080e7          	jalr	940(ra) # 800035e4 <bread>
    80004240:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004242:	3ff97713          	andi	a4,s2,1023
    80004246:	40ed07bb          	subw	a5,s10,a4
    8000424a:	414b86bb          	subw	a3,s7,s4
    8000424e:	89be                	mv	s3,a5
    80004250:	2781                	sext.w	a5,a5
    80004252:	0006861b          	sext.w	a2,a3
    80004256:	f8f674e3          	bgeu	a2,a5,800041de <writei+0x4c>
    8000425a:	89b6                	mv	s3,a3
    8000425c:	b749                	j	800041de <writei+0x4c>
      brelse(bp);
    8000425e:	8526                	mv	a0,s1
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	4b4080e7          	jalr	1204(ra) # 80003714 <brelse>
  }

  if(off > ip->size)
    80004268:	04cb2783          	lw	a5,76(s6)
    8000426c:	0127f463          	bgeu	a5,s2,80004274 <writei+0xe2>
    ip->size = off;
    80004270:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004274:	855a                	mv	a0,s6
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	aa6080e7          	jalr	-1370(ra) # 80003d1c <iupdate>

  return tot;
    8000427e:	000a051b          	sext.w	a0,s4
}
    80004282:	70a6                	ld	ra,104(sp)
    80004284:	7406                	ld	s0,96(sp)
    80004286:	64e6                	ld	s1,88(sp)
    80004288:	6946                	ld	s2,80(sp)
    8000428a:	69a6                	ld	s3,72(sp)
    8000428c:	6a06                	ld	s4,64(sp)
    8000428e:	7ae2                	ld	s5,56(sp)
    80004290:	7b42                	ld	s6,48(sp)
    80004292:	7ba2                	ld	s7,40(sp)
    80004294:	7c02                	ld	s8,32(sp)
    80004296:	6ce2                	ld	s9,24(sp)
    80004298:	6d42                	ld	s10,16(sp)
    8000429a:	6da2                	ld	s11,8(sp)
    8000429c:	6165                	addi	sp,sp,112
    8000429e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a0:	8a5e                	mv	s4,s7
    800042a2:	bfc9                	j	80004274 <writei+0xe2>
    return -1;
    800042a4:	557d                	li	a0,-1
}
    800042a6:	8082                	ret
    return -1;
    800042a8:	557d                	li	a0,-1
    800042aa:	bfe1                	j	80004282 <writei+0xf0>
    return -1;
    800042ac:	557d                	li	a0,-1
    800042ae:	bfd1                	j	80004282 <writei+0xf0>

00000000800042b0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042b0:	1141                	addi	sp,sp,-16
    800042b2:	e406                	sd	ra,8(sp)
    800042b4:	e022                	sd	s0,0(sp)
    800042b6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042b8:	4639                	li	a2,14
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	afe080e7          	jalr	-1282(ra) # 80000db8 <strncmp>
}
    800042c2:	60a2                	ld	ra,8(sp)
    800042c4:	6402                	ld	s0,0(sp)
    800042c6:	0141                	addi	sp,sp,16
    800042c8:	8082                	ret

00000000800042ca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042ca:	7139                	addi	sp,sp,-64
    800042cc:	fc06                	sd	ra,56(sp)
    800042ce:	f822                	sd	s0,48(sp)
    800042d0:	f426                	sd	s1,40(sp)
    800042d2:	f04a                	sd	s2,32(sp)
    800042d4:	ec4e                	sd	s3,24(sp)
    800042d6:	e852                	sd	s4,16(sp)
    800042d8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042da:	04451703          	lh	a4,68(a0)
    800042de:	4785                	li	a5,1
    800042e0:	00f71a63          	bne	a4,a5,800042f4 <dirlookup+0x2a>
    800042e4:	892a                	mv	s2,a0
    800042e6:	89ae                	mv	s3,a1
    800042e8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ea:	457c                	lw	a5,76(a0)
    800042ec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042ee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f0:	e79d                	bnez	a5,8000431e <dirlookup+0x54>
    800042f2:	a8a5                	j	8000436a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042f4:	00004517          	auipc	a0,0x4
    800042f8:	43450513          	addi	a0,a0,1076 # 80008728 <syscalls+0x1b8>
    800042fc:	ffffc097          	auipc	ra,0xffffc
    80004300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004304:	00004517          	auipc	a0,0x4
    80004308:	43c50513          	addi	a0,a0,1084 # 80008740 <syscalls+0x1d0>
    8000430c:	ffffc097          	auipc	ra,0xffffc
    80004310:	232080e7          	jalr	562(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004314:	24c1                	addiw	s1,s1,16
    80004316:	04c92783          	lw	a5,76(s2)
    8000431a:	04f4f763          	bgeu	s1,a5,80004368 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000431e:	4741                	li	a4,16
    80004320:	86a6                	mv	a3,s1
    80004322:	fc040613          	addi	a2,s0,-64
    80004326:	4581                	li	a1,0
    80004328:	854a                	mv	a0,s2
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	d70080e7          	jalr	-656(ra) # 8000409a <readi>
    80004332:	47c1                	li	a5,16
    80004334:	fcf518e3          	bne	a0,a5,80004304 <dirlookup+0x3a>
    if(de.inum == 0)
    80004338:	fc045783          	lhu	a5,-64(s0)
    8000433c:	dfe1                	beqz	a5,80004314 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000433e:	fc240593          	addi	a1,s0,-62
    80004342:	854e                	mv	a0,s3
    80004344:	00000097          	auipc	ra,0x0
    80004348:	f6c080e7          	jalr	-148(ra) # 800042b0 <namecmp>
    8000434c:	f561                	bnez	a0,80004314 <dirlookup+0x4a>
      if(poff)
    8000434e:	000a0463          	beqz	s4,80004356 <dirlookup+0x8c>
        *poff = off;
    80004352:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004356:	fc045583          	lhu	a1,-64(s0)
    8000435a:	00092503          	lw	a0,0(s2)
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	754080e7          	jalr	1876(ra) # 80003ab2 <iget>
    80004366:	a011                	j	8000436a <dirlookup+0xa0>
  return 0;
    80004368:	4501                	li	a0,0
}
    8000436a:	70e2                	ld	ra,56(sp)
    8000436c:	7442                	ld	s0,48(sp)
    8000436e:	74a2                	ld	s1,40(sp)
    80004370:	7902                	ld	s2,32(sp)
    80004372:	69e2                	ld	s3,24(sp)
    80004374:	6a42                	ld	s4,16(sp)
    80004376:	6121                	addi	sp,sp,64
    80004378:	8082                	ret

000000008000437a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000437a:	711d                	addi	sp,sp,-96
    8000437c:	ec86                	sd	ra,88(sp)
    8000437e:	e8a2                	sd	s0,80(sp)
    80004380:	e4a6                	sd	s1,72(sp)
    80004382:	e0ca                	sd	s2,64(sp)
    80004384:	fc4e                	sd	s3,56(sp)
    80004386:	f852                	sd	s4,48(sp)
    80004388:	f456                	sd	s5,40(sp)
    8000438a:	f05a                	sd	s6,32(sp)
    8000438c:	ec5e                	sd	s7,24(sp)
    8000438e:	e862                	sd	s8,16(sp)
    80004390:	e466                	sd	s9,8(sp)
    80004392:	1080                	addi	s0,sp,96
    80004394:	84aa                	mv	s1,a0
    80004396:	8b2e                	mv	s6,a1
    80004398:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000439a:	00054703          	lbu	a4,0(a0)
    8000439e:	02f00793          	li	a5,47
    800043a2:	02f70363          	beq	a4,a5,800043c8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043a6:	ffffe097          	auipc	ra,0xffffe
    800043aa:	a90080e7          	jalr	-1392(ra) # 80001e36 <myproc>
    800043ae:	15053503          	ld	a0,336(a0)
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	9f6080e7          	jalr	-1546(ra) # 80003da8 <idup>
    800043ba:	89aa                	mv	s3,a0
  while(*path == '/')
    800043bc:	02f00913          	li	s2,47
  len = path - s;
    800043c0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043c2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043c4:	4c05                	li	s8,1
    800043c6:	a865                	j	8000447e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043c8:	4585                	li	a1,1
    800043ca:	4505                	li	a0,1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	6e6080e7          	jalr	1766(ra) # 80003ab2 <iget>
    800043d4:	89aa                	mv	s3,a0
    800043d6:	b7dd                	j	800043bc <namex+0x42>
      iunlockput(ip);
    800043d8:	854e                	mv	a0,s3
    800043da:	00000097          	auipc	ra,0x0
    800043de:	c6e080e7          	jalr	-914(ra) # 80004048 <iunlockput>
      return 0;
    800043e2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043e4:	854e                	mv	a0,s3
    800043e6:	60e6                	ld	ra,88(sp)
    800043e8:	6446                	ld	s0,80(sp)
    800043ea:	64a6                	ld	s1,72(sp)
    800043ec:	6906                	ld	s2,64(sp)
    800043ee:	79e2                	ld	s3,56(sp)
    800043f0:	7a42                	ld	s4,48(sp)
    800043f2:	7aa2                	ld	s5,40(sp)
    800043f4:	7b02                	ld	s6,32(sp)
    800043f6:	6be2                	ld	s7,24(sp)
    800043f8:	6c42                	ld	s8,16(sp)
    800043fa:	6ca2                	ld	s9,8(sp)
    800043fc:	6125                	addi	sp,sp,96
    800043fe:	8082                	ret
      iunlock(ip);
    80004400:	854e                	mv	a0,s3
    80004402:	00000097          	auipc	ra,0x0
    80004406:	aa6080e7          	jalr	-1370(ra) # 80003ea8 <iunlock>
      return ip;
    8000440a:	bfe9                	j	800043e4 <namex+0x6a>
      iunlockput(ip);
    8000440c:	854e                	mv	a0,s3
    8000440e:	00000097          	auipc	ra,0x0
    80004412:	c3a080e7          	jalr	-966(ra) # 80004048 <iunlockput>
      return 0;
    80004416:	89d2                	mv	s3,s4
    80004418:	b7f1                	j	800043e4 <namex+0x6a>
  len = path - s;
    8000441a:	40b48633          	sub	a2,s1,a1
    8000441e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004422:	094cd463          	bge	s9,s4,800044aa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004426:	4639                	li	a2,14
    80004428:	8556                	mv	a0,s5
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	916080e7          	jalr	-1770(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004432:	0004c783          	lbu	a5,0(s1)
    80004436:	01279763          	bne	a5,s2,80004444 <namex+0xca>
    path++;
    8000443a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000443c:	0004c783          	lbu	a5,0(s1)
    80004440:	ff278de3          	beq	a5,s2,8000443a <namex+0xc0>
    ilock(ip);
    80004444:	854e                	mv	a0,s3
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	9a0080e7          	jalr	-1632(ra) # 80003de6 <ilock>
    if(ip->type != T_DIR){
    8000444e:	04499783          	lh	a5,68(s3)
    80004452:	f98793e3          	bne	a5,s8,800043d8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004456:	000b0563          	beqz	s6,80004460 <namex+0xe6>
    8000445a:	0004c783          	lbu	a5,0(s1)
    8000445e:	d3cd                	beqz	a5,80004400 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004460:	865e                	mv	a2,s7
    80004462:	85d6                	mv	a1,s5
    80004464:	854e                	mv	a0,s3
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	e64080e7          	jalr	-412(ra) # 800042ca <dirlookup>
    8000446e:	8a2a                	mv	s4,a0
    80004470:	dd51                	beqz	a0,8000440c <namex+0x92>
    iunlockput(ip);
    80004472:	854e                	mv	a0,s3
    80004474:	00000097          	auipc	ra,0x0
    80004478:	bd4080e7          	jalr	-1068(ra) # 80004048 <iunlockput>
    ip = next;
    8000447c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000447e:	0004c783          	lbu	a5,0(s1)
    80004482:	05279763          	bne	a5,s2,800044d0 <namex+0x156>
    path++;
    80004486:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004488:	0004c783          	lbu	a5,0(s1)
    8000448c:	ff278de3          	beq	a5,s2,80004486 <namex+0x10c>
  if(*path == 0)
    80004490:	c79d                	beqz	a5,800044be <namex+0x144>
    path++;
    80004492:	85a6                	mv	a1,s1
  len = path - s;
    80004494:	8a5e                	mv	s4,s7
    80004496:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004498:	01278963          	beq	a5,s2,800044aa <namex+0x130>
    8000449c:	dfbd                	beqz	a5,8000441a <namex+0xa0>
    path++;
    8000449e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	ff279ce3          	bne	a5,s2,8000449c <namex+0x122>
    800044a8:	bf8d                	j	8000441a <namex+0xa0>
    memmove(name, s, len);
    800044aa:	2601                	sext.w	a2,a2
    800044ac:	8556                	mv	a0,s5
    800044ae:	ffffd097          	auipc	ra,0xffffd
    800044b2:	892080e7          	jalr	-1902(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044b6:	9a56                	add	s4,s4,s5
    800044b8:	000a0023          	sb	zero,0(s4)
    800044bc:	bf9d                	j	80004432 <namex+0xb8>
  if(nameiparent){
    800044be:	f20b03e3          	beqz	s6,800043e4 <namex+0x6a>
    iput(ip);
    800044c2:	854e                	mv	a0,s3
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	adc080e7          	jalr	-1316(ra) # 80003fa0 <iput>
    return 0;
    800044cc:	4981                	li	s3,0
    800044ce:	bf19                	j	800043e4 <namex+0x6a>
  if(*path == 0)
    800044d0:	d7fd                	beqz	a5,800044be <namex+0x144>
  while(*path != '/' && *path != 0)
    800044d2:	0004c783          	lbu	a5,0(s1)
    800044d6:	85a6                	mv	a1,s1
    800044d8:	b7d1                	j	8000449c <namex+0x122>

00000000800044da <dirlink>:
{
    800044da:	7139                	addi	sp,sp,-64
    800044dc:	fc06                	sd	ra,56(sp)
    800044de:	f822                	sd	s0,48(sp)
    800044e0:	f426                	sd	s1,40(sp)
    800044e2:	f04a                	sd	s2,32(sp)
    800044e4:	ec4e                	sd	s3,24(sp)
    800044e6:	e852                	sd	s4,16(sp)
    800044e8:	0080                	addi	s0,sp,64
    800044ea:	892a                	mv	s2,a0
    800044ec:	8a2e                	mv	s4,a1
    800044ee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044f0:	4601                	li	a2,0
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	dd8080e7          	jalr	-552(ra) # 800042ca <dirlookup>
    800044fa:	e93d                	bnez	a0,80004570 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fc:	04c92483          	lw	s1,76(s2)
    80004500:	c49d                	beqz	s1,8000452e <dirlink+0x54>
    80004502:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004504:	4741                	li	a4,16
    80004506:	86a6                	mv	a3,s1
    80004508:	fc040613          	addi	a2,s0,-64
    8000450c:	4581                	li	a1,0
    8000450e:	854a                	mv	a0,s2
    80004510:	00000097          	auipc	ra,0x0
    80004514:	b8a080e7          	jalr	-1142(ra) # 8000409a <readi>
    80004518:	47c1                	li	a5,16
    8000451a:	06f51163          	bne	a0,a5,8000457c <dirlink+0xa2>
    if(de.inum == 0)
    8000451e:	fc045783          	lhu	a5,-64(s0)
    80004522:	c791                	beqz	a5,8000452e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004524:	24c1                	addiw	s1,s1,16
    80004526:	04c92783          	lw	a5,76(s2)
    8000452a:	fcf4ede3          	bltu	s1,a5,80004504 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000452e:	4639                	li	a2,14
    80004530:	85d2                	mv	a1,s4
    80004532:	fc240513          	addi	a0,s0,-62
    80004536:	ffffd097          	auipc	ra,0xffffd
    8000453a:	8be080e7          	jalr	-1858(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000453e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004542:	4741                	li	a4,16
    80004544:	86a6                	mv	a3,s1
    80004546:	fc040613          	addi	a2,s0,-64
    8000454a:	4581                	li	a1,0
    8000454c:	854a                	mv	a0,s2
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	c44080e7          	jalr	-956(ra) # 80004192 <writei>
    80004556:	872a                	mv	a4,a0
    80004558:	47c1                	li	a5,16
  return 0;
    8000455a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000455c:	02f71863          	bne	a4,a5,8000458c <dirlink+0xb2>
}
    80004560:	70e2                	ld	ra,56(sp)
    80004562:	7442                	ld	s0,48(sp)
    80004564:	74a2                	ld	s1,40(sp)
    80004566:	7902                	ld	s2,32(sp)
    80004568:	69e2                	ld	s3,24(sp)
    8000456a:	6a42                	ld	s4,16(sp)
    8000456c:	6121                	addi	sp,sp,64
    8000456e:	8082                	ret
    iput(ip);
    80004570:	00000097          	auipc	ra,0x0
    80004574:	a30080e7          	jalr	-1488(ra) # 80003fa0 <iput>
    return -1;
    80004578:	557d                	li	a0,-1
    8000457a:	b7dd                	j	80004560 <dirlink+0x86>
      panic("dirlink read");
    8000457c:	00004517          	auipc	a0,0x4
    80004580:	1d450513          	addi	a0,a0,468 # 80008750 <syscalls+0x1e0>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	fba080e7          	jalr	-70(ra) # 8000053e <panic>
    panic("dirlink");
    8000458c:	00004517          	auipc	a0,0x4
    80004590:	2d450513          	addi	a0,a0,724 # 80008860 <syscalls+0x2f0>
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>

000000008000459c <namei>:

struct inode*
namei(char *path)
{
    8000459c:	1101                	addi	sp,sp,-32
    8000459e:	ec06                	sd	ra,24(sp)
    800045a0:	e822                	sd	s0,16(sp)
    800045a2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045a4:	fe040613          	addi	a2,s0,-32
    800045a8:	4581                	li	a1,0
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	dd0080e7          	jalr	-560(ra) # 8000437a <namex>
}
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045ba:	1141                	addi	sp,sp,-16
    800045bc:	e406                	sd	ra,8(sp)
    800045be:	e022                	sd	s0,0(sp)
    800045c0:	0800                	addi	s0,sp,16
    800045c2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045c4:	4585                	li	a1,1
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	db4080e7          	jalr	-588(ra) # 8000437a <namex>
}
    800045ce:	60a2                	ld	ra,8(sp)
    800045d0:	6402                	ld	s0,0(sp)
    800045d2:	0141                	addi	sp,sp,16
    800045d4:	8082                	ret

00000000800045d6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045d6:	1101                	addi	sp,sp,-32
    800045d8:	ec06                	sd	ra,24(sp)
    800045da:	e822                	sd	s0,16(sp)
    800045dc:	e426                	sd	s1,8(sp)
    800045de:	e04a                	sd	s2,0(sp)
    800045e0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045e2:	0001e917          	auipc	s2,0x1e
    800045e6:	80e90913          	addi	s2,s2,-2034 # 80021df0 <log>
    800045ea:	01892583          	lw	a1,24(s2)
    800045ee:	02892503          	lw	a0,40(s2)
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	ff2080e7          	jalr	-14(ra) # 800035e4 <bread>
    800045fa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045fc:	02c92683          	lw	a3,44(s2)
    80004600:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004602:	02d05763          	blez	a3,80004630 <write_head+0x5a>
    80004606:	0001e797          	auipc	a5,0x1e
    8000460a:	81a78793          	addi	a5,a5,-2022 # 80021e20 <log+0x30>
    8000460e:	05c50713          	addi	a4,a0,92
    80004612:	36fd                	addiw	a3,a3,-1
    80004614:	1682                	slli	a3,a3,0x20
    80004616:	9281                	srli	a3,a3,0x20
    80004618:	068a                	slli	a3,a3,0x2
    8000461a:	0001e617          	auipc	a2,0x1e
    8000461e:	80a60613          	addi	a2,a2,-2038 # 80021e24 <log+0x34>
    80004622:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004624:	4390                	lw	a2,0(a5)
    80004626:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004628:	0791                	addi	a5,a5,4
    8000462a:	0711                	addi	a4,a4,4
    8000462c:	fed79ce3          	bne	a5,a3,80004624 <write_head+0x4e>
  }
  bwrite(buf);
    80004630:	8526                	mv	a0,s1
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	0a4080e7          	jalr	164(ra) # 800036d6 <bwrite>
  brelse(buf);
    8000463a:	8526                	mv	a0,s1
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	0d8080e7          	jalr	216(ra) # 80003714 <brelse>
}
    80004644:	60e2                	ld	ra,24(sp)
    80004646:	6442                	ld	s0,16(sp)
    80004648:	64a2                	ld	s1,8(sp)
    8000464a:	6902                	ld	s2,0(sp)
    8000464c:	6105                	addi	sp,sp,32
    8000464e:	8082                	ret

0000000080004650 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004650:	0001d797          	auipc	a5,0x1d
    80004654:	7cc7a783          	lw	a5,1996(a5) # 80021e1c <log+0x2c>
    80004658:	0af05d63          	blez	a5,80004712 <install_trans+0xc2>
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	e05a                	sd	s6,0(sp)
    8000466e:	0080                	addi	s0,sp,64
    80004670:	8b2a                	mv	s6,a0
    80004672:	0001da97          	auipc	s5,0x1d
    80004676:	7aea8a93          	addi	s5,s5,1966 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000467c:	0001d997          	auipc	s3,0x1d
    80004680:	77498993          	addi	s3,s3,1908 # 80021df0 <log>
    80004684:	a035                	j	800046b0 <install_trans+0x60>
      bunpin(dbuf);
    80004686:	8526                	mv	a0,s1
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	166080e7          	jalr	358(ra) # 800037ee <bunpin>
    brelse(lbuf);
    80004690:	854a                	mv	a0,s2
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	082080e7          	jalr	130(ra) # 80003714 <brelse>
    brelse(dbuf);
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	078080e7          	jalr	120(ra) # 80003714 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a4:	2a05                	addiw	s4,s4,1
    800046a6:	0a91                	addi	s5,s5,4
    800046a8:	02c9a783          	lw	a5,44(s3)
    800046ac:	04fa5963          	bge	s4,a5,800046fe <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046b0:	0189a583          	lw	a1,24(s3)
    800046b4:	014585bb          	addw	a1,a1,s4
    800046b8:	2585                	addiw	a1,a1,1
    800046ba:	0289a503          	lw	a0,40(s3)
    800046be:	fffff097          	auipc	ra,0xfffff
    800046c2:	f26080e7          	jalr	-218(ra) # 800035e4 <bread>
    800046c6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046c8:	000aa583          	lw	a1,0(s5)
    800046cc:	0289a503          	lw	a0,40(s3)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	f14080e7          	jalr	-236(ra) # 800035e4 <bread>
    800046d8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046da:	40000613          	li	a2,1024
    800046de:	05890593          	addi	a1,s2,88
    800046e2:	05850513          	addi	a0,a0,88
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	65a080e7          	jalr	1626(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046ee:	8526                	mv	a0,s1
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	fe6080e7          	jalr	-26(ra) # 800036d6 <bwrite>
    if(recovering == 0)
    800046f8:	f80b1ce3          	bnez	s6,80004690 <install_trans+0x40>
    800046fc:	b769                	j	80004686 <install_trans+0x36>
}
    800046fe:	70e2                	ld	ra,56(sp)
    80004700:	7442                	ld	s0,48(sp)
    80004702:	74a2                	ld	s1,40(sp)
    80004704:	7902                	ld	s2,32(sp)
    80004706:	69e2                	ld	s3,24(sp)
    80004708:	6a42                	ld	s4,16(sp)
    8000470a:	6aa2                	ld	s5,8(sp)
    8000470c:	6b02                	ld	s6,0(sp)
    8000470e:	6121                	addi	sp,sp,64
    80004710:	8082                	ret
    80004712:	8082                	ret

0000000080004714 <initlog>:
{
    80004714:	7179                	addi	sp,sp,-48
    80004716:	f406                	sd	ra,40(sp)
    80004718:	f022                	sd	s0,32(sp)
    8000471a:	ec26                	sd	s1,24(sp)
    8000471c:	e84a                	sd	s2,16(sp)
    8000471e:	e44e                	sd	s3,8(sp)
    80004720:	1800                	addi	s0,sp,48
    80004722:	892a                	mv	s2,a0
    80004724:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004726:	0001d497          	auipc	s1,0x1d
    8000472a:	6ca48493          	addi	s1,s1,1738 # 80021df0 <log>
    8000472e:	00004597          	auipc	a1,0x4
    80004732:	03258593          	addi	a1,a1,50 # 80008760 <syscalls+0x1f0>
    80004736:	8526                	mv	a0,s1
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	41c080e7          	jalr	1052(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004740:	0149a583          	lw	a1,20(s3)
    80004744:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004746:	0109a783          	lw	a5,16(s3)
    8000474a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000474c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004750:	854a                	mv	a0,s2
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	e92080e7          	jalr	-366(ra) # 800035e4 <bread>
  log.lh.n = lh->n;
    8000475a:	4d3c                	lw	a5,88(a0)
    8000475c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000475e:	02f05563          	blez	a5,80004788 <initlog+0x74>
    80004762:	05c50713          	addi	a4,a0,92
    80004766:	0001d697          	auipc	a3,0x1d
    8000476a:	6ba68693          	addi	a3,a3,1722 # 80021e20 <log+0x30>
    8000476e:	37fd                	addiw	a5,a5,-1
    80004770:	1782                	slli	a5,a5,0x20
    80004772:	9381                	srli	a5,a5,0x20
    80004774:	078a                	slli	a5,a5,0x2
    80004776:	06050613          	addi	a2,a0,96
    8000477a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000477c:	4310                	lw	a2,0(a4)
    8000477e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004780:	0711                	addi	a4,a4,4
    80004782:	0691                	addi	a3,a3,4
    80004784:	fef71ce3          	bne	a4,a5,8000477c <initlog+0x68>
  brelse(buf);
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	f8c080e7          	jalr	-116(ra) # 80003714 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004790:	4505                	li	a0,1
    80004792:	00000097          	auipc	ra,0x0
    80004796:	ebe080e7          	jalr	-322(ra) # 80004650 <install_trans>
  log.lh.n = 0;
    8000479a:	0001d797          	auipc	a5,0x1d
    8000479e:	6807a123          	sw	zero,1666(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	e34080e7          	jalr	-460(ra) # 800045d6 <write_head>
}
    800047aa:	70a2                	ld	ra,40(sp)
    800047ac:	7402                	ld	s0,32(sp)
    800047ae:	64e2                	ld	s1,24(sp)
    800047b0:	6942                	ld	s2,16(sp)
    800047b2:	69a2                	ld	s3,8(sp)
    800047b4:	6145                	addi	sp,sp,48
    800047b6:	8082                	ret

00000000800047b8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047b8:	1101                	addi	sp,sp,-32
    800047ba:	ec06                	sd	ra,24(sp)
    800047bc:	e822                	sd	s0,16(sp)
    800047be:	e426                	sd	s1,8(sp)
    800047c0:	e04a                	sd	s2,0(sp)
    800047c2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047c4:	0001d517          	auipc	a0,0x1d
    800047c8:	62c50513          	addi	a0,a0,1580 # 80021df0 <log>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047d4:	0001d497          	auipc	s1,0x1d
    800047d8:	61c48493          	addi	s1,s1,1564 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047dc:	4979                	li	s2,30
    800047de:	a039                	j	800047ec <begin_op+0x34>
      sleep(&log, &log.lock);
    800047e0:	85a6                	mv	a1,s1
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffe097          	auipc	ra,0xffffe
    800047e8:	cfa080e7          	jalr	-774(ra) # 800024de <sleep>
    if(log.committing){
    800047ec:	50dc                	lw	a5,36(s1)
    800047ee:	fbed                	bnez	a5,800047e0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047f0:	509c                	lw	a5,32(s1)
    800047f2:	0017871b          	addiw	a4,a5,1
    800047f6:	0007069b          	sext.w	a3,a4
    800047fa:	0027179b          	slliw	a5,a4,0x2
    800047fe:	9fb9                	addw	a5,a5,a4
    80004800:	0017979b          	slliw	a5,a5,0x1
    80004804:	54d8                	lw	a4,44(s1)
    80004806:	9fb9                	addw	a5,a5,a4
    80004808:	00f95963          	bge	s2,a5,8000481a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000480c:	85a6                	mv	a1,s1
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffe097          	auipc	ra,0xffffe
    80004814:	cce080e7          	jalr	-818(ra) # 800024de <sleep>
    80004818:	bfd1                	j	800047ec <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000481a:	0001d517          	auipc	a0,0x1d
    8000481e:	5d650513          	addi	a0,a0,1494 # 80021df0 <log>
    80004822:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	474080e7          	jalr	1140(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6902                	ld	s2,0(sp)
    80004834:	6105                	addi	sp,sp,32
    80004836:	8082                	ret

0000000080004838 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004838:	7139                	addi	sp,sp,-64
    8000483a:	fc06                	sd	ra,56(sp)
    8000483c:	f822                	sd	s0,48(sp)
    8000483e:	f426                	sd	s1,40(sp)
    80004840:	f04a                	sd	s2,32(sp)
    80004842:	ec4e                	sd	s3,24(sp)
    80004844:	e852                	sd	s4,16(sp)
    80004846:	e456                	sd	s5,8(sp)
    80004848:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000484a:	0001d497          	auipc	s1,0x1d
    8000484e:	5a648493          	addi	s1,s1,1446 # 80021df0 <log>
    80004852:	8526                	mv	a0,s1
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	390080e7          	jalr	912(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000485c:	509c                	lw	a5,32(s1)
    8000485e:	37fd                	addiw	a5,a5,-1
    80004860:	0007891b          	sext.w	s2,a5
    80004864:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004866:	50dc                	lw	a5,36(s1)
    80004868:	efb9                	bnez	a5,800048c6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000486a:	06091663          	bnez	s2,800048d6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000486e:	0001d497          	auipc	s1,0x1d
    80004872:	58248493          	addi	s1,s1,1410 # 80021df0 <log>
    80004876:	4785                	li	a5,1
    80004878:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000487a:	8526                	mv	a0,s1
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004884:	54dc                	lw	a5,44(s1)
    80004886:	06f04763          	bgtz	a5,800048f4 <end_op+0xbc>
    acquire(&log.lock);
    8000488a:	0001d497          	auipc	s1,0x1d
    8000488e:	56648493          	addi	s1,s1,1382 # 80021df0 <log>
    80004892:	8526                	mv	a0,s1
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	350080e7          	jalr	848(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000489c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffe097          	auipc	ra,0xffffe
    800048a6:	22a080e7          	jalr	554(ra) # 80002acc <wakeup>
    release(&log.lock);
    800048aa:	8526                	mv	a0,s1
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	3ec080e7          	jalr	1004(ra) # 80000c98 <release>
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6aa2                	ld	s5,8(sp)
    800048c2:	6121                	addi	sp,sp,64
    800048c4:	8082                	ret
    panic("log.committing");
    800048c6:	00004517          	auipc	a0,0x4
    800048ca:	ea250513          	addi	a0,a0,-350 # 80008768 <syscalls+0x1f8>
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	c70080e7          	jalr	-912(ra) # 8000053e <panic>
    wakeup(&log);
    800048d6:	0001d497          	auipc	s1,0x1d
    800048da:	51a48493          	addi	s1,s1,1306 # 80021df0 <log>
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffe097          	auipc	ra,0xffffe
    800048e4:	1ec080e7          	jalr	492(ra) # 80002acc <wakeup>
  release(&log.lock);
    800048e8:	8526                	mv	a0,s1
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
  if(do_commit){
    800048f2:	b7c9                	j	800048b4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f4:	0001da97          	auipc	s5,0x1d
    800048f8:	52ca8a93          	addi	s5,s5,1324 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048fc:	0001da17          	auipc	s4,0x1d
    80004900:	4f4a0a13          	addi	s4,s4,1268 # 80021df0 <log>
    80004904:	018a2583          	lw	a1,24(s4)
    80004908:	012585bb          	addw	a1,a1,s2
    8000490c:	2585                	addiw	a1,a1,1
    8000490e:	028a2503          	lw	a0,40(s4)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	cd2080e7          	jalr	-814(ra) # 800035e4 <bread>
    8000491a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000491c:	000aa583          	lw	a1,0(s5)
    80004920:	028a2503          	lw	a0,40(s4)
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	cc0080e7          	jalr	-832(ra) # 800035e4 <bread>
    8000492c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000492e:	40000613          	li	a2,1024
    80004932:	05850593          	addi	a1,a0,88
    80004936:	05848513          	addi	a0,s1,88
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	406080e7          	jalr	1030(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004942:	8526                	mv	a0,s1
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	d92080e7          	jalr	-622(ra) # 800036d6 <bwrite>
    brelse(from);
    8000494c:	854e                	mv	a0,s3
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	dc6080e7          	jalr	-570(ra) # 80003714 <brelse>
    brelse(to);
    80004956:	8526                	mv	a0,s1
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	dbc080e7          	jalr	-580(ra) # 80003714 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004960:	2905                	addiw	s2,s2,1
    80004962:	0a91                	addi	s5,s5,4
    80004964:	02ca2783          	lw	a5,44(s4)
    80004968:	f8f94ee3          	blt	s2,a5,80004904 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	c6a080e7          	jalr	-918(ra) # 800045d6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004974:	4501                	li	a0,0
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	cda080e7          	jalr	-806(ra) # 80004650 <install_trans>
    log.lh.n = 0;
    8000497e:	0001d797          	auipc	a5,0x1d
    80004982:	4807af23          	sw	zero,1182(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004986:	00000097          	auipc	ra,0x0
    8000498a:	c50080e7          	jalr	-944(ra) # 800045d6 <write_head>
    8000498e:	bdf5                	j	8000488a <end_op+0x52>

0000000080004990 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004990:	1101                	addi	sp,sp,-32
    80004992:	ec06                	sd	ra,24(sp)
    80004994:	e822                	sd	s0,16(sp)
    80004996:	e426                	sd	s1,8(sp)
    80004998:	e04a                	sd	s2,0(sp)
    8000499a:	1000                	addi	s0,sp,32
    8000499c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000499e:	0001d917          	auipc	s2,0x1d
    800049a2:	45290913          	addi	s2,s2,1106 # 80021df0 <log>
    800049a6:	854a                	mv	a0,s2
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	23c080e7          	jalr	572(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049b0:	02c92603          	lw	a2,44(s2)
    800049b4:	47f5                	li	a5,29
    800049b6:	06c7c563          	blt	a5,a2,80004a20 <log_write+0x90>
    800049ba:	0001d797          	auipc	a5,0x1d
    800049be:	4527a783          	lw	a5,1106(a5) # 80021e0c <log+0x1c>
    800049c2:	37fd                	addiw	a5,a5,-1
    800049c4:	04f65e63          	bge	a2,a5,80004a20 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049c8:	0001d797          	auipc	a5,0x1d
    800049cc:	4487a783          	lw	a5,1096(a5) # 80021e10 <log+0x20>
    800049d0:	06f05063          	blez	a5,80004a30 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049d4:	4781                	li	a5,0
    800049d6:	06c05563          	blez	a2,80004a40 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049da:	44cc                	lw	a1,12(s1)
    800049dc:	0001d717          	auipc	a4,0x1d
    800049e0:	44470713          	addi	a4,a4,1092 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049e4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049e6:	4314                	lw	a3,0(a4)
    800049e8:	04b68c63          	beq	a3,a1,80004a40 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ec:	2785                	addiw	a5,a5,1
    800049ee:	0711                	addi	a4,a4,4
    800049f0:	fef61be3          	bne	a2,a5,800049e6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049f4:	0621                	addi	a2,a2,8
    800049f6:	060a                	slli	a2,a2,0x2
    800049f8:	0001d797          	auipc	a5,0x1d
    800049fc:	3f878793          	addi	a5,a5,1016 # 80021df0 <log>
    80004a00:	963e                	add	a2,a2,a5
    80004a02:	44dc                	lw	a5,12(s1)
    80004a04:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a06:	8526                	mv	a0,s1
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	daa080e7          	jalr	-598(ra) # 800037b2 <bpin>
    log.lh.n++;
    80004a10:	0001d717          	auipc	a4,0x1d
    80004a14:	3e070713          	addi	a4,a4,992 # 80021df0 <log>
    80004a18:	575c                	lw	a5,44(a4)
    80004a1a:	2785                	addiw	a5,a5,1
    80004a1c:	d75c                	sw	a5,44(a4)
    80004a1e:	a835                	j	80004a5a <log_write+0xca>
    panic("too big a transaction");
    80004a20:	00004517          	auipc	a0,0x4
    80004a24:	d5850513          	addi	a0,a0,-680 # 80008778 <syscalls+0x208>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a30:	00004517          	auipc	a0,0x4
    80004a34:	d6050513          	addi	a0,a0,-672 # 80008790 <syscalls+0x220>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	b06080e7          	jalr	-1274(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a40:	00878713          	addi	a4,a5,8
    80004a44:	00271693          	slli	a3,a4,0x2
    80004a48:	0001d717          	auipc	a4,0x1d
    80004a4c:	3a870713          	addi	a4,a4,936 # 80021df0 <log>
    80004a50:	9736                	add	a4,a4,a3
    80004a52:	44d4                	lw	a3,12(s1)
    80004a54:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a56:	faf608e3          	beq	a2,a5,80004a06 <log_write+0x76>
  }
  release(&log.lock);
    80004a5a:	0001d517          	auipc	a0,0x1d
    80004a5e:	39650513          	addi	a0,a0,918 # 80021df0 <log>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
}
    80004a6a:	60e2                	ld	ra,24(sp)
    80004a6c:	6442                	ld	s0,16(sp)
    80004a6e:	64a2                	ld	s1,8(sp)
    80004a70:	6902                	ld	s2,0(sp)
    80004a72:	6105                	addi	sp,sp,32
    80004a74:	8082                	ret

0000000080004a76 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	e426                	sd	s1,8(sp)
    80004a7e:	e04a                	sd	s2,0(sp)
    80004a80:	1000                	addi	s0,sp,32
    80004a82:	84aa                	mv	s1,a0
    80004a84:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a86:	00004597          	auipc	a1,0x4
    80004a8a:	d2a58593          	addi	a1,a1,-726 # 800087b0 <syscalls+0x240>
    80004a8e:	0521                	addi	a0,a0,8
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	0c4080e7          	jalr	196(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a98:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a9c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aa0:	0204a423          	sw	zero,40(s1)
}
    80004aa4:	60e2                	ld	ra,24(sp)
    80004aa6:	6442                	ld	s0,16(sp)
    80004aa8:	64a2                	ld	s1,8(sp)
    80004aaa:	6902                	ld	s2,0(sp)
    80004aac:	6105                	addi	sp,sp,32
    80004aae:	8082                	ret

0000000080004ab0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	e04a                	sd	s2,0(sp)
    80004aba:	1000                	addi	s0,sp,32
    80004abc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004abe:	00850913          	addi	s2,a0,8
    80004ac2:	854a                	mv	a0,s2
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	120080e7          	jalr	288(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004acc:	409c                	lw	a5,0(s1)
    80004ace:	cb89                	beqz	a5,80004ae0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ad0:	85ca                	mv	a1,s2
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffe097          	auipc	ra,0xffffe
    80004ad8:	a0a080e7          	jalr	-1526(ra) # 800024de <sleep>
  while (lk->locked) {
    80004adc:	409c                	lw	a5,0(s1)
    80004ade:	fbed                	bnez	a5,80004ad0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ae0:	4785                	li	a5,1
    80004ae2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ae4:	ffffd097          	auipc	ra,0xffffd
    80004ae8:	352080e7          	jalr	850(ra) # 80001e36 <myproc>
    80004aec:	591c                	lw	a5,48(a0)
    80004aee:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004af0:	854a                	mv	a0,s2
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	1a6080e7          	jalr	422(ra) # 80000c98 <release>
}
    80004afa:	60e2                	ld	ra,24(sp)
    80004afc:	6442                	ld	s0,16(sp)
    80004afe:	64a2                	ld	s1,8(sp)
    80004b00:	6902                	ld	s2,0(sp)
    80004b02:	6105                	addi	sp,sp,32
    80004b04:	8082                	ret

0000000080004b06 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	e04a                	sd	s2,0(sp)
    80004b10:	1000                	addi	s0,sp,32
    80004b12:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b14:	00850913          	addi	s2,a0,8
    80004b18:	854a                	mv	a0,s2
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	0ca080e7          	jalr	202(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b22:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b26:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffe097          	auipc	ra,0xffffe
    80004b30:	fa0080e7          	jalr	-96(ra) # 80002acc <wakeup>
  release(&lk->lk);
    80004b34:	854a                	mv	a0,s2
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	162080e7          	jalr	354(ra) # 80000c98 <release>
}
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6902                	ld	s2,0(sp)
    80004b46:	6105                	addi	sp,sp,32
    80004b48:	8082                	ret

0000000080004b4a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b4a:	7179                	addi	sp,sp,-48
    80004b4c:	f406                	sd	ra,40(sp)
    80004b4e:	f022                	sd	s0,32(sp)
    80004b50:	ec26                	sd	s1,24(sp)
    80004b52:	e84a                	sd	s2,16(sp)
    80004b54:	e44e                	sd	s3,8(sp)
    80004b56:	1800                	addi	s0,sp,48
    80004b58:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b5a:	00850913          	addi	s2,a0,8
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	084080e7          	jalr	132(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b68:	409c                	lw	a5,0(s1)
    80004b6a:	ef99                	bnez	a5,80004b88 <holdingsleep+0x3e>
    80004b6c:	4481                	li	s1,0
  release(&lk->lk);
    80004b6e:	854a                	mv	a0,s2
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	128080e7          	jalr	296(ra) # 80000c98 <release>
  return r;
}
    80004b78:	8526                	mv	a0,s1
    80004b7a:	70a2                	ld	ra,40(sp)
    80004b7c:	7402                	ld	s0,32(sp)
    80004b7e:	64e2                	ld	s1,24(sp)
    80004b80:	6942                	ld	s2,16(sp)
    80004b82:	69a2                	ld	s3,8(sp)
    80004b84:	6145                	addi	sp,sp,48
    80004b86:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b88:	0284a983          	lw	s3,40(s1)
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	2aa080e7          	jalr	682(ra) # 80001e36 <myproc>
    80004b94:	5904                	lw	s1,48(a0)
    80004b96:	413484b3          	sub	s1,s1,s3
    80004b9a:	0014b493          	seqz	s1,s1
    80004b9e:	bfc1                	j	80004b6e <holdingsleep+0x24>

0000000080004ba0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ba0:	1141                	addi	sp,sp,-16
    80004ba2:	e406                	sd	ra,8(sp)
    80004ba4:	e022                	sd	s0,0(sp)
    80004ba6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ba8:	00004597          	auipc	a1,0x4
    80004bac:	c1858593          	addi	a1,a1,-1000 # 800087c0 <syscalls+0x250>
    80004bb0:	0001d517          	auipc	a0,0x1d
    80004bb4:	38850513          	addi	a0,a0,904 # 80021f38 <ftable>
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	f9c080e7          	jalr	-100(ra) # 80000b54 <initlock>
}
    80004bc0:	60a2                	ld	ra,8(sp)
    80004bc2:	6402                	ld	s0,0(sp)
    80004bc4:	0141                	addi	sp,sp,16
    80004bc6:	8082                	ret

0000000080004bc8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bc8:	1101                	addi	sp,sp,-32
    80004bca:	ec06                	sd	ra,24(sp)
    80004bcc:	e822                	sd	s0,16(sp)
    80004bce:	e426                	sd	s1,8(sp)
    80004bd0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bd2:	0001d517          	auipc	a0,0x1d
    80004bd6:	36650513          	addi	a0,a0,870 # 80021f38 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	00a080e7          	jalr	10(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be2:	0001d497          	auipc	s1,0x1d
    80004be6:	36e48493          	addi	s1,s1,878 # 80021f50 <ftable+0x18>
    80004bea:	0001e717          	auipc	a4,0x1e
    80004bee:	30670713          	addi	a4,a4,774 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004bf2:	40dc                	lw	a5,4(s1)
    80004bf4:	cf99                	beqz	a5,80004c12 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bf6:	02848493          	addi	s1,s1,40
    80004bfa:	fee49ce3          	bne	s1,a4,80004bf2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bfe:	0001d517          	auipc	a0,0x1d
    80004c02:	33a50513          	addi	a0,a0,826 # 80021f38 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	092080e7          	jalr	146(ra) # 80000c98 <release>
  return 0;
    80004c0e:	4481                	li	s1,0
    80004c10:	a819                	j	80004c26 <filealloc+0x5e>
      f->ref = 1;
    80004c12:	4785                	li	a5,1
    80004c14:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c16:	0001d517          	auipc	a0,0x1d
    80004c1a:	32250513          	addi	a0,a0,802 # 80021f38 <ftable>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	07a080e7          	jalr	122(ra) # 80000c98 <release>
}
    80004c26:	8526                	mv	a0,s1
    80004c28:	60e2                	ld	ra,24(sp)
    80004c2a:	6442                	ld	s0,16(sp)
    80004c2c:	64a2                	ld	s1,8(sp)
    80004c2e:	6105                	addi	sp,sp,32
    80004c30:	8082                	ret

0000000080004c32 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c32:	1101                	addi	sp,sp,-32
    80004c34:	ec06                	sd	ra,24(sp)
    80004c36:	e822                	sd	s0,16(sp)
    80004c38:	e426                	sd	s1,8(sp)
    80004c3a:	1000                	addi	s0,sp,32
    80004c3c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c3e:	0001d517          	auipc	a0,0x1d
    80004c42:	2fa50513          	addi	a0,a0,762 # 80021f38 <ftable>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c4e:	40dc                	lw	a5,4(s1)
    80004c50:	02f05263          	blez	a5,80004c74 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c54:	2785                	addiw	a5,a5,1
    80004c56:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c58:	0001d517          	auipc	a0,0x1d
    80004c5c:	2e050513          	addi	a0,a0,736 # 80021f38 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	038080e7          	jalr	56(ra) # 80000c98 <release>
  return f;
}
    80004c68:	8526                	mv	a0,s1
    80004c6a:	60e2                	ld	ra,24(sp)
    80004c6c:	6442                	ld	s0,16(sp)
    80004c6e:	64a2                	ld	s1,8(sp)
    80004c70:	6105                	addi	sp,sp,32
    80004c72:	8082                	ret
    panic("filedup");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	b5450513          	addi	a0,a0,-1196 # 800087c8 <syscalls+0x258>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8c2080e7          	jalr	-1854(ra) # 8000053e <panic>

0000000080004c84 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c84:	7139                	addi	sp,sp,-64
    80004c86:	fc06                	sd	ra,56(sp)
    80004c88:	f822                	sd	s0,48(sp)
    80004c8a:	f426                	sd	s1,40(sp)
    80004c8c:	f04a                	sd	s2,32(sp)
    80004c8e:	ec4e                	sd	s3,24(sp)
    80004c90:	e852                	sd	s4,16(sp)
    80004c92:	e456                	sd	s5,8(sp)
    80004c94:	0080                	addi	s0,sp,64
    80004c96:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c98:	0001d517          	auipc	a0,0x1d
    80004c9c:	2a050513          	addi	a0,a0,672 # 80021f38 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f44080e7          	jalr	-188(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ca8:	40dc                	lw	a5,4(s1)
    80004caa:	06f05163          	blez	a5,80004d0c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cae:	37fd                	addiw	a5,a5,-1
    80004cb0:	0007871b          	sext.w	a4,a5
    80004cb4:	c0dc                	sw	a5,4(s1)
    80004cb6:	06e04363          	bgtz	a4,80004d1c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cba:	0004a903          	lw	s2,0(s1)
    80004cbe:	0094ca83          	lbu	s5,9(s1)
    80004cc2:	0104ba03          	ld	s4,16(s1)
    80004cc6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cca:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cce:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cd2:	0001d517          	auipc	a0,0x1d
    80004cd6:	26650513          	addi	a0,a0,614 # 80021f38 <ftable>
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ce2:	4785                	li	a5,1
    80004ce4:	04f90d63          	beq	s2,a5,80004d3e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ce8:	3979                	addiw	s2,s2,-2
    80004cea:	4785                	li	a5,1
    80004cec:	0527e063          	bltu	a5,s2,80004d2c <fileclose+0xa8>
    begin_op();
    80004cf0:	00000097          	auipc	ra,0x0
    80004cf4:	ac8080e7          	jalr	-1336(ra) # 800047b8 <begin_op>
    iput(ff.ip);
    80004cf8:	854e                	mv	a0,s3
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	2a6080e7          	jalr	678(ra) # 80003fa0 <iput>
    end_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	b36080e7          	jalr	-1226(ra) # 80004838 <end_op>
    80004d0a:	a00d                	j	80004d2c <fileclose+0xa8>
    panic("fileclose");
    80004d0c:	00004517          	auipc	a0,0x4
    80004d10:	ac450513          	addi	a0,a0,-1340 # 800087d0 <syscalls+0x260>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d1c:	0001d517          	auipc	a0,0x1d
    80004d20:	21c50513          	addi	a0,a0,540 # 80021f38 <ftable>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f74080e7          	jalr	-140(ra) # 80000c98 <release>
  }
}
    80004d2c:	70e2                	ld	ra,56(sp)
    80004d2e:	7442                	ld	s0,48(sp)
    80004d30:	74a2                	ld	s1,40(sp)
    80004d32:	7902                	ld	s2,32(sp)
    80004d34:	69e2                	ld	s3,24(sp)
    80004d36:	6a42                	ld	s4,16(sp)
    80004d38:	6aa2                	ld	s5,8(sp)
    80004d3a:	6121                	addi	sp,sp,64
    80004d3c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d3e:	85d6                	mv	a1,s5
    80004d40:	8552                	mv	a0,s4
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	34c080e7          	jalr	844(ra) # 8000508e <pipeclose>
    80004d4a:	b7cd                	j	80004d2c <fileclose+0xa8>

0000000080004d4c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d4c:	715d                	addi	sp,sp,-80
    80004d4e:	e486                	sd	ra,72(sp)
    80004d50:	e0a2                	sd	s0,64(sp)
    80004d52:	fc26                	sd	s1,56(sp)
    80004d54:	f84a                	sd	s2,48(sp)
    80004d56:	f44e                	sd	s3,40(sp)
    80004d58:	0880                	addi	s0,sp,80
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d5e:	ffffd097          	auipc	ra,0xffffd
    80004d62:	0d8080e7          	jalr	216(ra) # 80001e36 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d66:	409c                	lw	a5,0(s1)
    80004d68:	37f9                	addiw	a5,a5,-2
    80004d6a:	4705                	li	a4,1
    80004d6c:	04f76763          	bltu	a4,a5,80004dba <filestat+0x6e>
    80004d70:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d72:	6c88                	ld	a0,24(s1)
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	072080e7          	jalr	114(ra) # 80003de6 <ilock>
    stati(f->ip, &st);
    80004d7c:	fb840593          	addi	a1,s0,-72
    80004d80:	6c88                	ld	a0,24(s1)
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	2ee080e7          	jalr	750(ra) # 80004070 <stati>
    iunlock(f->ip);
    80004d8a:	6c88                	ld	a0,24(s1)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	11c080e7          	jalr	284(ra) # 80003ea8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d94:	46e1                	li	a3,24
    80004d96:	fb840613          	addi	a2,s0,-72
    80004d9a:	85ce                	mv	a1,s3
    80004d9c:	05093503          	ld	a0,80(s2)
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	8d2080e7          	jalr	-1838(ra) # 80001672 <copyout>
    80004da8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dac:	60a6                	ld	ra,72(sp)
    80004dae:	6406                	ld	s0,64(sp)
    80004db0:	74e2                	ld	s1,56(sp)
    80004db2:	7942                	ld	s2,48(sp)
    80004db4:	79a2                	ld	s3,40(sp)
    80004db6:	6161                	addi	sp,sp,80
    80004db8:	8082                	ret
  return -1;
    80004dba:	557d                	li	a0,-1
    80004dbc:	bfc5                	j	80004dac <filestat+0x60>

0000000080004dbe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dbe:	7179                	addi	sp,sp,-48
    80004dc0:	f406                	sd	ra,40(sp)
    80004dc2:	f022                	sd	s0,32(sp)
    80004dc4:	ec26                	sd	s1,24(sp)
    80004dc6:	e84a                	sd	s2,16(sp)
    80004dc8:	e44e                	sd	s3,8(sp)
    80004dca:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dcc:	00854783          	lbu	a5,8(a0)
    80004dd0:	c3d5                	beqz	a5,80004e74 <fileread+0xb6>
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	89ae                	mv	s3,a1
    80004dd6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dd8:	411c                	lw	a5,0(a0)
    80004dda:	4705                	li	a4,1
    80004ddc:	04e78963          	beq	a5,a4,80004e2e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004de0:	470d                	li	a4,3
    80004de2:	04e78d63          	beq	a5,a4,80004e3c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004de6:	4709                	li	a4,2
    80004de8:	06e79e63          	bne	a5,a4,80004e64 <fileread+0xa6>
    ilock(f->ip);
    80004dec:	6d08                	ld	a0,24(a0)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	ff8080e7          	jalr	-8(ra) # 80003de6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004df6:	874a                	mv	a4,s2
    80004df8:	5094                	lw	a3,32(s1)
    80004dfa:	864e                	mv	a2,s3
    80004dfc:	4585                	li	a1,1
    80004dfe:	6c88                	ld	a0,24(s1)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	29a080e7          	jalr	666(ra) # 8000409a <readi>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	00a05563          	blez	a0,80004e14 <fileread+0x56>
      f->off += r;
    80004e0e:	509c                	lw	a5,32(s1)
    80004e10:	9fa9                	addw	a5,a5,a0
    80004e12:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e14:	6c88                	ld	a0,24(s1)
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	092080e7          	jalr	146(ra) # 80003ea8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e1e:	854a                	mv	a0,s2
    80004e20:	70a2                	ld	ra,40(sp)
    80004e22:	7402                	ld	s0,32(sp)
    80004e24:	64e2                	ld	s1,24(sp)
    80004e26:	6942                	ld	s2,16(sp)
    80004e28:	69a2                	ld	s3,8(sp)
    80004e2a:	6145                	addi	sp,sp,48
    80004e2c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e2e:	6908                	ld	a0,16(a0)
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	3c8080e7          	jalr	968(ra) # 800051f8 <piperead>
    80004e38:	892a                	mv	s2,a0
    80004e3a:	b7d5                	j	80004e1e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e3c:	02451783          	lh	a5,36(a0)
    80004e40:	03079693          	slli	a3,a5,0x30
    80004e44:	92c1                	srli	a3,a3,0x30
    80004e46:	4725                	li	a4,9
    80004e48:	02d76863          	bltu	a4,a3,80004e78 <fileread+0xba>
    80004e4c:	0792                	slli	a5,a5,0x4
    80004e4e:	0001d717          	auipc	a4,0x1d
    80004e52:	04a70713          	addi	a4,a4,74 # 80021e98 <devsw>
    80004e56:	97ba                	add	a5,a5,a4
    80004e58:	639c                	ld	a5,0(a5)
    80004e5a:	c38d                	beqz	a5,80004e7c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e5c:	4505                	li	a0,1
    80004e5e:	9782                	jalr	a5
    80004e60:	892a                	mv	s2,a0
    80004e62:	bf75                	j	80004e1e <fileread+0x60>
    panic("fileread");
    80004e64:	00004517          	auipc	a0,0x4
    80004e68:	97c50513          	addi	a0,a0,-1668 # 800087e0 <syscalls+0x270>
    80004e6c:	ffffb097          	auipc	ra,0xffffb
    80004e70:	6d2080e7          	jalr	1746(ra) # 8000053e <panic>
    return -1;
    80004e74:	597d                	li	s2,-1
    80004e76:	b765                	j	80004e1e <fileread+0x60>
      return -1;
    80004e78:	597d                	li	s2,-1
    80004e7a:	b755                	j	80004e1e <fileread+0x60>
    80004e7c:	597d                	li	s2,-1
    80004e7e:	b745                	j	80004e1e <fileread+0x60>

0000000080004e80 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e80:	715d                	addi	sp,sp,-80
    80004e82:	e486                	sd	ra,72(sp)
    80004e84:	e0a2                	sd	s0,64(sp)
    80004e86:	fc26                	sd	s1,56(sp)
    80004e88:	f84a                	sd	s2,48(sp)
    80004e8a:	f44e                	sd	s3,40(sp)
    80004e8c:	f052                	sd	s4,32(sp)
    80004e8e:	ec56                	sd	s5,24(sp)
    80004e90:	e85a                	sd	s6,16(sp)
    80004e92:	e45e                	sd	s7,8(sp)
    80004e94:	e062                	sd	s8,0(sp)
    80004e96:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e98:	00954783          	lbu	a5,9(a0)
    80004e9c:	10078663          	beqz	a5,80004fa8 <filewrite+0x128>
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	8aae                	mv	s5,a1
    80004ea4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ea6:	411c                	lw	a5,0(a0)
    80004ea8:	4705                	li	a4,1
    80004eaa:	02e78263          	beq	a5,a4,80004ece <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eae:	470d                	li	a4,3
    80004eb0:	02e78663          	beq	a5,a4,80004edc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb4:	4709                	li	a4,2
    80004eb6:	0ee79163          	bne	a5,a4,80004f98 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eba:	0ac05d63          	blez	a2,80004f74 <filewrite+0xf4>
    int i = 0;
    80004ebe:	4981                	li	s3,0
    80004ec0:	6b05                	lui	s6,0x1
    80004ec2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ec6:	6b85                	lui	s7,0x1
    80004ec8:	c00b8b9b          	addiw	s7,s7,-1024
    80004ecc:	a861                	j	80004f64 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ece:	6908                	ld	a0,16(a0)
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	22e080e7          	jalr	558(ra) # 800050fe <pipewrite>
    80004ed8:	8a2a                	mv	s4,a0
    80004eda:	a045                	j	80004f7a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004edc:	02451783          	lh	a5,36(a0)
    80004ee0:	03079693          	slli	a3,a5,0x30
    80004ee4:	92c1                	srli	a3,a3,0x30
    80004ee6:	4725                	li	a4,9
    80004ee8:	0cd76263          	bltu	a4,a3,80004fac <filewrite+0x12c>
    80004eec:	0792                	slli	a5,a5,0x4
    80004eee:	0001d717          	auipc	a4,0x1d
    80004ef2:	faa70713          	addi	a4,a4,-86 # 80021e98 <devsw>
    80004ef6:	97ba                	add	a5,a5,a4
    80004ef8:	679c                	ld	a5,8(a5)
    80004efa:	cbdd                	beqz	a5,80004fb0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004efc:	4505                	li	a0,1
    80004efe:	9782                	jalr	a5
    80004f00:	8a2a                	mv	s4,a0
    80004f02:	a8a5                	j	80004f7a <filewrite+0xfa>
    80004f04:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f08:	00000097          	auipc	ra,0x0
    80004f0c:	8b0080e7          	jalr	-1872(ra) # 800047b8 <begin_op>
      ilock(f->ip);
    80004f10:	01893503          	ld	a0,24(s2)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	ed2080e7          	jalr	-302(ra) # 80003de6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f1c:	8762                	mv	a4,s8
    80004f1e:	02092683          	lw	a3,32(s2)
    80004f22:	01598633          	add	a2,s3,s5
    80004f26:	4585                	li	a1,1
    80004f28:	01893503          	ld	a0,24(s2)
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	266080e7          	jalr	614(ra) # 80004192 <writei>
    80004f34:	84aa                	mv	s1,a0
    80004f36:	00a05763          	blez	a0,80004f44 <filewrite+0xc4>
        f->off += r;
    80004f3a:	02092783          	lw	a5,32(s2)
    80004f3e:	9fa9                	addw	a5,a5,a0
    80004f40:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f44:	01893503          	ld	a0,24(s2)
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	f60080e7          	jalr	-160(ra) # 80003ea8 <iunlock>
      end_op();
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	8e8080e7          	jalr	-1816(ra) # 80004838 <end_op>

      if(r != n1){
    80004f58:	009c1f63          	bne	s8,s1,80004f76 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f5c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f60:	0149db63          	bge	s3,s4,80004f76 <filewrite+0xf6>
      int n1 = n - i;
    80004f64:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f68:	84be                	mv	s1,a5
    80004f6a:	2781                	sext.w	a5,a5
    80004f6c:	f8fb5ce3          	bge	s6,a5,80004f04 <filewrite+0x84>
    80004f70:	84de                	mv	s1,s7
    80004f72:	bf49                	j	80004f04 <filewrite+0x84>
    int i = 0;
    80004f74:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f76:	013a1f63          	bne	s4,s3,80004f94 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f7a:	8552                	mv	a0,s4
    80004f7c:	60a6                	ld	ra,72(sp)
    80004f7e:	6406                	ld	s0,64(sp)
    80004f80:	74e2                	ld	s1,56(sp)
    80004f82:	7942                	ld	s2,48(sp)
    80004f84:	79a2                	ld	s3,40(sp)
    80004f86:	7a02                	ld	s4,32(sp)
    80004f88:	6ae2                	ld	s5,24(sp)
    80004f8a:	6b42                	ld	s6,16(sp)
    80004f8c:	6ba2                	ld	s7,8(sp)
    80004f8e:	6c02                	ld	s8,0(sp)
    80004f90:	6161                	addi	sp,sp,80
    80004f92:	8082                	ret
    ret = (i == n ? n : -1);
    80004f94:	5a7d                	li	s4,-1
    80004f96:	b7d5                	j	80004f7a <filewrite+0xfa>
    panic("filewrite");
    80004f98:	00004517          	auipc	a0,0x4
    80004f9c:	85850513          	addi	a0,a0,-1960 # 800087f0 <syscalls+0x280>
    80004fa0:	ffffb097          	auipc	ra,0xffffb
    80004fa4:	59e080e7          	jalr	1438(ra) # 8000053e <panic>
    return -1;
    80004fa8:	5a7d                	li	s4,-1
    80004faa:	bfc1                	j	80004f7a <filewrite+0xfa>
      return -1;
    80004fac:	5a7d                	li	s4,-1
    80004fae:	b7f1                	j	80004f7a <filewrite+0xfa>
    80004fb0:	5a7d                	li	s4,-1
    80004fb2:	b7e1                	j	80004f7a <filewrite+0xfa>

0000000080004fb4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fb4:	7179                	addi	sp,sp,-48
    80004fb6:	f406                	sd	ra,40(sp)
    80004fb8:	f022                	sd	s0,32(sp)
    80004fba:	ec26                	sd	s1,24(sp)
    80004fbc:	e84a                	sd	s2,16(sp)
    80004fbe:	e44e                	sd	s3,8(sp)
    80004fc0:	e052                	sd	s4,0(sp)
    80004fc2:	1800                	addi	s0,sp,48
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fc8:	0005b023          	sd	zero,0(a1)
    80004fcc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fd0:	00000097          	auipc	ra,0x0
    80004fd4:	bf8080e7          	jalr	-1032(ra) # 80004bc8 <filealloc>
    80004fd8:	e088                	sd	a0,0(s1)
    80004fda:	c551                	beqz	a0,80005066 <pipealloc+0xb2>
    80004fdc:	00000097          	auipc	ra,0x0
    80004fe0:	bec080e7          	jalr	-1044(ra) # 80004bc8 <filealloc>
    80004fe4:	00aa3023          	sd	a0,0(s4)
    80004fe8:	c92d                	beqz	a0,8000505a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	b0a080e7          	jalr	-1270(ra) # 80000af4 <kalloc>
    80004ff2:	892a                	mv	s2,a0
    80004ff4:	c125                	beqz	a0,80005054 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ff6:	4985                	li	s3,1
    80004ff8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ffc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005000:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005004:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005008:	00003597          	auipc	a1,0x3
    8000500c:	7f858593          	addi	a1,a1,2040 # 80008800 <syscalls+0x290>
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	b44080e7          	jalr	-1212(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005018:	609c                	ld	a5,0(s1)
    8000501a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000501e:	609c                	ld	a5,0(s1)
    80005020:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005024:	609c                	ld	a5,0(s1)
    80005026:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000502a:	609c                	ld	a5,0(s1)
    8000502c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005030:	000a3783          	ld	a5,0(s4)
    80005034:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005038:	000a3783          	ld	a5,0(s4)
    8000503c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005040:	000a3783          	ld	a5,0(s4)
    80005044:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005048:	000a3783          	ld	a5,0(s4)
    8000504c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005050:	4501                	li	a0,0
    80005052:	a025                	j	8000507a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005054:	6088                	ld	a0,0(s1)
    80005056:	e501                	bnez	a0,8000505e <pipealloc+0xaa>
    80005058:	a039                	j	80005066 <pipealloc+0xb2>
    8000505a:	6088                	ld	a0,0(s1)
    8000505c:	c51d                	beqz	a0,8000508a <pipealloc+0xd6>
    fileclose(*f0);
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	c26080e7          	jalr	-986(ra) # 80004c84 <fileclose>
  if(*f1)
    80005066:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000506a:	557d                	li	a0,-1
  if(*f1)
    8000506c:	c799                	beqz	a5,8000507a <pipealloc+0xc6>
    fileclose(*f1);
    8000506e:	853e                	mv	a0,a5
    80005070:	00000097          	auipc	ra,0x0
    80005074:	c14080e7          	jalr	-1004(ra) # 80004c84 <fileclose>
  return -1;
    80005078:	557d                	li	a0,-1
}
    8000507a:	70a2                	ld	ra,40(sp)
    8000507c:	7402                	ld	s0,32(sp)
    8000507e:	64e2                	ld	s1,24(sp)
    80005080:	6942                	ld	s2,16(sp)
    80005082:	69a2                	ld	s3,8(sp)
    80005084:	6a02                	ld	s4,0(sp)
    80005086:	6145                	addi	sp,sp,48
    80005088:	8082                	ret
  return -1;
    8000508a:	557d                	li	a0,-1
    8000508c:	b7fd                	j	8000507a <pipealloc+0xc6>

000000008000508e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000508e:	1101                	addi	sp,sp,-32
    80005090:	ec06                	sd	ra,24(sp)
    80005092:	e822                	sd	s0,16(sp)
    80005094:	e426                	sd	s1,8(sp)
    80005096:	e04a                	sd	s2,0(sp)
    80005098:	1000                	addi	s0,sp,32
    8000509a:	84aa                	mv	s1,a0
    8000509c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  if(writable){
    800050a6:	02090d63          	beqz	s2,800050e0 <pipeclose+0x52>
    pi->writeopen = 0;
    800050aa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050ae:	21848513          	addi	a0,s1,536
    800050b2:	ffffe097          	auipc	ra,0xffffe
    800050b6:	a1a080e7          	jalr	-1510(ra) # 80002acc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050ba:	2204b783          	ld	a5,544(s1)
    800050be:	eb95                	bnez	a5,800050f2 <pipeclose+0x64>
    release(&pi->lock);
    800050c0:	8526                	mv	a0,s1
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050ca:	8526                	mv	a0,s1
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	92c080e7          	jalr	-1748(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050d4:	60e2                	ld	ra,24(sp)
    800050d6:	6442                	ld	s0,16(sp)
    800050d8:	64a2                	ld	s1,8(sp)
    800050da:	6902                	ld	s2,0(sp)
    800050dc:	6105                	addi	sp,sp,32
    800050de:	8082                	ret
    pi->readopen = 0;
    800050e0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050e4:	21c48513          	addi	a0,s1,540
    800050e8:	ffffe097          	auipc	ra,0xffffe
    800050ec:	9e4080e7          	jalr	-1564(ra) # 80002acc <wakeup>
    800050f0:	b7e9                	j	800050ba <pipeclose+0x2c>
    release(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	ba4080e7          	jalr	-1116(ra) # 80000c98 <release>
}
    800050fc:	bfe1                	j	800050d4 <pipeclose+0x46>

00000000800050fe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050fe:	7159                	addi	sp,sp,-112
    80005100:	f486                	sd	ra,104(sp)
    80005102:	f0a2                	sd	s0,96(sp)
    80005104:	eca6                	sd	s1,88(sp)
    80005106:	e8ca                	sd	s2,80(sp)
    80005108:	e4ce                	sd	s3,72(sp)
    8000510a:	e0d2                	sd	s4,64(sp)
    8000510c:	fc56                	sd	s5,56(sp)
    8000510e:	f85a                	sd	s6,48(sp)
    80005110:	f45e                	sd	s7,40(sp)
    80005112:	f062                	sd	s8,32(sp)
    80005114:	ec66                	sd	s9,24(sp)
    80005116:	1880                	addi	s0,sp,112
    80005118:	84aa                	mv	s1,a0
    8000511a:	8aae                	mv	s5,a1
    8000511c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	d18080e7          	jalr	-744(ra) # 80001e36 <myproc>
    80005126:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005128:	8526                	mv	a0,s1
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	aba080e7          	jalr	-1350(ra) # 80000be4 <acquire>
  while(i < n){
    80005132:	0d405163          	blez	s4,800051f4 <pipewrite+0xf6>
    80005136:	8ba6                	mv	s7,s1
  int i = 0;
    80005138:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000513a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000513c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005140:	21c48c13          	addi	s8,s1,540
    80005144:	a08d                	j	800051a6 <pipewrite+0xa8>
      release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
      return -1;
    80005150:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005152:	854a                	mv	a0,s2
    80005154:	70a6                	ld	ra,104(sp)
    80005156:	7406                	ld	s0,96(sp)
    80005158:	64e6                	ld	s1,88(sp)
    8000515a:	6946                	ld	s2,80(sp)
    8000515c:	69a6                	ld	s3,72(sp)
    8000515e:	6a06                	ld	s4,64(sp)
    80005160:	7ae2                	ld	s5,56(sp)
    80005162:	7b42                	ld	s6,48(sp)
    80005164:	7ba2                	ld	s7,40(sp)
    80005166:	7c02                	ld	s8,32(sp)
    80005168:	6ce2                	ld	s9,24(sp)
    8000516a:	6165                	addi	sp,sp,112
    8000516c:	8082                	ret
      wakeup(&pi->nread);
    8000516e:	8566                	mv	a0,s9
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	95c080e7          	jalr	-1700(ra) # 80002acc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005178:	85de                	mv	a1,s7
    8000517a:	8562                	mv	a0,s8
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	362080e7          	jalr	866(ra) # 800024de <sleep>
    80005184:	a839                	j	800051a2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005186:	21c4a783          	lw	a5,540(s1)
    8000518a:	0017871b          	addiw	a4,a5,1
    8000518e:	20e4ae23          	sw	a4,540(s1)
    80005192:	1ff7f793          	andi	a5,a5,511
    80005196:	97a6                	add	a5,a5,s1
    80005198:	f9f44703          	lbu	a4,-97(s0)
    8000519c:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a0:	2905                	addiw	s2,s2,1
  while(i < n){
    800051a2:	03495d63          	bge	s2,s4,800051dc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051a6:	2204a783          	lw	a5,544(s1)
    800051aa:	dfd1                	beqz	a5,80005146 <pipewrite+0x48>
    800051ac:	0289a783          	lw	a5,40(s3)
    800051b0:	fbd9                	bnez	a5,80005146 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051b2:	2184a783          	lw	a5,536(s1)
    800051b6:	21c4a703          	lw	a4,540(s1)
    800051ba:	2007879b          	addiw	a5,a5,512
    800051be:	faf708e3          	beq	a4,a5,8000516e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051c2:	4685                	li	a3,1
    800051c4:	01590633          	add	a2,s2,s5
    800051c8:	f9f40593          	addi	a1,s0,-97
    800051cc:	0509b503          	ld	a0,80(s3)
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	52e080e7          	jalr	1326(ra) # 800016fe <copyin>
    800051d8:	fb6517e3          	bne	a0,s6,80005186 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051dc:	21848513          	addi	a0,s1,536
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	8ec080e7          	jalr	-1812(ra) # 80002acc <wakeup>
  release(&pi->lock);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
  return i;
    800051f2:	b785                	j	80005152 <pipewrite+0x54>
  int i = 0;
    800051f4:	4901                	li	s2,0
    800051f6:	b7dd                	j	800051dc <pipewrite+0xde>

00000000800051f8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051f8:	715d                	addi	sp,sp,-80
    800051fa:	e486                	sd	ra,72(sp)
    800051fc:	e0a2                	sd	s0,64(sp)
    800051fe:	fc26                	sd	s1,56(sp)
    80005200:	f84a                	sd	s2,48(sp)
    80005202:	f44e                	sd	s3,40(sp)
    80005204:	f052                	sd	s4,32(sp)
    80005206:	ec56                	sd	s5,24(sp)
    80005208:	e85a                	sd	s6,16(sp)
    8000520a:	0880                	addi	s0,sp,80
    8000520c:	84aa                	mv	s1,a0
    8000520e:	892e                	mv	s2,a1
    80005210:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	c24080e7          	jalr	-988(ra) # 80001e36 <myproc>
    8000521a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000521c:	8b26                	mv	s6,s1
    8000521e:	8526                	mv	a0,s1
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005228:	2184a703          	lw	a4,536(s1)
    8000522c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005230:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005234:	02f71463          	bne	a4,a5,8000525c <piperead+0x64>
    80005238:	2244a783          	lw	a5,548(s1)
    8000523c:	c385                	beqz	a5,8000525c <piperead+0x64>
    if(pr->killed){
    8000523e:	028a2783          	lw	a5,40(s4)
    80005242:	ebc1                	bnez	a5,800052d2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005244:	85da                	mv	a1,s6
    80005246:	854e                	mv	a0,s3
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	296080e7          	jalr	662(ra) # 800024de <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005250:	2184a703          	lw	a4,536(s1)
    80005254:	21c4a783          	lw	a5,540(s1)
    80005258:	fef700e3          	beq	a4,a5,80005238 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000525c:	09505263          	blez	s5,800052e0 <piperead+0xe8>
    80005260:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005262:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005264:	2184a783          	lw	a5,536(s1)
    80005268:	21c4a703          	lw	a4,540(s1)
    8000526c:	02f70d63          	beq	a4,a5,800052a6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005270:	0017871b          	addiw	a4,a5,1
    80005274:	20e4ac23          	sw	a4,536(s1)
    80005278:	1ff7f793          	andi	a5,a5,511
    8000527c:	97a6                	add	a5,a5,s1
    8000527e:	0187c783          	lbu	a5,24(a5)
    80005282:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005286:	4685                	li	a3,1
    80005288:	fbf40613          	addi	a2,s0,-65
    8000528c:	85ca                	mv	a1,s2
    8000528e:	050a3503          	ld	a0,80(s4)
    80005292:	ffffc097          	auipc	ra,0xffffc
    80005296:	3e0080e7          	jalr	992(ra) # 80001672 <copyout>
    8000529a:	01650663          	beq	a0,s6,800052a6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000529e:	2985                	addiw	s3,s3,1
    800052a0:	0905                	addi	s2,s2,1
    800052a2:	fd3a91e3          	bne	s5,s3,80005264 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052a6:	21c48513          	addi	a0,s1,540
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	822080e7          	jalr	-2014(ra) # 80002acc <wakeup>
  release(&pi->lock);
    800052b2:	8526                	mv	a0,s1
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
  return i;
}
    800052bc:	854e                	mv	a0,s3
    800052be:	60a6                	ld	ra,72(sp)
    800052c0:	6406                	ld	s0,64(sp)
    800052c2:	74e2                	ld	s1,56(sp)
    800052c4:	7942                	ld	s2,48(sp)
    800052c6:	79a2                	ld	s3,40(sp)
    800052c8:	7a02                	ld	s4,32(sp)
    800052ca:	6ae2                	ld	s5,24(sp)
    800052cc:	6b42                	ld	s6,16(sp)
    800052ce:	6161                	addi	sp,sp,80
    800052d0:	8082                	ret
      release(&pi->lock);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	9c4080e7          	jalr	-1596(ra) # 80000c98 <release>
      return -1;
    800052dc:	59fd                	li	s3,-1
    800052de:	bff9                	j	800052bc <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052e0:	4981                	li	s3,0
    800052e2:	b7d1                	j	800052a6 <piperead+0xae>

00000000800052e4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052e4:	df010113          	addi	sp,sp,-528
    800052e8:	20113423          	sd	ra,520(sp)
    800052ec:	20813023          	sd	s0,512(sp)
    800052f0:	ffa6                	sd	s1,504(sp)
    800052f2:	fbca                	sd	s2,496(sp)
    800052f4:	f7ce                	sd	s3,488(sp)
    800052f6:	f3d2                	sd	s4,480(sp)
    800052f8:	efd6                	sd	s5,472(sp)
    800052fa:	ebda                	sd	s6,464(sp)
    800052fc:	e7de                	sd	s7,456(sp)
    800052fe:	e3e2                	sd	s8,448(sp)
    80005300:	ff66                	sd	s9,440(sp)
    80005302:	fb6a                	sd	s10,432(sp)
    80005304:	f76e                	sd	s11,424(sp)
    80005306:	0c00                	addi	s0,sp,528
    80005308:	84aa                	mv	s1,a0
    8000530a:	dea43c23          	sd	a0,-520(s0)
    8000530e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	b24080e7          	jalr	-1244(ra) # 80001e36 <myproc>
    8000531a:	892a                	mv	s2,a0

  begin_op();
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	49c080e7          	jalr	1180(ra) # 800047b8 <begin_op>

  if((ip = namei(path)) == 0){
    80005324:	8526                	mv	a0,s1
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	276080e7          	jalr	630(ra) # 8000459c <namei>
    8000532e:	c92d                	beqz	a0,800053a0 <exec+0xbc>
    80005330:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	ab4080e7          	jalr	-1356(ra) # 80003de6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000533a:	04000713          	li	a4,64
    8000533e:	4681                	li	a3,0
    80005340:	e5040613          	addi	a2,s0,-432
    80005344:	4581                	li	a1,0
    80005346:	8526                	mv	a0,s1
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	d52080e7          	jalr	-686(ra) # 8000409a <readi>
    80005350:	04000793          	li	a5,64
    80005354:	00f51a63          	bne	a0,a5,80005368 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005358:	e5042703          	lw	a4,-432(s0)
    8000535c:	464c47b7          	lui	a5,0x464c4
    80005360:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005364:	04f70463          	beq	a4,a5,800053ac <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005368:	8526                	mv	a0,s1
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	cde080e7          	jalr	-802(ra) # 80004048 <iunlockput>
    end_op();
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	4c6080e7          	jalr	1222(ra) # 80004838 <end_op>
  }
  return -1;
    8000537a:	557d                	li	a0,-1
}
    8000537c:	20813083          	ld	ra,520(sp)
    80005380:	20013403          	ld	s0,512(sp)
    80005384:	74fe                	ld	s1,504(sp)
    80005386:	795e                	ld	s2,496(sp)
    80005388:	79be                	ld	s3,488(sp)
    8000538a:	7a1e                	ld	s4,480(sp)
    8000538c:	6afe                	ld	s5,472(sp)
    8000538e:	6b5e                	ld	s6,464(sp)
    80005390:	6bbe                	ld	s7,456(sp)
    80005392:	6c1e                	ld	s8,448(sp)
    80005394:	7cfa                	ld	s9,440(sp)
    80005396:	7d5a                	ld	s10,432(sp)
    80005398:	7dba                	ld	s11,424(sp)
    8000539a:	21010113          	addi	sp,sp,528
    8000539e:	8082                	ret
    end_op();
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	498080e7          	jalr	1176(ra) # 80004838 <end_op>
    return -1;
    800053a8:	557d                	li	a0,-1
    800053aa:	bfc9                	j	8000537c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053ac:	854a                	mv	a0,s2
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	b46080e7          	jalr	-1210(ra) # 80001ef4 <proc_pagetable>
    800053b6:	8baa                	mv	s7,a0
    800053b8:	d945                	beqz	a0,80005368 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ba:	e7042983          	lw	s3,-400(s0)
    800053be:	e8845783          	lhu	a5,-376(s0)
    800053c2:	c7ad                	beqz	a5,8000542c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053c4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053c6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053c8:	6c85                	lui	s9,0x1
    800053ca:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053ce:	def43823          	sd	a5,-528(s0)
    800053d2:	a42d                	j	800055fc <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053d4:	00003517          	auipc	a0,0x3
    800053d8:	43450513          	addi	a0,a0,1076 # 80008808 <syscalls+0x298>
    800053dc:	ffffb097          	auipc	ra,0xffffb
    800053e0:	162080e7          	jalr	354(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053e4:	8756                	mv	a4,s5
    800053e6:	012d86bb          	addw	a3,s11,s2
    800053ea:	4581                	li	a1,0
    800053ec:	8526                	mv	a0,s1
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	cac080e7          	jalr	-852(ra) # 8000409a <readi>
    800053f6:	2501                	sext.w	a0,a0
    800053f8:	1aaa9963          	bne	s5,a0,800055aa <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053fc:	6785                	lui	a5,0x1
    800053fe:	0127893b          	addw	s2,a5,s2
    80005402:	77fd                	lui	a5,0xfffff
    80005404:	01478a3b          	addw	s4,a5,s4
    80005408:	1f897163          	bgeu	s2,s8,800055ea <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000540c:	02091593          	slli	a1,s2,0x20
    80005410:	9181                	srli	a1,a1,0x20
    80005412:	95ea                	add	a1,a1,s10
    80005414:	855e                	mv	a0,s7
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	c58080e7          	jalr	-936(ra) # 8000106e <walkaddr>
    8000541e:	862a                	mv	a2,a0
    if(pa == 0)
    80005420:	d955                	beqz	a0,800053d4 <exec+0xf0>
      n = PGSIZE;
    80005422:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005424:	fd9a70e3          	bgeu	s4,s9,800053e4 <exec+0x100>
      n = sz - i;
    80005428:	8ad2                	mv	s5,s4
    8000542a:	bf6d                	j	800053e4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000542c:	4901                	li	s2,0
  iunlockput(ip);
    8000542e:	8526                	mv	a0,s1
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	c18080e7          	jalr	-1000(ra) # 80004048 <iunlockput>
  end_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	400080e7          	jalr	1024(ra) # 80004838 <end_op>
  p = myproc();
    80005440:	ffffd097          	auipc	ra,0xffffd
    80005444:	9f6080e7          	jalr	-1546(ra) # 80001e36 <myproc>
    80005448:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000544a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000544e:	6785                	lui	a5,0x1
    80005450:	17fd                	addi	a5,a5,-1
    80005452:	993e                	add	s2,s2,a5
    80005454:	757d                	lui	a0,0xfffff
    80005456:	00a977b3          	and	a5,s2,a0
    8000545a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000545e:	6609                	lui	a2,0x2
    80005460:	963e                	add	a2,a2,a5
    80005462:	85be                	mv	a1,a5
    80005464:	855e                	mv	a0,s7
    80005466:	ffffc097          	auipc	ra,0xffffc
    8000546a:	fbc080e7          	jalr	-68(ra) # 80001422 <uvmalloc>
    8000546e:	8b2a                	mv	s6,a0
  ip = 0;
    80005470:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005472:	12050c63          	beqz	a0,800055aa <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005476:	75f9                	lui	a1,0xffffe
    80005478:	95aa                	add	a1,a1,a0
    8000547a:	855e                	mv	a0,s7
    8000547c:	ffffc097          	auipc	ra,0xffffc
    80005480:	1c4080e7          	jalr	452(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005484:	7c7d                	lui	s8,0xfffff
    80005486:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005488:	e0043783          	ld	a5,-512(s0)
    8000548c:	6388                	ld	a0,0(a5)
    8000548e:	c535                	beqz	a0,800054fa <exec+0x216>
    80005490:	e9040993          	addi	s3,s0,-368
    80005494:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005498:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	9ca080e7          	jalr	-1590(ra) # 80000e64 <strlen>
    800054a2:	2505                	addiw	a0,a0,1
    800054a4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054a8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054ac:	13896363          	bltu	s2,s8,800055d2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054b0:	e0043d83          	ld	s11,-512(s0)
    800054b4:	000dba03          	ld	s4,0(s11)
    800054b8:	8552                	mv	a0,s4
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	9aa080e7          	jalr	-1622(ra) # 80000e64 <strlen>
    800054c2:	0015069b          	addiw	a3,a0,1
    800054c6:	8652                	mv	a2,s4
    800054c8:	85ca                	mv	a1,s2
    800054ca:	855e                	mv	a0,s7
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	1a6080e7          	jalr	422(ra) # 80001672 <copyout>
    800054d4:	10054363          	bltz	a0,800055da <exec+0x2f6>
    ustack[argc] = sp;
    800054d8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054dc:	0485                	addi	s1,s1,1
    800054de:	008d8793          	addi	a5,s11,8
    800054e2:	e0f43023          	sd	a5,-512(s0)
    800054e6:	008db503          	ld	a0,8(s11)
    800054ea:	c911                	beqz	a0,800054fe <exec+0x21a>
    if(argc >= MAXARG)
    800054ec:	09a1                	addi	s3,s3,8
    800054ee:	fb3c96e3          	bne	s9,s3,8000549a <exec+0x1b6>
  sz = sz1;
    800054f2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054f6:	4481                	li	s1,0
    800054f8:	a84d                	j	800055aa <exec+0x2c6>
  sp = sz;
    800054fa:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054fc:	4481                	li	s1,0
  ustack[argc] = 0;
    800054fe:	00349793          	slli	a5,s1,0x3
    80005502:	f9040713          	addi	a4,s0,-112
    80005506:	97ba                	add	a5,a5,a4
    80005508:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000550c:	00148693          	addi	a3,s1,1
    80005510:	068e                	slli	a3,a3,0x3
    80005512:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005516:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000551a:	01897663          	bgeu	s2,s8,80005526 <exec+0x242>
  sz = sz1;
    8000551e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005522:	4481                	li	s1,0
    80005524:	a059                	j	800055aa <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005526:	e9040613          	addi	a2,s0,-368
    8000552a:	85ca                	mv	a1,s2
    8000552c:	855e                	mv	a0,s7
    8000552e:	ffffc097          	auipc	ra,0xffffc
    80005532:	144080e7          	jalr	324(ra) # 80001672 <copyout>
    80005536:	0a054663          	bltz	a0,800055e2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000553a:	058ab783          	ld	a5,88(s5)
    8000553e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005542:	df843783          	ld	a5,-520(s0)
    80005546:	0007c703          	lbu	a4,0(a5)
    8000554a:	cf11                	beqz	a4,80005566 <exec+0x282>
    8000554c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000554e:	02f00693          	li	a3,47
    80005552:	a039                	j	80005560 <exec+0x27c>
      last = s+1;
    80005554:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005558:	0785                	addi	a5,a5,1
    8000555a:	fff7c703          	lbu	a4,-1(a5)
    8000555e:	c701                	beqz	a4,80005566 <exec+0x282>
    if(*s == '/')
    80005560:	fed71ce3          	bne	a4,a3,80005558 <exec+0x274>
    80005564:	bfc5                	j	80005554 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005566:	4641                	li	a2,16
    80005568:	df843583          	ld	a1,-520(s0)
    8000556c:	158a8513          	addi	a0,s5,344
    80005570:	ffffc097          	auipc	ra,0xffffc
    80005574:	8c2080e7          	jalr	-1854(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005578:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000557c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005580:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005584:	058ab783          	ld	a5,88(s5)
    80005588:	e6843703          	ld	a4,-408(s0)
    8000558c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000558e:	058ab783          	ld	a5,88(s5)
    80005592:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005596:	85ea                	mv	a1,s10
    80005598:	ffffd097          	auipc	ra,0xffffd
    8000559c:	9f8080e7          	jalr	-1544(ra) # 80001f90 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055a0:	0004851b          	sext.w	a0,s1
    800055a4:	bbe1                	j	8000537c <exec+0x98>
    800055a6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055aa:	e0843583          	ld	a1,-504(s0)
    800055ae:	855e                	mv	a0,s7
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	9e0080e7          	jalr	-1568(ra) # 80001f90 <proc_freepagetable>
  if(ip){
    800055b8:	da0498e3          	bnez	s1,80005368 <exec+0x84>
  return -1;
    800055bc:	557d                	li	a0,-1
    800055be:	bb7d                	j	8000537c <exec+0x98>
    800055c0:	e1243423          	sd	s2,-504(s0)
    800055c4:	b7dd                	j	800055aa <exec+0x2c6>
    800055c6:	e1243423          	sd	s2,-504(s0)
    800055ca:	b7c5                	j	800055aa <exec+0x2c6>
    800055cc:	e1243423          	sd	s2,-504(s0)
    800055d0:	bfe9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d6:	4481                	li	s1,0
    800055d8:	bfc9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055da:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055de:	4481                	li	s1,0
    800055e0:	b7e9                	j	800055aa <exec+0x2c6>
  sz = sz1;
    800055e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055e6:	4481                	li	s1,0
    800055e8:	b7c9                	j	800055aa <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055ea:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055ee:	2b05                	addiw	s6,s6,1
    800055f0:	0389899b          	addiw	s3,s3,56
    800055f4:	e8845783          	lhu	a5,-376(s0)
    800055f8:	e2fb5be3          	bge	s6,a5,8000542e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055fc:	2981                	sext.w	s3,s3
    800055fe:	03800713          	li	a4,56
    80005602:	86ce                	mv	a3,s3
    80005604:	e1840613          	addi	a2,s0,-488
    80005608:	4581                	li	a1,0
    8000560a:	8526                	mv	a0,s1
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	a8e080e7          	jalr	-1394(ra) # 8000409a <readi>
    80005614:	03800793          	li	a5,56
    80005618:	f8f517e3          	bne	a0,a5,800055a6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000561c:	e1842783          	lw	a5,-488(s0)
    80005620:	4705                	li	a4,1
    80005622:	fce796e3          	bne	a5,a4,800055ee <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005626:	e4043603          	ld	a2,-448(s0)
    8000562a:	e3843783          	ld	a5,-456(s0)
    8000562e:	f8f669e3          	bltu	a2,a5,800055c0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005632:	e2843783          	ld	a5,-472(s0)
    80005636:	963e                	add	a2,a2,a5
    80005638:	f8f667e3          	bltu	a2,a5,800055c6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000563c:	85ca                	mv	a1,s2
    8000563e:	855e                	mv	a0,s7
    80005640:	ffffc097          	auipc	ra,0xffffc
    80005644:	de2080e7          	jalr	-542(ra) # 80001422 <uvmalloc>
    80005648:	e0a43423          	sd	a0,-504(s0)
    8000564c:	d141                	beqz	a0,800055cc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000564e:	e2843d03          	ld	s10,-472(s0)
    80005652:	df043783          	ld	a5,-528(s0)
    80005656:	00fd77b3          	and	a5,s10,a5
    8000565a:	fba1                	bnez	a5,800055aa <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000565c:	e2042d83          	lw	s11,-480(s0)
    80005660:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005664:	f80c03e3          	beqz	s8,800055ea <exec+0x306>
    80005668:	8a62                	mv	s4,s8
    8000566a:	4901                	li	s2,0
    8000566c:	b345                	j	8000540c <exec+0x128>

000000008000566e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000566e:	7179                	addi	sp,sp,-48
    80005670:	f406                	sd	ra,40(sp)
    80005672:	f022                	sd	s0,32(sp)
    80005674:	ec26                	sd	s1,24(sp)
    80005676:	e84a                	sd	s2,16(sp)
    80005678:	1800                	addi	s0,sp,48
    8000567a:	892e                	mv	s2,a1
    8000567c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000567e:	fdc40593          	addi	a1,s0,-36
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	b76080e7          	jalr	-1162(ra) # 800031f8 <argint>
    8000568a:	04054063          	bltz	a0,800056ca <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000568e:	fdc42703          	lw	a4,-36(s0)
    80005692:	47bd                	li	a5,15
    80005694:	02e7ed63          	bltu	a5,a4,800056ce <argfd+0x60>
    80005698:	ffffc097          	auipc	ra,0xffffc
    8000569c:	79e080e7          	jalr	1950(ra) # 80001e36 <myproc>
    800056a0:	fdc42703          	lw	a4,-36(s0)
    800056a4:	01a70793          	addi	a5,a4,26
    800056a8:	078e                	slli	a5,a5,0x3
    800056aa:	953e                	add	a0,a0,a5
    800056ac:	611c                	ld	a5,0(a0)
    800056ae:	c395                	beqz	a5,800056d2 <argfd+0x64>
    return -1;
  if(pfd)
    800056b0:	00090463          	beqz	s2,800056b8 <argfd+0x4a>
    *pfd = fd;
    800056b4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056b8:	4501                	li	a0,0
  if(pf)
    800056ba:	c091                	beqz	s1,800056be <argfd+0x50>
    *pf = f;
    800056bc:	e09c                	sd	a5,0(s1)
}
    800056be:	70a2                	ld	ra,40(sp)
    800056c0:	7402                	ld	s0,32(sp)
    800056c2:	64e2                	ld	s1,24(sp)
    800056c4:	6942                	ld	s2,16(sp)
    800056c6:	6145                	addi	sp,sp,48
    800056c8:	8082                	ret
    return -1;
    800056ca:	557d                	li	a0,-1
    800056cc:	bfcd                	j	800056be <argfd+0x50>
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	b7fd                	j	800056be <argfd+0x50>
    800056d2:	557d                	li	a0,-1
    800056d4:	b7ed                	j	800056be <argfd+0x50>

00000000800056d6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056d6:	1101                	addi	sp,sp,-32
    800056d8:	ec06                	sd	ra,24(sp)
    800056da:	e822                	sd	s0,16(sp)
    800056dc:	e426                	sd	s1,8(sp)
    800056de:	1000                	addi	s0,sp,32
    800056e0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056e2:	ffffc097          	auipc	ra,0xffffc
    800056e6:	754080e7          	jalr	1876(ra) # 80001e36 <myproc>
    800056ea:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ec:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800056f0:	4501                	li	a0,0
    800056f2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056f4:	6398                	ld	a4,0(a5)
    800056f6:	cb19                	beqz	a4,8000570c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056f8:	2505                	addiw	a0,a0,1
    800056fa:	07a1                	addi	a5,a5,8
    800056fc:	fed51ce3          	bne	a0,a3,800056f4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005700:	557d                	li	a0,-1
}
    80005702:	60e2                	ld	ra,24(sp)
    80005704:	6442                	ld	s0,16(sp)
    80005706:	64a2                	ld	s1,8(sp)
    80005708:	6105                	addi	sp,sp,32
    8000570a:	8082                	ret
      p->ofile[fd] = f;
    8000570c:	01a50793          	addi	a5,a0,26
    80005710:	078e                	slli	a5,a5,0x3
    80005712:	963e                	add	a2,a2,a5
    80005714:	e204                	sd	s1,0(a2)
      return fd;
    80005716:	b7f5                	j	80005702 <fdalloc+0x2c>

0000000080005718 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005718:	715d                	addi	sp,sp,-80
    8000571a:	e486                	sd	ra,72(sp)
    8000571c:	e0a2                	sd	s0,64(sp)
    8000571e:	fc26                	sd	s1,56(sp)
    80005720:	f84a                	sd	s2,48(sp)
    80005722:	f44e                	sd	s3,40(sp)
    80005724:	f052                	sd	s4,32(sp)
    80005726:	ec56                	sd	s5,24(sp)
    80005728:	0880                	addi	s0,sp,80
    8000572a:	89ae                	mv	s3,a1
    8000572c:	8ab2                	mv	s5,a2
    8000572e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	e86080e7          	jalr	-378(ra) # 800045ba <nameiparent>
    8000573c:	892a                	mv	s2,a0
    8000573e:	12050f63          	beqz	a0,8000587c <create+0x164>
    return 0;

  ilock(dp);
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	6a4080e7          	jalr	1700(ra) # 80003de6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000574a:	4601                	li	a2,0
    8000574c:	fb040593          	addi	a1,s0,-80
    80005750:	854a                	mv	a0,s2
    80005752:	fffff097          	auipc	ra,0xfffff
    80005756:	b78080e7          	jalr	-1160(ra) # 800042ca <dirlookup>
    8000575a:	84aa                	mv	s1,a0
    8000575c:	c921                	beqz	a0,800057ac <create+0x94>
    iunlockput(dp);
    8000575e:	854a                	mv	a0,s2
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	8e8080e7          	jalr	-1816(ra) # 80004048 <iunlockput>
    ilock(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	67c080e7          	jalr	1660(ra) # 80003de6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005772:	2981                	sext.w	s3,s3
    80005774:	4789                	li	a5,2
    80005776:	02f99463          	bne	s3,a5,8000579e <create+0x86>
    8000577a:	0444d783          	lhu	a5,68(s1)
    8000577e:	37f9                	addiw	a5,a5,-2
    80005780:	17c2                	slli	a5,a5,0x30
    80005782:	93c1                	srli	a5,a5,0x30
    80005784:	4705                	li	a4,1
    80005786:	00f76c63          	bltu	a4,a5,8000579e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000578a:	8526                	mv	a0,s1
    8000578c:	60a6                	ld	ra,72(sp)
    8000578e:	6406                	ld	s0,64(sp)
    80005790:	74e2                	ld	s1,56(sp)
    80005792:	7942                	ld	s2,48(sp)
    80005794:	79a2                	ld	s3,40(sp)
    80005796:	7a02                	ld	s4,32(sp)
    80005798:	6ae2                	ld	s5,24(sp)
    8000579a:	6161                	addi	sp,sp,80
    8000579c:	8082                	ret
    iunlockput(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	8a8080e7          	jalr	-1880(ra) # 80004048 <iunlockput>
    return 0;
    800057a8:	4481                	li	s1,0
    800057aa:	b7c5                	j	8000578a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057ac:	85ce                	mv	a1,s3
    800057ae:	00092503          	lw	a0,0(s2)
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	49c080e7          	jalr	1180(ra) # 80003c4e <ialloc>
    800057ba:	84aa                	mv	s1,a0
    800057bc:	c529                	beqz	a0,80005806 <create+0xee>
  ilock(ip);
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	628080e7          	jalr	1576(ra) # 80003de6 <ilock>
  ip->major = major;
    800057c6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057ca:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057ce:	4785                	li	a5,1
    800057d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	546080e7          	jalr	1350(ra) # 80003d1c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057de:	2981                	sext.w	s3,s3
    800057e0:	4785                	li	a5,1
    800057e2:	02f98a63          	beq	s3,a5,80005816 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057e6:	40d0                	lw	a2,4(s1)
    800057e8:	fb040593          	addi	a1,s0,-80
    800057ec:	854a                	mv	a0,s2
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	cec080e7          	jalr	-788(ra) # 800044da <dirlink>
    800057f6:	06054b63          	bltz	a0,8000586c <create+0x154>
  iunlockput(dp);
    800057fa:	854a                	mv	a0,s2
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	84c080e7          	jalr	-1972(ra) # 80004048 <iunlockput>
  return ip;
    80005804:	b759                	j	8000578a <create+0x72>
    panic("create: ialloc");
    80005806:	00003517          	auipc	a0,0x3
    8000580a:	02250513          	addi	a0,a0,34 # 80008828 <syscalls+0x2b8>
    8000580e:	ffffb097          	auipc	ra,0xffffb
    80005812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005816:	04a95783          	lhu	a5,74(s2)
    8000581a:	2785                	addiw	a5,a5,1
    8000581c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	4fa080e7          	jalr	1274(ra) # 80003d1c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000582a:	40d0                	lw	a2,4(s1)
    8000582c:	00003597          	auipc	a1,0x3
    80005830:	00c58593          	addi	a1,a1,12 # 80008838 <syscalls+0x2c8>
    80005834:	8526                	mv	a0,s1
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	ca4080e7          	jalr	-860(ra) # 800044da <dirlink>
    8000583e:	00054f63          	bltz	a0,8000585c <create+0x144>
    80005842:	00492603          	lw	a2,4(s2)
    80005846:	00003597          	auipc	a1,0x3
    8000584a:	ffa58593          	addi	a1,a1,-6 # 80008840 <syscalls+0x2d0>
    8000584e:	8526                	mv	a0,s1
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	c8a080e7          	jalr	-886(ra) # 800044da <dirlink>
    80005858:	f80557e3          	bgez	a0,800057e6 <create+0xce>
      panic("create dots");
    8000585c:	00003517          	auipc	a0,0x3
    80005860:	fec50513          	addi	a0,a0,-20 # 80008848 <syscalls+0x2d8>
    80005864:	ffffb097          	auipc	ra,0xffffb
    80005868:	cda080e7          	jalr	-806(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000586c:	00003517          	auipc	a0,0x3
    80005870:	fec50513          	addi	a0,a0,-20 # 80008858 <syscalls+0x2e8>
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	cca080e7          	jalr	-822(ra) # 8000053e <panic>
    return 0;
    8000587c:	84aa                	mv	s1,a0
    8000587e:	b731                	j	8000578a <create+0x72>

0000000080005880 <sys_dup>:
{
    80005880:	7179                	addi	sp,sp,-48
    80005882:	f406                	sd	ra,40(sp)
    80005884:	f022                	sd	s0,32(sp)
    80005886:	ec26                	sd	s1,24(sp)
    80005888:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000588a:	fd840613          	addi	a2,s0,-40
    8000588e:	4581                	li	a1,0
    80005890:	4501                	li	a0,0
    80005892:	00000097          	auipc	ra,0x0
    80005896:	ddc080e7          	jalr	-548(ra) # 8000566e <argfd>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000589c:	02054363          	bltz	a0,800058c2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058a0:	fd843503          	ld	a0,-40(s0)
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	e32080e7          	jalr	-462(ra) # 800056d6 <fdalloc>
    800058ac:	84aa                	mv	s1,a0
    return -1;
    800058ae:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058b0:	00054963          	bltz	a0,800058c2 <sys_dup+0x42>
  filedup(f);
    800058b4:	fd843503          	ld	a0,-40(s0)
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	37a080e7          	jalr	890(ra) # 80004c32 <filedup>
  return fd;
    800058c0:	87a6                	mv	a5,s1
}
    800058c2:	853e                	mv	a0,a5
    800058c4:	70a2                	ld	ra,40(sp)
    800058c6:	7402                	ld	s0,32(sp)
    800058c8:	64e2                	ld	s1,24(sp)
    800058ca:	6145                	addi	sp,sp,48
    800058cc:	8082                	ret

00000000800058ce <sys_read>:
{
    800058ce:	7179                	addi	sp,sp,-48
    800058d0:	f406                	sd	ra,40(sp)
    800058d2:	f022                	sd	s0,32(sp)
    800058d4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d6:	fe840613          	addi	a2,s0,-24
    800058da:	4581                	li	a1,0
    800058dc:	4501                	li	a0,0
    800058de:	00000097          	auipc	ra,0x0
    800058e2:	d90080e7          	jalr	-624(ra) # 8000566e <argfd>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e8:	04054163          	bltz	a0,8000592a <sys_read+0x5c>
    800058ec:	fe440593          	addi	a1,s0,-28
    800058f0:	4509                	li	a0,2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	906080e7          	jalr	-1786(ra) # 800031f8 <argint>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fc:	02054763          	bltz	a0,8000592a <sys_read+0x5c>
    80005900:	fd840593          	addi	a1,s0,-40
    80005904:	4505                	li	a0,1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	914080e7          	jalr	-1772(ra) # 8000321a <argaddr>
    return -1;
    8000590e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005910:	00054d63          	bltz	a0,8000592a <sys_read+0x5c>
  return fileread(f, p, n);
    80005914:	fe442603          	lw	a2,-28(s0)
    80005918:	fd843583          	ld	a1,-40(s0)
    8000591c:	fe843503          	ld	a0,-24(s0)
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	49e080e7          	jalr	1182(ra) # 80004dbe <fileread>
    80005928:	87aa                	mv	a5,a0
}
    8000592a:	853e                	mv	a0,a5
    8000592c:	70a2                	ld	ra,40(sp)
    8000592e:	7402                	ld	s0,32(sp)
    80005930:	6145                	addi	sp,sp,48
    80005932:	8082                	ret

0000000080005934 <sys_write>:
{
    80005934:	7179                	addi	sp,sp,-48
    80005936:	f406                	sd	ra,40(sp)
    80005938:	f022                	sd	s0,32(sp)
    8000593a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593c:	fe840613          	addi	a2,s0,-24
    80005940:	4581                	li	a1,0
    80005942:	4501                	li	a0,0
    80005944:	00000097          	auipc	ra,0x0
    80005948:	d2a080e7          	jalr	-726(ra) # 8000566e <argfd>
    return -1;
    8000594c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594e:	04054163          	bltz	a0,80005990 <sys_write+0x5c>
    80005952:	fe440593          	addi	a1,s0,-28
    80005956:	4509                	li	a0,2
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	8a0080e7          	jalr	-1888(ra) # 800031f8 <argint>
    return -1;
    80005960:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005962:	02054763          	bltz	a0,80005990 <sys_write+0x5c>
    80005966:	fd840593          	addi	a1,s0,-40
    8000596a:	4505                	li	a0,1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	8ae080e7          	jalr	-1874(ra) # 8000321a <argaddr>
    return -1;
    80005974:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005976:	00054d63          	bltz	a0,80005990 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000597a:	fe442603          	lw	a2,-28(s0)
    8000597e:	fd843583          	ld	a1,-40(s0)
    80005982:	fe843503          	ld	a0,-24(s0)
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	4fa080e7          	jalr	1274(ra) # 80004e80 <filewrite>
    8000598e:	87aa                	mv	a5,a0
}
    80005990:	853e                	mv	a0,a5
    80005992:	70a2                	ld	ra,40(sp)
    80005994:	7402                	ld	s0,32(sp)
    80005996:	6145                	addi	sp,sp,48
    80005998:	8082                	ret

000000008000599a <sys_close>:
{
    8000599a:	1101                	addi	sp,sp,-32
    8000599c:	ec06                	sd	ra,24(sp)
    8000599e:	e822                	sd	s0,16(sp)
    800059a0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059a2:	fe040613          	addi	a2,s0,-32
    800059a6:	fec40593          	addi	a1,s0,-20
    800059aa:	4501                	li	a0,0
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	cc2080e7          	jalr	-830(ra) # 8000566e <argfd>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059b6:	02054463          	bltz	a0,800059de <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059ba:	ffffc097          	auipc	ra,0xffffc
    800059be:	47c080e7          	jalr	1148(ra) # 80001e36 <myproc>
    800059c2:	fec42783          	lw	a5,-20(s0)
    800059c6:	07e9                	addi	a5,a5,26
    800059c8:	078e                	slli	a5,a5,0x3
    800059ca:	97aa                	add	a5,a5,a0
    800059cc:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059d0:	fe043503          	ld	a0,-32(s0)
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	2b0080e7          	jalr	688(ra) # 80004c84 <fileclose>
  return 0;
    800059dc:	4781                	li	a5,0
}
    800059de:	853e                	mv	a0,a5
    800059e0:	60e2                	ld	ra,24(sp)
    800059e2:	6442                	ld	s0,16(sp)
    800059e4:	6105                	addi	sp,sp,32
    800059e6:	8082                	ret

00000000800059e8 <sys_fstat>:
{
    800059e8:	1101                	addi	sp,sp,-32
    800059ea:	ec06                	sd	ra,24(sp)
    800059ec:	e822                	sd	s0,16(sp)
    800059ee:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059f0:	fe840613          	addi	a2,s0,-24
    800059f4:	4581                	li	a1,0
    800059f6:	4501                	li	a0,0
    800059f8:	00000097          	auipc	ra,0x0
    800059fc:	c76080e7          	jalr	-906(ra) # 8000566e <argfd>
    return -1;
    80005a00:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a02:	02054563          	bltz	a0,80005a2c <sys_fstat+0x44>
    80005a06:	fe040593          	addi	a1,s0,-32
    80005a0a:	4505                	li	a0,1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	80e080e7          	jalr	-2034(ra) # 8000321a <argaddr>
    return -1;
    80005a14:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a16:	00054b63          	bltz	a0,80005a2c <sys_fstat+0x44>
  return filestat(f, st);
    80005a1a:	fe043583          	ld	a1,-32(s0)
    80005a1e:	fe843503          	ld	a0,-24(s0)
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	32a080e7          	jalr	810(ra) # 80004d4c <filestat>
    80005a2a:	87aa                	mv	a5,a0
}
    80005a2c:	853e                	mv	a0,a5
    80005a2e:	60e2                	ld	ra,24(sp)
    80005a30:	6442                	ld	s0,16(sp)
    80005a32:	6105                	addi	sp,sp,32
    80005a34:	8082                	ret

0000000080005a36 <sys_link>:
{
    80005a36:	7169                	addi	sp,sp,-304
    80005a38:	f606                	sd	ra,296(sp)
    80005a3a:	f222                	sd	s0,288(sp)
    80005a3c:	ee26                	sd	s1,280(sp)
    80005a3e:	ea4a                	sd	s2,272(sp)
    80005a40:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a42:	08000613          	li	a2,128
    80005a46:	ed040593          	addi	a1,s0,-304
    80005a4a:	4501                	li	a0,0
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	7f0080e7          	jalr	2032(ra) # 8000323c <argstr>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a56:	10054e63          	bltz	a0,80005b72 <sys_link+0x13c>
    80005a5a:	08000613          	li	a2,128
    80005a5e:	f5040593          	addi	a1,s0,-176
    80005a62:	4505                	li	a0,1
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	7d8080e7          	jalr	2008(ra) # 8000323c <argstr>
    return -1;
    80005a6c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a6e:	10054263          	bltz	a0,80005b72 <sys_link+0x13c>
  begin_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	d46080e7          	jalr	-698(ra) # 800047b8 <begin_op>
  if((ip = namei(old)) == 0){
    80005a7a:	ed040513          	addi	a0,s0,-304
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	b1e080e7          	jalr	-1250(ra) # 8000459c <namei>
    80005a86:	84aa                	mv	s1,a0
    80005a88:	c551                	beqz	a0,80005b14 <sys_link+0xde>
  ilock(ip);
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	35c080e7          	jalr	860(ra) # 80003de6 <ilock>
  if(ip->type == T_DIR){
    80005a92:	04449703          	lh	a4,68(s1)
    80005a96:	4785                	li	a5,1
    80005a98:	08f70463          	beq	a4,a5,80005b20 <sys_link+0xea>
  ip->nlink++;
    80005a9c:	04a4d783          	lhu	a5,74(s1)
    80005aa0:	2785                	addiw	a5,a5,1
    80005aa2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	274080e7          	jalr	628(ra) # 80003d1c <iupdate>
  iunlock(ip);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	3f6080e7          	jalr	1014(ra) # 80003ea8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aba:	fd040593          	addi	a1,s0,-48
    80005abe:	f5040513          	addi	a0,s0,-176
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	af8080e7          	jalr	-1288(ra) # 800045ba <nameiparent>
    80005aca:	892a                	mv	s2,a0
    80005acc:	c935                	beqz	a0,80005b40 <sys_link+0x10a>
  ilock(dp);
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	318080e7          	jalr	792(ra) # 80003de6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ad6:	00092703          	lw	a4,0(s2)
    80005ada:	409c                	lw	a5,0(s1)
    80005adc:	04f71d63          	bne	a4,a5,80005b36 <sys_link+0x100>
    80005ae0:	40d0                	lw	a2,4(s1)
    80005ae2:	fd040593          	addi	a1,s0,-48
    80005ae6:	854a                	mv	a0,s2
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	9f2080e7          	jalr	-1550(ra) # 800044da <dirlink>
    80005af0:	04054363          	bltz	a0,80005b36 <sys_link+0x100>
  iunlockput(dp);
    80005af4:	854a                	mv	a0,s2
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	552080e7          	jalr	1362(ra) # 80004048 <iunlockput>
  iput(ip);
    80005afe:	8526                	mv	a0,s1
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	4a0080e7          	jalr	1184(ra) # 80003fa0 <iput>
  end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	d30080e7          	jalr	-720(ra) # 80004838 <end_op>
  return 0;
    80005b10:	4781                	li	a5,0
    80005b12:	a085                	j	80005b72 <sys_link+0x13c>
    end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	d24080e7          	jalr	-732(ra) # 80004838 <end_op>
    return -1;
    80005b1c:	57fd                	li	a5,-1
    80005b1e:	a891                	j	80005b72 <sys_link+0x13c>
    iunlockput(ip);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	526080e7          	jalr	1318(ra) # 80004048 <iunlockput>
    end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	d0e080e7          	jalr	-754(ra) # 80004838 <end_op>
    return -1;
    80005b32:	57fd                	li	a5,-1
    80005b34:	a83d                	j	80005b72 <sys_link+0x13c>
    iunlockput(dp);
    80005b36:	854a                	mv	a0,s2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	510080e7          	jalr	1296(ra) # 80004048 <iunlockput>
  ilock(ip);
    80005b40:	8526                	mv	a0,s1
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	2a4080e7          	jalr	676(ra) # 80003de6 <ilock>
  ip->nlink--;
    80005b4a:	04a4d783          	lhu	a5,74(s1)
    80005b4e:	37fd                	addiw	a5,a5,-1
    80005b50:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b54:	8526                	mv	a0,s1
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	1c6080e7          	jalr	454(ra) # 80003d1c <iupdate>
  iunlockput(ip);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	4e8080e7          	jalr	1256(ra) # 80004048 <iunlockput>
  end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	cd0080e7          	jalr	-816(ra) # 80004838 <end_op>
  return -1;
    80005b70:	57fd                	li	a5,-1
}
    80005b72:	853e                	mv	a0,a5
    80005b74:	70b2                	ld	ra,296(sp)
    80005b76:	7412                	ld	s0,288(sp)
    80005b78:	64f2                	ld	s1,280(sp)
    80005b7a:	6952                	ld	s2,272(sp)
    80005b7c:	6155                	addi	sp,sp,304
    80005b7e:	8082                	ret

0000000080005b80 <sys_unlink>:
{
    80005b80:	7151                	addi	sp,sp,-240
    80005b82:	f586                	sd	ra,232(sp)
    80005b84:	f1a2                	sd	s0,224(sp)
    80005b86:	eda6                	sd	s1,216(sp)
    80005b88:	e9ca                	sd	s2,208(sp)
    80005b8a:	e5ce                	sd	s3,200(sp)
    80005b8c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b8e:	08000613          	li	a2,128
    80005b92:	f3040593          	addi	a1,s0,-208
    80005b96:	4501                	li	a0,0
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	6a4080e7          	jalr	1700(ra) # 8000323c <argstr>
    80005ba0:	18054163          	bltz	a0,80005d22 <sys_unlink+0x1a2>
  begin_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	c14080e7          	jalr	-1004(ra) # 800047b8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bac:	fb040593          	addi	a1,s0,-80
    80005bb0:	f3040513          	addi	a0,s0,-208
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	a06080e7          	jalr	-1530(ra) # 800045ba <nameiparent>
    80005bbc:	84aa                	mv	s1,a0
    80005bbe:	c979                	beqz	a0,80005c94 <sys_unlink+0x114>
  ilock(dp);
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	226080e7          	jalr	550(ra) # 80003de6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bc8:	00003597          	auipc	a1,0x3
    80005bcc:	c7058593          	addi	a1,a1,-912 # 80008838 <syscalls+0x2c8>
    80005bd0:	fb040513          	addi	a0,s0,-80
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	6dc080e7          	jalr	1756(ra) # 800042b0 <namecmp>
    80005bdc:	14050a63          	beqz	a0,80005d30 <sys_unlink+0x1b0>
    80005be0:	00003597          	auipc	a1,0x3
    80005be4:	c6058593          	addi	a1,a1,-928 # 80008840 <syscalls+0x2d0>
    80005be8:	fb040513          	addi	a0,s0,-80
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	6c4080e7          	jalr	1732(ra) # 800042b0 <namecmp>
    80005bf4:	12050e63          	beqz	a0,80005d30 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bf8:	f2c40613          	addi	a2,s0,-212
    80005bfc:	fb040593          	addi	a1,s0,-80
    80005c00:	8526                	mv	a0,s1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	6c8080e7          	jalr	1736(ra) # 800042ca <dirlookup>
    80005c0a:	892a                	mv	s2,a0
    80005c0c:	12050263          	beqz	a0,80005d30 <sys_unlink+0x1b0>
  ilock(ip);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	1d6080e7          	jalr	470(ra) # 80003de6 <ilock>
  if(ip->nlink < 1)
    80005c18:	04a91783          	lh	a5,74(s2)
    80005c1c:	08f05263          	blez	a5,80005ca0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c20:	04491703          	lh	a4,68(s2)
    80005c24:	4785                	li	a5,1
    80005c26:	08f70563          	beq	a4,a5,80005cb0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c2a:	4641                	li	a2,16
    80005c2c:	4581                	li	a1,0
    80005c2e:	fc040513          	addi	a0,s0,-64
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	0ae080e7          	jalr	174(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c3a:	4741                	li	a4,16
    80005c3c:	f2c42683          	lw	a3,-212(s0)
    80005c40:	fc040613          	addi	a2,s0,-64
    80005c44:	4581                	li	a1,0
    80005c46:	8526                	mv	a0,s1
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	54a080e7          	jalr	1354(ra) # 80004192 <writei>
    80005c50:	47c1                	li	a5,16
    80005c52:	0af51563          	bne	a0,a5,80005cfc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c56:	04491703          	lh	a4,68(s2)
    80005c5a:	4785                	li	a5,1
    80005c5c:	0af70863          	beq	a4,a5,80005d0c <sys_unlink+0x18c>
  iunlockput(dp);
    80005c60:	8526                	mv	a0,s1
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	3e6080e7          	jalr	998(ra) # 80004048 <iunlockput>
  ip->nlink--;
    80005c6a:	04a95783          	lhu	a5,74(s2)
    80005c6e:	37fd                	addiw	a5,a5,-1
    80005c70:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c74:	854a                	mv	a0,s2
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	0a6080e7          	jalr	166(ra) # 80003d1c <iupdate>
  iunlockput(ip);
    80005c7e:	854a                	mv	a0,s2
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	3c8080e7          	jalr	968(ra) # 80004048 <iunlockput>
  end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	bb0080e7          	jalr	-1104(ra) # 80004838 <end_op>
  return 0;
    80005c90:	4501                	li	a0,0
    80005c92:	a84d                	j	80005d44 <sys_unlink+0x1c4>
    end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	ba4080e7          	jalr	-1116(ra) # 80004838 <end_op>
    return -1;
    80005c9c:	557d                	li	a0,-1
    80005c9e:	a05d                	j	80005d44 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ca0:	00003517          	auipc	a0,0x3
    80005ca4:	bc850513          	addi	a0,a0,-1080 # 80008868 <syscalls+0x2f8>
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	896080e7          	jalr	-1898(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cb0:	04c92703          	lw	a4,76(s2)
    80005cb4:	02000793          	li	a5,32
    80005cb8:	f6e7f9e3          	bgeu	a5,a4,80005c2a <sys_unlink+0xaa>
    80005cbc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc0:	4741                	li	a4,16
    80005cc2:	86ce                	mv	a3,s3
    80005cc4:	f1840613          	addi	a2,s0,-232
    80005cc8:	4581                	li	a1,0
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	3ce080e7          	jalr	974(ra) # 8000409a <readi>
    80005cd4:	47c1                	li	a5,16
    80005cd6:	00f51b63          	bne	a0,a5,80005cec <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cda:	f1845783          	lhu	a5,-232(s0)
    80005cde:	e7a1                	bnez	a5,80005d26 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce0:	29c1                	addiw	s3,s3,16
    80005ce2:	04c92783          	lw	a5,76(s2)
    80005ce6:	fcf9ede3          	bltu	s3,a5,80005cc0 <sys_unlink+0x140>
    80005cea:	b781                	j	80005c2a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cec:	00003517          	auipc	a0,0x3
    80005cf0:	b9450513          	addi	a0,a0,-1132 # 80008880 <syscalls+0x310>
    80005cf4:	ffffb097          	auipc	ra,0xffffb
    80005cf8:	84a080e7          	jalr	-1974(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005cfc:	00003517          	auipc	a0,0x3
    80005d00:	b9c50513          	addi	a0,a0,-1124 # 80008898 <syscalls+0x328>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	83a080e7          	jalr	-1990(ra) # 8000053e <panic>
    dp->nlink--;
    80005d0c:	04a4d783          	lhu	a5,74(s1)
    80005d10:	37fd                	addiw	a5,a5,-1
    80005d12:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	004080e7          	jalr	4(ra) # 80003d1c <iupdate>
    80005d20:	b781                	j	80005c60 <sys_unlink+0xe0>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	a005                	j	80005d44 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d26:	854a                	mv	a0,s2
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	320080e7          	jalr	800(ra) # 80004048 <iunlockput>
  iunlockput(dp);
    80005d30:	8526                	mv	a0,s1
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	316080e7          	jalr	790(ra) # 80004048 <iunlockput>
  end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	afe080e7          	jalr	-1282(ra) # 80004838 <end_op>
  return -1;
    80005d42:	557d                	li	a0,-1
}
    80005d44:	70ae                	ld	ra,232(sp)
    80005d46:	740e                	ld	s0,224(sp)
    80005d48:	64ee                	ld	s1,216(sp)
    80005d4a:	694e                	ld	s2,208(sp)
    80005d4c:	69ae                	ld	s3,200(sp)
    80005d4e:	616d                	addi	sp,sp,240
    80005d50:	8082                	ret

0000000080005d52 <sys_open>:

uint64
sys_open(void)
{
    80005d52:	7131                	addi	sp,sp,-192
    80005d54:	fd06                	sd	ra,184(sp)
    80005d56:	f922                	sd	s0,176(sp)
    80005d58:	f526                	sd	s1,168(sp)
    80005d5a:	f14a                	sd	s2,160(sp)
    80005d5c:	ed4e                	sd	s3,152(sp)
    80005d5e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d60:	08000613          	li	a2,128
    80005d64:	f5040593          	addi	a1,s0,-176
    80005d68:	4501                	li	a0,0
    80005d6a:	ffffd097          	auipc	ra,0xffffd
    80005d6e:	4d2080e7          	jalr	1234(ra) # 8000323c <argstr>
    return -1;
    80005d72:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d74:	0c054163          	bltz	a0,80005e36 <sys_open+0xe4>
    80005d78:	f4c40593          	addi	a1,s0,-180
    80005d7c:	4505                	li	a0,1
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	47a080e7          	jalr	1146(ra) # 800031f8 <argint>
    80005d86:	0a054863          	bltz	a0,80005e36 <sys_open+0xe4>

  begin_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	a2e080e7          	jalr	-1490(ra) # 800047b8 <begin_op>

  if(omode & O_CREATE){
    80005d92:	f4c42783          	lw	a5,-180(s0)
    80005d96:	2007f793          	andi	a5,a5,512
    80005d9a:	cbdd                	beqz	a5,80005e50 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d9c:	4681                	li	a3,0
    80005d9e:	4601                	li	a2,0
    80005da0:	4589                	li	a1,2
    80005da2:	f5040513          	addi	a0,s0,-176
    80005da6:	00000097          	auipc	ra,0x0
    80005daa:	972080e7          	jalr	-1678(ra) # 80005718 <create>
    80005dae:	892a                	mv	s2,a0
    if(ip == 0){
    80005db0:	c959                	beqz	a0,80005e46 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005db2:	04491703          	lh	a4,68(s2)
    80005db6:	478d                	li	a5,3
    80005db8:	00f71763          	bne	a4,a5,80005dc6 <sys_open+0x74>
    80005dbc:	04695703          	lhu	a4,70(s2)
    80005dc0:	47a5                	li	a5,9
    80005dc2:	0ce7ec63          	bltu	a5,a4,80005e9a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dc6:	fffff097          	auipc	ra,0xfffff
    80005dca:	e02080e7          	jalr	-510(ra) # 80004bc8 <filealloc>
    80005dce:	89aa                	mv	s3,a0
    80005dd0:	10050263          	beqz	a0,80005ed4 <sys_open+0x182>
    80005dd4:	00000097          	auipc	ra,0x0
    80005dd8:	902080e7          	jalr	-1790(ra) # 800056d6 <fdalloc>
    80005ddc:	84aa                	mv	s1,a0
    80005dde:	0e054663          	bltz	a0,80005eca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005de2:	04491703          	lh	a4,68(s2)
    80005de6:	478d                	li	a5,3
    80005de8:	0cf70463          	beq	a4,a5,80005eb0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dec:	4789                	li	a5,2
    80005dee:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005df2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005df6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dfa:	f4c42783          	lw	a5,-180(s0)
    80005dfe:	0017c713          	xori	a4,a5,1
    80005e02:	8b05                	andi	a4,a4,1
    80005e04:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e08:	0037f713          	andi	a4,a5,3
    80005e0c:	00e03733          	snez	a4,a4
    80005e10:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e14:	4007f793          	andi	a5,a5,1024
    80005e18:	c791                	beqz	a5,80005e24 <sys_open+0xd2>
    80005e1a:	04491703          	lh	a4,68(s2)
    80005e1e:	4789                	li	a5,2
    80005e20:	08f70f63          	beq	a4,a5,80005ebe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e24:	854a                	mv	a0,s2
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	082080e7          	jalr	130(ra) # 80003ea8 <iunlock>
  end_op();
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	a0a080e7          	jalr	-1526(ra) # 80004838 <end_op>

  return fd;
}
    80005e36:	8526                	mv	a0,s1
    80005e38:	70ea                	ld	ra,184(sp)
    80005e3a:	744a                	ld	s0,176(sp)
    80005e3c:	74aa                	ld	s1,168(sp)
    80005e3e:	790a                	ld	s2,160(sp)
    80005e40:	69ea                	ld	s3,152(sp)
    80005e42:	6129                	addi	sp,sp,192
    80005e44:	8082                	ret
      end_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	9f2080e7          	jalr	-1550(ra) # 80004838 <end_op>
      return -1;
    80005e4e:	b7e5                	j	80005e36 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e50:	f5040513          	addi	a0,s0,-176
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	748080e7          	jalr	1864(ra) # 8000459c <namei>
    80005e5c:	892a                	mv	s2,a0
    80005e5e:	c905                	beqz	a0,80005e8e <sys_open+0x13c>
    ilock(ip);
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	f86080e7          	jalr	-122(ra) # 80003de6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e68:	04491703          	lh	a4,68(s2)
    80005e6c:	4785                	li	a5,1
    80005e6e:	f4f712e3          	bne	a4,a5,80005db2 <sys_open+0x60>
    80005e72:	f4c42783          	lw	a5,-180(s0)
    80005e76:	dba1                	beqz	a5,80005dc6 <sys_open+0x74>
      iunlockput(ip);
    80005e78:	854a                	mv	a0,s2
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	1ce080e7          	jalr	462(ra) # 80004048 <iunlockput>
      end_op();
    80005e82:	fffff097          	auipc	ra,0xfffff
    80005e86:	9b6080e7          	jalr	-1610(ra) # 80004838 <end_op>
      return -1;
    80005e8a:	54fd                	li	s1,-1
    80005e8c:	b76d                	j	80005e36 <sys_open+0xe4>
      end_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	9aa080e7          	jalr	-1622(ra) # 80004838 <end_op>
      return -1;
    80005e96:	54fd                	li	s1,-1
    80005e98:	bf79                	j	80005e36 <sys_open+0xe4>
    iunlockput(ip);
    80005e9a:	854a                	mv	a0,s2
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	1ac080e7          	jalr	428(ra) # 80004048 <iunlockput>
    end_op();
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	994080e7          	jalr	-1644(ra) # 80004838 <end_op>
    return -1;
    80005eac:	54fd                	li	s1,-1
    80005eae:	b761                	j	80005e36 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eb0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eb4:	04691783          	lh	a5,70(s2)
    80005eb8:	02f99223          	sh	a5,36(s3)
    80005ebc:	bf2d                	j	80005df6 <sys_open+0xa4>
    itrunc(ip);
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	034080e7          	jalr	52(ra) # 80003ef4 <itrunc>
    80005ec8:	bfb1                	j	80005e24 <sys_open+0xd2>
      fileclose(f);
    80005eca:	854e                	mv	a0,s3
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	db8080e7          	jalr	-584(ra) # 80004c84 <fileclose>
    iunlockput(ip);
    80005ed4:	854a                	mv	a0,s2
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	172080e7          	jalr	370(ra) # 80004048 <iunlockput>
    end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	95a080e7          	jalr	-1702(ra) # 80004838 <end_op>
    return -1;
    80005ee6:	54fd                	li	s1,-1
    80005ee8:	b7b9                	j	80005e36 <sys_open+0xe4>

0000000080005eea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eea:	7175                	addi	sp,sp,-144
    80005eec:	e506                	sd	ra,136(sp)
    80005eee:	e122                	sd	s0,128(sp)
    80005ef0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	8c6080e7          	jalr	-1850(ra) # 800047b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005efa:	08000613          	li	a2,128
    80005efe:	f7040593          	addi	a1,s0,-144
    80005f02:	4501                	li	a0,0
    80005f04:	ffffd097          	auipc	ra,0xffffd
    80005f08:	338080e7          	jalr	824(ra) # 8000323c <argstr>
    80005f0c:	02054963          	bltz	a0,80005f3e <sys_mkdir+0x54>
    80005f10:	4681                	li	a3,0
    80005f12:	4601                	li	a2,0
    80005f14:	4585                	li	a1,1
    80005f16:	f7040513          	addi	a0,s0,-144
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	7fe080e7          	jalr	2046(ra) # 80005718 <create>
    80005f22:	cd11                	beqz	a0,80005f3e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	124080e7          	jalr	292(ra) # 80004048 <iunlockput>
  end_op();
    80005f2c:	fffff097          	auipc	ra,0xfffff
    80005f30:	90c080e7          	jalr	-1780(ra) # 80004838 <end_op>
  return 0;
    80005f34:	4501                	li	a0,0
}
    80005f36:	60aa                	ld	ra,136(sp)
    80005f38:	640a                	ld	s0,128(sp)
    80005f3a:	6149                	addi	sp,sp,144
    80005f3c:	8082                	ret
    end_op();
    80005f3e:	fffff097          	auipc	ra,0xfffff
    80005f42:	8fa080e7          	jalr	-1798(ra) # 80004838 <end_op>
    return -1;
    80005f46:	557d                	li	a0,-1
    80005f48:	b7fd                	j	80005f36 <sys_mkdir+0x4c>

0000000080005f4a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f4a:	7135                	addi	sp,sp,-160
    80005f4c:	ed06                	sd	ra,152(sp)
    80005f4e:	e922                	sd	s0,144(sp)
    80005f50:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f52:	fffff097          	auipc	ra,0xfffff
    80005f56:	866080e7          	jalr	-1946(ra) # 800047b8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f5a:	08000613          	li	a2,128
    80005f5e:	f7040593          	addi	a1,s0,-144
    80005f62:	4501                	li	a0,0
    80005f64:	ffffd097          	auipc	ra,0xffffd
    80005f68:	2d8080e7          	jalr	728(ra) # 8000323c <argstr>
    80005f6c:	04054a63          	bltz	a0,80005fc0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f70:	f6c40593          	addi	a1,s0,-148
    80005f74:	4505                	li	a0,1
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	282080e7          	jalr	642(ra) # 800031f8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f7e:	04054163          	bltz	a0,80005fc0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f82:	f6840593          	addi	a1,s0,-152
    80005f86:	4509                	li	a0,2
    80005f88:	ffffd097          	auipc	ra,0xffffd
    80005f8c:	270080e7          	jalr	624(ra) # 800031f8 <argint>
     argint(1, &major) < 0 ||
    80005f90:	02054863          	bltz	a0,80005fc0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f94:	f6841683          	lh	a3,-152(s0)
    80005f98:	f6c41603          	lh	a2,-148(s0)
    80005f9c:	458d                	li	a1,3
    80005f9e:	f7040513          	addi	a0,s0,-144
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	776080e7          	jalr	1910(ra) # 80005718 <create>
     argint(2, &minor) < 0 ||
    80005faa:	c919                	beqz	a0,80005fc0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fac:	ffffe097          	auipc	ra,0xffffe
    80005fb0:	09c080e7          	jalr	156(ra) # 80004048 <iunlockput>
  end_op();
    80005fb4:	fffff097          	auipc	ra,0xfffff
    80005fb8:	884080e7          	jalr	-1916(ra) # 80004838 <end_op>
  return 0;
    80005fbc:	4501                	li	a0,0
    80005fbe:	a031                	j	80005fca <sys_mknod+0x80>
    end_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	878080e7          	jalr	-1928(ra) # 80004838 <end_op>
    return -1;
    80005fc8:	557d                	li	a0,-1
}
    80005fca:	60ea                	ld	ra,152(sp)
    80005fcc:	644a                	ld	s0,144(sp)
    80005fce:	610d                	addi	sp,sp,160
    80005fd0:	8082                	ret

0000000080005fd2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd2:	7135                	addi	sp,sp,-160
    80005fd4:	ed06                	sd	ra,152(sp)
    80005fd6:	e922                	sd	s0,144(sp)
    80005fd8:	e526                	sd	s1,136(sp)
    80005fda:	e14a                	sd	s2,128(sp)
    80005fdc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fde:	ffffc097          	auipc	ra,0xffffc
    80005fe2:	e58080e7          	jalr	-424(ra) # 80001e36 <myproc>
    80005fe6:	892a                	mv	s2,a0
  
  begin_op();
    80005fe8:	ffffe097          	auipc	ra,0xffffe
    80005fec:	7d0080e7          	jalr	2000(ra) # 800047b8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ff0:	08000613          	li	a2,128
    80005ff4:	f6040593          	addi	a1,s0,-160
    80005ff8:	4501                	li	a0,0
    80005ffa:	ffffd097          	auipc	ra,0xffffd
    80005ffe:	242080e7          	jalr	578(ra) # 8000323c <argstr>
    80006002:	04054b63          	bltz	a0,80006058 <sys_chdir+0x86>
    80006006:	f6040513          	addi	a0,s0,-160
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	592080e7          	jalr	1426(ra) # 8000459c <namei>
    80006012:	84aa                	mv	s1,a0
    80006014:	c131                	beqz	a0,80006058 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	dd0080e7          	jalr	-560(ra) # 80003de6 <ilock>
  if(ip->type != T_DIR){
    8000601e:	04449703          	lh	a4,68(s1)
    80006022:	4785                	li	a5,1
    80006024:	04f71063          	bne	a4,a5,80006064 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006028:	8526                	mv	a0,s1
    8000602a:	ffffe097          	auipc	ra,0xffffe
    8000602e:	e7e080e7          	jalr	-386(ra) # 80003ea8 <iunlock>
  iput(p->cwd);
    80006032:	15093503          	ld	a0,336(s2)
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	f6a080e7          	jalr	-150(ra) # 80003fa0 <iput>
  end_op();
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	7fa080e7          	jalr	2042(ra) # 80004838 <end_op>
  p->cwd = ip;
    80006046:	14993823          	sd	s1,336(s2)
  return 0;
    8000604a:	4501                	li	a0,0
}
    8000604c:	60ea                	ld	ra,152(sp)
    8000604e:	644a                	ld	s0,144(sp)
    80006050:	64aa                	ld	s1,136(sp)
    80006052:	690a                	ld	s2,128(sp)
    80006054:	610d                	addi	sp,sp,160
    80006056:	8082                	ret
    end_op();
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	7e0080e7          	jalr	2016(ra) # 80004838 <end_op>
    return -1;
    80006060:	557d                	li	a0,-1
    80006062:	b7ed                	j	8000604c <sys_chdir+0x7a>
    iunlockput(ip);
    80006064:	8526                	mv	a0,s1
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	fe2080e7          	jalr	-30(ra) # 80004048 <iunlockput>
    end_op();
    8000606e:	ffffe097          	auipc	ra,0xffffe
    80006072:	7ca080e7          	jalr	1994(ra) # 80004838 <end_op>
    return -1;
    80006076:	557d                	li	a0,-1
    80006078:	bfd1                	j	8000604c <sys_chdir+0x7a>

000000008000607a <sys_exec>:

uint64
sys_exec(void)
{
    8000607a:	7145                	addi	sp,sp,-464
    8000607c:	e786                	sd	ra,456(sp)
    8000607e:	e3a2                	sd	s0,448(sp)
    80006080:	ff26                	sd	s1,440(sp)
    80006082:	fb4a                	sd	s2,432(sp)
    80006084:	f74e                	sd	s3,424(sp)
    80006086:	f352                	sd	s4,416(sp)
    80006088:	ef56                	sd	s5,408(sp)
    8000608a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000608c:	08000613          	li	a2,128
    80006090:	f4040593          	addi	a1,s0,-192
    80006094:	4501                	li	a0,0
    80006096:	ffffd097          	auipc	ra,0xffffd
    8000609a:	1a6080e7          	jalr	422(ra) # 8000323c <argstr>
    return -1;
    8000609e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060a0:	0c054a63          	bltz	a0,80006174 <sys_exec+0xfa>
    800060a4:	e3840593          	addi	a1,s0,-456
    800060a8:	4505                	li	a0,1
    800060aa:	ffffd097          	auipc	ra,0xffffd
    800060ae:	170080e7          	jalr	368(ra) # 8000321a <argaddr>
    800060b2:	0c054163          	bltz	a0,80006174 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060b6:	10000613          	li	a2,256
    800060ba:	4581                	li	a1,0
    800060bc:	e4040513          	addi	a0,s0,-448
    800060c0:	ffffb097          	auipc	ra,0xffffb
    800060c4:	c20080e7          	jalr	-992(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060c8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060cc:	89a6                	mv	s3,s1
    800060ce:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060d0:	02000a13          	li	s4,32
    800060d4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060d8:	00391513          	slli	a0,s2,0x3
    800060dc:	e3040593          	addi	a1,s0,-464
    800060e0:	e3843783          	ld	a5,-456(s0)
    800060e4:	953e                	add	a0,a0,a5
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	078080e7          	jalr	120(ra) # 8000315e <fetchaddr>
    800060ee:	02054a63          	bltz	a0,80006122 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060f2:	e3043783          	ld	a5,-464(s0)
    800060f6:	c3b9                	beqz	a5,8000613c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060f8:	ffffb097          	auipc	ra,0xffffb
    800060fc:	9fc080e7          	jalr	-1540(ra) # 80000af4 <kalloc>
    80006100:	85aa                	mv	a1,a0
    80006102:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006106:	cd11                	beqz	a0,80006122 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006108:	6605                	lui	a2,0x1
    8000610a:	e3043503          	ld	a0,-464(s0)
    8000610e:	ffffd097          	auipc	ra,0xffffd
    80006112:	0a2080e7          	jalr	162(ra) # 800031b0 <fetchstr>
    80006116:	00054663          	bltz	a0,80006122 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000611a:	0905                	addi	s2,s2,1
    8000611c:	09a1                	addi	s3,s3,8
    8000611e:	fb491be3          	bne	s2,s4,800060d4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006122:	10048913          	addi	s2,s1,256
    80006126:	6088                	ld	a0,0(s1)
    80006128:	c529                	beqz	a0,80006172 <sys_exec+0xf8>
    kfree(argv[i]);
    8000612a:	ffffb097          	auipc	ra,0xffffb
    8000612e:	8ce080e7          	jalr	-1842(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006132:	04a1                	addi	s1,s1,8
    80006134:	ff2499e3          	bne	s1,s2,80006126 <sys_exec+0xac>
  return -1;
    80006138:	597d                	li	s2,-1
    8000613a:	a82d                	j	80006174 <sys_exec+0xfa>
      argv[i] = 0;
    8000613c:	0a8e                	slli	s5,s5,0x3
    8000613e:	fc040793          	addi	a5,s0,-64
    80006142:	9abe                	add	s5,s5,a5
    80006144:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006148:	e4040593          	addi	a1,s0,-448
    8000614c:	f4040513          	addi	a0,s0,-192
    80006150:	fffff097          	auipc	ra,0xfffff
    80006154:	194080e7          	jalr	404(ra) # 800052e4 <exec>
    80006158:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000615a:	10048993          	addi	s3,s1,256
    8000615e:	6088                	ld	a0,0(s1)
    80006160:	c911                	beqz	a0,80006174 <sys_exec+0xfa>
    kfree(argv[i]);
    80006162:	ffffb097          	auipc	ra,0xffffb
    80006166:	896080e7          	jalr	-1898(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000616a:	04a1                	addi	s1,s1,8
    8000616c:	ff3499e3          	bne	s1,s3,8000615e <sys_exec+0xe4>
    80006170:	a011                	j	80006174 <sys_exec+0xfa>
  return -1;
    80006172:	597d                	li	s2,-1
}
    80006174:	854a                	mv	a0,s2
    80006176:	60be                	ld	ra,456(sp)
    80006178:	641e                	ld	s0,448(sp)
    8000617a:	74fa                	ld	s1,440(sp)
    8000617c:	795a                	ld	s2,432(sp)
    8000617e:	79ba                	ld	s3,424(sp)
    80006180:	7a1a                	ld	s4,416(sp)
    80006182:	6afa                	ld	s5,408(sp)
    80006184:	6179                	addi	sp,sp,464
    80006186:	8082                	ret

0000000080006188 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006188:	7139                	addi	sp,sp,-64
    8000618a:	fc06                	sd	ra,56(sp)
    8000618c:	f822                	sd	s0,48(sp)
    8000618e:	f426                	sd	s1,40(sp)
    80006190:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	ca4080e7          	jalr	-860(ra) # 80001e36 <myproc>
    8000619a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000619c:	fd840593          	addi	a1,s0,-40
    800061a0:	4501                	li	a0,0
    800061a2:	ffffd097          	auipc	ra,0xffffd
    800061a6:	078080e7          	jalr	120(ra) # 8000321a <argaddr>
    return -1;
    800061aa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061ac:	0e054063          	bltz	a0,8000628c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061b0:	fc840593          	addi	a1,s0,-56
    800061b4:	fd040513          	addi	a0,s0,-48
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	dfc080e7          	jalr	-516(ra) # 80004fb4 <pipealloc>
    return -1;
    800061c0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061c2:	0c054563          	bltz	a0,8000628c <sys_pipe+0x104>
  fd0 = -1;
    800061c6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061ca:	fd043503          	ld	a0,-48(s0)
    800061ce:	fffff097          	auipc	ra,0xfffff
    800061d2:	508080e7          	jalr	1288(ra) # 800056d6 <fdalloc>
    800061d6:	fca42223          	sw	a0,-60(s0)
    800061da:	08054c63          	bltz	a0,80006272 <sys_pipe+0xea>
    800061de:	fc843503          	ld	a0,-56(s0)
    800061e2:	fffff097          	auipc	ra,0xfffff
    800061e6:	4f4080e7          	jalr	1268(ra) # 800056d6 <fdalloc>
    800061ea:	fca42023          	sw	a0,-64(s0)
    800061ee:	06054863          	bltz	a0,8000625e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061f2:	4691                	li	a3,4
    800061f4:	fc440613          	addi	a2,s0,-60
    800061f8:	fd843583          	ld	a1,-40(s0)
    800061fc:	68a8                	ld	a0,80(s1)
    800061fe:	ffffb097          	auipc	ra,0xffffb
    80006202:	474080e7          	jalr	1140(ra) # 80001672 <copyout>
    80006206:	02054063          	bltz	a0,80006226 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000620a:	4691                	li	a3,4
    8000620c:	fc040613          	addi	a2,s0,-64
    80006210:	fd843583          	ld	a1,-40(s0)
    80006214:	0591                	addi	a1,a1,4
    80006216:	68a8                	ld	a0,80(s1)
    80006218:	ffffb097          	auipc	ra,0xffffb
    8000621c:	45a080e7          	jalr	1114(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006220:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006222:	06055563          	bgez	a0,8000628c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006226:	fc442783          	lw	a5,-60(s0)
    8000622a:	07e9                	addi	a5,a5,26
    8000622c:	078e                	slli	a5,a5,0x3
    8000622e:	97a6                	add	a5,a5,s1
    80006230:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006234:	fc042503          	lw	a0,-64(s0)
    80006238:	0569                	addi	a0,a0,26
    8000623a:	050e                	slli	a0,a0,0x3
    8000623c:	9526                	add	a0,a0,s1
    8000623e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006242:	fd043503          	ld	a0,-48(s0)
    80006246:	fffff097          	auipc	ra,0xfffff
    8000624a:	a3e080e7          	jalr	-1474(ra) # 80004c84 <fileclose>
    fileclose(wf);
    8000624e:	fc843503          	ld	a0,-56(s0)
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	a32080e7          	jalr	-1486(ra) # 80004c84 <fileclose>
    return -1;
    8000625a:	57fd                	li	a5,-1
    8000625c:	a805                	j	8000628c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000625e:	fc442783          	lw	a5,-60(s0)
    80006262:	0007c863          	bltz	a5,80006272 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006266:	01a78513          	addi	a0,a5,26
    8000626a:	050e                	slli	a0,a0,0x3
    8000626c:	9526                	add	a0,a0,s1
    8000626e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006272:	fd043503          	ld	a0,-48(s0)
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	a0e080e7          	jalr	-1522(ra) # 80004c84 <fileclose>
    fileclose(wf);
    8000627e:	fc843503          	ld	a0,-56(s0)
    80006282:	fffff097          	auipc	ra,0xfffff
    80006286:	a02080e7          	jalr	-1534(ra) # 80004c84 <fileclose>
    return -1;
    8000628a:	57fd                	li	a5,-1
}
    8000628c:	853e                	mv	a0,a5
    8000628e:	70e2                	ld	ra,56(sp)
    80006290:	7442                	ld	s0,48(sp)
    80006292:	74a2                	ld	s1,40(sp)
    80006294:	6121                	addi	sp,sp,64
    80006296:	8082                	ret
	...

00000000800062a0 <kernelvec>:
    800062a0:	7111                	addi	sp,sp,-256
    800062a2:	e006                	sd	ra,0(sp)
    800062a4:	e40a                	sd	sp,8(sp)
    800062a6:	e80e                	sd	gp,16(sp)
    800062a8:	ec12                	sd	tp,24(sp)
    800062aa:	f016                	sd	t0,32(sp)
    800062ac:	f41a                	sd	t1,40(sp)
    800062ae:	f81e                	sd	t2,48(sp)
    800062b0:	fc22                	sd	s0,56(sp)
    800062b2:	e0a6                	sd	s1,64(sp)
    800062b4:	e4aa                	sd	a0,72(sp)
    800062b6:	e8ae                	sd	a1,80(sp)
    800062b8:	ecb2                	sd	a2,88(sp)
    800062ba:	f0b6                	sd	a3,96(sp)
    800062bc:	f4ba                	sd	a4,104(sp)
    800062be:	f8be                	sd	a5,112(sp)
    800062c0:	fcc2                	sd	a6,120(sp)
    800062c2:	e146                	sd	a7,128(sp)
    800062c4:	e54a                	sd	s2,136(sp)
    800062c6:	e94e                	sd	s3,144(sp)
    800062c8:	ed52                	sd	s4,152(sp)
    800062ca:	f156                	sd	s5,160(sp)
    800062cc:	f55a                	sd	s6,168(sp)
    800062ce:	f95e                	sd	s7,176(sp)
    800062d0:	fd62                	sd	s8,184(sp)
    800062d2:	e1e6                	sd	s9,192(sp)
    800062d4:	e5ea                	sd	s10,200(sp)
    800062d6:	e9ee                	sd	s11,208(sp)
    800062d8:	edf2                	sd	t3,216(sp)
    800062da:	f1f6                	sd	t4,224(sp)
    800062dc:	f5fa                	sd	t5,232(sp)
    800062de:	f9fe                	sd	t6,240(sp)
    800062e0:	d4bfc0ef          	jal	ra,8000302a <kerneltrap>
    800062e4:	6082                	ld	ra,0(sp)
    800062e6:	6122                	ld	sp,8(sp)
    800062e8:	61c2                	ld	gp,16(sp)
    800062ea:	7282                	ld	t0,32(sp)
    800062ec:	7322                	ld	t1,40(sp)
    800062ee:	73c2                	ld	t2,48(sp)
    800062f0:	7462                	ld	s0,56(sp)
    800062f2:	6486                	ld	s1,64(sp)
    800062f4:	6526                	ld	a0,72(sp)
    800062f6:	65c6                	ld	a1,80(sp)
    800062f8:	6666                	ld	a2,88(sp)
    800062fa:	7686                	ld	a3,96(sp)
    800062fc:	7726                	ld	a4,104(sp)
    800062fe:	77c6                	ld	a5,112(sp)
    80006300:	7866                	ld	a6,120(sp)
    80006302:	688a                	ld	a7,128(sp)
    80006304:	692a                	ld	s2,136(sp)
    80006306:	69ca                	ld	s3,144(sp)
    80006308:	6a6a                	ld	s4,152(sp)
    8000630a:	7a8a                	ld	s5,160(sp)
    8000630c:	7b2a                	ld	s6,168(sp)
    8000630e:	7bca                	ld	s7,176(sp)
    80006310:	7c6a                	ld	s8,184(sp)
    80006312:	6c8e                	ld	s9,192(sp)
    80006314:	6d2e                	ld	s10,200(sp)
    80006316:	6dce                	ld	s11,208(sp)
    80006318:	6e6e                	ld	t3,216(sp)
    8000631a:	7e8e                	ld	t4,224(sp)
    8000631c:	7f2e                	ld	t5,232(sp)
    8000631e:	7fce                	ld	t6,240(sp)
    80006320:	6111                	addi	sp,sp,256
    80006322:	10200073          	sret
    80006326:	00000013          	nop
    8000632a:	00000013          	nop
    8000632e:	0001                	nop

0000000080006330 <timervec>:
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	e10c                	sd	a1,0(a0)
    80006336:	e510                	sd	a2,8(a0)
    80006338:	e914                	sd	a3,16(a0)
    8000633a:	6d0c                	ld	a1,24(a0)
    8000633c:	7110                	ld	a2,32(a0)
    8000633e:	6194                	ld	a3,0(a1)
    80006340:	96b2                	add	a3,a3,a2
    80006342:	e194                	sd	a3,0(a1)
    80006344:	4589                	li	a1,2
    80006346:	14459073          	csrw	sip,a1
    8000634a:	6914                	ld	a3,16(a0)
    8000634c:	6510                	ld	a2,8(a0)
    8000634e:	610c                	ld	a1,0(a0)
    80006350:	34051573          	csrrw	a0,mscratch,a0
    80006354:	30200073          	mret
	...

000000008000635a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000635a:	1141                	addi	sp,sp,-16
    8000635c:	e422                	sd	s0,8(sp)
    8000635e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006360:	0c0007b7          	lui	a5,0xc000
    80006364:	4705                	li	a4,1
    80006366:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006368:	c3d8                	sw	a4,4(a5)
}
    8000636a:	6422                	ld	s0,8(sp)
    8000636c:	0141                	addi	sp,sp,16
    8000636e:	8082                	ret

0000000080006370 <plicinithart>:

void
plicinithart(void)
{
    80006370:	1141                	addi	sp,sp,-16
    80006372:	e406                	sd	ra,8(sp)
    80006374:	e022                	sd	s0,0(sp)
    80006376:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	a8c080e7          	jalr	-1396(ra) # 80001e04 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006380:	0085171b          	slliw	a4,a0,0x8
    80006384:	0c0027b7          	lui	a5,0xc002
    80006388:	97ba                	add	a5,a5,a4
    8000638a:	40200713          	li	a4,1026
    8000638e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006392:	00d5151b          	slliw	a0,a0,0xd
    80006396:	0c2017b7          	lui	a5,0xc201
    8000639a:	953e                	add	a0,a0,a5
    8000639c:	00052023          	sw	zero,0(a0)
}
    800063a0:	60a2                	ld	ra,8(sp)
    800063a2:	6402                	ld	s0,0(sp)
    800063a4:	0141                	addi	sp,sp,16
    800063a6:	8082                	ret

00000000800063a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063a8:	1141                	addi	sp,sp,-16
    800063aa:	e406                	sd	ra,8(sp)
    800063ac:	e022                	sd	s0,0(sp)
    800063ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063b0:	ffffc097          	auipc	ra,0xffffc
    800063b4:	a54080e7          	jalr	-1452(ra) # 80001e04 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063b8:	00d5179b          	slliw	a5,a0,0xd
    800063bc:	0c201537          	lui	a0,0xc201
    800063c0:	953e                	add	a0,a0,a5
  return irq;
}
    800063c2:	4148                	lw	a0,4(a0)
    800063c4:	60a2                	ld	ra,8(sp)
    800063c6:	6402                	ld	s0,0(sp)
    800063c8:	0141                	addi	sp,sp,16
    800063ca:	8082                	ret

00000000800063cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063cc:	1101                	addi	sp,sp,-32
    800063ce:	ec06                	sd	ra,24(sp)
    800063d0:	e822                	sd	s0,16(sp)
    800063d2:	e426                	sd	s1,8(sp)
    800063d4:	1000                	addi	s0,sp,32
    800063d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063d8:	ffffc097          	auipc	ra,0xffffc
    800063dc:	a2c080e7          	jalr	-1492(ra) # 80001e04 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063e0:	00d5151b          	slliw	a0,a0,0xd
    800063e4:	0c2017b7          	lui	a5,0xc201
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	c3c4                	sw	s1,4(a5)
}
    800063ec:	60e2                	ld	ra,24(sp)
    800063ee:	6442                	ld	s0,16(sp)
    800063f0:	64a2                	ld	s1,8(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret

00000000800063f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063f6:	1141                	addi	sp,sp,-16
    800063f8:	e406                	sd	ra,8(sp)
    800063fa:	e022                	sd	s0,0(sp)
    800063fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063fe:	479d                	li	a5,7
    80006400:	06a7c963          	blt	a5,a0,80006472 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006404:	0001d797          	auipc	a5,0x1d
    80006408:	bfc78793          	addi	a5,a5,-1028 # 80023000 <disk>
    8000640c:	00a78733          	add	a4,a5,a0
    80006410:	6789                	lui	a5,0x2
    80006412:	97ba                	add	a5,a5,a4
    80006414:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006418:	e7ad                	bnez	a5,80006482 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000641a:	00451793          	slli	a5,a0,0x4
    8000641e:	0001f717          	auipc	a4,0x1f
    80006422:	be270713          	addi	a4,a4,-1054 # 80025000 <disk+0x2000>
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000642e:	6314                	ld	a3,0(a4)
    80006430:	96be                	add	a3,a3,a5
    80006432:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006436:	6314                	ld	a3,0(a4)
    80006438:	96be                	add	a3,a3,a5
    8000643a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000643e:	6318                	ld	a4,0(a4)
    80006440:	97ba                	add	a5,a5,a4
    80006442:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006446:	0001d797          	auipc	a5,0x1d
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80023000 <disk>
    8000644e:	97aa                	add	a5,a5,a0
    80006450:	6509                	lui	a0,0x2
    80006452:	953e                	add	a0,a0,a5
    80006454:	4785                	li	a5,1
    80006456:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000645a:	0001f517          	auipc	a0,0x1f
    8000645e:	bbe50513          	addi	a0,a0,-1090 # 80025018 <disk+0x2018>
    80006462:	ffffc097          	auipc	ra,0xffffc
    80006466:	66a080e7          	jalr	1642(ra) # 80002acc <wakeup>
}
    8000646a:	60a2                	ld	ra,8(sp)
    8000646c:	6402                	ld	s0,0(sp)
    8000646e:	0141                	addi	sp,sp,16
    80006470:	8082                	ret
    panic("free_desc 1");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	43650513          	addi	a0,a0,1078 # 800088a8 <syscalls+0x338>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	43650513          	addi	a0,a0,1078 # 800088b8 <syscalls+0x348>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>

0000000080006492 <virtio_disk_init>:
{
    80006492:	1101                	addi	sp,sp,-32
    80006494:	ec06                	sd	ra,24(sp)
    80006496:	e822                	sd	s0,16(sp)
    80006498:	e426                	sd	s1,8(sp)
    8000649a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000649c:	00002597          	auipc	a1,0x2
    800064a0:	42c58593          	addi	a1,a1,1068 # 800088c8 <syscalls+0x358>
    800064a4:	0001f517          	auipc	a0,0x1f
    800064a8:	c8450513          	addi	a0,a0,-892 # 80025128 <disk+0x2128>
    800064ac:	ffffa097          	auipc	ra,0xffffa
    800064b0:	6a8080e7          	jalr	1704(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	4398                	lw	a4,0(a5)
    800064ba:	2701                	sext.w	a4,a4
    800064bc:	747277b7          	lui	a5,0x74727
    800064c0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064c4:	0ef71163          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064c8:	100017b7          	lui	a5,0x10001
    800064cc:	43dc                	lw	a5,4(a5)
    800064ce:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064d0:	4705                	li	a4,1
    800064d2:	0ce79a63          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064d6:	100017b7          	lui	a5,0x10001
    800064da:	479c                	lw	a5,8(a5)
    800064dc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064de:	4709                	li	a4,2
    800064e0:	0ce79363          	bne	a5,a4,800065a6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	47d8                	lw	a4,12(a5)
    800064ea:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ec:	554d47b7          	lui	a5,0x554d4
    800064f0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064f4:	0af71963          	bne	a4,a5,800065a6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	4705                	li	a4,1
    800064fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006500:	470d                	li	a4,3
    80006502:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006504:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006506:	c7ffe737          	lui	a4,0xc7ffe
    8000650a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000650e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006510:	2701                	sext.w	a4,a4
    80006512:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006514:	472d                	li	a4,11
    80006516:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006518:	473d                	li	a4,15
    8000651a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000651c:	6705                	lui	a4,0x1
    8000651e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006520:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006524:	5bdc                	lw	a5,52(a5)
    80006526:	2781                	sext.w	a5,a5
  if(max == 0)
    80006528:	c7d9                	beqz	a5,800065b6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000652a:	471d                	li	a4,7
    8000652c:	08f77d63          	bgeu	a4,a5,800065c6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006530:	100014b7          	lui	s1,0x10001
    80006534:	47a1                	li	a5,8
    80006536:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006538:	6609                	lui	a2,0x2
    8000653a:	4581                	li	a1,0
    8000653c:	0001d517          	auipc	a0,0x1d
    80006540:	ac450513          	addi	a0,a0,-1340 # 80023000 <disk>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	79c080e7          	jalr	1948(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000654c:	0001d717          	auipc	a4,0x1d
    80006550:	ab470713          	addi	a4,a4,-1356 # 80023000 <disk>
    80006554:	00c75793          	srli	a5,a4,0xc
    80006558:	2781                	sext.w	a5,a5
    8000655a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000655c:	0001f797          	auipc	a5,0x1f
    80006560:	aa478793          	addi	a5,a5,-1372 # 80025000 <disk+0x2000>
    80006564:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006566:	0001d717          	auipc	a4,0x1d
    8000656a:	b1a70713          	addi	a4,a4,-1254 # 80023080 <disk+0x80>
    8000656e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006570:	0001e717          	auipc	a4,0x1e
    80006574:	a9070713          	addi	a4,a4,-1392 # 80024000 <disk+0x1000>
    80006578:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000657a:	4705                	li	a4,1
    8000657c:	00e78c23          	sb	a4,24(a5)
    80006580:	00e78ca3          	sb	a4,25(a5)
    80006584:	00e78d23          	sb	a4,26(a5)
    80006588:	00e78da3          	sb	a4,27(a5)
    8000658c:	00e78e23          	sb	a4,28(a5)
    80006590:	00e78ea3          	sb	a4,29(a5)
    80006594:	00e78f23          	sb	a4,30(a5)
    80006598:	00e78fa3          	sb	a4,31(a5)
}
    8000659c:	60e2                	ld	ra,24(sp)
    8000659e:	6442                	ld	s0,16(sp)
    800065a0:	64a2                	ld	s1,8(sp)
    800065a2:	6105                	addi	sp,sp,32
    800065a4:	8082                	ret
    panic("could not find virtio disk");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	33250513          	addi	a0,a0,818 # 800088d8 <syscalls+0x368>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	34250513          	addi	a0,a0,834 # 800088f8 <syscalls+0x388>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065c6:	00002517          	auipc	a0,0x2
    800065ca:	35250513          	addi	a0,a0,850 # 80008918 <syscalls+0x3a8>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>

00000000800065d6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065d6:	7159                	addi	sp,sp,-112
    800065d8:	f486                	sd	ra,104(sp)
    800065da:	f0a2                	sd	s0,96(sp)
    800065dc:	eca6                	sd	s1,88(sp)
    800065de:	e8ca                	sd	s2,80(sp)
    800065e0:	e4ce                	sd	s3,72(sp)
    800065e2:	e0d2                	sd	s4,64(sp)
    800065e4:	fc56                	sd	s5,56(sp)
    800065e6:	f85a                	sd	s6,48(sp)
    800065e8:	f45e                	sd	s7,40(sp)
    800065ea:	f062                	sd	s8,32(sp)
    800065ec:	ec66                	sd	s9,24(sp)
    800065ee:	e86a                	sd	s10,16(sp)
    800065f0:	1880                	addi	s0,sp,112
    800065f2:	892a                	mv	s2,a0
    800065f4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065f6:	00c52c83          	lw	s9,12(a0)
    800065fa:	001c9c9b          	slliw	s9,s9,0x1
    800065fe:	1c82                	slli	s9,s9,0x20
    80006600:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006604:	0001f517          	auipc	a0,0x1f
    80006608:	b2450513          	addi	a0,a0,-1244 # 80025128 <disk+0x2128>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006614:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006616:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006618:	0001db97          	auipc	s7,0x1d
    8000661c:	9e8b8b93          	addi	s7,s7,-1560 # 80023000 <disk>
    80006620:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006622:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006624:	8a4e                	mv	s4,s3
    80006626:	a051                	j	800066aa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006628:	00fb86b3          	add	a3,s7,a5
    8000662c:	96da                	add	a3,a3,s6
    8000662e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006632:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006634:	0207c563          	bltz	a5,8000665e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006638:	2485                	addiw	s1,s1,1
    8000663a:	0711                	addi	a4,a4,4
    8000663c:	25548063          	beq	s1,s5,8000687c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006640:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006642:	0001f697          	auipc	a3,0x1f
    80006646:	9d668693          	addi	a3,a3,-1578 # 80025018 <disk+0x2018>
    8000664a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000664c:	0006c583          	lbu	a1,0(a3)
    80006650:	fde1                	bnez	a1,80006628 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006652:	2785                	addiw	a5,a5,1
    80006654:	0685                	addi	a3,a3,1
    80006656:	ff879be3          	bne	a5,s8,8000664c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000665a:	57fd                	li	a5,-1
    8000665c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000665e:	02905a63          	blez	s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006662:	f9042503          	lw	a0,-112(s0)
    80006666:	00000097          	auipc	ra,0x0
    8000666a:	d90080e7          	jalr	-624(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    8000666e:	4785                	li	a5,1
    80006670:	0297d163          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006674:	f9442503          	lw	a0,-108(s0)
    80006678:	00000097          	auipc	ra,0x0
    8000667c:	d7e080e7          	jalr	-642(ra) # 800063f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006680:	4789                	li	a5,2
    80006682:	0097d863          	bge	a5,s1,80006692 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006686:	f9842503          	lw	a0,-104(s0)
    8000668a:	00000097          	auipc	ra,0x0
    8000668e:	d6c080e7          	jalr	-660(ra) # 800063f6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006692:	0001f597          	auipc	a1,0x1f
    80006696:	a9658593          	addi	a1,a1,-1386 # 80025128 <disk+0x2128>
    8000669a:	0001f517          	auipc	a0,0x1f
    8000669e:	97e50513          	addi	a0,a0,-1666 # 80025018 <disk+0x2018>
    800066a2:	ffffc097          	auipc	ra,0xffffc
    800066a6:	e3c080e7          	jalr	-452(ra) # 800024de <sleep>
  for(int i = 0; i < 3; i++){
    800066aa:	f9040713          	addi	a4,s0,-112
    800066ae:	84ce                	mv	s1,s3
    800066b0:	bf41                	j	80006640 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066b2:	20058713          	addi	a4,a1,512
    800066b6:	00471693          	slli	a3,a4,0x4
    800066ba:	0001d717          	auipc	a4,0x1d
    800066be:	94670713          	addi	a4,a4,-1722 # 80023000 <disk>
    800066c2:	9736                	add	a4,a4,a3
    800066c4:	4685                	li	a3,1
    800066c6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ca:	20058713          	addi	a4,a1,512
    800066ce:	00471693          	slli	a3,a4,0x4
    800066d2:	0001d717          	auipc	a4,0x1d
    800066d6:	92e70713          	addi	a4,a4,-1746 # 80023000 <disk>
    800066da:	9736                	add	a4,a4,a3
    800066dc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066e0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e4:	7679                	lui	a2,0xffffe
    800066e6:	963e                	add	a2,a2,a5
    800066e8:	0001f697          	auipc	a3,0x1f
    800066ec:	91868693          	addi	a3,a3,-1768 # 80025000 <disk+0x2000>
    800066f0:	6298                	ld	a4,0(a3)
    800066f2:	9732                	add	a4,a4,a2
    800066f4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f6:	6298                	ld	a4,0(a3)
    800066f8:	9732                	add	a4,a4,a2
    800066fa:	4541                	li	a0,16
    800066fc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066fe:	6298                	ld	a4,0(a3)
    80006700:	9732                	add	a4,a4,a2
    80006702:	4505                	li	a0,1
    80006704:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442703          	lw	a4,-108(s0)
    8000670c:	6288                	ld	a0,0(a3)
    8000670e:	962a                	add	a2,a2,a0
    80006710:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006714:	0712                	slli	a4,a4,0x4
    80006716:	6290                	ld	a2,0(a3)
    80006718:	963a                	add	a2,a2,a4
    8000671a:	05890513          	addi	a0,s2,88
    8000671e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006720:	6294                	ld	a3,0(a3)
    80006722:	96ba                	add	a3,a3,a4
    80006724:	40000613          	li	a2,1024
    80006728:	c690                	sw	a2,8(a3)
  if(write)
    8000672a:	140d0063          	beqz	s10,8000686a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000672e:	0001f697          	auipc	a3,0x1f
    80006732:	8d26b683          	ld	a3,-1838(a3) # 80025000 <disk+0x2000>
    80006736:	96ba                	add	a3,a3,a4
    80006738:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000673c:	0001d817          	auipc	a6,0x1d
    80006740:	8c480813          	addi	a6,a6,-1852 # 80023000 <disk>
    80006744:	0001f517          	auipc	a0,0x1f
    80006748:	8bc50513          	addi	a0,a0,-1860 # 80025000 <disk+0x2000>
    8000674c:	6114                	ld	a3,0(a0)
    8000674e:	96ba                	add	a3,a3,a4
    80006750:	00c6d603          	lhu	a2,12(a3)
    80006754:	00166613          	ori	a2,a2,1
    80006758:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000675c:	f9842683          	lw	a3,-104(s0)
    80006760:	6110                	ld	a2,0(a0)
    80006762:	9732                	add	a4,a4,a2
    80006764:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006768:	20058613          	addi	a2,a1,512
    8000676c:	0612                	slli	a2,a2,0x4
    8000676e:	9642                	add	a2,a2,a6
    80006770:	577d                	li	a4,-1
    80006772:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006776:	00469713          	slli	a4,a3,0x4
    8000677a:	6114                	ld	a3,0(a0)
    8000677c:	96ba                	add	a3,a3,a4
    8000677e:	03078793          	addi	a5,a5,48
    80006782:	97c2                	add	a5,a5,a6
    80006784:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006786:	611c                	ld	a5,0(a0)
    80006788:	97ba                	add	a5,a5,a4
    8000678a:	4685                	li	a3,1
    8000678c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000678e:	611c                	ld	a5,0(a0)
    80006790:	97ba                	add	a5,a5,a4
    80006792:	4809                	li	a6,2
    80006794:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006798:	611c                	ld	a5,0(a0)
    8000679a:	973e                	add	a4,a4,a5
    8000679c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067a0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067a4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067a8:	6518                	ld	a4,8(a0)
    800067aa:	00275783          	lhu	a5,2(a4)
    800067ae:	8b9d                	andi	a5,a5,7
    800067b0:	0786                	slli	a5,a5,0x1
    800067b2:	97ba                	add	a5,a5,a4
    800067b4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067bc:	6518                	ld	a4,8(a0)
    800067be:	00275783          	lhu	a5,2(a4)
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067c8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067cc:	100017b7          	lui	a5,0x10001
    800067d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067d4:	00492703          	lw	a4,4(s2)
    800067d8:	4785                	li	a5,1
    800067da:	02f71163          	bne	a4,a5,800067fc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067de:	0001f997          	auipc	s3,0x1f
    800067e2:	94a98993          	addi	s3,s3,-1718 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800067e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067e8:	85ce                	mv	a1,s3
    800067ea:	854a                	mv	a0,s2
    800067ec:	ffffc097          	auipc	ra,0xffffc
    800067f0:	cf2080e7          	jalr	-782(ra) # 800024de <sleep>
  while(b->disk == 1) {
    800067f4:	00492783          	lw	a5,4(s2)
    800067f8:	fe9788e3          	beq	a5,s1,800067e8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067fc:	f9042903          	lw	s2,-112(s0)
    80006800:	20090793          	addi	a5,s2,512
    80006804:	00479713          	slli	a4,a5,0x4
    80006808:	0001c797          	auipc	a5,0x1c
    8000680c:	7f878793          	addi	a5,a5,2040 # 80023000 <disk>
    80006810:	97ba                	add	a5,a5,a4
    80006812:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006816:	0001e997          	auipc	s3,0x1e
    8000681a:	7ea98993          	addi	s3,s3,2026 # 80025000 <disk+0x2000>
    8000681e:	00491713          	slli	a4,s2,0x4
    80006822:	0009b783          	ld	a5,0(s3)
    80006826:	97ba                	add	a5,a5,a4
    80006828:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000682c:	854a                	mv	a0,s2
    8000682e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006832:	00000097          	auipc	ra,0x0
    80006836:	bc4080e7          	jalr	-1084(ra) # 800063f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000683a:	8885                	andi	s1,s1,1
    8000683c:	f0ed                	bnez	s1,8000681e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000683e:	0001f517          	auipc	a0,0x1f
    80006842:	8ea50513          	addi	a0,a0,-1814 # 80025128 <disk+0x2128>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
}
    8000684e:	70a6                	ld	ra,104(sp)
    80006850:	7406                	ld	s0,96(sp)
    80006852:	64e6                	ld	s1,88(sp)
    80006854:	6946                	ld	s2,80(sp)
    80006856:	69a6                	ld	s3,72(sp)
    80006858:	6a06                	ld	s4,64(sp)
    8000685a:	7ae2                	ld	s5,56(sp)
    8000685c:	7b42                	ld	s6,48(sp)
    8000685e:	7ba2                	ld	s7,40(sp)
    80006860:	7c02                	ld	s8,32(sp)
    80006862:	6ce2                	ld	s9,24(sp)
    80006864:	6d42                	ld	s10,16(sp)
    80006866:	6165                	addi	sp,sp,112
    80006868:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000686a:	0001e697          	auipc	a3,0x1e
    8000686e:	7966b683          	ld	a3,1942(a3) # 80025000 <disk+0x2000>
    80006872:	96ba                	add	a3,a3,a4
    80006874:	4609                	li	a2,2
    80006876:	00c69623          	sh	a2,12(a3)
    8000687a:	b5c9                	j	8000673c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000687c:	f9042583          	lw	a1,-112(s0)
    80006880:	20058793          	addi	a5,a1,512
    80006884:	0792                	slli	a5,a5,0x4
    80006886:	0001d517          	auipc	a0,0x1d
    8000688a:	82250513          	addi	a0,a0,-2014 # 800230a8 <disk+0xa8>
    8000688e:	953e                	add	a0,a0,a5
  if(write)
    80006890:	e20d11e3          	bnez	s10,800066b2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006894:	20058713          	addi	a4,a1,512
    80006898:	00471693          	slli	a3,a4,0x4
    8000689c:	0001c717          	auipc	a4,0x1c
    800068a0:	76470713          	addi	a4,a4,1892 # 80023000 <disk>
    800068a4:	9736                	add	a4,a4,a3
    800068a6:	0a072423          	sw	zero,168(a4)
    800068aa:	b505                	j	800066ca <virtio_disk_rw+0xf4>

00000000800068ac <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068ac:	1101                	addi	sp,sp,-32
    800068ae:	ec06                	sd	ra,24(sp)
    800068b0:	e822                	sd	s0,16(sp)
    800068b2:	e426                	sd	s1,8(sp)
    800068b4:	e04a                	sd	s2,0(sp)
    800068b6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068b8:	0001f517          	auipc	a0,0x1f
    800068bc:	87050513          	addi	a0,a0,-1936 # 80025128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068c8:	10001737          	lui	a4,0x10001
    800068cc:	533c                	lw	a5,96(a4)
    800068ce:	8b8d                	andi	a5,a5,3
    800068d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068d6:	0001e797          	auipc	a5,0x1e
    800068da:	72a78793          	addi	a5,a5,1834 # 80025000 <disk+0x2000>
    800068de:	6b94                	ld	a3,16(a5)
    800068e0:	0207d703          	lhu	a4,32(a5)
    800068e4:	0026d783          	lhu	a5,2(a3)
    800068e8:	06f70163          	beq	a4,a5,8000694a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ec:	0001c917          	auipc	s2,0x1c
    800068f0:	71490913          	addi	s2,s2,1812 # 80023000 <disk>
    800068f4:	0001e497          	auipc	s1,0x1e
    800068f8:	70c48493          	addi	s1,s1,1804 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800068fc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006900:	6898                	ld	a4,16(s1)
    80006902:	0204d783          	lhu	a5,32(s1)
    80006906:	8b9d                	andi	a5,a5,7
    80006908:	078e                	slli	a5,a5,0x3
    8000690a:	97ba                	add	a5,a5,a4
    8000690c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000690e:	20078713          	addi	a4,a5,512
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	974a                	add	a4,a4,s2
    80006916:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000691a:	e731                	bnez	a4,80006966 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000691c:	20078793          	addi	a5,a5,512
    80006920:	0792                	slli	a5,a5,0x4
    80006922:	97ca                	add	a5,a5,s2
    80006924:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006926:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000692a:	ffffc097          	auipc	ra,0xffffc
    8000692e:	1a2080e7          	jalr	418(ra) # 80002acc <wakeup>

    disk.used_idx += 1;
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	2785                	addiw	a5,a5,1
    80006938:	17c2                	slli	a5,a5,0x30
    8000693a:	93c1                	srli	a5,a5,0x30
    8000693c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006940:	6898                	ld	a4,16(s1)
    80006942:	00275703          	lhu	a4,2(a4)
    80006946:	faf71be3          	bne	a4,a5,800068fc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000694a:	0001e517          	auipc	a0,0x1e
    8000694e:	7de50513          	addi	a0,a0,2014 # 80025128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000695a:	60e2                	ld	ra,24(sp)
    8000695c:	6442                	ld	s0,16(sp)
    8000695e:	64a2                	ld	s1,8(sp)
    80006960:	6902                	ld	s2,0(sp)
    80006962:	6105                	addi	sp,sp,32
    80006964:	8082                	ret
      panic("virtio_disk_intr status");
    80006966:	00002517          	auipc	a0,0x2
    8000696a:	fd250513          	addi	a0,a0,-46 # 80008938 <syscalls+0x3c8>
    8000696e:	ffffa097          	auipc	ra,0xffffa
    80006972:	bd0080e7          	jalr	-1072(ra) # 8000053e <panic>

0000000080006976 <cas>:
    80006976:	100522af          	lr.w	t0,(a0)
    8000697a:	00b29563          	bne	t0,a1,80006984 <fail>
    8000697e:	18c5252f          	sc.w	a0,a2,(a0)
    80006982:	8082                	ret

0000000080006984 <fail>:
    80006984:	4505                	li	a0,1
    80006986:	8082                	ret
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
