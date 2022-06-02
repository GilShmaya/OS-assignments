
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a4013103          	ld	sp,-1472(sp) # 80008a40 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	51c78793          	addi	a5,a5,1308 # 80006580 <timervec>
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
    80000130:	75a080e7          	jalr	1882(ra) # 80002886 <either_copyin>
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
    800001c8:	d82080e7          	jalr	-638(ra) # 80001f46 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	41a080e7          	jalr	1050(ra) # 800025ee <sleep>
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
    80000214:	620080e7          	jalr	1568(ra) # 80002830 <either_copyout>
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
    800002f6:	5ea080e7          	jalr	1514(ra) # 800028dc <procdump>
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
    8000044a:	7d2080e7          	jalr	2002(ra) # 80002c18 <wakeup>
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
    800008a4:	378080e7          	jalr	888(ra) # 80002c18 <wakeup>
    
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
    80000930:	cc2080e7          	jalr	-830(ra) # 800025ee <sleep>
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
    80000b82:	3a6080e7          	jalr	934(ra) # 80001f24 <mycpu>
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
    80000bb4:	374080e7          	jalr	884(ra) # 80001f24 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	368080e7          	jalr	872(ra) # 80001f24 <mycpu>
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
    80000bd8:	350080e7          	jalr	848(ra) # 80001f24 <mycpu>
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
    80000c18:	310080e7          	jalr	784(ra) # 80001f24 <mycpu>
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
    80000c44:	2e4080e7          	jalr	740(ra) # 80001f24 <mycpu>
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
    80000e9a:	07e080e7          	jalr	126(ra) # 80001f14 <cpuid>
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
    80000eb6:	062080e7          	jalr	98(ra) # 80001f14 <cpuid>
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
    80000ed8:	110080e7          	jalr	272(ra) # 80002fe4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	6e4080e7          	jalr	1764(ra) # 800065c0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	4f6080e7          	jalr	1270(ra) # 800023da <scheduler>
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
    80000f48:	ece080e7          	jalr	-306(ra) # 80001e12 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	070080e7          	jalr	112(ra) # 80002fbc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	090080e7          	jalr	144(ra) # 80002fe4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	64e080e7          	jalr	1614(ra) # 800065aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	65c080e7          	jalr	1628(ra) # 800065c0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	836080e7          	jalr	-1994(ra) # 800037a2 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	ec6080e7          	jalr	-314(ra) # 80003e3a <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	e70080e7          	jalr	-400(ra) # 80004dec <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	75e080e7          	jalr	1886(ra) # 800066e2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	346080e7          	jalr	838(ra) # 800022d2 <userinit>
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
    80001244:	b3c080e7          	jalr	-1220(ra) # 80001d7c <proc_mapstacks>
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
    800018f0:	7139                	addi	sp,sp,-64
    800018f2:	fc06                	sd	ra,56(sp)
    800018f4:	f822                	sd	s0,48(sp)
    800018f6:	f426                	sd	s1,40(sp)
    800018f8:	f04a                	sd	s2,32(sp)
    800018fa:	ec4e                	sd	s3,24(sp)
    800018fc:	e852                	sd	s4,16(sp)
    800018fe:	e456                	sd	s5,8(sp)
    80001900:	0080                	addi	s0,sp,64
  struct cpu *c;
  int i = 0;
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    c->runnable_list = (struct _list){-1};
    80001902:	00010497          	auipc	s1,0x10
    80001906:	99e48493          	addi	s1,s1,-1634 # 800112a0 <cpus>
    8000190a:	0804b023          	sd	zero,128(s1)
    8000190e:	0804b423          	sd	zero,136(s1)
    80001912:	0804b823          	sd	zero,144(s1)
    80001916:	0804bc23          	sd	zero,152(s1)
    8000191a:	57fd                	li	a5,-1
    8000191c:	08f4a023          	sw	a5,128(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    80001920:	00007597          	auipc	a1,0x7
    80001924:	8d058593          	addi	a1,a1,-1840 # 800081f0 <digits+0x1b0>
    80001928:	00010517          	auipc	a0,0x10
    8000192c:	a0050513          	addi	a0,a0,-1536 # 80011328 <cpus+0x88>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	224080e7          	jalr	548(ra) # 80000b54 <initlock>
    c->cpu_id = i;
    80001938:	0a04a023          	sw	zero,160(s1)
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    8000193c:	00010497          	auipc	s1,0x10
    80001940:	a1448493          	addi	s1,s1,-1516 # 80011350 <cpus+0xb0>
    i++;
    80001944:	4905                	li	s2,1
    c->runnable_list = (struct _list){-1};
    80001946:	5afd                	li	s5,-1
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    80001948:	00007a17          	auipc	s4,0x7
    8000194c:	8a8a0a13          	addi	s4,s4,-1880 # 800081f0 <digits+0x1b0>
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    80001950:	4995                	li	s3,5
    c->runnable_list = (struct _list){-1};
    80001952:	0804b023          	sd	zero,128(s1)
    80001956:	0804b423          	sd	zero,136(s1)
    8000195a:	0804b823          	sd	zero,144(s1)
    8000195e:	0804bc23          	sd	zero,152(s1)
    80001962:	0954a023          	sw	s5,128(s1)
    initlock(&c->runnable_list.head_lock, "cpu_runnable_list - head lock");
    80001966:	85d2                	mv	a1,s4
    80001968:	08848513          	addi	a0,s1,136
    8000196c:	fffff097          	auipc	ra,0xfffff
    80001970:	1e8080e7          	jalr	488(ra) # 80000b54 <initlock>
    c->cpu_id = i;
    80001974:	0b24a023          	sw	s2,160(s1)
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    80001978:	0b048493          	addi	s1,s1,176
    i++;
    8000197c:	2905                	addiw	s2,s2,1
  for(c = cpus; c < &cpus[NCPU] && i < CPUS ; c++){
    8000197e:	fd391ae3          	bne	s2,s3,80001952 <initialize_lists+0x62>
  }
  initlock(&unused_list.head_lock, "unused_list - head lock");
    80001982:	00007597          	auipc	a1,0x7
    80001986:	88e58593          	addi	a1,a1,-1906 # 80008210 <digits+0x1d0>
    8000198a:	00007517          	auipc	a0,0x7
    8000198e:	01e50513          	addi	a0,a0,30 # 800089a8 <unused_list+0x8>
    80001992:	fffff097          	auipc	ra,0xfffff
    80001996:	1c2080e7          	jalr	450(ra) # 80000b54 <initlock>
  initlock(&sleeping_list.head_lock, "sleeping_list - head lock");
    8000199a:	00007597          	auipc	a1,0x7
    8000199e:	88e58593          	addi	a1,a1,-1906 # 80008228 <digits+0x1e8>
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	02650513          	addi	a0,a0,38 # 800089c8 <sleeping_list+0x8>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1aa080e7          	jalr	426(ra) # 80000b54 <initlock>
  initlock(&zombie_list.head_lock, "zombie_list - head lock");
    800019b2:	00007597          	auipc	a1,0x7
    800019b6:	89658593          	addi	a1,a1,-1898 # 80008248 <digits+0x208>
    800019ba:	00007517          	auipc	a0,0x7
    800019be:	02e50513          	addi	a0,a0,46 # 800089e8 <zombie_list+0x8>
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	192080e7          	jalr	402(ra) # 80000b54 <initlock>
}
    800019ca:	70e2                	ld	ra,56(sp)
    800019cc:	7442                	ld	s0,48(sp)
    800019ce:	74a2                	ld	s1,40(sp)
    800019d0:	7902                	ld	s2,32(sp)
    800019d2:	69e2                	ld	s3,24(sp)
    800019d4:	6a42                	ld	s4,16(sp)
    800019d6:	6aa2                	ld	s5,8(sp)
    800019d8:	6121                	addi	sp,sp,64
    800019da:	8082                	ret

00000000800019dc <initialize_proc>:

void
initialize_proc(struct proc *p){
    800019dc:	1141                	addi	sp,sp,-16
    800019de:	e422                	sd	s0,8(sp)
    800019e0:	0800                	addi	s0,sp,16
  p->next_index = -1;
    800019e2:	57fd                	li	a5,-1
    800019e4:	16f52a23          	sw	a5,372(a0)
  p->prev_index = -1;
    800019e8:	16f52823          	sw	a5,368(a0)
}
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <isEmpty>:

int
isEmpty(struct _list *lst){
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e422                	sd	s0,8(sp)
    800019f6:	0800                	addi	s0,sp,16
  return lst->head == -1;
    800019f8:	4108                	lw	a0,0(a0)
    800019fa:	0505                	addi	a0,a0,1
}
    800019fc:	00153513          	seqz	a0,a0
    80001a00:	6422                	ld	s0,8(sp)
    80001a02:	0141                	addi	sp,sp,16
    80001a04:	8082                	ret

0000000080001a06 <get_head>:

int 
get_head(struct _list *lst){
    80001a06:	1101                	addi	sp,sp,-32
    80001a08:	ec06                	sd	ra,24(sp)
    80001a0a:	e822                	sd	s0,16(sp)
    80001a0c:	e426                	sd	s1,8(sp)
    80001a0e:	e04a                	sd	s2,0(sp)
    80001a10:	1000                	addi	s0,sp,32
    80001a12:	84aa                	mv	s1,a0
  acquire(&lst->head_lock); 
    80001a14:	00850913          	addi	s2,a0,8
    80001a18:	854a                	mv	a0,s2
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	1ca080e7          	jalr	458(ra) # 80000be4 <acquire>
  int output = lst->head;
    80001a22:	4084                	lw	s1,0(s1)
  release(&lst->head_lock);
    80001a24:	854a                	mv	a0,s2
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>
  return output;
}
    80001a2e:	8526                	mv	a0,s1
    80001a30:	60e2                	ld	ra,24(sp)
    80001a32:	6442                	ld	s0,16(sp)
    80001a34:	64a2                	ld	s1,8(sp)
    80001a36:	6902                	ld	s2,0(sp)
    80001a38:	6105                	addi	sp,sp,32
    80001a3a:	8082                	ret

0000000080001a3c <set_prev_proc>:

void set_prev_proc(struct proc *p, int value){
    80001a3c:	1141                	addi	sp,sp,-16
    80001a3e:	e422                	sd	s0,8(sp)
    80001a40:	0800                	addi	s0,sp,16
  p->prev_index = value; 
    80001a42:	16b52823          	sw	a1,368(a0)
}
    80001a46:	6422                	ld	s0,8(sp)
    80001a48:	0141                	addi	sp,sp,16
    80001a4a:	8082                	ret

0000000080001a4c <set_next_proc>:

void set_next_proc(struct proc *p, int value){
    80001a4c:	1141                	addi	sp,sp,-16
    80001a4e:	e422                	sd	s0,8(sp)
    80001a50:	0800                	addi	s0,sp,16
  p->next_index = value; 
    80001a52:	16b52a23          	sw	a1,372(a0)
}
    80001a56:	6422                	ld	s0,8(sp)
    80001a58:	0141                	addi	sp,sp,16
    80001a5a:	8082                	ret

0000000080001a5c <insert_proc_to_list>:

int 
insert_proc_to_list(struct _list *lst, struct proc *p){
    80001a5c:	7139                	addi	sp,sp,-64
    80001a5e:	fc06                	sd	ra,56(sp)
    80001a60:	f822                	sd	s0,48(sp)
    80001a62:	f426                	sd	s1,40(sp)
    80001a64:	f04a                	sd	s2,32(sp)
    80001a66:	ec4e                	sd	s3,24(sp)
    80001a68:	e852                	sd	s4,16(sp)
    80001a6a:	e456                	sd	s5,8(sp)
    80001a6c:	0080                	addi	s0,sp,64
    80001a6e:	84aa                	mv	s1,a0
    80001a70:	8a2e                	mv	s4,a1
  acquire(&lst->head_lock);
    80001a72:	00850913          	addi	s2,a0,8
    80001a76:	854a                	mv	a0,s2
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	16c080e7          	jalr	364(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001a80:	4088                	lw	a0,0(s1)
  if(isEmpty(lst)){
    80001a82:	57fd                	li	a5,-1
    80001a84:	02f51063          	bne	a0,a5,80001aa4 <insert_proc_to_list+0x48>
    lst->head = p->index;
    80001a88:	16ca2783          	lw	a5,364(s4)
    80001a8c:	c09c                	sw	a5,0(s1)
  p->next_index = -1;
    80001a8e:	57fd                	li	a5,-1
    80001a90:	16fa2a23          	sw	a5,372(s4)
  p->prev_index = -1;
    80001a94:	16fa2823          	sw	a5,368(s4)
    initialize_proc(p);
    release(&lst->head_lock);
    80001a98:	854a                	mv	a0,s2
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
    80001aa2:	a849                	j	80001b34 <insert_proc_to_list+0xd8>
  }
  else{ 
    struct proc *curr = &proc[lst->head];
    80001aa4:	19000793          	li	a5,400
    80001aa8:	02f50533          	mul	a0,a0,a5
    80001aac:	00010797          	auipc	a5,0x10
    80001ab0:	da478793          	addi	a5,a5,-604 # 80011850 <proc>
    80001ab4:	00f504b3          	add	s1,a0,a5
    acquire(&curr->node_lock);
    80001ab8:	17850513          	addi	a0,a0,376
    80001abc:	953e                	add	a0,a0,a5
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	126080e7          	jalr	294(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001ac6:	854a                	mv	a0,s2
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
    while(curr->next_index != -1){ // search tail
    80001ad0:	1744a503          	lw	a0,372(s1)
    80001ad4:	57fd                	li	a5,-1
    80001ad6:	04f50163          	beq	a0,a5,80001b18 <insert_proc_to_list+0xbc>
      acquire(&proc[curr->next_index].node_lock);
    80001ada:	19000993          	li	s3,400
    80001ade:	00010917          	auipc	s2,0x10
    80001ae2:	d7290913          	addi	s2,s2,-654 # 80011850 <proc>
    while(curr->next_index != -1){ // search tail
    80001ae6:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001ae8:	03350533          	mul	a0,a0,s3
    80001aec:	17850513          	addi	a0,a0,376
    80001af0:	954a                	add	a0,a0,s2
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	0f2080e7          	jalr	242(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001afa:	17848513          	addi	a0,s1,376
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	19a080e7          	jalr	410(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001b06:	1744a483          	lw	s1,372(s1)
    80001b0a:	033484b3          	mul	s1,s1,s3
    80001b0e:	94ca                	add	s1,s1,s2
    while(curr->next_index != -1){ // search tail
    80001b10:	1744a503          	lw	a0,372(s1)
    80001b14:	fd551ae3          	bne	a0,s5,80001ae8 <insert_proc_to_list+0x8c>
    }
    set_next_proc(curr, p->index);  // update next proc of the curr tail
    80001b18:	16ca2783          	lw	a5,364(s4)
  p->next_index = value; 
    80001b1c:	16f4aa23          	sw	a5,372(s1)
    set_prev_proc(p, curr->index); // update the prev proc of the new proc
    80001b20:	16c4a783          	lw	a5,364(s1)
  p->prev_index = value; 
    80001b24:	16fa2823          	sw	a5,368(s4)
    release(&curr->node_lock);
    80001b28:	17848513          	addi	a0,s1,376
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	16c080e7          	jalr	364(ra) # 80000c98 <release>
  }
  return 1; 
}
    80001b34:	4505                	li	a0,1
    80001b36:	70e2                	ld	ra,56(sp)
    80001b38:	7442                	ld	s0,48(sp)
    80001b3a:	74a2                	ld	s1,40(sp)
    80001b3c:	7902                	ld	s2,32(sp)
    80001b3e:	69e2                	ld	s3,24(sp)
    80001b40:	6a42                	ld	s4,16(sp)
    80001b42:	6aa2                	ld	s5,8(sp)
    80001b44:	6121                	addi	sp,sp,64
    80001b46:	8082                	ret

0000000080001b48 <remove_head_from_list>:

int 
remove_head_from_list(struct _list *lst){
    80001b48:	7139                	addi	sp,sp,-64
    80001b4a:	fc06                	sd	ra,56(sp)
    80001b4c:	f822                	sd	s0,48(sp)
    80001b4e:	f426                	sd	s1,40(sp)
    80001b50:	f04a                	sd	s2,32(sp)
    80001b52:	ec4e                	sd	s3,24(sp)
    80001b54:	e852                	sd	s4,16(sp)
    80001b56:	e456                	sd	s5,8(sp)
    80001b58:	0080                	addi	s0,sp,64
  return lst->head == -1;
    80001b5a:	00052903          	lw	s2,0(a0)
  if(isEmpty(lst)){
    80001b5e:	57fd                	li	a5,-1
    80001b60:	06f90763          	beq	s2,a5,80001bce <remove_head_from_list+0x86>
    80001b64:	84aa                	mv	s1,a0
    printf("Fails in removing the head from the list: the list is empty\n");
    return 0;
  }
  struct proc *p_head = &proc[lst->head];
  acquire(&p_head->node_lock);
    80001b66:	19000a13          	li	s4,400
    80001b6a:	03490ab3          	mul	s5,s2,s4
    80001b6e:	178a8993          	addi	s3,s5,376
    80001b72:	00010a17          	auipc	s4,0x10
    80001b76:	cdea0a13          	addi	s4,s4,-802 # 80011850 <proc>
    80001b7a:	99d2                	add	s3,s3,s4
    80001b7c:	854e                	mv	a0,s3
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	066080e7          	jalr	102(ra) # 80000be4 <acquire>
  lst->head = p_head->next_index;
    80001b86:	9a56                	add	s4,s4,s5
    80001b88:	174a2783          	lw	a5,372(s4)
    80001b8c:	c09c                	sw	a5,0(s1)
  if(lst->head != -1){
    80001b8e:	577d                	li	a4,-1
    80001b90:	04e79963          	bne	a5,a4,80001be2 <remove_head_from_list+0x9a>
  p->next_index = -1;
    80001b94:	19000793          	li	a5,400
    80001b98:	02f90933          	mul	s2,s2,a5
    80001b9c:	00010797          	auipc	a5,0x10
    80001ba0:	cb478793          	addi	a5,a5,-844 # 80011850 <proc>
    80001ba4:	993e                	add	s2,s2,a5
    80001ba6:	57fd                	li	a5,-1
    80001ba8:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001bac:	16f92823          	sw	a5,368(s2)
    set_prev_proc(&proc[p_head->next_index], -1);
  }
  initialize_proc(p_head);
  release(&p_head->node_lock);
    80001bb0:	854e                	mv	a0,s3
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>

  return 1;
    80001bba:	4505                	li	a0,1
}
    80001bbc:	70e2                	ld	ra,56(sp)
    80001bbe:	7442                	ld	s0,48(sp)
    80001bc0:	74a2                	ld	s1,40(sp)
    80001bc2:	7902                	ld	s2,32(sp)
    80001bc4:	69e2                	ld	s3,24(sp)
    80001bc6:	6a42                	ld	s4,16(sp)
    80001bc8:	6aa2                	ld	s5,8(sp)
    80001bca:	6121                	addi	sp,sp,64
    80001bcc:	8082                	ret
    printf("Fails in removing the head from the list: the list is empty\n");
    80001bce:	00006517          	auipc	a0,0x6
    80001bd2:	69250513          	addi	a0,a0,1682 # 80008260 <digits+0x220>
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	9b2080e7          	jalr	-1614(ra) # 80000588 <printf>
    return 0;
    80001bde:	4501                	li	a0,0
    80001be0:	bff1                	j	80001bbc <remove_head_from_list+0x74>
  p->prev_index = value; 
    80001be2:	19000713          	li	a4,400
    80001be6:	02e787b3          	mul	a5,a5,a4
    80001bea:	00010717          	auipc	a4,0x10
    80001bee:	c6670713          	addi	a4,a4,-922 # 80011850 <proc>
    80001bf2:	97ba                	add	a5,a5,a4
    80001bf4:	577d                	li	a4,-1
    80001bf6:	16e7a823          	sw	a4,368(a5)
}
    80001bfa:	bf69                	j	80001b94 <remove_head_from_list+0x4c>

0000000080001bfc <remove_proc_to_list>:

int
remove_proc_to_list(struct _list *lst, struct proc *p){
    80001bfc:	7139                	addi	sp,sp,-64
    80001bfe:	fc06                	sd	ra,56(sp)
    80001c00:	f822                	sd	s0,48(sp)
    80001c02:	f426                	sd	s1,40(sp)
    80001c04:	f04a                	sd	s2,32(sp)
    80001c06:	ec4e                	sd	s3,24(sp)
    80001c08:	e852                	sd	s4,16(sp)
    80001c0a:	e456                	sd	s5,8(sp)
    80001c0c:	e05a                	sd	s6,0(sp)
    80001c0e:	0080                	addi	s0,sp,64
    80001c10:	84aa                	mv	s1,a0
    80001c12:	892e                	mv	s2,a1
  acquire(&lst->head_lock);
    80001c14:	00850b13          	addi	s6,a0,8
    80001c18:	855a                	mv	a0,s6
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fca080e7          	jalr	-54(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80001c22:	409c                	lw	a5,0(s1)
  if(isEmpty(lst)){
    80001c24:	577d                	li	a4,-1
    80001c26:	0ee78163          	beq	a5,a4,80001d08 <remove_proc_to_list+0x10c>
    printf("Fails in removing the process from the list: the list is empty\n");
    release(&lst->head_lock);
    return 0;
  }

  if(lst->head == p->index){ // the required proc is the head
    80001c2a:	16c92703          	lw	a4,364(s2)
    80001c2e:	0ef70c63          	beq	a4,a5,80001d26 <remove_proc_to_list+0x12a>
   remove_head_from_list(lst);
   release(&lst->head_lock);
  }
  else{
    struct proc *curr = &proc[lst->head];
    80001c32:	19000513          	li	a0,400
    80001c36:	02a787b3          	mul	a5,a5,a0
    80001c3a:	00010517          	auipc	a0,0x10
    80001c3e:	c1650513          	addi	a0,a0,-1002 # 80011850 <proc>
    80001c42:	00a784b3          	add	s1,a5,a0
    acquire(&curr->node_lock);
    80001c46:	17878793          	addi	a5,a5,376
    80001c4a:	953e                	add	a0,a0,a5
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	f98080e7          	jalr	-104(ra) # 80000be4 <acquire>
    release(&lst->head_lock);
    80001c54:	855a                	mv	a0,s6
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c5e:	1744a503          	lw	a0,372(s1)
    80001c62:	16c92783          	lw	a5,364(s2)
    80001c66:	5afd                	li	s5,-1
      acquire(&proc[curr->next_index].node_lock);
    80001c68:	19000a13          	li	s4,400
    80001c6c:	00010997          	auipc	s3,0x10
    80001c70:	be498993          	addi	s3,s3,-1052 # 80011850 <proc>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001c74:	0ca78563          	beq	a5,a0,80001d3e <remove_proc_to_list+0x142>
    80001c78:	0d550563          	beq	a0,s5,80001d42 <remove_proc_to_list+0x146>
      acquire(&proc[curr->next_index].node_lock);
    80001c7c:	03450533          	mul	a0,a0,s4
    80001c80:	17850513          	addi	a0,a0,376
    80001c84:	954e                	add	a0,a0,s3
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	f5e080e7          	jalr	-162(ra) # 80000be4 <acquire>
      release(&curr->node_lock);
    80001c8e:	17848513          	addi	a0,s1,376
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
      curr = &proc[curr->next_index];
    80001c9a:	1744a483          	lw	s1,372(s1)
    80001c9e:	034484b3          	mul	s1,s1,s4
    80001ca2:	94ce                	add	s1,s1,s3
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001ca4:	1744a503          	lw	a0,372(s1)
    80001ca8:	16c92783          	lw	a5,364(s2)
    80001cac:	fcf516e3          	bne	a0,a5,80001c78 <remove_proc_to_list+0x7c>
    }
    if(curr->next_index == -1){
    80001cb0:	577d                	li	a4,-1
    80001cb2:	08e78863          	beq	a5,a4,80001d42 <remove_proc_to_list+0x146>
      printf("Fails in removing the process from the list: process is not found in the list\n");
      release(&lst->head_lock);
      return 0;
    }
    acquire(&p->node_lock); // curr is p->prev
    80001cb6:	17890993          	addi	s3,s2,376
    80001cba:	854e                	mv	a0,s3
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	f28080e7          	jalr	-216(ra) # 80000be4 <acquire>
    set_next_proc(curr, p->next_index);
    80001cc4:	17492783          	lw	a5,372(s2)
  p->next_index = value; 
    80001cc8:	16f4aa23          	sw	a5,372(s1)
    if(p->next_index != -1)
    80001ccc:	577d                	li	a4,-1
    80001cce:	08e79963          	bne	a5,a4,80001d60 <remove_proc_to_list+0x164>
  p->next_index = -1;
    80001cd2:	57fd                	li	a5,-1
    80001cd4:	16f92a23          	sw	a5,372(s2)
  p->prev_index = -1;
    80001cd8:	16f92823          	sw	a5,368(s2)
      set_prev_proc(&proc[p->next_index], curr->index);
    initialize_proc(p);
    release(&p->node_lock);
    80001cdc:	854e                	mv	a0,s3
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	fba080e7          	jalr	-70(ra) # 80000c98 <release>
    release(&curr->node_lock);
    80001ce6:	17848513          	addi	a0,s1,376
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	fae080e7          	jalr	-82(ra) # 80000c98 <release>
  }

  return 1;
    80001cf2:	4505                	li	a0,1
}
    80001cf4:	70e2                	ld	ra,56(sp)
    80001cf6:	7442                	ld	s0,48(sp)
    80001cf8:	74a2                	ld	s1,40(sp)
    80001cfa:	7902                	ld	s2,32(sp)
    80001cfc:	69e2                	ld	s3,24(sp)
    80001cfe:	6a42                	ld	s4,16(sp)
    80001d00:	6aa2                	ld	s5,8(sp)
    80001d02:	6b02                	ld	s6,0(sp)
    80001d04:	6121                	addi	sp,sp,64
    80001d06:	8082                	ret
    printf("Fails in removing the process from the list: the list is empty\n");
    80001d08:	00006517          	auipc	a0,0x6
    80001d0c:	59850513          	addi	a0,a0,1432 # 800082a0 <digits+0x260>
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	878080e7          	jalr	-1928(ra) # 80000588 <printf>
    release(&lst->head_lock);
    80001d18:	855a                	mv	a0,s6
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>
    return 0;
    80001d22:	4501                	li	a0,0
    80001d24:	bfc1                	j	80001cf4 <remove_proc_to_list+0xf8>
   remove_head_from_list(lst);
    80001d26:	8526                	mv	a0,s1
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	e20080e7          	jalr	-480(ra) # 80001b48 <remove_head_from_list>
   release(&lst->head_lock);
    80001d30:	855a                	mv	a0,s6
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f66080e7          	jalr	-154(ra) # 80000c98 <release>
  return 1;
    80001d3a:	4505                	li	a0,1
    80001d3c:	bf65                	j	80001cf4 <remove_proc_to_list+0xf8>
    while(curr->next_index != p->index && curr->next_index != -1){ // search p
    80001d3e:	87aa                	mv	a5,a0
    80001d40:	bf85                	j	80001cb0 <remove_proc_to_list+0xb4>
      printf("Fails in removing the process from the list: process is not found in the list\n");
    80001d42:	00006517          	auipc	a0,0x6
    80001d46:	59e50513          	addi	a0,a0,1438 # 800082e0 <digits+0x2a0>
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	83e080e7          	jalr	-1986(ra) # 80000588 <printf>
      release(&lst->head_lock);
    80001d52:	855a                	mv	a0,s6
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	f44080e7          	jalr	-188(ra) # 80000c98 <release>
      return 0;
    80001d5c:	4501                	li	a0,0
    80001d5e:	bf59                	j	80001cf4 <remove_proc_to_list+0xf8>
      set_prev_proc(&proc[p->next_index], curr->index);
    80001d60:	16c4a683          	lw	a3,364(s1)
  p->prev_index = value; 
    80001d64:	19000713          	li	a4,400
    80001d68:	02e787b3          	mul	a5,a5,a4
    80001d6c:	00010717          	auipc	a4,0x10
    80001d70:	ae470713          	addi	a4,a4,-1308 # 80011850 <proc>
    80001d74:	97ba                	add	a5,a5,a4
    80001d76:	16d7a823          	sw	a3,368(a5)
}
    80001d7a:	bfa1                	j	80001cd2 <remove_proc_to_list+0xd6>

0000000080001d7c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001d7c:	7139                	addi	sp,sp,-64
    80001d7e:	fc06                	sd	ra,56(sp)
    80001d80:	f822                	sd	s0,48(sp)
    80001d82:	f426                	sd	s1,40(sp)
    80001d84:	f04a                	sd	s2,32(sp)
    80001d86:	ec4e                	sd	s3,24(sp)
    80001d88:	e852                	sd	s4,16(sp)
    80001d8a:	e456                	sd	s5,8(sp)
    80001d8c:	e05a                	sd	s6,0(sp)
    80001d8e:	0080                	addi	s0,sp,64
    80001d90:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d92:	00010497          	auipc	s1,0x10
    80001d96:	abe48493          	addi	s1,s1,-1346 # 80011850 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001d9a:	8b26                	mv	s6,s1
    80001d9c:	00006a97          	auipc	s5,0x6
    80001da0:	264a8a93          	addi	s5,s5,612 # 80008000 <etext>
    80001da4:	04000937          	lui	s2,0x4000
    80001da8:	197d                	addi	s2,s2,-1
    80001daa:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dac:	00016a17          	auipc	s4,0x16
    80001db0:	ea4a0a13          	addi	s4,s4,-348 # 80017c50 <tickslock>
    char *pa = kalloc();
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	d40080e7          	jalr	-704(ra) # 80000af4 <kalloc>
    80001dbc:	862a                	mv	a2,a0
    if(pa == 0)
    80001dbe:	c131                	beqz	a0,80001e02 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001dc0:	416485b3          	sub	a1,s1,s6
    80001dc4:	8591                	srai	a1,a1,0x4
    80001dc6:	000ab783          	ld	a5,0(s5)
    80001dca:	02f585b3          	mul	a1,a1,a5
    80001dce:	2585                	addiw	a1,a1,1
    80001dd0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001dd4:	4719                	li	a4,6
    80001dd6:	6685                	lui	a3,0x1
    80001dd8:	40b905b3          	sub	a1,s2,a1
    80001ddc:	854e                	mv	a0,s3
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	372080e7          	jalr	882(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001de6:	19048493          	addi	s1,s1,400
    80001dea:	fd4495e3          	bne	s1,s4,80001db4 <proc_mapstacks+0x38>
  }
}
    80001dee:	70e2                	ld	ra,56(sp)
    80001df0:	7442                	ld	s0,48(sp)
    80001df2:	74a2                	ld	s1,40(sp)
    80001df4:	7902                	ld	s2,32(sp)
    80001df6:	69e2                	ld	s3,24(sp)
    80001df8:	6a42                	ld	s4,16(sp)
    80001dfa:	6aa2                	ld	s5,8(sp)
    80001dfc:	6b02                	ld	s6,0(sp)
    80001dfe:	6121                	addi	sp,sp,64
    80001e00:	8082                	ret
      panic("kalloc");
    80001e02:	00006517          	auipc	a0,0x6
    80001e06:	52e50513          	addi	a0,a0,1326 # 80008330 <digits+0x2f0>
    80001e0a:	ffffe097          	auipc	ra,0xffffe
    80001e0e:	734080e7          	jalr	1844(ra) # 8000053e <panic>

0000000080001e12 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001e12:	711d                	addi	sp,sp,-96
    80001e14:	ec86                	sd	ra,88(sp)
    80001e16:	e8a2                	sd	s0,80(sp)
    80001e18:	e4a6                	sd	s1,72(sp)
    80001e1a:	e0ca                	sd	s2,64(sp)
    80001e1c:	fc4e                	sd	s3,56(sp)
    80001e1e:	f852                	sd	s4,48(sp)
    80001e20:	f456                	sd	s5,40(sp)
    80001e22:	f05a                	sd	s6,32(sp)
    80001e24:	ec5e                	sd	s7,24(sp)
    80001e26:	e862                	sd	s8,16(sp)
    80001e28:	e466                	sd	s9,8(sp)
    80001e2a:	e06a                	sd	s10,0(sp)
    80001e2c:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_lists();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	ac2080e7          	jalr	-1342(ra) # 800018f0 <initialize_lists>

  initlock(&pid_lock, "nextpid");
    80001e36:	00006597          	auipc	a1,0x6
    80001e3a:	50258593          	addi	a1,a1,1282 # 80008338 <digits+0x2f8>
    80001e3e:	00010517          	auipc	a0,0x10
    80001e42:	9e250513          	addi	a0,a0,-1566 # 80011820 <pid_lock>
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	d0e080e7          	jalr	-754(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001e4e:	00006597          	auipc	a1,0x6
    80001e52:	4f258593          	addi	a1,a1,1266 # 80008340 <digits+0x300>
    80001e56:	00010517          	auipc	a0,0x10
    80001e5a:	9e250513          	addi	a0,a0,-1566 # 80011838 <wait_lock>
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	cf6080e7          	jalr	-778(ra) # 80000b54 <initlock>

  int i = 0;
    80001e66:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e68:	00010497          	auipc	s1,0x10
    80001e6c:	9e848493          	addi	s1,s1,-1560 # 80011850 <proc>
      initlock(&p->lock, "proc");
    80001e70:	00006d17          	auipc	s10,0x6
    80001e74:	4e0d0d13          	addi	s10,s10,1248 # 80008350 <digits+0x310>
      initlock(&p->lock, "node_lock");
    80001e78:	00006c97          	auipc	s9,0x6
    80001e7c:	4e0c8c93          	addi	s9,s9,1248 # 80008358 <digits+0x318>
      p->kstack = KSTACK((int) (p - proc));
    80001e80:	8c26                	mv	s8,s1
    80001e82:	00006b97          	auipc	s7,0x6
    80001e86:	17eb8b93          	addi	s7,s7,382 # 80008000 <etext>
    80001e8a:	04000a37          	lui	s4,0x4000
    80001e8e:	1a7d                	addi	s4,s4,-1
    80001e90:	0a32                	slli	s4,s4,0xc
  p->next_index = -1;
    80001e92:	59fd                	li	s3,-1
      p->index = i;
      initialize_proc(p);
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001e94:	00007b17          	auipc	s6,0x7
    80001e98:	b0cb0b13          	addi	s6,s6,-1268 # 800089a0 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e9c:	00016a97          	auipc	s5,0x16
    80001ea0:	db4a8a93          	addi	s5,s5,-588 # 80017c50 <tickslock>
      initlock(&p->lock, "proc");
    80001ea4:	85ea                	mv	a1,s10
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	cac080e7          	jalr	-852(ra) # 80000b54 <initlock>
      initlock(&p->lock, "node_lock");
    80001eb0:	85e6                	mv	a1,s9
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	ca0080e7          	jalr	-864(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ebc:	418487b3          	sub	a5,s1,s8
    80001ec0:	8791                	srai	a5,a5,0x4
    80001ec2:	000bb703          	ld	a4,0(s7)
    80001ec6:	02e787b3          	mul	a5,a5,a4
    80001eca:	2785                	addiw	a5,a5,1
    80001ecc:	00d7979b          	slliw	a5,a5,0xd
    80001ed0:	40fa07b3          	sub	a5,s4,a5
    80001ed4:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001ed6:	1724a623          	sw	s2,364(s1)
  p->next_index = -1;
    80001eda:	1734aa23          	sw	s3,372(s1)
  p->prev_index = -1;
    80001ede:	1734a823          	sw	s3,368(s1)
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001ee2:	85a6                	mv	a1,s1
    80001ee4:	855a                	mv	a0,s6
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	b76080e7          	jalr	-1162(ra) # 80001a5c <insert_proc_to_list>
      i++;
    80001eee:	2905                	addiw	s2,s2,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ef0:	19048493          	addi	s1,s1,400
    80001ef4:	fb5498e3          	bne	s1,s5,80001ea4 <procinit+0x92>
  }
}
    80001ef8:	60e6                	ld	ra,88(sp)
    80001efa:	6446                	ld	s0,80(sp)
    80001efc:	64a6                	ld	s1,72(sp)
    80001efe:	6906                	ld	s2,64(sp)
    80001f00:	79e2                	ld	s3,56(sp)
    80001f02:	7a42                	ld	s4,48(sp)
    80001f04:	7aa2                	ld	s5,40(sp)
    80001f06:	7b02                	ld	s6,32(sp)
    80001f08:	6be2                	ld	s7,24(sp)
    80001f0a:	6c42                	ld	s8,16(sp)
    80001f0c:	6ca2                	ld	s9,8(sp)
    80001f0e:	6d02                	ld	s10,0(sp)
    80001f10:	6125                	addi	sp,sp,96
    80001f12:	8082                	ret

0000000080001f14 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001f14:	1141                	addi	sp,sp,-16
    80001f16:	e422                	sd	s0,8(sp)
    80001f18:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f1a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001f1c:	2501                	sext.w	a0,a0
    80001f1e:	6422                	ld	s0,8(sp)
    80001f20:	0141                	addi	sp,sp,16
    80001f22:	8082                	ret

0000000080001f24 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001f24:	1141                	addi	sp,sp,-16
    80001f26:	e422                	sd	s0,8(sp)
    80001f28:	0800                	addi	s0,sp,16
    80001f2a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001f2c:	2781                	sext.w	a5,a5
    80001f2e:	0b000513          	li	a0,176
    80001f32:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001f36:	0000f517          	auipc	a0,0xf
    80001f3a:	36a50513          	addi	a0,a0,874 # 800112a0 <cpus>
    80001f3e:	953e                	add	a0,a0,a5
    80001f40:	6422                	ld	s0,8(sp)
    80001f42:	0141                	addi	sp,sp,16
    80001f44:	8082                	ret

0000000080001f46 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001f46:	1101                	addi	sp,sp,-32
    80001f48:	ec06                	sd	ra,24(sp)
    80001f4a:	e822                	sd	s0,16(sp)
    80001f4c:	e426                	sd	s1,8(sp)
    80001f4e:	1000                	addi	s0,sp,32
  push_off();
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c48080e7          	jalr	-952(ra) # 80000b98 <push_off>
    80001f58:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001f5a:	2781                	sext.w	a5,a5
    80001f5c:	0b000713          	li	a4,176
    80001f60:	02e787b3          	mul	a5,a5,a4
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	33c70713          	addi	a4,a4,828 # 800112a0 <cpus>
    80001f6c:	97ba                	add	a5,a5,a4
    80001f6e:	6384                	ld	s1,0(a5)
  pop_off();
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	cc8080e7          	jalr	-824(ra) # 80000c38 <pop_off>
  return p;
}
    80001f78:	8526                	mv	a0,s1
    80001f7a:	60e2                	ld	ra,24(sp)
    80001f7c:	6442                	ld	s0,16(sp)
    80001f7e:	64a2                	ld	s1,8(sp)
    80001f80:	6105                	addi	sp,sp,32
    80001f82:	8082                	ret

0000000080001f84 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001f84:	1141                	addi	sp,sp,-16
    80001f86:	e406                	sd	ra,8(sp)
    80001f88:	e022                	sd	s0,0(sp)
    80001f8a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	fba080e7          	jalr	-70(ra) # 80001f46 <myproc>
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>

  if (first) {
    80001f9c:	00007797          	auipc	a5,0x7
    80001fa0:	9f47a783          	lw	a5,-1548(a5) # 80008990 <first.1787>
    80001fa4:	eb89                	bnez	a5,80001fb6 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001fa6:	00001097          	auipc	ra,0x1
    80001faa:	056080e7          	jalr	86(ra) # 80002ffc <usertrapret>
}
    80001fae:	60a2                	ld	ra,8(sp)
    80001fb0:	6402                	ld	s0,0(sp)
    80001fb2:	0141                	addi	sp,sp,16
    80001fb4:	8082                	ret
    first = 0;
    80001fb6:	00007797          	auipc	a5,0x7
    80001fba:	9c07ad23          	sw	zero,-1574(a5) # 80008990 <first.1787>
    fsinit(ROOTDEV);
    80001fbe:	4505                	li	a0,1
    80001fc0:	00002097          	auipc	ra,0x2
    80001fc4:	dfa080e7          	jalr	-518(ra) # 80003dba <fsinit>
    80001fc8:	bff9                	j	80001fa6 <forkret+0x22>

0000000080001fca <allocpid>:
allocpid() {
    80001fca:	1101                	addi	sp,sp,-32
    80001fcc:	ec06                	sd	ra,24(sp)
    80001fce:	e822                	sd	s0,16(sp)
    80001fd0:	e426                	sd	s1,8(sp)
    80001fd2:	e04a                	sd	s2,0(sp)
    80001fd4:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001fd6:	00007917          	auipc	s2,0x7
    80001fda:	9be90913          	addi	s2,s2,-1602 # 80008994 <nextpid>
    80001fde:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001fe2:	0014861b          	addiw	a2,s1,1
    80001fe6:	85a6                	mv	a1,s1
    80001fe8:	854a                	mv	a0,s2
    80001fea:	00005097          	auipc	ra,0x5
    80001fee:	bdc080e7          	jalr	-1060(ra) # 80006bc6 <cas>
    80001ff2:	2501                	sext.w	a0,a0
    80001ff4:	f56d                	bnez	a0,80001fde <allocpid+0x14>
}
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	60e2                	ld	ra,24(sp)
    80001ffa:	6442                	ld	s0,16(sp)
    80001ffc:	64a2                	ld	s1,8(sp)
    80001ffe:	6902                	ld	s2,0(sp)
    80002000:	6105                	addi	sp,sp,32
    80002002:	8082                	ret

0000000080002004 <proc_pagetable>:
{
    80002004:	1101                	addi	sp,sp,-32
    80002006:	ec06                	sd	ra,24(sp)
    80002008:	e822                	sd	s0,16(sp)
    8000200a:	e426                	sd	s1,8(sp)
    8000200c:	e04a                	sd	s2,0(sp)
    8000200e:	1000                	addi	s0,sp,32
    80002010:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	328080e7          	jalr	808(ra) # 8000133a <uvmcreate>
    8000201a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000201c:	c121                	beqz	a0,8000205c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    8000201e:	4729                	li	a4,10
    80002020:	00005697          	auipc	a3,0x5
    80002024:	fe068693          	addi	a3,a3,-32 # 80007000 <_trampoline>
    80002028:	6605                	lui	a2,0x1
    8000202a:	040005b7          	lui	a1,0x4000
    8000202e:	15fd                	addi	a1,a1,-1
    80002030:	05b2                	slli	a1,a1,0xc
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	07e080e7          	jalr	126(ra) # 800010b0 <mappages>
    8000203a:	02054863          	bltz	a0,8000206a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    8000203e:	4719                	li	a4,6
    80002040:	05893683          	ld	a3,88(s2)
    80002044:	6605                	lui	a2,0x1
    80002046:	020005b7          	lui	a1,0x2000
    8000204a:	15fd                	addi	a1,a1,-1
    8000204c:	05b6                	slli	a1,a1,0xd
    8000204e:	8526                	mv	a0,s1
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	060080e7          	jalr	96(ra) # 800010b0 <mappages>
    80002058:	02054163          	bltz	a0,8000207a <proc_pagetable+0x76>
}
    8000205c:	8526                	mv	a0,s1
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6902                	ld	s2,0(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret
    uvmfree(pagetable, 0);
    8000206a:	4581                	li	a1,0
    8000206c:	8526                	mv	a0,s1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	4c8080e7          	jalr	1224(ra) # 80001536 <uvmfree>
    return 0;
    80002076:	4481                	li	s1,0
    80002078:	b7d5                	j	8000205c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000207a:	4681                	li	a3,0
    8000207c:	4605                	li	a2,1
    8000207e:	040005b7          	lui	a1,0x4000
    80002082:	15fd                	addi	a1,a1,-1
    80002084:	05b2                	slli	a1,a1,0xc
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	1ee080e7          	jalr	494(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80002090:	4581                	li	a1,0
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	4a2080e7          	jalr	1186(ra) # 80001536 <uvmfree>
    return 0;
    8000209c:	4481                	li	s1,0
    8000209e:	bf7d                	j	8000205c <proc_pagetable+0x58>

00000000800020a0 <proc_freepagetable>:
{
    800020a0:	1101                	addi	sp,sp,-32
    800020a2:	ec06                	sd	ra,24(sp)
    800020a4:	e822                	sd	s0,16(sp)
    800020a6:	e426                	sd	s1,8(sp)
    800020a8:	e04a                	sd	s2,0(sp)
    800020aa:	1000                	addi	s0,sp,32
    800020ac:	84aa                	mv	s1,a0
    800020ae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800020b0:	4681                	li	a3,0
    800020b2:	4605                	li	a2,1
    800020b4:	040005b7          	lui	a1,0x4000
    800020b8:	15fd                	addi	a1,a1,-1
    800020ba:	05b2                	slli	a1,a1,0xc
    800020bc:	fffff097          	auipc	ra,0xfffff
    800020c0:	1ba080e7          	jalr	442(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800020c4:	4681                	li	a3,0
    800020c6:	4605                	li	a2,1
    800020c8:	020005b7          	lui	a1,0x2000
    800020cc:	15fd                	addi	a1,a1,-1
    800020ce:	05b6                	slli	a1,a1,0xd
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	1a4080e7          	jalr	420(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    800020da:	85ca                	mv	a1,s2
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	458080e7          	jalr	1112(ra) # 80001536 <uvmfree>
}
    800020e6:	60e2                	ld	ra,24(sp)
    800020e8:	6442                	ld	s0,16(sp)
    800020ea:	64a2                	ld	s1,8(sp)
    800020ec:	6902                	ld	s2,0(sp)
    800020ee:	6105                	addi	sp,sp,32
    800020f0:	8082                	ret

00000000800020f2 <freeproc>:
{
    800020f2:	1101                	addi	sp,sp,-32
    800020f4:	ec06                	sd	ra,24(sp)
    800020f6:	e822                	sd	s0,16(sp)
    800020f8:	e426                	sd	s1,8(sp)
    800020fa:	1000                	addi	s0,sp,32
    800020fc:	84aa                	mv	s1,a0
  if(p->trapframe)
    800020fe:	6d28                	ld	a0,88(a0)
    80002100:	c509                	beqz	a0,8000210a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	8f6080e7          	jalr	-1802(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    8000210a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    8000210e:	68a8                	ld	a0,80(s1)
    80002110:	c511                	beqz	a0,8000211c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002112:	64ac                	ld	a1,72(s1)
    80002114:	00000097          	auipc	ra,0x0
    80002118:	f8c080e7          	jalr	-116(ra) # 800020a0 <proc_freepagetable>
  p->pagetable = 0;
    8000211c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002120:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80002124:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002128:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    8000212c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002130:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002134:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002138:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    8000213c:	0004ac23          	sw	zero,24(s1)
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80002140:	85a6                	mv	a1,s1
    80002142:	00007517          	auipc	a0,0x7
    80002146:	89e50513          	addi	a0,a0,-1890 # 800089e0 <zombie_list>
    8000214a:	00000097          	auipc	ra,0x0
    8000214e:	ab2080e7          	jalr	-1358(ra) # 80001bfc <remove_proc_to_list>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80002152:	85a6                	mv	a1,s1
    80002154:	00007517          	auipc	a0,0x7
    80002158:	84c50513          	addi	a0,a0,-1972 # 800089a0 <unused_list>
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	900080e7          	jalr	-1792(ra) # 80001a5c <insert_proc_to_list>
}
    80002164:	60e2                	ld	ra,24(sp)
    80002166:	6442                	ld	s0,16(sp)
    80002168:	64a2                	ld	s1,8(sp)
    8000216a:	6105                	addi	sp,sp,32
    8000216c:	8082                	ret

000000008000216e <allocproc>:
{
    8000216e:	715d                	addi	sp,sp,-80
    80002170:	e486                	sd	ra,72(sp)
    80002172:	e0a2                	sd	s0,64(sp)
    80002174:	fc26                	sd	s1,56(sp)
    80002176:	f84a                	sd	s2,48(sp)
    80002178:	f44e                	sd	s3,40(sp)
    8000217a:	f052                	sd	s4,32(sp)
    8000217c:	ec56                	sd	s5,24(sp)
    8000217e:	e85a                	sd	s6,16(sp)
    80002180:	e45e                	sd	s7,8(sp)
    80002182:	0880                	addi	s0,sp,80
  while(!isEmpty(&unused_list)){
    80002184:	00007717          	auipc	a4,0x7
    80002188:	81c72703          	lw	a4,-2020(a4) # 800089a0 <unused_list>
    8000218c:	57fd                	li	a5,-1
    8000218e:	14f70063          	beq	a4,a5,800022ce <allocproc+0x160>
    p = &proc[get_head(&unused_list)];
    80002192:	00007a17          	auipc	s4,0x7
    80002196:	80ea0a13          	addi	s4,s4,-2034 # 800089a0 <unused_list>
    8000219a:	19000b13          	li	s6,400
    8000219e:	0000fa97          	auipc	s5,0xf
    800021a2:	6b2a8a93          	addi	s5,s5,1714 # 80011850 <proc>
  while(!isEmpty(&unused_list)){
    800021a6:	5bfd                	li	s7,-1
    p = &proc[get_head(&unused_list)];
    800021a8:	8552                	mv	a0,s4
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	85c080e7          	jalr	-1956(ra) # 80001a06 <get_head>
    800021b2:	892a                	mv	s2,a0
    800021b4:	036509b3          	mul	s3,a0,s6
    800021b8:	015984b3          	add	s1,s3,s5
    acquire(&p->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	a26080e7          	jalr	-1498(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    800021c6:	4c9c                	lw	a5,24(s1)
    800021c8:	c79d                	beqz	a5,800021f6 <allocproc+0x88>
      release(&p->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
  while(!isEmpty(&unused_list)){
    800021d4:	000a2783          	lw	a5,0(s4)
    800021d8:	fd7798e3          	bne	a5,s7,800021a8 <allocproc+0x3a>
  return 0;
    800021dc:	4481                	li	s1,0
}
    800021de:	8526                	mv	a0,s1
    800021e0:	60a6                	ld	ra,72(sp)
    800021e2:	6406                	ld	s0,64(sp)
    800021e4:	74e2                	ld	s1,56(sp)
    800021e6:	7942                	ld	s2,48(sp)
    800021e8:	79a2                	ld	s3,40(sp)
    800021ea:	7a02                	ld	s4,32(sp)
    800021ec:	6ae2                	ld	s5,24(sp)
    800021ee:	6b42                	ld	s6,16(sp)
    800021f0:	6ba2                	ld	s7,8(sp)
    800021f2:	6161                	addi	sp,sp,80
    800021f4:	8082                	ret
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    800021f6:	85a6                	mv	a1,s1
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	7a850513          	addi	a0,a0,1960 # 800089a0 <unused_list>
    80002200:	00000097          	auipc	ra,0x0
    80002204:	9fc080e7          	jalr	-1540(ra) # 80001bfc <remove_proc_to_list>
  p->pid = allocpid();
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	dc2080e7          	jalr	-574(ra) # 80001fca <allocpid>
    80002210:	19000a13          	li	s4,400
    80002214:	034907b3          	mul	a5,s2,s4
    80002218:	0000fa17          	auipc	s4,0xf
    8000221c:	638a0a13          	addi	s4,s4,1592 # 80011850 <proc>
    80002220:	9a3e                	add	s4,s4,a5
    80002222:	02aa2823          	sw	a0,48(s4)
  p->state = USED;
    80002226:	4785                	li	a5,1
    80002228:	00fa2c23          	sw	a5,24(s4)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	8c8080e7          	jalr	-1848(ra) # 80000af4 <kalloc>
    80002234:	8aaa                	mv	s5,a0
    80002236:	04aa3c23          	sd	a0,88(s4)
    8000223a:	c135                	beqz	a0,8000229e <allocproc+0x130>
  p->pagetable = proc_pagetable(p);
    8000223c:	8526                	mv	a0,s1
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	dc6080e7          	jalr	-570(ra) # 80002004 <proc_pagetable>
    80002246:	8a2a                	mv	s4,a0
    80002248:	19000793          	li	a5,400
    8000224c:	02f90733          	mul	a4,s2,a5
    80002250:	0000f797          	auipc	a5,0xf
    80002254:	60078793          	addi	a5,a5,1536 # 80011850 <proc>
    80002258:	97ba                	add	a5,a5,a4
    8000225a:	eba8                	sd	a0,80(a5)
  if(p->pagetable == 0){
    8000225c:	cd29                	beqz	a0,800022b6 <allocproc+0x148>
  memset(&p->context, 0, sizeof(p->context));
    8000225e:	06098513          	addi	a0,s3,96
    80002262:	0000f997          	auipc	s3,0xf
    80002266:	5ee98993          	addi	s3,s3,1518 # 80011850 <proc>
    8000226a:	07000613          	li	a2,112
    8000226e:	4581                	li	a1,0
    80002270:	954e                	add	a0,a0,s3
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a6e080e7          	jalr	-1426(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    8000227a:	19000793          	li	a5,400
    8000227e:	02f90933          	mul	s2,s2,a5
    80002282:	994e                	add	s2,s2,s3
    80002284:	00000797          	auipc	a5,0x0
    80002288:	d0078793          	addi	a5,a5,-768 # 80001f84 <forkret>
    8000228c:	06f93023          	sd	a5,96(s2)
  p->context.sp = p->kstack + PGSIZE;
    80002290:	04093783          	ld	a5,64(s2)
    80002294:	6705                	lui	a4,0x1
    80002296:	97ba                	add	a5,a5,a4
    80002298:	06f93423          	sd	a5,104(s2)
  return p;
    8000229c:	b789                	j	800021de <allocproc+0x70>
    freeproc(p);
    8000229e:	8526                	mv	a0,s1
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	e52080e7          	jalr	-430(ra) # 800020f2 <freeproc>
    release(&p->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
    return 0;
    800022b2:	84d6                	mv	s1,s5
    800022b4:	b72d                	j	800021de <allocproc+0x70>
    freeproc(p);
    800022b6:	8526                	mv	a0,s1
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	e3a080e7          	jalr	-454(ra) # 800020f2 <freeproc>
    release(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
    return 0;
    800022ca:	84d2                	mv	s1,s4
    800022cc:	bf09                	j	800021de <allocproc+0x70>
  return 0;
    800022ce:	4481                	li	s1,0
    800022d0:	b739                	j	800021de <allocproc+0x70>

00000000800022d2 <userinit>:
{
    800022d2:	1101                	addi	sp,sp,-32
    800022d4:	ec06                	sd	ra,24(sp)
    800022d6:	e822                	sd	s0,16(sp)
    800022d8:	e426                	sd	s1,8(sp)
    800022da:	1000                	addi	s0,sp,32
  p = allocproc();
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	e92080e7          	jalr	-366(ra) # 8000216e <allocproc>
    800022e4:	84aa                	mv	s1,a0
  initproc = p;
    800022e6:	00007797          	auipc	a5,0x7
    800022ea:	d4a7b123          	sd	a0,-702(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800022ee:	03400613          	li	a2,52
    800022f2:	00006597          	auipc	a1,0x6
    800022f6:	70e58593          	addi	a1,a1,1806 # 80008a00 <initcode>
    800022fa:	6928                	ld	a0,80(a0)
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	06c080e7          	jalr	108(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80002304:	6785                	lui	a5,0x1
    80002306:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002308:	6cb8                	ld	a4,88(s1)
    8000230a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000230e:	6cb8                	ld	a4,88(s1)
    80002310:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002312:	4641                	li	a2,16
    80002314:	00006597          	auipc	a1,0x6
    80002318:	05458593          	addi	a1,a1,84 # 80008368 <digits+0x328>
    8000231c:	15848513          	addi	a0,s1,344
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	b12080e7          	jalr	-1262(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80002328:	00006517          	auipc	a0,0x6
    8000232c:	05050513          	addi	a0,a0,80 # 80008378 <digits+0x338>
    80002330:	00002097          	auipc	ra,0x2
    80002334:	4b8080e7          	jalr	1208(ra) # 800047e8 <namei>
    80002338:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000233c:	478d                	li	a5,3
    8000233e:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    80002340:	85a6                	mv	a1,s1
    80002342:	0000f517          	auipc	a0,0xf
    80002346:	fde50513          	addi	a0,a0,-34 # 80011320 <cpus+0x80>
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	712080e7          	jalr	1810(ra) # 80001a5c <insert_proc_to_list>
  release(&p->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
}
    8000235c:	60e2                	ld	ra,24(sp)
    8000235e:	6442                	ld	s0,16(sp)
    80002360:	64a2                	ld	s1,8(sp)
    80002362:	6105                	addi	sp,sp,32
    80002364:	8082                	ret

0000000080002366 <growproc>:
{
    80002366:	1101                	addi	sp,sp,-32
    80002368:	ec06                	sd	ra,24(sp)
    8000236a:	e822                	sd	s0,16(sp)
    8000236c:	e426                	sd	s1,8(sp)
    8000236e:	e04a                	sd	s2,0(sp)
    80002370:	1000                	addi	s0,sp,32
    80002372:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002374:	00000097          	auipc	ra,0x0
    80002378:	bd2080e7          	jalr	-1070(ra) # 80001f46 <myproc>
    8000237c:	892a                	mv	s2,a0
  sz = p->sz;
    8000237e:	652c                	ld	a1,72(a0)
    80002380:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002384:	00904f63          	bgtz	s1,800023a2 <growproc+0x3c>
  } else if(n < 0){
    80002388:	0204cc63          	bltz	s1,800023c0 <growproc+0x5a>
  p->sz = sz;
    8000238c:	1602                	slli	a2,a2,0x20
    8000238e:	9201                	srli	a2,a2,0x20
    80002390:	04c93423          	sd	a2,72(s2)
  return 0;
    80002394:	4501                	li	a0,0
}
    80002396:	60e2                	ld	ra,24(sp)
    80002398:	6442                	ld	s0,16(sp)
    8000239a:	64a2                	ld	s1,8(sp)
    8000239c:	6902                	ld	s2,0(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800023a2:	9e25                	addw	a2,a2,s1
    800023a4:	1602                	slli	a2,a2,0x20
    800023a6:	9201                	srli	a2,a2,0x20
    800023a8:	1582                	slli	a1,a1,0x20
    800023aa:	9181                	srli	a1,a1,0x20
    800023ac:	6928                	ld	a0,80(a0)
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	074080e7          	jalr	116(ra) # 80001422 <uvmalloc>
    800023b6:	0005061b          	sext.w	a2,a0
    800023ba:	fa69                	bnez	a2,8000238c <growproc+0x26>
      return -1;
    800023bc:	557d                	li	a0,-1
    800023be:	bfe1                	j	80002396 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800023c0:	9e25                	addw	a2,a2,s1
    800023c2:	1602                	slli	a2,a2,0x20
    800023c4:	9201                	srli	a2,a2,0x20
    800023c6:	1582                	slli	a1,a1,0x20
    800023c8:	9181                	srli	a1,a1,0x20
    800023ca:	6928                	ld	a0,80(a0)
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	00e080e7          	jalr	14(ra) # 800013da <uvmdealloc>
    800023d4:	0005061b          	sext.w	a2,a0
    800023d8:	bf55                	j	8000238c <growproc+0x26>

00000000800023da <scheduler>:
{
    800023da:	711d                	addi	sp,sp,-96
    800023dc:	ec86                	sd	ra,88(sp)
    800023de:	e8a2                	sd	s0,80(sp)
    800023e0:	e4a6                	sd	s1,72(sp)
    800023e2:	e0ca                	sd	s2,64(sp)
    800023e4:	fc4e                	sd	s3,56(sp)
    800023e6:	f852                	sd	s4,48(sp)
    800023e8:	f456                	sd	s5,40(sp)
    800023ea:	f05a                	sd	s6,32(sp)
    800023ec:	ec5e                	sd	s7,24(sp)
    800023ee:	e862                	sd	s8,16(sp)
    800023f0:	e466                	sd	s9,8(sp)
    800023f2:	1080                	addi	s0,sp,96
    800023f4:	8712                	mv	a4,tp
  int id = r_tp();
    800023f6:	2701                	sext.w	a4,a4
  c->proc = 0;
    800023f8:	0000fb97          	auipc	s7,0xf
    800023fc:	ea8b8b93          	addi	s7,s7,-344 # 800112a0 <cpus>
    80002400:	0b000793          	li	a5,176
    80002404:	02f707b3          	mul	a5,a4,a5
    80002408:	00fb86b3          	add	a3,s7,a5
    8000240c:	0006b023          	sd	zero,0(a3)
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002410:	08078b13          	addi	s6,a5,128 # 1080 <_entry-0x7fffef80>
    80002414:	9b5e                	add	s6,s6,s7
          swtch(&c->context, &p->context);
    80002416:	07a1                	addi	a5,a5,8
    80002418:	9bbe                	add	s7,s7,a5
  return lst->head == -1;
    8000241a:	89b6                	mv	s3,a3
      if(p->state == RUNNABLE) {
    8000241c:	0000fa17          	auipc	s4,0xf
    80002420:	434a0a13          	addi	s4,s4,1076 # 80011850 <proc>
    80002424:	19000a93          	li	s5,400
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002428:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000242c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002430:	10079073          	csrw	sstatus,a5
    80002434:	4c0d                	li	s8,3
    while(!isEmpty(&(c->runnable_list))){ // check whether there is a ready process in the cpu
    80002436:	54fd                	li	s1,-1
    80002438:	0809a783          	lw	a5,128(s3)
    8000243c:	fe9786e3          	beq	a5,s1,80002428 <scheduler+0x4e>
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    80002440:	855a                	mv	a0,s6
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	5c4080e7          	jalr	1476(ra) # 80001a06 <get_head>
      if(p->state == RUNNABLE) {
    8000244a:	035507b3          	mul	a5,a0,s5
    8000244e:	97d2                	add	a5,a5,s4
    80002450:	4f9c                	lw	a5,24(a5)
    80002452:	ff8793e3          	bne	a5,s8,80002438 <scheduler+0x5e>
    80002456:	03550cb3          	mul	s9,a0,s5
      p =  &proc[get_head(&c->runnable_list)]; //  pick the first process from the correct CPU’s list.
    8000245a:	014c84b3          	add	s1,s9,s4
        acquire(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	784080e7          	jalr	1924(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {  
    80002468:	4c9c                	lw	a5,24(s1)
    8000246a:	01878863          	beq	a5,s8,8000247a <scheduler+0xa0>
        release(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	828080e7          	jalr	-2008(ra) # 80000c98 <release>
    80002478:	bf7d                	j	80002436 <scheduler+0x5c>
          remove_proc_to_list(&(c->runnable_list), p);
    8000247a:	85a6                	mv	a1,s1
    8000247c:	855a                	mv	a0,s6
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	77e080e7          	jalr	1918(ra) # 80001bfc <remove_proc_to_list>
          p->state = RUNNING;
    80002486:	4711                	li	a4,4
    80002488:	cc98                	sw	a4,24(s1)
          c->proc = p;
    8000248a:	0099b023          	sd	s1,0(s3)
          p->last_cpu = c->cpu_id;
    8000248e:	0a09a703          	lw	a4,160(s3)
    80002492:	16e4a423          	sw	a4,360(s1)
          swtch(&c->context, &p->context);
    80002496:	060c8593          	addi	a1,s9,96
    8000249a:	95d2                	add	a1,a1,s4
    8000249c:	855e                	mv	a0,s7
    8000249e:	00001097          	auipc	ra,0x1
    800024a2:	ab4080e7          	jalr	-1356(ra) # 80002f52 <swtch>
          c->proc = 0;
    800024a6:	0009b023          	sd	zero,0(s3)
    800024aa:	b7d1                	j	8000246e <scheduler+0x94>

00000000800024ac <sched>:
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024bc:	00000097          	auipc	ra,0x0
    800024c0:	a8a080e7          	jalr	-1398(ra) # 80001f46 <myproc>
    800024c4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	6a4080e7          	jalr	1700(ra) # 80000b6a <holding>
    800024ce:	c141                	beqz	a0,8000254e <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800024d0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800024d2:	2781                	sext.w	a5,a5
    800024d4:	0b000713          	li	a4,176
    800024d8:	02e787b3          	mul	a5,a5,a4
    800024dc:	0000f717          	auipc	a4,0xf
    800024e0:	dc470713          	addi	a4,a4,-572 # 800112a0 <cpus>
    800024e4:	97ba                	add	a5,a5,a4
    800024e6:	5fb8                	lw	a4,120(a5)
    800024e8:	4785                	li	a5,1
    800024ea:	06f71a63          	bne	a4,a5,8000255e <sched+0xb2>
  if(p->state == RUNNING)
    800024ee:	4c98                	lw	a4,24(s1)
    800024f0:	4791                	li	a5,4
    800024f2:	06f70e63          	beq	a4,a5,8000256e <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800024fa:	8b89                	andi	a5,a5,2
  if(intr_get())
    800024fc:	e3c9                	bnez	a5,8000257e <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    800024fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002500:	0000f917          	auipc	s2,0xf
    80002504:	da090913          	addi	s2,s2,-608 # 800112a0 <cpus>
    80002508:	2781                	sext.w	a5,a5
    8000250a:	0b000993          	li	s3,176
    8000250e:	033787b3          	mul	a5,a5,s3
    80002512:	97ca                	add	a5,a5,s2
    80002514:	07c7aa03          	lw	s4,124(a5)
    80002518:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000251a:	2581                	sext.w	a1,a1
    8000251c:	033585b3          	mul	a1,a1,s3
    80002520:	05a1                	addi	a1,a1,8
    80002522:	95ca                	add	a1,a1,s2
    80002524:	06048513          	addi	a0,s1,96
    80002528:	00001097          	auipc	ra,0x1
    8000252c:	a2a080e7          	jalr	-1494(ra) # 80002f52 <swtch>
    80002530:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002532:	2781                	sext.w	a5,a5
    80002534:	033787b3          	mul	a5,a5,s3
    80002538:	993e                	add	s2,s2,a5
    8000253a:	07492e23          	sw	s4,124(s2)
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    panic("sched p->lock");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	e3250513          	addi	a0,a0,-462 # 80008380 <digits+0x340>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	fe8080e7          	jalr	-24(ra) # 8000053e <panic>
    panic("sched locks");
    8000255e:	00006517          	auipc	a0,0x6
    80002562:	e3250513          	addi	a0,a0,-462 # 80008390 <digits+0x350>
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	fd8080e7          	jalr	-40(ra) # 8000053e <panic>
    panic("sched running");
    8000256e:	00006517          	auipc	a0,0x6
    80002572:	e3250513          	addi	a0,a0,-462 # 800083a0 <digits+0x360>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000257e:	00006517          	auipc	a0,0x6
    80002582:	e3250513          	addi	a0,a0,-462 # 800083b0 <digits+0x370>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>

000000008000258e <yield>:
{
    8000258e:	1101                	addi	sp,sp,-32
    80002590:	ec06                	sd	ra,24(sp)
    80002592:	e822                	sd	s0,16(sp)
    80002594:	e426                	sd	s1,8(sp)
    80002596:	e04a                	sd	s2,0(sp)
    80002598:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000259a:	00000097          	auipc	ra,0x0
    8000259e:	9ac080e7          	jalr	-1620(ra) # 80001f46 <myproc>
    800025a2:	84aa                	mv	s1,a0
    800025a4:	8912                	mv	s2,tp
  acquire(&p->lock);
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	63e080e7          	jalr	1598(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800025ae:	478d                	li	a5,3
    800025b0:	cc9c                	sw	a5,24(s1)
  insert_proc_to_list(&(c->runnable_list), p);
    800025b2:	2901                	sext.w	s2,s2
    800025b4:	0b000513          	li	a0,176
    800025b8:	02a90933          	mul	s2,s2,a0
    800025bc:	85a6                	mv	a1,s1
    800025be:	0000f517          	auipc	a0,0xf
    800025c2:	d6250513          	addi	a0,a0,-670 # 80011320 <cpus+0x80>
    800025c6:	954a                	add	a0,a0,s2
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	494080e7          	jalr	1172(ra) # 80001a5c <insert_proc_to_list>
  sched();
    800025d0:	00000097          	auipc	ra,0x0
    800025d4:	edc080e7          	jalr	-292(ra) # 800024ac <sched>
  release(&p->lock);
    800025d8:	8526                	mv	a0,s1
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
}
    800025e2:	60e2                	ld	ra,24(sp)
    800025e4:	6442                	ld	s0,16(sp)
    800025e6:	64a2                	ld	s1,8(sp)
    800025e8:	6902                	ld	s2,0(sp)
    800025ea:	6105                	addi	sp,sp,32
    800025ec:	8082                	ret

00000000800025ee <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	1800                	addi	s0,sp,48
    800025fc:	89aa                	mv	s3,a0
    800025fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002600:	00000097          	auipc	ra,0x0
    80002604:	946080e7          	jalr	-1722(ra) # 80001f46 <myproc>
    80002608:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	5da080e7          	jalr	1498(ra) # 80000be4 <acquire>
  insert_proc_to_list(&sleeping_list, p);
    80002612:	85a6                	mv	a1,s1
    80002614:	00006517          	auipc	a0,0x6
    80002618:	3ac50513          	addi	a0,a0,940 # 800089c0 <sleeping_list>
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	440080e7          	jalr	1088(ra) # 80001a5c <insert_proc_to_list>
  release(lk);
    80002624:	854a                	mv	a0,s2
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	672080e7          	jalr	1650(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000262e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002632:	4789                	li	a5,2
    80002634:	cc9c                	sw	a5,24(s1)

  sched();
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	e76080e7          	jalr	-394(ra) # 800024ac <sched>

  // Tidy up.
  p->chan = 0;
    8000263e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	654080e7          	jalr	1620(ra) # 80000c98 <release>
  acquire(lk);
    8000264c:	854a                	mv	a0,s2
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
}
    80002656:	70a2                	ld	ra,40(sp)
    80002658:	7402                	ld	s0,32(sp)
    8000265a:	64e2                	ld	s1,24(sp)
    8000265c:	6942                	ld	s2,16(sp)
    8000265e:	69a2                	ld	s3,8(sp)
    80002660:	6145                	addi	sp,sp,48
    80002662:	8082                	ret

0000000080002664 <wait>:
{
    80002664:	715d                	addi	sp,sp,-80
    80002666:	e486                	sd	ra,72(sp)
    80002668:	e0a2                	sd	s0,64(sp)
    8000266a:	fc26                	sd	s1,56(sp)
    8000266c:	f84a                	sd	s2,48(sp)
    8000266e:	f44e                	sd	s3,40(sp)
    80002670:	f052                	sd	s4,32(sp)
    80002672:	ec56                	sd	s5,24(sp)
    80002674:	e85a                	sd	s6,16(sp)
    80002676:	e45e                	sd	s7,8(sp)
    80002678:	e062                	sd	s8,0(sp)
    8000267a:	0880                	addi	s0,sp,80
    8000267c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	8c8080e7          	jalr	-1848(ra) # 80001f46 <myproc>
    80002686:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002688:	0000f517          	auipc	a0,0xf
    8000268c:	1b050513          	addi	a0,a0,432 # 80011838 <wait_lock>
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	554080e7          	jalr	1364(ra) # 80000be4 <acquire>
    havekids = 0;
    80002698:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000269a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000269c:	00015997          	auipc	s3,0x15
    800026a0:	5b498993          	addi	s3,s3,1460 # 80017c50 <tickslock>
        havekids = 1;
    800026a4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026a6:	0000fc17          	auipc	s8,0xf
    800026aa:	192c0c13          	addi	s8,s8,402 # 80011838 <wait_lock>
    havekids = 0;
    800026ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800026b0:	0000f497          	auipc	s1,0xf
    800026b4:	1a048493          	addi	s1,s1,416 # 80011850 <proc>
    800026b8:	a0bd                	j	80002726 <wait+0xc2>
          pid = np->pid;
    800026ba:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026be:	000b0e63          	beqz	s6,800026da <wait+0x76>
    800026c2:	4691                	li	a3,4
    800026c4:	02c48613          	addi	a2,s1,44
    800026c8:	85da                	mv	a1,s6
    800026ca:	05093503          	ld	a0,80(s2)
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	fa4080e7          	jalr	-92(ra) # 80001672 <copyout>
    800026d6:	02054563          	bltz	a0,80002700 <wait+0x9c>
          freeproc(np);
    800026da:	8526                	mv	a0,s1
    800026dc:	00000097          	auipc	ra,0x0
    800026e0:	a16080e7          	jalr	-1514(ra) # 800020f2 <freeproc>
          release(&np->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	5b2080e7          	jalr	1458(ra) # 80000c98 <release>
          release(&wait_lock);
    800026ee:	0000f517          	auipc	a0,0xf
    800026f2:	14a50513          	addi	a0,a0,330 # 80011838 <wait_lock>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	5a2080e7          	jalr	1442(ra) # 80000c98 <release>
          return pid;
    800026fe:	a09d                	j	80002764 <wait+0x100>
            release(&np->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	596080e7          	jalr	1430(ra) # 80000c98 <release>
            release(&wait_lock);
    8000270a:	0000f517          	auipc	a0,0xf
    8000270e:	12e50513          	addi	a0,a0,302 # 80011838 <wait_lock>
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	586080e7          	jalr	1414(ra) # 80000c98 <release>
            return -1;
    8000271a:	59fd                	li	s3,-1
    8000271c:	a0a1                	j	80002764 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000271e:	19048493          	addi	s1,s1,400
    80002722:	03348463          	beq	s1,s3,8000274a <wait+0xe6>
      if(np->parent == p){
    80002726:	7c9c                	ld	a5,56(s1)
    80002728:	ff279be3          	bne	a5,s2,8000271e <wait+0xba>
        acquire(&np->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002736:	4c9c                	lw	a5,24(s1)
    80002738:	f94781e3          	beq	a5,s4,800026ba <wait+0x56>
        release(&np->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	55a080e7          	jalr	1370(ra) # 80000c98 <release>
        havekids = 1;
    80002746:	8756                	mv	a4,s5
    80002748:	bfd9                	j	8000271e <wait+0xba>
    if(!havekids || p->killed){
    8000274a:	c701                	beqz	a4,80002752 <wait+0xee>
    8000274c:	02892783          	lw	a5,40(s2)
    80002750:	c79d                	beqz	a5,8000277e <wait+0x11a>
      release(&wait_lock);
    80002752:	0000f517          	auipc	a0,0xf
    80002756:	0e650513          	addi	a0,a0,230 # 80011838 <wait_lock>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	53e080e7          	jalr	1342(ra) # 80000c98 <release>
      return -1;
    80002762:	59fd                	li	s3,-1
}
    80002764:	854e                	mv	a0,s3
    80002766:	60a6                	ld	ra,72(sp)
    80002768:	6406                	ld	s0,64(sp)
    8000276a:	74e2                	ld	s1,56(sp)
    8000276c:	7942                	ld	s2,48(sp)
    8000276e:	79a2                	ld	s3,40(sp)
    80002770:	7a02                	ld	s4,32(sp)
    80002772:	6ae2                	ld	s5,24(sp)
    80002774:	6b42                	ld	s6,16(sp)
    80002776:	6ba2                	ld	s7,8(sp)
    80002778:	6c02                	ld	s8,0(sp)
    8000277a:	6161                	addi	sp,sp,80
    8000277c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000277e:	85e2                	mv	a1,s8
    80002780:	854a                	mv	a0,s2
    80002782:	00000097          	auipc	ra,0x0
    80002786:	e6c080e7          	jalr	-404(ra) # 800025ee <sleep>
    havekids = 0;
    8000278a:	b715                	j	800026ae <wait+0x4a>

000000008000278c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000278c:	7179                	addi	sp,sp,-48
    8000278e:	f406                	sd	ra,40(sp)
    80002790:	f022                	sd	s0,32(sp)
    80002792:	ec26                	sd	s1,24(sp)
    80002794:	e84a                	sd	s2,16(sp)
    80002796:	e44e                	sd	s3,8(sp)
    80002798:	1800                	addi	s0,sp,48
    8000279a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000279c:	0000f497          	auipc	s1,0xf
    800027a0:	0b448493          	addi	s1,s1,180 # 80011850 <proc>
    800027a4:	00015997          	auipc	s3,0x15
    800027a8:	4ac98993          	addi	s3,s3,1196 # 80017c50 <tickslock>
    acquire(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	436080e7          	jalr	1078(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800027b6:	589c                	lw	a5,48(s1)
    800027b8:	01278d63          	beq	a5,s2,800027d2 <kill+0x46>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4da080e7          	jalr	1242(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c6:	19048493          	addi	s1,s1,400
    800027ca:	ff3491e3          	bne	s1,s3,800027ac <kill+0x20>
  }
  return -1;
    800027ce:	557d                	li	a0,-1
    800027d0:	a829                	j	800027ea <kill+0x5e>
      p->killed = 1;
    800027d2:	4785                	li	a5,1
    800027d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027d6:	4c98                	lw	a4,24(s1)
    800027d8:	4789                	li	a5,2
    800027da:	00f70f63          	beq	a4,a5,800027f8 <kill+0x6c>
      release(&p->lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4b8080e7          	jalr	1208(ra) # 80000c98 <release>
      return 0;
    800027e8:	4501                	li	a0,0
}
    800027ea:	70a2                	ld	ra,40(sp)
    800027ec:	7402                	ld	s0,32(sp)
    800027ee:	64e2                	ld	s1,24(sp)
    800027f0:	6942                	ld	s2,16(sp)
    800027f2:	69a2                	ld	s3,8(sp)
    800027f4:	6145                	addi	sp,sp,48
    800027f6:	8082                	ret
        p->state = RUNNABLE;
    800027f8:	478d                	li	a5,3
    800027fa:	cc9c                	sw	a5,24(s1)
        remove_proc_to_list(&sleeping_list, p);
    800027fc:	85a6                	mv	a1,s1
    800027fe:	00006517          	auipc	a0,0x6
    80002802:	1c250513          	addi	a0,a0,450 # 800089c0 <sleeping_list>
    80002806:	fffff097          	auipc	ra,0xfffff
    8000280a:	3f6080e7          	jalr	1014(ra) # 80001bfc <remove_proc_to_list>
        insert_proc_to_list(&cpus[p->last_cpu].runnable_list, p);
    8000280e:	1684a783          	lw	a5,360(s1)
    80002812:	0b000713          	li	a4,176
    80002816:	02e787b3          	mul	a5,a5,a4
    8000281a:	85a6                	mv	a1,s1
    8000281c:	0000f517          	auipc	a0,0xf
    80002820:	b0450513          	addi	a0,a0,-1276 # 80011320 <cpus+0x80>
    80002824:	953e                	add	a0,a0,a5
    80002826:	fffff097          	auipc	ra,0xfffff
    8000282a:	236080e7          	jalr	566(ra) # 80001a5c <insert_proc_to_list>
    8000282e:	bf45                	j	800027de <kill+0x52>

0000000080002830 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002830:	7179                	addi	sp,sp,-48
    80002832:	f406                	sd	ra,40(sp)
    80002834:	f022                	sd	s0,32(sp)
    80002836:	ec26                	sd	s1,24(sp)
    80002838:	e84a                	sd	s2,16(sp)
    8000283a:	e44e                	sd	s3,8(sp)
    8000283c:	e052                	sd	s4,0(sp)
    8000283e:	1800                	addi	s0,sp,48
    80002840:	84aa                	mv	s1,a0
    80002842:	892e                	mv	s2,a1
    80002844:	89b2                	mv	s3,a2
    80002846:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002848:	fffff097          	auipc	ra,0xfffff
    8000284c:	6fe080e7          	jalr	1790(ra) # 80001f46 <myproc>
  if(user_dst){
    80002850:	c08d                	beqz	s1,80002872 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002852:	86d2                	mv	a3,s4
    80002854:	864e                	mv	a2,s3
    80002856:	85ca                	mv	a1,s2
    80002858:	6928                	ld	a0,80(a0)
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	e18080e7          	jalr	-488(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002862:	70a2                	ld	ra,40(sp)
    80002864:	7402                	ld	s0,32(sp)
    80002866:	64e2                	ld	s1,24(sp)
    80002868:	6942                	ld	s2,16(sp)
    8000286a:	69a2                	ld	s3,8(sp)
    8000286c:	6a02                	ld	s4,0(sp)
    8000286e:	6145                	addi	sp,sp,48
    80002870:	8082                	ret
    memmove((char *)dst, src, len);
    80002872:	000a061b          	sext.w	a2,s4
    80002876:	85ce                	mv	a1,s3
    80002878:	854a                	mv	a0,s2
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	4c6080e7          	jalr	1222(ra) # 80000d40 <memmove>
    return 0;
    80002882:	8526                	mv	a0,s1
    80002884:	bff9                	j	80002862 <either_copyout+0x32>

0000000080002886 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002886:	7179                	addi	sp,sp,-48
    80002888:	f406                	sd	ra,40(sp)
    8000288a:	f022                	sd	s0,32(sp)
    8000288c:	ec26                	sd	s1,24(sp)
    8000288e:	e84a                	sd	s2,16(sp)
    80002890:	e44e                	sd	s3,8(sp)
    80002892:	e052                	sd	s4,0(sp)
    80002894:	1800                	addi	s0,sp,48
    80002896:	892a                	mv	s2,a0
    80002898:	84ae                	mv	s1,a1
    8000289a:	89b2                	mv	s3,a2
    8000289c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	6a8080e7          	jalr	1704(ra) # 80001f46 <myproc>
  if(user_src){
    800028a6:	c08d                	beqz	s1,800028c8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800028a8:	86d2                	mv	a3,s4
    800028aa:	864e                	mv	a2,s3
    800028ac:	85ca                	mv	a1,s2
    800028ae:	6928                	ld	a0,80(a0)
    800028b0:	fffff097          	auipc	ra,0xfffff
    800028b4:	e4e080e7          	jalr	-434(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028b8:	70a2                	ld	ra,40(sp)
    800028ba:	7402                	ld	s0,32(sp)
    800028bc:	64e2                	ld	s1,24(sp)
    800028be:	6942                	ld	s2,16(sp)
    800028c0:	69a2                	ld	s3,8(sp)
    800028c2:	6a02                	ld	s4,0(sp)
    800028c4:	6145                	addi	sp,sp,48
    800028c6:	8082                	ret
    memmove(dst, (char*)src, len);
    800028c8:	000a061b          	sext.w	a2,s4
    800028cc:	85ce                	mv	a1,s3
    800028ce:	854a                	mv	a0,s2
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	470080e7          	jalr	1136(ra) # 80000d40 <memmove>
    return 0;
    800028d8:	8526                	mv	a0,s1
    800028da:	bff9                	j	800028b8 <either_copyin+0x32>

00000000800028dc <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    800028dc:	715d                	addi	sp,sp,-80
    800028de:	e486                	sd	ra,72(sp)
    800028e0:	e0a2                	sd	s0,64(sp)
    800028e2:	fc26                	sd	s1,56(sp)
    800028e4:	f84a                	sd	s2,48(sp)
    800028e6:	f44e                	sd	s3,40(sp)
    800028e8:	f052                	sd	s4,32(sp)
    800028ea:	ec56                	sd	s5,24(sp)
    800028ec:	e85a                	sd	s6,16(sp)
    800028ee:	e45e                	sd	s7,8(sp)
    800028f0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028f2:	00005517          	auipc	a0,0x5
    800028f6:	7d650513          	addi	a0,a0,2006 # 800080c8 <digits+0x88>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c8e080e7          	jalr	-882(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002902:	0000f497          	auipc	s1,0xf
    80002906:	0a648493          	addi	s1,s1,166 # 800119a8 <proc+0x158>
    8000290a:	00015917          	auipc	s2,0x15
    8000290e:	49e90913          	addi	s2,s2,1182 # 80017da8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002912:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002914:	00006997          	auipc	s3,0x6
    80002918:	ab498993          	addi	s3,s3,-1356 # 800083c8 <digits+0x388>
    printf("%d %s %s", p->pid, state, p->name);
    8000291c:	00006a97          	auipc	s5,0x6
    80002920:	ab4a8a93          	addi	s5,s5,-1356 # 800083d0 <digits+0x390>
    printf("\n");
    80002924:	00005a17          	auipc	s4,0x5
    80002928:	7a4a0a13          	addi	s4,s4,1956 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000292c:	00006b97          	auipc	s7,0x6
    80002930:	afcb8b93          	addi	s7,s7,-1284 # 80008428 <states.1826>
    80002934:	a00d                	j	80002956 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002936:	ed86a583          	lw	a1,-296(a3)
    8000293a:	8556                	mv	a0,s5
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c4c080e7          	jalr	-948(ra) # 80000588 <printf>
    printf("\n");
    80002944:	8552                	mv	a0,s4
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	c42080e7          	jalr	-958(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000294e:	19048493          	addi	s1,s1,400
    80002952:	03248163          	beq	s1,s2,80002974 <procdump+0x98>
    if(p->state == UNUSED)
    80002956:	86a6                	mv	a3,s1
    80002958:	ec04a783          	lw	a5,-320(s1)
    8000295c:	dbed                	beqz	a5,8000294e <procdump+0x72>
      state = "???"; 
    8000295e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002960:	fcfb6be3          	bltu	s6,a5,80002936 <procdump+0x5a>
    80002964:	1782                	slli	a5,a5,0x20
    80002966:	9381                	srli	a5,a5,0x20
    80002968:	078e                	slli	a5,a5,0x3
    8000296a:	97de                	add	a5,a5,s7
    8000296c:	6390                	ld	a2,0(a5)
    8000296e:	f661                	bnez	a2,80002936 <procdump+0x5a>
      state = "???"; 
    80002970:	864e                	mv	a2,s3
    80002972:	b7d1                	j	80002936 <procdump+0x5a>
  }
}
    80002974:	60a6                	ld	ra,72(sp)
    80002976:	6406                	ld	s0,64(sp)
    80002978:	74e2                	ld	s1,56(sp)
    8000297a:	7942                	ld	s2,48(sp)
    8000297c:	79a2                	ld	s3,40(sp)
    8000297e:	7a02                	ld	s4,32(sp)
    80002980:	6ae2                	ld	s5,24(sp)
    80002982:	6b42                	ld	s6,16(sp)
    80002984:	6ba2                	ld	s7,8(sp)
    80002986:	6161                	addi	sp,sp,80
    80002988:	8082                	ret

000000008000298a <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    8000298a:	1101                	addi	sp,sp,-32
    8000298c:	ec06                	sd	ra,24(sp)
    8000298e:	e822                	sd	s0,16(sp)
    80002990:	e426                	sd	s1,8(sp)
    80002992:	e04a                	sd	s2,0(sp)
    80002994:	1000                	addi	s0,sp,32
    80002996:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	5ae080e7          	jalr	1454(ra) # 80001f46 <myproc>
  if(cpu_num >= 0 && cpu_num < CPUS){
    800029a0:	0004871b          	sext.w	a4,s1
    800029a4:	4791                	li	a5,4
    800029a6:	02e7e963          	bltu	a5,a4,800029d8 <set_cpu+0x4e>
    800029aa:	892a                	mv	s2,a0
    acquire(&p->lock);
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	238080e7          	jalr	568(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    800029b4:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    800029b8:	854a                	mv	a0,s2
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	2de080e7          	jalr	734(ra) # 80000c98 <release>

    yield();
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	bcc080e7          	jalr	-1076(ra) # 8000258e <yield>

    return cpu_num;
    800029ca:	8526                	mv	a0,s1
  }
  return -1;
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6902                	ld	s2,0(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret
  return -1;
    800029d8:	557d                	li	a0,-1
    800029da:	bfcd                	j	800029cc <set_cpu+0x42>

00000000800029dc <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    800029dc:	1141                	addi	sp,sp,-16
    800029de:	e406                	sd	ra,8(sp)
    800029e0:	e022                	sd	s0,0(sp)
    800029e2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	562080e7          	jalr	1378(ra) # 80001f46 <myproc>
  return p->last_cpu;
}
    800029ec:	16852503          	lw	a0,360(a0)
    800029f0:	60a2                	ld	ra,8(sp)
    800029f2:	6402                	ld	s0,0(sp)
    800029f4:	0141                	addi	sp,sp,16
    800029f6:	8082                	ret

00000000800029f8 <min_cpu_process_count>:

int
min_cpu_process_count(void){
    800029f8:	1141                	addi	sp,sp,-16
    800029fa:	e422                	sd	s0,8(sp)
    800029fc:	0800                	addi	s0,sp,16
  struct cpu *c, *min_cpu;
  min_cpu = cpus;
    800029fe:	0000f617          	auipc	a2,0xf
    80002a02:	8a260613          	addi	a2,a2,-1886 # 800112a0 <cpus>
  for(c = cpus + 1; c < &cpus[NCPU] && c != NULL && c->cpu_id<CPUS ; c++){
    80002a06:	0000f797          	auipc	a5,0xf
    80002a0a:	94a78793          	addi	a5,a5,-1718 # 80011350 <cpus+0xb0>
    80002a0e:	4591                	li	a1,4
    80002a10:	0000f517          	auipc	a0,0xf
    80002a14:	e1050513          	addi	a0,a0,-496 # 80011820 <pid_lock>
    80002a18:	a029                	j	80002a22 <min_cpu_process_count+0x2a>
    80002a1a:	0b078793          	addi	a5,a5,176
    80002a1e:	00a78c63          	beq	a5,a0,80002a36 <min_cpu_process_count+0x3e>
    80002a22:	0a07a703          	lw	a4,160(a5)
    80002a26:	00e5c863          	blt	a1,a4,80002a36 <min_cpu_process_count+0x3e>
    if (c->cpu_process_count < min_cpu->cpu_process_count)
    80002a2a:	77d4                	ld	a3,168(a5)
    80002a2c:	7658                	ld	a4,168(a2)
    80002a2e:	fee6f6e3          	bgeu	a3,a4,80002a1a <min_cpu_process_count+0x22>
    80002a32:	863e                	mv	a2,a5
    80002a34:	b7dd                	j	80002a1a <min_cpu_process_count+0x22>
      min_cpu = c;
  }
  return min_cpu->cpu_id;   
}
    80002a36:	0a062503          	lw	a0,160(a2)
    80002a3a:	6422                	ld	s0,8(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <cpu_process_count>:

int
cpu_process_count(int cpu_num){
    80002a40:	1141                	addi	sp,sp,-16
    80002a42:	e422                	sd	s0,8(sp)
    80002a44:	0800                	addi	s0,sp,16
  if (cpu_num > 0 && cpu_num < CPUS && &cpus[cpu_num] != NULL) 
    80002a46:	fff5071b          	addiw	a4,a0,-1
    80002a4a:	478d                	li	a5,3
    80002a4c:	02e7e063          	bltu	a5,a4,80002a6c <cpu_process_count+0x2c>
    return cpus[cpu_num].cpu_process_count;
    80002a50:	0b000793          	li	a5,176
    80002a54:	02f50533          	mul	a0,a0,a5
    80002a58:	0000f797          	auipc	a5,0xf
    80002a5c:	84878793          	addi	a5,a5,-1976 # 800112a0 <cpus>
    80002a60:	953e                	add	a0,a0,a5
    80002a62:	0a852503          	lw	a0,168(a0)
  return -1;
}
    80002a66:	6422                	ld	s0,8(sp)
    80002a68:	0141                	addi	sp,sp,16
    80002a6a:	8082                	ret
  return -1;
    80002a6c:	557d                	li	a0,-1
    80002a6e:	bfe5                	j	80002a66 <cpu_process_count+0x26>

0000000080002a70 <increment_cpu_process_count>:

void 
increment_cpu_process_count(struct cpu *c){
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	e04a                	sd	s2,0(sp)
    80002a7a:	1000                	addi	s0,sp,32
    80002a7c:	84aa                	mv	s1,a0
  uint64 curr_count;
  do{
    curr_count = c->cpu_process_count;
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002a7e:	0a850913          	addi	s2,a0,168
    curr_count = c->cpu_process_count;
    80002a82:	74cc                	ld	a1,168(s1)
  }while(cas(&(c->cpu_process_count), curr_count, curr_count+1));
    80002a84:	0015861b          	addiw	a2,a1,1
    80002a88:	2581                	sext.w	a1,a1
    80002a8a:	854a                	mv	a0,s2
    80002a8c:	00004097          	auipc	ra,0x4
    80002a90:	13a080e7          	jalr	314(ra) # 80006bc6 <cas>
    80002a94:	2501                	sext.w	a0,a0
    80002a96:	f575                	bnez	a0,80002a82 <increment_cpu_process_count+0x12>
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6902                	ld	s2,0(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret

0000000080002aa4 <fork>:
{
    80002aa4:	7139                	addi	sp,sp,-64
    80002aa6:	fc06                	sd	ra,56(sp)
    80002aa8:	f822                	sd	s0,48(sp)
    80002aaa:	f426                	sd	s1,40(sp)
    80002aac:	f04a                	sd	s2,32(sp)
    80002aae:	ec4e                	sd	s3,24(sp)
    80002ab0:	e852                	sd	s4,16(sp)
    80002ab2:	e456                	sd	s5,8(sp)
    80002ab4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	490080e7          	jalr	1168(ra) # 80001f46 <myproc>
    80002abe:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	6ae080e7          	jalr	1710(ra) # 8000216e <allocproc>
    80002ac8:	14050663          	beqz	a0,80002c14 <fork+0x170>
    80002acc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002ace:	04893603          	ld	a2,72(s2)
    80002ad2:	692c                	ld	a1,80(a0)
    80002ad4:	05093503          	ld	a0,80(s2)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	a96080e7          	jalr	-1386(ra) # 8000156e <uvmcopy>
    80002ae0:	04054663          	bltz	a0,80002b2c <fork+0x88>
  np->sz = p->sz;
    80002ae4:	04893783          	ld	a5,72(s2)
    80002ae8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002aec:	05893683          	ld	a3,88(s2)
    80002af0:	87b6                	mv	a5,a3
    80002af2:	0589b703          	ld	a4,88(s3)
    80002af6:	12068693          	addi	a3,a3,288
    80002afa:	0007b803          	ld	a6,0(a5)
    80002afe:	6788                	ld	a0,8(a5)
    80002b00:	6b8c                	ld	a1,16(a5)
    80002b02:	6f90                	ld	a2,24(a5)
    80002b04:	01073023          	sd	a6,0(a4)
    80002b08:	e708                	sd	a0,8(a4)
    80002b0a:	eb0c                	sd	a1,16(a4)
    80002b0c:	ef10                	sd	a2,24(a4)
    80002b0e:	02078793          	addi	a5,a5,32
    80002b12:	02070713          	addi	a4,a4,32
    80002b16:	fed792e3          	bne	a5,a3,80002afa <fork+0x56>
  np->trapframe->a0 = 0;
    80002b1a:	0589b783          	ld	a5,88(s3)
    80002b1e:	0607b823          	sd	zero,112(a5)
    80002b22:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002b26:	15000a13          	li	s4,336
    80002b2a:	a03d                	j	80002b58 <fork+0xb4>
    freeproc(np);
    80002b2c:	854e                	mv	a0,s3
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	5c4080e7          	jalr	1476(ra) # 800020f2 <freeproc>
    release(&np->lock);
    80002b36:	854e                	mv	a0,s3
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
    return -1;
    80002b40:	5afd                	li	s5,-1
    80002b42:	a87d                	j	80002c00 <fork+0x15c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002b44:	00002097          	auipc	ra,0x2
    80002b48:	33a080e7          	jalr	826(ra) # 80004e7e <filedup>
    80002b4c:	009987b3          	add	a5,s3,s1
    80002b50:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002b52:	04a1                	addi	s1,s1,8
    80002b54:	01448763          	beq	s1,s4,80002b62 <fork+0xbe>
    if(p->ofile[i])
    80002b58:	009907b3          	add	a5,s2,s1
    80002b5c:	6388                	ld	a0,0(a5)
    80002b5e:	f17d                	bnez	a0,80002b44 <fork+0xa0>
    80002b60:	bfcd                	j	80002b52 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002b62:	15093503          	ld	a0,336(s2)
    80002b66:	00001097          	auipc	ra,0x1
    80002b6a:	48e080e7          	jalr	1166(ra) # 80003ff4 <idup>
    80002b6e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002b72:	4641                	li	a2,16
    80002b74:	15890593          	addi	a1,s2,344
    80002b78:	15898513          	addi	a0,s3,344
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	2b6080e7          	jalr	694(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002b84:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80002b88:	854e                	mv	a0,s3
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	10e080e7          	jalr	270(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002b92:	0000ea17          	auipc	s4,0xe
    80002b96:	70ea0a13          	addi	s4,s4,1806 # 800112a0 <cpus>
    80002b9a:	0000f497          	auipc	s1,0xf
    80002b9e:	c9e48493          	addi	s1,s1,-866 # 80011838 <wait_lock>
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	040080e7          	jalr	64(ra) # 80000be4 <acquire>
  np->parent = p;
    80002bac:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002bba:	854e                	mv	a0,s3
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	028080e7          	jalr	40(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002bc4:	478d                	li	a5,3
    80002bc6:	00f9ac23          	sw	a5,24(s3)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002bca:	16892483          	lw	s1,360(s2)
    80002bce:	1699a423          	sw	s1,360(s3)
  struct cpu *c = &cpus[np->last_cpu];
    80002bd2:	0b000513          	li	a0,176
    80002bd6:	02a484b3          	mul	s1,s1,a0
  increment_cpu_process_count(c);
    80002bda:	009a0533          	add	a0,s4,s1
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	e92080e7          	jalr	-366(ra) # 80002a70 <increment_cpu_process_count>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002be6:	08048513          	addi	a0,s1,128
    80002bea:	85ce                	mv	a1,s3
    80002bec:	9552                	add	a0,a0,s4
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	e6e080e7          	jalr	-402(ra) # 80001a5c <insert_proc_to_list>
  release(&np->lock);
    80002bf6:	854e                	mv	a0,s3
    80002bf8:	ffffe097          	auipc	ra,0xffffe
    80002bfc:	0a0080e7          	jalr	160(ra) # 80000c98 <release>
}
    80002c00:	8556                	mv	a0,s5
    80002c02:	70e2                	ld	ra,56(sp)
    80002c04:	7442                	ld	s0,48(sp)
    80002c06:	74a2                	ld	s1,40(sp)
    80002c08:	7902                	ld	s2,32(sp)
    80002c0a:	69e2                	ld	s3,24(sp)
    80002c0c:	6a42                	ld	s4,16(sp)
    80002c0e:	6aa2                	ld	s5,8(sp)
    80002c10:	6121                	addi	sp,sp,64
    80002c12:	8082                	ret
    return -1;
    80002c14:	5afd                	li	s5,-1
    80002c16:	b7ed                	j	80002c00 <fork+0x15c>

0000000080002c18 <wakeup>:
{
    80002c18:	7159                	addi	sp,sp,-112
    80002c1a:	f486                	sd	ra,104(sp)
    80002c1c:	f0a2                	sd	s0,96(sp)
    80002c1e:	eca6                	sd	s1,88(sp)
    80002c20:	e8ca                	sd	s2,80(sp)
    80002c22:	e4ce                	sd	s3,72(sp)
    80002c24:	e0d2                	sd	s4,64(sp)
    80002c26:	fc56                	sd	s5,56(sp)
    80002c28:	f85a                	sd	s6,48(sp)
    80002c2a:	f45e                	sd	s7,40(sp)
    80002c2c:	f062                	sd	s8,32(sp)
    80002c2e:	ec66                	sd	s9,24(sp)
    80002c30:	e86a                	sd	s10,16(sp)
    80002c32:	e46e                	sd	s11,8(sp)
    80002c34:	1880                	addi	s0,sp,112
    80002c36:	8c2a                	mv	s8,a0
  int curr = get_head(&sleeping_list);
    80002c38:	00006517          	auipc	a0,0x6
    80002c3c:	d8850513          	addi	a0,a0,-632 # 800089c0 <sleeping_list>
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	dc6080e7          	jalr	-570(ra) # 80001a06 <get_head>
  while(curr != -1) {
    80002c48:	57fd                	li	a5,-1
    80002c4a:	08f50e63          	beq	a0,a5,80002ce6 <wakeup+0xce>
    80002c4e:	892a                	mv	s2,a0
    p = &proc[curr];
    80002c50:	19000a93          	li	s5,400
    80002c54:	0000fa17          	auipc	s4,0xf
    80002c58:	bfca0a13          	addi	s4,s4,-1028 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c5c:	4b89                	li	s7,2
        p->state = RUNNABLE;
    80002c5e:	4d8d                	li	s11,3
    80002c60:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002c64:	0000ec97          	auipc	s9,0xe
    80002c68:	63cc8c93          	addi	s9,s9,1596 # 800112a0 <cpus>
  while(curr != -1) {
    80002c6c:	5b7d                	li	s6,-1
    80002c6e:	a801                	j	80002c7e <wakeup+0x66>
      release(&p->lock);
    80002c70:	8526                	mv	a0,s1
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	026080e7          	jalr	38(ra) # 80000c98 <release>
  while(curr != -1) {
    80002c7a:	07690663          	beq	s2,s6,80002ce6 <wakeup+0xce>
    p = &proc[curr];
    80002c7e:	035904b3          	mul	s1,s2,s5
    80002c82:	94d2                	add	s1,s1,s4
    curr = p->next_index;
    80002c84:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	2be080e7          	jalr	702(ra) # 80001f46 <myproc>
    80002c90:	fea485e3          	beq	s1,a0,80002c7a <wakeup+0x62>
      acquire(&p->lock);
    80002c94:	8526                	mv	a0,s1
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	f4e080e7          	jalr	-178(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c9e:	4c9c                	lw	a5,24(s1)
    80002ca0:	fd7798e3          	bne	a5,s7,80002c70 <wakeup+0x58>
    80002ca4:	709c                	ld	a5,32(s1)
    80002ca6:	fd8795e3          	bne	a5,s8,80002c70 <wakeup+0x58>
        remove_proc_to_list(&sleeping_list, p);
    80002caa:	85a6                	mv	a1,s1
    80002cac:	00006517          	auipc	a0,0x6
    80002cb0:	d1450513          	addi	a0,a0,-748 # 800089c0 <sleeping_list>
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	f48080e7          	jalr	-184(ra) # 80001bfc <remove_proc_to_list>
        p->state = RUNNABLE;
    80002cbc:	01b4ac23          	sw	s11,24(s1)
        c = &cpus[p->last_cpu];
    80002cc0:	1684a983          	lw	s3,360(s1)
    80002cc4:	03a989b3          	mul	s3,s3,s10
        increment_cpu_process_count(c);
    80002cc8:	013c8533          	add	a0,s9,s3
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	da4080e7          	jalr	-604(ra) # 80002a70 <increment_cpu_process_count>
        insert_proc_to_list(&(c->runnable_list), p);
    80002cd4:	08098513          	addi	a0,s3,128
    80002cd8:	85a6                	mv	a1,s1
    80002cda:	9566                	add	a0,a0,s9
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	d80080e7          	jalr	-640(ra) # 80001a5c <insert_proc_to_list>
    80002ce4:	b771                	j	80002c70 <wakeup+0x58>
}
    80002ce6:	70a6                	ld	ra,104(sp)
    80002ce8:	7406                	ld	s0,96(sp)
    80002cea:	64e6                	ld	s1,88(sp)
    80002cec:	6946                	ld	s2,80(sp)
    80002cee:	69a6                	ld	s3,72(sp)
    80002cf0:	6a06                	ld	s4,64(sp)
    80002cf2:	7ae2                	ld	s5,56(sp)
    80002cf4:	7b42                	ld	s6,48(sp)
    80002cf6:	7ba2                	ld	s7,40(sp)
    80002cf8:	7c02                	ld	s8,32(sp)
    80002cfa:	6ce2                	ld	s9,24(sp)
    80002cfc:	6d42                	ld	s10,16(sp)
    80002cfe:	6da2                	ld	s11,8(sp)
    80002d00:	6165                	addi	sp,sp,112
    80002d02:	8082                	ret

0000000080002d04 <reparent>:
{
    80002d04:	7179                	addi	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	e84a                	sd	s2,16(sp)
    80002d0e:	e44e                	sd	s3,8(sp)
    80002d10:	e052                	sd	s4,0(sp)
    80002d12:	1800                	addi	s0,sp,48
    80002d14:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d16:	0000f497          	auipc	s1,0xf
    80002d1a:	b3a48493          	addi	s1,s1,-1222 # 80011850 <proc>
      pp->parent = initproc;
    80002d1e:	00006a17          	auipc	s4,0x6
    80002d22:	30aa0a13          	addi	s4,s4,778 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d26:	00015997          	auipc	s3,0x15
    80002d2a:	f2a98993          	addi	s3,s3,-214 # 80017c50 <tickslock>
    80002d2e:	a029                	j	80002d38 <reparent+0x34>
    80002d30:	19048493          	addi	s1,s1,400
    80002d34:	01348d63          	beq	s1,s3,80002d4e <reparent+0x4a>
    if(pp->parent == p){
    80002d38:	7c9c                	ld	a5,56(s1)
    80002d3a:	ff279be3          	bne	a5,s2,80002d30 <reparent+0x2c>
      pp->parent = initproc;
    80002d3e:	000a3503          	ld	a0,0(s4)
    80002d42:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	ed4080e7          	jalr	-300(ra) # 80002c18 <wakeup>
    80002d4c:	b7d5                	j	80002d30 <reparent+0x2c>
}
    80002d4e:	70a2                	ld	ra,40(sp)
    80002d50:	7402                	ld	s0,32(sp)
    80002d52:	64e2                	ld	s1,24(sp)
    80002d54:	6942                	ld	s2,16(sp)
    80002d56:	69a2                	ld	s3,8(sp)
    80002d58:	6a02                	ld	s4,0(sp)
    80002d5a:	6145                	addi	sp,sp,48
    80002d5c:	8082                	ret

0000000080002d5e <exit>:
{
    80002d5e:	7179                	addi	sp,sp,-48
    80002d60:	f406                	sd	ra,40(sp)
    80002d62:	f022                	sd	s0,32(sp)
    80002d64:	ec26                	sd	s1,24(sp)
    80002d66:	e84a                	sd	s2,16(sp)
    80002d68:	e44e                	sd	s3,8(sp)
    80002d6a:	e052                	sd	s4,0(sp)
    80002d6c:	1800                	addi	s0,sp,48
    80002d6e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	1d6080e7          	jalr	470(ra) # 80001f46 <myproc>
    80002d78:	89aa                	mv	s3,a0
  if(p == initproc)
    80002d7a:	00006797          	auipc	a5,0x6
    80002d7e:	2ae7b783          	ld	a5,686(a5) # 80009028 <initproc>
    80002d82:	0d050493          	addi	s1,a0,208
    80002d86:	15050913          	addi	s2,a0,336
    80002d8a:	02a79363          	bne	a5,a0,80002db0 <exit+0x52>
    panic("init exiting");
    80002d8e:	00005517          	auipc	a0,0x5
    80002d92:	65250513          	addi	a0,a0,1618 # 800083e0 <digits+0x3a0>
    80002d96:	ffffd097          	auipc	ra,0xffffd
    80002d9a:	7a8080e7          	jalr	1960(ra) # 8000053e <panic>
      fileclose(f);
    80002d9e:	00002097          	auipc	ra,0x2
    80002da2:	132080e7          	jalr	306(ra) # 80004ed0 <fileclose>
      p->ofile[fd] = 0;
    80002da6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002daa:	04a1                	addi	s1,s1,8
    80002dac:	01248563          	beq	s1,s2,80002db6 <exit+0x58>
    if(p->ofile[fd]){
    80002db0:	6088                	ld	a0,0(s1)
    80002db2:	f575                	bnez	a0,80002d9e <exit+0x40>
    80002db4:	bfdd                	j	80002daa <exit+0x4c>
  begin_op();
    80002db6:	00002097          	auipc	ra,0x2
    80002dba:	c4e080e7          	jalr	-946(ra) # 80004a04 <begin_op>
  iput(p->cwd);
    80002dbe:	1509b503          	ld	a0,336(s3)
    80002dc2:	00001097          	auipc	ra,0x1
    80002dc6:	42a080e7          	jalr	1066(ra) # 800041ec <iput>
  end_op();
    80002dca:	00002097          	auipc	ra,0x2
    80002dce:	cba080e7          	jalr	-838(ra) # 80004a84 <end_op>
  p->cwd = 0;
    80002dd2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002dd6:	0000f497          	auipc	s1,0xf
    80002dda:	a6248493          	addi	s1,s1,-1438 # 80011838 <wait_lock>
    80002dde:	8526                	mv	a0,s1
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	e04080e7          	jalr	-508(ra) # 80000be4 <acquire>
  reparent(p);
    80002de8:	854e                	mv	a0,s3
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	f1a080e7          	jalr	-230(ra) # 80002d04 <reparent>
  wakeup(p->parent);
    80002df2:	0389b503          	ld	a0,56(s3)
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	e22080e7          	jalr	-478(ra) # 80002c18 <wakeup>
  acquire(&p->lock);
    80002dfe:	854e                	mv	a0,s3
    80002e00:	ffffe097          	auipc	ra,0xffffe
    80002e04:	de4080e7          	jalr	-540(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002e08:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002e0c:	4795                	li	a5,5
    80002e0e:	00f9ac23          	sw	a5,24(s3)
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002e12:	85ce                	mv	a1,s3
    80002e14:	00006517          	auipc	a0,0x6
    80002e18:	bcc50513          	addi	a0,a0,-1076 # 800089e0 <zombie_list>
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	c40080e7          	jalr	-960(ra) # 80001a5c <insert_proc_to_list>
  release(&wait_lock);
    80002e24:	8526                	mv	a0,s1
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	e72080e7          	jalr	-398(ra) # 80000c98 <release>
  sched();
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	67e080e7          	jalr	1662(ra) # 800024ac <sched>
  panic("zombie exit");
    80002e36:	00005517          	auipc	a0,0x5
    80002e3a:	5ba50513          	addi	a0,a0,1466 # 800083f0 <digits+0x3b0>
    80002e3e:	ffffd097          	auipc	ra,0xffffd
    80002e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>

0000000080002e46 <steal_process>:

void
steal_process(struct cpu *curr_c){  
    80002e46:	7119                	addi	sp,sp,-128
    80002e48:	fc86                	sd	ra,120(sp)
    80002e4a:	f8a2                	sd	s0,112(sp)
    80002e4c:	f4a6                	sd	s1,104(sp)
    80002e4e:	f0ca                	sd	s2,96(sp)
    80002e50:	ecce                	sd	s3,88(sp)
    80002e52:	e8d2                	sd	s4,80(sp)
    80002e54:	e4d6                	sd	s5,72(sp)
    80002e56:	e0da                	sd	s6,64(sp)
    80002e58:	fc5e                	sd	s7,56(sp)
    80002e5a:	f862                	sd	s8,48(sp)
    80002e5c:	f466                	sd	s9,40(sp)
    80002e5e:	f06a                	sd	s10,32(sp)
    80002e60:	ec6e                	sd	s11,24(sp)
    80002e62:	0100                	addi	s0,sp,128
    80002e64:	892a                	mv	s2,a0
  struct cpu *c;
  struct proc *p;
  struct _list *lst;
  int stolen_process;
  int succeed = 0;
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002e66:	0000e497          	auipc	s1,0xe
    80002e6a:	43a48493          	addi	s1,s1,1082 # 800112a0 <cpus>
    80002e6e:	4a91                	li	s5,4
      if(c->cpu_id != curr_c->cpu_id){
        lst = &c->runnable_list;
        acquire(&lst->head_lock);
        if(!isEmpty(lst)){ 
    80002e70:	5c7d                	li	s8,-1
          stolen_process = lst->head;
          p = &proc[stolen_process];
    80002e72:	19000d93          	li	s11,400
    80002e76:	0000fd17          	auipc	s10,0xf
    80002e7a:	9dad0d13          	addi	s10,s10,-1574 # 80011850 <proc>
          acquire(&p->lock);
          if(!isEmpty(lst) && lst->head == stolen_process){ // p is still the head
            remove_head_from_list(lst);
            insert_proc_to_list(&curr_c->runnable_list, p);
    80002e7e:	08050793          	addi	a5,a0,128
    80002e82:	f8f43023          	sd	a5,-128(s0)
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002e86:	0000fb97          	auipc	s7,0xf
    80002e8a:	99ab8b93          	addi	s7,s7,-1638 # 80011820 <pid_lock>
    80002e8e:	a815                	j	80002ec2 <steal_process+0x7c>
        acquire(&lst->head_lock);
    80002e90:	f8943423          	sd	s1,-120(s0)
    80002e94:	08848993          	addi	s3,s1,136
    80002e98:	854e                	mv	a0,s3
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	d4a080e7          	jalr	-694(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002ea2:	0804aa03          	lw	s4,128(s1)
    80002ea6:	4b01                	li	s6,0
        if(!isEmpty(lst)){ 
    80002ea8:	038a1863          	bne	s4,s8,80002ed8 <steal_process+0x92>
            increment_cpu_process_count(curr_c); 
            succeed = 1;
          }
          release(&p->lock);
        }
        release(&lst->head_lock);
    80002eac:	854e                	mv	a0,s3
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002eb6:	0b048493          	addi	s1,s1,176
    80002eba:	060b1d63          	bnez	s6,80002f34 <steal_process+0xee>
    80002ebe:	07748b63          	beq	s1,s7,80002f34 <steal_process+0xee>
    80002ec2:	0a04a783          	lw	a5,160(s1)
    80002ec6:	06fac763          	blt	s5,a5,80002f34 <steal_process+0xee>
      if(c->cpu_id != curr_c->cpu_id){
    80002eca:	0a092703          	lw	a4,160(s2)
    80002ece:	fcf711e3          	bne	a4,a5,80002e90 <steal_process+0x4a>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002ed2:	0b048493          	addi	s1,s1,176
    80002ed6:	b7e5                	j	80002ebe <steal_process+0x78>
          p = &proc[stolen_process];
    80002ed8:	03ba0cb3          	mul	s9,s4,s11
    80002edc:	9cea                	add	s9,s9,s10
          acquire(&p->lock);
    80002ede:	8566                	mv	a0,s9
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	d04080e7          	jalr	-764(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002ee8:	0804a783          	lw	a5,128(s1)
          if(!isEmpty(lst) && lst->head == stolen_process){ // p is still the head
    80002eec:	01878463          	beq	a5,s8,80002ef4 <steal_process+0xae>
    80002ef0:	00fa0863          	beq	s4,a5,80002f00 <steal_process+0xba>
          release(&p->lock);
    80002ef4:	8566                	mv	a0,s9
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	da2080e7          	jalr	-606(ra) # 80000c98 <release>
    80002efe:	b77d                	j	80002eac <steal_process+0x66>
            remove_head_from_list(lst);
    80002f00:	f8843783          	ld	a5,-120(s0)
    80002f04:	08078513          	addi	a0,a5,128
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	c40080e7          	jalr	-960(ra) # 80001b48 <remove_head_from_list>
            insert_proc_to_list(&curr_c->runnable_list, p);
    80002f10:	85e6                	mv	a1,s9
    80002f12:	f8043503          	ld	a0,-128(s0)
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	b46080e7          	jalr	-1210(ra) # 80001a5c <insert_proc_to_list>
            p->last_cpu = curr_c->cpu_id;
    80002f1e:	0a092703          	lw	a4,160(s2)
    80002f22:	16eca423          	sw	a4,360(s9)
            increment_cpu_process_count(curr_c); 
    80002f26:	854a                	mv	a0,s2
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	b48080e7          	jalr	-1208(ra) # 80002a70 <increment_cpu_process_count>
            succeed = 1;
    80002f30:	4b05                	li	s6,1
    80002f32:	b7c9                	j	80002ef4 <steal_process+0xae>
      }
  }
    80002f34:	70e6                	ld	ra,120(sp)
    80002f36:	7446                	ld	s0,112(sp)
    80002f38:	74a6                	ld	s1,104(sp)
    80002f3a:	7906                	ld	s2,96(sp)
    80002f3c:	69e6                	ld	s3,88(sp)
    80002f3e:	6a46                	ld	s4,80(sp)
    80002f40:	6aa6                	ld	s5,72(sp)
    80002f42:	6b06                	ld	s6,64(sp)
    80002f44:	7be2                	ld	s7,56(sp)
    80002f46:	7c42                	ld	s8,48(sp)
    80002f48:	7ca2                	ld	s9,40(sp)
    80002f4a:	7d02                	ld	s10,32(sp)
    80002f4c:	6de2                	ld	s11,24(sp)
    80002f4e:	6109                	addi	sp,sp,128
    80002f50:	8082                	ret

0000000080002f52 <swtch>:
    80002f52:	00153023          	sd	ra,0(a0)
    80002f56:	00253423          	sd	sp,8(a0)
    80002f5a:	e900                	sd	s0,16(a0)
    80002f5c:	ed04                	sd	s1,24(a0)
    80002f5e:	03253023          	sd	s2,32(a0)
    80002f62:	03353423          	sd	s3,40(a0)
    80002f66:	03453823          	sd	s4,48(a0)
    80002f6a:	03553c23          	sd	s5,56(a0)
    80002f6e:	05653023          	sd	s6,64(a0)
    80002f72:	05753423          	sd	s7,72(a0)
    80002f76:	05853823          	sd	s8,80(a0)
    80002f7a:	05953c23          	sd	s9,88(a0)
    80002f7e:	07a53023          	sd	s10,96(a0)
    80002f82:	07b53423          	sd	s11,104(a0)
    80002f86:	0005b083          	ld	ra,0(a1)
    80002f8a:	0085b103          	ld	sp,8(a1)
    80002f8e:	6980                	ld	s0,16(a1)
    80002f90:	6d84                	ld	s1,24(a1)
    80002f92:	0205b903          	ld	s2,32(a1)
    80002f96:	0285b983          	ld	s3,40(a1)
    80002f9a:	0305ba03          	ld	s4,48(a1)
    80002f9e:	0385ba83          	ld	s5,56(a1)
    80002fa2:	0405bb03          	ld	s6,64(a1)
    80002fa6:	0485bb83          	ld	s7,72(a1)
    80002faa:	0505bc03          	ld	s8,80(a1)
    80002fae:	0585bc83          	ld	s9,88(a1)
    80002fb2:	0605bd03          	ld	s10,96(a1)
    80002fb6:	0685bd83          	ld	s11,104(a1)
    80002fba:	8082                	ret

0000000080002fbc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002fbc:	1141                	addi	sp,sp,-16
    80002fbe:	e406                	sd	ra,8(sp)
    80002fc0:	e022                	sd	s0,0(sp)
    80002fc2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002fc4:	00005597          	auipc	a1,0x5
    80002fc8:	49458593          	addi	a1,a1,1172 # 80008458 <states.1826+0x30>
    80002fcc:	00015517          	auipc	a0,0x15
    80002fd0:	c8450513          	addi	a0,a0,-892 # 80017c50 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	b80080e7          	jalr	-1152(ra) # 80000b54 <initlock>
}
    80002fdc:	60a2                	ld	ra,8(sp)
    80002fde:	6402                	ld	s0,0(sp)
    80002fe0:	0141                	addi	sp,sp,16
    80002fe2:	8082                	ret

0000000080002fe4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002fe4:	1141                	addi	sp,sp,-16
    80002fe6:	e422                	sd	s0,8(sp)
    80002fe8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fea:	00003797          	auipc	a5,0x3
    80002fee:	50678793          	addi	a5,a5,1286 # 800064f0 <kernelvec>
    80002ff2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ff6:	6422                	ld	s0,8(sp)
    80002ff8:	0141                	addi	sp,sp,16
    80002ffa:	8082                	ret

0000000080002ffc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ffc:	1141                	addi	sp,sp,-16
    80002ffe:	e406                	sd	ra,8(sp)
    80003000:	e022                	sd	s0,0(sp)
    80003002:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	f42080e7          	jalr	-190(ra) # 80001f46 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000300c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003010:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003012:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003016:	00004617          	auipc	a2,0x4
    8000301a:	fea60613          	addi	a2,a2,-22 # 80007000 <_trampoline>
    8000301e:	00004697          	auipc	a3,0x4
    80003022:	fe268693          	addi	a3,a3,-30 # 80007000 <_trampoline>
    80003026:	8e91                	sub	a3,a3,a2
    80003028:	040007b7          	lui	a5,0x4000
    8000302c:	17fd                	addi	a5,a5,-1
    8000302e:	07b2                	slli	a5,a5,0xc
    80003030:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003032:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003036:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003038:	180026f3          	csrr	a3,satp
    8000303c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000303e:	6d38                	ld	a4,88(a0)
    80003040:	6134                	ld	a3,64(a0)
    80003042:	6585                	lui	a1,0x1
    80003044:	96ae                	add	a3,a3,a1
    80003046:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003048:	6d38                	ld	a4,88(a0)
    8000304a:	00000697          	auipc	a3,0x0
    8000304e:	13868693          	addi	a3,a3,312 # 80003182 <usertrap>
    80003052:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003054:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003056:	8692                	mv	a3,tp
    80003058:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000305a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000305e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003062:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003066:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000306a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000306c:	6f18                	ld	a4,24(a4)
    8000306e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003072:	692c                	ld	a1,80(a0)
    80003074:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003076:	00004717          	auipc	a4,0x4
    8000307a:	01a70713          	addi	a4,a4,26 # 80007090 <userret>
    8000307e:	8f11                	sub	a4,a4,a2
    80003080:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003082:	577d                	li	a4,-1
    80003084:	177e                	slli	a4,a4,0x3f
    80003086:	8dd9                	or	a1,a1,a4
    80003088:	02000537          	lui	a0,0x2000
    8000308c:	157d                	addi	a0,a0,-1
    8000308e:	0536                	slli	a0,a0,0xd
    80003090:	9782                	jalr	a5
}
    80003092:	60a2                	ld	ra,8(sp)
    80003094:	6402                	ld	s0,0(sp)
    80003096:	0141                	addi	sp,sp,16
    80003098:	8082                	ret

000000008000309a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030a4:	00015497          	auipc	s1,0x15
    800030a8:	bac48493          	addi	s1,s1,-1108 # 80017c50 <tickslock>
    800030ac:	8526                	mv	a0,s1
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	b36080e7          	jalr	-1226(ra) # 80000be4 <acquire>
  ticks++;
    800030b6:	00006517          	auipc	a0,0x6
    800030ba:	f7a50513          	addi	a0,a0,-134 # 80009030 <ticks>
    800030be:	411c                	lw	a5,0(a0)
    800030c0:	2785                	addiw	a5,a5,1
    800030c2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	b54080e7          	jalr	-1196(ra) # 80002c18 <wakeup>
  release(&tickslock);
    800030cc:	8526                	mv	a0,s1
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	bca080e7          	jalr	-1078(ra) # 80000c98 <release>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6105                	addi	sp,sp,32
    800030de:	8082                	ret

00000000800030e0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	e426                	sd	s1,8(sp)
    800030e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ea:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800030ee:	00074d63          	bltz	a4,80003108 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800030f2:	57fd                	li	a5,-1
    800030f4:	17fe                	slli	a5,a5,0x3f
    800030f6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800030f8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800030fa:	06f70363          	beq	a4,a5,80003160 <devintr+0x80>
  }
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	64a2                	ld	s1,8(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret
     (scause & 0xff) == 9){
    80003108:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000310c:	46a5                	li	a3,9
    8000310e:	fed792e3          	bne	a5,a3,800030f2 <devintr+0x12>
    int irq = plic_claim();
    80003112:	00003097          	auipc	ra,0x3
    80003116:	4e6080e7          	jalr	1254(ra) # 800065f8 <plic_claim>
    8000311a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000311c:	47a9                	li	a5,10
    8000311e:	02f50763          	beq	a0,a5,8000314c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003122:	4785                	li	a5,1
    80003124:	02f50963          	beq	a0,a5,80003156 <devintr+0x76>
    return 1;
    80003128:	4505                	li	a0,1
    } else if(irq){
    8000312a:	d8f1                	beqz	s1,800030fe <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000312c:	85a6                	mv	a1,s1
    8000312e:	00005517          	auipc	a0,0x5
    80003132:	33250513          	addi	a0,a0,818 # 80008460 <states.1826+0x38>
    80003136:	ffffd097          	auipc	ra,0xffffd
    8000313a:	452080e7          	jalr	1106(ra) # 80000588 <printf>
      plic_complete(irq);
    8000313e:	8526                	mv	a0,s1
    80003140:	00003097          	auipc	ra,0x3
    80003144:	4dc080e7          	jalr	1244(ra) # 8000661c <plic_complete>
    return 1;
    80003148:	4505                	li	a0,1
    8000314a:	bf55                	j	800030fe <devintr+0x1e>
      uartintr();
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	85c080e7          	jalr	-1956(ra) # 800009a8 <uartintr>
    80003154:	b7ed                	j	8000313e <devintr+0x5e>
      virtio_disk_intr();
    80003156:	00004097          	auipc	ra,0x4
    8000315a:	9a6080e7          	jalr	-1626(ra) # 80006afc <virtio_disk_intr>
    8000315e:	b7c5                	j	8000313e <devintr+0x5e>
    if(cpuid() == 0){
    80003160:	fffff097          	auipc	ra,0xfffff
    80003164:	db4080e7          	jalr	-588(ra) # 80001f14 <cpuid>
    80003168:	c901                	beqz	a0,80003178 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000316a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000316e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003170:	14479073          	csrw	sip,a5
    return 2;
    80003174:	4509                	li	a0,2
    80003176:	b761                	j	800030fe <devintr+0x1e>
      clockintr();
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	f22080e7          	jalr	-222(ra) # 8000309a <clockintr>
    80003180:	b7ed                	j	8000316a <devintr+0x8a>

0000000080003182 <usertrap>:
{
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	e04a                	sd	s2,0(sp)
    8000318c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000318e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003192:	1007f793          	andi	a5,a5,256
    80003196:	e3ad                	bnez	a5,800031f8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003198:	00003797          	auipc	a5,0x3
    8000319c:	35878793          	addi	a5,a5,856 # 800064f0 <kernelvec>
    800031a0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	da2080e7          	jalr	-606(ra) # 80001f46 <myproc>
    800031ac:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031ae:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031b0:	14102773          	csrr	a4,sepc
    800031b4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031b6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800031ba:	47a1                	li	a5,8
    800031bc:	04f71c63          	bne	a4,a5,80003214 <usertrap+0x92>
    if(p->killed)
    800031c0:	551c                	lw	a5,40(a0)
    800031c2:	e3b9                	bnez	a5,80003208 <usertrap+0x86>
    p->trapframe->epc += 4;
    800031c4:	6cb8                	ld	a4,88(s1)
    800031c6:	6f1c                	ld	a5,24(a4)
    800031c8:	0791                	addi	a5,a5,4
    800031ca:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031d4:	10079073          	csrw	sstatus,a5
    syscall();
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	2e0080e7          	jalr	736(ra) # 800034b8 <syscall>
  if(p->killed)
    800031e0:	549c                	lw	a5,40(s1)
    800031e2:	ebc1                	bnez	a5,80003272 <usertrap+0xf0>
  usertrapret();
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e18080e7          	jalr	-488(ra) # 80002ffc <usertrapret>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6902                	ld	s2,0(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret
    panic("usertrap: not from user mode");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	28850513          	addi	a0,a0,648 # 80008480 <states.1826+0x58>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	33e080e7          	jalr	830(ra) # 8000053e <panic>
      exit(-1);
    80003208:	557d                	li	a0,-1
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	b54080e7          	jalr	-1196(ra) # 80002d5e <exit>
    80003212:	bf4d                	j	800031c4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003214:	00000097          	auipc	ra,0x0
    80003218:	ecc080e7          	jalr	-308(ra) # 800030e0 <devintr>
    8000321c:	892a                	mv	s2,a0
    8000321e:	c501                	beqz	a0,80003226 <usertrap+0xa4>
  if(p->killed)
    80003220:	549c                	lw	a5,40(s1)
    80003222:	c3a1                	beqz	a5,80003262 <usertrap+0xe0>
    80003224:	a815                	j	80003258 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003226:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000322a:	5890                	lw	a2,48(s1)
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	27450513          	addi	a0,a0,628 # 800084a0 <states.1826+0x78>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	354080e7          	jalr	852(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000323c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003240:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003244:	00005517          	auipc	a0,0x5
    80003248:	28c50513          	addi	a0,a0,652 # 800084d0 <states.1826+0xa8>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	33c080e7          	jalr	828(ra) # 80000588 <printf>
    p->killed = 1;
    80003254:	4785                	li	a5,1
    80003256:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003258:	557d                	li	a0,-1
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	b04080e7          	jalr	-1276(ra) # 80002d5e <exit>
  if(which_dev == 2)
    80003262:	4789                	li	a5,2
    80003264:	f8f910e3          	bne	s2,a5,800031e4 <usertrap+0x62>
    yield();
    80003268:	fffff097          	auipc	ra,0xfffff
    8000326c:	326080e7          	jalr	806(ra) # 8000258e <yield>
    80003270:	bf95                	j	800031e4 <usertrap+0x62>
  int which_dev = 0;
    80003272:	4901                	li	s2,0
    80003274:	b7d5                	j	80003258 <usertrap+0xd6>

0000000080003276 <kerneltrap>:
{
    80003276:	7179                	addi	sp,sp,-48
    80003278:	f406                	sd	ra,40(sp)
    8000327a:	f022                	sd	s0,32(sp)
    8000327c:	ec26                	sd	s1,24(sp)
    8000327e:	e84a                	sd	s2,16(sp)
    80003280:	e44e                	sd	s3,8(sp)
    80003282:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003284:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003288:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000328c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003290:	1004f793          	andi	a5,s1,256
    80003294:	cb85                	beqz	a5,800032c4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003296:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000329a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000329c:	ef85                	bnez	a5,800032d4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	e42080e7          	jalr	-446(ra) # 800030e0 <devintr>
    800032a6:	cd1d                	beqz	a0,800032e4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032a8:	4789                	li	a5,2
    800032aa:	06f50a63          	beq	a0,a5,8000331e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032ae:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032b2:	10049073          	csrw	sstatus,s1
}
    800032b6:	70a2                	ld	ra,40(sp)
    800032b8:	7402                	ld	s0,32(sp)
    800032ba:	64e2                	ld	s1,24(sp)
    800032bc:	6942                	ld	s2,16(sp)
    800032be:	69a2                	ld	s3,8(sp)
    800032c0:	6145                	addi	sp,sp,48
    800032c2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	22c50513          	addi	a0,a0,556 # 800084f0 <states.1826+0xc8>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	24450513          	addi	a0,a0,580 # 80008518 <states.1826+0xf0>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800032e4:	85ce                	mv	a1,s3
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	25250513          	addi	a0,a0,594 # 80008538 <states.1826+0x110>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	29a080e7          	jalr	666(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032f6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800032fa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800032fe:	00005517          	auipc	a0,0x5
    80003302:	24a50513          	addi	a0,a0,586 # 80008548 <states.1826+0x120>
    80003306:	ffffd097          	auipc	ra,0xffffd
    8000330a:	282080e7          	jalr	642(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	25250513          	addi	a0,a0,594 # 80008560 <states.1826+0x138>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	228080e7          	jalr	552(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	c28080e7          	jalr	-984(ra) # 80001f46 <myproc>
    80003326:	d541                	beqz	a0,800032ae <kerneltrap+0x38>
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	c1e080e7          	jalr	-994(ra) # 80001f46 <myproc>
    80003330:	4d18                	lw	a4,24(a0)
    80003332:	4791                	li	a5,4
    80003334:	f6f71de3          	bne	a4,a5,800032ae <kerneltrap+0x38>
    yield();
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	256080e7          	jalr	598(ra) # 8000258e <yield>
    80003340:	b7bd                	j	800032ae <kerneltrap+0x38>

0000000080003342 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	e426                	sd	s1,8(sp)
    8000334a:	1000                	addi	s0,sp,32
    8000334c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000334e:	fffff097          	auipc	ra,0xfffff
    80003352:	bf8080e7          	jalr	-1032(ra) # 80001f46 <myproc>
  switch (n) {
    80003356:	4795                	li	a5,5
    80003358:	0497e163          	bltu	a5,s1,8000339a <argraw+0x58>
    8000335c:	048a                	slli	s1,s1,0x2
    8000335e:	00005717          	auipc	a4,0x5
    80003362:	23a70713          	addi	a4,a4,570 # 80008598 <states.1826+0x170>
    80003366:	94ba                	add	s1,s1,a4
    80003368:	409c                	lw	a5,0(s1)
    8000336a:	97ba                	add	a5,a5,a4
    8000336c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000336e:	6d3c                	ld	a5,88(a0)
    80003370:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	64a2                	ld	s1,8(sp)
    80003378:	6105                	addi	sp,sp,32
    8000337a:	8082                	ret
    return p->trapframe->a1;
    8000337c:	6d3c                	ld	a5,88(a0)
    8000337e:	7fa8                	ld	a0,120(a5)
    80003380:	bfcd                	j	80003372 <argraw+0x30>
    return p->trapframe->a2;
    80003382:	6d3c                	ld	a5,88(a0)
    80003384:	63c8                	ld	a0,128(a5)
    80003386:	b7f5                	j	80003372 <argraw+0x30>
    return p->trapframe->a3;
    80003388:	6d3c                	ld	a5,88(a0)
    8000338a:	67c8                	ld	a0,136(a5)
    8000338c:	b7dd                	j	80003372 <argraw+0x30>
    return p->trapframe->a4;
    8000338e:	6d3c                	ld	a5,88(a0)
    80003390:	6bc8                	ld	a0,144(a5)
    80003392:	b7c5                	j	80003372 <argraw+0x30>
    return p->trapframe->a5;
    80003394:	6d3c                	ld	a5,88(a0)
    80003396:	6fc8                	ld	a0,152(a5)
    80003398:	bfe9                	j	80003372 <argraw+0x30>
  panic("argraw");
    8000339a:	00005517          	auipc	a0,0x5
    8000339e:	1d650513          	addi	a0,a0,470 # 80008570 <states.1826+0x148>
    800033a2:	ffffd097          	auipc	ra,0xffffd
    800033a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>

00000000800033aa <fetchaddr>:
{
    800033aa:	1101                	addi	sp,sp,-32
    800033ac:	ec06                	sd	ra,24(sp)
    800033ae:	e822                	sd	s0,16(sp)
    800033b0:	e426                	sd	s1,8(sp)
    800033b2:	e04a                	sd	s2,0(sp)
    800033b4:	1000                	addi	s0,sp,32
    800033b6:	84aa                	mv	s1,a0
    800033b8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033ba:	fffff097          	auipc	ra,0xfffff
    800033be:	b8c080e7          	jalr	-1140(ra) # 80001f46 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033c2:	653c                	ld	a5,72(a0)
    800033c4:	02f4f863          	bgeu	s1,a5,800033f4 <fetchaddr+0x4a>
    800033c8:	00848713          	addi	a4,s1,8
    800033cc:	02e7e663          	bltu	a5,a4,800033f8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033d0:	46a1                	li	a3,8
    800033d2:	8626                	mv	a2,s1
    800033d4:	85ca                	mv	a1,s2
    800033d6:	6928                	ld	a0,80(a0)
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	326080e7          	jalr	806(ra) # 800016fe <copyin>
    800033e0:	00a03533          	snez	a0,a0
    800033e4:	40a00533          	neg	a0,a0
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6902                	ld	s2,0(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret
    return -1;
    800033f4:	557d                	li	a0,-1
    800033f6:	bfcd                	j	800033e8 <fetchaddr+0x3e>
    800033f8:	557d                	li	a0,-1
    800033fa:	b7fd                	j	800033e8 <fetchaddr+0x3e>

00000000800033fc <fetchstr>:
{
    800033fc:	7179                	addi	sp,sp,-48
    800033fe:	f406                	sd	ra,40(sp)
    80003400:	f022                	sd	s0,32(sp)
    80003402:	ec26                	sd	s1,24(sp)
    80003404:	e84a                	sd	s2,16(sp)
    80003406:	e44e                	sd	s3,8(sp)
    80003408:	1800                	addi	s0,sp,48
    8000340a:	892a                	mv	s2,a0
    8000340c:	84ae                	mv	s1,a1
    8000340e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003410:	fffff097          	auipc	ra,0xfffff
    80003414:	b36080e7          	jalr	-1226(ra) # 80001f46 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003418:	86ce                	mv	a3,s3
    8000341a:	864a                	mv	a2,s2
    8000341c:	85a6                	mv	a1,s1
    8000341e:	6928                	ld	a0,80(a0)
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	36a080e7          	jalr	874(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003428:	00054763          	bltz	a0,80003436 <fetchstr+0x3a>
  return strlen(buf);
    8000342c:	8526                	mv	a0,s1
    8000342e:	ffffe097          	auipc	ra,0xffffe
    80003432:	a36080e7          	jalr	-1482(ra) # 80000e64 <strlen>
}
    80003436:	70a2                	ld	ra,40(sp)
    80003438:	7402                	ld	s0,32(sp)
    8000343a:	64e2                	ld	s1,24(sp)
    8000343c:	6942                	ld	s2,16(sp)
    8000343e:	69a2                	ld	s3,8(sp)
    80003440:	6145                	addi	sp,sp,48
    80003442:	8082                	ret

0000000080003444 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003444:	1101                	addi	sp,sp,-32
    80003446:	ec06                	sd	ra,24(sp)
    80003448:	e822                	sd	s0,16(sp)
    8000344a:	e426                	sd	s1,8(sp)
    8000344c:	1000                	addi	s0,sp,32
    8000344e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003450:	00000097          	auipc	ra,0x0
    80003454:	ef2080e7          	jalr	-270(ra) # 80003342 <argraw>
    80003458:	c088                	sw	a0,0(s1)
  return 0;
}
    8000345a:	4501                	li	a0,0
    8000345c:	60e2                	ld	ra,24(sp)
    8000345e:	6442                	ld	s0,16(sp)
    80003460:	64a2                	ld	s1,8(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret

0000000080003466 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003466:	1101                	addi	sp,sp,-32
    80003468:	ec06                	sd	ra,24(sp)
    8000346a:	e822                	sd	s0,16(sp)
    8000346c:	e426                	sd	s1,8(sp)
    8000346e:	1000                	addi	s0,sp,32
    80003470:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003472:	00000097          	auipc	ra,0x0
    80003476:	ed0080e7          	jalr	-304(ra) # 80003342 <argraw>
    8000347a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000347c:	4501                	li	a0,0
    8000347e:	60e2                	ld	ra,24(sp)
    80003480:	6442                	ld	s0,16(sp)
    80003482:	64a2                	ld	s1,8(sp)
    80003484:	6105                	addi	sp,sp,32
    80003486:	8082                	ret

0000000080003488 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003488:	1101                	addi	sp,sp,-32
    8000348a:	ec06                	sd	ra,24(sp)
    8000348c:	e822                	sd	s0,16(sp)
    8000348e:	e426                	sd	s1,8(sp)
    80003490:	e04a                	sd	s2,0(sp)
    80003492:	1000                	addi	s0,sp,32
    80003494:	84ae                	mv	s1,a1
    80003496:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	eaa080e7          	jalr	-342(ra) # 80003342 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034a0:	864a                	mv	a2,s2
    800034a2:	85a6                	mv	a1,s1
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	f58080e7          	jalr	-168(ra) # 800033fc <fetchstr>
}
    800034ac:	60e2                	ld	ra,24(sp)
    800034ae:	6442                	ld	s0,16(sp)
    800034b0:	64a2                	ld	s1,8(sp)
    800034b2:	6902                	ld	s2,0(sp)
    800034b4:	6105                	addi	sp,sp,32
    800034b6:	8082                	ret

00000000800034b8 <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    800034b8:	1101                	addi	sp,sp,-32
    800034ba:	ec06                	sd	ra,24(sp)
    800034bc:	e822                	sd	s0,16(sp)
    800034be:	e426                	sd	s1,8(sp)
    800034c0:	e04a                	sd	s2,0(sp)
    800034c2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034c4:	fffff097          	auipc	ra,0xfffff
    800034c8:	a82080e7          	jalr	-1406(ra) # 80001f46 <myproc>
    800034cc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034ce:	05853903          	ld	s2,88(a0)
    800034d2:	0a893783          	ld	a5,168(s2)
    800034d6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034da:	37fd                	addiw	a5,a5,-1
    800034dc:	475d                	li	a4,23
    800034de:	00f76f63          	bltu	a4,a5,800034fc <syscall+0x44>
    800034e2:	00369713          	slli	a4,a3,0x3
    800034e6:	00005797          	auipc	a5,0x5
    800034ea:	0ca78793          	addi	a5,a5,202 # 800085b0 <syscalls>
    800034ee:	97ba                	add	a5,a5,a4
    800034f0:	639c                	ld	a5,0(a5)
    800034f2:	c789                	beqz	a5,800034fc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034f4:	9782                	jalr	a5
    800034f6:	06a93823          	sd	a0,112(s2)
    800034fa:	a839                	j	80003518 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800034fc:	15848613          	addi	a2,s1,344
    80003500:	588c                	lw	a1,48(s1)
    80003502:	00005517          	auipc	a0,0x5
    80003506:	07650513          	addi	a0,a0,118 # 80008578 <states.1826+0x150>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	07e080e7          	jalr	126(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003512:	6cbc                	ld	a5,88(s1)
    80003514:	577d                	li	a4,-1
    80003516:	fbb8                	sd	a4,112(a5)
  }
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6902                	ld	s2,0(sp)
    80003520:	6105                	addi	sp,sp,32
    80003522:	8082                	ret

0000000080003524 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003524:	1101                	addi	sp,sp,-32
    80003526:	ec06                	sd	ra,24(sp)
    80003528:	e822                	sd	s0,16(sp)
    8000352a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000352c:	fec40593          	addi	a1,s0,-20
    80003530:	4501                	li	a0,0
    80003532:	00000097          	auipc	ra,0x0
    80003536:	f12080e7          	jalr	-238(ra) # 80003444 <argint>
    return -1;
    8000353a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000353c:	00054963          	bltz	a0,8000354e <sys_exit+0x2a>
  exit(n);
    80003540:	fec42503          	lw	a0,-20(s0)
    80003544:	00000097          	auipc	ra,0x0
    80003548:	81a080e7          	jalr	-2022(ra) # 80002d5e <exit>
  return 0;  // not reached
    8000354c:	4781                	li	a5,0
}
    8000354e:	853e                	mv	a0,a5
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret

0000000080003558 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003558:	1141                	addi	sp,sp,-16
    8000355a:	e406                	sd	ra,8(sp)
    8000355c:	e022                	sd	s0,0(sp)
    8000355e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003560:	fffff097          	auipc	ra,0xfffff
    80003564:	9e6080e7          	jalr	-1562(ra) # 80001f46 <myproc>
}
    80003568:	5908                	lw	a0,48(a0)
    8000356a:	60a2                	ld	ra,8(sp)
    8000356c:	6402                	ld	s0,0(sp)
    8000356e:	0141                	addi	sp,sp,16
    80003570:	8082                	ret

0000000080003572 <sys_fork>:

uint64
sys_fork(void)
{
    80003572:	1141                	addi	sp,sp,-16
    80003574:	e406                	sd	ra,8(sp)
    80003576:	e022                	sd	s0,0(sp)
    80003578:	0800                	addi	s0,sp,16
  return fork();
    8000357a:	fffff097          	auipc	ra,0xfffff
    8000357e:	52a080e7          	jalr	1322(ra) # 80002aa4 <fork>
}
    80003582:	60a2                	ld	ra,8(sp)
    80003584:	6402                	ld	s0,0(sp)
    80003586:	0141                	addi	sp,sp,16
    80003588:	8082                	ret

000000008000358a <sys_wait>:

uint64
sys_wait(void)
{
    8000358a:	1101                	addi	sp,sp,-32
    8000358c:	ec06                	sd	ra,24(sp)
    8000358e:	e822                	sd	s0,16(sp)
    80003590:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003592:	fe840593          	addi	a1,s0,-24
    80003596:	4501                	li	a0,0
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	ece080e7          	jalr	-306(ra) # 80003466 <argaddr>
    800035a0:	87aa                	mv	a5,a0
    return -1;
    800035a2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035a4:	0007c863          	bltz	a5,800035b4 <sys_wait+0x2a>
  return wait(p);
    800035a8:	fe843503          	ld	a0,-24(s0)
    800035ac:	fffff097          	auipc	ra,0xfffff
    800035b0:	0b8080e7          	jalr	184(ra) # 80002664 <wait>
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	6105                	addi	sp,sp,32
    800035ba:	8082                	ret

00000000800035bc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035bc:	7179                	addi	sp,sp,-48
    800035be:	f406                	sd	ra,40(sp)
    800035c0:	f022                	sd	s0,32(sp)
    800035c2:	ec26                	sd	s1,24(sp)
    800035c4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035c6:	fdc40593          	addi	a1,s0,-36
    800035ca:	4501                	li	a0,0
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	e78080e7          	jalr	-392(ra) # 80003444 <argint>
    800035d4:	87aa                	mv	a5,a0
    return -1;
    800035d6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800035d8:	0207c063          	bltz	a5,800035f8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800035dc:	fffff097          	auipc	ra,0xfffff
    800035e0:	96a080e7          	jalr	-1686(ra) # 80001f46 <myproc>
    800035e4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035e6:	fdc42503          	lw	a0,-36(s0)
    800035ea:	fffff097          	auipc	ra,0xfffff
    800035ee:	d7c080e7          	jalr	-644(ra) # 80002366 <growproc>
    800035f2:	00054863          	bltz	a0,80003602 <sys_sbrk+0x46>
    return -1;
  return addr;
    800035f6:	8526                	mv	a0,s1
}
    800035f8:	70a2                	ld	ra,40(sp)
    800035fa:	7402                	ld	s0,32(sp)
    800035fc:	64e2                	ld	s1,24(sp)
    800035fe:	6145                	addi	sp,sp,48
    80003600:	8082                	ret
    return -1;
    80003602:	557d                	li	a0,-1
    80003604:	bfd5                	j	800035f8 <sys_sbrk+0x3c>

0000000080003606 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003606:	7139                	addi	sp,sp,-64
    80003608:	fc06                	sd	ra,56(sp)
    8000360a:	f822                	sd	s0,48(sp)
    8000360c:	f426                	sd	s1,40(sp)
    8000360e:	f04a                	sd	s2,32(sp)
    80003610:	ec4e                	sd	s3,24(sp)
    80003612:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003614:	fcc40593          	addi	a1,s0,-52
    80003618:	4501                	li	a0,0
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	e2a080e7          	jalr	-470(ra) # 80003444 <argint>
    return -1;
    80003622:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003624:	06054563          	bltz	a0,8000368e <sys_sleep+0x88>
  acquire(&tickslock);
    80003628:	00014517          	auipc	a0,0x14
    8000362c:	62850513          	addi	a0,a0,1576 # 80017c50 <tickslock>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003638:	00006917          	auipc	s2,0x6
    8000363c:	9f892903          	lw	s2,-1544(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003640:	fcc42783          	lw	a5,-52(s0)
    80003644:	cf85                	beqz	a5,8000367c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003646:	00014997          	auipc	s3,0x14
    8000364a:	60a98993          	addi	s3,s3,1546 # 80017c50 <tickslock>
    8000364e:	00006497          	auipc	s1,0x6
    80003652:	9e248493          	addi	s1,s1,-1566 # 80009030 <ticks>
    if(myproc()->killed){
    80003656:	fffff097          	auipc	ra,0xfffff
    8000365a:	8f0080e7          	jalr	-1808(ra) # 80001f46 <myproc>
    8000365e:	551c                	lw	a5,40(a0)
    80003660:	ef9d                	bnez	a5,8000369e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003662:	85ce                	mv	a1,s3
    80003664:	8526                	mv	a0,s1
    80003666:	fffff097          	auipc	ra,0xfffff
    8000366a:	f88080e7          	jalr	-120(ra) # 800025ee <sleep>
  while(ticks - ticks0 < n){
    8000366e:	409c                	lw	a5,0(s1)
    80003670:	412787bb          	subw	a5,a5,s2
    80003674:	fcc42703          	lw	a4,-52(s0)
    80003678:	fce7efe3          	bltu	a5,a4,80003656 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000367c:	00014517          	auipc	a0,0x14
    80003680:	5d450513          	addi	a0,a0,1492 # 80017c50 <tickslock>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	614080e7          	jalr	1556(ra) # 80000c98 <release>
  return 0;
    8000368c:	4781                	li	a5,0
}
    8000368e:	853e                	mv	a0,a5
    80003690:	70e2                	ld	ra,56(sp)
    80003692:	7442                	ld	s0,48(sp)
    80003694:	74a2                	ld	s1,40(sp)
    80003696:	7902                	ld	s2,32(sp)
    80003698:	69e2                	ld	s3,24(sp)
    8000369a:	6121                	addi	sp,sp,64
    8000369c:	8082                	ret
      release(&tickslock);
    8000369e:	00014517          	auipc	a0,0x14
    800036a2:	5b250513          	addi	a0,a0,1458 # 80017c50 <tickslock>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	5f2080e7          	jalr	1522(ra) # 80000c98 <release>
      return -1;
    800036ae:	57fd                	li	a5,-1
    800036b0:	bff9                	j	8000368e <sys_sleep+0x88>

00000000800036b2 <sys_kill>:

uint64
sys_kill(void)
{
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036ba:	fec40593          	addi	a1,s0,-20
    800036be:	4501                	li	a0,0
    800036c0:	00000097          	auipc	ra,0x0
    800036c4:	d84080e7          	jalr	-636(ra) # 80003444 <argint>
    800036c8:	87aa                	mv	a5,a0
    return -1;
    800036ca:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036cc:	0007c863          	bltz	a5,800036dc <sys_kill+0x2a>
  return kill(pid);
    800036d0:	fec42503          	lw	a0,-20(s0)
    800036d4:	fffff097          	auipc	ra,0xfffff
    800036d8:	0b8080e7          	jalr	184(ra) # 8000278c <kill>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	6105                	addi	sp,sp,32
    800036e2:	8082                	ret

00000000800036e4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036e4:	1101                	addi	sp,sp,-32
    800036e6:	ec06                	sd	ra,24(sp)
    800036e8:	e822                	sd	s0,16(sp)
    800036ea:	e426                	sd	s1,8(sp)
    800036ec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036ee:	00014517          	auipc	a0,0x14
    800036f2:	56250513          	addi	a0,a0,1378 # 80017c50 <tickslock>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	4ee080e7          	jalr	1262(ra) # 80000be4 <acquire>
  xticks = ticks;
    800036fe:	00006497          	auipc	s1,0x6
    80003702:	9324a483          	lw	s1,-1742(s1) # 80009030 <ticks>
  release(&tickslock);
    80003706:	00014517          	auipc	a0,0x14
    8000370a:	54a50513          	addi	a0,a0,1354 # 80017c50 <tickslock>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	58a080e7          	jalr	1418(ra) # 80000c98 <release>
  return xticks;
}
    80003716:	02049513          	slli	a0,s1,0x20
    8000371a:	9101                	srli	a0,a0,0x20
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret

0000000080003726 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003726:	1101                	addi	sp,sp,-32
    80003728:	ec06                	sd	ra,24(sp)
    8000372a:	e822                	sd	s0,16(sp)
    8000372c:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000372e:	fec40593          	addi	a1,s0,-20
    80003732:	4501                	li	a0,0
    80003734:	00000097          	auipc	ra,0x0
    80003738:	d10080e7          	jalr	-752(ra) # 80003444 <argint>
    8000373c:	87aa                	mv	a5,a0
    return -1;
    8000373e:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003740:	0007c863          	bltz	a5,80003750 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003744:	fec42503          	lw	a0,-20(s0)
    80003748:	fffff097          	auipc	ra,0xfffff
    8000374c:	242080e7          	jalr	578(ra) # 8000298a <set_cpu>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	6105                	addi	sp,sp,32
    80003756:	8082                	ret

0000000080003758 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003758:	1141                	addi	sp,sp,-16
    8000375a:	e406                	sd	ra,8(sp)
    8000375c:	e022                	sd	s0,0(sp)
    8000375e:	0800                	addi	s0,sp,16
  return get_cpu();
    80003760:	fffff097          	auipc	ra,0xfffff
    80003764:	27c080e7          	jalr	636(ra) # 800029dc <get_cpu>
}
    80003768:	60a2                	ld	ra,8(sp)
    8000376a:	6402                	ld	s0,0(sp)
    8000376c:	0141                	addi	sp,sp,16
    8000376e:	8082                	ret

0000000080003770 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003778:	fec40593          	addi	a1,s0,-20
    8000377c:	4501                	li	a0,0
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	cc6080e7          	jalr	-826(ra) # 80003444 <argint>
    80003786:	87aa                	mv	a5,a0
    return -1;
    80003788:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000378a:	0007c863          	bltz	a5,8000379a <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    8000378e:	fec42503          	lw	a0,-20(s0)
    80003792:	fffff097          	auipc	ra,0xfffff
    80003796:	2ae080e7          	jalr	686(ra) # 80002a40 <cpu_process_count>
}
    8000379a:	60e2                	ld	ra,24(sp)
    8000379c:	6442                	ld	s0,16(sp)
    8000379e:	6105                	addi	sp,sp,32
    800037a0:	8082                	ret

00000000800037a2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037a2:	7179                	addi	sp,sp,-48
    800037a4:	f406                	sd	ra,40(sp)
    800037a6:	f022                	sd	s0,32(sp)
    800037a8:	ec26                	sd	s1,24(sp)
    800037aa:	e84a                	sd	s2,16(sp)
    800037ac:	e44e                	sd	s3,8(sp)
    800037ae:	e052                	sd	s4,0(sp)
    800037b0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037b2:	00005597          	auipc	a1,0x5
    800037b6:	ec658593          	addi	a1,a1,-314 # 80008678 <syscalls+0xc8>
    800037ba:	00014517          	auipc	a0,0x14
    800037be:	4ae50513          	addi	a0,a0,1198 # 80017c68 <bcache>
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	392080e7          	jalr	914(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800037ca:	0001c797          	auipc	a5,0x1c
    800037ce:	49e78793          	addi	a5,a5,1182 # 8001fc68 <bcache+0x8000>
    800037d2:	0001c717          	auipc	a4,0x1c
    800037d6:	6fe70713          	addi	a4,a4,1790 # 8001fed0 <bcache+0x8268>
    800037da:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037de:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037e2:	00014497          	auipc	s1,0x14
    800037e6:	49e48493          	addi	s1,s1,1182 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    800037ea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800037ec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800037ee:	00005a17          	auipc	s4,0x5
    800037f2:	e92a0a13          	addi	s4,s4,-366 # 80008680 <syscalls+0xd0>
    b->next = bcache.head.next;
    800037f6:	2b893783          	ld	a5,696(s2)
    800037fa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800037fc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003800:	85d2                	mv	a1,s4
    80003802:	01048513          	addi	a0,s1,16
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	4bc080e7          	jalr	1212(ra) # 80004cc2 <initsleeplock>
    bcache.head.next->prev = b;
    8000380e:	2b893783          	ld	a5,696(s2)
    80003812:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003814:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003818:	45848493          	addi	s1,s1,1112
    8000381c:	fd349de3          	bne	s1,s3,800037f6 <binit+0x54>
  }
}
    80003820:	70a2                	ld	ra,40(sp)
    80003822:	7402                	ld	s0,32(sp)
    80003824:	64e2                	ld	s1,24(sp)
    80003826:	6942                	ld	s2,16(sp)
    80003828:	69a2                	ld	s3,8(sp)
    8000382a:	6a02                	ld	s4,0(sp)
    8000382c:	6145                	addi	sp,sp,48
    8000382e:	8082                	ret

0000000080003830 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003830:	7179                	addi	sp,sp,-48
    80003832:	f406                	sd	ra,40(sp)
    80003834:	f022                	sd	s0,32(sp)
    80003836:	ec26                	sd	s1,24(sp)
    80003838:	e84a                	sd	s2,16(sp)
    8000383a:	e44e                	sd	s3,8(sp)
    8000383c:	1800                	addi	s0,sp,48
    8000383e:	89aa                	mv	s3,a0
    80003840:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003842:	00014517          	auipc	a0,0x14
    80003846:	42650513          	addi	a0,a0,1062 # 80017c68 <bcache>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	39a080e7          	jalr	922(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003852:	0001c497          	auipc	s1,0x1c
    80003856:	6ce4b483          	ld	s1,1742(s1) # 8001ff20 <bcache+0x82b8>
    8000385a:	0001c797          	auipc	a5,0x1c
    8000385e:	67678793          	addi	a5,a5,1654 # 8001fed0 <bcache+0x8268>
    80003862:	02f48f63          	beq	s1,a5,800038a0 <bread+0x70>
    80003866:	873e                	mv	a4,a5
    80003868:	a021                	j	80003870 <bread+0x40>
    8000386a:	68a4                	ld	s1,80(s1)
    8000386c:	02e48a63          	beq	s1,a4,800038a0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003870:	449c                	lw	a5,8(s1)
    80003872:	ff379ce3          	bne	a5,s3,8000386a <bread+0x3a>
    80003876:	44dc                	lw	a5,12(s1)
    80003878:	ff2799e3          	bne	a5,s2,8000386a <bread+0x3a>
      b->refcnt++;
    8000387c:	40bc                	lw	a5,64(s1)
    8000387e:	2785                	addiw	a5,a5,1
    80003880:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003882:	00014517          	auipc	a0,0x14
    80003886:	3e650513          	addi	a0,a0,998 # 80017c68 <bcache>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	40e080e7          	jalr	1038(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003892:	01048513          	addi	a0,s1,16
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	466080e7          	jalr	1126(ra) # 80004cfc <acquiresleep>
      return b;
    8000389e:	a8b9                	j	800038fc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038a0:	0001c497          	auipc	s1,0x1c
    800038a4:	6784b483          	ld	s1,1656(s1) # 8001ff18 <bcache+0x82b0>
    800038a8:	0001c797          	auipc	a5,0x1c
    800038ac:	62878793          	addi	a5,a5,1576 # 8001fed0 <bcache+0x8268>
    800038b0:	00f48863          	beq	s1,a5,800038c0 <bread+0x90>
    800038b4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038b6:	40bc                	lw	a5,64(s1)
    800038b8:	cf81                	beqz	a5,800038d0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038ba:	64a4                	ld	s1,72(s1)
    800038bc:	fee49de3          	bne	s1,a4,800038b6 <bread+0x86>
  panic("bget: no buffers");
    800038c0:	00005517          	auipc	a0,0x5
    800038c4:	dc850513          	addi	a0,a0,-568 # 80008688 <syscalls+0xd8>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	c76080e7          	jalr	-906(ra) # 8000053e <panic>
      b->dev = dev;
    800038d0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800038d4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800038d8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038dc:	4785                	li	a5,1
    800038de:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038e0:	00014517          	auipc	a0,0x14
    800038e4:	38850513          	addi	a0,a0,904 # 80017c68 <bcache>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	3b0080e7          	jalr	944(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800038f0:	01048513          	addi	a0,s1,16
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	408080e7          	jalr	1032(ra) # 80004cfc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800038fc:	409c                	lw	a5,0(s1)
    800038fe:	cb89                	beqz	a5,80003910 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003900:	8526                	mv	a0,s1
    80003902:	70a2                	ld	ra,40(sp)
    80003904:	7402                	ld	s0,32(sp)
    80003906:	64e2                	ld	s1,24(sp)
    80003908:	6942                	ld	s2,16(sp)
    8000390a:	69a2                	ld	s3,8(sp)
    8000390c:	6145                	addi	sp,sp,48
    8000390e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003910:	4581                	li	a1,0
    80003912:	8526                	mv	a0,s1
    80003914:	00003097          	auipc	ra,0x3
    80003918:	f12080e7          	jalr	-238(ra) # 80006826 <virtio_disk_rw>
    b->valid = 1;
    8000391c:	4785                	li	a5,1
    8000391e:	c09c                	sw	a5,0(s1)
  return b;
    80003920:	b7c5                	j	80003900 <bread+0xd0>

0000000080003922 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003922:	1101                	addi	sp,sp,-32
    80003924:	ec06                	sd	ra,24(sp)
    80003926:	e822                	sd	s0,16(sp)
    80003928:	e426                	sd	s1,8(sp)
    8000392a:	1000                	addi	s0,sp,32
    8000392c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000392e:	0541                	addi	a0,a0,16
    80003930:	00001097          	auipc	ra,0x1
    80003934:	466080e7          	jalr	1126(ra) # 80004d96 <holdingsleep>
    80003938:	cd01                	beqz	a0,80003950 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000393a:	4585                	li	a1,1
    8000393c:	8526                	mv	a0,s1
    8000393e:	00003097          	auipc	ra,0x3
    80003942:	ee8080e7          	jalr	-280(ra) # 80006826 <virtio_disk_rw>
}
    80003946:	60e2                	ld	ra,24(sp)
    80003948:	6442                	ld	s0,16(sp)
    8000394a:	64a2                	ld	s1,8(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret
    panic("bwrite");
    80003950:	00005517          	auipc	a0,0x5
    80003954:	d5050513          	addi	a0,a0,-688 # 800086a0 <syscalls+0xf0>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	be6080e7          	jalr	-1050(ra) # 8000053e <panic>

0000000080003960 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003960:	1101                	addi	sp,sp,-32
    80003962:	ec06                	sd	ra,24(sp)
    80003964:	e822                	sd	s0,16(sp)
    80003966:	e426                	sd	s1,8(sp)
    80003968:	e04a                	sd	s2,0(sp)
    8000396a:	1000                	addi	s0,sp,32
    8000396c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000396e:	01050913          	addi	s2,a0,16
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	422080e7          	jalr	1058(ra) # 80004d96 <holdingsleep>
    8000397c:	c92d                	beqz	a0,800039ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	3d2080e7          	jalr	978(ra) # 80004d52 <releasesleep>

  acquire(&bcache.lock);
    80003988:	00014517          	auipc	a0,0x14
    8000398c:	2e050513          	addi	a0,a0,736 # 80017c68 <bcache>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003998:	40bc                	lw	a5,64(s1)
    8000399a:	37fd                	addiw	a5,a5,-1
    8000399c:	0007871b          	sext.w	a4,a5
    800039a0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039a2:	eb05                	bnez	a4,800039d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039a4:	68bc                	ld	a5,80(s1)
    800039a6:	64b8                	ld	a4,72(s1)
    800039a8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039aa:	64bc                	ld	a5,72(s1)
    800039ac:	68b8                	ld	a4,80(s1)
    800039ae:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039b0:	0001c797          	auipc	a5,0x1c
    800039b4:	2b878793          	addi	a5,a5,696 # 8001fc68 <bcache+0x8000>
    800039b8:	2b87b703          	ld	a4,696(a5)
    800039bc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039be:	0001c717          	auipc	a4,0x1c
    800039c2:	51270713          	addi	a4,a4,1298 # 8001fed0 <bcache+0x8268>
    800039c6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800039c8:	2b87b703          	ld	a4,696(a5)
    800039cc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800039ce:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800039d2:	00014517          	auipc	a0,0x14
    800039d6:	29650513          	addi	a0,a0,662 # 80017c68 <bcache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	2be080e7          	jalr	702(ra) # 80000c98 <release>
}
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6902                	ld	s2,0(sp)
    800039ea:	6105                	addi	sp,sp,32
    800039ec:	8082                	ret
    panic("brelse");
    800039ee:	00005517          	auipc	a0,0x5
    800039f2:	cba50513          	addi	a0,a0,-838 # 800086a8 <syscalls+0xf8>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>

00000000800039fe <bpin>:

void
bpin(struct buf *b) {
    800039fe:	1101                	addi	sp,sp,-32
    80003a00:	ec06                	sd	ra,24(sp)
    80003a02:	e822                	sd	s0,16(sp)
    80003a04:	e426                	sd	s1,8(sp)
    80003a06:	1000                	addi	s0,sp,32
    80003a08:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a0a:	00014517          	auipc	a0,0x14
    80003a0e:	25e50513          	addi	a0,a0,606 # 80017c68 <bcache>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	1d2080e7          	jalr	466(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003a1a:	40bc                	lw	a5,64(s1)
    80003a1c:	2785                	addiw	a5,a5,1
    80003a1e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a20:	00014517          	auipc	a0,0x14
    80003a24:	24850513          	addi	a0,a0,584 # 80017c68 <bcache>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	270080e7          	jalr	624(ra) # 80000c98 <release>
}
    80003a30:	60e2                	ld	ra,24(sp)
    80003a32:	6442                	ld	s0,16(sp)
    80003a34:	64a2                	ld	s1,8(sp)
    80003a36:	6105                	addi	sp,sp,32
    80003a38:	8082                	ret

0000000080003a3a <bunpin>:

void
bunpin(struct buf *b) {
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	1000                	addi	s0,sp,32
    80003a44:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a46:	00014517          	auipc	a0,0x14
    80003a4a:	22250513          	addi	a0,a0,546 # 80017c68 <bcache>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	196080e7          	jalr	406(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a56:	40bc                	lw	a5,64(s1)
    80003a58:	37fd                	addiw	a5,a5,-1
    80003a5a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a5c:	00014517          	auipc	a0,0x14
    80003a60:	20c50513          	addi	a0,a0,524 # 80017c68 <bcache>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	234080e7          	jalr	564(ra) # 80000c98 <release>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6105                	addi	sp,sp,32
    80003a74:	8082                	ret

0000000080003a76 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a76:	1101                	addi	sp,sp,-32
    80003a78:	ec06                	sd	ra,24(sp)
    80003a7a:	e822                	sd	s0,16(sp)
    80003a7c:	e426                	sd	s1,8(sp)
    80003a7e:	e04a                	sd	s2,0(sp)
    80003a80:	1000                	addi	s0,sp,32
    80003a82:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a84:	00d5d59b          	srliw	a1,a1,0xd
    80003a88:	0001d797          	auipc	a5,0x1d
    80003a8c:	8bc7a783          	lw	a5,-1860(a5) # 80020344 <sb+0x1c>
    80003a90:	9dbd                	addw	a1,a1,a5
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	d9e080e7          	jalr	-610(ra) # 80003830 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a9a:	0074f713          	andi	a4,s1,7
    80003a9e:	4785                	li	a5,1
    80003aa0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003aa4:	14ce                	slli	s1,s1,0x33
    80003aa6:	90d9                	srli	s1,s1,0x36
    80003aa8:	00950733          	add	a4,a0,s1
    80003aac:	05874703          	lbu	a4,88(a4)
    80003ab0:	00e7f6b3          	and	a3,a5,a4
    80003ab4:	c69d                	beqz	a3,80003ae2 <bfree+0x6c>
    80003ab6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003ab8:	94aa                	add	s1,s1,a0
    80003aba:	fff7c793          	not	a5,a5
    80003abe:	8ff9                	and	a5,a5,a4
    80003ac0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	118080e7          	jalr	280(ra) # 80004bdc <log_write>
  brelse(bp);
    80003acc:	854a                	mv	a0,s2
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	e92080e7          	jalr	-366(ra) # 80003960 <brelse>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	64a2                	ld	s1,8(sp)
    80003adc:	6902                	ld	s2,0(sp)
    80003ade:	6105                	addi	sp,sp,32
    80003ae0:	8082                	ret
    panic("freeing free block");
    80003ae2:	00005517          	auipc	a0,0x5
    80003ae6:	bce50513          	addi	a0,a0,-1074 # 800086b0 <syscalls+0x100>
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	a54080e7          	jalr	-1452(ra) # 8000053e <panic>

0000000080003af2 <balloc>:
{
    80003af2:	711d                	addi	sp,sp,-96
    80003af4:	ec86                	sd	ra,88(sp)
    80003af6:	e8a2                	sd	s0,80(sp)
    80003af8:	e4a6                	sd	s1,72(sp)
    80003afa:	e0ca                	sd	s2,64(sp)
    80003afc:	fc4e                	sd	s3,56(sp)
    80003afe:	f852                	sd	s4,48(sp)
    80003b00:	f456                	sd	s5,40(sp)
    80003b02:	f05a                	sd	s6,32(sp)
    80003b04:	ec5e                	sd	s7,24(sp)
    80003b06:	e862                	sd	s8,16(sp)
    80003b08:	e466                	sd	s9,8(sp)
    80003b0a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b0c:	0001d797          	auipc	a5,0x1d
    80003b10:	8207a783          	lw	a5,-2016(a5) # 8002032c <sb+0x4>
    80003b14:	cbd1                	beqz	a5,80003ba8 <balloc+0xb6>
    80003b16:	8baa                	mv	s7,a0
    80003b18:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b1a:	0001db17          	auipc	s6,0x1d
    80003b1e:	80eb0b13          	addi	s6,s6,-2034 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b22:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b24:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b26:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b28:	6c89                	lui	s9,0x2
    80003b2a:	a831                	j	80003b46 <balloc+0x54>
    brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	e32080e7          	jalr	-462(ra) # 80003960 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b36:	015c87bb          	addw	a5,s9,s5
    80003b3a:	00078a9b          	sext.w	s5,a5
    80003b3e:	004b2703          	lw	a4,4(s6)
    80003b42:	06eaf363          	bgeu	s5,a4,80003ba8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003b46:	41fad79b          	sraiw	a5,s5,0x1f
    80003b4a:	0137d79b          	srliw	a5,a5,0x13
    80003b4e:	015787bb          	addw	a5,a5,s5
    80003b52:	40d7d79b          	sraiw	a5,a5,0xd
    80003b56:	01cb2583          	lw	a1,28(s6)
    80003b5a:	9dbd                	addw	a1,a1,a5
    80003b5c:	855e                	mv	a0,s7
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	cd2080e7          	jalr	-814(ra) # 80003830 <bread>
    80003b66:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b68:	004b2503          	lw	a0,4(s6)
    80003b6c:	000a849b          	sext.w	s1,s5
    80003b70:	8662                	mv	a2,s8
    80003b72:	faa4fde3          	bgeu	s1,a0,80003b2c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b76:	41f6579b          	sraiw	a5,a2,0x1f
    80003b7a:	01d7d69b          	srliw	a3,a5,0x1d
    80003b7e:	00c6873b          	addw	a4,a3,a2
    80003b82:	00777793          	andi	a5,a4,7
    80003b86:	9f95                	subw	a5,a5,a3
    80003b88:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b8c:	4037571b          	sraiw	a4,a4,0x3
    80003b90:	00e906b3          	add	a3,s2,a4
    80003b94:	0586c683          	lbu	a3,88(a3)
    80003b98:	00d7f5b3          	and	a1,a5,a3
    80003b9c:	cd91                	beqz	a1,80003bb8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b9e:	2605                	addiw	a2,a2,1
    80003ba0:	2485                	addiw	s1,s1,1
    80003ba2:	fd4618e3          	bne	a2,s4,80003b72 <balloc+0x80>
    80003ba6:	b759                	j	80003b2c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	b2050513          	addi	a0,a0,-1248 # 800086c8 <syscalls+0x118>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bb8:	974a                	add	a4,a4,s2
    80003bba:	8fd5                	or	a5,a5,a3
    80003bbc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	01a080e7          	jalr	26(ra) # 80004bdc <log_write>
        brelse(bp);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	d94080e7          	jalr	-620(ra) # 80003960 <brelse>
  bp = bread(dev, bno);
    80003bd4:	85a6                	mv	a1,s1
    80003bd6:	855e                	mv	a0,s7
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	c58080e7          	jalr	-936(ra) # 80003830 <bread>
    80003be0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003be2:	40000613          	li	a2,1024
    80003be6:	4581                	li	a1,0
    80003be8:	05850513          	addi	a0,a0,88
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	0f4080e7          	jalr	244(ra) # 80000ce0 <memset>
  log_write(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	fe6080e7          	jalr	-26(ra) # 80004bdc <log_write>
  brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	d60080e7          	jalr	-672(ra) # 80003960 <brelse>
}
    80003c08:	8526                	mv	a0,s1
    80003c0a:	60e6                	ld	ra,88(sp)
    80003c0c:	6446                	ld	s0,80(sp)
    80003c0e:	64a6                	ld	s1,72(sp)
    80003c10:	6906                	ld	s2,64(sp)
    80003c12:	79e2                	ld	s3,56(sp)
    80003c14:	7a42                	ld	s4,48(sp)
    80003c16:	7aa2                	ld	s5,40(sp)
    80003c18:	7b02                	ld	s6,32(sp)
    80003c1a:	6be2                	ld	s7,24(sp)
    80003c1c:	6c42                	ld	s8,16(sp)
    80003c1e:	6ca2                	ld	s9,8(sp)
    80003c20:	6125                	addi	sp,sp,96
    80003c22:	8082                	ret

0000000080003c24 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c24:	7179                	addi	sp,sp,-48
    80003c26:	f406                	sd	ra,40(sp)
    80003c28:	f022                	sd	s0,32(sp)
    80003c2a:	ec26                	sd	s1,24(sp)
    80003c2c:	e84a                	sd	s2,16(sp)
    80003c2e:	e44e                	sd	s3,8(sp)
    80003c30:	e052                	sd	s4,0(sp)
    80003c32:	1800                	addi	s0,sp,48
    80003c34:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c36:	47ad                	li	a5,11
    80003c38:	04b7fe63          	bgeu	a5,a1,80003c94 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003c3c:	ff45849b          	addiw	s1,a1,-12
    80003c40:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c44:	0ff00793          	li	a5,255
    80003c48:	0ae7e363          	bltu	a5,a4,80003cee <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003c4c:	08052583          	lw	a1,128(a0)
    80003c50:	c5ad                	beqz	a1,80003cba <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003c52:	00092503          	lw	a0,0(s2)
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	bda080e7          	jalr	-1062(ra) # 80003830 <bread>
    80003c5e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c60:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c64:	02049593          	slli	a1,s1,0x20
    80003c68:	9181                	srli	a1,a1,0x20
    80003c6a:	058a                	slli	a1,a1,0x2
    80003c6c:	00b784b3          	add	s1,a5,a1
    80003c70:	0004a983          	lw	s3,0(s1)
    80003c74:	04098d63          	beqz	s3,80003cce <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c78:	8552                	mv	a0,s4
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	ce6080e7          	jalr	-794(ra) # 80003960 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c82:	854e                	mv	a0,s3
    80003c84:	70a2                	ld	ra,40(sp)
    80003c86:	7402                	ld	s0,32(sp)
    80003c88:	64e2                	ld	s1,24(sp)
    80003c8a:	6942                	ld	s2,16(sp)
    80003c8c:	69a2                	ld	s3,8(sp)
    80003c8e:	6a02                	ld	s4,0(sp)
    80003c90:	6145                	addi	sp,sp,48
    80003c92:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c94:	02059493          	slli	s1,a1,0x20
    80003c98:	9081                	srli	s1,s1,0x20
    80003c9a:	048a                	slli	s1,s1,0x2
    80003c9c:	94aa                	add	s1,s1,a0
    80003c9e:	0504a983          	lw	s3,80(s1)
    80003ca2:	fe0990e3          	bnez	s3,80003c82 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ca6:	4108                	lw	a0,0(a0)
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	e4a080e7          	jalr	-438(ra) # 80003af2 <balloc>
    80003cb0:	0005099b          	sext.w	s3,a0
    80003cb4:	0534a823          	sw	s3,80(s1)
    80003cb8:	b7e9                	j	80003c82 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003cba:	4108                	lw	a0,0(a0)
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	e36080e7          	jalr	-458(ra) # 80003af2 <balloc>
    80003cc4:	0005059b          	sext.w	a1,a0
    80003cc8:	08b92023          	sw	a1,128(s2)
    80003ccc:	b759                	j	80003c52 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003cce:	00092503          	lw	a0,0(s2)
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	e20080e7          	jalr	-480(ra) # 80003af2 <balloc>
    80003cda:	0005099b          	sext.w	s3,a0
    80003cde:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ce2:	8552                	mv	a0,s4
    80003ce4:	00001097          	auipc	ra,0x1
    80003ce8:	ef8080e7          	jalr	-264(ra) # 80004bdc <log_write>
    80003cec:	b771                	j	80003c78 <bmap+0x54>
  panic("bmap: out of range");
    80003cee:	00005517          	auipc	a0,0x5
    80003cf2:	9f250513          	addi	a0,a0,-1550 # 800086e0 <syscalls+0x130>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>

0000000080003cfe <iget>:
{
    80003cfe:	7179                	addi	sp,sp,-48
    80003d00:	f406                	sd	ra,40(sp)
    80003d02:	f022                	sd	s0,32(sp)
    80003d04:	ec26                	sd	s1,24(sp)
    80003d06:	e84a                	sd	s2,16(sp)
    80003d08:	e44e                	sd	s3,8(sp)
    80003d0a:	e052                	sd	s4,0(sp)
    80003d0c:	1800                	addi	s0,sp,48
    80003d0e:	89aa                	mv	s3,a0
    80003d10:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d12:	0001c517          	auipc	a0,0x1c
    80003d16:	63650513          	addi	a0,a0,1590 # 80020348 <itable>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	eca080e7          	jalr	-310(ra) # 80000be4 <acquire>
  empty = 0;
    80003d22:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d24:	0001c497          	auipc	s1,0x1c
    80003d28:	63c48493          	addi	s1,s1,1596 # 80020360 <itable+0x18>
    80003d2c:	0001e697          	auipc	a3,0x1e
    80003d30:	0c468693          	addi	a3,a3,196 # 80021df0 <log>
    80003d34:	a039                	j	80003d42 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d36:	02090b63          	beqz	s2,80003d6c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d3a:	08848493          	addi	s1,s1,136
    80003d3e:	02d48a63          	beq	s1,a3,80003d72 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d42:	449c                	lw	a5,8(s1)
    80003d44:	fef059e3          	blez	a5,80003d36 <iget+0x38>
    80003d48:	4098                	lw	a4,0(s1)
    80003d4a:	ff3716e3          	bne	a4,s3,80003d36 <iget+0x38>
    80003d4e:	40d8                	lw	a4,4(s1)
    80003d50:	ff4713e3          	bne	a4,s4,80003d36 <iget+0x38>
      ip->ref++;
    80003d54:	2785                	addiw	a5,a5,1
    80003d56:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d58:	0001c517          	auipc	a0,0x1c
    80003d5c:	5f050513          	addi	a0,a0,1520 # 80020348 <itable>
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
      return ip;
    80003d68:	8926                	mv	s2,s1
    80003d6a:	a03d                	j	80003d98 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d6c:	f7f9                	bnez	a5,80003d3a <iget+0x3c>
    80003d6e:	8926                	mv	s2,s1
    80003d70:	b7e9                	j	80003d3a <iget+0x3c>
  if(empty == 0)
    80003d72:	02090c63          	beqz	s2,80003daa <iget+0xac>
  ip->dev = dev;
    80003d76:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d7a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d7e:	4785                	li	a5,1
    80003d80:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d84:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d88:	0001c517          	auipc	a0,0x1c
    80003d8c:	5c050513          	addi	a0,a0,1472 # 80020348 <itable>
    80003d90:	ffffd097          	auipc	ra,0xffffd
    80003d94:	f08080e7          	jalr	-248(ra) # 80000c98 <release>
}
    80003d98:	854a                	mv	a0,s2
    80003d9a:	70a2                	ld	ra,40(sp)
    80003d9c:	7402                	ld	s0,32(sp)
    80003d9e:	64e2                	ld	s1,24(sp)
    80003da0:	6942                	ld	s2,16(sp)
    80003da2:	69a2                	ld	s3,8(sp)
    80003da4:	6a02                	ld	s4,0(sp)
    80003da6:	6145                	addi	sp,sp,48
    80003da8:	8082                	ret
    panic("iget: no inodes");
    80003daa:	00005517          	auipc	a0,0x5
    80003dae:	94e50513          	addi	a0,a0,-1714 # 800086f8 <syscalls+0x148>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	78c080e7          	jalr	1932(ra) # 8000053e <panic>

0000000080003dba <fsinit>:
fsinit(int dev) {
    80003dba:	7179                	addi	sp,sp,-48
    80003dbc:	f406                	sd	ra,40(sp)
    80003dbe:	f022                	sd	s0,32(sp)
    80003dc0:	ec26                	sd	s1,24(sp)
    80003dc2:	e84a                	sd	s2,16(sp)
    80003dc4:	e44e                	sd	s3,8(sp)
    80003dc6:	1800                	addi	s0,sp,48
    80003dc8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003dca:	4585                	li	a1,1
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	a64080e7          	jalr	-1436(ra) # 80003830 <bread>
    80003dd4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003dd6:	0001c997          	auipc	s3,0x1c
    80003dda:	55298993          	addi	s3,s3,1362 # 80020328 <sb>
    80003dde:	02000613          	li	a2,32
    80003de2:	05850593          	addi	a1,a0,88
    80003de6:	854e                	mv	a0,s3
    80003de8:	ffffd097          	auipc	ra,0xffffd
    80003dec:	f58080e7          	jalr	-168(ra) # 80000d40 <memmove>
  brelse(bp);
    80003df0:	8526                	mv	a0,s1
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	b6e080e7          	jalr	-1170(ra) # 80003960 <brelse>
  if(sb.magic != FSMAGIC)
    80003dfa:	0009a703          	lw	a4,0(s3)
    80003dfe:	102037b7          	lui	a5,0x10203
    80003e02:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e06:	02f71263          	bne	a4,a5,80003e2a <fsinit+0x70>
  initlog(dev, &sb);
    80003e0a:	0001c597          	auipc	a1,0x1c
    80003e0e:	51e58593          	addi	a1,a1,1310 # 80020328 <sb>
    80003e12:	854a                	mv	a0,s2
    80003e14:	00001097          	auipc	ra,0x1
    80003e18:	b4c080e7          	jalr	-1204(ra) # 80004960 <initlog>
}
    80003e1c:	70a2                	ld	ra,40(sp)
    80003e1e:	7402                	ld	s0,32(sp)
    80003e20:	64e2                	ld	s1,24(sp)
    80003e22:	6942                	ld	s2,16(sp)
    80003e24:	69a2                	ld	s3,8(sp)
    80003e26:	6145                	addi	sp,sp,48
    80003e28:	8082                	ret
    panic("invalid file system");
    80003e2a:	00005517          	auipc	a0,0x5
    80003e2e:	8de50513          	addi	a0,a0,-1826 # 80008708 <syscalls+0x158>
    80003e32:	ffffc097          	auipc	ra,0xffffc
    80003e36:	70c080e7          	jalr	1804(ra) # 8000053e <panic>

0000000080003e3a <iinit>:
{
    80003e3a:	7179                	addi	sp,sp,-48
    80003e3c:	f406                	sd	ra,40(sp)
    80003e3e:	f022                	sd	s0,32(sp)
    80003e40:	ec26                	sd	s1,24(sp)
    80003e42:	e84a                	sd	s2,16(sp)
    80003e44:	e44e                	sd	s3,8(sp)
    80003e46:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e48:	00005597          	auipc	a1,0x5
    80003e4c:	8d858593          	addi	a1,a1,-1832 # 80008720 <syscalls+0x170>
    80003e50:	0001c517          	auipc	a0,0x1c
    80003e54:	4f850513          	addi	a0,a0,1272 # 80020348 <itable>
    80003e58:	ffffd097          	auipc	ra,0xffffd
    80003e5c:	cfc080e7          	jalr	-772(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e60:	0001c497          	auipc	s1,0x1c
    80003e64:	51048493          	addi	s1,s1,1296 # 80020370 <itable+0x28>
    80003e68:	0001e997          	auipc	s3,0x1e
    80003e6c:	f9898993          	addi	s3,s3,-104 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e70:	00005917          	auipc	s2,0x5
    80003e74:	8b890913          	addi	s2,s2,-1864 # 80008728 <syscalls+0x178>
    80003e78:	85ca                	mv	a1,s2
    80003e7a:	8526                	mv	a0,s1
    80003e7c:	00001097          	auipc	ra,0x1
    80003e80:	e46080e7          	jalr	-442(ra) # 80004cc2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e84:	08848493          	addi	s1,s1,136
    80003e88:	ff3498e3          	bne	s1,s3,80003e78 <iinit+0x3e>
}
    80003e8c:	70a2                	ld	ra,40(sp)
    80003e8e:	7402                	ld	s0,32(sp)
    80003e90:	64e2                	ld	s1,24(sp)
    80003e92:	6942                	ld	s2,16(sp)
    80003e94:	69a2                	ld	s3,8(sp)
    80003e96:	6145                	addi	sp,sp,48
    80003e98:	8082                	ret

0000000080003e9a <ialloc>:
{
    80003e9a:	715d                	addi	sp,sp,-80
    80003e9c:	e486                	sd	ra,72(sp)
    80003e9e:	e0a2                	sd	s0,64(sp)
    80003ea0:	fc26                	sd	s1,56(sp)
    80003ea2:	f84a                	sd	s2,48(sp)
    80003ea4:	f44e                	sd	s3,40(sp)
    80003ea6:	f052                	sd	s4,32(sp)
    80003ea8:	ec56                	sd	s5,24(sp)
    80003eaa:	e85a                	sd	s6,16(sp)
    80003eac:	e45e                	sd	s7,8(sp)
    80003eae:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003eb0:	0001c717          	auipc	a4,0x1c
    80003eb4:	48472703          	lw	a4,1156(a4) # 80020334 <sb+0xc>
    80003eb8:	4785                	li	a5,1
    80003eba:	04e7fa63          	bgeu	a5,a4,80003f0e <ialloc+0x74>
    80003ebe:	8aaa                	mv	s5,a0
    80003ec0:	8bae                	mv	s7,a1
    80003ec2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ec4:	0001ca17          	auipc	s4,0x1c
    80003ec8:	464a0a13          	addi	s4,s4,1124 # 80020328 <sb>
    80003ecc:	00048b1b          	sext.w	s6,s1
    80003ed0:	0044d593          	srli	a1,s1,0x4
    80003ed4:	018a2783          	lw	a5,24(s4)
    80003ed8:	9dbd                	addw	a1,a1,a5
    80003eda:	8556                	mv	a0,s5
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	954080e7          	jalr	-1708(ra) # 80003830 <bread>
    80003ee4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ee6:	05850993          	addi	s3,a0,88
    80003eea:	00f4f793          	andi	a5,s1,15
    80003eee:	079a                	slli	a5,a5,0x6
    80003ef0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ef2:	00099783          	lh	a5,0(s3)
    80003ef6:	c785                	beqz	a5,80003f1e <ialloc+0x84>
    brelse(bp);
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	a68080e7          	jalr	-1432(ra) # 80003960 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f00:	0485                	addi	s1,s1,1
    80003f02:	00ca2703          	lw	a4,12(s4)
    80003f06:	0004879b          	sext.w	a5,s1
    80003f0a:	fce7e1e3          	bltu	a5,a4,80003ecc <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f0e:	00005517          	auipc	a0,0x5
    80003f12:	82250513          	addi	a0,a0,-2014 # 80008730 <syscalls+0x180>
    80003f16:	ffffc097          	auipc	ra,0xffffc
    80003f1a:	628080e7          	jalr	1576(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003f1e:	04000613          	li	a2,64
    80003f22:	4581                	li	a1,0
    80003f24:	854e                	mv	a0,s3
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	dba080e7          	jalr	-582(ra) # 80000ce0 <memset>
      dip->type = type;
    80003f2e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	ca8080e7          	jalr	-856(ra) # 80004bdc <log_write>
      brelse(bp);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	a22080e7          	jalr	-1502(ra) # 80003960 <brelse>
      return iget(dev, inum);
    80003f46:	85da                	mv	a1,s6
    80003f48:	8556                	mv	a0,s5
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	db4080e7          	jalr	-588(ra) # 80003cfe <iget>
}
    80003f52:	60a6                	ld	ra,72(sp)
    80003f54:	6406                	ld	s0,64(sp)
    80003f56:	74e2                	ld	s1,56(sp)
    80003f58:	7942                	ld	s2,48(sp)
    80003f5a:	79a2                	ld	s3,40(sp)
    80003f5c:	7a02                	ld	s4,32(sp)
    80003f5e:	6ae2                	ld	s5,24(sp)
    80003f60:	6b42                	ld	s6,16(sp)
    80003f62:	6ba2                	ld	s7,8(sp)
    80003f64:	6161                	addi	sp,sp,80
    80003f66:	8082                	ret

0000000080003f68 <iupdate>:
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	e426                	sd	s1,8(sp)
    80003f70:	e04a                	sd	s2,0(sp)
    80003f72:	1000                	addi	s0,sp,32
    80003f74:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f76:	415c                	lw	a5,4(a0)
    80003f78:	0047d79b          	srliw	a5,a5,0x4
    80003f7c:	0001c597          	auipc	a1,0x1c
    80003f80:	3c45a583          	lw	a1,964(a1) # 80020340 <sb+0x18>
    80003f84:	9dbd                	addw	a1,a1,a5
    80003f86:	4108                	lw	a0,0(a0)
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	8a8080e7          	jalr	-1880(ra) # 80003830 <bread>
    80003f90:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f92:	05850793          	addi	a5,a0,88
    80003f96:	40c8                	lw	a0,4(s1)
    80003f98:	893d                	andi	a0,a0,15
    80003f9a:	051a                	slli	a0,a0,0x6
    80003f9c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f9e:	04449703          	lh	a4,68(s1)
    80003fa2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003fa6:	04649703          	lh	a4,70(s1)
    80003faa:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003fae:	04849703          	lh	a4,72(s1)
    80003fb2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003fb6:	04a49703          	lh	a4,74(s1)
    80003fba:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003fbe:	44f8                	lw	a4,76(s1)
    80003fc0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fc2:	03400613          	li	a2,52
    80003fc6:	05048593          	addi	a1,s1,80
    80003fca:	0531                	addi	a0,a0,12
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	d74080e7          	jalr	-652(ra) # 80000d40 <memmove>
  log_write(bp);
    80003fd4:	854a                	mv	a0,s2
    80003fd6:	00001097          	auipc	ra,0x1
    80003fda:	c06080e7          	jalr	-1018(ra) # 80004bdc <log_write>
  brelse(bp);
    80003fde:	854a                	mv	a0,s2
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	980080e7          	jalr	-1664(ra) # 80003960 <brelse>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <idup>:
{
    80003ff4:	1101                	addi	sp,sp,-32
    80003ff6:	ec06                	sd	ra,24(sp)
    80003ff8:	e822                	sd	s0,16(sp)
    80003ffa:	e426                	sd	s1,8(sp)
    80003ffc:	1000                	addi	s0,sp,32
    80003ffe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004000:	0001c517          	auipc	a0,0x1c
    80004004:	34850513          	addi	a0,a0,840 # 80020348 <itable>
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	bdc080e7          	jalr	-1060(ra) # 80000be4 <acquire>
  ip->ref++;
    80004010:	449c                	lw	a5,8(s1)
    80004012:	2785                	addiw	a5,a5,1
    80004014:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004016:	0001c517          	auipc	a0,0x1c
    8000401a:	33250513          	addi	a0,a0,818 # 80020348 <itable>
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	c7a080e7          	jalr	-902(ra) # 80000c98 <release>
}
    80004026:	8526                	mv	a0,s1
    80004028:	60e2                	ld	ra,24(sp)
    8000402a:	6442                	ld	s0,16(sp)
    8000402c:	64a2                	ld	s1,8(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <ilock>:
{
    80004032:	1101                	addi	sp,sp,-32
    80004034:	ec06                	sd	ra,24(sp)
    80004036:	e822                	sd	s0,16(sp)
    80004038:	e426                	sd	s1,8(sp)
    8000403a:	e04a                	sd	s2,0(sp)
    8000403c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000403e:	c115                	beqz	a0,80004062 <ilock+0x30>
    80004040:	84aa                	mv	s1,a0
    80004042:	451c                	lw	a5,8(a0)
    80004044:	00f05f63          	blez	a5,80004062 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004048:	0541                	addi	a0,a0,16
    8000404a:	00001097          	auipc	ra,0x1
    8000404e:	cb2080e7          	jalr	-846(ra) # 80004cfc <acquiresleep>
  if(ip->valid == 0){
    80004052:	40bc                	lw	a5,64(s1)
    80004054:	cf99                	beqz	a5,80004072 <ilock+0x40>
}
    80004056:	60e2                	ld	ra,24(sp)
    80004058:	6442                	ld	s0,16(sp)
    8000405a:	64a2                	ld	s1,8(sp)
    8000405c:	6902                	ld	s2,0(sp)
    8000405e:	6105                	addi	sp,sp,32
    80004060:	8082                	ret
    panic("ilock");
    80004062:	00004517          	auipc	a0,0x4
    80004066:	6e650513          	addi	a0,a0,1766 # 80008748 <syscalls+0x198>
    8000406a:	ffffc097          	auipc	ra,0xffffc
    8000406e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004072:	40dc                	lw	a5,4(s1)
    80004074:	0047d79b          	srliw	a5,a5,0x4
    80004078:	0001c597          	auipc	a1,0x1c
    8000407c:	2c85a583          	lw	a1,712(a1) # 80020340 <sb+0x18>
    80004080:	9dbd                	addw	a1,a1,a5
    80004082:	4088                	lw	a0,0(s1)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	7ac080e7          	jalr	1964(ra) # 80003830 <bread>
    8000408c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000408e:	05850593          	addi	a1,a0,88
    80004092:	40dc                	lw	a5,4(s1)
    80004094:	8bbd                	andi	a5,a5,15
    80004096:	079a                	slli	a5,a5,0x6
    80004098:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000409a:	00059783          	lh	a5,0(a1)
    8000409e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040a2:	00259783          	lh	a5,2(a1)
    800040a6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040aa:	00459783          	lh	a5,4(a1)
    800040ae:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040b2:	00659783          	lh	a5,6(a1)
    800040b6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040ba:	459c                	lw	a5,8(a1)
    800040bc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040be:	03400613          	li	a2,52
    800040c2:	05b1                	addi	a1,a1,12
    800040c4:	05048513          	addi	a0,s1,80
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	c78080e7          	jalr	-904(ra) # 80000d40 <memmove>
    brelse(bp);
    800040d0:	854a                	mv	a0,s2
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	88e080e7          	jalr	-1906(ra) # 80003960 <brelse>
    ip->valid = 1;
    800040da:	4785                	li	a5,1
    800040dc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800040de:	04449783          	lh	a5,68(s1)
    800040e2:	fbb5                	bnez	a5,80004056 <ilock+0x24>
      panic("ilock: no type");
    800040e4:	00004517          	auipc	a0,0x4
    800040e8:	66c50513          	addi	a0,a0,1644 # 80008750 <syscalls+0x1a0>
    800040ec:	ffffc097          	auipc	ra,0xffffc
    800040f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>

00000000800040f4 <iunlock>:
{
    800040f4:	1101                	addi	sp,sp,-32
    800040f6:	ec06                	sd	ra,24(sp)
    800040f8:	e822                	sd	s0,16(sp)
    800040fa:	e426                	sd	s1,8(sp)
    800040fc:	e04a                	sd	s2,0(sp)
    800040fe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004100:	c905                	beqz	a0,80004130 <iunlock+0x3c>
    80004102:	84aa                	mv	s1,a0
    80004104:	01050913          	addi	s2,a0,16
    80004108:	854a                	mv	a0,s2
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	c8c080e7          	jalr	-884(ra) # 80004d96 <holdingsleep>
    80004112:	cd19                	beqz	a0,80004130 <iunlock+0x3c>
    80004114:	449c                	lw	a5,8(s1)
    80004116:	00f05d63          	blez	a5,80004130 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000411a:	854a                	mv	a0,s2
    8000411c:	00001097          	auipc	ra,0x1
    80004120:	c36080e7          	jalr	-970(ra) # 80004d52 <releasesleep>
}
    80004124:	60e2                	ld	ra,24(sp)
    80004126:	6442                	ld	s0,16(sp)
    80004128:	64a2                	ld	s1,8(sp)
    8000412a:	6902                	ld	s2,0(sp)
    8000412c:	6105                	addi	sp,sp,32
    8000412e:	8082                	ret
    panic("iunlock");
    80004130:	00004517          	auipc	a0,0x4
    80004134:	63050513          	addi	a0,a0,1584 # 80008760 <syscalls+0x1b0>
    80004138:	ffffc097          	auipc	ra,0xffffc
    8000413c:	406080e7          	jalr	1030(ra) # 8000053e <panic>

0000000080004140 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004140:	7179                	addi	sp,sp,-48
    80004142:	f406                	sd	ra,40(sp)
    80004144:	f022                	sd	s0,32(sp)
    80004146:	ec26                	sd	s1,24(sp)
    80004148:	e84a                	sd	s2,16(sp)
    8000414a:	e44e                	sd	s3,8(sp)
    8000414c:	e052                	sd	s4,0(sp)
    8000414e:	1800                	addi	s0,sp,48
    80004150:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004152:	05050493          	addi	s1,a0,80
    80004156:	08050913          	addi	s2,a0,128
    8000415a:	a021                	j	80004162 <itrunc+0x22>
    8000415c:	0491                	addi	s1,s1,4
    8000415e:	01248d63          	beq	s1,s2,80004178 <itrunc+0x38>
    if(ip->addrs[i]){
    80004162:	408c                	lw	a1,0(s1)
    80004164:	dde5                	beqz	a1,8000415c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004166:	0009a503          	lw	a0,0(s3)
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	90c080e7          	jalr	-1780(ra) # 80003a76 <bfree>
      ip->addrs[i] = 0;
    80004172:	0004a023          	sw	zero,0(s1)
    80004176:	b7dd                	j	8000415c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004178:	0809a583          	lw	a1,128(s3)
    8000417c:	e185                	bnez	a1,8000419c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000417e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004182:	854e                	mv	a0,s3
    80004184:	00000097          	auipc	ra,0x0
    80004188:	de4080e7          	jalr	-540(ra) # 80003f68 <iupdate>
}
    8000418c:	70a2                	ld	ra,40(sp)
    8000418e:	7402                	ld	s0,32(sp)
    80004190:	64e2                	ld	s1,24(sp)
    80004192:	6942                	ld	s2,16(sp)
    80004194:	69a2                	ld	s3,8(sp)
    80004196:	6a02                	ld	s4,0(sp)
    80004198:	6145                	addi	sp,sp,48
    8000419a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000419c:	0009a503          	lw	a0,0(s3)
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	690080e7          	jalr	1680(ra) # 80003830 <bread>
    800041a8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041aa:	05850493          	addi	s1,a0,88
    800041ae:	45850913          	addi	s2,a0,1112
    800041b2:	a811                	j	800041c6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800041b4:	0009a503          	lw	a0,0(s3)
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	8be080e7          	jalr	-1858(ra) # 80003a76 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800041c0:	0491                	addi	s1,s1,4
    800041c2:	01248563          	beq	s1,s2,800041cc <itrunc+0x8c>
      if(a[j])
    800041c6:	408c                	lw	a1,0(s1)
    800041c8:	dde5                	beqz	a1,800041c0 <itrunc+0x80>
    800041ca:	b7ed                	j	800041b4 <itrunc+0x74>
    brelse(bp);
    800041cc:	8552                	mv	a0,s4
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	792080e7          	jalr	1938(ra) # 80003960 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041d6:	0809a583          	lw	a1,128(s3)
    800041da:	0009a503          	lw	a0,0(s3)
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	898080e7          	jalr	-1896(ra) # 80003a76 <bfree>
    ip->addrs[NDIRECT] = 0;
    800041e6:	0809a023          	sw	zero,128(s3)
    800041ea:	bf51                	j	8000417e <itrunc+0x3e>

00000000800041ec <iput>:
{
    800041ec:	1101                	addi	sp,sp,-32
    800041ee:	ec06                	sd	ra,24(sp)
    800041f0:	e822                	sd	s0,16(sp)
    800041f2:	e426                	sd	s1,8(sp)
    800041f4:	e04a                	sd	s2,0(sp)
    800041f6:	1000                	addi	s0,sp,32
    800041f8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041fa:	0001c517          	auipc	a0,0x1c
    800041fe:	14e50513          	addi	a0,a0,334 # 80020348 <itable>
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000420a:	4498                	lw	a4,8(s1)
    8000420c:	4785                	li	a5,1
    8000420e:	02f70363          	beq	a4,a5,80004234 <iput+0x48>
  ip->ref--;
    80004212:	449c                	lw	a5,8(s1)
    80004214:	37fd                	addiw	a5,a5,-1
    80004216:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004218:	0001c517          	auipc	a0,0x1c
    8000421c:	13050513          	addi	a0,a0,304 # 80020348 <itable>
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
}
    80004228:	60e2                	ld	ra,24(sp)
    8000422a:	6442                	ld	s0,16(sp)
    8000422c:	64a2                	ld	s1,8(sp)
    8000422e:	6902                	ld	s2,0(sp)
    80004230:	6105                	addi	sp,sp,32
    80004232:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004234:	40bc                	lw	a5,64(s1)
    80004236:	dff1                	beqz	a5,80004212 <iput+0x26>
    80004238:	04a49783          	lh	a5,74(s1)
    8000423c:	fbf9                	bnez	a5,80004212 <iput+0x26>
    acquiresleep(&ip->lock);
    8000423e:	01048913          	addi	s2,s1,16
    80004242:	854a                	mv	a0,s2
    80004244:	00001097          	auipc	ra,0x1
    80004248:	ab8080e7          	jalr	-1352(ra) # 80004cfc <acquiresleep>
    release(&itable.lock);
    8000424c:	0001c517          	auipc	a0,0x1c
    80004250:	0fc50513          	addi	a0,a0,252 # 80020348 <itable>
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a44080e7          	jalr	-1468(ra) # 80000c98 <release>
    itrunc(ip);
    8000425c:	8526                	mv	a0,s1
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	ee2080e7          	jalr	-286(ra) # 80004140 <itrunc>
    ip->type = 0;
    80004266:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000426a:	8526                	mv	a0,s1
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	cfc080e7          	jalr	-772(ra) # 80003f68 <iupdate>
    ip->valid = 0;
    80004274:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004278:	854a                	mv	a0,s2
    8000427a:	00001097          	auipc	ra,0x1
    8000427e:	ad8080e7          	jalr	-1320(ra) # 80004d52 <releasesleep>
    acquire(&itable.lock);
    80004282:	0001c517          	auipc	a0,0x1c
    80004286:	0c650513          	addi	a0,a0,198 # 80020348 <itable>
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	95a080e7          	jalr	-1702(ra) # 80000be4 <acquire>
    80004292:	b741                	j	80004212 <iput+0x26>

0000000080004294 <iunlockput>:
{
    80004294:	1101                	addi	sp,sp,-32
    80004296:	ec06                	sd	ra,24(sp)
    80004298:	e822                	sd	s0,16(sp)
    8000429a:	e426                	sd	s1,8(sp)
    8000429c:	1000                	addi	s0,sp,32
    8000429e:	84aa                	mv	s1,a0
  iunlock(ip);
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	e54080e7          	jalr	-428(ra) # 800040f4 <iunlock>
  iput(ip);
    800042a8:	8526                	mv	a0,s1
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	f42080e7          	jalr	-190(ra) # 800041ec <iput>
}
    800042b2:	60e2                	ld	ra,24(sp)
    800042b4:	6442                	ld	s0,16(sp)
    800042b6:	64a2                	ld	s1,8(sp)
    800042b8:	6105                	addi	sp,sp,32
    800042ba:	8082                	ret

00000000800042bc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042bc:	1141                	addi	sp,sp,-16
    800042be:	e422                	sd	s0,8(sp)
    800042c0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042c2:	411c                	lw	a5,0(a0)
    800042c4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042c6:	415c                	lw	a5,4(a0)
    800042c8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042ca:	04451783          	lh	a5,68(a0)
    800042ce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042d2:	04a51783          	lh	a5,74(a0)
    800042d6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042da:	04c56783          	lwu	a5,76(a0)
    800042de:	e99c                	sd	a5,16(a1)
}
    800042e0:	6422                	ld	s0,8(sp)
    800042e2:	0141                	addi	sp,sp,16
    800042e4:	8082                	ret

00000000800042e6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042e6:	457c                	lw	a5,76(a0)
    800042e8:	0ed7e963          	bltu	a5,a3,800043da <readi+0xf4>
{
    800042ec:	7159                	addi	sp,sp,-112
    800042ee:	f486                	sd	ra,104(sp)
    800042f0:	f0a2                	sd	s0,96(sp)
    800042f2:	eca6                	sd	s1,88(sp)
    800042f4:	e8ca                	sd	s2,80(sp)
    800042f6:	e4ce                	sd	s3,72(sp)
    800042f8:	e0d2                	sd	s4,64(sp)
    800042fa:	fc56                	sd	s5,56(sp)
    800042fc:	f85a                	sd	s6,48(sp)
    800042fe:	f45e                	sd	s7,40(sp)
    80004300:	f062                	sd	s8,32(sp)
    80004302:	ec66                	sd	s9,24(sp)
    80004304:	e86a                	sd	s10,16(sp)
    80004306:	e46e                	sd	s11,8(sp)
    80004308:	1880                	addi	s0,sp,112
    8000430a:	8baa                	mv	s7,a0
    8000430c:	8c2e                	mv	s8,a1
    8000430e:	8ab2                	mv	s5,a2
    80004310:	84b6                	mv	s1,a3
    80004312:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004314:	9f35                	addw	a4,a4,a3
    return 0;
    80004316:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004318:	0ad76063          	bltu	a4,a3,800043b8 <readi+0xd2>
  if(off + n > ip->size)
    8000431c:	00e7f463          	bgeu	a5,a4,80004324 <readi+0x3e>
    n = ip->size - off;
    80004320:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004324:	0a0b0963          	beqz	s6,800043d6 <readi+0xf0>
    80004328:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000432a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000432e:	5cfd                	li	s9,-1
    80004330:	a82d                	j	8000436a <readi+0x84>
    80004332:	020a1d93          	slli	s11,s4,0x20
    80004336:	020ddd93          	srli	s11,s11,0x20
    8000433a:	05890613          	addi	a2,s2,88
    8000433e:	86ee                	mv	a3,s11
    80004340:	963a                	add	a2,a2,a4
    80004342:	85d6                	mv	a1,s5
    80004344:	8562                	mv	a0,s8
    80004346:	ffffe097          	auipc	ra,0xffffe
    8000434a:	4ea080e7          	jalr	1258(ra) # 80002830 <either_copyout>
    8000434e:	05950d63          	beq	a0,s9,800043a8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004352:	854a                	mv	a0,s2
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	60c080e7          	jalr	1548(ra) # 80003960 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000435c:	013a09bb          	addw	s3,s4,s3
    80004360:	009a04bb          	addw	s1,s4,s1
    80004364:	9aee                	add	s5,s5,s11
    80004366:	0569f763          	bgeu	s3,s6,800043b4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000436a:	000ba903          	lw	s2,0(s7)
    8000436e:	00a4d59b          	srliw	a1,s1,0xa
    80004372:	855e                	mv	a0,s7
    80004374:	00000097          	auipc	ra,0x0
    80004378:	8b0080e7          	jalr	-1872(ra) # 80003c24 <bmap>
    8000437c:	0005059b          	sext.w	a1,a0
    80004380:	854a                	mv	a0,s2
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	4ae080e7          	jalr	1198(ra) # 80003830 <bread>
    8000438a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000438c:	3ff4f713          	andi	a4,s1,1023
    80004390:	40ed07bb          	subw	a5,s10,a4
    80004394:	413b06bb          	subw	a3,s6,s3
    80004398:	8a3e                	mv	s4,a5
    8000439a:	2781                	sext.w	a5,a5
    8000439c:	0006861b          	sext.w	a2,a3
    800043a0:	f8f679e3          	bgeu	a2,a5,80004332 <readi+0x4c>
    800043a4:	8a36                	mv	s4,a3
    800043a6:	b771                	j	80004332 <readi+0x4c>
      brelse(bp);
    800043a8:	854a                	mv	a0,s2
    800043aa:	fffff097          	auipc	ra,0xfffff
    800043ae:	5b6080e7          	jalr	1462(ra) # 80003960 <brelse>
      tot = -1;
    800043b2:	59fd                	li	s3,-1
  }
  return tot;
    800043b4:	0009851b          	sext.w	a0,s3
}
    800043b8:	70a6                	ld	ra,104(sp)
    800043ba:	7406                	ld	s0,96(sp)
    800043bc:	64e6                	ld	s1,88(sp)
    800043be:	6946                	ld	s2,80(sp)
    800043c0:	69a6                	ld	s3,72(sp)
    800043c2:	6a06                	ld	s4,64(sp)
    800043c4:	7ae2                	ld	s5,56(sp)
    800043c6:	7b42                	ld	s6,48(sp)
    800043c8:	7ba2                	ld	s7,40(sp)
    800043ca:	7c02                	ld	s8,32(sp)
    800043cc:	6ce2                	ld	s9,24(sp)
    800043ce:	6d42                	ld	s10,16(sp)
    800043d0:	6da2                	ld	s11,8(sp)
    800043d2:	6165                	addi	sp,sp,112
    800043d4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043d6:	89da                	mv	s3,s6
    800043d8:	bff1                	j	800043b4 <readi+0xce>
    return 0;
    800043da:	4501                	li	a0,0
}
    800043dc:	8082                	ret

00000000800043de <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043de:	457c                	lw	a5,76(a0)
    800043e0:	10d7e863          	bltu	a5,a3,800044f0 <writei+0x112>
{
    800043e4:	7159                	addi	sp,sp,-112
    800043e6:	f486                	sd	ra,104(sp)
    800043e8:	f0a2                	sd	s0,96(sp)
    800043ea:	eca6                	sd	s1,88(sp)
    800043ec:	e8ca                	sd	s2,80(sp)
    800043ee:	e4ce                	sd	s3,72(sp)
    800043f0:	e0d2                	sd	s4,64(sp)
    800043f2:	fc56                	sd	s5,56(sp)
    800043f4:	f85a                	sd	s6,48(sp)
    800043f6:	f45e                	sd	s7,40(sp)
    800043f8:	f062                	sd	s8,32(sp)
    800043fa:	ec66                	sd	s9,24(sp)
    800043fc:	e86a                	sd	s10,16(sp)
    800043fe:	e46e                	sd	s11,8(sp)
    80004400:	1880                	addi	s0,sp,112
    80004402:	8b2a                	mv	s6,a0
    80004404:	8c2e                	mv	s8,a1
    80004406:	8ab2                	mv	s5,a2
    80004408:	8936                	mv	s2,a3
    8000440a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000440c:	00e687bb          	addw	a5,a3,a4
    80004410:	0ed7e263          	bltu	a5,a3,800044f4 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004414:	00043737          	lui	a4,0x43
    80004418:	0ef76063          	bltu	a4,a5,800044f8 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000441c:	0c0b8863          	beqz	s7,800044ec <writei+0x10e>
    80004420:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004422:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004426:	5cfd                	li	s9,-1
    80004428:	a091                	j	8000446c <writei+0x8e>
    8000442a:	02099d93          	slli	s11,s3,0x20
    8000442e:	020ddd93          	srli	s11,s11,0x20
    80004432:	05848513          	addi	a0,s1,88
    80004436:	86ee                	mv	a3,s11
    80004438:	8656                	mv	a2,s5
    8000443a:	85e2                	mv	a1,s8
    8000443c:	953a                	add	a0,a0,a4
    8000443e:	ffffe097          	auipc	ra,0xffffe
    80004442:	448080e7          	jalr	1096(ra) # 80002886 <either_copyin>
    80004446:	07950263          	beq	a0,s9,800044aa <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000444a:	8526                	mv	a0,s1
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	790080e7          	jalr	1936(ra) # 80004bdc <log_write>
    brelse(bp);
    80004454:	8526                	mv	a0,s1
    80004456:	fffff097          	auipc	ra,0xfffff
    8000445a:	50a080e7          	jalr	1290(ra) # 80003960 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000445e:	01498a3b          	addw	s4,s3,s4
    80004462:	0129893b          	addw	s2,s3,s2
    80004466:	9aee                	add	s5,s5,s11
    80004468:	057a7663          	bgeu	s4,s7,800044b4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000446c:	000b2483          	lw	s1,0(s6)
    80004470:	00a9559b          	srliw	a1,s2,0xa
    80004474:	855a                	mv	a0,s6
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	7ae080e7          	jalr	1966(ra) # 80003c24 <bmap>
    8000447e:	0005059b          	sext.w	a1,a0
    80004482:	8526                	mv	a0,s1
    80004484:	fffff097          	auipc	ra,0xfffff
    80004488:	3ac080e7          	jalr	940(ra) # 80003830 <bread>
    8000448c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000448e:	3ff97713          	andi	a4,s2,1023
    80004492:	40ed07bb          	subw	a5,s10,a4
    80004496:	414b86bb          	subw	a3,s7,s4
    8000449a:	89be                	mv	s3,a5
    8000449c:	2781                	sext.w	a5,a5
    8000449e:	0006861b          	sext.w	a2,a3
    800044a2:	f8f674e3          	bgeu	a2,a5,8000442a <writei+0x4c>
    800044a6:	89b6                	mv	s3,a3
    800044a8:	b749                	j	8000442a <writei+0x4c>
      brelse(bp);
    800044aa:	8526                	mv	a0,s1
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	4b4080e7          	jalr	1204(ra) # 80003960 <brelse>
  }

  if(off > ip->size)
    800044b4:	04cb2783          	lw	a5,76(s6)
    800044b8:	0127f463          	bgeu	a5,s2,800044c0 <writei+0xe2>
    ip->size = off;
    800044bc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044c0:	855a                	mv	a0,s6
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	aa6080e7          	jalr	-1370(ra) # 80003f68 <iupdate>

  return tot;
    800044ca:	000a051b          	sext.w	a0,s4
}
    800044ce:	70a6                	ld	ra,104(sp)
    800044d0:	7406                	ld	s0,96(sp)
    800044d2:	64e6                	ld	s1,88(sp)
    800044d4:	6946                	ld	s2,80(sp)
    800044d6:	69a6                	ld	s3,72(sp)
    800044d8:	6a06                	ld	s4,64(sp)
    800044da:	7ae2                	ld	s5,56(sp)
    800044dc:	7b42                	ld	s6,48(sp)
    800044de:	7ba2                	ld	s7,40(sp)
    800044e0:	7c02                	ld	s8,32(sp)
    800044e2:	6ce2                	ld	s9,24(sp)
    800044e4:	6d42                	ld	s10,16(sp)
    800044e6:	6da2                	ld	s11,8(sp)
    800044e8:	6165                	addi	sp,sp,112
    800044ea:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044ec:	8a5e                	mv	s4,s7
    800044ee:	bfc9                	j	800044c0 <writei+0xe2>
    return -1;
    800044f0:	557d                	li	a0,-1
}
    800044f2:	8082                	ret
    return -1;
    800044f4:	557d                	li	a0,-1
    800044f6:	bfe1                	j	800044ce <writei+0xf0>
    return -1;
    800044f8:	557d                	li	a0,-1
    800044fa:	bfd1                	j	800044ce <writei+0xf0>

00000000800044fc <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800044fc:	1141                	addi	sp,sp,-16
    800044fe:	e406                	sd	ra,8(sp)
    80004500:	e022                	sd	s0,0(sp)
    80004502:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004504:	4639                	li	a2,14
    80004506:	ffffd097          	auipc	ra,0xffffd
    8000450a:	8b2080e7          	jalr	-1870(ra) # 80000db8 <strncmp>
}
    8000450e:	60a2                	ld	ra,8(sp)
    80004510:	6402                	ld	s0,0(sp)
    80004512:	0141                	addi	sp,sp,16
    80004514:	8082                	ret

0000000080004516 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004516:	7139                	addi	sp,sp,-64
    80004518:	fc06                	sd	ra,56(sp)
    8000451a:	f822                	sd	s0,48(sp)
    8000451c:	f426                	sd	s1,40(sp)
    8000451e:	f04a                	sd	s2,32(sp)
    80004520:	ec4e                	sd	s3,24(sp)
    80004522:	e852                	sd	s4,16(sp)
    80004524:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004526:	04451703          	lh	a4,68(a0)
    8000452a:	4785                	li	a5,1
    8000452c:	00f71a63          	bne	a4,a5,80004540 <dirlookup+0x2a>
    80004530:	892a                	mv	s2,a0
    80004532:	89ae                	mv	s3,a1
    80004534:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004536:	457c                	lw	a5,76(a0)
    80004538:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000453a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000453c:	e79d                	bnez	a5,8000456a <dirlookup+0x54>
    8000453e:	a8a5                	j	800045b6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004540:	00004517          	auipc	a0,0x4
    80004544:	22850513          	addi	a0,a0,552 # 80008768 <syscalls+0x1b8>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	ff6080e7          	jalr	-10(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004550:	00004517          	auipc	a0,0x4
    80004554:	23050513          	addi	a0,a0,560 # 80008780 <syscalls+0x1d0>
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004560:	24c1                	addiw	s1,s1,16
    80004562:	04c92783          	lw	a5,76(s2)
    80004566:	04f4f763          	bgeu	s1,a5,800045b4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000456a:	4741                	li	a4,16
    8000456c:	86a6                	mv	a3,s1
    8000456e:	fc040613          	addi	a2,s0,-64
    80004572:	4581                	li	a1,0
    80004574:	854a                	mv	a0,s2
    80004576:	00000097          	auipc	ra,0x0
    8000457a:	d70080e7          	jalr	-656(ra) # 800042e6 <readi>
    8000457e:	47c1                	li	a5,16
    80004580:	fcf518e3          	bne	a0,a5,80004550 <dirlookup+0x3a>
    if(de.inum == 0)
    80004584:	fc045783          	lhu	a5,-64(s0)
    80004588:	dfe1                	beqz	a5,80004560 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000458a:	fc240593          	addi	a1,s0,-62
    8000458e:	854e                	mv	a0,s3
    80004590:	00000097          	auipc	ra,0x0
    80004594:	f6c080e7          	jalr	-148(ra) # 800044fc <namecmp>
    80004598:	f561                	bnez	a0,80004560 <dirlookup+0x4a>
      if(poff)
    8000459a:	000a0463          	beqz	s4,800045a2 <dirlookup+0x8c>
        *poff = off;
    8000459e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045a2:	fc045583          	lhu	a1,-64(s0)
    800045a6:	00092503          	lw	a0,0(s2)
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	754080e7          	jalr	1876(ra) # 80003cfe <iget>
    800045b2:	a011                	j	800045b6 <dirlookup+0xa0>
  return 0;
    800045b4:	4501                	li	a0,0
}
    800045b6:	70e2                	ld	ra,56(sp)
    800045b8:	7442                	ld	s0,48(sp)
    800045ba:	74a2                	ld	s1,40(sp)
    800045bc:	7902                	ld	s2,32(sp)
    800045be:	69e2                	ld	s3,24(sp)
    800045c0:	6a42                	ld	s4,16(sp)
    800045c2:	6121                	addi	sp,sp,64
    800045c4:	8082                	ret

00000000800045c6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045c6:	711d                	addi	sp,sp,-96
    800045c8:	ec86                	sd	ra,88(sp)
    800045ca:	e8a2                	sd	s0,80(sp)
    800045cc:	e4a6                	sd	s1,72(sp)
    800045ce:	e0ca                	sd	s2,64(sp)
    800045d0:	fc4e                	sd	s3,56(sp)
    800045d2:	f852                	sd	s4,48(sp)
    800045d4:	f456                	sd	s5,40(sp)
    800045d6:	f05a                	sd	s6,32(sp)
    800045d8:	ec5e                	sd	s7,24(sp)
    800045da:	e862                	sd	s8,16(sp)
    800045dc:	e466                	sd	s9,8(sp)
    800045de:	1080                	addi	s0,sp,96
    800045e0:	84aa                	mv	s1,a0
    800045e2:	8b2e                	mv	s6,a1
    800045e4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800045e6:	00054703          	lbu	a4,0(a0)
    800045ea:	02f00793          	li	a5,47
    800045ee:	02f70363          	beq	a4,a5,80004614 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800045f2:	ffffe097          	auipc	ra,0xffffe
    800045f6:	954080e7          	jalr	-1708(ra) # 80001f46 <myproc>
    800045fa:	15053503          	ld	a0,336(a0)
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	9f6080e7          	jalr	-1546(ra) # 80003ff4 <idup>
    80004606:	89aa                	mv	s3,a0
  while(*path == '/')
    80004608:	02f00913          	li	s2,47
  len = path - s;
    8000460c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000460e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004610:	4c05                	li	s8,1
    80004612:	a865                	j	800046ca <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004614:	4585                	li	a1,1
    80004616:	4505                	li	a0,1
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	6e6080e7          	jalr	1766(ra) # 80003cfe <iget>
    80004620:	89aa                	mv	s3,a0
    80004622:	b7dd                	j	80004608 <namex+0x42>
      iunlockput(ip);
    80004624:	854e                	mv	a0,s3
    80004626:	00000097          	auipc	ra,0x0
    8000462a:	c6e080e7          	jalr	-914(ra) # 80004294 <iunlockput>
      return 0;
    8000462e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004630:	854e                	mv	a0,s3
    80004632:	60e6                	ld	ra,88(sp)
    80004634:	6446                	ld	s0,80(sp)
    80004636:	64a6                	ld	s1,72(sp)
    80004638:	6906                	ld	s2,64(sp)
    8000463a:	79e2                	ld	s3,56(sp)
    8000463c:	7a42                	ld	s4,48(sp)
    8000463e:	7aa2                	ld	s5,40(sp)
    80004640:	7b02                	ld	s6,32(sp)
    80004642:	6be2                	ld	s7,24(sp)
    80004644:	6c42                	ld	s8,16(sp)
    80004646:	6ca2                	ld	s9,8(sp)
    80004648:	6125                	addi	sp,sp,96
    8000464a:	8082                	ret
      iunlock(ip);
    8000464c:	854e                	mv	a0,s3
    8000464e:	00000097          	auipc	ra,0x0
    80004652:	aa6080e7          	jalr	-1370(ra) # 800040f4 <iunlock>
      return ip;
    80004656:	bfe9                	j	80004630 <namex+0x6a>
      iunlockput(ip);
    80004658:	854e                	mv	a0,s3
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	c3a080e7          	jalr	-966(ra) # 80004294 <iunlockput>
      return 0;
    80004662:	89d2                	mv	s3,s4
    80004664:	b7f1                	j	80004630 <namex+0x6a>
  len = path - s;
    80004666:	40b48633          	sub	a2,s1,a1
    8000466a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000466e:	094cd463          	bge	s9,s4,800046f6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004672:	4639                	li	a2,14
    80004674:	8556                	mv	a0,s5
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	6ca080e7          	jalr	1738(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000467e:	0004c783          	lbu	a5,0(s1)
    80004682:	01279763          	bne	a5,s2,80004690 <namex+0xca>
    path++;
    80004686:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004688:	0004c783          	lbu	a5,0(s1)
    8000468c:	ff278de3          	beq	a5,s2,80004686 <namex+0xc0>
    ilock(ip);
    80004690:	854e                	mv	a0,s3
    80004692:	00000097          	auipc	ra,0x0
    80004696:	9a0080e7          	jalr	-1632(ra) # 80004032 <ilock>
    if(ip->type != T_DIR){
    8000469a:	04499783          	lh	a5,68(s3)
    8000469e:	f98793e3          	bne	a5,s8,80004624 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800046a2:	000b0563          	beqz	s6,800046ac <namex+0xe6>
    800046a6:	0004c783          	lbu	a5,0(s1)
    800046aa:	d3cd                	beqz	a5,8000464c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046ac:	865e                	mv	a2,s7
    800046ae:	85d6                	mv	a1,s5
    800046b0:	854e                	mv	a0,s3
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	e64080e7          	jalr	-412(ra) # 80004516 <dirlookup>
    800046ba:	8a2a                	mv	s4,a0
    800046bc:	dd51                	beqz	a0,80004658 <namex+0x92>
    iunlockput(ip);
    800046be:	854e                	mv	a0,s3
    800046c0:	00000097          	auipc	ra,0x0
    800046c4:	bd4080e7          	jalr	-1068(ra) # 80004294 <iunlockput>
    ip = next;
    800046c8:	89d2                	mv	s3,s4
  while(*path == '/')
    800046ca:	0004c783          	lbu	a5,0(s1)
    800046ce:	05279763          	bne	a5,s2,8000471c <namex+0x156>
    path++;
    800046d2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046d4:	0004c783          	lbu	a5,0(s1)
    800046d8:	ff278de3          	beq	a5,s2,800046d2 <namex+0x10c>
  if(*path == 0)
    800046dc:	c79d                	beqz	a5,8000470a <namex+0x144>
    path++;
    800046de:	85a6                	mv	a1,s1
  len = path - s;
    800046e0:	8a5e                	mv	s4,s7
    800046e2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800046e4:	01278963          	beq	a5,s2,800046f6 <namex+0x130>
    800046e8:	dfbd                	beqz	a5,80004666 <namex+0xa0>
    path++;
    800046ea:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800046ec:	0004c783          	lbu	a5,0(s1)
    800046f0:	ff279ce3          	bne	a5,s2,800046e8 <namex+0x122>
    800046f4:	bf8d                	j	80004666 <namex+0xa0>
    memmove(name, s, len);
    800046f6:	2601                	sext.w	a2,a2
    800046f8:	8556                	mv	a0,s5
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	646080e7          	jalr	1606(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004702:	9a56                	add	s4,s4,s5
    80004704:	000a0023          	sb	zero,0(s4)
    80004708:	bf9d                	j	8000467e <namex+0xb8>
  if(nameiparent){
    8000470a:	f20b03e3          	beqz	s6,80004630 <namex+0x6a>
    iput(ip);
    8000470e:	854e                	mv	a0,s3
    80004710:	00000097          	auipc	ra,0x0
    80004714:	adc080e7          	jalr	-1316(ra) # 800041ec <iput>
    return 0;
    80004718:	4981                	li	s3,0
    8000471a:	bf19                	j	80004630 <namex+0x6a>
  if(*path == 0)
    8000471c:	d7fd                	beqz	a5,8000470a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000471e:	0004c783          	lbu	a5,0(s1)
    80004722:	85a6                	mv	a1,s1
    80004724:	b7d1                	j	800046e8 <namex+0x122>

0000000080004726 <dirlink>:
{
    80004726:	7139                	addi	sp,sp,-64
    80004728:	fc06                	sd	ra,56(sp)
    8000472a:	f822                	sd	s0,48(sp)
    8000472c:	f426                	sd	s1,40(sp)
    8000472e:	f04a                	sd	s2,32(sp)
    80004730:	ec4e                	sd	s3,24(sp)
    80004732:	e852                	sd	s4,16(sp)
    80004734:	0080                	addi	s0,sp,64
    80004736:	892a                	mv	s2,a0
    80004738:	8a2e                	mv	s4,a1
    8000473a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000473c:	4601                	li	a2,0
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	dd8080e7          	jalr	-552(ra) # 80004516 <dirlookup>
    80004746:	e93d                	bnez	a0,800047bc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004748:	04c92483          	lw	s1,76(s2)
    8000474c:	c49d                	beqz	s1,8000477a <dirlink+0x54>
    8000474e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004750:	4741                	li	a4,16
    80004752:	86a6                	mv	a3,s1
    80004754:	fc040613          	addi	a2,s0,-64
    80004758:	4581                	li	a1,0
    8000475a:	854a                	mv	a0,s2
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	b8a080e7          	jalr	-1142(ra) # 800042e6 <readi>
    80004764:	47c1                	li	a5,16
    80004766:	06f51163          	bne	a0,a5,800047c8 <dirlink+0xa2>
    if(de.inum == 0)
    8000476a:	fc045783          	lhu	a5,-64(s0)
    8000476e:	c791                	beqz	a5,8000477a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004770:	24c1                	addiw	s1,s1,16
    80004772:	04c92783          	lw	a5,76(s2)
    80004776:	fcf4ede3          	bltu	s1,a5,80004750 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000477a:	4639                	li	a2,14
    8000477c:	85d2                	mv	a1,s4
    8000477e:	fc240513          	addi	a0,s0,-62
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	672080e7          	jalr	1650(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000478a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000478e:	4741                	li	a4,16
    80004790:	86a6                	mv	a3,s1
    80004792:	fc040613          	addi	a2,s0,-64
    80004796:	4581                	li	a1,0
    80004798:	854a                	mv	a0,s2
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	c44080e7          	jalr	-956(ra) # 800043de <writei>
    800047a2:	872a                	mv	a4,a0
    800047a4:	47c1                	li	a5,16
  return 0;
    800047a6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047a8:	02f71863          	bne	a4,a5,800047d8 <dirlink+0xb2>
}
    800047ac:	70e2                	ld	ra,56(sp)
    800047ae:	7442                	ld	s0,48(sp)
    800047b0:	74a2                	ld	s1,40(sp)
    800047b2:	7902                	ld	s2,32(sp)
    800047b4:	69e2                	ld	s3,24(sp)
    800047b6:	6a42                	ld	s4,16(sp)
    800047b8:	6121                	addi	sp,sp,64
    800047ba:	8082                	ret
    iput(ip);
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	a30080e7          	jalr	-1488(ra) # 800041ec <iput>
    return -1;
    800047c4:	557d                	li	a0,-1
    800047c6:	b7dd                	j	800047ac <dirlink+0x86>
      panic("dirlink read");
    800047c8:	00004517          	auipc	a0,0x4
    800047cc:	fc850513          	addi	a0,a0,-56 # 80008790 <syscalls+0x1e0>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	d6e080e7          	jalr	-658(ra) # 8000053e <panic>
    panic("dirlink");
    800047d8:	00004517          	auipc	a0,0x4
    800047dc:	0c850513          	addi	a0,a0,200 # 800088a0 <syscalls+0x2f0>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	d5e080e7          	jalr	-674(ra) # 8000053e <panic>

00000000800047e8 <namei>:

struct inode*
namei(char *path)
{
    800047e8:	1101                	addi	sp,sp,-32
    800047ea:	ec06                	sd	ra,24(sp)
    800047ec:	e822                	sd	s0,16(sp)
    800047ee:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800047f0:	fe040613          	addi	a2,s0,-32
    800047f4:	4581                	li	a1,0
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	dd0080e7          	jalr	-560(ra) # 800045c6 <namex>
}
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	6105                	addi	sp,sp,32
    80004804:	8082                	ret

0000000080004806 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004806:	1141                	addi	sp,sp,-16
    80004808:	e406                	sd	ra,8(sp)
    8000480a:	e022                	sd	s0,0(sp)
    8000480c:	0800                	addi	s0,sp,16
    8000480e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004810:	4585                	li	a1,1
    80004812:	00000097          	auipc	ra,0x0
    80004816:	db4080e7          	jalr	-588(ra) # 800045c6 <namex>
}
    8000481a:	60a2                	ld	ra,8(sp)
    8000481c:	6402                	ld	s0,0(sp)
    8000481e:	0141                	addi	sp,sp,16
    80004820:	8082                	ret

0000000080004822 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004822:	1101                	addi	sp,sp,-32
    80004824:	ec06                	sd	ra,24(sp)
    80004826:	e822                	sd	s0,16(sp)
    80004828:	e426                	sd	s1,8(sp)
    8000482a:	e04a                	sd	s2,0(sp)
    8000482c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000482e:	0001d917          	auipc	s2,0x1d
    80004832:	5c290913          	addi	s2,s2,1474 # 80021df0 <log>
    80004836:	01892583          	lw	a1,24(s2)
    8000483a:	02892503          	lw	a0,40(s2)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	ff2080e7          	jalr	-14(ra) # 80003830 <bread>
    80004846:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004848:	02c92683          	lw	a3,44(s2)
    8000484c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000484e:	02d05763          	blez	a3,8000487c <write_head+0x5a>
    80004852:	0001d797          	auipc	a5,0x1d
    80004856:	5ce78793          	addi	a5,a5,1486 # 80021e20 <log+0x30>
    8000485a:	05c50713          	addi	a4,a0,92
    8000485e:	36fd                	addiw	a3,a3,-1
    80004860:	1682                	slli	a3,a3,0x20
    80004862:	9281                	srli	a3,a3,0x20
    80004864:	068a                	slli	a3,a3,0x2
    80004866:	0001d617          	auipc	a2,0x1d
    8000486a:	5be60613          	addi	a2,a2,1470 # 80021e24 <log+0x34>
    8000486e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004870:	4390                	lw	a2,0(a5)
    80004872:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004874:	0791                	addi	a5,a5,4
    80004876:	0711                	addi	a4,a4,4
    80004878:	fed79ce3          	bne	a5,a3,80004870 <write_head+0x4e>
  }
  bwrite(buf);
    8000487c:	8526                	mv	a0,s1
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	0a4080e7          	jalr	164(ra) # 80003922 <bwrite>
  brelse(buf);
    80004886:	8526                	mv	a0,s1
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	0d8080e7          	jalr	216(ra) # 80003960 <brelse>
}
    80004890:	60e2                	ld	ra,24(sp)
    80004892:	6442                	ld	s0,16(sp)
    80004894:	64a2                	ld	s1,8(sp)
    80004896:	6902                	ld	s2,0(sp)
    80004898:	6105                	addi	sp,sp,32
    8000489a:	8082                	ret

000000008000489c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489c:	0001d797          	auipc	a5,0x1d
    800048a0:	5807a783          	lw	a5,1408(a5) # 80021e1c <log+0x2c>
    800048a4:	0af05d63          	blez	a5,8000495e <install_trans+0xc2>
{
    800048a8:	7139                	addi	sp,sp,-64
    800048aa:	fc06                	sd	ra,56(sp)
    800048ac:	f822                	sd	s0,48(sp)
    800048ae:	f426                	sd	s1,40(sp)
    800048b0:	f04a                	sd	s2,32(sp)
    800048b2:	ec4e                	sd	s3,24(sp)
    800048b4:	e852                	sd	s4,16(sp)
    800048b6:	e456                	sd	s5,8(sp)
    800048b8:	e05a                	sd	s6,0(sp)
    800048ba:	0080                	addi	s0,sp,64
    800048bc:	8b2a                	mv	s6,a0
    800048be:	0001da97          	auipc	s5,0x1d
    800048c2:	562a8a93          	addi	s5,s5,1378 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048c8:	0001d997          	auipc	s3,0x1d
    800048cc:	52898993          	addi	s3,s3,1320 # 80021df0 <log>
    800048d0:	a035                	j	800048fc <install_trans+0x60>
      bunpin(dbuf);
    800048d2:	8526                	mv	a0,s1
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	166080e7          	jalr	358(ra) # 80003a3a <bunpin>
    brelse(lbuf);
    800048dc:	854a                	mv	a0,s2
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	082080e7          	jalr	130(ra) # 80003960 <brelse>
    brelse(dbuf);
    800048e6:	8526                	mv	a0,s1
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	078080e7          	jalr	120(ra) # 80003960 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f0:	2a05                	addiw	s4,s4,1
    800048f2:	0a91                	addi	s5,s5,4
    800048f4:	02c9a783          	lw	a5,44(s3)
    800048f8:	04fa5963          	bge	s4,a5,8000494a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048fc:	0189a583          	lw	a1,24(s3)
    80004900:	014585bb          	addw	a1,a1,s4
    80004904:	2585                	addiw	a1,a1,1
    80004906:	0289a503          	lw	a0,40(s3)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	f26080e7          	jalr	-218(ra) # 80003830 <bread>
    80004912:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004914:	000aa583          	lw	a1,0(s5)
    80004918:	0289a503          	lw	a0,40(s3)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	f14080e7          	jalr	-236(ra) # 80003830 <bread>
    80004924:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004926:	40000613          	li	a2,1024
    8000492a:	05890593          	addi	a1,s2,88
    8000492e:	05850513          	addi	a0,a0,88
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	40e080e7          	jalr	1038(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000493a:	8526                	mv	a0,s1
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	fe6080e7          	jalr	-26(ra) # 80003922 <bwrite>
    if(recovering == 0)
    80004944:	f80b1ce3          	bnez	s6,800048dc <install_trans+0x40>
    80004948:	b769                	j	800048d2 <install_trans+0x36>
}
    8000494a:	70e2                	ld	ra,56(sp)
    8000494c:	7442                	ld	s0,48(sp)
    8000494e:	74a2                	ld	s1,40(sp)
    80004950:	7902                	ld	s2,32(sp)
    80004952:	69e2                	ld	s3,24(sp)
    80004954:	6a42                	ld	s4,16(sp)
    80004956:	6aa2                	ld	s5,8(sp)
    80004958:	6b02                	ld	s6,0(sp)
    8000495a:	6121                	addi	sp,sp,64
    8000495c:	8082                	ret
    8000495e:	8082                	ret

0000000080004960 <initlog>:
{
    80004960:	7179                	addi	sp,sp,-48
    80004962:	f406                	sd	ra,40(sp)
    80004964:	f022                	sd	s0,32(sp)
    80004966:	ec26                	sd	s1,24(sp)
    80004968:	e84a                	sd	s2,16(sp)
    8000496a:	e44e                	sd	s3,8(sp)
    8000496c:	1800                	addi	s0,sp,48
    8000496e:	892a                	mv	s2,a0
    80004970:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004972:	0001d497          	auipc	s1,0x1d
    80004976:	47e48493          	addi	s1,s1,1150 # 80021df0 <log>
    8000497a:	00004597          	auipc	a1,0x4
    8000497e:	e2658593          	addi	a1,a1,-474 # 800087a0 <syscalls+0x1f0>
    80004982:	8526                	mv	a0,s1
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	1d0080e7          	jalr	464(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000498c:	0149a583          	lw	a1,20(s3)
    80004990:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004992:	0109a783          	lw	a5,16(s3)
    80004996:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004998:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000499c:	854a                	mv	a0,s2
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	e92080e7          	jalr	-366(ra) # 80003830 <bread>
  log.lh.n = lh->n;
    800049a6:	4d3c                	lw	a5,88(a0)
    800049a8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049aa:	02f05563          	blez	a5,800049d4 <initlog+0x74>
    800049ae:	05c50713          	addi	a4,a0,92
    800049b2:	0001d697          	auipc	a3,0x1d
    800049b6:	46e68693          	addi	a3,a3,1134 # 80021e20 <log+0x30>
    800049ba:	37fd                	addiw	a5,a5,-1
    800049bc:	1782                	slli	a5,a5,0x20
    800049be:	9381                	srli	a5,a5,0x20
    800049c0:	078a                	slli	a5,a5,0x2
    800049c2:	06050613          	addi	a2,a0,96
    800049c6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800049c8:	4310                	lw	a2,0(a4)
    800049ca:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800049cc:	0711                	addi	a4,a4,4
    800049ce:	0691                	addi	a3,a3,4
    800049d0:	fef71ce3          	bne	a4,a5,800049c8 <initlog+0x68>
  brelse(buf);
    800049d4:	fffff097          	auipc	ra,0xfffff
    800049d8:	f8c080e7          	jalr	-116(ra) # 80003960 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049dc:	4505                	li	a0,1
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	ebe080e7          	jalr	-322(ra) # 8000489c <install_trans>
  log.lh.n = 0;
    800049e6:	0001d797          	auipc	a5,0x1d
    800049ea:	4207ab23          	sw	zero,1078(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	e34080e7          	jalr	-460(ra) # 80004822 <write_head>
}
    800049f6:	70a2                	ld	ra,40(sp)
    800049f8:	7402                	ld	s0,32(sp)
    800049fa:	64e2                	ld	s1,24(sp)
    800049fc:	6942                	ld	s2,16(sp)
    800049fe:	69a2                	ld	s3,8(sp)
    80004a00:	6145                	addi	sp,sp,48
    80004a02:	8082                	ret

0000000080004a04 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a04:	1101                	addi	sp,sp,-32
    80004a06:	ec06                	sd	ra,24(sp)
    80004a08:	e822                	sd	s0,16(sp)
    80004a0a:	e426                	sd	s1,8(sp)
    80004a0c:	e04a                	sd	s2,0(sp)
    80004a0e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a10:	0001d517          	auipc	a0,0x1d
    80004a14:	3e050513          	addi	a0,a0,992 # 80021df0 <log>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	1cc080e7          	jalr	460(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004a20:	0001d497          	auipc	s1,0x1d
    80004a24:	3d048493          	addi	s1,s1,976 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a28:	4979                	li	s2,30
    80004a2a:	a039                	j	80004a38 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a2c:	85a6                	mv	a1,s1
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffe097          	auipc	ra,0xffffe
    80004a34:	bbe080e7          	jalr	-1090(ra) # 800025ee <sleep>
    if(log.committing){
    80004a38:	50dc                	lw	a5,36(s1)
    80004a3a:	fbed                	bnez	a5,80004a2c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a3c:	509c                	lw	a5,32(s1)
    80004a3e:	0017871b          	addiw	a4,a5,1
    80004a42:	0007069b          	sext.w	a3,a4
    80004a46:	0027179b          	slliw	a5,a4,0x2
    80004a4a:	9fb9                	addw	a5,a5,a4
    80004a4c:	0017979b          	slliw	a5,a5,0x1
    80004a50:	54d8                	lw	a4,44(s1)
    80004a52:	9fb9                	addw	a5,a5,a4
    80004a54:	00f95963          	bge	s2,a5,80004a66 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a58:	85a6                	mv	a1,s1
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffe097          	auipc	ra,0xffffe
    80004a60:	b92080e7          	jalr	-1134(ra) # 800025ee <sleep>
    80004a64:	bfd1                	j	80004a38 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a66:	0001d517          	auipc	a0,0x1d
    80004a6a:	38a50513          	addi	a0,a0,906 # 80021df0 <log>
    80004a6e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	228080e7          	jalr	552(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004a78:	60e2                	ld	ra,24(sp)
    80004a7a:	6442                	ld	s0,16(sp)
    80004a7c:	64a2                	ld	s1,8(sp)
    80004a7e:	6902                	ld	s2,0(sp)
    80004a80:	6105                	addi	sp,sp,32
    80004a82:	8082                	ret

0000000080004a84 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a84:	7139                	addi	sp,sp,-64
    80004a86:	fc06                	sd	ra,56(sp)
    80004a88:	f822                	sd	s0,48(sp)
    80004a8a:	f426                	sd	s1,40(sp)
    80004a8c:	f04a                	sd	s2,32(sp)
    80004a8e:	ec4e                	sd	s3,24(sp)
    80004a90:	e852                	sd	s4,16(sp)
    80004a92:	e456                	sd	s5,8(sp)
    80004a94:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a96:	0001d497          	auipc	s1,0x1d
    80004a9a:	35a48493          	addi	s1,s1,858 # 80021df0 <log>
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	144080e7          	jalr	324(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004aa8:	509c                	lw	a5,32(s1)
    80004aaa:	37fd                	addiw	a5,a5,-1
    80004aac:	0007891b          	sext.w	s2,a5
    80004ab0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ab2:	50dc                	lw	a5,36(s1)
    80004ab4:	efb9                	bnez	a5,80004b12 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004ab6:	06091663          	bnez	s2,80004b22 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004aba:	0001d497          	auipc	s1,0x1d
    80004abe:	33648493          	addi	s1,s1,822 # 80021df0 <log>
    80004ac2:	4785                	li	a5,1
    80004ac4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1d0080e7          	jalr	464(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ad0:	54dc                	lw	a5,44(s1)
    80004ad2:	06f04763          	bgtz	a5,80004b40 <end_op+0xbc>
    acquire(&log.lock);
    80004ad6:	0001d497          	auipc	s1,0x1d
    80004ada:	31a48493          	addi	s1,s1,794 # 80021df0 <log>
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	104080e7          	jalr	260(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004ae8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffe097          	auipc	ra,0xffffe
    80004af2:	12a080e7          	jalr	298(ra) # 80002c18 <wakeup>
    release(&log.lock);
    80004af6:	8526                	mv	a0,s1
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	1a0080e7          	jalr	416(ra) # 80000c98 <release>
}
    80004b00:	70e2                	ld	ra,56(sp)
    80004b02:	7442                	ld	s0,48(sp)
    80004b04:	74a2                	ld	s1,40(sp)
    80004b06:	7902                	ld	s2,32(sp)
    80004b08:	69e2                	ld	s3,24(sp)
    80004b0a:	6a42                	ld	s4,16(sp)
    80004b0c:	6aa2                	ld	s5,8(sp)
    80004b0e:	6121                	addi	sp,sp,64
    80004b10:	8082                	ret
    panic("log.committing");
    80004b12:	00004517          	auipc	a0,0x4
    80004b16:	c9650513          	addi	a0,a0,-874 # 800087a8 <syscalls+0x1f8>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	a24080e7          	jalr	-1500(ra) # 8000053e <panic>
    wakeup(&log);
    80004b22:	0001d497          	auipc	s1,0x1d
    80004b26:	2ce48493          	addi	s1,s1,718 # 80021df0 <log>
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffe097          	auipc	ra,0xffffe
    80004b30:	0ec080e7          	jalr	236(ra) # 80002c18 <wakeup>
  release(&log.lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	162080e7          	jalr	354(ra) # 80000c98 <release>
  if(do_commit){
    80004b3e:	b7c9                	j	80004b00 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b40:	0001da97          	auipc	s5,0x1d
    80004b44:	2e0a8a93          	addi	s5,s5,736 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b48:	0001da17          	auipc	s4,0x1d
    80004b4c:	2a8a0a13          	addi	s4,s4,680 # 80021df0 <log>
    80004b50:	018a2583          	lw	a1,24(s4)
    80004b54:	012585bb          	addw	a1,a1,s2
    80004b58:	2585                	addiw	a1,a1,1
    80004b5a:	028a2503          	lw	a0,40(s4)
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	cd2080e7          	jalr	-814(ra) # 80003830 <bread>
    80004b66:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b68:	000aa583          	lw	a1,0(s5)
    80004b6c:	028a2503          	lw	a0,40(s4)
    80004b70:	fffff097          	auipc	ra,0xfffff
    80004b74:	cc0080e7          	jalr	-832(ra) # 80003830 <bread>
    80004b78:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b7a:	40000613          	li	a2,1024
    80004b7e:	05850593          	addi	a1,a0,88
    80004b82:	05848513          	addi	a0,s1,88
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	1ba080e7          	jalr	442(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004b8e:	8526                	mv	a0,s1
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	d92080e7          	jalr	-622(ra) # 80003922 <bwrite>
    brelse(from);
    80004b98:	854e                	mv	a0,s3
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	dc6080e7          	jalr	-570(ra) # 80003960 <brelse>
    brelse(to);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	dbc080e7          	jalr	-580(ra) # 80003960 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bac:	2905                	addiw	s2,s2,1
    80004bae:	0a91                	addi	s5,s5,4
    80004bb0:	02ca2783          	lw	a5,44(s4)
    80004bb4:	f8f94ee3          	blt	s2,a5,80004b50 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bb8:	00000097          	auipc	ra,0x0
    80004bbc:	c6a080e7          	jalr	-918(ra) # 80004822 <write_head>
    install_trans(0); // Now install writes to home locations
    80004bc0:	4501                	li	a0,0
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	cda080e7          	jalr	-806(ra) # 8000489c <install_trans>
    log.lh.n = 0;
    80004bca:	0001d797          	auipc	a5,0x1d
    80004bce:	2407a923          	sw	zero,594(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	c50080e7          	jalr	-944(ra) # 80004822 <write_head>
    80004bda:	bdf5                	j	80004ad6 <end_op+0x52>

0000000080004bdc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bdc:	1101                	addi	sp,sp,-32
    80004bde:	ec06                	sd	ra,24(sp)
    80004be0:	e822                	sd	s0,16(sp)
    80004be2:	e426                	sd	s1,8(sp)
    80004be4:	e04a                	sd	s2,0(sp)
    80004be6:	1000                	addi	s0,sp,32
    80004be8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bea:	0001d917          	auipc	s2,0x1d
    80004bee:	20690913          	addi	s2,s2,518 # 80021df0 <log>
    80004bf2:	854a                	mv	a0,s2
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	ff0080e7          	jalr	-16(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004bfc:	02c92603          	lw	a2,44(s2)
    80004c00:	47f5                	li	a5,29
    80004c02:	06c7c563          	blt	a5,a2,80004c6c <log_write+0x90>
    80004c06:	0001d797          	auipc	a5,0x1d
    80004c0a:	2067a783          	lw	a5,518(a5) # 80021e0c <log+0x1c>
    80004c0e:	37fd                	addiw	a5,a5,-1
    80004c10:	04f65e63          	bge	a2,a5,80004c6c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c14:	0001d797          	auipc	a5,0x1d
    80004c18:	1fc7a783          	lw	a5,508(a5) # 80021e10 <log+0x20>
    80004c1c:	06f05063          	blez	a5,80004c7c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c20:	4781                	li	a5,0
    80004c22:	06c05563          	blez	a2,80004c8c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c26:	44cc                	lw	a1,12(s1)
    80004c28:	0001d717          	auipc	a4,0x1d
    80004c2c:	1f870713          	addi	a4,a4,504 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c30:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c32:	4314                	lw	a3,0(a4)
    80004c34:	04b68c63          	beq	a3,a1,80004c8c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c38:	2785                	addiw	a5,a5,1
    80004c3a:	0711                	addi	a4,a4,4
    80004c3c:	fef61be3          	bne	a2,a5,80004c32 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c40:	0621                	addi	a2,a2,8
    80004c42:	060a                	slli	a2,a2,0x2
    80004c44:	0001d797          	auipc	a5,0x1d
    80004c48:	1ac78793          	addi	a5,a5,428 # 80021df0 <log>
    80004c4c:	963e                	add	a2,a2,a5
    80004c4e:	44dc                	lw	a5,12(s1)
    80004c50:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c52:	8526                	mv	a0,s1
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	daa080e7          	jalr	-598(ra) # 800039fe <bpin>
    log.lh.n++;
    80004c5c:	0001d717          	auipc	a4,0x1d
    80004c60:	19470713          	addi	a4,a4,404 # 80021df0 <log>
    80004c64:	575c                	lw	a5,44(a4)
    80004c66:	2785                	addiw	a5,a5,1
    80004c68:	d75c                	sw	a5,44(a4)
    80004c6a:	a835                	j	80004ca6 <log_write+0xca>
    panic("too big a transaction");
    80004c6c:	00004517          	auipc	a0,0x4
    80004c70:	b4c50513          	addi	a0,a0,-1204 # 800087b8 <syscalls+0x208>
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	8ca080e7          	jalr	-1846(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c7c:	00004517          	auipc	a0,0x4
    80004c80:	b5450513          	addi	a0,a0,-1196 # 800087d0 <syscalls+0x220>
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	8ba080e7          	jalr	-1862(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004c8c:	00878713          	addi	a4,a5,8
    80004c90:	00271693          	slli	a3,a4,0x2
    80004c94:	0001d717          	auipc	a4,0x1d
    80004c98:	15c70713          	addi	a4,a4,348 # 80021df0 <log>
    80004c9c:	9736                	add	a4,a4,a3
    80004c9e:	44d4                	lw	a3,12(s1)
    80004ca0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ca2:	faf608e3          	beq	a2,a5,80004c52 <log_write+0x76>
  }
  release(&log.lock);
    80004ca6:	0001d517          	auipc	a0,0x1d
    80004caa:	14a50513          	addi	a0,a0,330 # 80021df0 <log>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
}
    80004cb6:	60e2                	ld	ra,24(sp)
    80004cb8:	6442                	ld	s0,16(sp)
    80004cba:	64a2                	ld	s1,8(sp)
    80004cbc:	6902                	ld	s2,0(sp)
    80004cbe:	6105                	addi	sp,sp,32
    80004cc0:	8082                	ret

0000000080004cc2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cc2:	1101                	addi	sp,sp,-32
    80004cc4:	ec06                	sd	ra,24(sp)
    80004cc6:	e822                	sd	s0,16(sp)
    80004cc8:	e426                	sd	s1,8(sp)
    80004cca:	e04a                	sd	s2,0(sp)
    80004ccc:	1000                	addi	s0,sp,32
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004cd2:	00004597          	auipc	a1,0x4
    80004cd6:	b1e58593          	addi	a1,a1,-1250 # 800087f0 <syscalls+0x240>
    80004cda:	0521                	addi	a0,a0,8
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	e78080e7          	jalr	-392(ra) # 80000b54 <initlock>
  lk->name = name;
    80004ce4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ce8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004cec:	0204a423          	sw	zero,40(s1)
}
    80004cf0:	60e2                	ld	ra,24(sp)
    80004cf2:	6442                	ld	s0,16(sp)
    80004cf4:	64a2                	ld	s1,8(sp)
    80004cf6:	6902                	ld	s2,0(sp)
    80004cf8:	6105                	addi	sp,sp,32
    80004cfa:	8082                	ret

0000000080004cfc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004cfc:	1101                	addi	sp,sp,-32
    80004cfe:	ec06                	sd	ra,24(sp)
    80004d00:	e822                	sd	s0,16(sp)
    80004d02:	e426                	sd	s1,8(sp)
    80004d04:	e04a                	sd	s2,0(sp)
    80004d06:	1000                	addi	s0,sp,32
    80004d08:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d0a:	00850913          	addi	s2,a0,8
    80004d0e:	854a                	mv	a0,s2
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	ed4080e7          	jalr	-300(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004d18:	409c                	lw	a5,0(s1)
    80004d1a:	cb89                	beqz	a5,80004d2c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d1c:	85ca                	mv	a1,s2
    80004d1e:	8526                	mv	a0,s1
    80004d20:	ffffe097          	auipc	ra,0xffffe
    80004d24:	8ce080e7          	jalr	-1842(ra) # 800025ee <sleep>
  while (lk->locked) {
    80004d28:	409c                	lw	a5,0(s1)
    80004d2a:	fbed                	bnez	a5,80004d1c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d2c:	4785                	li	a5,1
    80004d2e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	216080e7          	jalr	534(ra) # 80001f46 <myproc>
    80004d38:	591c                	lw	a5,48(a0)
    80004d3a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d3c:	854a                	mv	a0,s2
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
}
    80004d46:	60e2                	ld	ra,24(sp)
    80004d48:	6442                	ld	s0,16(sp)
    80004d4a:	64a2                	ld	s1,8(sp)
    80004d4c:	6902                	ld	s2,0(sp)
    80004d4e:	6105                	addi	sp,sp,32
    80004d50:	8082                	ret

0000000080004d52 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d52:	1101                	addi	sp,sp,-32
    80004d54:	ec06                	sd	ra,24(sp)
    80004d56:	e822                	sd	s0,16(sp)
    80004d58:	e426                	sd	s1,8(sp)
    80004d5a:	e04a                	sd	s2,0(sp)
    80004d5c:	1000                	addi	s0,sp,32
    80004d5e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d60:	00850913          	addi	s2,a0,8
    80004d64:	854a                	mv	a0,s2
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	e7e080e7          	jalr	-386(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d6e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d72:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d76:	8526                	mv	a0,s1
    80004d78:	ffffe097          	auipc	ra,0xffffe
    80004d7c:	ea0080e7          	jalr	-352(ra) # 80002c18 <wakeup>
  release(&lk->lk);
    80004d80:	854a                	mv	a0,s2
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>
}
    80004d8a:	60e2                	ld	ra,24(sp)
    80004d8c:	6442                	ld	s0,16(sp)
    80004d8e:	64a2                	ld	s1,8(sp)
    80004d90:	6902                	ld	s2,0(sp)
    80004d92:	6105                	addi	sp,sp,32
    80004d94:	8082                	ret

0000000080004d96 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d96:	7179                	addi	sp,sp,-48
    80004d98:	f406                	sd	ra,40(sp)
    80004d9a:	f022                	sd	s0,32(sp)
    80004d9c:	ec26                	sd	s1,24(sp)
    80004d9e:	e84a                	sd	s2,16(sp)
    80004da0:	e44e                	sd	s3,8(sp)
    80004da2:	1800                	addi	s0,sp,48
    80004da4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004da6:	00850913          	addi	s2,a0,8
    80004daa:	854a                	mv	a0,s2
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	e38080e7          	jalr	-456(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004db4:	409c                	lw	a5,0(s1)
    80004db6:	ef99                	bnez	a5,80004dd4 <holdingsleep+0x3e>
    80004db8:	4481                	li	s1,0
  release(&lk->lk);
    80004dba:	854a                	mv	a0,s2
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	edc080e7          	jalr	-292(ra) # 80000c98 <release>
  return r;
}
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	70a2                	ld	ra,40(sp)
    80004dc8:	7402                	ld	s0,32(sp)
    80004dca:	64e2                	ld	s1,24(sp)
    80004dcc:	6942                	ld	s2,16(sp)
    80004dce:	69a2                	ld	s3,8(sp)
    80004dd0:	6145                	addi	sp,sp,48
    80004dd2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dd4:	0284a983          	lw	s3,40(s1)
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	16e080e7          	jalr	366(ra) # 80001f46 <myproc>
    80004de0:	5904                	lw	s1,48(a0)
    80004de2:	413484b3          	sub	s1,s1,s3
    80004de6:	0014b493          	seqz	s1,s1
    80004dea:	bfc1                	j	80004dba <holdingsleep+0x24>

0000000080004dec <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004dec:	1141                	addi	sp,sp,-16
    80004dee:	e406                	sd	ra,8(sp)
    80004df0:	e022                	sd	s0,0(sp)
    80004df2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004df4:	00004597          	auipc	a1,0x4
    80004df8:	a0c58593          	addi	a1,a1,-1524 # 80008800 <syscalls+0x250>
    80004dfc:	0001d517          	auipc	a0,0x1d
    80004e00:	13c50513          	addi	a0,a0,316 # 80021f38 <ftable>
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	d50080e7          	jalr	-688(ra) # 80000b54 <initlock>
}
    80004e0c:	60a2                	ld	ra,8(sp)
    80004e0e:	6402                	ld	s0,0(sp)
    80004e10:	0141                	addi	sp,sp,16
    80004e12:	8082                	ret

0000000080004e14 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e14:	1101                	addi	sp,sp,-32
    80004e16:	ec06                	sd	ra,24(sp)
    80004e18:	e822                	sd	s0,16(sp)
    80004e1a:	e426                	sd	s1,8(sp)
    80004e1c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e1e:	0001d517          	auipc	a0,0x1d
    80004e22:	11a50513          	addi	a0,a0,282 # 80021f38 <ftable>
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	dbe080e7          	jalr	-578(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e2e:	0001d497          	auipc	s1,0x1d
    80004e32:	12248493          	addi	s1,s1,290 # 80021f50 <ftable+0x18>
    80004e36:	0001e717          	auipc	a4,0x1e
    80004e3a:	0ba70713          	addi	a4,a4,186 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004e3e:	40dc                	lw	a5,4(s1)
    80004e40:	cf99                	beqz	a5,80004e5e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e42:	02848493          	addi	s1,s1,40
    80004e46:	fee49ce3          	bne	s1,a4,80004e3e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e4a:	0001d517          	auipc	a0,0x1d
    80004e4e:	0ee50513          	addi	a0,a0,238 # 80021f38 <ftable>
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>
  return 0;
    80004e5a:	4481                	li	s1,0
    80004e5c:	a819                	j	80004e72 <filealloc+0x5e>
      f->ref = 1;
    80004e5e:	4785                	li	a5,1
    80004e60:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e62:	0001d517          	auipc	a0,0x1d
    80004e66:	0d650513          	addi	a0,a0,214 # 80021f38 <ftable>
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
}
    80004e72:	8526                	mv	a0,s1
    80004e74:	60e2                	ld	ra,24(sp)
    80004e76:	6442                	ld	s0,16(sp)
    80004e78:	64a2                	ld	s1,8(sp)
    80004e7a:	6105                	addi	sp,sp,32
    80004e7c:	8082                	ret

0000000080004e7e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e7e:	1101                	addi	sp,sp,-32
    80004e80:	ec06                	sd	ra,24(sp)
    80004e82:	e822                	sd	s0,16(sp)
    80004e84:	e426                	sd	s1,8(sp)
    80004e86:	1000                	addi	s0,sp,32
    80004e88:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e8a:	0001d517          	auipc	a0,0x1d
    80004e8e:	0ae50513          	addi	a0,a0,174 # 80021f38 <ftable>
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	d52080e7          	jalr	-686(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004e9a:	40dc                	lw	a5,4(s1)
    80004e9c:	02f05263          	blez	a5,80004ec0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ea0:	2785                	addiw	a5,a5,1
    80004ea2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ea4:	0001d517          	auipc	a0,0x1d
    80004ea8:	09450513          	addi	a0,a0,148 # 80021f38 <ftable>
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	dec080e7          	jalr	-532(ra) # 80000c98 <release>
  return f;
}
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	60e2                	ld	ra,24(sp)
    80004eb8:	6442                	ld	s0,16(sp)
    80004eba:	64a2                	ld	s1,8(sp)
    80004ebc:	6105                	addi	sp,sp,32
    80004ebe:	8082                	ret
    panic("filedup");
    80004ec0:	00004517          	auipc	a0,0x4
    80004ec4:	94850513          	addi	a0,a0,-1720 # 80008808 <syscalls+0x258>
    80004ec8:	ffffb097          	auipc	ra,0xffffb
    80004ecc:	676080e7          	jalr	1654(ra) # 8000053e <panic>

0000000080004ed0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ed0:	7139                	addi	sp,sp,-64
    80004ed2:	fc06                	sd	ra,56(sp)
    80004ed4:	f822                	sd	s0,48(sp)
    80004ed6:	f426                	sd	s1,40(sp)
    80004ed8:	f04a                	sd	s2,32(sp)
    80004eda:	ec4e                	sd	s3,24(sp)
    80004edc:	e852                	sd	s4,16(sp)
    80004ede:	e456                	sd	s5,8(sp)
    80004ee0:	0080                	addi	s0,sp,64
    80004ee2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ee4:	0001d517          	auipc	a0,0x1d
    80004ee8:	05450513          	addi	a0,a0,84 # 80021f38 <ftable>
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	cf8080e7          	jalr	-776(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ef4:	40dc                	lw	a5,4(s1)
    80004ef6:	06f05163          	blez	a5,80004f58 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004efa:	37fd                	addiw	a5,a5,-1
    80004efc:	0007871b          	sext.w	a4,a5
    80004f00:	c0dc                	sw	a5,4(s1)
    80004f02:	06e04363          	bgtz	a4,80004f68 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f06:	0004a903          	lw	s2,0(s1)
    80004f0a:	0094ca83          	lbu	s5,9(s1)
    80004f0e:	0104ba03          	ld	s4,16(s1)
    80004f12:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f16:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f1a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f1e:	0001d517          	auipc	a0,0x1d
    80004f22:	01a50513          	addi	a0,a0,26 # 80021f38 <ftable>
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	d72080e7          	jalr	-654(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004f2e:	4785                	li	a5,1
    80004f30:	04f90d63          	beq	s2,a5,80004f8a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f34:	3979                	addiw	s2,s2,-2
    80004f36:	4785                	li	a5,1
    80004f38:	0527e063          	bltu	a5,s2,80004f78 <fileclose+0xa8>
    begin_op();
    80004f3c:	00000097          	auipc	ra,0x0
    80004f40:	ac8080e7          	jalr	-1336(ra) # 80004a04 <begin_op>
    iput(ff.ip);
    80004f44:	854e                	mv	a0,s3
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	2a6080e7          	jalr	678(ra) # 800041ec <iput>
    end_op();
    80004f4e:	00000097          	auipc	ra,0x0
    80004f52:	b36080e7          	jalr	-1226(ra) # 80004a84 <end_op>
    80004f56:	a00d                	j	80004f78 <fileclose+0xa8>
    panic("fileclose");
    80004f58:	00004517          	auipc	a0,0x4
    80004f5c:	8b850513          	addi	a0,a0,-1864 # 80008810 <syscalls+0x260>
    80004f60:	ffffb097          	auipc	ra,0xffffb
    80004f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f68:	0001d517          	auipc	a0,0x1d
    80004f6c:	fd050513          	addi	a0,a0,-48 # 80021f38 <ftable>
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	d28080e7          	jalr	-728(ra) # 80000c98 <release>
  }
}
    80004f78:	70e2                	ld	ra,56(sp)
    80004f7a:	7442                	ld	s0,48(sp)
    80004f7c:	74a2                	ld	s1,40(sp)
    80004f7e:	7902                	ld	s2,32(sp)
    80004f80:	69e2                	ld	s3,24(sp)
    80004f82:	6a42                	ld	s4,16(sp)
    80004f84:	6aa2                	ld	s5,8(sp)
    80004f86:	6121                	addi	sp,sp,64
    80004f88:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f8a:	85d6                	mv	a1,s5
    80004f8c:	8552                	mv	a0,s4
    80004f8e:	00000097          	auipc	ra,0x0
    80004f92:	34c080e7          	jalr	844(ra) # 800052da <pipeclose>
    80004f96:	b7cd                	j	80004f78 <fileclose+0xa8>

0000000080004f98 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f98:	715d                	addi	sp,sp,-80
    80004f9a:	e486                	sd	ra,72(sp)
    80004f9c:	e0a2                	sd	s0,64(sp)
    80004f9e:	fc26                	sd	s1,56(sp)
    80004fa0:	f84a                	sd	s2,48(sp)
    80004fa2:	f44e                	sd	s3,40(sp)
    80004fa4:	0880                	addi	s0,sp,80
    80004fa6:	84aa                	mv	s1,a0
    80004fa8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	f9c080e7          	jalr	-100(ra) # 80001f46 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fb2:	409c                	lw	a5,0(s1)
    80004fb4:	37f9                	addiw	a5,a5,-2
    80004fb6:	4705                	li	a4,1
    80004fb8:	04f76763          	bltu	a4,a5,80005006 <filestat+0x6e>
    80004fbc:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fbe:	6c88                	ld	a0,24(s1)
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	072080e7          	jalr	114(ra) # 80004032 <ilock>
    stati(f->ip, &st);
    80004fc8:	fb840593          	addi	a1,s0,-72
    80004fcc:	6c88                	ld	a0,24(s1)
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	2ee080e7          	jalr	750(ra) # 800042bc <stati>
    iunlock(f->ip);
    80004fd6:	6c88                	ld	a0,24(s1)
    80004fd8:	fffff097          	auipc	ra,0xfffff
    80004fdc:	11c080e7          	jalr	284(ra) # 800040f4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004fe0:	46e1                	li	a3,24
    80004fe2:	fb840613          	addi	a2,s0,-72
    80004fe6:	85ce                	mv	a1,s3
    80004fe8:	05093503          	ld	a0,80(s2)
    80004fec:	ffffc097          	auipc	ra,0xffffc
    80004ff0:	686080e7          	jalr	1670(ra) # 80001672 <copyout>
    80004ff4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ff8:	60a6                	ld	ra,72(sp)
    80004ffa:	6406                	ld	s0,64(sp)
    80004ffc:	74e2                	ld	s1,56(sp)
    80004ffe:	7942                	ld	s2,48(sp)
    80005000:	79a2                	ld	s3,40(sp)
    80005002:	6161                	addi	sp,sp,80
    80005004:	8082                	ret
  return -1;
    80005006:	557d                	li	a0,-1
    80005008:	bfc5                	j	80004ff8 <filestat+0x60>

000000008000500a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000500a:	7179                	addi	sp,sp,-48
    8000500c:	f406                	sd	ra,40(sp)
    8000500e:	f022                	sd	s0,32(sp)
    80005010:	ec26                	sd	s1,24(sp)
    80005012:	e84a                	sd	s2,16(sp)
    80005014:	e44e                	sd	s3,8(sp)
    80005016:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005018:	00854783          	lbu	a5,8(a0)
    8000501c:	c3d5                	beqz	a5,800050c0 <fileread+0xb6>
    8000501e:	84aa                	mv	s1,a0
    80005020:	89ae                	mv	s3,a1
    80005022:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005024:	411c                	lw	a5,0(a0)
    80005026:	4705                	li	a4,1
    80005028:	04e78963          	beq	a5,a4,8000507a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000502c:	470d                	li	a4,3
    8000502e:	04e78d63          	beq	a5,a4,80005088 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005032:	4709                	li	a4,2
    80005034:	06e79e63          	bne	a5,a4,800050b0 <fileread+0xa6>
    ilock(f->ip);
    80005038:	6d08                	ld	a0,24(a0)
    8000503a:	fffff097          	auipc	ra,0xfffff
    8000503e:	ff8080e7          	jalr	-8(ra) # 80004032 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005042:	874a                	mv	a4,s2
    80005044:	5094                	lw	a3,32(s1)
    80005046:	864e                	mv	a2,s3
    80005048:	4585                	li	a1,1
    8000504a:	6c88                	ld	a0,24(s1)
    8000504c:	fffff097          	auipc	ra,0xfffff
    80005050:	29a080e7          	jalr	666(ra) # 800042e6 <readi>
    80005054:	892a                	mv	s2,a0
    80005056:	00a05563          	blez	a0,80005060 <fileread+0x56>
      f->off += r;
    8000505a:	509c                	lw	a5,32(s1)
    8000505c:	9fa9                	addw	a5,a5,a0
    8000505e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005060:	6c88                	ld	a0,24(s1)
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	092080e7          	jalr	146(ra) # 800040f4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000506a:	854a                	mv	a0,s2
    8000506c:	70a2                	ld	ra,40(sp)
    8000506e:	7402                	ld	s0,32(sp)
    80005070:	64e2                	ld	s1,24(sp)
    80005072:	6942                	ld	s2,16(sp)
    80005074:	69a2                	ld	s3,8(sp)
    80005076:	6145                	addi	sp,sp,48
    80005078:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000507a:	6908                	ld	a0,16(a0)
    8000507c:	00000097          	auipc	ra,0x0
    80005080:	3c8080e7          	jalr	968(ra) # 80005444 <piperead>
    80005084:	892a                	mv	s2,a0
    80005086:	b7d5                	j	8000506a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005088:	02451783          	lh	a5,36(a0)
    8000508c:	03079693          	slli	a3,a5,0x30
    80005090:	92c1                	srli	a3,a3,0x30
    80005092:	4725                	li	a4,9
    80005094:	02d76863          	bltu	a4,a3,800050c4 <fileread+0xba>
    80005098:	0792                	slli	a5,a5,0x4
    8000509a:	0001d717          	auipc	a4,0x1d
    8000509e:	dfe70713          	addi	a4,a4,-514 # 80021e98 <devsw>
    800050a2:	97ba                	add	a5,a5,a4
    800050a4:	639c                	ld	a5,0(a5)
    800050a6:	c38d                	beqz	a5,800050c8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050a8:	4505                	li	a0,1
    800050aa:	9782                	jalr	a5
    800050ac:	892a                	mv	s2,a0
    800050ae:	bf75                	j	8000506a <fileread+0x60>
    panic("fileread");
    800050b0:	00003517          	auipc	a0,0x3
    800050b4:	77050513          	addi	a0,a0,1904 # 80008820 <syscalls+0x270>
    800050b8:	ffffb097          	auipc	ra,0xffffb
    800050bc:	486080e7          	jalr	1158(ra) # 8000053e <panic>
    return -1;
    800050c0:	597d                	li	s2,-1
    800050c2:	b765                	j	8000506a <fileread+0x60>
      return -1;
    800050c4:	597d                	li	s2,-1
    800050c6:	b755                	j	8000506a <fileread+0x60>
    800050c8:	597d                	li	s2,-1
    800050ca:	b745                	j	8000506a <fileread+0x60>

00000000800050cc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050cc:	715d                	addi	sp,sp,-80
    800050ce:	e486                	sd	ra,72(sp)
    800050d0:	e0a2                	sd	s0,64(sp)
    800050d2:	fc26                	sd	s1,56(sp)
    800050d4:	f84a                	sd	s2,48(sp)
    800050d6:	f44e                	sd	s3,40(sp)
    800050d8:	f052                	sd	s4,32(sp)
    800050da:	ec56                	sd	s5,24(sp)
    800050dc:	e85a                	sd	s6,16(sp)
    800050de:	e45e                	sd	s7,8(sp)
    800050e0:	e062                	sd	s8,0(sp)
    800050e2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050e4:	00954783          	lbu	a5,9(a0)
    800050e8:	10078663          	beqz	a5,800051f4 <filewrite+0x128>
    800050ec:	892a                	mv	s2,a0
    800050ee:	8aae                	mv	s5,a1
    800050f0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800050f2:	411c                	lw	a5,0(a0)
    800050f4:	4705                	li	a4,1
    800050f6:	02e78263          	beq	a5,a4,8000511a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050fa:	470d                	li	a4,3
    800050fc:	02e78663          	beq	a5,a4,80005128 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005100:	4709                	li	a4,2
    80005102:	0ee79163          	bne	a5,a4,800051e4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005106:	0ac05d63          	blez	a2,800051c0 <filewrite+0xf4>
    int i = 0;
    8000510a:	4981                	li	s3,0
    8000510c:	6b05                	lui	s6,0x1
    8000510e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005112:	6b85                	lui	s7,0x1
    80005114:	c00b8b9b          	addiw	s7,s7,-1024
    80005118:	a861                	j	800051b0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000511a:	6908                	ld	a0,16(a0)
    8000511c:	00000097          	auipc	ra,0x0
    80005120:	22e080e7          	jalr	558(ra) # 8000534a <pipewrite>
    80005124:	8a2a                	mv	s4,a0
    80005126:	a045                	j	800051c6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005128:	02451783          	lh	a5,36(a0)
    8000512c:	03079693          	slli	a3,a5,0x30
    80005130:	92c1                	srli	a3,a3,0x30
    80005132:	4725                	li	a4,9
    80005134:	0cd76263          	bltu	a4,a3,800051f8 <filewrite+0x12c>
    80005138:	0792                	slli	a5,a5,0x4
    8000513a:	0001d717          	auipc	a4,0x1d
    8000513e:	d5e70713          	addi	a4,a4,-674 # 80021e98 <devsw>
    80005142:	97ba                	add	a5,a5,a4
    80005144:	679c                	ld	a5,8(a5)
    80005146:	cbdd                	beqz	a5,800051fc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005148:	4505                	li	a0,1
    8000514a:	9782                	jalr	a5
    8000514c:	8a2a                	mv	s4,a0
    8000514e:	a8a5                	j	800051c6 <filewrite+0xfa>
    80005150:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005154:	00000097          	auipc	ra,0x0
    80005158:	8b0080e7          	jalr	-1872(ra) # 80004a04 <begin_op>
      ilock(f->ip);
    8000515c:	01893503          	ld	a0,24(s2)
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	ed2080e7          	jalr	-302(ra) # 80004032 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005168:	8762                	mv	a4,s8
    8000516a:	02092683          	lw	a3,32(s2)
    8000516e:	01598633          	add	a2,s3,s5
    80005172:	4585                	li	a1,1
    80005174:	01893503          	ld	a0,24(s2)
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	266080e7          	jalr	614(ra) # 800043de <writei>
    80005180:	84aa                	mv	s1,a0
    80005182:	00a05763          	blez	a0,80005190 <filewrite+0xc4>
        f->off += r;
    80005186:	02092783          	lw	a5,32(s2)
    8000518a:	9fa9                	addw	a5,a5,a0
    8000518c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005190:	01893503          	ld	a0,24(s2)
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	f60080e7          	jalr	-160(ra) # 800040f4 <iunlock>
      end_op();
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	8e8080e7          	jalr	-1816(ra) # 80004a84 <end_op>

      if(r != n1){
    800051a4:	009c1f63          	bne	s8,s1,800051c2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051a8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051ac:	0149db63          	bge	s3,s4,800051c2 <filewrite+0xf6>
      int n1 = n - i;
    800051b0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051b4:	84be                	mv	s1,a5
    800051b6:	2781                	sext.w	a5,a5
    800051b8:	f8fb5ce3          	bge	s6,a5,80005150 <filewrite+0x84>
    800051bc:	84de                	mv	s1,s7
    800051be:	bf49                	j	80005150 <filewrite+0x84>
    int i = 0;
    800051c0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051c2:	013a1f63          	bne	s4,s3,800051e0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051c6:	8552                	mv	a0,s4
    800051c8:	60a6                	ld	ra,72(sp)
    800051ca:	6406                	ld	s0,64(sp)
    800051cc:	74e2                	ld	s1,56(sp)
    800051ce:	7942                	ld	s2,48(sp)
    800051d0:	79a2                	ld	s3,40(sp)
    800051d2:	7a02                	ld	s4,32(sp)
    800051d4:	6ae2                	ld	s5,24(sp)
    800051d6:	6b42                	ld	s6,16(sp)
    800051d8:	6ba2                	ld	s7,8(sp)
    800051da:	6c02                	ld	s8,0(sp)
    800051dc:	6161                	addi	sp,sp,80
    800051de:	8082                	ret
    ret = (i == n ? n : -1);
    800051e0:	5a7d                	li	s4,-1
    800051e2:	b7d5                	j	800051c6 <filewrite+0xfa>
    panic("filewrite");
    800051e4:	00003517          	auipc	a0,0x3
    800051e8:	64c50513          	addi	a0,a0,1612 # 80008830 <syscalls+0x280>
    800051ec:	ffffb097          	auipc	ra,0xffffb
    800051f0:	352080e7          	jalr	850(ra) # 8000053e <panic>
    return -1;
    800051f4:	5a7d                	li	s4,-1
    800051f6:	bfc1                	j	800051c6 <filewrite+0xfa>
      return -1;
    800051f8:	5a7d                	li	s4,-1
    800051fa:	b7f1                	j	800051c6 <filewrite+0xfa>
    800051fc:	5a7d                	li	s4,-1
    800051fe:	b7e1                	j	800051c6 <filewrite+0xfa>

0000000080005200 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005200:	7179                	addi	sp,sp,-48
    80005202:	f406                	sd	ra,40(sp)
    80005204:	f022                	sd	s0,32(sp)
    80005206:	ec26                	sd	s1,24(sp)
    80005208:	e84a                	sd	s2,16(sp)
    8000520a:	e44e                	sd	s3,8(sp)
    8000520c:	e052                	sd	s4,0(sp)
    8000520e:	1800                	addi	s0,sp,48
    80005210:	84aa                	mv	s1,a0
    80005212:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005214:	0005b023          	sd	zero,0(a1)
    80005218:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	bf8080e7          	jalr	-1032(ra) # 80004e14 <filealloc>
    80005224:	e088                	sd	a0,0(s1)
    80005226:	c551                	beqz	a0,800052b2 <pipealloc+0xb2>
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	bec080e7          	jalr	-1044(ra) # 80004e14 <filealloc>
    80005230:	00aa3023          	sd	a0,0(s4)
    80005234:	c92d                	beqz	a0,800052a6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	8be080e7          	jalr	-1858(ra) # 80000af4 <kalloc>
    8000523e:	892a                	mv	s2,a0
    80005240:	c125                	beqz	a0,800052a0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005242:	4985                	li	s3,1
    80005244:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005248:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000524c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005250:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005254:	00003597          	auipc	a1,0x3
    80005258:	5ec58593          	addi	a1,a1,1516 # 80008840 <syscalls+0x290>
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	8f8080e7          	jalr	-1800(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005264:	609c                	ld	a5,0(s1)
    80005266:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000526a:	609c                	ld	a5,0(s1)
    8000526c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005270:	609c                	ld	a5,0(s1)
    80005272:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005276:	609c                	ld	a5,0(s1)
    80005278:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000527c:	000a3783          	ld	a5,0(s4)
    80005280:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005284:	000a3783          	ld	a5,0(s4)
    80005288:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000528c:	000a3783          	ld	a5,0(s4)
    80005290:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005294:	000a3783          	ld	a5,0(s4)
    80005298:	0127b823          	sd	s2,16(a5)
  return 0;
    8000529c:	4501                	li	a0,0
    8000529e:	a025                	j	800052c6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052a0:	6088                	ld	a0,0(s1)
    800052a2:	e501                	bnez	a0,800052aa <pipealloc+0xaa>
    800052a4:	a039                	j	800052b2 <pipealloc+0xb2>
    800052a6:	6088                	ld	a0,0(s1)
    800052a8:	c51d                	beqz	a0,800052d6 <pipealloc+0xd6>
    fileclose(*f0);
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	c26080e7          	jalr	-986(ra) # 80004ed0 <fileclose>
  if(*f1)
    800052b2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052b6:	557d                	li	a0,-1
  if(*f1)
    800052b8:	c799                	beqz	a5,800052c6 <pipealloc+0xc6>
    fileclose(*f1);
    800052ba:	853e                	mv	a0,a5
    800052bc:	00000097          	auipc	ra,0x0
    800052c0:	c14080e7          	jalr	-1004(ra) # 80004ed0 <fileclose>
  return -1;
    800052c4:	557d                	li	a0,-1
}
    800052c6:	70a2                	ld	ra,40(sp)
    800052c8:	7402                	ld	s0,32(sp)
    800052ca:	64e2                	ld	s1,24(sp)
    800052cc:	6942                	ld	s2,16(sp)
    800052ce:	69a2                	ld	s3,8(sp)
    800052d0:	6a02                	ld	s4,0(sp)
    800052d2:	6145                	addi	sp,sp,48
    800052d4:	8082                	ret
  return -1;
    800052d6:	557d                	li	a0,-1
    800052d8:	b7fd                	j	800052c6 <pipealloc+0xc6>

00000000800052da <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052da:	1101                	addi	sp,sp,-32
    800052dc:	ec06                	sd	ra,24(sp)
    800052de:	e822                	sd	s0,16(sp)
    800052e0:	e426                	sd	s1,8(sp)
    800052e2:	e04a                	sd	s2,0(sp)
    800052e4:	1000                	addi	s0,sp,32
    800052e6:	84aa                	mv	s1,a0
    800052e8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	8fa080e7          	jalr	-1798(ra) # 80000be4 <acquire>
  if(writable){
    800052f2:	02090d63          	beqz	s2,8000532c <pipeclose+0x52>
    pi->writeopen = 0;
    800052f6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800052fa:	21848513          	addi	a0,s1,536
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	91a080e7          	jalr	-1766(ra) # 80002c18 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005306:	2204b783          	ld	a5,544(s1)
    8000530a:	eb95                	bnez	a5,8000533e <pipeclose+0x64>
    release(&pi->lock);
    8000530c:	8526                	mv	a0,s1
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005316:	8526                	mv	a0,s1
    80005318:	ffffb097          	auipc	ra,0xffffb
    8000531c:	6e0080e7          	jalr	1760(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005320:	60e2                	ld	ra,24(sp)
    80005322:	6442                	ld	s0,16(sp)
    80005324:	64a2                	ld	s1,8(sp)
    80005326:	6902                	ld	s2,0(sp)
    80005328:	6105                	addi	sp,sp,32
    8000532a:	8082                	ret
    pi->readopen = 0;
    8000532c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005330:	21c48513          	addi	a0,s1,540
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	8e4080e7          	jalr	-1820(ra) # 80002c18 <wakeup>
    8000533c:	b7e9                	j	80005306 <pipeclose+0x2c>
    release(&pi->lock);
    8000533e:	8526                	mv	a0,s1
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
}
    80005348:	bfe1                	j	80005320 <pipeclose+0x46>

000000008000534a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000534a:	7159                	addi	sp,sp,-112
    8000534c:	f486                	sd	ra,104(sp)
    8000534e:	f0a2                	sd	s0,96(sp)
    80005350:	eca6                	sd	s1,88(sp)
    80005352:	e8ca                	sd	s2,80(sp)
    80005354:	e4ce                	sd	s3,72(sp)
    80005356:	e0d2                	sd	s4,64(sp)
    80005358:	fc56                	sd	s5,56(sp)
    8000535a:	f85a                	sd	s6,48(sp)
    8000535c:	f45e                	sd	s7,40(sp)
    8000535e:	f062                	sd	s8,32(sp)
    80005360:	ec66                	sd	s9,24(sp)
    80005362:	1880                	addi	s0,sp,112
    80005364:	84aa                	mv	s1,a0
    80005366:	8aae                	mv	s5,a1
    80005368:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000536a:	ffffd097          	auipc	ra,0xffffd
    8000536e:	bdc080e7          	jalr	-1060(ra) # 80001f46 <myproc>
    80005372:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005374:	8526                	mv	a0,s1
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	86e080e7          	jalr	-1938(ra) # 80000be4 <acquire>
  while(i < n){
    8000537e:	0d405163          	blez	s4,80005440 <pipewrite+0xf6>
    80005382:	8ba6                	mv	s7,s1
  int i = 0;
    80005384:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005386:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005388:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000538c:	21c48c13          	addi	s8,s1,540
    80005390:	a08d                	j	800053f2 <pipewrite+0xa8>
      release(&pi->lock);
    80005392:	8526                	mv	a0,s1
    80005394:	ffffc097          	auipc	ra,0xffffc
    80005398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
      return -1;
    8000539c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000539e:	854a                	mv	a0,s2
    800053a0:	70a6                	ld	ra,104(sp)
    800053a2:	7406                	ld	s0,96(sp)
    800053a4:	64e6                	ld	s1,88(sp)
    800053a6:	6946                	ld	s2,80(sp)
    800053a8:	69a6                	ld	s3,72(sp)
    800053aa:	6a06                	ld	s4,64(sp)
    800053ac:	7ae2                	ld	s5,56(sp)
    800053ae:	7b42                	ld	s6,48(sp)
    800053b0:	7ba2                	ld	s7,40(sp)
    800053b2:	7c02                	ld	s8,32(sp)
    800053b4:	6ce2                	ld	s9,24(sp)
    800053b6:	6165                	addi	sp,sp,112
    800053b8:	8082                	ret
      wakeup(&pi->nread);
    800053ba:	8566                	mv	a0,s9
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	85c080e7          	jalr	-1956(ra) # 80002c18 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053c4:	85de                	mv	a1,s7
    800053c6:	8562                	mv	a0,s8
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	226080e7          	jalr	550(ra) # 800025ee <sleep>
    800053d0:	a839                	j	800053ee <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800053d2:	21c4a783          	lw	a5,540(s1)
    800053d6:	0017871b          	addiw	a4,a5,1
    800053da:	20e4ae23          	sw	a4,540(s1)
    800053de:	1ff7f793          	andi	a5,a5,511
    800053e2:	97a6                	add	a5,a5,s1
    800053e4:	f9f44703          	lbu	a4,-97(s0)
    800053e8:	00e78c23          	sb	a4,24(a5)
      i++;
    800053ec:	2905                	addiw	s2,s2,1
  while(i < n){
    800053ee:	03495d63          	bge	s2,s4,80005428 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800053f2:	2204a783          	lw	a5,544(s1)
    800053f6:	dfd1                	beqz	a5,80005392 <pipewrite+0x48>
    800053f8:	0289a783          	lw	a5,40(s3)
    800053fc:	fbd9                	bnez	a5,80005392 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800053fe:	2184a783          	lw	a5,536(s1)
    80005402:	21c4a703          	lw	a4,540(s1)
    80005406:	2007879b          	addiw	a5,a5,512
    8000540a:	faf708e3          	beq	a4,a5,800053ba <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000540e:	4685                	li	a3,1
    80005410:	01590633          	add	a2,s2,s5
    80005414:	f9f40593          	addi	a1,s0,-97
    80005418:	0509b503          	ld	a0,80(s3)
    8000541c:	ffffc097          	auipc	ra,0xffffc
    80005420:	2e2080e7          	jalr	738(ra) # 800016fe <copyin>
    80005424:	fb6517e3          	bne	a0,s6,800053d2 <pipewrite+0x88>
  wakeup(&pi->nread);
    80005428:	21848513          	addi	a0,s1,536
    8000542c:	ffffd097          	auipc	ra,0xffffd
    80005430:	7ec080e7          	jalr	2028(ra) # 80002c18 <wakeup>
  release(&pi->lock);
    80005434:	8526                	mv	a0,s1
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	862080e7          	jalr	-1950(ra) # 80000c98 <release>
  return i;
    8000543e:	b785                	j	8000539e <pipewrite+0x54>
  int i = 0;
    80005440:	4901                	li	s2,0
    80005442:	b7dd                	j	80005428 <pipewrite+0xde>

0000000080005444 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005444:	715d                	addi	sp,sp,-80
    80005446:	e486                	sd	ra,72(sp)
    80005448:	e0a2                	sd	s0,64(sp)
    8000544a:	fc26                	sd	s1,56(sp)
    8000544c:	f84a                	sd	s2,48(sp)
    8000544e:	f44e                	sd	s3,40(sp)
    80005450:	f052                	sd	s4,32(sp)
    80005452:	ec56                	sd	s5,24(sp)
    80005454:	e85a                	sd	s6,16(sp)
    80005456:	0880                	addi	s0,sp,80
    80005458:	84aa                	mv	s1,a0
    8000545a:	892e                	mv	s2,a1
    8000545c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000545e:	ffffd097          	auipc	ra,0xffffd
    80005462:	ae8080e7          	jalr	-1304(ra) # 80001f46 <myproc>
    80005466:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005468:	8b26                	mv	s6,s1
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffb097          	auipc	ra,0xffffb
    80005470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005474:	2184a703          	lw	a4,536(s1)
    80005478:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000547c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005480:	02f71463          	bne	a4,a5,800054a8 <piperead+0x64>
    80005484:	2244a783          	lw	a5,548(s1)
    80005488:	c385                	beqz	a5,800054a8 <piperead+0x64>
    if(pr->killed){
    8000548a:	028a2783          	lw	a5,40(s4)
    8000548e:	ebc1                	bnez	a5,8000551e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005490:	85da                	mv	a1,s6
    80005492:	854e                	mv	a0,s3
    80005494:	ffffd097          	auipc	ra,0xffffd
    80005498:	15a080e7          	jalr	346(ra) # 800025ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000549c:	2184a703          	lw	a4,536(s1)
    800054a0:	21c4a783          	lw	a5,540(s1)
    800054a4:	fef700e3          	beq	a4,a5,80005484 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054a8:	09505263          	blez	s5,8000552c <piperead+0xe8>
    800054ac:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054ae:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800054b0:	2184a783          	lw	a5,536(s1)
    800054b4:	21c4a703          	lw	a4,540(s1)
    800054b8:	02f70d63          	beq	a4,a5,800054f2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054bc:	0017871b          	addiw	a4,a5,1
    800054c0:	20e4ac23          	sw	a4,536(s1)
    800054c4:	1ff7f793          	andi	a5,a5,511
    800054c8:	97a6                	add	a5,a5,s1
    800054ca:	0187c783          	lbu	a5,24(a5)
    800054ce:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054d2:	4685                	li	a3,1
    800054d4:	fbf40613          	addi	a2,s0,-65
    800054d8:	85ca                	mv	a1,s2
    800054da:	050a3503          	ld	a0,80(s4)
    800054de:	ffffc097          	auipc	ra,0xffffc
    800054e2:	194080e7          	jalr	404(ra) # 80001672 <copyout>
    800054e6:	01650663          	beq	a0,s6,800054f2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054ea:	2985                	addiw	s3,s3,1
    800054ec:	0905                	addi	s2,s2,1
    800054ee:	fd3a91e3          	bne	s5,s3,800054b0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800054f2:	21c48513          	addi	a0,s1,540
    800054f6:	ffffd097          	auipc	ra,0xffffd
    800054fa:	722080e7          	jalr	1826(ra) # 80002c18 <wakeup>
  release(&pi->lock);
    800054fe:	8526                	mv	a0,s1
    80005500:	ffffb097          	auipc	ra,0xffffb
    80005504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
  return i;
}
    80005508:	854e                	mv	a0,s3
    8000550a:	60a6                	ld	ra,72(sp)
    8000550c:	6406                	ld	s0,64(sp)
    8000550e:	74e2                	ld	s1,56(sp)
    80005510:	7942                	ld	s2,48(sp)
    80005512:	79a2                	ld	s3,40(sp)
    80005514:	7a02                	ld	s4,32(sp)
    80005516:	6ae2                	ld	s5,24(sp)
    80005518:	6b42                	ld	s6,16(sp)
    8000551a:	6161                	addi	sp,sp,80
    8000551c:	8082                	ret
      release(&pi->lock);
    8000551e:	8526                	mv	a0,s1
    80005520:	ffffb097          	auipc	ra,0xffffb
    80005524:	778080e7          	jalr	1912(ra) # 80000c98 <release>
      return -1;
    80005528:	59fd                	li	s3,-1
    8000552a:	bff9                	j	80005508 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000552c:	4981                	li	s3,0
    8000552e:	b7d1                	j	800054f2 <piperead+0xae>

0000000080005530 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005530:	df010113          	addi	sp,sp,-528
    80005534:	20113423          	sd	ra,520(sp)
    80005538:	20813023          	sd	s0,512(sp)
    8000553c:	ffa6                	sd	s1,504(sp)
    8000553e:	fbca                	sd	s2,496(sp)
    80005540:	f7ce                	sd	s3,488(sp)
    80005542:	f3d2                	sd	s4,480(sp)
    80005544:	efd6                	sd	s5,472(sp)
    80005546:	ebda                	sd	s6,464(sp)
    80005548:	e7de                	sd	s7,456(sp)
    8000554a:	e3e2                	sd	s8,448(sp)
    8000554c:	ff66                	sd	s9,440(sp)
    8000554e:	fb6a                	sd	s10,432(sp)
    80005550:	f76e                	sd	s11,424(sp)
    80005552:	0c00                	addi	s0,sp,528
    80005554:	84aa                	mv	s1,a0
    80005556:	dea43c23          	sd	a0,-520(s0)
    8000555a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	9e8080e7          	jalr	-1560(ra) # 80001f46 <myproc>
    80005566:	892a                	mv	s2,a0

  begin_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	49c080e7          	jalr	1180(ra) # 80004a04 <begin_op>

  if((ip = namei(path)) == 0){
    80005570:	8526                	mv	a0,s1
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	276080e7          	jalr	630(ra) # 800047e8 <namei>
    8000557a:	c92d                	beqz	a0,800055ec <exec+0xbc>
    8000557c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	ab4080e7          	jalr	-1356(ra) # 80004032 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005586:	04000713          	li	a4,64
    8000558a:	4681                	li	a3,0
    8000558c:	e5040613          	addi	a2,s0,-432
    80005590:	4581                	li	a1,0
    80005592:	8526                	mv	a0,s1
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	d52080e7          	jalr	-686(ra) # 800042e6 <readi>
    8000559c:	04000793          	li	a5,64
    800055a0:	00f51a63          	bne	a0,a5,800055b4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800055a4:	e5042703          	lw	a4,-432(s0)
    800055a8:	464c47b7          	lui	a5,0x464c4
    800055ac:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055b0:	04f70463          	beq	a4,a5,800055f8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	cde080e7          	jalr	-802(ra) # 80004294 <iunlockput>
    end_op();
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	4c6080e7          	jalr	1222(ra) # 80004a84 <end_op>
  }
  return -1;
    800055c6:	557d                	li	a0,-1
}
    800055c8:	20813083          	ld	ra,520(sp)
    800055cc:	20013403          	ld	s0,512(sp)
    800055d0:	74fe                	ld	s1,504(sp)
    800055d2:	795e                	ld	s2,496(sp)
    800055d4:	79be                	ld	s3,488(sp)
    800055d6:	7a1e                	ld	s4,480(sp)
    800055d8:	6afe                	ld	s5,472(sp)
    800055da:	6b5e                	ld	s6,464(sp)
    800055dc:	6bbe                	ld	s7,456(sp)
    800055de:	6c1e                	ld	s8,448(sp)
    800055e0:	7cfa                	ld	s9,440(sp)
    800055e2:	7d5a                	ld	s10,432(sp)
    800055e4:	7dba                	ld	s11,424(sp)
    800055e6:	21010113          	addi	sp,sp,528
    800055ea:	8082                	ret
    end_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	498080e7          	jalr	1176(ra) # 80004a84 <end_op>
    return -1;
    800055f4:	557d                	li	a0,-1
    800055f6:	bfc9                	j	800055c8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800055f8:	854a                	mv	a0,s2
    800055fa:	ffffd097          	auipc	ra,0xffffd
    800055fe:	a0a080e7          	jalr	-1526(ra) # 80002004 <proc_pagetable>
    80005602:	8baa                	mv	s7,a0
    80005604:	d945                	beqz	a0,800055b4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005606:	e7042983          	lw	s3,-400(s0)
    8000560a:	e8845783          	lhu	a5,-376(s0)
    8000560e:	c7ad                	beqz	a5,80005678 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005610:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005612:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005614:	6c85                	lui	s9,0x1
    80005616:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000561a:	def43823          	sd	a5,-528(s0)
    8000561e:	a42d                	j	80005848 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005620:	00003517          	auipc	a0,0x3
    80005624:	22850513          	addi	a0,a0,552 # 80008848 <syscalls+0x298>
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005630:	8756                	mv	a4,s5
    80005632:	012d86bb          	addw	a3,s11,s2
    80005636:	4581                	li	a1,0
    80005638:	8526                	mv	a0,s1
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	cac080e7          	jalr	-852(ra) # 800042e6 <readi>
    80005642:	2501                	sext.w	a0,a0
    80005644:	1aaa9963          	bne	s5,a0,800057f6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005648:	6785                	lui	a5,0x1
    8000564a:	0127893b          	addw	s2,a5,s2
    8000564e:	77fd                	lui	a5,0xfffff
    80005650:	01478a3b          	addw	s4,a5,s4
    80005654:	1f897163          	bgeu	s2,s8,80005836 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005658:	02091593          	slli	a1,s2,0x20
    8000565c:	9181                	srli	a1,a1,0x20
    8000565e:	95ea                	add	a1,a1,s10
    80005660:	855e                	mv	a0,s7
    80005662:	ffffc097          	auipc	ra,0xffffc
    80005666:	a0c080e7          	jalr	-1524(ra) # 8000106e <walkaddr>
    8000566a:	862a                	mv	a2,a0
    if(pa == 0)
    8000566c:	d955                	beqz	a0,80005620 <exec+0xf0>
      n = PGSIZE;
    8000566e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005670:	fd9a70e3          	bgeu	s4,s9,80005630 <exec+0x100>
      n = sz - i;
    80005674:	8ad2                	mv	s5,s4
    80005676:	bf6d                	j	80005630 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005678:	4901                	li	s2,0
  iunlockput(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	c18080e7          	jalr	-1000(ra) # 80004294 <iunlockput>
  end_op();
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	400080e7          	jalr	1024(ra) # 80004a84 <end_op>
  p = myproc();
    8000568c:	ffffd097          	auipc	ra,0xffffd
    80005690:	8ba080e7          	jalr	-1862(ra) # 80001f46 <myproc>
    80005694:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005696:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000569a:	6785                	lui	a5,0x1
    8000569c:	17fd                	addi	a5,a5,-1
    8000569e:	993e                	add	s2,s2,a5
    800056a0:	757d                	lui	a0,0xfffff
    800056a2:	00a977b3          	and	a5,s2,a0
    800056a6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056aa:	6609                	lui	a2,0x2
    800056ac:	963e                	add	a2,a2,a5
    800056ae:	85be                	mv	a1,a5
    800056b0:	855e                	mv	a0,s7
    800056b2:	ffffc097          	auipc	ra,0xffffc
    800056b6:	d70080e7          	jalr	-656(ra) # 80001422 <uvmalloc>
    800056ba:	8b2a                	mv	s6,a0
  ip = 0;
    800056bc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056be:	12050c63          	beqz	a0,800057f6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056c2:	75f9                	lui	a1,0xffffe
    800056c4:	95aa                	add	a1,a1,a0
    800056c6:	855e                	mv	a0,s7
    800056c8:	ffffc097          	auipc	ra,0xffffc
    800056cc:	f78080e7          	jalr	-136(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800056d0:	7c7d                	lui	s8,0xfffff
    800056d2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800056d4:	e0043783          	ld	a5,-512(s0)
    800056d8:	6388                	ld	a0,0(a5)
    800056da:	c535                	beqz	a0,80005746 <exec+0x216>
    800056dc:	e9040993          	addi	s3,s0,-368
    800056e0:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800056e4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800056e6:	ffffb097          	auipc	ra,0xffffb
    800056ea:	77e080e7          	jalr	1918(ra) # 80000e64 <strlen>
    800056ee:	2505                	addiw	a0,a0,1
    800056f0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800056f4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800056f8:	13896363          	bltu	s2,s8,8000581e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800056fc:	e0043d83          	ld	s11,-512(s0)
    80005700:	000dba03          	ld	s4,0(s11)
    80005704:	8552                	mv	a0,s4
    80005706:	ffffb097          	auipc	ra,0xffffb
    8000570a:	75e080e7          	jalr	1886(ra) # 80000e64 <strlen>
    8000570e:	0015069b          	addiw	a3,a0,1
    80005712:	8652                	mv	a2,s4
    80005714:	85ca                	mv	a1,s2
    80005716:	855e                	mv	a0,s7
    80005718:	ffffc097          	auipc	ra,0xffffc
    8000571c:	f5a080e7          	jalr	-166(ra) # 80001672 <copyout>
    80005720:	10054363          	bltz	a0,80005826 <exec+0x2f6>
    ustack[argc] = sp;
    80005724:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005728:	0485                	addi	s1,s1,1
    8000572a:	008d8793          	addi	a5,s11,8
    8000572e:	e0f43023          	sd	a5,-512(s0)
    80005732:	008db503          	ld	a0,8(s11)
    80005736:	c911                	beqz	a0,8000574a <exec+0x21a>
    if(argc >= MAXARG)
    80005738:	09a1                	addi	s3,s3,8
    8000573a:	fb3c96e3          	bne	s9,s3,800056e6 <exec+0x1b6>
  sz = sz1;
    8000573e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005742:	4481                	li	s1,0
    80005744:	a84d                	j	800057f6 <exec+0x2c6>
  sp = sz;
    80005746:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005748:	4481                	li	s1,0
  ustack[argc] = 0;
    8000574a:	00349793          	slli	a5,s1,0x3
    8000574e:	f9040713          	addi	a4,s0,-112
    80005752:	97ba                	add	a5,a5,a4
    80005754:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005758:	00148693          	addi	a3,s1,1
    8000575c:	068e                	slli	a3,a3,0x3
    8000575e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005762:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005766:	01897663          	bgeu	s2,s8,80005772 <exec+0x242>
  sz = sz1;
    8000576a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000576e:	4481                	li	s1,0
    80005770:	a059                	j	800057f6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005772:	e9040613          	addi	a2,s0,-368
    80005776:	85ca                	mv	a1,s2
    80005778:	855e                	mv	a0,s7
    8000577a:	ffffc097          	auipc	ra,0xffffc
    8000577e:	ef8080e7          	jalr	-264(ra) # 80001672 <copyout>
    80005782:	0a054663          	bltz	a0,8000582e <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005786:	058ab783          	ld	a5,88(s5)
    8000578a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000578e:	df843783          	ld	a5,-520(s0)
    80005792:	0007c703          	lbu	a4,0(a5)
    80005796:	cf11                	beqz	a4,800057b2 <exec+0x282>
    80005798:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000579a:	02f00693          	li	a3,47
    8000579e:	a039                	j	800057ac <exec+0x27c>
      last = s+1;
    800057a0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800057a4:	0785                	addi	a5,a5,1
    800057a6:	fff7c703          	lbu	a4,-1(a5)
    800057aa:	c701                	beqz	a4,800057b2 <exec+0x282>
    if(*s == '/')
    800057ac:	fed71ce3          	bne	a4,a3,800057a4 <exec+0x274>
    800057b0:	bfc5                	j	800057a0 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800057b2:	4641                	li	a2,16
    800057b4:	df843583          	ld	a1,-520(s0)
    800057b8:	158a8513          	addi	a0,s5,344
    800057bc:	ffffb097          	auipc	ra,0xffffb
    800057c0:	676080e7          	jalr	1654(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800057c4:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800057c8:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800057cc:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800057d0:	058ab783          	ld	a5,88(s5)
    800057d4:	e6843703          	ld	a4,-408(s0)
    800057d8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057da:	058ab783          	ld	a5,88(s5)
    800057de:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057e2:	85ea                	mv	a1,s10
    800057e4:	ffffd097          	auipc	ra,0xffffd
    800057e8:	8bc080e7          	jalr	-1860(ra) # 800020a0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800057ec:	0004851b          	sext.w	a0,s1
    800057f0:	bbe1                	j	800055c8 <exec+0x98>
    800057f2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800057f6:	e0843583          	ld	a1,-504(s0)
    800057fa:	855e                	mv	a0,s7
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	8a4080e7          	jalr	-1884(ra) # 800020a0 <proc_freepagetable>
  if(ip){
    80005804:	da0498e3          	bnez	s1,800055b4 <exec+0x84>
  return -1;
    80005808:	557d                	li	a0,-1
    8000580a:	bb7d                	j	800055c8 <exec+0x98>
    8000580c:	e1243423          	sd	s2,-504(s0)
    80005810:	b7dd                	j	800057f6 <exec+0x2c6>
    80005812:	e1243423          	sd	s2,-504(s0)
    80005816:	b7c5                	j	800057f6 <exec+0x2c6>
    80005818:	e1243423          	sd	s2,-504(s0)
    8000581c:	bfe9                	j	800057f6 <exec+0x2c6>
  sz = sz1;
    8000581e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005822:	4481                	li	s1,0
    80005824:	bfc9                	j	800057f6 <exec+0x2c6>
  sz = sz1;
    80005826:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000582a:	4481                	li	s1,0
    8000582c:	b7e9                	j	800057f6 <exec+0x2c6>
  sz = sz1;
    8000582e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005832:	4481                	li	s1,0
    80005834:	b7c9                	j	800057f6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005836:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000583a:	2b05                	addiw	s6,s6,1
    8000583c:	0389899b          	addiw	s3,s3,56
    80005840:	e8845783          	lhu	a5,-376(s0)
    80005844:	e2fb5be3          	bge	s6,a5,8000567a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005848:	2981                	sext.w	s3,s3
    8000584a:	03800713          	li	a4,56
    8000584e:	86ce                	mv	a3,s3
    80005850:	e1840613          	addi	a2,s0,-488
    80005854:	4581                	li	a1,0
    80005856:	8526                	mv	a0,s1
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	a8e080e7          	jalr	-1394(ra) # 800042e6 <readi>
    80005860:	03800793          	li	a5,56
    80005864:	f8f517e3          	bne	a0,a5,800057f2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005868:	e1842783          	lw	a5,-488(s0)
    8000586c:	4705                	li	a4,1
    8000586e:	fce796e3          	bne	a5,a4,8000583a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005872:	e4043603          	ld	a2,-448(s0)
    80005876:	e3843783          	ld	a5,-456(s0)
    8000587a:	f8f669e3          	bltu	a2,a5,8000580c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000587e:	e2843783          	ld	a5,-472(s0)
    80005882:	963e                	add	a2,a2,a5
    80005884:	f8f667e3          	bltu	a2,a5,80005812 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005888:	85ca                	mv	a1,s2
    8000588a:	855e                	mv	a0,s7
    8000588c:	ffffc097          	auipc	ra,0xffffc
    80005890:	b96080e7          	jalr	-1130(ra) # 80001422 <uvmalloc>
    80005894:	e0a43423          	sd	a0,-504(s0)
    80005898:	d141                	beqz	a0,80005818 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000589a:	e2843d03          	ld	s10,-472(s0)
    8000589e:	df043783          	ld	a5,-528(s0)
    800058a2:	00fd77b3          	and	a5,s10,a5
    800058a6:	fba1                	bnez	a5,800057f6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058a8:	e2042d83          	lw	s11,-480(s0)
    800058ac:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058b0:	f80c03e3          	beqz	s8,80005836 <exec+0x306>
    800058b4:	8a62                	mv	s4,s8
    800058b6:	4901                	li	s2,0
    800058b8:	b345                	j	80005658 <exec+0x128>

00000000800058ba <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800058ba:	7179                	addi	sp,sp,-48
    800058bc:	f406                	sd	ra,40(sp)
    800058be:	f022                	sd	s0,32(sp)
    800058c0:	ec26                	sd	s1,24(sp)
    800058c2:	e84a                	sd	s2,16(sp)
    800058c4:	1800                	addi	s0,sp,48
    800058c6:	892e                	mv	s2,a1
    800058c8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800058ca:	fdc40593          	addi	a1,s0,-36
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	b76080e7          	jalr	-1162(ra) # 80003444 <argint>
    800058d6:	04054063          	bltz	a0,80005916 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058da:	fdc42703          	lw	a4,-36(s0)
    800058de:	47bd                	li	a5,15
    800058e0:	02e7ed63          	bltu	a5,a4,8000591a <argfd+0x60>
    800058e4:	ffffc097          	auipc	ra,0xffffc
    800058e8:	662080e7          	jalr	1634(ra) # 80001f46 <myproc>
    800058ec:	fdc42703          	lw	a4,-36(s0)
    800058f0:	01a70793          	addi	a5,a4,26
    800058f4:	078e                	slli	a5,a5,0x3
    800058f6:	953e                	add	a0,a0,a5
    800058f8:	611c                	ld	a5,0(a0)
    800058fa:	c395                	beqz	a5,8000591e <argfd+0x64>
    return -1;
  if(pfd)
    800058fc:	00090463          	beqz	s2,80005904 <argfd+0x4a>
    *pfd = fd;
    80005900:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005904:	4501                	li	a0,0
  if(pf)
    80005906:	c091                	beqz	s1,8000590a <argfd+0x50>
    *pf = f;
    80005908:	e09c                	sd	a5,0(s1)
}
    8000590a:	70a2                	ld	ra,40(sp)
    8000590c:	7402                	ld	s0,32(sp)
    8000590e:	64e2                	ld	s1,24(sp)
    80005910:	6942                	ld	s2,16(sp)
    80005912:	6145                	addi	sp,sp,48
    80005914:	8082                	ret
    return -1;
    80005916:	557d                	li	a0,-1
    80005918:	bfcd                	j	8000590a <argfd+0x50>
    return -1;
    8000591a:	557d                	li	a0,-1
    8000591c:	b7fd                	j	8000590a <argfd+0x50>
    8000591e:	557d                	li	a0,-1
    80005920:	b7ed                	j	8000590a <argfd+0x50>

0000000080005922 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005922:	1101                	addi	sp,sp,-32
    80005924:	ec06                	sd	ra,24(sp)
    80005926:	e822                	sd	s0,16(sp)
    80005928:	e426                	sd	s1,8(sp)
    8000592a:	1000                	addi	s0,sp,32
    8000592c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000592e:	ffffc097          	auipc	ra,0xffffc
    80005932:	618080e7          	jalr	1560(ra) # 80001f46 <myproc>
    80005936:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005938:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000593c:	4501                	li	a0,0
    8000593e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005940:	6398                	ld	a4,0(a5)
    80005942:	cb19                	beqz	a4,80005958 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005944:	2505                	addiw	a0,a0,1
    80005946:	07a1                	addi	a5,a5,8
    80005948:	fed51ce3          	bne	a0,a3,80005940 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000594c:	557d                	li	a0,-1
}
    8000594e:	60e2                	ld	ra,24(sp)
    80005950:	6442                	ld	s0,16(sp)
    80005952:	64a2                	ld	s1,8(sp)
    80005954:	6105                	addi	sp,sp,32
    80005956:	8082                	ret
      p->ofile[fd] = f;
    80005958:	01a50793          	addi	a5,a0,26
    8000595c:	078e                	slli	a5,a5,0x3
    8000595e:	963e                	add	a2,a2,a5
    80005960:	e204                	sd	s1,0(a2)
      return fd;
    80005962:	b7f5                	j	8000594e <fdalloc+0x2c>

0000000080005964 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005964:	715d                	addi	sp,sp,-80
    80005966:	e486                	sd	ra,72(sp)
    80005968:	e0a2                	sd	s0,64(sp)
    8000596a:	fc26                	sd	s1,56(sp)
    8000596c:	f84a                	sd	s2,48(sp)
    8000596e:	f44e                	sd	s3,40(sp)
    80005970:	f052                	sd	s4,32(sp)
    80005972:	ec56                	sd	s5,24(sp)
    80005974:	0880                	addi	s0,sp,80
    80005976:	89ae                	mv	s3,a1
    80005978:	8ab2                	mv	s5,a2
    8000597a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000597c:	fb040593          	addi	a1,s0,-80
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	e86080e7          	jalr	-378(ra) # 80004806 <nameiparent>
    80005988:	892a                	mv	s2,a0
    8000598a:	12050f63          	beqz	a0,80005ac8 <create+0x164>
    return 0;

  ilock(dp);
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	6a4080e7          	jalr	1700(ra) # 80004032 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005996:	4601                	li	a2,0
    80005998:	fb040593          	addi	a1,s0,-80
    8000599c:	854a                	mv	a0,s2
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	b78080e7          	jalr	-1160(ra) # 80004516 <dirlookup>
    800059a6:	84aa                	mv	s1,a0
    800059a8:	c921                	beqz	a0,800059f8 <create+0x94>
    iunlockput(dp);
    800059aa:	854a                	mv	a0,s2
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	8e8080e7          	jalr	-1816(ra) # 80004294 <iunlockput>
    ilock(ip);
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	67c080e7          	jalr	1660(ra) # 80004032 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059be:	2981                	sext.w	s3,s3
    800059c0:	4789                	li	a5,2
    800059c2:	02f99463          	bne	s3,a5,800059ea <create+0x86>
    800059c6:	0444d783          	lhu	a5,68(s1)
    800059ca:	37f9                	addiw	a5,a5,-2
    800059cc:	17c2                	slli	a5,a5,0x30
    800059ce:	93c1                	srli	a5,a5,0x30
    800059d0:	4705                	li	a4,1
    800059d2:	00f76c63          	bltu	a4,a5,800059ea <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800059d6:	8526                	mv	a0,s1
    800059d8:	60a6                	ld	ra,72(sp)
    800059da:	6406                	ld	s0,64(sp)
    800059dc:	74e2                	ld	s1,56(sp)
    800059de:	7942                	ld	s2,48(sp)
    800059e0:	79a2                	ld	s3,40(sp)
    800059e2:	7a02                	ld	s4,32(sp)
    800059e4:	6ae2                	ld	s5,24(sp)
    800059e6:	6161                	addi	sp,sp,80
    800059e8:	8082                	ret
    iunlockput(ip);
    800059ea:	8526                	mv	a0,s1
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8a8080e7          	jalr	-1880(ra) # 80004294 <iunlockput>
    return 0;
    800059f4:	4481                	li	s1,0
    800059f6:	b7c5                	j	800059d6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800059f8:	85ce                	mv	a1,s3
    800059fa:	00092503          	lw	a0,0(s2)
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	49c080e7          	jalr	1180(ra) # 80003e9a <ialloc>
    80005a06:	84aa                	mv	s1,a0
    80005a08:	c529                	beqz	a0,80005a52 <create+0xee>
  ilock(ip);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	628080e7          	jalr	1576(ra) # 80004032 <ilock>
  ip->major = major;
    80005a12:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005a16:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005a1a:	4785                	li	a5,1
    80005a1c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	546080e7          	jalr	1350(ra) # 80003f68 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a2a:	2981                	sext.w	s3,s3
    80005a2c:	4785                	li	a5,1
    80005a2e:	02f98a63          	beq	s3,a5,80005a62 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a32:	40d0                	lw	a2,4(s1)
    80005a34:	fb040593          	addi	a1,s0,-80
    80005a38:	854a                	mv	a0,s2
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	cec080e7          	jalr	-788(ra) # 80004726 <dirlink>
    80005a42:	06054b63          	bltz	a0,80005ab8 <create+0x154>
  iunlockput(dp);
    80005a46:	854a                	mv	a0,s2
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	84c080e7          	jalr	-1972(ra) # 80004294 <iunlockput>
  return ip;
    80005a50:	b759                	j	800059d6 <create+0x72>
    panic("create: ialloc");
    80005a52:	00003517          	auipc	a0,0x3
    80005a56:	e1650513          	addi	a0,a0,-490 # 80008868 <syscalls+0x2b8>
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005a62:	04a95783          	lhu	a5,74(s2)
    80005a66:	2785                	addiw	a5,a5,1
    80005a68:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a6c:	854a                	mv	a0,s2
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	4fa080e7          	jalr	1274(ra) # 80003f68 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a76:	40d0                	lw	a2,4(s1)
    80005a78:	00003597          	auipc	a1,0x3
    80005a7c:	e0058593          	addi	a1,a1,-512 # 80008878 <syscalls+0x2c8>
    80005a80:	8526                	mv	a0,s1
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	ca4080e7          	jalr	-860(ra) # 80004726 <dirlink>
    80005a8a:	00054f63          	bltz	a0,80005aa8 <create+0x144>
    80005a8e:	00492603          	lw	a2,4(s2)
    80005a92:	00003597          	auipc	a1,0x3
    80005a96:	dee58593          	addi	a1,a1,-530 # 80008880 <syscalls+0x2d0>
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	c8a080e7          	jalr	-886(ra) # 80004726 <dirlink>
    80005aa4:	f80557e3          	bgez	a0,80005a32 <create+0xce>
      panic("create dots");
    80005aa8:	00003517          	auipc	a0,0x3
    80005aac:	de050513          	addi	a0,a0,-544 # 80008888 <syscalls+0x2d8>
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	a8e080e7          	jalr	-1394(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005ab8:	00003517          	auipc	a0,0x3
    80005abc:	de050513          	addi	a0,a0,-544 # 80008898 <syscalls+0x2e8>
    80005ac0:	ffffb097          	auipc	ra,0xffffb
    80005ac4:	a7e080e7          	jalr	-1410(ra) # 8000053e <panic>
    return 0;
    80005ac8:	84aa                	mv	s1,a0
    80005aca:	b731                	j	800059d6 <create+0x72>

0000000080005acc <sys_dup>:
{
    80005acc:	7179                	addi	sp,sp,-48
    80005ace:	f406                	sd	ra,40(sp)
    80005ad0:	f022                	sd	s0,32(sp)
    80005ad2:	ec26                	sd	s1,24(sp)
    80005ad4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005ad6:	fd840613          	addi	a2,s0,-40
    80005ada:	4581                	li	a1,0
    80005adc:	4501                	li	a0,0
    80005ade:	00000097          	auipc	ra,0x0
    80005ae2:	ddc080e7          	jalr	-548(ra) # 800058ba <argfd>
    return -1;
    80005ae6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005ae8:	02054363          	bltz	a0,80005b0e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005aec:	fd843503          	ld	a0,-40(s0)
    80005af0:	00000097          	auipc	ra,0x0
    80005af4:	e32080e7          	jalr	-462(ra) # 80005922 <fdalloc>
    80005af8:	84aa                	mv	s1,a0
    return -1;
    80005afa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005afc:	00054963          	bltz	a0,80005b0e <sys_dup+0x42>
  filedup(f);
    80005b00:	fd843503          	ld	a0,-40(s0)
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	37a080e7          	jalr	890(ra) # 80004e7e <filedup>
  return fd;
    80005b0c:	87a6                	mv	a5,s1
}
    80005b0e:	853e                	mv	a0,a5
    80005b10:	70a2                	ld	ra,40(sp)
    80005b12:	7402                	ld	s0,32(sp)
    80005b14:	64e2                	ld	s1,24(sp)
    80005b16:	6145                	addi	sp,sp,48
    80005b18:	8082                	ret

0000000080005b1a <sys_read>:
{
    80005b1a:	7179                	addi	sp,sp,-48
    80005b1c:	f406                	sd	ra,40(sp)
    80005b1e:	f022                	sd	s0,32(sp)
    80005b20:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b22:	fe840613          	addi	a2,s0,-24
    80005b26:	4581                	li	a1,0
    80005b28:	4501                	li	a0,0
    80005b2a:	00000097          	auipc	ra,0x0
    80005b2e:	d90080e7          	jalr	-624(ra) # 800058ba <argfd>
    return -1;
    80005b32:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b34:	04054163          	bltz	a0,80005b76 <sys_read+0x5c>
    80005b38:	fe440593          	addi	a1,s0,-28
    80005b3c:	4509                	li	a0,2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	906080e7          	jalr	-1786(ra) # 80003444 <argint>
    return -1;
    80005b46:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b48:	02054763          	bltz	a0,80005b76 <sys_read+0x5c>
    80005b4c:	fd840593          	addi	a1,s0,-40
    80005b50:	4505                	li	a0,1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	914080e7          	jalr	-1772(ra) # 80003466 <argaddr>
    return -1;
    80005b5a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b5c:	00054d63          	bltz	a0,80005b76 <sys_read+0x5c>
  return fileread(f, p, n);
    80005b60:	fe442603          	lw	a2,-28(s0)
    80005b64:	fd843583          	ld	a1,-40(s0)
    80005b68:	fe843503          	ld	a0,-24(s0)
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	49e080e7          	jalr	1182(ra) # 8000500a <fileread>
    80005b74:	87aa                	mv	a5,a0
}
    80005b76:	853e                	mv	a0,a5
    80005b78:	70a2                	ld	ra,40(sp)
    80005b7a:	7402                	ld	s0,32(sp)
    80005b7c:	6145                	addi	sp,sp,48
    80005b7e:	8082                	ret

0000000080005b80 <sys_write>:
{
    80005b80:	7179                	addi	sp,sp,-48
    80005b82:	f406                	sd	ra,40(sp)
    80005b84:	f022                	sd	s0,32(sp)
    80005b86:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b88:	fe840613          	addi	a2,s0,-24
    80005b8c:	4581                	li	a1,0
    80005b8e:	4501                	li	a0,0
    80005b90:	00000097          	auipc	ra,0x0
    80005b94:	d2a080e7          	jalr	-726(ra) # 800058ba <argfd>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b9a:	04054163          	bltz	a0,80005bdc <sys_write+0x5c>
    80005b9e:	fe440593          	addi	a1,s0,-28
    80005ba2:	4509                	li	a0,2
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	8a0080e7          	jalr	-1888(ra) # 80003444 <argint>
    return -1;
    80005bac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bae:	02054763          	bltz	a0,80005bdc <sys_write+0x5c>
    80005bb2:	fd840593          	addi	a1,s0,-40
    80005bb6:	4505                	li	a0,1
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	8ae080e7          	jalr	-1874(ra) # 80003466 <argaddr>
    return -1;
    80005bc0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc2:	00054d63          	bltz	a0,80005bdc <sys_write+0x5c>
  return filewrite(f, p, n);
    80005bc6:	fe442603          	lw	a2,-28(s0)
    80005bca:	fd843583          	ld	a1,-40(s0)
    80005bce:	fe843503          	ld	a0,-24(s0)
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	4fa080e7          	jalr	1274(ra) # 800050cc <filewrite>
    80005bda:	87aa                	mv	a5,a0
}
    80005bdc:	853e                	mv	a0,a5
    80005bde:	70a2                	ld	ra,40(sp)
    80005be0:	7402                	ld	s0,32(sp)
    80005be2:	6145                	addi	sp,sp,48
    80005be4:	8082                	ret

0000000080005be6 <sys_close>:
{
    80005be6:	1101                	addi	sp,sp,-32
    80005be8:	ec06                	sd	ra,24(sp)
    80005bea:	e822                	sd	s0,16(sp)
    80005bec:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005bee:	fe040613          	addi	a2,s0,-32
    80005bf2:	fec40593          	addi	a1,s0,-20
    80005bf6:	4501                	li	a0,0
    80005bf8:	00000097          	auipc	ra,0x0
    80005bfc:	cc2080e7          	jalr	-830(ra) # 800058ba <argfd>
    return -1;
    80005c00:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c02:	02054463          	bltz	a0,80005c2a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c06:	ffffc097          	auipc	ra,0xffffc
    80005c0a:	340080e7          	jalr	832(ra) # 80001f46 <myproc>
    80005c0e:	fec42783          	lw	a5,-20(s0)
    80005c12:	07e9                	addi	a5,a5,26
    80005c14:	078e                	slli	a5,a5,0x3
    80005c16:	97aa                	add	a5,a5,a0
    80005c18:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c1c:	fe043503          	ld	a0,-32(s0)
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	2b0080e7          	jalr	688(ra) # 80004ed0 <fileclose>
  return 0;
    80005c28:	4781                	li	a5,0
}
    80005c2a:	853e                	mv	a0,a5
    80005c2c:	60e2                	ld	ra,24(sp)
    80005c2e:	6442                	ld	s0,16(sp)
    80005c30:	6105                	addi	sp,sp,32
    80005c32:	8082                	ret

0000000080005c34 <sys_fstat>:
{
    80005c34:	1101                	addi	sp,sp,-32
    80005c36:	ec06                	sd	ra,24(sp)
    80005c38:	e822                	sd	s0,16(sp)
    80005c3a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c3c:	fe840613          	addi	a2,s0,-24
    80005c40:	4581                	li	a1,0
    80005c42:	4501                	li	a0,0
    80005c44:	00000097          	auipc	ra,0x0
    80005c48:	c76080e7          	jalr	-906(ra) # 800058ba <argfd>
    return -1;
    80005c4c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c4e:	02054563          	bltz	a0,80005c78 <sys_fstat+0x44>
    80005c52:	fe040593          	addi	a1,s0,-32
    80005c56:	4505                	li	a0,1
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	80e080e7          	jalr	-2034(ra) # 80003466 <argaddr>
    return -1;
    80005c60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c62:	00054b63          	bltz	a0,80005c78 <sys_fstat+0x44>
  return filestat(f, st);
    80005c66:	fe043583          	ld	a1,-32(s0)
    80005c6a:	fe843503          	ld	a0,-24(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	32a080e7          	jalr	810(ra) # 80004f98 <filestat>
    80005c76:	87aa                	mv	a5,a0
}
    80005c78:	853e                	mv	a0,a5
    80005c7a:	60e2                	ld	ra,24(sp)
    80005c7c:	6442                	ld	s0,16(sp)
    80005c7e:	6105                	addi	sp,sp,32
    80005c80:	8082                	ret

0000000080005c82 <sys_link>:
{
    80005c82:	7169                	addi	sp,sp,-304
    80005c84:	f606                	sd	ra,296(sp)
    80005c86:	f222                	sd	s0,288(sp)
    80005c88:	ee26                	sd	s1,280(sp)
    80005c8a:	ea4a                	sd	s2,272(sp)
    80005c8c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c8e:	08000613          	li	a2,128
    80005c92:	ed040593          	addi	a1,s0,-304
    80005c96:	4501                	li	a0,0
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	7f0080e7          	jalr	2032(ra) # 80003488 <argstr>
    return -1;
    80005ca0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ca2:	10054e63          	bltz	a0,80005dbe <sys_link+0x13c>
    80005ca6:	08000613          	li	a2,128
    80005caa:	f5040593          	addi	a1,s0,-176
    80005cae:	4505                	li	a0,1
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	7d8080e7          	jalr	2008(ra) # 80003488 <argstr>
    return -1;
    80005cb8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cba:	10054263          	bltz	a0,80005dbe <sys_link+0x13c>
  begin_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	d46080e7          	jalr	-698(ra) # 80004a04 <begin_op>
  if((ip = namei(old)) == 0){
    80005cc6:	ed040513          	addi	a0,s0,-304
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	b1e080e7          	jalr	-1250(ra) # 800047e8 <namei>
    80005cd2:	84aa                	mv	s1,a0
    80005cd4:	c551                	beqz	a0,80005d60 <sys_link+0xde>
  ilock(ip);
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	35c080e7          	jalr	860(ra) # 80004032 <ilock>
  if(ip->type == T_DIR){
    80005cde:	04449703          	lh	a4,68(s1)
    80005ce2:	4785                	li	a5,1
    80005ce4:	08f70463          	beq	a4,a5,80005d6c <sys_link+0xea>
  ip->nlink++;
    80005ce8:	04a4d783          	lhu	a5,74(s1)
    80005cec:	2785                	addiw	a5,a5,1
    80005cee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cf2:	8526                	mv	a0,s1
    80005cf4:	ffffe097          	auipc	ra,0xffffe
    80005cf8:	274080e7          	jalr	628(ra) # 80003f68 <iupdate>
  iunlock(ip);
    80005cfc:	8526                	mv	a0,s1
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	3f6080e7          	jalr	1014(ra) # 800040f4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d06:	fd040593          	addi	a1,s0,-48
    80005d0a:	f5040513          	addi	a0,s0,-176
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	af8080e7          	jalr	-1288(ra) # 80004806 <nameiparent>
    80005d16:	892a                	mv	s2,a0
    80005d18:	c935                	beqz	a0,80005d8c <sys_link+0x10a>
  ilock(dp);
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	318080e7          	jalr	792(ra) # 80004032 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d22:	00092703          	lw	a4,0(s2)
    80005d26:	409c                	lw	a5,0(s1)
    80005d28:	04f71d63          	bne	a4,a5,80005d82 <sys_link+0x100>
    80005d2c:	40d0                	lw	a2,4(s1)
    80005d2e:	fd040593          	addi	a1,s0,-48
    80005d32:	854a                	mv	a0,s2
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	9f2080e7          	jalr	-1550(ra) # 80004726 <dirlink>
    80005d3c:	04054363          	bltz	a0,80005d82 <sys_link+0x100>
  iunlockput(dp);
    80005d40:	854a                	mv	a0,s2
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	552080e7          	jalr	1362(ra) # 80004294 <iunlockput>
  iput(ip);
    80005d4a:	8526                	mv	a0,s1
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	4a0080e7          	jalr	1184(ra) # 800041ec <iput>
  end_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	d30080e7          	jalr	-720(ra) # 80004a84 <end_op>
  return 0;
    80005d5c:	4781                	li	a5,0
    80005d5e:	a085                	j	80005dbe <sys_link+0x13c>
    end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	d24080e7          	jalr	-732(ra) # 80004a84 <end_op>
    return -1;
    80005d68:	57fd                	li	a5,-1
    80005d6a:	a891                	j	80005dbe <sys_link+0x13c>
    iunlockput(ip);
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	526080e7          	jalr	1318(ra) # 80004294 <iunlockput>
    end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	d0e080e7          	jalr	-754(ra) # 80004a84 <end_op>
    return -1;
    80005d7e:	57fd                	li	a5,-1
    80005d80:	a83d                	j	80005dbe <sys_link+0x13c>
    iunlockput(dp);
    80005d82:	854a                	mv	a0,s2
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	510080e7          	jalr	1296(ra) # 80004294 <iunlockput>
  ilock(ip);
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	2a4080e7          	jalr	676(ra) # 80004032 <ilock>
  ip->nlink--;
    80005d96:	04a4d783          	lhu	a5,74(s1)
    80005d9a:	37fd                	addiw	a5,a5,-1
    80005d9c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005da0:	8526                	mv	a0,s1
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	1c6080e7          	jalr	454(ra) # 80003f68 <iupdate>
  iunlockput(ip);
    80005daa:	8526                	mv	a0,s1
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	4e8080e7          	jalr	1256(ra) # 80004294 <iunlockput>
  end_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	cd0080e7          	jalr	-816(ra) # 80004a84 <end_op>
  return -1;
    80005dbc:	57fd                	li	a5,-1
}
    80005dbe:	853e                	mv	a0,a5
    80005dc0:	70b2                	ld	ra,296(sp)
    80005dc2:	7412                	ld	s0,288(sp)
    80005dc4:	64f2                	ld	s1,280(sp)
    80005dc6:	6952                	ld	s2,272(sp)
    80005dc8:	6155                	addi	sp,sp,304
    80005dca:	8082                	ret

0000000080005dcc <sys_unlink>:
{
    80005dcc:	7151                	addi	sp,sp,-240
    80005dce:	f586                	sd	ra,232(sp)
    80005dd0:	f1a2                	sd	s0,224(sp)
    80005dd2:	eda6                	sd	s1,216(sp)
    80005dd4:	e9ca                	sd	s2,208(sp)
    80005dd6:	e5ce                	sd	s3,200(sp)
    80005dd8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005dda:	08000613          	li	a2,128
    80005dde:	f3040593          	addi	a1,s0,-208
    80005de2:	4501                	li	a0,0
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	6a4080e7          	jalr	1700(ra) # 80003488 <argstr>
    80005dec:	18054163          	bltz	a0,80005f6e <sys_unlink+0x1a2>
  begin_op();
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	c14080e7          	jalr	-1004(ra) # 80004a04 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005df8:	fb040593          	addi	a1,s0,-80
    80005dfc:	f3040513          	addi	a0,s0,-208
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	a06080e7          	jalr	-1530(ra) # 80004806 <nameiparent>
    80005e08:	84aa                	mv	s1,a0
    80005e0a:	c979                	beqz	a0,80005ee0 <sys_unlink+0x114>
  ilock(dp);
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	226080e7          	jalr	550(ra) # 80004032 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e14:	00003597          	auipc	a1,0x3
    80005e18:	a6458593          	addi	a1,a1,-1436 # 80008878 <syscalls+0x2c8>
    80005e1c:	fb040513          	addi	a0,s0,-80
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	6dc080e7          	jalr	1756(ra) # 800044fc <namecmp>
    80005e28:	14050a63          	beqz	a0,80005f7c <sys_unlink+0x1b0>
    80005e2c:	00003597          	auipc	a1,0x3
    80005e30:	a5458593          	addi	a1,a1,-1452 # 80008880 <syscalls+0x2d0>
    80005e34:	fb040513          	addi	a0,s0,-80
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	6c4080e7          	jalr	1732(ra) # 800044fc <namecmp>
    80005e40:	12050e63          	beqz	a0,80005f7c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e44:	f2c40613          	addi	a2,s0,-212
    80005e48:	fb040593          	addi	a1,s0,-80
    80005e4c:	8526                	mv	a0,s1
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	6c8080e7          	jalr	1736(ra) # 80004516 <dirlookup>
    80005e56:	892a                	mv	s2,a0
    80005e58:	12050263          	beqz	a0,80005f7c <sys_unlink+0x1b0>
  ilock(ip);
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	1d6080e7          	jalr	470(ra) # 80004032 <ilock>
  if(ip->nlink < 1)
    80005e64:	04a91783          	lh	a5,74(s2)
    80005e68:	08f05263          	blez	a5,80005eec <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e6c:	04491703          	lh	a4,68(s2)
    80005e70:	4785                	li	a5,1
    80005e72:	08f70563          	beq	a4,a5,80005efc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e76:	4641                	li	a2,16
    80005e78:	4581                	li	a1,0
    80005e7a:	fc040513          	addi	a0,s0,-64
    80005e7e:	ffffb097          	auipc	ra,0xffffb
    80005e82:	e62080e7          	jalr	-414(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e86:	4741                	li	a4,16
    80005e88:	f2c42683          	lw	a3,-212(s0)
    80005e8c:	fc040613          	addi	a2,s0,-64
    80005e90:	4581                	li	a1,0
    80005e92:	8526                	mv	a0,s1
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	54a080e7          	jalr	1354(ra) # 800043de <writei>
    80005e9c:	47c1                	li	a5,16
    80005e9e:	0af51563          	bne	a0,a5,80005f48 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ea2:	04491703          	lh	a4,68(s2)
    80005ea6:	4785                	li	a5,1
    80005ea8:	0af70863          	beq	a4,a5,80005f58 <sys_unlink+0x18c>
  iunlockput(dp);
    80005eac:	8526                	mv	a0,s1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	3e6080e7          	jalr	998(ra) # 80004294 <iunlockput>
  ip->nlink--;
    80005eb6:	04a95783          	lhu	a5,74(s2)
    80005eba:	37fd                	addiw	a5,a5,-1
    80005ebc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ec0:	854a                	mv	a0,s2
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	0a6080e7          	jalr	166(ra) # 80003f68 <iupdate>
  iunlockput(ip);
    80005eca:	854a                	mv	a0,s2
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	3c8080e7          	jalr	968(ra) # 80004294 <iunlockput>
  end_op();
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	bb0080e7          	jalr	-1104(ra) # 80004a84 <end_op>
  return 0;
    80005edc:	4501                	li	a0,0
    80005ede:	a84d                	j	80005f90 <sys_unlink+0x1c4>
    end_op();
    80005ee0:	fffff097          	auipc	ra,0xfffff
    80005ee4:	ba4080e7          	jalr	-1116(ra) # 80004a84 <end_op>
    return -1;
    80005ee8:	557d                	li	a0,-1
    80005eea:	a05d                	j	80005f90 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005eec:	00003517          	auipc	a0,0x3
    80005ef0:	9bc50513          	addi	a0,a0,-1604 # 800088a8 <syscalls+0x2f8>
    80005ef4:	ffffa097          	auipc	ra,0xffffa
    80005ef8:	64a080e7          	jalr	1610(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005efc:	04c92703          	lw	a4,76(s2)
    80005f00:	02000793          	li	a5,32
    80005f04:	f6e7f9e3          	bgeu	a5,a4,80005e76 <sys_unlink+0xaa>
    80005f08:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f0c:	4741                	li	a4,16
    80005f0e:	86ce                	mv	a3,s3
    80005f10:	f1840613          	addi	a2,s0,-232
    80005f14:	4581                	li	a1,0
    80005f16:	854a                	mv	a0,s2
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	3ce080e7          	jalr	974(ra) # 800042e6 <readi>
    80005f20:	47c1                	li	a5,16
    80005f22:	00f51b63          	bne	a0,a5,80005f38 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f26:	f1845783          	lhu	a5,-232(s0)
    80005f2a:	e7a1                	bnez	a5,80005f72 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f2c:	29c1                	addiw	s3,s3,16
    80005f2e:	04c92783          	lw	a5,76(s2)
    80005f32:	fcf9ede3          	bltu	s3,a5,80005f0c <sys_unlink+0x140>
    80005f36:	b781                	j	80005e76 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	98850513          	addi	a0,a0,-1656 # 800088c0 <syscalls+0x310>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	5fe080e7          	jalr	1534(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	99050513          	addi	a0,a0,-1648 # 800088d8 <syscalls+0x328>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5ee080e7          	jalr	1518(ra) # 8000053e <panic>
    dp->nlink--;
    80005f58:	04a4d783          	lhu	a5,74(s1)
    80005f5c:	37fd                	addiw	a5,a5,-1
    80005f5e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f62:	8526                	mv	a0,s1
    80005f64:	ffffe097          	auipc	ra,0xffffe
    80005f68:	004080e7          	jalr	4(ra) # 80003f68 <iupdate>
    80005f6c:	b781                	j	80005eac <sys_unlink+0xe0>
    return -1;
    80005f6e:	557d                	li	a0,-1
    80005f70:	a005                	j	80005f90 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f72:	854a                	mv	a0,s2
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	320080e7          	jalr	800(ra) # 80004294 <iunlockput>
  iunlockput(dp);
    80005f7c:	8526                	mv	a0,s1
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	316080e7          	jalr	790(ra) # 80004294 <iunlockput>
  end_op();
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	afe080e7          	jalr	-1282(ra) # 80004a84 <end_op>
  return -1;
    80005f8e:	557d                	li	a0,-1
}
    80005f90:	70ae                	ld	ra,232(sp)
    80005f92:	740e                	ld	s0,224(sp)
    80005f94:	64ee                	ld	s1,216(sp)
    80005f96:	694e                	ld	s2,208(sp)
    80005f98:	69ae                	ld	s3,200(sp)
    80005f9a:	616d                	addi	sp,sp,240
    80005f9c:	8082                	ret

0000000080005f9e <sys_open>:

uint64
sys_open(void)
{
    80005f9e:	7131                	addi	sp,sp,-192
    80005fa0:	fd06                	sd	ra,184(sp)
    80005fa2:	f922                	sd	s0,176(sp)
    80005fa4:	f526                	sd	s1,168(sp)
    80005fa6:	f14a                	sd	s2,160(sp)
    80005fa8:	ed4e                	sd	s3,152(sp)
    80005faa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fac:	08000613          	li	a2,128
    80005fb0:	f5040593          	addi	a1,s0,-176
    80005fb4:	4501                	li	a0,0
    80005fb6:	ffffd097          	auipc	ra,0xffffd
    80005fba:	4d2080e7          	jalr	1234(ra) # 80003488 <argstr>
    return -1;
    80005fbe:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fc0:	0c054163          	bltz	a0,80006082 <sys_open+0xe4>
    80005fc4:	f4c40593          	addi	a1,s0,-180
    80005fc8:	4505                	li	a0,1
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	47a080e7          	jalr	1146(ra) # 80003444 <argint>
    80005fd2:	0a054863          	bltz	a0,80006082 <sys_open+0xe4>

  begin_op();
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	a2e080e7          	jalr	-1490(ra) # 80004a04 <begin_op>

  if(omode & O_CREATE){
    80005fde:	f4c42783          	lw	a5,-180(s0)
    80005fe2:	2007f793          	andi	a5,a5,512
    80005fe6:	cbdd                	beqz	a5,8000609c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005fe8:	4681                	li	a3,0
    80005fea:	4601                	li	a2,0
    80005fec:	4589                	li	a1,2
    80005fee:	f5040513          	addi	a0,s0,-176
    80005ff2:	00000097          	auipc	ra,0x0
    80005ff6:	972080e7          	jalr	-1678(ra) # 80005964 <create>
    80005ffa:	892a                	mv	s2,a0
    if(ip == 0){
    80005ffc:	c959                	beqz	a0,80006092 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ffe:	04491703          	lh	a4,68(s2)
    80006002:	478d                	li	a5,3
    80006004:	00f71763          	bne	a4,a5,80006012 <sys_open+0x74>
    80006008:	04695703          	lhu	a4,70(s2)
    8000600c:	47a5                	li	a5,9
    8000600e:	0ce7ec63          	bltu	a5,a4,800060e6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	e02080e7          	jalr	-510(ra) # 80004e14 <filealloc>
    8000601a:	89aa                	mv	s3,a0
    8000601c:	10050263          	beqz	a0,80006120 <sys_open+0x182>
    80006020:	00000097          	auipc	ra,0x0
    80006024:	902080e7          	jalr	-1790(ra) # 80005922 <fdalloc>
    80006028:	84aa                	mv	s1,a0
    8000602a:	0e054663          	bltz	a0,80006116 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000602e:	04491703          	lh	a4,68(s2)
    80006032:	478d                	li	a5,3
    80006034:	0cf70463          	beq	a4,a5,800060fc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006038:	4789                	li	a5,2
    8000603a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000603e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006042:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006046:	f4c42783          	lw	a5,-180(s0)
    8000604a:	0017c713          	xori	a4,a5,1
    8000604e:	8b05                	andi	a4,a4,1
    80006050:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006054:	0037f713          	andi	a4,a5,3
    80006058:	00e03733          	snez	a4,a4
    8000605c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006060:	4007f793          	andi	a5,a5,1024
    80006064:	c791                	beqz	a5,80006070 <sys_open+0xd2>
    80006066:	04491703          	lh	a4,68(s2)
    8000606a:	4789                	li	a5,2
    8000606c:	08f70f63          	beq	a4,a5,8000610a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006070:	854a                	mv	a0,s2
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	082080e7          	jalr	130(ra) # 800040f4 <iunlock>
  end_op();
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	a0a080e7          	jalr	-1526(ra) # 80004a84 <end_op>

  return fd;
}
    80006082:	8526                	mv	a0,s1
    80006084:	70ea                	ld	ra,184(sp)
    80006086:	744a                	ld	s0,176(sp)
    80006088:	74aa                	ld	s1,168(sp)
    8000608a:	790a                	ld	s2,160(sp)
    8000608c:	69ea                	ld	s3,152(sp)
    8000608e:	6129                	addi	sp,sp,192
    80006090:	8082                	ret
      end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	9f2080e7          	jalr	-1550(ra) # 80004a84 <end_op>
      return -1;
    8000609a:	b7e5                	j	80006082 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000609c:	f5040513          	addi	a0,s0,-176
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	748080e7          	jalr	1864(ra) # 800047e8 <namei>
    800060a8:	892a                	mv	s2,a0
    800060aa:	c905                	beqz	a0,800060da <sys_open+0x13c>
    ilock(ip);
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	f86080e7          	jalr	-122(ra) # 80004032 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060b4:	04491703          	lh	a4,68(s2)
    800060b8:	4785                	li	a5,1
    800060ba:	f4f712e3          	bne	a4,a5,80005ffe <sys_open+0x60>
    800060be:	f4c42783          	lw	a5,-180(s0)
    800060c2:	dba1                	beqz	a5,80006012 <sys_open+0x74>
      iunlockput(ip);
    800060c4:	854a                	mv	a0,s2
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	1ce080e7          	jalr	462(ra) # 80004294 <iunlockput>
      end_op();
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	9b6080e7          	jalr	-1610(ra) # 80004a84 <end_op>
      return -1;
    800060d6:	54fd                	li	s1,-1
    800060d8:	b76d                	j	80006082 <sys_open+0xe4>
      end_op();
    800060da:	fffff097          	auipc	ra,0xfffff
    800060de:	9aa080e7          	jalr	-1622(ra) # 80004a84 <end_op>
      return -1;
    800060e2:	54fd                	li	s1,-1
    800060e4:	bf79                	j	80006082 <sys_open+0xe4>
    iunlockput(ip);
    800060e6:	854a                	mv	a0,s2
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	1ac080e7          	jalr	428(ra) # 80004294 <iunlockput>
    end_op();
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	994080e7          	jalr	-1644(ra) # 80004a84 <end_op>
    return -1;
    800060f8:	54fd                	li	s1,-1
    800060fa:	b761                	j	80006082 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800060fc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006100:	04691783          	lh	a5,70(s2)
    80006104:	02f99223          	sh	a5,36(s3)
    80006108:	bf2d                	j	80006042 <sys_open+0xa4>
    itrunc(ip);
    8000610a:	854a                	mv	a0,s2
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	034080e7          	jalr	52(ra) # 80004140 <itrunc>
    80006114:	bfb1                	j	80006070 <sys_open+0xd2>
      fileclose(f);
    80006116:	854e                	mv	a0,s3
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	db8080e7          	jalr	-584(ra) # 80004ed0 <fileclose>
    iunlockput(ip);
    80006120:	854a                	mv	a0,s2
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	172080e7          	jalr	370(ra) # 80004294 <iunlockput>
    end_op();
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	95a080e7          	jalr	-1702(ra) # 80004a84 <end_op>
    return -1;
    80006132:	54fd                	li	s1,-1
    80006134:	b7b9                	j	80006082 <sys_open+0xe4>

0000000080006136 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006136:	7175                	addi	sp,sp,-144
    80006138:	e506                	sd	ra,136(sp)
    8000613a:	e122                	sd	s0,128(sp)
    8000613c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000613e:	fffff097          	auipc	ra,0xfffff
    80006142:	8c6080e7          	jalr	-1850(ra) # 80004a04 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006146:	08000613          	li	a2,128
    8000614a:	f7040593          	addi	a1,s0,-144
    8000614e:	4501                	li	a0,0
    80006150:	ffffd097          	auipc	ra,0xffffd
    80006154:	338080e7          	jalr	824(ra) # 80003488 <argstr>
    80006158:	02054963          	bltz	a0,8000618a <sys_mkdir+0x54>
    8000615c:	4681                	li	a3,0
    8000615e:	4601                	li	a2,0
    80006160:	4585                	li	a1,1
    80006162:	f7040513          	addi	a0,s0,-144
    80006166:	fffff097          	auipc	ra,0xfffff
    8000616a:	7fe080e7          	jalr	2046(ra) # 80005964 <create>
    8000616e:	cd11                	beqz	a0,8000618a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	124080e7          	jalr	292(ra) # 80004294 <iunlockput>
  end_op();
    80006178:	fffff097          	auipc	ra,0xfffff
    8000617c:	90c080e7          	jalr	-1780(ra) # 80004a84 <end_op>
  return 0;
    80006180:	4501                	li	a0,0
}
    80006182:	60aa                	ld	ra,136(sp)
    80006184:	640a                	ld	s0,128(sp)
    80006186:	6149                	addi	sp,sp,144
    80006188:	8082                	ret
    end_op();
    8000618a:	fffff097          	auipc	ra,0xfffff
    8000618e:	8fa080e7          	jalr	-1798(ra) # 80004a84 <end_op>
    return -1;
    80006192:	557d                	li	a0,-1
    80006194:	b7fd                	j	80006182 <sys_mkdir+0x4c>

0000000080006196 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006196:	7135                	addi	sp,sp,-160
    80006198:	ed06                	sd	ra,152(sp)
    8000619a:	e922                	sd	s0,144(sp)
    8000619c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000619e:	fffff097          	auipc	ra,0xfffff
    800061a2:	866080e7          	jalr	-1946(ra) # 80004a04 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061a6:	08000613          	li	a2,128
    800061aa:	f7040593          	addi	a1,s0,-144
    800061ae:	4501                	li	a0,0
    800061b0:	ffffd097          	auipc	ra,0xffffd
    800061b4:	2d8080e7          	jalr	728(ra) # 80003488 <argstr>
    800061b8:	04054a63          	bltz	a0,8000620c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800061bc:	f6c40593          	addi	a1,s0,-148
    800061c0:	4505                	li	a0,1
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	282080e7          	jalr	642(ra) # 80003444 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061ca:	04054163          	bltz	a0,8000620c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800061ce:	f6840593          	addi	a1,s0,-152
    800061d2:	4509                	li	a0,2
    800061d4:	ffffd097          	auipc	ra,0xffffd
    800061d8:	270080e7          	jalr	624(ra) # 80003444 <argint>
     argint(1, &major) < 0 ||
    800061dc:	02054863          	bltz	a0,8000620c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061e0:	f6841683          	lh	a3,-152(s0)
    800061e4:	f6c41603          	lh	a2,-148(s0)
    800061e8:	458d                	li	a1,3
    800061ea:	f7040513          	addi	a0,s0,-144
    800061ee:	fffff097          	auipc	ra,0xfffff
    800061f2:	776080e7          	jalr	1910(ra) # 80005964 <create>
     argint(2, &minor) < 0 ||
    800061f6:	c919                	beqz	a0,8000620c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800061f8:	ffffe097          	auipc	ra,0xffffe
    800061fc:	09c080e7          	jalr	156(ra) # 80004294 <iunlockput>
  end_op();
    80006200:	fffff097          	auipc	ra,0xfffff
    80006204:	884080e7          	jalr	-1916(ra) # 80004a84 <end_op>
  return 0;
    80006208:	4501                	li	a0,0
    8000620a:	a031                	j	80006216 <sys_mknod+0x80>
    end_op();
    8000620c:	fffff097          	auipc	ra,0xfffff
    80006210:	878080e7          	jalr	-1928(ra) # 80004a84 <end_op>
    return -1;
    80006214:	557d                	li	a0,-1
}
    80006216:	60ea                	ld	ra,152(sp)
    80006218:	644a                	ld	s0,144(sp)
    8000621a:	610d                	addi	sp,sp,160
    8000621c:	8082                	ret

000000008000621e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000621e:	7135                	addi	sp,sp,-160
    80006220:	ed06                	sd	ra,152(sp)
    80006222:	e922                	sd	s0,144(sp)
    80006224:	e526                	sd	s1,136(sp)
    80006226:	e14a                	sd	s2,128(sp)
    80006228:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000622a:	ffffc097          	auipc	ra,0xffffc
    8000622e:	d1c080e7          	jalr	-740(ra) # 80001f46 <myproc>
    80006232:	892a                	mv	s2,a0
  
  begin_op();
    80006234:	ffffe097          	auipc	ra,0xffffe
    80006238:	7d0080e7          	jalr	2000(ra) # 80004a04 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000623c:	08000613          	li	a2,128
    80006240:	f6040593          	addi	a1,s0,-160
    80006244:	4501                	li	a0,0
    80006246:	ffffd097          	auipc	ra,0xffffd
    8000624a:	242080e7          	jalr	578(ra) # 80003488 <argstr>
    8000624e:	04054b63          	bltz	a0,800062a4 <sys_chdir+0x86>
    80006252:	f6040513          	addi	a0,s0,-160
    80006256:	ffffe097          	auipc	ra,0xffffe
    8000625a:	592080e7          	jalr	1426(ra) # 800047e8 <namei>
    8000625e:	84aa                	mv	s1,a0
    80006260:	c131                	beqz	a0,800062a4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	dd0080e7          	jalr	-560(ra) # 80004032 <ilock>
  if(ip->type != T_DIR){
    8000626a:	04449703          	lh	a4,68(s1)
    8000626e:	4785                	li	a5,1
    80006270:	04f71063          	bne	a4,a5,800062b0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006274:	8526                	mv	a0,s1
    80006276:	ffffe097          	auipc	ra,0xffffe
    8000627a:	e7e080e7          	jalr	-386(ra) # 800040f4 <iunlock>
  iput(p->cwd);
    8000627e:	15093503          	ld	a0,336(s2)
    80006282:	ffffe097          	auipc	ra,0xffffe
    80006286:	f6a080e7          	jalr	-150(ra) # 800041ec <iput>
  end_op();
    8000628a:	ffffe097          	auipc	ra,0xffffe
    8000628e:	7fa080e7          	jalr	2042(ra) # 80004a84 <end_op>
  p->cwd = ip;
    80006292:	14993823          	sd	s1,336(s2)
  return 0;
    80006296:	4501                	li	a0,0
}
    80006298:	60ea                	ld	ra,152(sp)
    8000629a:	644a                	ld	s0,144(sp)
    8000629c:	64aa                	ld	s1,136(sp)
    8000629e:	690a                	ld	s2,128(sp)
    800062a0:	610d                	addi	sp,sp,160
    800062a2:	8082                	ret
    end_op();
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	7e0080e7          	jalr	2016(ra) # 80004a84 <end_op>
    return -1;
    800062ac:	557d                	li	a0,-1
    800062ae:	b7ed                	j	80006298 <sys_chdir+0x7a>
    iunlockput(ip);
    800062b0:	8526                	mv	a0,s1
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	fe2080e7          	jalr	-30(ra) # 80004294 <iunlockput>
    end_op();
    800062ba:	ffffe097          	auipc	ra,0xffffe
    800062be:	7ca080e7          	jalr	1994(ra) # 80004a84 <end_op>
    return -1;
    800062c2:	557d                	li	a0,-1
    800062c4:	bfd1                	j	80006298 <sys_chdir+0x7a>

00000000800062c6 <sys_exec>:

uint64
sys_exec(void)
{
    800062c6:	7145                	addi	sp,sp,-464
    800062c8:	e786                	sd	ra,456(sp)
    800062ca:	e3a2                	sd	s0,448(sp)
    800062cc:	ff26                	sd	s1,440(sp)
    800062ce:	fb4a                	sd	s2,432(sp)
    800062d0:	f74e                	sd	s3,424(sp)
    800062d2:	f352                	sd	s4,416(sp)
    800062d4:	ef56                	sd	s5,408(sp)
    800062d6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800062d8:	08000613          	li	a2,128
    800062dc:	f4040593          	addi	a1,s0,-192
    800062e0:	4501                	li	a0,0
    800062e2:	ffffd097          	auipc	ra,0xffffd
    800062e6:	1a6080e7          	jalr	422(ra) # 80003488 <argstr>
    return -1;
    800062ea:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800062ec:	0c054a63          	bltz	a0,800063c0 <sys_exec+0xfa>
    800062f0:	e3840593          	addi	a1,s0,-456
    800062f4:	4505                	li	a0,1
    800062f6:	ffffd097          	auipc	ra,0xffffd
    800062fa:	170080e7          	jalr	368(ra) # 80003466 <argaddr>
    800062fe:	0c054163          	bltz	a0,800063c0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006302:	10000613          	li	a2,256
    80006306:	4581                	li	a1,0
    80006308:	e4040513          	addi	a0,s0,-448
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	9d4080e7          	jalr	-1580(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006314:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006318:	89a6                	mv	s3,s1
    8000631a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000631c:	02000a13          	li	s4,32
    80006320:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006324:	00391513          	slli	a0,s2,0x3
    80006328:	e3040593          	addi	a1,s0,-464
    8000632c:	e3843783          	ld	a5,-456(s0)
    80006330:	953e                	add	a0,a0,a5
    80006332:	ffffd097          	auipc	ra,0xffffd
    80006336:	078080e7          	jalr	120(ra) # 800033aa <fetchaddr>
    8000633a:	02054a63          	bltz	a0,8000636e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000633e:	e3043783          	ld	a5,-464(s0)
    80006342:	c3b9                	beqz	a5,80006388 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006344:	ffffa097          	auipc	ra,0xffffa
    80006348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000634c:	85aa                	mv	a1,a0
    8000634e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006352:	cd11                	beqz	a0,8000636e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006354:	6605                	lui	a2,0x1
    80006356:	e3043503          	ld	a0,-464(s0)
    8000635a:	ffffd097          	auipc	ra,0xffffd
    8000635e:	0a2080e7          	jalr	162(ra) # 800033fc <fetchstr>
    80006362:	00054663          	bltz	a0,8000636e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006366:	0905                	addi	s2,s2,1
    80006368:	09a1                	addi	s3,s3,8
    8000636a:	fb491be3          	bne	s2,s4,80006320 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000636e:	10048913          	addi	s2,s1,256
    80006372:	6088                	ld	a0,0(s1)
    80006374:	c529                	beqz	a0,800063be <sys_exec+0xf8>
    kfree(argv[i]);
    80006376:	ffffa097          	auipc	ra,0xffffa
    8000637a:	682080e7          	jalr	1666(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000637e:	04a1                	addi	s1,s1,8
    80006380:	ff2499e3          	bne	s1,s2,80006372 <sys_exec+0xac>
  return -1;
    80006384:	597d                	li	s2,-1
    80006386:	a82d                	j	800063c0 <sys_exec+0xfa>
      argv[i] = 0;
    80006388:	0a8e                	slli	s5,s5,0x3
    8000638a:	fc040793          	addi	a5,s0,-64
    8000638e:	9abe                	add	s5,s5,a5
    80006390:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006394:	e4040593          	addi	a1,s0,-448
    80006398:	f4040513          	addi	a0,s0,-192
    8000639c:	fffff097          	auipc	ra,0xfffff
    800063a0:	194080e7          	jalr	404(ra) # 80005530 <exec>
    800063a4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063a6:	10048993          	addi	s3,s1,256
    800063aa:	6088                	ld	a0,0(s1)
    800063ac:	c911                	beqz	a0,800063c0 <sys_exec+0xfa>
    kfree(argv[i]);
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	64a080e7          	jalr	1610(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063b6:	04a1                	addi	s1,s1,8
    800063b8:	ff3499e3          	bne	s1,s3,800063aa <sys_exec+0xe4>
    800063bc:	a011                	j	800063c0 <sys_exec+0xfa>
  return -1;
    800063be:	597d                	li	s2,-1
}
    800063c0:	854a                	mv	a0,s2
    800063c2:	60be                	ld	ra,456(sp)
    800063c4:	641e                	ld	s0,448(sp)
    800063c6:	74fa                	ld	s1,440(sp)
    800063c8:	795a                	ld	s2,432(sp)
    800063ca:	79ba                	ld	s3,424(sp)
    800063cc:	7a1a                	ld	s4,416(sp)
    800063ce:	6afa                	ld	s5,408(sp)
    800063d0:	6179                	addi	sp,sp,464
    800063d2:	8082                	ret

00000000800063d4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063d4:	7139                	addi	sp,sp,-64
    800063d6:	fc06                	sd	ra,56(sp)
    800063d8:	f822                	sd	s0,48(sp)
    800063da:	f426                	sd	s1,40(sp)
    800063dc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063de:	ffffc097          	auipc	ra,0xffffc
    800063e2:	b68080e7          	jalr	-1176(ra) # 80001f46 <myproc>
    800063e6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800063e8:	fd840593          	addi	a1,s0,-40
    800063ec:	4501                	li	a0,0
    800063ee:	ffffd097          	auipc	ra,0xffffd
    800063f2:	078080e7          	jalr	120(ra) # 80003466 <argaddr>
    return -1;
    800063f6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800063f8:	0e054063          	bltz	a0,800064d8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800063fc:	fc840593          	addi	a1,s0,-56
    80006400:	fd040513          	addi	a0,s0,-48
    80006404:	fffff097          	auipc	ra,0xfffff
    80006408:	dfc080e7          	jalr	-516(ra) # 80005200 <pipealloc>
    return -1;
    8000640c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000640e:	0c054563          	bltz	a0,800064d8 <sys_pipe+0x104>
  fd0 = -1;
    80006412:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006416:	fd043503          	ld	a0,-48(s0)
    8000641a:	fffff097          	auipc	ra,0xfffff
    8000641e:	508080e7          	jalr	1288(ra) # 80005922 <fdalloc>
    80006422:	fca42223          	sw	a0,-60(s0)
    80006426:	08054c63          	bltz	a0,800064be <sys_pipe+0xea>
    8000642a:	fc843503          	ld	a0,-56(s0)
    8000642e:	fffff097          	auipc	ra,0xfffff
    80006432:	4f4080e7          	jalr	1268(ra) # 80005922 <fdalloc>
    80006436:	fca42023          	sw	a0,-64(s0)
    8000643a:	06054863          	bltz	a0,800064aa <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000643e:	4691                	li	a3,4
    80006440:	fc440613          	addi	a2,s0,-60
    80006444:	fd843583          	ld	a1,-40(s0)
    80006448:	68a8                	ld	a0,80(s1)
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	228080e7          	jalr	552(ra) # 80001672 <copyout>
    80006452:	02054063          	bltz	a0,80006472 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006456:	4691                	li	a3,4
    80006458:	fc040613          	addi	a2,s0,-64
    8000645c:	fd843583          	ld	a1,-40(s0)
    80006460:	0591                	addi	a1,a1,4
    80006462:	68a8                	ld	a0,80(s1)
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	20e080e7          	jalr	526(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000646c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000646e:	06055563          	bgez	a0,800064d8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006472:	fc442783          	lw	a5,-60(s0)
    80006476:	07e9                	addi	a5,a5,26
    80006478:	078e                	slli	a5,a5,0x3
    8000647a:	97a6                	add	a5,a5,s1
    8000647c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006480:	fc042503          	lw	a0,-64(s0)
    80006484:	0569                	addi	a0,a0,26
    80006486:	050e                	slli	a0,a0,0x3
    80006488:	9526                	add	a0,a0,s1
    8000648a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000648e:	fd043503          	ld	a0,-48(s0)
    80006492:	fffff097          	auipc	ra,0xfffff
    80006496:	a3e080e7          	jalr	-1474(ra) # 80004ed0 <fileclose>
    fileclose(wf);
    8000649a:	fc843503          	ld	a0,-56(s0)
    8000649e:	fffff097          	auipc	ra,0xfffff
    800064a2:	a32080e7          	jalr	-1486(ra) # 80004ed0 <fileclose>
    return -1;
    800064a6:	57fd                	li	a5,-1
    800064a8:	a805                	j	800064d8 <sys_pipe+0x104>
    if(fd0 >= 0)
    800064aa:	fc442783          	lw	a5,-60(s0)
    800064ae:	0007c863          	bltz	a5,800064be <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800064b2:	01a78513          	addi	a0,a5,26
    800064b6:	050e                	slli	a0,a0,0x3
    800064b8:	9526                	add	a0,a0,s1
    800064ba:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800064be:	fd043503          	ld	a0,-48(s0)
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	a0e080e7          	jalr	-1522(ra) # 80004ed0 <fileclose>
    fileclose(wf);
    800064ca:	fc843503          	ld	a0,-56(s0)
    800064ce:	fffff097          	auipc	ra,0xfffff
    800064d2:	a02080e7          	jalr	-1534(ra) # 80004ed0 <fileclose>
    return -1;
    800064d6:	57fd                	li	a5,-1
}
    800064d8:	853e                	mv	a0,a5
    800064da:	70e2                	ld	ra,56(sp)
    800064dc:	7442                	ld	s0,48(sp)
    800064de:	74a2                	ld	s1,40(sp)
    800064e0:	6121                	addi	sp,sp,64
    800064e2:	8082                	ret
	...

00000000800064f0 <kernelvec>:
    800064f0:	7111                	addi	sp,sp,-256
    800064f2:	e006                	sd	ra,0(sp)
    800064f4:	e40a                	sd	sp,8(sp)
    800064f6:	e80e                	sd	gp,16(sp)
    800064f8:	ec12                	sd	tp,24(sp)
    800064fa:	f016                	sd	t0,32(sp)
    800064fc:	f41a                	sd	t1,40(sp)
    800064fe:	f81e                	sd	t2,48(sp)
    80006500:	fc22                	sd	s0,56(sp)
    80006502:	e0a6                	sd	s1,64(sp)
    80006504:	e4aa                	sd	a0,72(sp)
    80006506:	e8ae                	sd	a1,80(sp)
    80006508:	ecb2                	sd	a2,88(sp)
    8000650a:	f0b6                	sd	a3,96(sp)
    8000650c:	f4ba                	sd	a4,104(sp)
    8000650e:	f8be                	sd	a5,112(sp)
    80006510:	fcc2                	sd	a6,120(sp)
    80006512:	e146                	sd	a7,128(sp)
    80006514:	e54a                	sd	s2,136(sp)
    80006516:	e94e                	sd	s3,144(sp)
    80006518:	ed52                	sd	s4,152(sp)
    8000651a:	f156                	sd	s5,160(sp)
    8000651c:	f55a                	sd	s6,168(sp)
    8000651e:	f95e                	sd	s7,176(sp)
    80006520:	fd62                	sd	s8,184(sp)
    80006522:	e1e6                	sd	s9,192(sp)
    80006524:	e5ea                	sd	s10,200(sp)
    80006526:	e9ee                	sd	s11,208(sp)
    80006528:	edf2                	sd	t3,216(sp)
    8000652a:	f1f6                	sd	t4,224(sp)
    8000652c:	f5fa                	sd	t5,232(sp)
    8000652e:	f9fe                	sd	t6,240(sp)
    80006530:	d47fc0ef          	jal	ra,80003276 <kerneltrap>
    80006534:	6082                	ld	ra,0(sp)
    80006536:	6122                	ld	sp,8(sp)
    80006538:	61c2                	ld	gp,16(sp)
    8000653a:	7282                	ld	t0,32(sp)
    8000653c:	7322                	ld	t1,40(sp)
    8000653e:	73c2                	ld	t2,48(sp)
    80006540:	7462                	ld	s0,56(sp)
    80006542:	6486                	ld	s1,64(sp)
    80006544:	6526                	ld	a0,72(sp)
    80006546:	65c6                	ld	a1,80(sp)
    80006548:	6666                	ld	a2,88(sp)
    8000654a:	7686                	ld	a3,96(sp)
    8000654c:	7726                	ld	a4,104(sp)
    8000654e:	77c6                	ld	a5,112(sp)
    80006550:	7866                	ld	a6,120(sp)
    80006552:	688a                	ld	a7,128(sp)
    80006554:	692a                	ld	s2,136(sp)
    80006556:	69ca                	ld	s3,144(sp)
    80006558:	6a6a                	ld	s4,152(sp)
    8000655a:	7a8a                	ld	s5,160(sp)
    8000655c:	7b2a                	ld	s6,168(sp)
    8000655e:	7bca                	ld	s7,176(sp)
    80006560:	7c6a                	ld	s8,184(sp)
    80006562:	6c8e                	ld	s9,192(sp)
    80006564:	6d2e                	ld	s10,200(sp)
    80006566:	6dce                	ld	s11,208(sp)
    80006568:	6e6e                	ld	t3,216(sp)
    8000656a:	7e8e                	ld	t4,224(sp)
    8000656c:	7f2e                	ld	t5,232(sp)
    8000656e:	7fce                	ld	t6,240(sp)
    80006570:	6111                	addi	sp,sp,256
    80006572:	10200073          	sret
    80006576:	00000013          	nop
    8000657a:	00000013          	nop
    8000657e:	0001                	nop

0000000080006580 <timervec>:
    80006580:	34051573          	csrrw	a0,mscratch,a0
    80006584:	e10c                	sd	a1,0(a0)
    80006586:	e510                	sd	a2,8(a0)
    80006588:	e914                	sd	a3,16(a0)
    8000658a:	6d0c                	ld	a1,24(a0)
    8000658c:	7110                	ld	a2,32(a0)
    8000658e:	6194                	ld	a3,0(a1)
    80006590:	96b2                	add	a3,a3,a2
    80006592:	e194                	sd	a3,0(a1)
    80006594:	4589                	li	a1,2
    80006596:	14459073          	csrw	sip,a1
    8000659a:	6914                	ld	a3,16(a0)
    8000659c:	6510                	ld	a2,8(a0)
    8000659e:	610c                	ld	a1,0(a0)
    800065a0:	34051573          	csrrw	a0,mscratch,a0
    800065a4:	30200073          	mret
	...

00000000800065aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065aa:	1141                	addi	sp,sp,-16
    800065ac:	e422                	sd	s0,8(sp)
    800065ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065b0:	0c0007b7          	lui	a5,0xc000
    800065b4:	4705                	li	a4,1
    800065b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065b8:	c3d8                	sw	a4,4(a5)
}
    800065ba:	6422                	ld	s0,8(sp)
    800065bc:	0141                	addi	sp,sp,16
    800065be:	8082                	ret

00000000800065c0 <plicinithart>:

void
plicinithart(void)
{
    800065c0:	1141                	addi	sp,sp,-16
    800065c2:	e406                	sd	ra,8(sp)
    800065c4:	e022                	sd	s0,0(sp)
    800065c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065c8:	ffffc097          	auipc	ra,0xffffc
    800065cc:	94c080e7          	jalr	-1716(ra) # 80001f14 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800065d0:	0085171b          	slliw	a4,a0,0x8
    800065d4:	0c0027b7          	lui	a5,0xc002
    800065d8:	97ba                	add	a5,a5,a4
    800065da:	40200713          	li	a4,1026
    800065de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800065e2:	00d5151b          	slliw	a0,a0,0xd
    800065e6:	0c2017b7          	lui	a5,0xc201
    800065ea:	953e                	add	a0,a0,a5
    800065ec:	00052023          	sw	zero,0(a0)
}
    800065f0:	60a2                	ld	ra,8(sp)
    800065f2:	6402                	ld	s0,0(sp)
    800065f4:	0141                	addi	sp,sp,16
    800065f6:	8082                	ret

00000000800065f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800065f8:	1141                	addi	sp,sp,-16
    800065fa:	e406                	sd	ra,8(sp)
    800065fc:	e022                	sd	s0,0(sp)
    800065fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006600:	ffffc097          	auipc	ra,0xffffc
    80006604:	914080e7          	jalr	-1772(ra) # 80001f14 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006608:	00d5179b          	slliw	a5,a0,0xd
    8000660c:	0c201537          	lui	a0,0xc201
    80006610:	953e                	add	a0,a0,a5
  return irq;
}
    80006612:	4148                	lw	a0,4(a0)
    80006614:	60a2                	ld	ra,8(sp)
    80006616:	6402                	ld	s0,0(sp)
    80006618:	0141                	addi	sp,sp,16
    8000661a:	8082                	ret

000000008000661c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000661c:	1101                	addi	sp,sp,-32
    8000661e:	ec06                	sd	ra,24(sp)
    80006620:	e822                	sd	s0,16(sp)
    80006622:	e426                	sd	s1,8(sp)
    80006624:	1000                	addi	s0,sp,32
    80006626:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006628:	ffffc097          	auipc	ra,0xffffc
    8000662c:	8ec080e7          	jalr	-1812(ra) # 80001f14 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006630:	00d5151b          	slliw	a0,a0,0xd
    80006634:	0c2017b7          	lui	a5,0xc201
    80006638:	97aa                	add	a5,a5,a0
    8000663a:	c3c4                	sw	s1,4(a5)
}
    8000663c:	60e2                	ld	ra,24(sp)
    8000663e:	6442                	ld	s0,16(sp)
    80006640:	64a2                	ld	s1,8(sp)
    80006642:	6105                	addi	sp,sp,32
    80006644:	8082                	ret

0000000080006646 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006646:	1141                	addi	sp,sp,-16
    80006648:	e406                	sd	ra,8(sp)
    8000664a:	e022                	sd	s0,0(sp)
    8000664c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000664e:	479d                	li	a5,7
    80006650:	06a7c963          	blt	a5,a0,800066c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006654:	0001d797          	auipc	a5,0x1d
    80006658:	9ac78793          	addi	a5,a5,-1620 # 80023000 <disk>
    8000665c:	00a78733          	add	a4,a5,a0
    80006660:	6789                	lui	a5,0x2
    80006662:	97ba                	add	a5,a5,a4
    80006664:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006668:	e7ad                	bnez	a5,800066d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000666a:	00451793          	slli	a5,a0,0x4
    8000666e:	0001f717          	auipc	a4,0x1f
    80006672:	99270713          	addi	a4,a4,-1646 # 80025000 <disk+0x2000>
    80006676:	6314                	ld	a3,0(a4)
    80006678:	96be                	add	a3,a3,a5
    8000667a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000667e:	6314                	ld	a3,0(a4)
    80006680:	96be                	add	a3,a3,a5
    80006682:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006686:	6314                	ld	a3,0(a4)
    80006688:	96be                	add	a3,a3,a5
    8000668a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000668e:	6318                	ld	a4,0(a4)
    80006690:	97ba                	add	a5,a5,a4
    80006692:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006696:	0001d797          	auipc	a5,0x1d
    8000669a:	96a78793          	addi	a5,a5,-1686 # 80023000 <disk>
    8000669e:	97aa                	add	a5,a5,a0
    800066a0:	6509                	lui	a0,0x2
    800066a2:	953e                	add	a0,a0,a5
    800066a4:	4785                	li	a5,1
    800066a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800066aa:	0001f517          	auipc	a0,0x1f
    800066ae:	96e50513          	addi	a0,a0,-1682 # 80025018 <disk+0x2018>
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	566080e7          	jalr	1382(ra) # 80002c18 <wakeup>
}
    800066ba:	60a2                	ld	ra,8(sp)
    800066bc:	6402                	ld	s0,0(sp)
    800066be:	0141                	addi	sp,sp,16
    800066c0:	8082                	ret
    panic("free_desc 1");
    800066c2:	00002517          	auipc	a0,0x2
    800066c6:	22650513          	addi	a0,a0,550 # 800088e8 <syscalls+0x338>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	e74080e7          	jalr	-396(ra) # 8000053e <panic>
    panic("free_desc 2");
    800066d2:	00002517          	auipc	a0,0x2
    800066d6:	22650513          	addi	a0,a0,550 # 800088f8 <syscalls+0x348>
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>

00000000800066e2 <virtio_disk_init>:
{
    800066e2:	1101                	addi	sp,sp,-32
    800066e4:	ec06                	sd	ra,24(sp)
    800066e6:	e822                	sd	s0,16(sp)
    800066e8:	e426                	sd	s1,8(sp)
    800066ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800066ec:	00002597          	auipc	a1,0x2
    800066f0:	21c58593          	addi	a1,a1,540 # 80008908 <syscalls+0x358>
    800066f4:	0001f517          	auipc	a0,0x1f
    800066f8:	a3450513          	addi	a0,a0,-1484 # 80025128 <disk+0x2128>
    800066fc:	ffffa097          	auipc	ra,0xffffa
    80006700:	458080e7          	jalr	1112(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006704:	100017b7          	lui	a5,0x10001
    80006708:	4398                	lw	a4,0(a5)
    8000670a:	2701                	sext.w	a4,a4
    8000670c:	747277b7          	lui	a5,0x74727
    80006710:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006714:	0ef71163          	bne	a4,a5,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006718:	100017b7          	lui	a5,0x10001
    8000671c:	43dc                	lw	a5,4(a5)
    8000671e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006720:	4705                	li	a4,1
    80006722:	0ce79a63          	bne	a5,a4,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006726:	100017b7          	lui	a5,0x10001
    8000672a:	479c                	lw	a5,8(a5)
    8000672c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000672e:	4709                	li	a4,2
    80006730:	0ce79363          	bne	a5,a4,800067f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006734:	100017b7          	lui	a5,0x10001
    80006738:	47d8                	lw	a4,12(a5)
    8000673a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000673c:	554d47b7          	lui	a5,0x554d4
    80006740:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006744:	0af71963          	bne	a4,a5,800067f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006748:	100017b7          	lui	a5,0x10001
    8000674c:	4705                	li	a4,1
    8000674e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006750:	470d                	li	a4,3
    80006752:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006754:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006756:	c7ffe737          	lui	a4,0xc7ffe
    8000675a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000675e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006760:	2701                	sext.w	a4,a4
    80006762:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006764:	472d                	li	a4,11
    80006766:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006768:	473d                	li	a4,15
    8000676a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000676c:	6705                	lui	a4,0x1
    8000676e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006770:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006774:	5bdc                	lw	a5,52(a5)
    80006776:	2781                	sext.w	a5,a5
  if(max == 0)
    80006778:	c7d9                	beqz	a5,80006806 <virtio_disk_init+0x124>
  if(max < NUM)
    8000677a:	471d                	li	a4,7
    8000677c:	08f77d63          	bgeu	a4,a5,80006816 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006780:	100014b7          	lui	s1,0x10001
    80006784:	47a1                	li	a5,8
    80006786:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006788:	6609                	lui	a2,0x2
    8000678a:	4581                	li	a1,0
    8000678c:	0001d517          	auipc	a0,0x1d
    80006790:	87450513          	addi	a0,a0,-1932 # 80023000 <disk>
    80006794:	ffffa097          	auipc	ra,0xffffa
    80006798:	54c080e7          	jalr	1356(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000679c:	0001d717          	auipc	a4,0x1d
    800067a0:	86470713          	addi	a4,a4,-1948 # 80023000 <disk>
    800067a4:	00c75793          	srli	a5,a4,0xc
    800067a8:	2781                	sext.w	a5,a5
    800067aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800067ac:	0001f797          	auipc	a5,0x1f
    800067b0:	85478793          	addi	a5,a5,-1964 # 80025000 <disk+0x2000>
    800067b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800067b6:	0001d717          	auipc	a4,0x1d
    800067ba:	8ca70713          	addi	a4,a4,-1846 # 80023080 <disk+0x80>
    800067be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800067c0:	0001e717          	auipc	a4,0x1e
    800067c4:	84070713          	addi	a4,a4,-1984 # 80024000 <disk+0x1000>
    800067c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800067ca:	4705                	li	a4,1
    800067cc:	00e78c23          	sb	a4,24(a5)
    800067d0:	00e78ca3          	sb	a4,25(a5)
    800067d4:	00e78d23          	sb	a4,26(a5)
    800067d8:	00e78da3          	sb	a4,27(a5)
    800067dc:	00e78e23          	sb	a4,28(a5)
    800067e0:	00e78ea3          	sb	a4,29(a5)
    800067e4:	00e78f23          	sb	a4,30(a5)
    800067e8:	00e78fa3          	sb	a4,31(a5)
}
    800067ec:	60e2                	ld	ra,24(sp)
    800067ee:	6442                	ld	s0,16(sp)
    800067f0:	64a2                	ld	s1,8(sp)
    800067f2:	6105                	addi	sp,sp,32
    800067f4:	8082                	ret
    panic("could not find virtio disk");
    800067f6:	00002517          	auipc	a0,0x2
    800067fa:	12250513          	addi	a0,a0,290 # 80008918 <syscalls+0x368>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	d40080e7          	jalr	-704(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	13250513          	addi	a0,a0,306 # 80008938 <syscalls+0x388>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006816:	00002517          	auipc	a0,0x2
    8000681a:	14250513          	addi	a0,a0,322 # 80008958 <syscalls+0x3a8>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>

0000000080006826 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006826:	7159                	addi	sp,sp,-112
    80006828:	f486                	sd	ra,104(sp)
    8000682a:	f0a2                	sd	s0,96(sp)
    8000682c:	eca6                	sd	s1,88(sp)
    8000682e:	e8ca                	sd	s2,80(sp)
    80006830:	e4ce                	sd	s3,72(sp)
    80006832:	e0d2                	sd	s4,64(sp)
    80006834:	fc56                	sd	s5,56(sp)
    80006836:	f85a                	sd	s6,48(sp)
    80006838:	f45e                	sd	s7,40(sp)
    8000683a:	f062                	sd	s8,32(sp)
    8000683c:	ec66                	sd	s9,24(sp)
    8000683e:	e86a                	sd	s10,16(sp)
    80006840:	1880                	addi	s0,sp,112
    80006842:	892a                	mv	s2,a0
    80006844:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006846:	00c52c83          	lw	s9,12(a0)
    8000684a:	001c9c9b          	slliw	s9,s9,0x1
    8000684e:	1c82                	slli	s9,s9,0x20
    80006850:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006854:	0001f517          	auipc	a0,0x1f
    80006858:	8d450513          	addi	a0,a0,-1836 # 80025128 <disk+0x2128>
    8000685c:	ffffa097          	auipc	ra,0xffffa
    80006860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006864:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006866:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006868:	0001cb97          	auipc	s7,0x1c
    8000686c:	798b8b93          	addi	s7,s7,1944 # 80023000 <disk>
    80006870:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006872:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006874:	8a4e                	mv	s4,s3
    80006876:	a051                	j	800068fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006878:	00fb86b3          	add	a3,s7,a5
    8000687c:	96da                	add	a3,a3,s6
    8000687e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006882:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006884:	0207c563          	bltz	a5,800068ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006888:	2485                	addiw	s1,s1,1
    8000688a:	0711                	addi	a4,a4,4
    8000688c:	25548063          	beq	s1,s5,80006acc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006890:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006892:	0001e697          	auipc	a3,0x1e
    80006896:	78668693          	addi	a3,a3,1926 # 80025018 <disk+0x2018>
    8000689a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000689c:	0006c583          	lbu	a1,0(a3)
    800068a0:	fde1                	bnez	a1,80006878 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800068a2:	2785                	addiw	a5,a5,1
    800068a4:	0685                	addi	a3,a3,1
    800068a6:	ff879be3          	bne	a5,s8,8000689c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800068aa:	57fd                	li	a5,-1
    800068ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800068ae:	02905a63          	blez	s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068b2:	f9042503          	lw	a0,-112(s0)
    800068b6:	00000097          	auipc	ra,0x0
    800068ba:	d90080e7          	jalr	-624(ra) # 80006646 <free_desc>
      for(int j = 0; j < i; j++)
    800068be:	4785                	li	a5,1
    800068c0:	0297d163          	bge	a5,s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068c4:	f9442503          	lw	a0,-108(s0)
    800068c8:	00000097          	auipc	ra,0x0
    800068cc:	d7e080e7          	jalr	-642(ra) # 80006646 <free_desc>
      for(int j = 0; j < i; j++)
    800068d0:	4789                	li	a5,2
    800068d2:	0097d863          	bge	a5,s1,800068e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068d6:	f9842503          	lw	a0,-104(s0)
    800068da:	00000097          	auipc	ra,0x0
    800068de:	d6c080e7          	jalr	-660(ra) # 80006646 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068e2:	0001f597          	auipc	a1,0x1f
    800068e6:	84658593          	addi	a1,a1,-1978 # 80025128 <disk+0x2128>
    800068ea:	0001e517          	auipc	a0,0x1e
    800068ee:	72e50513          	addi	a0,a0,1838 # 80025018 <disk+0x2018>
    800068f2:	ffffc097          	auipc	ra,0xffffc
    800068f6:	cfc080e7          	jalr	-772(ra) # 800025ee <sleep>
  for(int i = 0; i < 3; i++){
    800068fa:	f9040713          	addi	a4,s0,-112
    800068fe:	84ce                	mv	s1,s3
    80006900:	bf41                	j	80006890 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006902:	20058713          	addi	a4,a1,512
    80006906:	00471693          	slli	a3,a4,0x4
    8000690a:	0001c717          	auipc	a4,0x1c
    8000690e:	6f670713          	addi	a4,a4,1782 # 80023000 <disk>
    80006912:	9736                	add	a4,a4,a3
    80006914:	4685                	li	a3,1
    80006916:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000691a:	20058713          	addi	a4,a1,512
    8000691e:	00471693          	slli	a3,a4,0x4
    80006922:	0001c717          	auipc	a4,0x1c
    80006926:	6de70713          	addi	a4,a4,1758 # 80023000 <disk>
    8000692a:	9736                	add	a4,a4,a3
    8000692c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006930:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006934:	7679                	lui	a2,0xffffe
    80006936:	963e                	add	a2,a2,a5
    80006938:	0001e697          	auipc	a3,0x1e
    8000693c:	6c868693          	addi	a3,a3,1736 # 80025000 <disk+0x2000>
    80006940:	6298                	ld	a4,0(a3)
    80006942:	9732                	add	a4,a4,a2
    80006944:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006946:	6298                	ld	a4,0(a3)
    80006948:	9732                	add	a4,a4,a2
    8000694a:	4541                	li	a0,16
    8000694c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000694e:	6298                	ld	a4,0(a3)
    80006950:	9732                	add	a4,a4,a2
    80006952:	4505                	li	a0,1
    80006954:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006958:	f9442703          	lw	a4,-108(s0)
    8000695c:	6288                	ld	a0,0(a3)
    8000695e:	962a                	add	a2,a2,a0
    80006960:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006964:	0712                	slli	a4,a4,0x4
    80006966:	6290                	ld	a2,0(a3)
    80006968:	963a                	add	a2,a2,a4
    8000696a:	05890513          	addi	a0,s2,88
    8000696e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006970:	6294                	ld	a3,0(a3)
    80006972:	96ba                	add	a3,a3,a4
    80006974:	40000613          	li	a2,1024
    80006978:	c690                	sw	a2,8(a3)
  if(write)
    8000697a:	140d0063          	beqz	s10,80006aba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000697e:	0001e697          	auipc	a3,0x1e
    80006982:	6826b683          	ld	a3,1666(a3) # 80025000 <disk+0x2000>
    80006986:	96ba                	add	a3,a3,a4
    80006988:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000698c:	0001c817          	auipc	a6,0x1c
    80006990:	67480813          	addi	a6,a6,1652 # 80023000 <disk>
    80006994:	0001e517          	auipc	a0,0x1e
    80006998:	66c50513          	addi	a0,a0,1644 # 80025000 <disk+0x2000>
    8000699c:	6114                	ld	a3,0(a0)
    8000699e:	96ba                	add	a3,a3,a4
    800069a0:	00c6d603          	lhu	a2,12(a3)
    800069a4:	00166613          	ori	a2,a2,1
    800069a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800069ac:	f9842683          	lw	a3,-104(s0)
    800069b0:	6110                	ld	a2,0(a0)
    800069b2:	9732                	add	a4,a4,a2
    800069b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069b8:	20058613          	addi	a2,a1,512
    800069bc:	0612                	slli	a2,a2,0x4
    800069be:	9642                	add	a2,a2,a6
    800069c0:	577d                	li	a4,-1
    800069c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069c6:	00469713          	slli	a4,a3,0x4
    800069ca:	6114                	ld	a3,0(a0)
    800069cc:	96ba                	add	a3,a3,a4
    800069ce:	03078793          	addi	a5,a5,48
    800069d2:	97c2                	add	a5,a5,a6
    800069d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800069d6:	611c                	ld	a5,0(a0)
    800069d8:	97ba                	add	a5,a5,a4
    800069da:	4685                	li	a3,1
    800069dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069de:	611c                	ld	a5,0(a0)
    800069e0:	97ba                	add	a5,a5,a4
    800069e2:	4809                	li	a6,2
    800069e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800069e8:	611c                	ld	a5,0(a0)
    800069ea:	973e                	add	a4,a4,a5
    800069ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800069f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800069f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800069f8:	6518                	ld	a4,8(a0)
    800069fa:	00275783          	lhu	a5,2(a4)
    800069fe:	8b9d                	andi	a5,a5,7
    80006a00:	0786                	slli	a5,a5,0x1
    80006a02:	97ba                	add	a5,a5,a4
    80006a04:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a08:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a0c:	6518                	ld	a4,8(a0)
    80006a0e:	00275783          	lhu	a5,2(a4)
    80006a12:	2785                	addiw	a5,a5,1
    80006a14:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a18:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a1c:	100017b7          	lui	a5,0x10001
    80006a20:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a24:	00492703          	lw	a4,4(s2)
    80006a28:	4785                	li	a5,1
    80006a2a:	02f71163          	bne	a4,a5,80006a4c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006a2e:	0001e997          	auipc	s3,0x1e
    80006a32:	6fa98993          	addi	s3,s3,1786 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006a36:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a38:	85ce                	mv	a1,s3
    80006a3a:	854a                	mv	a0,s2
    80006a3c:	ffffc097          	auipc	ra,0xffffc
    80006a40:	bb2080e7          	jalr	-1102(ra) # 800025ee <sleep>
  while(b->disk == 1) {
    80006a44:	00492783          	lw	a5,4(s2)
    80006a48:	fe9788e3          	beq	a5,s1,80006a38 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006a4c:	f9042903          	lw	s2,-112(s0)
    80006a50:	20090793          	addi	a5,s2,512
    80006a54:	00479713          	slli	a4,a5,0x4
    80006a58:	0001c797          	auipc	a5,0x1c
    80006a5c:	5a878793          	addi	a5,a5,1448 # 80023000 <disk>
    80006a60:	97ba                	add	a5,a5,a4
    80006a62:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a66:	0001e997          	auipc	s3,0x1e
    80006a6a:	59a98993          	addi	s3,s3,1434 # 80025000 <disk+0x2000>
    80006a6e:	00491713          	slli	a4,s2,0x4
    80006a72:	0009b783          	ld	a5,0(s3)
    80006a76:	97ba                	add	a5,a5,a4
    80006a78:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a7c:	854a                	mv	a0,s2
    80006a7e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a82:	00000097          	auipc	ra,0x0
    80006a86:	bc4080e7          	jalr	-1084(ra) # 80006646 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a8a:	8885                	andi	s1,s1,1
    80006a8c:	f0ed                	bnez	s1,80006a6e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a8e:	0001e517          	auipc	a0,0x1e
    80006a92:	69a50513          	addi	a0,a0,1690 # 80025128 <disk+0x2128>
    80006a96:	ffffa097          	auipc	ra,0xffffa
    80006a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
}
    80006a9e:	70a6                	ld	ra,104(sp)
    80006aa0:	7406                	ld	s0,96(sp)
    80006aa2:	64e6                	ld	s1,88(sp)
    80006aa4:	6946                	ld	s2,80(sp)
    80006aa6:	69a6                	ld	s3,72(sp)
    80006aa8:	6a06                	ld	s4,64(sp)
    80006aaa:	7ae2                	ld	s5,56(sp)
    80006aac:	7b42                	ld	s6,48(sp)
    80006aae:	7ba2                	ld	s7,40(sp)
    80006ab0:	7c02                	ld	s8,32(sp)
    80006ab2:	6ce2                	ld	s9,24(sp)
    80006ab4:	6d42                	ld	s10,16(sp)
    80006ab6:	6165                	addi	sp,sp,112
    80006ab8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006aba:	0001e697          	auipc	a3,0x1e
    80006abe:	5466b683          	ld	a3,1350(a3) # 80025000 <disk+0x2000>
    80006ac2:	96ba                	add	a3,a3,a4
    80006ac4:	4609                	li	a2,2
    80006ac6:	00c69623          	sh	a2,12(a3)
    80006aca:	b5c9                	j	8000698c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006acc:	f9042583          	lw	a1,-112(s0)
    80006ad0:	20058793          	addi	a5,a1,512
    80006ad4:	0792                	slli	a5,a5,0x4
    80006ad6:	0001c517          	auipc	a0,0x1c
    80006ada:	5d250513          	addi	a0,a0,1490 # 800230a8 <disk+0xa8>
    80006ade:	953e                	add	a0,a0,a5
  if(write)
    80006ae0:	e20d11e3          	bnez	s10,80006902 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006ae4:	20058713          	addi	a4,a1,512
    80006ae8:	00471693          	slli	a3,a4,0x4
    80006aec:	0001c717          	auipc	a4,0x1c
    80006af0:	51470713          	addi	a4,a4,1300 # 80023000 <disk>
    80006af4:	9736                	add	a4,a4,a3
    80006af6:	0a072423          	sw	zero,168(a4)
    80006afa:	b505                	j	8000691a <virtio_disk_rw+0xf4>

0000000080006afc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006afc:	1101                	addi	sp,sp,-32
    80006afe:	ec06                	sd	ra,24(sp)
    80006b00:	e822                	sd	s0,16(sp)
    80006b02:	e426                	sd	s1,8(sp)
    80006b04:	e04a                	sd	s2,0(sp)
    80006b06:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b08:	0001e517          	auipc	a0,0x1e
    80006b0c:	62050513          	addi	a0,a0,1568 # 80025128 <disk+0x2128>
    80006b10:	ffffa097          	auipc	ra,0xffffa
    80006b14:	0d4080e7          	jalr	212(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b18:	10001737          	lui	a4,0x10001
    80006b1c:	533c                	lw	a5,96(a4)
    80006b1e:	8b8d                	andi	a5,a5,3
    80006b20:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b22:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b26:	0001e797          	auipc	a5,0x1e
    80006b2a:	4da78793          	addi	a5,a5,1242 # 80025000 <disk+0x2000>
    80006b2e:	6b94                	ld	a3,16(a5)
    80006b30:	0207d703          	lhu	a4,32(a5)
    80006b34:	0026d783          	lhu	a5,2(a3)
    80006b38:	06f70163          	beq	a4,a5,80006b9a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b3c:	0001c917          	auipc	s2,0x1c
    80006b40:	4c490913          	addi	s2,s2,1220 # 80023000 <disk>
    80006b44:	0001e497          	auipc	s1,0x1e
    80006b48:	4bc48493          	addi	s1,s1,1212 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006b4c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b50:	6898                	ld	a4,16(s1)
    80006b52:	0204d783          	lhu	a5,32(s1)
    80006b56:	8b9d                	andi	a5,a5,7
    80006b58:	078e                	slli	a5,a5,0x3
    80006b5a:	97ba                	add	a5,a5,a4
    80006b5c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b5e:	20078713          	addi	a4,a5,512
    80006b62:	0712                	slli	a4,a4,0x4
    80006b64:	974a                	add	a4,a4,s2
    80006b66:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006b6a:	e731                	bnez	a4,80006bb6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b6c:	20078793          	addi	a5,a5,512
    80006b70:	0792                	slli	a5,a5,0x4
    80006b72:	97ca                	add	a5,a5,s2
    80006b74:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b76:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b7a:	ffffc097          	auipc	ra,0xffffc
    80006b7e:	09e080e7          	jalr	158(ra) # 80002c18 <wakeup>

    disk.used_idx += 1;
    80006b82:	0204d783          	lhu	a5,32(s1)
    80006b86:	2785                	addiw	a5,a5,1
    80006b88:	17c2                	slli	a5,a5,0x30
    80006b8a:	93c1                	srli	a5,a5,0x30
    80006b8c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b90:	6898                	ld	a4,16(s1)
    80006b92:	00275703          	lhu	a4,2(a4)
    80006b96:	faf71be3          	bne	a4,a5,80006b4c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b9a:	0001e517          	auipc	a0,0x1e
    80006b9e:	58e50513          	addi	a0,a0,1422 # 80025128 <disk+0x2128>
    80006ba2:	ffffa097          	auipc	ra,0xffffa
    80006ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
}
    80006baa:	60e2                	ld	ra,24(sp)
    80006bac:	6442                	ld	s0,16(sp)
    80006bae:	64a2                	ld	s1,8(sp)
    80006bb0:	6902                	ld	s2,0(sp)
    80006bb2:	6105                	addi	sp,sp,32
    80006bb4:	8082                	ret
      panic("virtio_disk_intr status");
    80006bb6:	00002517          	auipc	a0,0x2
    80006bba:	dc250513          	addi	a0,a0,-574 # 80008978 <syscalls+0x3c8>
    80006bbe:	ffffa097          	auipc	ra,0xffffa
    80006bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>

0000000080006bc6 <cas>:
    80006bc6:	100522af          	lr.w	t0,(a0)
    80006bca:	00b29563          	bne	t0,a1,80006bd4 <fail>
    80006bce:	18c5252f          	sc.w	a0,a2,(a0)
    80006bd2:	8082                	ret

0000000080006bd4 <fail>:
    80006bd4:	4505                	li	a0,1
    80006bd6:	8082                	ret
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
