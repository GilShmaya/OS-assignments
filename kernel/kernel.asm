
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
    80000068:	4ac78793          	addi	a5,a5,1196 # 80006510 <timervec>
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
    80000130:	60e080e7          	jalr	1550(ra) # 8000273a <either_copyin>
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
    800001c8:	d08080e7          	jalr	-760(ra) # 80001ecc <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	2ce080e7          	jalr	718(ra) # 800024a2 <sleep>
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
    80000214:	4d4080e7          	jalr	1236(ra) # 800026e4 <either_copyout>
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
    800002f6:	49e080e7          	jalr	1182(ra) # 80002790 <procdump>
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
    8000044a:	688080e7          	jalr	1672(ra) # 80002ace <wakeup>
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
    800008a4:	22e080e7          	jalr	558(ra) # 80002ace <wakeup>
    
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
    80000930:	b76080e7          	jalr	-1162(ra) # 800024a2 <sleep>
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
    80000b82:	32c080e7          	jalr	812(ra) # 80001eaa <mycpu>
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
    80000bb4:	2fa080e7          	jalr	762(ra) # 80001eaa <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	2ee080e7          	jalr	750(ra) # 80001eaa <mycpu>
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
    80000bd8:	2d6080e7          	jalr	726(ra) # 80001eaa <mycpu>
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
    80000c18:	296080e7          	jalr	662(ra) # 80001eaa <mycpu>
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
    80000c44:	26a080e7          	jalr	618(ra) # 80001eaa <mycpu>
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
    80000e9a:	004080e7          	jalr	4(ra) # 80001e9a <cpuid>
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
    80000eb6:	fe8080e7          	jalr	-24(ra) # 80001e9a <cpuid>
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
    80000ed8:	0a2080e7          	jalr	162(ra) # 80002f76 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	674080e7          	jalr	1652(ra) # 80006550 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	f1c080e7          	jalr	-228(ra) # 80002e00 <scheduler>
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
    80000f48:	e54080e7          	jalr	-428(ra) # 80001d98 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	002080e7          	jalr	2(ra) # 80002f4e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	022080e7          	jalr	34(ra) # 80002f76 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	5de080e7          	jalr	1502(ra) # 8000653a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	5ec080e7          	jalr	1516(ra) # 80006550 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	7c8080e7          	jalr	1992(ra) # 80003734 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	e58080e7          	jalr	-424(ra) # 80003dcc <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	e02080e7          	jalr	-510(ra) # 80004d7e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	6ee080e7          	jalr	1774(ra) # 80006672 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	2cc080e7          	jalr	716(ra) # 80002258 <userinit>
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
    80001244:	ac2080e7          	jalr	-1342(ra) # 80001d02 <proc_mapstacks>
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

int 
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
  return 1; 
  //printf("after insert: \n");
  //print_list(*lst); // delete
}
    80001aea:	4505                	li	a0,1
    80001aec:	70e2                	ld	ra,56(sp)
    80001aee:	7442                	ld	s0,48(sp)
    80001af0:	74a2                	ld	s1,40(sp)
    80001af2:	7902                	ld	s2,32(sp)
    80001af4:	69e2                	ld	s3,24(sp)
    80001af6:	6a42                	ld	s4,16(sp)
    80001af8:	6aa2                	ld	s5,8(sp)
    80001afa:	6121                	addi	sp,sp,64
    80001afc:	8082                	ret

0000000080001afe <remove_head_from_list>:

int 
remove_head_from_list(struct _list *lst){
    80001afe:	1101                	addi	sp,sp,-32
    80001b00:	ec06                	sd	ra,24(sp)
    80001b02:	e822                	sd	s0,16(sp)
    80001b04:	e426                	sd	s1,8(sp)
    80001b06:	1000                	addi	s0,sp,32
    80001b08:	84aa                	mv	s1,a0
  return lst->head == -1;
    80001b0a:	4118                	lw	a4,0(a0)
  if(isEmpty(lst)){
    80001b0c:	57fd                	li	a5,-1
    80001b0e:	02f70d63          	beq	a4,a5,80001b48 <remove_head_from_list+0x4a>
    printf("Fails in removing the process from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }
  struct proc *p_head = &proc[lst->head];
  lst->head = p_head->next_index;
    80001b12:	19000793          	li	a5,400
    80001b16:	02f706b3          	mul	a3,a4,a5
    80001b1a:	00010797          	auipc	a5,0x10
    80001b1e:	d3678793          	addi	a5,a5,-714 # 80011850 <proc>
    80001b22:	97b6                	add	a5,a5,a3
    80001b24:	1747a783          	lw	a5,372(a5)
    80001b28:	c11c                	sw	a5,0(a0)
  if(p_head->next_index != -1){
    80001b2a:	56fd                	li	a3,-1
    80001b2c:	02d79e63          	bne	a5,a3,80001b68 <remove_head_from_list+0x6a>
    set_prev_proc(&proc[p_head->next_index], -1);
    set_next_proc(p_head, -1);
  }
  release(&lst->head_lock);
    80001b30:	00848513          	addi	a0,s1,8
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	164080e7          	jalr	356(ra) # 80000c98 <release>
  return 1;
    80001b3c:	4505                	li	a0,1
}
    80001b3e:	60e2                	ld	ra,24(sp)
    80001b40:	6442                	ld	s0,16(sp)
    80001b42:	64a2                	ld	s1,8(sp)
    80001b44:	6105                	addi	sp,sp,32
    80001b46:	8082                	ret
    printf("Fails in removing the process from the list: the list is empty\n");
    80001b48:	00006517          	auipc	a0,0x6
    80001b4c:	71850513          	addi	a0,a0,1816 # 80008260 <digits+0x220>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	a38080e7          	jalr	-1480(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001b58:	00848513          	addi	a0,s1,8
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	13c080e7          	jalr	316(ra) # 80000c98 <release>
    return 0;
    80001b64:	4501                	li	a0,0
    80001b66:	bfe1                	j	80001b3e <remove_head_from_list+0x40>
  p->prev_index = value; 
    80001b68:	00010697          	auipc	a3,0x10
    80001b6c:	ce868693          	addi	a3,a3,-792 # 80011850 <proc>
    80001b70:	19000593          	li	a1,400
    80001b74:	02b787b3          	mul	a5,a5,a1
    80001b78:	97b6                	add	a5,a5,a3
    80001b7a:	567d                	li	a2,-1
    80001b7c:	16c7a823          	sw	a2,368(a5)
  p->next_index = value; 
    80001b80:	02b70733          	mul	a4,a4,a1
    80001b84:	9736                	add	a4,a4,a3
    80001b86:	16c72a23          	sw	a2,372(a4)
}
    80001b8a:	b75d                	j	80001b30 <remove_head_from_list+0x32>

0000000080001b8c <remove_proc_to_list>:

int
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001b8c:	7139                	addi	sp,sp,-64
    80001b8e:	fc06                	sd	ra,56(sp)
    80001b90:	f822                	sd	s0,48(sp)
    80001b92:	f426                	sd	s1,40(sp)
    80001b94:	f04a                	sd	s2,32(sp)
    80001b96:	ec4e                	sd	s3,24(sp)
    80001b98:	e852                	sd	s4,16(sp)
    80001b9a:	e456                	sd	s5,8(sp)
    80001b9c:	e05a                	sd	s6,0(sp)
    80001b9e:	0080                	addi	s0,sp,64
    80001ba0:	84aa                	mv	s1,a0
    80001ba2:	892e                	mv	s2,a1
  //printf("before remove: \n");
  //print_list(*lst); // delete

  acquire(&lst->head_lock);
    80001ba4:	00850b13          	addi	s6,a0,8
    80001ba8:	855a                	mv	a0,s6
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	03a080e7          	jalr	58(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001bb2:	409c                	lw	a5,0(s1)
  if(isEmpty(lst)){
    80001bb4:	577d                	li	a4,-1
    80001bb6:	0ee78163          	beq	a5,a4,80001c98 <remove_proc_to_list+0x10c>
    printf("Fails in removing the process from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }

  if(lst->head == p->index){ // the required proc is the head
    80001bba:	16c92703          	lw	a4,364(s2)
    80001bbe:	0ef70c63          	beq	a4,a5,80001cb6 <remove_proc_to_list+0x12a>
   remove_head_from_list(lst);
  }
  else{
    struct proc *curr = &proc[lst->head];
    80001bc2:	19000513          	li	a0,400
    80001bc6:	02a787b3          	mul	a5,a5,a0
    80001bca:	00010517          	auipc	a0,0x10
    80001bce:	c8650513          	addi	a0,a0,-890 # 80011850 <proc>
    80001bd2:	00a784b3          	add	s1,a5,a0
    acquire(&curr->node_lock);
    80001bd6:	17878793          	addi	a5,a5,376
    80001bda:	953e                	add	a0,a0,a5
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	008080e7          	jalr	8(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001be4:	855a                	mv	a0,s6
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001bee:	1744a503          	lw	a0,372(s1)
    80001bf2:	16c92783          	lw	a5,364(s2)
    80001bf6:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001bf8:	19000a13          	li	s4,400
    80001bfc:	00010997          	auipc	s3,0x10
    80001c00:	c5498993          	addi	s3,s3,-940 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c04:	0ca78063          	beq	a5,a0,80001cc4 <remove_proc_to_list+0x138>
    80001c08:	0d550063          	beq	a0,s5,80001cc8 <remove_proc_to_list+0x13c>
      acquire(&proc[curr->next_index].node_lock);
    80001c0c:	03450533          	mul	a0,a0,s4
    80001c10:	17850513          	addi	a0,a0,376
    80001c14:	954e                	add	a0,a0,s3
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	fce080e7          	jalr	-50(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001c1e:	17848513          	addi	a0,s1,376
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	076080e7          	jalr	118(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001c2a:	1744a483          	lw	s1,372(s1)
    80001c2e:	034484b3          	mul	s1,s1,s4
    80001c32:	94ce                	add	s1,s1,s3
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c34:	1744a503          	lw	a0,372(s1)
    80001c38:	16c92783          	lw	a5,364(s2)
    80001c3c:	fcf516e3          	bne	a0,a5,80001c08 <remove_proc_to_list+0x7c>
    }
    if(curr->next_index == -1){
    80001c40:	577d                	li	a4,-1
    80001c42:	08e78363          	beq	a5,a4,80001cc8 <remove_proc_to_list+0x13c>
      printf("Fails in removing the process from the list: process is not found in the list\n");
      release(&lst->head_lock);
      return 0;
    }
    acquire(&p->node_lock); // curr is p->prev
    80001c46:	17890993          	addi	s3,s2,376
    80001c4a:	854e                	mv	a0,s3
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	f98080e7          	jalr	-104(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001c54:	17492783          	lw	a5,372(s2)
  p->next_index = value; 
    80001c58:	16f4aa23          	sw	a5,372(s1)
    if(p->next_index != -1)
    80001c5c:	577d                	li	a4,-1
    80001c5e:	08e79463          	bne	a5,a4,80001ce6 <remove_proc_to_list+0x15a>
  p->next_index = -1;
    80001c62:	57fd                	li	a5,-1
    80001c64:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001c68:	16f92823          	sw	a5,368(s2)
      set_prev_proc(&proc[p->next_index], curr->index);
    initialize_proc(p);
    release(&p->node_lock);
    80001c6c:	854e                	mv	a0,s3
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
    release(&curr->node_lock);
    80001c76:	17848513          	addi	a0,s1,376
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
  }
  return 1;
    80001c82:	4505                	li	a0,1
  //printf("after remove: \n");
  //print_list(*lst); // delete
}
    80001c84:	70e2                	ld	ra,56(sp)
    80001c86:	7442                	ld	s0,48(sp)
    80001c88:	74a2                	ld	s1,40(sp)
    80001c8a:	7902                	ld	s2,32(sp)
    80001c8c:	69e2                	ld	s3,24(sp)
    80001c8e:	6a42                	ld	s4,16(sp)
    80001c90:	6aa2                	ld	s5,8(sp)
    80001c92:	6b02                	ld	s6,0(sp)
    80001c94:	6121                	addi	sp,sp,64
    80001c96:	8082                	ret
    printf("Fails in removing the process from the list: the list is empty\n");
    80001c98:	00006517          	auipc	a0,0x6
    80001c9c:	5c850513          	addi	a0,a0,1480 # 80008260 <digits+0x220>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	8e8080e7          	jalr	-1816(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001ca8:	855a                	mv	a0,s6
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	fee080e7          	jalr	-18(ra) # 80000c98 <release>
    return 0;
    80001cb2:	4501                	li	a0,0
    80001cb4:	bfc1                	j	80001c84 <remove_proc_to_list+0xf8>
   remove_head_from_list(lst);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	e46080e7          	jalr	-442(ra) # 80001afe <remove_head_from_list>
  return 1;
    80001cc0:	4505                	li	a0,1
    80001cc2:	b7c9                	j	80001c84 <remove_proc_to_list+0xf8>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001cc4:	87aa                	mv	a5,a0
    80001cc6:	bfad                	j	80001c40 <remove_proc_to_list+0xb4>
      printf("Fails in removing the process from the list: process is not found in the list\n");
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	5d850513          	addi	a0,a0,1496 # 800082a0 <digits+0x260>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8b8080e7          	jalr	-1864(ra) # 80000588 <printf>
      release(&lst->head_lock);
    80001cd8:	855a                	mv	a0,s6
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fbe080e7          	jalr	-66(ra) # 80000c98 <release>
      return 0;
    80001ce2:	4501                	li	a0,0
    80001ce4:	b745                	j	80001c84 <remove_proc_to_list+0xf8>
      set_prev_proc(&proc[p->next_index], curr->index);
    80001ce6:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001cea:	19000713          	li	a4,400
    80001cee:	02e787b3          	mul	a5,a5,a4
    80001cf2:	00010717          	auipc	a4,0x10
    80001cf6:	b5e70713          	addi	a4,a4,-1186 # 80011850 <proc>
    80001cfa:	97ba                	add	a5,a5,a4
    80001cfc:	16d7a823          	sw	a3,368(a5)
}
    80001d00:	b78d                	j	80001c62 <remove_proc_to_list+0xd6>

0000000080001d02 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d02:	7139                	addi	sp,sp,-64
    80001d04:	fc06                	sd	ra,56(sp)
    80001d06:	f822                	sd	s0,48(sp)
    80001d08:	f426                	sd	s1,40(sp)
    80001d0a:	f04a                	sd	s2,32(sp)
    80001d0c:	ec4e                	sd	s3,24(sp)
    80001d0e:	e852                	sd	s4,16(sp)
    80001d10:	e456                	sd	s5,8(sp)
    80001d12:	e05a                	sd	s6,0(sp)
    80001d14:	0080                	addi	s0,sp,64
    80001d16:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d18:	00010497          	auipc	s1,0x10
    80001d1c:	b3848493          	addi	s1,s1,-1224 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d20:	8b26                	mv	s6,s1
    80001d22:	00006a97          	auipc	s5,0x6
    80001d26:	2dea8a93          	addi	s5,s5,734 # 80008000 <etext>
    80001d2a:	04000937          	lui	s2,0x4000
    80001d2e:	197d                	addi	s2,s2,-1
    80001d30:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d32:	00016a17          	auipc	s4,0x16
    80001d36:	f1ea0a13          	addi	s4,s4,-226 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	dba080e7          	jalr	-582(ra) # 80000af4 <kalloc>
    80001d42:	862a                	mv	a2,a0
    if(pa == 0)
    80001d44:	c131                	beqz	a0,80001d88 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001d46:	416485b3          	sub	a1,s1,s6
    80001d4a:	8591                	srai	a1,a1,0x4
    80001d4c:	000ab783          	ld	a5,0(s5)
    80001d50:	02f585b3          	mul	a1,a1,a5
    80001d54:	2585                	addiw	a1,a1,1
    80001d56:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d5a:	4719                	li	a4,6
    80001d5c:	6685                	lui	a3,0x1
    80001d5e:	40b905b3          	sub	a1,s2,a1
    80001d62:	854e                	mv	a0,s3
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	3ec080e7          	jalr	1004(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d6c:	19048493          	addi	s1,s1,400
    80001d70:	fd4495e3          	bne	s1,s4,80001d3a <proc_mapstacks+0x38>
  }
}
    80001d74:	70e2                	ld	ra,56(sp)
    80001d76:	7442                	ld	s0,48(sp)
    80001d78:	74a2                	ld	s1,40(sp)
    80001d7a:	7902                	ld	s2,32(sp)
    80001d7c:	69e2                	ld	s3,24(sp)
    80001d7e:	6a42                	ld	s4,16(sp)
    80001d80:	6aa2                	ld	s5,8(sp)
    80001d82:	6b02                	ld	s6,0(sp)
    80001d84:	6121                	addi	sp,sp,64
    80001d86:	8082                	ret
      panic("kalloc");
    80001d88:	00006517          	auipc	a0,0x6
    80001d8c:	56850513          	addi	a0,a0,1384 # 800082f0 <digits+0x2b0>
    80001d90:	ffffe097          	auipc	ra,0xffffe
    80001d94:	7ae080e7          	jalr	1966(ra) # 8000053e <panic>

0000000080001d98 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001d98:	711d                	addi	sp,sp,-96
    80001d9a:	ec86                	sd	ra,88(sp)
    80001d9c:	e8a2                	sd	s0,80(sp)
    80001d9e:	e4a6                	sd	s1,72(sp)
    80001da0:	e0ca                	sd	s2,64(sp)
    80001da2:	fc4e                	sd	s3,56(sp)
    80001da4:	f852                	sd	s4,48(sp)
    80001da6:	f456                	sd	s5,40(sp)
    80001da8:	f05a                	sd	s6,32(sp)
    80001daa:	ec5e                	sd	s7,24(sp)
    80001dac:	e862                	sd	s8,16(sp)
    80001dae:	e466                	sd	s9,8(sp)
    80001db0:	e06a                	sd	s10,0(sp)
    80001db2:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	b3c080e7          	jalr	-1220(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001dbc:	00006597          	auipc	a1,0x6
    80001dc0:	53c58593          	addi	a1,a1,1340 # 800082f8 <digits+0x2b8>
    80001dc4:	00010517          	auipc	a0,0x10
    80001dc8:	a5c50513          	addi	a0,a0,-1444 # 80011820 <pid_lock>
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	d88080e7          	jalr	-632(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001dd4:	00006597          	auipc	a1,0x6
    80001dd8:	52c58593          	addi	a1,a1,1324 # 80008300 <digits+0x2c0>
    80001ddc:	00010517          	auipc	a0,0x10
    80001de0:	a5c50513          	addi	a0,a0,-1444 # 80011838 <wait_lock>
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	d70080e7          	jalr	-656(ra) # 80000b54 <initlock>

  int i = 0;
    80001dec:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dee:	00010497          	auipc	s1,0x10
    80001df2:	a6248493          	addi	s1,s1,-1438 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001df6:	00006d17          	auipc	s10,0x6
    80001dfa:	51ad0d13          	addi	s10,s10,1306 # 80008310 <digits+0x2d0>
      initlock(&p->lock, "node_lock");
    80001dfe:	00006c97          	auipc	s9,0x6
    80001e02:	51ac8c93          	addi	s9,s9,1306 # 80008318 <digits+0x2d8>
      p->kstack = KSTACK((int) (p - proc));
    80001e06:	8c26                	mv	s8,s1
    80001e08:	00006b97          	auipc	s7,0x6
    80001e0c:	1f8b8b93          	addi	s7,s7,504 # 80008000 <etext>
    80001e10:	04000a37          	lui	s4,0x4000
    80001e14:	1a7d                	addi	s4,s4,-1
    80001e16:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001e18:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      //printf("insert procinit unused %d\n", p->index); //delete
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e1a:	00007b17          	auipc	s6,0x7
    80001e1e:	b46b0b13          	addi	s6,s6,-1210 # 80008960 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e22:	00016a97          	auipc	s5,0x16
    80001e26:	e2ea8a93          	addi	s5,s5,-466 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    80001e2a:	85ea                	mv	a1,s10
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	d26080e7          	jalr	-730(ra) # 80000b54 <initlock>
      initlock(&p->lock, "node_lock");
    80001e36:	85e6                	mv	a1,s9
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	d1a080e7          	jalr	-742(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001e42:	418487b3          	sub	a5,s1,s8
    80001e46:	8791                	srai	a5,a5,0x4
    80001e48:	000bb703          	ld	a4,0(s7)
    80001e4c:	02e787b3          	mul	a5,a5,a4
    80001e50:	2785                	addiw	a5,a5,1
    80001e52:	00d7979b          	slliw	a5,a5,0xd
    80001e56:	40fa07b3          	sub	a5,s4,a5
    80001e5a:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001e5c:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001e60:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001e64:	1734a823          	sw	s3,368(s1)
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e68:	85a6                	mv	a1,s1
    80001e6a:	855a                	mv	a0,s6
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	bb0080e7          	jalr	-1104(ra) # 80001a1c <insert_proc_to_list>
      i++;
    80001e74:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e76:	19048493          	addi	s1,s1,400
    80001e7a:	fb5498e3          	bne	s1,s5,80001e2a <procinit+0x92>
  }
}
    80001e7e:	60e6                	ld	ra,88(sp)
    80001e80:	6446                	ld	s0,80(sp)
    80001e82:	64a6                	ld	s1,72(sp)
    80001e84:	6906                	ld	s2,64(sp)
    80001e86:	79e2                	ld	s3,56(sp)
    80001e88:	7a42                	ld	s4,48(sp)
    80001e8a:	7aa2                	ld	s5,40(sp)
    80001e8c:	7b02                	ld	s6,32(sp)
    80001e8e:	6be2                	ld	s7,24(sp)
    80001e90:	6c42                	ld	s8,16(sp)
    80001e92:	6ca2                	ld	s9,8(sp)
    80001e94:	6d02                	ld	s10,0(sp)
    80001e96:	6125                	addi	sp,sp,96
    80001e98:	8082                	ret

0000000080001e9a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001e9a:	1141                	addi	sp,sp,-16
    80001e9c:	e422                	sd	s0,8(sp)
    80001e9e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ea0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ea2:	2501                	sext.w	a0,a0
    80001ea4:	6422                	ld	s0,8(sp)
    80001ea6:	0141                	addi	sp,sp,16
    80001ea8:	8082                	ret

0000000080001eaa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001eaa:	1141                	addi	sp,sp,-16
    80001eac:	e422                	sd	s0,8(sp)
    80001eae:	0800                	addi	s0,sp,16
    80001eb0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001eb2:	2781                	sext.w	a5,a5
    80001eb4:	0b000513          	li	a0,176
    80001eb8:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001ebc:	0000f517          	auipc	a0,0xf
    80001ec0:	3e450513          	addi	a0,a0,996 # 800112a0 <cpus>
    80001ec4:	953e                	add	a0,a0,a5
    80001ec6:	6422                	ld	s0,8(sp)
    80001ec8:	0141                	addi	sp,sp,16
    80001eca:	8082                	ret

0000000080001ecc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	1000                	addi	s0,sp,32
  push_off();
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	cc2080e7          	jalr	-830(ra) # 80000b98 <push_off>
    80001ede:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ee0:	2781                	sext.w	a5,a5
    80001ee2:	0b000713          	li	a4,176
    80001ee6:	02e787b3          	mul	a5,a5,a4
    80001eea:	0000f717          	auipc	a4,0xf
    80001eee:	3b670713          	addi	a4,a4,950 # 800112a0 <cpus>
    80001ef2:	97ba                	add	a5,a5,a4
    80001ef4:	6384                	ld	s1,0(a5)
  pop_off();
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	d42080e7          	jalr	-702(ra) # 80000c38 <pop_off>
  return p;
}
    80001efe:	8526                	mv	a0,s1
    80001f00:	60e2                	ld	ra,24(sp)
    80001f02:	6442                	ld	s0,16(sp)
    80001f04:	64a2                	ld	s1,8(sp)
    80001f06:	6105                	addi	sp,sp,32
    80001f08:	8082                	ret

0000000080001f0a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f0a:	1141                	addi	sp,sp,-16
    80001f0c:	e406                	sd	ra,8(sp)
    80001f0e:	e022                	sd	s0,0(sp)
    80001f10:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	fba080e7          	jalr	-70(ra) # 80001ecc <myproc>
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d7e080e7          	jalr	-642(ra) # 80000c98 <release>

  if (first) {
    80001f22:	00007797          	auipc	a5,0x7
    80001f26:	a2e7a783          	lw	a5,-1490(a5) # 80008950 <first.1786>
    80001f2a:	eb89                	bnez	a5,80001f3c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001f2c:	00001097          	auipc	ra,0x1
    80001f30:	062080e7          	jalr	98(ra) # 80002f8e <usertrapret>
}
    80001f34:	60a2                	ld	ra,8(sp)
    80001f36:	6402                	ld	s0,0(sp)
    80001f38:	0141                	addi	sp,sp,16
    80001f3a:	8082                	ret
    first = 0;
    80001f3c:	00007797          	auipc	a5,0x7
    80001f40:	a007aa23          	sw	zero,-1516(a5) # 80008950 <first.1786>
    fsinit(ROOTDEV);
    80001f44:	4505                	li	a0,1
    80001f46:	00002097          	auipc	ra,0x2
    80001f4a:	e06080e7          	jalr	-506(ra) # 80003d4c <fsinit>
    80001f4e:	bff9                	j	80001f2c <forkret+0x22>

0000000080001f50 <allocpid>:
allocpid() {
    80001f50:	1101                	addi	sp,sp,-32
    80001f52:	ec06                	sd	ra,24(sp)
    80001f54:	e822                	sd	s0,16(sp)
    80001f56:	e426                	sd	s1,8(sp)
    80001f58:	e04a                	sd	s2,0(sp)
    80001f5a:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001f5c:	00007917          	auipc	s2,0x7
    80001f60:	9f890913          	addi	s2,s2,-1544 # 80008954 <nextpid>
    80001f64:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001f68:	0014861b          	addiw	a2,s1,1
    80001f6c:	85a6                	mv	a1,s1
    80001f6e:	854a                	mv	a0,s2
    80001f70:	00005097          	auipc	ra,0x5
    80001f74:	be6080e7          	jalr	-1050(ra) # 80006b56 <cas>
    80001f78:	2501                	sext.w	a0,a0
    80001f7a:	f56d                	bnez	a0,80001f64 <allocpid+0x14>
}
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	60e2                	ld	ra,24(sp)
    80001f80:	6442                	ld	s0,16(sp)
    80001f82:	64a2                	ld	s1,8(sp)
    80001f84:	6902                	ld	s2,0(sp)
    80001f86:	6105                	addi	sp,sp,32
    80001f88:	8082                	ret

0000000080001f8a <proc_pagetable>:
{
    80001f8a:	1101                	addi	sp,sp,-32
    80001f8c:	ec06                	sd	ra,24(sp)
    80001f8e:	e822                	sd	s0,16(sp)
    80001f90:	e426                	sd	s1,8(sp)
    80001f92:	e04a                	sd	s2,0(sp)
    80001f94:	1000                	addi	s0,sp,32
    80001f96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	3a2080e7          	jalr	930(ra) # 8000133a <uvmcreate>
    80001fa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001fa2:	c121                	beqz	a0,80001fe2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001fa4:	4729                	li	a4,10
    80001fa6:	00005697          	auipc	a3,0x5
    80001faa:	05a68693          	addi	a3,a3,90 # 80007000 <_trampoline>
    80001fae:	6605                	lui	a2,0x1
    80001fb0:	040005b7          	lui	a1,0x4000
    80001fb4:	15fd                	addi	a1,a1,-1
    80001fb6:	05b2                	slli	a1,a1,0xc
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	0f8080e7          	jalr	248(ra) # 800010b0 <mappages>
    80001fc0:	02054863          	bltz	a0,80001ff0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001fc4:	4719                	li	a4,6
    80001fc6:	05893683          	ld	a3,88(s2)
    80001fca:	6605                	lui	a2,0x1
    80001fcc:	020005b7          	lui	a1,0x2000
    80001fd0:	15fd                	addi	a1,a1,-1
    80001fd2:	05b6                	slli	a1,a1,0xd
    80001fd4:	8526                	mv	a0,s1
    80001fd6:	fffff097          	auipc	ra,0xfffff
    80001fda:	0da080e7          	jalr	218(ra) # 800010b0 <mappages>
    80001fde:	02054163          	bltz	a0,80002000 <proc_pagetable+0x76>
}
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	60e2                	ld	ra,24(sp)
    80001fe6:	6442                	ld	s0,16(sp)
    80001fe8:	64a2                	ld	s1,8(sp)
    80001fea:	6902                	ld	s2,0(sp)
    80001fec:	6105                	addi	sp,sp,32
    80001fee:	8082                	ret
    uvmfree(pagetable, 0);
    80001ff0:	4581                	li	a1,0
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	542080e7          	jalr	1346(ra) # 80001536 <uvmfree>
    return 0;
    80001ffc:	4481                	li	s1,0
    80001ffe:	b7d5                	j	80001fe2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002000:	4681                	li	a3,0
    80002002:	4605                	li	a2,1
    80002004:	040005b7          	lui	a1,0x4000
    80002008:	15fd                	addi	a1,a1,-1
    8000200a:	05b2                	slli	a1,a1,0xc
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	268080e7          	jalr	616(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80002016:	4581                	li	a1,0
    80002018:	8526                	mv	a0,s1
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	51c080e7          	jalr	1308(ra) # 80001536 <uvmfree>
    return 0;
    80002022:	4481                	li	s1,0
    80002024:	bf7d                	j	80001fe2 <proc_pagetable+0x58>

0000000080002026 <proc_freepagetable>:
{
    80002026:	1101                	addi	sp,sp,-32
    80002028:	ec06                	sd	ra,24(sp)
    8000202a:	e822                	sd	s0,16(sp)
    8000202c:	e426                	sd	s1,8(sp)
    8000202e:	e04a                	sd	s2,0(sp)
    80002030:	1000                	addi	s0,sp,32
    80002032:	84aa                	mv	s1,a0
    80002034:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002036:	4681                	li	a3,0
    80002038:	4605                	li	a2,1
    8000203a:	040005b7          	lui	a1,0x4000
    8000203e:	15fd                	addi	a1,a1,-1
    80002040:	05b2                	slli	a1,a1,0xc
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	234080e7          	jalr	564(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000204a:	4681                	li	a3,0
    8000204c:	4605                	li	a2,1
    8000204e:	020005b7          	lui	a1,0x2000
    80002052:	15fd                	addi	a1,a1,-1
    80002054:	05b6                	slli	a1,a1,0xd
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	21e080e7          	jalr	542(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80002060:	85ca                	mv	a1,s2
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	4d2080e7          	jalr	1234(ra) # 80001536 <uvmfree>
}
    8000206c:	60e2                	ld	ra,24(sp)
    8000206e:	6442                	ld	s0,16(sp)
    80002070:	64a2                	ld	s1,8(sp)
    80002072:	6902                	ld	s2,0(sp)
    80002074:	6105                	addi	sp,sp,32
    80002076:	8082                	ret

0000000080002078 <freeproc>:
{
    80002078:	1101                	addi	sp,sp,-32
    8000207a:	ec06                	sd	ra,24(sp)
    8000207c:	e822                	sd	s0,16(sp)
    8000207e:	e426                	sd	s1,8(sp)
    80002080:	1000                	addi	s0,sp,32
    80002082:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002084:	6d28                	ld	a0,88(a0)
    80002086:	c509                	beqz	a0,80002090 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	970080e7          	jalr	-1680(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80002090:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002094:	68a8                	ld	a0,80(s1)
    80002096:	c511                	beqz	a0,800020a2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002098:	64ac                	ld	a1,72(s1)
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	f8c080e7          	jalr	-116(ra) # 80002026 <proc_freepagetable>
  p->pagetable = 0;
    800020a2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800020a6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800020aa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800020ae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800020b2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800020b6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800020ba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800020be:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    800020c2:	0004ac23          	sw	zero,24(s1)
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    800020c6:	85a6                	mv	a1,s1
    800020c8:	00007517          	auipc	a0,0x7
    800020cc:	8d850513          	addi	a0,a0,-1832 # 800089a0 <zombie_list>
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	abc080e7          	jalr	-1348(ra) # 80001b8c <remove_proc_to_list>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    800020d8:	85a6                	mv	a1,s1
    800020da:	00007517          	auipc	a0,0x7
    800020de:	88650513          	addi	a0,a0,-1914 # 80008960 <unused_list>
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	93a080e7          	jalr	-1734(ra) # 80001a1c <insert_proc_to_list>
}
    800020ea:	60e2                	ld	ra,24(sp)
    800020ec:	6442                	ld	s0,16(sp)
    800020ee:	64a2                	ld	s1,8(sp)
    800020f0:	6105                	addi	sp,sp,32
    800020f2:	8082                	ret

00000000800020f4 <allocproc>:
{
    800020f4:	715d                	addi	sp,sp,-80
    800020f6:	e486                	sd	ra,72(sp)
    800020f8:	e0a2                	sd	s0,64(sp)
    800020fa:	fc26                	sd	s1,56(sp)
    800020fc:	f84a                	sd	s2,48(sp)
    800020fe:	f44e                	sd	s3,40(sp)
    80002100:	f052                	sd	s4,32(sp)
    80002102:	ec56                	sd	s5,24(sp)
    80002104:	e85a                	sd	s6,16(sp)
    80002106:	e45e                	sd	s7,8(sp)
    80002108:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    8000210a:	00007717          	auipc	a4,0x7
    8000210e:	85672703          	lw	a4,-1962(a4) # 80008960 <unused_list>
    80002112:	57fd                	li	a5,-1
    80002114:	14f70063          	beq	a4,a5,80002254 <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    80002118:	00007a17          	auipc	s4,0x7
    8000211c:	848a0a13          	addi	s4,s4,-1976 # 80008960 <unused_list>
    80002120:	19000b13          	li	s6,400
    80002124:	0000fa97          	auipc	s5,0xf
    80002128:	72ca8a93          	addi	s5,s5,1836 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    8000212c:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    8000212e:	8552                	mv	a0,s4
    80002130:	00000097          	auipc	ra,0x0
    80002134:	896080e7          	jalr	-1898(ra) # 800019c6 <get_head>
    80002138:	892a                	mv	s2,a0
    8000213a:	036509b3          	mul	s3,a0,s6
    8000213e:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    8000214c:	4c9c                	lw	a5,24(s1)
    8000214e:	c79d                	beqz	a5,8000217c <allocproc+0x88>
      release(&p->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    8000215a:	000a2783          	lw	a5,0(s4)
    8000215e:	fd7798e3          	bne	a5,s7,8000212e <allocproc+0x3a>
  return 0;
    80002162:	4481                	li	s1,0
}
    80002164:	8526                	mv	a0,s1
    80002166:	60a6                	ld	ra,72(sp)
    80002168:	6406                	ld	s0,64(sp)
    8000216a:	74e2                	ld	s1,56(sp)
    8000216c:	7942                	ld	s2,48(sp)
    8000216e:	79a2                	ld	s3,40(sp)
    80002170:	7a02                	ld	s4,32(sp)
    80002172:	6ae2                	ld	s5,24(sp)
    80002174:	6b42                	ld	s6,16(sp)
    80002176:	6ba2                	ld	s7,8(sp)
    80002178:	6161                	addi	sp,sp,80
    8000217a:	8082                	ret
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    8000217c:	85a6                	mv	a1,s1
    8000217e:	00006517          	auipc	a0,0x6
    80002182:	7e250513          	addi	a0,a0,2018 # 80008960 <unused_list>
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	a06080e7          	jalr	-1530(ra) # 80001b8c <remove_proc_to_list>
  p->pid = allocpid();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	dc2080e7          	jalr	-574(ra) # 80001f50 <allocpid>
    80002196:	19000a13          	li	s4,400
    8000219a:	034907b3          	mul	a5,s2,s4
    8000219e:	0000fa17          	auipc	s4,0xf
    800021a2:	6b2a0a13          	addi	s4,s4,1714 # 80011850 <proc>
    800021a6:	9a3e                	add	s4,s4,a5
    800021a8:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    800021ac:	4785                	li	a5,1
    800021ae:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	942080e7          	jalr	-1726(ra) # 80000af4 <kalloc>
    800021ba:	8aaa                	mv	s5,a0
    800021bc:	04aa3c23          	sd	a0,88(s4)
    800021c0:	c135                	beqz	a0,80002224 <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    800021c2:	8526                	mv	a0,s1
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	dc6080e7          	jalr	-570(ra) # 80001f8a <proc_pagetable>
    800021cc:	8a2a                	mv	s4,a0
    800021ce:	19000793          	li	a5,400
    800021d2:	02f90733          	mul	a4,s2,a5
    800021d6:	0000f797          	auipc	a5,0xf
    800021da:	67a78793          	addi	a5,a5,1658 # 80011850 <proc>
    800021de:	97ba                	add	a5,a5,a4
    800021e0:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    800021e2:	cd29                	beqz	a0,8000223c <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    800021e4:	06098513          	addi	a0,s3,96
    800021e8:	0000f997          	auipc	s3,0xf
    800021ec:	66898993          	addi	s3,s3,1640 # 80011850 <proc>
    800021f0:	07000613          	li	a2,112
    800021f4:	4581                	li	a1,0
    800021f6:	954e                	add	a0,a0,s3
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	ae8080e7          	jalr	-1304(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002200:	19000793          	li	a5,400
    80002204:	02f90933          	mul	s2,s2,a5
    80002208:	994e                	add	s2,s2,s3
    8000220a:	00000797          	auipc	a5,0x0
    8000220e:	d0078793          	addi	a5,a5,-768 # 80001f0a <forkret>
    80002212:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002216:	04093783          	ld	a5,64(s2)
    8000221a:	6705                	lui	a4,0x1
    8000221c:	97ba                	add	a5,a5,a4
    8000221e:	06f93423          	sd	a5,104(s2)
  return p;
    80002222:	b789                	j	80002164 <allocproc+0x70>
    freeproc(p);
    80002224:	8526                	mv	a0,s1
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	e52080e7          	jalr	-430(ra) # 80002078 <freeproc>
    release(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a68080e7          	jalr	-1432(ra) # 80000c98 <release>
    return 0;
    80002238:	84d6                	mv	s1,s5
    8000223a:	b72d                	j	80002164 <allocproc+0x70>
    freeproc(p);
    8000223c:	8526                	mv	a0,s1
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e3a080e7          	jalr	-454(ra) # 80002078 <freeproc>
    release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a50080e7          	jalr	-1456(ra) # 80000c98 <release>
    return 0;
    80002250:	84d2                	mv	s1,s4
    80002252:	bf09                	j	80002164 <allocproc+0x70>
  return 0;
    80002254:	4481                	li	s1,0
    80002256:	b739                	j	80002164 <allocproc+0x70>

0000000080002258 <userinit>:
{
    80002258:	1101                	addi	sp,sp,-32
    8000225a:	ec06                	sd	ra,24(sp)
    8000225c:	e822                	sd	s0,16(sp)
    8000225e:	e426                	sd	s1,8(sp)
    80002260:	1000                	addi	s0,sp,32
  p = allocproc();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	e92080e7          	jalr	-366(ra) # 800020f4 <allocproc>
    8000226a:	84aa                	mv	s1,a0
  initproc = p;
    8000226c:	00007797          	auipc	a5,0x7
    80002270:	daa7be23          	sd	a0,-580(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002274:	03400613          	li	a2,52
    80002278:	00006597          	auipc	a1,0x6
    8000227c:	74858593          	addi	a1,a1,1864 # 800089c0 <initcode>
    80002280:	6928                	ld	a0,80(a0)
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	0e6080e7          	jalr	230(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000228a:	6785                	lui	a5,0x1
    8000228c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000228e:	6cb8                	ld	a4,88(s1)
    80002290:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002294:	6cb8                	ld	a4,88(s1)
    80002296:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002298:	4641                	li	a2,16
    8000229a:	00006597          	auipc	a1,0x6
    8000229e:	08e58593          	addi	a1,a1,142 # 80008328 <digits+0x2e8>
    800022a2:	15848513          	addi	a0,s1,344
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	b8c080e7          	jalr	-1140(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800022ae:	00006517          	auipc	a0,0x6
    800022b2:	08a50513          	addi	a0,a0,138 # 80008338 <digits+0x2f8>
    800022b6:	00002097          	auipc	ra,0x2
    800022ba:	4c4080e7          	jalr	1220(ra) # 8000477a <namei>
    800022be:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800022c2:	478d                	li	a5,3
    800022c4:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    800022c6:	85a6                	mv	a1,s1
    800022c8:	0000f517          	auipc	a0,0xf
    800022cc:	05850513          	addi	a0,a0,88 # 80011320 <cpus+0x80>
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	74c080e7          	jalr	1868(ra) # 80001a1c <insert_proc_to_list>
  release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9be080e7          	jalr	-1602(ra) # 80000c98 <release>
}
    800022e2:	60e2                	ld	ra,24(sp)
    800022e4:	6442                	ld	s0,16(sp)
    800022e6:	64a2                	ld	s1,8(sp)
    800022e8:	6105                	addi	sp,sp,32
    800022ea:	8082                	ret

00000000800022ec <growproc>:
{
    800022ec:	1101                	addi	sp,sp,-32
    800022ee:	ec06                	sd	ra,24(sp)
    800022f0:	e822                	sd	s0,16(sp)
    800022f2:	e426                	sd	s1,8(sp)
    800022f4:	e04a                	sd	s2,0(sp)
    800022f6:	1000                	addi	s0,sp,32
    800022f8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	bd2080e7          	jalr	-1070(ra) # 80001ecc <myproc>
    80002302:	892a                	mv	s2,a0
  sz = p->sz;
    80002304:	652c                	ld	a1,72(a0)
    80002306:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000230a:	00904f63          	bgtz	s1,80002328 <growproc+0x3c>
  } else if(n < 0){
    8000230e:	0204cc63          	bltz	s1,80002346 <growproc+0x5a>
  p->sz = sz;
    80002312:	1602                	slli	a2,a2,0x20
    80002314:	9201                	srli	a2,a2,0x20
    80002316:	04c93423          	sd	a2,72(s2)
  return 0;
    8000231a:	4501                	li	a0,0
}
    8000231c:	60e2                	ld	ra,24(sp)
    8000231e:	6442                	ld	s0,16(sp)
    80002320:	64a2                	ld	s1,8(sp)
    80002322:	6902                	ld	s2,0(sp)
    80002324:	6105                	addi	sp,sp,32
    80002326:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002328:	9e25                	addw	a2,a2,s1
    8000232a:	1602                	slli	a2,a2,0x20
    8000232c:	9201                	srli	a2,a2,0x20
    8000232e:	1582                	slli	a1,a1,0x20
    80002330:	9181                	srli	a1,a1,0x20
    80002332:	6928                	ld	a0,80(a0)
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	0ee080e7          	jalr	238(ra) # 80001422 <uvmalloc>
    8000233c:	0005061b          	sext.w	a2,a0
    80002340:	fa69                	bnez	a2,80002312 <growproc+0x26>
      return -1;
    80002342:	557d                	li	a0,-1
    80002344:	bfe1                	j	8000231c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002346:	9e25                	addw	a2,a2,s1
    80002348:	1602                	slli	a2,a2,0x20
    8000234a:	9201                	srli	a2,a2,0x20
    8000234c:	1582                	slli	a1,a1,0x20
    8000234e:	9181                	srli	a1,a1,0x20
    80002350:	6928                	ld	a0,80(a0)
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	088080e7          	jalr	136(ra) # 800013da <uvmdealloc>
    8000235a:	0005061b          	sext.w	a2,a0
    8000235e:	bf55                	j	80002312 <growproc+0x26>

0000000080002360 <sched>:
{
    80002360:	7179                	addi	sp,sp,-48
    80002362:	f406                	sd	ra,40(sp)
    80002364:	f022                	sd	s0,32(sp)
    80002366:	ec26                	sd	s1,24(sp)
    80002368:	e84a                	sd	s2,16(sp)
    8000236a:	e44e                	sd	s3,8(sp)
    8000236c:	e052                	sd	s4,0(sp)
    8000236e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002370:	00000097          	auipc	ra,0x0
    80002374:	b5c080e7          	jalr	-1188(ra) # 80001ecc <myproc>
    80002378:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000237a:	ffffe097          	auipc	ra,0xffffe
    8000237e:	7f0080e7          	jalr	2032(ra) # 80000b6a <holding>
    80002382:	c141                	beqz	a0,80002402 <sched+0xa2>
    80002384:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002386:	2781                	sext.w	a5,a5
    80002388:	0b000713          	li	a4,176
    8000238c:	02e787b3          	mul	a5,a5,a4
    80002390:	0000f717          	auipc	a4,0xf
    80002394:	f1070713          	addi	a4,a4,-240 # 800112a0 <cpus>
    80002398:	97ba                	add	a5,a5,a4
    8000239a:	5fb8                	lw	a4,120(a5)
    8000239c:	4785                	li	a5,1
    8000239e:	06f71a63          	bne	a4,a5,80002412 <sched+0xb2>
  if(p->state == RUNNING)
    800023a2:	4c98                	lw	a4,24(s1)
    800023a4:	4791                	li	a5,4
    800023a6:	06f70e63          	beq	a4,a5,80002422 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023ae:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023b0:	e3c9                	bnez	a5,80002432 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023b2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023b4:	0000f917          	auipc	s2,0xf
    800023b8:	eec90913          	addi	s2,s2,-276 # 800112a0 <cpus>
    800023bc:	2781                	sext.w	a5,a5
    800023be:	0b000993          	li	s3,176
    800023c2:	033787b3          	mul	a5,a5,s3
    800023c6:	97ca                	add	a5,a5,s2
    800023c8:	07c7aa03          	lw	s4,124(a5) # 107c <_entry-0x7fffef84>
    800023cc:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800023ce:	2581                	sext.w	a1,a1
    800023d0:	033585b3          	mul	a1,a1,s3
    800023d4:	05a1                	addi	a1,a1,8
    800023d6:	95ca                	add	a1,a1,s2
    800023d8:	06048513          	addi	a0,s1,96
    800023dc:	00001097          	auipc	ra,0x1
    800023e0:	b08080e7          	jalr	-1272(ra) # 80002ee4 <swtch>
    800023e4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023e6:	2781                	sext.w	a5,a5
    800023e8:	033787b3          	mul	a5,a5,s3
    800023ec:	993e                	add	s2,s2,a5
    800023ee:	07492e23          	sw	s4,124(s2)
}
    800023f2:	70a2                	ld	ra,40(sp)
    800023f4:	7402                	ld	s0,32(sp)
    800023f6:	64e2                	ld	s1,24(sp)
    800023f8:	6942                	ld	s2,16(sp)
    800023fa:	69a2                	ld	s3,8(sp)
    800023fc:	6a02                	ld	s4,0(sp)
    800023fe:	6145                	addi	sp,sp,48
    80002400:	8082                	ret
    panic("sched p->lock");
    80002402:	00006517          	auipc	a0,0x6
    80002406:	f3e50513          	addi	a0,a0,-194 # 80008340 <digits+0x300>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	134080e7          	jalr	308(ra) # 8000053e <panic>
    panic("sched locks");
    80002412:	00006517          	auipc	a0,0x6
    80002416:	f3e50513          	addi	a0,a0,-194 # 80008350 <digits+0x310>
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	124080e7          	jalr	292(ra) # 8000053e <panic>
    panic("sched running");
    80002422:	00006517          	auipc	a0,0x6
    80002426:	f3e50513          	addi	a0,a0,-194 # 80008360 <digits+0x320>
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	114080e7          	jalr	276(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002432:	00006517          	auipc	a0,0x6
    80002436:	f3e50513          	addi	a0,a0,-194 # 80008370 <digits+0x330>
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	104080e7          	jalr	260(ra) # 8000053e <panic>

0000000080002442 <yield>:
{
    80002442:	1101                	addi	sp,sp,-32
    80002444:	ec06                	sd	ra,24(sp)
    80002446:	e822                	sd	s0,16(sp)
    80002448:	e426                	sd	s1,8(sp)
    8000244a:	e04a                	sd	s2,0(sp)
    8000244c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	a7e080e7          	jalr	-1410(ra) # 80001ecc <myproc>
    80002456:	84aa                	mv	s1,a0
    80002458:	8912                	mv	s2,tp
  acquire(&p->lock);
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	78a080e7          	jalr	1930(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002462:	478d                	li	a5,3
    80002464:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    80002466:	2901                	sext.w	s2,s2
    80002468:	0b000513          	li	a0,176
    8000246c:	02a90933          	mul	s2,s2,a0
    80002470:	85a6                	mv	a1,s1
    80002472:	0000f517          	auipc	a0,0xf
    80002476:	eae50513          	addi	a0,a0,-338 # 80011320 <cpus+0x80>
    8000247a:	954a                	add	a0,a0,s2
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	5a0080e7          	jalr	1440(ra) # 80001a1c <insert_proc_to_list>
  sched();
    80002484:	00000097          	auipc	ra,0x0
    80002488:	edc080e7          	jalr	-292(ra) # 80002360 <sched>
  release(&p->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
}
    80002496:	60e2                	ld	ra,24(sp)
    80002498:	6442                	ld	s0,16(sp)
    8000249a:	64a2                	ld	s1,8(sp)
    8000249c:	6902                	ld	s2,0(sp)
    8000249e:	6105                	addi	sp,sp,32
    800024a0:	8082                	ret

00000000800024a2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800024a2:	7179                	addi	sp,sp,-48
    800024a4:	f406                	sd	ra,40(sp)
    800024a6:	f022                	sd	s0,32(sp)
    800024a8:	ec26                	sd	s1,24(sp)
    800024aa:	e84a                	sd	s2,16(sp)
    800024ac:	e44e                	sd	s3,8(sp)
    800024ae:	1800                	addi	s0,sp,48
    800024b0:	89aa                	mv	s3,a0
    800024b2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	a18080e7          	jalr	-1512(ra) # 80001ecc <myproc>
    800024bc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	726080e7          	jalr	1830(ra) # 80000be4 <acquire>
  release(lk);
    800024c6:	854a                	mv	a0,s2
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800024d0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800024d4:	4789                	li	a5,2
    800024d6:	cc9c                	sw	a5,24(s1)
  //printf("insert sleep sleep %d\n", p->index); //delete
  insert_proc_to_list(&sleeping_list, p);
    800024d8:	85a6                	mv	a1,s1
    800024da:	00006517          	auipc	a0,0x6
    800024de:	4a650513          	addi	a0,a0,1190 # 80008980 <sleeping_list>
    800024e2:	fffff097          	auipc	ra,0xfffff
    800024e6:	53a080e7          	jalr	1338(ra) # 80001a1c <insert_proc_to_list>

  sched();
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	e76080e7          	jalr	-394(ra) # 80002360 <sched>

  // Tidy up.
  p->chan = 0;
    800024f2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	7a0080e7          	jalr	1952(ra) # 80000c98 <release>
  acquire(lk);
    80002500:	854a                	mv	a0,s2
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	6e2080e7          	jalr	1762(ra) # 80000be4 <acquire>
}
    8000250a:	70a2                	ld	ra,40(sp)
    8000250c:	7402                	ld	s0,32(sp)
    8000250e:	64e2                	ld	s1,24(sp)
    80002510:	6942                	ld	s2,16(sp)
    80002512:	69a2                	ld	s3,8(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret

0000000080002518 <wait>:
{
    80002518:	715d                	addi	sp,sp,-80
    8000251a:	e486                	sd	ra,72(sp)
    8000251c:	e0a2                	sd	s0,64(sp)
    8000251e:	fc26                	sd	s1,56(sp)
    80002520:	f84a                	sd	s2,48(sp)
    80002522:	f44e                	sd	s3,40(sp)
    80002524:	f052                	sd	s4,32(sp)
    80002526:	ec56                	sd	s5,24(sp)
    80002528:	e85a                	sd	s6,16(sp)
    8000252a:	e45e                	sd	s7,8(sp)
    8000252c:	e062                	sd	s8,0(sp)
    8000252e:	0880                	addi	s0,sp,80
    80002530:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002532:	00000097          	auipc	ra,0x0
    80002536:	99a080e7          	jalr	-1638(ra) # 80001ecc <myproc>
    8000253a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000253c:	0000f517          	auipc	a0,0xf
    80002540:	2fc50513          	addi	a0,a0,764 # 80011838 <wait_lock>
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
    havekids = 0;
    8000254c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000254e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002550:	00015997          	auipc	s3,0x15
    80002554:	70098993          	addi	s3,s3,1792 # 80017c50 <tickslock>
        havekids = 1;
    80002558:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000255a:	0000fc17          	auipc	s8,0xf
    8000255e:	2dec0c13          	addi	s8,s8,734 # 80011838 <wait_lock>
    havekids = 0;
    80002562:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002564:	0000f497          	auipc	s1,0xf
    80002568:	2ec48493          	addi	s1,s1,748 # 80011850 <proc>
    8000256c:	a0bd                	j	800025da <wait+0xc2>
          pid = np->pid;
    8000256e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002572:	000b0e63          	beqz	s6,8000258e <wait+0x76>
    80002576:	4691                	li	a3,4
    80002578:	02c48613          	addi	a2,s1,44
    8000257c:	85da                	mv	a1,s6
    8000257e:	05093503          	ld	a0,80(s2)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	0f0080e7          	jalr	240(ra) # 80001672 <copyout>
    8000258a:	02054563          	bltz	a0,800025b4 <wait+0x9c>
          freeproc(np);
    8000258e:	8526                	mv	a0,s1
    80002590:	00000097          	auipc	ra,0x0
    80002594:	ae8080e7          	jalr	-1304(ra) # 80002078 <freeproc>
          release(&np->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
          release(&wait_lock);
    800025a2:	0000f517          	auipc	a0,0xf
    800025a6:	29650513          	addi	a0,a0,662 # 80011838 <wait_lock>
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6ee080e7          	jalr	1774(ra) # 80000c98 <release>
          return pid;
    800025b2:	a09d                	j	80002618 <wait+0x100>
            release(&np->lock);
    800025b4:	8526                	mv	a0,s1
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
            release(&wait_lock);
    800025be:	0000f517          	auipc	a0,0xf
    800025c2:	27a50513          	addi	a0,a0,634 # 80011838 <wait_lock>
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
            return -1;
    800025ce:	59fd                	li	s3,-1
    800025d0:	a0a1                	j	80002618 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800025d2:	19048493          	addi	s1,s1,400
    800025d6:	03348463          	beq	s1,s3,800025fe <wait+0xe6>
      if(np->parent == p){
    800025da:	7c9c                	ld	a5,56(s1)
    800025dc:	ff279be3          	bne	a5,s2,800025d2 <wait+0xba>
        acquire(&np->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	602080e7          	jalr	1538(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800025ea:	4c9c                	lw	a5,24(s1)
    800025ec:	f94781e3          	beq	a5,s4,8000256e <wait+0x56>
        release(&np->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
        havekids = 1;
    800025fa:	8756                	mv	a4,s5
    800025fc:	bfd9                	j	800025d2 <wait+0xba>
    if(!havekids || p->killed){
    800025fe:	c701                	beqz	a4,80002606 <wait+0xee>
    80002600:	02892783          	lw	a5,40(s2)
    80002604:	c79d                	beqz	a5,80002632 <wait+0x11a>
      release(&wait_lock);
    80002606:	0000f517          	auipc	a0,0xf
    8000260a:	23250513          	addi	a0,a0,562 # 80011838 <wait_lock>
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
      return -1;
    80002616:	59fd                	li	s3,-1
}
    80002618:	854e                	mv	a0,s3
    8000261a:	60a6                	ld	ra,72(sp)
    8000261c:	6406                	ld	s0,64(sp)
    8000261e:	74e2                	ld	s1,56(sp)
    80002620:	7942                	ld	s2,48(sp)
    80002622:	79a2                	ld	s3,40(sp)
    80002624:	7a02                	ld	s4,32(sp)
    80002626:	6ae2                	ld	s5,24(sp)
    80002628:	6b42                	ld	s6,16(sp)
    8000262a:	6ba2                	ld	s7,8(sp)
    8000262c:	6c02                	ld	s8,0(sp)
    8000262e:	6161                	addi	sp,sp,80
    80002630:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002632:	85e2                	mv	a1,s8
    80002634:	854a                	mv	a0,s2
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	e6c080e7          	jalr	-404(ra) # 800024a2 <sleep>
    havekids = 0;
    8000263e:	b715                	j	80002562 <wait+0x4a>

0000000080002640 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002640:	7179                	addi	sp,sp,-48
    80002642:	f406                	sd	ra,40(sp)
    80002644:	f022                	sd	s0,32(sp)
    80002646:	ec26                	sd	s1,24(sp)
    80002648:	e84a                	sd	s2,16(sp)
    8000264a:	e44e                	sd	s3,8(sp)
    8000264c:	1800                	addi	s0,sp,48
    8000264e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002650:	0000f497          	auipc	s1,0xf
    80002654:	20048493          	addi	s1,s1,512 # 80011850 <proc>
    80002658:	00015997          	auipc	s3,0x15
    8000265c:	5f898993          	addi	s3,s3,1528 # 80017c50 <tickslock>
    acquire(&p->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	582080e7          	jalr	1410(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000266a:	589c                	lw	a5,48(s1)
    8000266c:	01278d63          	beq	a5,s2,80002686 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	626080e7          	jalr	1574(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267a:	19048493          	addi	s1,s1,400
    8000267e:	ff3491e3          	bne	s1,s3,80002660 <kill+0x20>
  }
  return -1;
    80002682:	557d                	li	a0,-1
    80002684:	a829                	j	8000269e <kill+0x5e>
      p->killed = 1;
    80002686:	4785                	li	a5,1
    80002688:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000268a:	4c98                	lw	a4,24(s1)
    8000268c:	4789                	li	a5,2
    8000268e:	00f70f63          	beq	a4,a5,800026ac <kill+0x6c>
      release(&p->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
      return 0;
    8000269c:	4501                	li	a0,0
}
    8000269e:	70a2                	ld	ra,40(sp)
    800026a0:	7402                	ld	s0,32(sp)
    800026a2:	64e2                	ld	s1,24(sp)
    800026a4:	6942                	ld	s2,16(sp)
    800026a6:	69a2                	ld	s3,8(sp)
    800026a8:	6145                	addi	sp,sp,48
    800026aa:	8082                	ret
        remove_proc_to_list(&sleeping_list, p);
    800026ac:	85a6                	mv	a1,s1
    800026ae:	00006517          	auipc	a0,0x6
    800026b2:	2d250513          	addi	a0,a0,722 # 80008980 <sleeping_list>
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	4d6080e7          	jalr	1238(ra) # 80001b8c <remove_proc_to_list>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
    800026be:	1684a783          	lw	a5,360(s1)
    800026c2:	0b000713          	li	a4,176
    800026c6:	02e787b3          	mul	a5,a5,a4
    800026ca:	85a6                	mv	a1,s1
    800026cc:	0000f517          	auipc	a0,0xf
    800026d0:	c5450513          	addi	a0,a0,-940 # 80011320 <cpus+0x80>
    800026d4:	953e                	add	a0,a0,a5
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	346080e7          	jalr	838(ra) # 80001a1c <insert_proc_to_list>
        p->state = RUNNABLE;
    800026de:	478d                	li	a5,3
    800026e0:	cc9c                	sw	a5,24(s1)
    800026e2:	bf45                	j	80002692 <kill+0x52>

00000000800026e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026e4:	7179                	addi	sp,sp,-48
    800026e6:	f406                	sd	ra,40(sp)
    800026e8:	f022                	sd	s0,32(sp)
    800026ea:	ec26                	sd	s1,24(sp)
    800026ec:	e84a                	sd	s2,16(sp)
    800026ee:	e44e                	sd	s3,8(sp)
    800026f0:	e052                	sd	s4,0(sp)
    800026f2:	1800                	addi	s0,sp,48
    800026f4:	84aa                	mv	s1,a0
    800026f6:	892e                	mv	s2,a1
    800026f8:	89b2                	mv	s3,a2
    800026fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	7d0080e7          	jalr	2000(ra) # 80001ecc <myproc>
  if(user_dst){
    80002704:	c08d                	beqz	s1,80002726 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002706:	86d2                	mv	a3,s4
    80002708:	864e                	mv	a2,s3
    8000270a:	85ca                	mv	a1,s2
    8000270c:	6928                	ld	a0,80(a0)
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	f64080e7          	jalr	-156(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002716:	70a2                	ld	ra,40(sp)
    80002718:	7402                	ld	s0,32(sp)
    8000271a:	64e2                	ld	s1,24(sp)
    8000271c:	6942                	ld	s2,16(sp)
    8000271e:	69a2                	ld	s3,8(sp)
    80002720:	6a02                	ld	s4,0(sp)
    80002722:	6145                	addi	sp,sp,48
    80002724:	8082                	ret
    memmove((char *)dst, src, len);
    80002726:	000a061b          	sext.w	a2,s4
    8000272a:	85ce                	mv	a1,s3
    8000272c:	854a                	mv	a0,s2
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	612080e7          	jalr	1554(ra) # 80000d40 <memmove>
    return 0;
    80002736:	8526                	mv	a0,s1
    80002738:	bff9                	j	80002716 <either_copyout+0x32>

000000008000273a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	e052                	sd	s4,0(sp)
    80002748:	1800                	addi	s0,sp,48
    8000274a:	892a                	mv	s2,a0
    8000274c:	84ae                	mv	s1,a1
    8000274e:	89b2                	mv	s3,a2
    80002750:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	77a080e7          	jalr	1914(ra) # 80001ecc <myproc>
  if(user_src){
    8000275a:	c08d                	beqz	s1,8000277c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000275c:	86d2                	mv	a3,s4
    8000275e:	864e                	mv	a2,s3
    80002760:	85ca                	mv	a1,s2
    80002762:	6928                	ld	a0,80(a0)
    80002764:	fffff097          	auipc	ra,0xfffff
    80002768:	f9a080e7          	jalr	-102(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000276c:	70a2                	ld	ra,40(sp)
    8000276e:	7402                	ld	s0,32(sp)
    80002770:	64e2                	ld	s1,24(sp)
    80002772:	6942                	ld	s2,16(sp)
    80002774:	69a2                	ld	s3,8(sp)
    80002776:	6a02                	ld	s4,0(sp)
    80002778:	6145                	addi	sp,sp,48
    8000277a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000277c:	000a061b          	sext.w	a2,s4
    80002780:	85ce                	mv	a1,s3
    80002782:	854a                	mv	a0,s2
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	5bc080e7          	jalr	1468(ra) # 80000d40 <memmove>
    return 0;
    8000278c:	8526                	mv	a0,s1
    8000278e:	bff9                	j	8000276c <either_copyin+0x32>

0000000080002790 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002790:	715d                	addi	sp,sp,-80
    80002792:	e486                	sd	ra,72(sp)
    80002794:	e0a2                	sd	s0,64(sp)
    80002796:	fc26                	sd	s1,56(sp)
    80002798:	f84a                	sd	s2,48(sp)
    8000279a:	f44e                	sd	s3,40(sp)
    8000279c:	f052                	sd	s4,32(sp)
    8000279e:	ec56                	sd	s5,24(sp)
    800027a0:	e85a                	sd	s6,16(sp)
    800027a2:	e45e                	sd	s7,8(sp)
    800027a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027a6:	00006517          	auipc	a0,0x6
    800027aa:	92250513          	addi	a0,a0,-1758 # 800080c8 <digits+0x88>
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	dda080e7          	jalr	-550(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027b6:	0000f497          	auipc	s1,0xf
    800027ba:	1f248493          	addi	s1,s1,498 # 800119a8 <proc+0x158>
    800027be:	00015917          	auipc	s2,0x15
    800027c2:	5ea90913          	addi	s2,s2,1514 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800027c8:	00006997          	auipc	s3,0x6
    800027cc:	bc098993          	addi	s3,s3,-1088 # 80008388 <digits+0x348>
    printf("%d %s %s", p->pid, state, p->name);
    800027d0:	00006a97          	auipc	s5,0x6
    800027d4:	bc0a8a93          	addi	s5,s5,-1088 # 80008390 <digits+0x350>
    printf("\n");
    800027d8:	00006a17          	auipc	s4,0x6
    800027dc:	8f0a0a13          	addi	s4,s4,-1808 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e0:	00006b97          	auipc	s7,0x6
    800027e4:	c08b8b93          	addi	s7,s7,-1016 # 800083e8 <states.1825>
    800027e8:	a00d                	j	8000280a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027ea:	ed86a583          	lw	a1,-296(a3)
    800027ee:	8556                	mv	a0,s5
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	d98080e7          	jalr	-616(ra) # 80000588 <printf>
    printf("\n");
    800027f8:	8552                	mv	a0,s4
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d8e080e7          	jalr	-626(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002802:	19048493          	addi	s1,s1,400
    80002806:	03248163          	beq	s1,s2,80002828 <procdump+0x98>
    if(p->state == UNUSED)
    8000280a:	86a6                	mv	a3,s1
    8000280c:	ec04a783          	lw	a5,-320(s1)
    80002810:	dbed                	beqz	a5,80002802 <procdump+0x72>
      state = "???"; 
    80002812:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002814:	fcfb6be3          	bltu	s6,a5,800027ea <procdump+0x5a>
    80002818:	1782                	slli	a5,a5,0x20
    8000281a:	9381                	srli	a5,a5,0x20
    8000281c:	078e                	slli	a5,a5,0x3
    8000281e:	97de                	add	a5,a5,s7
    80002820:	6390                	ld	a2,0(a5)
    80002822:	f661                	bnez	a2,800027ea <procdump+0x5a>
      state = "???"; 
    80002824:	864e                	mv	a2,s3
    80002826:	b7d1                	j	800027ea <procdump+0x5a>
  }
}
    80002828:	60a6                	ld	ra,72(sp)
    8000282a:	6406                	ld	s0,64(sp)
    8000282c:	74e2                	ld	s1,56(sp)
    8000282e:	7942                	ld	s2,48(sp)
    80002830:	79a2                	ld	s3,40(sp)
    80002832:	7a02                	ld	s4,32(sp)
    80002834:	6ae2                	ld	s5,24(sp)
    80002836:	6b42                	ld	s6,16(sp)
    80002838:	6ba2                	ld	s7,8(sp)
    8000283a:	6161                	addi	sp,sp,80
    8000283c:	8082                	ret

000000008000283e <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    8000283e:	1101                	addi	sp,sp,-32
    80002840:	ec06                	sd	ra,24(sp)
    80002842:	e822                	sd	s0,16(sp)
    80002844:	e426                	sd	s1,8(sp)
    80002846:	e04a                	sd	s2,0(sp)
    80002848:	1000                	addi	s0,sp,32
    8000284a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	680080e7          	jalr	1664(ra) # 80001ecc <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002854:	0004871b          	sext.w	a4,s1
    80002858:	479d                	li	a5,7
    8000285a:	02e7e963          	bltu	a5,a4,8000288c <set_cpu+0x4e>
    8000285e:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	384080e7          	jalr	900(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002868:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    8000286c:	854a                	mv	a0,s2
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>

    yield();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	bcc080e7          	jalr	-1076(ra) # 80002442 <yield>

    return cpu_num;
    8000287e:	8526                	mv	a0,s1
  }
  return -1;
}
    80002880:	60e2                	ld	ra,24(sp)
    80002882:	6442                	ld	s0,16(sp)
    80002884:	64a2                	ld	s1,8(sp)
    80002886:	6902                	ld	s2,0(sp)
    80002888:	6105                	addi	sp,sp,32
    8000288a:	8082                	ret
  return -1;
    8000288c:	557d                	li	a0,-1
    8000288e:	bfcd                	j	80002880 <set_cpu+0x42>

0000000080002890 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002890:	1141                	addi	sp,sp,-16
    80002892:	e406                	sd	ra,8(sp)
    80002894:	e022                	sd	s0,0(sp)
    80002896:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	634080e7          	jalr	1588(ra) # 80001ecc <myproc>
  return p->last_cpu;
}
    800028a0:	16852503          	lw	a0,360(a0)
    800028a4:	60a2                	ld	ra,8(sp)
    800028a6:	6402                	ld	s0,0(sp)
    800028a8:	0141                	addi	sp,sp,16
    800028aa:	8082                	ret

00000000800028ac <min_cpu_process_count>:

int
min_cpu_process_count(void){
    800028ac:	1141                	addi	sp,sp,-16
    800028ae:	e422                	sd	s0,8(sp)
    800028b0:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
  min_cpu = cpus;
    800028b2:	0000f617          	auipc	a2,0xf
    800028b6:	9ee60613          	addi	a2,a2,-1554 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL ; c++){
    800028ba:	0000f797          	auipc	a5,0xf
    800028be:	a9678793          	addi	a5,a5,-1386 # 80011350 <cpus+0xb0>
    800028c2:	0000f597          	auipc	a1,0xf
    800028c6:	f5e58593          	addi	a1,a1,-162 # 80011820 <pid_lock>
    800028ca:	a029                	j	800028d4 <min_cpu_process_count+0x28>
    800028cc:	0b078793          	addi	a5,a5,176
    800028d0:	00b78863          	beq	a5,a1,800028e0 <min_cpu_process_count+0x34>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    800028d4:	77d4                	ld	a3,168(a5)
    800028d6:	7658                	ld	a4,168(a2)
    800028d8:	fee6fae3          	bgeu	a3,a4,800028cc <min_cpu_process_count+0x20>
    800028dc:	863e                	mv	a2,a5
    800028de:	b7fd                	j	800028cc <min_cpu_process_count+0x20>
      min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    800028e0:	0a062503          	lw	a0,160(a2)
    800028e4:	6422                	ld	s0,8(sp)
    800028e6:	0141                	addi	sp,sp,16
    800028e8:	8082                	ret

00000000800028ea <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    800028ea:	1141                	addi	sp,sp,-16
    800028ec:	e422                	sd	s0,8(sp)
    800028ee:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL) 
    800028f0:	fff5071b          	addiw	a4,a0,-1
    800028f4:	4799                	li	a5,6
    800028f6:	02e7e063          	bltu	a5,a4,80002916 <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    800028fa:	0b000793          	li	a5,176
    800028fe:	02f50533          	mul	a0,a0,a5
    80002902:	0000f797          	auipc	a5,0xf
    80002906:	99e78793          	addi	a5,a5,-1634 # 800112a0 <cpus>
    8000290a:	953e                	add	a0,a0,a5
    8000290c:	0a852503          	lw	a0,168(a0)
  return -1;
}
    80002910:	6422                	ld	s0,8(sp)
    80002912:	0141                	addi	sp,sp,16
    80002914:	8082                	ret
  return -1;
    80002916:	557d                	li	a0,-1
    80002918:	bfe5                	j	80002910 <cpu_process_count+0x26>

000000008000291a <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    8000291a:	1101                	addi	sp,sp,-32
    8000291c:	ec06                	sd	ra,24(sp)
    8000291e:	e822                	sd	s0,16(sp)
    80002920:	e426                	sd	s1,8(sp)
    80002922:	e04a                	sd	s2,0(sp)
    80002924:	1000                	addi	s0,sp,32
    80002926:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002928:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    8000292c:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    8000292e:	0015861b          	addiw	a2,a1,1
    80002932:	2581                	sext.w	a1,a1
    80002934:	854a                	mv	a0,s2
    80002936:	00004097          	auipc	ra,0x4
    8000293a:	220080e7          	jalr	544(ra) # 80006b56 <cas>
    8000293e:	2501                	sext.w	a0,a0
    80002940:	f575                	bnez	a0,8000292c <increment_cpu_process_count+0x12>
}
    80002942:	60e2                	ld	ra,24(sp)
    80002944:	6442                	ld	s0,16(sp)
    80002946:	64a2                	ld	s1,8(sp)
    80002948:	6902                	ld	s2,0(sp)
    8000294a:	6105                	addi	sp,sp,32
    8000294c:	8082                	ret

000000008000294e <fork>:
{
    8000294e:	7139                	addi	sp,sp,-64
    80002950:	fc06                	sd	ra,56(sp)
    80002952:	f822                	sd	s0,48(sp)
    80002954:	f426                	sd	s1,40(sp)
    80002956:	f04a                	sd	s2,32(sp)
    80002958:	ec4e                	sd	s3,24(sp)
    8000295a:	e852                	sd	s4,16(sp)
    8000295c:	e456                	sd	s5,8(sp)
    8000295e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002960:	fffff097          	auipc	ra,0xfffff
    80002964:	56c080e7          	jalr	1388(ra) # 80001ecc <myproc>
    80002968:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	78a080e7          	jalr	1930(ra) # 800020f4 <allocproc>
    80002972:	14050c63          	beqz	a0,80002aca <fork+0x17c>
    80002976:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002978:	0489b603          	ld	a2,72(s3)
    8000297c:	692c                	ld	a1,80(a0)
    8000297e:	0509b503          	ld	a0,80(s3)
    80002982:	fffff097          	auipc	ra,0xfffff
    80002986:	bec080e7          	jalr	-1044(ra) # 8000156e <uvmcopy>
    8000298a:	04054663          	bltz	a0,800029d6 <fork+0x88>
  np->sz = p->sz;
    8000298e:	0489b783          	ld	a5,72(s3)
    80002992:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80002996:	0589b683          	ld	a3,88(s3)
    8000299a:	87b6                	mv	a5,a3
    8000299c:	05893703          	ld	a4,88(s2)
    800029a0:	12068693          	addi	a3,a3,288
    800029a4:	0007b803          	ld	a6,0(a5)
    800029a8:	6788                	ld	a0,8(a5)
    800029aa:	6b8c                	ld	a1,16(a5)
    800029ac:	6f90                	ld	a2,24(a5)
    800029ae:	01073023          	sd	a6,0(a4)
    800029b2:	e708                	sd	a0,8(a4)
    800029b4:	eb0c                	sd	a1,16(a4)
    800029b6:	ef10                	sd	a2,24(a4)
    800029b8:	02078793          	addi	a5,a5,32
    800029bc:	02070713          	addi	a4,a4,32
    800029c0:	fed792e3          	bne	a5,a3,800029a4 <fork+0x56>
  np->trapframe->a0 = 0;
    800029c4:	05893783          	ld	a5,88(s2)
    800029c8:	0607b823          	sd	zero,112(a5)
    800029cc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800029d0:	15000a13          	li	s4,336
    800029d4:	a03d                	j	80002a02 <fork+0xb4>
    freeproc(np);
    800029d6:	854a                	mv	a0,s2
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	6a0080e7          	jalr	1696(ra) # 80002078 <freeproc>
    release(&np->lock);
    800029e0:	854a                	mv	a0,s2
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	2b6080e7          	jalr	694(ra) # 80000c98 <release>
    return -1;
    800029ea:	5afd                	li	s5,-1
    800029ec:	a0e9                	j	80002ab6 <fork+0x168>
      np->ofile[i] = filedup(p->ofile[i]);
    800029ee:	00002097          	auipc	ra,0x2
    800029f2:	422080e7          	jalr	1058(ra) # 80004e10 <filedup>
    800029f6:	009907b3          	add	a5,s2,s1
    800029fa:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800029fc:	04a1                	addi	s1,s1,8
    800029fe:	01448763          	beq	s1,s4,80002a0c <fork+0xbe>
    if(p->ofile[i])
    80002a02:	009987b3          	add	a5,s3,s1
    80002a06:	6388                	ld	a0,0(a5)
    80002a08:	f17d                	bnez	a0,800029ee <fork+0xa0>
    80002a0a:	bfcd                	j	800029fc <fork+0xae>
  np->cwd = idup(p->cwd);
    80002a0c:	1509b503          	ld	a0,336(s3)
    80002a10:	00001097          	auipc	ra,0x1
    80002a14:	576080e7          	jalr	1398(ra) # 80003f86 <idup>
    80002a18:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002a1c:	4641                	li	a2,16
    80002a1e:	15898593          	addi	a1,s3,344
    80002a22:	15890513          	addi	a0,s2,344
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	40c080e7          	jalr	1036(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002a2e:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002a32:	854a                	mv	a0,s2
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	264080e7          	jalr	612(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002a3c:	0000fa17          	auipc	s4,0xf
    80002a40:	864a0a13          	addi	s4,s4,-1948 # 800112a0 <cpus>
    80002a44:	0000f497          	auipc	s1,0xf
    80002a48:	df448493          	addi	s1,s1,-524 # 80011838 <wait_lock>
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	196080e7          	jalr	406(ra) # 80000be4 <acquire>
  np->parent = p;
    80002a56:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002a64:	854a                	mv	a0,s2
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	17e080e7          	jalr	382(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002a6e:	478d                	li	a5,3
    80002a70:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002a74:	1689a783          	lw	a5,360(s3)
    80002a78:	16f92423          	sw	a5,360(s2)
      np->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	e30080e7          	jalr	-464(ra) # 800028ac <min_cpu_process_count>
    80002a84:	16a92423          	sw	a0,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    80002a88:	0b000493          	li	s1,176
    80002a8c:	029504b3          	mul	s1,a0,s1
  increment_cpu_process_count(c);
    80002a90:	009a0533          	add	a0,s4,s1
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	e86080e7          	jalr	-378(ra) # 8000291a <increment_cpu_process_count>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002a9c:	08048513          	addi	a0,s1,128
    80002aa0:	85ca                	mv	a1,s2
    80002aa2:	9552                	add	a0,a0,s4
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	f78080e7          	jalr	-136(ra) # 80001a1c <insert_proc_to_list>
  release(&np->lock);
    80002aac:	854a                	mv	a0,s2
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	1ea080e7          	jalr	490(ra) # 80000c98 <release>
}
    80002ab6:	8556                	mv	a0,s5
    80002ab8:	70e2                	ld	ra,56(sp)
    80002aba:	7442                	ld	s0,48(sp)
    80002abc:	74a2                	ld	s1,40(sp)
    80002abe:	7902                	ld	s2,32(sp)
    80002ac0:	69e2                	ld	s3,24(sp)
    80002ac2:	6a42                	ld	s4,16(sp)
    80002ac4:	6aa2                	ld	s5,8(sp)
    80002ac6:	6121                	addi	sp,sp,64
    80002ac8:	8082                	ret
    return -1;
    80002aca:	5afd                	li	s5,-1
    80002acc:	b7ed                	j	80002ab6 <fork+0x168>

0000000080002ace <wakeup>:
{
    80002ace:	7159                	addi	sp,sp,-112
    80002ad0:	f486                	sd	ra,104(sp)
    80002ad2:	f0a2                	sd	s0,96(sp)
    80002ad4:	eca6                	sd	s1,88(sp)
    80002ad6:	e8ca                	sd	s2,80(sp)
    80002ad8:	e4ce                	sd	s3,72(sp)
    80002ada:	e0d2                	sd	s4,64(sp)
    80002adc:	fc56                	sd	s5,56(sp)
    80002ade:	f85a                	sd	s6,48(sp)
    80002ae0:	f45e                	sd	s7,40(sp)
    80002ae2:	f062                	sd	s8,32(sp)
    80002ae4:	ec66                	sd	s9,24(sp)
    80002ae6:	e86a                	sd	s10,16(sp)
    80002ae8:	e46e                	sd	s11,8(sp)
    80002aea:	1880                	addi	s0,sp,112
    80002aec:	8c2a                	mv	s8,a0
  int curr = get_head(&sleeping_list);
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	e9250513          	addi	a0,a0,-366 # 80008980 <sleeping_list>
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	ed0080e7          	jalr	-304(ra) # 800019c6 <get_head>
  while(curr != -1) {
    80002afe:	57fd                	li	a5,-1
    80002b00:	0af50263          	beq	a0,a5,80002ba4 <wakeup+0xd6>
    80002b04:	892a                	mv	s2,a0
    p = &proc[curr];
    80002b06:	19000a13          	li	s4,400
    80002b0a:	0000f997          	auipc	s3,0xf
    80002b0e:	d4698993          	addi	s3,s3,-698 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002b12:	4b89                	li	s7,2
        p->state = RUNNABLE;
    80002b14:	4d8d                	li	s11,3
    80002b16:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002b1a:	0000ec97          	auipc	s9,0xe
    80002b1e:	786c8c93          	addi	s9,s9,1926 # 800112a0 <cpus>
  while(curr != -1) {
    80002b22:	5b7d                	li	s6,-1
    80002b24:	a801                	j	80002b34 <wakeup+0x66>
      release(&p->lock);
    80002b26:	8526                	mv	a0,s1
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	170080e7          	jalr	368(ra) # 80000c98 <release>
  while(curr != -1) {
    80002b30:	07690a63          	beq	s2,s6,80002ba4 <wakeup+0xd6>
    p = &proc[curr];
    80002b34:	034904b3          	mul	s1,s2,s4
    80002b38:	94ce                	add	s1,s1,s3
    curr = p->next_index;
    80002b3a:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	38e080e7          	jalr	910(ra) # 80001ecc <myproc>
    80002b46:	fea485e3          	beq	s1,a0,80002b30 <wakeup+0x62>
      acquire(&p->lock);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	098080e7          	jalr	152(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002b54:	4c9c                	lw	a5,24(s1)
    80002b56:	fd7798e3          	bne	a5,s7,80002b26 <wakeup+0x58>
    80002b5a:	709c                	ld	a5,32(s1)
    80002b5c:	fd8795e3          	bne	a5,s8,80002b26 <wakeup+0x58>
        remove_proc_to_list(&sleeping_list, p);
    80002b60:	85a6                	mv	a1,s1
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	e1e50513          	addi	a0,a0,-482 # 80008980 <sleeping_list>
    80002b6a:	fffff097          	auipc	ra,0xfffff
    80002b6e:	022080e7          	jalr	34(ra) # 80001b8c <remove_proc_to_list>
        p->state = RUNNABLE;
    80002b72:	01b4ac23          	sw	s11,24(s1)
            p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	d36080e7          	jalr	-714(ra) # 800028ac <min_cpu_process_count>
    80002b7e:	16a4a423          	sw	a0,360(s1)
        c = &cpus[p->last_cpu];
    80002b82:	03a50ab3          	mul	s5,a0,s10
        increment_cpu_process_count(c);
    80002b86:	015c8533          	add	a0,s9,s5
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	d90080e7          	jalr	-624(ra) # 8000291a <increment_cpu_process_count>
        insert_proc_to_list(&(c->runnable_list), p);
    80002b92:	080a8513          	addi	a0,s5,128
    80002b96:	85a6                	mv	a1,s1
    80002b98:	9566                	add	a0,a0,s9
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	e82080e7          	jalr	-382(ra) # 80001a1c <insert_proc_to_list>
    80002ba2:	b751                	j	80002b26 <wakeup+0x58>
}
    80002ba4:	70a6                	ld	ra,104(sp)
    80002ba6:	7406                	ld	s0,96(sp)
    80002ba8:	64e6                	ld	s1,88(sp)
    80002baa:	6946                	ld	s2,80(sp)
    80002bac:	69a6                	ld	s3,72(sp)
    80002bae:	6a06                	ld	s4,64(sp)
    80002bb0:	7ae2                	ld	s5,56(sp)
    80002bb2:	7b42                	ld	s6,48(sp)
    80002bb4:	7ba2                	ld	s7,40(sp)
    80002bb6:	7c02                	ld	s8,32(sp)
    80002bb8:	6ce2                	ld	s9,24(sp)
    80002bba:	6d42                	ld	s10,16(sp)
    80002bbc:	6da2                	ld	s11,8(sp)
    80002bbe:	6165                	addi	sp,sp,112
    80002bc0:	8082                	ret

0000000080002bc2 <reparent>:
{
    80002bc2:	7179                	addi	sp,sp,-48
    80002bc4:	f406                	sd	ra,40(sp)
    80002bc6:	f022                	sd	s0,32(sp)
    80002bc8:	ec26                	sd	s1,24(sp)
    80002bca:	e84a                	sd	s2,16(sp)
    80002bcc:	e44e                	sd	s3,8(sp)
    80002bce:	e052                	sd	s4,0(sp)
    80002bd0:	1800                	addi	s0,sp,48
    80002bd2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002bd4:	0000f497          	auipc	s1,0xf
    80002bd8:	c7c48493          	addi	s1,s1,-900 # 80011850 <proc>
      pp->parent = initproc;
    80002bdc:	00006a17          	auipc	s4,0x6
    80002be0:	44ca0a13          	addi	s4,s4,1100 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002be4:	00015997          	auipc	s3,0x15
    80002be8:	06c98993          	addi	s3,s3,108 # 80017c50 <tickslock>
    80002bec:	a029                	j	80002bf6 <reparent+0x34>
    80002bee:	19048493          	addi	s1,s1,400
    80002bf2:	01348d63          	beq	s1,s3,80002c0c <reparent+0x4a>
    if(pp->parent == p){
    80002bf6:	7c9c                	ld	a5,56(s1)
    80002bf8:	ff279be3          	bne	a5,s2,80002bee <reparent+0x2c>
      pp->parent = initproc;
    80002bfc:	000a3503          	ld	a0,0(s4)
    80002c00:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	ecc080e7          	jalr	-308(ra) # 80002ace <wakeup>
    80002c0a:	b7d5                	j	80002bee <reparent+0x2c>
}
    80002c0c:	70a2                	ld	ra,40(sp)
    80002c0e:	7402                	ld	s0,32(sp)
    80002c10:	64e2                	ld	s1,24(sp)
    80002c12:	6942                	ld	s2,16(sp)
    80002c14:	69a2                	ld	s3,8(sp)
    80002c16:	6a02                	ld	s4,0(sp)
    80002c18:	6145                	addi	sp,sp,48
    80002c1a:	8082                	ret

0000000080002c1c <exit>:
{
    80002c1c:	7179                	addi	sp,sp,-48
    80002c1e:	f406                	sd	ra,40(sp)
    80002c20:	f022                	sd	s0,32(sp)
    80002c22:	ec26                	sd	s1,24(sp)
    80002c24:	e84a                	sd	s2,16(sp)
    80002c26:	e44e                	sd	s3,8(sp)
    80002c28:	e052                	sd	s4,0(sp)
    80002c2a:	1800                	addi	s0,sp,48
    80002c2c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	29e080e7          	jalr	670(ra) # 80001ecc <myproc>
    80002c36:	89aa                	mv	s3,a0
  if(p == initproc)
    80002c38:	00006797          	auipc	a5,0x6
    80002c3c:	3f07b783          	ld	a5,1008(a5) # 80009028 <initproc>
    80002c40:	0d050493          	addi	s1,a0,208
    80002c44:	15050913          	addi	s2,a0,336
    80002c48:	02a79363          	bne	a5,a0,80002c6e <exit+0x52>
    panic("init exiting");
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	75450513          	addi	a0,a0,1876 # 800083a0 <digits+0x360>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>
      fileclose(f);
    80002c5c:	00002097          	auipc	ra,0x2
    80002c60:	206080e7          	jalr	518(ra) # 80004e62 <fileclose>
      p->ofile[fd] = 0;
    80002c64:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002c68:	04a1                	addi	s1,s1,8
    80002c6a:	01248563          	beq	s1,s2,80002c74 <exit+0x58>
    if(p->ofile[fd]){
    80002c6e:	6088                	ld	a0,0(s1)
    80002c70:	f575                	bnez	a0,80002c5c <exit+0x40>
    80002c72:	bfdd                	j	80002c68 <exit+0x4c>
  begin_op();
    80002c74:	00002097          	auipc	ra,0x2
    80002c78:	d22080e7          	jalr	-734(ra) # 80004996 <begin_op>
  iput(p->cwd);
    80002c7c:	1509b503          	ld	a0,336(s3)
    80002c80:	00001097          	auipc	ra,0x1
    80002c84:	4fe080e7          	jalr	1278(ra) # 8000417e <iput>
  end_op();
    80002c88:	00002097          	auipc	ra,0x2
    80002c8c:	d8e080e7          	jalr	-626(ra) # 80004a16 <end_op>
  p->cwd = 0;
    80002c90:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002c94:	0000f497          	auipc	s1,0xf
    80002c98:	ba448493          	addi	s1,s1,-1116 # 80011838 <wait_lock>
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	f46080e7          	jalr	-186(ra) # 80000be4 <acquire>
  reparent(p);
    80002ca6:	854e                	mv	a0,s3
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	f1a080e7          	jalr	-230(ra) # 80002bc2 <reparent>
  wakeup(p->parent);
    80002cb0:	0389b503          	ld	a0,56(s3)
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	e1a080e7          	jalr	-486(ra) # 80002ace <wakeup>
  acquire(&p->lock);
    80002cbc:	854e                	mv	a0,s3
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	f26080e7          	jalr	-218(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002cc6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002cca:	4795                	li	a5,5
    80002ccc:	00f9ac23          	sw	a5,24(s3)
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002cd0:	85ce                	mv	a1,s3
    80002cd2:	00006517          	auipc	a0,0x6
    80002cd6:	cce50513          	addi	a0,a0,-818 # 800089a0 <zombie_list>
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	d42080e7          	jalr	-702(ra) # 80001a1c <insert_proc_to_list>
  release(&wait_lock);
    80002ce2:	8526                	mv	a0,s1
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>
  sched();
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	674080e7          	jalr	1652(ra) # 80002360 <sched>
  panic("zombie exit");
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	6bc50513          	addi	a0,a0,1724 # 800083b0 <digits+0x370>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>

0000000080002d04 <steal_process>:

void
steal_process(struct cpu *curr_c){  
    80002d04:	711d                	addi	sp,sp,-96
    80002d06:	ec86                	sd	ra,88(sp)
    80002d08:	e8a2                	sd	s0,80(sp)
    80002d0a:	e4a6                	sd	s1,72(sp)
    80002d0c:	e0ca                	sd	s2,64(sp)
    80002d0e:	fc4e                	sd	s3,56(sp)
    80002d10:	f852                	sd	s4,48(sp)
    80002d12:	f456                	sd	s5,40(sp)
    80002d14:	f05a                	sd	s6,32(sp)
    80002d16:	ec5e                	sd	s7,24(sp)
    80002d18:	e862                	sd	s8,16(sp)
    80002d1a:	e466                	sd	s9,8(sp)
    80002d1c:	e06a                	sd	s10,0(sp)
    80002d1e:	1080                	addi	s0,sp,96
    80002d20:	89aa                	mv	s3,a0
  struct cpu *c;
  struct proc *p;
  struct _list *lst;
  int stolen_process;
  int succeed = 0;
    80002d22:	4901                	li	s2,0
  for(c = cpus; c < &cpus[NCPU] && c->cpu_id < CPUS && !succeed ; c++){
    80002d24:	0000e497          	auipc	s1,0xe
    80002d28:	57c48493          	addi	s1,s1,1404 # 800112a0 <cpus>
    80002d2c:	4a09                	li	s4,2
      if(c != curr_c){
        lst = &c->runnable_list;
        acquire(&lst->head_lock);
        if(!isEmpty(lst)){ 
    80002d2e:	5b7d                	li	s6,-1
          stolen_process = lst->head;
          p = &proc[stolen_process];
    80002d30:	19000c13          	li	s8,400
    80002d34:	0000fb97          	auipc	s7,0xf
    80002d38:	b1cb8b93          	addi	s7,s7,-1252 # 80011850 <proc>
  for(c = cpus; c < &cpus[NCPU] && c->cpu_id < CPUS && !succeed ; c++){
    80002d3c:	0000fa97          	auipc	s5,0xf
    80002d40:	ae4a8a93          	addi	s5,s5,-1308 # 80011820 <pid_lock>
    80002d44:	a811                	j	80002d58 <steal_process+0x54>
          acquire(&p->lock);
          succeed = remove_head_from_list(lst);
          release(&p->lock);
        }
        else{
          release(&lst->head_lock);
    80002d46:	856a                	mv	a0,s10
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	f50080e7          	jalr	-176(ra) # 80000c98 <release>
  for(c = cpus; c < &cpus[NCPU] && c->cpu_id < CPUS && !succeed ; c++){
    80002d50:	0b048493          	addi	s1,s1,176
    80002d54:	05548b63          	beq	s1,s5,80002daa <steal_process+0xa6>
    80002d58:	0a04a783          	lw	a5,160(s1)
    80002d5c:	04fa4763          	blt	s4,a5,80002daa <steal_process+0xa6>
    80002d60:	06091563          	bnez	s2,80002dca <steal_process+0xc6>
      if(c != curr_c){
    80002d64:	fe9986e3          	beq	s3,s1,80002d50 <steal_process+0x4c>
        acquire(&lst->head_lock);
    80002d68:	08848d13          	addi	s10,s1,136
    80002d6c:	856a                	mv	a0,s10
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	e76080e7          	jalr	-394(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002d76:	0804a783          	lw	a5,128(s1)
        if(!isEmpty(lst)){ 
    80002d7a:	fd6786e3          	beq	a5,s6,80002d46 <steal_process+0x42>
          p = &proc[stolen_process];
    80002d7e:	038787b3          	mul	a5,a5,s8
    80002d82:	01778cb3          	add	s9,a5,s7
          acquire(&p->lock);
    80002d86:	8566                	mv	a0,s9
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	e5c080e7          	jalr	-420(ra) # 80000be4 <acquire>
          succeed = remove_head_from_list(lst);
    80002d90:	08048513          	addi	a0,s1,128
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	d6a080e7          	jalr	-662(ra) # 80001afe <remove_head_from_list>
    80002d9c:	892a                	mv	s2,a0
          release(&p->lock);
    80002d9e:	8566                	mv	a0,s9
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	ef8080e7          	jalr	-264(ra) # 80000c98 <release>
    80002da8:	b765                	j	80002d50 <steal_process+0x4c>
        }
      }
  }
  if(succeed){
    80002daa:	02091063          	bnez	s2,80002dca <steal_process+0xc6>
    insert_proc_to_list(&curr_c->runnable_list, p);
    p->last_cpu = curr_c->cpu_id;
    increment_cpu_process_count(curr_c); 
    release(&p->lock);
  }
    80002dae:	60e6                	ld	ra,88(sp)
    80002db0:	6446                	ld	s0,80(sp)
    80002db2:	64a6                	ld	s1,72(sp)
    80002db4:	6906                	ld	s2,64(sp)
    80002db6:	79e2                	ld	s3,56(sp)
    80002db8:	7a42                	ld	s4,48(sp)
    80002dba:	7aa2                	ld	s5,40(sp)
    80002dbc:	7b02                	ld	s6,32(sp)
    80002dbe:	6be2                	ld	s7,24(sp)
    80002dc0:	6c42                	ld	s8,16(sp)
    80002dc2:	6ca2                	ld	s9,8(sp)
    80002dc4:	6d02                	ld	s10,0(sp)
    80002dc6:	6125                	addi	sp,sp,96
    80002dc8:	8082                	ret
    acquire(&p->lock);
    80002dca:	8566                	mv	a0,s9
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	e18080e7          	jalr	-488(ra) # 80000be4 <acquire>
    insert_proc_to_list(&curr_c->runnable_list, p);
    80002dd4:	85e6                	mv	a1,s9
    80002dd6:	08098513          	addi	a0,s3,128
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	c42080e7          	jalr	-958(ra) # 80001a1c <insert_proc_to_list>
    p->last_cpu = curr_c->cpu_id;
    80002de2:	0a09a783          	lw	a5,160(s3)
    80002de6:	16fca423          	sw	a5,360(s9)
    increment_cpu_process_count(curr_c); 
    80002dea:	854e                	mv	a0,s3
    80002dec:	00000097          	auipc	ra,0x0
    80002df0:	b2e080e7          	jalr	-1234(ra) # 8000291a <increment_cpu_process_count>
    release(&p->lock);
    80002df4:	8566                	mv	a0,s9
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	ea2080e7          	jalr	-350(ra) # 80000c98 <release>
    80002dfe:	bf45                	j	80002dae <steal_process+0xaa>

0000000080002e00 <scheduler>:
{
    80002e00:	711d                	addi	sp,sp,-96
    80002e02:	ec86                	sd	ra,88(sp)
    80002e04:	e8a2                	sd	s0,80(sp)
    80002e06:	e4a6                	sd	s1,72(sp)
    80002e08:	e0ca                	sd	s2,64(sp)
    80002e0a:	fc4e                	sd	s3,56(sp)
    80002e0c:	f852                	sd	s4,48(sp)
    80002e0e:	f456                	sd	s5,40(sp)
    80002e10:	f05a                	sd	s6,32(sp)
    80002e12:	ec5e                	sd	s7,24(sp)
    80002e14:	e862                	sd	s8,16(sp)
    80002e16:	e466                	sd	s9,8(sp)
    80002e18:	e06a                	sd	s10,0(sp)
    80002e1a:	1080                	addi	s0,sp,96
    80002e1c:	8712                	mv	a4,tp
  int id = r_tp();
    80002e1e:	2701                	sext.w	a4,a4
  struct cpu *c = &cpus[id];
    80002e20:	0b000793          	li	a5,176
    80002e24:	02f707b3          	mul	a5,a4,a5
    80002e28:	0000eb97          	auipc	s7,0xe
    80002e2c:	478b8b93          	addi	s7,s7,1144 # 800112a0 <cpus>
    80002e30:	00fb8b33          	add	s6,s7,a5
  c->proc = 0;
    80002e34:	000b3023          	sd	zero,0(s6)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002e38:	08078a93          	addi	s5,a5,128
    80002e3c:	9ade                	add	s5,s5,s7
          swtch(&c->context, &p->context);
    80002e3e:	07a1                	addi	a5,a5,8
    80002e40:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    80002e42:	895a                	mv	s2,s6
      if(p->state == RUNNABLE) {
    80002e44:	0000f997          	auipc	s3,0xf
    80002e48:	a0c98993          	addi	s3,s3,-1524 # 80011850 <proc>
    80002e4c:	19000a13          	li	s4,400
    80002e50:	a081                	j	80002e90 <scheduler+0x90>
          remove_proc_to_list(&(c->runnable_list), p);
    80002e52:	85e2                	mv	a1,s8
    80002e54:	8556                	mv	a0,s5
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	d36080e7          	jalr	-714(ra) # 80001b8c <remove_proc_to_list>
          p->state = RUNNING;
    80002e5e:	4711                	li	a4,4
    80002e60:	00ec2c23          	sw	a4,24(s8)
          c->proc = p;
    80002e64:	01893023          	sd	s8,0(s2)
          p->last_cpu = c->cpu_id;
    80002e68:	0a092703          	lw	a4,160(s2)
    80002e6c:	16ec2423          	sw	a4,360(s8)
          swtch(&c->context, &p->context);
    80002e70:	060d0593          	addi	a1,s10,96
    80002e74:	95ce                	add	a1,a1,s3
    80002e76:	855e                	mv	a0,s7
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	06c080e7          	jalr	108(ra) # 80002ee4 <swtch>
          c->proc = 0;
    80002e80:	00093023          	sd	zero,0(s2)
    80002e84:	a891                	j	80002ed8 <scheduler+0xd8>
        steal_process(c);
    80002e86:	855a                	mv	a0,s6
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	e7c080e7          	jalr	-388(ra) # 80002d04 <steal_process>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e98:	10079073          	csrw	sstatus,a5
      if(p->state == RUNNABLE) {
    80002e9c:	4c8d                	li	s9,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002e9e:	5c7d                	li	s8,-1
    80002ea0:	08092783          	lw	a5,128(s2)
    80002ea4:	ff8781e3          	beq	a5,s8,80002e86 <scheduler+0x86>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002ea8:	8556                	mv	a0,s5
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	b1c080e7          	jalr	-1252(ra) # 800019c6 <get_head>
      if(p->state == RUNNABLE) {
    80002eb2:	034507b3          	mul	a5,a0,s4
    80002eb6:	97ce                	add	a5,a5,s3
    80002eb8:	4f9c                	lw	a5,24(a5)
    80002eba:	ff9793e3          	bne	a5,s9,80002ea0 <scheduler+0xa0>
    80002ebe:	03450d33          	mul	s10,a0,s4
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002ec2:	013d0c33          	add	s8,s10,s3
        acquire(&p->lock);
    80002ec6:	8562                	mv	a0,s8
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	d1c080e7          	jalr	-740(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    80002ed0:	018c2783          	lw	a5,24(s8)
    80002ed4:	f7978fe3          	beq	a5,s9,80002e52 <scheduler+0x52>
        release(&p->lock);
    80002ed8:	8562                	mv	a0,s8
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	dbe080e7          	jalr	-578(ra) # 80000c98 <release>
    80002ee2:	bf75                	j	80002e9e <scheduler+0x9e>

0000000080002ee4 <swtch>:
    80002ee4:	00153023          	sd	ra,0(a0)
    80002ee8:	00253423          	sd	sp,8(a0)
    80002eec:	e900                	sd	s0,16(a0)
    80002eee:	ed04                	sd	s1,24(a0)
    80002ef0:	03253023          	sd	s2,32(a0)
    80002ef4:	03353423          	sd	s3,40(a0)
    80002ef8:	03453823          	sd	s4,48(a0)
    80002efc:	03553c23          	sd	s5,56(a0)
    80002f00:	05653023          	sd	s6,64(a0)
    80002f04:	05753423          	sd	s7,72(a0)
    80002f08:	05853823          	sd	s8,80(a0)
    80002f0c:	05953c23          	sd	s9,88(a0)
    80002f10:	07a53023          	sd	s10,96(a0)
    80002f14:	07b53423          	sd	s11,104(a0)
    80002f18:	0005b083          	ld	ra,0(a1)
    80002f1c:	0085b103          	ld	sp,8(a1)
    80002f20:	6980                	ld	s0,16(a1)
    80002f22:	6d84                	ld	s1,24(a1)
    80002f24:	0205b903          	ld	s2,32(a1)
    80002f28:	0285b983          	ld	s3,40(a1)
    80002f2c:	0305ba03          	ld	s4,48(a1)
    80002f30:	0385ba83          	ld	s5,56(a1)
    80002f34:	0405bb03          	ld	s6,64(a1)
    80002f38:	0485bb83          	ld	s7,72(a1)
    80002f3c:	0505bc03          	ld	s8,80(a1)
    80002f40:	0585bc83          	ld	s9,88(a1)
    80002f44:	0605bd03          	ld	s10,96(a1)
    80002f48:	0685bd83          	ld	s11,104(a1)
    80002f4c:	8082                	ret

0000000080002f4e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f4e:	1141                	addi	sp,sp,-16
    80002f50:	e406                	sd	ra,8(sp)
    80002f52:	e022                	sd	s0,0(sp)
    80002f54:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f56:	00005597          	auipc	a1,0x5
    80002f5a:	4c258593          	addi	a1,a1,1218 # 80008418 <states.1825+0x30>
    80002f5e:	00015517          	auipc	a0,0x15
    80002f62:	cf250513          	addi	a0,a0,-782 # 80017c50 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	bee080e7          	jalr	-1042(ra) # 80000b54 <initlock>
}
    80002f6e:	60a2                	ld	ra,8(sp)
    80002f70:	6402                	ld	s0,0(sp)
    80002f72:	0141                	addi	sp,sp,16
    80002f74:	8082                	ret

0000000080002f76 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f76:	1141                	addi	sp,sp,-16
    80002f78:	e422                	sd	s0,8(sp)
    80002f7a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f7c:	00003797          	auipc	a5,0x3
    80002f80:	50478793          	addi	a5,a5,1284 # 80006480 <kernelvec>
    80002f84:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f88:	6422                	ld	s0,8(sp)
    80002f8a:	0141                	addi	sp,sp,16
    80002f8c:	8082                	ret

0000000080002f8e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f8e:	1141                	addi	sp,sp,-16
    80002f90:	e406                	sd	ra,8(sp)
    80002f92:	e022                	sd	s0,0(sp)
    80002f94:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	f36080e7          	jalr	-202(ra) # 80001ecc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fa2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fa8:	00004617          	auipc	a2,0x4
    80002fac:	05860613          	addi	a2,a2,88 # 80007000 <_trampoline>
    80002fb0:	00004697          	auipc	a3,0x4
    80002fb4:	05068693          	addi	a3,a3,80 # 80007000 <_trampoline>
    80002fb8:	8e91                	sub	a3,a3,a2
    80002fba:	040007b7          	lui	a5,0x4000
    80002fbe:	17fd                	addi	a5,a5,-1
    80002fc0:	07b2                	slli	a5,a5,0xc
    80002fc2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fc4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fc8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fca:	180026f3          	csrr	a3,satp
    80002fce:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fd0:	6d38                	ld	a4,88(a0)
    80002fd2:	6134                	ld	a3,64(a0)
    80002fd4:	6585                	lui	a1,0x1
    80002fd6:	96ae                	add	a3,a3,a1
    80002fd8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fda:	6d38                	ld	a4,88(a0)
    80002fdc:	00000697          	auipc	a3,0x0
    80002fe0:	13868693          	addi	a3,a3,312 # 80003114 <usertrap>
    80002fe4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002fe6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002fe8:	8692                	mv	a3,tp
    80002fea:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fec:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ff0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ff4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ffc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ffe:	6f18                	ld	a4,24(a4)
    80003000:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003004:	692c                	ld	a1,80(a0)
    80003006:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003008:	00004717          	auipc	a4,0x4
    8000300c:	08870713          	addi	a4,a4,136 # 80007090 <userret>
    80003010:	8f11                	sub	a4,a4,a2
    80003012:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003014:	577d                	li	a4,-1
    80003016:	177e                	slli	a4,a4,0x3f
    80003018:	8dd9                	or	a1,a1,a4
    8000301a:	02000537          	lui	a0,0x2000
    8000301e:	157d                	addi	a0,a0,-1
    80003020:	0536                	slli	a0,a0,0xd
    80003022:	9782                	jalr	a5
}
    80003024:	60a2                	ld	ra,8(sp)
    80003026:	6402                	ld	s0,0(sp)
    80003028:	0141                	addi	sp,sp,16
    8000302a:	8082                	ret

000000008000302c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	e426                	sd	s1,8(sp)
    80003034:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003036:	00015497          	auipc	s1,0x15
    8000303a:	c1a48493          	addi	s1,s1,-998 # 80017c50 <tickslock>
    8000303e:	8526                	mv	a0,s1
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	ba4080e7          	jalr	-1116(ra) # 80000be4 <acquire>
  ticks++;
    80003048:	00006517          	auipc	a0,0x6
    8000304c:	fe850513          	addi	a0,a0,-24 # 80009030 <ticks>
    80003050:	411c                	lw	a5,0(a0)
    80003052:	2785                	addiw	a5,a5,1
    80003054:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003056:	00000097          	auipc	ra,0x0
    8000305a:	a78080e7          	jalr	-1416(ra) # 80002ace <wakeup>
  release(&tickslock);
    8000305e:	8526                	mv	a0,s1
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c38080e7          	jalr	-968(ra) # 80000c98 <release>
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000307c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003080:	00074d63          	bltz	a4,8000309a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003084:	57fd                	li	a5,-1
    80003086:	17fe                	slli	a5,a5,0x3f
    80003088:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000308a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000308c:	06f70363          	beq	a4,a5,800030f2 <devintr+0x80>
  }
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
     (scause & 0xff) == 9){
    8000309a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000309e:	46a5                	li	a3,9
    800030a0:	fed792e3          	bne	a5,a3,80003084 <devintr+0x12>
    int irq = plic_claim();
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	4e4080e7          	jalr	1252(ra) # 80006588 <plic_claim>
    800030ac:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030ae:	47a9                	li	a5,10
    800030b0:	02f50763          	beq	a0,a5,800030de <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030b4:	4785                	li	a5,1
    800030b6:	02f50963          	beq	a0,a5,800030e8 <devintr+0x76>
    return 1;
    800030ba:	4505                	li	a0,1
    } else if(irq){
    800030bc:	d8f1                	beqz	s1,80003090 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030be:	85a6                	mv	a1,s1
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	36050513          	addi	a0,a0,864 # 80008420 <states.1825+0x38>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	4c0080e7          	jalr	1216(ra) # 80000588 <printf>
      plic_complete(irq);
    800030d0:	8526                	mv	a0,s1
    800030d2:	00003097          	auipc	ra,0x3
    800030d6:	4da080e7          	jalr	1242(ra) # 800065ac <plic_complete>
    return 1;
    800030da:	4505                	li	a0,1
    800030dc:	bf55                	j	80003090 <devintr+0x1e>
      uartintr();
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	8ca080e7          	jalr	-1846(ra) # 800009a8 <uartintr>
    800030e6:	b7ed                	j	800030d0 <devintr+0x5e>
      virtio_disk_intr();
    800030e8:	00004097          	auipc	ra,0x4
    800030ec:	9a4080e7          	jalr	-1628(ra) # 80006a8c <virtio_disk_intr>
    800030f0:	b7c5                	j	800030d0 <devintr+0x5e>
    if(cpuid() == 0){
    800030f2:	fffff097          	auipc	ra,0xfffff
    800030f6:	da8080e7          	jalr	-600(ra) # 80001e9a <cpuid>
    800030fa:	c901                	beqz	a0,8000310a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800030fc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003100:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003102:	14479073          	csrw	sip,a5
    return 2;
    80003106:	4509                	li	a0,2
    80003108:	b761                	j	80003090 <devintr+0x1e>
      clockintr();
    8000310a:	00000097          	auipc	ra,0x0
    8000310e:	f22080e7          	jalr	-222(ra) # 8000302c <clockintr>
    80003112:	b7ed                	j	800030fc <devintr+0x8a>

0000000080003114 <usertrap>:
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	e426                	sd	s1,8(sp)
    8000311c:	e04a                	sd	s2,0(sp)
    8000311e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003120:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003124:	1007f793          	andi	a5,a5,256
    80003128:	e3ad                	bnez	a5,8000318a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000312a:	00003797          	auipc	a5,0x3
    8000312e:	35678793          	addi	a5,a5,854 # 80006480 <kernelvec>
    80003132:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	d96080e7          	jalr	-618(ra) # 80001ecc <myproc>
    8000313e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003140:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003142:	14102773          	csrr	a4,sepc
    80003146:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003148:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000314c:	47a1                	li	a5,8
    8000314e:	04f71c63          	bne	a4,a5,800031a6 <usertrap+0x92>
    if(p->killed)
    80003152:	551c                	lw	a5,40(a0)
    80003154:	e3b9                	bnez	a5,8000319a <usertrap+0x86>
    p->trapframe->epc += 4;
    80003156:	6cb8                	ld	a4,88(s1)
    80003158:	6f1c                	ld	a5,24(a4)
    8000315a:	0791                	addi	a5,a5,4
    8000315c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000315e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003162:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003166:	10079073          	csrw	sstatus,a5
    syscall();
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	2e0080e7          	jalr	736(ra) # 8000344a <syscall>
  if(p->killed)
    80003172:	549c                	lw	a5,40(s1)
    80003174:	ebc1                	bnez	a5,80003204 <usertrap+0xf0>
  usertrapret();
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	e18080e7          	jalr	-488(ra) # 80002f8e <usertrapret>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	64a2                	ld	s1,8(sp)
    80003184:	6902                	ld	s2,0(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret
    panic("usertrap: not from user mode");
    8000318a:	00005517          	auipc	a0,0x5
    8000318e:	2b650513          	addi	a0,a0,694 # 80008440 <states.1825+0x58>
    80003192:	ffffd097          	auipc	ra,0xffffd
    80003196:	3ac080e7          	jalr	940(ra) # 8000053e <panic>
      exit(-1);
    8000319a:	557d                	li	a0,-1
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	a80080e7          	jalr	-1408(ra) # 80002c1c <exit>
    800031a4:	bf4d                	j	80003156 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	ecc080e7          	jalr	-308(ra) # 80003072 <devintr>
    800031ae:	892a                	mv	s2,a0
    800031b0:	c501                	beqz	a0,800031b8 <usertrap+0xa4>
  if(p->killed)
    800031b2:	549c                	lw	a5,40(s1)
    800031b4:	c3a1                	beqz	a5,800031f4 <usertrap+0xe0>
    800031b6:	a815                	j	800031ea <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031b8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800031bc:	5890                	lw	a2,48(s1)
    800031be:	00005517          	auipc	a0,0x5
    800031c2:	2a250513          	addi	a0,a0,674 # 80008460 <states.1825+0x78>
    800031c6:	ffffd097          	auipc	ra,0xffffd
    800031ca:	3c2080e7          	jalr	962(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031ce:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031d2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	2ba50513          	addi	a0,a0,698 # 80008490 <states.1825+0xa8>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	3aa080e7          	jalr	938(ra) # 80000588 <printf>
    p->killed = 1;
    800031e6:	4785                	li	a5,1
    800031e8:	d49c                	sw	a5,40(s1)
    exit(-1);
    800031ea:	557d                	li	a0,-1
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	a30080e7          	jalr	-1488(ra) # 80002c1c <exit>
  if(which_dev == 2)
    800031f4:	4789                	li	a5,2
    800031f6:	f8f910e3          	bne	s2,a5,80003176 <usertrap+0x62>
    yield();
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	248080e7          	jalr	584(ra) # 80002442 <yield>
    80003202:	bf95                	j	80003176 <usertrap+0x62>
  int which_dev = 0;
    80003204:	4901                	li	s2,0
    80003206:	b7d5                	j	800031ea <usertrap+0xd6>

0000000080003208 <kerneltrap>:
{
    80003208:	7179                	addi	sp,sp,-48
    8000320a:	f406                	sd	ra,40(sp)
    8000320c:	f022                	sd	s0,32(sp)
    8000320e:	ec26                	sd	s1,24(sp)
    80003210:	e84a                	sd	s2,16(sp)
    80003212:	e44e                	sd	s3,8(sp)
    80003214:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003216:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000321a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000321e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003222:	1004f793          	andi	a5,s1,256
    80003226:	cb85                	beqz	a5,80003256 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003228:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000322c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000322e:	ef85                	bnez	a5,80003266 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003230:	00000097          	auipc	ra,0x0
    80003234:	e42080e7          	jalr	-446(ra) # 80003072 <devintr>
    80003238:	cd1d                	beqz	a0,80003276 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000323a:	4789                	li	a5,2
    8000323c:	06f50a63          	beq	a0,a5,800032b0 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003240:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003244:	10049073          	csrw	sstatus,s1
}
    80003248:	70a2                	ld	ra,40(sp)
    8000324a:	7402                	ld	s0,32(sp)
    8000324c:	64e2                	ld	s1,24(sp)
    8000324e:	6942                	ld	s2,16(sp)
    80003250:	69a2                	ld	s3,8(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003256:	00005517          	auipc	a0,0x5
    8000325a:	25a50513          	addi	a0,a0,602 # 800084b0 <states.1825+0xc8>
    8000325e:	ffffd097          	auipc	ra,0xffffd
    80003262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	27250513          	addi	a0,a0,626 # 800084d8 <states.1825+0xf0>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003276:	85ce                	mv	a1,s3
    80003278:	00005517          	auipc	a0,0x5
    8000327c:	28050513          	addi	a0,a0,640 # 800084f8 <states.1825+0x110>
    80003280:	ffffd097          	auipc	ra,0xffffd
    80003284:	308080e7          	jalr	776(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003288:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000328c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003290:	00005517          	auipc	a0,0x5
    80003294:	27850513          	addi	a0,a0,632 # 80008508 <states.1825+0x120>
    80003298:	ffffd097          	auipc	ra,0xffffd
    8000329c:	2f0080e7          	jalr	752(ra) # 80000588 <printf>
    panic("kerneltrap");
    800032a0:	00005517          	auipc	a0,0x5
    800032a4:	28050513          	addi	a0,a0,640 # 80008520 <states.1825+0x138>
    800032a8:	ffffd097          	auipc	ra,0xffffd
    800032ac:	296080e7          	jalr	662(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	c1c080e7          	jalr	-996(ra) # 80001ecc <myproc>
    800032b8:	d541                	beqz	a0,80003240 <kerneltrap+0x38>
    800032ba:	fffff097          	auipc	ra,0xfffff
    800032be:	c12080e7          	jalr	-1006(ra) # 80001ecc <myproc>
    800032c2:	4d18                	lw	a4,24(a0)
    800032c4:	4791                	li	a5,4
    800032c6:	f6f71de3          	bne	a4,a5,80003240 <kerneltrap+0x38>
    yield();
    800032ca:	fffff097          	auipc	ra,0xfffff
    800032ce:	178080e7          	jalr	376(ra) # 80002442 <yield>
    800032d2:	b7bd                	j	80003240 <kerneltrap+0x38>

00000000800032d4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800032d4:	1101                	addi	sp,sp,-32
    800032d6:	ec06                	sd	ra,24(sp)
    800032d8:	e822                	sd	s0,16(sp)
    800032da:	e426                	sd	s1,8(sp)
    800032dc:	1000                	addi	s0,sp,32
    800032de:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800032e0:	fffff097          	auipc	ra,0xfffff
    800032e4:	bec080e7          	jalr	-1044(ra) # 80001ecc <myproc>
  switch (n) {
    800032e8:	4795                	li	a5,5
    800032ea:	0497e163          	bltu	a5,s1,8000332c <argraw+0x58>
    800032ee:	048a                	slli	s1,s1,0x2
    800032f0:	00005717          	auipc	a4,0x5
    800032f4:	26870713          	addi	a4,a4,616 # 80008558 <states.1825+0x170>
    800032f8:	94ba                	add	s1,s1,a4
    800032fa:	409c                	lw	a5,0(s1)
    800032fc:	97ba                	add	a5,a5,a4
    800032fe:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003300:	6d3c                	ld	a5,88(a0)
    80003302:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003304:	60e2                	ld	ra,24(sp)
    80003306:	6442                	ld	s0,16(sp)
    80003308:	64a2                	ld	s1,8(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret
    return p->trapframe->a1;
    8000330e:	6d3c                	ld	a5,88(a0)
    80003310:	7fa8                	ld	a0,120(a5)
    80003312:	bfcd                	j	80003304 <argraw+0x30>
    return p->trapframe->a2;
    80003314:	6d3c                	ld	a5,88(a0)
    80003316:	63c8                	ld	a0,128(a5)
    80003318:	b7f5                	j	80003304 <argraw+0x30>
    return p->trapframe->a3;
    8000331a:	6d3c                	ld	a5,88(a0)
    8000331c:	67c8                	ld	a0,136(a5)
    8000331e:	b7dd                	j	80003304 <argraw+0x30>
    return p->trapframe->a4;
    80003320:	6d3c                	ld	a5,88(a0)
    80003322:	6bc8                	ld	a0,144(a5)
    80003324:	b7c5                	j	80003304 <argraw+0x30>
    return p->trapframe->a5;
    80003326:	6d3c                	ld	a5,88(a0)
    80003328:	6fc8                	ld	a0,152(a5)
    8000332a:	bfe9                	j	80003304 <argraw+0x30>
  panic("argraw");
    8000332c:	00005517          	auipc	a0,0x5
    80003330:	20450513          	addi	a0,a0,516 # 80008530 <states.1825+0x148>
    80003334:	ffffd097          	auipc	ra,0xffffd
    80003338:	20a080e7          	jalr	522(ra) # 8000053e <panic>

000000008000333c <fetchaddr>:
{
    8000333c:	1101                	addi	sp,sp,-32
    8000333e:	ec06                	sd	ra,24(sp)
    80003340:	e822                	sd	s0,16(sp)
    80003342:	e426                	sd	s1,8(sp)
    80003344:	e04a                	sd	s2,0(sp)
    80003346:	1000                	addi	s0,sp,32
    80003348:	84aa                	mv	s1,a0
    8000334a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	b80080e7          	jalr	-1152(ra) # 80001ecc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003354:	653c                	ld	a5,72(a0)
    80003356:	02f4f863          	bgeu	s1,a5,80003386 <fetchaddr+0x4a>
    8000335a:	00848713          	addi	a4,s1,8
    8000335e:	02e7e663          	bltu	a5,a4,8000338a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003362:	46a1                	li	a3,8
    80003364:	8626                	mv	a2,s1
    80003366:	85ca                	mv	a1,s2
    80003368:	6928                	ld	a0,80(a0)
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	394080e7          	jalr	916(ra) # 800016fe <copyin>
    80003372:	00a03533          	snez	a0,a0
    80003376:	40a00533          	neg	a0,a0
}
    8000337a:	60e2                	ld	ra,24(sp)
    8000337c:	6442                	ld	s0,16(sp)
    8000337e:	64a2                	ld	s1,8(sp)
    80003380:	6902                	ld	s2,0(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret
    return -1;
    80003386:	557d                	li	a0,-1
    80003388:	bfcd                	j	8000337a <fetchaddr+0x3e>
    8000338a:	557d                	li	a0,-1
    8000338c:	b7fd                	j	8000337a <fetchaddr+0x3e>

000000008000338e <fetchstr>:
{
    8000338e:	7179                	addi	sp,sp,-48
    80003390:	f406                	sd	ra,40(sp)
    80003392:	f022                	sd	s0,32(sp)
    80003394:	ec26                	sd	s1,24(sp)
    80003396:	e84a                	sd	s2,16(sp)
    80003398:	e44e                	sd	s3,8(sp)
    8000339a:	1800                	addi	s0,sp,48
    8000339c:	892a                	mv	s2,a0
    8000339e:	84ae                	mv	s1,a1
    800033a0:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800033a2:	fffff097          	auipc	ra,0xfffff
    800033a6:	b2a080e7          	jalr	-1238(ra) # 80001ecc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800033aa:	86ce                	mv	a3,s3
    800033ac:	864a                	mv	a2,s2
    800033ae:	85a6                	mv	a1,s1
    800033b0:	6928                	ld	a0,80(a0)
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	3d8080e7          	jalr	984(ra) # 8000178a <copyinstr>
  if(err < 0)
    800033ba:	00054763          	bltz	a0,800033c8 <fetchstr+0x3a>
  return strlen(buf);
    800033be:	8526                	mv	a0,s1
    800033c0:	ffffe097          	auipc	ra,0xffffe
    800033c4:	aa4080e7          	jalr	-1372(ra) # 80000e64 <strlen>
}
    800033c8:	70a2                	ld	ra,40(sp)
    800033ca:	7402                	ld	s0,32(sp)
    800033cc:	64e2                	ld	s1,24(sp)
    800033ce:	6942                	ld	s2,16(sp)
    800033d0:	69a2                	ld	s3,8(sp)
    800033d2:	6145                	addi	sp,sp,48
    800033d4:	8082                	ret

00000000800033d6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
    800033e0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	ef2080e7          	jalr	-270(ra) # 800032d4 <argraw>
    800033ea:	c088                	sw	a0,0(s1)
  return 0;
}
    800033ec:	4501                	li	a0,0
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	64a2                	ld	s1,8(sp)
    800033f4:	6105                	addi	sp,sp,32
    800033f6:	8082                	ret

00000000800033f8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	1000                	addi	s0,sp,32
    80003402:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003404:	00000097          	auipc	ra,0x0
    80003408:	ed0080e7          	jalr	-304(ra) # 800032d4 <argraw>
    8000340c:	e088                	sd	a0,0(s1)
  return 0;
}
    8000340e:	4501                	li	a0,0
    80003410:	60e2                	ld	ra,24(sp)
    80003412:	6442                	ld	s0,16(sp)
    80003414:	64a2                	ld	s1,8(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret

000000008000341a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000341a:	1101                	addi	sp,sp,-32
    8000341c:	ec06                	sd	ra,24(sp)
    8000341e:	e822                	sd	s0,16(sp)
    80003420:	e426                	sd	s1,8(sp)
    80003422:	e04a                	sd	s2,0(sp)
    80003424:	1000                	addi	s0,sp,32
    80003426:	84ae                	mv	s1,a1
    80003428:	8932                	mv	s2,a2
  *ip = argraw(n);
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	eaa080e7          	jalr	-342(ra) # 800032d4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003432:	864a                	mv	a2,s2
    80003434:	85a6                	mv	a1,s1
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	f58080e7          	jalr	-168(ra) # 8000338e <fetchstr>
}
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	64a2                	ld	s1,8(sp)
    80003444:	6902                	ld	s2,0(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    8000344a:	1101                	addi	sp,sp,-32
    8000344c:	ec06                	sd	ra,24(sp)
    8000344e:	e822                	sd	s0,16(sp)
    80003450:	e426                	sd	s1,8(sp)
    80003452:	e04a                	sd	s2,0(sp)
    80003454:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003456:	fffff097          	auipc	ra,0xfffff
    8000345a:	a76080e7          	jalr	-1418(ra) # 80001ecc <myproc>
    8000345e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003460:	05853903          	ld	s2,88(a0)
    80003464:	0a893783          	ld	a5,168(s2)
    80003468:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000346c:	37fd                	addiw	a5,a5,-1
    8000346e:	475d                	li	a4,23
    80003470:	00f76f63          	bltu	a4,a5,8000348e <syscall+0x44>
    80003474:	00369713          	slli	a4,a3,0x3
    80003478:	00005797          	auipc	a5,0x5
    8000347c:	0f878793          	addi	a5,a5,248 # 80008570 <syscalls>
    80003480:	97ba                	add	a5,a5,a4
    80003482:	639c                	ld	a5,0(a5)
    80003484:	c789                	beqz	a5,8000348e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003486:	9782                	jalr	a5
    80003488:	06a93823          	sd	a0,112(s2)
    8000348c:	a839                	j	800034aa <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000348e:	15848613          	addi	a2,s1,344
    80003492:	588c                	lw	a1,48(s1)
    80003494:	00005517          	auipc	a0,0x5
    80003498:	0a450513          	addi	a0,a0,164 # 80008538 <states.1825+0x150>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	0ec080e7          	jalr	236(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800034a4:	6cbc                	ld	a5,88(s1)
    800034a6:	577d                	li	a4,-1
    800034a8:	fbb8                	sd	a4,112(a5)
  }
}
    800034aa:	60e2                	ld	ra,24(sp)
    800034ac:	6442                	ld	s0,16(sp)
    800034ae:	64a2                	ld	s1,8(sp)
    800034b0:	6902                	ld	s2,0(sp)
    800034b2:	6105                	addi	sp,sp,32
    800034b4:	8082                	ret

00000000800034b6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800034b6:	1101                	addi	sp,sp,-32
    800034b8:	ec06                	sd	ra,24(sp)
    800034ba:	e822                	sd	s0,16(sp)
    800034bc:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800034be:	fec40593          	addi	a1,s0,-20
    800034c2:	4501                	li	a0,0
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	f12080e7          	jalr	-238(ra) # 800033d6 <argint>
    return -1;
    800034cc:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034ce:	00054963          	bltz	a0,800034e0 <sys_exit+0x2a>
  exit(n);
    800034d2:	fec42503          	lw	a0,-20(s0)
    800034d6:	fffff097          	auipc	ra,0xfffff
    800034da:	746080e7          	jalr	1862(ra) # 80002c1c <exit>
  return 0;  // not reached
    800034de:	4781                	li	a5,0
}
    800034e0:	853e                	mv	a0,a5
    800034e2:	60e2                	ld	ra,24(sp)
    800034e4:	6442                	ld	s0,16(sp)
    800034e6:	6105                	addi	sp,sp,32
    800034e8:	8082                	ret

00000000800034ea <sys_getpid>:

uint64
sys_getpid(void)
{
    800034ea:	1141                	addi	sp,sp,-16
    800034ec:	e406                	sd	ra,8(sp)
    800034ee:	e022                	sd	s0,0(sp)
    800034f0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	9da080e7          	jalr	-1574(ra) # 80001ecc <myproc>
}
    800034fa:	5908                	lw	a0,48(a0)
    800034fc:	60a2                	ld	ra,8(sp)
    800034fe:	6402                	ld	s0,0(sp)
    80003500:	0141                	addi	sp,sp,16
    80003502:	8082                	ret

0000000080003504 <sys_fork>:

uint64
sys_fork(void)
{
    80003504:	1141                	addi	sp,sp,-16
    80003506:	e406                	sd	ra,8(sp)
    80003508:	e022                	sd	s0,0(sp)
    8000350a:	0800                	addi	s0,sp,16
  return fork();
    8000350c:	fffff097          	auipc	ra,0xfffff
    80003510:	442080e7          	jalr	1090(ra) # 8000294e <fork>
}
    80003514:	60a2                	ld	ra,8(sp)
    80003516:	6402                	ld	s0,0(sp)
    80003518:	0141                	addi	sp,sp,16
    8000351a:	8082                	ret

000000008000351c <sys_wait>:

uint64
sys_wait(void)
{
    8000351c:	1101                	addi	sp,sp,-32
    8000351e:	ec06                	sd	ra,24(sp)
    80003520:	e822                	sd	s0,16(sp)
    80003522:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003524:	fe840593          	addi	a1,s0,-24
    80003528:	4501                	li	a0,0
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	ece080e7          	jalr	-306(ra) # 800033f8 <argaddr>
    80003532:	87aa                	mv	a5,a0
    return -1;
    80003534:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003536:	0007c863          	bltz	a5,80003546 <sys_wait+0x2a>
  return wait(p);
    8000353a:	fe843503          	ld	a0,-24(s0)
    8000353e:	fffff097          	auipc	ra,0xfffff
    80003542:	fda080e7          	jalr	-38(ra) # 80002518 <wait>
}
    80003546:	60e2                	ld	ra,24(sp)
    80003548:	6442                	ld	s0,16(sp)
    8000354a:	6105                	addi	sp,sp,32
    8000354c:	8082                	ret

000000008000354e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000354e:	7179                	addi	sp,sp,-48
    80003550:	f406                	sd	ra,40(sp)
    80003552:	f022                	sd	s0,32(sp)
    80003554:	ec26                	sd	s1,24(sp)
    80003556:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003558:	fdc40593          	addi	a1,s0,-36
    8000355c:	4501                	li	a0,0
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	e78080e7          	jalr	-392(ra) # 800033d6 <argint>
    80003566:	87aa                	mv	a5,a0
    return -1;
    80003568:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000356a:	0207c063          	bltz	a5,8000358a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000356e:	fffff097          	auipc	ra,0xfffff
    80003572:	95e080e7          	jalr	-1698(ra) # 80001ecc <myproc>
    80003576:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003578:	fdc42503          	lw	a0,-36(s0)
    8000357c:	fffff097          	auipc	ra,0xfffff
    80003580:	d70080e7          	jalr	-656(ra) # 800022ec <growproc>
    80003584:	00054863          	bltz	a0,80003594 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003588:	8526                	mv	a0,s1
}
    8000358a:	70a2                	ld	ra,40(sp)
    8000358c:	7402                	ld	s0,32(sp)
    8000358e:	64e2                	ld	s1,24(sp)
    80003590:	6145                	addi	sp,sp,48
    80003592:	8082                	ret
    return -1;
    80003594:	557d                	li	a0,-1
    80003596:	bfd5                	j	8000358a <sys_sbrk+0x3c>

0000000080003598 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003598:	7139                	addi	sp,sp,-64
    8000359a:	fc06                	sd	ra,56(sp)
    8000359c:	f822                	sd	s0,48(sp)
    8000359e:	f426                	sd	s1,40(sp)
    800035a0:	f04a                	sd	s2,32(sp)
    800035a2:	ec4e                	sd	s3,24(sp)
    800035a4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800035a6:	fcc40593          	addi	a1,s0,-52
    800035aa:	4501                	li	a0,0
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	e2a080e7          	jalr	-470(ra) # 800033d6 <argint>
    return -1;
    800035b4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800035b6:	06054563          	bltz	a0,80003620 <sys_sleep+0x88>
  acquire(&tickslock);
    800035ba:	00014517          	auipc	a0,0x14
    800035be:	69650513          	addi	a0,a0,1686 # 80017c50 <tickslock>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	622080e7          	jalr	1570(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800035ca:	00006917          	auipc	s2,0x6
    800035ce:	a6692903          	lw	s2,-1434(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    800035d2:	fcc42783          	lw	a5,-52(s0)
    800035d6:	cf85                	beqz	a5,8000360e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800035d8:	00014997          	auipc	s3,0x14
    800035dc:	67898993          	addi	s3,s3,1656 # 80017c50 <tickslock>
    800035e0:	00006497          	auipc	s1,0x6
    800035e4:	a5048493          	addi	s1,s1,-1456 # 80009030 <ticks>
    if(myproc()->killed){
    800035e8:	fffff097          	auipc	ra,0xfffff
    800035ec:	8e4080e7          	jalr	-1820(ra) # 80001ecc <myproc>
    800035f0:	551c                	lw	a5,40(a0)
    800035f2:	ef9d                	bnez	a5,80003630 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800035f4:	85ce                	mv	a1,s3
    800035f6:	8526                	mv	a0,s1
    800035f8:	fffff097          	auipc	ra,0xfffff
    800035fc:	eaa080e7          	jalr	-342(ra) # 800024a2 <sleep>
  while(ticks - ticks0 < n){
    80003600:	409c                	lw	a5,0(s1)
    80003602:	412787bb          	subw	a5,a5,s2
    80003606:	fcc42703          	lw	a4,-52(s0)
    8000360a:	fce7efe3          	bltu	a5,a4,800035e8 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000360e:	00014517          	auipc	a0,0x14
    80003612:	64250513          	addi	a0,a0,1602 # 80017c50 <tickslock>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
  return 0;
    8000361e:	4781                	li	a5,0
}
    80003620:	853e                	mv	a0,a5
    80003622:	70e2                	ld	ra,56(sp)
    80003624:	7442                	ld	s0,48(sp)
    80003626:	74a2                	ld	s1,40(sp)
    80003628:	7902                	ld	s2,32(sp)
    8000362a:	69e2                	ld	s3,24(sp)
    8000362c:	6121                	addi	sp,sp,64
    8000362e:	8082                	ret
      release(&tickslock);
    80003630:	00014517          	auipc	a0,0x14
    80003634:	62050513          	addi	a0,a0,1568 # 80017c50 <tickslock>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	660080e7          	jalr	1632(ra) # 80000c98 <release>
      return -1;
    80003640:	57fd                	li	a5,-1
    80003642:	bff9                	j	80003620 <sys_sleep+0x88>

0000000080003644 <sys_kill>:

uint64
sys_kill(void)
{
    80003644:	1101                	addi	sp,sp,-32
    80003646:	ec06                	sd	ra,24(sp)
    80003648:	e822                	sd	s0,16(sp)
    8000364a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000364c:	fec40593          	addi	a1,s0,-20
    80003650:	4501                	li	a0,0
    80003652:	00000097          	auipc	ra,0x0
    80003656:	d84080e7          	jalr	-636(ra) # 800033d6 <argint>
    8000365a:	87aa                	mv	a5,a0
    return -1;
    8000365c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000365e:	0007c863          	bltz	a5,8000366e <sys_kill+0x2a>
  return kill(pid);
    80003662:	fec42503          	lw	a0,-20(s0)
    80003666:	fffff097          	auipc	ra,0xfffff
    8000366a:	fda080e7          	jalr	-38(ra) # 80002640 <kill>
}
    8000366e:	60e2                	ld	ra,24(sp)
    80003670:	6442                	ld	s0,16(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret

0000000080003676 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003676:	1101                	addi	sp,sp,-32
    80003678:	ec06                	sd	ra,24(sp)
    8000367a:	e822                	sd	s0,16(sp)
    8000367c:	e426                	sd	s1,8(sp)
    8000367e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003680:	00014517          	auipc	a0,0x14
    80003684:	5d050513          	addi	a0,a0,1488 # 80017c50 <tickslock>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	55c080e7          	jalr	1372(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003690:	00006497          	auipc	s1,0x6
    80003694:	9a04a483          	lw	s1,-1632(s1) # 80009030 <ticks>
  release(&tickslock);
    80003698:	00014517          	auipc	a0,0x14
    8000369c:	5b850513          	addi	a0,a0,1464 # 80017c50 <tickslock>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>
  return xticks;
}
    800036a8:	02049513          	slli	a0,s1,0x20
    800036ac:	9101                	srli	a0,a0,0x20
    800036ae:	60e2                	ld	ra,24(sp)
    800036b0:	6442                	ld	s0,16(sp)
    800036b2:	64a2                	ld	s1,8(sp)
    800036b4:	6105                	addi	sp,sp,32
    800036b6:	8082                	ret

00000000800036b8 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    800036b8:	1101                	addi	sp,sp,-32
    800036ba:	ec06                	sd	ra,24(sp)
    800036bc:	e822                	sd	s0,16(sp)
    800036be:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    800036c0:	fec40593          	addi	a1,s0,-20
    800036c4:	4501                	li	a0,0
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	d10080e7          	jalr	-752(ra) # 800033d6 <argint>
    800036ce:	87aa                	mv	a5,a0
    return -1;
    800036d0:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    800036d2:	0007c863          	bltz	a5,800036e2 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    800036d6:	fec42503          	lw	a0,-20(s0)
    800036da:	fffff097          	auipc	ra,0xfffff
    800036de:	164080e7          	jalr	356(ra) # 8000283e <set_cpu>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	6105                	addi	sp,sp,32
    800036e8:	8082                	ret

00000000800036ea <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    800036ea:	1141                	addi	sp,sp,-16
    800036ec:	e406                	sd	ra,8(sp)
    800036ee:	e022                	sd	s0,0(sp)
    800036f0:	0800                	addi	s0,sp,16
  return get_cpu();
    800036f2:	fffff097          	auipc	ra,0xfffff
    800036f6:	19e080e7          	jalr	414(ra) # 80002890 <get_cpu>
}
    800036fa:	60a2                	ld	ra,8(sp)
    800036fc:	6402                	ld	s0,0(sp)
    800036fe:	0141                	addi	sp,sp,16
    80003700:	8082                	ret

0000000080003702 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000370a:	fec40593          	addi	a1,s0,-20
    8000370e:	4501                	li	a0,0
    80003710:	00000097          	auipc	ra,0x0
    80003714:	cc6080e7          	jalr	-826(ra) # 800033d6 <argint>
    80003718:	87aa                	mv	a5,a0
    return -1;
    8000371a:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000371c:	0007c863          	bltz	a5,8000372c <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    80003720:	fec42503          	lw	a0,-20(s0)
    80003724:	fffff097          	auipc	ra,0xfffff
    80003728:	1c6080e7          	jalr	454(ra) # 800028ea <cpu_process_count>
}
    8000372c:	60e2                	ld	ra,24(sp)
    8000372e:	6442                	ld	s0,16(sp)
    80003730:	6105                	addi	sp,sp,32
    80003732:	8082                	ret

0000000080003734 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003734:	7179                	addi	sp,sp,-48
    80003736:	f406                	sd	ra,40(sp)
    80003738:	f022                	sd	s0,32(sp)
    8000373a:	ec26                	sd	s1,24(sp)
    8000373c:	e84a                	sd	s2,16(sp)
    8000373e:	e44e                	sd	s3,8(sp)
    80003740:	e052                	sd	s4,0(sp)
    80003742:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003744:	00005597          	auipc	a1,0x5
    80003748:	ef458593          	addi	a1,a1,-268 # 80008638 <syscalls+0xc8>
    8000374c:	00014517          	auipc	a0,0x14
    80003750:	51c50513          	addi	a0,a0,1308 # 80017c68 <bcache>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	400080e7          	jalr	1024(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000375c:	0001c797          	auipc	a5,0x1c
    80003760:	50c78793          	addi	a5,a5,1292 # 8001fc68 <bcache+0x8000>
    80003764:	0001c717          	auipc	a4,0x1c
    80003768:	76c70713          	addi	a4,a4,1900 # 8001fed0 <bcache+0x8268>
    8000376c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003770:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003774:	00014497          	auipc	s1,0x14
    80003778:	50c48493          	addi	s1,s1,1292 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    8000377c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000377e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003780:	00005a17          	auipc	s4,0x5
    80003784:	ec0a0a13          	addi	s4,s4,-320 # 80008640 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003788:	2b893783          	ld	a5,696(s2)
    8000378c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000378e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003792:	85d2                	mv	a1,s4
    80003794:	01048513          	addi	a0,s1,16
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	4bc080e7          	jalr	1212(ra) # 80004c54 <initsleeplock>
    bcache.head.next->prev = b;
    800037a0:	2b893783          	ld	a5,696(s2)
    800037a4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800037a6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037aa:	45848493          	addi	s1,s1,1112
    800037ae:	fd349de3          	bne	s1,s3,80003788 <binit+0x54>
  }
}
    800037b2:	70a2                	ld	ra,40(sp)
    800037b4:	7402                	ld	s0,32(sp)
    800037b6:	64e2                	ld	s1,24(sp)
    800037b8:	6942                	ld	s2,16(sp)
    800037ba:	69a2                	ld	s3,8(sp)
    800037bc:	6a02                	ld	s4,0(sp)
    800037be:	6145                	addi	sp,sp,48
    800037c0:	8082                	ret

00000000800037c2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037c2:	7179                	addi	sp,sp,-48
    800037c4:	f406                	sd	ra,40(sp)
    800037c6:	f022                	sd	s0,32(sp)
    800037c8:	ec26                	sd	s1,24(sp)
    800037ca:	e84a                	sd	s2,16(sp)
    800037cc:	e44e                	sd	s3,8(sp)
    800037ce:	1800                	addi	s0,sp,48
    800037d0:	89aa                	mv	s3,a0
    800037d2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800037d4:	00014517          	auipc	a0,0x14
    800037d8:	49450513          	addi	a0,a0,1172 # 80017c68 <bcache>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	408080e7          	jalr	1032(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037e4:	0001c497          	auipc	s1,0x1c
    800037e8:	73c4b483          	ld	s1,1852(s1) # 8001ff20 <bcache+0x82b8>
    800037ec:	0001c797          	auipc	a5,0x1c
    800037f0:	6e478793          	addi	a5,a5,1764 # 8001fed0 <bcache+0x8268>
    800037f4:	02f48f63          	beq	s1,a5,80003832 <bread+0x70>
    800037f8:	873e                	mv	a4,a5
    800037fa:	a021                	j	80003802 <bread+0x40>
    800037fc:	68a4                	ld	s1,80(s1)
    800037fe:	02e48a63          	beq	s1,a4,80003832 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003802:	449c                	lw	a5,8(s1)
    80003804:	ff379ce3          	bne	a5,s3,800037fc <bread+0x3a>
    80003808:	44dc                	lw	a5,12(s1)
    8000380a:	ff2799e3          	bne	a5,s2,800037fc <bread+0x3a>
      b->refcnt++;
    8000380e:	40bc                	lw	a5,64(s1)
    80003810:	2785                	addiw	a5,a5,1
    80003812:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003814:	00014517          	auipc	a0,0x14
    80003818:	45450513          	addi	a0,a0,1108 # 80017c68 <bcache>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	47c080e7          	jalr	1148(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003824:	01048513          	addi	a0,s1,16
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	466080e7          	jalr	1126(ra) # 80004c8e <acquiresleep>
      return b;
    80003830:	a8b9                	j	8000388e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003832:	0001c497          	auipc	s1,0x1c
    80003836:	6e64b483          	ld	s1,1766(s1) # 8001ff18 <bcache+0x82b0>
    8000383a:	0001c797          	auipc	a5,0x1c
    8000383e:	69678793          	addi	a5,a5,1686 # 8001fed0 <bcache+0x8268>
    80003842:	00f48863          	beq	s1,a5,80003852 <bread+0x90>
    80003846:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003848:	40bc                	lw	a5,64(s1)
    8000384a:	cf81                	beqz	a5,80003862 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000384c:	64a4                	ld	s1,72(s1)
    8000384e:	fee49de3          	bne	s1,a4,80003848 <bread+0x86>
  panic("bget: no buffers");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	df650513          	addi	a0,a0,-522 # 80008648 <syscalls+0xd8>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>
      b->dev = dev;
    80003862:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003866:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000386a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000386e:	4785                	li	a5,1
    80003870:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003872:	00014517          	auipc	a0,0x14
    80003876:	3f650513          	addi	a0,a0,1014 # 80017c68 <bcache>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	41e080e7          	jalr	1054(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003882:	01048513          	addi	a0,s1,16
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	408080e7          	jalr	1032(ra) # 80004c8e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000388e:	409c                	lw	a5,0(s1)
    80003890:	cb89                	beqz	a5,800038a2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003892:	8526                	mv	a0,s1
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret
    virtio_disk_rw(b, 0);
    800038a2:	4581                	li	a1,0
    800038a4:	8526                	mv	a0,s1
    800038a6:	00003097          	auipc	ra,0x3
    800038aa:	f10080e7          	jalr	-240(ra) # 800067b6 <virtio_disk_rw>
    b->valid = 1;
    800038ae:	4785                	li	a5,1
    800038b0:	c09c                	sw	a5,0(s1)
  return b;
    800038b2:	b7c5                	j	80003892 <bread+0xd0>

00000000800038b4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038b4:	1101                	addi	sp,sp,-32
    800038b6:	ec06                	sd	ra,24(sp)
    800038b8:	e822                	sd	s0,16(sp)
    800038ba:	e426                	sd	s1,8(sp)
    800038bc:	1000                	addi	s0,sp,32
    800038be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038c0:	0541                	addi	a0,a0,16
    800038c2:	00001097          	auipc	ra,0x1
    800038c6:	466080e7          	jalr	1126(ra) # 80004d28 <holdingsleep>
    800038ca:	cd01                	beqz	a0,800038e2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038cc:	4585                	li	a1,1
    800038ce:	8526                	mv	a0,s1
    800038d0:	00003097          	auipc	ra,0x3
    800038d4:	ee6080e7          	jalr	-282(ra) # 800067b6 <virtio_disk_rw>
}
    800038d8:	60e2                	ld	ra,24(sp)
    800038da:	6442                	ld	s0,16(sp)
    800038dc:	64a2                	ld	s1,8(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret
    panic("bwrite");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	d7e50513          	addi	a0,a0,-642 # 80008660 <syscalls+0xf0>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c54080e7          	jalr	-940(ra) # 8000053e <panic>

00000000800038f2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003900:	01050913          	addi	s2,a0,16
    80003904:	854a                	mv	a0,s2
    80003906:	00001097          	auipc	ra,0x1
    8000390a:	422080e7          	jalr	1058(ra) # 80004d28 <holdingsleep>
    8000390e:	c92d                	beqz	a0,80003980 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	3d2080e7          	jalr	978(ra) # 80004ce4 <releasesleep>

  acquire(&bcache.lock);
    8000391a:	00014517          	auipc	a0,0x14
    8000391e:	34e50513          	addi	a0,a0,846 # 80017c68 <bcache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	2c2080e7          	jalr	706(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000392a:	40bc                	lw	a5,64(s1)
    8000392c:	37fd                	addiw	a5,a5,-1
    8000392e:	0007871b          	sext.w	a4,a5
    80003932:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003934:	eb05                	bnez	a4,80003964 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003936:	68bc                	ld	a5,80(s1)
    80003938:	64b8                	ld	a4,72(s1)
    8000393a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000393c:	64bc                	ld	a5,72(s1)
    8000393e:	68b8                	ld	a4,80(s1)
    80003940:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003942:	0001c797          	auipc	a5,0x1c
    80003946:	32678793          	addi	a5,a5,806 # 8001fc68 <bcache+0x8000>
    8000394a:	2b87b703          	ld	a4,696(a5)
    8000394e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003950:	0001c717          	auipc	a4,0x1c
    80003954:	58070713          	addi	a4,a4,1408 # 8001fed0 <bcache+0x8268>
    80003958:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000395a:	2b87b703          	ld	a4,696(a5)
    8000395e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003960:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003964:	00014517          	auipc	a0,0x14
    80003968:	30450513          	addi	a0,a0,772 # 80017c68 <bcache>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	32c080e7          	jalr	812(ra) # 80000c98 <release>
}
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6902                	ld	s2,0(sp)
    8000397c:	6105                	addi	sp,sp,32
    8000397e:	8082                	ret
    panic("brelse");
    80003980:	00005517          	auipc	a0,0x5
    80003984:	ce850513          	addi	a0,a0,-792 # 80008668 <syscalls+0xf8>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>

0000000080003990 <bpin>:

void
bpin(struct buf *b) {
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	1000                	addi	s0,sp,32
    8000399a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000399c:	00014517          	auipc	a0,0x14
    800039a0:	2cc50513          	addi	a0,a0,716 # 80017c68 <bcache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  b->refcnt++;
    800039ac:	40bc                	lw	a5,64(s1)
    800039ae:	2785                	addiw	a5,a5,1
    800039b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039b2:	00014517          	auipc	a0,0x14
    800039b6:	2b650513          	addi	a0,a0,694 # 80017c68 <bcache>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	2de080e7          	jalr	734(ra) # 80000c98 <release>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6105                	addi	sp,sp,32
    800039ca:	8082                	ret

00000000800039cc <bunpin>:

void
bunpin(struct buf *b) {
    800039cc:	1101                	addi	sp,sp,-32
    800039ce:	ec06                	sd	ra,24(sp)
    800039d0:	e822                	sd	s0,16(sp)
    800039d2:	e426                	sd	s1,8(sp)
    800039d4:	1000                	addi	s0,sp,32
    800039d6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039d8:	00014517          	auipc	a0,0x14
    800039dc:	29050513          	addi	a0,a0,656 # 80017c68 <bcache>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	204080e7          	jalr	516(ra) # 80000be4 <acquire>
  b->refcnt--;
    800039e8:	40bc                	lw	a5,64(s1)
    800039ea:	37fd                	addiw	a5,a5,-1
    800039ec:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039ee:	00014517          	auipc	a0,0x14
    800039f2:	27a50513          	addi	a0,a0,634 # 80017c68 <bcache>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	2a2080e7          	jalr	674(ra) # 80000c98 <release>
}
    800039fe:	60e2                	ld	ra,24(sp)
    80003a00:	6442                	ld	s0,16(sp)
    80003a02:	64a2                	ld	s1,8(sp)
    80003a04:	6105                	addi	sp,sp,32
    80003a06:	8082                	ret

0000000080003a08 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a08:	1101                	addi	sp,sp,-32
    80003a0a:	ec06                	sd	ra,24(sp)
    80003a0c:	e822                	sd	s0,16(sp)
    80003a0e:	e426                	sd	s1,8(sp)
    80003a10:	e04a                	sd	s2,0(sp)
    80003a12:	1000                	addi	s0,sp,32
    80003a14:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a16:	00d5d59b          	srliw	a1,a1,0xd
    80003a1a:	0001d797          	auipc	a5,0x1d
    80003a1e:	92a7a783          	lw	a5,-1750(a5) # 80020344 <sb+0x1c>
    80003a22:	9dbd                	addw	a1,a1,a5
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	d9e080e7          	jalr	-610(ra) # 800037c2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a2c:	0074f713          	andi	a4,s1,7
    80003a30:	4785                	li	a5,1
    80003a32:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a36:	14ce                	slli	s1,s1,0x33
    80003a38:	90d9                	srli	s1,s1,0x36
    80003a3a:	00950733          	add	a4,a0,s1
    80003a3e:	05874703          	lbu	a4,88(a4)
    80003a42:	00e7f6b3          	and	a3,a5,a4
    80003a46:	c69d                	beqz	a3,80003a74 <bfree+0x6c>
    80003a48:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a4a:	94aa                	add	s1,s1,a0
    80003a4c:	fff7c793          	not	a5,a5
    80003a50:	8ff9                	and	a5,a5,a4
    80003a52:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a56:	00001097          	auipc	ra,0x1
    80003a5a:	118080e7          	jalr	280(ra) # 80004b6e <log_write>
  brelse(bp);
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	e92080e7          	jalr	-366(ra) # 800038f2 <brelse>
}
    80003a68:	60e2                	ld	ra,24(sp)
    80003a6a:	6442                	ld	s0,16(sp)
    80003a6c:	64a2                	ld	s1,8(sp)
    80003a6e:	6902                	ld	s2,0(sp)
    80003a70:	6105                	addi	sp,sp,32
    80003a72:	8082                	ret
    panic("freeing free block");
    80003a74:	00005517          	auipc	a0,0x5
    80003a78:	bfc50513          	addi	a0,a0,-1028 # 80008670 <syscalls+0x100>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	ac2080e7          	jalr	-1342(ra) # 8000053e <panic>

0000000080003a84 <balloc>:
{
    80003a84:	711d                	addi	sp,sp,-96
    80003a86:	ec86                	sd	ra,88(sp)
    80003a88:	e8a2                	sd	s0,80(sp)
    80003a8a:	e4a6                	sd	s1,72(sp)
    80003a8c:	e0ca                	sd	s2,64(sp)
    80003a8e:	fc4e                	sd	s3,56(sp)
    80003a90:	f852                	sd	s4,48(sp)
    80003a92:	f456                	sd	s5,40(sp)
    80003a94:	f05a                	sd	s6,32(sp)
    80003a96:	ec5e                	sd	s7,24(sp)
    80003a98:	e862                	sd	s8,16(sp)
    80003a9a:	e466                	sd	s9,8(sp)
    80003a9c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a9e:	0001d797          	auipc	a5,0x1d
    80003aa2:	88e7a783          	lw	a5,-1906(a5) # 8002032c <sb+0x4>
    80003aa6:	cbd1                	beqz	a5,80003b3a <balloc+0xb6>
    80003aa8:	8baa                	mv	s7,a0
    80003aaa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003aac:	0001db17          	auipc	s6,0x1d
    80003ab0:	87cb0b13          	addi	s6,s6,-1924 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ab6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003aba:	6c89                	lui	s9,0x2
    80003abc:	a831                	j	80003ad8 <balloc+0x54>
    brelse(bp);
    80003abe:	854a                	mv	a0,s2
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	e32080e7          	jalr	-462(ra) # 800038f2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ac8:	015c87bb          	addw	a5,s9,s5
    80003acc:	00078a9b          	sext.w	s5,a5
    80003ad0:	004b2703          	lw	a4,4(s6)
    80003ad4:	06eaf363          	bgeu	s5,a4,80003b3a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ad8:	41fad79b          	sraiw	a5,s5,0x1f
    80003adc:	0137d79b          	srliw	a5,a5,0x13
    80003ae0:	015787bb          	addw	a5,a5,s5
    80003ae4:	40d7d79b          	sraiw	a5,a5,0xd
    80003ae8:	01cb2583          	lw	a1,28(s6)
    80003aec:	9dbd                	addw	a1,a1,a5
    80003aee:	855e                	mv	a0,s7
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	cd2080e7          	jalr	-814(ra) # 800037c2 <bread>
    80003af8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003afa:	004b2503          	lw	a0,4(s6)
    80003afe:	000a849b          	sext.w	s1,s5
    80003b02:	8662                	mv	a2,s8
    80003b04:	faa4fde3          	bgeu	s1,a0,80003abe <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b08:	41f6579b          	sraiw	a5,a2,0x1f
    80003b0c:	01d7d69b          	srliw	a3,a5,0x1d
    80003b10:	00c6873b          	addw	a4,a3,a2
    80003b14:	00777793          	andi	a5,a4,7
    80003b18:	9f95                	subw	a5,a5,a3
    80003b1a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b1e:	4037571b          	sraiw	a4,a4,0x3
    80003b22:	00e906b3          	add	a3,s2,a4
    80003b26:	0586c683          	lbu	a3,88(a3)
    80003b2a:	00d7f5b3          	and	a1,a5,a3
    80003b2e:	cd91                	beqz	a1,80003b4a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b30:	2605                	addiw	a2,a2,1
    80003b32:	2485                	addiw	s1,s1,1
    80003b34:	fd4618e3          	bne	a2,s4,80003b04 <balloc+0x80>
    80003b38:	b759                	j	80003abe <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b3a:	00005517          	auipc	a0,0x5
    80003b3e:	b4e50513          	addi	a0,a0,-1202 # 80008688 <syscalls+0x118>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b4a:	974a                	add	a4,a4,s2
    80003b4c:	8fd5                	or	a5,a5,a3
    80003b4e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b52:	854a                	mv	a0,s2
    80003b54:	00001097          	auipc	ra,0x1
    80003b58:	01a080e7          	jalr	26(ra) # 80004b6e <log_write>
        brelse(bp);
    80003b5c:	854a                	mv	a0,s2
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	d94080e7          	jalr	-620(ra) # 800038f2 <brelse>
  bp = bread(dev, bno);
    80003b66:	85a6                	mv	a1,s1
    80003b68:	855e                	mv	a0,s7
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	c58080e7          	jalr	-936(ra) # 800037c2 <bread>
    80003b72:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b74:	40000613          	li	a2,1024
    80003b78:	4581                	li	a1,0
    80003b7a:	05850513          	addi	a0,a0,88
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	162080e7          	jalr	354(ra) # 80000ce0 <memset>
  log_write(bp);
    80003b86:	854a                	mv	a0,s2
    80003b88:	00001097          	auipc	ra,0x1
    80003b8c:	fe6080e7          	jalr	-26(ra) # 80004b6e <log_write>
  brelse(bp);
    80003b90:	854a                	mv	a0,s2
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	d60080e7          	jalr	-672(ra) # 800038f2 <brelse>
}
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	60e6                	ld	ra,88(sp)
    80003b9e:	6446                	ld	s0,80(sp)
    80003ba0:	64a6                	ld	s1,72(sp)
    80003ba2:	6906                	ld	s2,64(sp)
    80003ba4:	79e2                	ld	s3,56(sp)
    80003ba6:	7a42                	ld	s4,48(sp)
    80003ba8:	7aa2                	ld	s5,40(sp)
    80003baa:	7b02                	ld	s6,32(sp)
    80003bac:	6be2                	ld	s7,24(sp)
    80003bae:	6c42                	ld	s8,16(sp)
    80003bb0:	6ca2                	ld	s9,8(sp)
    80003bb2:	6125                	addi	sp,sp,96
    80003bb4:	8082                	ret

0000000080003bb6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003bb6:	7179                	addi	sp,sp,-48
    80003bb8:	f406                	sd	ra,40(sp)
    80003bba:	f022                	sd	s0,32(sp)
    80003bbc:	ec26                	sd	s1,24(sp)
    80003bbe:	e84a                	sd	s2,16(sp)
    80003bc0:	e44e                	sd	s3,8(sp)
    80003bc2:	e052                	sd	s4,0(sp)
    80003bc4:	1800                	addi	s0,sp,48
    80003bc6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003bc8:	47ad                	li	a5,11
    80003bca:	04b7fe63          	bgeu	a5,a1,80003c26 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003bce:	ff45849b          	addiw	s1,a1,-12
    80003bd2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bd6:	0ff00793          	li	a5,255
    80003bda:	0ae7e363          	bltu	a5,a4,80003c80 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bde:	08052583          	lw	a1,128(a0)
    80003be2:	c5ad                	beqz	a1,80003c4c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003be4:	00092503          	lw	a0,0(s2)
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	bda080e7          	jalr	-1062(ra) # 800037c2 <bread>
    80003bf0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bf2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bf6:	02049593          	slli	a1,s1,0x20
    80003bfa:	9181                	srli	a1,a1,0x20
    80003bfc:	058a                	slli	a1,a1,0x2
    80003bfe:	00b784b3          	add	s1,a5,a1
    80003c02:	0004a983          	lw	s3,0(s1)
    80003c06:	04098d63          	beqz	s3,80003c60 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c0a:	8552                	mv	a0,s4
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	ce6080e7          	jalr	-794(ra) # 800038f2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c14:	854e                	mv	a0,s3
    80003c16:	70a2                	ld	ra,40(sp)
    80003c18:	7402                	ld	s0,32(sp)
    80003c1a:	64e2                	ld	s1,24(sp)
    80003c1c:	6942                	ld	s2,16(sp)
    80003c1e:	69a2                	ld	s3,8(sp)
    80003c20:	6a02                	ld	s4,0(sp)
    80003c22:	6145                	addi	sp,sp,48
    80003c24:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c26:	02059493          	slli	s1,a1,0x20
    80003c2a:	9081                	srli	s1,s1,0x20
    80003c2c:	048a                	slli	s1,s1,0x2
    80003c2e:	94aa                	add	s1,s1,a0
    80003c30:	0504a983          	lw	s3,80(s1)
    80003c34:	fe0990e3          	bnez	s3,80003c14 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c38:	4108                	lw	a0,0(a0)
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	e4a080e7          	jalr	-438(ra) # 80003a84 <balloc>
    80003c42:	0005099b          	sext.w	s3,a0
    80003c46:	0534a823          	sw	s3,80(s1)
    80003c4a:	b7e9                	j	80003c14 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c4c:	4108                	lw	a0,0(a0)
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	e36080e7          	jalr	-458(ra) # 80003a84 <balloc>
    80003c56:	0005059b          	sext.w	a1,a0
    80003c5a:	08b92023          	sw	a1,128(s2)
    80003c5e:	b759                	j	80003be4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c60:	00092503          	lw	a0,0(s2)
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	e20080e7          	jalr	-480(ra) # 80003a84 <balloc>
    80003c6c:	0005099b          	sext.w	s3,a0
    80003c70:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c74:	8552                	mv	a0,s4
    80003c76:	00001097          	auipc	ra,0x1
    80003c7a:	ef8080e7          	jalr	-264(ra) # 80004b6e <log_write>
    80003c7e:	b771                	j	80003c0a <bmap+0x54>
  panic("bmap: out of range");
    80003c80:	00005517          	auipc	a0,0x5
    80003c84:	a2050513          	addi	a0,a0,-1504 # 800086a0 <syscalls+0x130>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	8b6080e7          	jalr	-1866(ra) # 8000053e <panic>

0000000080003c90 <iget>:
{
    80003c90:	7179                	addi	sp,sp,-48
    80003c92:	f406                	sd	ra,40(sp)
    80003c94:	f022                	sd	s0,32(sp)
    80003c96:	ec26                	sd	s1,24(sp)
    80003c98:	e84a                	sd	s2,16(sp)
    80003c9a:	e44e                	sd	s3,8(sp)
    80003c9c:	e052                	sd	s4,0(sp)
    80003c9e:	1800                	addi	s0,sp,48
    80003ca0:	89aa                	mv	s3,a0
    80003ca2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ca4:	0001c517          	auipc	a0,0x1c
    80003ca8:	6a450513          	addi	a0,a0,1700 # 80020348 <itable>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	f38080e7          	jalr	-200(ra) # 80000be4 <acquire>
  empty = 0;
    80003cb4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003cb6:	0001c497          	auipc	s1,0x1c
    80003cba:	6aa48493          	addi	s1,s1,1706 # 80020360 <itable+0x18>
    80003cbe:	0001e697          	auipc	a3,0x1e
    80003cc2:	13268693          	addi	a3,a3,306 # 80021df0 <log>
    80003cc6:	a039                	j	80003cd4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cc8:	02090b63          	beqz	s2,80003cfe <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ccc:	08848493          	addi	s1,s1,136
    80003cd0:	02d48a63          	beq	s1,a3,80003d04 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cd4:	449c                	lw	a5,8(s1)
    80003cd6:	fef059e3          	blez	a5,80003cc8 <iget+0x38>
    80003cda:	4098                	lw	a4,0(s1)
    80003cdc:	ff3716e3          	bne	a4,s3,80003cc8 <iget+0x38>
    80003ce0:	40d8                	lw	a4,4(s1)
    80003ce2:	ff4713e3          	bne	a4,s4,80003cc8 <iget+0x38>
      ip->ref++;
    80003ce6:	2785                	addiw	a5,a5,1
    80003ce8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003cea:	0001c517          	auipc	a0,0x1c
    80003cee:	65e50513          	addi	a0,a0,1630 # 80020348 <itable>
    80003cf2:	ffffd097          	auipc	ra,0xffffd
    80003cf6:	fa6080e7          	jalr	-90(ra) # 80000c98 <release>
      return ip;
    80003cfa:	8926                	mv	s2,s1
    80003cfc:	a03d                	j	80003d2a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cfe:	f7f9                	bnez	a5,80003ccc <iget+0x3c>
    80003d00:	8926                	mv	s2,s1
    80003d02:	b7e9                	j	80003ccc <iget+0x3c>
  if(empty == 0)
    80003d04:	02090c63          	beqz	s2,80003d3c <iget+0xac>
  ip->dev = dev;
    80003d08:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d0c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d10:	4785                	li	a5,1
    80003d12:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d16:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d1a:	0001c517          	auipc	a0,0x1c
    80003d1e:	62e50513          	addi	a0,a0,1582 # 80020348 <itable>
    80003d22:	ffffd097          	auipc	ra,0xffffd
    80003d26:	f76080e7          	jalr	-138(ra) # 80000c98 <release>
}
    80003d2a:	854a                	mv	a0,s2
    80003d2c:	70a2                	ld	ra,40(sp)
    80003d2e:	7402                	ld	s0,32(sp)
    80003d30:	64e2                	ld	s1,24(sp)
    80003d32:	6942                	ld	s2,16(sp)
    80003d34:	69a2                	ld	s3,8(sp)
    80003d36:	6a02                	ld	s4,0(sp)
    80003d38:	6145                	addi	sp,sp,48
    80003d3a:	8082                	ret
    panic("iget: no inodes");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	97c50513          	addi	a0,a0,-1668 # 800086b8 <syscalls+0x148>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>

0000000080003d4c <fsinit>:
fsinit(int dev) {
    80003d4c:	7179                	addi	sp,sp,-48
    80003d4e:	f406                	sd	ra,40(sp)
    80003d50:	f022                	sd	s0,32(sp)
    80003d52:	ec26                	sd	s1,24(sp)
    80003d54:	e84a                	sd	s2,16(sp)
    80003d56:	e44e                	sd	s3,8(sp)
    80003d58:	1800                	addi	s0,sp,48
    80003d5a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d5c:	4585                	li	a1,1
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	a64080e7          	jalr	-1436(ra) # 800037c2 <bread>
    80003d66:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d68:	0001c997          	auipc	s3,0x1c
    80003d6c:	5c098993          	addi	s3,s3,1472 # 80020328 <sb>
    80003d70:	02000613          	li	a2,32
    80003d74:	05850593          	addi	a1,a0,88
    80003d78:	854e                	mv	a0,s3
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	fc6080e7          	jalr	-58(ra) # 80000d40 <memmove>
  brelse(bp);
    80003d82:	8526                	mv	a0,s1
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	b6e080e7          	jalr	-1170(ra) # 800038f2 <brelse>
  if(sb.magic != FSMAGIC)
    80003d8c:	0009a703          	lw	a4,0(s3)
    80003d90:	102037b7          	lui	a5,0x10203
    80003d94:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d98:	02f71263          	bne	a4,a5,80003dbc <fsinit+0x70>
  initlog(dev, &sb);
    80003d9c:	0001c597          	auipc	a1,0x1c
    80003da0:	58c58593          	addi	a1,a1,1420 # 80020328 <sb>
    80003da4:	854a                	mv	a0,s2
    80003da6:	00001097          	auipc	ra,0x1
    80003daa:	b4c080e7          	jalr	-1204(ra) # 800048f2 <initlog>
}
    80003dae:	70a2                	ld	ra,40(sp)
    80003db0:	7402                	ld	s0,32(sp)
    80003db2:	64e2                	ld	s1,24(sp)
    80003db4:	6942                	ld	s2,16(sp)
    80003db6:	69a2                	ld	s3,8(sp)
    80003db8:	6145                	addi	sp,sp,48
    80003dba:	8082                	ret
    panic("invalid file system");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	90c50513          	addi	a0,a0,-1780 # 800086c8 <syscalls+0x158>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	77a080e7          	jalr	1914(ra) # 8000053e <panic>

0000000080003dcc <iinit>:
{
    80003dcc:	7179                	addi	sp,sp,-48
    80003dce:	f406                	sd	ra,40(sp)
    80003dd0:	f022                	sd	s0,32(sp)
    80003dd2:	ec26                	sd	s1,24(sp)
    80003dd4:	e84a                	sd	s2,16(sp)
    80003dd6:	e44e                	sd	s3,8(sp)
    80003dd8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003dda:	00005597          	auipc	a1,0x5
    80003dde:	90658593          	addi	a1,a1,-1786 # 800086e0 <syscalls+0x170>
    80003de2:	0001c517          	auipc	a0,0x1c
    80003de6:	56650513          	addi	a0,a0,1382 # 80020348 <itable>
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	d6a080e7          	jalr	-662(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003df2:	0001c497          	auipc	s1,0x1c
    80003df6:	57e48493          	addi	s1,s1,1406 # 80020370 <itable+0x28>
    80003dfa:	0001e997          	auipc	s3,0x1e
    80003dfe:	00698993          	addi	s3,s3,6 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e02:	00005917          	auipc	s2,0x5
    80003e06:	8e690913          	addi	s2,s2,-1818 # 800086e8 <syscalls+0x178>
    80003e0a:	85ca                	mv	a1,s2
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	00001097          	auipc	ra,0x1
    80003e12:	e46080e7          	jalr	-442(ra) # 80004c54 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e16:	08848493          	addi	s1,s1,136
    80003e1a:	ff3498e3          	bne	s1,s3,80003e0a <iinit+0x3e>
}
    80003e1e:	70a2                	ld	ra,40(sp)
    80003e20:	7402                	ld	s0,32(sp)
    80003e22:	64e2                	ld	s1,24(sp)
    80003e24:	6942                	ld	s2,16(sp)
    80003e26:	69a2                	ld	s3,8(sp)
    80003e28:	6145                	addi	sp,sp,48
    80003e2a:	8082                	ret

0000000080003e2c <ialloc>:
{
    80003e2c:	715d                	addi	sp,sp,-80
    80003e2e:	e486                	sd	ra,72(sp)
    80003e30:	e0a2                	sd	s0,64(sp)
    80003e32:	fc26                	sd	s1,56(sp)
    80003e34:	f84a                	sd	s2,48(sp)
    80003e36:	f44e                	sd	s3,40(sp)
    80003e38:	f052                	sd	s4,32(sp)
    80003e3a:	ec56                	sd	s5,24(sp)
    80003e3c:	e85a                	sd	s6,16(sp)
    80003e3e:	e45e                	sd	s7,8(sp)
    80003e40:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e42:	0001c717          	auipc	a4,0x1c
    80003e46:	4f272703          	lw	a4,1266(a4) # 80020334 <sb+0xc>
    80003e4a:	4785                	li	a5,1
    80003e4c:	04e7fa63          	bgeu	a5,a4,80003ea0 <ialloc+0x74>
    80003e50:	8aaa                	mv	s5,a0
    80003e52:	8bae                	mv	s7,a1
    80003e54:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e56:	0001ca17          	auipc	s4,0x1c
    80003e5a:	4d2a0a13          	addi	s4,s4,1234 # 80020328 <sb>
    80003e5e:	00048b1b          	sext.w	s6,s1
    80003e62:	0044d593          	srli	a1,s1,0x4
    80003e66:	018a2783          	lw	a5,24(s4)
    80003e6a:	9dbd                	addw	a1,a1,a5
    80003e6c:	8556                	mv	a0,s5
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	954080e7          	jalr	-1708(ra) # 800037c2 <bread>
    80003e76:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e78:	05850993          	addi	s3,a0,88
    80003e7c:	00f4f793          	andi	a5,s1,15
    80003e80:	079a                	slli	a5,a5,0x6
    80003e82:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e84:	00099783          	lh	a5,0(s3)
    80003e88:	c785                	beqz	a5,80003eb0 <ialloc+0x84>
    brelse(bp);
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	a68080e7          	jalr	-1432(ra) # 800038f2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e92:	0485                	addi	s1,s1,1
    80003e94:	00ca2703          	lw	a4,12(s4)
    80003e98:	0004879b          	sext.w	a5,s1
    80003e9c:	fce7e1e3          	bltu	a5,a4,80003e5e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ea0:	00005517          	auipc	a0,0x5
    80003ea4:	85050513          	addi	a0,a0,-1968 # 800086f0 <syscalls+0x180>
    80003ea8:	ffffc097          	auipc	ra,0xffffc
    80003eac:	696080e7          	jalr	1686(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003eb0:	04000613          	li	a2,64
    80003eb4:	4581                	li	a1,0
    80003eb6:	854e                	mv	a0,s3
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	e28080e7          	jalr	-472(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ec0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00001097          	auipc	ra,0x1
    80003eca:	ca8080e7          	jalr	-856(ra) # 80004b6e <log_write>
      brelse(bp);
    80003ece:	854a                	mv	a0,s2
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	a22080e7          	jalr	-1502(ra) # 800038f2 <brelse>
      return iget(dev, inum);
    80003ed8:	85da                	mv	a1,s6
    80003eda:	8556                	mv	a0,s5
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	db4080e7          	jalr	-588(ra) # 80003c90 <iget>
}
    80003ee4:	60a6                	ld	ra,72(sp)
    80003ee6:	6406                	ld	s0,64(sp)
    80003ee8:	74e2                	ld	s1,56(sp)
    80003eea:	7942                	ld	s2,48(sp)
    80003eec:	79a2                	ld	s3,40(sp)
    80003eee:	7a02                	ld	s4,32(sp)
    80003ef0:	6ae2                	ld	s5,24(sp)
    80003ef2:	6b42                	ld	s6,16(sp)
    80003ef4:	6ba2                	ld	s7,8(sp)
    80003ef6:	6161                	addi	sp,sp,80
    80003ef8:	8082                	ret

0000000080003efa <iupdate>:
{
    80003efa:	1101                	addi	sp,sp,-32
    80003efc:	ec06                	sd	ra,24(sp)
    80003efe:	e822                	sd	s0,16(sp)
    80003f00:	e426                	sd	s1,8(sp)
    80003f02:	e04a                	sd	s2,0(sp)
    80003f04:	1000                	addi	s0,sp,32
    80003f06:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f08:	415c                	lw	a5,4(a0)
    80003f0a:	0047d79b          	srliw	a5,a5,0x4
    80003f0e:	0001c597          	auipc	a1,0x1c
    80003f12:	4325a583          	lw	a1,1074(a1) # 80020340 <sb+0x18>
    80003f16:	9dbd                	addw	a1,a1,a5
    80003f18:	4108                	lw	a0,0(a0)
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	8a8080e7          	jalr	-1880(ra) # 800037c2 <bread>
    80003f22:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f24:	05850793          	addi	a5,a0,88
    80003f28:	40c8                	lw	a0,4(s1)
    80003f2a:	893d                	andi	a0,a0,15
    80003f2c:	051a                	slli	a0,a0,0x6
    80003f2e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f30:	04449703          	lh	a4,68(s1)
    80003f34:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f38:	04649703          	lh	a4,70(s1)
    80003f3c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f40:	04849703          	lh	a4,72(s1)
    80003f44:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f48:	04a49703          	lh	a4,74(s1)
    80003f4c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f50:	44f8                	lw	a4,76(s1)
    80003f52:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f54:	03400613          	li	a2,52
    80003f58:	05048593          	addi	a1,s1,80
    80003f5c:	0531                	addi	a0,a0,12
    80003f5e:	ffffd097          	auipc	ra,0xffffd
    80003f62:	de2080e7          	jalr	-542(ra) # 80000d40 <memmove>
  log_write(bp);
    80003f66:	854a                	mv	a0,s2
    80003f68:	00001097          	auipc	ra,0x1
    80003f6c:	c06080e7          	jalr	-1018(ra) # 80004b6e <log_write>
  brelse(bp);
    80003f70:	854a                	mv	a0,s2
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	980080e7          	jalr	-1664(ra) # 800038f2 <brelse>
}
    80003f7a:	60e2                	ld	ra,24(sp)
    80003f7c:	6442                	ld	s0,16(sp)
    80003f7e:	64a2                	ld	s1,8(sp)
    80003f80:	6902                	ld	s2,0(sp)
    80003f82:	6105                	addi	sp,sp,32
    80003f84:	8082                	ret

0000000080003f86 <idup>:
{
    80003f86:	1101                	addi	sp,sp,-32
    80003f88:	ec06                	sd	ra,24(sp)
    80003f8a:	e822                	sd	s0,16(sp)
    80003f8c:	e426                	sd	s1,8(sp)
    80003f8e:	1000                	addi	s0,sp,32
    80003f90:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f92:	0001c517          	auipc	a0,0x1c
    80003f96:	3b650513          	addi	a0,a0,950 # 80020348 <itable>
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	c4a080e7          	jalr	-950(ra) # 80000be4 <acquire>
  ip->ref++;
    80003fa2:	449c                	lw	a5,8(s1)
    80003fa4:	2785                	addiw	a5,a5,1
    80003fa6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fa8:	0001c517          	auipc	a0,0x1c
    80003fac:	3a050513          	addi	a0,a0,928 # 80020348 <itable>
    80003fb0:	ffffd097          	auipc	ra,0xffffd
    80003fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
}
    80003fb8:	8526                	mv	a0,s1
    80003fba:	60e2                	ld	ra,24(sp)
    80003fbc:	6442                	ld	s0,16(sp)
    80003fbe:	64a2                	ld	s1,8(sp)
    80003fc0:	6105                	addi	sp,sp,32
    80003fc2:	8082                	ret

0000000080003fc4 <ilock>:
{
    80003fc4:	1101                	addi	sp,sp,-32
    80003fc6:	ec06                	sd	ra,24(sp)
    80003fc8:	e822                	sd	s0,16(sp)
    80003fca:	e426                	sd	s1,8(sp)
    80003fcc:	e04a                	sd	s2,0(sp)
    80003fce:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fd0:	c115                	beqz	a0,80003ff4 <ilock+0x30>
    80003fd2:	84aa                	mv	s1,a0
    80003fd4:	451c                	lw	a5,8(a0)
    80003fd6:	00f05f63          	blez	a5,80003ff4 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fda:	0541                	addi	a0,a0,16
    80003fdc:	00001097          	auipc	ra,0x1
    80003fe0:	cb2080e7          	jalr	-846(ra) # 80004c8e <acquiresleep>
  if(ip->valid == 0){
    80003fe4:	40bc                	lw	a5,64(s1)
    80003fe6:	cf99                	beqz	a5,80004004 <ilock+0x40>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret
    panic("ilock");
    80003ff4:	00004517          	auipc	a0,0x4
    80003ff8:	71450513          	addi	a0,a0,1812 # 80008708 <syscalls+0x198>
    80003ffc:	ffffc097          	auipc	ra,0xffffc
    80004000:	542080e7          	jalr	1346(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004004:	40dc                	lw	a5,4(s1)
    80004006:	0047d79b          	srliw	a5,a5,0x4
    8000400a:	0001c597          	auipc	a1,0x1c
    8000400e:	3365a583          	lw	a1,822(a1) # 80020340 <sb+0x18>
    80004012:	9dbd                	addw	a1,a1,a5
    80004014:	4088                	lw	a0,0(s1)
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	7ac080e7          	jalr	1964(ra) # 800037c2 <bread>
    8000401e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004020:	05850593          	addi	a1,a0,88
    80004024:	40dc                	lw	a5,4(s1)
    80004026:	8bbd                	andi	a5,a5,15
    80004028:	079a                	slli	a5,a5,0x6
    8000402a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000402c:	00059783          	lh	a5,0(a1)
    80004030:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004034:	00259783          	lh	a5,2(a1)
    80004038:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000403c:	00459783          	lh	a5,4(a1)
    80004040:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004044:	00659783          	lh	a5,6(a1)
    80004048:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000404c:	459c                	lw	a5,8(a1)
    8000404e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004050:	03400613          	li	a2,52
    80004054:	05b1                	addi	a1,a1,12
    80004056:	05048513          	addi	a0,s1,80
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	ce6080e7          	jalr	-794(ra) # 80000d40 <memmove>
    brelse(bp);
    80004062:	854a                	mv	a0,s2
    80004064:	00000097          	auipc	ra,0x0
    80004068:	88e080e7          	jalr	-1906(ra) # 800038f2 <brelse>
    ip->valid = 1;
    8000406c:	4785                	li	a5,1
    8000406e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004070:	04449783          	lh	a5,68(s1)
    80004074:	fbb5                	bnez	a5,80003fe8 <ilock+0x24>
      panic("ilock: no type");
    80004076:	00004517          	auipc	a0,0x4
    8000407a:	69a50513          	addi	a0,a0,1690 # 80008710 <syscalls+0x1a0>
    8000407e:	ffffc097          	auipc	ra,0xffffc
    80004082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>

0000000080004086 <iunlock>:
{
    80004086:	1101                	addi	sp,sp,-32
    80004088:	ec06                	sd	ra,24(sp)
    8000408a:	e822                	sd	s0,16(sp)
    8000408c:	e426                	sd	s1,8(sp)
    8000408e:	e04a                	sd	s2,0(sp)
    80004090:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004092:	c905                	beqz	a0,800040c2 <iunlock+0x3c>
    80004094:	84aa                	mv	s1,a0
    80004096:	01050913          	addi	s2,a0,16
    8000409a:	854a                	mv	a0,s2
    8000409c:	00001097          	auipc	ra,0x1
    800040a0:	c8c080e7          	jalr	-884(ra) # 80004d28 <holdingsleep>
    800040a4:	cd19                	beqz	a0,800040c2 <iunlock+0x3c>
    800040a6:	449c                	lw	a5,8(s1)
    800040a8:	00f05d63          	blez	a5,800040c2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040ac:	854a                	mv	a0,s2
    800040ae:	00001097          	auipc	ra,0x1
    800040b2:	c36080e7          	jalr	-970(ra) # 80004ce4 <releasesleep>
}
    800040b6:	60e2                	ld	ra,24(sp)
    800040b8:	6442                	ld	s0,16(sp)
    800040ba:	64a2                	ld	s1,8(sp)
    800040bc:	6902                	ld	s2,0(sp)
    800040be:	6105                	addi	sp,sp,32
    800040c0:	8082                	ret
    panic("iunlock");
    800040c2:	00004517          	auipc	a0,0x4
    800040c6:	65e50513          	addi	a0,a0,1630 # 80008720 <syscalls+0x1b0>
    800040ca:	ffffc097          	auipc	ra,0xffffc
    800040ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>

00000000800040d2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040d2:	7179                	addi	sp,sp,-48
    800040d4:	f406                	sd	ra,40(sp)
    800040d6:	f022                	sd	s0,32(sp)
    800040d8:	ec26                	sd	s1,24(sp)
    800040da:	e84a                	sd	s2,16(sp)
    800040dc:	e44e                	sd	s3,8(sp)
    800040de:	e052                	sd	s4,0(sp)
    800040e0:	1800                	addi	s0,sp,48
    800040e2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040e4:	05050493          	addi	s1,a0,80
    800040e8:	08050913          	addi	s2,a0,128
    800040ec:	a021                	j	800040f4 <itrunc+0x22>
    800040ee:	0491                	addi	s1,s1,4
    800040f0:	01248d63          	beq	s1,s2,8000410a <itrunc+0x38>
    if(ip->addrs[i]){
    800040f4:	408c                	lw	a1,0(s1)
    800040f6:	dde5                	beqz	a1,800040ee <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040f8:	0009a503          	lw	a0,0(s3)
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	90c080e7          	jalr	-1780(ra) # 80003a08 <bfree>
      ip->addrs[i] = 0;
    80004104:	0004a023          	sw	zero,0(s1)
    80004108:	b7dd                	j	800040ee <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000410a:	0809a583          	lw	a1,128(s3)
    8000410e:	e185                	bnez	a1,8000412e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004110:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004114:	854e                	mv	a0,s3
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	de4080e7          	jalr	-540(ra) # 80003efa <iupdate>
}
    8000411e:	70a2                	ld	ra,40(sp)
    80004120:	7402                	ld	s0,32(sp)
    80004122:	64e2                	ld	s1,24(sp)
    80004124:	6942                	ld	s2,16(sp)
    80004126:	69a2                	ld	s3,8(sp)
    80004128:	6a02                	ld	s4,0(sp)
    8000412a:	6145                	addi	sp,sp,48
    8000412c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000412e:	0009a503          	lw	a0,0(s3)
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	690080e7          	jalr	1680(ra) # 800037c2 <bread>
    8000413a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000413c:	05850493          	addi	s1,a0,88
    80004140:	45850913          	addi	s2,a0,1112
    80004144:	a811                	j	80004158 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004146:	0009a503          	lw	a0,0(s3)
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	8be080e7          	jalr	-1858(ra) # 80003a08 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004152:	0491                	addi	s1,s1,4
    80004154:	01248563          	beq	s1,s2,8000415e <itrunc+0x8c>
      if(a[j])
    80004158:	408c                	lw	a1,0(s1)
    8000415a:	dde5                	beqz	a1,80004152 <itrunc+0x80>
    8000415c:	b7ed                	j	80004146 <itrunc+0x74>
    brelse(bp);
    8000415e:	8552                	mv	a0,s4
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	792080e7          	jalr	1938(ra) # 800038f2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004168:	0809a583          	lw	a1,128(s3)
    8000416c:	0009a503          	lw	a0,0(s3)
    80004170:	00000097          	auipc	ra,0x0
    80004174:	898080e7          	jalr	-1896(ra) # 80003a08 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004178:	0809a023          	sw	zero,128(s3)
    8000417c:	bf51                	j	80004110 <itrunc+0x3e>

000000008000417e <iput>:
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	e426                	sd	s1,8(sp)
    80004186:	e04a                	sd	s2,0(sp)
    80004188:	1000                	addi	s0,sp,32
    8000418a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000418c:	0001c517          	auipc	a0,0x1c
    80004190:	1bc50513          	addi	a0,a0,444 # 80020348 <itable>
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000419c:	4498                	lw	a4,8(s1)
    8000419e:	4785                	li	a5,1
    800041a0:	02f70363          	beq	a4,a5,800041c6 <iput+0x48>
  ip->ref--;
    800041a4:	449c                	lw	a5,8(s1)
    800041a6:	37fd                	addiw	a5,a5,-1
    800041a8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041aa:	0001c517          	auipc	a0,0x1c
    800041ae:	19e50513          	addi	a0,a0,414 # 80020348 <itable>
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	ae6080e7          	jalr	-1306(ra) # 80000c98 <release>
}
    800041ba:	60e2                	ld	ra,24(sp)
    800041bc:	6442                	ld	s0,16(sp)
    800041be:	64a2                	ld	s1,8(sp)
    800041c0:	6902                	ld	s2,0(sp)
    800041c2:	6105                	addi	sp,sp,32
    800041c4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041c6:	40bc                	lw	a5,64(s1)
    800041c8:	dff1                	beqz	a5,800041a4 <iput+0x26>
    800041ca:	04a49783          	lh	a5,74(s1)
    800041ce:	fbf9                	bnez	a5,800041a4 <iput+0x26>
    acquiresleep(&ip->lock);
    800041d0:	01048913          	addi	s2,s1,16
    800041d4:	854a                	mv	a0,s2
    800041d6:	00001097          	auipc	ra,0x1
    800041da:	ab8080e7          	jalr	-1352(ra) # 80004c8e <acquiresleep>
    release(&itable.lock);
    800041de:	0001c517          	auipc	a0,0x1c
    800041e2:	16a50513          	addi	a0,a0,362 # 80020348 <itable>
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	ab2080e7          	jalr	-1358(ra) # 80000c98 <release>
    itrunc(ip);
    800041ee:	8526                	mv	a0,s1
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	ee2080e7          	jalr	-286(ra) # 800040d2 <itrunc>
    ip->type = 0;
    800041f8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041fc:	8526                	mv	a0,s1
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	cfc080e7          	jalr	-772(ra) # 80003efa <iupdate>
    ip->valid = 0;
    80004206:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000420a:	854a                	mv	a0,s2
    8000420c:	00001097          	auipc	ra,0x1
    80004210:	ad8080e7          	jalr	-1320(ra) # 80004ce4 <releasesleep>
    acquire(&itable.lock);
    80004214:	0001c517          	auipc	a0,0x1c
    80004218:	13450513          	addi	a0,a0,308 # 80020348 <itable>
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	9c8080e7          	jalr	-1592(ra) # 80000be4 <acquire>
    80004224:	b741                	j	800041a4 <iput+0x26>

0000000080004226 <iunlockput>:
{
    80004226:	1101                	addi	sp,sp,-32
    80004228:	ec06                	sd	ra,24(sp)
    8000422a:	e822                	sd	s0,16(sp)
    8000422c:	e426                	sd	s1,8(sp)
    8000422e:	1000                	addi	s0,sp,32
    80004230:	84aa                	mv	s1,a0
  iunlock(ip);
    80004232:	00000097          	auipc	ra,0x0
    80004236:	e54080e7          	jalr	-428(ra) # 80004086 <iunlock>
  iput(ip);
    8000423a:	8526                	mv	a0,s1
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	f42080e7          	jalr	-190(ra) # 8000417e <iput>
}
    80004244:	60e2                	ld	ra,24(sp)
    80004246:	6442                	ld	s0,16(sp)
    80004248:	64a2                	ld	s1,8(sp)
    8000424a:	6105                	addi	sp,sp,32
    8000424c:	8082                	ret

000000008000424e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000424e:	1141                	addi	sp,sp,-16
    80004250:	e422                	sd	s0,8(sp)
    80004252:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004254:	411c                	lw	a5,0(a0)
    80004256:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004258:	415c                	lw	a5,4(a0)
    8000425a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000425c:	04451783          	lh	a5,68(a0)
    80004260:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004264:	04a51783          	lh	a5,74(a0)
    80004268:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000426c:	04c56783          	lwu	a5,76(a0)
    80004270:	e99c                	sd	a5,16(a1)
}
    80004272:	6422                	ld	s0,8(sp)
    80004274:	0141                	addi	sp,sp,16
    80004276:	8082                	ret

0000000080004278 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004278:	457c                	lw	a5,76(a0)
    8000427a:	0ed7e963          	bltu	a5,a3,8000436c <readi+0xf4>
{
    8000427e:	7159                	addi	sp,sp,-112
    80004280:	f486                	sd	ra,104(sp)
    80004282:	f0a2                	sd	s0,96(sp)
    80004284:	eca6                	sd	s1,88(sp)
    80004286:	e8ca                	sd	s2,80(sp)
    80004288:	e4ce                	sd	s3,72(sp)
    8000428a:	e0d2                	sd	s4,64(sp)
    8000428c:	fc56                	sd	s5,56(sp)
    8000428e:	f85a                	sd	s6,48(sp)
    80004290:	f45e                	sd	s7,40(sp)
    80004292:	f062                	sd	s8,32(sp)
    80004294:	ec66                	sd	s9,24(sp)
    80004296:	e86a                	sd	s10,16(sp)
    80004298:	e46e                	sd	s11,8(sp)
    8000429a:	1880                	addi	s0,sp,112
    8000429c:	8baa                	mv	s7,a0
    8000429e:	8c2e                	mv	s8,a1
    800042a0:	8ab2                	mv	s5,a2
    800042a2:	84b6                	mv	s1,a3
    800042a4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042a6:	9f35                	addw	a4,a4,a3
    return 0;
    800042a8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042aa:	0ad76063          	bltu	a4,a3,8000434a <readi+0xd2>
  if(off + n > ip->size)
    800042ae:	00e7f463          	bgeu	a5,a4,800042b6 <readi+0x3e>
    n = ip->size - off;
    800042b2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042b6:	0a0b0963          	beqz	s6,80004368 <readi+0xf0>
    800042ba:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042bc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042c0:	5cfd                	li	s9,-1
    800042c2:	a82d                	j	800042fc <readi+0x84>
    800042c4:	020a1d93          	slli	s11,s4,0x20
    800042c8:	020ddd93          	srli	s11,s11,0x20
    800042cc:	05890613          	addi	a2,s2,88
    800042d0:	86ee                	mv	a3,s11
    800042d2:	963a                	add	a2,a2,a4
    800042d4:	85d6                	mv	a1,s5
    800042d6:	8562                	mv	a0,s8
    800042d8:	ffffe097          	auipc	ra,0xffffe
    800042dc:	40c080e7          	jalr	1036(ra) # 800026e4 <either_copyout>
    800042e0:	05950d63          	beq	a0,s9,8000433a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042e4:	854a                	mv	a0,s2
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	60c080e7          	jalr	1548(ra) # 800038f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042ee:	013a09bb          	addw	s3,s4,s3
    800042f2:	009a04bb          	addw	s1,s4,s1
    800042f6:	9aee                	add	s5,s5,s11
    800042f8:	0569f763          	bgeu	s3,s6,80004346 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042fc:	000ba903          	lw	s2,0(s7)
    80004300:	00a4d59b          	srliw	a1,s1,0xa
    80004304:	855e                	mv	a0,s7
    80004306:	00000097          	auipc	ra,0x0
    8000430a:	8b0080e7          	jalr	-1872(ra) # 80003bb6 <bmap>
    8000430e:	0005059b          	sext.w	a1,a0
    80004312:	854a                	mv	a0,s2
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	4ae080e7          	jalr	1198(ra) # 800037c2 <bread>
    8000431c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000431e:	3ff4f713          	andi	a4,s1,1023
    80004322:	40ed07bb          	subw	a5,s10,a4
    80004326:	413b06bb          	subw	a3,s6,s3
    8000432a:	8a3e                	mv	s4,a5
    8000432c:	2781                	sext.w	a5,a5
    8000432e:	0006861b          	sext.w	a2,a3
    80004332:	f8f679e3          	bgeu	a2,a5,800042c4 <readi+0x4c>
    80004336:	8a36                	mv	s4,a3
    80004338:	b771                	j	800042c4 <readi+0x4c>
      brelse(bp);
    8000433a:	854a                	mv	a0,s2
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	5b6080e7          	jalr	1462(ra) # 800038f2 <brelse>
      tot = -1;
    80004344:	59fd                	li	s3,-1
  }
  return tot;
    80004346:	0009851b          	sext.w	a0,s3
}
    8000434a:	70a6                	ld	ra,104(sp)
    8000434c:	7406                	ld	s0,96(sp)
    8000434e:	64e6                	ld	s1,88(sp)
    80004350:	6946                	ld	s2,80(sp)
    80004352:	69a6                	ld	s3,72(sp)
    80004354:	6a06                	ld	s4,64(sp)
    80004356:	7ae2                	ld	s5,56(sp)
    80004358:	7b42                	ld	s6,48(sp)
    8000435a:	7ba2                	ld	s7,40(sp)
    8000435c:	7c02                	ld	s8,32(sp)
    8000435e:	6ce2                	ld	s9,24(sp)
    80004360:	6d42                	ld	s10,16(sp)
    80004362:	6da2                	ld	s11,8(sp)
    80004364:	6165                	addi	sp,sp,112
    80004366:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004368:	89da                	mv	s3,s6
    8000436a:	bff1                	j	80004346 <readi+0xce>
    return 0;
    8000436c:	4501                	li	a0,0
}
    8000436e:	8082                	ret

0000000080004370 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004370:	457c                	lw	a5,76(a0)
    80004372:	10d7e863          	bltu	a5,a3,80004482 <writei+0x112>
{
    80004376:	7159                	addi	sp,sp,-112
    80004378:	f486                	sd	ra,104(sp)
    8000437a:	f0a2                	sd	s0,96(sp)
    8000437c:	eca6                	sd	s1,88(sp)
    8000437e:	e8ca                	sd	s2,80(sp)
    80004380:	e4ce                	sd	s3,72(sp)
    80004382:	e0d2                	sd	s4,64(sp)
    80004384:	fc56                	sd	s5,56(sp)
    80004386:	f85a                	sd	s6,48(sp)
    80004388:	f45e                	sd	s7,40(sp)
    8000438a:	f062                	sd	s8,32(sp)
    8000438c:	ec66                	sd	s9,24(sp)
    8000438e:	e86a                	sd	s10,16(sp)
    80004390:	e46e                	sd	s11,8(sp)
    80004392:	1880                	addi	s0,sp,112
    80004394:	8b2a                	mv	s6,a0
    80004396:	8c2e                	mv	s8,a1
    80004398:	8ab2                	mv	s5,a2
    8000439a:	8936                	mv	s2,a3
    8000439c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000439e:	00e687bb          	addw	a5,a3,a4
    800043a2:	0ed7e263          	bltu	a5,a3,80004486 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800043a6:	00043737          	lui	a4,0x43
    800043aa:	0ef76063          	bltu	a4,a5,8000448a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ae:	0c0b8863          	beqz	s7,8000447e <writei+0x10e>
    800043b2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043b4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043b8:	5cfd                	li	s9,-1
    800043ba:	a091                	j	800043fe <writei+0x8e>
    800043bc:	02099d93          	slli	s11,s3,0x20
    800043c0:	020ddd93          	srli	s11,s11,0x20
    800043c4:	05848513          	addi	a0,s1,88
    800043c8:	86ee                	mv	a3,s11
    800043ca:	8656                	mv	a2,s5
    800043cc:	85e2                	mv	a1,s8
    800043ce:	953a                	add	a0,a0,a4
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	36a080e7          	jalr	874(ra) # 8000273a <either_copyin>
    800043d8:	07950263          	beq	a0,s9,8000443c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043dc:	8526                	mv	a0,s1
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	790080e7          	jalr	1936(ra) # 80004b6e <log_write>
    brelse(bp);
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	50a080e7          	jalr	1290(ra) # 800038f2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043f0:	01498a3b          	addw	s4,s3,s4
    800043f4:	0129893b          	addw	s2,s3,s2
    800043f8:	9aee                	add	s5,s5,s11
    800043fa:	057a7663          	bgeu	s4,s7,80004446 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043fe:	000b2483          	lw	s1,0(s6)
    80004402:	00a9559b          	srliw	a1,s2,0xa
    80004406:	855a                	mv	a0,s6
    80004408:	fffff097          	auipc	ra,0xfffff
    8000440c:	7ae080e7          	jalr	1966(ra) # 80003bb6 <bmap>
    80004410:	0005059b          	sext.w	a1,a0
    80004414:	8526                	mv	a0,s1
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	3ac080e7          	jalr	940(ra) # 800037c2 <bread>
    8000441e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004420:	3ff97713          	andi	a4,s2,1023
    80004424:	40ed07bb          	subw	a5,s10,a4
    80004428:	414b86bb          	subw	a3,s7,s4
    8000442c:	89be                	mv	s3,a5
    8000442e:	2781                	sext.w	a5,a5
    80004430:	0006861b          	sext.w	a2,a3
    80004434:	f8f674e3          	bgeu	a2,a5,800043bc <writei+0x4c>
    80004438:	89b6                	mv	s3,a3
    8000443a:	b749                	j	800043bc <writei+0x4c>
      brelse(bp);
    8000443c:	8526                	mv	a0,s1
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	4b4080e7          	jalr	1204(ra) # 800038f2 <brelse>
  }

  if(off > ip->size)
    80004446:	04cb2783          	lw	a5,76(s6)
    8000444a:	0127f463          	bgeu	a5,s2,80004452 <writei+0xe2>
    ip->size = off;
    8000444e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004452:	855a                	mv	a0,s6
    80004454:	00000097          	auipc	ra,0x0
    80004458:	aa6080e7          	jalr	-1370(ra) # 80003efa <iupdate>

  return tot;
    8000445c:	000a051b          	sext.w	a0,s4
}
    80004460:	70a6                	ld	ra,104(sp)
    80004462:	7406                	ld	s0,96(sp)
    80004464:	64e6                	ld	s1,88(sp)
    80004466:	6946                	ld	s2,80(sp)
    80004468:	69a6                	ld	s3,72(sp)
    8000446a:	6a06                	ld	s4,64(sp)
    8000446c:	7ae2                	ld	s5,56(sp)
    8000446e:	7b42                	ld	s6,48(sp)
    80004470:	7ba2                	ld	s7,40(sp)
    80004472:	7c02                	ld	s8,32(sp)
    80004474:	6ce2                	ld	s9,24(sp)
    80004476:	6d42                	ld	s10,16(sp)
    80004478:	6da2                	ld	s11,8(sp)
    8000447a:	6165                	addi	sp,sp,112
    8000447c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000447e:	8a5e                	mv	s4,s7
    80004480:	bfc9                	j	80004452 <writei+0xe2>
    return -1;
    80004482:	557d                	li	a0,-1
}
    80004484:	8082                	ret
    return -1;
    80004486:	557d                	li	a0,-1
    80004488:	bfe1                	j	80004460 <writei+0xf0>
    return -1;
    8000448a:	557d                	li	a0,-1
    8000448c:	bfd1                	j	80004460 <writei+0xf0>

000000008000448e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000448e:	1141                	addi	sp,sp,-16
    80004490:	e406                	sd	ra,8(sp)
    80004492:	e022                	sd	s0,0(sp)
    80004494:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004496:	4639                	li	a2,14
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	920080e7          	jalr	-1760(ra) # 80000db8 <strncmp>
}
    800044a0:	60a2                	ld	ra,8(sp)
    800044a2:	6402                	ld	s0,0(sp)
    800044a4:	0141                	addi	sp,sp,16
    800044a6:	8082                	ret

00000000800044a8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800044a8:	7139                	addi	sp,sp,-64
    800044aa:	fc06                	sd	ra,56(sp)
    800044ac:	f822                	sd	s0,48(sp)
    800044ae:	f426                	sd	s1,40(sp)
    800044b0:	f04a                	sd	s2,32(sp)
    800044b2:	ec4e                	sd	s3,24(sp)
    800044b4:	e852                	sd	s4,16(sp)
    800044b6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044b8:	04451703          	lh	a4,68(a0)
    800044bc:	4785                	li	a5,1
    800044be:	00f71a63          	bne	a4,a5,800044d2 <dirlookup+0x2a>
    800044c2:	892a                	mv	s2,a0
    800044c4:	89ae                	mv	s3,a1
    800044c6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c8:	457c                	lw	a5,76(a0)
    800044ca:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044cc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ce:	e79d                	bnez	a5,800044fc <dirlookup+0x54>
    800044d0:	a8a5                	j	80004548 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044d2:	00004517          	auipc	a0,0x4
    800044d6:	25650513          	addi	a0,a0,598 # 80008728 <syscalls+0x1b8>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	064080e7          	jalr	100(ra) # 8000053e <panic>
      panic("dirlookup read");
    800044e2:	00004517          	auipc	a0,0x4
    800044e6:	25e50513          	addi	a0,a0,606 # 80008740 <syscalls+0x1d0>
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	054080e7          	jalr	84(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f2:	24c1                	addiw	s1,s1,16
    800044f4:	04c92783          	lw	a5,76(s2)
    800044f8:	04f4f763          	bgeu	s1,a5,80004546 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044fc:	4741                	li	a4,16
    800044fe:	86a6                	mv	a3,s1
    80004500:	fc040613          	addi	a2,s0,-64
    80004504:	4581                	li	a1,0
    80004506:	854a                	mv	a0,s2
    80004508:	00000097          	auipc	ra,0x0
    8000450c:	d70080e7          	jalr	-656(ra) # 80004278 <readi>
    80004510:	47c1                	li	a5,16
    80004512:	fcf518e3          	bne	a0,a5,800044e2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004516:	fc045783          	lhu	a5,-64(s0)
    8000451a:	dfe1                	beqz	a5,800044f2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000451c:	fc240593          	addi	a1,s0,-62
    80004520:	854e                	mv	a0,s3
    80004522:	00000097          	auipc	ra,0x0
    80004526:	f6c080e7          	jalr	-148(ra) # 8000448e <namecmp>
    8000452a:	f561                	bnez	a0,800044f2 <dirlookup+0x4a>
      if(poff)
    8000452c:	000a0463          	beqz	s4,80004534 <dirlookup+0x8c>
        *poff = off;
    80004530:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004534:	fc045583          	lhu	a1,-64(s0)
    80004538:	00092503          	lw	a0,0(s2)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	754080e7          	jalr	1876(ra) # 80003c90 <iget>
    80004544:	a011                	j	80004548 <dirlookup+0xa0>
  return 0;
    80004546:	4501                	li	a0,0
}
    80004548:	70e2                	ld	ra,56(sp)
    8000454a:	7442                	ld	s0,48(sp)
    8000454c:	74a2                	ld	s1,40(sp)
    8000454e:	7902                	ld	s2,32(sp)
    80004550:	69e2                	ld	s3,24(sp)
    80004552:	6a42                	ld	s4,16(sp)
    80004554:	6121                	addi	sp,sp,64
    80004556:	8082                	ret

0000000080004558 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004558:	711d                	addi	sp,sp,-96
    8000455a:	ec86                	sd	ra,88(sp)
    8000455c:	e8a2                	sd	s0,80(sp)
    8000455e:	e4a6                	sd	s1,72(sp)
    80004560:	e0ca                	sd	s2,64(sp)
    80004562:	fc4e                	sd	s3,56(sp)
    80004564:	f852                	sd	s4,48(sp)
    80004566:	f456                	sd	s5,40(sp)
    80004568:	f05a                	sd	s6,32(sp)
    8000456a:	ec5e                	sd	s7,24(sp)
    8000456c:	e862                	sd	s8,16(sp)
    8000456e:	e466                	sd	s9,8(sp)
    80004570:	1080                	addi	s0,sp,96
    80004572:	84aa                	mv	s1,a0
    80004574:	8b2e                	mv	s6,a1
    80004576:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004578:	00054703          	lbu	a4,0(a0)
    8000457c:	02f00793          	li	a5,47
    80004580:	02f70363          	beq	a4,a5,800045a6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	948080e7          	jalr	-1720(ra) # 80001ecc <myproc>
    8000458c:	15053503          	ld	a0,336(a0)
    80004590:	00000097          	auipc	ra,0x0
    80004594:	9f6080e7          	jalr	-1546(ra) # 80003f86 <idup>
    80004598:	89aa                	mv	s3,a0
  while(*path == '/')
    8000459a:	02f00913          	li	s2,47
  len = path - s;
    8000459e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800045a0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800045a2:	4c05                	li	s8,1
    800045a4:	a865                	j	8000465c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800045a6:	4585                	li	a1,1
    800045a8:	4505                	li	a0,1
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	6e6080e7          	jalr	1766(ra) # 80003c90 <iget>
    800045b2:	89aa                	mv	s3,a0
    800045b4:	b7dd                	j	8000459a <namex+0x42>
      iunlockput(ip);
    800045b6:	854e                	mv	a0,s3
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	c6e080e7          	jalr	-914(ra) # 80004226 <iunlockput>
      return 0;
    800045c0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045c2:	854e                	mv	a0,s3
    800045c4:	60e6                	ld	ra,88(sp)
    800045c6:	6446                	ld	s0,80(sp)
    800045c8:	64a6                	ld	s1,72(sp)
    800045ca:	6906                	ld	s2,64(sp)
    800045cc:	79e2                	ld	s3,56(sp)
    800045ce:	7a42                	ld	s4,48(sp)
    800045d0:	7aa2                	ld	s5,40(sp)
    800045d2:	7b02                	ld	s6,32(sp)
    800045d4:	6be2                	ld	s7,24(sp)
    800045d6:	6c42                	ld	s8,16(sp)
    800045d8:	6ca2                	ld	s9,8(sp)
    800045da:	6125                	addi	sp,sp,96
    800045dc:	8082                	ret
      iunlock(ip);
    800045de:	854e                	mv	a0,s3
    800045e0:	00000097          	auipc	ra,0x0
    800045e4:	aa6080e7          	jalr	-1370(ra) # 80004086 <iunlock>
      return ip;
    800045e8:	bfe9                	j	800045c2 <namex+0x6a>
      iunlockput(ip);
    800045ea:	854e                	mv	a0,s3
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	c3a080e7          	jalr	-966(ra) # 80004226 <iunlockput>
      return 0;
    800045f4:	89d2                	mv	s3,s4
    800045f6:	b7f1                	j	800045c2 <namex+0x6a>
  len = path - s;
    800045f8:	40b48633          	sub	a2,s1,a1
    800045fc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004600:	094cd463          	bge	s9,s4,80004688 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004604:	4639                	li	a2,14
    80004606:	8556                	mv	a0,s5
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	738080e7          	jalr	1848(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004610:	0004c783          	lbu	a5,0(s1)
    80004614:	01279763          	bne	a5,s2,80004622 <namex+0xca>
    path++;
    80004618:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000461a:	0004c783          	lbu	a5,0(s1)
    8000461e:	ff278de3          	beq	a5,s2,80004618 <namex+0xc0>
    ilock(ip);
    80004622:	854e                	mv	a0,s3
    80004624:	00000097          	auipc	ra,0x0
    80004628:	9a0080e7          	jalr	-1632(ra) # 80003fc4 <ilock>
    if(ip->type != T_DIR){
    8000462c:	04499783          	lh	a5,68(s3)
    80004630:	f98793e3          	bne	a5,s8,800045b6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004634:	000b0563          	beqz	s6,8000463e <namex+0xe6>
    80004638:	0004c783          	lbu	a5,0(s1)
    8000463c:	d3cd                	beqz	a5,800045de <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000463e:	865e                	mv	a2,s7
    80004640:	85d6                	mv	a1,s5
    80004642:	854e                	mv	a0,s3
    80004644:	00000097          	auipc	ra,0x0
    80004648:	e64080e7          	jalr	-412(ra) # 800044a8 <dirlookup>
    8000464c:	8a2a                	mv	s4,a0
    8000464e:	dd51                	beqz	a0,800045ea <namex+0x92>
    iunlockput(ip);
    80004650:	854e                	mv	a0,s3
    80004652:	00000097          	auipc	ra,0x0
    80004656:	bd4080e7          	jalr	-1068(ra) # 80004226 <iunlockput>
    ip = next;
    8000465a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000465c:	0004c783          	lbu	a5,0(s1)
    80004660:	05279763          	bne	a5,s2,800046ae <namex+0x156>
    path++;
    80004664:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004666:	0004c783          	lbu	a5,0(s1)
    8000466a:	ff278de3          	beq	a5,s2,80004664 <namex+0x10c>
  if(*path == 0)
    8000466e:	c79d                	beqz	a5,8000469c <namex+0x144>
    path++;
    80004670:	85a6                	mv	a1,s1
  len = path - s;
    80004672:	8a5e                	mv	s4,s7
    80004674:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004676:	01278963          	beq	a5,s2,80004688 <namex+0x130>
    8000467a:	dfbd                	beqz	a5,800045f8 <namex+0xa0>
    path++;
    8000467c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000467e:	0004c783          	lbu	a5,0(s1)
    80004682:	ff279ce3          	bne	a5,s2,8000467a <namex+0x122>
    80004686:	bf8d                	j	800045f8 <namex+0xa0>
    memmove(name, s, len);
    80004688:	2601                	sext.w	a2,a2
    8000468a:	8556                	mv	a0,s5
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	6b4080e7          	jalr	1716(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004694:	9a56                	add	s4,s4,s5
    80004696:	000a0023          	sb	zero,0(s4)
    8000469a:	bf9d                	j	80004610 <namex+0xb8>
  if(nameiparent){
    8000469c:	f20b03e3          	beqz	s6,800045c2 <namex+0x6a>
    iput(ip);
    800046a0:	854e                	mv	a0,s3
    800046a2:	00000097          	auipc	ra,0x0
    800046a6:	adc080e7          	jalr	-1316(ra) # 8000417e <iput>
    return 0;
    800046aa:	4981                	li	s3,0
    800046ac:	bf19                	j	800045c2 <namex+0x6a>
  if(*path == 0)
    800046ae:	d7fd                	beqz	a5,8000469c <namex+0x144>
  while(*path != '/' && *path != 0)
    800046b0:	0004c783          	lbu	a5,0(s1)
    800046b4:	85a6                	mv	a1,s1
    800046b6:	b7d1                	j	8000467a <namex+0x122>

00000000800046b8 <dirlink>:
{
    800046b8:	7139                	addi	sp,sp,-64
    800046ba:	fc06                	sd	ra,56(sp)
    800046bc:	f822                	sd	s0,48(sp)
    800046be:	f426                	sd	s1,40(sp)
    800046c0:	f04a                	sd	s2,32(sp)
    800046c2:	ec4e                	sd	s3,24(sp)
    800046c4:	e852                	sd	s4,16(sp)
    800046c6:	0080                	addi	s0,sp,64
    800046c8:	892a                	mv	s2,a0
    800046ca:	8a2e                	mv	s4,a1
    800046cc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046ce:	4601                	li	a2,0
    800046d0:	00000097          	auipc	ra,0x0
    800046d4:	dd8080e7          	jalr	-552(ra) # 800044a8 <dirlookup>
    800046d8:	e93d                	bnez	a0,8000474e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046da:	04c92483          	lw	s1,76(s2)
    800046de:	c49d                	beqz	s1,8000470c <dirlink+0x54>
    800046e0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046e2:	4741                	li	a4,16
    800046e4:	86a6                	mv	a3,s1
    800046e6:	fc040613          	addi	a2,s0,-64
    800046ea:	4581                	li	a1,0
    800046ec:	854a                	mv	a0,s2
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	b8a080e7          	jalr	-1142(ra) # 80004278 <readi>
    800046f6:	47c1                	li	a5,16
    800046f8:	06f51163          	bne	a0,a5,8000475a <dirlink+0xa2>
    if(de.inum == 0)
    800046fc:	fc045783          	lhu	a5,-64(s0)
    80004700:	c791                	beqz	a5,8000470c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004702:	24c1                	addiw	s1,s1,16
    80004704:	04c92783          	lw	a5,76(s2)
    80004708:	fcf4ede3          	bltu	s1,a5,800046e2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000470c:	4639                	li	a2,14
    8000470e:	85d2                	mv	a1,s4
    80004710:	fc240513          	addi	a0,s0,-62
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	6e0080e7          	jalr	1760(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000471c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004720:	4741                	li	a4,16
    80004722:	86a6                	mv	a3,s1
    80004724:	fc040613          	addi	a2,s0,-64
    80004728:	4581                	li	a1,0
    8000472a:	854a                	mv	a0,s2
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	c44080e7          	jalr	-956(ra) # 80004370 <writei>
    80004734:	872a                	mv	a4,a0
    80004736:	47c1                	li	a5,16
  return 0;
    80004738:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000473a:	02f71863          	bne	a4,a5,8000476a <dirlink+0xb2>
}
    8000473e:	70e2                	ld	ra,56(sp)
    80004740:	7442                	ld	s0,48(sp)
    80004742:	74a2                	ld	s1,40(sp)
    80004744:	7902                	ld	s2,32(sp)
    80004746:	69e2                	ld	s3,24(sp)
    80004748:	6a42                	ld	s4,16(sp)
    8000474a:	6121                	addi	sp,sp,64
    8000474c:	8082                	ret
    iput(ip);
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	a30080e7          	jalr	-1488(ra) # 8000417e <iput>
    return -1;
    80004756:	557d                	li	a0,-1
    80004758:	b7dd                	j	8000473e <dirlink+0x86>
      panic("dirlink read");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	ff650513          	addi	a0,a0,-10 # 80008750 <syscalls+0x1e0>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	ddc080e7          	jalr	-548(ra) # 8000053e <panic>
    panic("dirlink");
    8000476a:	00004517          	auipc	a0,0x4
    8000476e:	0f650513          	addi	a0,a0,246 # 80008860 <syscalls+0x2f0>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>

000000008000477a <namei>:

struct inode*
namei(char *path)
{
    8000477a:	1101                	addi	sp,sp,-32
    8000477c:	ec06                	sd	ra,24(sp)
    8000477e:	e822                	sd	s0,16(sp)
    80004780:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004782:	fe040613          	addi	a2,s0,-32
    80004786:	4581                	li	a1,0
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	dd0080e7          	jalr	-560(ra) # 80004558 <namex>
}
    80004790:	60e2                	ld	ra,24(sp)
    80004792:	6442                	ld	s0,16(sp)
    80004794:	6105                	addi	sp,sp,32
    80004796:	8082                	ret

0000000080004798 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004798:	1141                	addi	sp,sp,-16
    8000479a:	e406                	sd	ra,8(sp)
    8000479c:	e022                	sd	s0,0(sp)
    8000479e:	0800                	addi	s0,sp,16
    800047a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800047a2:	4585                	li	a1,1
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	db4080e7          	jalr	-588(ra) # 80004558 <namex>
}
    800047ac:	60a2                	ld	ra,8(sp)
    800047ae:	6402                	ld	s0,0(sp)
    800047b0:	0141                	addi	sp,sp,16
    800047b2:	8082                	ret

00000000800047b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047b4:	1101                	addi	sp,sp,-32
    800047b6:	ec06                	sd	ra,24(sp)
    800047b8:	e822                	sd	s0,16(sp)
    800047ba:	e426                	sd	s1,8(sp)
    800047bc:	e04a                	sd	s2,0(sp)
    800047be:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047c0:	0001d917          	auipc	s2,0x1d
    800047c4:	63090913          	addi	s2,s2,1584 # 80021df0 <log>
    800047c8:	01892583          	lw	a1,24(s2)
    800047cc:	02892503          	lw	a0,40(s2)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	ff2080e7          	jalr	-14(ra) # 800037c2 <bread>
    800047d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047da:	02c92683          	lw	a3,44(s2)
    800047de:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047e0:	02d05763          	blez	a3,8000480e <write_head+0x5a>
    800047e4:	0001d797          	auipc	a5,0x1d
    800047e8:	63c78793          	addi	a5,a5,1596 # 80021e20 <log+0x30>
    800047ec:	05c50713          	addi	a4,a0,92
    800047f0:	36fd                	addiw	a3,a3,-1
    800047f2:	1682                	slli	a3,a3,0x20
    800047f4:	9281                	srli	a3,a3,0x20
    800047f6:	068a                	slli	a3,a3,0x2
    800047f8:	0001d617          	auipc	a2,0x1d
    800047fc:	62c60613          	addi	a2,a2,1580 # 80021e24 <log+0x34>
    80004800:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004802:	4390                	lw	a2,0(a5)
    80004804:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004806:	0791                	addi	a5,a5,4
    80004808:	0711                	addi	a4,a4,4
    8000480a:	fed79ce3          	bne	a5,a3,80004802 <write_head+0x4e>
  }
  bwrite(buf);
    8000480e:	8526                	mv	a0,s1
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	0a4080e7          	jalr	164(ra) # 800038b4 <bwrite>
  brelse(buf);
    80004818:	8526                	mv	a0,s1
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	0d8080e7          	jalr	216(ra) # 800038f2 <brelse>
}
    80004822:	60e2                	ld	ra,24(sp)
    80004824:	6442                	ld	s0,16(sp)
    80004826:	64a2                	ld	s1,8(sp)
    80004828:	6902                	ld	s2,0(sp)
    8000482a:	6105                	addi	sp,sp,32
    8000482c:	8082                	ret

000000008000482e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000482e:	0001d797          	auipc	a5,0x1d
    80004832:	5ee7a783          	lw	a5,1518(a5) # 80021e1c <log+0x2c>
    80004836:	0af05d63          	blez	a5,800048f0 <install_trans+0xc2>
{
    8000483a:	7139                	addi	sp,sp,-64
    8000483c:	fc06                	sd	ra,56(sp)
    8000483e:	f822                	sd	s0,48(sp)
    80004840:	f426                	sd	s1,40(sp)
    80004842:	f04a                	sd	s2,32(sp)
    80004844:	ec4e                	sd	s3,24(sp)
    80004846:	e852                	sd	s4,16(sp)
    80004848:	e456                	sd	s5,8(sp)
    8000484a:	e05a                	sd	s6,0(sp)
    8000484c:	0080                	addi	s0,sp,64
    8000484e:	8b2a                	mv	s6,a0
    80004850:	0001da97          	auipc	s5,0x1d
    80004854:	5d0a8a93          	addi	s5,s5,1488 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004858:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000485a:	0001d997          	auipc	s3,0x1d
    8000485e:	59698993          	addi	s3,s3,1430 # 80021df0 <log>
    80004862:	a035                	j	8000488e <install_trans+0x60>
      bunpin(dbuf);
    80004864:	8526                	mv	a0,s1
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	166080e7          	jalr	358(ra) # 800039cc <bunpin>
    brelse(lbuf);
    8000486e:	854a                	mv	a0,s2
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	082080e7          	jalr	130(ra) # 800038f2 <brelse>
    brelse(dbuf);
    80004878:	8526                	mv	a0,s1
    8000487a:	fffff097          	auipc	ra,0xfffff
    8000487e:	078080e7          	jalr	120(ra) # 800038f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004882:	2a05                	addiw	s4,s4,1
    80004884:	0a91                	addi	s5,s5,4
    80004886:	02c9a783          	lw	a5,44(s3)
    8000488a:	04fa5963          	bge	s4,a5,800048dc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000488e:	0189a583          	lw	a1,24(s3)
    80004892:	014585bb          	addw	a1,a1,s4
    80004896:	2585                	addiw	a1,a1,1
    80004898:	0289a503          	lw	a0,40(s3)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	f26080e7          	jalr	-218(ra) # 800037c2 <bread>
    800048a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800048a6:	000aa583          	lw	a1,0(s5)
    800048aa:	0289a503          	lw	a0,40(s3)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	f14080e7          	jalr	-236(ra) # 800037c2 <bread>
    800048b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048b8:	40000613          	li	a2,1024
    800048bc:	05890593          	addi	a1,s2,88
    800048c0:	05850513          	addi	a0,a0,88
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	47c080e7          	jalr	1148(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800048cc:	8526                	mv	a0,s1
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	fe6080e7          	jalr	-26(ra) # 800038b4 <bwrite>
    if(recovering == 0)
    800048d6:	f80b1ce3          	bnez	s6,8000486e <install_trans+0x40>
    800048da:	b769                	j	80004864 <install_trans+0x36>
}
    800048dc:	70e2                	ld	ra,56(sp)
    800048de:	7442                	ld	s0,48(sp)
    800048e0:	74a2                	ld	s1,40(sp)
    800048e2:	7902                	ld	s2,32(sp)
    800048e4:	69e2                	ld	s3,24(sp)
    800048e6:	6a42                	ld	s4,16(sp)
    800048e8:	6aa2                	ld	s5,8(sp)
    800048ea:	6b02                	ld	s6,0(sp)
    800048ec:	6121                	addi	sp,sp,64
    800048ee:	8082                	ret
    800048f0:	8082                	ret

00000000800048f2 <initlog>:
{
    800048f2:	7179                	addi	sp,sp,-48
    800048f4:	f406                	sd	ra,40(sp)
    800048f6:	f022                	sd	s0,32(sp)
    800048f8:	ec26                	sd	s1,24(sp)
    800048fa:	e84a                	sd	s2,16(sp)
    800048fc:	e44e                	sd	s3,8(sp)
    800048fe:	1800                	addi	s0,sp,48
    80004900:	892a                	mv	s2,a0
    80004902:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004904:	0001d497          	auipc	s1,0x1d
    80004908:	4ec48493          	addi	s1,s1,1260 # 80021df0 <log>
    8000490c:	00004597          	auipc	a1,0x4
    80004910:	e5458593          	addi	a1,a1,-428 # 80008760 <syscalls+0x1f0>
    80004914:	8526                	mv	a0,s1
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	23e080e7          	jalr	574(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000491e:	0149a583          	lw	a1,20(s3)
    80004922:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004924:	0109a783          	lw	a5,16(s3)
    80004928:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000492a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000492e:	854a                	mv	a0,s2
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	e92080e7          	jalr	-366(ra) # 800037c2 <bread>
  log.lh.n = lh->n;
    80004938:	4d3c                	lw	a5,88(a0)
    8000493a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000493c:	02f05563          	blez	a5,80004966 <initlog+0x74>
    80004940:	05c50713          	addi	a4,a0,92
    80004944:	0001d697          	auipc	a3,0x1d
    80004948:	4dc68693          	addi	a3,a3,1244 # 80021e20 <log+0x30>
    8000494c:	37fd                	addiw	a5,a5,-1
    8000494e:	1782                	slli	a5,a5,0x20
    80004950:	9381                	srli	a5,a5,0x20
    80004952:	078a                	slli	a5,a5,0x2
    80004954:	06050613          	addi	a2,a0,96
    80004958:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000495a:	4310                	lw	a2,0(a4)
    8000495c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000495e:	0711                	addi	a4,a4,4
    80004960:	0691                	addi	a3,a3,4
    80004962:	fef71ce3          	bne	a4,a5,8000495a <initlog+0x68>
  brelse(buf);
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	f8c080e7          	jalr	-116(ra) # 800038f2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000496e:	4505                	li	a0,1
    80004970:	00000097          	auipc	ra,0x0
    80004974:	ebe080e7          	jalr	-322(ra) # 8000482e <install_trans>
  log.lh.n = 0;
    80004978:	0001d797          	auipc	a5,0x1d
    8000497c:	4a07a223          	sw	zero,1188(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004980:	00000097          	auipc	ra,0x0
    80004984:	e34080e7          	jalr	-460(ra) # 800047b4 <write_head>
}
    80004988:	70a2                	ld	ra,40(sp)
    8000498a:	7402                	ld	s0,32(sp)
    8000498c:	64e2                	ld	s1,24(sp)
    8000498e:	6942                	ld	s2,16(sp)
    80004990:	69a2                	ld	s3,8(sp)
    80004992:	6145                	addi	sp,sp,48
    80004994:	8082                	ret

0000000080004996 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004996:	1101                	addi	sp,sp,-32
    80004998:	ec06                	sd	ra,24(sp)
    8000499a:	e822                	sd	s0,16(sp)
    8000499c:	e426                	sd	s1,8(sp)
    8000499e:	e04a                	sd	s2,0(sp)
    800049a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800049a2:	0001d517          	auipc	a0,0x1d
    800049a6:	44e50513          	addi	a0,a0,1102 # 80021df0 <log>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	23a080e7          	jalr	570(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800049b2:	0001d497          	auipc	s1,0x1d
    800049b6:	43e48493          	addi	s1,s1,1086 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049ba:	4979                	li	s2,30
    800049bc:	a039                	j	800049ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800049be:	85a6                	mv	a1,s1
    800049c0:	8526                	mv	a0,s1
    800049c2:	ffffe097          	auipc	ra,0xffffe
    800049c6:	ae0080e7          	jalr	-1312(ra) # 800024a2 <sleep>
    if(log.committing){
    800049ca:	50dc                	lw	a5,36(s1)
    800049cc:	fbed                	bnez	a5,800049be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049ce:	509c                	lw	a5,32(s1)
    800049d0:	0017871b          	addiw	a4,a5,1
    800049d4:	0007069b          	sext.w	a3,a4
    800049d8:	0027179b          	slliw	a5,a4,0x2
    800049dc:	9fb9                	addw	a5,a5,a4
    800049de:	0017979b          	slliw	a5,a5,0x1
    800049e2:	54d8                	lw	a4,44(s1)
    800049e4:	9fb9                	addw	a5,a5,a4
    800049e6:	00f95963          	bge	s2,a5,800049f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049ea:	85a6                	mv	a1,s1
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffe097          	auipc	ra,0xffffe
    800049f2:	ab4080e7          	jalr	-1356(ra) # 800024a2 <sleep>
    800049f6:	bfd1                	j	800049ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049f8:	0001d517          	auipc	a0,0x1d
    800049fc:	3f850513          	addi	a0,a0,1016 # 80021df0 <log>
    80004a00:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	296080e7          	jalr	662(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004a0a:	60e2                	ld	ra,24(sp)
    80004a0c:	6442                	ld	s0,16(sp)
    80004a0e:	64a2                	ld	s1,8(sp)
    80004a10:	6902                	ld	s2,0(sp)
    80004a12:	6105                	addi	sp,sp,32
    80004a14:	8082                	ret

0000000080004a16 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a16:	7139                	addi	sp,sp,-64
    80004a18:	fc06                	sd	ra,56(sp)
    80004a1a:	f822                	sd	s0,48(sp)
    80004a1c:	f426                	sd	s1,40(sp)
    80004a1e:	f04a                	sd	s2,32(sp)
    80004a20:	ec4e                	sd	s3,24(sp)
    80004a22:	e852                	sd	s4,16(sp)
    80004a24:	e456                	sd	s5,8(sp)
    80004a26:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a28:	0001d497          	auipc	s1,0x1d
    80004a2c:	3c848493          	addi	s1,s1,968 # 80021df0 <log>
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	1b2080e7          	jalr	434(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004a3a:	509c                	lw	a5,32(s1)
    80004a3c:	37fd                	addiw	a5,a5,-1
    80004a3e:	0007891b          	sext.w	s2,a5
    80004a42:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a44:	50dc                	lw	a5,36(s1)
    80004a46:	efb9                	bnez	a5,80004aa4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a48:	06091663          	bnez	s2,80004ab4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004a4c:	0001d497          	auipc	s1,0x1d
    80004a50:	3a448493          	addi	s1,s1,932 # 80021df0 <log>
    80004a54:	4785                	li	a5,1
    80004a56:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	23e080e7          	jalr	574(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a62:	54dc                	lw	a5,44(s1)
    80004a64:	06f04763          	bgtz	a5,80004ad2 <end_op+0xbc>
    acquire(&log.lock);
    80004a68:	0001d497          	auipc	s1,0x1d
    80004a6c:	38848493          	addi	s1,s1,904 # 80021df0 <log>
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	172080e7          	jalr	370(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004a7a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a7e:	8526                	mv	a0,s1
    80004a80:	ffffe097          	auipc	ra,0xffffe
    80004a84:	04e080e7          	jalr	78(ra) # 80002ace <wakeup>
    release(&log.lock);
    80004a88:	8526                	mv	a0,s1
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	20e080e7          	jalr	526(ra) # 80000c98 <release>
}
    80004a92:	70e2                	ld	ra,56(sp)
    80004a94:	7442                	ld	s0,48(sp)
    80004a96:	74a2                	ld	s1,40(sp)
    80004a98:	7902                	ld	s2,32(sp)
    80004a9a:	69e2                	ld	s3,24(sp)
    80004a9c:	6a42                	ld	s4,16(sp)
    80004a9e:	6aa2                	ld	s5,8(sp)
    80004aa0:	6121                	addi	sp,sp,64
    80004aa2:	8082                	ret
    panic("log.committing");
    80004aa4:	00004517          	auipc	a0,0x4
    80004aa8:	cc450513          	addi	a0,a0,-828 # 80008768 <syscalls+0x1f8>
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>
    wakeup(&log);
    80004ab4:	0001d497          	auipc	s1,0x1d
    80004ab8:	33c48493          	addi	s1,s1,828 # 80021df0 <log>
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffe097          	auipc	ra,0xffffe
    80004ac2:	010080e7          	jalr	16(ra) # 80002ace <wakeup>
  release(&log.lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
  if(do_commit){
    80004ad0:	b7c9                	j	80004a92 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ad2:	0001da97          	auipc	s5,0x1d
    80004ad6:	34ea8a93          	addi	s5,s5,846 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ada:	0001da17          	auipc	s4,0x1d
    80004ade:	316a0a13          	addi	s4,s4,790 # 80021df0 <log>
    80004ae2:	018a2583          	lw	a1,24(s4)
    80004ae6:	012585bb          	addw	a1,a1,s2
    80004aea:	2585                	addiw	a1,a1,1
    80004aec:	028a2503          	lw	a0,40(s4)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	cd2080e7          	jalr	-814(ra) # 800037c2 <bread>
    80004af8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004afa:	000aa583          	lw	a1,0(s5)
    80004afe:	028a2503          	lw	a0,40(s4)
    80004b02:	fffff097          	auipc	ra,0xfffff
    80004b06:	cc0080e7          	jalr	-832(ra) # 800037c2 <bread>
    80004b0a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b0c:	40000613          	li	a2,1024
    80004b10:	05850593          	addi	a1,a0,88
    80004b14:	05848513          	addi	a0,s1,88
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	228080e7          	jalr	552(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004b20:	8526                	mv	a0,s1
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	d92080e7          	jalr	-622(ra) # 800038b4 <bwrite>
    brelse(from);
    80004b2a:	854e                	mv	a0,s3
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	dc6080e7          	jalr	-570(ra) # 800038f2 <brelse>
    brelse(to);
    80004b34:	8526                	mv	a0,s1
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	dbc080e7          	jalr	-580(ra) # 800038f2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b3e:	2905                	addiw	s2,s2,1
    80004b40:	0a91                	addi	s5,s5,4
    80004b42:	02ca2783          	lw	a5,44(s4)
    80004b46:	f8f94ee3          	blt	s2,a5,80004ae2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b4a:	00000097          	auipc	ra,0x0
    80004b4e:	c6a080e7          	jalr	-918(ra) # 800047b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004b52:	4501                	li	a0,0
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	cda080e7          	jalr	-806(ra) # 8000482e <install_trans>
    log.lh.n = 0;
    80004b5c:	0001d797          	auipc	a5,0x1d
    80004b60:	2c07a023          	sw	zero,704(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	c50080e7          	jalr	-944(ra) # 800047b4 <write_head>
    80004b6c:	bdf5                	j	80004a68 <end_op+0x52>

0000000080004b6e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b6e:	1101                	addi	sp,sp,-32
    80004b70:	ec06                	sd	ra,24(sp)
    80004b72:	e822                	sd	s0,16(sp)
    80004b74:	e426                	sd	s1,8(sp)
    80004b76:	e04a                	sd	s2,0(sp)
    80004b78:	1000                	addi	s0,sp,32
    80004b7a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004b7c:	0001d917          	auipc	s2,0x1d
    80004b80:	27490913          	addi	s2,s2,628 # 80021df0 <log>
    80004b84:	854a                	mv	a0,s2
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	05e080e7          	jalr	94(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b8e:	02c92603          	lw	a2,44(s2)
    80004b92:	47f5                	li	a5,29
    80004b94:	06c7c563          	blt	a5,a2,80004bfe <log_write+0x90>
    80004b98:	0001d797          	auipc	a5,0x1d
    80004b9c:	2747a783          	lw	a5,628(a5) # 80021e0c <log+0x1c>
    80004ba0:	37fd                	addiw	a5,a5,-1
    80004ba2:	04f65e63          	bge	a2,a5,80004bfe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ba6:	0001d797          	auipc	a5,0x1d
    80004baa:	26a7a783          	lw	a5,618(a5) # 80021e10 <log+0x20>
    80004bae:	06f05063          	blez	a5,80004c0e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004bb2:	4781                	li	a5,0
    80004bb4:	06c05563          	blez	a2,80004c1e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bb8:	44cc                	lw	a1,12(s1)
    80004bba:	0001d717          	auipc	a4,0x1d
    80004bbe:	26670713          	addi	a4,a4,614 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bc2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004bc4:	4314                	lw	a3,0(a4)
    80004bc6:	04b68c63          	beq	a3,a1,80004c1e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004bca:	2785                	addiw	a5,a5,1
    80004bcc:	0711                	addi	a4,a4,4
    80004bce:	fef61be3          	bne	a2,a5,80004bc4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bd2:	0621                	addi	a2,a2,8
    80004bd4:	060a                	slli	a2,a2,0x2
    80004bd6:	0001d797          	auipc	a5,0x1d
    80004bda:	21a78793          	addi	a5,a5,538 # 80021df0 <log>
    80004bde:	963e                	add	a2,a2,a5
    80004be0:	44dc                	lw	a5,12(s1)
    80004be2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004be4:	8526                	mv	a0,s1
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	daa080e7          	jalr	-598(ra) # 80003990 <bpin>
    log.lh.n++;
    80004bee:	0001d717          	auipc	a4,0x1d
    80004bf2:	20270713          	addi	a4,a4,514 # 80021df0 <log>
    80004bf6:	575c                	lw	a5,44(a4)
    80004bf8:	2785                	addiw	a5,a5,1
    80004bfa:	d75c                	sw	a5,44(a4)
    80004bfc:	a835                	j	80004c38 <log_write+0xca>
    panic("too big a transaction");
    80004bfe:	00004517          	auipc	a0,0x4
    80004c02:	b7a50513          	addi	a0,a0,-1158 # 80008778 <syscalls+0x208>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	938080e7          	jalr	-1736(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c0e:	00004517          	auipc	a0,0x4
    80004c12:	b8250513          	addi	a0,a0,-1150 # 80008790 <syscalls+0x220>
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	928080e7          	jalr	-1752(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c1e:	00878713          	addi	a4,a5,8
    80004c22:	00271693          	slli	a3,a4,0x2
    80004c26:	0001d717          	auipc	a4,0x1d
    80004c2a:	1ca70713          	addi	a4,a4,458 # 80021df0 <log>
    80004c2e:	9736                	add	a4,a4,a3
    80004c30:	44d4                	lw	a3,12(s1)
    80004c32:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c34:	faf608e3          	beq	a2,a5,80004be4 <log_write+0x76>
  }
  release(&log.lock);
    80004c38:	0001d517          	auipc	a0,0x1d
    80004c3c:	1b850513          	addi	a0,a0,440 # 80021df0 <log>
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	058080e7          	jalr	88(ra) # 80000c98 <release>
}
    80004c48:	60e2                	ld	ra,24(sp)
    80004c4a:	6442                	ld	s0,16(sp)
    80004c4c:	64a2                	ld	s1,8(sp)
    80004c4e:	6902                	ld	s2,0(sp)
    80004c50:	6105                	addi	sp,sp,32
    80004c52:	8082                	ret

0000000080004c54 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c54:	1101                	addi	sp,sp,-32
    80004c56:	ec06                	sd	ra,24(sp)
    80004c58:	e822                	sd	s0,16(sp)
    80004c5a:	e426                	sd	s1,8(sp)
    80004c5c:	e04a                	sd	s2,0(sp)
    80004c5e:	1000                	addi	s0,sp,32
    80004c60:	84aa                	mv	s1,a0
    80004c62:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c64:	00004597          	auipc	a1,0x4
    80004c68:	b4c58593          	addi	a1,a1,-1204 # 800087b0 <syscalls+0x240>
    80004c6c:	0521                	addi	a0,a0,8
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	ee6080e7          	jalr	-282(ra) # 80000b54 <initlock>
  lk->name = name;
    80004c76:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c7a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c7e:	0204a423          	sw	zero,40(s1)
}
    80004c82:	60e2                	ld	ra,24(sp)
    80004c84:	6442                	ld	s0,16(sp)
    80004c86:	64a2                	ld	s1,8(sp)
    80004c88:	6902                	ld	s2,0(sp)
    80004c8a:	6105                	addi	sp,sp,32
    80004c8c:	8082                	ret

0000000080004c8e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c8e:	1101                	addi	sp,sp,-32
    80004c90:	ec06                	sd	ra,24(sp)
    80004c92:	e822                	sd	s0,16(sp)
    80004c94:	e426                	sd	s1,8(sp)
    80004c96:	e04a                	sd	s2,0(sp)
    80004c98:	1000                	addi	s0,sp,32
    80004c9a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c9c:	00850913          	addi	s2,a0,8
    80004ca0:	854a                	mv	a0,s2
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	f42080e7          	jalr	-190(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004caa:	409c                	lw	a5,0(s1)
    80004cac:	cb89                	beqz	a5,80004cbe <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cae:	85ca                	mv	a1,s2
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	7f0080e7          	jalr	2032(ra) # 800024a2 <sleep>
  while (lk->locked) {
    80004cba:	409c                	lw	a5,0(s1)
    80004cbc:	fbed                	bnez	a5,80004cae <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cbe:	4785                	li	a5,1
    80004cc0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	20a080e7          	jalr	522(ra) # 80001ecc <myproc>
    80004cca:	591c                	lw	a5,48(a0)
    80004ccc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004cce:	854a                	mv	a0,s2
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	fc8080e7          	jalr	-56(ra) # 80000c98 <release>
}
    80004cd8:	60e2                	ld	ra,24(sp)
    80004cda:	6442                	ld	s0,16(sp)
    80004cdc:	64a2                	ld	s1,8(sp)
    80004cde:	6902                	ld	s2,0(sp)
    80004ce0:	6105                	addi	sp,sp,32
    80004ce2:	8082                	ret

0000000080004ce4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ce4:	1101                	addi	sp,sp,-32
    80004ce6:	ec06                	sd	ra,24(sp)
    80004ce8:	e822                	sd	s0,16(sp)
    80004cea:	e426                	sd	s1,8(sp)
    80004cec:	e04a                	sd	s2,0(sp)
    80004cee:	1000                	addi	s0,sp,32
    80004cf0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cf2:	00850913          	addi	s2,a0,8
    80004cf6:	854a                	mv	a0,s2
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	eec080e7          	jalr	-276(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d00:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d04:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffe097          	auipc	ra,0xffffe
    80004d0e:	dc4080e7          	jalr	-572(ra) # 80002ace <wakeup>
  release(&lk->lk);
    80004d12:	854a                	mv	a0,s2
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f84080e7          	jalr	-124(ra) # 80000c98 <release>
}
    80004d1c:	60e2                	ld	ra,24(sp)
    80004d1e:	6442                	ld	s0,16(sp)
    80004d20:	64a2                	ld	s1,8(sp)
    80004d22:	6902                	ld	s2,0(sp)
    80004d24:	6105                	addi	sp,sp,32
    80004d26:	8082                	ret

0000000080004d28 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d28:	7179                	addi	sp,sp,-48
    80004d2a:	f406                	sd	ra,40(sp)
    80004d2c:	f022                	sd	s0,32(sp)
    80004d2e:	ec26                	sd	s1,24(sp)
    80004d30:	e84a                	sd	s2,16(sp)
    80004d32:	e44e                	sd	s3,8(sp)
    80004d34:	1800                	addi	s0,sp,48
    80004d36:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d38:	00850913          	addi	s2,a0,8
    80004d3c:	854a                	mv	a0,s2
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	ea6080e7          	jalr	-346(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d46:	409c                	lw	a5,0(s1)
    80004d48:	ef99                	bnez	a5,80004d66 <holdingsleep+0x3e>
    80004d4a:	4481                	li	s1,0
  release(&lk->lk);
    80004d4c:	854a                	mv	a0,s2
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f4a080e7          	jalr	-182(ra) # 80000c98 <release>
  return r;
}
    80004d56:	8526                	mv	a0,s1
    80004d58:	70a2                	ld	ra,40(sp)
    80004d5a:	7402                	ld	s0,32(sp)
    80004d5c:	64e2                	ld	s1,24(sp)
    80004d5e:	6942                	ld	s2,16(sp)
    80004d60:	69a2                	ld	s3,8(sp)
    80004d62:	6145                	addi	sp,sp,48
    80004d64:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d66:	0284a983          	lw	s3,40(s1)
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	162080e7          	jalr	354(ra) # 80001ecc <myproc>
    80004d72:	5904                	lw	s1,48(a0)
    80004d74:	413484b3          	sub	s1,s1,s3
    80004d78:	0014b493          	seqz	s1,s1
    80004d7c:	bfc1                	j	80004d4c <holdingsleep+0x24>

0000000080004d7e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d7e:	1141                	addi	sp,sp,-16
    80004d80:	e406                	sd	ra,8(sp)
    80004d82:	e022                	sd	s0,0(sp)
    80004d84:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d86:	00004597          	auipc	a1,0x4
    80004d8a:	a3a58593          	addi	a1,a1,-1478 # 800087c0 <syscalls+0x250>
    80004d8e:	0001d517          	auipc	a0,0x1d
    80004d92:	1aa50513          	addi	a0,a0,426 # 80021f38 <ftable>
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	dbe080e7          	jalr	-578(ra) # 80000b54 <initlock>
}
    80004d9e:	60a2                	ld	ra,8(sp)
    80004da0:	6402                	ld	s0,0(sp)
    80004da2:	0141                	addi	sp,sp,16
    80004da4:	8082                	ret

0000000080004da6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004da6:	1101                	addi	sp,sp,-32
    80004da8:	ec06                	sd	ra,24(sp)
    80004daa:	e822                	sd	s0,16(sp)
    80004dac:	e426                	sd	s1,8(sp)
    80004dae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004db0:	0001d517          	auipc	a0,0x1d
    80004db4:	18850513          	addi	a0,a0,392 # 80021f38 <ftable>
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	e2c080e7          	jalr	-468(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dc0:	0001d497          	auipc	s1,0x1d
    80004dc4:	19048493          	addi	s1,s1,400 # 80021f50 <ftable+0x18>
    80004dc8:	0001e717          	auipc	a4,0x1e
    80004dcc:	12870713          	addi	a4,a4,296 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004dd0:	40dc                	lw	a5,4(s1)
    80004dd2:	cf99                	beqz	a5,80004df0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dd4:	02848493          	addi	s1,s1,40
    80004dd8:	fee49ce3          	bne	s1,a4,80004dd0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ddc:	0001d517          	auipc	a0,0x1d
    80004de0:	15c50513          	addi	a0,a0,348 # 80021f38 <ftable>
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	eb4080e7          	jalr	-332(ra) # 80000c98 <release>
  return 0;
    80004dec:	4481                	li	s1,0
    80004dee:	a819                	j	80004e04 <filealloc+0x5e>
      f->ref = 1;
    80004df0:	4785                	li	a5,1
    80004df2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004df4:	0001d517          	auipc	a0,0x1d
    80004df8:	14450513          	addi	a0,a0,324 # 80021f38 <ftable>
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	e9c080e7          	jalr	-356(ra) # 80000c98 <release>
}
    80004e04:	8526                	mv	a0,s1
    80004e06:	60e2                	ld	ra,24(sp)
    80004e08:	6442                	ld	s0,16(sp)
    80004e0a:	64a2                	ld	s1,8(sp)
    80004e0c:	6105                	addi	sp,sp,32
    80004e0e:	8082                	ret

0000000080004e10 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e10:	1101                	addi	sp,sp,-32
    80004e12:	ec06                	sd	ra,24(sp)
    80004e14:	e822                	sd	s0,16(sp)
    80004e16:	e426                	sd	s1,8(sp)
    80004e18:	1000                	addi	s0,sp,32
    80004e1a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e1c:	0001d517          	auipc	a0,0x1d
    80004e20:	11c50513          	addi	a0,a0,284 # 80021f38 <ftable>
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	dc0080e7          	jalr	-576(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e2c:	40dc                	lw	a5,4(s1)
    80004e2e:	02f05263          	blez	a5,80004e52 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e32:	2785                	addiw	a5,a5,1
    80004e34:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e36:	0001d517          	auipc	a0,0x1d
    80004e3a:	10250513          	addi	a0,a0,258 # 80021f38 <ftable>
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	e5a080e7          	jalr	-422(ra) # 80000c98 <release>
  return f;
}
    80004e46:	8526                	mv	a0,s1
    80004e48:	60e2                	ld	ra,24(sp)
    80004e4a:	6442                	ld	s0,16(sp)
    80004e4c:	64a2                	ld	s1,8(sp)
    80004e4e:	6105                	addi	sp,sp,32
    80004e50:	8082                	ret
    panic("filedup");
    80004e52:	00004517          	auipc	a0,0x4
    80004e56:	97650513          	addi	a0,a0,-1674 # 800087c8 <syscalls+0x258>
    80004e5a:	ffffb097          	auipc	ra,0xffffb
    80004e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>

0000000080004e62 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e62:	7139                	addi	sp,sp,-64
    80004e64:	fc06                	sd	ra,56(sp)
    80004e66:	f822                	sd	s0,48(sp)
    80004e68:	f426                	sd	s1,40(sp)
    80004e6a:	f04a                	sd	s2,32(sp)
    80004e6c:	ec4e                	sd	s3,24(sp)
    80004e6e:	e852                	sd	s4,16(sp)
    80004e70:	e456                	sd	s5,8(sp)
    80004e72:	0080                	addi	s0,sp,64
    80004e74:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e76:	0001d517          	auipc	a0,0x1d
    80004e7a:	0c250513          	addi	a0,a0,194 # 80021f38 <ftable>
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	d66080e7          	jalr	-666(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e86:	40dc                	lw	a5,4(s1)
    80004e88:	06f05163          	blez	a5,80004eea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e8c:	37fd                	addiw	a5,a5,-1
    80004e8e:	0007871b          	sext.w	a4,a5
    80004e92:	c0dc                	sw	a5,4(s1)
    80004e94:	06e04363          	bgtz	a4,80004efa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e98:	0004a903          	lw	s2,0(s1)
    80004e9c:	0094ca83          	lbu	s5,9(s1)
    80004ea0:	0104ba03          	ld	s4,16(s1)
    80004ea4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ea8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004eac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004eb0:	0001d517          	auipc	a0,0x1d
    80004eb4:	08850513          	addi	a0,a0,136 # 80021f38 <ftable>
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	de0080e7          	jalr	-544(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ec0:	4785                	li	a5,1
    80004ec2:	04f90d63          	beq	s2,a5,80004f1c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ec6:	3979                	addiw	s2,s2,-2
    80004ec8:	4785                	li	a5,1
    80004eca:	0527e063          	bltu	a5,s2,80004f0a <fileclose+0xa8>
    begin_op();
    80004ece:	00000097          	auipc	ra,0x0
    80004ed2:	ac8080e7          	jalr	-1336(ra) # 80004996 <begin_op>
    iput(ff.ip);
    80004ed6:	854e                	mv	a0,s3
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	2a6080e7          	jalr	678(ra) # 8000417e <iput>
    end_op();
    80004ee0:	00000097          	auipc	ra,0x0
    80004ee4:	b36080e7          	jalr	-1226(ra) # 80004a16 <end_op>
    80004ee8:	a00d                	j	80004f0a <fileclose+0xa8>
    panic("fileclose");
    80004eea:	00004517          	auipc	a0,0x4
    80004eee:	8e650513          	addi	a0,a0,-1818 # 800087d0 <syscalls+0x260>
    80004ef2:	ffffb097          	auipc	ra,0xffffb
    80004ef6:	64c080e7          	jalr	1612(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004efa:	0001d517          	auipc	a0,0x1d
    80004efe:	03e50513          	addi	a0,a0,62 # 80021f38 <ftable>
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	d96080e7          	jalr	-618(ra) # 80000c98 <release>
  }
}
    80004f0a:	70e2                	ld	ra,56(sp)
    80004f0c:	7442                	ld	s0,48(sp)
    80004f0e:	74a2                	ld	s1,40(sp)
    80004f10:	7902                	ld	s2,32(sp)
    80004f12:	69e2                	ld	s3,24(sp)
    80004f14:	6a42                	ld	s4,16(sp)
    80004f16:	6aa2                	ld	s5,8(sp)
    80004f18:	6121                	addi	sp,sp,64
    80004f1a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f1c:	85d6                	mv	a1,s5
    80004f1e:	8552                	mv	a0,s4
    80004f20:	00000097          	auipc	ra,0x0
    80004f24:	34c080e7          	jalr	844(ra) # 8000526c <pipeclose>
    80004f28:	b7cd                	j	80004f0a <fileclose+0xa8>

0000000080004f2a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f2a:	715d                	addi	sp,sp,-80
    80004f2c:	e486                	sd	ra,72(sp)
    80004f2e:	e0a2                	sd	s0,64(sp)
    80004f30:	fc26                	sd	s1,56(sp)
    80004f32:	f84a                	sd	s2,48(sp)
    80004f34:	f44e                	sd	s3,40(sp)
    80004f36:	0880                	addi	s0,sp,80
    80004f38:	84aa                	mv	s1,a0
    80004f3a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f3c:	ffffd097          	auipc	ra,0xffffd
    80004f40:	f90080e7          	jalr	-112(ra) # 80001ecc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f44:	409c                	lw	a5,0(s1)
    80004f46:	37f9                	addiw	a5,a5,-2
    80004f48:	4705                	li	a4,1
    80004f4a:	04f76763          	bltu	a4,a5,80004f98 <filestat+0x6e>
    80004f4e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f50:	6c88                	ld	a0,24(s1)
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	072080e7          	jalr	114(ra) # 80003fc4 <ilock>
    stati(f->ip, &st);
    80004f5a:	fb840593          	addi	a1,s0,-72
    80004f5e:	6c88                	ld	a0,24(s1)
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	2ee080e7          	jalr	750(ra) # 8000424e <stati>
    iunlock(f->ip);
    80004f68:	6c88                	ld	a0,24(s1)
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	11c080e7          	jalr	284(ra) # 80004086 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f72:	46e1                	li	a3,24
    80004f74:	fb840613          	addi	a2,s0,-72
    80004f78:	85ce                	mv	a1,s3
    80004f7a:	05093503          	ld	a0,80(s2)
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	6f4080e7          	jalr	1780(ra) # 80001672 <copyout>
    80004f86:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f8a:	60a6                	ld	ra,72(sp)
    80004f8c:	6406                	ld	s0,64(sp)
    80004f8e:	74e2                	ld	s1,56(sp)
    80004f90:	7942                	ld	s2,48(sp)
    80004f92:	79a2                	ld	s3,40(sp)
    80004f94:	6161                	addi	sp,sp,80
    80004f96:	8082                	ret
  return -1;
    80004f98:	557d                	li	a0,-1
    80004f9a:	bfc5                	j	80004f8a <filestat+0x60>

0000000080004f9c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f9c:	7179                	addi	sp,sp,-48
    80004f9e:	f406                	sd	ra,40(sp)
    80004fa0:	f022                	sd	s0,32(sp)
    80004fa2:	ec26                	sd	s1,24(sp)
    80004fa4:	e84a                	sd	s2,16(sp)
    80004fa6:	e44e                	sd	s3,8(sp)
    80004fa8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004faa:	00854783          	lbu	a5,8(a0)
    80004fae:	c3d5                	beqz	a5,80005052 <fileread+0xb6>
    80004fb0:	84aa                	mv	s1,a0
    80004fb2:	89ae                	mv	s3,a1
    80004fb4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fb6:	411c                	lw	a5,0(a0)
    80004fb8:	4705                	li	a4,1
    80004fba:	04e78963          	beq	a5,a4,8000500c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fbe:	470d                	li	a4,3
    80004fc0:	04e78d63          	beq	a5,a4,8000501a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fc4:	4709                	li	a4,2
    80004fc6:	06e79e63          	bne	a5,a4,80005042 <fileread+0xa6>
    ilock(f->ip);
    80004fca:	6d08                	ld	a0,24(a0)
    80004fcc:	fffff097          	auipc	ra,0xfffff
    80004fd0:	ff8080e7          	jalr	-8(ra) # 80003fc4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fd4:	874a                	mv	a4,s2
    80004fd6:	5094                	lw	a3,32(s1)
    80004fd8:	864e                	mv	a2,s3
    80004fda:	4585                	li	a1,1
    80004fdc:	6c88                	ld	a0,24(s1)
    80004fde:	fffff097          	auipc	ra,0xfffff
    80004fe2:	29a080e7          	jalr	666(ra) # 80004278 <readi>
    80004fe6:	892a                	mv	s2,a0
    80004fe8:	00a05563          	blez	a0,80004ff2 <fileread+0x56>
      f->off += r;
    80004fec:	509c                	lw	a5,32(s1)
    80004fee:	9fa9                	addw	a5,a5,a0
    80004ff0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ff2:	6c88                	ld	a0,24(s1)
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	092080e7          	jalr	146(ra) # 80004086 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ffc:	854a                	mv	a0,s2
    80004ffe:	70a2                	ld	ra,40(sp)
    80005000:	7402                	ld	s0,32(sp)
    80005002:	64e2                	ld	s1,24(sp)
    80005004:	6942                	ld	s2,16(sp)
    80005006:	69a2                	ld	s3,8(sp)
    80005008:	6145                	addi	sp,sp,48
    8000500a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000500c:	6908                	ld	a0,16(a0)
    8000500e:	00000097          	auipc	ra,0x0
    80005012:	3c8080e7          	jalr	968(ra) # 800053d6 <piperead>
    80005016:	892a                	mv	s2,a0
    80005018:	b7d5                	j	80004ffc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000501a:	02451783          	lh	a5,36(a0)
    8000501e:	03079693          	slli	a3,a5,0x30
    80005022:	92c1                	srli	a3,a3,0x30
    80005024:	4725                	li	a4,9
    80005026:	02d76863          	bltu	a4,a3,80005056 <fileread+0xba>
    8000502a:	0792                	slli	a5,a5,0x4
    8000502c:	0001d717          	auipc	a4,0x1d
    80005030:	e6c70713          	addi	a4,a4,-404 # 80021e98 <devsw>
    80005034:	97ba                	add	a5,a5,a4
    80005036:	639c                	ld	a5,0(a5)
    80005038:	c38d                	beqz	a5,8000505a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000503a:	4505                	li	a0,1
    8000503c:	9782                	jalr	a5
    8000503e:	892a                	mv	s2,a0
    80005040:	bf75                	j	80004ffc <fileread+0x60>
    panic("fileread");
    80005042:	00003517          	auipc	a0,0x3
    80005046:	79e50513          	addi	a0,a0,1950 # 800087e0 <syscalls+0x270>
    8000504a:	ffffb097          	auipc	ra,0xffffb
    8000504e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
    return -1;
    80005052:	597d                	li	s2,-1
    80005054:	b765                	j	80004ffc <fileread+0x60>
      return -1;
    80005056:	597d                	li	s2,-1
    80005058:	b755                	j	80004ffc <fileread+0x60>
    8000505a:	597d                	li	s2,-1
    8000505c:	b745                	j	80004ffc <fileread+0x60>

000000008000505e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000505e:	715d                	addi	sp,sp,-80
    80005060:	e486                	sd	ra,72(sp)
    80005062:	e0a2                	sd	s0,64(sp)
    80005064:	fc26                	sd	s1,56(sp)
    80005066:	f84a                	sd	s2,48(sp)
    80005068:	f44e                	sd	s3,40(sp)
    8000506a:	f052                	sd	s4,32(sp)
    8000506c:	ec56                	sd	s5,24(sp)
    8000506e:	e85a                	sd	s6,16(sp)
    80005070:	e45e                	sd	s7,8(sp)
    80005072:	e062                	sd	s8,0(sp)
    80005074:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005076:	00954783          	lbu	a5,9(a0)
    8000507a:	10078663          	beqz	a5,80005186 <filewrite+0x128>
    8000507e:	892a                	mv	s2,a0
    80005080:	8aae                	mv	s5,a1
    80005082:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005084:	411c                	lw	a5,0(a0)
    80005086:	4705                	li	a4,1
    80005088:	02e78263          	beq	a5,a4,800050ac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000508c:	470d                	li	a4,3
    8000508e:	02e78663          	beq	a5,a4,800050ba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005092:	4709                	li	a4,2
    80005094:	0ee79163          	bne	a5,a4,80005176 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005098:	0ac05d63          	blez	a2,80005152 <filewrite+0xf4>
    int i = 0;
    8000509c:	4981                	li	s3,0
    8000509e:	6b05                	lui	s6,0x1
    800050a0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050a4:	6b85                	lui	s7,0x1
    800050a6:	c00b8b9b          	addiw	s7,s7,-1024
    800050aa:	a861                	j	80005142 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050ac:	6908                	ld	a0,16(a0)
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	22e080e7          	jalr	558(ra) # 800052dc <pipewrite>
    800050b6:	8a2a                	mv	s4,a0
    800050b8:	a045                	j	80005158 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050ba:	02451783          	lh	a5,36(a0)
    800050be:	03079693          	slli	a3,a5,0x30
    800050c2:	92c1                	srli	a3,a3,0x30
    800050c4:	4725                	li	a4,9
    800050c6:	0cd76263          	bltu	a4,a3,8000518a <filewrite+0x12c>
    800050ca:	0792                	slli	a5,a5,0x4
    800050cc:	0001d717          	auipc	a4,0x1d
    800050d0:	dcc70713          	addi	a4,a4,-564 # 80021e98 <devsw>
    800050d4:	97ba                	add	a5,a5,a4
    800050d6:	679c                	ld	a5,8(a5)
    800050d8:	cbdd                	beqz	a5,8000518e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050da:	4505                	li	a0,1
    800050dc:	9782                	jalr	a5
    800050de:	8a2a                	mv	s4,a0
    800050e0:	a8a5                	j	80005158 <filewrite+0xfa>
    800050e2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050e6:	00000097          	auipc	ra,0x0
    800050ea:	8b0080e7          	jalr	-1872(ra) # 80004996 <begin_op>
      ilock(f->ip);
    800050ee:	01893503          	ld	a0,24(s2)
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	ed2080e7          	jalr	-302(ra) # 80003fc4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050fa:	8762                	mv	a4,s8
    800050fc:	02092683          	lw	a3,32(s2)
    80005100:	01598633          	add	a2,s3,s5
    80005104:	4585                	li	a1,1
    80005106:	01893503          	ld	a0,24(s2)
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	266080e7          	jalr	614(ra) # 80004370 <writei>
    80005112:	84aa                	mv	s1,a0
    80005114:	00a05763          	blez	a0,80005122 <filewrite+0xc4>
        f->off += r;
    80005118:	02092783          	lw	a5,32(s2)
    8000511c:	9fa9                	addw	a5,a5,a0
    8000511e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005122:	01893503          	ld	a0,24(s2)
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	f60080e7          	jalr	-160(ra) # 80004086 <iunlock>
      end_op();
    8000512e:	00000097          	auipc	ra,0x0
    80005132:	8e8080e7          	jalr	-1816(ra) # 80004a16 <end_op>

      if(r != n1){
    80005136:	009c1f63          	bne	s8,s1,80005154 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000513a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000513e:	0149db63          	bge	s3,s4,80005154 <filewrite+0xf6>
      int n1 = n - i;
    80005142:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005146:	84be                	mv	s1,a5
    80005148:	2781                	sext.w	a5,a5
    8000514a:	f8fb5ce3          	bge	s6,a5,800050e2 <filewrite+0x84>
    8000514e:	84de                	mv	s1,s7
    80005150:	bf49                	j	800050e2 <filewrite+0x84>
    int i = 0;
    80005152:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005154:	013a1f63          	bne	s4,s3,80005172 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005158:	8552                	mv	a0,s4
    8000515a:	60a6                	ld	ra,72(sp)
    8000515c:	6406                	ld	s0,64(sp)
    8000515e:	74e2                	ld	s1,56(sp)
    80005160:	7942                	ld	s2,48(sp)
    80005162:	79a2                	ld	s3,40(sp)
    80005164:	7a02                	ld	s4,32(sp)
    80005166:	6ae2                	ld	s5,24(sp)
    80005168:	6b42                	ld	s6,16(sp)
    8000516a:	6ba2                	ld	s7,8(sp)
    8000516c:	6c02                	ld	s8,0(sp)
    8000516e:	6161                	addi	sp,sp,80
    80005170:	8082                	ret
    ret = (i == n ? n : -1);
    80005172:	5a7d                	li	s4,-1
    80005174:	b7d5                	j	80005158 <filewrite+0xfa>
    panic("filewrite");
    80005176:	00003517          	auipc	a0,0x3
    8000517a:	67a50513          	addi	a0,a0,1658 # 800087f0 <syscalls+0x280>
    8000517e:	ffffb097          	auipc	ra,0xffffb
    80005182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>
    return -1;
    80005186:	5a7d                	li	s4,-1
    80005188:	bfc1                	j	80005158 <filewrite+0xfa>
      return -1;
    8000518a:	5a7d                	li	s4,-1
    8000518c:	b7f1                	j	80005158 <filewrite+0xfa>
    8000518e:	5a7d                	li	s4,-1
    80005190:	b7e1                	j	80005158 <filewrite+0xfa>

0000000080005192 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005192:	7179                	addi	sp,sp,-48
    80005194:	f406                	sd	ra,40(sp)
    80005196:	f022                	sd	s0,32(sp)
    80005198:	ec26                	sd	s1,24(sp)
    8000519a:	e84a                	sd	s2,16(sp)
    8000519c:	e44e                	sd	s3,8(sp)
    8000519e:	e052                	sd	s4,0(sp)
    800051a0:	1800                	addi	s0,sp,48
    800051a2:	84aa                	mv	s1,a0
    800051a4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051a6:	0005b023          	sd	zero,0(a1)
    800051aa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	bf8080e7          	jalr	-1032(ra) # 80004da6 <filealloc>
    800051b6:	e088                	sd	a0,0(s1)
    800051b8:	c551                	beqz	a0,80005244 <pipealloc+0xb2>
    800051ba:	00000097          	auipc	ra,0x0
    800051be:	bec080e7          	jalr	-1044(ra) # 80004da6 <filealloc>
    800051c2:	00aa3023          	sd	a0,0(s4)
    800051c6:	c92d                	beqz	a0,80005238 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	92c080e7          	jalr	-1748(ra) # 80000af4 <kalloc>
    800051d0:	892a                	mv	s2,a0
    800051d2:	c125                	beqz	a0,80005232 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800051d4:	4985                	li	s3,1
    800051d6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051da:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051e6:	00003597          	auipc	a1,0x3
    800051ea:	61a58593          	addi	a1,a1,1562 # 80008800 <syscalls+0x290>
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	966080e7          	jalr	-1690(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800051f6:	609c                	ld	a5,0(s1)
    800051f8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051fc:	609c                	ld	a5,0(s1)
    800051fe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005202:	609c                	ld	a5,0(s1)
    80005204:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005208:	609c                	ld	a5,0(s1)
    8000520a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000520e:	000a3783          	ld	a5,0(s4)
    80005212:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005216:	000a3783          	ld	a5,0(s4)
    8000521a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000521e:	000a3783          	ld	a5,0(s4)
    80005222:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005226:	000a3783          	ld	a5,0(s4)
    8000522a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000522e:	4501                	li	a0,0
    80005230:	a025                	j	80005258 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005232:	6088                	ld	a0,0(s1)
    80005234:	e501                	bnez	a0,8000523c <pipealloc+0xaa>
    80005236:	a039                	j	80005244 <pipealloc+0xb2>
    80005238:	6088                	ld	a0,0(s1)
    8000523a:	c51d                	beqz	a0,80005268 <pipealloc+0xd6>
    fileclose(*f0);
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	c26080e7          	jalr	-986(ra) # 80004e62 <fileclose>
  if(*f1)
    80005244:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005248:	557d                	li	a0,-1
  if(*f1)
    8000524a:	c799                	beqz	a5,80005258 <pipealloc+0xc6>
    fileclose(*f1);
    8000524c:	853e                	mv	a0,a5
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	c14080e7          	jalr	-1004(ra) # 80004e62 <fileclose>
  return -1;
    80005256:	557d                	li	a0,-1
}
    80005258:	70a2                	ld	ra,40(sp)
    8000525a:	7402                	ld	s0,32(sp)
    8000525c:	64e2                	ld	s1,24(sp)
    8000525e:	6942                	ld	s2,16(sp)
    80005260:	69a2                	ld	s3,8(sp)
    80005262:	6a02                	ld	s4,0(sp)
    80005264:	6145                	addi	sp,sp,48
    80005266:	8082                	ret
  return -1;
    80005268:	557d                	li	a0,-1
    8000526a:	b7fd                	j	80005258 <pipealloc+0xc6>

000000008000526c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000526c:	1101                	addi	sp,sp,-32
    8000526e:	ec06                	sd	ra,24(sp)
    80005270:	e822                	sd	s0,16(sp)
    80005272:	e426                	sd	s1,8(sp)
    80005274:	e04a                	sd	s2,0(sp)
    80005276:	1000                	addi	s0,sp,32
    80005278:	84aa                	mv	s1,a0
    8000527a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	968080e7          	jalr	-1688(ra) # 80000be4 <acquire>
  if(writable){
    80005284:	02090d63          	beqz	s2,800052be <pipeclose+0x52>
    pi->writeopen = 0;
    80005288:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000528c:	21848513          	addi	a0,s1,536
    80005290:	ffffe097          	auipc	ra,0xffffe
    80005294:	83e080e7          	jalr	-1986(ra) # 80002ace <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005298:	2204b783          	ld	a5,544(s1)
    8000529c:	eb95                	bnez	a5,800052d0 <pipeclose+0x64>
    release(&pi->lock);
    8000529e:	8526                	mv	a0,s1
    800052a0:	ffffc097          	auipc	ra,0xffffc
    800052a4:	9f8080e7          	jalr	-1544(ra) # 80000c98 <release>
    kfree((char*)pi);
    800052a8:	8526                	mv	a0,s1
    800052aa:	ffffb097          	auipc	ra,0xffffb
    800052ae:	74e080e7          	jalr	1870(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800052b2:	60e2                	ld	ra,24(sp)
    800052b4:	6442                	ld	s0,16(sp)
    800052b6:	64a2                	ld	s1,8(sp)
    800052b8:	6902                	ld	s2,0(sp)
    800052ba:	6105                	addi	sp,sp,32
    800052bc:	8082                	ret
    pi->readopen = 0;
    800052be:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052c2:	21c48513          	addi	a0,s1,540
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	808080e7          	jalr	-2040(ra) # 80002ace <wakeup>
    800052ce:	b7e9                	j	80005298 <pipeclose+0x2c>
    release(&pi->lock);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
}
    800052da:	bfe1                	j	800052b2 <pipeclose+0x46>

00000000800052dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052dc:	7159                	addi	sp,sp,-112
    800052de:	f486                	sd	ra,104(sp)
    800052e0:	f0a2                	sd	s0,96(sp)
    800052e2:	eca6                	sd	s1,88(sp)
    800052e4:	e8ca                	sd	s2,80(sp)
    800052e6:	e4ce                	sd	s3,72(sp)
    800052e8:	e0d2                	sd	s4,64(sp)
    800052ea:	fc56                	sd	s5,56(sp)
    800052ec:	f85a                	sd	s6,48(sp)
    800052ee:	f45e                	sd	s7,40(sp)
    800052f0:	f062                	sd	s8,32(sp)
    800052f2:	ec66                	sd	s9,24(sp)
    800052f4:	1880                	addi	s0,sp,112
    800052f6:	84aa                	mv	s1,a0
    800052f8:	8aae                	mv	s5,a1
    800052fa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052fc:	ffffd097          	auipc	ra,0xffffd
    80005300:	bd0080e7          	jalr	-1072(ra) # 80001ecc <myproc>
    80005304:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005306:	8526                	mv	a0,s1
    80005308:	ffffc097          	auipc	ra,0xffffc
    8000530c:	8dc080e7          	jalr	-1828(ra) # 80000be4 <acquire>
  while(i < n){
    80005310:	0d405163          	blez	s4,800053d2 <pipewrite+0xf6>
    80005314:	8ba6                	mv	s7,s1
  int i = 0;
    80005316:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005318:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000531a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000531e:	21c48c13          	addi	s8,s1,540
    80005322:	a08d                	j	80005384 <pipewrite+0xa8>
      release(&pi->lock);
    80005324:	8526                	mv	a0,s1
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	972080e7          	jalr	-1678(ra) # 80000c98 <release>
      return -1;
    8000532e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005330:	854a                	mv	a0,s2
    80005332:	70a6                	ld	ra,104(sp)
    80005334:	7406                	ld	s0,96(sp)
    80005336:	64e6                	ld	s1,88(sp)
    80005338:	6946                	ld	s2,80(sp)
    8000533a:	69a6                	ld	s3,72(sp)
    8000533c:	6a06                	ld	s4,64(sp)
    8000533e:	7ae2                	ld	s5,56(sp)
    80005340:	7b42                	ld	s6,48(sp)
    80005342:	7ba2                	ld	s7,40(sp)
    80005344:	7c02                	ld	s8,32(sp)
    80005346:	6ce2                	ld	s9,24(sp)
    80005348:	6165                	addi	sp,sp,112
    8000534a:	8082                	ret
      wakeup(&pi->nread);
    8000534c:	8566                	mv	a0,s9
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	780080e7          	jalr	1920(ra) # 80002ace <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005356:	85de                	mv	a1,s7
    80005358:	8562                	mv	a0,s8
    8000535a:	ffffd097          	auipc	ra,0xffffd
    8000535e:	148080e7          	jalr	328(ra) # 800024a2 <sleep>
    80005362:	a839                	j	80005380 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005364:	21c4a783          	lw	a5,540(s1)
    80005368:	0017871b          	addiw	a4,a5,1
    8000536c:	20e4ae23          	sw	a4,540(s1)
    80005370:	1ff7f793          	andi	a5,a5,511
    80005374:	97a6                	add	a5,a5,s1
    80005376:	f9f44703          	lbu	a4,-97(s0)
    8000537a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000537e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005380:	03495d63          	bge	s2,s4,800053ba <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005384:	2204a783          	lw	a5,544(s1)
    80005388:	dfd1                	beqz	a5,80005324 <pipewrite+0x48>
    8000538a:	0289a783          	lw	a5,40(s3)
    8000538e:	fbd9                	bnez	a5,80005324 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005390:	2184a783          	lw	a5,536(s1)
    80005394:	21c4a703          	lw	a4,540(s1)
    80005398:	2007879b          	addiw	a5,a5,512
    8000539c:	faf708e3          	beq	a4,a5,8000534c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053a0:	4685                	li	a3,1
    800053a2:	01590633          	add	a2,s2,s5
    800053a6:	f9f40593          	addi	a1,s0,-97
    800053aa:	0509b503          	ld	a0,80(s3)
    800053ae:	ffffc097          	auipc	ra,0xffffc
    800053b2:	350080e7          	jalr	848(ra) # 800016fe <copyin>
    800053b6:	fb6517e3          	bne	a0,s6,80005364 <pipewrite+0x88>
  wakeup(&pi->nread);
    800053ba:	21848513          	addi	a0,s1,536
    800053be:	ffffd097          	auipc	ra,0xffffd
    800053c2:	710080e7          	jalr	1808(ra) # 80002ace <wakeup>
  release(&pi->lock);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>
  return i;
    800053d0:	b785                	j	80005330 <pipewrite+0x54>
  int i = 0;
    800053d2:	4901                	li	s2,0
    800053d4:	b7dd                	j	800053ba <pipewrite+0xde>

00000000800053d6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053d6:	715d                	addi	sp,sp,-80
    800053d8:	e486                	sd	ra,72(sp)
    800053da:	e0a2                	sd	s0,64(sp)
    800053dc:	fc26                	sd	s1,56(sp)
    800053de:	f84a                	sd	s2,48(sp)
    800053e0:	f44e                	sd	s3,40(sp)
    800053e2:	f052                	sd	s4,32(sp)
    800053e4:	ec56                	sd	s5,24(sp)
    800053e6:	e85a                	sd	s6,16(sp)
    800053e8:	0880                	addi	s0,sp,80
    800053ea:	84aa                	mv	s1,a0
    800053ec:	892e                	mv	s2,a1
    800053ee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800053f0:	ffffd097          	auipc	ra,0xffffd
    800053f4:	adc080e7          	jalr	-1316(ra) # 80001ecc <myproc>
    800053f8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053fa:	8b26                	mv	s6,s1
    800053fc:	8526                	mv	a0,s1
    800053fe:	ffffb097          	auipc	ra,0xffffb
    80005402:	7e6080e7          	jalr	2022(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005406:	2184a703          	lw	a4,536(s1)
    8000540a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000540e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005412:	02f71463          	bne	a4,a5,8000543a <piperead+0x64>
    80005416:	2244a783          	lw	a5,548(s1)
    8000541a:	c385                	beqz	a5,8000543a <piperead+0x64>
    if(pr->killed){
    8000541c:	028a2783          	lw	a5,40(s4)
    80005420:	ebc1                	bnez	a5,800054b0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005422:	85da                	mv	a1,s6
    80005424:	854e                	mv	a0,s3
    80005426:	ffffd097          	auipc	ra,0xffffd
    8000542a:	07c080e7          	jalr	124(ra) # 800024a2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000542e:	2184a703          	lw	a4,536(s1)
    80005432:	21c4a783          	lw	a5,540(s1)
    80005436:	fef700e3          	beq	a4,a5,80005416 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000543a:	09505263          	blez	s5,800054be <piperead+0xe8>
    8000543e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005440:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005442:	2184a783          	lw	a5,536(s1)
    80005446:	21c4a703          	lw	a4,540(s1)
    8000544a:	02f70d63          	beq	a4,a5,80005484 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000544e:	0017871b          	addiw	a4,a5,1
    80005452:	20e4ac23          	sw	a4,536(s1)
    80005456:	1ff7f793          	andi	a5,a5,511
    8000545a:	97a6                	add	a5,a5,s1
    8000545c:	0187c783          	lbu	a5,24(a5)
    80005460:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005464:	4685                	li	a3,1
    80005466:	fbf40613          	addi	a2,s0,-65
    8000546a:	85ca                	mv	a1,s2
    8000546c:	050a3503          	ld	a0,80(s4)
    80005470:	ffffc097          	auipc	ra,0xffffc
    80005474:	202080e7          	jalr	514(ra) # 80001672 <copyout>
    80005478:	01650663          	beq	a0,s6,80005484 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000547c:	2985                	addiw	s3,s3,1
    8000547e:	0905                	addi	s2,s2,1
    80005480:	fd3a91e3          	bne	s5,s3,80005442 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005484:	21c48513          	addi	a0,s1,540
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	646080e7          	jalr	1606(ra) # 80002ace <wakeup>
  release(&pi->lock);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffc097          	auipc	ra,0xffffc
    80005496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
  return i;
}
    8000549a:	854e                	mv	a0,s3
    8000549c:	60a6                	ld	ra,72(sp)
    8000549e:	6406                	ld	s0,64(sp)
    800054a0:	74e2                	ld	s1,56(sp)
    800054a2:	7942                	ld	s2,48(sp)
    800054a4:	79a2                	ld	s3,40(sp)
    800054a6:	7a02                	ld	s4,32(sp)
    800054a8:	6ae2                	ld	s5,24(sp)
    800054aa:	6b42                	ld	s6,16(sp)
    800054ac:	6161                	addi	sp,sp,80
    800054ae:	8082                	ret
      release(&pi->lock);
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffb097          	auipc	ra,0xffffb
    800054b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
      return -1;
    800054ba:	59fd                	li	s3,-1
    800054bc:	bff9                	j	8000549a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054be:	4981                	li	s3,0
    800054c0:	b7d1                	j	80005484 <piperead+0xae>

00000000800054c2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800054c2:	df010113          	addi	sp,sp,-528
    800054c6:	20113423          	sd	ra,520(sp)
    800054ca:	20813023          	sd	s0,512(sp)
    800054ce:	ffa6                	sd	s1,504(sp)
    800054d0:	fbca                	sd	s2,496(sp)
    800054d2:	f7ce                	sd	s3,488(sp)
    800054d4:	f3d2                	sd	s4,480(sp)
    800054d6:	efd6                	sd	s5,472(sp)
    800054d8:	ebda                	sd	s6,464(sp)
    800054da:	e7de                	sd	s7,456(sp)
    800054dc:	e3e2                	sd	s8,448(sp)
    800054de:	ff66                	sd	s9,440(sp)
    800054e0:	fb6a                	sd	s10,432(sp)
    800054e2:	f76e                	sd	s11,424(sp)
    800054e4:	0c00                	addi	s0,sp,528
    800054e6:	84aa                	mv	s1,a0
    800054e8:	dea43c23          	sd	a0,-520(s0)
    800054ec:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054f0:	ffffd097          	auipc	ra,0xffffd
    800054f4:	9dc080e7          	jalr	-1572(ra) # 80001ecc <myproc>
    800054f8:	892a                	mv	s2,a0

  begin_op();
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	49c080e7          	jalr	1180(ra) # 80004996 <begin_op>

  if((ip = namei(path)) == 0){
    80005502:	8526                	mv	a0,s1
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	276080e7          	jalr	630(ra) # 8000477a <namei>
    8000550c:	c92d                	beqz	a0,8000557e <exec+0xbc>
    8000550e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	ab4080e7          	jalr	-1356(ra) # 80003fc4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005518:	04000713          	li	a4,64
    8000551c:	4681                	li	a3,0
    8000551e:	e5040613          	addi	a2,s0,-432
    80005522:	4581                	li	a1,0
    80005524:	8526                	mv	a0,s1
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	d52080e7          	jalr	-686(ra) # 80004278 <readi>
    8000552e:	04000793          	li	a5,64
    80005532:	00f51a63          	bne	a0,a5,80005546 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005536:	e5042703          	lw	a4,-432(s0)
    8000553a:	464c47b7          	lui	a5,0x464c4
    8000553e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005542:	04f70463          	beq	a4,a5,8000558a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	cde080e7          	jalr	-802(ra) # 80004226 <iunlockput>
    end_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	4c6080e7          	jalr	1222(ra) # 80004a16 <end_op>
  }
  return -1;
    80005558:	557d                	li	a0,-1
}
    8000555a:	20813083          	ld	ra,520(sp)
    8000555e:	20013403          	ld	s0,512(sp)
    80005562:	74fe                	ld	s1,504(sp)
    80005564:	795e                	ld	s2,496(sp)
    80005566:	79be                	ld	s3,488(sp)
    80005568:	7a1e                	ld	s4,480(sp)
    8000556a:	6afe                	ld	s5,472(sp)
    8000556c:	6b5e                	ld	s6,464(sp)
    8000556e:	6bbe                	ld	s7,456(sp)
    80005570:	6c1e                	ld	s8,448(sp)
    80005572:	7cfa                	ld	s9,440(sp)
    80005574:	7d5a                	ld	s10,432(sp)
    80005576:	7dba                	ld	s11,424(sp)
    80005578:	21010113          	addi	sp,sp,528
    8000557c:	8082                	ret
    end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	498080e7          	jalr	1176(ra) # 80004a16 <end_op>
    return -1;
    80005586:	557d                	li	a0,-1
    80005588:	bfc9                	j	8000555a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffd097          	auipc	ra,0xffffd
    80005590:	9fe080e7          	jalr	-1538(ra) # 80001f8a <proc_pagetable>
    80005594:	8baa                	mv	s7,a0
    80005596:	d945                	beqz	a0,80005546 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005598:	e7042983          	lw	s3,-400(s0)
    8000559c:	e8845783          	lhu	a5,-376(s0)
    800055a0:	c7ad                	beqz	a5,8000560a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800055a2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800055a6:	6c85                	lui	s9,0x1
    800055a8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800055ac:	def43823          	sd	a5,-528(s0)
    800055b0:	a42d                	j	800057da <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055b2:	00003517          	auipc	a0,0x3
    800055b6:	25650513          	addi	a0,a0,598 # 80008808 <syscalls+0x298>
    800055ba:	ffffb097          	auipc	ra,0xffffb
    800055be:	f84080e7          	jalr	-124(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055c2:	8756                	mv	a4,s5
    800055c4:	012d86bb          	addw	a3,s11,s2
    800055c8:	4581                	li	a1,0
    800055ca:	8526                	mv	a0,s1
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	cac080e7          	jalr	-852(ra) # 80004278 <readi>
    800055d4:	2501                	sext.w	a0,a0
    800055d6:	1aaa9963          	bne	s5,a0,80005788 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800055da:	6785                	lui	a5,0x1
    800055dc:	0127893b          	addw	s2,a5,s2
    800055e0:	77fd                	lui	a5,0xfffff
    800055e2:	01478a3b          	addw	s4,a5,s4
    800055e6:	1f897163          	bgeu	s2,s8,800057c8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800055ea:	02091593          	slli	a1,s2,0x20
    800055ee:	9181                	srli	a1,a1,0x20
    800055f0:	95ea                	add	a1,a1,s10
    800055f2:	855e                	mv	a0,s7
    800055f4:	ffffc097          	auipc	ra,0xffffc
    800055f8:	a7a080e7          	jalr	-1414(ra) # 8000106e <walkaddr>
    800055fc:	862a                	mv	a2,a0
    if(pa == 0)
    800055fe:	d955                	beqz	a0,800055b2 <exec+0xf0>
      n = PGSIZE;
    80005600:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005602:	fd9a70e3          	bgeu	s4,s9,800055c2 <exec+0x100>
      n = sz - i;
    80005606:	8ad2                	mv	s5,s4
    80005608:	bf6d                	j	800055c2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000560a:	4901                	li	s2,0
  iunlockput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	c18080e7          	jalr	-1000(ra) # 80004226 <iunlockput>
  end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	400080e7          	jalr	1024(ra) # 80004a16 <end_op>
  p = myproc();
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	8ae080e7          	jalr	-1874(ra) # 80001ecc <myproc>
    80005626:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005628:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000562c:	6785                	lui	a5,0x1
    8000562e:	17fd                	addi	a5,a5,-1
    80005630:	993e                	add	s2,s2,a5
    80005632:	757d                	lui	a0,0xfffff
    80005634:	00a977b3          	and	a5,s2,a0
    80005638:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000563c:	6609                	lui	a2,0x2
    8000563e:	963e                	add	a2,a2,a5
    80005640:	85be                	mv	a1,a5
    80005642:	855e                	mv	a0,s7
    80005644:	ffffc097          	auipc	ra,0xffffc
    80005648:	dde080e7          	jalr	-546(ra) # 80001422 <uvmalloc>
    8000564c:	8b2a                	mv	s6,a0
  ip = 0;
    8000564e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005650:	12050c63          	beqz	a0,80005788 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005654:	75f9                	lui	a1,0xffffe
    80005656:	95aa                	add	a1,a1,a0
    80005658:	855e                	mv	a0,s7
    8000565a:	ffffc097          	auipc	ra,0xffffc
    8000565e:	fe6080e7          	jalr	-26(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005662:	7c7d                	lui	s8,0xfffff
    80005664:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005666:	e0043783          	ld	a5,-512(s0)
    8000566a:	6388                	ld	a0,0(a5)
    8000566c:	c535                	beqz	a0,800056d8 <exec+0x216>
    8000566e:	e9040993          	addi	s3,s0,-368
    80005672:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005676:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	7ec080e7          	jalr	2028(ra) # 80000e64 <strlen>
    80005680:	2505                	addiw	a0,a0,1
    80005682:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005686:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000568a:	13896363          	bltu	s2,s8,800057b0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000568e:	e0043d83          	ld	s11,-512(s0)
    80005692:	000dba03          	ld	s4,0(s11)
    80005696:	8552                	mv	a0,s4
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	7cc080e7          	jalr	1996(ra) # 80000e64 <strlen>
    800056a0:	0015069b          	addiw	a3,a0,1
    800056a4:	8652                	mv	a2,s4
    800056a6:	85ca                	mv	a1,s2
    800056a8:	855e                	mv	a0,s7
    800056aa:	ffffc097          	auipc	ra,0xffffc
    800056ae:	fc8080e7          	jalr	-56(ra) # 80001672 <copyout>
    800056b2:	10054363          	bltz	a0,800057b8 <exec+0x2f6>
    ustack[argc] = sp;
    800056b6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056ba:	0485                	addi	s1,s1,1
    800056bc:	008d8793          	addi	a5,s11,8
    800056c0:	e0f43023          	sd	a5,-512(s0)
    800056c4:	008db503          	ld	a0,8(s11)
    800056c8:	c911                	beqz	a0,800056dc <exec+0x21a>
    if(argc >= MAXARG)
    800056ca:	09a1                	addi	s3,s3,8
    800056cc:	fb3c96e3          	bne	s9,s3,80005678 <exec+0x1b6>
  sz = sz1;
    800056d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d4:	4481                	li	s1,0
    800056d6:	a84d                	j	80005788 <exec+0x2c6>
  sp = sz;
    800056d8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800056da:	4481                	li	s1,0
  ustack[argc] = 0;
    800056dc:	00349793          	slli	a5,s1,0x3
    800056e0:	f9040713          	addi	a4,s0,-112
    800056e4:	97ba                	add	a5,a5,a4
    800056e6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800056ea:	00148693          	addi	a3,s1,1
    800056ee:	068e                	slli	a3,a3,0x3
    800056f0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800056f4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800056f8:	01897663          	bgeu	s2,s8,80005704 <exec+0x242>
  sz = sz1;
    800056fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005700:	4481                	li	s1,0
    80005702:	a059                	j	80005788 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005704:	e9040613          	addi	a2,s0,-368
    80005708:	85ca                	mv	a1,s2
    8000570a:	855e                	mv	a0,s7
    8000570c:	ffffc097          	auipc	ra,0xffffc
    80005710:	f66080e7          	jalr	-154(ra) # 80001672 <copyout>
    80005714:	0a054663          	bltz	a0,800057c0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005718:	058ab783          	ld	a5,88(s5)
    8000571c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005720:	df843783          	ld	a5,-520(s0)
    80005724:	0007c703          	lbu	a4,0(a5)
    80005728:	cf11                	beqz	a4,80005744 <exec+0x282>
    8000572a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000572c:	02f00693          	li	a3,47
    80005730:	a039                	j	8000573e <exec+0x27c>
      last = s+1;
    80005732:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005736:	0785                	addi	a5,a5,1
    80005738:	fff7c703          	lbu	a4,-1(a5)
    8000573c:	c701                	beqz	a4,80005744 <exec+0x282>
    if(*s == '/')
    8000573e:	fed71ce3          	bne	a4,a3,80005736 <exec+0x274>
    80005742:	bfc5                	j	80005732 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005744:	4641                	li	a2,16
    80005746:	df843583          	ld	a1,-520(s0)
    8000574a:	158a8513          	addi	a0,s5,344
    8000574e:	ffffb097          	auipc	ra,0xffffb
    80005752:	6e4080e7          	jalr	1764(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005756:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000575a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000575e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005762:	058ab783          	ld	a5,88(s5)
    80005766:	e6843703          	ld	a4,-408(s0)
    8000576a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000576c:	058ab783          	ld	a5,88(s5)
    80005770:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005774:	85ea                	mv	a1,s10
    80005776:	ffffd097          	auipc	ra,0xffffd
    8000577a:	8b0080e7          	jalr	-1872(ra) # 80002026 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000577e:	0004851b          	sext.w	a0,s1
    80005782:	bbe1                	j	8000555a <exec+0x98>
    80005784:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005788:	e0843583          	ld	a1,-504(s0)
    8000578c:	855e                	mv	a0,s7
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	898080e7          	jalr	-1896(ra) # 80002026 <proc_freepagetable>
  if(ip){
    80005796:	da0498e3          	bnez	s1,80005546 <exec+0x84>
  return -1;
    8000579a:	557d                	li	a0,-1
    8000579c:	bb7d                	j	8000555a <exec+0x98>
    8000579e:	e1243423          	sd	s2,-504(s0)
    800057a2:	b7dd                	j	80005788 <exec+0x2c6>
    800057a4:	e1243423          	sd	s2,-504(s0)
    800057a8:	b7c5                	j	80005788 <exec+0x2c6>
    800057aa:	e1243423          	sd	s2,-504(s0)
    800057ae:	bfe9                	j	80005788 <exec+0x2c6>
  sz = sz1;
    800057b0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057b4:	4481                	li	s1,0
    800057b6:	bfc9                	j	80005788 <exec+0x2c6>
  sz = sz1;
    800057b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057bc:	4481                	li	s1,0
    800057be:	b7e9                	j	80005788 <exec+0x2c6>
  sz = sz1;
    800057c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057c4:	4481                	li	s1,0
    800057c6:	b7c9                	j	80005788 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057c8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057cc:	2b05                	addiw	s6,s6,1
    800057ce:	0389899b          	addiw	s3,s3,56
    800057d2:	e8845783          	lhu	a5,-376(s0)
    800057d6:	e2fb5be3          	bge	s6,a5,8000560c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057da:	2981                	sext.w	s3,s3
    800057dc:	03800713          	li	a4,56
    800057e0:	86ce                	mv	a3,s3
    800057e2:	e1840613          	addi	a2,s0,-488
    800057e6:	4581                	li	a1,0
    800057e8:	8526                	mv	a0,s1
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	a8e080e7          	jalr	-1394(ra) # 80004278 <readi>
    800057f2:	03800793          	li	a5,56
    800057f6:	f8f517e3          	bne	a0,a5,80005784 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800057fa:	e1842783          	lw	a5,-488(s0)
    800057fe:	4705                	li	a4,1
    80005800:	fce796e3          	bne	a5,a4,800057cc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005804:	e4043603          	ld	a2,-448(s0)
    80005808:	e3843783          	ld	a5,-456(s0)
    8000580c:	f8f669e3          	bltu	a2,a5,8000579e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005810:	e2843783          	ld	a5,-472(s0)
    80005814:	963e                	add	a2,a2,a5
    80005816:	f8f667e3          	bltu	a2,a5,800057a4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000581a:	85ca                	mv	a1,s2
    8000581c:	855e                	mv	a0,s7
    8000581e:	ffffc097          	auipc	ra,0xffffc
    80005822:	c04080e7          	jalr	-1020(ra) # 80001422 <uvmalloc>
    80005826:	e0a43423          	sd	a0,-504(s0)
    8000582a:	d141                	beqz	a0,800057aa <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000582c:	e2843d03          	ld	s10,-472(s0)
    80005830:	df043783          	ld	a5,-528(s0)
    80005834:	00fd77b3          	and	a5,s10,a5
    80005838:	fba1                	bnez	a5,80005788 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000583a:	e2042d83          	lw	s11,-480(s0)
    8000583e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005842:	f80c03e3          	beqz	s8,800057c8 <exec+0x306>
    80005846:	8a62                	mv	s4,s8
    80005848:	4901                	li	s2,0
    8000584a:	b345                	j	800055ea <exec+0x128>

000000008000584c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000584c:	7179                	addi	sp,sp,-48
    8000584e:	f406                	sd	ra,40(sp)
    80005850:	f022                	sd	s0,32(sp)
    80005852:	ec26                	sd	s1,24(sp)
    80005854:	e84a                	sd	s2,16(sp)
    80005856:	1800                	addi	s0,sp,48
    80005858:	892e                	mv	s2,a1
    8000585a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000585c:	fdc40593          	addi	a1,s0,-36
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	b76080e7          	jalr	-1162(ra) # 800033d6 <argint>
    80005868:	04054063          	bltz	a0,800058a8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000586c:	fdc42703          	lw	a4,-36(s0)
    80005870:	47bd                	li	a5,15
    80005872:	02e7ed63          	bltu	a5,a4,800058ac <argfd+0x60>
    80005876:	ffffc097          	auipc	ra,0xffffc
    8000587a:	656080e7          	jalr	1622(ra) # 80001ecc <myproc>
    8000587e:	fdc42703          	lw	a4,-36(s0)
    80005882:	01a70793          	addi	a5,a4,26
    80005886:	078e                	slli	a5,a5,0x3
    80005888:	953e                	add	a0,a0,a5
    8000588a:	611c                	ld	a5,0(a0)
    8000588c:	c395                	beqz	a5,800058b0 <argfd+0x64>
    return -1;
  if(pfd)
    8000588e:	00090463          	beqz	s2,80005896 <argfd+0x4a>
    *pfd = fd;
    80005892:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005896:	4501                	li	a0,0
  if(pf)
    80005898:	c091                	beqz	s1,8000589c <argfd+0x50>
    *pf = f;
    8000589a:	e09c                	sd	a5,0(s1)
}
    8000589c:	70a2                	ld	ra,40(sp)
    8000589e:	7402                	ld	s0,32(sp)
    800058a0:	64e2                	ld	s1,24(sp)
    800058a2:	6942                	ld	s2,16(sp)
    800058a4:	6145                	addi	sp,sp,48
    800058a6:	8082                	ret
    return -1;
    800058a8:	557d                	li	a0,-1
    800058aa:	bfcd                	j	8000589c <argfd+0x50>
    return -1;
    800058ac:	557d                	li	a0,-1
    800058ae:	b7fd                	j	8000589c <argfd+0x50>
    800058b0:	557d                	li	a0,-1
    800058b2:	b7ed                	j	8000589c <argfd+0x50>

00000000800058b4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058b4:	1101                	addi	sp,sp,-32
    800058b6:	ec06                	sd	ra,24(sp)
    800058b8:	e822                	sd	s0,16(sp)
    800058ba:	e426                	sd	s1,8(sp)
    800058bc:	1000                	addi	s0,sp,32
    800058be:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058c0:	ffffc097          	auipc	ra,0xffffc
    800058c4:	60c080e7          	jalr	1548(ra) # 80001ecc <myproc>
    800058c8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058ca:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800058ce:	4501                	li	a0,0
    800058d0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058d2:	6398                	ld	a4,0(a5)
    800058d4:	cb19                	beqz	a4,800058ea <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058d6:	2505                	addiw	a0,a0,1
    800058d8:	07a1                	addi	a5,a5,8
    800058da:	fed51ce3          	bne	a0,a3,800058d2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058de:	557d                	li	a0,-1
}
    800058e0:	60e2                	ld	ra,24(sp)
    800058e2:	6442                	ld	s0,16(sp)
    800058e4:	64a2                	ld	s1,8(sp)
    800058e6:	6105                	addi	sp,sp,32
    800058e8:	8082                	ret
      p->ofile[fd] = f;
    800058ea:	01a50793          	addi	a5,a0,26
    800058ee:	078e                	slli	a5,a5,0x3
    800058f0:	963e                	add	a2,a2,a5
    800058f2:	e204                	sd	s1,0(a2)
      return fd;
    800058f4:	b7f5                	j	800058e0 <fdalloc+0x2c>

00000000800058f6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058f6:	715d                	addi	sp,sp,-80
    800058f8:	e486                	sd	ra,72(sp)
    800058fa:	e0a2                	sd	s0,64(sp)
    800058fc:	fc26                	sd	s1,56(sp)
    800058fe:	f84a                	sd	s2,48(sp)
    80005900:	f44e                	sd	s3,40(sp)
    80005902:	f052                	sd	s4,32(sp)
    80005904:	ec56                	sd	s5,24(sp)
    80005906:	0880                	addi	s0,sp,80
    80005908:	89ae                	mv	s3,a1
    8000590a:	8ab2                	mv	s5,a2
    8000590c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000590e:	fb040593          	addi	a1,s0,-80
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	e86080e7          	jalr	-378(ra) # 80004798 <nameiparent>
    8000591a:	892a                	mv	s2,a0
    8000591c:	12050f63          	beqz	a0,80005a5a <create+0x164>
    return 0;

  ilock(dp);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	6a4080e7          	jalr	1700(ra) # 80003fc4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005928:	4601                	li	a2,0
    8000592a:	fb040593          	addi	a1,s0,-80
    8000592e:	854a                	mv	a0,s2
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	b78080e7          	jalr	-1160(ra) # 800044a8 <dirlookup>
    80005938:	84aa                	mv	s1,a0
    8000593a:	c921                	beqz	a0,8000598a <create+0x94>
    iunlockput(dp);
    8000593c:	854a                	mv	a0,s2
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	8e8080e7          	jalr	-1816(ra) # 80004226 <iunlockput>
    ilock(ip);
    80005946:	8526                	mv	a0,s1
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	67c080e7          	jalr	1660(ra) # 80003fc4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005950:	2981                	sext.w	s3,s3
    80005952:	4789                	li	a5,2
    80005954:	02f99463          	bne	s3,a5,8000597c <create+0x86>
    80005958:	0444d783          	lhu	a5,68(s1)
    8000595c:	37f9                	addiw	a5,a5,-2
    8000595e:	17c2                	slli	a5,a5,0x30
    80005960:	93c1                	srli	a5,a5,0x30
    80005962:	4705                	li	a4,1
    80005964:	00f76c63          	bltu	a4,a5,8000597c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005968:	8526                	mv	a0,s1
    8000596a:	60a6                	ld	ra,72(sp)
    8000596c:	6406                	ld	s0,64(sp)
    8000596e:	74e2                	ld	s1,56(sp)
    80005970:	7942                	ld	s2,48(sp)
    80005972:	79a2                	ld	s3,40(sp)
    80005974:	7a02                	ld	s4,32(sp)
    80005976:	6ae2                	ld	s5,24(sp)
    80005978:	6161                	addi	sp,sp,80
    8000597a:	8082                	ret
    iunlockput(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	8a8080e7          	jalr	-1880(ra) # 80004226 <iunlockput>
    return 0;
    80005986:	4481                	li	s1,0
    80005988:	b7c5                	j	80005968 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000598a:	85ce                	mv	a1,s3
    8000598c:	00092503          	lw	a0,0(s2)
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	49c080e7          	jalr	1180(ra) # 80003e2c <ialloc>
    80005998:	84aa                	mv	s1,a0
    8000599a:	c529                	beqz	a0,800059e4 <create+0xee>
  ilock(ip);
    8000599c:	ffffe097          	auipc	ra,0xffffe
    800059a0:	628080e7          	jalr	1576(ra) # 80003fc4 <ilock>
  ip->major = major;
    800059a4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800059a8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800059ac:	4785                	li	a5,1
    800059ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	546080e7          	jalr	1350(ra) # 80003efa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059bc:	2981                	sext.w	s3,s3
    800059be:	4785                	li	a5,1
    800059c0:	02f98a63          	beq	s3,a5,800059f4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059c4:	40d0                	lw	a2,4(s1)
    800059c6:	fb040593          	addi	a1,s0,-80
    800059ca:	854a                	mv	a0,s2
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	cec080e7          	jalr	-788(ra) # 800046b8 <dirlink>
    800059d4:	06054b63          	bltz	a0,80005a4a <create+0x154>
  iunlockput(dp);
    800059d8:	854a                	mv	a0,s2
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	84c080e7          	jalr	-1972(ra) # 80004226 <iunlockput>
  return ip;
    800059e2:	b759                	j	80005968 <create+0x72>
    panic("create: ialloc");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	e4450513          	addi	a0,a0,-444 # 80008828 <syscalls+0x2b8>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800059f4:	04a95783          	lhu	a5,74(s2)
    800059f8:	2785                	addiw	a5,a5,1
    800059fa:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	4fa080e7          	jalr	1274(ra) # 80003efa <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a08:	40d0                	lw	a2,4(s1)
    80005a0a:	00003597          	auipc	a1,0x3
    80005a0e:	e2e58593          	addi	a1,a1,-466 # 80008838 <syscalls+0x2c8>
    80005a12:	8526                	mv	a0,s1
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	ca4080e7          	jalr	-860(ra) # 800046b8 <dirlink>
    80005a1c:	00054f63          	bltz	a0,80005a3a <create+0x144>
    80005a20:	00492603          	lw	a2,4(s2)
    80005a24:	00003597          	auipc	a1,0x3
    80005a28:	e1c58593          	addi	a1,a1,-484 # 80008840 <syscalls+0x2d0>
    80005a2c:	8526                	mv	a0,s1
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	c8a080e7          	jalr	-886(ra) # 800046b8 <dirlink>
    80005a36:	f80557e3          	bgez	a0,800059c4 <create+0xce>
      panic("create dots");
    80005a3a:	00003517          	auipc	a0,0x3
    80005a3e:	e0e50513          	addi	a0,a0,-498 # 80008848 <syscalls+0x2d8>
    80005a42:	ffffb097          	auipc	ra,0xffffb
    80005a46:	afc080e7          	jalr	-1284(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005a4a:	00003517          	auipc	a0,0x3
    80005a4e:	e0e50513          	addi	a0,a0,-498 # 80008858 <syscalls+0x2e8>
    80005a52:	ffffb097          	auipc	ra,0xffffb
    80005a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
    return 0;
    80005a5a:	84aa                	mv	s1,a0
    80005a5c:	b731                	j	80005968 <create+0x72>

0000000080005a5e <sys_dup>:
{
    80005a5e:	7179                	addi	sp,sp,-48
    80005a60:	f406                	sd	ra,40(sp)
    80005a62:	f022                	sd	s0,32(sp)
    80005a64:	ec26                	sd	s1,24(sp)
    80005a66:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a68:	fd840613          	addi	a2,s0,-40
    80005a6c:	4581                	li	a1,0
    80005a6e:	4501                	li	a0,0
    80005a70:	00000097          	auipc	ra,0x0
    80005a74:	ddc080e7          	jalr	-548(ra) # 8000584c <argfd>
    return -1;
    80005a78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a7a:	02054363          	bltz	a0,80005aa0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a7e:	fd843503          	ld	a0,-40(s0)
    80005a82:	00000097          	auipc	ra,0x0
    80005a86:	e32080e7          	jalr	-462(ra) # 800058b4 <fdalloc>
    80005a8a:	84aa                	mv	s1,a0
    return -1;
    80005a8c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a8e:	00054963          	bltz	a0,80005aa0 <sys_dup+0x42>
  filedup(f);
    80005a92:	fd843503          	ld	a0,-40(s0)
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	37a080e7          	jalr	890(ra) # 80004e10 <filedup>
  return fd;
    80005a9e:	87a6                	mv	a5,s1
}
    80005aa0:	853e                	mv	a0,a5
    80005aa2:	70a2                	ld	ra,40(sp)
    80005aa4:	7402                	ld	s0,32(sp)
    80005aa6:	64e2                	ld	s1,24(sp)
    80005aa8:	6145                	addi	sp,sp,48
    80005aaa:	8082                	ret

0000000080005aac <sys_read>:
{
    80005aac:	7179                	addi	sp,sp,-48
    80005aae:	f406                	sd	ra,40(sp)
    80005ab0:	f022                	sd	s0,32(sp)
    80005ab2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ab4:	fe840613          	addi	a2,s0,-24
    80005ab8:	4581                	li	a1,0
    80005aba:	4501                	li	a0,0
    80005abc:	00000097          	auipc	ra,0x0
    80005ac0:	d90080e7          	jalr	-624(ra) # 8000584c <argfd>
    return -1;
    80005ac4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ac6:	04054163          	bltz	a0,80005b08 <sys_read+0x5c>
    80005aca:	fe440593          	addi	a1,s0,-28
    80005ace:	4509                	li	a0,2
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	906080e7          	jalr	-1786(ra) # 800033d6 <argint>
    return -1;
    80005ad8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ada:	02054763          	bltz	a0,80005b08 <sys_read+0x5c>
    80005ade:	fd840593          	addi	a1,s0,-40
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	914080e7          	jalr	-1772(ra) # 800033f8 <argaddr>
    return -1;
    80005aec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aee:	00054d63          	bltz	a0,80005b08 <sys_read+0x5c>
  return fileread(f, p, n);
    80005af2:	fe442603          	lw	a2,-28(s0)
    80005af6:	fd843583          	ld	a1,-40(s0)
    80005afa:	fe843503          	ld	a0,-24(s0)
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	49e080e7          	jalr	1182(ra) # 80004f9c <fileread>
    80005b06:	87aa                	mv	a5,a0
}
    80005b08:	853e                	mv	a0,a5
    80005b0a:	70a2                	ld	ra,40(sp)
    80005b0c:	7402                	ld	s0,32(sp)
    80005b0e:	6145                	addi	sp,sp,48
    80005b10:	8082                	ret

0000000080005b12 <sys_write>:
{
    80005b12:	7179                	addi	sp,sp,-48
    80005b14:	f406                	sd	ra,40(sp)
    80005b16:	f022                	sd	s0,32(sp)
    80005b18:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b1a:	fe840613          	addi	a2,s0,-24
    80005b1e:	4581                	li	a1,0
    80005b20:	4501                	li	a0,0
    80005b22:	00000097          	auipc	ra,0x0
    80005b26:	d2a080e7          	jalr	-726(ra) # 8000584c <argfd>
    return -1;
    80005b2a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b2c:	04054163          	bltz	a0,80005b6e <sys_write+0x5c>
    80005b30:	fe440593          	addi	a1,s0,-28
    80005b34:	4509                	li	a0,2
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	8a0080e7          	jalr	-1888(ra) # 800033d6 <argint>
    return -1;
    80005b3e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b40:	02054763          	bltz	a0,80005b6e <sys_write+0x5c>
    80005b44:	fd840593          	addi	a1,s0,-40
    80005b48:	4505                	li	a0,1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	8ae080e7          	jalr	-1874(ra) # 800033f8 <argaddr>
    return -1;
    80005b52:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b54:	00054d63          	bltz	a0,80005b6e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005b58:	fe442603          	lw	a2,-28(s0)
    80005b5c:	fd843583          	ld	a1,-40(s0)
    80005b60:	fe843503          	ld	a0,-24(s0)
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	4fa080e7          	jalr	1274(ra) # 8000505e <filewrite>
    80005b6c:	87aa                	mv	a5,a0
}
    80005b6e:	853e                	mv	a0,a5
    80005b70:	70a2                	ld	ra,40(sp)
    80005b72:	7402                	ld	s0,32(sp)
    80005b74:	6145                	addi	sp,sp,48
    80005b76:	8082                	ret

0000000080005b78 <sys_close>:
{
    80005b78:	1101                	addi	sp,sp,-32
    80005b7a:	ec06                	sd	ra,24(sp)
    80005b7c:	e822                	sd	s0,16(sp)
    80005b7e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b80:	fe040613          	addi	a2,s0,-32
    80005b84:	fec40593          	addi	a1,s0,-20
    80005b88:	4501                	li	a0,0
    80005b8a:	00000097          	auipc	ra,0x0
    80005b8e:	cc2080e7          	jalr	-830(ra) # 8000584c <argfd>
    return -1;
    80005b92:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b94:	02054463          	bltz	a0,80005bbc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b98:	ffffc097          	auipc	ra,0xffffc
    80005b9c:	334080e7          	jalr	820(ra) # 80001ecc <myproc>
    80005ba0:	fec42783          	lw	a5,-20(s0)
    80005ba4:	07e9                	addi	a5,a5,26
    80005ba6:	078e                	slli	a5,a5,0x3
    80005ba8:	97aa                	add	a5,a5,a0
    80005baa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005bae:	fe043503          	ld	a0,-32(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	2b0080e7          	jalr	688(ra) # 80004e62 <fileclose>
  return 0;
    80005bba:	4781                	li	a5,0
}
    80005bbc:	853e                	mv	a0,a5
    80005bbe:	60e2                	ld	ra,24(sp)
    80005bc0:	6442                	ld	s0,16(sp)
    80005bc2:	6105                	addi	sp,sp,32
    80005bc4:	8082                	ret

0000000080005bc6 <sys_fstat>:
{
    80005bc6:	1101                	addi	sp,sp,-32
    80005bc8:	ec06                	sd	ra,24(sp)
    80005bca:	e822                	sd	s0,16(sp)
    80005bcc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bce:	fe840613          	addi	a2,s0,-24
    80005bd2:	4581                	li	a1,0
    80005bd4:	4501                	li	a0,0
    80005bd6:	00000097          	auipc	ra,0x0
    80005bda:	c76080e7          	jalr	-906(ra) # 8000584c <argfd>
    return -1;
    80005bde:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005be0:	02054563          	bltz	a0,80005c0a <sys_fstat+0x44>
    80005be4:	fe040593          	addi	a1,s0,-32
    80005be8:	4505                	li	a0,1
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	80e080e7          	jalr	-2034(ra) # 800033f8 <argaddr>
    return -1;
    80005bf2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bf4:	00054b63          	bltz	a0,80005c0a <sys_fstat+0x44>
  return filestat(f, st);
    80005bf8:	fe043583          	ld	a1,-32(s0)
    80005bfc:	fe843503          	ld	a0,-24(s0)
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	32a080e7          	jalr	810(ra) # 80004f2a <filestat>
    80005c08:	87aa                	mv	a5,a0
}
    80005c0a:	853e                	mv	a0,a5
    80005c0c:	60e2                	ld	ra,24(sp)
    80005c0e:	6442                	ld	s0,16(sp)
    80005c10:	6105                	addi	sp,sp,32
    80005c12:	8082                	ret

0000000080005c14 <sys_link>:
{
    80005c14:	7169                	addi	sp,sp,-304
    80005c16:	f606                	sd	ra,296(sp)
    80005c18:	f222                	sd	s0,288(sp)
    80005c1a:	ee26                	sd	s1,280(sp)
    80005c1c:	ea4a                	sd	s2,272(sp)
    80005c1e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c20:	08000613          	li	a2,128
    80005c24:	ed040593          	addi	a1,s0,-304
    80005c28:	4501                	li	a0,0
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	7f0080e7          	jalr	2032(ra) # 8000341a <argstr>
    return -1;
    80005c32:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c34:	10054e63          	bltz	a0,80005d50 <sys_link+0x13c>
    80005c38:	08000613          	li	a2,128
    80005c3c:	f5040593          	addi	a1,s0,-176
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	7d8080e7          	jalr	2008(ra) # 8000341a <argstr>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c4c:	10054263          	bltz	a0,80005d50 <sys_link+0x13c>
  begin_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	d46080e7          	jalr	-698(ra) # 80004996 <begin_op>
  if((ip = namei(old)) == 0){
    80005c58:	ed040513          	addi	a0,s0,-304
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	b1e080e7          	jalr	-1250(ra) # 8000477a <namei>
    80005c64:	84aa                	mv	s1,a0
    80005c66:	c551                	beqz	a0,80005cf2 <sys_link+0xde>
  ilock(ip);
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	35c080e7          	jalr	860(ra) # 80003fc4 <ilock>
  if(ip->type == T_DIR){
    80005c70:	04449703          	lh	a4,68(s1)
    80005c74:	4785                	li	a5,1
    80005c76:	08f70463          	beq	a4,a5,80005cfe <sys_link+0xea>
  ip->nlink++;
    80005c7a:	04a4d783          	lhu	a5,74(s1)
    80005c7e:	2785                	addiw	a5,a5,1
    80005c80:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	274080e7          	jalr	628(ra) # 80003efa <iupdate>
  iunlock(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	3f6080e7          	jalr	1014(ra) # 80004086 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c98:	fd040593          	addi	a1,s0,-48
    80005c9c:	f5040513          	addi	a0,s0,-176
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	af8080e7          	jalr	-1288(ra) # 80004798 <nameiparent>
    80005ca8:	892a                	mv	s2,a0
    80005caa:	c935                	beqz	a0,80005d1e <sys_link+0x10a>
  ilock(dp);
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	318080e7          	jalr	792(ra) # 80003fc4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005cb4:	00092703          	lw	a4,0(s2)
    80005cb8:	409c                	lw	a5,0(s1)
    80005cba:	04f71d63          	bne	a4,a5,80005d14 <sys_link+0x100>
    80005cbe:	40d0                	lw	a2,4(s1)
    80005cc0:	fd040593          	addi	a1,s0,-48
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9f2080e7          	jalr	-1550(ra) # 800046b8 <dirlink>
    80005cce:	04054363          	bltz	a0,80005d14 <sys_link+0x100>
  iunlockput(dp);
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	552080e7          	jalr	1362(ra) # 80004226 <iunlockput>
  iput(ip);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	4a0080e7          	jalr	1184(ra) # 8000417e <iput>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	d30080e7          	jalr	-720(ra) # 80004a16 <end_op>
  return 0;
    80005cee:	4781                	li	a5,0
    80005cf0:	a085                	j	80005d50 <sys_link+0x13c>
    end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	d24080e7          	jalr	-732(ra) # 80004a16 <end_op>
    return -1;
    80005cfa:	57fd                	li	a5,-1
    80005cfc:	a891                	j	80005d50 <sys_link+0x13c>
    iunlockput(ip);
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	526080e7          	jalr	1318(ra) # 80004226 <iunlockput>
    end_op();
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	d0e080e7          	jalr	-754(ra) # 80004a16 <end_op>
    return -1;
    80005d10:	57fd                	li	a5,-1
    80005d12:	a83d                	j	80005d50 <sys_link+0x13c>
    iunlockput(dp);
    80005d14:	854a                	mv	a0,s2
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	510080e7          	jalr	1296(ra) # 80004226 <iunlockput>
  ilock(ip);
    80005d1e:	8526                	mv	a0,s1
    80005d20:	ffffe097          	auipc	ra,0xffffe
    80005d24:	2a4080e7          	jalr	676(ra) # 80003fc4 <ilock>
  ip->nlink--;
    80005d28:	04a4d783          	lhu	a5,74(s1)
    80005d2c:	37fd                	addiw	a5,a5,-1
    80005d2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d32:	8526                	mv	a0,s1
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	1c6080e7          	jalr	454(ra) # 80003efa <iupdate>
  iunlockput(ip);
    80005d3c:	8526                	mv	a0,s1
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	4e8080e7          	jalr	1256(ra) # 80004226 <iunlockput>
  end_op();
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	cd0080e7          	jalr	-816(ra) # 80004a16 <end_op>
  return -1;
    80005d4e:	57fd                	li	a5,-1
}
    80005d50:	853e                	mv	a0,a5
    80005d52:	70b2                	ld	ra,296(sp)
    80005d54:	7412                	ld	s0,288(sp)
    80005d56:	64f2                	ld	s1,280(sp)
    80005d58:	6952                	ld	s2,272(sp)
    80005d5a:	6155                	addi	sp,sp,304
    80005d5c:	8082                	ret

0000000080005d5e <sys_unlink>:
{
    80005d5e:	7151                	addi	sp,sp,-240
    80005d60:	f586                	sd	ra,232(sp)
    80005d62:	f1a2                	sd	s0,224(sp)
    80005d64:	eda6                	sd	s1,216(sp)
    80005d66:	e9ca                	sd	s2,208(sp)
    80005d68:	e5ce                	sd	s3,200(sp)
    80005d6a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d6c:	08000613          	li	a2,128
    80005d70:	f3040593          	addi	a1,s0,-208
    80005d74:	4501                	li	a0,0
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	6a4080e7          	jalr	1700(ra) # 8000341a <argstr>
    80005d7e:	18054163          	bltz	a0,80005f00 <sys_unlink+0x1a2>
  begin_op();
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	c14080e7          	jalr	-1004(ra) # 80004996 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d8a:	fb040593          	addi	a1,s0,-80
    80005d8e:	f3040513          	addi	a0,s0,-208
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	a06080e7          	jalr	-1530(ra) # 80004798 <nameiparent>
    80005d9a:	84aa                	mv	s1,a0
    80005d9c:	c979                	beqz	a0,80005e72 <sys_unlink+0x114>
  ilock(dp);
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	226080e7          	jalr	550(ra) # 80003fc4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005da6:	00003597          	auipc	a1,0x3
    80005daa:	a9258593          	addi	a1,a1,-1390 # 80008838 <syscalls+0x2c8>
    80005dae:	fb040513          	addi	a0,s0,-80
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	6dc080e7          	jalr	1756(ra) # 8000448e <namecmp>
    80005dba:	14050a63          	beqz	a0,80005f0e <sys_unlink+0x1b0>
    80005dbe:	00003597          	auipc	a1,0x3
    80005dc2:	a8258593          	addi	a1,a1,-1406 # 80008840 <syscalls+0x2d0>
    80005dc6:	fb040513          	addi	a0,s0,-80
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	6c4080e7          	jalr	1732(ra) # 8000448e <namecmp>
    80005dd2:	12050e63          	beqz	a0,80005f0e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dd6:	f2c40613          	addi	a2,s0,-212
    80005dda:	fb040593          	addi	a1,s0,-80
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	6c8080e7          	jalr	1736(ra) # 800044a8 <dirlookup>
    80005de8:	892a                	mv	s2,a0
    80005dea:	12050263          	beqz	a0,80005f0e <sys_unlink+0x1b0>
  ilock(ip);
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	1d6080e7          	jalr	470(ra) # 80003fc4 <ilock>
  if(ip->nlink < 1)
    80005df6:	04a91783          	lh	a5,74(s2)
    80005dfa:	08f05263          	blez	a5,80005e7e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005dfe:	04491703          	lh	a4,68(s2)
    80005e02:	4785                	li	a5,1
    80005e04:	08f70563          	beq	a4,a5,80005e8e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e08:	4641                	li	a2,16
    80005e0a:	4581                	li	a1,0
    80005e0c:	fc040513          	addi	a0,s0,-64
    80005e10:	ffffb097          	auipc	ra,0xffffb
    80005e14:	ed0080e7          	jalr	-304(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e18:	4741                	li	a4,16
    80005e1a:	f2c42683          	lw	a3,-212(s0)
    80005e1e:	fc040613          	addi	a2,s0,-64
    80005e22:	4581                	li	a1,0
    80005e24:	8526                	mv	a0,s1
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	54a080e7          	jalr	1354(ra) # 80004370 <writei>
    80005e2e:	47c1                	li	a5,16
    80005e30:	0af51563          	bne	a0,a5,80005eda <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e34:	04491703          	lh	a4,68(s2)
    80005e38:	4785                	li	a5,1
    80005e3a:	0af70863          	beq	a4,a5,80005eea <sys_unlink+0x18c>
  iunlockput(dp);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	3e6080e7          	jalr	998(ra) # 80004226 <iunlockput>
  ip->nlink--;
    80005e48:	04a95783          	lhu	a5,74(s2)
    80005e4c:	37fd                	addiw	a5,a5,-1
    80005e4e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e52:	854a                	mv	a0,s2
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	0a6080e7          	jalr	166(ra) # 80003efa <iupdate>
  iunlockput(ip);
    80005e5c:	854a                	mv	a0,s2
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	3c8080e7          	jalr	968(ra) # 80004226 <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	bb0080e7          	jalr	-1104(ra) # 80004a16 <end_op>
  return 0;
    80005e6e:	4501                	li	a0,0
    80005e70:	a84d                	j	80005f22 <sys_unlink+0x1c4>
    end_op();
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	ba4080e7          	jalr	-1116(ra) # 80004a16 <end_op>
    return -1;
    80005e7a:	557d                	li	a0,-1
    80005e7c:	a05d                	j	80005f22 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e7e:	00003517          	auipc	a0,0x3
    80005e82:	9ea50513          	addi	a0,a0,-1558 # 80008868 <syscalls+0x2f8>
    80005e86:	ffffa097          	auipc	ra,0xffffa
    80005e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e8e:	04c92703          	lw	a4,76(s2)
    80005e92:	02000793          	li	a5,32
    80005e96:	f6e7f9e3          	bgeu	a5,a4,80005e08 <sys_unlink+0xaa>
    80005e9a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e9e:	4741                	li	a4,16
    80005ea0:	86ce                	mv	a3,s3
    80005ea2:	f1840613          	addi	a2,s0,-232
    80005ea6:	4581                	li	a1,0
    80005ea8:	854a                	mv	a0,s2
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	3ce080e7          	jalr	974(ra) # 80004278 <readi>
    80005eb2:	47c1                	li	a5,16
    80005eb4:	00f51b63          	bne	a0,a5,80005eca <sys_unlink+0x16c>
    if(de.inum != 0)
    80005eb8:	f1845783          	lhu	a5,-232(s0)
    80005ebc:	e7a1                	bnez	a5,80005f04 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ebe:	29c1                	addiw	s3,s3,16
    80005ec0:	04c92783          	lw	a5,76(s2)
    80005ec4:	fcf9ede3          	bltu	s3,a5,80005e9e <sys_unlink+0x140>
    80005ec8:	b781                	j	80005e08 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005eca:	00003517          	auipc	a0,0x3
    80005ece:	9b650513          	addi	a0,a0,-1610 # 80008880 <syscalls+0x310>
    80005ed2:	ffffa097          	auipc	ra,0xffffa
    80005ed6:	66c080e7          	jalr	1644(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005eda:	00003517          	auipc	a0,0x3
    80005ede:	9be50513          	addi	a0,a0,-1602 # 80008898 <syscalls+0x328>
    80005ee2:	ffffa097          	auipc	ra,0xffffa
    80005ee6:	65c080e7          	jalr	1628(ra) # 8000053e <panic>
    dp->nlink--;
    80005eea:	04a4d783          	lhu	a5,74(s1)
    80005eee:	37fd                	addiw	a5,a5,-1
    80005ef0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ef4:	8526                	mv	a0,s1
    80005ef6:	ffffe097          	auipc	ra,0xffffe
    80005efa:	004080e7          	jalr	4(ra) # 80003efa <iupdate>
    80005efe:	b781                	j	80005e3e <sys_unlink+0xe0>
    return -1;
    80005f00:	557d                	li	a0,-1
    80005f02:	a005                	j	80005f22 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f04:	854a                	mv	a0,s2
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	320080e7          	jalr	800(ra) # 80004226 <iunlockput>
  iunlockput(dp);
    80005f0e:	8526                	mv	a0,s1
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	316080e7          	jalr	790(ra) # 80004226 <iunlockput>
  end_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	afe080e7          	jalr	-1282(ra) # 80004a16 <end_op>
  return -1;
    80005f20:	557d                	li	a0,-1
}
    80005f22:	70ae                	ld	ra,232(sp)
    80005f24:	740e                	ld	s0,224(sp)
    80005f26:	64ee                	ld	s1,216(sp)
    80005f28:	694e                	ld	s2,208(sp)
    80005f2a:	69ae                	ld	s3,200(sp)
    80005f2c:	616d                	addi	sp,sp,240
    80005f2e:	8082                	ret

0000000080005f30 <sys_open>:

uint64
sys_open(void)
{
    80005f30:	7131                	addi	sp,sp,-192
    80005f32:	fd06                	sd	ra,184(sp)
    80005f34:	f922                	sd	s0,176(sp)
    80005f36:	f526                	sd	s1,168(sp)
    80005f38:	f14a                	sd	s2,160(sp)
    80005f3a:	ed4e                	sd	s3,152(sp)
    80005f3c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f3e:	08000613          	li	a2,128
    80005f42:	f5040593          	addi	a1,s0,-176
    80005f46:	4501                	li	a0,0
    80005f48:	ffffd097          	auipc	ra,0xffffd
    80005f4c:	4d2080e7          	jalr	1234(ra) # 8000341a <argstr>
    return -1;
    80005f50:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f52:	0c054163          	bltz	a0,80006014 <sys_open+0xe4>
    80005f56:	f4c40593          	addi	a1,s0,-180
    80005f5a:	4505                	li	a0,1
    80005f5c:	ffffd097          	auipc	ra,0xffffd
    80005f60:	47a080e7          	jalr	1146(ra) # 800033d6 <argint>
    80005f64:	0a054863          	bltz	a0,80006014 <sys_open+0xe4>

  begin_op();
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	a2e080e7          	jalr	-1490(ra) # 80004996 <begin_op>

  if(omode & O_CREATE){
    80005f70:	f4c42783          	lw	a5,-180(s0)
    80005f74:	2007f793          	andi	a5,a5,512
    80005f78:	cbdd                	beqz	a5,8000602e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f7a:	4681                	li	a3,0
    80005f7c:	4601                	li	a2,0
    80005f7e:	4589                	li	a1,2
    80005f80:	f5040513          	addi	a0,s0,-176
    80005f84:	00000097          	auipc	ra,0x0
    80005f88:	972080e7          	jalr	-1678(ra) # 800058f6 <create>
    80005f8c:	892a                	mv	s2,a0
    if(ip == 0){
    80005f8e:	c959                	beqz	a0,80006024 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f90:	04491703          	lh	a4,68(s2)
    80005f94:	478d                	li	a5,3
    80005f96:	00f71763          	bne	a4,a5,80005fa4 <sys_open+0x74>
    80005f9a:	04695703          	lhu	a4,70(s2)
    80005f9e:	47a5                	li	a5,9
    80005fa0:	0ce7ec63          	bltu	a5,a4,80006078 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	e02080e7          	jalr	-510(ra) # 80004da6 <filealloc>
    80005fac:	89aa                	mv	s3,a0
    80005fae:	10050263          	beqz	a0,800060b2 <sys_open+0x182>
    80005fb2:	00000097          	auipc	ra,0x0
    80005fb6:	902080e7          	jalr	-1790(ra) # 800058b4 <fdalloc>
    80005fba:	84aa                	mv	s1,a0
    80005fbc:	0e054663          	bltz	a0,800060a8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fc0:	04491703          	lh	a4,68(s2)
    80005fc4:	478d                	li	a5,3
    80005fc6:	0cf70463          	beq	a4,a5,8000608e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fca:	4789                	li	a5,2
    80005fcc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005fd0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005fd4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005fd8:	f4c42783          	lw	a5,-180(s0)
    80005fdc:	0017c713          	xori	a4,a5,1
    80005fe0:	8b05                	andi	a4,a4,1
    80005fe2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fe6:	0037f713          	andi	a4,a5,3
    80005fea:	00e03733          	snez	a4,a4
    80005fee:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ff2:	4007f793          	andi	a5,a5,1024
    80005ff6:	c791                	beqz	a5,80006002 <sys_open+0xd2>
    80005ff8:	04491703          	lh	a4,68(s2)
    80005ffc:	4789                	li	a5,2
    80005ffe:	08f70f63          	beq	a4,a5,8000609c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006002:	854a                	mv	a0,s2
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	082080e7          	jalr	130(ra) # 80004086 <iunlock>
  end_op();
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	a0a080e7          	jalr	-1526(ra) # 80004a16 <end_op>

  return fd;
}
    80006014:	8526                	mv	a0,s1
    80006016:	70ea                	ld	ra,184(sp)
    80006018:	744a                	ld	s0,176(sp)
    8000601a:	74aa                	ld	s1,168(sp)
    8000601c:	790a                	ld	s2,160(sp)
    8000601e:	69ea                	ld	s3,152(sp)
    80006020:	6129                	addi	sp,sp,192
    80006022:	8082                	ret
      end_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	9f2080e7          	jalr	-1550(ra) # 80004a16 <end_op>
      return -1;
    8000602c:	b7e5                	j	80006014 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000602e:	f5040513          	addi	a0,s0,-176
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	748080e7          	jalr	1864(ra) # 8000477a <namei>
    8000603a:	892a                	mv	s2,a0
    8000603c:	c905                	beqz	a0,8000606c <sys_open+0x13c>
    ilock(ip);
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	f86080e7          	jalr	-122(ra) # 80003fc4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006046:	04491703          	lh	a4,68(s2)
    8000604a:	4785                	li	a5,1
    8000604c:	f4f712e3          	bne	a4,a5,80005f90 <sys_open+0x60>
    80006050:	f4c42783          	lw	a5,-180(s0)
    80006054:	dba1                	beqz	a5,80005fa4 <sys_open+0x74>
      iunlockput(ip);
    80006056:	854a                	mv	a0,s2
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	1ce080e7          	jalr	462(ra) # 80004226 <iunlockput>
      end_op();
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	9b6080e7          	jalr	-1610(ra) # 80004a16 <end_op>
      return -1;
    80006068:	54fd                	li	s1,-1
    8000606a:	b76d                	j	80006014 <sys_open+0xe4>
      end_op();
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	9aa080e7          	jalr	-1622(ra) # 80004a16 <end_op>
      return -1;
    80006074:	54fd                	li	s1,-1
    80006076:	bf79                	j	80006014 <sys_open+0xe4>
    iunlockput(ip);
    80006078:	854a                	mv	a0,s2
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	1ac080e7          	jalr	428(ra) # 80004226 <iunlockput>
    end_op();
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	994080e7          	jalr	-1644(ra) # 80004a16 <end_op>
    return -1;
    8000608a:	54fd                	li	s1,-1
    8000608c:	b761                	j	80006014 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000608e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006092:	04691783          	lh	a5,70(s2)
    80006096:	02f99223          	sh	a5,36(s3)
    8000609a:	bf2d                	j	80005fd4 <sys_open+0xa4>
    itrunc(ip);
    8000609c:	854a                	mv	a0,s2
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	034080e7          	jalr	52(ra) # 800040d2 <itrunc>
    800060a6:	bfb1                	j	80006002 <sys_open+0xd2>
      fileclose(f);
    800060a8:	854e                	mv	a0,s3
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	db8080e7          	jalr	-584(ra) # 80004e62 <fileclose>
    iunlockput(ip);
    800060b2:	854a                	mv	a0,s2
    800060b4:	ffffe097          	auipc	ra,0xffffe
    800060b8:	172080e7          	jalr	370(ra) # 80004226 <iunlockput>
    end_op();
    800060bc:	fffff097          	auipc	ra,0xfffff
    800060c0:	95a080e7          	jalr	-1702(ra) # 80004a16 <end_op>
    return -1;
    800060c4:	54fd                	li	s1,-1
    800060c6:	b7b9                	j	80006014 <sys_open+0xe4>

00000000800060c8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060c8:	7175                	addi	sp,sp,-144
    800060ca:	e506                	sd	ra,136(sp)
    800060cc:	e122                	sd	s0,128(sp)
    800060ce:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060d0:	fffff097          	auipc	ra,0xfffff
    800060d4:	8c6080e7          	jalr	-1850(ra) # 80004996 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060d8:	08000613          	li	a2,128
    800060dc:	f7040593          	addi	a1,s0,-144
    800060e0:	4501                	li	a0,0
    800060e2:	ffffd097          	auipc	ra,0xffffd
    800060e6:	338080e7          	jalr	824(ra) # 8000341a <argstr>
    800060ea:	02054963          	bltz	a0,8000611c <sys_mkdir+0x54>
    800060ee:	4681                	li	a3,0
    800060f0:	4601                	li	a2,0
    800060f2:	4585                	li	a1,1
    800060f4:	f7040513          	addi	a0,s0,-144
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	7fe080e7          	jalr	2046(ra) # 800058f6 <create>
    80006100:	cd11                	beqz	a0,8000611c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	124080e7          	jalr	292(ra) # 80004226 <iunlockput>
  end_op();
    8000610a:	fffff097          	auipc	ra,0xfffff
    8000610e:	90c080e7          	jalr	-1780(ra) # 80004a16 <end_op>
  return 0;
    80006112:	4501                	li	a0,0
}
    80006114:	60aa                	ld	ra,136(sp)
    80006116:	640a                	ld	s0,128(sp)
    80006118:	6149                	addi	sp,sp,144
    8000611a:	8082                	ret
    end_op();
    8000611c:	fffff097          	auipc	ra,0xfffff
    80006120:	8fa080e7          	jalr	-1798(ra) # 80004a16 <end_op>
    return -1;
    80006124:	557d                	li	a0,-1
    80006126:	b7fd                	j	80006114 <sys_mkdir+0x4c>

0000000080006128 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006128:	7135                	addi	sp,sp,-160
    8000612a:	ed06                	sd	ra,152(sp)
    8000612c:	e922                	sd	s0,144(sp)
    8000612e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006130:	fffff097          	auipc	ra,0xfffff
    80006134:	866080e7          	jalr	-1946(ra) # 80004996 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006138:	08000613          	li	a2,128
    8000613c:	f7040593          	addi	a1,s0,-144
    80006140:	4501                	li	a0,0
    80006142:	ffffd097          	auipc	ra,0xffffd
    80006146:	2d8080e7          	jalr	728(ra) # 8000341a <argstr>
    8000614a:	04054a63          	bltz	a0,8000619e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000614e:	f6c40593          	addi	a1,s0,-148
    80006152:	4505                	li	a0,1
    80006154:	ffffd097          	auipc	ra,0xffffd
    80006158:	282080e7          	jalr	642(ra) # 800033d6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000615c:	04054163          	bltz	a0,8000619e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006160:	f6840593          	addi	a1,s0,-152
    80006164:	4509                	li	a0,2
    80006166:	ffffd097          	auipc	ra,0xffffd
    8000616a:	270080e7          	jalr	624(ra) # 800033d6 <argint>
     argint(1, &major) < 0 ||
    8000616e:	02054863          	bltz	a0,8000619e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006172:	f6841683          	lh	a3,-152(s0)
    80006176:	f6c41603          	lh	a2,-148(s0)
    8000617a:	458d                	li	a1,3
    8000617c:	f7040513          	addi	a0,s0,-144
    80006180:	fffff097          	auipc	ra,0xfffff
    80006184:	776080e7          	jalr	1910(ra) # 800058f6 <create>
     argint(2, &minor) < 0 ||
    80006188:	c919                	beqz	a0,8000619e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	09c080e7          	jalr	156(ra) # 80004226 <iunlockput>
  end_op();
    80006192:	fffff097          	auipc	ra,0xfffff
    80006196:	884080e7          	jalr	-1916(ra) # 80004a16 <end_op>
  return 0;
    8000619a:	4501                	li	a0,0
    8000619c:	a031                	j	800061a8 <sys_mknod+0x80>
    end_op();
    8000619e:	fffff097          	auipc	ra,0xfffff
    800061a2:	878080e7          	jalr	-1928(ra) # 80004a16 <end_op>
    return -1;
    800061a6:	557d                	li	a0,-1
}
    800061a8:	60ea                	ld	ra,152(sp)
    800061aa:	644a                	ld	s0,144(sp)
    800061ac:	610d                	addi	sp,sp,160
    800061ae:	8082                	ret

00000000800061b0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061b0:	7135                	addi	sp,sp,-160
    800061b2:	ed06                	sd	ra,152(sp)
    800061b4:	e922                	sd	s0,144(sp)
    800061b6:	e526                	sd	s1,136(sp)
    800061b8:	e14a                	sd	s2,128(sp)
    800061ba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061bc:	ffffc097          	auipc	ra,0xffffc
    800061c0:	d10080e7          	jalr	-752(ra) # 80001ecc <myproc>
    800061c4:	892a                	mv	s2,a0
  
  begin_op();
    800061c6:	ffffe097          	auipc	ra,0xffffe
    800061ca:	7d0080e7          	jalr	2000(ra) # 80004996 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061ce:	08000613          	li	a2,128
    800061d2:	f6040593          	addi	a1,s0,-160
    800061d6:	4501                	li	a0,0
    800061d8:	ffffd097          	auipc	ra,0xffffd
    800061dc:	242080e7          	jalr	578(ra) # 8000341a <argstr>
    800061e0:	04054b63          	bltz	a0,80006236 <sys_chdir+0x86>
    800061e4:	f6040513          	addi	a0,s0,-160
    800061e8:	ffffe097          	auipc	ra,0xffffe
    800061ec:	592080e7          	jalr	1426(ra) # 8000477a <namei>
    800061f0:	84aa                	mv	s1,a0
    800061f2:	c131                	beqz	a0,80006236 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800061f4:	ffffe097          	auipc	ra,0xffffe
    800061f8:	dd0080e7          	jalr	-560(ra) # 80003fc4 <ilock>
  if(ip->type != T_DIR){
    800061fc:	04449703          	lh	a4,68(s1)
    80006200:	4785                	li	a5,1
    80006202:	04f71063          	bne	a4,a5,80006242 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006206:	8526                	mv	a0,s1
    80006208:	ffffe097          	auipc	ra,0xffffe
    8000620c:	e7e080e7          	jalr	-386(ra) # 80004086 <iunlock>
  iput(p->cwd);
    80006210:	15093503          	ld	a0,336(s2)
    80006214:	ffffe097          	auipc	ra,0xffffe
    80006218:	f6a080e7          	jalr	-150(ra) # 8000417e <iput>
  end_op();
    8000621c:	ffffe097          	auipc	ra,0xffffe
    80006220:	7fa080e7          	jalr	2042(ra) # 80004a16 <end_op>
  p->cwd = ip;
    80006224:	14993823          	sd	s1,336(s2)
  return 0;
    80006228:	4501                	li	a0,0
}
    8000622a:	60ea                	ld	ra,152(sp)
    8000622c:	644a                	ld	s0,144(sp)
    8000622e:	64aa                	ld	s1,136(sp)
    80006230:	690a                	ld	s2,128(sp)
    80006232:	610d                	addi	sp,sp,160
    80006234:	8082                	ret
    end_op();
    80006236:	ffffe097          	auipc	ra,0xffffe
    8000623a:	7e0080e7          	jalr	2016(ra) # 80004a16 <end_op>
    return -1;
    8000623e:	557d                	li	a0,-1
    80006240:	b7ed                	j	8000622a <sys_chdir+0x7a>
    iunlockput(ip);
    80006242:	8526                	mv	a0,s1
    80006244:	ffffe097          	auipc	ra,0xffffe
    80006248:	fe2080e7          	jalr	-30(ra) # 80004226 <iunlockput>
    end_op();
    8000624c:	ffffe097          	auipc	ra,0xffffe
    80006250:	7ca080e7          	jalr	1994(ra) # 80004a16 <end_op>
    return -1;
    80006254:	557d                	li	a0,-1
    80006256:	bfd1                	j	8000622a <sys_chdir+0x7a>

0000000080006258 <sys_exec>:

uint64
sys_exec(void)
{
    80006258:	7145                	addi	sp,sp,-464
    8000625a:	e786                	sd	ra,456(sp)
    8000625c:	e3a2                	sd	s0,448(sp)
    8000625e:	ff26                	sd	s1,440(sp)
    80006260:	fb4a                	sd	s2,432(sp)
    80006262:	f74e                	sd	s3,424(sp)
    80006264:	f352                	sd	s4,416(sp)
    80006266:	ef56                	sd	s5,408(sp)
    80006268:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000626a:	08000613          	li	a2,128
    8000626e:	f4040593          	addi	a1,s0,-192
    80006272:	4501                	li	a0,0
    80006274:	ffffd097          	auipc	ra,0xffffd
    80006278:	1a6080e7          	jalr	422(ra) # 8000341a <argstr>
    return -1;
    8000627c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000627e:	0c054a63          	bltz	a0,80006352 <sys_exec+0xfa>
    80006282:	e3840593          	addi	a1,s0,-456
    80006286:	4505                	li	a0,1
    80006288:	ffffd097          	auipc	ra,0xffffd
    8000628c:	170080e7          	jalr	368(ra) # 800033f8 <argaddr>
    80006290:	0c054163          	bltz	a0,80006352 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006294:	10000613          	li	a2,256
    80006298:	4581                	li	a1,0
    8000629a:	e4040513          	addi	a0,s0,-448
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	a42080e7          	jalr	-1470(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062a6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062aa:	89a6                	mv	s3,s1
    800062ac:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062ae:	02000a13          	li	s4,32
    800062b2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062b6:	00391513          	slli	a0,s2,0x3
    800062ba:	e3040593          	addi	a1,s0,-464
    800062be:	e3843783          	ld	a5,-456(s0)
    800062c2:	953e                	add	a0,a0,a5
    800062c4:	ffffd097          	auipc	ra,0xffffd
    800062c8:	078080e7          	jalr	120(ra) # 8000333c <fetchaddr>
    800062cc:	02054a63          	bltz	a0,80006300 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800062d0:	e3043783          	ld	a5,-464(s0)
    800062d4:	c3b9                	beqz	a5,8000631a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	81e080e7          	jalr	-2018(ra) # 80000af4 <kalloc>
    800062de:	85aa                	mv	a1,a0
    800062e0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062e4:	cd11                	beqz	a0,80006300 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062e6:	6605                	lui	a2,0x1
    800062e8:	e3043503          	ld	a0,-464(s0)
    800062ec:	ffffd097          	auipc	ra,0xffffd
    800062f0:	0a2080e7          	jalr	162(ra) # 8000338e <fetchstr>
    800062f4:	00054663          	bltz	a0,80006300 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800062f8:	0905                	addi	s2,s2,1
    800062fa:	09a1                	addi	s3,s3,8
    800062fc:	fb491be3          	bne	s2,s4,800062b2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006300:	10048913          	addi	s2,s1,256
    80006304:	6088                	ld	a0,0(s1)
    80006306:	c529                	beqz	a0,80006350 <sys_exec+0xf8>
    kfree(argv[i]);
    80006308:	ffffa097          	auipc	ra,0xffffa
    8000630c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006310:	04a1                	addi	s1,s1,8
    80006312:	ff2499e3          	bne	s1,s2,80006304 <sys_exec+0xac>
  return -1;
    80006316:	597d                	li	s2,-1
    80006318:	a82d                	j	80006352 <sys_exec+0xfa>
      argv[i] = 0;
    8000631a:	0a8e                	slli	s5,s5,0x3
    8000631c:	fc040793          	addi	a5,s0,-64
    80006320:	9abe                	add	s5,s5,a5
    80006322:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006326:	e4040593          	addi	a1,s0,-448
    8000632a:	f4040513          	addi	a0,s0,-192
    8000632e:	fffff097          	auipc	ra,0xfffff
    80006332:	194080e7          	jalr	404(ra) # 800054c2 <exec>
    80006336:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006338:	10048993          	addi	s3,s1,256
    8000633c:	6088                	ld	a0,0(s1)
    8000633e:	c911                	beqz	a0,80006352 <sys_exec+0xfa>
    kfree(argv[i]);
    80006340:	ffffa097          	auipc	ra,0xffffa
    80006344:	6b8080e7          	jalr	1720(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006348:	04a1                	addi	s1,s1,8
    8000634a:	ff3499e3          	bne	s1,s3,8000633c <sys_exec+0xe4>
    8000634e:	a011                	j	80006352 <sys_exec+0xfa>
  return -1;
    80006350:	597d                	li	s2,-1
}
    80006352:	854a                	mv	a0,s2
    80006354:	60be                	ld	ra,456(sp)
    80006356:	641e                	ld	s0,448(sp)
    80006358:	74fa                	ld	s1,440(sp)
    8000635a:	795a                	ld	s2,432(sp)
    8000635c:	79ba                	ld	s3,424(sp)
    8000635e:	7a1a                	ld	s4,416(sp)
    80006360:	6afa                	ld	s5,408(sp)
    80006362:	6179                	addi	sp,sp,464
    80006364:	8082                	ret

0000000080006366 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006366:	7139                	addi	sp,sp,-64
    80006368:	fc06                	sd	ra,56(sp)
    8000636a:	f822                	sd	s0,48(sp)
    8000636c:	f426                	sd	s1,40(sp)
    8000636e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006370:	ffffc097          	auipc	ra,0xffffc
    80006374:	b5c080e7          	jalr	-1188(ra) # 80001ecc <myproc>
    80006378:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000637a:	fd840593          	addi	a1,s0,-40
    8000637e:	4501                	li	a0,0
    80006380:	ffffd097          	auipc	ra,0xffffd
    80006384:	078080e7          	jalr	120(ra) # 800033f8 <argaddr>
    return -1;
    80006388:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000638a:	0e054063          	bltz	a0,8000646a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000638e:	fc840593          	addi	a1,s0,-56
    80006392:	fd040513          	addi	a0,s0,-48
    80006396:	fffff097          	auipc	ra,0xfffff
    8000639a:	dfc080e7          	jalr	-516(ra) # 80005192 <pipealloc>
    return -1;
    8000639e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063a0:	0c054563          	bltz	a0,8000646a <sys_pipe+0x104>
  fd0 = -1;
    800063a4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063a8:	fd043503          	ld	a0,-48(s0)
    800063ac:	fffff097          	auipc	ra,0xfffff
    800063b0:	508080e7          	jalr	1288(ra) # 800058b4 <fdalloc>
    800063b4:	fca42223          	sw	a0,-60(s0)
    800063b8:	08054c63          	bltz	a0,80006450 <sys_pipe+0xea>
    800063bc:	fc843503          	ld	a0,-56(s0)
    800063c0:	fffff097          	auipc	ra,0xfffff
    800063c4:	4f4080e7          	jalr	1268(ra) # 800058b4 <fdalloc>
    800063c8:	fca42023          	sw	a0,-64(s0)
    800063cc:	06054863          	bltz	a0,8000643c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063d0:	4691                	li	a3,4
    800063d2:	fc440613          	addi	a2,s0,-60
    800063d6:	fd843583          	ld	a1,-40(s0)
    800063da:	68a8                	ld	a0,80(s1)
    800063dc:	ffffb097          	auipc	ra,0xffffb
    800063e0:	296080e7          	jalr	662(ra) # 80001672 <copyout>
    800063e4:	02054063          	bltz	a0,80006404 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800063e8:	4691                	li	a3,4
    800063ea:	fc040613          	addi	a2,s0,-64
    800063ee:	fd843583          	ld	a1,-40(s0)
    800063f2:	0591                	addi	a1,a1,4
    800063f4:	68a8                	ld	a0,80(s1)
    800063f6:	ffffb097          	auipc	ra,0xffffb
    800063fa:	27c080e7          	jalr	636(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800063fe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006400:	06055563          	bgez	a0,8000646a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006404:	fc442783          	lw	a5,-60(s0)
    80006408:	07e9                	addi	a5,a5,26
    8000640a:	078e                	slli	a5,a5,0x3
    8000640c:	97a6                	add	a5,a5,s1
    8000640e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006412:	fc042503          	lw	a0,-64(s0)
    80006416:	0569                	addi	a0,a0,26
    80006418:	050e                	slli	a0,a0,0x3
    8000641a:	9526                	add	a0,a0,s1
    8000641c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006420:	fd043503          	ld	a0,-48(s0)
    80006424:	fffff097          	auipc	ra,0xfffff
    80006428:	a3e080e7          	jalr	-1474(ra) # 80004e62 <fileclose>
    fileclose(wf);
    8000642c:	fc843503          	ld	a0,-56(s0)
    80006430:	fffff097          	auipc	ra,0xfffff
    80006434:	a32080e7          	jalr	-1486(ra) # 80004e62 <fileclose>
    return -1;
    80006438:	57fd                	li	a5,-1
    8000643a:	a805                	j	8000646a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000643c:	fc442783          	lw	a5,-60(s0)
    80006440:	0007c863          	bltz	a5,80006450 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006444:	01a78513          	addi	a0,a5,26
    80006448:	050e                	slli	a0,a0,0x3
    8000644a:	9526                	add	a0,a0,s1
    8000644c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006450:	fd043503          	ld	a0,-48(s0)
    80006454:	fffff097          	auipc	ra,0xfffff
    80006458:	a0e080e7          	jalr	-1522(ra) # 80004e62 <fileclose>
    fileclose(wf);
    8000645c:	fc843503          	ld	a0,-56(s0)
    80006460:	fffff097          	auipc	ra,0xfffff
    80006464:	a02080e7          	jalr	-1534(ra) # 80004e62 <fileclose>
    return -1;
    80006468:	57fd                	li	a5,-1
}
    8000646a:	853e                	mv	a0,a5
    8000646c:	70e2                	ld	ra,56(sp)
    8000646e:	7442                	ld	s0,48(sp)
    80006470:	74a2                	ld	s1,40(sp)
    80006472:	6121                	addi	sp,sp,64
    80006474:	8082                	ret
	...

0000000080006480 <kernelvec>:
    80006480:	7111                	addi	sp,sp,-256
    80006482:	e006                	sd	ra,0(sp)
    80006484:	e40a                	sd	sp,8(sp)
    80006486:	e80e                	sd	gp,16(sp)
    80006488:	ec12                	sd	tp,24(sp)
    8000648a:	f016                	sd	t0,32(sp)
    8000648c:	f41a                	sd	t1,40(sp)
    8000648e:	f81e                	sd	t2,48(sp)
    80006490:	fc22                	sd	s0,56(sp)
    80006492:	e0a6                	sd	s1,64(sp)
    80006494:	e4aa                	sd	a0,72(sp)
    80006496:	e8ae                	sd	a1,80(sp)
    80006498:	ecb2                	sd	a2,88(sp)
    8000649a:	f0b6                	sd	a3,96(sp)
    8000649c:	f4ba                	sd	a4,104(sp)
    8000649e:	f8be                	sd	a5,112(sp)
    800064a0:	fcc2                	sd	a6,120(sp)
    800064a2:	e146                	sd	a7,128(sp)
    800064a4:	e54a                	sd	s2,136(sp)
    800064a6:	e94e                	sd	s3,144(sp)
    800064a8:	ed52                	sd	s4,152(sp)
    800064aa:	f156                	sd	s5,160(sp)
    800064ac:	f55a                	sd	s6,168(sp)
    800064ae:	f95e                	sd	s7,176(sp)
    800064b0:	fd62                	sd	s8,184(sp)
    800064b2:	e1e6                	sd	s9,192(sp)
    800064b4:	e5ea                	sd	s10,200(sp)
    800064b6:	e9ee                	sd	s11,208(sp)
    800064b8:	edf2                	sd	t3,216(sp)
    800064ba:	f1f6                	sd	t4,224(sp)
    800064bc:	f5fa                	sd	t5,232(sp)
    800064be:	f9fe                	sd	t6,240(sp)
    800064c0:	d49fc0ef          	jal	ra,80003208 <kerneltrap>
    800064c4:	6082                	ld	ra,0(sp)
    800064c6:	6122                	ld	sp,8(sp)
    800064c8:	61c2                	ld	gp,16(sp)
    800064ca:	7282                	ld	t0,32(sp)
    800064cc:	7322                	ld	t1,40(sp)
    800064ce:	73c2                	ld	t2,48(sp)
    800064d0:	7462                	ld	s0,56(sp)
    800064d2:	6486                	ld	s1,64(sp)
    800064d4:	6526                	ld	a0,72(sp)
    800064d6:	65c6                	ld	a1,80(sp)
    800064d8:	6666                	ld	a2,88(sp)
    800064da:	7686                	ld	a3,96(sp)
    800064dc:	7726                	ld	a4,104(sp)
    800064de:	77c6                	ld	a5,112(sp)
    800064e0:	7866                	ld	a6,120(sp)
    800064e2:	688a                	ld	a7,128(sp)
    800064e4:	692a                	ld	s2,136(sp)
    800064e6:	69ca                	ld	s3,144(sp)
    800064e8:	6a6a                	ld	s4,152(sp)
    800064ea:	7a8a                	ld	s5,160(sp)
    800064ec:	7b2a                	ld	s6,168(sp)
    800064ee:	7bca                	ld	s7,176(sp)
    800064f0:	7c6a                	ld	s8,184(sp)
    800064f2:	6c8e                	ld	s9,192(sp)
    800064f4:	6d2e                	ld	s10,200(sp)
    800064f6:	6dce                	ld	s11,208(sp)
    800064f8:	6e6e                	ld	t3,216(sp)
    800064fa:	7e8e                	ld	t4,224(sp)
    800064fc:	7f2e                	ld	t5,232(sp)
    800064fe:	7fce                	ld	t6,240(sp)
    80006500:	6111                	addi	sp,sp,256
    80006502:	10200073          	sret
    80006506:	00000013          	nop
    8000650a:	00000013          	nop
    8000650e:	0001                	nop

0000000080006510 <timervec>:
    80006510:	34051573          	csrrw	a0,mscratch,a0
    80006514:	e10c                	sd	a1,0(a0)
    80006516:	e510                	sd	a2,8(a0)
    80006518:	e914                	sd	a3,16(a0)
    8000651a:	6d0c                	ld	a1,24(a0)
    8000651c:	7110                	ld	a2,32(a0)
    8000651e:	6194                	ld	a3,0(a1)
    80006520:	96b2                	add	a3,a3,a2
    80006522:	e194                	sd	a3,0(a1)
    80006524:	4589                	li	a1,2
    80006526:	14459073          	csrw	sip,a1
    8000652a:	6914                	ld	a3,16(a0)
    8000652c:	6510                	ld	a2,8(a0)
    8000652e:	610c                	ld	a1,0(a0)
    80006530:	34051573          	csrrw	a0,mscratch,a0
    80006534:	30200073          	mret
	...

000000008000653a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000653a:	1141                	addi	sp,sp,-16
    8000653c:	e422                	sd	s0,8(sp)
    8000653e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006540:	0c0007b7          	lui	a5,0xc000
    80006544:	4705                	li	a4,1
    80006546:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006548:	c3d8                	sw	a4,4(a5)
}
    8000654a:	6422                	ld	s0,8(sp)
    8000654c:	0141                	addi	sp,sp,16
    8000654e:	8082                	ret

0000000080006550 <plicinithart>:

void
plicinithart(void)
{
    80006550:	1141                	addi	sp,sp,-16
    80006552:	e406                	sd	ra,8(sp)
    80006554:	e022                	sd	s0,0(sp)
    80006556:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	942080e7          	jalr	-1726(ra) # 80001e9a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006560:	0085171b          	slliw	a4,a0,0x8
    80006564:	0c0027b7          	lui	a5,0xc002
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	40200713          	li	a4,1026
    8000656e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006572:	00d5151b          	slliw	a0,a0,0xd
    80006576:	0c2017b7          	lui	a5,0xc201
    8000657a:	953e                	add	a0,a0,a5
    8000657c:	00052023          	sw	zero,0(a0)
}
    80006580:	60a2                	ld	ra,8(sp)
    80006582:	6402                	ld	s0,0(sp)
    80006584:	0141                	addi	sp,sp,16
    80006586:	8082                	ret

0000000080006588 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006588:	1141                	addi	sp,sp,-16
    8000658a:	e406                	sd	ra,8(sp)
    8000658c:	e022                	sd	s0,0(sp)
    8000658e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006590:	ffffc097          	auipc	ra,0xffffc
    80006594:	90a080e7          	jalr	-1782(ra) # 80001e9a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006598:	00d5179b          	slliw	a5,a0,0xd
    8000659c:	0c201537          	lui	a0,0xc201
    800065a0:	953e                	add	a0,a0,a5
  return irq;
}
    800065a2:	4148                	lw	a0,4(a0)
    800065a4:	60a2                	ld	ra,8(sp)
    800065a6:	6402                	ld	s0,0(sp)
    800065a8:	0141                	addi	sp,sp,16
    800065aa:	8082                	ret

00000000800065ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065ac:	1101                	addi	sp,sp,-32
    800065ae:	ec06                	sd	ra,24(sp)
    800065b0:	e822                	sd	s0,16(sp)
    800065b2:	e426                	sd	s1,8(sp)
    800065b4:	1000                	addi	s0,sp,32
    800065b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065b8:	ffffc097          	auipc	ra,0xffffc
    800065bc:	8e2080e7          	jalr	-1822(ra) # 80001e9a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065c0:	00d5151b          	slliw	a0,a0,0xd
    800065c4:	0c2017b7          	lui	a5,0xc201
    800065c8:	97aa                	add	a5,a5,a0
    800065ca:	c3c4                	sw	s1,4(a5)
}
    800065cc:	60e2                	ld	ra,24(sp)
    800065ce:	6442                	ld	s0,16(sp)
    800065d0:	64a2                	ld	s1,8(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret

00000000800065d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065d6:	1141                	addi	sp,sp,-16
    800065d8:	e406                	sd	ra,8(sp)
    800065da:	e022                	sd	s0,0(sp)
    800065dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065de:	479d                	li	a5,7
    800065e0:	06a7c963          	blt	a5,a0,80006652 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800065e4:	0001d797          	auipc	a5,0x1d
    800065e8:	a1c78793          	addi	a5,a5,-1508 # 80023000 <disk>
    800065ec:	00a78733          	add	a4,a5,a0
    800065f0:	6789                	lui	a5,0x2
    800065f2:	97ba                	add	a5,a5,a4
    800065f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800065f8:	e7ad                	bnez	a5,80006662 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800065fa:	00451793          	slli	a5,a0,0x4
    800065fe:	0001f717          	auipc	a4,0x1f
    80006602:	a0270713          	addi	a4,a4,-1534 # 80025000 <disk+0x2000>
    80006606:	6314                	ld	a3,0(a4)
    80006608:	96be                	add	a3,a3,a5
    8000660a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000660e:	6314                	ld	a3,0(a4)
    80006610:	96be                	add	a3,a3,a5
    80006612:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006616:	6314                	ld	a3,0(a4)
    80006618:	96be                	add	a3,a3,a5
    8000661a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000661e:	6318                	ld	a4,0(a4)
    80006620:	97ba                	add	a5,a5,a4
    80006622:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006626:	0001d797          	auipc	a5,0x1d
    8000662a:	9da78793          	addi	a5,a5,-1574 # 80023000 <disk>
    8000662e:	97aa                	add	a5,a5,a0
    80006630:	6509                	lui	a0,0x2
    80006632:	953e                	add	a0,a0,a5
    80006634:	4785                	li	a5,1
    80006636:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	9de50513          	addi	a0,a0,-1570 # 80025018 <disk+0x2018>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	48c080e7          	jalr	1164(ra) # 80002ace <wakeup>
}
    8000664a:	60a2                	ld	ra,8(sp)
    8000664c:	6402                	ld	s0,0(sp)
    8000664e:	0141                	addi	sp,sp,16
    80006650:	8082                	ret
    panic("free_desc 1");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	25650513          	addi	a0,a0,598 # 800088a8 <syscalls+0x338>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ee4080e7          	jalr	-284(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	25650513          	addi	a0,a0,598 # 800088b8 <syscalls+0x348>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080006672 <virtio_disk_init>:
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec06                	sd	ra,24(sp)
    80006676:	e822                	sd	s0,16(sp)
    80006678:	e426                	sd	s1,8(sp)
    8000667a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000667c:	00002597          	auipc	a1,0x2
    80006680:	24c58593          	addi	a1,a1,588 # 800088c8 <syscalls+0x358>
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	aa450513          	addi	a0,a0,-1372 # 80025128 <disk+0x2128>
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	4c8080e7          	jalr	1224(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006694:	100017b7          	lui	a5,0x10001
    80006698:	4398                	lw	a4,0(a5)
    8000669a:	2701                	sext.w	a4,a4
    8000669c:	747277b7          	lui	a5,0x74727
    800066a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066a4:	0ef71163          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066a8:	100017b7          	lui	a5,0x10001
    800066ac:	43dc                	lw	a5,4(a5)
    800066ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066b0:	4705                	li	a4,1
    800066b2:	0ce79a63          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066b6:	100017b7          	lui	a5,0x10001
    800066ba:	479c                	lw	a5,8(a5)
    800066bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066be:	4709                	li	a4,2
    800066c0:	0ce79363          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066c4:	100017b7          	lui	a5,0x10001
    800066c8:	47d8                	lw	a4,12(a5)
    800066ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066cc:	554d47b7          	lui	a5,0x554d4
    800066d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066d4:	0af71963          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	4705                	li	a4,1
    800066de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e0:	470d                	li	a4,3
    800066e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066e6:	c7ffe737          	lui	a4,0xc7ffe
    800066ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800066ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066f0:	2701                	sext.w	a4,a4
    800066f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f4:	472d                	li	a4,11
    800066f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f8:	473d                	li	a4,15
    800066fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800066fc:	6705                	lui	a4,0x1
    800066fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006700:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006704:	5bdc                	lw	a5,52(a5)
    80006706:	2781                	sext.w	a5,a5
  if(max == 0)
    80006708:	c7d9                	beqz	a5,80006796 <virtio_disk_init+0x124>
  if(max < NUM)
    8000670a:	471d                	li	a4,7
    8000670c:	08f77d63          	bgeu	a4,a5,800067a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006710:	100014b7          	lui	s1,0x10001
    80006714:	47a1                	li	a5,8
    80006716:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006718:	6609                	lui	a2,0x2
    8000671a:	4581                	li	a1,0
    8000671c:	0001d517          	auipc	a0,0x1d
    80006720:	8e450513          	addi	a0,a0,-1820 # 80023000 <disk>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	5bc080e7          	jalr	1468(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000672c:	0001d717          	auipc	a4,0x1d
    80006730:	8d470713          	addi	a4,a4,-1836 # 80023000 <disk>
    80006734:	00c75793          	srli	a5,a4,0xc
    80006738:	2781                	sext.w	a5,a5
    8000673a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000673c:	0001f797          	auipc	a5,0x1f
    80006740:	8c478793          	addi	a5,a5,-1852 # 80025000 <disk+0x2000>
    80006744:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006746:	0001d717          	auipc	a4,0x1d
    8000674a:	93a70713          	addi	a4,a4,-1734 # 80023080 <disk+0x80>
    8000674e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006750:	0001e717          	auipc	a4,0x1e
    80006754:	8b070713          	addi	a4,a4,-1872 # 80024000 <disk+0x1000>
    80006758:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000675a:	4705                	li	a4,1
    8000675c:	00e78c23          	sb	a4,24(a5)
    80006760:	00e78ca3          	sb	a4,25(a5)
    80006764:	00e78d23          	sb	a4,26(a5)
    80006768:	00e78da3          	sb	a4,27(a5)
    8000676c:	00e78e23          	sb	a4,28(a5)
    80006770:	00e78ea3          	sb	a4,29(a5)
    80006774:	00e78f23          	sb	a4,30(a5)
    80006778:	00e78fa3          	sb	a4,31(a5)
}
    8000677c:	60e2                	ld	ra,24(sp)
    8000677e:	6442                	ld	s0,16(sp)
    80006780:	64a2                	ld	s1,8(sp)
    80006782:	6105                	addi	sp,sp,32
    80006784:	8082                	ret
    panic("could not find virtio disk");
    80006786:	00002517          	auipc	a0,0x2
    8000678a:	15250513          	addi	a0,a0,338 # 800088d8 <syscalls+0x368>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	16250513          	addi	a0,a0,354 # 800088f8 <syscalls+0x388>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800067a6:	00002517          	auipc	a0,0x2
    800067aa:	17250513          	addi	a0,a0,370 # 80008918 <syscalls+0x3a8>
    800067ae:	ffffa097          	auipc	ra,0xffffa
    800067b2:	d90080e7          	jalr	-624(ra) # 8000053e <panic>

00000000800067b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067b6:	7159                	addi	sp,sp,-112
    800067b8:	f486                	sd	ra,104(sp)
    800067ba:	f0a2                	sd	s0,96(sp)
    800067bc:	eca6                	sd	s1,88(sp)
    800067be:	e8ca                	sd	s2,80(sp)
    800067c0:	e4ce                	sd	s3,72(sp)
    800067c2:	e0d2                	sd	s4,64(sp)
    800067c4:	fc56                	sd	s5,56(sp)
    800067c6:	f85a                	sd	s6,48(sp)
    800067c8:	f45e                	sd	s7,40(sp)
    800067ca:	f062                	sd	s8,32(sp)
    800067cc:	ec66                	sd	s9,24(sp)
    800067ce:	e86a                	sd	s10,16(sp)
    800067d0:	1880                	addi	s0,sp,112
    800067d2:	892a                	mv	s2,a0
    800067d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067d6:	00c52c83          	lw	s9,12(a0)
    800067da:	001c9c9b          	slliw	s9,s9,0x1
    800067de:	1c82                	slli	s9,s9,0x20
    800067e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800067e4:	0001f517          	auipc	a0,0x1f
    800067e8:	94450513          	addi	a0,a0,-1724 # 80025128 <disk+0x2128>
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	3f8080e7          	jalr	1016(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800067f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800067f8:	0001db97          	auipc	s7,0x1d
    800067fc:	808b8b93          	addi	s7,s7,-2040 # 80023000 <disk>
    80006800:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006802:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006804:	8a4e                	mv	s4,s3
    80006806:	a051                	j	8000688a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006808:	00fb86b3          	add	a3,s7,a5
    8000680c:	96da                	add	a3,a3,s6
    8000680e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006812:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006814:	0207c563          	bltz	a5,8000683e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006818:	2485                	addiw	s1,s1,1
    8000681a:	0711                	addi	a4,a4,4
    8000681c:	25548063          	beq	s1,s5,80006a5c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006820:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006822:	0001e697          	auipc	a3,0x1e
    80006826:	7f668693          	addi	a3,a3,2038 # 80025018 <disk+0x2018>
    8000682a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000682c:	0006c583          	lbu	a1,0(a3)
    80006830:	fde1                	bnez	a1,80006808 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006832:	2785                	addiw	a5,a5,1
    80006834:	0685                	addi	a3,a3,1
    80006836:	ff879be3          	bne	a5,s8,8000682c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000683a:	57fd                	li	a5,-1
    8000683c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000683e:	02905a63          	blez	s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006842:	f9042503          	lw	a0,-112(s0)
    80006846:	00000097          	auipc	ra,0x0
    8000684a:	d90080e7          	jalr	-624(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000684e:	4785                	li	a5,1
    80006850:	0297d163          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006854:	f9442503          	lw	a0,-108(s0)
    80006858:	00000097          	auipc	ra,0x0
    8000685c:	d7e080e7          	jalr	-642(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006860:	4789                	li	a5,2
    80006862:	0097d863          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006866:	f9842503          	lw	a0,-104(s0)
    8000686a:	00000097          	auipc	ra,0x0
    8000686e:	d6c080e7          	jalr	-660(ra) # 800065d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006872:	0001f597          	auipc	a1,0x1f
    80006876:	8b658593          	addi	a1,a1,-1866 # 80025128 <disk+0x2128>
    8000687a:	0001e517          	auipc	a0,0x1e
    8000687e:	79e50513          	addi	a0,a0,1950 # 80025018 <disk+0x2018>
    80006882:	ffffc097          	auipc	ra,0xffffc
    80006886:	c20080e7          	jalr	-992(ra) # 800024a2 <sleep>
  for(int i = 0; i < 3; i++){
    8000688a:	f9040713          	addi	a4,s0,-112
    8000688e:	84ce                	mv	s1,s3
    80006890:	bf41                	j	80006820 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006892:	20058713          	addi	a4,a1,512
    80006896:	00471693          	slli	a3,a4,0x4
    8000689a:	0001c717          	auipc	a4,0x1c
    8000689e:	76670713          	addi	a4,a4,1894 # 80023000 <disk>
    800068a2:	9736                	add	a4,a4,a3
    800068a4:	4685                	li	a3,1
    800068a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068aa:	20058713          	addi	a4,a1,512
    800068ae:	00471693          	slli	a3,a4,0x4
    800068b2:	0001c717          	auipc	a4,0x1c
    800068b6:	74e70713          	addi	a4,a4,1870 # 80023000 <disk>
    800068ba:	9736                	add	a4,a4,a3
    800068bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800068c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c4:	7679                	lui	a2,0xffffe
    800068c6:	963e                	add	a2,a2,a5
    800068c8:	0001e697          	auipc	a3,0x1e
    800068cc:	73868693          	addi	a3,a3,1848 # 80025000 <disk+0x2000>
    800068d0:	6298                	ld	a4,0(a3)
    800068d2:	9732                	add	a4,a4,a2
    800068d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068d6:	6298                	ld	a4,0(a3)
    800068d8:	9732                	add	a4,a4,a2
    800068da:	4541                	li	a0,16
    800068dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068de:	6298                	ld	a4,0(a3)
    800068e0:	9732                	add	a4,a4,a2
    800068e2:	4505                	li	a0,1
    800068e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800068e8:	f9442703          	lw	a4,-108(s0)
    800068ec:	6288                	ld	a0,0(a3)
    800068ee:	962a                	add	a2,a2,a0
    800068f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068f4:	0712                	slli	a4,a4,0x4
    800068f6:	6290                	ld	a2,0(a3)
    800068f8:	963a                	add	a2,a2,a4
    800068fa:	05890513          	addi	a0,s2,88
    800068fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006900:	6294                	ld	a3,0(a3)
    80006902:	96ba                	add	a3,a3,a4
    80006904:	40000613          	li	a2,1024
    80006908:	c690                	sw	a2,8(a3)
  if(write)
    8000690a:	140d0063          	beqz	s10,80006a4a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000690e:	0001e697          	auipc	a3,0x1e
    80006912:	6f26b683          	ld	a3,1778(a3) # 80025000 <disk+0x2000>
    80006916:	96ba                	add	a3,a3,a4
    80006918:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000691c:	0001c817          	auipc	a6,0x1c
    80006920:	6e480813          	addi	a6,a6,1764 # 80023000 <disk>
    80006924:	0001e517          	auipc	a0,0x1e
    80006928:	6dc50513          	addi	a0,a0,1756 # 80025000 <disk+0x2000>
    8000692c:	6114                	ld	a3,0(a0)
    8000692e:	96ba                	add	a3,a3,a4
    80006930:	00c6d603          	lhu	a2,12(a3)
    80006934:	00166613          	ori	a2,a2,1
    80006938:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000693c:	f9842683          	lw	a3,-104(s0)
    80006940:	6110                	ld	a2,0(a0)
    80006942:	9732                	add	a4,a4,a2
    80006944:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006948:	20058613          	addi	a2,a1,512
    8000694c:	0612                	slli	a2,a2,0x4
    8000694e:	9642                	add	a2,a2,a6
    80006950:	577d                	li	a4,-1
    80006952:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006956:	00469713          	slli	a4,a3,0x4
    8000695a:	6114                	ld	a3,0(a0)
    8000695c:	96ba                	add	a3,a3,a4
    8000695e:	03078793          	addi	a5,a5,48
    80006962:	97c2                	add	a5,a5,a6
    80006964:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006966:	611c                	ld	a5,0(a0)
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	4685                	li	a3,1
    8000696c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000696e:	611c                	ld	a5,0(a0)
    80006970:	97ba                	add	a5,a5,a4
    80006972:	4809                	li	a6,2
    80006974:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006978:	611c                	ld	a5,0(a0)
    8000697a:	973e                	add	a4,a4,a5
    8000697c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006980:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006984:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006988:	6518                	ld	a4,8(a0)
    8000698a:	00275783          	lhu	a5,2(a4)
    8000698e:	8b9d                	andi	a5,a5,7
    80006990:	0786                	slli	a5,a5,0x1
    80006992:	97ba                	add	a5,a5,a4
    80006994:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006998:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000699c:	6518                	ld	a4,8(a0)
    8000699e:	00275783          	lhu	a5,2(a4)
    800069a2:	2785                	addiw	a5,a5,1
    800069a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069ac:	100017b7          	lui	a5,0x10001
    800069b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069b4:	00492703          	lw	a4,4(s2)
    800069b8:	4785                	li	a5,1
    800069ba:	02f71163          	bne	a4,a5,800069dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800069be:	0001e997          	auipc	s3,0x1e
    800069c2:	76a98993          	addi	s3,s3,1898 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800069c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800069c8:	85ce                	mv	a1,s3
    800069ca:	854a                	mv	a0,s2
    800069cc:	ffffc097          	auipc	ra,0xffffc
    800069d0:	ad6080e7          	jalr	-1322(ra) # 800024a2 <sleep>
  while(b->disk == 1) {
    800069d4:	00492783          	lw	a5,4(s2)
    800069d8:	fe9788e3          	beq	a5,s1,800069c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800069dc:	f9042903          	lw	s2,-112(s0)
    800069e0:	20090793          	addi	a5,s2,512
    800069e4:	00479713          	slli	a4,a5,0x4
    800069e8:	0001c797          	auipc	a5,0x1c
    800069ec:	61878793          	addi	a5,a5,1560 # 80023000 <disk>
    800069f0:	97ba                	add	a5,a5,a4
    800069f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800069f6:	0001e997          	auipc	s3,0x1e
    800069fa:	60a98993          	addi	s3,s3,1546 # 80025000 <disk+0x2000>
    800069fe:	00491713          	slli	a4,s2,0x4
    80006a02:	0009b783          	ld	a5,0(s3)
    80006a06:	97ba                	add	a5,a5,a4
    80006a08:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a0c:	854a                	mv	a0,s2
    80006a0e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a12:	00000097          	auipc	ra,0x0
    80006a16:	bc4080e7          	jalr	-1084(ra) # 800065d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a1a:	8885                	andi	s1,s1,1
    80006a1c:	f0ed                	bnez	s1,800069fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a1e:	0001e517          	auipc	a0,0x1e
    80006a22:	70a50513          	addi	a0,a0,1802 # 80025128 <disk+0x2128>
    80006a26:	ffffa097          	auipc	ra,0xffffa
    80006a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
}
    80006a2e:	70a6                	ld	ra,104(sp)
    80006a30:	7406                	ld	s0,96(sp)
    80006a32:	64e6                	ld	s1,88(sp)
    80006a34:	6946                	ld	s2,80(sp)
    80006a36:	69a6                	ld	s3,72(sp)
    80006a38:	6a06                	ld	s4,64(sp)
    80006a3a:	7ae2                	ld	s5,56(sp)
    80006a3c:	7b42                	ld	s6,48(sp)
    80006a3e:	7ba2                	ld	s7,40(sp)
    80006a40:	7c02                	ld	s8,32(sp)
    80006a42:	6ce2                	ld	s9,24(sp)
    80006a44:	6d42                	ld	s10,16(sp)
    80006a46:	6165                	addi	sp,sp,112
    80006a48:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a4a:	0001e697          	auipc	a3,0x1e
    80006a4e:	5b66b683          	ld	a3,1462(a3) # 80025000 <disk+0x2000>
    80006a52:	96ba                	add	a3,a3,a4
    80006a54:	4609                	li	a2,2
    80006a56:	00c69623          	sh	a2,12(a3)
    80006a5a:	b5c9                	j	8000691c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a5c:	f9042583          	lw	a1,-112(s0)
    80006a60:	20058793          	addi	a5,a1,512
    80006a64:	0792                	slli	a5,a5,0x4
    80006a66:	0001c517          	auipc	a0,0x1c
    80006a6a:	64250513          	addi	a0,a0,1602 # 800230a8 <disk+0xa8>
    80006a6e:	953e                	add	a0,a0,a5
  if(write)
    80006a70:	e20d11e3          	bnez	s10,80006892 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a74:	20058713          	addi	a4,a1,512
    80006a78:	00471693          	slli	a3,a4,0x4
    80006a7c:	0001c717          	auipc	a4,0x1c
    80006a80:	58470713          	addi	a4,a4,1412 # 80023000 <disk>
    80006a84:	9736                	add	a4,a4,a3
    80006a86:	0a072423          	sw	zero,168(a4)
    80006a8a:	b505                	j	800068aa <virtio_disk_rw+0xf4>

0000000080006a8c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a8c:	1101                	addi	sp,sp,-32
    80006a8e:	ec06                	sd	ra,24(sp)
    80006a90:	e822                	sd	s0,16(sp)
    80006a92:	e426                	sd	s1,8(sp)
    80006a94:	e04a                	sd	s2,0(sp)
    80006a96:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a98:	0001e517          	auipc	a0,0x1e
    80006a9c:	69050513          	addi	a0,a0,1680 # 80025128 <disk+0x2128>
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006aa8:	10001737          	lui	a4,0x10001
    80006aac:	533c                	lw	a5,96(a4)
    80006aae:	8b8d                	andi	a5,a5,3
    80006ab0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ab2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ab6:	0001e797          	auipc	a5,0x1e
    80006aba:	54a78793          	addi	a5,a5,1354 # 80025000 <disk+0x2000>
    80006abe:	6b94                	ld	a3,16(a5)
    80006ac0:	0207d703          	lhu	a4,32(a5)
    80006ac4:	0026d783          	lhu	a5,2(a3)
    80006ac8:	06f70163          	beq	a4,a5,80006b2a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006acc:	0001c917          	auipc	s2,0x1c
    80006ad0:	53490913          	addi	s2,s2,1332 # 80023000 <disk>
    80006ad4:	0001e497          	auipc	s1,0x1e
    80006ad8:	52c48493          	addi	s1,s1,1324 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006adc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ae0:	6898                	ld	a4,16(s1)
    80006ae2:	0204d783          	lhu	a5,32(s1)
    80006ae6:	8b9d                	andi	a5,a5,7
    80006ae8:	078e                	slli	a5,a5,0x3
    80006aea:	97ba                	add	a5,a5,a4
    80006aec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006aee:	20078713          	addi	a4,a5,512
    80006af2:	0712                	slli	a4,a4,0x4
    80006af4:	974a                	add	a4,a4,s2
    80006af6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006afa:	e731                	bnez	a4,80006b46 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006afc:	20078793          	addi	a5,a5,512
    80006b00:	0792                	slli	a5,a5,0x4
    80006b02:	97ca                	add	a5,a5,s2
    80006b04:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b06:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b0a:	ffffc097          	auipc	ra,0xffffc
    80006b0e:	fc4080e7          	jalr	-60(ra) # 80002ace <wakeup>

    disk.used_idx += 1;
    80006b12:	0204d783          	lhu	a5,32(s1)
    80006b16:	2785                	addiw	a5,a5,1
    80006b18:	17c2                	slli	a5,a5,0x30
    80006b1a:	93c1                	srli	a5,a5,0x30
    80006b1c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b20:	6898                	ld	a4,16(s1)
    80006b22:	00275703          	lhu	a4,2(a4)
    80006b26:	faf71be3          	bne	a4,a5,80006adc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b2a:	0001e517          	auipc	a0,0x1e
    80006b2e:	5fe50513          	addi	a0,a0,1534 # 80025128 <disk+0x2128>
    80006b32:	ffffa097          	auipc	ra,0xffffa
    80006b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
}
    80006b3a:	60e2                	ld	ra,24(sp)
    80006b3c:	6442                	ld	s0,16(sp)
    80006b3e:	64a2                	ld	s1,8(sp)
    80006b40:	6902                	ld	s2,0(sp)
    80006b42:	6105                	addi	sp,sp,32
    80006b44:	8082                	ret
      panic("virtio_disk_intr status");
    80006b46:	00002517          	auipc	a0,0x2
    80006b4a:	df250513          	addi	a0,a0,-526 # 80008938 <syscalls+0x3c8>
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>

0000000080006b56 <cas>:
    80006b56:	100522af          	lr.w	t0,(a0)
    80006b5a:	00b29563          	bne	t0,a1,80006b64 <fail>
    80006b5e:	18c5252f          	sc.w	a0,a2,(a0)
    80006b62:	8082                	ret

0000000080006b64 <fail>:
    80006b64:	4505                	li	a0,1
    80006b66:	8082                	ret
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
