
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
    80000068:	d5c78793          	addi	a5,a5,-676 # 80005dc0 <timervec>
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
    80000130:	4f0080e7          	jalr	1264(ra) # 8000261c <either_copyin>
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
    800001c8:	80a080e7          	jalr	-2038(ra) # 800019ce <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	032080e7          	jalr	50(ra) # 80002206 <sleep>
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
    80000214:	3b6080e7          	jalr	950(ra) # 800025c6 <either_copyout>
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
    800002f6:	380080e7          	jalr	896(ra) # 80002672 <procdump>
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
    8000044a:	f4c080e7          	jalr	-180(ra) # 80002392 <wakeup>
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
    800008a4:	af2080e7          	jalr	-1294(ra) # 80002392 <wakeup>
    
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
    80000930:	8da080e7          	jalr	-1830(ra) # 80002206 <sleep>
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
    80000b82:	e34080e7          	jalr	-460(ra) # 800019b2 <mycpu>
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
    80000bb4:	e02080e7          	jalr	-510(ra) # 800019b2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df6080e7          	jalr	-522(ra) # 800019b2 <mycpu>
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
    80000bd8:	dde080e7          	jalr	-546(ra) # 800019b2 <mycpu>
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
    80000c18:	d9e080e7          	jalr	-610(ra) # 800019b2 <mycpu>
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
    80000c44:	d72080e7          	jalr	-654(ra) # 800019b2 <mycpu>
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
    80000e9a:	b0c080e7          	jalr	-1268(ra) # 800019a2 <cpuid>
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
    80000eb6:	af0080e7          	jalr	-1296(ra) # 800019a2 <cpuid>
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
    80000ed8:	97e080e7          	jalr	-1666(ra) # 80002852 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	f24080e7          	jalr	-220(ra) # 80005e00 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1e6080e7          	jalr	486(ra) # 800020ca <scheduler>
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
    80000f50:	9a6080e7          	jalr	-1626(ra) # 800018f2 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8d6080e7          	jalr	-1834(ra) # 8000282a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	8f6080e7          	jalr	-1802(ra) # 80002852 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	e86080e7          	jalr	-378(ra) # 80005dea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	e94080e7          	jalr	-364(ra) # 80005e00 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	06c080e7          	jalr	108(ra) # 80002fe0 <binit>
    iinit();         // inode table
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	6fc080e7          	jalr	1788(ra) # 80003678 <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	6a6080e7          	jalr	1702(ra) # 8000462a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	f96080e7          	jalr	-106(ra) # 80005f22 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d12080e7          	jalr	-750(ra) # 80001ca6 <userinit>
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
    8000124c:	614080e7          	jalr	1556(ra) # 8000185c <proc_mapstacks>
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

0000000080001846 <update_last_runnable_time>:
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void 
update_last_runnable_time(struct proc *p){
    80001846:	1141                	addi	sp,sp,-16
    80001848:	e422                	sd	s0,8(sp)
    8000184a:	0800                	addi	s0,sp,16
  #ifdef FCFS
    p->last_runnable_time = ticks;
    8000184c:	00007797          	auipc	a5,0x7
    80001850:	7ec7a783          	lw	a5,2028(a5) # 80009038 <ticks>
    80001854:	d95c                	sw	a5,52(a0)
  #endif
}  
    80001856:	6422                	ld	s0,8(sp)
    80001858:	0141                	addi	sp,sp,16
    8000185a:	8082                	ret

000000008000185c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000185c:	7139                	addi	sp,sp,-64
    8000185e:	fc06                	sd	ra,56(sp)
    80001860:	f822                	sd	s0,48(sp)
    80001862:	f426                	sd	s1,40(sp)
    80001864:	f04a                	sd	s2,32(sp)
    80001866:	ec4e                	sd	s3,24(sp)
    80001868:	e852                	sd	s4,16(sp)
    8000186a:	e456                	sd	s5,8(sp)
    8000186c:	e05a                	sd	s6,0(sp)
    8000186e:	0080                	addi	s0,sp,64
    80001870:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001872:	00010497          	auipc	s1,0x10
    80001876:	e5e48493          	addi	s1,s1,-418 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	8b26                	mv	s6,s1
    8000187c:	00006a97          	auipc	s5,0x6
    80001880:	784a8a93          	addi	s5,s5,1924 # 80008000 <etext>
    80001884:	04000937          	lui	s2,0x4000
    80001888:	197d                	addi	s2,s2,-1
    8000188a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188c:	00016a17          	auipc	s4,0x16
    80001890:	844a0a13          	addi	s4,s4,-1980 # 800170d0 <tickslock>
    char *pa = kalloc();
    80001894:	fffff097          	auipc	ra,0xfffff
    80001898:	260080e7          	jalr	608(ra) # 80000af4 <kalloc>
    8000189c:	862a                	mv	a2,a0
    if(pa == 0)
    8000189e:	c131                	beqz	a0,800018e2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018a0:	416485b3          	sub	a1,s1,s6
    800018a4:	858d                	srai	a1,a1,0x3
    800018a6:	000ab783          	ld	a5,0(s5)
    800018aa:	02f585b3          	mul	a1,a1,a5
    800018ae:	2585                	addiw	a1,a1,1
    800018b0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018b4:	4719                	li	a4,6
    800018b6:	6685                	lui	a3,0x1
    800018b8:	40b905b3          	sub	a1,s2,a1
    800018bc:	854e                	mv	a0,s3
    800018be:	00000097          	auipc	ra,0x0
    800018c2:	89a080e7          	jalr	-1894(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c6:	16848493          	addi	s1,s1,360
    800018ca:	fd4495e3          	bne	s1,s4,80001894 <proc_mapstacks+0x38>
  }
}
    800018ce:	70e2                	ld	ra,56(sp)
    800018d0:	7442                	ld	s0,48(sp)
    800018d2:	74a2                	ld	s1,40(sp)
    800018d4:	7902                	ld	s2,32(sp)
    800018d6:	69e2                	ld	s3,24(sp)
    800018d8:	6a42                	ld	s4,16(sp)
    800018da:	6aa2                	ld	s5,8(sp)
    800018dc:	6b02                	ld	s6,0(sp)
    800018de:	6121                	addi	sp,sp,64
    800018e0:	8082                	ret
      panic("kalloc");
    800018e2:	00007517          	auipc	a0,0x7
    800018e6:	8f650513          	addi	a0,a0,-1802 # 800081d8 <digits+0x198>
    800018ea:	fffff097          	auipc	ra,0xfffff
    800018ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>

00000000800018f2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018f2:	7139                	addi	sp,sp,-64
    800018f4:	fc06                	sd	ra,56(sp)
    800018f6:	f822                	sd	s0,48(sp)
    800018f8:	f426                	sd	s1,40(sp)
    800018fa:	f04a                	sd	s2,32(sp)
    800018fc:	ec4e                	sd	s3,24(sp)
    800018fe:	e852                	sd	s4,16(sp)
    80001900:	e456                	sd	s5,8(sp)
    80001902:	e05a                	sd	s6,0(sp)
    80001904:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001906:	00007597          	auipc	a1,0x7
    8000190a:	8da58593          	addi	a1,a1,-1830 # 800081e0 <digits+0x1a0>
    8000190e:	00010517          	auipc	a0,0x10
    80001912:	99250513          	addi	a0,a0,-1646 # 800112a0 <pid_lock>
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	23e080e7          	jalr	574(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000191e:	00007597          	auipc	a1,0x7
    80001922:	8ca58593          	addi	a1,a1,-1846 # 800081e8 <digits+0x1a8>
    80001926:	00010517          	auipc	a0,0x10
    8000192a:	99250513          	addi	a0,a0,-1646 # 800112b8 <wait_lock>
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	226080e7          	jalr	550(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001936:	00010497          	auipc	s1,0x10
    8000193a:	d9a48493          	addi	s1,s1,-614 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    8000193e:	00007b17          	auipc	s6,0x7
    80001942:	8bab0b13          	addi	s6,s6,-1862 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001946:	8aa6                	mv	s5,s1
    80001948:	00006a17          	auipc	s4,0x6
    8000194c:	6b8a0a13          	addi	s4,s4,1720 # 80008000 <etext>
    80001950:	04000937          	lui	s2,0x4000
    80001954:	197d                	addi	s2,s2,-1
    80001956:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00015997          	auipc	s3,0x15
    8000195c:	77898993          	addi	s3,s3,1912 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001960:	85da                	mv	a1,s6
    80001962:	8526                	mv	a0,s1
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	1f0080e7          	jalr	496(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000196c:	415487b3          	sub	a5,s1,s5
    80001970:	878d                	srai	a5,a5,0x3
    80001972:	000a3703          	ld	a4,0(s4)
    80001976:	02e787b3          	mul	a5,a5,a4
    8000197a:	2785                	addiw	a5,a5,1
    8000197c:	00d7979b          	slliw	a5,a5,0xd
    80001980:	40f907b3          	sub	a5,s2,a5
    80001984:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	16848493          	addi	s1,s1,360
    8000198a:	fd349be3          	bne	s1,s3,80001960 <procinit+0x6e>
  }
}
    8000198e:	70e2                	ld	ra,56(sp)
    80001990:	7442                	ld	s0,48(sp)
    80001992:	74a2                	ld	s1,40(sp)
    80001994:	7902                	ld	s2,32(sp)
    80001996:	69e2                	ld	s3,24(sp)
    80001998:	6a42                	ld	s4,16(sp)
    8000199a:	6aa2                	ld	s5,8(sp)
    8000199c:	6b02                	ld	s6,0(sp)
    8000199e:	6121                	addi	sp,sp,64
    800019a0:	8082                	ret

00000000800019a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a2:	1141                	addi	sp,sp,-16
    800019a4:	e422                	sd	s0,8(sp)
    800019a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019aa:	2501                	sext.w	a0,a0
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
    800019b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019be:	00010517          	auipc	a0,0x10
    800019c2:	91250513          	addi	a0,a0,-1774 # 800112d0 <cpus>
    800019c6:	953e                	add	a0,a0,a5
    800019c8:	6422                	ld	s0,8(sp)
    800019ca:	0141                	addi	sp,sp,16
    800019cc:	8082                	ret

00000000800019ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	1000                	addi	s0,sp,32
  push_off();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	1c0080e7          	jalr	448(ra) # 80000b98 <push_off>
    800019e0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
    800019e6:	00010717          	auipc	a4,0x10
    800019ea:	8ba70713          	addi	a4,a4,-1862 # 800112a0 <pid_lock>
    800019ee:	97ba                	add	a5,a5,a4
    800019f0:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	246080e7          	jalr	582(ra) # 80000c38 <pop_off>
  return p;
}
    800019fa:	8526                	mv	a0,s1
    800019fc:	60e2                	ld	ra,24(sp)
    800019fe:	6442                	ld	s0,16(sp)
    80001a00:	64a2                	ld	s1,8(sp)
    80001a02:	6105                	addi	sp,sp,32
    80001a04:	8082                	ret

0000000080001a06 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a06:	1141                	addi	sp,sp,-16
    80001a08:	e406                	sd	ra,8(sp)
    80001a0a:	e022                	sd	s0,0(sp)
    80001a0c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a0e:	00000097          	auipc	ra,0x0
    80001a12:	fc0080e7          	jalr	-64(ra) # 800019ce <myproc>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	282080e7          	jalr	642(ra) # 80000c98 <release>

  if (first) {
    80001a1e:	00007797          	auipc	a5,0x7
    80001a22:	e227a783          	lw	a5,-478(a5) # 80008840 <first.1714>
    80001a26:	eb89                	bnez	a5,80001a38 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a28:	00001097          	auipc	ra,0x1
    80001a2c:	e42080e7          	jalr	-446(ra) # 8000286a <usertrapret>
}
    80001a30:	60a2                	ld	ra,8(sp)
    80001a32:	6402                	ld	s0,0(sp)
    80001a34:	0141                	addi	sp,sp,16
    80001a36:	8082                	ret
    first = 0;
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	e007a423          	sw	zero,-504(a5) # 80008840 <first.1714>
    fsinit(ROOTDEV);
    80001a40:	4505                	li	a0,1
    80001a42:	00002097          	auipc	ra,0x2
    80001a46:	bb6080e7          	jalr	-1098(ra) # 800035f8 <fsinit>
    80001a4a:	bff9                	j	80001a28 <forkret+0x22>

0000000080001a4c <allocpid>:
allocpid() {
    80001a4c:	1101                	addi	sp,sp,-32
    80001a4e:	ec06                	sd	ra,24(sp)
    80001a50:	e822                	sd	s0,16(sp)
    80001a52:	e426                	sd	s1,8(sp)
    80001a54:	e04a                	sd	s2,0(sp)
    80001a56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a58:	00010917          	auipc	s2,0x10
    80001a5c:	84890913          	addi	s2,s2,-1976 # 800112a0 <pid_lock>
    80001a60:	854a                	mv	a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	182080e7          	jalr	386(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a6a:	00007797          	auipc	a5,0x7
    80001a6e:	dda78793          	addi	a5,a5,-550 # 80008844 <nextpid>
    80001a72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a74:	0014871b          	addiw	a4,s1,1
    80001a78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	21c080e7          	jalr	540(ra) # 80000c98 <release>
}
    80001a84:	8526                	mv	a0,s1
    80001a86:	60e2                	ld	ra,24(sp)
    80001a88:	6442                	ld	s0,16(sp)
    80001a8a:	64a2                	ld	s1,8(sp)
    80001a8c:	6902                	ld	s2,0(sp)
    80001a8e:	6105                	addi	sp,sp,32
    80001a90:	8082                	ret

0000000080001a92 <proc_pagetable>:
{
    80001a92:	1101                	addi	sp,sp,-32
    80001a94:	ec06                	sd	ra,24(sp)
    80001a96:	e822                	sd	s0,16(sp)
    80001a98:	e426                	sd	s1,8(sp)
    80001a9a:	e04a                	sd	s2,0(sp)
    80001a9c:	1000                	addi	s0,sp,32
    80001a9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa0:	00000097          	auipc	ra,0x0
    80001aa4:	8a2080e7          	jalr	-1886(ra) # 80001342 <uvmcreate>
    80001aa8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aaa:	c121                	beqz	a0,80001aea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aac:	4729                	li	a4,10
    80001aae:	00005697          	auipc	a3,0x5
    80001ab2:	55268693          	addi	a3,a3,1362 # 80007000 <_trampoline>
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	040005b7          	lui	a1,0x4000
    80001abc:	15fd                	addi	a1,a1,-1
    80001abe:	05b2                	slli	a1,a1,0xc
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f8080e7          	jalr	1528(ra) # 800010b8 <mappages>
    80001ac8:	02054863          	bltz	a0,80001af8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001acc:	4719                	li	a4,6
    80001ace:	05893683          	ld	a3,88(s2)
    80001ad2:	6605                	lui	a2,0x1
    80001ad4:	020005b7          	lui	a1,0x2000
    80001ad8:	15fd                	addi	a1,a1,-1
    80001ada:	05b6                	slli	a1,a1,0xd
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	5da080e7          	jalr	1498(ra) # 800010b8 <mappages>
    80001ae6:	02054163          	bltz	a0,80001b08 <proc_pagetable+0x76>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6902                	ld	s2,0(sp)
    80001af4:	6105                	addi	sp,sp,32
    80001af6:	8082                	ret
    uvmfree(pagetable, 0);
    80001af8:	4581                	li	a1,0
    80001afa:	8526                	mv	a0,s1
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	a42080e7          	jalr	-1470(ra) # 8000153e <uvmfree>
    return 0;
    80001b04:	4481                	li	s1,0
    80001b06:	b7d5                	j	80001aea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b08:	4681                	li	a3,0
    80001b0a:	4605                	li	a2,1
    80001b0c:	040005b7          	lui	a1,0x4000
    80001b10:	15fd                	addi	a1,a1,-1
    80001b12:	05b2                	slli	a1,a1,0xc
    80001b14:	8526                	mv	a0,s1
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	768080e7          	jalr	1896(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1e:	4581                	li	a1,0
    80001b20:	8526                	mv	a0,s1
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	a1c080e7          	jalr	-1508(ra) # 8000153e <uvmfree>
    return 0;
    80001b2a:	4481                	li	s1,0
    80001b2c:	bf7d                	j	80001aea <proc_pagetable+0x58>

0000000080001b2e <proc_freepagetable>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
    80001b3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	040005b7          	lui	a1,0x4000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b2                	slli	a1,a1,0xc
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	734080e7          	jalr	1844(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	020005b7          	lui	a1,0x2000
    80001b5a:	15fd                	addi	a1,a1,-1
    80001b5c:	05b6                	slli	a1,a1,0xd
    80001b5e:	8526                	mv	a0,s1
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	71e080e7          	jalr	1822(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b68:	85ca                	mv	a1,s2
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	9d2080e7          	jalr	-1582(ra) # 8000153e <uvmfree>
}
    80001b74:	60e2                	ld	ra,24(sp)
    80001b76:	6442                	ld	s0,16(sp)
    80001b78:	64a2                	ld	s1,8(sp)
    80001b7a:	6902                	ld	s2,0(sp)
    80001b7c:	6105                	addi	sp,sp,32
    80001b7e:	8082                	ret

0000000080001b80 <freeproc>:
{
    80001b80:	1101                	addi	sp,sp,-32
    80001b82:	ec06                	sd	ra,24(sp)
    80001b84:	e822                	sd	s0,16(sp)
    80001b86:	e426                	sd	s1,8(sp)
    80001b88:	1000                	addi	s0,sp,32
    80001b8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8c:	6d28                	ld	a0,88(a0)
    80001b8e:	c509                	beqz	a0,80001b98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	e68080e7          	jalr	-408(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b9c:	68a8                	ld	a0,80(s1)
    80001b9e:	c511                	beqz	a0,80001baa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba0:	64ac                	ld	a1,72(s1)
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	f8c080e7          	jalr	-116(ra) # 80001b2e <proc_freepagetable>
  p->pagetable = 0;
    80001baa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bae:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb2:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bb6:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bba:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bbe:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bc6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bca:	0004ac23          	sw	zero,24(s1)
}
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <allocproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	00010497          	auipc	s1,0x10
    80001be8:	aec48493          	addi	s1,s1,-1300 # 800116d0 <proc>
    80001bec:	00015917          	auipc	s2,0x15
    80001bf0:	4e490913          	addi	s2,s2,1252 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	fee080e7          	jalr	-18(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001bfe:	4c9c                	lw	a5,24(s1)
    80001c00:	cf81                	beqz	a5,80001c18 <allocproc+0x40>
      release(&p->lock);
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	094080e7          	jalr	148(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0c:	16848493          	addi	s1,s1,360
    80001c10:	ff2492e3          	bne	s1,s2,80001bf4 <allocproc+0x1c>
  return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	a889                	j	80001c68 <allocproc+0x90>
  p->pid = allocpid();
    80001c18:	00000097          	auipc	ra,0x0
    80001c1c:	e34080e7          	jalr	-460(ra) # 80001a4c <allocpid>
    80001c20:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c22:	4785                	li	a5,1
    80001c24:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	ece080e7          	jalr	-306(ra) # 80000af4 <kalloc>
    80001c2e:	892a                	mv	s2,a0
    80001c30:	eca8                	sd	a0,88(s1)
    80001c32:	c131                	beqz	a0,80001c76 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	e5c080e7          	jalr	-420(ra) # 80001a92 <proc_pagetable>
    80001c3e:	892a                	mv	s2,a0
    80001c40:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c42:	c531                	beqz	a0,80001c8e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c44:	07000613          	li	a2,112
    80001c48:	4581                	li	a1,0
    80001c4a:	06048513          	addi	a0,s1,96
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	092080e7          	jalr	146(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c56:	00000797          	auipc	a5,0x0
    80001c5a:	db078793          	addi	a5,a5,-592 # 80001a06 <forkret>
    80001c5e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c60:	60bc                	ld	a5,64(s1)
    80001c62:	6705                	lui	a4,0x1
    80001c64:	97ba                	add	a5,a5,a4
    80001c66:	f4bc                	sd	a5,104(s1)
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret
    freeproc(p);
    80001c76:	8526                	mv	a0,s1
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	f08080e7          	jalr	-248(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	016080e7          	jalr	22(ra) # 80000c98 <release>
    return 0;
    80001c8a:	84ca                	mv	s1,s2
    80001c8c:	bff1                	j	80001c68 <allocproc+0x90>
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ef0080e7          	jalr	-272(ra) # 80001b80 <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ffe080e7          	jalr	-2(ra) # 80000c98 <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	b7d1                	j	80001c68 <allocproc+0x90>

0000000080001ca6 <userinit>:
{
    80001ca6:	1101                	addi	sp,sp,-32
    80001ca8:	ec06                	sd	ra,24(sp)
    80001caa:	e822                	sd	s0,16(sp)
    80001cac:	e426                	sd	s1,8(sp)
    80001cae:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	f28080e7          	jalr	-216(ra) # 80001bd8 <allocproc>
    80001cb8:	84aa                	mv	s1,a0
  initproc = p;
    80001cba:	00007797          	auipc	a5,0x7
    80001cbe:	36a7bb23          	sd	a0,886(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc2:	03400613          	li	a2,52
    80001cc6:	00007597          	auipc	a1,0x7
    80001cca:	b8a58593          	addi	a1,a1,-1142 # 80008850 <initcode>
    80001cce:	6928                	ld	a0,80(a0)
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	6a0080e7          	jalr	1696(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001cd8:	6785                	lui	a5,0x1
    80001cda:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cdc:	6cb8                	ld	a4,88(s1)
    80001cde:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce2:	6cb8                	ld	a4,88(s1)
    80001ce4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce6:	4641                	li	a2,16
    80001ce8:	00006597          	auipc	a1,0x6
    80001cec:	51858593          	addi	a1,a1,1304 # 80008200 <digits+0x1c0>
    80001cf0:	15848513          	addi	a0,s1,344
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	13e080e7          	jalr	318(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001cfc:	00006517          	auipc	a0,0x6
    80001d00:	51450513          	addi	a0,a0,1300 # 80008210 <digits+0x1d0>
    80001d04:	00002097          	auipc	ra,0x2
    80001d08:	322080e7          	jalr	802(ra) # 80004026 <namei>
    80001d0c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d10:	478d                	li	a5,3
    80001d12:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    80001d14:	00007797          	auipc	a5,0x7
    80001d18:	3247a783          	lw	a5,804(a5) # 80009038 <ticks>
    80001d1c:	d8dc                	sw	a5,52(s1)
  release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	f78080e7          	jalr	-136(ra) # 80000c98 <release>
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <growproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
    80001d3e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	c8e080e7          	jalr	-882(ra) # 800019ce <myproc>
    80001d48:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4a:	652c                	ld	a1,72(a0)
    80001d4c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d50:	00904f63          	bgtz	s1,80001d6e <growproc+0x3c>
  } else if(n < 0){
    80001d54:	0204cc63          	bltz	s1,80001d8c <growproc+0x5a>
  p->sz = sz;
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d60:	4501                	li	a0,0
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d6e:	9e25                	addw	a2,a2,s1
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	1582                	slli	a1,a1,0x20
    80001d76:	9181                	srli	a1,a1,0x20
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	6b0080e7          	jalr	1712(ra) # 8000142a <uvmalloc>
    80001d82:	0005061b          	sext.w	a2,a0
    80001d86:	fa69                	bnez	a2,80001d58 <growproc+0x26>
      return -1;
    80001d88:	557d                	li	a0,-1
    80001d8a:	bfe1                	j	80001d62 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8c:	9e25                	addw	a2,a2,s1
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	64a080e7          	jalr	1610(ra) # 800013e2 <uvmdealloc>
    80001da0:	0005061b          	sext.w	a2,a0
    80001da4:	bf55                	j	80001d58 <growproc+0x26>

0000000080001da6 <fork>:
{
    80001da6:	7179                	addi	sp,sp,-48
    80001da8:	f406                	sd	ra,40(sp)
    80001daa:	f022                	sd	s0,32(sp)
    80001dac:	ec26                	sd	s1,24(sp)
    80001dae:	e84a                	sd	s2,16(sp)
    80001db0:	e44e                	sd	s3,8(sp)
    80001db2:	e052                	sd	s4,0(sp)
    80001db4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	c18080e7          	jalr	-1000(ra) # 800019ce <myproc>
    80001dbe:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	e18080e7          	jalr	-488(ra) # 80001bd8 <allocproc>
    80001dc8:	12050163          	beqz	a0,80001eea <fork+0x144>
    80001dcc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dce:	04893603          	ld	a2,72(s2)
    80001dd2:	692c                	ld	a1,80(a0)
    80001dd4:	05093503          	ld	a0,80(s2)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	79e080e7          	jalr	1950(ra) # 80001576 <uvmcopy>
    80001de0:	04054663          	bltz	a0,80001e2c <fork+0x86>
  np->sz = p->sz;
    80001de4:	04893783          	ld	a5,72(s2)
    80001de8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dec:	05893683          	ld	a3,88(s2)
    80001df0:	87b6                	mv	a5,a3
    80001df2:	0589b703          	ld	a4,88(s3)
    80001df6:	12068693          	addi	a3,a3,288
    80001dfa:	0007b803          	ld	a6,0(a5)
    80001dfe:	6788                	ld	a0,8(a5)
    80001e00:	6b8c                	ld	a1,16(a5)
    80001e02:	6f90                	ld	a2,24(a5)
    80001e04:	01073023          	sd	a6,0(a4)
    80001e08:	e708                	sd	a0,8(a4)
    80001e0a:	eb0c                	sd	a1,16(a4)
    80001e0c:	ef10                	sd	a2,24(a4)
    80001e0e:	02078793          	addi	a5,a5,32
    80001e12:	02070713          	addi	a4,a4,32
    80001e16:	fed792e3          	bne	a5,a3,80001dfa <fork+0x54>
  np->trapframe->a0 = 0;
    80001e1a:	0589b783          	ld	a5,88(s3)
    80001e1e:	0607b823          	sd	zero,112(a5)
    80001e22:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e26:	15000a13          	li	s4,336
    80001e2a:	a03d                	j	80001e58 <fork+0xb2>
    freeproc(np);
    80001e2c:	854e                	mv	a0,s3
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	d52080e7          	jalr	-686(ra) # 80001b80 <freeproc>
    release(&np->lock);
    80001e36:	854e                	mv	a0,s3
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
    return -1;
    80001e40:	5a7d                	li	s4,-1
    80001e42:	a859                	j	80001ed8 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e44:	00003097          	auipc	ra,0x3
    80001e48:	878080e7          	jalr	-1928(ra) # 800046bc <filedup>
    80001e4c:	009987b3          	add	a5,s3,s1
    80001e50:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	01448763          	beq	s1,s4,80001e62 <fork+0xbc>
    if(p->ofile[i])
    80001e58:	009907b3          	add	a5,s2,s1
    80001e5c:	6388                	ld	a0,0(a5)
    80001e5e:	f17d                	bnez	a0,80001e44 <fork+0x9e>
    80001e60:	bfcd                	j	80001e52 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e62:	15093503          	ld	a0,336(s2)
    80001e66:	00002097          	auipc	ra,0x2
    80001e6a:	9cc080e7          	jalr	-1588(ra) # 80003832 <idup>
    80001e6e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e72:	4641                	li	a2,16
    80001e74:	15890593          	addi	a1,s2,344
    80001e78:	15898513          	addi	a0,s3,344
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	fb6080e7          	jalr	-74(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e84:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	e0e080e7          	jalr	-498(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e92:	0000f497          	auipc	s1,0xf
    80001e96:	42648493          	addi	s1,s1,1062 # 800112b8 <wait_lock>
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	d48080e7          	jalr	-696(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	dee080e7          	jalr	-530(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb2:	854e                	mv	a0,s3
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d30080e7          	jalr	-720(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ebc:	478d                	li	a5,3
    80001ebe:	00f9ac23          	sw	a5,24(s3)
    p->last_runnable_time = ticks;
    80001ec2:	00007797          	auipc	a5,0x7
    80001ec6:	1767a783          	lw	a5,374(a5) # 80009038 <ticks>
    80001eca:	02f92a23          	sw	a5,52(s2)
  release(&np->lock);
    80001ece:	854e                	mv	a0,s3
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
}
    80001ed8:	8552                	mv	a0,s4
    80001eda:	70a2                	ld	ra,40(sp)
    80001edc:	7402                	ld	s0,32(sp)
    80001ede:	64e2                	ld	s1,24(sp)
    80001ee0:	6942                	ld	s2,16(sp)
    80001ee2:	69a2                	ld	s3,8(sp)
    80001ee4:	6a02                	ld	s4,0(sp)
    80001ee6:	6145                	addi	sp,sp,48
    80001ee8:	8082                	ret
    return -1;
    80001eea:	5a7d                	li	s4,-1
    80001eec:	b7f5                	j	80001ed8 <fork+0x132>

0000000080001eee <scheduler_default>:
{
    80001eee:	715d                	addi	sp,sp,-80
    80001ef0:	e486                	sd	ra,72(sp)
    80001ef2:	e0a2                	sd	s0,64(sp)
    80001ef4:	fc26                	sd	s1,56(sp)
    80001ef6:	f84a                	sd	s2,48(sp)
    80001ef8:	f44e                	sd	s3,40(sp)
    80001efa:	f052                	sd	s4,32(sp)
    80001efc:	ec56                	sd	s5,24(sp)
    80001efe:	e85a                	sd	s6,16(sp)
    80001f00:	e45e                	sd	s7,8(sp)
    80001f02:	e062                	sd	s8,0(sp)
    80001f04:	0880                	addi	s0,sp,80
    80001f06:	8792                	mv	a5,tp
  int id = r_tp();
    80001f08:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0a:	00779c13          	slli	s8,a5,0x7
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	39270713          	addi	a4,a4,914 # 800112a0 <pid_lock>
    80001f16:	9762                	add	a4,a4,s8
    80001f18:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f1c:	0000f717          	auipc	a4,0xf
    80001f20:	3bc70713          	addi	a4,a4,956 # 800112d8 <cpus+0x8>
    80001f24:	9c3a                	add	s8,s8,a4
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f26:	00007a17          	auipc	s4,0x7
    80001f2a:	112a0a13          	addi	s4,s4,274 # 80009038 <ticks>
    80001f2e:	00007997          	auipc	s3,0x7
    80001f32:	0fa98993          	addi	s3,s3,250 # 80009028 <pause_ticks>
        if(p->state == RUNNABLE) {
    80001f36:	4a8d                	li	s5,3
          c->proc = p;
    80001f38:	079e                	slli	a5,a5,0x7
    80001f3a:	0000fb17          	auipc	s6,0xf
    80001f3e:	366b0b13          	addi	s6,s6,870 # 800112a0 <pid_lock>
    80001f42:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f44:	00015917          	auipc	s2,0x15
    80001f48:	18c90913          	addi	s2,s2,396 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f50:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f54:	10079073          	csrw	sstatus,a5
    80001f58:	0000f497          	auipc	s1,0xf
    80001f5c:	77848493          	addi	s1,s1,1912 # 800116d0 <proc>
          p->state = RUNNING;
    80001f60:	4b91                	li	s7,4
    80001f62:	a03d                	j	80001f90 <scheduler_default+0xa2>
    80001f64:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80001f68:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    80001f6c:	06048593          	addi	a1,s1,96
    80001f70:	8562                	mv	a0,s8
    80001f72:	00001097          	auipc	ra,0x1
    80001f76:	84e080e7          	jalr	-1970(ra) # 800027c0 <swtch>
          c->proc = 0;
    80001f7a:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d18080e7          	jalr	-744(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f88:	16848493          	addi	s1,s1,360
    80001f8c:	fd2480e3          	beq	s1,s2,80001f4c <scheduler_default+0x5e>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f90:	000a2703          	lw	a4,0(s4)
    80001f94:	0009a783          	lw	a5,0(s3)
    80001f98:	fef768e3          	bltu	a4,a5,80001f88 <scheduler_default+0x9a>
        acquire(&p->lock);
    80001f9c:	8526                	mv	a0,s1
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	c46080e7          	jalr	-954(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001fa6:	4c9c                	lw	a5,24(s1)
    80001fa8:	fd579be3          	bne	a5,s5,80001f7e <scheduler_default+0x90>
    80001fac:	bf65                	j	80001f64 <scheduler_default+0x76>

0000000080001fae <swap_process_ptr>:
{
    80001fae:	1141                	addi	sp,sp,-16
    80001fb0:	e422                	sd	s0,8(sp)
    80001fb2:	0800                	addi	s0,sp,16
  struct proc *temp = *p1;
    80001fb4:	611c                	ld	a5,0(a0)
  *p1 = *p2;
    80001fb6:	6198                	ld	a4,0(a1)
    80001fb8:	e118                	sd	a4,0(a0)
  *p2 = temp; 
    80001fba:	e19c                	sd	a5,0(a1)
}     
    80001fbc:	6422                	ld	s0,8(sp)
    80001fbe:	0141                	addi	sp,sp,16
    80001fc0:	8082                	ret

0000000080001fc2 <make_acquired_process_running>:
make_acquired_process_running(struct cpu *c, struct proc *p){
    80001fc2:	1101                	addi	sp,sp,-32
    80001fc4:	ec06                	sd	ra,24(sp)
    80001fc6:	e822                	sd	s0,16(sp)
    80001fc8:	e426                	sd	s1,8(sp)
    80001fca:	e04a                	sd	s2,0(sp)
    80001fcc:	1000                	addi	s0,sp,32
    80001fce:	892a                	mv	s2,a0
    80001fd0:	84ae                	mv	s1,a1
  p->state = RUNNING;
    80001fd2:	4791                	li	a5,4
    80001fd4:	cd9c                	sw	a5,24(a1)
  c->proc = p;
    80001fd6:	e10c                	sd	a1,0(a0)
  swtch(&c->context, &p->context);
    80001fd8:	06058593          	addi	a1,a1,96
    80001fdc:	0521                	addi	a0,a0,8
    80001fde:	00000097          	auipc	ra,0x0
    80001fe2:	7e2080e7          	jalr	2018(ra) # 800027c0 <swtch>
  c->proc = 0;
    80001fe6:	00093023          	sd	zero,0(s2)
  release(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
}
    80001ff4:	60e2                	ld	ra,24(sp)
    80001ff6:	6442                	ld	s0,16(sp)
    80001ff8:	64a2                	ld	s1,8(sp)
    80001ffa:	6902                	ld	s2,0(sp)
    80001ffc:	6105                	addi	sp,sp,32
    80001ffe:	8082                	ret

0000000080002000 <scheduler_fcfs>:
scheduler_fcfs(void) {
    80002000:	715d                	addi	sp,sp,-80
    80002002:	e486                	sd	ra,72(sp)
    80002004:	e0a2                	sd	s0,64(sp)
    80002006:	fc26                	sd	s1,56(sp)
    80002008:	f84a                	sd	s2,48(sp)
    8000200a:	f44e                	sd	s3,40(sp)
    8000200c:	f052                	sd	s4,32(sp)
    8000200e:	ec56                	sd	s5,24(sp)
    80002010:	e85a                	sd	s6,16(sp)
    80002012:	e45e                	sd	s7,8(sp)
    80002014:	e062                	sd	s8,0(sp)
    80002016:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002018:	8792                	mv	a5,tp
  int id = r_tp();
    8000201a:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	0000fb97          	auipc	s7,0xf
    80002022:	2b2b8b93          	addi	s7,s7,690 # 800112d0 <cpus>
    80002026:	9bbe                	add	s7,s7,a5
  c->proc = 0;
    80002028:	0000f717          	auipc	a4,0xf
    8000202c:	27870713          	addi	a4,a4,632 # 800112a0 <pid_lock>
    80002030:	97ba                	add	a5,a5,a4
    80002032:	0207b823          	sd	zero,48(a5)
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002036:	0000fb17          	auipc	s6,0xf
    8000203a:	69ab0b13          	addi	s6,s6,1690 # 800116d0 <proc>
      if(ticks >= pause_ticks){ // check if pause signal was called
    8000203e:	00007a97          	auipc	s5,0x7
    80002042:	ffaa8a93          	addi	s5,s5,-6 # 80009038 <ticks>
    80002046:	00007a17          	auipc	s4,0x7
    8000204a:	fe2a0a13          	addi	s4,s4,-30 # 80009028 <pause_ticks>
        if(curr->state == RUNNABLE) {
    8000204e:	4c0d                	li	s8,3
    for(curr = proc; curr < &proc[NPROC]; p++) {
    80002050:	00015997          	auipc	s3,0x15
    80002054:	08098993          	addi	s3,s3,128 # 800170d0 <tickslock>
    80002058:	a889                	j	800020aa <scheduler_fcfs+0xaa>
        acquire(&curr->lock);
    8000205a:	854a                	mv	a0,s2
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	b88080e7          	jalr	-1144(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    80002064:	01892783          	lw	a5,24(s2)
    80002068:	01878a63          	beq	a5,s8,8000207c <scheduler_fcfs+0x7c>
        if(p != curr)
    8000206c:	03248463          	beq	s1,s2,80002094 <scheduler_fcfs+0x94>
          release(&curr->lock);
    80002070:	854a                	mv	a0,s2
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c26080e7          	jalr	-986(ra) # 80000c98 <release>
    8000207a:	a0b1                	j	800020c6 <scheduler_fcfs+0xc6>
          if(p == NULL){
    8000207c:	c891                	beqz	s1,80002090 <scheduler_fcfs+0x90>
          } else if(p->last_runnable_time > curr->last_runnable_time) {
    8000207e:	58d8                	lw	a4,52(s1)
    80002080:	03492783          	lw	a5,52(s2)
    80002084:	fee7f4e3          	bgeu	a5,a4,8000206c <scheduler_fcfs+0x6c>
    80002088:	87a6                	mv	a5,s1
    8000208a:	84ca                	mv	s1,s2
    8000208c:	893e                	mv	s2,a5
    8000208e:	bff9                	j	8000206c <scheduler_fcfs+0x6c>
    80002090:	84ca                	mv	s1,s2
    80002092:	a011                	j	80002096 <scheduler_fcfs+0x96>
        if(p != curr)
    80002094:	84ca                	mv	s1,s2
        make_acquired_process_running(c, p);
    80002096:	85a6                	mv	a1,s1
    80002098:	855e                	mv	a0,s7
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	f28080e7          	jalr	-216(ra) # 80001fc2 <make_acquired_process_running>
    for(curr = proc; curr < &proc[NPROC]; p++) {
    800020a2:	16848493          	addi	s1,s1,360
    800020a6:	01396a63          	bltu	s2,s3,800020ba <scheduler_fcfs+0xba>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b2:	10079073          	csrw	sstatus,a5
    800020b6:	895a                	mv	s2,s6
    p = NULL;
    800020b8:	4481                	li	s1,0
      if(ticks >= pause_ticks){ // check if pause signal was called
    800020ba:	000aa703          	lw	a4,0(s5)
    800020be:	000a2783          	lw	a5,0(s4)
    800020c2:	f8f77ce3          	bgeu	a4,a5,8000205a <scheduler_fcfs+0x5a>
      if(p != NULL){
    800020c6:	dcf1                	beqz	s1,800020a2 <scheduler_fcfs+0xa2>
    800020c8:	b7f9                	j	80002096 <scheduler_fcfs+0x96>

00000000800020ca <scheduler>:
{
    800020ca:	1141                	addi	sp,sp,-16
    800020cc:	e406                	sd	ra,8(sp)
    800020ce:	e022                	sd	s0,0(sp)
    800020d0:	0800                	addi	s0,sp,16
    printf("FCFS scheduler mode\n");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	14650513          	addi	a0,a0,326 # 80008218 <digits+0x1d8>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	4ae080e7          	jalr	1198(ra) # 80000588 <printf>
    scheduler_fcfs();
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	f1e080e7          	jalr	-226(ra) # 80002000 <scheduler_fcfs>

00000000800020ea <sched>:
{
    800020ea:	7179                	addi	sp,sp,-48
    800020ec:	f406                	sd	ra,40(sp)
    800020ee:	f022                	sd	s0,32(sp)
    800020f0:	ec26                	sd	s1,24(sp)
    800020f2:	e84a                	sd	s2,16(sp)
    800020f4:	e44e                	sd	s3,8(sp)
    800020f6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	8d6080e7          	jalr	-1834(ra) # 800019ce <myproc>
    80002100:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	a68080e7          	jalr	-1432(ra) # 80000b6a <holding>
    8000210a:	c93d                	beqz	a0,80002180 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000210c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000210e:	2781                	sext.w	a5,a5
    80002110:	079e                	slli	a5,a5,0x7
    80002112:	0000f717          	auipc	a4,0xf
    80002116:	18e70713          	addi	a4,a4,398 # 800112a0 <pid_lock>
    8000211a:	97ba                	add	a5,a5,a4
    8000211c:	0a87a703          	lw	a4,168(a5)
    80002120:	4785                	li	a5,1
    80002122:	06f71763          	bne	a4,a5,80002190 <sched+0xa6>
  if(p->state == RUNNING)
    80002126:	4c98                	lw	a4,24(s1)
    80002128:	4791                	li	a5,4
    8000212a:	06f70b63          	beq	a4,a5,800021a0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000212e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002132:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002134:	efb5                	bnez	a5,800021b0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002136:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002138:	0000f917          	auipc	s2,0xf
    8000213c:	16890913          	addi	s2,s2,360 # 800112a0 <pid_lock>
    80002140:	2781                	sext.w	a5,a5
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	97ca                	add	a5,a5,s2
    80002146:	0ac7a983          	lw	s3,172(a5)
    8000214a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	0000f597          	auipc	a1,0xf
    80002154:	18858593          	addi	a1,a1,392 # 800112d8 <cpus+0x8>
    80002158:	95be                	add	a1,a1,a5
    8000215a:	06048513          	addi	a0,s1,96
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	662080e7          	jalr	1634(ra) # 800027c0 <swtch>
    80002166:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002168:	2781                	sext.w	a5,a5
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	97ca                	add	a5,a5,s2
    8000216e:	0b37a623          	sw	s3,172(a5)
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6145                	addi	sp,sp,48
    8000217e:	8082                	ret
    panic("sched p->lock");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	0b050513          	addi	a0,a0,176 # 80008230 <digits+0x1f0>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>
    panic("sched locks");
    80002190:	00006517          	auipc	a0,0x6
    80002194:	0b050513          	addi	a0,a0,176 # 80008240 <digits+0x200>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
    panic("sched running");
    800021a0:	00006517          	auipc	a0,0x6
    800021a4:	0b050513          	addi	a0,a0,176 # 80008250 <digits+0x210>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	396080e7          	jalr	918(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021b0:	00006517          	auipc	a0,0x6
    800021b4:	0b050513          	addi	a0,a0,176 # 80008260 <digits+0x220>
    800021b8:	ffffe097          	auipc	ra,0xffffe
    800021bc:	386080e7          	jalr	902(ra) # 8000053e <panic>

00000000800021c0 <yield>:
{
    800021c0:	1101                	addi	sp,sp,-32
    800021c2:	ec06                	sd	ra,24(sp)
    800021c4:	e822                	sd	s0,16(sp)
    800021c6:	e426                	sd	s1,8(sp)
    800021c8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	804080e7          	jalr	-2044(ra) # 800019ce <myproc>
    800021d2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	a10080e7          	jalr	-1520(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021dc:	478d                	li	a5,3
    800021de:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    800021e0:	00007797          	auipc	a5,0x7
    800021e4:	e587a783          	lw	a5,-424(a5) # 80009038 <ticks>
    800021e8:	d8dc                	sw	a5,52(s1)
  sched();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	f00080e7          	jalr	-256(ra) # 800020ea <sched>
  release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
}
    800021fc:	60e2                	ld	ra,24(sp)
    800021fe:	6442                	ld	s0,16(sp)
    80002200:	64a2                	ld	s1,8(sp)
    80002202:	6105                	addi	sp,sp,32
    80002204:	8082                	ret

0000000080002206 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002206:	7179                	addi	sp,sp,-48
    80002208:	f406                	sd	ra,40(sp)
    8000220a:	f022                	sd	s0,32(sp)
    8000220c:	ec26                	sd	s1,24(sp)
    8000220e:	e84a                	sd	s2,16(sp)
    80002210:	e44e                	sd	s3,8(sp)
    80002212:	1800                	addi	s0,sp,48
    80002214:	89aa                	mv	s3,a0
    80002216:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	7b6080e7          	jalr	1974(ra) # 800019ce <myproc>
    80002220:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9c2080e7          	jalr	-1598(ra) # 80000be4 <acquire>
  release(lk);
    8000222a:	854a                	mv	a0,s2
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002234:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002238:	4789                	li	a5,2
    8000223a:	cc9c                	sw	a5,24(s1)

  sched();
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	eae080e7          	jalr	-338(ra) # 800020ea <sched>

  // Tidy up.
  p->chan = 0;
    80002244:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a4e080e7          	jalr	-1458(ra) # 80000c98 <release>
  acquire(lk);
    80002252:	854a                	mv	a0,s2
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	990080e7          	jalr	-1648(ra) # 80000be4 <acquire>
}
    8000225c:	70a2                	ld	ra,40(sp)
    8000225e:	7402                	ld	s0,32(sp)
    80002260:	64e2                	ld	s1,24(sp)
    80002262:	6942                	ld	s2,16(sp)
    80002264:	69a2                	ld	s3,8(sp)
    80002266:	6145                	addi	sp,sp,48
    80002268:	8082                	ret

000000008000226a <wait>:
{
    8000226a:	715d                	addi	sp,sp,-80
    8000226c:	e486                	sd	ra,72(sp)
    8000226e:	e0a2                	sd	s0,64(sp)
    80002270:	fc26                	sd	s1,56(sp)
    80002272:	f84a                	sd	s2,48(sp)
    80002274:	f44e                	sd	s3,40(sp)
    80002276:	f052                	sd	s4,32(sp)
    80002278:	ec56                	sd	s5,24(sp)
    8000227a:	e85a                	sd	s6,16(sp)
    8000227c:	e45e                	sd	s7,8(sp)
    8000227e:	e062                	sd	s8,0(sp)
    80002280:	0880                	addi	s0,sp,80
    80002282:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	74a080e7          	jalr	1866(ra) # 800019ce <myproc>
    8000228c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000228e:	0000f517          	auipc	a0,0xf
    80002292:	02a50513          	addi	a0,a0,42 # 800112b8 <wait_lock>
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	94e080e7          	jalr	-1714(ra) # 80000be4 <acquire>
    havekids = 0;
    8000229e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022a2:	00015997          	auipc	s3,0x15
    800022a6:	e2e98993          	addi	s3,s3,-466 # 800170d0 <tickslock>
        havekids = 1;
    800022aa:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022ac:	0000fc17          	auipc	s8,0xf
    800022b0:	00cc0c13          	addi	s8,s8,12 # 800112b8 <wait_lock>
    havekids = 0;
    800022b4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022b6:	0000f497          	auipc	s1,0xf
    800022ba:	41a48493          	addi	s1,s1,1050 # 800116d0 <proc>
    800022be:	a0bd                	j	8000232c <wait+0xc2>
          pid = np->pid;
    800022c0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022c4:	000b0e63          	beqz	s6,800022e0 <wait+0x76>
    800022c8:	4691                	li	a3,4
    800022ca:	02c48613          	addi	a2,s1,44
    800022ce:	85da                	mv	a1,s6
    800022d0:	05093503          	ld	a0,80(s2)
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	3a6080e7          	jalr	934(ra) # 8000167a <copyout>
    800022dc:	02054563          	bltz	a0,80002306 <wait+0x9c>
          freeproc(np);
    800022e0:	8526                	mv	a0,s1
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	89e080e7          	jalr	-1890(ra) # 80001b80 <freeproc>
          release(&np->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	9ac080e7          	jalr	-1620(ra) # 80000c98 <release>
          release(&wait_lock);
    800022f4:	0000f517          	auipc	a0,0xf
    800022f8:	fc450513          	addi	a0,a0,-60 # 800112b8 <wait_lock>
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	99c080e7          	jalr	-1636(ra) # 80000c98 <release>
          return pid;
    80002304:	a09d                	j	8000236a <wait+0x100>
            release(&np->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	990080e7          	jalr	-1648(ra) # 80000c98 <release>
            release(&wait_lock);
    80002310:	0000f517          	auipc	a0,0xf
    80002314:	fa850513          	addi	a0,a0,-88 # 800112b8 <wait_lock>
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	980080e7          	jalr	-1664(ra) # 80000c98 <release>
            return -1;
    80002320:	59fd                	li	s3,-1
    80002322:	a0a1                	j	8000236a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002324:	16848493          	addi	s1,s1,360
    80002328:	03348463          	beq	s1,s3,80002350 <wait+0xe6>
      if(np->parent == p){
    8000232c:	7c9c                	ld	a5,56(s1)
    8000232e:	ff279be3          	bne	a5,s2,80002324 <wait+0xba>
        acquire(&np->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8b0080e7          	jalr	-1872(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000233c:	4c9c                	lw	a5,24(s1)
    8000233e:	f94781e3          	beq	a5,s4,800022c0 <wait+0x56>
        release(&np->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	954080e7          	jalr	-1708(ra) # 80000c98 <release>
        havekids = 1;
    8000234c:	8756                	mv	a4,s5
    8000234e:	bfd9                	j	80002324 <wait+0xba>
    if(!havekids || p->killed){
    80002350:	c701                	beqz	a4,80002358 <wait+0xee>
    80002352:	02892783          	lw	a5,40(s2)
    80002356:	c79d                	beqz	a5,80002384 <wait+0x11a>
      release(&wait_lock);
    80002358:	0000f517          	auipc	a0,0xf
    8000235c:	f6050513          	addi	a0,a0,-160 # 800112b8 <wait_lock>
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
      return -1;
    80002368:	59fd                	li	s3,-1
}
    8000236a:	854e                	mv	a0,s3
    8000236c:	60a6                	ld	ra,72(sp)
    8000236e:	6406                	ld	s0,64(sp)
    80002370:	74e2                	ld	s1,56(sp)
    80002372:	7942                	ld	s2,48(sp)
    80002374:	79a2                	ld	s3,40(sp)
    80002376:	7a02                	ld	s4,32(sp)
    80002378:	6ae2                	ld	s5,24(sp)
    8000237a:	6b42                	ld	s6,16(sp)
    8000237c:	6ba2                	ld	s7,8(sp)
    8000237e:	6c02                	ld	s8,0(sp)
    80002380:	6161                	addi	sp,sp,80
    80002382:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002384:	85e2                	mv	a1,s8
    80002386:	854a                	mv	a0,s2
    80002388:	00000097          	auipc	ra,0x0
    8000238c:	e7e080e7          	jalr	-386(ra) # 80002206 <sleep>
    havekids = 0;
    80002390:	b715                	j	800022b4 <wait+0x4a>

0000000080002392 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002392:	7139                	addi	sp,sp,-64
    80002394:	fc06                	sd	ra,56(sp)
    80002396:	f822                	sd	s0,48(sp)
    80002398:	f426                	sd	s1,40(sp)
    8000239a:	f04a                	sd	s2,32(sp)
    8000239c:	ec4e                	sd	s3,24(sp)
    8000239e:	e852                	sd	s4,16(sp)
    800023a0:	e456                	sd	s5,8(sp)
    800023a2:	e05a                	sd	s6,0(sp)
    800023a4:	0080                	addi	s0,sp,64
    800023a6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023a8:	0000f497          	auipc	s1,0xf
    800023ac:	32848493          	addi	s1,s1,808 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023b0:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023b2:	4b0d                	li	s6,3
    p->last_runnable_time = ticks;
    800023b4:	00007a97          	auipc	s5,0x7
    800023b8:	c84a8a93          	addi	s5,s5,-892 # 80009038 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023bc:	00015917          	auipc	s2,0x15
    800023c0:	d1490913          	addi	s2,s2,-748 # 800170d0 <tickslock>
    800023c4:	a811                	j	800023d8 <wakeup+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d0:	16848493          	addi	s1,s1,360
    800023d4:	03248963          	beq	s1,s2,80002406 <wakeup+0x74>
    if(p != myproc()){
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	5f6080e7          	jalr	1526(ra) # 800019ce <myproc>
    800023e0:	fea488e3          	beq	s1,a0,800023d0 <wakeup+0x3e>
      acquire(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023ee:	4c9c                	lw	a5,24(s1)
    800023f0:	fd379be3          	bne	a5,s3,800023c6 <wakeup+0x34>
    800023f4:	709c                	ld	a5,32(s1)
    800023f6:	fd4798e3          	bne	a5,s4,800023c6 <wakeup+0x34>
        p->state = RUNNABLE;
    800023fa:	0164ac23          	sw	s6,24(s1)
    p->last_runnable_time = ticks;
    800023fe:	000aa783          	lw	a5,0(s5)
    80002402:	d8dc                	sw	a5,52(s1)
}  
    80002404:	b7c9                	j	800023c6 <wakeup+0x34>
    }
  }
}
    80002406:	70e2                	ld	ra,56(sp)
    80002408:	7442                	ld	s0,48(sp)
    8000240a:	74a2                	ld	s1,40(sp)
    8000240c:	7902                	ld	s2,32(sp)
    8000240e:	69e2                	ld	s3,24(sp)
    80002410:	6a42                	ld	s4,16(sp)
    80002412:	6aa2                	ld	s5,8(sp)
    80002414:	6b02                	ld	s6,0(sp)
    80002416:	6121                	addi	sp,sp,64
    80002418:	8082                	ret

000000008000241a <reparent>:
{
    8000241a:	7179                	addi	sp,sp,-48
    8000241c:	f406                	sd	ra,40(sp)
    8000241e:	f022                	sd	s0,32(sp)
    80002420:	ec26                	sd	s1,24(sp)
    80002422:	e84a                	sd	s2,16(sp)
    80002424:	e44e                	sd	s3,8(sp)
    80002426:	e052                	sd	s4,0(sp)
    80002428:	1800                	addi	s0,sp,48
    8000242a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242c:	0000f497          	auipc	s1,0xf
    80002430:	2a448493          	addi	s1,s1,676 # 800116d0 <proc>
      pp->parent = initproc;
    80002434:	00007a17          	auipc	s4,0x7
    80002438:	bfca0a13          	addi	s4,s4,-1028 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000243c:	00015997          	auipc	s3,0x15
    80002440:	c9498993          	addi	s3,s3,-876 # 800170d0 <tickslock>
    80002444:	a029                	j	8000244e <reparent+0x34>
    80002446:	16848493          	addi	s1,s1,360
    8000244a:	01348d63          	beq	s1,s3,80002464 <reparent+0x4a>
    if(pp->parent == p){
    8000244e:	7c9c                	ld	a5,56(s1)
    80002450:	ff279be3          	bne	a5,s2,80002446 <reparent+0x2c>
      pp->parent = initproc;
    80002454:	000a3503          	ld	a0,0(s4)
    80002458:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000245a:	00000097          	auipc	ra,0x0
    8000245e:	f38080e7          	jalr	-200(ra) # 80002392 <wakeup>
    80002462:	b7d5                	j	80002446 <reparent+0x2c>
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6a02                	ld	s4,0(sp)
    80002470:	6145                	addi	sp,sp,48
    80002472:	8082                	ret

0000000080002474 <exit>:
{
    80002474:	7179                	addi	sp,sp,-48
    80002476:	f406                	sd	ra,40(sp)
    80002478:	f022                	sd	s0,32(sp)
    8000247a:	ec26                	sd	s1,24(sp)
    8000247c:	e84a                	sd	s2,16(sp)
    8000247e:	e44e                	sd	s3,8(sp)
    80002480:	e052                	sd	s4,0(sp)
    80002482:	1800                	addi	s0,sp,48
    80002484:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	548080e7          	jalr	1352(ra) # 800019ce <myproc>
    8000248e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002490:	00007797          	auipc	a5,0x7
    80002494:	ba07b783          	ld	a5,-1120(a5) # 80009030 <initproc>
    80002498:	0d050493          	addi	s1,a0,208
    8000249c:	15050913          	addi	s2,a0,336
    800024a0:	02a79363          	bne	a5,a0,800024c6 <exit+0x52>
    panic("init exiting");
    800024a4:	00006517          	auipc	a0,0x6
    800024a8:	dd450513          	addi	a0,a0,-556 # 80008278 <digits+0x238>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	092080e7          	jalr	146(ra) # 8000053e <panic>
      fileclose(f);
    800024b4:	00002097          	auipc	ra,0x2
    800024b8:	25a080e7          	jalr	602(ra) # 8000470e <fileclose>
      p->ofile[fd] = 0;
    800024bc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024c0:	04a1                	addi	s1,s1,8
    800024c2:	01248563          	beq	s1,s2,800024cc <exit+0x58>
    if(p->ofile[fd]){
    800024c6:	6088                	ld	a0,0(s1)
    800024c8:	f575                	bnez	a0,800024b4 <exit+0x40>
    800024ca:	bfdd                	j	800024c0 <exit+0x4c>
  begin_op();
    800024cc:	00002097          	auipc	ra,0x2
    800024d0:	d76080e7          	jalr	-650(ra) # 80004242 <begin_op>
  iput(p->cwd);
    800024d4:	1509b503          	ld	a0,336(s3)
    800024d8:	00001097          	auipc	ra,0x1
    800024dc:	552080e7          	jalr	1362(ra) # 80003a2a <iput>
  end_op();
    800024e0:	00002097          	auipc	ra,0x2
    800024e4:	de2080e7          	jalr	-542(ra) # 800042c2 <end_op>
  p->cwd = 0;
    800024e8:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024ec:	0000f497          	auipc	s1,0xf
    800024f0:	dcc48493          	addi	s1,s1,-564 # 800112b8 <wait_lock>
    800024f4:	8526                	mv	a0,s1
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6ee080e7          	jalr	1774(ra) # 80000be4 <acquire>
  reparent(p);
    800024fe:	854e                	mv	a0,s3
    80002500:	00000097          	auipc	ra,0x0
    80002504:	f1a080e7          	jalr	-230(ra) # 8000241a <reparent>
  wakeup(p->parent);
    80002508:	0389b503          	ld	a0,56(s3)
    8000250c:	00000097          	auipc	ra,0x0
    80002510:	e86080e7          	jalr	-378(ra) # 80002392 <wakeup>
  acquire(&p->lock);
    80002514:	854e                	mv	a0,s3
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	6ce080e7          	jalr	1742(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000251e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002522:	4795                	li	a5,5
    80002524:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	76e080e7          	jalr	1902(ra) # 80000c98 <release>
  sched();
    80002532:	00000097          	auipc	ra,0x0
    80002536:	bb8080e7          	jalr	-1096(ra) # 800020ea <sched>
  panic("zombie exit");
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	d4e50513          	addi	a0,a0,-690 # 80008288 <digits+0x248>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	ffc080e7          	jalr	-4(ra) # 8000053e <panic>

000000008000254a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000255a:	0000f497          	auipc	s1,0xf
    8000255e:	17648493          	addi	s1,s1,374 # 800116d0 <proc>
    80002562:	00015997          	auipc	s3,0x15
    80002566:	b6e98993          	addi	s3,s3,-1170 # 800170d0 <tickslock>
    acquire(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002574:	589c                	lw	a5,48(s1)
    80002576:	01278d63          	beq	a5,s2,80002590 <kill+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	71c080e7          	jalr	1820(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002584:	16848493          	addi	s1,s1,360
    80002588:	ff3491e3          	bne	s1,s3,8000256a <kill+0x20>
  }
  return -1;
    8000258c:	557d                	li	a0,-1
    8000258e:	a829                	j	800025a8 <kill+0x5e>
      p->killed = 1;
    80002590:	4785                	li	a5,1
    80002592:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002594:	4c98                	lw	a4,24(s1)
    80002596:	4789                	li	a5,2
    80002598:	00f70f63          	beq	a4,a5,800025b6 <kill+0x6c>
      release(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6fa080e7          	jalr	1786(ra) # 80000c98 <release>
      return 0;
    800025a6:	4501                	li	a0,0
}
    800025a8:	70a2                	ld	ra,40(sp)
    800025aa:	7402                	ld	s0,32(sp)
    800025ac:	64e2                	ld	s1,24(sp)
    800025ae:	6942                	ld	s2,16(sp)
    800025b0:	69a2                	ld	s3,8(sp)
    800025b2:	6145                	addi	sp,sp,48
    800025b4:	8082                	ret
        p->state = RUNNABLE;
    800025b6:	478d                	li	a5,3
    800025b8:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;
    800025ba:	00007797          	auipc	a5,0x7
    800025be:	a7e7a783          	lw	a5,-1410(a5) # 80009038 <ticks>
    800025c2:	d8dc                	sw	a5,52(s1)
}  
    800025c4:	bfe1                	j	8000259c <kill+0x52>

00000000800025c6 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025c6:	7179                	addi	sp,sp,-48
    800025c8:	f406                	sd	ra,40(sp)
    800025ca:	f022                	sd	s0,32(sp)
    800025cc:	ec26                	sd	s1,24(sp)
    800025ce:	e84a                	sd	s2,16(sp)
    800025d0:	e44e                	sd	s3,8(sp)
    800025d2:	e052                	sd	s4,0(sp)
    800025d4:	1800                	addi	s0,sp,48
    800025d6:	84aa                	mv	s1,a0
    800025d8:	892e                	mv	s2,a1
    800025da:	89b2                	mv	s3,a2
    800025dc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	3f0080e7          	jalr	1008(ra) # 800019ce <myproc>
  if(user_dst){
    800025e6:	c08d                	beqz	s1,80002608 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025e8:	86d2                	mv	a3,s4
    800025ea:	864e                	mv	a2,s3
    800025ec:	85ca                	mv	a1,s2
    800025ee:	6928                	ld	a0,80(a0)
    800025f0:	fffff097          	auipc	ra,0xfffff
    800025f4:	08a080e7          	jalr	138(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6a02                	ld	s4,0(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret
    memmove((char *)dst, src, len);
    80002608:	000a061b          	sext.w	a2,s4
    8000260c:	85ce                	mv	a1,s3
    8000260e:	854a                	mv	a0,s2
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	730080e7          	jalr	1840(ra) # 80000d40 <memmove>
    return 0;
    80002618:	8526                	mv	a0,s1
    8000261a:	bff9                	j	800025f8 <either_copyout+0x32>

000000008000261c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000261c:	7179                	addi	sp,sp,-48
    8000261e:	f406                	sd	ra,40(sp)
    80002620:	f022                	sd	s0,32(sp)
    80002622:	ec26                	sd	s1,24(sp)
    80002624:	e84a                	sd	s2,16(sp)
    80002626:	e44e                	sd	s3,8(sp)
    80002628:	e052                	sd	s4,0(sp)
    8000262a:	1800                	addi	s0,sp,48
    8000262c:	892a                	mv	s2,a0
    8000262e:	84ae                	mv	s1,a1
    80002630:	89b2                	mv	s3,a2
    80002632:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002634:	fffff097          	auipc	ra,0xfffff
    80002638:	39a080e7          	jalr	922(ra) # 800019ce <myproc>
  if(user_src){
    8000263c:	c08d                	beqz	s1,8000265e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000263e:	86d2                	mv	a3,s4
    80002640:	864e                	mv	a2,s3
    80002642:	85ca                	mv	a1,s2
    80002644:	6928                	ld	a0,80(a0)
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	0c0080e7          	jalr	192(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000264e:	70a2                	ld	ra,40(sp)
    80002650:	7402                	ld	s0,32(sp)
    80002652:	64e2                	ld	s1,24(sp)
    80002654:	6942                	ld	s2,16(sp)
    80002656:	69a2                	ld	s3,8(sp)
    80002658:	6a02                	ld	s4,0(sp)
    8000265a:	6145                	addi	sp,sp,48
    8000265c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000265e:	000a061b          	sext.w	a2,s4
    80002662:	85ce                	mv	a1,s3
    80002664:	854a                	mv	a0,s2
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	6da080e7          	jalr	1754(ra) # 80000d40 <memmove>
    return 0;
    8000266e:	8526                	mv	a0,s1
    80002670:	bff9                	j	8000264e <either_copyin+0x32>

0000000080002672 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002672:	715d                	addi	sp,sp,-80
    80002674:	e486                	sd	ra,72(sp)
    80002676:	e0a2                	sd	s0,64(sp)
    80002678:	fc26                	sd	s1,56(sp)
    8000267a:	f84a                	sd	s2,48(sp)
    8000267c:	f44e                	sd	s3,40(sp)
    8000267e:	f052                	sd	s4,32(sp)
    80002680:	ec56                	sd	s5,24(sp)
    80002682:	e85a                	sd	s6,16(sp)
    80002684:	e45e                	sd	s7,8(sp)
    80002686:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002688:	00006517          	auipc	a0,0x6
    8000268c:	a4050513          	addi	a0,a0,-1472 # 800080c8 <digits+0x88>
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	ef8080e7          	jalr	-264(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002698:	0000f497          	auipc	s1,0xf
    8000269c:	19048493          	addi	s1,s1,400 # 80011828 <proc+0x158>
    800026a0:	00015917          	auipc	s2,0x15
    800026a4:	b8890913          	addi	s2,s2,-1144 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026aa:	00006997          	auipc	s3,0x6
    800026ae:	bee98993          	addi	s3,s3,-1042 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    800026b2:	00006a97          	auipc	s5,0x6
    800026b6:	beea8a93          	addi	s5,s5,-1042 # 800082a0 <digits+0x260>
    printf("\n");
    800026ba:	00006a17          	auipc	s4,0x6
    800026be:	a0ea0a13          	addi	s4,s4,-1522 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c2:	00006b97          	auipc	s7,0x6
    800026c6:	c16b8b93          	addi	s7,s7,-1002 # 800082d8 <states.1751>
    800026ca:	a00d                	j	800026ec <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026cc:	ed86a583          	lw	a1,-296(a3)
    800026d0:	8556                	mv	a0,s5
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	eb6080e7          	jalr	-330(ra) # 80000588 <printf>
    printf("\n");
    800026da:	8552                	mv	a0,s4
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	eac080e7          	jalr	-340(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e4:	16848493          	addi	s1,s1,360
    800026e8:	03248163          	beq	s1,s2,8000270a <procdump+0x98>
    if(p->state == UNUSED)
    800026ec:	86a6                	mv	a3,s1
    800026ee:	ec04a783          	lw	a5,-320(s1)
    800026f2:	dbed                	beqz	a5,800026e4 <procdump+0x72>
      state = "???";
    800026f4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f6:	fcfb6be3          	bltu	s6,a5,800026cc <procdump+0x5a>
    800026fa:	1782                	slli	a5,a5,0x20
    800026fc:	9381                	srli	a5,a5,0x20
    800026fe:	078e                	slli	a5,a5,0x3
    80002700:	97de                	add	a5,a5,s7
    80002702:	6390                	ld	a2,0(a5)
    80002704:	f661                	bnez	a2,800026cc <procdump+0x5a>
      state = "???";
    80002706:	864e                	mv	a2,s3
    80002708:	b7d1                	j	800026cc <procdump+0x5a>
  }
}
    8000270a:	60a6                	ld	ra,72(sp)
    8000270c:	6406                	ld	s0,64(sp)
    8000270e:	74e2                	ld	s1,56(sp)
    80002710:	7942                	ld	s2,48(sp)
    80002712:	79a2                	ld	s3,40(sp)
    80002714:	7a02                	ld	s4,32(sp)
    80002716:	6ae2                	ld	s5,24(sp)
    80002718:	6b42                	ld	s6,16(sp)
    8000271a:	6ba2                	ld	s7,8(sp)
    8000271c:	6161                	addi	sp,sp,80
    8000271e:	8082                	ret

0000000080002720 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    80002720:	1141                	addi	sp,sp,-16
    80002722:	e406                	sd	ra,8(sp)
    80002724:	e022                	sd	s0,0(sp)
    80002726:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    80002728:	0025179b          	slliw	a5,a0,0x2
    8000272c:	9fa9                	addw	a5,a5,a0
    8000272e:	0017979b          	slliw	a5,a5,0x1
    80002732:	00007517          	auipc	a0,0x7
    80002736:	90652503          	lw	a0,-1786(a0) # 80009038 <ticks>
    8000273a:	9fa9                	addw	a5,a5,a0
    8000273c:	00007717          	auipc	a4,0x7
    80002740:	8ef72623          	sw	a5,-1812(a4) # 80009028 <pause_ticks>
  yield();
    80002744:	00000097          	auipc	ra,0x0
    80002748:	a7c080e7          	jalr	-1412(ra) # 800021c0 <yield>

  return 0;
}
    8000274c:	4501                	li	a0,0
    8000274e:	60a2                	ld	ra,8(sp)
    80002750:	6402                	ld	s0,0(sp)
    80002752:	0141                	addi	sp,sp,16
    80002754:	8082                	ret

0000000080002756 <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    80002756:	7179                	addi	sp,sp,-48
    80002758:	f406                	sd	ra,40(sp)
    8000275a:	f022                	sd	s0,32(sp)
    8000275c:	ec26                	sd	s1,24(sp)
    8000275e:	e84a                	sd	s2,16(sp)
    80002760:	e44e                	sd	s3,8(sp)
    80002762:	e052                	sd	s4,0(sp)
    80002764:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002766:	0000f497          	auipc	s1,0xf
    8000276a:	f6a48493          	addi	s1,s1,-150 # 800116d0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    8000276e:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80002770:	00015997          	auipc	s3,0x15
    80002774:	96098993          	addi	s3,s3,-1696 # 800170d0 <tickslock>
    80002778:	a029                	j	80002782 <kill_system+0x2c>
    8000277a:	16848493          	addi	s1,s1,360
    8000277e:	03348863          	beq	s1,s3,800027ae <kill_system+0x58>
      acquire(&p->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	460080e7          	jalr	1120(ra) # 80000be4 <acquire>
      pid = p->pid;
    8000278c:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	506080e7          	jalr	1286(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    8000279a:	fff9079b          	addiw	a5,s2,-1
    8000279e:	fcfa7ee3          	bgeu	s4,a5,8000277a <kill_system+0x24>
        kill(pid);
    800027a2:	854a                	mv	a0,s2
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	da6080e7          	jalr	-602(ra) # 8000254a <kill>
    800027ac:	b7f9                	j	8000277a <kill_system+0x24>
  }
  return 0;
}
    800027ae:	4501                	li	a0,0
    800027b0:	70a2                	ld	ra,40(sp)
    800027b2:	7402                	ld	s0,32(sp)
    800027b4:	64e2                	ld	s1,24(sp)
    800027b6:	6942                	ld	s2,16(sp)
    800027b8:	69a2                	ld	s3,8(sp)
    800027ba:	6a02                	ld	s4,0(sp)
    800027bc:	6145                	addi	sp,sp,48
    800027be:	8082                	ret

00000000800027c0 <swtch>:
    800027c0:	00153023          	sd	ra,0(a0)
    800027c4:	00253423          	sd	sp,8(a0)
    800027c8:	e900                	sd	s0,16(a0)
    800027ca:	ed04                	sd	s1,24(a0)
    800027cc:	03253023          	sd	s2,32(a0)
    800027d0:	03353423          	sd	s3,40(a0)
    800027d4:	03453823          	sd	s4,48(a0)
    800027d8:	03553c23          	sd	s5,56(a0)
    800027dc:	05653023          	sd	s6,64(a0)
    800027e0:	05753423          	sd	s7,72(a0)
    800027e4:	05853823          	sd	s8,80(a0)
    800027e8:	05953c23          	sd	s9,88(a0)
    800027ec:	07a53023          	sd	s10,96(a0)
    800027f0:	07b53423          	sd	s11,104(a0)
    800027f4:	0005b083          	ld	ra,0(a1)
    800027f8:	0085b103          	ld	sp,8(a1)
    800027fc:	6980                	ld	s0,16(a1)
    800027fe:	6d84                	ld	s1,24(a1)
    80002800:	0205b903          	ld	s2,32(a1)
    80002804:	0285b983          	ld	s3,40(a1)
    80002808:	0305ba03          	ld	s4,48(a1)
    8000280c:	0385ba83          	ld	s5,56(a1)
    80002810:	0405bb03          	ld	s6,64(a1)
    80002814:	0485bb83          	ld	s7,72(a1)
    80002818:	0505bc03          	ld	s8,80(a1)
    8000281c:	0585bc83          	ld	s9,88(a1)
    80002820:	0605bd03          	ld	s10,96(a1)
    80002824:	0685bd83          	ld	s11,104(a1)
    80002828:	8082                	ret

000000008000282a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000282a:	1141                	addi	sp,sp,-16
    8000282c:	e406                	sd	ra,8(sp)
    8000282e:	e022                	sd	s0,0(sp)
    80002830:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002832:	00006597          	auipc	a1,0x6
    80002836:	ad658593          	addi	a1,a1,-1322 # 80008308 <states.1751+0x30>
    8000283a:	00015517          	auipc	a0,0x15
    8000283e:	89650513          	addi	a0,a0,-1898 # 800170d0 <tickslock>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	312080e7          	jalr	786(ra) # 80000b54 <initlock>
}
    8000284a:	60a2                	ld	ra,8(sp)
    8000284c:	6402                	ld	s0,0(sp)
    8000284e:	0141                	addi	sp,sp,16
    80002850:	8082                	ret

0000000080002852 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002852:	1141                	addi	sp,sp,-16
    80002854:	e422                	sd	s0,8(sp)
    80002856:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002858:	00003797          	auipc	a5,0x3
    8000285c:	4d878793          	addi	a5,a5,1240 # 80005d30 <kernelvec>
    80002860:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002864:	6422                	ld	s0,8(sp)
    80002866:	0141                	addi	sp,sp,16
    80002868:	8082                	ret

000000008000286a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000286a:	1141                	addi	sp,sp,-16
    8000286c:	e406                	sd	ra,8(sp)
    8000286e:	e022                	sd	s0,0(sp)
    80002870:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	15c080e7          	jalr	348(ra) # 800019ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000287e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002880:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002884:	00004617          	auipc	a2,0x4
    80002888:	77c60613          	addi	a2,a2,1916 # 80007000 <_trampoline>
    8000288c:	00004697          	auipc	a3,0x4
    80002890:	77468693          	addi	a3,a3,1908 # 80007000 <_trampoline>
    80002894:	8e91                	sub	a3,a3,a2
    80002896:	040007b7          	lui	a5,0x4000
    8000289a:	17fd                	addi	a5,a5,-1
    8000289c:	07b2                	slli	a5,a5,0xc
    8000289e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028a6:	180026f3          	csrr	a3,satp
    800028aa:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028ac:	6d38                	ld	a4,88(a0)
    800028ae:	6134                	ld	a3,64(a0)
    800028b0:	6585                	lui	a1,0x1
    800028b2:	96ae                	add	a3,a3,a1
    800028b4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028b6:	6d38                	ld	a4,88(a0)
    800028b8:	00000697          	auipc	a3,0x0
    800028bc:	13868693          	addi	a3,a3,312 # 800029f0 <usertrap>
    800028c0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028c2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028c4:	8692                	mv	a3,tp
    800028c6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028cc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028d0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028d8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028da:	6f18                	ld	a4,24(a4)
    800028dc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028e0:	692c                	ld	a1,80(a0)
    800028e2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028e4:	00004717          	auipc	a4,0x4
    800028e8:	7ac70713          	addi	a4,a4,1964 # 80007090 <userret>
    800028ec:	8f11                	sub	a4,a4,a2
    800028ee:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028f0:	577d                	li	a4,-1
    800028f2:	177e                	slli	a4,a4,0x3f
    800028f4:	8dd9                	or	a1,a1,a4
    800028f6:	02000537          	lui	a0,0x2000
    800028fa:	157d                	addi	a0,a0,-1
    800028fc:	0536                	slli	a0,a0,0xd
    800028fe:	9782                	jalr	a5
}
    80002900:	60a2                	ld	ra,8(sp)
    80002902:	6402                	ld	s0,0(sp)
    80002904:	0141                	addi	sp,sp,16
    80002906:	8082                	ret

0000000080002908 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002908:	1101                	addi	sp,sp,-32
    8000290a:	ec06                	sd	ra,24(sp)
    8000290c:	e822                	sd	s0,16(sp)
    8000290e:	e426                	sd	s1,8(sp)
    80002910:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002912:	00014497          	auipc	s1,0x14
    80002916:	7be48493          	addi	s1,s1,1982 # 800170d0 <tickslock>
    8000291a:	8526                	mv	a0,s1
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	2c8080e7          	jalr	712(ra) # 80000be4 <acquire>
  ticks++;
    80002924:	00006517          	auipc	a0,0x6
    80002928:	71450513          	addi	a0,a0,1812 # 80009038 <ticks>
    8000292c:	411c                	lw	a5,0(a0)
    8000292e:	2785                	addiw	a5,a5,1
    80002930:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002932:	00000097          	auipc	ra,0x0
    80002936:	a60080e7          	jalr	-1440(ra) # 80002392 <wakeup>
  release(&tickslock);
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
}
    80002944:	60e2                	ld	ra,24(sp)
    80002946:	6442                	ld	s0,16(sp)
    80002948:	64a2                	ld	s1,8(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret

000000008000294e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000294e:	1101                	addi	sp,sp,-32
    80002950:	ec06                	sd	ra,24(sp)
    80002952:	e822                	sd	s0,16(sp)
    80002954:	e426                	sd	s1,8(sp)
    80002956:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002958:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000295c:	00074d63          	bltz	a4,80002976 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002960:	57fd                	li	a5,-1
    80002962:	17fe                	slli	a5,a5,0x3f
    80002964:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002966:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002968:	06f70363          	beq	a4,a5,800029ce <devintr+0x80>
  }
}
    8000296c:	60e2                	ld	ra,24(sp)
    8000296e:	6442                	ld	s0,16(sp)
    80002970:	64a2                	ld	s1,8(sp)
    80002972:	6105                	addi	sp,sp,32
    80002974:	8082                	ret
     (scause & 0xff) == 9){
    80002976:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000297a:	46a5                	li	a3,9
    8000297c:	fed792e3          	bne	a5,a3,80002960 <devintr+0x12>
    int irq = plic_claim();
    80002980:	00003097          	auipc	ra,0x3
    80002984:	4b8080e7          	jalr	1208(ra) # 80005e38 <plic_claim>
    80002988:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000298a:	47a9                	li	a5,10
    8000298c:	02f50763          	beq	a0,a5,800029ba <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002990:	4785                	li	a5,1
    80002992:	02f50963          	beq	a0,a5,800029c4 <devintr+0x76>
    return 1;
    80002996:	4505                	li	a0,1
    } else if(irq){
    80002998:	d8f1                	beqz	s1,8000296c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000299a:	85a6                	mv	a1,s1
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	97450513          	addi	a0,a0,-1676 # 80008310 <states.1751+0x38>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	be4080e7          	jalr	-1052(ra) # 80000588 <printf>
      plic_complete(irq);
    800029ac:	8526                	mv	a0,s1
    800029ae:	00003097          	auipc	ra,0x3
    800029b2:	4ae080e7          	jalr	1198(ra) # 80005e5c <plic_complete>
    return 1;
    800029b6:	4505                	li	a0,1
    800029b8:	bf55                	j	8000296c <devintr+0x1e>
      uartintr();
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	fee080e7          	jalr	-18(ra) # 800009a8 <uartintr>
    800029c2:	b7ed                	j	800029ac <devintr+0x5e>
      virtio_disk_intr();
    800029c4:	00004097          	auipc	ra,0x4
    800029c8:	978080e7          	jalr	-1672(ra) # 8000633c <virtio_disk_intr>
    800029cc:	b7c5                	j	800029ac <devintr+0x5e>
    if(cpuid() == 0){
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	fd4080e7          	jalr	-44(ra) # 800019a2 <cpuid>
    800029d6:	c901                	beqz	a0,800029e6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029d8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029dc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029de:	14479073          	csrw	sip,a5
    return 2;
    800029e2:	4509                	li	a0,2
    800029e4:	b761                	j	8000296c <devintr+0x1e>
      clockintr();
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	f22080e7          	jalr	-222(ra) # 80002908 <clockintr>
    800029ee:	b7ed                	j	800029d8 <devintr+0x8a>

00000000800029f0 <usertrap>:
{
    800029f0:	1101                	addi	sp,sp,-32
    800029f2:	ec06                	sd	ra,24(sp)
    800029f4:	e822                	sd	s0,16(sp)
    800029f6:	e426                	sd	s1,8(sp)
    800029f8:	e04a                	sd	s2,0(sp)
    800029fa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a00:	1007f793          	andi	a5,a5,256
    80002a04:	e3ad                	bnez	a5,80002a66 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a06:	00003797          	auipc	a5,0x3
    80002a0a:	32a78793          	addi	a5,a5,810 # 80005d30 <kernelvec>
    80002a0e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	fbc080e7          	jalr	-68(ra) # 800019ce <myproc>
    80002a1a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a1c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	14102773          	csrr	a4,sepc
    80002a22:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a28:	47a1                	li	a5,8
    80002a2a:	04f71c63          	bne	a4,a5,80002a82 <usertrap+0x92>
    if(p->killed)
    80002a2e:	551c                	lw	a5,40(a0)
    80002a30:	e3b9                	bnez	a5,80002a76 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a32:	6cb8                	ld	a4,88(s1)
    80002a34:	6f1c                	ld	a5,24(a4)
    80002a36:	0791                	addi	a5,a5,4
    80002a38:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a42:	10079073          	csrw	sstatus,a5
    syscall();
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	2e0080e7          	jalr	736(ra) # 80002d26 <syscall>
  if(p->killed)
    80002a4e:	549c                	lw	a5,40(s1)
    80002a50:	ebc1                	bnez	a5,80002ae0 <usertrap+0xf0>
  usertrapret();
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	e18080e7          	jalr	-488(ra) # 8000286a <usertrapret>
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6902                	ld	s2,0(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret
    panic("usertrap: not from user mode");
    80002a66:	00006517          	auipc	a0,0x6
    80002a6a:	8ca50513          	addi	a0,a0,-1846 # 80008330 <states.1751+0x58>
    80002a6e:	ffffe097          	auipc	ra,0xffffe
    80002a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
      exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	9fc080e7          	jalr	-1540(ra) # 80002474 <exit>
    80002a80:	bf4d                	j	80002a32 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	ecc080e7          	jalr	-308(ra) # 8000294e <devintr>
    80002a8a:	892a                	mv	s2,a0
    80002a8c:	c501                	beqz	a0,80002a94 <usertrap+0xa4>
  if(p->killed)
    80002a8e:	549c                	lw	a5,40(s1)
    80002a90:	c3a1                	beqz	a5,80002ad0 <usertrap+0xe0>
    80002a92:	a815                	j	80002ac6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a98:	5890                	lw	a2,48(s1)
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8b650513          	addi	a0,a0,-1866 # 80008350 <states.1751+0x78>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	ae6080e7          	jalr	-1306(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aaa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aae:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	8ce50513          	addi	a0,a0,-1842 # 80008380 <states.1751+0xa8>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ace080e7          	jalr	-1330(ra) # 80000588 <printf>
    p->killed = 1;
    80002ac2:	4785                	li	a5,1
    80002ac4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ac6:	557d                	li	a0,-1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	9ac080e7          	jalr	-1620(ra) # 80002474 <exit>
  if(which_dev == 2)
    80002ad0:	4789                	li	a5,2
    80002ad2:	f8f910e3          	bne	s2,a5,80002a52 <usertrap+0x62>
    yield();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	6ea080e7          	jalr	1770(ra) # 800021c0 <yield>
    80002ade:	bf95                	j	80002a52 <usertrap+0x62>
  int which_dev = 0;
    80002ae0:	4901                	li	s2,0
    80002ae2:	b7d5                	j	80002ac6 <usertrap+0xd6>

0000000080002ae4 <kerneltrap>:
{
    80002ae4:	7179                	addi	sp,sp,-48
    80002ae6:	f406                	sd	ra,40(sp)
    80002ae8:	f022                	sd	s0,32(sp)
    80002aea:	ec26                	sd	s1,24(sp)
    80002aec:	e84a                	sd	s2,16(sp)
    80002aee:	e44e                	sd	s3,8(sp)
    80002af0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002afe:	1004f793          	andi	a5,s1,256
    80002b02:	cb85                	beqz	a5,80002b32 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b04:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b08:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b0a:	ef85                	bnez	a5,80002b42 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	e42080e7          	jalr	-446(ra) # 8000294e <devintr>
    80002b14:	cd1d                	beqz	a0,80002b52 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b16:	4789                	li	a5,2
    80002b18:	06f50a63          	beq	a0,a5,80002b8c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b1c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b20:	10049073          	csrw	sstatus,s1
}
    80002b24:	70a2                	ld	ra,40(sp)
    80002b26:	7402                	ld	s0,32(sp)
    80002b28:	64e2                	ld	s1,24(sp)
    80002b2a:	6942                	ld	s2,16(sp)
    80002b2c:	69a2                	ld	s3,8(sp)
    80002b2e:	6145                	addi	sp,sp,48
    80002b30:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b32:	00006517          	auipc	a0,0x6
    80002b36:	86e50513          	addi	a0,a0,-1938 # 800083a0 <states.1751+0xc8>
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	a04080e7          	jalr	-1532(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b42:	00006517          	auipc	a0,0x6
    80002b46:	88650513          	addi	a0,a0,-1914 # 800083c8 <states.1751+0xf0>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	9f4080e7          	jalr	-1548(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b52:	85ce                	mv	a1,s3
    80002b54:	00006517          	auipc	a0,0x6
    80002b58:	89450513          	addi	a0,a0,-1900 # 800083e8 <states.1751+0x110>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	a2c080e7          	jalr	-1492(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b64:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b68:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b6c:	00006517          	auipc	a0,0x6
    80002b70:	88c50513          	addi	a0,a0,-1908 # 800083f8 <states.1751+0x120>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	a14080e7          	jalr	-1516(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	89450513          	addi	a0,a0,-1900 # 80008410 <states.1751+0x138>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	9ba080e7          	jalr	-1606(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e42080e7          	jalr	-446(ra) # 800019ce <myproc>
    80002b94:	d541                	beqz	a0,80002b1c <kerneltrap+0x38>
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	e38080e7          	jalr	-456(ra) # 800019ce <myproc>
    80002b9e:	4d18                	lw	a4,24(a0)
    80002ba0:	4791                	li	a5,4
    80002ba2:	f6f71de3          	bne	a4,a5,80002b1c <kerneltrap+0x38>
    yield();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	61a080e7          	jalr	1562(ra) # 800021c0 <yield>
    80002bae:	b7bd                	j	80002b1c <kerneltrap+0x38>

0000000080002bb0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	e12080e7          	jalr	-494(ra) # 800019ce <myproc>
  switch (n) {
    80002bc4:	4795                	li	a5,5
    80002bc6:	0497e163          	bltu	a5,s1,80002c08 <argraw+0x58>
    80002bca:	048a                	slli	s1,s1,0x2
    80002bcc:	00006717          	auipc	a4,0x6
    80002bd0:	87c70713          	addi	a4,a4,-1924 # 80008448 <states.1751+0x170>
    80002bd4:	94ba                	add	s1,s1,a4
    80002bd6:	409c                	lw	a5,0(s1)
    80002bd8:	97ba                	add	a5,a5,a4
    80002bda:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bdc:	6d3c                	ld	a5,88(a0)
    80002bde:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be0:	60e2                	ld	ra,24(sp)
    80002be2:	6442                	ld	s0,16(sp)
    80002be4:	64a2                	ld	s1,8(sp)
    80002be6:	6105                	addi	sp,sp,32
    80002be8:	8082                	ret
    return p->trapframe->a1;
    80002bea:	6d3c                	ld	a5,88(a0)
    80002bec:	7fa8                	ld	a0,120(a5)
    80002bee:	bfcd                	j	80002be0 <argraw+0x30>
    return p->trapframe->a2;
    80002bf0:	6d3c                	ld	a5,88(a0)
    80002bf2:	63c8                	ld	a0,128(a5)
    80002bf4:	b7f5                	j	80002be0 <argraw+0x30>
    return p->trapframe->a3;
    80002bf6:	6d3c                	ld	a5,88(a0)
    80002bf8:	67c8                	ld	a0,136(a5)
    80002bfa:	b7dd                	j	80002be0 <argraw+0x30>
    return p->trapframe->a4;
    80002bfc:	6d3c                	ld	a5,88(a0)
    80002bfe:	6bc8                	ld	a0,144(a5)
    80002c00:	b7c5                	j	80002be0 <argraw+0x30>
    return p->trapframe->a5;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	6fc8                	ld	a0,152(a5)
    80002c06:	bfe9                	j	80002be0 <argraw+0x30>
  panic("argraw");
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	81850513          	addi	a0,a0,-2024 # 80008420 <states.1751+0x148>
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	92e080e7          	jalr	-1746(ra) # 8000053e <panic>

0000000080002c18 <fetchaddr>:
{
    80002c18:	1101                	addi	sp,sp,-32
    80002c1a:	ec06                	sd	ra,24(sp)
    80002c1c:	e822                	sd	s0,16(sp)
    80002c1e:	e426                	sd	s1,8(sp)
    80002c20:	e04a                	sd	s2,0(sp)
    80002c22:	1000                	addi	s0,sp,32
    80002c24:	84aa                	mv	s1,a0
    80002c26:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	da6080e7          	jalr	-602(ra) # 800019ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c30:	653c                	ld	a5,72(a0)
    80002c32:	02f4f863          	bgeu	s1,a5,80002c62 <fetchaddr+0x4a>
    80002c36:	00848713          	addi	a4,s1,8
    80002c3a:	02e7e663          	bltu	a5,a4,80002c66 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c3e:	46a1                	li	a3,8
    80002c40:	8626                	mv	a2,s1
    80002c42:	85ca                	mv	a1,s2
    80002c44:	6928                	ld	a0,80(a0)
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	ac0080e7          	jalr	-1344(ra) # 80001706 <copyin>
    80002c4e:	00a03533          	snez	a0,a0
    80002c52:	40a00533          	neg	a0,a0
}
    80002c56:	60e2                	ld	ra,24(sp)
    80002c58:	6442                	ld	s0,16(sp)
    80002c5a:	64a2                	ld	s1,8(sp)
    80002c5c:	6902                	ld	s2,0(sp)
    80002c5e:	6105                	addi	sp,sp,32
    80002c60:	8082                	ret
    return -1;
    80002c62:	557d                	li	a0,-1
    80002c64:	bfcd                	j	80002c56 <fetchaddr+0x3e>
    80002c66:	557d                	li	a0,-1
    80002c68:	b7fd                	j	80002c56 <fetchaddr+0x3e>

0000000080002c6a <fetchstr>:
{
    80002c6a:	7179                	addi	sp,sp,-48
    80002c6c:	f406                	sd	ra,40(sp)
    80002c6e:	f022                	sd	s0,32(sp)
    80002c70:	ec26                	sd	s1,24(sp)
    80002c72:	e84a                	sd	s2,16(sp)
    80002c74:	e44e                	sd	s3,8(sp)
    80002c76:	1800                	addi	s0,sp,48
    80002c78:	892a                	mv	s2,a0
    80002c7a:	84ae                	mv	s1,a1
    80002c7c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	d50080e7          	jalr	-688(ra) # 800019ce <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c86:	86ce                	mv	a3,s3
    80002c88:	864a                	mv	a2,s2
    80002c8a:	85a6                	mv	a1,s1
    80002c8c:	6928                	ld	a0,80(a0)
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	b04080e7          	jalr	-1276(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002c96:	00054763          	bltz	a0,80002ca4 <fetchstr+0x3a>
  return strlen(buf);
    80002c9a:	8526                	mv	a0,s1
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	1c8080e7          	jalr	456(ra) # 80000e64 <strlen>
}
    80002ca4:	70a2                	ld	ra,40(sp)
    80002ca6:	7402                	ld	s0,32(sp)
    80002ca8:	64e2                	ld	s1,24(sp)
    80002caa:	6942                	ld	s2,16(sp)
    80002cac:	69a2                	ld	s3,8(sp)
    80002cae:	6145                	addi	sp,sp,48
    80002cb0:	8082                	ret

0000000080002cb2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb2:	1101                	addi	sp,sp,-32
    80002cb4:	ec06                	sd	ra,24(sp)
    80002cb6:	e822                	sd	s0,16(sp)
    80002cb8:	e426                	sd	s1,8(sp)
    80002cba:	1000                	addi	s0,sp,32
    80002cbc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	ef2080e7          	jalr	-270(ra) # 80002bb0 <argraw>
    80002cc6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cc8:	4501                	li	a0,0
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret

0000000080002cd4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cd4:	1101                	addi	sp,sp,-32
    80002cd6:	ec06                	sd	ra,24(sp)
    80002cd8:	e822                	sd	s0,16(sp)
    80002cda:	e426                	sd	s1,8(sp)
    80002cdc:	1000                	addi	s0,sp,32
    80002cde:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	ed0080e7          	jalr	-304(ra) # 80002bb0 <argraw>
    80002ce8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cea:	4501                	li	a0,0
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret

0000000080002cf6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	e04a                	sd	s2,0(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84ae                	mv	s1,a1
    80002d04:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	eaa080e7          	jalr	-342(ra) # 80002bb0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d0e:	864a                	mv	a2,s2
    80002d10:	85a6                	mv	a1,s1
    80002d12:	00000097          	auipc	ra,0x0
    80002d16:	f58080e7          	jalr	-168(ra) # 80002c6a <fetchstr>
}
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	64a2                	ld	s1,8(sp)
    80002d20:	6902                	ld	s2,0(sp)
    80002d22:	6105                	addi	sp,sp,32
    80002d24:	8082                	ret

0000000080002d26 <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c9c080e7          	jalr	-868(ra) # 800019ce <myproc>
    80002d3a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d3c:	05853903          	ld	s2,88(a0)
    80002d40:	0a893783          	ld	a5,168(s2)
    80002d44:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d48:	37fd                	addiw	a5,a5,-1
    80002d4a:	4759                	li	a4,22
    80002d4c:	00f76f63          	bltu	a4,a5,80002d6a <syscall+0x44>
    80002d50:	00369713          	slli	a4,a3,0x3
    80002d54:	00005797          	auipc	a5,0x5
    80002d58:	70c78793          	addi	a5,a5,1804 # 80008460 <syscalls>
    80002d5c:	97ba                	add	a5,a5,a4
    80002d5e:	639c                	ld	a5,0(a5)
    80002d60:	c789                	beqz	a5,80002d6a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d62:	9782                	jalr	a5
    80002d64:	06a93823          	sd	a0,112(s2)
    80002d68:	a839                	j	80002d86 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d6a:	15848613          	addi	a2,s1,344
    80002d6e:	588c                	lw	a1,48(s1)
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	6b850513          	addi	a0,a0,1720 # 80008428 <states.1751+0x150>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	810080e7          	jalr	-2032(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d80:	6cbc                	ld	a5,88(s1)
    80002d82:	577d                	li	a4,-1
    80002d84:	fbb8                	sd	a4,112(a5)
  }
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	64a2                	ld	s1,8(sp)
    80002d8c:	6902                	ld	s2,0(sp)
    80002d8e:	6105                	addi	sp,sp,32
    80002d90:	8082                	ret

0000000080002d92 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d9a:	fec40593          	addi	a1,s0,-20
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	f12080e7          	jalr	-238(ra) # 80002cb2 <argint>
    return -1;
    80002da8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002daa:	00054963          	bltz	a0,80002dbc <sys_exit+0x2a>
  exit(n);
    80002dae:	fec42503          	lw	a0,-20(s0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	6c2080e7          	jalr	1730(ra) # 80002474 <exit>
  return 0;  // not reached
    80002dba:	4781                	li	a5,0
}
    80002dbc:	853e                	mv	a0,a5
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dc6:	1141                	addi	sp,sp,-16
    80002dc8:	e406                	sd	ra,8(sp)
    80002dca:	e022                	sd	s0,0(sp)
    80002dcc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	c00080e7          	jalr	-1024(ra) # 800019ce <myproc>
}
    80002dd6:	5908                	lw	a0,48(a0)
    80002dd8:	60a2                	ld	ra,8(sp)
    80002dda:	6402                	ld	s0,0(sp)
    80002ddc:	0141                	addi	sp,sp,16
    80002dde:	8082                	ret

0000000080002de0 <sys_fork>:

uint64
sys_fork(void)
{
    80002de0:	1141                	addi	sp,sp,-16
    80002de2:	e406                	sd	ra,8(sp)
    80002de4:	e022                	sd	s0,0(sp)
    80002de6:	0800                	addi	s0,sp,16
  return fork();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	fbe080e7          	jalr	-66(ra) # 80001da6 <fork>
}
    80002df0:	60a2                	ld	ra,8(sp)
    80002df2:	6402                	ld	s0,0(sp)
    80002df4:	0141                	addi	sp,sp,16
    80002df6:	8082                	ret

0000000080002df8 <sys_wait>:

uint64
sys_wait(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e00:	fe840593          	addi	a1,s0,-24
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	ece080e7          	jalr	-306(ra) # 80002cd4 <argaddr>
    80002e0e:	87aa                	mv	a5,a0
    return -1;
    80002e10:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e12:	0007c863          	bltz	a5,80002e22 <sys_wait+0x2a>
  return wait(p);
    80002e16:	fe843503          	ld	a0,-24(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	450080e7          	jalr	1104(ra) # 8000226a <wait>
}
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	6105                	addi	sp,sp,32
    80002e28:	8082                	ret

0000000080002e2a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e34:	fdc40593          	addi	a1,s0,-36
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	e78080e7          	jalr	-392(ra) # 80002cb2 <argint>
    80002e42:	87aa                	mv	a5,a0
    return -1;
    80002e44:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e46:	0207c063          	bltz	a5,80002e66 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b84080e7          	jalr	-1148(ra) # 800019ce <myproc>
    80002e52:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e54:	fdc42503          	lw	a0,-36(s0)
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	eda080e7          	jalr	-294(ra) # 80001d32 <growproc>
    80002e60:	00054863          	bltz	a0,80002e70 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e64:	8526                	mv	a0,s1
}
    80002e66:	70a2                	ld	ra,40(sp)
    80002e68:	7402                	ld	s0,32(sp)
    80002e6a:	64e2                	ld	s1,24(sp)
    80002e6c:	6145                	addi	sp,sp,48
    80002e6e:	8082                	ret
    return -1;
    80002e70:	557d                	li	a0,-1
    80002e72:	bfd5                	j	80002e66 <sys_sbrk+0x3c>

0000000080002e74 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e74:	7139                	addi	sp,sp,-64
    80002e76:	fc06                	sd	ra,56(sp)
    80002e78:	f822                	sd	s0,48(sp)
    80002e7a:	f426                	sd	s1,40(sp)
    80002e7c:	f04a                	sd	s2,32(sp)
    80002e7e:	ec4e                	sd	s3,24(sp)
    80002e80:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e82:	fcc40593          	addi	a1,s0,-52
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	e2a080e7          	jalr	-470(ra) # 80002cb2 <argint>
    return -1;
    80002e90:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e92:	06054563          	bltz	a0,80002efc <sys_sleep+0x88>
  acquire(&tickslock);
    80002e96:	00014517          	auipc	a0,0x14
    80002e9a:	23a50513          	addi	a0,a0,570 # 800170d0 <tickslock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	d46080e7          	jalr	-698(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002ea6:	00006917          	auipc	s2,0x6
    80002eaa:	19292903          	lw	s2,402(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002eae:	fcc42783          	lw	a5,-52(s0)
    80002eb2:	cf85                	beqz	a5,80002eea <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eb4:	00014997          	auipc	s3,0x14
    80002eb8:	21c98993          	addi	s3,s3,540 # 800170d0 <tickslock>
    80002ebc:	00006497          	auipc	s1,0x6
    80002ec0:	17c48493          	addi	s1,s1,380 # 80009038 <ticks>
    if(myproc()->killed){
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	b0a080e7          	jalr	-1270(ra) # 800019ce <myproc>
    80002ecc:	551c                	lw	a5,40(a0)
    80002ece:	ef9d                	bnez	a5,80002f0c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ed0:	85ce                	mv	a1,s3
    80002ed2:	8526                	mv	a0,s1
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	332080e7          	jalr	818(ra) # 80002206 <sleep>
  while(ticks - ticks0 < n){
    80002edc:	409c                	lw	a5,0(s1)
    80002ede:	412787bb          	subw	a5,a5,s2
    80002ee2:	fcc42703          	lw	a4,-52(s0)
    80002ee6:	fce7efe3          	bltu	a5,a4,80002ec4 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	1e650513          	addi	a0,a0,486 # 800170d0 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
  return 0;
    80002efa:	4781                	li	a5,0
}
    80002efc:	853e                	mv	a0,a5
    80002efe:	70e2                	ld	ra,56(sp)
    80002f00:	7442                	ld	s0,48(sp)
    80002f02:	74a2                	ld	s1,40(sp)
    80002f04:	7902                	ld	s2,32(sp)
    80002f06:	69e2                	ld	s3,24(sp)
    80002f08:	6121                	addi	sp,sp,64
    80002f0a:	8082                	ret
      release(&tickslock);
    80002f0c:	00014517          	auipc	a0,0x14
    80002f10:	1c450513          	addi	a0,a0,452 # 800170d0 <tickslock>
    80002f14:	ffffe097          	auipc	ra,0xffffe
    80002f18:	d84080e7          	jalr	-636(ra) # 80000c98 <release>
      return -1;
    80002f1c:	57fd                	li	a5,-1
    80002f1e:	bff9                	j	80002efc <sys_sleep+0x88>

0000000080002f20 <sys_kill>:

uint64
sys_kill(void)
{
    80002f20:	1101                	addi	sp,sp,-32
    80002f22:	ec06                	sd	ra,24(sp)
    80002f24:	e822                	sd	s0,16(sp)
    80002f26:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f28:	fec40593          	addi	a1,s0,-20
    80002f2c:	4501                	li	a0,0
    80002f2e:	00000097          	auipc	ra,0x0
    80002f32:	d84080e7          	jalr	-636(ra) # 80002cb2 <argint>
    80002f36:	87aa                	mv	a5,a0
    return -1;
    80002f38:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f3a:	0007c863          	bltz	a5,80002f4a <sys_kill+0x2a>
  return kill(pid);
    80002f3e:	fec42503          	lw	a0,-20(s0)
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	608080e7          	jalr	1544(ra) # 8000254a <kill>
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	e426                	sd	s1,8(sp)
    80002f5a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f5c:	00014517          	auipc	a0,0x14
    80002f60:	17450513          	addi	a0,a0,372 # 800170d0 <tickslock>
    80002f64:	ffffe097          	auipc	ra,0xffffe
    80002f68:	c80080e7          	jalr	-896(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f6c:	00006497          	auipc	s1,0x6
    80002f70:	0cc4a483          	lw	s1,204(s1) # 80009038 <ticks>
  release(&tickslock);
    80002f74:	00014517          	auipc	a0,0x14
    80002f78:	15c50513          	addi	a0,a0,348 # 800170d0 <tickslock>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	d1c080e7          	jalr	-740(ra) # 80000c98 <release>
  return xticks;
}
    80002f84:	02049513          	slli	a0,s1,0x20
    80002f88:	9101                	srli	a0,a0,0x20
    80002f8a:	60e2                	ld	ra,24(sp)
    80002f8c:	6442                	ld	s0,16(sp)
    80002f8e:	64a2                	ld	s1,8(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    80002f9c:	fec40593          	addi	a1,s0,-20
    80002fa0:	4501                	li	a0,0
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	d10080e7          	jalr	-752(ra) # 80002cb2 <argint>
    80002faa:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    80002fac:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    80002fae:	0007d663          	bgez	a5,80002fba <sys_pause_system+0x26>
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret
    return pause_system(seconds);
    80002fba:	fec42503          	lw	a0,-20(s0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	762080e7          	jalr	1890(ra) # 80002720 <pause_system>
    80002fc6:	b7f5                	j	80002fb2 <sys_pause_system+0x1e>

0000000080002fc8 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002fc8:	1141                	addi	sp,sp,-16
    80002fca:	e406                	sd	ra,8(sp)
    80002fcc:	e022                	sd	s0,0(sp)
    80002fce:	0800                	addi	s0,sp,16
  return kill_system();
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	786080e7          	jalr	1926(ra) # 80002756 <kill_system>
    80002fd8:	60a2                	ld	ra,8(sp)
    80002fda:	6402                	ld	s0,0(sp)
    80002fdc:	0141                	addi	sp,sp,16
    80002fde:	8082                	ret

0000000080002fe0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fe0:	7179                	addi	sp,sp,-48
    80002fe2:	f406                	sd	ra,40(sp)
    80002fe4:	f022                	sd	s0,32(sp)
    80002fe6:	ec26                	sd	s1,24(sp)
    80002fe8:	e84a                	sd	s2,16(sp)
    80002fea:	e44e                	sd	s3,8(sp)
    80002fec:	e052                	sd	s4,0(sp)
    80002fee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ff0:	00005597          	auipc	a1,0x5
    80002ff4:	53058593          	addi	a1,a1,1328 # 80008520 <syscalls+0xc0>
    80002ff8:	00014517          	auipc	a0,0x14
    80002ffc:	0f050513          	addi	a0,a0,240 # 800170e8 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	b54080e7          	jalr	-1196(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003008:	0001c797          	auipc	a5,0x1c
    8000300c:	0e078793          	addi	a5,a5,224 # 8001f0e8 <bcache+0x8000>
    80003010:	0001c717          	auipc	a4,0x1c
    80003014:	34070713          	addi	a4,a4,832 # 8001f350 <bcache+0x8268>
    80003018:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000301c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003020:	00014497          	auipc	s1,0x14
    80003024:	0e048493          	addi	s1,s1,224 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80003028:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000302a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000302c:	00005a17          	auipc	s4,0x5
    80003030:	4fca0a13          	addi	s4,s4,1276 # 80008528 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003034:	2b893783          	ld	a5,696(s2)
    80003038:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000303a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000303e:	85d2                	mv	a1,s4
    80003040:	01048513          	addi	a0,s1,16
    80003044:	00001097          	auipc	ra,0x1
    80003048:	4bc080e7          	jalr	1212(ra) # 80004500 <initsleeplock>
    bcache.head.next->prev = b;
    8000304c:	2b893783          	ld	a5,696(s2)
    80003050:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003052:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003056:	45848493          	addi	s1,s1,1112
    8000305a:	fd349de3          	bne	s1,s3,80003034 <binit+0x54>
  }
}
    8000305e:	70a2                	ld	ra,40(sp)
    80003060:	7402                	ld	s0,32(sp)
    80003062:	64e2                	ld	s1,24(sp)
    80003064:	6942                	ld	s2,16(sp)
    80003066:	69a2                	ld	s3,8(sp)
    80003068:	6a02                	ld	s4,0(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret

000000008000306e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000306e:	7179                	addi	sp,sp,-48
    80003070:	f406                	sd	ra,40(sp)
    80003072:	f022                	sd	s0,32(sp)
    80003074:	ec26                	sd	s1,24(sp)
    80003076:	e84a                	sd	s2,16(sp)
    80003078:	e44e                	sd	s3,8(sp)
    8000307a:	1800                	addi	s0,sp,48
    8000307c:	89aa                	mv	s3,a0
    8000307e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003080:	00014517          	auipc	a0,0x14
    80003084:	06850513          	addi	a0,a0,104 # 800170e8 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003090:	0001c497          	auipc	s1,0x1c
    80003094:	3104b483          	ld	s1,784(s1) # 8001f3a0 <bcache+0x82b8>
    80003098:	0001c797          	auipc	a5,0x1c
    8000309c:	2b878793          	addi	a5,a5,696 # 8001f350 <bcache+0x8268>
    800030a0:	02f48f63          	beq	s1,a5,800030de <bread+0x70>
    800030a4:	873e                	mv	a4,a5
    800030a6:	a021                	j	800030ae <bread+0x40>
    800030a8:	68a4                	ld	s1,80(s1)
    800030aa:	02e48a63          	beq	s1,a4,800030de <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030ae:	449c                	lw	a5,8(s1)
    800030b0:	ff379ce3          	bne	a5,s3,800030a8 <bread+0x3a>
    800030b4:	44dc                	lw	a5,12(s1)
    800030b6:	ff2799e3          	bne	a5,s2,800030a8 <bread+0x3a>
      b->refcnt++;
    800030ba:	40bc                	lw	a5,64(s1)
    800030bc:	2785                	addiw	a5,a5,1
    800030be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	02850513          	addi	a0,a0,40 # 800170e8 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	bd0080e7          	jalr	-1072(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030d0:	01048513          	addi	a0,s1,16
    800030d4:	00001097          	auipc	ra,0x1
    800030d8:	466080e7          	jalr	1126(ra) # 8000453a <acquiresleep>
      return b;
    800030dc:	a8b9                	j	8000313a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030de:	0001c497          	auipc	s1,0x1c
    800030e2:	2ba4b483          	ld	s1,698(s1) # 8001f398 <bcache+0x82b0>
    800030e6:	0001c797          	auipc	a5,0x1c
    800030ea:	26a78793          	addi	a5,a5,618 # 8001f350 <bcache+0x8268>
    800030ee:	00f48863          	beq	s1,a5,800030fe <bread+0x90>
    800030f2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030f4:	40bc                	lw	a5,64(s1)
    800030f6:	cf81                	beqz	a5,8000310e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f8:	64a4                	ld	s1,72(s1)
    800030fa:	fee49de3          	bne	s1,a4,800030f4 <bread+0x86>
  panic("bget: no buffers");
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	43250513          	addi	a0,a0,1074 # 80008530 <syscalls+0xd0>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
      b->dev = dev;
    8000310e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003112:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003116:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000311a:	4785                	li	a5,1
    8000311c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000311e:	00014517          	auipc	a0,0x14
    80003122:	fca50513          	addi	a0,a0,-54 # 800170e8 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000312e:	01048513          	addi	a0,s1,16
    80003132:	00001097          	auipc	ra,0x1
    80003136:	408080e7          	jalr	1032(ra) # 8000453a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000313a:	409c                	lw	a5,0(s1)
    8000313c:	cb89                	beqz	a5,8000314e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000313e:	8526                	mv	a0,s1
    80003140:	70a2                	ld	ra,40(sp)
    80003142:	7402                	ld	s0,32(sp)
    80003144:	64e2                	ld	s1,24(sp)
    80003146:	6942                	ld	s2,16(sp)
    80003148:	69a2                	ld	s3,8(sp)
    8000314a:	6145                	addi	sp,sp,48
    8000314c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000314e:	4581                	li	a1,0
    80003150:	8526                	mv	a0,s1
    80003152:	00003097          	auipc	ra,0x3
    80003156:	f14080e7          	jalr	-236(ra) # 80006066 <virtio_disk_rw>
    b->valid = 1;
    8000315a:	4785                	li	a5,1
    8000315c:	c09c                	sw	a5,0(s1)
  return b;
    8000315e:	b7c5                	j	8000313e <bread+0xd0>

0000000080003160 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000316c:	0541                	addi	a0,a0,16
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	466080e7          	jalr	1126(ra) # 800045d4 <holdingsleep>
    80003176:	cd01                	beqz	a0,8000318e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003178:	4585                	li	a1,1
    8000317a:	8526                	mv	a0,s1
    8000317c:	00003097          	auipc	ra,0x3
    80003180:	eea080e7          	jalr	-278(ra) # 80006066 <virtio_disk_rw>
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	64a2                	ld	s1,8(sp)
    8000318a:	6105                	addi	sp,sp,32
    8000318c:	8082                	ret
    panic("bwrite");
    8000318e:	00005517          	auipc	a0,0x5
    80003192:	3ba50513          	addi	a0,a0,954 # 80008548 <syscalls+0xe8>
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3a8080e7          	jalr	936(ra) # 8000053e <panic>

000000008000319e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	e04a                	sd	s2,0(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ac:	01050913          	addi	s2,a0,16
    800031b0:	854a                	mv	a0,s2
    800031b2:	00001097          	auipc	ra,0x1
    800031b6:	422080e7          	jalr	1058(ra) # 800045d4 <holdingsleep>
    800031ba:	c92d                	beqz	a0,8000322c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031bc:	854a                	mv	a0,s2
    800031be:	00001097          	auipc	ra,0x1
    800031c2:	3d2080e7          	jalr	978(ra) # 80004590 <releasesleep>

  acquire(&bcache.lock);
    800031c6:	00014517          	auipc	a0,0x14
    800031ca:	f2250513          	addi	a0,a0,-222 # 800170e8 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	a16080e7          	jalr	-1514(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031d6:	40bc                	lw	a5,64(s1)
    800031d8:	37fd                	addiw	a5,a5,-1
    800031da:	0007871b          	sext.w	a4,a5
    800031de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031e0:	eb05                	bnez	a4,80003210 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031e2:	68bc                	ld	a5,80(s1)
    800031e4:	64b8                	ld	a4,72(s1)
    800031e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031e8:	64bc                	ld	a5,72(s1)
    800031ea:	68b8                	ld	a4,80(s1)
    800031ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ee:	0001c797          	auipc	a5,0x1c
    800031f2:	efa78793          	addi	a5,a5,-262 # 8001f0e8 <bcache+0x8000>
    800031f6:	2b87b703          	ld	a4,696(a5)
    800031fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031fc:	0001c717          	auipc	a4,0x1c
    80003200:	15470713          	addi	a4,a4,340 # 8001f350 <bcache+0x8268>
    80003204:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003206:	2b87b703          	ld	a4,696(a5)
    8000320a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000320c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	ed850513          	addi	a0,a0,-296 # 800170e8 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	a80080e7          	jalr	-1408(ra) # 80000c98 <release>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("brelse");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	32450513          	addi	a0,a0,804 # 80008550 <syscalls+0xf0>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	30a080e7          	jalr	778(ra) # 8000053e <panic>

000000008000323c <bpin>:

void
bpin(struct buf *b) {
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	e426                	sd	s1,8(sp)
    80003244:	1000                	addi	s0,sp,32
    80003246:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003248:	00014517          	auipc	a0,0x14
    8000324c:	ea050513          	addi	a0,a0,-352 # 800170e8 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	994080e7          	jalr	-1644(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	2785                	addiw	a5,a5,1
    8000325c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	e8a50513          	addi	a0,a0,-374 # 800170e8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
}
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <bunpin>:

void
bunpin(struct buf *b) {
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	e426                	sd	s1,8(sp)
    80003280:	1000                	addi	s0,sp,32
    80003282:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003284:	00014517          	auipc	a0,0x14
    80003288:	e6450513          	addi	a0,a0,-412 # 800170e8 <bcache>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003294:	40bc                	lw	a5,64(s1)
    80003296:	37fd                	addiw	a5,a5,-1
    80003298:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000329a:	00014517          	auipc	a0,0x14
    8000329e:	e4e50513          	addi	a0,a0,-434 # 800170e8 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret

00000000800032b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	e04a                	sd	s2,0(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032c2:	00d5d59b          	srliw	a1,a1,0xd
    800032c6:	0001c797          	auipc	a5,0x1c
    800032ca:	4fe7a783          	lw	a5,1278(a5) # 8001f7c4 <sb+0x1c>
    800032ce:	9dbd                	addw	a1,a1,a5
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	d9e080e7          	jalr	-610(ra) # 8000306e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032d8:	0074f713          	andi	a4,s1,7
    800032dc:	4785                	li	a5,1
    800032de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032e2:	14ce                	slli	s1,s1,0x33
    800032e4:	90d9                	srli	s1,s1,0x36
    800032e6:	00950733          	add	a4,a0,s1
    800032ea:	05874703          	lbu	a4,88(a4)
    800032ee:	00e7f6b3          	and	a3,a5,a4
    800032f2:	c69d                	beqz	a3,80003320 <bfree+0x6c>
    800032f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032f6:	94aa                	add	s1,s1,a0
    800032f8:	fff7c793          	not	a5,a5
    800032fc:	8ff9                	and	a5,a5,a4
    800032fe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003302:	00001097          	auipc	ra,0x1
    80003306:	118080e7          	jalr	280(ra) # 8000441a <log_write>
  brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	e92080e7          	jalr	-366(ra) # 8000319e <brelse>
}
    80003314:	60e2                	ld	ra,24(sp)
    80003316:	6442                	ld	s0,16(sp)
    80003318:	64a2                	ld	s1,8(sp)
    8000331a:	6902                	ld	s2,0(sp)
    8000331c:	6105                	addi	sp,sp,32
    8000331e:	8082                	ret
    panic("freeing free block");
    80003320:	00005517          	auipc	a0,0x5
    80003324:	23850513          	addi	a0,a0,568 # 80008558 <syscalls+0xf8>
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	216080e7          	jalr	534(ra) # 8000053e <panic>

0000000080003330 <balloc>:
{
    80003330:	711d                	addi	sp,sp,-96
    80003332:	ec86                	sd	ra,88(sp)
    80003334:	e8a2                	sd	s0,80(sp)
    80003336:	e4a6                	sd	s1,72(sp)
    80003338:	e0ca                	sd	s2,64(sp)
    8000333a:	fc4e                	sd	s3,56(sp)
    8000333c:	f852                	sd	s4,48(sp)
    8000333e:	f456                	sd	s5,40(sp)
    80003340:	f05a                	sd	s6,32(sp)
    80003342:	ec5e                	sd	s7,24(sp)
    80003344:	e862                	sd	s8,16(sp)
    80003346:	e466                	sd	s9,8(sp)
    80003348:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000334a:	0001c797          	auipc	a5,0x1c
    8000334e:	4627a783          	lw	a5,1122(a5) # 8001f7ac <sb+0x4>
    80003352:	cbd1                	beqz	a5,800033e6 <balloc+0xb6>
    80003354:	8baa                	mv	s7,a0
    80003356:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003358:	0001cb17          	auipc	s6,0x1c
    8000335c:	450b0b13          	addi	s6,s6,1104 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003360:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003362:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003364:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003366:	6c89                	lui	s9,0x2
    80003368:	a831                	j	80003384 <balloc+0x54>
    brelse(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	e32080e7          	jalr	-462(ra) # 8000319e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003374:	015c87bb          	addw	a5,s9,s5
    80003378:	00078a9b          	sext.w	s5,a5
    8000337c:	004b2703          	lw	a4,4(s6)
    80003380:	06eaf363          	bgeu	s5,a4,800033e6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003384:	41fad79b          	sraiw	a5,s5,0x1f
    80003388:	0137d79b          	srliw	a5,a5,0x13
    8000338c:	015787bb          	addw	a5,a5,s5
    80003390:	40d7d79b          	sraiw	a5,a5,0xd
    80003394:	01cb2583          	lw	a1,28(s6)
    80003398:	9dbd                	addw	a1,a1,a5
    8000339a:	855e                	mv	a0,s7
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	cd2080e7          	jalr	-814(ra) # 8000306e <bread>
    800033a4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033a6:	004b2503          	lw	a0,4(s6)
    800033aa:	000a849b          	sext.w	s1,s5
    800033ae:	8662                	mv	a2,s8
    800033b0:	faa4fde3          	bgeu	s1,a0,8000336a <balloc+0x3a>
      m = 1 << (bi % 8);
    800033b4:	41f6579b          	sraiw	a5,a2,0x1f
    800033b8:	01d7d69b          	srliw	a3,a5,0x1d
    800033bc:	00c6873b          	addw	a4,a3,a2
    800033c0:	00777793          	andi	a5,a4,7
    800033c4:	9f95                	subw	a5,a5,a3
    800033c6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ca:	4037571b          	sraiw	a4,a4,0x3
    800033ce:	00e906b3          	add	a3,s2,a4
    800033d2:	0586c683          	lbu	a3,88(a3)
    800033d6:	00d7f5b3          	and	a1,a5,a3
    800033da:	cd91                	beqz	a1,800033f6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033dc:	2605                	addiw	a2,a2,1
    800033de:	2485                	addiw	s1,s1,1
    800033e0:	fd4618e3          	bne	a2,s4,800033b0 <balloc+0x80>
    800033e4:	b759                	j	8000336a <balloc+0x3a>
  panic("balloc: out of blocks");
    800033e6:	00005517          	auipc	a0,0x5
    800033ea:	18a50513          	addi	a0,a0,394 # 80008570 <syscalls+0x110>
    800033ee:	ffffd097          	auipc	ra,0xffffd
    800033f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033f6:	974a                	add	a4,a4,s2
    800033f8:	8fd5                	or	a5,a5,a3
    800033fa:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033fe:	854a                	mv	a0,s2
    80003400:	00001097          	auipc	ra,0x1
    80003404:	01a080e7          	jalr	26(ra) # 8000441a <log_write>
        brelse(bp);
    80003408:	854a                	mv	a0,s2
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	d94080e7          	jalr	-620(ra) # 8000319e <brelse>
  bp = bread(dev, bno);
    80003412:	85a6                	mv	a1,s1
    80003414:	855e                	mv	a0,s7
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	c58080e7          	jalr	-936(ra) # 8000306e <bread>
    8000341e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003420:	40000613          	li	a2,1024
    80003424:	4581                	li	a1,0
    80003426:	05850513          	addi	a0,a0,88
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	8b6080e7          	jalr	-1866(ra) # 80000ce0 <memset>
  log_write(bp);
    80003432:	854a                	mv	a0,s2
    80003434:	00001097          	auipc	ra,0x1
    80003438:	fe6080e7          	jalr	-26(ra) # 8000441a <log_write>
  brelse(bp);
    8000343c:	854a                	mv	a0,s2
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	d60080e7          	jalr	-672(ra) # 8000319e <brelse>
}
    80003446:	8526                	mv	a0,s1
    80003448:	60e6                	ld	ra,88(sp)
    8000344a:	6446                	ld	s0,80(sp)
    8000344c:	64a6                	ld	s1,72(sp)
    8000344e:	6906                	ld	s2,64(sp)
    80003450:	79e2                	ld	s3,56(sp)
    80003452:	7a42                	ld	s4,48(sp)
    80003454:	7aa2                	ld	s5,40(sp)
    80003456:	7b02                	ld	s6,32(sp)
    80003458:	6be2                	ld	s7,24(sp)
    8000345a:	6c42                	ld	s8,16(sp)
    8000345c:	6ca2                	ld	s9,8(sp)
    8000345e:	6125                	addi	sp,sp,96
    80003460:	8082                	ret

0000000080003462 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	e052                	sd	s4,0(sp)
    80003470:	1800                	addi	s0,sp,48
    80003472:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003474:	47ad                	li	a5,11
    80003476:	04b7fe63          	bgeu	a5,a1,800034d2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000347a:	ff45849b          	addiw	s1,a1,-12
    8000347e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003482:	0ff00793          	li	a5,255
    80003486:	0ae7e363          	bltu	a5,a4,8000352c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000348a:	08052583          	lw	a1,128(a0)
    8000348e:	c5ad                	beqz	a1,800034f8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003490:	00092503          	lw	a0,0(s2)
    80003494:	00000097          	auipc	ra,0x0
    80003498:	bda080e7          	jalr	-1062(ra) # 8000306e <bread>
    8000349c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000349e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034a2:	02049593          	slli	a1,s1,0x20
    800034a6:	9181                	srli	a1,a1,0x20
    800034a8:	058a                	slli	a1,a1,0x2
    800034aa:	00b784b3          	add	s1,a5,a1
    800034ae:	0004a983          	lw	s3,0(s1)
    800034b2:	04098d63          	beqz	s3,8000350c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034b6:	8552                	mv	a0,s4
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	ce6080e7          	jalr	-794(ra) # 8000319e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034c0:	854e                	mv	a0,s3
    800034c2:	70a2                	ld	ra,40(sp)
    800034c4:	7402                	ld	s0,32(sp)
    800034c6:	64e2                	ld	s1,24(sp)
    800034c8:	6942                	ld	s2,16(sp)
    800034ca:	69a2                	ld	s3,8(sp)
    800034cc:	6a02                	ld	s4,0(sp)
    800034ce:	6145                	addi	sp,sp,48
    800034d0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034d2:	02059493          	slli	s1,a1,0x20
    800034d6:	9081                	srli	s1,s1,0x20
    800034d8:	048a                	slli	s1,s1,0x2
    800034da:	94aa                	add	s1,s1,a0
    800034dc:	0504a983          	lw	s3,80(s1)
    800034e0:	fe0990e3          	bnez	s3,800034c0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034e4:	4108                	lw	a0,0(a0)
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	e4a080e7          	jalr	-438(ra) # 80003330 <balloc>
    800034ee:	0005099b          	sext.w	s3,a0
    800034f2:	0534a823          	sw	s3,80(s1)
    800034f6:	b7e9                	j	800034c0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034f8:	4108                	lw	a0,0(a0)
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	e36080e7          	jalr	-458(ra) # 80003330 <balloc>
    80003502:	0005059b          	sext.w	a1,a0
    80003506:	08b92023          	sw	a1,128(s2)
    8000350a:	b759                	j	80003490 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000350c:	00092503          	lw	a0,0(s2)
    80003510:	00000097          	auipc	ra,0x0
    80003514:	e20080e7          	jalr	-480(ra) # 80003330 <balloc>
    80003518:	0005099b          	sext.w	s3,a0
    8000351c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003520:	8552                	mv	a0,s4
    80003522:	00001097          	auipc	ra,0x1
    80003526:	ef8080e7          	jalr	-264(ra) # 8000441a <log_write>
    8000352a:	b771                	j	800034b6 <bmap+0x54>
  panic("bmap: out of range");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	05c50513          	addi	a0,a0,92 # 80008588 <syscalls+0x128>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	00a080e7          	jalr	10(ra) # 8000053e <panic>

000000008000353c <iget>:
{
    8000353c:	7179                	addi	sp,sp,-48
    8000353e:	f406                	sd	ra,40(sp)
    80003540:	f022                	sd	s0,32(sp)
    80003542:	ec26                	sd	s1,24(sp)
    80003544:	e84a                	sd	s2,16(sp)
    80003546:	e44e                	sd	s3,8(sp)
    80003548:	e052                	sd	s4,0(sp)
    8000354a:	1800                	addi	s0,sp,48
    8000354c:	89aa                	mv	s3,a0
    8000354e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003550:	0001c517          	auipc	a0,0x1c
    80003554:	27850513          	addi	a0,a0,632 # 8001f7c8 <itable>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	68c080e7          	jalr	1676(ra) # 80000be4 <acquire>
  empty = 0;
    80003560:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003562:	0001c497          	auipc	s1,0x1c
    80003566:	27e48493          	addi	s1,s1,638 # 8001f7e0 <itable+0x18>
    8000356a:	0001e697          	auipc	a3,0x1e
    8000356e:	d0668693          	addi	a3,a3,-762 # 80021270 <log>
    80003572:	a039                	j	80003580 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003574:	02090b63          	beqz	s2,800035aa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003578:	08848493          	addi	s1,s1,136
    8000357c:	02d48a63          	beq	s1,a3,800035b0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003580:	449c                	lw	a5,8(s1)
    80003582:	fef059e3          	blez	a5,80003574 <iget+0x38>
    80003586:	4098                	lw	a4,0(s1)
    80003588:	ff3716e3          	bne	a4,s3,80003574 <iget+0x38>
    8000358c:	40d8                	lw	a4,4(s1)
    8000358e:	ff4713e3          	bne	a4,s4,80003574 <iget+0x38>
      ip->ref++;
    80003592:	2785                	addiw	a5,a5,1
    80003594:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003596:	0001c517          	auipc	a0,0x1c
    8000359a:	23250513          	addi	a0,a0,562 # 8001f7c8 <itable>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	6fa080e7          	jalr	1786(ra) # 80000c98 <release>
      return ip;
    800035a6:	8926                	mv	s2,s1
    800035a8:	a03d                	j	800035d6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035aa:	f7f9                	bnez	a5,80003578 <iget+0x3c>
    800035ac:	8926                	mv	s2,s1
    800035ae:	b7e9                	j	80003578 <iget+0x3c>
  if(empty == 0)
    800035b0:	02090c63          	beqz	s2,800035e8 <iget+0xac>
  ip->dev = dev;
    800035b4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035b8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035bc:	4785                	li	a5,1
    800035be:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035c2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035c6:	0001c517          	auipc	a0,0x1c
    800035ca:	20250513          	addi	a0,a0,514 # 8001f7c8 <itable>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	6ca080e7          	jalr	1738(ra) # 80000c98 <release>
}
    800035d6:	854a                	mv	a0,s2
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6a02                	ld	s4,0(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
    panic("iget: no inodes");
    800035e8:	00005517          	auipc	a0,0x5
    800035ec:	fb850513          	addi	a0,a0,-72 # 800085a0 <syscalls+0x140>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>

00000000800035f8 <fsinit>:
fsinit(int dev) {
    800035f8:	7179                	addi	sp,sp,-48
    800035fa:	f406                	sd	ra,40(sp)
    800035fc:	f022                	sd	s0,32(sp)
    800035fe:	ec26                	sd	s1,24(sp)
    80003600:	e84a                	sd	s2,16(sp)
    80003602:	e44e                	sd	s3,8(sp)
    80003604:	1800                	addi	s0,sp,48
    80003606:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003608:	4585                	li	a1,1
    8000360a:	00000097          	auipc	ra,0x0
    8000360e:	a64080e7          	jalr	-1436(ra) # 8000306e <bread>
    80003612:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003614:	0001c997          	auipc	s3,0x1c
    80003618:	19498993          	addi	s3,s3,404 # 8001f7a8 <sb>
    8000361c:	02000613          	li	a2,32
    80003620:	05850593          	addi	a1,a0,88
    80003624:	854e                	mv	a0,s3
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	71a080e7          	jalr	1818(ra) # 80000d40 <memmove>
  brelse(bp);
    8000362e:	8526                	mv	a0,s1
    80003630:	00000097          	auipc	ra,0x0
    80003634:	b6e080e7          	jalr	-1170(ra) # 8000319e <brelse>
  if(sb.magic != FSMAGIC)
    80003638:	0009a703          	lw	a4,0(s3)
    8000363c:	102037b7          	lui	a5,0x10203
    80003640:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003644:	02f71263          	bne	a4,a5,80003668 <fsinit+0x70>
  initlog(dev, &sb);
    80003648:	0001c597          	auipc	a1,0x1c
    8000364c:	16058593          	addi	a1,a1,352 # 8001f7a8 <sb>
    80003650:	854a                	mv	a0,s2
    80003652:	00001097          	auipc	ra,0x1
    80003656:	b4c080e7          	jalr	-1204(ra) # 8000419e <initlog>
}
    8000365a:	70a2                	ld	ra,40(sp)
    8000365c:	7402                	ld	s0,32(sp)
    8000365e:	64e2                	ld	s1,24(sp)
    80003660:	6942                	ld	s2,16(sp)
    80003662:	69a2                	ld	s3,8(sp)
    80003664:	6145                	addi	sp,sp,48
    80003666:	8082                	ret
    panic("invalid file system");
    80003668:	00005517          	auipc	a0,0x5
    8000366c:	f4850513          	addi	a0,a0,-184 # 800085b0 <syscalls+0x150>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>

0000000080003678 <iinit>:
{
    80003678:	7179                	addi	sp,sp,-48
    8000367a:	f406                	sd	ra,40(sp)
    8000367c:	f022                	sd	s0,32(sp)
    8000367e:	ec26                	sd	s1,24(sp)
    80003680:	e84a                	sd	s2,16(sp)
    80003682:	e44e                	sd	s3,8(sp)
    80003684:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003686:	00005597          	auipc	a1,0x5
    8000368a:	f4258593          	addi	a1,a1,-190 # 800085c8 <syscalls+0x168>
    8000368e:	0001c517          	auipc	a0,0x1c
    80003692:	13a50513          	addi	a0,a0,314 # 8001f7c8 <itable>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	4be080e7          	jalr	1214(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000369e:	0001c497          	auipc	s1,0x1c
    800036a2:	15248493          	addi	s1,s1,338 # 8001f7f0 <itable+0x28>
    800036a6:	0001e997          	auipc	s3,0x1e
    800036aa:	bda98993          	addi	s3,s3,-1062 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036ae:	00005917          	auipc	s2,0x5
    800036b2:	f2290913          	addi	s2,s2,-222 # 800085d0 <syscalls+0x170>
    800036b6:	85ca                	mv	a1,s2
    800036b8:	8526                	mv	a0,s1
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	e46080e7          	jalr	-442(ra) # 80004500 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036c2:	08848493          	addi	s1,s1,136
    800036c6:	ff3498e3          	bne	s1,s3,800036b6 <iinit+0x3e>
}
    800036ca:	70a2                	ld	ra,40(sp)
    800036cc:	7402                	ld	s0,32(sp)
    800036ce:	64e2                	ld	s1,24(sp)
    800036d0:	6942                	ld	s2,16(sp)
    800036d2:	69a2                	ld	s3,8(sp)
    800036d4:	6145                	addi	sp,sp,48
    800036d6:	8082                	ret

00000000800036d8 <ialloc>:
{
    800036d8:	715d                	addi	sp,sp,-80
    800036da:	e486                	sd	ra,72(sp)
    800036dc:	e0a2                	sd	s0,64(sp)
    800036de:	fc26                	sd	s1,56(sp)
    800036e0:	f84a                	sd	s2,48(sp)
    800036e2:	f44e                	sd	s3,40(sp)
    800036e4:	f052                	sd	s4,32(sp)
    800036e6:	ec56                	sd	s5,24(sp)
    800036e8:	e85a                	sd	s6,16(sp)
    800036ea:	e45e                	sd	s7,8(sp)
    800036ec:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ee:	0001c717          	auipc	a4,0x1c
    800036f2:	0c672703          	lw	a4,198(a4) # 8001f7b4 <sb+0xc>
    800036f6:	4785                	li	a5,1
    800036f8:	04e7fa63          	bgeu	a5,a4,8000374c <ialloc+0x74>
    800036fc:	8aaa                	mv	s5,a0
    800036fe:	8bae                	mv	s7,a1
    80003700:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003702:	0001ca17          	auipc	s4,0x1c
    80003706:	0a6a0a13          	addi	s4,s4,166 # 8001f7a8 <sb>
    8000370a:	00048b1b          	sext.w	s6,s1
    8000370e:	0044d593          	srli	a1,s1,0x4
    80003712:	018a2783          	lw	a5,24(s4)
    80003716:	9dbd                	addw	a1,a1,a5
    80003718:	8556                	mv	a0,s5
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	954080e7          	jalr	-1708(ra) # 8000306e <bread>
    80003722:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003724:	05850993          	addi	s3,a0,88
    80003728:	00f4f793          	andi	a5,s1,15
    8000372c:	079a                	slli	a5,a5,0x6
    8000372e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003730:	00099783          	lh	a5,0(s3)
    80003734:	c785                	beqz	a5,8000375c <ialloc+0x84>
    brelse(bp);
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	a68080e7          	jalr	-1432(ra) # 8000319e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000373e:	0485                	addi	s1,s1,1
    80003740:	00ca2703          	lw	a4,12(s4)
    80003744:	0004879b          	sext.w	a5,s1
    80003748:	fce7e1e3          	bltu	a5,a4,8000370a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	e8c50513          	addi	a0,a0,-372 # 800085d8 <syscalls+0x178>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000375c:	04000613          	li	a2,64
    80003760:	4581                	li	a1,0
    80003762:	854e                	mv	a0,s3
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	57c080e7          	jalr	1404(ra) # 80000ce0 <memset>
      dip->type = type;
    8000376c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003770:	854a                	mv	a0,s2
    80003772:	00001097          	auipc	ra,0x1
    80003776:	ca8080e7          	jalr	-856(ra) # 8000441a <log_write>
      brelse(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	a22080e7          	jalr	-1502(ra) # 8000319e <brelse>
      return iget(dev, inum);
    80003784:	85da                	mv	a1,s6
    80003786:	8556                	mv	a0,s5
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	db4080e7          	jalr	-588(ra) # 8000353c <iget>
}
    80003790:	60a6                	ld	ra,72(sp)
    80003792:	6406                	ld	s0,64(sp)
    80003794:	74e2                	ld	s1,56(sp)
    80003796:	7942                	ld	s2,48(sp)
    80003798:	79a2                	ld	s3,40(sp)
    8000379a:	7a02                	ld	s4,32(sp)
    8000379c:	6ae2                	ld	s5,24(sp)
    8000379e:	6b42                	ld	s6,16(sp)
    800037a0:	6ba2                	ld	s7,8(sp)
    800037a2:	6161                	addi	sp,sp,80
    800037a4:	8082                	ret

00000000800037a6 <iupdate>:
{
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	e04a                	sd	s2,0(sp)
    800037b0:	1000                	addi	s0,sp,32
    800037b2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037b4:	415c                	lw	a5,4(a0)
    800037b6:	0047d79b          	srliw	a5,a5,0x4
    800037ba:	0001c597          	auipc	a1,0x1c
    800037be:	0065a583          	lw	a1,6(a1) # 8001f7c0 <sb+0x18>
    800037c2:	9dbd                	addw	a1,a1,a5
    800037c4:	4108                	lw	a0,0(a0)
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	8a8080e7          	jalr	-1880(ra) # 8000306e <bread>
    800037ce:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d0:	05850793          	addi	a5,a0,88
    800037d4:	40c8                	lw	a0,4(s1)
    800037d6:	893d                	andi	a0,a0,15
    800037d8:	051a                	slli	a0,a0,0x6
    800037da:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037dc:	04449703          	lh	a4,68(s1)
    800037e0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037e4:	04649703          	lh	a4,70(s1)
    800037e8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ec:	04849703          	lh	a4,72(s1)
    800037f0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037f4:	04a49703          	lh	a4,74(s1)
    800037f8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037fc:	44f8                	lw	a4,76(s1)
    800037fe:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003800:	03400613          	li	a2,52
    80003804:	05048593          	addi	a1,s1,80
    80003808:	0531                	addi	a0,a0,12
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	536080e7          	jalr	1334(ra) # 80000d40 <memmove>
  log_write(bp);
    80003812:	854a                	mv	a0,s2
    80003814:	00001097          	auipc	ra,0x1
    80003818:	c06080e7          	jalr	-1018(ra) # 8000441a <log_write>
  brelse(bp);
    8000381c:	854a                	mv	a0,s2
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	980080e7          	jalr	-1664(ra) # 8000319e <brelse>
}
    80003826:	60e2                	ld	ra,24(sp)
    80003828:	6442                	ld	s0,16(sp)
    8000382a:	64a2                	ld	s1,8(sp)
    8000382c:	6902                	ld	s2,0(sp)
    8000382e:	6105                	addi	sp,sp,32
    80003830:	8082                	ret

0000000080003832 <idup>:
{
    80003832:	1101                	addi	sp,sp,-32
    80003834:	ec06                	sd	ra,24(sp)
    80003836:	e822                	sd	s0,16(sp)
    80003838:	e426                	sd	s1,8(sp)
    8000383a:	1000                	addi	s0,sp,32
    8000383c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000383e:	0001c517          	auipc	a0,0x1c
    80003842:	f8a50513          	addi	a0,a0,-118 # 8001f7c8 <itable>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	39e080e7          	jalr	926(ra) # 80000be4 <acquire>
  ip->ref++;
    8000384e:	449c                	lw	a5,8(s1)
    80003850:	2785                	addiw	a5,a5,1
    80003852:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003854:	0001c517          	auipc	a0,0x1c
    80003858:	f7450513          	addi	a0,a0,-140 # 8001f7c8 <itable>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	43c080e7          	jalr	1084(ra) # 80000c98 <release>
}
    80003864:	8526                	mv	a0,s1
    80003866:	60e2                	ld	ra,24(sp)
    80003868:	6442                	ld	s0,16(sp)
    8000386a:	64a2                	ld	s1,8(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret

0000000080003870 <ilock>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000387c:	c115                	beqz	a0,800038a0 <ilock+0x30>
    8000387e:	84aa                	mv	s1,a0
    80003880:	451c                	lw	a5,8(a0)
    80003882:	00f05f63          	blez	a5,800038a0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003886:	0541                	addi	a0,a0,16
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	cb2080e7          	jalr	-846(ra) # 8000453a <acquiresleep>
  if(ip->valid == 0){
    80003890:	40bc                	lw	a5,64(s1)
    80003892:	cf99                	beqz	a5,800038b0 <ilock+0x40>
}
    80003894:	60e2                	ld	ra,24(sp)
    80003896:	6442                	ld	s0,16(sp)
    80003898:	64a2                	ld	s1,8(sp)
    8000389a:	6902                	ld	s2,0(sp)
    8000389c:	6105                	addi	sp,sp,32
    8000389e:	8082                	ret
    panic("ilock");
    800038a0:	00005517          	auipc	a0,0x5
    800038a4:	d5050513          	addi	a0,a0,-688 # 800085f0 <syscalls+0x190>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	c96080e7          	jalr	-874(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038b0:	40dc                	lw	a5,4(s1)
    800038b2:	0047d79b          	srliw	a5,a5,0x4
    800038b6:	0001c597          	auipc	a1,0x1c
    800038ba:	f0a5a583          	lw	a1,-246(a1) # 8001f7c0 <sb+0x18>
    800038be:	9dbd                	addw	a1,a1,a5
    800038c0:	4088                	lw	a0,0(s1)
    800038c2:	fffff097          	auipc	ra,0xfffff
    800038c6:	7ac080e7          	jalr	1964(ra) # 8000306e <bread>
    800038ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038cc:	05850593          	addi	a1,a0,88
    800038d0:	40dc                	lw	a5,4(s1)
    800038d2:	8bbd                	andi	a5,a5,15
    800038d4:	079a                	slli	a5,a5,0x6
    800038d6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038d8:	00059783          	lh	a5,0(a1)
    800038dc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038e0:	00259783          	lh	a5,2(a1)
    800038e4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038e8:	00459783          	lh	a5,4(a1)
    800038ec:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038f0:	00659783          	lh	a5,6(a1)
    800038f4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038f8:	459c                	lw	a5,8(a1)
    800038fa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038fc:	03400613          	li	a2,52
    80003900:	05b1                	addi	a1,a1,12
    80003902:	05048513          	addi	a0,s1,80
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	43a080e7          	jalr	1082(ra) # 80000d40 <memmove>
    brelse(bp);
    8000390e:	854a                	mv	a0,s2
    80003910:	00000097          	auipc	ra,0x0
    80003914:	88e080e7          	jalr	-1906(ra) # 8000319e <brelse>
    ip->valid = 1;
    80003918:	4785                	li	a5,1
    8000391a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000391c:	04449783          	lh	a5,68(s1)
    80003920:	fbb5                	bnez	a5,80003894 <ilock+0x24>
      panic("ilock: no type");
    80003922:	00005517          	auipc	a0,0x5
    80003926:	cd650513          	addi	a0,a0,-810 # 800085f8 <syscalls+0x198>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	c14080e7          	jalr	-1004(ra) # 8000053e <panic>

0000000080003932 <iunlock>:
{
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	e04a                	sd	s2,0(sp)
    8000393c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000393e:	c905                	beqz	a0,8000396e <iunlock+0x3c>
    80003940:	84aa                	mv	s1,a0
    80003942:	01050913          	addi	s2,a0,16
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	c8c080e7          	jalr	-884(ra) # 800045d4 <holdingsleep>
    80003950:	cd19                	beqz	a0,8000396e <iunlock+0x3c>
    80003952:	449c                	lw	a5,8(s1)
    80003954:	00f05d63          	blez	a5,8000396e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003958:	854a                	mv	a0,s2
    8000395a:	00001097          	auipc	ra,0x1
    8000395e:	c36080e7          	jalr	-970(ra) # 80004590 <releasesleep>
}
    80003962:	60e2                	ld	ra,24(sp)
    80003964:	6442                	ld	s0,16(sp)
    80003966:	64a2                	ld	s1,8(sp)
    80003968:	6902                	ld	s2,0(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret
    panic("iunlock");
    8000396e:	00005517          	auipc	a0,0x5
    80003972:	c9a50513          	addi	a0,a0,-870 # 80008608 <syscalls+0x1a8>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	bc8080e7          	jalr	-1080(ra) # 8000053e <panic>

000000008000397e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000397e:	7179                	addi	sp,sp,-48
    80003980:	f406                	sd	ra,40(sp)
    80003982:	f022                	sd	s0,32(sp)
    80003984:	ec26                	sd	s1,24(sp)
    80003986:	e84a                	sd	s2,16(sp)
    80003988:	e44e                	sd	s3,8(sp)
    8000398a:	e052                	sd	s4,0(sp)
    8000398c:	1800                	addi	s0,sp,48
    8000398e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003990:	05050493          	addi	s1,a0,80
    80003994:	08050913          	addi	s2,a0,128
    80003998:	a021                	j	800039a0 <itrunc+0x22>
    8000399a:	0491                	addi	s1,s1,4
    8000399c:	01248d63          	beq	s1,s2,800039b6 <itrunc+0x38>
    if(ip->addrs[i]){
    800039a0:	408c                	lw	a1,0(s1)
    800039a2:	dde5                	beqz	a1,8000399a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039a4:	0009a503          	lw	a0,0(s3)
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	90c080e7          	jalr	-1780(ra) # 800032b4 <bfree>
      ip->addrs[i] = 0;
    800039b0:	0004a023          	sw	zero,0(s1)
    800039b4:	b7dd                	j	8000399a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039b6:	0809a583          	lw	a1,128(s3)
    800039ba:	e185                	bnez	a1,800039da <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039bc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039c0:	854e                	mv	a0,s3
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	de4080e7          	jalr	-540(ra) # 800037a6 <iupdate>
}
    800039ca:	70a2                	ld	ra,40(sp)
    800039cc:	7402                	ld	s0,32(sp)
    800039ce:	64e2                	ld	s1,24(sp)
    800039d0:	6942                	ld	s2,16(sp)
    800039d2:	69a2                	ld	s3,8(sp)
    800039d4:	6a02                	ld	s4,0(sp)
    800039d6:	6145                	addi	sp,sp,48
    800039d8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039da:	0009a503          	lw	a0,0(s3)
    800039de:	fffff097          	auipc	ra,0xfffff
    800039e2:	690080e7          	jalr	1680(ra) # 8000306e <bread>
    800039e6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039e8:	05850493          	addi	s1,a0,88
    800039ec:	45850913          	addi	s2,a0,1112
    800039f0:	a811                	j	80003a04 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039f2:	0009a503          	lw	a0,0(s3)
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	8be080e7          	jalr	-1858(ra) # 800032b4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039fe:	0491                	addi	s1,s1,4
    80003a00:	01248563          	beq	s1,s2,80003a0a <itrunc+0x8c>
      if(a[j])
    80003a04:	408c                	lw	a1,0(s1)
    80003a06:	dde5                	beqz	a1,800039fe <itrunc+0x80>
    80003a08:	b7ed                	j	800039f2 <itrunc+0x74>
    brelse(bp);
    80003a0a:	8552                	mv	a0,s4
    80003a0c:	fffff097          	auipc	ra,0xfffff
    80003a10:	792080e7          	jalr	1938(ra) # 8000319e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a14:	0809a583          	lw	a1,128(s3)
    80003a18:	0009a503          	lw	a0,0(s3)
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	898080e7          	jalr	-1896(ra) # 800032b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a24:	0809a023          	sw	zero,128(s3)
    80003a28:	bf51                	j	800039bc <itrunc+0x3e>

0000000080003a2a <iput>:
{
    80003a2a:	1101                	addi	sp,sp,-32
    80003a2c:	ec06                	sd	ra,24(sp)
    80003a2e:	e822                	sd	s0,16(sp)
    80003a30:	e426                	sd	s1,8(sp)
    80003a32:	e04a                	sd	s2,0(sp)
    80003a34:	1000                	addi	s0,sp,32
    80003a36:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a38:	0001c517          	auipc	a0,0x1c
    80003a3c:	d9050513          	addi	a0,a0,-624 # 8001f7c8 <itable>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a48:	4498                	lw	a4,8(s1)
    80003a4a:	4785                	li	a5,1
    80003a4c:	02f70363          	beq	a4,a5,80003a72 <iput+0x48>
  ip->ref--;
    80003a50:	449c                	lw	a5,8(s1)
    80003a52:	37fd                	addiw	a5,a5,-1
    80003a54:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a56:	0001c517          	auipc	a0,0x1c
    80003a5a:	d7250513          	addi	a0,a0,-654 # 8001f7c8 <itable>
    80003a5e:	ffffd097          	auipc	ra,0xffffd
    80003a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6902                	ld	s2,0(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a72:	40bc                	lw	a5,64(s1)
    80003a74:	dff1                	beqz	a5,80003a50 <iput+0x26>
    80003a76:	04a49783          	lh	a5,74(s1)
    80003a7a:	fbf9                	bnez	a5,80003a50 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a7c:	01048913          	addi	s2,s1,16
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	ab8080e7          	jalr	-1352(ra) # 8000453a <acquiresleep>
    release(&itable.lock);
    80003a8a:	0001c517          	auipc	a0,0x1c
    80003a8e:	d3e50513          	addi	a0,a0,-706 # 8001f7c8 <itable>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	206080e7          	jalr	518(ra) # 80000c98 <release>
    itrunc(ip);
    80003a9a:	8526                	mv	a0,s1
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	ee2080e7          	jalr	-286(ra) # 8000397e <itrunc>
    ip->type = 0;
    80003aa4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003aa8:	8526                	mv	a0,s1
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	cfc080e7          	jalr	-772(ra) # 800037a6 <iupdate>
    ip->valid = 0;
    80003ab2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00001097          	auipc	ra,0x1
    80003abc:	ad8080e7          	jalr	-1320(ra) # 80004590 <releasesleep>
    acquire(&itable.lock);
    80003ac0:	0001c517          	auipc	a0,0x1c
    80003ac4:	d0850513          	addi	a0,a0,-760 # 8001f7c8 <itable>
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
    80003ad0:	b741                	j	80003a50 <iput+0x26>

0000000080003ad2 <iunlockput>:
{
    80003ad2:	1101                	addi	sp,sp,-32
    80003ad4:	ec06                	sd	ra,24(sp)
    80003ad6:	e822                	sd	s0,16(sp)
    80003ad8:	e426                	sd	s1,8(sp)
    80003ada:	1000                	addi	s0,sp,32
    80003adc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	e54080e7          	jalr	-428(ra) # 80003932 <iunlock>
  iput(ip);
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	f42080e7          	jalr	-190(ra) # 80003a2a <iput>
}
    80003af0:	60e2                	ld	ra,24(sp)
    80003af2:	6442                	ld	s0,16(sp)
    80003af4:	64a2                	ld	s1,8(sp)
    80003af6:	6105                	addi	sp,sp,32
    80003af8:	8082                	ret

0000000080003afa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003afa:	1141                	addi	sp,sp,-16
    80003afc:	e422                	sd	s0,8(sp)
    80003afe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b00:	411c                	lw	a5,0(a0)
    80003b02:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b04:	415c                	lw	a5,4(a0)
    80003b06:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b08:	04451783          	lh	a5,68(a0)
    80003b0c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b10:	04a51783          	lh	a5,74(a0)
    80003b14:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b18:	04c56783          	lwu	a5,76(a0)
    80003b1c:	e99c                	sd	a5,16(a1)
}
    80003b1e:	6422                	ld	s0,8(sp)
    80003b20:	0141                	addi	sp,sp,16
    80003b22:	8082                	ret

0000000080003b24 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b24:	457c                	lw	a5,76(a0)
    80003b26:	0ed7e963          	bltu	a5,a3,80003c18 <readi+0xf4>
{
    80003b2a:	7159                	addi	sp,sp,-112
    80003b2c:	f486                	sd	ra,104(sp)
    80003b2e:	f0a2                	sd	s0,96(sp)
    80003b30:	eca6                	sd	s1,88(sp)
    80003b32:	e8ca                	sd	s2,80(sp)
    80003b34:	e4ce                	sd	s3,72(sp)
    80003b36:	e0d2                	sd	s4,64(sp)
    80003b38:	fc56                	sd	s5,56(sp)
    80003b3a:	f85a                	sd	s6,48(sp)
    80003b3c:	f45e                	sd	s7,40(sp)
    80003b3e:	f062                	sd	s8,32(sp)
    80003b40:	ec66                	sd	s9,24(sp)
    80003b42:	e86a                	sd	s10,16(sp)
    80003b44:	e46e                	sd	s11,8(sp)
    80003b46:	1880                	addi	s0,sp,112
    80003b48:	8baa                	mv	s7,a0
    80003b4a:	8c2e                	mv	s8,a1
    80003b4c:	8ab2                	mv	s5,a2
    80003b4e:	84b6                	mv	s1,a3
    80003b50:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b52:	9f35                	addw	a4,a4,a3
    return 0;
    80003b54:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b56:	0ad76063          	bltu	a4,a3,80003bf6 <readi+0xd2>
  if(off + n > ip->size)
    80003b5a:	00e7f463          	bgeu	a5,a4,80003b62 <readi+0x3e>
    n = ip->size - off;
    80003b5e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b62:	0a0b0963          	beqz	s6,80003c14 <readi+0xf0>
    80003b66:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b68:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b6c:	5cfd                	li	s9,-1
    80003b6e:	a82d                	j	80003ba8 <readi+0x84>
    80003b70:	020a1d93          	slli	s11,s4,0x20
    80003b74:	020ddd93          	srli	s11,s11,0x20
    80003b78:	05890613          	addi	a2,s2,88
    80003b7c:	86ee                	mv	a3,s11
    80003b7e:	963a                	add	a2,a2,a4
    80003b80:	85d6                	mv	a1,s5
    80003b82:	8562                	mv	a0,s8
    80003b84:	fffff097          	auipc	ra,0xfffff
    80003b88:	a42080e7          	jalr	-1470(ra) # 800025c6 <either_copyout>
    80003b8c:	05950d63          	beq	a0,s9,80003be6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b90:	854a                	mv	a0,s2
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	60c080e7          	jalr	1548(ra) # 8000319e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b9a:	013a09bb          	addw	s3,s4,s3
    80003b9e:	009a04bb          	addw	s1,s4,s1
    80003ba2:	9aee                	add	s5,s5,s11
    80003ba4:	0569f763          	bgeu	s3,s6,80003bf2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ba8:	000ba903          	lw	s2,0(s7)
    80003bac:	00a4d59b          	srliw	a1,s1,0xa
    80003bb0:	855e                	mv	a0,s7
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	8b0080e7          	jalr	-1872(ra) # 80003462 <bmap>
    80003bba:	0005059b          	sext.w	a1,a0
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	4ae080e7          	jalr	1198(ra) # 8000306e <bread>
    80003bc8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bca:	3ff4f713          	andi	a4,s1,1023
    80003bce:	40ed07bb          	subw	a5,s10,a4
    80003bd2:	413b06bb          	subw	a3,s6,s3
    80003bd6:	8a3e                	mv	s4,a5
    80003bd8:	2781                	sext.w	a5,a5
    80003bda:	0006861b          	sext.w	a2,a3
    80003bde:	f8f679e3          	bgeu	a2,a5,80003b70 <readi+0x4c>
    80003be2:	8a36                	mv	s4,a3
    80003be4:	b771                	j	80003b70 <readi+0x4c>
      brelse(bp);
    80003be6:	854a                	mv	a0,s2
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	5b6080e7          	jalr	1462(ra) # 8000319e <brelse>
      tot = -1;
    80003bf0:	59fd                	li	s3,-1
  }
  return tot;
    80003bf2:	0009851b          	sext.w	a0,s3
}
    80003bf6:	70a6                	ld	ra,104(sp)
    80003bf8:	7406                	ld	s0,96(sp)
    80003bfa:	64e6                	ld	s1,88(sp)
    80003bfc:	6946                	ld	s2,80(sp)
    80003bfe:	69a6                	ld	s3,72(sp)
    80003c00:	6a06                	ld	s4,64(sp)
    80003c02:	7ae2                	ld	s5,56(sp)
    80003c04:	7b42                	ld	s6,48(sp)
    80003c06:	7ba2                	ld	s7,40(sp)
    80003c08:	7c02                	ld	s8,32(sp)
    80003c0a:	6ce2                	ld	s9,24(sp)
    80003c0c:	6d42                	ld	s10,16(sp)
    80003c0e:	6da2                	ld	s11,8(sp)
    80003c10:	6165                	addi	sp,sp,112
    80003c12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c14:	89da                	mv	s3,s6
    80003c16:	bff1                	j	80003bf2 <readi+0xce>
    return 0;
    80003c18:	4501                	li	a0,0
}
    80003c1a:	8082                	ret

0000000080003c1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c1c:	457c                	lw	a5,76(a0)
    80003c1e:	10d7e863          	bltu	a5,a3,80003d2e <writei+0x112>
{
    80003c22:	7159                	addi	sp,sp,-112
    80003c24:	f486                	sd	ra,104(sp)
    80003c26:	f0a2                	sd	s0,96(sp)
    80003c28:	eca6                	sd	s1,88(sp)
    80003c2a:	e8ca                	sd	s2,80(sp)
    80003c2c:	e4ce                	sd	s3,72(sp)
    80003c2e:	e0d2                	sd	s4,64(sp)
    80003c30:	fc56                	sd	s5,56(sp)
    80003c32:	f85a                	sd	s6,48(sp)
    80003c34:	f45e                	sd	s7,40(sp)
    80003c36:	f062                	sd	s8,32(sp)
    80003c38:	ec66                	sd	s9,24(sp)
    80003c3a:	e86a                	sd	s10,16(sp)
    80003c3c:	e46e                	sd	s11,8(sp)
    80003c3e:	1880                	addi	s0,sp,112
    80003c40:	8b2a                	mv	s6,a0
    80003c42:	8c2e                	mv	s8,a1
    80003c44:	8ab2                	mv	s5,a2
    80003c46:	8936                	mv	s2,a3
    80003c48:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c4a:	00e687bb          	addw	a5,a3,a4
    80003c4e:	0ed7e263          	bltu	a5,a3,80003d32 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c52:	00043737          	lui	a4,0x43
    80003c56:	0ef76063          	bltu	a4,a5,80003d36 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c5a:	0c0b8863          	beqz	s7,80003d2a <writei+0x10e>
    80003c5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c64:	5cfd                	li	s9,-1
    80003c66:	a091                	j	80003caa <writei+0x8e>
    80003c68:	02099d93          	slli	s11,s3,0x20
    80003c6c:	020ddd93          	srli	s11,s11,0x20
    80003c70:	05848513          	addi	a0,s1,88
    80003c74:	86ee                	mv	a3,s11
    80003c76:	8656                	mv	a2,s5
    80003c78:	85e2                	mv	a1,s8
    80003c7a:	953a                	add	a0,a0,a4
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	9a0080e7          	jalr	-1632(ra) # 8000261c <either_copyin>
    80003c84:	07950263          	beq	a0,s9,80003ce8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c88:	8526                	mv	a0,s1
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	790080e7          	jalr	1936(ra) # 8000441a <log_write>
    brelse(bp);
    80003c92:	8526                	mv	a0,s1
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	50a080e7          	jalr	1290(ra) # 8000319e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c9c:	01498a3b          	addw	s4,s3,s4
    80003ca0:	0129893b          	addw	s2,s3,s2
    80003ca4:	9aee                	add	s5,s5,s11
    80003ca6:	057a7663          	bgeu	s4,s7,80003cf2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003caa:	000b2483          	lw	s1,0(s6)
    80003cae:	00a9559b          	srliw	a1,s2,0xa
    80003cb2:	855a                	mv	a0,s6
    80003cb4:	fffff097          	auipc	ra,0xfffff
    80003cb8:	7ae080e7          	jalr	1966(ra) # 80003462 <bmap>
    80003cbc:	0005059b          	sext.w	a1,a0
    80003cc0:	8526                	mv	a0,s1
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	3ac080e7          	jalr	940(ra) # 8000306e <bread>
    80003cca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ccc:	3ff97713          	andi	a4,s2,1023
    80003cd0:	40ed07bb          	subw	a5,s10,a4
    80003cd4:	414b86bb          	subw	a3,s7,s4
    80003cd8:	89be                	mv	s3,a5
    80003cda:	2781                	sext.w	a5,a5
    80003cdc:	0006861b          	sext.w	a2,a3
    80003ce0:	f8f674e3          	bgeu	a2,a5,80003c68 <writei+0x4c>
    80003ce4:	89b6                	mv	s3,a3
    80003ce6:	b749                	j	80003c68 <writei+0x4c>
      brelse(bp);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	4b4080e7          	jalr	1204(ra) # 8000319e <brelse>
  }

  if(off > ip->size)
    80003cf2:	04cb2783          	lw	a5,76(s6)
    80003cf6:	0127f463          	bgeu	a5,s2,80003cfe <writei+0xe2>
    ip->size = off;
    80003cfa:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cfe:	855a                	mv	a0,s6
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	aa6080e7          	jalr	-1370(ra) # 800037a6 <iupdate>

  return tot;
    80003d08:	000a051b          	sext.w	a0,s4
}
    80003d0c:	70a6                	ld	ra,104(sp)
    80003d0e:	7406                	ld	s0,96(sp)
    80003d10:	64e6                	ld	s1,88(sp)
    80003d12:	6946                	ld	s2,80(sp)
    80003d14:	69a6                	ld	s3,72(sp)
    80003d16:	6a06                	ld	s4,64(sp)
    80003d18:	7ae2                	ld	s5,56(sp)
    80003d1a:	7b42                	ld	s6,48(sp)
    80003d1c:	7ba2                	ld	s7,40(sp)
    80003d1e:	7c02                	ld	s8,32(sp)
    80003d20:	6ce2                	ld	s9,24(sp)
    80003d22:	6d42                	ld	s10,16(sp)
    80003d24:	6da2                	ld	s11,8(sp)
    80003d26:	6165                	addi	sp,sp,112
    80003d28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2a:	8a5e                	mv	s4,s7
    80003d2c:	bfc9                	j	80003cfe <writei+0xe2>
    return -1;
    80003d2e:	557d                	li	a0,-1
}
    80003d30:	8082                	ret
    return -1;
    80003d32:	557d                	li	a0,-1
    80003d34:	bfe1                	j	80003d0c <writei+0xf0>
    return -1;
    80003d36:	557d                	li	a0,-1
    80003d38:	bfd1                	j	80003d0c <writei+0xf0>

0000000080003d3a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d3a:	1141                	addi	sp,sp,-16
    80003d3c:	e406                	sd	ra,8(sp)
    80003d3e:	e022                	sd	s0,0(sp)
    80003d40:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d42:	4639                	li	a2,14
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	074080e7          	jalr	116(ra) # 80000db8 <strncmp>
}
    80003d4c:	60a2                	ld	ra,8(sp)
    80003d4e:	6402                	ld	s0,0(sp)
    80003d50:	0141                	addi	sp,sp,16
    80003d52:	8082                	ret

0000000080003d54 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d54:	7139                	addi	sp,sp,-64
    80003d56:	fc06                	sd	ra,56(sp)
    80003d58:	f822                	sd	s0,48(sp)
    80003d5a:	f426                	sd	s1,40(sp)
    80003d5c:	f04a                	sd	s2,32(sp)
    80003d5e:	ec4e                	sd	s3,24(sp)
    80003d60:	e852                	sd	s4,16(sp)
    80003d62:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d64:	04451703          	lh	a4,68(a0)
    80003d68:	4785                	li	a5,1
    80003d6a:	00f71a63          	bne	a4,a5,80003d7e <dirlookup+0x2a>
    80003d6e:	892a                	mv	s2,a0
    80003d70:	89ae                	mv	s3,a1
    80003d72:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d74:	457c                	lw	a5,76(a0)
    80003d76:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d78:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7a:	e79d                	bnez	a5,80003da8 <dirlookup+0x54>
    80003d7c:	a8a5                	j	80003df4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d7e:	00005517          	auipc	a0,0x5
    80003d82:	89250513          	addi	a0,a0,-1902 # 80008610 <syscalls+0x1b0>
    80003d86:	ffffc097          	auipc	ra,0xffffc
    80003d8a:	7b8080e7          	jalr	1976(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d8e:	00005517          	auipc	a0,0x5
    80003d92:	89a50513          	addi	a0,a0,-1894 # 80008628 <syscalls+0x1c8>
    80003d96:	ffffc097          	auipc	ra,0xffffc
    80003d9a:	7a8080e7          	jalr	1960(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9e:	24c1                	addiw	s1,s1,16
    80003da0:	04c92783          	lw	a5,76(s2)
    80003da4:	04f4f763          	bgeu	s1,a5,80003df2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003da8:	4741                	li	a4,16
    80003daa:	86a6                	mv	a3,s1
    80003dac:	fc040613          	addi	a2,s0,-64
    80003db0:	4581                	li	a1,0
    80003db2:	854a                	mv	a0,s2
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	d70080e7          	jalr	-656(ra) # 80003b24 <readi>
    80003dbc:	47c1                	li	a5,16
    80003dbe:	fcf518e3          	bne	a0,a5,80003d8e <dirlookup+0x3a>
    if(de.inum == 0)
    80003dc2:	fc045783          	lhu	a5,-64(s0)
    80003dc6:	dfe1                	beqz	a5,80003d9e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dc8:	fc240593          	addi	a1,s0,-62
    80003dcc:	854e                	mv	a0,s3
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	f6c080e7          	jalr	-148(ra) # 80003d3a <namecmp>
    80003dd6:	f561                	bnez	a0,80003d9e <dirlookup+0x4a>
      if(poff)
    80003dd8:	000a0463          	beqz	s4,80003de0 <dirlookup+0x8c>
        *poff = off;
    80003ddc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003de0:	fc045583          	lhu	a1,-64(s0)
    80003de4:	00092503          	lw	a0,0(s2)
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	754080e7          	jalr	1876(ra) # 8000353c <iget>
    80003df0:	a011                	j	80003df4 <dirlookup+0xa0>
  return 0;
    80003df2:	4501                	li	a0,0
}
    80003df4:	70e2                	ld	ra,56(sp)
    80003df6:	7442                	ld	s0,48(sp)
    80003df8:	74a2                	ld	s1,40(sp)
    80003dfa:	7902                	ld	s2,32(sp)
    80003dfc:	69e2                	ld	s3,24(sp)
    80003dfe:	6a42                	ld	s4,16(sp)
    80003e00:	6121                	addi	sp,sp,64
    80003e02:	8082                	ret

0000000080003e04 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e04:	711d                	addi	sp,sp,-96
    80003e06:	ec86                	sd	ra,88(sp)
    80003e08:	e8a2                	sd	s0,80(sp)
    80003e0a:	e4a6                	sd	s1,72(sp)
    80003e0c:	e0ca                	sd	s2,64(sp)
    80003e0e:	fc4e                	sd	s3,56(sp)
    80003e10:	f852                	sd	s4,48(sp)
    80003e12:	f456                	sd	s5,40(sp)
    80003e14:	f05a                	sd	s6,32(sp)
    80003e16:	ec5e                	sd	s7,24(sp)
    80003e18:	e862                	sd	s8,16(sp)
    80003e1a:	e466                	sd	s9,8(sp)
    80003e1c:	1080                	addi	s0,sp,96
    80003e1e:	84aa                	mv	s1,a0
    80003e20:	8b2e                	mv	s6,a1
    80003e22:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e24:	00054703          	lbu	a4,0(a0)
    80003e28:	02f00793          	li	a5,47
    80003e2c:	02f70363          	beq	a4,a5,80003e52 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e30:	ffffe097          	auipc	ra,0xffffe
    80003e34:	b9e080e7          	jalr	-1122(ra) # 800019ce <myproc>
    80003e38:	15053503          	ld	a0,336(a0)
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	9f6080e7          	jalr	-1546(ra) # 80003832 <idup>
    80003e44:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e46:	02f00913          	li	s2,47
  len = path - s;
    80003e4a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e4c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e4e:	4c05                	li	s8,1
    80003e50:	a865                	j	80003f08 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e52:	4585                	li	a1,1
    80003e54:	4505                	li	a0,1
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	6e6080e7          	jalr	1766(ra) # 8000353c <iget>
    80003e5e:	89aa                	mv	s3,a0
    80003e60:	b7dd                	j	80003e46 <namex+0x42>
      iunlockput(ip);
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	c6e080e7          	jalr	-914(ra) # 80003ad2 <iunlockput>
      return 0;
    80003e6c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e6e:	854e                	mv	a0,s3
    80003e70:	60e6                	ld	ra,88(sp)
    80003e72:	6446                	ld	s0,80(sp)
    80003e74:	64a6                	ld	s1,72(sp)
    80003e76:	6906                	ld	s2,64(sp)
    80003e78:	79e2                	ld	s3,56(sp)
    80003e7a:	7a42                	ld	s4,48(sp)
    80003e7c:	7aa2                	ld	s5,40(sp)
    80003e7e:	7b02                	ld	s6,32(sp)
    80003e80:	6be2                	ld	s7,24(sp)
    80003e82:	6c42                	ld	s8,16(sp)
    80003e84:	6ca2                	ld	s9,8(sp)
    80003e86:	6125                	addi	sp,sp,96
    80003e88:	8082                	ret
      iunlock(ip);
    80003e8a:	854e                	mv	a0,s3
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	aa6080e7          	jalr	-1370(ra) # 80003932 <iunlock>
      return ip;
    80003e94:	bfe9                	j	80003e6e <namex+0x6a>
      iunlockput(ip);
    80003e96:	854e                	mv	a0,s3
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	c3a080e7          	jalr	-966(ra) # 80003ad2 <iunlockput>
      return 0;
    80003ea0:	89d2                	mv	s3,s4
    80003ea2:	b7f1                	j	80003e6e <namex+0x6a>
  len = path - s;
    80003ea4:	40b48633          	sub	a2,s1,a1
    80003ea8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003eac:	094cd463          	bge	s9,s4,80003f34 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003eb0:	4639                	li	a2,14
    80003eb2:	8556                	mv	a0,s5
    80003eb4:	ffffd097          	auipc	ra,0xffffd
    80003eb8:	e8c080e7          	jalr	-372(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	01279763          	bne	a5,s2,80003ece <namex+0xca>
    path++;
    80003ec4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec6:	0004c783          	lbu	a5,0(s1)
    80003eca:	ff278de3          	beq	a5,s2,80003ec4 <namex+0xc0>
    ilock(ip);
    80003ece:	854e                	mv	a0,s3
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	9a0080e7          	jalr	-1632(ra) # 80003870 <ilock>
    if(ip->type != T_DIR){
    80003ed8:	04499783          	lh	a5,68(s3)
    80003edc:	f98793e3          	bne	a5,s8,80003e62 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ee0:	000b0563          	beqz	s6,80003eea <namex+0xe6>
    80003ee4:	0004c783          	lbu	a5,0(s1)
    80003ee8:	d3cd                	beqz	a5,80003e8a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eea:	865e                	mv	a2,s7
    80003eec:	85d6                	mv	a1,s5
    80003eee:	854e                	mv	a0,s3
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	e64080e7          	jalr	-412(ra) # 80003d54 <dirlookup>
    80003ef8:	8a2a                	mv	s4,a0
    80003efa:	dd51                	beqz	a0,80003e96 <namex+0x92>
    iunlockput(ip);
    80003efc:	854e                	mv	a0,s3
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	bd4080e7          	jalr	-1068(ra) # 80003ad2 <iunlockput>
    ip = next;
    80003f06:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f08:	0004c783          	lbu	a5,0(s1)
    80003f0c:	05279763          	bne	a5,s2,80003f5a <namex+0x156>
    path++;
    80003f10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f12:	0004c783          	lbu	a5,0(s1)
    80003f16:	ff278de3          	beq	a5,s2,80003f10 <namex+0x10c>
  if(*path == 0)
    80003f1a:	c79d                	beqz	a5,80003f48 <namex+0x144>
    path++;
    80003f1c:	85a6                	mv	a1,s1
  len = path - s;
    80003f1e:	8a5e                	mv	s4,s7
    80003f20:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f22:	01278963          	beq	a5,s2,80003f34 <namex+0x130>
    80003f26:	dfbd                	beqz	a5,80003ea4 <namex+0xa0>
    path++;
    80003f28:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	ff279ce3          	bne	a5,s2,80003f26 <namex+0x122>
    80003f32:	bf8d                	j	80003ea4 <namex+0xa0>
    memmove(name, s, len);
    80003f34:	2601                	sext.w	a2,a2
    80003f36:	8556                	mv	a0,s5
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	e08080e7          	jalr	-504(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f40:	9a56                	add	s4,s4,s5
    80003f42:	000a0023          	sb	zero,0(s4)
    80003f46:	bf9d                	j	80003ebc <namex+0xb8>
  if(nameiparent){
    80003f48:	f20b03e3          	beqz	s6,80003e6e <namex+0x6a>
    iput(ip);
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	adc080e7          	jalr	-1316(ra) # 80003a2a <iput>
    return 0;
    80003f56:	4981                	li	s3,0
    80003f58:	bf19                	j	80003e6e <namex+0x6a>
  if(*path == 0)
    80003f5a:	d7fd                	beqz	a5,80003f48 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f5c:	0004c783          	lbu	a5,0(s1)
    80003f60:	85a6                	mv	a1,s1
    80003f62:	b7d1                	j	80003f26 <namex+0x122>

0000000080003f64 <dirlink>:
{
    80003f64:	7139                	addi	sp,sp,-64
    80003f66:	fc06                	sd	ra,56(sp)
    80003f68:	f822                	sd	s0,48(sp)
    80003f6a:	f426                	sd	s1,40(sp)
    80003f6c:	f04a                	sd	s2,32(sp)
    80003f6e:	ec4e                	sd	s3,24(sp)
    80003f70:	e852                	sd	s4,16(sp)
    80003f72:	0080                	addi	s0,sp,64
    80003f74:	892a                	mv	s2,a0
    80003f76:	8a2e                	mv	s4,a1
    80003f78:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f7a:	4601                	li	a2,0
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	dd8080e7          	jalr	-552(ra) # 80003d54 <dirlookup>
    80003f84:	e93d                	bnez	a0,80003ffa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f86:	04c92483          	lw	s1,76(s2)
    80003f8a:	c49d                	beqz	s1,80003fb8 <dirlink+0x54>
    80003f8c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8e:	4741                	li	a4,16
    80003f90:	86a6                	mv	a3,s1
    80003f92:	fc040613          	addi	a2,s0,-64
    80003f96:	4581                	li	a1,0
    80003f98:	854a                	mv	a0,s2
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	b8a080e7          	jalr	-1142(ra) # 80003b24 <readi>
    80003fa2:	47c1                	li	a5,16
    80003fa4:	06f51163          	bne	a0,a5,80004006 <dirlink+0xa2>
    if(de.inum == 0)
    80003fa8:	fc045783          	lhu	a5,-64(s0)
    80003fac:	c791                	beqz	a5,80003fb8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fae:	24c1                	addiw	s1,s1,16
    80003fb0:	04c92783          	lw	a5,76(s2)
    80003fb4:	fcf4ede3          	bltu	s1,a5,80003f8e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fb8:	4639                	li	a2,14
    80003fba:	85d2                	mv	a1,s4
    80003fbc:	fc240513          	addi	a0,s0,-62
    80003fc0:	ffffd097          	auipc	ra,0xffffd
    80003fc4:	e34080e7          	jalr	-460(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fc8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fcc:	4741                	li	a4,16
    80003fce:	86a6                	mv	a3,s1
    80003fd0:	fc040613          	addi	a2,s0,-64
    80003fd4:	4581                	li	a1,0
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	c44080e7          	jalr	-956(ra) # 80003c1c <writei>
    80003fe0:	872a                	mv	a4,a0
    80003fe2:	47c1                	li	a5,16
  return 0;
    80003fe4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe6:	02f71863          	bne	a4,a5,80004016 <dirlink+0xb2>
}
    80003fea:	70e2                	ld	ra,56(sp)
    80003fec:	7442                	ld	s0,48(sp)
    80003fee:	74a2                	ld	s1,40(sp)
    80003ff0:	7902                	ld	s2,32(sp)
    80003ff2:	69e2                	ld	s3,24(sp)
    80003ff4:	6a42                	ld	s4,16(sp)
    80003ff6:	6121                	addi	sp,sp,64
    80003ff8:	8082                	ret
    iput(ip);
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	a30080e7          	jalr	-1488(ra) # 80003a2a <iput>
    return -1;
    80004002:	557d                	li	a0,-1
    80004004:	b7dd                	j	80003fea <dirlink+0x86>
      panic("dirlink read");
    80004006:	00004517          	auipc	a0,0x4
    8000400a:	63250513          	addi	a0,a0,1586 # 80008638 <syscalls+0x1d8>
    8000400e:	ffffc097          	auipc	ra,0xffffc
    80004012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("dirlink");
    80004016:	00004517          	auipc	a0,0x4
    8000401a:	73250513          	addi	a0,a0,1842 # 80008748 <syscalls+0x2e8>
    8000401e:	ffffc097          	auipc	ra,0xffffc
    80004022:	520080e7          	jalr	1312(ra) # 8000053e <panic>

0000000080004026 <namei>:

struct inode*
namei(char *path)
{
    80004026:	1101                	addi	sp,sp,-32
    80004028:	ec06                	sd	ra,24(sp)
    8000402a:	e822                	sd	s0,16(sp)
    8000402c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000402e:	fe040613          	addi	a2,s0,-32
    80004032:	4581                	li	a1,0
    80004034:	00000097          	auipc	ra,0x0
    80004038:	dd0080e7          	jalr	-560(ra) # 80003e04 <namex>
}
    8000403c:	60e2                	ld	ra,24(sp)
    8000403e:	6442                	ld	s0,16(sp)
    80004040:	6105                	addi	sp,sp,32
    80004042:	8082                	ret

0000000080004044 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004044:	1141                	addi	sp,sp,-16
    80004046:	e406                	sd	ra,8(sp)
    80004048:	e022                	sd	s0,0(sp)
    8000404a:	0800                	addi	s0,sp,16
    8000404c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000404e:	4585                	li	a1,1
    80004050:	00000097          	auipc	ra,0x0
    80004054:	db4080e7          	jalr	-588(ra) # 80003e04 <namex>
}
    80004058:	60a2                	ld	ra,8(sp)
    8000405a:	6402                	ld	s0,0(sp)
    8000405c:	0141                	addi	sp,sp,16
    8000405e:	8082                	ret

0000000080004060 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004060:	1101                	addi	sp,sp,-32
    80004062:	ec06                	sd	ra,24(sp)
    80004064:	e822                	sd	s0,16(sp)
    80004066:	e426                	sd	s1,8(sp)
    80004068:	e04a                	sd	s2,0(sp)
    8000406a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000406c:	0001d917          	auipc	s2,0x1d
    80004070:	20490913          	addi	s2,s2,516 # 80021270 <log>
    80004074:	01892583          	lw	a1,24(s2)
    80004078:	02892503          	lw	a0,40(s2)
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	ff2080e7          	jalr	-14(ra) # 8000306e <bread>
    80004084:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004086:	02c92683          	lw	a3,44(s2)
    8000408a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000408c:	02d05763          	blez	a3,800040ba <write_head+0x5a>
    80004090:	0001d797          	auipc	a5,0x1d
    80004094:	21078793          	addi	a5,a5,528 # 800212a0 <log+0x30>
    80004098:	05c50713          	addi	a4,a0,92
    8000409c:	36fd                	addiw	a3,a3,-1
    8000409e:	1682                	slli	a3,a3,0x20
    800040a0:	9281                	srli	a3,a3,0x20
    800040a2:	068a                	slli	a3,a3,0x2
    800040a4:	0001d617          	auipc	a2,0x1d
    800040a8:	20060613          	addi	a2,a2,512 # 800212a4 <log+0x34>
    800040ac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040ae:	4390                	lw	a2,0(a5)
    800040b0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040b2:	0791                	addi	a5,a5,4
    800040b4:	0711                	addi	a4,a4,4
    800040b6:	fed79ce3          	bne	a5,a3,800040ae <write_head+0x4e>
  }
  bwrite(buf);
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	0a4080e7          	jalr	164(ra) # 80003160 <bwrite>
  brelse(buf);
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	0d8080e7          	jalr	216(ra) # 8000319e <brelse>
}
    800040ce:	60e2                	ld	ra,24(sp)
    800040d0:	6442                	ld	s0,16(sp)
    800040d2:	64a2                	ld	s1,8(sp)
    800040d4:	6902                	ld	s2,0(sp)
    800040d6:	6105                	addi	sp,sp,32
    800040d8:	8082                	ret

00000000800040da <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040da:	0001d797          	auipc	a5,0x1d
    800040de:	1c27a783          	lw	a5,450(a5) # 8002129c <log+0x2c>
    800040e2:	0af05d63          	blez	a5,8000419c <install_trans+0xc2>
{
    800040e6:	7139                	addi	sp,sp,-64
    800040e8:	fc06                	sd	ra,56(sp)
    800040ea:	f822                	sd	s0,48(sp)
    800040ec:	f426                	sd	s1,40(sp)
    800040ee:	f04a                	sd	s2,32(sp)
    800040f0:	ec4e                	sd	s3,24(sp)
    800040f2:	e852                	sd	s4,16(sp)
    800040f4:	e456                	sd	s5,8(sp)
    800040f6:	e05a                	sd	s6,0(sp)
    800040f8:	0080                	addi	s0,sp,64
    800040fa:	8b2a                	mv	s6,a0
    800040fc:	0001da97          	auipc	s5,0x1d
    80004100:	1a4a8a93          	addi	s5,s5,420 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004104:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004106:	0001d997          	auipc	s3,0x1d
    8000410a:	16a98993          	addi	s3,s3,362 # 80021270 <log>
    8000410e:	a035                	j	8000413a <install_trans+0x60>
      bunpin(dbuf);
    80004110:	8526                	mv	a0,s1
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	166080e7          	jalr	358(ra) # 80003278 <bunpin>
    brelse(lbuf);
    8000411a:	854a                	mv	a0,s2
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	082080e7          	jalr	130(ra) # 8000319e <brelse>
    brelse(dbuf);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	078080e7          	jalr	120(ra) # 8000319e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412e:	2a05                	addiw	s4,s4,1
    80004130:	0a91                	addi	s5,s5,4
    80004132:	02c9a783          	lw	a5,44(s3)
    80004136:	04fa5963          	bge	s4,a5,80004188 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000413a:	0189a583          	lw	a1,24(s3)
    8000413e:	014585bb          	addw	a1,a1,s4
    80004142:	2585                	addiw	a1,a1,1
    80004144:	0289a503          	lw	a0,40(s3)
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	f26080e7          	jalr	-218(ra) # 8000306e <bread>
    80004150:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004152:	000aa583          	lw	a1,0(s5)
    80004156:	0289a503          	lw	a0,40(s3)
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	f14080e7          	jalr	-236(ra) # 8000306e <bread>
    80004162:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004164:	40000613          	li	a2,1024
    80004168:	05890593          	addi	a1,s2,88
    8000416c:	05850513          	addi	a0,a0,88
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	bd0080e7          	jalr	-1072(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004178:	8526                	mv	a0,s1
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	fe6080e7          	jalr	-26(ra) # 80003160 <bwrite>
    if(recovering == 0)
    80004182:	f80b1ce3          	bnez	s6,8000411a <install_trans+0x40>
    80004186:	b769                	j	80004110 <install_trans+0x36>
}
    80004188:	70e2                	ld	ra,56(sp)
    8000418a:	7442                	ld	s0,48(sp)
    8000418c:	74a2                	ld	s1,40(sp)
    8000418e:	7902                	ld	s2,32(sp)
    80004190:	69e2                	ld	s3,24(sp)
    80004192:	6a42                	ld	s4,16(sp)
    80004194:	6aa2                	ld	s5,8(sp)
    80004196:	6b02                	ld	s6,0(sp)
    80004198:	6121                	addi	sp,sp,64
    8000419a:	8082                	ret
    8000419c:	8082                	ret

000000008000419e <initlog>:
{
    8000419e:	7179                	addi	sp,sp,-48
    800041a0:	f406                	sd	ra,40(sp)
    800041a2:	f022                	sd	s0,32(sp)
    800041a4:	ec26                	sd	s1,24(sp)
    800041a6:	e84a                	sd	s2,16(sp)
    800041a8:	e44e                	sd	s3,8(sp)
    800041aa:	1800                	addi	s0,sp,48
    800041ac:	892a                	mv	s2,a0
    800041ae:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041b0:	0001d497          	auipc	s1,0x1d
    800041b4:	0c048493          	addi	s1,s1,192 # 80021270 <log>
    800041b8:	00004597          	auipc	a1,0x4
    800041bc:	49058593          	addi	a1,a1,1168 # 80008648 <syscalls+0x1e8>
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	992080e7          	jalr	-1646(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041ca:	0149a583          	lw	a1,20(s3)
    800041ce:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041d0:	0109a783          	lw	a5,16(s3)
    800041d4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041d6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041da:	854a                	mv	a0,s2
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	e92080e7          	jalr	-366(ra) # 8000306e <bread>
  log.lh.n = lh->n;
    800041e4:	4d3c                	lw	a5,88(a0)
    800041e6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041e8:	02f05563          	blez	a5,80004212 <initlog+0x74>
    800041ec:	05c50713          	addi	a4,a0,92
    800041f0:	0001d697          	auipc	a3,0x1d
    800041f4:	0b068693          	addi	a3,a3,176 # 800212a0 <log+0x30>
    800041f8:	37fd                	addiw	a5,a5,-1
    800041fa:	1782                	slli	a5,a5,0x20
    800041fc:	9381                	srli	a5,a5,0x20
    800041fe:	078a                	slli	a5,a5,0x2
    80004200:	06050613          	addi	a2,a0,96
    80004204:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004206:	4310                	lw	a2,0(a4)
    80004208:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000420a:	0711                	addi	a4,a4,4
    8000420c:	0691                	addi	a3,a3,4
    8000420e:	fef71ce3          	bne	a4,a5,80004206 <initlog+0x68>
  brelse(buf);
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	f8c080e7          	jalr	-116(ra) # 8000319e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000421a:	4505                	li	a0,1
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	ebe080e7          	jalr	-322(ra) # 800040da <install_trans>
  log.lh.n = 0;
    80004224:	0001d797          	auipc	a5,0x1d
    80004228:	0607ac23          	sw	zero,120(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	e34080e7          	jalr	-460(ra) # 80004060 <write_head>
}
    80004234:	70a2                	ld	ra,40(sp)
    80004236:	7402                	ld	s0,32(sp)
    80004238:	64e2                	ld	s1,24(sp)
    8000423a:	6942                	ld	s2,16(sp)
    8000423c:	69a2                	ld	s3,8(sp)
    8000423e:	6145                	addi	sp,sp,48
    80004240:	8082                	ret

0000000080004242 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004242:	1101                	addi	sp,sp,-32
    80004244:	ec06                	sd	ra,24(sp)
    80004246:	e822                	sd	s0,16(sp)
    80004248:	e426                	sd	s1,8(sp)
    8000424a:	e04a                	sd	s2,0(sp)
    8000424c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000424e:	0001d517          	auipc	a0,0x1d
    80004252:	02250513          	addi	a0,a0,34 # 80021270 <log>
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	98e080e7          	jalr	-1650(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000425e:	0001d497          	auipc	s1,0x1d
    80004262:	01248493          	addi	s1,s1,18 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004266:	4979                	li	s2,30
    80004268:	a039                	j	80004276 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000426a:	85a6                	mv	a1,s1
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	f98080e7          	jalr	-104(ra) # 80002206 <sleep>
    if(log.committing){
    80004276:	50dc                	lw	a5,36(s1)
    80004278:	fbed                	bnez	a5,8000426a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000427a:	509c                	lw	a5,32(s1)
    8000427c:	0017871b          	addiw	a4,a5,1
    80004280:	0007069b          	sext.w	a3,a4
    80004284:	0027179b          	slliw	a5,a4,0x2
    80004288:	9fb9                	addw	a5,a5,a4
    8000428a:	0017979b          	slliw	a5,a5,0x1
    8000428e:	54d8                	lw	a4,44(s1)
    80004290:	9fb9                	addw	a5,a5,a4
    80004292:	00f95963          	bge	s2,a5,800042a4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004296:	85a6                	mv	a1,s1
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffe097          	auipc	ra,0xffffe
    8000429e:	f6c080e7          	jalr	-148(ra) # 80002206 <sleep>
    800042a2:	bfd1                	j	80004276 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042a4:	0001d517          	auipc	a0,0x1d
    800042a8:	fcc50513          	addi	a0,a0,-52 # 80021270 <log>
    800042ac:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	9ea080e7          	jalr	-1558(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042b6:	60e2                	ld	ra,24(sp)
    800042b8:	6442                	ld	s0,16(sp)
    800042ba:	64a2                	ld	s1,8(sp)
    800042bc:	6902                	ld	s2,0(sp)
    800042be:	6105                	addi	sp,sp,32
    800042c0:	8082                	ret

00000000800042c2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042c2:	7139                	addi	sp,sp,-64
    800042c4:	fc06                	sd	ra,56(sp)
    800042c6:	f822                	sd	s0,48(sp)
    800042c8:	f426                	sd	s1,40(sp)
    800042ca:	f04a                	sd	s2,32(sp)
    800042cc:	ec4e                	sd	s3,24(sp)
    800042ce:	e852                	sd	s4,16(sp)
    800042d0:	e456                	sd	s5,8(sp)
    800042d2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042d4:	0001d497          	auipc	s1,0x1d
    800042d8:	f9c48493          	addi	s1,s1,-100 # 80021270 <log>
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	906080e7          	jalr	-1786(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042e6:	509c                	lw	a5,32(s1)
    800042e8:	37fd                	addiw	a5,a5,-1
    800042ea:	0007891b          	sext.w	s2,a5
    800042ee:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042f0:	50dc                	lw	a5,36(s1)
    800042f2:	efb9                	bnez	a5,80004350 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042f4:	06091663          	bnez	s2,80004360 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042f8:	0001d497          	auipc	s1,0x1d
    800042fc:	f7848493          	addi	s1,s1,-136 # 80021270 <log>
    80004300:	4785                	li	a5,1
    80004302:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000430e:	54dc                	lw	a5,44(s1)
    80004310:	06f04763          	bgtz	a5,8000437e <end_op+0xbc>
    acquire(&log.lock);
    80004314:	0001d497          	auipc	s1,0x1d
    80004318:	f5c48493          	addi	s1,s1,-164 # 80021270 <log>
    8000431c:	8526                	mv	a0,s1
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004326:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffe097          	auipc	ra,0xffffe
    80004330:	066080e7          	jalr	102(ra) # 80002392 <wakeup>
    release(&log.lock);
    80004334:	8526                	mv	a0,s1
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
}
    8000433e:	70e2                	ld	ra,56(sp)
    80004340:	7442                	ld	s0,48(sp)
    80004342:	74a2                	ld	s1,40(sp)
    80004344:	7902                	ld	s2,32(sp)
    80004346:	69e2                	ld	s3,24(sp)
    80004348:	6a42                	ld	s4,16(sp)
    8000434a:	6aa2                	ld	s5,8(sp)
    8000434c:	6121                	addi	sp,sp,64
    8000434e:	8082                	ret
    panic("log.committing");
    80004350:	00004517          	auipc	a0,0x4
    80004354:	30050513          	addi	a0,a0,768 # 80008650 <syscalls+0x1f0>
    80004358:	ffffc097          	auipc	ra,0xffffc
    8000435c:	1e6080e7          	jalr	486(ra) # 8000053e <panic>
    wakeup(&log);
    80004360:	0001d497          	auipc	s1,0x1d
    80004364:	f1048493          	addi	s1,s1,-240 # 80021270 <log>
    80004368:	8526                	mv	a0,s1
    8000436a:	ffffe097          	auipc	ra,0xffffe
    8000436e:	028080e7          	jalr	40(ra) # 80002392 <wakeup>
  release(&log.lock);
    80004372:	8526                	mv	a0,s1
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
  if(do_commit){
    8000437c:	b7c9                	j	8000433e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000437e:	0001da97          	auipc	s5,0x1d
    80004382:	f22a8a93          	addi	s5,s5,-222 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004386:	0001da17          	auipc	s4,0x1d
    8000438a:	eeaa0a13          	addi	s4,s4,-278 # 80021270 <log>
    8000438e:	018a2583          	lw	a1,24(s4)
    80004392:	012585bb          	addw	a1,a1,s2
    80004396:	2585                	addiw	a1,a1,1
    80004398:	028a2503          	lw	a0,40(s4)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	cd2080e7          	jalr	-814(ra) # 8000306e <bread>
    800043a4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043a6:	000aa583          	lw	a1,0(s5)
    800043aa:	028a2503          	lw	a0,40(s4)
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	cc0080e7          	jalr	-832(ra) # 8000306e <bread>
    800043b6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043b8:	40000613          	li	a2,1024
    800043bc:	05850593          	addi	a1,a0,88
    800043c0:	05848513          	addi	a0,s1,88
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	97c080e7          	jalr	-1668(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	d92080e7          	jalr	-622(ra) # 80003160 <bwrite>
    brelse(from);
    800043d6:	854e                	mv	a0,s3
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	dc6080e7          	jalr	-570(ra) # 8000319e <brelse>
    brelse(to);
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	dbc080e7          	jalr	-580(ra) # 8000319e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ea:	2905                	addiw	s2,s2,1
    800043ec:	0a91                	addi	s5,s5,4
    800043ee:	02ca2783          	lw	a5,44(s4)
    800043f2:	f8f94ee3          	blt	s2,a5,8000438e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043f6:	00000097          	auipc	ra,0x0
    800043fa:	c6a080e7          	jalr	-918(ra) # 80004060 <write_head>
    install_trans(0); // Now install writes to home locations
    800043fe:	4501                	li	a0,0
    80004400:	00000097          	auipc	ra,0x0
    80004404:	cda080e7          	jalr	-806(ra) # 800040da <install_trans>
    log.lh.n = 0;
    80004408:	0001d797          	auipc	a5,0x1d
    8000440c:	e807aa23          	sw	zero,-364(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c50080e7          	jalr	-944(ra) # 80004060 <write_head>
    80004418:	bdf5                	j	80004314 <end_op+0x52>

000000008000441a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	e426                	sd	s1,8(sp)
    80004422:	e04a                	sd	s2,0(sp)
    80004424:	1000                	addi	s0,sp,32
    80004426:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004428:	0001d917          	auipc	s2,0x1d
    8000442c:	e4890913          	addi	s2,s2,-440 # 80021270 <log>
    80004430:	854a                	mv	a0,s2
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000443a:	02c92603          	lw	a2,44(s2)
    8000443e:	47f5                	li	a5,29
    80004440:	06c7c563          	blt	a5,a2,800044aa <log_write+0x90>
    80004444:	0001d797          	auipc	a5,0x1d
    80004448:	e487a783          	lw	a5,-440(a5) # 8002128c <log+0x1c>
    8000444c:	37fd                	addiw	a5,a5,-1
    8000444e:	04f65e63          	bge	a2,a5,800044aa <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004452:	0001d797          	auipc	a5,0x1d
    80004456:	e3e7a783          	lw	a5,-450(a5) # 80021290 <log+0x20>
    8000445a:	06f05063          	blez	a5,800044ba <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000445e:	4781                	li	a5,0
    80004460:	06c05563          	blez	a2,800044ca <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004464:	44cc                	lw	a1,12(s1)
    80004466:	0001d717          	auipc	a4,0x1d
    8000446a:	e3a70713          	addi	a4,a4,-454 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000446e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004470:	4314                	lw	a3,0(a4)
    80004472:	04b68c63          	beq	a3,a1,800044ca <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004476:	2785                	addiw	a5,a5,1
    80004478:	0711                	addi	a4,a4,4
    8000447a:	fef61be3          	bne	a2,a5,80004470 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000447e:	0621                	addi	a2,a2,8
    80004480:	060a                	slli	a2,a2,0x2
    80004482:	0001d797          	auipc	a5,0x1d
    80004486:	dee78793          	addi	a5,a5,-530 # 80021270 <log>
    8000448a:	963e                	add	a2,a2,a5
    8000448c:	44dc                	lw	a5,12(s1)
    8000448e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004490:	8526                	mv	a0,s1
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	daa080e7          	jalr	-598(ra) # 8000323c <bpin>
    log.lh.n++;
    8000449a:	0001d717          	auipc	a4,0x1d
    8000449e:	dd670713          	addi	a4,a4,-554 # 80021270 <log>
    800044a2:	575c                	lw	a5,44(a4)
    800044a4:	2785                	addiw	a5,a5,1
    800044a6:	d75c                	sw	a5,44(a4)
    800044a8:	a835                	j	800044e4 <log_write+0xca>
    panic("too big a transaction");
    800044aa:	00004517          	auipc	a0,0x4
    800044ae:	1b650513          	addi	a0,a0,438 # 80008660 <syscalls+0x200>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	08c080e7          	jalr	140(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	1be50513          	addi	a0,a0,446 # 80008678 <syscalls+0x218>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	07c080e7          	jalr	124(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044ca:	00878713          	addi	a4,a5,8
    800044ce:	00271693          	slli	a3,a4,0x2
    800044d2:	0001d717          	auipc	a4,0x1d
    800044d6:	d9e70713          	addi	a4,a4,-610 # 80021270 <log>
    800044da:	9736                	add	a4,a4,a3
    800044dc:	44d4                	lw	a3,12(s1)
    800044de:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044e0:	faf608e3          	beq	a2,a5,80004490 <log_write+0x76>
  }
  release(&log.lock);
    800044e4:	0001d517          	auipc	a0,0x1d
    800044e8:	d8c50513          	addi	a0,a0,-628 # 80021270 <log>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	7ac080e7          	jalr	1964(ra) # 80000c98 <release>
}
    800044f4:	60e2                	ld	ra,24(sp)
    800044f6:	6442                	ld	s0,16(sp)
    800044f8:	64a2                	ld	s1,8(sp)
    800044fa:	6902                	ld	s2,0(sp)
    800044fc:	6105                	addi	sp,sp,32
    800044fe:	8082                	ret

0000000080004500 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004500:	1101                	addi	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	e426                	sd	s1,8(sp)
    80004508:	e04a                	sd	s2,0(sp)
    8000450a:	1000                	addi	s0,sp,32
    8000450c:	84aa                	mv	s1,a0
    8000450e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004510:	00004597          	auipc	a1,0x4
    80004514:	18858593          	addi	a1,a1,392 # 80008698 <syscalls+0x238>
    80004518:	0521                	addi	a0,a0,8
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	63a080e7          	jalr	1594(ra) # 80000b54 <initlock>
  lk->name = name;
    80004522:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004526:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000452a:	0204a423          	sw	zero,40(s1)
}
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	64a2                	ld	s1,8(sp)
    80004534:	6902                	ld	s2,0(sp)
    80004536:	6105                	addi	sp,sp,32
    80004538:	8082                	ret

000000008000453a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	e04a                	sd	s2,0(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004548:	00850913          	addi	s2,a0,8
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	696080e7          	jalr	1686(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004556:	409c                	lw	a5,0(s1)
    80004558:	cb89                	beqz	a5,8000456a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000455a:	85ca                	mv	a1,s2
    8000455c:	8526                	mv	a0,s1
    8000455e:	ffffe097          	auipc	ra,0xffffe
    80004562:	ca8080e7          	jalr	-856(ra) # 80002206 <sleep>
  while (lk->locked) {
    80004566:	409c                	lw	a5,0(s1)
    80004568:	fbed                	bnez	a5,8000455a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000456a:	4785                	li	a5,1
    8000456c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000456e:	ffffd097          	auipc	ra,0xffffd
    80004572:	460080e7          	jalr	1120(ra) # 800019ce <myproc>
    80004576:	591c                	lw	a5,48(a0)
    80004578:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000457a:	854a                	mv	a0,s2
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	71c080e7          	jalr	1820(ra) # 80000c98 <release>
}
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6902                	ld	s2,0(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004590:	1101                	addi	sp,sp,-32
    80004592:	ec06                	sd	ra,24(sp)
    80004594:	e822                	sd	s0,16(sp)
    80004596:	e426                	sd	s1,8(sp)
    80004598:	e04a                	sd	s2,0(sp)
    8000459a:	1000                	addi	s0,sp,32
    8000459c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000459e:	00850913          	addi	s2,a0,8
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045b4:	8526                	mv	a0,s1
    800045b6:	ffffe097          	auipc	ra,0xffffe
    800045ba:	ddc080e7          	jalr	-548(ra) # 80002392 <wakeup>
  release(&lk->lk);
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6d8080e7          	jalr	1752(ra) # 80000c98 <release>
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045d4:	7179                	addi	sp,sp,-48
    800045d6:	f406                	sd	ra,40(sp)
    800045d8:	f022                	sd	s0,32(sp)
    800045da:	ec26                	sd	s1,24(sp)
    800045dc:	e84a                	sd	s2,16(sp)
    800045de:	e44e                	sd	s3,8(sp)
    800045e0:	1800                	addi	s0,sp,48
    800045e2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045e4:	00850913          	addi	s2,a0,8
    800045e8:	854a                	mv	a0,s2
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	5fa080e7          	jalr	1530(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045f2:	409c                	lw	a5,0(s1)
    800045f4:	ef99                	bnez	a5,80004612 <holdingsleep+0x3e>
    800045f6:	4481                	li	s1,0
  release(&lk->lk);
    800045f8:	854a                	mv	a0,s2
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	69e080e7          	jalr	1694(ra) # 80000c98 <release>
  return r;
}
    80004602:	8526                	mv	a0,s1
    80004604:	70a2                	ld	ra,40(sp)
    80004606:	7402                	ld	s0,32(sp)
    80004608:	64e2                	ld	s1,24(sp)
    8000460a:	6942                	ld	s2,16(sp)
    8000460c:	69a2                	ld	s3,8(sp)
    8000460e:	6145                	addi	sp,sp,48
    80004610:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004612:	0284a983          	lw	s3,40(s1)
    80004616:	ffffd097          	auipc	ra,0xffffd
    8000461a:	3b8080e7          	jalr	952(ra) # 800019ce <myproc>
    8000461e:	5904                	lw	s1,48(a0)
    80004620:	413484b3          	sub	s1,s1,s3
    80004624:	0014b493          	seqz	s1,s1
    80004628:	bfc1                	j	800045f8 <holdingsleep+0x24>

000000008000462a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000462a:	1141                	addi	sp,sp,-16
    8000462c:	e406                	sd	ra,8(sp)
    8000462e:	e022                	sd	s0,0(sp)
    80004630:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004632:	00004597          	auipc	a1,0x4
    80004636:	07658593          	addi	a1,a1,118 # 800086a8 <syscalls+0x248>
    8000463a:	0001d517          	auipc	a0,0x1d
    8000463e:	d7e50513          	addi	a0,a0,-642 # 800213b8 <ftable>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	512080e7          	jalr	1298(ra) # 80000b54 <initlock>
}
    8000464a:	60a2                	ld	ra,8(sp)
    8000464c:	6402                	ld	s0,0(sp)
    8000464e:	0141                	addi	sp,sp,16
    80004650:	8082                	ret

0000000080004652 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004652:	1101                	addi	sp,sp,-32
    80004654:	ec06                	sd	ra,24(sp)
    80004656:	e822                	sd	s0,16(sp)
    80004658:	e426                	sd	s1,8(sp)
    8000465a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	d5c50513          	addi	a0,a0,-676 # 800213b8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	580080e7          	jalr	1408(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000466c:	0001d497          	auipc	s1,0x1d
    80004670:	d6448493          	addi	s1,s1,-668 # 800213d0 <ftable+0x18>
    80004674:	0001e717          	auipc	a4,0x1e
    80004678:	cfc70713          	addi	a4,a4,-772 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000467c:	40dc                	lw	a5,4(s1)
    8000467e:	cf99                	beqz	a5,8000469c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004680:	02848493          	addi	s1,s1,40
    80004684:	fee49ce3          	bne	s1,a4,8000467c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	d3050513          	addi	a0,a0,-720 # 800213b8 <ftable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	608080e7          	jalr	1544(ra) # 80000c98 <release>
  return 0;
    80004698:	4481                	li	s1,0
    8000469a:	a819                	j	800046b0 <filealloc+0x5e>
      f->ref = 1;
    8000469c:	4785                	li	a5,1
    8000469e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046a0:	0001d517          	auipc	a0,0x1d
    800046a4:	d1850513          	addi	a0,a0,-744 # 800213b8 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	5f0080e7          	jalr	1520(ra) # 80000c98 <release>
}
    800046b0:	8526                	mv	a0,s1
    800046b2:	60e2                	ld	ra,24(sp)
    800046b4:	6442                	ld	s0,16(sp)
    800046b6:	64a2                	ld	s1,8(sp)
    800046b8:	6105                	addi	sp,sp,32
    800046ba:	8082                	ret

00000000800046bc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046bc:	1101                	addi	sp,sp,-32
    800046be:	ec06                	sd	ra,24(sp)
    800046c0:	e822                	sd	s0,16(sp)
    800046c2:	e426                	sd	s1,8(sp)
    800046c4:	1000                	addi	s0,sp,32
    800046c6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046c8:	0001d517          	auipc	a0,0x1d
    800046cc:	cf050513          	addi	a0,a0,-784 # 800213b8 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	514080e7          	jalr	1300(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046d8:	40dc                	lw	a5,4(s1)
    800046da:	02f05263          	blez	a5,800046fe <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046de:	2785                	addiw	a5,a5,1
    800046e0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046e2:	0001d517          	auipc	a0,0x1d
    800046e6:	cd650513          	addi	a0,a0,-810 # 800213b8 <ftable>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5ae080e7          	jalr	1454(ra) # 80000c98 <release>
  return f;
}
    800046f2:	8526                	mv	a0,s1
    800046f4:	60e2                	ld	ra,24(sp)
    800046f6:	6442                	ld	s0,16(sp)
    800046f8:	64a2                	ld	s1,8(sp)
    800046fa:	6105                	addi	sp,sp,32
    800046fc:	8082                	ret
    panic("filedup");
    800046fe:	00004517          	auipc	a0,0x4
    80004702:	fb250513          	addi	a0,a0,-78 # 800086b0 <syscalls+0x250>
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	e38080e7          	jalr	-456(ra) # 8000053e <panic>

000000008000470e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000470e:	7139                	addi	sp,sp,-64
    80004710:	fc06                	sd	ra,56(sp)
    80004712:	f822                	sd	s0,48(sp)
    80004714:	f426                	sd	s1,40(sp)
    80004716:	f04a                	sd	s2,32(sp)
    80004718:	ec4e                	sd	s3,24(sp)
    8000471a:	e852                	sd	s4,16(sp)
    8000471c:	e456                	sd	s5,8(sp)
    8000471e:	0080                	addi	s0,sp,64
    80004720:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004722:	0001d517          	auipc	a0,0x1d
    80004726:	c9650513          	addi	a0,a0,-874 # 800213b8 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	4ba080e7          	jalr	1210(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004732:	40dc                	lw	a5,4(s1)
    80004734:	06f05163          	blez	a5,80004796 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004738:	37fd                	addiw	a5,a5,-1
    8000473a:	0007871b          	sext.w	a4,a5
    8000473e:	c0dc                	sw	a5,4(s1)
    80004740:	06e04363          	bgtz	a4,800047a6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004744:	0004a903          	lw	s2,0(s1)
    80004748:	0094ca83          	lbu	s5,9(s1)
    8000474c:	0104ba03          	ld	s4,16(s1)
    80004750:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004754:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004758:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000475c:	0001d517          	auipc	a0,0x1d
    80004760:	c5c50513          	addi	a0,a0,-932 # 800213b8 <ftable>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	534080e7          	jalr	1332(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000476c:	4785                	li	a5,1
    8000476e:	04f90d63          	beq	s2,a5,800047c8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004772:	3979                	addiw	s2,s2,-2
    80004774:	4785                	li	a5,1
    80004776:	0527e063          	bltu	a5,s2,800047b6 <fileclose+0xa8>
    begin_op();
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	ac8080e7          	jalr	-1336(ra) # 80004242 <begin_op>
    iput(ff.ip);
    80004782:	854e                	mv	a0,s3
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	2a6080e7          	jalr	678(ra) # 80003a2a <iput>
    end_op();
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	b36080e7          	jalr	-1226(ra) # 800042c2 <end_op>
    80004794:	a00d                	j	800047b6 <fileclose+0xa8>
    panic("fileclose");
    80004796:	00004517          	auipc	a0,0x4
    8000479a:	f2250513          	addi	a0,a0,-222 # 800086b8 <syscalls+0x258>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047a6:	0001d517          	auipc	a0,0x1d
    800047aa:	c1250513          	addi	a0,a0,-1006 # 800213b8 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	4ea080e7          	jalr	1258(ra) # 80000c98 <release>
  }
}
    800047b6:	70e2                	ld	ra,56(sp)
    800047b8:	7442                	ld	s0,48(sp)
    800047ba:	74a2                	ld	s1,40(sp)
    800047bc:	7902                	ld	s2,32(sp)
    800047be:	69e2                	ld	s3,24(sp)
    800047c0:	6a42                	ld	s4,16(sp)
    800047c2:	6aa2                	ld	s5,8(sp)
    800047c4:	6121                	addi	sp,sp,64
    800047c6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047c8:	85d6                	mv	a1,s5
    800047ca:	8552                	mv	a0,s4
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	34c080e7          	jalr	844(ra) # 80004b18 <pipeclose>
    800047d4:	b7cd                	j	800047b6 <fileclose+0xa8>

00000000800047d6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047d6:	715d                	addi	sp,sp,-80
    800047d8:	e486                	sd	ra,72(sp)
    800047da:	e0a2                	sd	s0,64(sp)
    800047dc:	fc26                	sd	s1,56(sp)
    800047de:	f84a                	sd	s2,48(sp)
    800047e0:	f44e                	sd	s3,40(sp)
    800047e2:	0880                	addi	s0,sp,80
    800047e4:	84aa                	mv	s1,a0
    800047e6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047e8:	ffffd097          	auipc	ra,0xffffd
    800047ec:	1e6080e7          	jalr	486(ra) # 800019ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047f0:	409c                	lw	a5,0(s1)
    800047f2:	37f9                	addiw	a5,a5,-2
    800047f4:	4705                	li	a4,1
    800047f6:	04f76763          	bltu	a4,a5,80004844 <filestat+0x6e>
    800047fa:	892a                	mv	s2,a0
    ilock(f->ip);
    800047fc:	6c88                	ld	a0,24(s1)
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	072080e7          	jalr	114(ra) # 80003870 <ilock>
    stati(f->ip, &st);
    80004806:	fb840593          	addi	a1,s0,-72
    8000480a:	6c88                	ld	a0,24(s1)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	2ee080e7          	jalr	750(ra) # 80003afa <stati>
    iunlock(f->ip);
    80004814:	6c88                	ld	a0,24(s1)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	11c080e7          	jalr	284(ra) # 80003932 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000481e:	46e1                	li	a3,24
    80004820:	fb840613          	addi	a2,s0,-72
    80004824:	85ce                	mv	a1,s3
    80004826:	05093503          	ld	a0,80(s2)
    8000482a:	ffffd097          	auipc	ra,0xffffd
    8000482e:	e50080e7          	jalr	-432(ra) # 8000167a <copyout>
    80004832:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004836:	60a6                	ld	ra,72(sp)
    80004838:	6406                	ld	s0,64(sp)
    8000483a:	74e2                	ld	s1,56(sp)
    8000483c:	7942                	ld	s2,48(sp)
    8000483e:	79a2                	ld	s3,40(sp)
    80004840:	6161                	addi	sp,sp,80
    80004842:	8082                	ret
  return -1;
    80004844:	557d                	li	a0,-1
    80004846:	bfc5                	j	80004836 <filestat+0x60>

0000000080004848 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004848:	7179                	addi	sp,sp,-48
    8000484a:	f406                	sd	ra,40(sp)
    8000484c:	f022                	sd	s0,32(sp)
    8000484e:	ec26                	sd	s1,24(sp)
    80004850:	e84a                	sd	s2,16(sp)
    80004852:	e44e                	sd	s3,8(sp)
    80004854:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004856:	00854783          	lbu	a5,8(a0)
    8000485a:	c3d5                	beqz	a5,800048fe <fileread+0xb6>
    8000485c:	84aa                	mv	s1,a0
    8000485e:	89ae                	mv	s3,a1
    80004860:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004862:	411c                	lw	a5,0(a0)
    80004864:	4705                	li	a4,1
    80004866:	04e78963          	beq	a5,a4,800048b8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000486a:	470d                	li	a4,3
    8000486c:	04e78d63          	beq	a5,a4,800048c6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004870:	4709                	li	a4,2
    80004872:	06e79e63          	bne	a5,a4,800048ee <fileread+0xa6>
    ilock(f->ip);
    80004876:	6d08                	ld	a0,24(a0)
    80004878:	fffff097          	auipc	ra,0xfffff
    8000487c:	ff8080e7          	jalr	-8(ra) # 80003870 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004880:	874a                	mv	a4,s2
    80004882:	5094                	lw	a3,32(s1)
    80004884:	864e                	mv	a2,s3
    80004886:	4585                	li	a1,1
    80004888:	6c88                	ld	a0,24(s1)
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	29a080e7          	jalr	666(ra) # 80003b24 <readi>
    80004892:	892a                	mv	s2,a0
    80004894:	00a05563          	blez	a0,8000489e <fileread+0x56>
      f->off += r;
    80004898:	509c                	lw	a5,32(s1)
    8000489a:	9fa9                	addw	a5,a5,a0
    8000489c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000489e:	6c88                	ld	a0,24(s1)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	092080e7          	jalr	146(ra) # 80003932 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048a8:	854a                	mv	a0,s2
    800048aa:	70a2                	ld	ra,40(sp)
    800048ac:	7402                	ld	s0,32(sp)
    800048ae:	64e2                	ld	s1,24(sp)
    800048b0:	6942                	ld	s2,16(sp)
    800048b2:	69a2                	ld	s3,8(sp)
    800048b4:	6145                	addi	sp,sp,48
    800048b6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048b8:	6908                	ld	a0,16(a0)
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	3c8080e7          	jalr	968(ra) # 80004c82 <piperead>
    800048c2:	892a                	mv	s2,a0
    800048c4:	b7d5                	j	800048a8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048c6:	02451783          	lh	a5,36(a0)
    800048ca:	03079693          	slli	a3,a5,0x30
    800048ce:	92c1                	srli	a3,a3,0x30
    800048d0:	4725                	li	a4,9
    800048d2:	02d76863          	bltu	a4,a3,80004902 <fileread+0xba>
    800048d6:	0792                	slli	a5,a5,0x4
    800048d8:	0001d717          	auipc	a4,0x1d
    800048dc:	a4070713          	addi	a4,a4,-1472 # 80021318 <devsw>
    800048e0:	97ba                	add	a5,a5,a4
    800048e2:	639c                	ld	a5,0(a5)
    800048e4:	c38d                	beqz	a5,80004906 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048e6:	4505                	li	a0,1
    800048e8:	9782                	jalr	a5
    800048ea:	892a                	mv	s2,a0
    800048ec:	bf75                	j	800048a8 <fileread+0x60>
    panic("fileread");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	dda50513          	addi	a0,a0,-550 # 800086c8 <syscalls+0x268>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c48080e7          	jalr	-952(ra) # 8000053e <panic>
    return -1;
    800048fe:	597d                	li	s2,-1
    80004900:	b765                	j	800048a8 <fileread+0x60>
      return -1;
    80004902:	597d                	li	s2,-1
    80004904:	b755                	j	800048a8 <fileread+0x60>
    80004906:	597d                	li	s2,-1
    80004908:	b745                	j	800048a8 <fileread+0x60>

000000008000490a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000490a:	715d                	addi	sp,sp,-80
    8000490c:	e486                	sd	ra,72(sp)
    8000490e:	e0a2                	sd	s0,64(sp)
    80004910:	fc26                	sd	s1,56(sp)
    80004912:	f84a                	sd	s2,48(sp)
    80004914:	f44e                	sd	s3,40(sp)
    80004916:	f052                	sd	s4,32(sp)
    80004918:	ec56                	sd	s5,24(sp)
    8000491a:	e85a                	sd	s6,16(sp)
    8000491c:	e45e                	sd	s7,8(sp)
    8000491e:	e062                	sd	s8,0(sp)
    80004920:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004922:	00954783          	lbu	a5,9(a0)
    80004926:	10078663          	beqz	a5,80004a32 <filewrite+0x128>
    8000492a:	892a                	mv	s2,a0
    8000492c:	8aae                	mv	s5,a1
    8000492e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004930:	411c                	lw	a5,0(a0)
    80004932:	4705                	li	a4,1
    80004934:	02e78263          	beq	a5,a4,80004958 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004938:	470d                	li	a4,3
    8000493a:	02e78663          	beq	a5,a4,80004966 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000493e:	4709                	li	a4,2
    80004940:	0ee79163          	bne	a5,a4,80004a22 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004944:	0ac05d63          	blez	a2,800049fe <filewrite+0xf4>
    int i = 0;
    80004948:	4981                	li	s3,0
    8000494a:	6b05                	lui	s6,0x1
    8000494c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004950:	6b85                	lui	s7,0x1
    80004952:	c00b8b9b          	addiw	s7,s7,-1024
    80004956:	a861                	j	800049ee <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004958:	6908                	ld	a0,16(a0)
    8000495a:	00000097          	auipc	ra,0x0
    8000495e:	22e080e7          	jalr	558(ra) # 80004b88 <pipewrite>
    80004962:	8a2a                	mv	s4,a0
    80004964:	a045                	j	80004a04 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004966:	02451783          	lh	a5,36(a0)
    8000496a:	03079693          	slli	a3,a5,0x30
    8000496e:	92c1                	srli	a3,a3,0x30
    80004970:	4725                	li	a4,9
    80004972:	0cd76263          	bltu	a4,a3,80004a36 <filewrite+0x12c>
    80004976:	0792                	slli	a5,a5,0x4
    80004978:	0001d717          	auipc	a4,0x1d
    8000497c:	9a070713          	addi	a4,a4,-1632 # 80021318 <devsw>
    80004980:	97ba                	add	a5,a5,a4
    80004982:	679c                	ld	a5,8(a5)
    80004984:	cbdd                	beqz	a5,80004a3a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004986:	4505                	li	a0,1
    80004988:	9782                	jalr	a5
    8000498a:	8a2a                	mv	s4,a0
    8000498c:	a8a5                	j	80004a04 <filewrite+0xfa>
    8000498e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004992:	00000097          	auipc	ra,0x0
    80004996:	8b0080e7          	jalr	-1872(ra) # 80004242 <begin_op>
      ilock(f->ip);
    8000499a:	01893503          	ld	a0,24(s2)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	ed2080e7          	jalr	-302(ra) # 80003870 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049a6:	8762                	mv	a4,s8
    800049a8:	02092683          	lw	a3,32(s2)
    800049ac:	01598633          	add	a2,s3,s5
    800049b0:	4585                	li	a1,1
    800049b2:	01893503          	ld	a0,24(s2)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	266080e7          	jalr	614(ra) # 80003c1c <writei>
    800049be:	84aa                	mv	s1,a0
    800049c0:	00a05763          	blez	a0,800049ce <filewrite+0xc4>
        f->off += r;
    800049c4:	02092783          	lw	a5,32(s2)
    800049c8:	9fa9                	addw	a5,a5,a0
    800049ca:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049ce:	01893503          	ld	a0,24(s2)
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	f60080e7          	jalr	-160(ra) # 80003932 <iunlock>
      end_op();
    800049da:	00000097          	auipc	ra,0x0
    800049de:	8e8080e7          	jalr	-1816(ra) # 800042c2 <end_op>

      if(r != n1){
    800049e2:	009c1f63          	bne	s8,s1,80004a00 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049e6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049ea:	0149db63          	bge	s3,s4,80004a00 <filewrite+0xf6>
      int n1 = n - i;
    800049ee:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049f2:	84be                	mv	s1,a5
    800049f4:	2781                	sext.w	a5,a5
    800049f6:	f8fb5ce3          	bge	s6,a5,8000498e <filewrite+0x84>
    800049fa:	84de                	mv	s1,s7
    800049fc:	bf49                	j	8000498e <filewrite+0x84>
    int i = 0;
    800049fe:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a00:	013a1f63          	bne	s4,s3,80004a1e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a04:	8552                	mv	a0,s4
    80004a06:	60a6                	ld	ra,72(sp)
    80004a08:	6406                	ld	s0,64(sp)
    80004a0a:	74e2                	ld	s1,56(sp)
    80004a0c:	7942                	ld	s2,48(sp)
    80004a0e:	79a2                	ld	s3,40(sp)
    80004a10:	7a02                	ld	s4,32(sp)
    80004a12:	6ae2                	ld	s5,24(sp)
    80004a14:	6b42                	ld	s6,16(sp)
    80004a16:	6ba2                	ld	s7,8(sp)
    80004a18:	6c02                	ld	s8,0(sp)
    80004a1a:	6161                	addi	sp,sp,80
    80004a1c:	8082                	ret
    ret = (i == n ? n : -1);
    80004a1e:	5a7d                	li	s4,-1
    80004a20:	b7d5                	j	80004a04 <filewrite+0xfa>
    panic("filewrite");
    80004a22:	00004517          	auipc	a0,0x4
    80004a26:	cb650513          	addi	a0,a0,-842 # 800086d8 <syscalls+0x278>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
    return -1;
    80004a32:	5a7d                	li	s4,-1
    80004a34:	bfc1                	j	80004a04 <filewrite+0xfa>
      return -1;
    80004a36:	5a7d                	li	s4,-1
    80004a38:	b7f1                	j	80004a04 <filewrite+0xfa>
    80004a3a:	5a7d                	li	s4,-1
    80004a3c:	b7e1                	j	80004a04 <filewrite+0xfa>

0000000080004a3e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a3e:	7179                	addi	sp,sp,-48
    80004a40:	f406                	sd	ra,40(sp)
    80004a42:	f022                	sd	s0,32(sp)
    80004a44:	ec26                	sd	s1,24(sp)
    80004a46:	e84a                	sd	s2,16(sp)
    80004a48:	e44e                	sd	s3,8(sp)
    80004a4a:	e052                	sd	s4,0(sp)
    80004a4c:	1800                	addi	s0,sp,48
    80004a4e:	84aa                	mv	s1,a0
    80004a50:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a52:	0005b023          	sd	zero,0(a1)
    80004a56:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	bf8080e7          	jalr	-1032(ra) # 80004652 <filealloc>
    80004a62:	e088                	sd	a0,0(s1)
    80004a64:	c551                	beqz	a0,80004af0 <pipealloc+0xb2>
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	bec080e7          	jalr	-1044(ra) # 80004652 <filealloc>
    80004a6e:	00aa3023          	sd	a0,0(s4)
    80004a72:	c92d                	beqz	a0,80004ae4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	080080e7          	jalr	128(ra) # 80000af4 <kalloc>
    80004a7c:	892a                	mv	s2,a0
    80004a7e:	c125                	beqz	a0,80004ade <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a80:	4985                	li	s3,1
    80004a82:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a86:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a8a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a8e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a92:	00004597          	auipc	a1,0x4
    80004a96:	c5658593          	addi	a1,a1,-938 # 800086e8 <syscalls+0x288>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	0ba080e7          	jalr	186(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004aa2:	609c                	ld	a5,0(s1)
    80004aa4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aa8:	609c                	ld	a5,0(s1)
    80004aaa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aae:	609c                	ld	a5,0(s1)
    80004ab0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ab4:	609c                	ld	a5,0(s1)
    80004ab6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aba:	000a3783          	ld	a5,0(s4)
    80004abe:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ac2:	000a3783          	ld	a5,0(s4)
    80004ac6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aca:	000a3783          	ld	a5,0(s4)
    80004ace:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ad2:	000a3783          	ld	a5,0(s4)
    80004ad6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ada:	4501                	li	a0,0
    80004adc:	a025                	j	80004b04 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ade:	6088                	ld	a0,0(s1)
    80004ae0:	e501                	bnez	a0,80004ae8 <pipealloc+0xaa>
    80004ae2:	a039                	j	80004af0 <pipealloc+0xb2>
    80004ae4:	6088                	ld	a0,0(s1)
    80004ae6:	c51d                	beqz	a0,80004b14 <pipealloc+0xd6>
    fileclose(*f0);
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	c26080e7          	jalr	-986(ra) # 8000470e <fileclose>
  if(*f1)
    80004af0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004af4:	557d                	li	a0,-1
  if(*f1)
    80004af6:	c799                	beqz	a5,80004b04 <pipealloc+0xc6>
    fileclose(*f1);
    80004af8:	853e                	mv	a0,a5
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	c14080e7          	jalr	-1004(ra) # 8000470e <fileclose>
  return -1;
    80004b02:	557d                	li	a0,-1
}
    80004b04:	70a2                	ld	ra,40(sp)
    80004b06:	7402                	ld	s0,32(sp)
    80004b08:	64e2                	ld	s1,24(sp)
    80004b0a:	6942                	ld	s2,16(sp)
    80004b0c:	69a2                	ld	s3,8(sp)
    80004b0e:	6a02                	ld	s4,0(sp)
    80004b10:	6145                	addi	sp,sp,48
    80004b12:	8082                	ret
  return -1;
    80004b14:	557d                	li	a0,-1
    80004b16:	b7fd                	j	80004b04 <pipealloc+0xc6>

0000000080004b18 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b18:	1101                	addi	sp,sp,-32
    80004b1a:	ec06                	sd	ra,24(sp)
    80004b1c:	e822                	sd	s0,16(sp)
    80004b1e:	e426                	sd	s1,8(sp)
    80004b20:	e04a                	sd	s2,0(sp)
    80004b22:	1000                	addi	s0,sp,32
    80004b24:	84aa                	mv	s1,a0
    80004b26:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	0bc080e7          	jalr	188(ra) # 80000be4 <acquire>
  if(writable){
    80004b30:	02090d63          	beqz	s2,80004b6a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b34:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b38:	21848513          	addi	a0,s1,536
    80004b3c:	ffffe097          	auipc	ra,0xffffe
    80004b40:	856080e7          	jalr	-1962(ra) # 80002392 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b44:	2204b783          	ld	a5,544(s1)
    80004b48:	eb95                	bnez	a5,80004b7c <pipeclose+0x64>
    release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	14c080e7          	jalr	332(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	ea2080e7          	jalr	-350(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b5e:	60e2                	ld	ra,24(sp)
    80004b60:	6442                	ld	s0,16(sp)
    80004b62:	64a2                	ld	s1,8(sp)
    80004b64:	6902                	ld	s2,0(sp)
    80004b66:	6105                	addi	sp,sp,32
    80004b68:	8082                	ret
    pi->readopen = 0;
    80004b6a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b6e:	21c48513          	addi	a0,s1,540
    80004b72:	ffffe097          	auipc	ra,0xffffe
    80004b76:	820080e7          	jalr	-2016(ra) # 80002392 <wakeup>
    80004b7a:	b7e9                	j	80004b44 <pipeclose+0x2c>
    release(&pi->lock);
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	11a080e7          	jalr	282(ra) # 80000c98 <release>
}
    80004b86:	bfe1                	j	80004b5e <pipeclose+0x46>

0000000080004b88 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b88:	7159                	addi	sp,sp,-112
    80004b8a:	f486                	sd	ra,104(sp)
    80004b8c:	f0a2                	sd	s0,96(sp)
    80004b8e:	eca6                	sd	s1,88(sp)
    80004b90:	e8ca                	sd	s2,80(sp)
    80004b92:	e4ce                	sd	s3,72(sp)
    80004b94:	e0d2                	sd	s4,64(sp)
    80004b96:	fc56                	sd	s5,56(sp)
    80004b98:	f85a                	sd	s6,48(sp)
    80004b9a:	f45e                	sd	s7,40(sp)
    80004b9c:	f062                	sd	s8,32(sp)
    80004b9e:	ec66                	sd	s9,24(sp)
    80004ba0:	1880                	addi	s0,sp,112
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	8aae                	mv	s5,a1
    80004ba6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	e26080e7          	jalr	-474(ra) # 800019ce <myproc>
    80004bb0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	030080e7          	jalr	48(ra) # 80000be4 <acquire>
  while(i < n){
    80004bbc:	0d405163          	blez	s4,80004c7e <pipewrite+0xf6>
    80004bc0:	8ba6                	mv	s7,s1
  int i = 0;
    80004bc2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bc6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bca:	21c48c13          	addi	s8,s1,540
    80004bce:	a08d                	j	80004c30 <pipewrite+0xa8>
      release(&pi->lock);
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	0c6080e7          	jalr	198(ra) # 80000c98 <release>
      return -1;
    80004bda:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bdc:	854a                	mv	a0,s2
    80004bde:	70a6                	ld	ra,104(sp)
    80004be0:	7406                	ld	s0,96(sp)
    80004be2:	64e6                	ld	s1,88(sp)
    80004be4:	6946                	ld	s2,80(sp)
    80004be6:	69a6                	ld	s3,72(sp)
    80004be8:	6a06                	ld	s4,64(sp)
    80004bea:	7ae2                	ld	s5,56(sp)
    80004bec:	7b42                	ld	s6,48(sp)
    80004bee:	7ba2                	ld	s7,40(sp)
    80004bf0:	7c02                	ld	s8,32(sp)
    80004bf2:	6ce2                	ld	s9,24(sp)
    80004bf4:	6165                	addi	sp,sp,112
    80004bf6:	8082                	ret
      wakeup(&pi->nread);
    80004bf8:	8566                	mv	a0,s9
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	798080e7          	jalr	1944(ra) # 80002392 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c02:	85de                	mv	a1,s7
    80004c04:	8562                	mv	a0,s8
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	600080e7          	jalr	1536(ra) # 80002206 <sleep>
    80004c0e:	a839                	j	80004c2c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c10:	21c4a783          	lw	a5,540(s1)
    80004c14:	0017871b          	addiw	a4,a5,1
    80004c18:	20e4ae23          	sw	a4,540(s1)
    80004c1c:	1ff7f793          	andi	a5,a5,511
    80004c20:	97a6                	add	a5,a5,s1
    80004c22:	f9f44703          	lbu	a4,-97(s0)
    80004c26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c2a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c2c:	03495d63          	bge	s2,s4,80004c66 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c30:	2204a783          	lw	a5,544(s1)
    80004c34:	dfd1                	beqz	a5,80004bd0 <pipewrite+0x48>
    80004c36:	0289a783          	lw	a5,40(s3)
    80004c3a:	fbd9                	bnez	a5,80004bd0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c3c:	2184a783          	lw	a5,536(s1)
    80004c40:	21c4a703          	lw	a4,540(s1)
    80004c44:	2007879b          	addiw	a5,a5,512
    80004c48:	faf708e3          	beq	a4,a5,80004bf8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c4c:	4685                	li	a3,1
    80004c4e:	01590633          	add	a2,s2,s5
    80004c52:	f9f40593          	addi	a1,s0,-97
    80004c56:	0509b503          	ld	a0,80(s3)
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	aac080e7          	jalr	-1364(ra) # 80001706 <copyin>
    80004c62:	fb6517e3          	bne	a0,s6,80004c10 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c66:	21848513          	addi	a0,s1,536
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	728080e7          	jalr	1832(ra) # 80002392 <wakeup>
  release(&pi->lock);
    80004c72:	8526                	mv	a0,s1
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
  return i;
    80004c7c:	b785                	j	80004bdc <pipewrite+0x54>
  int i = 0;
    80004c7e:	4901                	li	s2,0
    80004c80:	b7dd                	j	80004c66 <pipewrite+0xde>

0000000080004c82 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c82:	715d                	addi	sp,sp,-80
    80004c84:	e486                	sd	ra,72(sp)
    80004c86:	e0a2                	sd	s0,64(sp)
    80004c88:	fc26                	sd	s1,56(sp)
    80004c8a:	f84a                	sd	s2,48(sp)
    80004c8c:	f44e                	sd	s3,40(sp)
    80004c8e:	f052                	sd	s4,32(sp)
    80004c90:	ec56                	sd	s5,24(sp)
    80004c92:	e85a                	sd	s6,16(sp)
    80004c94:	0880                	addi	s0,sp,80
    80004c96:	84aa                	mv	s1,a0
    80004c98:	892e                	mv	s2,a1
    80004c9a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	d32080e7          	jalr	-718(ra) # 800019ce <myproc>
    80004ca4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ca6:	8b26                	mv	s6,s1
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	f3a080e7          	jalr	-198(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb2:	2184a703          	lw	a4,536(s1)
    80004cb6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cbe:	02f71463          	bne	a4,a5,80004ce6 <piperead+0x64>
    80004cc2:	2244a783          	lw	a5,548(s1)
    80004cc6:	c385                	beqz	a5,80004ce6 <piperead+0x64>
    if(pr->killed){
    80004cc8:	028a2783          	lw	a5,40(s4)
    80004ccc:	ebc1                	bnez	a5,80004d5c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cce:	85da                	mv	a1,s6
    80004cd0:	854e                	mv	a0,s3
    80004cd2:	ffffd097          	auipc	ra,0xffffd
    80004cd6:	534080e7          	jalr	1332(ra) # 80002206 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cda:	2184a703          	lw	a4,536(s1)
    80004cde:	21c4a783          	lw	a5,540(s1)
    80004ce2:	fef700e3          	beq	a4,a5,80004cc2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce6:	09505263          	blez	s5,80004d6a <piperead+0xe8>
    80004cea:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cec:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cee:	2184a783          	lw	a5,536(s1)
    80004cf2:	21c4a703          	lw	a4,540(s1)
    80004cf6:	02f70d63          	beq	a4,a5,80004d30 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cfa:	0017871b          	addiw	a4,a5,1
    80004cfe:	20e4ac23          	sw	a4,536(s1)
    80004d02:	1ff7f793          	andi	a5,a5,511
    80004d06:	97a6                	add	a5,a5,s1
    80004d08:	0187c783          	lbu	a5,24(a5)
    80004d0c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d10:	4685                	li	a3,1
    80004d12:	fbf40613          	addi	a2,s0,-65
    80004d16:	85ca                	mv	a1,s2
    80004d18:	050a3503          	ld	a0,80(s4)
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	95e080e7          	jalr	-1698(ra) # 8000167a <copyout>
    80004d24:	01650663          	beq	a0,s6,80004d30 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d28:	2985                	addiw	s3,s3,1
    80004d2a:	0905                	addi	s2,s2,1
    80004d2c:	fd3a91e3          	bne	s5,s3,80004cee <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d30:	21c48513          	addi	a0,s1,540
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	65e080e7          	jalr	1630(ra) # 80002392 <wakeup>
  release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
  return i;
}
    80004d46:	854e                	mv	a0,s3
    80004d48:	60a6                	ld	ra,72(sp)
    80004d4a:	6406                	ld	s0,64(sp)
    80004d4c:	74e2                	ld	s1,56(sp)
    80004d4e:	7942                	ld	s2,48(sp)
    80004d50:	79a2                	ld	s3,40(sp)
    80004d52:	7a02                	ld	s4,32(sp)
    80004d54:	6ae2                	ld	s5,24(sp)
    80004d56:	6b42                	ld	s6,16(sp)
    80004d58:	6161                	addi	sp,sp,80
    80004d5a:	8082                	ret
      release(&pi->lock);
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	f3a080e7          	jalr	-198(ra) # 80000c98 <release>
      return -1;
    80004d66:	59fd                	li	s3,-1
    80004d68:	bff9                	j	80004d46 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d6a:	4981                	li	s3,0
    80004d6c:	b7d1                	j	80004d30 <piperead+0xae>

0000000080004d6e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d6e:	df010113          	addi	sp,sp,-528
    80004d72:	20113423          	sd	ra,520(sp)
    80004d76:	20813023          	sd	s0,512(sp)
    80004d7a:	ffa6                	sd	s1,504(sp)
    80004d7c:	fbca                	sd	s2,496(sp)
    80004d7e:	f7ce                	sd	s3,488(sp)
    80004d80:	f3d2                	sd	s4,480(sp)
    80004d82:	efd6                	sd	s5,472(sp)
    80004d84:	ebda                	sd	s6,464(sp)
    80004d86:	e7de                	sd	s7,456(sp)
    80004d88:	e3e2                	sd	s8,448(sp)
    80004d8a:	ff66                	sd	s9,440(sp)
    80004d8c:	fb6a                	sd	s10,432(sp)
    80004d8e:	f76e                	sd	s11,424(sp)
    80004d90:	0c00                	addi	s0,sp,528
    80004d92:	84aa                	mv	s1,a0
    80004d94:	dea43c23          	sd	a0,-520(s0)
    80004d98:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	c32080e7          	jalr	-974(ra) # 800019ce <myproc>
    80004da4:	892a                	mv	s2,a0

  begin_op();
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	49c080e7          	jalr	1180(ra) # 80004242 <begin_op>

  if((ip = namei(path)) == 0){
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	276080e7          	jalr	630(ra) # 80004026 <namei>
    80004db8:	c92d                	beqz	a0,80004e2a <exec+0xbc>
    80004dba:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	ab4080e7          	jalr	-1356(ra) # 80003870 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dc4:	04000713          	li	a4,64
    80004dc8:	4681                	li	a3,0
    80004dca:	e5040613          	addi	a2,s0,-432
    80004dce:	4581                	li	a1,0
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	d52080e7          	jalr	-686(ra) # 80003b24 <readi>
    80004dda:	04000793          	li	a5,64
    80004dde:	00f51a63          	bne	a0,a5,80004df2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004de2:	e5042703          	lw	a4,-432(s0)
    80004de6:	464c47b7          	lui	a5,0x464c4
    80004dea:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dee:	04f70463          	beq	a4,a5,80004e36 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004df2:	8526                	mv	a0,s1
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	cde080e7          	jalr	-802(ra) # 80003ad2 <iunlockput>
    end_op();
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	4c6080e7          	jalr	1222(ra) # 800042c2 <end_op>
  }
  return -1;
    80004e04:	557d                	li	a0,-1
}
    80004e06:	20813083          	ld	ra,520(sp)
    80004e0a:	20013403          	ld	s0,512(sp)
    80004e0e:	74fe                	ld	s1,504(sp)
    80004e10:	795e                	ld	s2,496(sp)
    80004e12:	79be                	ld	s3,488(sp)
    80004e14:	7a1e                	ld	s4,480(sp)
    80004e16:	6afe                	ld	s5,472(sp)
    80004e18:	6b5e                	ld	s6,464(sp)
    80004e1a:	6bbe                	ld	s7,456(sp)
    80004e1c:	6c1e                	ld	s8,448(sp)
    80004e1e:	7cfa                	ld	s9,440(sp)
    80004e20:	7d5a                	ld	s10,432(sp)
    80004e22:	7dba                	ld	s11,424(sp)
    80004e24:	21010113          	addi	sp,sp,528
    80004e28:	8082                	ret
    end_op();
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	498080e7          	jalr	1176(ra) # 800042c2 <end_op>
    return -1;
    80004e32:	557d                	li	a0,-1
    80004e34:	bfc9                	j	80004e06 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e36:	854a                	mv	a0,s2
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	c5a080e7          	jalr	-934(ra) # 80001a92 <proc_pagetable>
    80004e40:	8baa                	mv	s7,a0
    80004e42:	d945                	beqz	a0,80004df2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e44:	e7042983          	lw	s3,-400(s0)
    80004e48:	e8845783          	lhu	a5,-376(s0)
    80004e4c:	c7ad                	beqz	a5,80004eb6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e4e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e50:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e52:	6c85                	lui	s9,0x1
    80004e54:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e58:	def43823          	sd	a5,-528(s0)
    80004e5c:	a42d                	j	80005086 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e5e:	00004517          	auipc	a0,0x4
    80004e62:	89250513          	addi	a0,a0,-1902 # 800086f0 <syscalls+0x290>
    80004e66:	ffffb097          	auipc	ra,0xffffb
    80004e6a:	6d8080e7          	jalr	1752(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e6e:	8756                	mv	a4,s5
    80004e70:	012d86bb          	addw	a3,s11,s2
    80004e74:	4581                	li	a1,0
    80004e76:	8526                	mv	a0,s1
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	cac080e7          	jalr	-852(ra) # 80003b24 <readi>
    80004e80:	2501                	sext.w	a0,a0
    80004e82:	1aaa9963          	bne	s5,a0,80005034 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e86:	6785                	lui	a5,0x1
    80004e88:	0127893b          	addw	s2,a5,s2
    80004e8c:	77fd                	lui	a5,0xfffff
    80004e8e:	01478a3b          	addw	s4,a5,s4
    80004e92:	1f897163          	bgeu	s2,s8,80005074 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e96:	02091593          	slli	a1,s2,0x20
    80004e9a:	9181                	srli	a1,a1,0x20
    80004e9c:	95ea                	add	a1,a1,s10
    80004e9e:	855e                	mv	a0,s7
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	1d6080e7          	jalr	470(ra) # 80001076 <walkaddr>
    80004ea8:	862a                	mv	a2,a0
    if(pa == 0)
    80004eaa:	d955                	beqz	a0,80004e5e <exec+0xf0>
      n = PGSIZE;
    80004eac:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004eae:	fd9a70e3          	bgeu	s4,s9,80004e6e <exec+0x100>
      n = sz - i;
    80004eb2:	8ad2                	mv	s5,s4
    80004eb4:	bf6d                	j	80004e6e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eb6:	4901                	li	s2,0
  iunlockput(ip);
    80004eb8:	8526                	mv	a0,s1
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	c18080e7          	jalr	-1000(ra) # 80003ad2 <iunlockput>
  end_op();
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	400080e7          	jalr	1024(ra) # 800042c2 <end_op>
  p = myproc();
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	b04080e7          	jalr	-1276(ra) # 800019ce <myproc>
    80004ed2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ed4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ed8:	6785                	lui	a5,0x1
    80004eda:	17fd                	addi	a5,a5,-1
    80004edc:	993e                	add	s2,s2,a5
    80004ede:	757d                	lui	a0,0xfffff
    80004ee0:	00a977b3          	and	a5,s2,a0
    80004ee4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ee8:	6609                	lui	a2,0x2
    80004eea:	963e                	add	a2,a2,a5
    80004eec:	85be                	mv	a1,a5
    80004eee:	855e                	mv	a0,s7
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	53a080e7          	jalr	1338(ra) # 8000142a <uvmalloc>
    80004ef8:	8b2a                	mv	s6,a0
  ip = 0;
    80004efa:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004efc:	12050c63          	beqz	a0,80005034 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f00:	75f9                	lui	a1,0xffffe
    80004f02:	95aa                	add	a1,a1,a0
    80004f04:	855e                	mv	a0,s7
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	742080e7          	jalr	1858(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f0e:	7c7d                	lui	s8,0xfffff
    80004f10:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f12:	e0043783          	ld	a5,-512(s0)
    80004f16:	6388                	ld	a0,0(a5)
    80004f18:	c535                	beqz	a0,80004f84 <exec+0x216>
    80004f1a:	e9040993          	addi	s3,s0,-368
    80004f1e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f22:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	f40080e7          	jalr	-192(ra) # 80000e64 <strlen>
    80004f2c:	2505                	addiw	a0,a0,1
    80004f2e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f32:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f36:	13896363          	bltu	s2,s8,8000505c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f3a:	e0043d83          	ld	s11,-512(s0)
    80004f3e:	000dba03          	ld	s4,0(s11)
    80004f42:	8552                	mv	a0,s4
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	f20080e7          	jalr	-224(ra) # 80000e64 <strlen>
    80004f4c:	0015069b          	addiw	a3,a0,1
    80004f50:	8652                	mv	a2,s4
    80004f52:	85ca                	mv	a1,s2
    80004f54:	855e                	mv	a0,s7
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	724080e7          	jalr	1828(ra) # 8000167a <copyout>
    80004f5e:	10054363          	bltz	a0,80005064 <exec+0x2f6>
    ustack[argc] = sp;
    80004f62:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f66:	0485                	addi	s1,s1,1
    80004f68:	008d8793          	addi	a5,s11,8
    80004f6c:	e0f43023          	sd	a5,-512(s0)
    80004f70:	008db503          	ld	a0,8(s11)
    80004f74:	c911                	beqz	a0,80004f88 <exec+0x21a>
    if(argc >= MAXARG)
    80004f76:	09a1                	addi	s3,s3,8
    80004f78:	fb3c96e3          	bne	s9,s3,80004f24 <exec+0x1b6>
  sz = sz1;
    80004f7c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f80:	4481                	li	s1,0
    80004f82:	a84d                	j	80005034 <exec+0x2c6>
  sp = sz;
    80004f84:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f86:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f88:	00349793          	slli	a5,s1,0x3
    80004f8c:	f9040713          	addi	a4,s0,-112
    80004f90:	97ba                	add	a5,a5,a4
    80004f92:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f96:	00148693          	addi	a3,s1,1
    80004f9a:	068e                	slli	a3,a3,0x3
    80004f9c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fa0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fa4:	01897663          	bgeu	s2,s8,80004fb0 <exec+0x242>
  sz = sz1;
    80004fa8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fac:	4481                	li	s1,0
    80004fae:	a059                	j	80005034 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fb0:	e9040613          	addi	a2,s0,-368
    80004fb4:	85ca                	mv	a1,s2
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	ffffc097          	auipc	ra,0xffffc
    80004fbc:	6c2080e7          	jalr	1730(ra) # 8000167a <copyout>
    80004fc0:	0a054663          	bltz	a0,8000506c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fc4:	058ab783          	ld	a5,88(s5)
    80004fc8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fcc:	df843783          	ld	a5,-520(s0)
    80004fd0:	0007c703          	lbu	a4,0(a5)
    80004fd4:	cf11                	beqz	a4,80004ff0 <exec+0x282>
    80004fd6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fd8:	02f00693          	li	a3,47
    80004fdc:	a039                	j	80004fea <exec+0x27c>
      last = s+1;
    80004fde:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fe2:	0785                	addi	a5,a5,1
    80004fe4:	fff7c703          	lbu	a4,-1(a5)
    80004fe8:	c701                	beqz	a4,80004ff0 <exec+0x282>
    if(*s == '/')
    80004fea:	fed71ce3          	bne	a4,a3,80004fe2 <exec+0x274>
    80004fee:	bfc5                	j	80004fde <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ff0:	4641                	li	a2,16
    80004ff2:	df843583          	ld	a1,-520(s0)
    80004ff6:	158a8513          	addi	a0,s5,344
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	e38080e7          	jalr	-456(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005002:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005006:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000500a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000500e:	058ab783          	ld	a5,88(s5)
    80005012:	e6843703          	ld	a4,-408(s0)
    80005016:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005018:	058ab783          	ld	a5,88(s5)
    8000501c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005020:	85ea                	mv	a1,s10
    80005022:	ffffd097          	auipc	ra,0xffffd
    80005026:	b0c080e7          	jalr	-1268(ra) # 80001b2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000502a:	0004851b          	sext.w	a0,s1
    8000502e:	bbe1                	j	80004e06 <exec+0x98>
    80005030:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005034:	e0843583          	ld	a1,-504(s0)
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	af4080e7          	jalr	-1292(ra) # 80001b2e <proc_freepagetable>
  if(ip){
    80005042:	da0498e3          	bnez	s1,80004df2 <exec+0x84>
  return -1;
    80005046:	557d                	li	a0,-1
    80005048:	bb7d                	j	80004e06 <exec+0x98>
    8000504a:	e1243423          	sd	s2,-504(s0)
    8000504e:	b7dd                	j	80005034 <exec+0x2c6>
    80005050:	e1243423          	sd	s2,-504(s0)
    80005054:	b7c5                	j	80005034 <exec+0x2c6>
    80005056:	e1243423          	sd	s2,-504(s0)
    8000505a:	bfe9                	j	80005034 <exec+0x2c6>
  sz = sz1;
    8000505c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005060:	4481                	li	s1,0
    80005062:	bfc9                	j	80005034 <exec+0x2c6>
  sz = sz1;
    80005064:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005068:	4481                	li	s1,0
    8000506a:	b7e9                	j	80005034 <exec+0x2c6>
  sz = sz1;
    8000506c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005070:	4481                	li	s1,0
    80005072:	b7c9                	j	80005034 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005074:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005078:	2b05                	addiw	s6,s6,1
    8000507a:	0389899b          	addiw	s3,s3,56
    8000507e:	e8845783          	lhu	a5,-376(s0)
    80005082:	e2fb5be3          	bge	s6,a5,80004eb8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005086:	2981                	sext.w	s3,s3
    80005088:	03800713          	li	a4,56
    8000508c:	86ce                	mv	a3,s3
    8000508e:	e1840613          	addi	a2,s0,-488
    80005092:	4581                	li	a1,0
    80005094:	8526                	mv	a0,s1
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	a8e080e7          	jalr	-1394(ra) # 80003b24 <readi>
    8000509e:	03800793          	li	a5,56
    800050a2:	f8f517e3          	bne	a0,a5,80005030 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050a6:	e1842783          	lw	a5,-488(s0)
    800050aa:	4705                	li	a4,1
    800050ac:	fce796e3          	bne	a5,a4,80005078 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050b0:	e4043603          	ld	a2,-448(s0)
    800050b4:	e3843783          	ld	a5,-456(s0)
    800050b8:	f8f669e3          	bltu	a2,a5,8000504a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050bc:	e2843783          	ld	a5,-472(s0)
    800050c0:	963e                	add	a2,a2,a5
    800050c2:	f8f667e3          	bltu	a2,a5,80005050 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c6:	85ca                	mv	a1,s2
    800050c8:	855e                	mv	a0,s7
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	360080e7          	jalr	864(ra) # 8000142a <uvmalloc>
    800050d2:	e0a43423          	sd	a0,-504(s0)
    800050d6:	d141                	beqz	a0,80005056 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050d8:	e2843d03          	ld	s10,-472(s0)
    800050dc:	df043783          	ld	a5,-528(s0)
    800050e0:	00fd77b3          	and	a5,s10,a5
    800050e4:	fba1                	bnez	a5,80005034 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050e6:	e2042d83          	lw	s11,-480(s0)
    800050ea:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050ee:	f80c03e3          	beqz	s8,80005074 <exec+0x306>
    800050f2:	8a62                	mv	s4,s8
    800050f4:	4901                	li	s2,0
    800050f6:	b345                	j	80004e96 <exec+0x128>

00000000800050f8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050f8:	7179                	addi	sp,sp,-48
    800050fa:	f406                	sd	ra,40(sp)
    800050fc:	f022                	sd	s0,32(sp)
    800050fe:	ec26                	sd	s1,24(sp)
    80005100:	e84a                	sd	s2,16(sp)
    80005102:	1800                	addi	s0,sp,48
    80005104:	892e                	mv	s2,a1
    80005106:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005108:	fdc40593          	addi	a1,s0,-36
    8000510c:	ffffe097          	auipc	ra,0xffffe
    80005110:	ba6080e7          	jalr	-1114(ra) # 80002cb2 <argint>
    80005114:	04054063          	bltz	a0,80005154 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005118:	fdc42703          	lw	a4,-36(s0)
    8000511c:	47bd                	li	a5,15
    8000511e:	02e7ed63          	bltu	a5,a4,80005158 <argfd+0x60>
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	8ac080e7          	jalr	-1876(ra) # 800019ce <myproc>
    8000512a:	fdc42703          	lw	a4,-36(s0)
    8000512e:	01a70793          	addi	a5,a4,26
    80005132:	078e                	slli	a5,a5,0x3
    80005134:	953e                	add	a0,a0,a5
    80005136:	611c                	ld	a5,0(a0)
    80005138:	c395                	beqz	a5,8000515c <argfd+0x64>
    return -1;
  if(pfd)
    8000513a:	00090463          	beqz	s2,80005142 <argfd+0x4a>
    *pfd = fd;
    8000513e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005142:	4501                	li	a0,0
  if(pf)
    80005144:	c091                	beqz	s1,80005148 <argfd+0x50>
    *pf = f;
    80005146:	e09c                	sd	a5,0(s1)
}
    80005148:	70a2                	ld	ra,40(sp)
    8000514a:	7402                	ld	s0,32(sp)
    8000514c:	64e2                	ld	s1,24(sp)
    8000514e:	6942                	ld	s2,16(sp)
    80005150:	6145                	addi	sp,sp,48
    80005152:	8082                	ret
    return -1;
    80005154:	557d                	li	a0,-1
    80005156:	bfcd                	j	80005148 <argfd+0x50>
    return -1;
    80005158:	557d                	li	a0,-1
    8000515a:	b7fd                	j	80005148 <argfd+0x50>
    8000515c:	557d                	li	a0,-1
    8000515e:	b7ed                	j	80005148 <argfd+0x50>

0000000080005160 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005160:	1101                	addi	sp,sp,-32
    80005162:	ec06                	sd	ra,24(sp)
    80005164:	e822                	sd	s0,16(sp)
    80005166:	e426                	sd	s1,8(sp)
    80005168:	1000                	addi	s0,sp,32
    8000516a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000516c:	ffffd097          	auipc	ra,0xffffd
    80005170:	862080e7          	jalr	-1950(ra) # 800019ce <myproc>
    80005174:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005176:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000517a:	4501                	li	a0,0
    8000517c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000517e:	6398                	ld	a4,0(a5)
    80005180:	cb19                	beqz	a4,80005196 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005182:	2505                	addiw	a0,a0,1
    80005184:	07a1                	addi	a5,a5,8
    80005186:	fed51ce3          	bne	a0,a3,8000517e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000518a:	557d                	li	a0,-1
}
    8000518c:	60e2                	ld	ra,24(sp)
    8000518e:	6442                	ld	s0,16(sp)
    80005190:	64a2                	ld	s1,8(sp)
    80005192:	6105                	addi	sp,sp,32
    80005194:	8082                	ret
      p->ofile[fd] = f;
    80005196:	01a50793          	addi	a5,a0,26
    8000519a:	078e                	slli	a5,a5,0x3
    8000519c:	963e                	add	a2,a2,a5
    8000519e:	e204                	sd	s1,0(a2)
      return fd;
    800051a0:	b7f5                	j	8000518c <fdalloc+0x2c>

00000000800051a2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051a2:	715d                	addi	sp,sp,-80
    800051a4:	e486                	sd	ra,72(sp)
    800051a6:	e0a2                	sd	s0,64(sp)
    800051a8:	fc26                	sd	s1,56(sp)
    800051aa:	f84a                	sd	s2,48(sp)
    800051ac:	f44e                	sd	s3,40(sp)
    800051ae:	f052                	sd	s4,32(sp)
    800051b0:	ec56                	sd	s5,24(sp)
    800051b2:	0880                	addi	s0,sp,80
    800051b4:	89ae                	mv	s3,a1
    800051b6:	8ab2                	mv	s5,a2
    800051b8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ba:	fb040593          	addi	a1,s0,-80
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	e86080e7          	jalr	-378(ra) # 80004044 <nameiparent>
    800051c6:	892a                	mv	s2,a0
    800051c8:	12050f63          	beqz	a0,80005306 <create+0x164>
    return 0;

  ilock(dp);
    800051cc:	ffffe097          	auipc	ra,0xffffe
    800051d0:	6a4080e7          	jalr	1700(ra) # 80003870 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051d4:	4601                	li	a2,0
    800051d6:	fb040593          	addi	a1,s0,-80
    800051da:	854a                	mv	a0,s2
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	b78080e7          	jalr	-1160(ra) # 80003d54 <dirlookup>
    800051e4:	84aa                	mv	s1,a0
    800051e6:	c921                	beqz	a0,80005236 <create+0x94>
    iunlockput(dp);
    800051e8:	854a                	mv	a0,s2
    800051ea:	fffff097          	auipc	ra,0xfffff
    800051ee:	8e8080e7          	jalr	-1816(ra) # 80003ad2 <iunlockput>
    ilock(ip);
    800051f2:	8526                	mv	a0,s1
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	67c080e7          	jalr	1660(ra) # 80003870 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051fc:	2981                	sext.w	s3,s3
    800051fe:	4789                	li	a5,2
    80005200:	02f99463          	bne	s3,a5,80005228 <create+0x86>
    80005204:	0444d783          	lhu	a5,68(s1)
    80005208:	37f9                	addiw	a5,a5,-2
    8000520a:	17c2                	slli	a5,a5,0x30
    8000520c:	93c1                	srli	a5,a5,0x30
    8000520e:	4705                	li	a4,1
    80005210:	00f76c63          	bltu	a4,a5,80005228 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005214:	8526                	mv	a0,s1
    80005216:	60a6                	ld	ra,72(sp)
    80005218:	6406                	ld	s0,64(sp)
    8000521a:	74e2                	ld	s1,56(sp)
    8000521c:	7942                	ld	s2,48(sp)
    8000521e:	79a2                	ld	s3,40(sp)
    80005220:	7a02                	ld	s4,32(sp)
    80005222:	6ae2                	ld	s5,24(sp)
    80005224:	6161                	addi	sp,sp,80
    80005226:	8082                	ret
    iunlockput(ip);
    80005228:	8526                	mv	a0,s1
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	8a8080e7          	jalr	-1880(ra) # 80003ad2 <iunlockput>
    return 0;
    80005232:	4481                	li	s1,0
    80005234:	b7c5                	j	80005214 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005236:	85ce                	mv	a1,s3
    80005238:	00092503          	lw	a0,0(s2)
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	49c080e7          	jalr	1180(ra) # 800036d8 <ialloc>
    80005244:	84aa                	mv	s1,a0
    80005246:	c529                	beqz	a0,80005290 <create+0xee>
  ilock(ip);
    80005248:	ffffe097          	auipc	ra,0xffffe
    8000524c:	628080e7          	jalr	1576(ra) # 80003870 <ilock>
  ip->major = major;
    80005250:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005254:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005258:	4785                	li	a5,1
    8000525a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000525e:	8526                	mv	a0,s1
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	546080e7          	jalr	1350(ra) # 800037a6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005268:	2981                	sext.w	s3,s3
    8000526a:	4785                	li	a5,1
    8000526c:	02f98a63          	beq	s3,a5,800052a0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005270:	40d0                	lw	a2,4(s1)
    80005272:	fb040593          	addi	a1,s0,-80
    80005276:	854a                	mv	a0,s2
    80005278:	fffff097          	auipc	ra,0xfffff
    8000527c:	cec080e7          	jalr	-788(ra) # 80003f64 <dirlink>
    80005280:	06054b63          	bltz	a0,800052f6 <create+0x154>
  iunlockput(dp);
    80005284:	854a                	mv	a0,s2
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	84c080e7          	jalr	-1972(ra) # 80003ad2 <iunlockput>
  return ip;
    8000528e:	b759                	j	80005214 <create+0x72>
    panic("create: ialloc");
    80005290:	00003517          	auipc	a0,0x3
    80005294:	48050513          	addi	a0,a0,1152 # 80008710 <syscalls+0x2b0>
    80005298:	ffffb097          	auipc	ra,0xffffb
    8000529c:	2a6080e7          	jalr	678(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052a0:	04a95783          	lhu	a5,74(s2)
    800052a4:	2785                	addiw	a5,a5,1
    800052a6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052aa:	854a                	mv	a0,s2
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	4fa080e7          	jalr	1274(ra) # 800037a6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052b4:	40d0                	lw	a2,4(s1)
    800052b6:	00003597          	auipc	a1,0x3
    800052ba:	46a58593          	addi	a1,a1,1130 # 80008720 <syscalls+0x2c0>
    800052be:	8526                	mv	a0,s1
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	ca4080e7          	jalr	-860(ra) # 80003f64 <dirlink>
    800052c8:	00054f63          	bltz	a0,800052e6 <create+0x144>
    800052cc:	00492603          	lw	a2,4(s2)
    800052d0:	00003597          	auipc	a1,0x3
    800052d4:	45858593          	addi	a1,a1,1112 # 80008728 <syscalls+0x2c8>
    800052d8:	8526                	mv	a0,s1
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	c8a080e7          	jalr	-886(ra) # 80003f64 <dirlink>
    800052e2:	f80557e3          	bgez	a0,80005270 <create+0xce>
      panic("create dots");
    800052e6:	00003517          	auipc	a0,0x3
    800052ea:	44a50513          	addi	a0,a0,1098 # 80008730 <syscalls+0x2d0>
    800052ee:	ffffb097          	auipc	ra,0xffffb
    800052f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052f6:	00003517          	auipc	a0,0x3
    800052fa:	44a50513          	addi	a0,a0,1098 # 80008740 <syscalls+0x2e0>
    800052fe:	ffffb097          	auipc	ra,0xffffb
    80005302:	240080e7          	jalr	576(ra) # 8000053e <panic>
    return 0;
    80005306:	84aa                	mv	s1,a0
    80005308:	b731                	j	80005214 <create+0x72>

000000008000530a <sys_dup>:
{
    8000530a:	7179                	addi	sp,sp,-48
    8000530c:	f406                	sd	ra,40(sp)
    8000530e:	f022                	sd	s0,32(sp)
    80005310:	ec26                	sd	s1,24(sp)
    80005312:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005314:	fd840613          	addi	a2,s0,-40
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	ddc080e7          	jalr	-548(ra) # 800050f8 <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005326:	02054363          	bltz	a0,8000534c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000532a:	fd843503          	ld	a0,-40(s0)
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	e32080e7          	jalr	-462(ra) # 80005160 <fdalloc>
    80005336:	84aa                	mv	s1,a0
    return -1;
    80005338:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000533a:	00054963          	bltz	a0,8000534c <sys_dup+0x42>
  filedup(f);
    8000533e:	fd843503          	ld	a0,-40(s0)
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	37a080e7          	jalr	890(ra) # 800046bc <filedup>
  return fd;
    8000534a:	87a6                	mv	a5,s1
}
    8000534c:	853e                	mv	a0,a5
    8000534e:	70a2                	ld	ra,40(sp)
    80005350:	7402                	ld	s0,32(sp)
    80005352:	64e2                	ld	s1,24(sp)
    80005354:	6145                	addi	sp,sp,48
    80005356:	8082                	ret

0000000080005358 <sys_read>:
{
    80005358:	7179                	addi	sp,sp,-48
    8000535a:	f406                	sd	ra,40(sp)
    8000535c:	f022                	sd	s0,32(sp)
    8000535e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	fe840613          	addi	a2,s0,-24
    80005364:	4581                	li	a1,0
    80005366:	4501                	li	a0,0
    80005368:	00000097          	auipc	ra,0x0
    8000536c:	d90080e7          	jalr	-624(ra) # 800050f8 <argfd>
    return -1;
    80005370:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005372:	04054163          	bltz	a0,800053b4 <sys_read+0x5c>
    80005376:	fe440593          	addi	a1,s0,-28
    8000537a:	4509                	li	a0,2
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	936080e7          	jalr	-1738(ra) # 80002cb2 <argint>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	02054763          	bltz	a0,800053b4 <sys_read+0x5c>
    8000538a:	fd840593          	addi	a1,s0,-40
    8000538e:	4505                	li	a0,1
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	944080e7          	jalr	-1724(ra) # 80002cd4 <argaddr>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	00054d63          	bltz	a0,800053b4 <sys_read+0x5c>
  return fileread(f, p, n);
    8000539e:	fe442603          	lw	a2,-28(s0)
    800053a2:	fd843583          	ld	a1,-40(s0)
    800053a6:	fe843503          	ld	a0,-24(s0)
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	49e080e7          	jalr	1182(ra) # 80004848 <fileread>
    800053b2:	87aa                	mv	a5,a0
}
    800053b4:	853e                	mv	a0,a5
    800053b6:	70a2                	ld	ra,40(sp)
    800053b8:	7402                	ld	s0,32(sp)
    800053ba:	6145                	addi	sp,sp,48
    800053bc:	8082                	ret

00000000800053be <sys_write>:
{
    800053be:	7179                	addi	sp,sp,-48
    800053c0:	f406                	sd	ra,40(sp)
    800053c2:	f022                	sd	s0,32(sp)
    800053c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c6:	fe840613          	addi	a2,s0,-24
    800053ca:	4581                	li	a1,0
    800053cc:	4501                	li	a0,0
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	d2a080e7          	jalr	-726(ra) # 800050f8 <argfd>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d8:	04054163          	bltz	a0,8000541a <sys_write+0x5c>
    800053dc:	fe440593          	addi	a1,s0,-28
    800053e0:	4509                	li	a0,2
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	8d0080e7          	jalr	-1840(ra) # 80002cb2 <argint>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	02054763          	bltz	a0,8000541a <sys_write+0x5c>
    800053f0:	fd840593          	addi	a1,s0,-40
    800053f4:	4505                	li	a0,1
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	8de080e7          	jalr	-1826(ra) # 80002cd4 <argaddr>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005400:	00054d63          	bltz	a0,8000541a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005404:	fe442603          	lw	a2,-28(s0)
    80005408:	fd843583          	ld	a1,-40(s0)
    8000540c:	fe843503          	ld	a0,-24(s0)
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	4fa080e7          	jalr	1274(ra) # 8000490a <filewrite>
    80005418:	87aa                	mv	a5,a0
}
    8000541a:	853e                	mv	a0,a5
    8000541c:	70a2                	ld	ra,40(sp)
    8000541e:	7402                	ld	s0,32(sp)
    80005420:	6145                	addi	sp,sp,48
    80005422:	8082                	ret

0000000080005424 <sys_close>:
{
    80005424:	1101                	addi	sp,sp,-32
    80005426:	ec06                	sd	ra,24(sp)
    80005428:	e822                	sd	s0,16(sp)
    8000542a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000542c:	fe040613          	addi	a2,s0,-32
    80005430:	fec40593          	addi	a1,s0,-20
    80005434:	4501                	li	a0,0
    80005436:	00000097          	auipc	ra,0x0
    8000543a:	cc2080e7          	jalr	-830(ra) # 800050f8 <argfd>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005440:	02054463          	bltz	a0,80005468 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005444:	ffffc097          	auipc	ra,0xffffc
    80005448:	58a080e7          	jalr	1418(ra) # 800019ce <myproc>
    8000544c:	fec42783          	lw	a5,-20(s0)
    80005450:	07e9                	addi	a5,a5,26
    80005452:	078e                	slli	a5,a5,0x3
    80005454:	97aa                	add	a5,a5,a0
    80005456:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000545a:	fe043503          	ld	a0,-32(s0)
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	2b0080e7          	jalr	688(ra) # 8000470e <fileclose>
  return 0;
    80005466:	4781                	li	a5,0
}
    80005468:	853e                	mv	a0,a5
    8000546a:	60e2                	ld	ra,24(sp)
    8000546c:	6442                	ld	s0,16(sp)
    8000546e:	6105                	addi	sp,sp,32
    80005470:	8082                	ret

0000000080005472 <sys_fstat>:
{
    80005472:	1101                	addi	sp,sp,-32
    80005474:	ec06                	sd	ra,24(sp)
    80005476:	e822                	sd	s0,16(sp)
    80005478:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	c76080e7          	jalr	-906(ra) # 800050f8 <argfd>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000548c:	02054563          	bltz	a0,800054b6 <sys_fstat+0x44>
    80005490:	fe040593          	addi	a1,s0,-32
    80005494:	4505                	li	a0,1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	83e080e7          	jalr	-1986(ra) # 80002cd4 <argaddr>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a0:	00054b63          	bltz	a0,800054b6 <sys_fstat+0x44>
  return filestat(f, st);
    800054a4:	fe043583          	ld	a1,-32(s0)
    800054a8:	fe843503          	ld	a0,-24(s0)
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	32a080e7          	jalr	810(ra) # 800047d6 <filestat>
    800054b4:	87aa                	mv	a5,a0
}
    800054b6:	853e                	mv	a0,a5
    800054b8:	60e2                	ld	ra,24(sp)
    800054ba:	6442                	ld	s0,16(sp)
    800054bc:	6105                	addi	sp,sp,32
    800054be:	8082                	ret

00000000800054c0 <sys_link>:
{
    800054c0:	7169                	addi	sp,sp,-304
    800054c2:	f606                	sd	ra,296(sp)
    800054c4:	f222                	sd	s0,288(sp)
    800054c6:	ee26                	sd	s1,280(sp)
    800054c8:	ea4a                	sd	s2,272(sp)
    800054ca:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054cc:	08000613          	li	a2,128
    800054d0:	ed040593          	addi	a1,s0,-304
    800054d4:	4501                	li	a0,0
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	820080e7          	jalr	-2016(ra) # 80002cf6 <argstr>
    return -1;
    800054de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e0:	10054e63          	bltz	a0,800055fc <sys_link+0x13c>
    800054e4:	08000613          	li	a2,128
    800054e8:	f5040593          	addi	a1,s0,-176
    800054ec:	4505                	li	a0,1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	808080e7          	jalr	-2040(ra) # 80002cf6 <argstr>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f8:	10054263          	bltz	a0,800055fc <sys_link+0x13c>
  begin_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	d46080e7          	jalr	-698(ra) # 80004242 <begin_op>
  if((ip = namei(old)) == 0){
    80005504:	ed040513          	addi	a0,s0,-304
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	b1e080e7          	jalr	-1250(ra) # 80004026 <namei>
    80005510:	84aa                	mv	s1,a0
    80005512:	c551                	beqz	a0,8000559e <sys_link+0xde>
  ilock(ip);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	35c080e7          	jalr	860(ra) # 80003870 <ilock>
  if(ip->type == T_DIR){
    8000551c:	04449703          	lh	a4,68(s1)
    80005520:	4785                	li	a5,1
    80005522:	08f70463          	beq	a4,a5,800055aa <sys_link+0xea>
  ip->nlink++;
    80005526:	04a4d783          	lhu	a5,74(s1)
    8000552a:	2785                	addiw	a5,a5,1
    8000552c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	274080e7          	jalr	628(ra) # 800037a6 <iupdate>
  iunlock(ip);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	3f6080e7          	jalr	1014(ra) # 80003932 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005544:	fd040593          	addi	a1,s0,-48
    80005548:	f5040513          	addi	a0,s0,-176
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	af8080e7          	jalr	-1288(ra) # 80004044 <nameiparent>
    80005554:	892a                	mv	s2,a0
    80005556:	c935                	beqz	a0,800055ca <sys_link+0x10a>
  ilock(dp);
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	318080e7          	jalr	792(ra) # 80003870 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005560:	00092703          	lw	a4,0(s2)
    80005564:	409c                	lw	a5,0(s1)
    80005566:	04f71d63          	bne	a4,a5,800055c0 <sys_link+0x100>
    8000556a:	40d0                	lw	a2,4(s1)
    8000556c:	fd040593          	addi	a1,s0,-48
    80005570:	854a                	mv	a0,s2
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	9f2080e7          	jalr	-1550(ra) # 80003f64 <dirlink>
    8000557a:	04054363          	bltz	a0,800055c0 <sys_link+0x100>
  iunlockput(dp);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	552080e7          	jalr	1362(ra) # 80003ad2 <iunlockput>
  iput(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	4a0080e7          	jalr	1184(ra) # 80003a2a <iput>
  end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	d30080e7          	jalr	-720(ra) # 800042c2 <end_op>
  return 0;
    8000559a:	4781                	li	a5,0
    8000559c:	a085                	j	800055fc <sys_link+0x13c>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	d24080e7          	jalr	-732(ra) # 800042c2 <end_op>
    return -1;
    800055a6:	57fd                	li	a5,-1
    800055a8:	a891                	j	800055fc <sys_link+0x13c>
    iunlockput(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	526080e7          	jalr	1318(ra) # 80003ad2 <iunlockput>
    end_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	d0e080e7          	jalr	-754(ra) # 800042c2 <end_op>
    return -1;
    800055bc:	57fd                	li	a5,-1
    800055be:	a83d                	j	800055fc <sys_link+0x13c>
    iunlockput(dp);
    800055c0:	854a                	mv	a0,s2
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	510080e7          	jalr	1296(ra) # 80003ad2 <iunlockput>
  ilock(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	2a4080e7          	jalr	676(ra) # 80003870 <ilock>
  ip->nlink--;
    800055d4:	04a4d783          	lhu	a5,74(s1)
    800055d8:	37fd                	addiw	a5,a5,-1
    800055da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	1c6080e7          	jalr	454(ra) # 800037a6 <iupdate>
  iunlockput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	4e8080e7          	jalr	1256(ra) # 80003ad2 <iunlockput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	cd0080e7          	jalr	-816(ra) # 800042c2 <end_op>
  return -1;
    800055fa:	57fd                	li	a5,-1
}
    800055fc:	853e                	mv	a0,a5
    800055fe:	70b2                	ld	ra,296(sp)
    80005600:	7412                	ld	s0,288(sp)
    80005602:	64f2                	ld	s1,280(sp)
    80005604:	6952                	ld	s2,272(sp)
    80005606:	6155                	addi	sp,sp,304
    80005608:	8082                	ret

000000008000560a <sys_unlink>:
{
    8000560a:	7151                	addi	sp,sp,-240
    8000560c:	f586                	sd	ra,232(sp)
    8000560e:	f1a2                	sd	s0,224(sp)
    80005610:	eda6                	sd	s1,216(sp)
    80005612:	e9ca                	sd	s2,208(sp)
    80005614:	e5ce                	sd	s3,200(sp)
    80005616:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005618:	08000613          	li	a2,128
    8000561c:	f3040593          	addi	a1,s0,-208
    80005620:	4501                	li	a0,0
    80005622:	ffffd097          	auipc	ra,0xffffd
    80005626:	6d4080e7          	jalr	1748(ra) # 80002cf6 <argstr>
    8000562a:	18054163          	bltz	a0,800057ac <sys_unlink+0x1a2>
  begin_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	c14080e7          	jalr	-1004(ra) # 80004242 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005636:	fb040593          	addi	a1,s0,-80
    8000563a:	f3040513          	addi	a0,s0,-208
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	a06080e7          	jalr	-1530(ra) # 80004044 <nameiparent>
    80005646:	84aa                	mv	s1,a0
    80005648:	c979                	beqz	a0,8000571e <sys_unlink+0x114>
  ilock(dp);
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	226080e7          	jalr	550(ra) # 80003870 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005652:	00003597          	auipc	a1,0x3
    80005656:	0ce58593          	addi	a1,a1,206 # 80008720 <syscalls+0x2c0>
    8000565a:	fb040513          	addi	a0,s0,-80
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	6dc080e7          	jalr	1756(ra) # 80003d3a <namecmp>
    80005666:	14050a63          	beqz	a0,800057ba <sys_unlink+0x1b0>
    8000566a:	00003597          	auipc	a1,0x3
    8000566e:	0be58593          	addi	a1,a1,190 # 80008728 <syscalls+0x2c8>
    80005672:	fb040513          	addi	a0,s0,-80
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	6c4080e7          	jalr	1732(ra) # 80003d3a <namecmp>
    8000567e:	12050e63          	beqz	a0,800057ba <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005682:	f2c40613          	addi	a2,s0,-212
    80005686:	fb040593          	addi	a1,s0,-80
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	6c8080e7          	jalr	1736(ra) # 80003d54 <dirlookup>
    80005694:	892a                	mv	s2,a0
    80005696:	12050263          	beqz	a0,800057ba <sys_unlink+0x1b0>
  ilock(ip);
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	1d6080e7          	jalr	470(ra) # 80003870 <ilock>
  if(ip->nlink < 1)
    800056a2:	04a91783          	lh	a5,74(s2)
    800056a6:	08f05263          	blez	a5,8000572a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056aa:	04491703          	lh	a4,68(s2)
    800056ae:	4785                	li	a5,1
    800056b0:	08f70563          	beq	a4,a5,8000573a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056b4:	4641                	li	a2,16
    800056b6:	4581                	li	a1,0
    800056b8:	fc040513          	addi	a0,s0,-64
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	624080e7          	jalr	1572(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c4:	4741                	li	a4,16
    800056c6:	f2c42683          	lw	a3,-212(s0)
    800056ca:	fc040613          	addi	a2,s0,-64
    800056ce:	4581                	li	a1,0
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	54a080e7          	jalr	1354(ra) # 80003c1c <writei>
    800056da:	47c1                	li	a5,16
    800056dc:	0af51563          	bne	a0,a5,80005786 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056e0:	04491703          	lh	a4,68(s2)
    800056e4:	4785                	li	a5,1
    800056e6:	0af70863          	beq	a4,a5,80005796 <sys_unlink+0x18c>
  iunlockput(dp);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	3e6080e7          	jalr	998(ra) # 80003ad2 <iunlockput>
  ip->nlink--;
    800056f4:	04a95783          	lhu	a5,74(s2)
    800056f8:	37fd                	addiw	a5,a5,-1
    800056fa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	0a6080e7          	jalr	166(ra) # 800037a6 <iupdate>
  iunlockput(ip);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	3c8080e7          	jalr	968(ra) # 80003ad2 <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	bb0080e7          	jalr	-1104(ra) # 800042c2 <end_op>
  return 0;
    8000571a:	4501                	li	a0,0
    8000571c:	a84d                	j	800057ce <sys_unlink+0x1c4>
    end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	ba4080e7          	jalr	-1116(ra) # 800042c2 <end_op>
    return -1;
    80005726:	557d                	li	a0,-1
    80005728:	a05d                	j	800057ce <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000572a:	00003517          	auipc	a0,0x3
    8000572e:	02650513          	addi	a0,a0,38 # 80008750 <syscalls+0x2f0>
    80005732:	ffffb097          	auipc	ra,0xffffb
    80005736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000573a:	04c92703          	lw	a4,76(s2)
    8000573e:	02000793          	li	a5,32
    80005742:	f6e7f9e3          	bgeu	a5,a4,800056b4 <sys_unlink+0xaa>
    80005746:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000574a:	4741                	li	a4,16
    8000574c:	86ce                	mv	a3,s3
    8000574e:	f1840613          	addi	a2,s0,-232
    80005752:	4581                	li	a1,0
    80005754:	854a                	mv	a0,s2
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	3ce080e7          	jalr	974(ra) # 80003b24 <readi>
    8000575e:	47c1                	li	a5,16
    80005760:	00f51b63          	bne	a0,a5,80005776 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005764:	f1845783          	lhu	a5,-232(s0)
    80005768:	e7a1                	bnez	a5,800057b0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000576a:	29c1                	addiw	s3,s3,16
    8000576c:	04c92783          	lw	a5,76(s2)
    80005770:	fcf9ede3          	bltu	s3,a5,8000574a <sys_unlink+0x140>
    80005774:	b781                	j	800056b4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005776:	00003517          	auipc	a0,0x3
    8000577a:	ff250513          	addi	a0,a0,-14 # 80008768 <syscalls+0x308>
    8000577e:	ffffb097          	auipc	ra,0xffffb
    80005782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005786:	00003517          	auipc	a0,0x3
    8000578a:	ffa50513          	addi	a0,a0,-6 # 80008780 <syscalls+0x320>
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>
    dp->nlink--;
    80005796:	04a4d783          	lhu	a5,74(s1)
    8000579a:	37fd                	addiw	a5,a5,-1
    8000579c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	004080e7          	jalr	4(ra) # 800037a6 <iupdate>
    800057aa:	b781                	j	800056ea <sys_unlink+0xe0>
    return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	a005                	j	800057ce <sys_unlink+0x1c4>
    iunlockput(ip);
    800057b0:	854a                	mv	a0,s2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	320080e7          	jalr	800(ra) # 80003ad2 <iunlockput>
  iunlockput(dp);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	316080e7          	jalr	790(ra) # 80003ad2 <iunlockput>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	afe080e7          	jalr	-1282(ra) # 800042c2 <end_op>
  return -1;
    800057cc:	557d                	li	a0,-1
}
    800057ce:	70ae                	ld	ra,232(sp)
    800057d0:	740e                	ld	s0,224(sp)
    800057d2:	64ee                	ld	s1,216(sp)
    800057d4:	694e                	ld	s2,208(sp)
    800057d6:	69ae                	ld	s3,200(sp)
    800057d8:	616d                	addi	sp,sp,240
    800057da:	8082                	ret

00000000800057dc <sys_open>:

uint64
sys_open(void)
{
    800057dc:	7131                	addi	sp,sp,-192
    800057de:	fd06                	sd	ra,184(sp)
    800057e0:	f922                	sd	s0,176(sp)
    800057e2:	f526                	sd	s1,168(sp)
    800057e4:	f14a                	sd	s2,160(sp)
    800057e6:	ed4e                	sd	s3,152(sp)
    800057e8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ea:	08000613          	li	a2,128
    800057ee:	f5040593          	addi	a1,s0,-176
    800057f2:	4501                	li	a0,0
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	502080e7          	jalr	1282(ra) # 80002cf6 <argstr>
    return -1;
    800057fc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057fe:	0c054163          	bltz	a0,800058c0 <sys_open+0xe4>
    80005802:	f4c40593          	addi	a1,s0,-180
    80005806:	4505                	li	a0,1
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	4aa080e7          	jalr	1194(ra) # 80002cb2 <argint>
    80005810:	0a054863          	bltz	a0,800058c0 <sys_open+0xe4>

  begin_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	a2e080e7          	jalr	-1490(ra) # 80004242 <begin_op>

  if(omode & O_CREATE){
    8000581c:	f4c42783          	lw	a5,-180(s0)
    80005820:	2007f793          	andi	a5,a5,512
    80005824:	cbdd                	beqz	a5,800058da <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005826:	4681                	li	a3,0
    80005828:	4601                	li	a2,0
    8000582a:	4589                	li	a1,2
    8000582c:	f5040513          	addi	a0,s0,-176
    80005830:	00000097          	auipc	ra,0x0
    80005834:	972080e7          	jalr	-1678(ra) # 800051a2 <create>
    80005838:	892a                	mv	s2,a0
    if(ip == 0){
    8000583a:	c959                	beqz	a0,800058d0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000583c:	04491703          	lh	a4,68(s2)
    80005840:	478d                	li	a5,3
    80005842:	00f71763          	bne	a4,a5,80005850 <sys_open+0x74>
    80005846:	04695703          	lhu	a4,70(s2)
    8000584a:	47a5                	li	a5,9
    8000584c:	0ce7ec63          	bltu	a5,a4,80005924 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	e02080e7          	jalr	-510(ra) # 80004652 <filealloc>
    80005858:	89aa                	mv	s3,a0
    8000585a:	10050263          	beqz	a0,8000595e <sys_open+0x182>
    8000585e:	00000097          	auipc	ra,0x0
    80005862:	902080e7          	jalr	-1790(ra) # 80005160 <fdalloc>
    80005866:	84aa                	mv	s1,a0
    80005868:	0e054663          	bltz	a0,80005954 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000586c:	04491703          	lh	a4,68(s2)
    80005870:	478d                	li	a5,3
    80005872:	0cf70463          	beq	a4,a5,8000593a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005876:	4789                	li	a5,2
    80005878:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000587c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005880:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005884:	f4c42783          	lw	a5,-180(s0)
    80005888:	0017c713          	xori	a4,a5,1
    8000588c:	8b05                	andi	a4,a4,1
    8000588e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005892:	0037f713          	andi	a4,a5,3
    80005896:	00e03733          	snez	a4,a4
    8000589a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000589e:	4007f793          	andi	a5,a5,1024
    800058a2:	c791                	beqz	a5,800058ae <sys_open+0xd2>
    800058a4:	04491703          	lh	a4,68(s2)
    800058a8:	4789                	li	a5,2
    800058aa:	08f70f63          	beq	a4,a5,80005948 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	082080e7          	jalr	130(ra) # 80003932 <iunlock>
  end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	a0a080e7          	jalr	-1526(ra) # 800042c2 <end_op>

  return fd;
}
    800058c0:	8526                	mv	a0,s1
    800058c2:	70ea                	ld	ra,184(sp)
    800058c4:	744a                	ld	s0,176(sp)
    800058c6:	74aa                	ld	s1,168(sp)
    800058c8:	790a                	ld	s2,160(sp)
    800058ca:	69ea                	ld	s3,152(sp)
    800058cc:	6129                	addi	sp,sp,192
    800058ce:	8082                	ret
      end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	9f2080e7          	jalr	-1550(ra) # 800042c2 <end_op>
      return -1;
    800058d8:	b7e5                	j	800058c0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058da:	f5040513          	addi	a0,s0,-176
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	748080e7          	jalr	1864(ra) # 80004026 <namei>
    800058e6:	892a                	mv	s2,a0
    800058e8:	c905                	beqz	a0,80005918 <sys_open+0x13c>
    ilock(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	f86080e7          	jalr	-122(ra) # 80003870 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058f2:	04491703          	lh	a4,68(s2)
    800058f6:	4785                	li	a5,1
    800058f8:	f4f712e3          	bne	a4,a5,8000583c <sys_open+0x60>
    800058fc:	f4c42783          	lw	a5,-180(s0)
    80005900:	dba1                	beqz	a5,80005850 <sys_open+0x74>
      iunlockput(ip);
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	1ce080e7          	jalr	462(ra) # 80003ad2 <iunlockput>
      end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	9b6080e7          	jalr	-1610(ra) # 800042c2 <end_op>
      return -1;
    80005914:	54fd                	li	s1,-1
    80005916:	b76d                	j	800058c0 <sys_open+0xe4>
      end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	9aa080e7          	jalr	-1622(ra) # 800042c2 <end_op>
      return -1;
    80005920:	54fd                	li	s1,-1
    80005922:	bf79                	j	800058c0 <sys_open+0xe4>
    iunlockput(ip);
    80005924:	854a                	mv	a0,s2
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	1ac080e7          	jalr	428(ra) # 80003ad2 <iunlockput>
    end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	994080e7          	jalr	-1644(ra) # 800042c2 <end_op>
    return -1;
    80005936:	54fd                	li	s1,-1
    80005938:	b761                	j	800058c0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000593a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000593e:	04691783          	lh	a5,70(s2)
    80005942:	02f99223          	sh	a5,36(s3)
    80005946:	bf2d                	j	80005880 <sys_open+0xa4>
    itrunc(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	034080e7          	jalr	52(ra) # 8000397e <itrunc>
    80005952:	bfb1                	j	800058ae <sys_open+0xd2>
      fileclose(f);
    80005954:	854e                	mv	a0,s3
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	db8080e7          	jalr	-584(ra) # 8000470e <fileclose>
    iunlockput(ip);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	172080e7          	jalr	370(ra) # 80003ad2 <iunlockput>
    end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	95a080e7          	jalr	-1702(ra) # 800042c2 <end_op>
    return -1;
    80005970:	54fd                	li	s1,-1
    80005972:	b7b9                	j	800058c0 <sys_open+0xe4>

0000000080005974 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005974:	7175                	addi	sp,sp,-144
    80005976:	e506                	sd	ra,136(sp)
    80005978:	e122                	sd	s0,128(sp)
    8000597a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	8c6080e7          	jalr	-1850(ra) # 80004242 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005984:	08000613          	li	a2,128
    80005988:	f7040593          	addi	a1,s0,-144
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	368080e7          	jalr	872(ra) # 80002cf6 <argstr>
    80005996:	02054963          	bltz	a0,800059c8 <sys_mkdir+0x54>
    8000599a:	4681                	li	a3,0
    8000599c:	4601                	li	a2,0
    8000599e:	4585                	li	a1,1
    800059a0:	f7040513          	addi	a0,s0,-144
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	7fe080e7          	jalr	2046(ra) # 800051a2 <create>
    800059ac:	cd11                	beqz	a0,800059c8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	124080e7          	jalr	292(ra) # 80003ad2 <iunlockput>
  end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	90c080e7          	jalr	-1780(ra) # 800042c2 <end_op>
  return 0;
    800059be:	4501                	li	a0,0
}
    800059c0:	60aa                	ld	ra,136(sp)
    800059c2:	640a                	ld	s0,128(sp)
    800059c4:	6149                	addi	sp,sp,144
    800059c6:	8082                	ret
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	8fa080e7          	jalr	-1798(ra) # 800042c2 <end_op>
    return -1;
    800059d0:	557d                	li	a0,-1
    800059d2:	b7fd                	j	800059c0 <sys_mkdir+0x4c>

00000000800059d4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059d4:	7135                	addi	sp,sp,-160
    800059d6:	ed06                	sd	ra,152(sp)
    800059d8:	e922                	sd	s0,144(sp)
    800059da:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	866080e7          	jalr	-1946(ra) # 80004242 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	308080e7          	jalr	776(ra) # 80002cf6 <argstr>
    800059f6:	04054a63          	bltz	a0,80005a4a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059fa:	f6c40593          	addi	a1,s0,-148
    800059fe:	4505                	li	a0,1
    80005a00:	ffffd097          	auipc	ra,0xffffd
    80005a04:	2b2080e7          	jalr	690(ra) # 80002cb2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a08:	04054163          	bltz	a0,80005a4a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a0c:	f6840593          	addi	a1,s0,-152
    80005a10:	4509                	li	a0,2
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	2a0080e7          	jalr	672(ra) # 80002cb2 <argint>
     argint(1, &major) < 0 ||
    80005a1a:	02054863          	bltz	a0,80005a4a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a1e:	f6841683          	lh	a3,-152(s0)
    80005a22:	f6c41603          	lh	a2,-148(s0)
    80005a26:	458d                	li	a1,3
    80005a28:	f7040513          	addi	a0,s0,-144
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	776080e7          	jalr	1910(ra) # 800051a2 <create>
     argint(2, &minor) < 0 ||
    80005a34:	c919                	beqz	a0,80005a4a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	09c080e7          	jalr	156(ra) # 80003ad2 <iunlockput>
  end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	884080e7          	jalr	-1916(ra) # 800042c2 <end_op>
  return 0;
    80005a46:	4501                	li	a0,0
    80005a48:	a031                	j	80005a54 <sys_mknod+0x80>
    end_op();
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	878080e7          	jalr	-1928(ra) # 800042c2 <end_op>
    return -1;
    80005a52:	557d                	li	a0,-1
}
    80005a54:	60ea                	ld	ra,152(sp)
    80005a56:	644a                	ld	s0,144(sp)
    80005a58:	610d                	addi	sp,sp,160
    80005a5a:	8082                	ret

0000000080005a5c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a5c:	7135                	addi	sp,sp,-160
    80005a5e:	ed06                	sd	ra,152(sp)
    80005a60:	e922                	sd	s0,144(sp)
    80005a62:	e526                	sd	s1,136(sp)
    80005a64:	e14a                	sd	s2,128(sp)
    80005a66:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a68:	ffffc097          	auipc	ra,0xffffc
    80005a6c:	f66080e7          	jalr	-154(ra) # 800019ce <myproc>
    80005a70:	892a                	mv	s2,a0
  
  begin_op();
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	7d0080e7          	jalr	2000(ra) # 80004242 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a7a:	08000613          	li	a2,128
    80005a7e:	f6040593          	addi	a1,s0,-160
    80005a82:	4501                	li	a0,0
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	272080e7          	jalr	626(ra) # 80002cf6 <argstr>
    80005a8c:	04054b63          	bltz	a0,80005ae2 <sys_chdir+0x86>
    80005a90:	f6040513          	addi	a0,s0,-160
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	592080e7          	jalr	1426(ra) # 80004026 <namei>
    80005a9c:	84aa                	mv	s1,a0
    80005a9e:	c131                	beqz	a0,80005ae2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	dd0080e7          	jalr	-560(ra) # 80003870 <ilock>
  if(ip->type != T_DIR){
    80005aa8:	04449703          	lh	a4,68(s1)
    80005aac:	4785                	li	a5,1
    80005aae:	04f71063          	bne	a4,a5,80005aee <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ab2:	8526                	mv	a0,s1
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	e7e080e7          	jalr	-386(ra) # 80003932 <iunlock>
  iput(p->cwd);
    80005abc:	15093503          	ld	a0,336(s2)
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	f6a080e7          	jalr	-150(ra) # 80003a2a <iput>
  end_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	7fa080e7          	jalr	2042(ra) # 800042c2 <end_op>
  p->cwd = ip;
    80005ad0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ad4:	4501                	li	a0,0
}
    80005ad6:	60ea                	ld	ra,152(sp)
    80005ad8:	644a                	ld	s0,144(sp)
    80005ada:	64aa                	ld	s1,136(sp)
    80005adc:	690a                	ld	s2,128(sp)
    80005ade:	610d                	addi	sp,sp,160
    80005ae0:	8082                	ret
    end_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	7e0080e7          	jalr	2016(ra) # 800042c2 <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
    80005aec:	b7ed                	j	80005ad6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005aee:	8526                	mv	a0,s1
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	fe2080e7          	jalr	-30(ra) # 80003ad2 <iunlockput>
    end_op();
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	7ca080e7          	jalr	1994(ra) # 800042c2 <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	bfd1                	j	80005ad6 <sys_chdir+0x7a>

0000000080005b04 <sys_exec>:

uint64
sys_exec(void)
{
    80005b04:	7145                	addi	sp,sp,-464
    80005b06:	e786                	sd	ra,456(sp)
    80005b08:	e3a2                	sd	s0,448(sp)
    80005b0a:	ff26                	sd	s1,440(sp)
    80005b0c:	fb4a                	sd	s2,432(sp)
    80005b0e:	f74e                	sd	s3,424(sp)
    80005b10:	f352                	sd	s4,416(sp)
    80005b12:	ef56                	sd	s5,408(sp)
    80005b14:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b16:	08000613          	li	a2,128
    80005b1a:	f4040593          	addi	a1,s0,-192
    80005b1e:	4501                	li	a0,0
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	1d6080e7          	jalr	470(ra) # 80002cf6 <argstr>
    return -1;
    80005b28:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b2a:	0c054a63          	bltz	a0,80005bfe <sys_exec+0xfa>
    80005b2e:	e3840593          	addi	a1,s0,-456
    80005b32:	4505                	li	a0,1
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	1a0080e7          	jalr	416(ra) # 80002cd4 <argaddr>
    80005b3c:	0c054163          	bltz	a0,80005bfe <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b40:	10000613          	li	a2,256
    80005b44:	4581                	li	a1,0
    80005b46:	e4040513          	addi	a0,s0,-448
    80005b4a:	ffffb097          	auipc	ra,0xffffb
    80005b4e:	196080e7          	jalr	406(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b56:	89a6                	mv	s3,s1
    80005b58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b5a:	02000a13          	li	s4,32
    80005b5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b62:	00391513          	slli	a0,s2,0x3
    80005b66:	e3040593          	addi	a1,s0,-464
    80005b6a:	e3843783          	ld	a5,-456(s0)
    80005b6e:	953e                	add	a0,a0,a5
    80005b70:	ffffd097          	auipc	ra,0xffffd
    80005b74:	0a8080e7          	jalr	168(ra) # 80002c18 <fetchaddr>
    80005b78:	02054a63          	bltz	a0,80005bac <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b7c:	e3043783          	ld	a5,-464(s0)
    80005b80:	c3b9                	beqz	a5,80005bc6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b82:	ffffb097          	auipc	ra,0xffffb
    80005b86:	f72080e7          	jalr	-142(ra) # 80000af4 <kalloc>
    80005b8a:	85aa                	mv	a1,a0
    80005b8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b90:	cd11                	beqz	a0,80005bac <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b92:	6605                	lui	a2,0x1
    80005b94:	e3043503          	ld	a0,-464(s0)
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	0d2080e7          	jalr	210(ra) # 80002c6a <fetchstr>
    80005ba0:	00054663          	bltz	a0,80005bac <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ba4:	0905                	addi	s2,s2,1
    80005ba6:	09a1                	addi	s3,s3,8
    80005ba8:	fb491be3          	bne	s2,s4,80005b5e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bac:	10048913          	addi	s2,s1,256
    80005bb0:	6088                	ld	a0,0(s1)
    80005bb2:	c529                	beqz	a0,80005bfc <sys_exec+0xf8>
    kfree(argv[i]);
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	e44080e7          	jalr	-444(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbc:	04a1                	addi	s1,s1,8
    80005bbe:	ff2499e3          	bne	s1,s2,80005bb0 <sys_exec+0xac>
  return -1;
    80005bc2:	597d                	li	s2,-1
    80005bc4:	a82d                	j	80005bfe <sys_exec+0xfa>
      argv[i] = 0;
    80005bc6:	0a8e                	slli	s5,s5,0x3
    80005bc8:	fc040793          	addi	a5,s0,-64
    80005bcc:	9abe                	add	s5,s5,a5
    80005bce:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bd2:	e4040593          	addi	a1,s0,-448
    80005bd6:	f4040513          	addi	a0,s0,-192
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	194080e7          	jalr	404(ra) # 80004d6e <exec>
    80005be2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be4:	10048993          	addi	s3,s1,256
    80005be8:	6088                	ld	a0,0(s1)
    80005bea:	c911                	beqz	a0,80005bfe <sys_exec+0xfa>
    kfree(argv[i]);
    80005bec:	ffffb097          	auipc	ra,0xffffb
    80005bf0:	e0c080e7          	jalr	-500(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf4:	04a1                	addi	s1,s1,8
    80005bf6:	ff3499e3          	bne	s1,s3,80005be8 <sys_exec+0xe4>
    80005bfa:	a011                	j	80005bfe <sys_exec+0xfa>
  return -1;
    80005bfc:	597d                	li	s2,-1
}
    80005bfe:	854a                	mv	a0,s2
    80005c00:	60be                	ld	ra,456(sp)
    80005c02:	641e                	ld	s0,448(sp)
    80005c04:	74fa                	ld	s1,440(sp)
    80005c06:	795a                	ld	s2,432(sp)
    80005c08:	79ba                	ld	s3,424(sp)
    80005c0a:	7a1a                	ld	s4,416(sp)
    80005c0c:	6afa                	ld	s5,408(sp)
    80005c0e:	6179                	addi	sp,sp,464
    80005c10:	8082                	ret

0000000080005c12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c12:	7139                	addi	sp,sp,-64
    80005c14:	fc06                	sd	ra,56(sp)
    80005c16:	f822                	sd	s0,48(sp)
    80005c18:	f426                	sd	s1,40(sp)
    80005c1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c1c:	ffffc097          	auipc	ra,0xffffc
    80005c20:	db2080e7          	jalr	-590(ra) # 800019ce <myproc>
    80005c24:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c26:	fd840593          	addi	a1,s0,-40
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffd097          	auipc	ra,0xffffd
    80005c30:	0a8080e7          	jalr	168(ra) # 80002cd4 <argaddr>
    return -1;
    80005c34:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c36:	0e054063          	bltz	a0,80005d16 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c3a:	fc840593          	addi	a1,s0,-56
    80005c3e:	fd040513          	addi	a0,s0,-48
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	dfc080e7          	jalr	-516(ra) # 80004a3e <pipealloc>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c4c:	0c054563          	bltz	a0,80005d16 <sys_pipe+0x104>
  fd0 = -1;
    80005c50:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c54:	fd043503          	ld	a0,-48(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	508080e7          	jalr	1288(ra) # 80005160 <fdalloc>
    80005c60:	fca42223          	sw	a0,-60(s0)
    80005c64:	08054c63          	bltz	a0,80005cfc <sys_pipe+0xea>
    80005c68:	fc843503          	ld	a0,-56(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	4f4080e7          	jalr	1268(ra) # 80005160 <fdalloc>
    80005c74:	fca42023          	sw	a0,-64(s0)
    80005c78:	06054863          	bltz	a0,80005ce8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c7c:	4691                	li	a3,4
    80005c7e:	fc440613          	addi	a2,s0,-60
    80005c82:	fd843583          	ld	a1,-40(s0)
    80005c86:	68a8                	ld	a0,80(s1)
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	9f2080e7          	jalr	-1550(ra) # 8000167a <copyout>
    80005c90:	02054063          	bltz	a0,80005cb0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c94:	4691                	li	a3,4
    80005c96:	fc040613          	addi	a2,s0,-64
    80005c9a:	fd843583          	ld	a1,-40(s0)
    80005c9e:	0591                	addi	a1,a1,4
    80005ca0:	68a8                	ld	a0,80(s1)
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	9d8080e7          	jalr	-1576(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005caa:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cac:	06055563          	bgez	a0,80005d16 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cb0:	fc442783          	lw	a5,-60(s0)
    80005cb4:	07e9                	addi	a5,a5,26
    80005cb6:	078e                	slli	a5,a5,0x3
    80005cb8:	97a6                	add	a5,a5,s1
    80005cba:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cbe:	fc042503          	lw	a0,-64(s0)
    80005cc2:	0569                	addi	a0,a0,26
    80005cc4:	050e                	slli	a0,a0,0x3
    80005cc6:	9526                	add	a0,a0,s1
    80005cc8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ccc:	fd043503          	ld	a0,-48(s0)
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	a3e080e7          	jalr	-1474(ra) # 8000470e <fileclose>
    fileclose(wf);
    80005cd8:	fc843503          	ld	a0,-56(s0)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	a32080e7          	jalr	-1486(ra) # 8000470e <fileclose>
    return -1;
    80005ce4:	57fd                	li	a5,-1
    80005ce6:	a805                	j	80005d16 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ce8:	fc442783          	lw	a5,-60(s0)
    80005cec:	0007c863          	bltz	a5,80005cfc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cf0:	01a78513          	addi	a0,a5,26
    80005cf4:	050e                	slli	a0,a0,0x3
    80005cf6:	9526                	add	a0,a0,s1
    80005cf8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cfc:	fd043503          	ld	a0,-48(s0)
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	a0e080e7          	jalr	-1522(ra) # 8000470e <fileclose>
    fileclose(wf);
    80005d08:	fc843503          	ld	a0,-56(s0)
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	a02080e7          	jalr	-1534(ra) # 8000470e <fileclose>
    return -1;
    80005d14:	57fd                	li	a5,-1
}
    80005d16:	853e                	mv	a0,a5
    80005d18:	70e2                	ld	ra,56(sp)
    80005d1a:	7442                	ld	s0,48(sp)
    80005d1c:	74a2                	ld	s1,40(sp)
    80005d1e:	6121                	addi	sp,sp,64
    80005d20:	8082                	ret
	...

0000000080005d30 <kernelvec>:
    80005d30:	7111                	addi	sp,sp,-256
    80005d32:	e006                	sd	ra,0(sp)
    80005d34:	e40a                	sd	sp,8(sp)
    80005d36:	e80e                	sd	gp,16(sp)
    80005d38:	ec12                	sd	tp,24(sp)
    80005d3a:	f016                	sd	t0,32(sp)
    80005d3c:	f41a                	sd	t1,40(sp)
    80005d3e:	f81e                	sd	t2,48(sp)
    80005d40:	fc22                	sd	s0,56(sp)
    80005d42:	e0a6                	sd	s1,64(sp)
    80005d44:	e4aa                	sd	a0,72(sp)
    80005d46:	e8ae                	sd	a1,80(sp)
    80005d48:	ecb2                	sd	a2,88(sp)
    80005d4a:	f0b6                	sd	a3,96(sp)
    80005d4c:	f4ba                	sd	a4,104(sp)
    80005d4e:	f8be                	sd	a5,112(sp)
    80005d50:	fcc2                	sd	a6,120(sp)
    80005d52:	e146                	sd	a7,128(sp)
    80005d54:	e54a                	sd	s2,136(sp)
    80005d56:	e94e                	sd	s3,144(sp)
    80005d58:	ed52                	sd	s4,152(sp)
    80005d5a:	f156                	sd	s5,160(sp)
    80005d5c:	f55a                	sd	s6,168(sp)
    80005d5e:	f95e                	sd	s7,176(sp)
    80005d60:	fd62                	sd	s8,184(sp)
    80005d62:	e1e6                	sd	s9,192(sp)
    80005d64:	e5ea                	sd	s10,200(sp)
    80005d66:	e9ee                	sd	s11,208(sp)
    80005d68:	edf2                	sd	t3,216(sp)
    80005d6a:	f1f6                	sd	t4,224(sp)
    80005d6c:	f5fa                	sd	t5,232(sp)
    80005d6e:	f9fe                	sd	t6,240(sp)
    80005d70:	d75fc0ef          	jal	ra,80002ae4 <kerneltrap>
    80005d74:	6082                	ld	ra,0(sp)
    80005d76:	6122                	ld	sp,8(sp)
    80005d78:	61c2                	ld	gp,16(sp)
    80005d7a:	7282                	ld	t0,32(sp)
    80005d7c:	7322                	ld	t1,40(sp)
    80005d7e:	73c2                	ld	t2,48(sp)
    80005d80:	7462                	ld	s0,56(sp)
    80005d82:	6486                	ld	s1,64(sp)
    80005d84:	6526                	ld	a0,72(sp)
    80005d86:	65c6                	ld	a1,80(sp)
    80005d88:	6666                	ld	a2,88(sp)
    80005d8a:	7686                	ld	a3,96(sp)
    80005d8c:	7726                	ld	a4,104(sp)
    80005d8e:	77c6                	ld	a5,112(sp)
    80005d90:	7866                	ld	a6,120(sp)
    80005d92:	688a                	ld	a7,128(sp)
    80005d94:	692a                	ld	s2,136(sp)
    80005d96:	69ca                	ld	s3,144(sp)
    80005d98:	6a6a                	ld	s4,152(sp)
    80005d9a:	7a8a                	ld	s5,160(sp)
    80005d9c:	7b2a                	ld	s6,168(sp)
    80005d9e:	7bca                	ld	s7,176(sp)
    80005da0:	7c6a                	ld	s8,184(sp)
    80005da2:	6c8e                	ld	s9,192(sp)
    80005da4:	6d2e                	ld	s10,200(sp)
    80005da6:	6dce                	ld	s11,208(sp)
    80005da8:	6e6e                	ld	t3,216(sp)
    80005daa:	7e8e                	ld	t4,224(sp)
    80005dac:	7f2e                	ld	t5,232(sp)
    80005dae:	7fce                	ld	t6,240(sp)
    80005db0:	6111                	addi	sp,sp,256
    80005db2:	10200073          	sret
    80005db6:	00000013          	nop
    80005dba:	00000013          	nop
    80005dbe:	0001                	nop

0000000080005dc0 <timervec>:
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	e10c                	sd	a1,0(a0)
    80005dc6:	e510                	sd	a2,8(a0)
    80005dc8:	e914                	sd	a3,16(a0)
    80005dca:	6d0c                	ld	a1,24(a0)
    80005dcc:	7110                	ld	a2,32(a0)
    80005dce:	6194                	ld	a3,0(a1)
    80005dd0:	96b2                	add	a3,a3,a2
    80005dd2:	e194                	sd	a3,0(a1)
    80005dd4:	4589                	li	a1,2
    80005dd6:	14459073          	csrw	sip,a1
    80005dda:	6914                	ld	a3,16(a0)
    80005ddc:	6510                	ld	a2,8(a0)
    80005dde:	610c                	ld	a1,0(a0)
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	30200073          	mret
	...

0000000080005dea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dea:	1141                	addi	sp,sp,-16
    80005dec:	e422                	sd	s0,8(sp)
    80005dee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005df0:	0c0007b7          	lui	a5,0xc000
    80005df4:	4705                	li	a4,1
    80005df6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005df8:	c3d8                	sw	a4,4(a5)
}
    80005dfa:	6422                	ld	s0,8(sp)
    80005dfc:	0141                	addi	sp,sp,16
    80005dfe:	8082                	ret

0000000080005e00 <plicinithart>:

void
plicinithart(void)
{
    80005e00:	1141                	addi	sp,sp,-16
    80005e02:	e406                	sd	ra,8(sp)
    80005e04:	e022                	sd	s0,0(sp)
    80005e06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	b9a080e7          	jalr	-1126(ra) # 800019a2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e10:	0085171b          	slliw	a4,a0,0x8
    80005e14:	0c0027b7          	lui	a5,0xc002
    80005e18:	97ba                	add	a5,a5,a4
    80005e1a:	40200713          	li	a4,1026
    80005e1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e22:	00d5151b          	slliw	a0,a0,0xd
    80005e26:	0c2017b7          	lui	a5,0xc201
    80005e2a:	953e                	add	a0,a0,a5
    80005e2c:	00052023          	sw	zero,0(a0)
}
    80005e30:	60a2                	ld	ra,8(sp)
    80005e32:	6402                	ld	s0,0(sp)
    80005e34:	0141                	addi	sp,sp,16
    80005e36:	8082                	ret

0000000080005e38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e38:	1141                	addi	sp,sp,-16
    80005e3a:	e406                	sd	ra,8(sp)
    80005e3c:	e022                	sd	s0,0(sp)
    80005e3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e40:	ffffc097          	auipc	ra,0xffffc
    80005e44:	b62080e7          	jalr	-1182(ra) # 800019a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e48:	00d5179b          	slliw	a5,a0,0xd
    80005e4c:	0c201537          	lui	a0,0xc201
    80005e50:	953e                	add	a0,a0,a5
  return irq;
}
    80005e52:	4148                	lw	a0,4(a0)
    80005e54:	60a2                	ld	ra,8(sp)
    80005e56:	6402                	ld	s0,0(sp)
    80005e58:	0141                	addi	sp,sp,16
    80005e5a:	8082                	ret

0000000080005e5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e5c:	1101                	addi	sp,sp,-32
    80005e5e:	ec06                	sd	ra,24(sp)
    80005e60:	e822                	sd	s0,16(sp)
    80005e62:	e426                	sd	s1,8(sp)
    80005e64:	1000                	addi	s0,sp,32
    80005e66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	b3a080e7          	jalr	-1222(ra) # 800019a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e70:	00d5151b          	slliw	a0,a0,0xd
    80005e74:	0c2017b7          	lui	a5,0xc201
    80005e78:	97aa                	add	a5,a5,a0
    80005e7a:	c3c4                	sw	s1,4(a5)
}
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	64a2                	ld	s1,8(sp)
    80005e82:	6105                	addi	sp,sp,32
    80005e84:	8082                	ret

0000000080005e86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e86:	1141                	addi	sp,sp,-16
    80005e88:	e406                	sd	ra,8(sp)
    80005e8a:	e022                	sd	s0,0(sp)
    80005e8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e8e:	479d                	li	a5,7
    80005e90:	06a7c963          	blt	a5,a0,80005f02 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e94:	0001d797          	auipc	a5,0x1d
    80005e98:	16c78793          	addi	a5,a5,364 # 80023000 <disk>
    80005e9c:	00a78733          	add	a4,a5,a0
    80005ea0:	6789                	lui	a5,0x2
    80005ea2:	97ba                	add	a5,a5,a4
    80005ea4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ea8:	e7ad                	bnez	a5,80005f12 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eaa:	00451793          	slli	a5,a0,0x4
    80005eae:	0001f717          	auipc	a4,0x1f
    80005eb2:	15270713          	addi	a4,a4,338 # 80025000 <disk+0x2000>
    80005eb6:	6314                	ld	a3,0(a4)
    80005eb8:	96be                	add	a3,a3,a5
    80005eba:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ebe:	6314                	ld	a3,0(a4)
    80005ec0:	96be                	add	a3,a3,a5
    80005ec2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ec6:	6314                	ld	a3,0(a4)
    80005ec8:	96be                	add	a3,a3,a5
    80005eca:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005ece:	6318                	ld	a4,0(a4)
    80005ed0:	97ba                	add	a5,a5,a4
    80005ed2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ed6:	0001d797          	auipc	a5,0x1d
    80005eda:	12a78793          	addi	a5,a5,298 # 80023000 <disk>
    80005ede:	97aa                	add	a5,a5,a0
    80005ee0:	6509                	lui	a0,0x2
    80005ee2:	953e                	add	a0,a0,a5
    80005ee4:	4785                	li	a5,1
    80005ee6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eea:	0001f517          	auipc	a0,0x1f
    80005eee:	12e50513          	addi	a0,a0,302 # 80025018 <disk+0x2018>
    80005ef2:	ffffc097          	auipc	ra,0xffffc
    80005ef6:	4a0080e7          	jalr	1184(ra) # 80002392 <wakeup>
}
    80005efa:	60a2                	ld	ra,8(sp)
    80005efc:	6402                	ld	s0,0(sp)
    80005efe:	0141                	addi	sp,sp,16
    80005f00:	8082                	ret
    panic("free_desc 1");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	88e50513          	addi	a0,a0,-1906 # 80008790 <syscalls+0x330>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	634080e7          	jalr	1588(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	88e50513          	addi	a0,a0,-1906 # 800087a0 <syscalls+0x340>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	624080e7          	jalr	1572(ra) # 8000053e <panic>

0000000080005f22 <virtio_disk_init>:
{
    80005f22:	1101                	addi	sp,sp,-32
    80005f24:	ec06                	sd	ra,24(sp)
    80005f26:	e822                	sd	s0,16(sp)
    80005f28:	e426                	sd	s1,8(sp)
    80005f2a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f2c:	00003597          	auipc	a1,0x3
    80005f30:	88458593          	addi	a1,a1,-1916 # 800087b0 <syscalls+0x350>
    80005f34:	0001f517          	auipc	a0,0x1f
    80005f38:	1f450513          	addi	a0,a0,500 # 80025128 <disk+0x2128>
    80005f3c:	ffffb097          	auipc	ra,0xffffb
    80005f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	4398                	lw	a4,0(a5)
    80005f4a:	2701                	sext.w	a4,a4
    80005f4c:	747277b7          	lui	a5,0x74727
    80005f50:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f54:	0ef71163          	bne	a4,a5,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	43dc                	lw	a5,4(a5)
    80005f5e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f60:	4705                	li	a4,1
    80005f62:	0ce79a63          	bne	a5,a4,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f66:	100017b7          	lui	a5,0x10001
    80005f6a:	479c                	lw	a5,8(a5)
    80005f6c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f6e:	4709                	li	a4,2
    80005f70:	0ce79363          	bne	a5,a4,80006036 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f74:	100017b7          	lui	a5,0x10001
    80005f78:	47d8                	lw	a4,12(a5)
    80005f7a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f7c:	554d47b7          	lui	a5,0x554d4
    80005f80:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f84:	0af71963          	bne	a4,a5,80006036 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f88:	100017b7          	lui	a5,0x10001
    80005f8c:	4705                	li	a4,1
    80005f8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f90:	470d                	li	a4,3
    80005f92:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f94:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f96:	c7ffe737          	lui	a4,0xc7ffe
    80005f9a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f9e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fa0:	2701                	sext.w	a4,a4
    80005fa2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa4:	472d                	li	a4,11
    80005fa6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa8:	473d                	li	a4,15
    80005faa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fac:	6705                	lui	a4,0x1
    80005fae:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fb0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fb4:	5bdc                	lw	a5,52(a5)
    80005fb6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fb8:	c7d9                	beqz	a5,80006046 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fba:	471d                	li	a4,7
    80005fbc:	08f77d63          	bgeu	a4,a5,80006056 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fc0:	100014b7          	lui	s1,0x10001
    80005fc4:	47a1                	li	a5,8
    80005fc6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fc8:	6609                	lui	a2,0x2
    80005fca:	4581                	li	a1,0
    80005fcc:	0001d517          	auipc	a0,0x1d
    80005fd0:	03450513          	addi	a0,a0,52 # 80023000 <disk>
    80005fd4:	ffffb097          	auipc	ra,0xffffb
    80005fd8:	d0c080e7          	jalr	-756(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fdc:	0001d717          	auipc	a4,0x1d
    80005fe0:	02470713          	addi	a4,a4,36 # 80023000 <disk>
    80005fe4:	00c75793          	srli	a5,a4,0xc
    80005fe8:	2781                	sext.w	a5,a5
    80005fea:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fec:	0001f797          	auipc	a5,0x1f
    80005ff0:	01478793          	addi	a5,a5,20 # 80025000 <disk+0x2000>
    80005ff4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ff6:	0001d717          	auipc	a4,0x1d
    80005ffa:	08a70713          	addi	a4,a4,138 # 80023080 <disk+0x80>
    80005ffe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006000:	0001e717          	auipc	a4,0x1e
    80006004:	00070713          	mv	a4,a4
    80006008:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000600a:	4705                	li	a4,1
    8000600c:	00e78c23          	sb	a4,24(a5)
    80006010:	00e78ca3          	sb	a4,25(a5)
    80006014:	00e78d23          	sb	a4,26(a5)
    80006018:	00e78da3          	sb	a4,27(a5)
    8000601c:	00e78e23          	sb	a4,28(a5)
    80006020:	00e78ea3          	sb	a4,29(a5)
    80006024:	00e78f23          	sb	a4,30(a5)
    80006028:	00e78fa3          	sb	a4,31(a5)
}
    8000602c:	60e2                	ld	ra,24(sp)
    8000602e:	6442                	ld	s0,16(sp)
    80006030:	64a2                	ld	s1,8(sp)
    80006032:	6105                	addi	sp,sp,32
    80006034:	8082                	ret
    panic("could not find virtio disk");
    80006036:	00002517          	auipc	a0,0x2
    8000603a:	78a50513          	addi	a0,a0,1930 # 800087c0 <syscalls+0x360>
    8000603e:	ffffa097          	auipc	ra,0xffffa
    80006042:	500080e7          	jalr	1280(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006046:	00002517          	auipc	a0,0x2
    8000604a:	79a50513          	addi	a0,a0,1946 # 800087e0 <syscalls+0x380>
    8000604e:	ffffa097          	auipc	ra,0xffffa
    80006052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	7aa50513          	addi	a0,a0,1962 # 80008800 <syscalls+0x3a0>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>

0000000080006066 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006066:	7159                	addi	sp,sp,-112
    80006068:	f486                	sd	ra,104(sp)
    8000606a:	f0a2                	sd	s0,96(sp)
    8000606c:	eca6                	sd	s1,88(sp)
    8000606e:	e8ca                	sd	s2,80(sp)
    80006070:	e4ce                	sd	s3,72(sp)
    80006072:	e0d2                	sd	s4,64(sp)
    80006074:	fc56                	sd	s5,56(sp)
    80006076:	f85a                	sd	s6,48(sp)
    80006078:	f45e                	sd	s7,40(sp)
    8000607a:	f062                	sd	s8,32(sp)
    8000607c:	ec66                	sd	s9,24(sp)
    8000607e:	e86a                	sd	s10,16(sp)
    80006080:	1880                	addi	s0,sp,112
    80006082:	892a                	mv	s2,a0
    80006084:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006086:	00c52c83          	lw	s9,12(a0)
    8000608a:	001c9c9b          	slliw	s9,s9,0x1
    8000608e:	1c82                	slli	s9,s9,0x20
    80006090:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006094:	0001f517          	auipc	a0,0x1f
    80006098:	09450513          	addi	a0,a0,148 # 80025128 <disk+0x2128>
    8000609c:	ffffb097          	auipc	ra,0xffffb
    800060a0:	b48080e7          	jalr	-1208(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060a6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060a8:	0001db97          	auipc	s7,0x1d
    800060ac:	f58b8b93          	addi	s7,s7,-168 # 80023000 <disk>
    800060b0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060b4:	8a4e                	mv	s4,s3
    800060b6:	a051                	j	8000613a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060b8:	00fb86b3          	add	a3,s7,a5
    800060bc:	96da                	add	a3,a3,s6
    800060be:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060c2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060c4:	0207c563          	bltz	a5,800060ee <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060c8:	2485                	addiw	s1,s1,1
    800060ca:	0711                	addi	a4,a4,4
    800060cc:	25548063          	beq	s1,s5,8000630c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060d0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060d2:	0001f697          	auipc	a3,0x1f
    800060d6:	f4668693          	addi	a3,a3,-186 # 80025018 <disk+0x2018>
    800060da:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060dc:	0006c583          	lbu	a1,0(a3)
    800060e0:	fde1                	bnez	a1,800060b8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060e2:	2785                	addiw	a5,a5,1
    800060e4:	0685                	addi	a3,a3,1
    800060e6:	ff879be3          	bne	a5,s8,800060dc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ea:	57fd                	li	a5,-1
    800060ec:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ee:	02905a63          	blez	s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060f2:	f9042503          	lw	a0,-112(s0)
    800060f6:	00000097          	auipc	ra,0x0
    800060fa:	d90080e7          	jalr	-624(ra) # 80005e86 <free_desc>
      for(int j = 0; j < i; j++)
    800060fe:	4785                	li	a5,1
    80006100:	0297d163          	bge	a5,s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006104:	f9442503          	lw	a0,-108(s0)
    80006108:	00000097          	auipc	ra,0x0
    8000610c:	d7e080e7          	jalr	-642(ra) # 80005e86 <free_desc>
      for(int j = 0; j < i; j++)
    80006110:	4789                	li	a5,2
    80006112:	0097d863          	bge	a5,s1,80006122 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006116:	f9842503          	lw	a0,-104(s0)
    8000611a:	00000097          	auipc	ra,0x0
    8000611e:	d6c080e7          	jalr	-660(ra) # 80005e86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006122:	0001f597          	auipc	a1,0x1f
    80006126:	00658593          	addi	a1,a1,6 # 80025128 <disk+0x2128>
    8000612a:	0001f517          	auipc	a0,0x1f
    8000612e:	eee50513          	addi	a0,a0,-274 # 80025018 <disk+0x2018>
    80006132:	ffffc097          	auipc	ra,0xffffc
    80006136:	0d4080e7          	jalr	212(ra) # 80002206 <sleep>
  for(int i = 0; i < 3; i++){
    8000613a:	f9040713          	addi	a4,s0,-112
    8000613e:	84ce                	mv	s1,s3
    80006140:	bf41                	j	800060d0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006142:	20058713          	addi	a4,a1,512
    80006146:	00471693          	slli	a3,a4,0x4
    8000614a:	0001d717          	auipc	a4,0x1d
    8000614e:	eb670713          	addi	a4,a4,-330 # 80023000 <disk>
    80006152:	9736                	add	a4,a4,a3
    80006154:	4685                	li	a3,1
    80006156:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000615a:	20058713          	addi	a4,a1,512
    8000615e:	00471693          	slli	a3,a4,0x4
    80006162:	0001d717          	auipc	a4,0x1d
    80006166:	e9e70713          	addi	a4,a4,-354 # 80023000 <disk>
    8000616a:	9736                	add	a4,a4,a3
    8000616c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006170:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006174:	7679                	lui	a2,0xffffe
    80006176:	963e                	add	a2,a2,a5
    80006178:	0001f697          	auipc	a3,0x1f
    8000617c:	e8868693          	addi	a3,a3,-376 # 80025000 <disk+0x2000>
    80006180:	6298                	ld	a4,0(a3)
    80006182:	9732                	add	a4,a4,a2
    80006184:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006186:	6298                	ld	a4,0(a3)
    80006188:	9732                	add	a4,a4,a2
    8000618a:	4541                	li	a0,16
    8000618c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000618e:	6298                	ld	a4,0(a3)
    80006190:	9732                	add	a4,a4,a2
    80006192:	4505                	li	a0,1
    80006194:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006198:	f9442703          	lw	a4,-108(s0)
    8000619c:	6288                	ld	a0,0(a3)
    8000619e:	962a                	add	a2,a2,a0
    800061a0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061a4:	0712                	slli	a4,a4,0x4
    800061a6:	6290                	ld	a2,0(a3)
    800061a8:	963a                	add	a2,a2,a4
    800061aa:	05890513          	addi	a0,s2,88
    800061ae:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061b0:	6294                	ld	a3,0(a3)
    800061b2:	96ba                	add	a3,a3,a4
    800061b4:	40000613          	li	a2,1024
    800061b8:	c690                	sw	a2,8(a3)
  if(write)
    800061ba:	140d0063          	beqz	s10,800062fa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061be:	0001f697          	auipc	a3,0x1f
    800061c2:	e426b683          	ld	a3,-446(a3) # 80025000 <disk+0x2000>
    800061c6:	96ba                	add	a3,a3,a4
    800061c8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061cc:	0001d817          	auipc	a6,0x1d
    800061d0:	e3480813          	addi	a6,a6,-460 # 80023000 <disk>
    800061d4:	0001f517          	auipc	a0,0x1f
    800061d8:	e2c50513          	addi	a0,a0,-468 # 80025000 <disk+0x2000>
    800061dc:	6114                	ld	a3,0(a0)
    800061de:	96ba                	add	a3,a3,a4
    800061e0:	00c6d603          	lhu	a2,12(a3)
    800061e4:	00166613          	ori	a2,a2,1
    800061e8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061ec:	f9842683          	lw	a3,-104(s0)
    800061f0:	6110                	ld	a2,0(a0)
    800061f2:	9732                	add	a4,a4,a2
    800061f4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061f8:	20058613          	addi	a2,a1,512
    800061fc:	0612                	slli	a2,a2,0x4
    800061fe:	9642                	add	a2,a2,a6
    80006200:	577d                	li	a4,-1
    80006202:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006206:	00469713          	slli	a4,a3,0x4
    8000620a:	6114                	ld	a3,0(a0)
    8000620c:	96ba                	add	a3,a3,a4
    8000620e:	03078793          	addi	a5,a5,48
    80006212:	97c2                	add	a5,a5,a6
    80006214:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006216:	611c                	ld	a5,0(a0)
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	4685                	li	a3,1
    8000621c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000621e:	611c                	ld	a5,0(a0)
    80006220:	97ba                	add	a5,a5,a4
    80006222:	4809                	li	a6,2
    80006224:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006228:	611c                	ld	a5,0(a0)
    8000622a:	973e                	add	a4,a4,a5
    8000622c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006230:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006234:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006238:	6518                	ld	a4,8(a0)
    8000623a:	00275783          	lhu	a5,2(a4)
    8000623e:	8b9d                	andi	a5,a5,7
    80006240:	0786                	slli	a5,a5,0x1
    80006242:	97ba                	add	a5,a5,a4
    80006244:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006248:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000624c:	6518                	ld	a4,8(a0)
    8000624e:	00275783          	lhu	a5,2(a4)
    80006252:	2785                	addiw	a5,a5,1
    80006254:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006258:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000625c:	100017b7          	lui	a5,0x10001
    80006260:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006264:	00492703          	lw	a4,4(s2)
    80006268:	4785                	li	a5,1
    8000626a:	02f71163          	bne	a4,a5,8000628c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000626e:	0001f997          	auipc	s3,0x1f
    80006272:	eba98993          	addi	s3,s3,-326 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006276:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006278:	85ce                	mv	a1,s3
    8000627a:	854a                	mv	a0,s2
    8000627c:	ffffc097          	auipc	ra,0xffffc
    80006280:	f8a080e7          	jalr	-118(ra) # 80002206 <sleep>
  while(b->disk == 1) {
    80006284:	00492783          	lw	a5,4(s2)
    80006288:	fe9788e3          	beq	a5,s1,80006278 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000628c:	f9042903          	lw	s2,-112(s0)
    80006290:	20090793          	addi	a5,s2,512
    80006294:	00479713          	slli	a4,a5,0x4
    80006298:	0001d797          	auipc	a5,0x1d
    8000629c:	d6878793          	addi	a5,a5,-664 # 80023000 <disk>
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062a6:	0001f997          	auipc	s3,0x1f
    800062aa:	d5a98993          	addi	s3,s3,-678 # 80025000 <disk+0x2000>
    800062ae:	00491713          	slli	a4,s2,0x4
    800062b2:	0009b783          	ld	a5,0(s3)
    800062b6:	97ba                	add	a5,a5,a4
    800062b8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062bc:	854a                	mv	a0,s2
    800062be:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062c2:	00000097          	auipc	ra,0x0
    800062c6:	bc4080e7          	jalr	-1084(ra) # 80005e86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ca:	8885                	andi	s1,s1,1
    800062cc:	f0ed                	bnez	s1,800062ae <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ce:	0001f517          	auipc	a0,0x1f
    800062d2:	e5a50513          	addi	a0,a0,-422 # 80025128 <disk+0x2128>
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
}
    800062de:	70a6                	ld	ra,104(sp)
    800062e0:	7406                	ld	s0,96(sp)
    800062e2:	64e6                	ld	s1,88(sp)
    800062e4:	6946                	ld	s2,80(sp)
    800062e6:	69a6                	ld	s3,72(sp)
    800062e8:	6a06                	ld	s4,64(sp)
    800062ea:	7ae2                	ld	s5,56(sp)
    800062ec:	7b42                	ld	s6,48(sp)
    800062ee:	7ba2                	ld	s7,40(sp)
    800062f0:	7c02                	ld	s8,32(sp)
    800062f2:	6ce2                	ld	s9,24(sp)
    800062f4:	6d42                	ld	s10,16(sp)
    800062f6:	6165                	addi	sp,sp,112
    800062f8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062fa:	0001f697          	auipc	a3,0x1f
    800062fe:	d066b683          	ld	a3,-762(a3) # 80025000 <disk+0x2000>
    80006302:	96ba                	add	a3,a3,a4
    80006304:	4609                	li	a2,2
    80006306:	00c69623          	sh	a2,12(a3)
    8000630a:	b5c9                	j	800061cc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000630c:	f9042583          	lw	a1,-112(s0)
    80006310:	20058793          	addi	a5,a1,512
    80006314:	0792                	slli	a5,a5,0x4
    80006316:	0001d517          	auipc	a0,0x1d
    8000631a:	d9250513          	addi	a0,a0,-622 # 800230a8 <disk+0xa8>
    8000631e:	953e                	add	a0,a0,a5
  if(write)
    80006320:	e20d11e3          	bnez	s10,80006142 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006324:	20058713          	addi	a4,a1,512
    80006328:	00471693          	slli	a3,a4,0x4
    8000632c:	0001d717          	auipc	a4,0x1d
    80006330:	cd470713          	addi	a4,a4,-812 # 80023000 <disk>
    80006334:	9736                	add	a4,a4,a3
    80006336:	0a072423          	sw	zero,168(a4)
    8000633a:	b505                	j	8000615a <virtio_disk_rw+0xf4>

000000008000633c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000633c:	1101                	addi	sp,sp,-32
    8000633e:	ec06                	sd	ra,24(sp)
    80006340:	e822                	sd	s0,16(sp)
    80006342:	e426                	sd	s1,8(sp)
    80006344:	e04a                	sd	s2,0(sp)
    80006346:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006348:	0001f517          	auipc	a0,0x1f
    8000634c:	de050513          	addi	a0,a0,-544 # 80025128 <disk+0x2128>
    80006350:	ffffb097          	auipc	ra,0xffffb
    80006354:	894080e7          	jalr	-1900(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006358:	10001737          	lui	a4,0x10001
    8000635c:	533c                	lw	a5,96(a4)
    8000635e:	8b8d                	andi	a5,a5,3
    80006360:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006362:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006366:	0001f797          	auipc	a5,0x1f
    8000636a:	c9a78793          	addi	a5,a5,-870 # 80025000 <disk+0x2000>
    8000636e:	6b94                	ld	a3,16(a5)
    80006370:	0207d703          	lhu	a4,32(a5)
    80006374:	0026d783          	lhu	a5,2(a3)
    80006378:	06f70163          	beq	a4,a5,800063da <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000637c:	0001d917          	auipc	s2,0x1d
    80006380:	c8490913          	addi	s2,s2,-892 # 80023000 <disk>
    80006384:	0001f497          	auipc	s1,0x1f
    80006388:	c7c48493          	addi	s1,s1,-900 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000638c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006390:	6898                	ld	a4,16(s1)
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	8b9d                	andi	a5,a5,7
    80006398:	078e                	slli	a5,a5,0x3
    8000639a:	97ba                	add	a5,a5,a4
    8000639c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000639e:	20078713          	addi	a4,a5,512
    800063a2:	0712                	slli	a4,a4,0x4
    800063a4:	974a                	add	a4,a4,s2
    800063a6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063aa:	e731                	bnez	a4,800063f6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063ac:	20078793          	addi	a5,a5,512
    800063b0:	0792                	slli	a5,a5,0x4
    800063b2:	97ca                	add	a5,a5,s2
    800063b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ba:	ffffc097          	auipc	ra,0xffffc
    800063be:	fd8080e7          	jalr	-40(ra) # 80002392 <wakeup>

    disk.used_idx += 1;
    800063c2:	0204d783          	lhu	a5,32(s1)
    800063c6:	2785                	addiw	a5,a5,1
    800063c8:	17c2                	slli	a5,a5,0x30
    800063ca:	93c1                	srli	a5,a5,0x30
    800063cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063d0:	6898                	ld	a4,16(s1)
    800063d2:	00275703          	lhu	a4,2(a4)
    800063d6:	faf71be3          	bne	a4,a5,8000638c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063da:	0001f517          	auipc	a0,0x1f
    800063de:	d4e50513          	addi	a0,a0,-690 # 80025128 <disk+0x2128>
    800063e2:	ffffb097          	auipc	ra,0xffffb
    800063e6:	8b6080e7          	jalr	-1866(ra) # 80000c98 <release>
}
    800063ea:	60e2                	ld	ra,24(sp)
    800063ec:	6442                	ld	s0,16(sp)
    800063ee:	64a2                	ld	s1,8(sp)
    800063f0:	6902                	ld	s2,0(sp)
    800063f2:	6105                	addi	sp,sp,32
    800063f4:	8082                	ret
      panic("virtio_disk_intr status");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	42a50513          	addi	a0,a0,1066 # 80008820 <syscalls+0x3c0>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>
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
