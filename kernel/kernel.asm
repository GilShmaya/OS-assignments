
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
    80000068:	52c78793          	addi	a5,a5,1324 # 80006590 <timervec>
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
    8000044a:	7de080e7          	jalr	2014(ra) # 80002c24 <wakeup>
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
    800008a4:	384080e7          	jalr	900(ra) # 80002c24 <wakeup>
    
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
    80000ed8:	124080e7          	jalr	292(ra) # 80002ff8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	6f4080e7          	jalr	1780(ra) # 800065d0 <plicinithart>
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
    80000f50:	084080e7          	jalr	132(ra) # 80002fd0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	0a4080e7          	jalr	164(ra) # 80002ff8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	65e080e7          	jalr	1630(ra) # 800065ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	66c080e7          	jalr	1644(ra) # 800065d0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00003097          	auipc	ra,0x3
    80000f70:	84a080e7          	jalr	-1974(ra) # 800037b6 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	eda080e7          	jalr	-294(ra) # 80003e4e <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	e84080e7          	jalr	-380(ra) # 80004e00 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	76e080e7          	jalr	1902(ra) # 800066f2 <virtio_disk_init>
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
    80001faa:	06a080e7          	jalr	106(ra) # 80003010 <usertrapret>
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
    80001fc4:	e0e080e7          	jalr	-498(ra) # 80003dce <fsinit>
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
    80001fee:	bec080e7          	jalr	-1044(ra) # 80006bd6 <cas>
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
    80002334:	4cc080e7          	jalr	1228(ra) # 800047fc <namei>
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
    800024a2:	ac8080e7          	jalr	-1336(ra) # 80002f66 <swtch>
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
    8000252c:	a3e080e7          	jalr	-1474(ra) # 80002f66 <swtch>
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
    80002a90:	14a080e7          	jalr	330(ra) # 80006bd6 <cas>
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
    80002abe:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	6ae080e7          	jalr	1710(ra) # 8000216e <allocproc>
    80002ac8:	14050c63          	beqz	a0,80002c20 <fork+0x17c>
    80002acc:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002ace:	0489b603          	ld	a2,72(s3)
    80002ad2:	692c                	ld	a1,80(a0)
    80002ad4:	0509b503          	ld	a0,80(s3)
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	a96080e7          	jalr	-1386(ra) # 8000156e <uvmcopy>
    80002ae0:	04054663          	bltz	a0,80002b2c <fork+0x88>
  np->sz = p->sz;
    80002ae4:	0489b783          	ld	a5,72(s3)
    80002ae8:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80002aec:	0589b683          	ld	a3,88(s3)
    80002af0:	87b6                	mv	a5,a3
    80002af2:	05893703          	ld	a4,88(s2)
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
    80002b1a:	05893783          	ld	a5,88(s2)
    80002b1e:	0607b823          	sd	zero,112(a5)
    80002b22:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002b26:	15000a13          	li	s4,336
    80002b2a:	a03d                	j	80002b58 <fork+0xb4>
    freeproc(np);
    80002b2c:	854a                	mv	a0,s2
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	5c4080e7          	jalr	1476(ra) # 800020f2 <freeproc>
    release(&np->lock);
    80002b36:	854a                	mv	a0,s2
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	160080e7          	jalr	352(ra) # 80000c98 <release>
    return -1;
    80002b40:	5afd                	li	s5,-1
    80002b42:	a0e9                	j	80002c0c <fork+0x168>
      np->ofile[i] = filedup(p->ofile[i]);
    80002b44:	00002097          	auipc	ra,0x2
    80002b48:	34e080e7          	jalr	846(ra) # 80004e92 <filedup>
    80002b4c:	009907b3          	add	a5,s2,s1
    80002b50:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002b52:	04a1                	addi	s1,s1,8
    80002b54:	01448763          	beq	s1,s4,80002b62 <fork+0xbe>
    if(p->ofile[i])
    80002b58:	009987b3          	add	a5,s3,s1
    80002b5c:	6388                	ld	a0,0(a5)
    80002b5e:	f17d                	bnez	a0,80002b44 <fork+0xa0>
    80002b60:	bfcd                	j	80002b52 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002b62:	1509b503          	ld	a0,336(s3)
    80002b66:	00001097          	auipc	ra,0x1
    80002b6a:	4a2080e7          	jalr	1186(ra) # 80004008 <idup>
    80002b6e:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002b72:	4641                	li	a2,16
    80002b74:	15898593          	addi	a1,s3,344
    80002b78:	15890513          	addi	a0,s2,344
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	2b6080e7          	jalr	694(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002b84:	03092a83          	lw	s5,48(s2)
  release(&np->lock);
    80002b88:	854a                	mv	a0,s2
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
    80002bac:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002bba:	854a                	mv	a0,s2
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	028080e7          	jalr	40(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002bc4:	478d                	li	a5,3
    80002bc6:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; // case BLNCFLG=OFF -> cpu = parent's cpu 
    80002bca:	1689a783          	lw	a5,360(s3)
    80002bce:	16f92423          	sw	a5,360(s2)
      np->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	e26080e7          	jalr	-474(ra) # 800029f8 <min_cpu_process_count>
    80002bda:	16a92423          	sw	a0,360(s2)
  struct cpu *c = &cpus[np->last_cpu];
    80002bde:	0b000493          	li	s1,176
    80002be2:	029504b3          	mul	s1,a0,s1
  increment_cpu_process_count(c);
    80002be6:	009a0533          	add	a0,s4,s1
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	e86080e7          	jalr	-378(ra) # 80002a70 <increment_cpu_process_count>
  insert_proc_to_list(&(c->runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    80002bf2:	08048513          	addi	a0,s1,128
    80002bf6:	85ca                	mv	a1,s2
    80002bf8:	9552                	add	a0,a0,s4
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	e62080e7          	jalr	-414(ra) # 80001a5c <insert_proc_to_list>
  release(&np->lock);
    80002c02:	854a                	mv	a0,s2
    80002c04:	ffffe097          	auipc	ra,0xffffe
    80002c08:	094080e7          	jalr	148(ra) # 80000c98 <release>
}
    80002c0c:	8556                	mv	a0,s5
    80002c0e:	70e2                	ld	ra,56(sp)
    80002c10:	7442                	ld	s0,48(sp)
    80002c12:	74a2                	ld	s1,40(sp)
    80002c14:	7902                	ld	s2,32(sp)
    80002c16:	69e2                	ld	s3,24(sp)
    80002c18:	6a42                	ld	s4,16(sp)
    80002c1a:	6aa2                	ld	s5,8(sp)
    80002c1c:	6121                	addi	sp,sp,64
    80002c1e:	8082                	ret
    return -1;
    80002c20:	5afd                	li	s5,-1
    80002c22:	b7ed                	j	80002c0c <fork+0x168>

0000000080002c24 <wakeup>:
{
    80002c24:	7159                	addi	sp,sp,-112
    80002c26:	f486                	sd	ra,104(sp)
    80002c28:	f0a2                	sd	s0,96(sp)
    80002c2a:	eca6                	sd	s1,88(sp)
    80002c2c:	e8ca                	sd	s2,80(sp)
    80002c2e:	e4ce                	sd	s3,72(sp)
    80002c30:	e0d2                	sd	s4,64(sp)
    80002c32:	fc56                	sd	s5,56(sp)
    80002c34:	f85a                	sd	s6,48(sp)
    80002c36:	f45e                	sd	s7,40(sp)
    80002c38:	f062                	sd	s8,32(sp)
    80002c3a:	ec66                	sd	s9,24(sp)
    80002c3c:	e86a                	sd	s10,16(sp)
    80002c3e:	e46e                	sd	s11,8(sp)
    80002c40:	1880                	addi	s0,sp,112
    80002c42:	8c2a                	mv	s8,a0
  int curr = get_head(&sleeping_list);
    80002c44:	00006517          	auipc	a0,0x6
    80002c48:	d7c50513          	addi	a0,a0,-644 # 800089c0 <sleeping_list>
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	dba080e7          	jalr	-582(ra) # 80001a06 <get_head>
  while(curr != -1) {
    80002c54:	57fd                	li	a5,-1
    80002c56:	0af50263          	beq	a0,a5,80002cfa <wakeup+0xd6>
    80002c5a:	892a                	mv	s2,a0
    p = &proc[curr];
    80002c5c:	19000a13          	li	s4,400
    80002c60:	0000f997          	auipc	s3,0xf
    80002c64:	bf098993          	addi	s3,s3,-1040 # 80011850 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002c68:	4b89                	li	s7,2
        p->state = RUNNABLE;
    80002c6a:	4d8d                	li	s11,3
    80002c6c:	0b000d13          	li	s10,176
        c = &cpus[p->last_cpu];
    80002c70:	0000ec97          	auipc	s9,0xe
    80002c74:	630c8c93          	addi	s9,s9,1584 # 800112a0 <cpus>
  while(curr != -1) {
    80002c78:	5b7d                	li	s6,-1
    80002c7a:	a801                	j	80002c8a <wakeup+0x66>
      release(&p->lock);
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	01a080e7          	jalr	26(ra) # 80000c98 <release>
  while(curr != -1) {
    80002c86:	07690a63          	beq	s2,s6,80002cfa <wakeup+0xd6>
    p = &proc[curr];
    80002c8a:	034904b3          	mul	s1,s2,s4
    80002c8e:	94ce                	add	s1,s1,s3
    curr = p->next_index;
    80002c90:	1744a903          	lw	s2,372(s1)
    if(p != myproc()){
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	2b2080e7          	jalr	690(ra) # 80001f46 <myproc>
    80002c9c:	fea485e3          	beq	s1,a0,80002c86 <wakeup+0x62>
      acquire(&p->lock);
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	f42080e7          	jalr	-190(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002caa:	4c9c                	lw	a5,24(s1)
    80002cac:	fd7798e3          	bne	a5,s7,80002c7c <wakeup+0x58>
    80002cb0:	709c                	ld	a5,32(s1)
    80002cb2:	fd8795e3          	bne	a5,s8,80002c7c <wakeup+0x58>
        remove_proc_to_list(&sleeping_list, p);
    80002cb6:	85a6                	mv	a1,s1
    80002cb8:	00006517          	auipc	a0,0x6
    80002cbc:	d0850513          	addi	a0,a0,-760 # 800089c0 <sleeping_list>
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	f3c080e7          	jalr	-196(ra) # 80001bfc <remove_proc_to_list>
        p->state = RUNNABLE;
    80002cc8:	01b4ac23          	sw	s11,24(s1)
          p->last_cpu = min_cpu_process_count(); // case BLNCFLG=ON -> cpu = CPU with the lowest counter value
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	d2c080e7          	jalr	-724(ra) # 800029f8 <min_cpu_process_count>
    80002cd4:	16a4a423          	sw	a0,360(s1)
        c = &cpus[p->last_cpu];
    80002cd8:	03a50ab3          	mul	s5,a0,s10
        increment_cpu_process_count(c);
    80002cdc:	015c8533          	add	a0,s9,s5
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	d90080e7          	jalr	-624(ra) # 80002a70 <increment_cpu_process_count>
        insert_proc_to_list(&(c->runnable_list), p);
    80002ce8:	080a8513          	addi	a0,s5,128
    80002cec:	85a6                	mv	a1,s1
    80002cee:	9566                	add	a0,a0,s9
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	d6c080e7          	jalr	-660(ra) # 80001a5c <insert_proc_to_list>
    80002cf8:	b751                	j	80002c7c <wakeup+0x58>
}
    80002cfa:	70a6                	ld	ra,104(sp)
    80002cfc:	7406                	ld	s0,96(sp)
    80002cfe:	64e6                	ld	s1,88(sp)
    80002d00:	6946                	ld	s2,80(sp)
    80002d02:	69a6                	ld	s3,72(sp)
    80002d04:	6a06                	ld	s4,64(sp)
    80002d06:	7ae2                	ld	s5,56(sp)
    80002d08:	7b42                	ld	s6,48(sp)
    80002d0a:	7ba2                	ld	s7,40(sp)
    80002d0c:	7c02                	ld	s8,32(sp)
    80002d0e:	6ce2                	ld	s9,24(sp)
    80002d10:	6d42                	ld	s10,16(sp)
    80002d12:	6da2                	ld	s11,8(sp)
    80002d14:	6165                	addi	sp,sp,112
    80002d16:	8082                	ret

0000000080002d18 <reparent>:
{
    80002d18:	7179                	addi	sp,sp,-48
    80002d1a:	f406                	sd	ra,40(sp)
    80002d1c:	f022                	sd	s0,32(sp)
    80002d1e:	ec26                	sd	s1,24(sp)
    80002d20:	e84a                	sd	s2,16(sp)
    80002d22:	e44e                	sd	s3,8(sp)
    80002d24:	e052                	sd	s4,0(sp)
    80002d26:	1800                	addi	s0,sp,48
    80002d28:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d2a:	0000f497          	auipc	s1,0xf
    80002d2e:	b2648493          	addi	s1,s1,-1242 # 80011850 <proc>
      pp->parent = initproc;
    80002d32:	00006a17          	auipc	s4,0x6
    80002d36:	2f6a0a13          	addi	s4,s4,758 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002d3a:	00015997          	auipc	s3,0x15
    80002d3e:	f1698993          	addi	s3,s3,-234 # 80017c50 <tickslock>
    80002d42:	a029                	j	80002d4c <reparent+0x34>
    80002d44:	19048493          	addi	s1,s1,400
    80002d48:	01348d63          	beq	s1,s3,80002d62 <reparent+0x4a>
    if(pp->parent == p){
    80002d4c:	7c9c                	ld	a5,56(s1)
    80002d4e:	ff279be3          	bne	a5,s2,80002d44 <reparent+0x2c>
      pp->parent = initproc;
    80002d52:	000a3503          	ld	a0,0(s4)
    80002d56:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	ecc080e7          	jalr	-308(ra) # 80002c24 <wakeup>
    80002d60:	b7d5                	j	80002d44 <reparent+0x2c>
}
    80002d62:	70a2                	ld	ra,40(sp)
    80002d64:	7402                	ld	s0,32(sp)
    80002d66:	64e2                	ld	s1,24(sp)
    80002d68:	6942                	ld	s2,16(sp)
    80002d6a:	69a2                	ld	s3,8(sp)
    80002d6c:	6a02                	ld	s4,0(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret

0000000080002d72 <exit>:
{
    80002d72:	7179                	addi	sp,sp,-48
    80002d74:	f406                	sd	ra,40(sp)
    80002d76:	f022                	sd	s0,32(sp)
    80002d78:	ec26                	sd	s1,24(sp)
    80002d7a:	e84a                	sd	s2,16(sp)
    80002d7c:	e44e                	sd	s3,8(sp)
    80002d7e:	e052                	sd	s4,0(sp)
    80002d80:	1800                	addi	s0,sp,48
    80002d82:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	1c2080e7          	jalr	450(ra) # 80001f46 <myproc>
    80002d8c:	89aa                	mv	s3,a0
  if(p == initproc)
    80002d8e:	00006797          	auipc	a5,0x6
    80002d92:	29a7b783          	ld	a5,666(a5) # 80009028 <initproc>
    80002d96:	0d050493          	addi	s1,a0,208
    80002d9a:	15050913          	addi	s2,a0,336
    80002d9e:	02a79363          	bne	a5,a0,80002dc4 <exit+0x52>
    panic("init exiting");
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	63e50513          	addi	a0,a0,1598 # 800083e0 <digits+0x3a0>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
      fileclose(f);
    80002db2:	00002097          	auipc	ra,0x2
    80002db6:	132080e7          	jalr	306(ra) # 80004ee4 <fileclose>
      p->ofile[fd] = 0;
    80002dba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002dbe:	04a1                	addi	s1,s1,8
    80002dc0:	01248563          	beq	s1,s2,80002dca <exit+0x58>
    if(p->ofile[fd]){
    80002dc4:	6088                	ld	a0,0(s1)
    80002dc6:	f575                	bnez	a0,80002db2 <exit+0x40>
    80002dc8:	bfdd                	j	80002dbe <exit+0x4c>
  begin_op();
    80002dca:	00002097          	auipc	ra,0x2
    80002dce:	c4e080e7          	jalr	-946(ra) # 80004a18 <begin_op>
  iput(p->cwd);
    80002dd2:	1509b503          	ld	a0,336(s3)
    80002dd6:	00001097          	auipc	ra,0x1
    80002dda:	42a080e7          	jalr	1066(ra) # 80004200 <iput>
  end_op();
    80002dde:	00002097          	auipc	ra,0x2
    80002de2:	cba080e7          	jalr	-838(ra) # 80004a98 <end_op>
  p->cwd = 0;
    80002de6:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002dea:	0000f497          	auipc	s1,0xf
    80002dee:	a4e48493          	addi	s1,s1,-1458 # 80011838 <wait_lock>
    80002df2:	8526                	mv	a0,s1
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	df0080e7          	jalr	-528(ra) # 80000be4 <acquire>
  reparent(p);
    80002dfc:	854e                	mv	a0,s3
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	f1a080e7          	jalr	-230(ra) # 80002d18 <reparent>
  wakeup(p->parent);
    80002e06:	0389b503          	ld	a0,56(s3)
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	e1a080e7          	jalr	-486(ra) # 80002c24 <wakeup>
  acquire(&p->lock);
    80002e12:	854e                	mv	a0,s3
    80002e14:	ffffe097          	auipc	ra,0xffffe
    80002e18:	dd0080e7          	jalr	-560(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002e1c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002e20:	4795                	li	a5,5
    80002e22:	00f9ac23          	sw	a5,24(s3)
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    80002e26:	85ce                	mv	a1,s3
    80002e28:	00006517          	auipc	a0,0x6
    80002e2c:	bb850513          	addi	a0,a0,-1096 # 800089e0 <zombie_list>
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	c2c080e7          	jalr	-980(ra) # 80001a5c <insert_proc_to_list>
  release(&wait_lock);
    80002e38:	8526                	mv	a0,s1
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	e5e080e7          	jalr	-418(ra) # 80000c98 <release>
  sched();
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	66a080e7          	jalr	1642(ra) # 800024ac <sched>
  panic("zombie exit");
    80002e4a:	00005517          	auipc	a0,0x5
    80002e4e:	5a650513          	addi	a0,a0,1446 # 800083f0 <digits+0x3b0>
    80002e52:	ffffd097          	auipc	ra,0xffffd
    80002e56:	6ec080e7          	jalr	1772(ra) # 8000053e <panic>

0000000080002e5a <steal_process>:

void
steal_process(struct cpu *curr_c){  
    80002e5a:	7119                	addi	sp,sp,-128
    80002e5c:	fc86                	sd	ra,120(sp)
    80002e5e:	f8a2                	sd	s0,112(sp)
    80002e60:	f4a6                	sd	s1,104(sp)
    80002e62:	f0ca                	sd	s2,96(sp)
    80002e64:	ecce                	sd	s3,88(sp)
    80002e66:	e8d2                	sd	s4,80(sp)
    80002e68:	e4d6                	sd	s5,72(sp)
    80002e6a:	e0da                	sd	s6,64(sp)
    80002e6c:	fc5e                	sd	s7,56(sp)
    80002e6e:	f862                	sd	s8,48(sp)
    80002e70:	f466                	sd	s9,40(sp)
    80002e72:	f06a                	sd	s10,32(sp)
    80002e74:	ec6e                	sd	s11,24(sp)
    80002e76:	0100                	addi	s0,sp,128
    80002e78:	892a                	mv	s2,a0
  struct cpu *c;
  struct proc *p;
  struct _list *lst;
  int stolen_process;
  int succeed = 0;
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002e7a:	0000e497          	auipc	s1,0xe
    80002e7e:	42648493          	addi	s1,s1,1062 # 800112a0 <cpus>
    80002e82:	4a91                	li	s5,4
      if(c->cpu_id != curr_c->cpu_id){
        lst = &c->runnable_list;
        acquire(&lst->head_lock);
        if(!isEmpty(lst)){ 
    80002e84:	5c7d                	li	s8,-1
          stolen_process = lst->head;
          p = &proc[stolen_process];
    80002e86:	19000d93          	li	s11,400
    80002e8a:	0000fd17          	auipc	s10,0xf
    80002e8e:	9c6d0d13          	addi	s10,s10,-1594 # 80011850 <proc>
          acquire(&p->lock);
          if(!isEmpty(lst) && lst->head == stolen_process){ // p is still the head
            remove_head_from_list(lst);
            insert_proc_to_list(&curr_c->runnable_list, p);
    80002e92:	08050793          	addi	a5,a0,128
    80002e96:	f8f43023          	sd	a5,-128(s0)
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002e9a:	0000fb97          	auipc	s7,0xf
    80002e9e:	986b8b93          	addi	s7,s7,-1658 # 80011820 <pid_lock>
    80002ea2:	a815                	j	80002ed6 <steal_process+0x7c>
        acquire(&lst->head_lock);
    80002ea4:	f8943423          	sd	s1,-120(s0)
    80002ea8:	08848993          	addi	s3,s1,136
    80002eac:	854e                	mv	a0,s3
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d36080e7          	jalr	-714(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002eb6:	0804aa03          	lw	s4,128(s1)
    80002eba:	4b01                	li	s6,0
        if(!isEmpty(lst)){ 
    80002ebc:	038a1863          	bne	s4,s8,80002eec <steal_process+0x92>
            increment_cpu_process_count(curr_c); 
            succeed = 1;
          }
          release(&p->lock);
        }
        release(&lst->head_lock);
    80002ec0:	854e                	mv	a0,s3
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	dd6080e7          	jalr	-554(ra) # 80000c98 <release>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002eca:	0b048493          	addi	s1,s1,176
    80002ece:	060b1d63          	bnez	s6,80002f48 <steal_process+0xee>
    80002ed2:	07748b63          	beq	s1,s7,80002f48 <steal_process+0xee>
    80002ed6:	0a04a783          	lw	a5,160(s1)
    80002eda:	06fac763          	blt	s5,a5,80002f48 <steal_process+0xee>
      if(c->cpu_id != curr_c->cpu_id){
    80002ede:	0a092703          	lw	a4,160(s2)
    80002ee2:	fcf711e3          	bne	a4,a5,80002ea4 <steal_process+0x4a>
  for(c = cpus; !succeed && c < &cpus[NCPU] && c != NULL && c->cpu_id < CPUS ; c++){
    80002ee6:	0b048493          	addi	s1,s1,176
    80002eea:	b7e5                	j	80002ed2 <steal_process+0x78>
          p = &proc[stolen_process];
    80002eec:	03ba0cb3          	mul	s9,s4,s11
    80002ef0:	9cea                	add	s9,s9,s10
          acquire(&p->lock);
    80002ef2:	8566                	mv	a0,s9
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	cf0080e7          	jalr	-784(ra) # 80000be4 <acquire>
  return lst->head == -1;
    80002efc:	0804a783          	lw	a5,128(s1)
          if(!isEmpty(lst) && lst->head == stolen_process){ // p is still the head
    80002f00:	01878463          	beq	a5,s8,80002f08 <steal_process+0xae>
    80002f04:	00fa0863          	beq	s4,a5,80002f14 <steal_process+0xba>
          release(&p->lock);
    80002f08:	8566                	mv	a0,s9
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	d8e080e7          	jalr	-626(ra) # 80000c98 <release>
    80002f12:	b77d                	j	80002ec0 <steal_process+0x66>
            remove_head_from_list(lst);
    80002f14:	f8843783          	ld	a5,-120(s0)
    80002f18:	08078513          	addi	a0,a5,128
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	c2c080e7          	jalr	-980(ra) # 80001b48 <remove_head_from_list>
            insert_proc_to_list(&curr_c->runnable_list, p);
    80002f24:	85e6                	mv	a1,s9
    80002f26:	f8043503          	ld	a0,-128(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	b32080e7          	jalr	-1230(ra) # 80001a5c <insert_proc_to_list>
            p->last_cpu = curr_c->cpu_id;
    80002f32:	0a092703          	lw	a4,160(s2)
    80002f36:	16eca423          	sw	a4,360(s9)
            increment_cpu_process_count(curr_c); 
    80002f3a:	854a                	mv	a0,s2
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	b34080e7          	jalr	-1228(ra) # 80002a70 <increment_cpu_process_count>
            succeed = 1;
    80002f44:	4b05                	li	s6,1
    80002f46:	b7c9                	j	80002f08 <steal_process+0xae>
      }
  }
    80002f48:	70e6                	ld	ra,120(sp)
    80002f4a:	7446                	ld	s0,112(sp)
    80002f4c:	74a6                	ld	s1,104(sp)
    80002f4e:	7906                	ld	s2,96(sp)
    80002f50:	69e6                	ld	s3,88(sp)
    80002f52:	6a46                	ld	s4,80(sp)
    80002f54:	6aa6                	ld	s5,72(sp)
    80002f56:	6b06                	ld	s6,64(sp)
    80002f58:	7be2                	ld	s7,56(sp)
    80002f5a:	7c42                	ld	s8,48(sp)
    80002f5c:	7ca2                	ld	s9,40(sp)
    80002f5e:	7d02                	ld	s10,32(sp)
    80002f60:	6de2                	ld	s11,24(sp)
    80002f62:	6109                	addi	sp,sp,128
    80002f64:	8082                	ret

0000000080002f66 <swtch>:
    80002f66:	00153023          	sd	ra,0(a0)
    80002f6a:	00253423          	sd	sp,8(a0)
    80002f6e:	e900                	sd	s0,16(a0)
    80002f70:	ed04                	sd	s1,24(a0)
    80002f72:	03253023          	sd	s2,32(a0)
    80002f76:	03353423          	sd	s3,40(a0)
    80002f7a:	03453823          	sd	s4,48(a0)
    80002f7e:	03553c23          	sd	s5,56(a0)
    80002f82:	05653023          	sd	s6,64(a0)
    80002f86:	05753423          	sd	s7,72(a0)
    80002f8a:	05853823          	sd	s8,80(a0)
    80002f8e:	05953c23          	sd	s9,88(a0)
    80002f92:	07a53023          	sd	s10,96(a0)
    80002f96:	07b53423          	sd	s11,104(a0)
    80002f9a:	0005b083          	ld	ra,0(a1)
    80002f9e:	0085b103          	ld	sp,8(a1)
    80002fa2:	6980                	ld	s0,16(a1)
    80002fa4:	6d84                	ld	s1,24(a1)
    80002fa6:	0205b903          	ld	s2,32(a1)
    80002faa:	0285b983          	ld	s3,40(a1)
    80002fae:	0305ba03          	ld	s4,48(a1)
    80002fb2:	0385ba83          	ld	s5,56(a1)
    80002fb6:	0405bb03          	ld	s6,64(a1)
    80002fba:	0485bb83          	ld	s7,72(a1)
    80002fbe:	0505bc03          	ld	s8,80(a1)
    80002fc2:	0585bc83          	ld	s9,88(a1)
    80002fc6:	0605bd03          	ld	s10,96(a1)
    80002fca:	0685bd83          	ld	s11,104(a1)
    80002fce:	8082                	ret

0000000080002fd0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002fd0:	1141                	addi	sp,sp,-16
    80002fd2:	e406                	sd	ra,8(sp)
    80002fd4:	e022                	sd	s0,0(sp)
    80002fd6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002fd8:	00005597          	auipc	a1,0x5
    80002fdc:	48058593          	addi	a1,a1,1152 # 80008458 <states.1826+0x30>
    80002fe0:	00015517          	auipc	a0,0x15
    80002fe4:	c7050513          	addi	a0,a0,-912 # 80017c50 <tickslock>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	b6c080e7          	jalr	-1172(ra) # 80000b54 <initlock>
}
    80002ff0:	60a2                	ld	ra,8(sp)
    80002ff2:	6402                	ld	s0,0(sp)
    80002ff4:	0141                	addi	sp,sp,16
    80002ff6:	8082                	ret

0000000080002ff8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ff8:	1141                	addi	sp,sp,-16
    80002ffa:	e422                	sd	s0,8(sp)
    80002ffc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ffe:	00003797          	auipc	a5,0x3
    80003002:	50278793          	addi	a5,a5,1282 # 80006500 <kernelvec>
    80003006:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000300a:	6422                	ld	s0,8(sp)
    8000300c:	0141                	addi	sp,sp,16
    8000300e:	8082                	ret

0000000080003010 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003010:	1141                	addi	sp,sp,-16
    80003012:	e406                	sd	ra,8(sp)
    80003014:	e022                	sd	s0,0(sp)
    80003016:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	f2e080e7          	jalr	-210(ra) # 80001f46 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003020:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003024:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003026:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000302a:	00004617          	auipc	a2,0x4
    8000302e:	fd660613          	addi	a2,a2,-42 # 80007000 <_trampoline>
    80003032:	00004697          	auipc	a3,0x4
    80003036:	fce68693          	addi	a3,a3,-50 # 80007000 <_trampoline>
    8000303a:	8e91                	sub	a3,a3,a2
    8000303c:	040007b7          	lui	a5,0x4000
    80003040:	17fd                	addi	a5,a5,-1
    80003042:	07b2                	slli	a5,a5,0xc
    80003044:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003046:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000304a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000304c:	180026f3          	csrr	a3,satp
    80003050:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003052:	6d38                	ld	a4,88(a0)
    80003054:	6134                	ld	a3,64(a0)
    80003056:	6585                	lui	a1,0x1
    80003058:	96ae                	add	a3,a3,a1
    8000305a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000305c:	6d38                	ld	a4,88(a0)
    8000305e:	00000697          	auipc	a3,0x0
    80003062:	13868693          	addi	a3,a3,312 # 80003196 <usertrap>
    80003066:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003068:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000306a:	8692                	mv	a3,tp
    8000306c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000306e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003072:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003076:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000307a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000307e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003080:	6f18                	ld	a4,24(a4)
    80003082:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003086:	692c                	ld	a1,80(a0)
    80003088:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000308a:	00004717          	auipc	a4,0x4
    8000308e:	00670713          	addi	a4,a4,6 # 80007090 <userret>
    80003092:	8f11                	sub	a4,a4,a2
    80003094:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003096:	577d                	li	a4,-1
    80003098:	177e                	slli	a4,a4,0x3f
    8000309a:	8dd9                	or	a1,a1,a4
    8000309c:	02000537          	lui	a0,0x2000
    800030a0:	157d                	addi	a0,a0,-1
    800030a2:	0536                	slli	a0,a0,0xd
    800030a4:	9782                	jalr	a5
}
    800030a6:	60a2                	ld	ra,8(sp)
    800030a8:	6402                	ld	s0,0(sp)
    800030aa:	0141                	addi	sp,sp,16
    800030ac:	8082                	ret

00000000800030ae <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800030b8:	00015497          	auipc	s1,0x15
    800030bc:	b9848493          	addi	s1,s1,-1128 # 80017c50 <tickslock>
    800030c0:	8526                	mv	a0,s1
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	b22080e7          	jalr	-1246(ra) # 80000be4 <acquire>
  ticks++;
    800030ca:	00006517          	auipc	a0,0x6
    800030ce:	f6650513          	addi	a0,a0,-154 # 80009030 <ticks>
    800030d2:	411c                	lw	a5,0(a0)
    800030d4:	2785                	addiw	a5,a5,1
    800030d6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800030d8:	00000097          	auipc	ra,0x0
    800030dc:	b4c080e7          	jalr	-1204(ra) # 80002c24 <wakeup>
  release(&tickslock);
    800030e0:	8526                	mv	a0,s1
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	bb6080e7          	jalr	-1098(ra) # 80000c98 <release>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret

00000000800030f4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800030f4:	1101                	addi	sp,sp,-32
    800030f6:	ec06                	sd	ra,24(sp)
    800030f8:	e822                	sd	s0,16(sp)
    800030fa:	e426                	sd	s1,8(sp)
    800030fc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030fe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003102:	00074d63          	bltz	a4,8000311c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003106:	57fd                	li	a5,-1
    80003108:	17fe                	slli	a5,a5,0x3f
    8000310a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000310c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000310e:	06f70363          	beq	a4,a5,80003174 <devintr+0x80>
  }
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	64a2                	ld	s1,8(sp)
    80003118:	6105                	addi	sp,sp,32
    8000311a:	8082                	ret
     (scause & 0xff) == 9){
    8000311c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003120:	46a5                	li	a3,9
    80003122:	fed792e3          	bne	a5,a3,80003106 <devintr+0x12>
    int irq = plic_claim();
    80003126:	00003097          	auipc	ra,0x3
    8000312a:	4e2080e7          	jalr	1250(ra) # 80006608 <plic_claim>
    8000312e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003130:	47a9                	li	a5,10
    80003132:	02f50763          	beq	a0,a5,80003160 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003136:	4785                	li	a5,1
    80003138:	02f50963          	beq	a0,a5,8000316a <devintr+0x76>
    return 1;
    8000313c:	4505                	li	a0,1
    } else if(irq){
    8000313e:	d8f1                	beqz	s1,80003112 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003140:	85a6                	mv	a1,s1
    80003142:	00005517          	auipc	a0,0x5
    80003146:	31e50513          	addi	a0,a0,798 # 80008460 <states.1826+0x38>
    8000314a:	ffffd097          	auipc	ra,0xffffd
    8000314e:	43e080e7          	jalr	1086(ra) # 80000588 <printf>
      plic_complete(irq);
    80003152:	8526                	mv	a0,s1
    80003154:	00003097          	auipc	ra,0x3
    80003158:	4d8080e7          	jalr	1240(ra) # 8000662c <plic_complete>
    return 1;
    8000315c:	4505                	li	a0,1
    8000315e:	bf55                	j	80003112 <devintr+0x1e>
      uartintr();
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	848080e7          	jalr	-1976(ra) # 800009a8 <uartintr>
    80003168:	b7ed                	j	80003152 <devintr+0x5e>
      virtio_disk_intr();
    8000316a:	00004097          	auipc	ra,0x4
    8000316e:	9a2080e7          	jalr	-1630(ra) # 80006b0c <virtio_disk_intr>
    80003172:	b7c5                	j	80003152 <devintr+0x5e>
    if(cpuid() == 0){
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	da0080e7          	jalr	-608(ra) # 80001f14 <cpuid>
    8000317c:	c901                	beqz	a0,8000318c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000317e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003182:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003184:	14479073          	csrw	sip,a5
    return 2;
    80003188:	4509                	li	a0,2
    8000318a:	b761                	j	80003112 <devintr+0x1e>
      clockintr();
    8000318c:	00000097          	auipc	ra,0x0
    80003190:	f22080e7          	jalr	-222(ra) # 800030ae <clockintr>
    80003194:	b7ed                	j	8000317e <devintr+0x8a>

0000000080003196 <usertrap>:
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800031a6:	1007f793          	andi	a5,a5,256
    800031aa:	e3ad                	bnez	a5,8000320c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800031ac:	00003797          	auipc	a5,0x3
    800031b0:	35478793          	addi	a5,a5,852 # 80006500 <kernelvec>
    800031b4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	d8e080e7          	jalr	-626(ra) # 80001f46 <myproc>
    800031c0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800031c2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031c4:	14102773          	csrr	a4,sepc
    800031c8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031ca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800031ce:	47a1                	li	a5,8
    800031d0:	04f71c63          	bne	a4,a5,80003228 <usertrap+0x92>
    if(p->killed)
    800031d4:	551c                	lw	a5,40(a0)
    800031d6:	e3b9                	bnez	a5,8000321c <usertrap+0x86>
    p->trapframe->epc += 4;
    800031d8:	6cb8                	ld	a4,88(s1)
    800031da:	6f1c                	ld	a5,24(a4)
    800031dc:	0791                	addi	a5,a5,4
    800031de:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800031e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031e8:	10079073          	csrw	sstatus,a5
    syscall();
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	2e0080e7          	jalr	736(ra) # 800034cc <syscall>
  if(p->killed)
    800031f4:	549c                	lw	a5,40(s1)
    800031f6:	ebc1                	bnez	a5,80003286 <usertrap+0xf0>
  usertrapret();
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	e18080e7          	jalr	-488(ra) # 80003010 <usertrapret>
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	64a2                	ld	s1,8(sp)
    80003206:	6902                	ld	s2,0(sp)
    80003208:	6105                	addi	sp,sp,32
    8000320a:	8082                	ret
    panic("usertrap: not from user mode");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	27450513          	addi	a0,a0,628 # 80008480 <states.1826+0x58>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	32a080e7          	jalr	810(ra) # 8000053e <panic>
      exit(-1);
    8000321c:	557d                	li	a0,-1
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	b54080e7          	jalr	-1196(ra) # 80002d72 <exit>
    80003226:	bf4d                	j	800031d8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	ecc080e7          	jalr	-308(ra) # 800030f4 <devintr>
    80003230:	892a                	mv	s2,a0
    80003232:	c501                	beqz	a0,8000323a <usertrap+0xa4>
  if(p->killed)
    80003234:	549c                	lw	a5,40(s1)
    80003236:	c3a1                	beqz	a5,80003276 <usertrap+0xe0>
    80003238:	a815                	j	8000326c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000323a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000323e:	5890                	lw	a2,48(s1)
    80003240:	00005517          	auipc	a0,0x5
    80003244:	26050513          	addi	a0,a0,608 # 800084a0 <states.1826+0x78>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	340080e7          	jalr	832(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003250:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003254:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003258:	00005517          	auipc	a0,0x5
    8000325c:	27850513          	addi	a0,a0,632 # 800084d0 <states.1826+0xa8>
    80003260:	ffffd097          	auipc	ra,0xffffd
    80003264:	328080e7          	jalr	808(ra) # 80000588 <printf>
    p->killed = 1;
    80003268:	4785                	li	a5,1
    8000326a:	d49c                	sw	a5,40(s1)
    exit(-1);
    8000326c:	557d                	li	a0,-1
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	b04080e7          	jalr	-1276(ra) # 80002d72 <exit>
  if(which_dev == 2)
    80003276:	4789                	li	a5,2
    80003278:	f8f910e3          	bne	s2,a5,800031f8 <usertrap+0x62>
    yield();
    8000327c:	fffff097          	auipc	ra,0xfffff
    80003280:	312080e7          	jalr	786(ra) # 8000258e <yield>
    80003284:	bf95                	j	800031f8 <usertrap+0x62>
  int which_dev = 0;
    80003286:	4901                	li	s2,0
    80003288:	b7d5                	j	8000326c <usertrap+0xd6>

000000008000328a <kerneltrap>:
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	e84a                	sd	s2,16(sp)
    80003294:	e44e                	sd	s3,8(sp)
    80003296:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003298:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000329c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800032a0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800032a4:	1004f793          	andi	a5,s1,256
    800032a8:	cb85                	beqz	a5,800032d8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032ae:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800032b0:	ef85                	bnez	a5,800032e8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	e42080e7          	jalr	-446(ra) # 800030f4 <devintr>
    800032ba:	cd1d                	beqz	a0,800032f8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032bc:	4789                	li	a5,2
    800032be:	06f50a63          	beq	a0,a5,80003332 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032c2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032c6:	10049073          	csrw	sstatus,s1
}
    800032ca:	70a2                	ld	ra,40(sp)
    800032cc:	7402                	ld	s0,32(sp)
    800032ce:	64e2                	ld	s1,24(sp)
    800032d0:	6942                	ld	s2,16(sp)
    800032d2:	69a2                	ld	s3,8(sp)
    800032d4:	6145                	addi	sp,sp,48
    800032d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032d8:	00005517          	auipc	a0,0x5
    800032dc:	21850513          	addi	a0,a0,536 # 800084f0 <states.1826+0xc8>
    800032e0:	ffffd097          	auipc	ra,0xffffd
    800032e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800032e8:	00005517          	auipc	a0,0x5
    800032ec:	23050513          	addi	a0,a0,560 # 80008518 <states.1826+0xf0>
    800032f0:	ffffd097          	auipc	ra,0xffffd
    800032f4:	24e080e7          	jalr	590(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800032f8:	85ce                	mv	a1,s3
    800032fa:	00005517          	auipc	a0,0x5
    800032fe:	23e50513          	addi	a0,a0,574 # 80008538 <states.1826+0x110>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	286080e7          	jalr	646(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000330a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000330e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003312:	00005517          	auipc	a0,0x5
    80003316:	23650513          	addi	a0,a0,566 # 80008548 <states.1826+0x120>
    8000331a:	ffffd097          	auipc	ra,0xffffd
    8000331e:	26e080e7          	jalr	622(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003322:	00005517          	auipc	a0,0x5
    80003326:	23e50513          	addi	a0,a0,574 # 80008560 <states.1826+0x138>
    8000332a:	ffffd097          	auipc	ra,0xffffd
    8000332e:	214080e7          	jalr	532(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003332:	fffff097          	auipc	ra,0xfffff
    80003336:	c14080e7          	jalr	-1004(ra) # 80001f46 <myproc>
    8000333a:	d541                	beqz	a0,800032c2 <kerneltrap+0x38>
    8000333c:	fffff097          	auipc	ra,0xfffff
    80003340:	c0a080e7          	jalr	-1014(ra) # 80001f46 <myproc>
    80003344:	4d18                	lw	a4,24(a0)
    80003346:	4791                	li	a5,4
    80003348:	f6f71de3          	bne	a4,a5,800032c2 <kerneltrap+0x38>
    yield();
    8000334c:	fffff097          	auipc	ra,0xfffff
    80003350:	242080e7          	jalr	578(ra) # 8000258e <yield>
    80003354:	b7bd                	j	800032c2 <kerneltrap+0x38>

0000000080003356 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003356:	1101                	addi	sp,sp,-32
    80003358:	ec06                	sd	ra,24(sp)
    8000335a:	e822                	sd	s0,16(sp)
    8000335c:	e426                	sd	s1,8(sp)
    8000335e:	1000                	addi	s0,sp,32
    80003360:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	be4080e7          	jalr	-1052(ra) # 80001f46 <myproc>
  switch (n) {
    8000336a:	4795                	li	a5,5
    8000336c:	0497e163          	bltu	a5,s1,800033ae <argraw+0x58>
    80003370:	048a                	slli	s1,s1,0x2
    80003372:	00005717          	auipc	a4,0x5
    80003376:	22670713          	addi	a4,a4,550 # 80008598 <states.1826+0x170>
    8000337a:	94ba                	add	s1,s1,a4
    8000337c:	409c                	lw	a5,0(s1)
    8000337e:	97ba                	add	a5,a5,a4
    80003380:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003382:	6d3c                	ld	a5,88(a0)
    80003384:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003386:	60e2                	ld	ra,24(sp)
    80003388:	6442                	ld	s0,16(sp)
    8000338a:	64a2                	ld	s1,8(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    return p->trapframe->a1;
    80003390:	6d3c                	ld	a5,88(a0)
    80003392:	7fa8                	ld	a0,120(a5)
    80003394:	bfcd                	j	80003386 <argraw+0x30>
    return p->trapframe->a2;
    80003396:	6d3c                	ld	a5,88(a0)
    80003398:	63c8                	ld	a0,128(a5)
    8000339a:	b7f5                	j	80003386 <argraw+0x30>
    return p->trapframe->a3;
    8000339c:	6d3c                	ld	a5,88(a0)
    8000339e:	67c8                	ld	a0,136(a5)
    800033a0:	b7dd                	j	80003386 <argraw+0x30>
    return p->trapframe->a4;
    800033a2:	6d3c                	ld	a5,88(a0)
    800033a4:	6bc8                	ld	a0,144(a5)
    800033a6:	b7c5                	j	80003386 <argraw+0x30>
    return p->trapframe->a5;
    800033a8:	6d3c                	ld	a5,88(a0)
    800033aa:	6fc8                	ld	a0,152(a5)
    800033ac:	bfe9                	j	80003386 <argraw+0x30>
  panic("argraw");
    800033ae:	00005517          	auipc	a0,0x5
    800033b2:	1c250513          	addi	a0,a0,450 # 80008570 <states.1826+0x148>
    800033b6:	ffffd097          	auipc	ra,0xffffd
    800033ba:	188080e7          	jalr	392(ra) # 8000053e <panic>

00000000800033be <fetchaddr>:
{
    800033be:	1101                	addi	sp,sp,-32
    800033c0:	ec06                	sd	ra,24(sp)
    800033c2:	e822                	sd	s0,16(sp)
    800033c4:	e426                	sd	s1,8(sp)
    800033c6:	e04a                	sd	s2,0(sp)
    800033c8:	1000                	addi	s0,sp,32
    800033ca:	84aa                	mv	s1,a0
    800033cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033ce:	fffff097          	auipc	ra,0xfffff
    800033d2:	b78080e7          	jalr	-1160(ra) # 80001f46 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033d6:	653c                	ld	a5,72(a0)
    800033d8:	02f4f863          	bgeu	s1,a5,80003408 <fetchaddr+0x4a>
    800033dc:	00848713          	addi	a4,s1,8
    800033e0:	02e7e663          	bltu	a5,a4,8000340c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033e4:	46a1                	li	a3,8
    800033e6:	8626                	mv	a2,s1
    800033e8:	85ca                	mv	a1,s2
    800033ea:	6928                	ld	a0,80(a0)
    800033ec:	ffffe097          	auipc	ra,0xffffe
    800033f0:	312080e7          	jalr	786(ra) # 800016fe <copyin>
    800033f4:	00a03533          	snez	a0,a0
    800033f8:	40a00533          	neg	a0,a0
}
    800033fc:	60e2                	ld	ra,24(sp)
    800033fe:	6442                	ld	s0,16(sp)
    80003400:	64a2                	ld	s1,8(sp)
    80003402:	6902                	ld	s2,0(sp)
    80003404:	6105                	addi	sp,sp,32
    80003406:	8082                	ret
    return -1;
    80003408:	557d                	li	a0,-1
    8000340a:	bfcd                	j	800033fc <fetchaddr+0x3e>
    8000340c:	557d                	li	a0,-1
    8000340e:	b7fd                	j	800033fc <fetchaddr+0x3e>

0000000080003410 <fetchstr>:
{
    80003410:	7179                	addi	sp,sp,-48
    80003412:	f406                	sd	ra,40(sp)
    80003414:	f022                	sd	s0,32(sp)
    80003416:	ec26                	sd	s1,24(sp)
    80003418:	e84a                	sd	s2,16(sp)
    8000341a:	e44e                	sd	s3,8(sp)
    8000341c:	1800                	addi	s0,sp,48
    8000341e:	892a                	mv	s2,a0
    80003420:	84ae                	mv	s1,a1
    80003422:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003424:	fffff097          	auipc	ra,0xfffff
    80003428:	b22080e7          	jalr	-1246(ra) # 80001f46 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000342c:	86ce                	mv	a3,s3
    8000342e:	864a                	mv	a2,s2
    80003430:	85a6                	mv	a1,s1
    80003432:	6928                	ld	a0,80(a0)
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	356080e7          	jalr	854(ra) # 8000178a <copyinstr>
  if(err < 0)
    8000343c:	00054763          	bltz	a0,8000344a <fetchstr+0x3a>
  return strlen(buf);
    80003440:	8526                	mv	a0,s1
    80003442:	ffffe097          	auipc	ra,0xffffe
    80003446:	a22080e7          	jalr	-1502(ra) # 80000e64 <strlen>
}
    8000344a:	70a2                	ld	ra,40(sp)
    8000344c:	7402                	ld	s0,32(sp)
    8000344e:	64e2                	ld	s1,24(sp)
    80003450:	6942                	ld	s2,16(sp)
    80003452:	69a2                	ld	s3,8(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret

0000000080003458 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003458:	1101                	addi	sp,sp,-32
    8000345a:	ec06                	sd	ra,24(sp)
    8000345c:	e822                	sd	s0,16(sp)
    8000345e:	e426                	sd	s1,8(sp)
    80003460:	1000                	addi	s0,sp,32
    80003462:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003464:	00000097          	auipc	ra,0x0
    80003468:	ef2080e7          	jalr	-270(ra) # 80003356 <argraw>
    8000346c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000346e:	4501                	li	a0,0
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret

000000008000347a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	e426                	sd	s1,8(sp)
    80003482:	1000                	addi	s0,sp,32
    80003484:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	ed0080e7          	jalr	-304(ra) # 80003356 <argraw>
    8000348e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003490:	4501                	li	a0,0
    80003492:	60e2                	ld	ra,24(sp)
    80003494:	6442                	ld	s0,16(sp)
    80003496:	64a2                	ld	s1,8(sp)
    80003498:	6105                	addi	sp,sp,32
    8000349a:	8082                	ret

000000008000349c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000349c:	1101                	addi	sp,sp,-32
    8000349e:	ec06                	sd	ra,24(sp)
    800034a0:	e822                	sd	s0,16(sp)
    800034a2:	e426                	sd	s1,8(sp)
    800034a4:	e04a                	sd	s2,0(sp)
    800034a6:	1000                	addi	s0,sp,32
    800034a8:	84ae                	mv	s1,a1
    800034aa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	eaa080e7          	jalr	-342(ra) # 80003356 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034b4:	864a                	mv	a2,s2
    800034b6:	85a6                	mv	a1,s1
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	f58080e7          	jalr	-168(ra) # 80003410 <fetchstr>
}
    800034c0:	60e2                	ld	ra,24(sp)
    800034c2:	6442                	ld	s0,16(sp)
    800034c4:	64a2                	ld	s1,8(sp)
    800034c6:	6902                	ld	s2,0(sp)
    800034c8:	6105                	addi	sp,sp,32
    800034ca:	8082                	ret

00000000800034cc <syscall>:
[SYS_cpu_process_count]   sys_cpu_process_count,
};

void
syscall(void)
{
    800034cc:	1101                	addi	sp,sp,-32
    800034ce:	ec06                	sd	ra,24(sp)
    800034d0:	e822                	sd	s0,16(sp)
    800034d2:	e426                	sd	s1,8(sp)
    800034d4:	e04a                	sd	s2,0(sp)
    800034d6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034d8:	fffff097          	auipc	ra,0xfffff
    800034dc:	a6e080e7          	jalr	-1426(ra) # 80001f46 <myproc>
    800034e0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034e2:	05853903          	ld	s2,88(a0)
    800034e6:	0a893783          	ld	a5,168(s2)
    800034ea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034ee:	37fd                	addiw	a5,a5,-1
    800034f0:	475d                	li	a4,23
    800034f2:	00f76f63          	bltu	a4,a5,80003510 <syscall+0x44>
    800034f6:	00369713          	slli	a4,a3,0x3
    800034fa:	00005797          	auipc	a5,0x5
    800034fe:	0b678793          	addi	a5,a5,182 # 800085b0 <syscalls>
    80003502:	97ba                	add	a5,a5,a4
    80003504:	639c                	ld	a5,0(a5)
    80003506:	c789                	beqz	a5,80003510 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003508:	9782                	jalr	a5
    8000350a:	06a93823          	sd	a0,112(s2)
    8000350e:	a839                	j	8000352c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003510:	15848613          	addi	a2,s1,344
    80003514:	588c                	lw	a1,48(s1)
    80003516:	00005517          	auipc	a0,0x5
    8000351a:	06250513          	addi	a0,a0,98 # 80008578 <states.1826+0x150>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	06a080e7          	jalr	106(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003526:	6cbc                	ld	a5,88(s1)
    80003528:	577d                	li	a4,-1
    8000352a:	fbb8                	sd	a4,112(a5)
  }
}
    8000352c:	60e2                	ld	ra,24(sp)
    8000352e:	6442                	ld	s0,16(sp)
    80003530:	64a2                	ld	s1,8(sp)
    80003532:	6902                	ld	s2,0(sp)
    80003534:	6105                	addi	sp,sp,32
    80003536:	8082                	ret

0000000080003538 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003538:	1101                	addi	sp,sp,-32
    8000353a:	ec06                	sd	ra,24(sp)
    8000353c:	e822                	sd	s0,16(sp)
    8000353e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003540:	fec40593          	addi	a1,s0,-20
    80003544:	4501                	li	a0,0
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	f12080e7          	jalr	-238(ra) # 80003458 <argint>
    return -1;
    8000354e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003550:	00054963          	bltz	a0,80003562 <sys_exit+0x2a>
  exit(n);
    80003554:	fec42503          	lw	a0,-20(s0)
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	81a080e7          	jalr	-2022(ra) # 80002d72 <exit>
  return 0;  // not reached
    80003560:	4781                	li	a5,0
}
    80003562:	853e                	mv	a0,a5
    80003564:	60e2                	ld	ra,24(sp)
    80003566:	6442                	ld	s0,16(sp)
    80003568:	6105                	addi	sp,sp,32
    8000356a:	8082                	ret

000000008000356c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000356c:	1141                	addi	sp,sp,-16
    8000356e:	e406                	sd	ra,8(sp)
    80003570:	e022                	sd	s0,0(sp)
    80003572:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003574:	fffff097          	auipc	ra,0xfffff
    80003578:	9d2080e7          	jalr	-1582(ra) # 80001f46 <myproc>
}
    8000357c:	5908                	lw	a0,48(a0)
    8000357e:	60a2                	ld	ra,8(sp)
    80003580:	6402                	ld	s0,0(sp)
    80003582:	0141                	addi	sp,sp,16
    80003584:	8082                	ret

0000000080003586 <sys_fork>:

uint64
sys_fork(void)
{
    80003586:	1141                	addi	sp,sp,-16
    80003588:	e406                	sd	ra,8(sp)
    8000358a:	e022                	sd	s0,0(sp)
    8000358c:	0800                	addi	s0,sp,16
  return fork();
    8000358e:	fffff097          	auipc	ra,0xfffff
    80003592:	516080e7          	jalr	1302(ra) # 80002aa4 <fork>
}
    80003596:	60a2                	ld	ra,8(sp)
    80003598:	6402                	ld	s0,0(sp)
    8000359a:	0141                	addi	sp,sp,16
    8000359c:	8082                	ret

000000008000359e <sys_wait>:

uint64
sys_wait(void)
{
    8000359e:	1101                	addi	sp,sp,-32
    800035a0:	ec06                	sd	ra,24(sp)
    800035a2:	e822                	sd	s0,16(sp)
    800035a4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800035a6:	fe840593          	addi	a1,s0,-24
    800035aa:	4501                	li	a0,0
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	ece080e7          	jalr	-306(ra) # 8000347a <argaddr>
    800035b4:	87aa                	mv	a5,a0
    return -1;
    800035b6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035b8:	0007c863          	bltz	a5,800035c8 <sys_wait+0x2a>
  return wait(p);
    800035bc:	fe843503          	ld	a0,-24(s0)
    800035c0:	fffff097          	auipc	ra,0xfffff
    800035c4:	0a4080e7          	jalr	164(ra) # 80002664 <wait>
}
    800035c8:	60e2                	ld	ra,24(sp)
    800035ca:	6442                	ld	s0,16(sp)
    800035cc:	6105                	addi	sp,sp,32
    800035ce:	8082                	ret

00000000800035d0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035da:	fdc40593          	addi	a1,s0,-36
    800035de:	4501                	li	a0,0
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	e78080e7          	jalr	-392(ra) # 80003458 <argint>
    800035e8:	87aa                	mv	a5,a0
    return -1;
    800035ea:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800035ec:	0207c063          	bltz	a5,8000360c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800035f0:	fffff097          	auipc	ra,0xfffff
    800035f4:	956080e7          	jalr	-1706(ra) # 80001f46 <myproc>
    800035f8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035fa:	fdc42503          	lw	a0,-36(s0)
    800035fe:	fffff097          	auipc	ra,0xfffff
    80003602:	d68080e7          	jalr	-664(ra) # 80002366 <growproc>
    80003606:	00054863          	bltz	a0,80003616 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000360a:	8526                	mv	a0,s1
}
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6145                	addi	sp,sp,48
    80003614:	8082                	ret
    return -1;
    80003616:	557d                	li	a0,-1
    80003618:	bfd5                	j	8000360c <sys_sbrk+0x3c>

000000008000361a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000361a:	7139                	addi	sp,sp,-64
    8000361c:	fc06                	sd	ra,56(sp)
    8000361e:	f822                	sd	s0,48(sp)
    80003620:	f426                	sd	s1,40(sp)
    80003622:	f04a                	sd	s2,32(sp)
    80003624:	ec4e                	sd	s3,24(sp)
    80003626:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003628:	fcc40593          	addi	a1,s0,-52
    8000362c:	4501                	li	a0,0
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	e2a080e7          	jalr	-470(ra) # 80003458 <argint>
    return -1;
    80003636:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003638:	06054563          	bltz	a0,800036a2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000363c:	00014517          	auipc	a0,0x14
    80003640:	61450513          	addi	a0,a0,1556 # 80017c50 <tickslock>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	5a0080e7          	jalr	1440(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000364c:	00006917          	auipc	s2,0x6
    80003650:	9e492903          	lw	s2,-1564(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003654:	fcc42783          	lw	a5,-52(s0)
    80003658:	cf85                	beqz	a5,80003690 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000365a:	00014997          	auipc	s3,0x14
    8000365e:	5f698993          	addi	s3,s3,1526 # 80017c50 <tickslock>
    80003662:	00006497          	auipc	s1,0x6
    80003666:	9ce48493          	addi	s1,s1,-1586 # 80009030 <ticks>
    if(myproc()->killed){
    8000366a:	fffff097          	auipc	ra,0xfffff
    8000366e:	8dc080e7          	jalr	-1828(ra) # 80001f46 <myproc>
    80003672:	551c                	lw	a5,40(a0)
    80003674:	ef9d                	bnez	a5,800036b2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003676:	85ce                	mv	a1,s3
    80003678:	8526                	mv	a0,s1
    8000367a:	fffff097          	auipc	ra,0xfffff
    8000367e:	f74080e7          	jalr	-140(ra) # 800025ee <sleep>
  while(ticks - ticks0 < n){
    80003682:	409c                	lw	a5,0(s1)
    80003684:	412787bb          	subw	a5,a5,s2
    80003688:	fcc42703          	lw	a4,-52(s0)
    8000368c:	fce7efe3          	bltu	a5,a4,8000366a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003690:	00014517          	auipc	a0,0x14
    80003694:	5c050513          	addi	a0,a0,1472 # 80017c50 <tickslock>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	600080e7          	jalr	1536(ra) # 80000c98 <release>
  return 0;
    800036a0:	4781                	li	a5,0
}
    800036a2:	853e                	mv	a0,a5
    800036a4:	70e2                	ld	ra,56(sp)
    800036a6:	7442                	ld	s0,48(sp)
    800036a8:	74a2                	ld	s1,40(sp)
    800036aa:	7902                	ld	s2,32(sp)
    800036ac:	69e2                	ld	s3,24(sp)
    800036ae:	6121                	addi	sp,sp,64
    800036b0:	8082                	ret
      release(&tickslock);
    800036b2:	00014517          	auipc	a0,0x14
    800036b6:	59e50513          	addi	a0,a0,1438 # 80017c50 <tickslock>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5de080e7          	jalr	1502(ra) # 80000c98 <release>
      return -1;
    800036c2:	57fd                	li	a5,-1
    800036c4:	bff9                	j	800036a2 <sys_sleep+0x88>

00000000800036c6 <sys_kill>:

uint64
sys_kill(void)
{
    800036c6:	1101                	addi	sp,sp,-32
    800036c8:	ec06                	sd	ra,24(sp)
    800036ca:	e822                	sd	s0,16(sp)
    800036cc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036ce:	fec40593          	addi	a1,s0,-20
    800036d2:	4501                	li	a0,0
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	d84080e7          	jalr	-636(ra) # 80003458 <argint>
    800036dc:	87aa                	mv	a5,a0
    return -1;
    800036de:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036e0:	0007c863          	bltz	a5,800036f0 <sys_kill+0x2a>
  return kill(pid);
    800036e4:	fec42503          	lw	a0,-20(s0)
    800036e8:	fffff097          	auipc	ra,0xfffff
    800036ec:	0a4080e7          	jalr	164(ra) # 8000278c <kill>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	6105                	addi	sp,sp,32
    800036f6:	8082                	ret

00000000800036f8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036f8:	1101                	addi	sp,sp,-32
    800036fa:	ec06                	sd	ra,24(sp)
    800036fc:	e822                	sd	s0,16(sp)
    800036fe:	e426                	sd	s1,8(sp)
    80003700:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003702:	00014517          	auipc	a0,0x14
    80003706:	54e50513          	addi	a0,a0,1358 # 80017c50 <tickslock>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	4da080e7          	jalr	1242(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003712:	00006497          	auipc	s1,0x6
    80003716:	91e4a483          	lw	s1,-1762(s1) # 80009030 <ticks>
  release(&tickslock);
    8000371a:	00014517          	auipc	a0,0x14
    8000371e:	53650513          	addi	a0,a0,1334 # 80017c50 <tickslock>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	576080e7          	jalr	1398(ra) # 80000c98 <release>
  return xticks;
}
    8000372a:	02049513          	slli	a0,s1,0x20
    8000372e:	9101                	srli	a0,a0,0x20
    80003730:	60e2                	ld	ra,24(sp)
    80003732:	6442                	ld	s0,16(sp)
    80003734:	64a2                	ld	s1,8(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    80003742:	fec40593          	addi	a1,s0,-20
    80003746:	4501                	li	a0,0
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	d10080e7          	jalr	-752(ra) # 80003458 <argint>
    80003750:	87aa                	mv	a5,a0
    return -1;
    80003752:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    80003754:	0007c863          	bltz	a5,80003764 <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003758:	fec42503          	lw	a0,-20(s0)
    8000375c:	fffff097          	auipc	ra,0xfffff
    80003760:	22e080e7          	jalr	558(ra) # 8000298a <set_cpu>
}
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	6105                	addi	sp,sp,32
    8000376a:	8082                	ret

000000008000376c <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    8000376c:	1141                	addi	sp,sp,-16
    8000376e:	e406                	sd	ra,8(sp)
    80003770:	e022                	sd	s0,0(sp)
    80003772:	0800                	addi	s0,sp,16
  return get_cpu();
    80003774:	fffff097          	auipc	ra,0xfffff
    80003778:	268080e7          	jalr	616(ra) # 800029dc <get_cpu>
}
    8000377c:	60a2                	ld	ra,8(sp)
    8000377e:	6402                	ld	s0,0(sp)
    80003780:	0141                	addi	sp,sp,16
    80003782:	8082                	ret

0000000080003784 <sys_cpu_process_count>:

uint64
sys_cpu_process_count(void)
{
    80003784:	1101                	addi	sp,sp,-32
    80003786:	ec06                	sd	ra,24(sp)
    80003788:	e822                	sd	s0,16(sp)
    8000378a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000378c:	fec40593          	addi	a1,s0,-20
    80003790:	4501                	li	a0,0
    80003792:	00000097          	auipc	ra,0x0
    80003796:	cc6080e7          	jalr	-826(ra) # 80003458 <argint>
    8000379a:	87aa                	mv	a5,a0
    return -1;
    8000379c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000379e:	0007c863          	bltz	a5,800037ae <sys_cpu_process_count+0x2a>
  return cpu_process_count(cpu_id);
    800037a2:	fec42503          	lw	a0,-20(s0)
    800037a6:	fffff097          	auipc	ra,0xfffff
    800037aa:	29a080e7          	jalr	666(ra) # 80002a40 <cpu_process_count>
}
    800037ae:	60e2                	ld	ra,24(sp)
    800037b0:	6442                	ld	s0,16(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800037b6:	7179                	addi	sp,sp,-48
    800037b8:	f406                	sd	ra,40(sp)
    800037ba:	f022                	sd	s0,32(sp)
    800037bc:	ec26                	sd	s1,24(sp)
    800037be:	e84a                	sd	s2,16(sp)
    800037c0:	e44e                	sd	s3,8(sp)
    800037c2:	e052                	sd	s4,0(sp)
    800037c4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800037c6:	00005597          	auipc	a1,0x5
    800037ca:	eb258593          	addi	a1,a1,-334 # 80008678 <syscalls+0xc8>
    800037ce:	00014517          	auipc	a0,0x14
    800037d2:	49a50513          	addi	a0,a0,1178 # 80017c68 <bcache>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	37e080e7          	jalr	894(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800037de:	0001c797          	auipc	a5,0x1c
    800037e2:	48a78793          	addi	a5,a5,1162 # 8001fc68 <bcache+0x8000>
    800037e6:	0001c717          	auipc	a4,0x1c
    800037ea:	6ea70713          	addi	a4,a4,1770 # 8001fed0 <bcache+0x8268>
    800037ee:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800037f2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037f6:	00014497          	auipc	s1,0x14
    800037fa:	48a48493          	addi	s1,s1,1162 # 80017c80 <bcache+0x18>
    b->next = bcache.head.next;
    800037fe:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003800:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003802:	00005a17          	auipc	s4,0x5
    80003806:	e7ea0a13          	addi	s4,s4,-386 # 80008680 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000380a:	2b893783          	ld	a5,696(s2)
    8000380e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003810:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003814:	85d2                	mv	a1,s4
    80003816:	01048513          	addi	a0,s1,16
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	4bc080e7          	jalr	1212(ra) # 80004cd6 <initsleeplock>
    bcache.head.next->prev = b;
    80003822:	2b893783          	ld	a5,696(s2)
    80003826:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003828:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000382c:	45848493          	addi	s1,s1,1112
    80003830:	fd349de3          	bne	s1,s3,8000380a <binit+0x54>
  }
}
    80003834:	70a2                	ld	ra,40(sp)
    80003836:	7402                	ld	s0,32(sp)
    80003838:	64e2                	ld	s1,24(sp)
    8000383a:	6942                	ld	s2,16(sp)
    8000383c:	69a2                	ld	s3,8(sp)
    8000383e:	6a02                	ld	s4,0(sp)
    80003840:	6145                	addi	sp,sp,48
    80003842:	8082                	ret

0000000080003844 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003844:	7179                	addi	sp,sp,-48
    80003846:	f406                	sd	ra,40(sp)
    80003848:	f022                	sd	s0,32(sp)
    8000384a:	ec26                	sd	s1,24(sp)
    8000384c:	e84a                	sd	s2,16(sp)
    8000384e:	e44e                	sd	s3,8(sp)
    80003850:	1800                	addi	s0,sp,48
    80003852:	89aa                	mv	s3,a0
    80003854:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003856:	00014517          	auipc	a0,0x14
    8000385a:	41250513          	addi	a0,a0,1042 # 80017c68 <bcache>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	386080e7          	jalr	902(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003866:	0001c497          	auipc	s1,0x1c
    8000386a:	6ba4b483          	ld	s1,1722(s1) # 8001ff20 <bcache+0x82b8>
    8000386e:	0001c797          	auipc	a5,0x1c
    80003872:	66278793          	addi	a5,a5,1634 # 8001fed0 <bcache+0x8268>
    80003876:	02f48f63          	beq	s1,a5,800038b4 <bread+0x70>
    8000387a:	873e                	mv	a4,a5
    8000387c:	a021                	j	80003884 <bread+0x40>
    8000387e:	68a4                	ld	s1,80(s1)
    80003880:	02e48a63          	beq	s1,a4,800038b4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003884:	449c                	lw	a5,8(s1)
    80003886:	ff379ce3          	bne	a5,s3,8000387e <bread+0x3a>
    8000388a:	44dc                	lw	a5,12(s1)
    8000388c:	ff2799e3          	bne	a5,s2,8000387e <bread+0x3a>
      b->refcnt++;
    80003890:	40bc                	lw	a5,64(s1)
    80003892:	2785                	addiw	a5,a5,1
    80003894:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003896:	00014517          	auipc	a0,0x14
    8000389a:	3d250513          	addi	a0,a0,978 # 80017c68 <bcache>
    8000389e:	ffffd097          	auipc	ra,0xffffd
    800038a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800038a6:	01048513          	addi	a0,s1,16
    800038aa:	00001097          	auipc	ra,0x1
    800038ae:	466080e7          	jalr	1126(ra) # 80004d10 <acquiresleep>
      return b;
    800038b2:	a8b9                	j	80003910 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038b4:	0001c497          	auipc	s1,0x1c
    800038b8:	6644b483          	ld	s1,1636(s1) # 8001ff18 <bcache+0x82b0>
    800038bc:	0001c797          	auipc	a5,0x1c
    800038c0:	61478793          	addi	a5,a5,1556 # 8001fed0 <bcache+0x8268>
    800038c4:	00f48863          	beq	s1,a5,800038d4 <bread+0x90>
    800038c8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800038ca:	40bc                	lw	a5,64(s1)
    800038cc:	cf81                	beqz	a5,800038e4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800038ce:	64a4                	ld	s1,72(s1)
    800038d0:	fee49de3          	bne	s1,a4,800038ca <bread+0x86>
  panic("bget: no buffers");
    800038d4:	00005517          	auipc	a0,0x5
    800038d8:	db450513          	addi	a0,a0,-588 # 80008688 <syscalls+0xd8>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	c62080e7          	jalr	-926(ra) # 8000053e <panic>
      b->dev = dev;
    800038e4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800038e8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800038ec:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800038f0:	4785                	li	a5,1
    800038f2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800038f4:	00014517          	auipc	a0,0x14
    800038f8:	37450513          	addi	a0,a0,884 # 80017c68 <bcache>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	39c080e7          	jalr	924(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003904:	01048513          	addi	a0,s1,16
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	408080e7          	jalr	1032(ra) # 80004d10 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003910:	409c                	lw	a5,0(s1)
    80003912:	cb89                	beqz	a5,80003924 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003914:	8526                	mv	a0,s1
    80003916:	70a2                	ld	ra,40(sp)
    80003918:	7402                	ld	s0,32(sp)
    8000391a:	64e2                	ld	s1,24(sp)
    8000391c:	6942                	ld	s2,16(sp)
    8000391e:	69a2                	ld	s3,8(sp)
    80003920:	6145                	addi	sp,sp,48
    80003922:	8082                	ret
    virtio_disk_rw(b, 0);
    80003924:	4581                	li	a1,0
    80003926:	8526                	mv	a0,s1
    80003928:	00003097          	auipc	ra,0x3
    8000392c:	f0e080e7          	jalr	-242(ra) # 80006836 <virtio_disk_rw>
    b->valid = 1;
    80003930:	4785                	li	a5,1
    80003932:	c09c                	sw	a5,0(s1)
  return b;
    80003934:	b7c5                	j	80003914 <bread+0xd0>

0000000080003936 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003936:	1101                	addi	sp,sp,-32
    80003938:	ec06                	sd	ra,24(sp)
    8000393a:	e822                	sd	s0,16(sp)
    8000393c:	e426                	sd	s1,8(sp)
    8000393e:	1000                	addi	s0,sp,32
    80003940:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003942:	0541                	addi	a0,a0,16
    80003944:	00001097          	auipc	ra,0x1
    80003948:	466080e7          	jalr	1126(ra) # 80004daa <holdingsleep>
    8000394c:	cd01                	beqz	a0,80003964 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000394e:	4585                	li	a1,1
    80003950:	8526                	mv	a0,s1
    80003952:	00003097          	auipc	ra,0x3
    80003956:	ee4080e7          	jalr	-284(ra) # 80006836 <virtio_disk_rw>
}
    8000395a:	60e2                	ld	ra,24(sp)
    8000395c:	6442                	ld	s0,16(sp)
    8000395e:	64a2                	ld	s1,8(sp)
    80003960:	6105                	addi	sp,sp,32
    80003962:	8082                	ret
    panic("bwrite");
    80003964:	00005517          	auipc	a0,0x5
    80003968:	d3c50513          	addi	a0,a0,-708 # 800086a0 <syscalls+0xf0>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>

0000000080003974 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	e04a                	sd	s2,0(sp)
    8000397e:	1000                	addi	s0,sp,32
    80003980:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003982:	01050913          	addi	s2,a0,16
    80003986:	854a                	mv	a0,s2
    80003988:	00001097          	auipc	ra,0x1
    8000398c:	422080e7          	jalr	1058(ra) # 80004daa <holdingsleep>
    80003990:	c92d                	beqz	a0,80003a02 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	3d2080e7          	jalr	978(ra) # 80004d66 <releasesleep>

  acquire(&bcache.lock);
    8000399c:	00014517          	auipc	a0,0x14
    800039a0:	2cc50513          	addi	a0,a0,716 # 80017c68 <bcache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	240080e7          	jalr	576(ra) # 80000be4 <acquire>
  b->refcnt--;
    800039ac:	40bc                	lw	a5,64(s1)
    800039ae:	37fd                	addiw	a5,a5,-1
    800039b0:	0007871b          	sext.w	a4,a5
    800039b4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800039b6:	eb05                	bnez	a4,800039e6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800039b8:	68bc                	ld	a5,80(s1)
    800039ba:	64b8                	ld	a4,72(s1)
    800039bc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800039be:	64bc                	ld	a5,72(s1)
    800039c0:	68b8                	ld	a4,80(s1)
    800039c2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800039c4:	0001c797          	auipc	a5,0x1c
    800039c8:	2a478793          	addi	a5,a5,676 # 8001fc68 <bcache+0x8000>
    800039cc:	2b87b703          	ld	a4,696(a5)
    800039d0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800039d2:	0001c717          	auipc	a4,0x1c
    800039d6:	4fe70713          	addi	a4,a4,1278 # 8001fed0 <bcache+0x8268>
    800039da:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800039dc:	2b87b703          	ld	a4,696(a5)
    800039e0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800039e2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800039e6:	00014517          	auipc	a0,0x14
    800039ea:	28250513          	addi	a0,a0,642 # 80017c68 <bcache>
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	2aa080e7          	jalr	682(ra) # 80000c98 <release>
}
    800039f6:	60e2                	ld	ra,24(sp)
    800039f8:	6442                	ld	s0,16(sp)
    800039fa:	64a2                	ld	s1,8(sp)
    800039fc:	6902                	ld	s2,0(sp)
    800039fe:	6105                	addi	sp,sp,32
    80003a00:	8082                	ret
    panic("brelse");
    80003a02:	00005517          	auipc	a0,0x5
    80003a06:	ca650513          	addi	a0,a0,-858 # 800086a8 <syscalls+0xf8>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080003a12 <bpin>:

void
bpin(struct buf *b) {
    80003a12:	1101                	addi	sp,sp,-32
    80003a14:	ec06                	sd	ra,24(sp)
    80003a16:	e822                	sd	s0,16(sp)
    80003a18:	e426                	sd	s1,8(sp)
    80003a1a:	1000                	addi	s0,sp,32
    80003a1c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a1e:	00014517          	auipc	a0,0x14
    80003a22:	24a50513          	addi	a0,a0,586 # 80017c68 <bcache>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	1be080e7          	jalr	446(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003a2e:	40bc                	lw	a5,64(s1)
    80003a30:	2785                	addiw	a5,a5,1
    80003a32:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a34:	00014517          	auipc	a0,0x14
    80003a38:	23450513          	addi	a0,a0,564 # 80017c68 <bcache>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	25c080e7          	jalr	604(ra) # 80000c98 <release>
}
    80003a44:	60e2                	ld	ra,24(sp)
    80003a46:	6442                	ld	s0,16(sp)
    80003a48:	64a2                	ld	s1,8(sp)
    80003a4a:	6105                	addi	sp,sp,32
    80003a4c:	8082                	ret

0000000080003a4e <bunpin>:

void
bunpin(struct buf *b) {
    80003a4e:	1101                	addi	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	1000                	addi	s0,sp,32
    80003a58:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003a5a:	00014517          	auipc	a0,0x14
    80003a5e:	20e50513          	addi	a0,a0,526 # 80017c68 <bcache>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	182080e7          	jalr	386(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003a6a:	40bc                	lw	a5,64(s1)
    80003a6c:	37fd                	addiw	a5,a5,-1
    80003a6e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003a70:	00014517          	auipc	a0,0x14
    80003a74:	1f850513          	addi	a0,a0,504 # 80017c68 <bcache>
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	220080e7          	jalr	544(ra) # 80000c98 <release>
}
    80003a80:	60e2                	ld	ra,24(sp)
    80003a82:	6442                	ld	s0,16(sp)
    80003a84:	64a2                	ld	s1,8(sp)
    80003a86:	6105                	addi	sp,sp,32
    80003a88:	8082                	ret

0000000080003a8a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a98:	00d5d59b          	srliw	a1,a1,0xd
    80003a9c:	0001d797          	auipc	a5,0x1d
    80003aa0:	8a87a783          	lw	a5,-1880(a5) # 80020344 <sb+0x1c>
    80003aa4:	9dbd                	addw	a1,a1,a5
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	d9e080e7          	jalr	-610(ra) # 80003844 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003aae:	0074f713          	andi	a4,s1,7
    80003ab2:	4785                	li	a5,1
    80003ab4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003ab8:	14ce                	slli	s1,s1,0x33
    80003aba:	90d9                	srli	s1,s1,0x36
    80003abc:	00950733          	add	a4,a0,s1
    80003ac0:	05874703          	lbu	a4,88(a4)
    80003ac4:	00e7f6b3          	and	a3,a5,a4
    80003ac8:	c69d                	beqz	a3,80003af6 <bfree+0x6c>
    80003aca:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003acc:	94aa                	add	s1,s1,a0
    80003ace:	fff7c793          	not	a5,a5
    80003ad2:	8ff9                	and	a5,a5,a4
    80003ad4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003ad8:	00001097          	auipc	ra,0x1
    80003adc:	118080e7          	jalr	280(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00000097          	auipc	ra,0x0
    80003ae6:	e92080e7          	jalr	-366(ra) # 80003974 <brelse>
}
    80003aea:	60e2                	ld	ra,24(sp)
    80003aec:	6442                	ld	s0,16(sp)
    80003aee:	64a2                	ld	s1,8(sp)
    80003af0:	6902                	ld	s2,0(sp)
    80003af2:	6105                	addi	sp,sp,32
    80003af4:	8082                	ret
    panic("freeing free block");
    80003af6:	00005517          	auipc	a0,0x5
    80003afa:	bba50513          	addi	a0,a0,-1094 # 800086b0 <syscalls+0x100>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	a40080e7          	jalr	-1472(ra) # 8000053e <panic>

0000000080003b06 <balloc>:
{
    80003b06:	711d                	addi	sp,sp,-96
    80003b08:	ec86                	sd	ra,88(sp)
    80003b0a:	e8a2                	sd	s0,80(sp)
    80003b0c:	e4a6                	sd	s1,72(sp)
    80003b0e:	e0ca                	sd	s2,64(sp)
    80003b10:	fc4e                	sd	s3,56(sp)
    80003b12:	f852                	sd	s4,48(sp)
    80003b14:	f456                	sd	s5,40(sp)
    80003b16:	f05a                	sd	s6,32(sp)
    80003b18:	ec5e                	sd	s7,24(sp)
    80003b1a:	e862                	sd	s8,16(sp)
    80003b1c:	e466                	sd	s9,8(sp)
    80003b1e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b20:	0001d797          	auipc	a5,0x1d
    80003b24:	80c7a783          	lw	a5,-2036(a5) # 8002032c <sb+0x4>
    80003b28:	cbd1                	beqz	a5,80003bbc <balloc+0xb6>
    80003b2a:	8baa                	mv	s7,a0
    80003b2c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003b2e:	0001cb17          	auipc	s6,0x1c
    80003b32:	7fab0b13          	addi	s6,s6,2042 # 80020328 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b36:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003b38:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b3a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003b3c:	6c89                	lui	s9,0x2
    80003b3e:	a831                	j	80003b5a <balloc+0x54>
    brelse(bp);
    80003b40:	854a                	mv	a0,s2
    80003b42:	00000097          	auipc	ra,0x0
    80003b46:	e32080e7          	jalr	-462(ra) # 80003974 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003b4a:	015c87bb          	addw	a5,s9,s5
    80003b4e:	00078a9b          	sext.w	s5,a5
    80003b52:	004b2703          	lw	a4,4(s6)
    80003b56:	06eaf363          	bgeu	s5,a4,80003bbc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003b5a:	41fad79b          	sraiw	a5,s5,0x1f
    80003b5e:	0137d79b          	srliw	a5,a5,0x13
    80003b62:	015787bb          	addw	a5,a5,s5
    80003b66:	40d7d79b          	sraiw	a5,a5,0xd
    80003b6a:	01cb2583          	lw	a1,28(s6)
    80003b6e:	9dbd                	addw	a1,a1,a5
    80003b70:	855e                	mv	a0,s7
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	cd2080e7          	jalr	-814(ra) # 80003844 <bread>
    80003b7a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b7c:	004b2503          	lw	a0,4(s6)
    80003b80:	000a849b          	sext.w	s1,s5
    80003b84:	8662                	mv	a2,s8
    80003b86:	faa4fde3          	bgeu	s1,a0,80003b40 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b8a:	41f6579b          	sraiw	a5,a2,0x1f
    80003b8e:	01d7d69b          	srliw	a3,a5,0x1d
    80003b92:	00c6873b          	addw	a4,a3,a2
    80003b96:	00777793          	andi	a5,a4,7
    80003b9a:	9f95                	subw	a5,a5,a3
    80003b9c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ba0:	4037571b          	sraiw	a4,a4,0x3
    80003ba4:	00e906b3          	add	a3,s2,a4
    80003ba8:	0586c683          	lbu	a3,88(a3)
    80003bac:	00d7f5b3          	and	a1,a5,a3
    80003bb0:	cd91                	beqz	a1,80003bcc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bb2:	2605                	addiw	a2,a2,1
    80003bb4:	2485                	addiw	s1,s1,1
    80003bb6:	fd4618e3          	bne	a2,s4,80003b86 <balloc+0x80>
    80003bba:	b759                	j	80003b40 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003bbc:	00005517          	auipc	a0,0x5
    80003bc0:	b0c50513          	addi	a0,a0,-1268 # 800086c8 <syscalls+0x118>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bcc:	974a                	add	a4,a4,s2
    80003bce:	8fd5                	or	a5,a5,a3
    80003bd0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	00001097          	auipc	ra,0x1
    80003bda:	01a080e7          	jalr	26(ra) # 80004bf0 <log_write>
        brelse(bp);
    80003bde:	854a                	mv	a0,s2
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	d94080e7          	jalr	-620(ra) # 80003974 <brelse>
  bp = bread(dev, bno);
    80003be8:	85a6                	mv	a1,s1
    80003bea:	855e                	mv	a0,s7
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	c58080e7          	jalr	-936(ra) # 80003844 <bread>
    80003bf4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003bf6:	40000613          	li	a2,1024
    80003bfa:	4581                	li	a1,0
    80003bfc:	05850513          	addi	a0,a0,88
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	0e0080e7          	jalr	224(ra) # 80000ce0 <memset>
  log_write(bp);
    80003c08:	854a                	mv	a0,s2
    80003c0a:	00001097          	auipc	ra,0x1
    80003c0e:	fe6080e7          	jalr	-26(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003c12:	854a                	mv	a0,s2
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	d60080e7          	jalr	-672(ra) # 80003974 <brelse>
}
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	60e6                	ld	ra,88(sp)
    80003c20:	6446                	ld	s0,80(sp)
    80003c22:	64a6                	ld	s1,72(sp)
    80003c24:	6906                	ld	s2,64(sp)
    80003c26:	79e2                	ld	s3,56(sp)
    80003c28:	7a42                	ld	s4,48(sp)
    80003c2a:	7aa2                	ld	s5,40(sp)
    80003c2c:	7b02                	ld	s6,32(sp)
    80003c2e:	6be2                	ld	s7,24(sp)
    80003c30:	6c42                	ld	s8,16(sp)
    80003c32:	6ca2                	ld	s9,8(sp)
    80003c34:	6125                	addi	sp,sp,96
    80003c36:	8082                	ret

0000000080003c38 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003c38:	7179                	addi	sp,sp,-48
    80003c3a:	f406                	sd	ra,40(sp)
    80003c3c:	f022                	sd	s0,32(sp)
    80003c3e:	ec26                	sd	s1,24(sp)
    80003c40:	e84a                	sd	s2,16(sp)
    80003c42:	e44e                	sd	s3,8(sp)
    80003c44:	e052                	sd	s4,0(sp)
    80003c46:	1800                	addi	s0,sp,48
    80003c48:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003c4a:	47ad                	li	a5,11
    80003c4c:	04b7fe63          	bgeu	a5,a1,80003ca8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003c50:	ff45849b          	addiw	s1,a1,-12
    80003c54:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003c58:	0ff00793          	li	a5,255
    80003c5c:	0ae7e363          	bltu	a5,a4,80003d02 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003c60:	08052583          	lw	a1,128(a0)
    80003c64:	c5ad                	beqz	a1,80003cce <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003c66:	00092503          	lw	a0,0(s2)
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	bda080e7          	jalr	-1062(ra) # 80003844 <bread>
    80003c72:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003c74:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003c78:	02049593          	slli	a1,s1,0x20
    80003c7c:	9181                	srli	a1,a1,0x20
    80003c7e:	058a                	slli	a1,a1,0x2
    80003c80:	00b784b3          	add	s1,a5,a1
    80003c84:	0004a983          	lw	s3,0(s1)
    80003c88:	04098d63          	beqz	s3,80003ce2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c8c:	8552                	mv	a0,s4
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	ce6080e7          	jalr	-794(ra) # 80003974 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c96:	854e                	mv	a0,s3
    80003c98:	70a2                	ld	ra,40(sp)
    80003c9a:	7402                	ld	s0,32(sp)
    80003c9c:	64e2                	ld	s1,24(sp)
    80003c9e:	6942                	ld	s2,16(sp)
    80003ca0:	69a2                	ld	s3,8(sp)
    80003ca2:	6a02                	ld	s4,0(sp)
    80003ca4:	6145                	addi	sp,sp,48
    80003ca6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003ca8:	02059493          	slli	s1,a1,0x20
    80003cac:	9081                	srli	s1,s1,0x20
    80003cae:	048a                	slli	s1,s1,0x2
    80003cb0:	94aa                	add	s1,s1,a0
    80003cb2:	0504a983          	lw	s3,80(s1)
    80003cb6:	fe0990e3          	bnez	s3,80003c96 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003cba:	4108                	lw	a0,0(a0)
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	e4a080e7          	jalr	-438(ra) # 80003b06 <balloc>
    80003cc4:	0005099b          	sext.w	s3,a0
    80003cc8:	0534a823          	sw	s3,80(s1)
    80003ccc:	b7e9                	j	80003c96 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003cce:	4108                	lw	a0,0(a0)
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	e36080e7          	jalr	-458(ra) # 80003b06 <balloc>
    80003cd8:	0005059b          	sext.w	a1,a0
    80003cdc:	08b92023          	sw	a1,128(s2)
    80003ce0:	b759                	j	80003c66 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ce2:	00092503          	lw	a0,0(s2)
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	e20080e7          	jalr	-480(ra) # 80003b06 <balloc>
    80003cee:	0005099b          	sext.w	s3,a0
    80003cf2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003cf6:	8552                	mv	a0,s4
    80003cf8:	00001097          	auipc	ra,0x1
    80003cfc:	ef8080e7          	jalr	-264(ra) # 80004bf0 <log_write>
    80003d00:	b771                	j	80003c8c <bmap+0x54>
  panic("bmap: out of range");
    80003d02:	00005517          	auipc	a0,0x5
    80003d06:	9de50513          	addi	a0,a0,-1570 # 800086e0 <syscalls+0x130>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	834080e7          	jalr	-1996(ra) # 8000053e <panic>

0000000080003d12 <iget>:
{
    80003d12:	7179                	addi	sp,sp,-48
    80003d14:	f406                	sd	ra,40(sp)
    80003d16:	f022                	sd	s0,32(sp)
    80003d18:	ec26                	sd	s1,24(sp)
    80003d1a:	e84a                	sd	s2,16(sp)
    80003d1c:	e44e                	sd	s3,8(sp)
    80003d1e:	e052                	sd	s4,0(sp)
    80003d20:	1800                	addi	s0,sp,48
    80003d22:	89aa                	mv	s3,a0
    80003d24:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003d26:	0001c517          	auipc	a0,0x1c
    80003d2a:	62250513          	addi	a0,a0,1570 # 80020348 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	eb6080e7          	jalr	-330(ra) # 80000be4 <acquire>
  empty = 0;
    80003d36:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d38:	0001c497          	auipc	s1,0x1c
    80003d3c:	62848493          	addi	s1,s1,1576 # 80020360 <itable+0x18>
    80003d40:	0001e697          	auipc	a3,0x1e
    80003d44:	0b068693          	addi	a3,a3,176 # 80021df0 <log>
    80003d48:	a039                	j	80003d56 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d4a:	02090b63          	beqz	s2,80003d80 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003d4e:	08848493          	addi	s1,s1,136
    80003d52:	02d48a63          	beq	s1,a3,80003d86 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003d56:	449c                	lw	a5,8(s1)
    80003d58:	fef059e3          	blez	a5,80003d4a <iget+0x38>
    80003d5c:	4098                	lw	a4,0(s1)
    80003d5e:	ff3716e3          	bne	a4,s3,80003d4a <iget+0x38>
    80003d62:	40d8                	lw	a4,4(s1)
    80003d64:	ff4713e3          	bne	a4,s4,80003d4a <iget+0x38>
      ip->ref++;
    80003d68:	2785                	addiw	a5,a5,1
    80003d6a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003d6c:	0001c517          	auipc	a0,0x1c
    80003d70:	5dc50513          	addi	a0,a0,1500 # 80020348 <itable>
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
      return ip;
    80003d7c:	8926                	mv	s2,s1
    80003d7e:	a03d                	j	80003dac <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003d80:	f7f9                	bnez	a5,80003d4e <iget+0x3c>
    80003d82:	8926                	mv	s2,s1
    80003d84:	b7e9                	j	80003d4e <iget+0x3c>
  if(empty == 0)
    80003d86:	02090c63          	beqz	s2,80003dbe <iget+0xac>
  ip->dev = dev;
    80003d8a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d8e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d92:	4785                	li	a5,1
    80003d94:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d98:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003d9c:	0001c517          	auipc	a0,0x1c
    80003da0:	5ac50513          	addi	a0,a0,1452 # 80020348 <itable>
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	ef4080e7          	jalr	-268(ra) # 80000c98 <release>
}
    80003dac:	854a                	mv	a0,s2
    80003dae:	70a2                	ld	ra,40(sp)
    80003db0:	7402                	ld	s0,32(sp)
    80003db2:	64e2                	ld	s1,24(sp)
    80003db4:	6942                	ld	s2,16(sp)
    80003db6:	69a2                	ld	s3,8(sp)
    80003db8:	6a02                	ld	s4,0(sp)
    80003dba:	6145                	addi	sp,sp,48
    80003dbc:	8082                	ret
    panic("iget: no inodes");
    80003dbe:	00005517          	auipc	a0,0x5
    80003dc2:	93a50513          	addi	a0,a0,-1734 # 800086f8 <syscalls+0x148>
    80003dc6:	ffffc097          	auipc	ra,0xffffc
    80003dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>

0000000080003dce <fsinit>:
fsinit(int dev) {
    80003dce:	7179                	addi	sp,sp,-48
    80003dd0:	f406                	sd	ra,40(sp)
    80003dd2:	f022                	sd	s0,32(sp)
    80003dd4:	ec26                	sd	s1,24(sp)
    80003dd6:	e84a                	sd	s2,16(sp)
    80003dd8:	e44e                	sd	s3,8(sp)
    80003dda:	1800                	addi	s0,sp,48
    80003ddc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003dde:	4585                	li	a1,1
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	a64080e7          	jalr	-1436(ra) # 80003844 <bread>
    80003de8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003dea:	0001c997          	auipc	s3,0x1c
    80003dee:	53e98993          	addi	s3,s3,1342 # 80020328 <sb>
    80003df2:	02000613          	li	a2,32
    80003df6:	05850593          	addi	a1,a0,88
    80003dfa:	854e                	mv	a0,s3
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	f44080e7          	jalr	-188(ra) # 80000d40 <memmove>
  brelse(bp);
    80003e04:	8526                	mv	a0,s1
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	b6e080e7          	jalr	-1170(ra) # 80003974 <brelse>
  if(sb.magic != FSMAGIC)
    80003e0e:	0009a703          	lw	a4,0(s3)
    80003e12:	102037b7          	lui	a5,0x10203
    80003e16:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003e1a:	02f71263          	bne	a4,a5,80003e3e <fsinit+0x70>
  initlog(dev, &sb);
    80003e1e:	0001c597          	auipc	a1,0x1c
    80003e22:	50a58593          	addi	a1,a1,1290 # 80020328 <sb>
    80003e26:	854a                	mv	a0,s2
    80003e28:	00001097          	auipc	ra,0x1
    80003e2c:	b4c080e7          	jalr	-1204(ra) # 80004974 <initlog>
}
    80003e30:	70a2                	ld	ra,40(sp)
    80003e32:	7402                	ld	s0,32(sp)
    80003e34:	64e2                	ld	s1,24(sp)
    80003e36:	6942                	ld	s2,16(sp)
    80003e38:	69a2                	ld	s3,8(sp)
    80003e3a:	6145                	addi	sp,sp,48
    80003e3c:	8082                	ret
    panic("invalid file system");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	8ca50513          	addi	a0,a0,-1846 # 80008708 <syscalls+0x158>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	6f8080e7          	jalr	1784(ra) # 8000053e <panic>

0000000080003e4e <iinit>:
{
    80003e4e:	7179                	addi	sp,sp,-48
    80003e50:	f406                	sd	ra,40(sp)
    80003e52:	f022                	sd	s0,32(sp)
    80003e54:	ec26                	sd	s1,24(sp)
    80003e56:	e84a                	sd	s2,16(sp)
    80003e58:	e44e                	sd	s3,8(sp)
    80003e5a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003e5c:	00005597          	auipc	a1,0x5
    80003e60:	8c458593          	addi	a1,a1,-1852 # 80008720 <syscalls+0x170>
    80003e64:	0001c517          	auipc	a0,0x1c
    80003e68:	4e450513          	addi	a0,a0,1252 # 80020348 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	ce8080e7          	jalr	-792(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003e74:	0001c497          	auipc	s1,0x1c
    80003e78:	4fc48493          	addi	s1,s1,1276 # 80020370 <itable+0x28>
    80003e7c:	0001e997          	auipc	s3,0x1e
    80003e80:	f8498993          	addi	s3,s3,-124 # 80021e00 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003e84:	00005917          	auipc	s2,0x5
    80003e88:	8a490913          	addi	s2,s2,-1884 # 80008728 <syscalls+0x178>
    80003e8c:	85ca                	mv	a1,s2
    80003e8e:	8526                	mv	a0,s1
    80003e90:	00001097          	auipc	ra,0x1
    80003e94:	e46080e7          	jalr	-442(ra) # 80004cd6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e98:	08848493          	addi	s1,s1,136
    80003e9c:	ff3498e3          	bne	s1,s3,80003e8c <iinit+0x3e>
}
    80003ea0:	70a2                	ld	ra,40(sp)
    80003ea2:	7402                	ld	s0,32(sp)
    80003ea4:	64e2                	ld	s1,24(sp)
    80003ea6:	6942                	ld	s2,16(sp)
    80003ea8:	69a2                	ld	s3,8(sp)
    80003eaa:	6145                	addi	sp,sp,48
    80003eac:	8082                	ret

0000000080003eae <ialloc>:
{
    80003eae:	715d                	addi	sp,sp,-80
    80003eb0:	e486                	sd	ra,72(sp)
    80003eb2:	e0a2                	sd	s0,64(sp)
    80003eb4:	fc26                	sd	s1,56(sp)
    80003eb6:	f84a                	sd	s2,48(sp)
    80003eb8:	f44e                	sd	s3,40(sp)
    80003eba:	f052                	sd	s4,32(sp)
    80003ebc:	ec56                	sd	s5,24(sp)
    80003ebe:	e85a                	sd	s6,16(sp)
    80003ec0:	e45e                	sd	s7,8(sp)
    80003ec2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ec4:	0001c717          	auipc	a4,0x1c
    80003ec8:	47072703          	lw	a4,1136(a4) # 80020334 <sb+0xc>
    80003ecc:	4785                	li	a5,1
    80003ece:	04e7fa63          	bgeu	a5,a4,80003f22 <ialloc+0x74>
    80003ed2:	8aaa                	mv	s5,a0
    80003ed4:	8bae                	mv	s7,a1
    80003ed6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ed8:	0001ca17          	auipc	s4,0x1c
    80003edc:	450a0a13          	addi	s4,s4,1104 # 80020328 <sb>
    80003ee0:	00048b1b          	sext.w	s6,s1
    80003ee4:	0044d593          	srli	a1,s1,0x4
    80003ee8:	018a2783          	lw	a5,24(s4)
    80003eec:	9dbd                	addw	a1,a1,a5
    80003eee:	8556                	mv	a0,s5
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	954080e7          	jalr	-1708(ra) # 80003844 <bread>
    80003ef8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003efa:	05850993          	addi	s3,a0,88
    80003efe:	00f4f793          	andi	a5,s1,15
    80003f02:	079a                	slli	a5,a5,0x6
    80003f04:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003f06:	00099783          	lh	a5,0(s3)
    80003f0a:	c785                	beqz	a5,80003f32 <ialloc+0x84>
    brelse(bp);
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	a68080e7          	jalr	-1432(ra) # 80003974 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f14:	0485                	addi	s1,s1,1
    80003f16:	00ca2703          	lw	a4,12(s4)
    80003f1a:	0004879b          	sext.w	a5,s1
    80003f1e:	fce7e1e3          	bltu	a5,a4,80003ee0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003f22:	00005517          	auipc	a0,0x5
    80003f26:	80e50513          	addi	a0,a0,-2034 # 80008730 <syscalls+0x180>
    80003f2a:	ffffc097          	auipc	ra,0xffffc
    80003f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003f32:	04000613          	li	a2,64
    80003f36:	4581                	li	a1,0
    80003f38:	854e                	mv	a0,s3
    80003f3a:	ffffd097          	auipc	ra,0xffffd
    80003f3e:	da6080e7          	jalr	-602(ra) # 80000ce0 <memset>
      dip->type = type;
    80003f42:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003f46:	854a                	mv	a0,s2
    80003f48:	00001097          	auipc	ra,0x1
    80003f4c:	ca8080e7          	jalr	-856(ra) # 80004bf0 <log_write>
      brelse(bp);
    80003f50:	854a                	mv	a0,s2
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	a22080e7          	jalr	-1502(ra) # 80003974 <brelse>
      return iget(dev, inum);
    80003f5a:	85da                	mv	a1,s6
    80003f5c:	8556                	mv	a0,s5
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	db4080e7          	jalr	-588(ra) # 80003d12 <iget>
}
    80003f66:	60a6                	ld	ra,72(sp)
    80003f68:	6406                	ld	s0,64(sp)
    80003f6a:	74e2                	ld	s1,56(sp)
    80003f6c:	7942                	ld	s2,48(sp)
    80003f6e:	79a2                	ld	s3,40(sp)
    80003f70:	7a02                	ld	s4,32(sp)
    80003f72:	6ae2                	ld	s5,24(sp)
    80003f74:	6b42                	ld	s6,16(sp)
    80003f76:	6ba2                	ld	s7,8(sp)
    80003f78:	6161                	addi	sp,sp,80
    80003f7a:	8082                	ret

0000000080003f7c <iupdate>:
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	e04a                	sd	s2,0(sp)
    80003f86:	1000                	addi	s0,sp,32
    80003f88:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f8a:	415c                	lw	a5,4(a0)
    80003f8c:	0047d79b          	srliw	a5,a5,0x4
    80003f90:	0001c597          	auipc	a1,0x1c
    80003f94:	3b05a583          	lw	a1,944(a1) # 80020340 <sb+0x18>
    80003f98:	9dbd                	addw	a1,a1,a5
    80003f9a:	4108                	lw	a0,0(a0)
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	8a8080e7          	jalr	-1880(ra) # 80003844 <bread>
    80003fa4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003fa6:	05850793          	addi	a5,a0,88
    80003faa:	40c8                	lw	a0,4(s1)
    80003fac:	893d                	andi	a0,a0,15
    80003fae:	051a                	slli	a0,a0,0x6
    80003fb0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003fb2:	04449703          	lh	a4,68(s1)
    80003fb6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003fba:	04649703          	lh	a4,70(s1)
    80003fbe:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003fc2:	04849703          	lh	a4,72(s1)
    80003fc6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003fca:	04a49703          	lh	a4,74(s1)
    80003fce:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003fd2:	44f8                	lw	a4,76(s1)
    80003fd4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003fd6:	03400613          	li	a2,52
    80003fda:	05048593          	addi	a1,s1,80
    80003fde:	0531                	addi	a0,a0,12
    80003fe0:	ffffd097          	auipc	ra,0xffffd
    80003fe4:	d60080e7          	jalr	-672(ra) # 80000d40 <memmove>
  log_write(bp);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	00001097          	auipc	ra,0x1
    80003fee:	c06080e7          	jalr	-1018(ra) # 80004bf0 <log_write>
  brelse(bp);
    80003ff2:	854a                	mv	a0,s2
    80003ff4:	00000097          	auipc	ra,0x0
    80003ff8:	980080e7          	jalr	-1664(ra) # 80003974 <brelse>
}
    80003ffc:	60e2                	ld	ra,24(sp)
    80003ffe:	6442                	ld	s0,16(sp)
    80004000:	64a2                	ld	s1,8(sp)
    80004002:	6902                	ld	s2,0(sp)
    80004004:	6105                	addi	sp,sp,32
    80004006:	8082                	ret

0000000080004008 <idup>:
{
    80004008:	1101                	addi	sp,sp,-32
    8000400a:	ec06                	sd	ra,24(sp)
    8000400c:	e822                	sd	s0,16(sp)
    8000400e:	e426                	sd	s1,8(sp)
    80004010:	1000                	addi	s0,sp,32
    80004012:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004014:	0001c517          	auipc	a0,0x1c
    80004018:	33450513          	addi	a0,a0,820 # 80020348 <itable>
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	bc8080e7          	jalr	-1080(ra) # 80000be4 <acquire>
  ip->ref++;
    80004024:	449c                	lw	a5,8(s1)
    80004026:	2785                	addiw	a5,a5,1
    80004028:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000402a:	0001c517          	auipc	a0,0x1c
    8000402e:	31e50513          	addi	a0,a0,798 # 80020348 <itable>
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	c66080e7          	jalr	-922(ra) # 80000c98 <release>
}
    8000403a:	8526                	mv	a0,s1
    8000403c:	60e2                	ld	ra,24(sp)
    8000403e:	6442                	ld	s0,16(sp)
    80004040:	64a2                	ld	s1,8(sp)
    80004042:	6105                	addi	sp,sp,32
    80004044:	8082                	ret

0000000080004046 <ilock>:
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	e426                	sd	s1,8(sp)
    8000404e:	e04a                	sd	s2,0(sp)
    80004050:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004052:	c115                	beqz	a0,80004076 <ilock+0x30>
    80004054:	84aa                	mv	s1,a0
    80004056:	451c                	lw	a5,8(a0)
    80004058:	00f05f63          	blez	a5,80004076 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000405c:	0541                	addi	a0,a0,16
    8000405e:	00001097          	auipc	ra,0x1
    80004062:	cb2080e7          	jalr	-846(ra) # 80004d10 <acquiresleep>
  if(ip->valid == 0){
    80004066:	40bc                	lw	a5,64(s1)
    80004068:	cf99                	beqz	a5,80004086 <ilock+0x40>
}
    8000406a:	60e2                	ld	ra,24(sp)
    8000406c:	6442                	ld	s0,16(sp)
    8000406e:	64a2                	ld	s1,8(sp)
    80004070:	6902                	ld	s2,0(sp)
    80004072:	6105                	addi	sp,sp,32
    80004074:	8082                	ret
    panic("ilock");
    80004076:	00004517          	auipc	a0,0x4
    8000407a:	6d250513          	addi	a0,a0,1746 # 80008748 <syscalls+0x198>
    8000407e:	ffffc097          	auipc	ra,0xffffc
    80004082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004086:	40dc                	lw	a5,4(s1)
    80004088:	0047d79b          	srliw	a5,a5,0x4
    8000408c:	0001c597          	auipc	a1,0x1c
    80004090:	2b45a583          	lw	a1,692(a1) # 80020340 <sb+0x18>
    80004094:	9dbd                	addw	a1,a1,a5
    80004096:	4088                	lw	a0,0(s1)
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	7ac080e7          	jalr	1964(ra) # 80003844 <bread>
    800040a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800040a2:	05850593          	addi	a1,a0,88
    800040a6:	40dc                	lw	a5,4(s1)
    800040a8:	8bbd                	andi	a5,a5,15
    800040aa:	079a                	slli	a5,a5,0x6
    800040ac:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800040ae:	00059783          	lh	a5,0(a1)
    800040b2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800040b6:	00259783          	lh	a5,2(a1)
    800040ba:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800040be:	00459783          	lh	a5,4(a1)
    800040c2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800040c6:	00659783          	lh	a5,6(a1)
    800040ca:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800040ce:	459c                	lw	a5,8(a1)
    800040d0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800040d2:	03400613          	li	a2,52
    800040d6:	05b1                	addi	a1,a1,12
    800040d8:	05048513          	addi	a0,s1,80
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	c64080e7          	jalr	-924(ra) # 80000d40 <memmove>
    brelse(bp);
    800040e4:	854a                	mv	a0,s2
    800040e6:	00000097          	auipc	ra,0x0
    800040ea:	88e080e7          	jalr	-1906(ra) # 80003974 <brelse>
    ip->valid = 1;
    800040ee:	4785                	li	a5,1
    800040f0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800040f2:	04449783          	lh	a5,68(s1)
    800040f6:	fbb5                	bnez	a5,8000406a <ilock+0x24>
      panic("ilock: no type");
    800040f8:	00004517          	auipc	a0,0x4
    800040fc:	65850513          	addi	a0,a0,1624 # 80008750 <syscalls+0x1a0>
    80004100:	ffffc097          	auipc	ra,0xffffc
    80004104:	43e080e7          	jalr	1086(ra) # 8000053e <panic>

0000000080004108 <iunlock>:
{
    80004108:	1101                	addi	sp,sp,-32
    8000410a:	ec06                	sd	ra,24(sp)
    8000410c:	e822                	sd	s0,16(sp)
    8000410e:	e426                	sd	s1,8(sp)
    80004110:	e04a                	sd	s2,0(sp)
    80004112:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004114:	c905                	beqz	a0,80004144 <iunlock+0x3c>
    80004116:	84aa                	mv	s1,a0
    80004118:	01050913          	addi	s2,a0,16
    8000411c:	854a                	mv	a0,s2
    8000411e:	00001097          	auipc	ra,0x1
    80004122:	c8c080e7          	jalr	-884(ra) # 80004daa <holdingsleep>
    80004126:	cd19                	beqz	a0,80004144 <iunlock+0x3c>
    80004128:	449c                	lw	a5,8(s1)
    8000412a:	00f05d63          	blez	a5,80004144 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000412e:	854a                	mv	a0,s2
    80004130:	00001097          	auipc	ra,0x1
    80004134:	c36080e7          	jalr	-970(ra) # 80004d66 <releasesleep>
}
    80004138:	60e2                	ld	ra,24(sp)
    8000413a:	6442                	ld	s0,16(sp)
    8000413c:	64a2                	ld	s1,8(sp)
    8000413e:	6902                	ld	s2,0(sp)
    80004140:	6105                	addi	sp,sp,32
    80004142:	8082                	ret
    panic("iunlock");
    80004144:	00004517          	auipc	a0,0x4
    80004148:	61c50513          	addi	a0,a0,1564 # 80008760 <syscalls+0x1b0>
    8000414c:	ffffc097          	auipc	ra,0xffffc
    80004150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>

0000000080004154 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004154:	7179                	addi	sp,sp,-48
    80004156:	f406                	sd	ra,40(sp)
    80004158:	f022                	sd	s0,32(sp)
    8000415a:	ec26                	sd	s1,24(sp)
    8000415c:	e84a                	sd	s2,16(sp)
    8000415e:	e44e                	sd	s3,8(sp)
    80004160:	e052                	sd	s4,0(sp)
    80004162:	1800                	addi	s0,sp,48
    80004164:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004166:	05050493          	addi	s1,a0,80
    8000416a:	08050913          	addi	s2,a0,128
    8000416e:	a021                	j	80004176 <itrunc+0x22>
    80004170:	0491                	addi	s1,s1,4
    80004172:	01248d63          	beq	s1,s2,8000418c <itrunc+0x38>
    if(ip->addrs[i]){
    80004176:	408c                	lw	a1,0(s1)
    80004178:	dde5                	beqz	a1,80004170 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000417a:	0009a503          	lw	a0,0(s3)
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	90c080e7          	jalr	-1780(ra) # 80003a8a <bfree>
      ip->addrs[i] = 0;
    80004186:	0004a023          	sw	zero,0(s1)
    8000418a:	b7dd                	j	80004170 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000418c:	0809a583          	lw	a1,128(s3)
    80004190:	e185                	bnez	a1,800041b0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004192:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004196:	854e                	mv	a0,s3
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	de4080e7          	jalr	-540(ra) # 80003f7c <iupdate>
}
    800041a0:	70a2                	ld	ra,40(sp)
    800041a2:	7402                	ld	s0,32(sp)
    800041a4:	64e2                	ld	s1,24(sp)
    800041a6:	6942                	ld	s2,16(sp)
    800041a8:	69a2                	ld	s3,8(sp)
    800041aa:	6a02                	ld	s4,0(sp)
    800041ac:	6145                	addi	sp,sp,48
    800041ae:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800041b0:	0009a503          	lw	a0,0(s3)
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	690080e7          	jalr	1680(ra) # 80003844 <bread>
    800041bc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800041be:	05850493          	addi	s1,a0,88
    800041c2:	45850913          	addi	s2,a0,1112
    800041c6:	a811                	j	800041da <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800041c8:	0009a503          	lw	a0,0(s3)
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	8be080e7          	jalr	-1858(ra) # 80003a8a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800041d4:	0491                	addi	s1,s1,4
    800041d6:	01248563          	beq	s1,s2,800041e0 <itrunc+0x8c>
      if(a[j])
    800041da:	408c                	lw	a1,0(s1)
    800041dc:	dde5                	beqz	a1,800041d4 <itrunc+0x80>
    800041de:	b7ed                	j	800041c8 <itrunc+0x74>
    brelse(bp);
    800041e0:	8552                	mv	a0,s4
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	792080e7          	jalr	1938(ra) # 80003974 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800041ea:	0809a583          	lw	a1,128(s3)
    800041ee:	0009a503          	lw	a0,0(s3)
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	898080e7          	jalr	-1896(ra) # 80003a8a <bfree>
    ip->addrs[NDIRECT] = 0;
    800041fa:	0809a023          	sw	zero,128(s3)
    800041fe:	bf51                	j	80004192 <itrunc+0x3e>

0000000080004200 <iput>:
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	e04a                	sd	s2,0(sp)
    8000420a:	1000                	addi	s0,sp,32
    8000420c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000420e:	0001c517          	auipc	a0,0x1c
    80004212:	13a50513          	addi	a0,a0,314 # 80020348 <itable>
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000421e:	4498                	lw	a4,8(s1)
    80004220:	4785                	li	a5,1
    80004222:	02f70363          	beq	a4,a5,80004248 <iput+0x48>
  ip->ref--;
    80004226:	449c                	lw	a5,8(s1)
    80004228:	37fd                	addiw	a5,a5,-1
    8000422a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000422c:	0001c517          	auipc	a0,0x1c
    80004230:	11c50513          	addi	a0,a0,284 # 80020348 <itable>
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
}
    8000423c:	60e2                	ld	ra,24(sp)
    8000423e:	6442                	ld	s0,16(sp)
    80004240:	64a2                	ld	s1,8(sp)
    80004242:	6902                	ld	s2,0(sp)
    80004244:	6105                	addi	sp,sp,32
    80004246:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004248:	40bc                	lw	a5,64(s1)
    8000424a:	dff1                	beqz	a5,80004226 <iput+0x26>
    8000424c:	04a49783          	lh	a5,74(s1)
    80004250:	fbf9                	bnez	a5,80004226 <iput+0x26>
    acquiresleep(&ip->lock);
    80004252:	01048913          	addi	s2,s1,16
    80004256:	854a                	mv	a0,s2
    80004258:	00001097          	auipc	ra,0x1
    8000425c:	ab8080e7          	jalr	-1352(ra) # 80004d10 <acquiresleep>
    release(&itable.lock);
    80004260:	0001c517          	auipc	a0,0x1c
    80004264:	0e850513          	addi	a0,a0,232 # 80020348 <itable>
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	a30080e7          	jalr	-1488(ra) # 80000c98 <release>
    itrunc(ip);
    80004270:	8526                	mv	a0,s1
    80004272:	00000097          	auipc	ra,0x0
    80004276:	ee2080e7          	jalr	-286(ra) # 80004154 <itrunc>
    ip->type = 0;
    8000427a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000427e:	8526                	mv	a0,s1
    80004280:	00000097          	auipc	ra,0x0
    80004284:	cfc080e7          	jalr	-772(ra) # 80003f7c <iupdate>
    ip->valid = 0;
    80004288:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000428c:	854a                	mv	a0,s2
    8000428e:	00001097          	auipc	ra,0x1
    80004292:	ad8080e7          	jalr	-1320(ra) # 80004d66 <releasesleep>
    acquire(&itable.lock);
    80004296:	0001c517          	auipc	a0,0x1c
    8000429a:	0b250513          	addi	a0,a0,178 # 80020348 <itable>
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	946080e7          	jalr	-1722(ra) # 80000be4 <acquire>
    800042a6:	b741                	j	80004226 <iput+0x26>

00000000800042a8 <iunlockput>:
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	1000                	addi	s0,sp,32
    800042b2:	84aa                	mv	s1,a0
  iunlock(ip);
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	e54080e7          	jalr	-428(ra) # 80004108 <iunlock>
  iput(ip);
    800042bc:	8526                	mv	a0,s1
    800042be:	00000097          	auipc	ra,0x0
    800042c2:	f42080e7          	jalr	-190(ra) # 80004200 <iput>
}
    800042c6:	60e2                	ld	ra,24(sp)
    800042c8:	6442                	ld	s0,16(sp)
    800042ca:	64a2                	ld	s1,8(sp)
    800042cc:	6105                	addi	sp,sp,32
    800042ce:	8082                	ret

00000000800042d0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800042d0:	1141                	addi	sp,sp,-16
    800042d2:	e422                	sd	s0,8(sp)
    800042d4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800042d6:	411c                	lw	a5,0(a0)
    800042d8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800042da:	415c                	lw	a5,4(a0)
    800042dc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800042de:	04451783          	lh	a5,68(a0)
    800042e2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800042e6:	04a51783          	lh	a5,74(a0)
    800042ea:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800042ee:	04c56783          	lwu	a5,76(a0)
    800042f2:	e99c                	sd	a5,16(a1)
}
    800042f4:	6422                	ld	s0,8(sp)
    800042f6:	0141                	addi	sp,sp,16
    800042f8:	8082                	ret

00000000800042fa <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042fa:	457c                	lw	a5,76(a0)
    800042fc:	0ed7e963          	bltu	a5,a3,800043ee <readi+0xf4>
{
    80004300:	7159                	addi	sp,sp,-112
    80004302:	f486                	sd	ra,104(sp)
    80004304:	f0a2                	sd	s0,96(sp)
    80004306:	eca6                	sd	s1,88(sp)
    80004308:	e8ca                	sd	s2,80(sp)
    8000430a:	e4ce                	sd	s3,72(sp)
    8000430c:	e0d2                	sd	s4,64(sp)
    8000430e:	fc56                	sd	s5,56(sp)
    80004310:	f85a                	sd	s6,48(sp)
    80004312:	f45e                	sd	s7,40(sp)
    80004314:	f062                	sd	s8,32(sp)
    80004316:	ec66                	sd	s9,24(sp)
    80004318:	e86a                	sd	s10,16(sp)
    8000431a:	e46e                	sd	s11,8(sp)
    8000431c:	1880                	addi	s0,sp,112
    8000431e:	8baa                	mv	s7,a0
    80004320:	8c2e                	mv	s8,a1
    80004322:	8ab2                	mv	s5,a2
    80004324:	84b6                	mv	s1,a3
    80004326:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004328:	9f35                	addw	a4,a4,a3
    return 0;
    8000432a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000432c:	0ad76063          	bltu	a4,a3,800043cc <readi+0xd2>
  if(off + n > ip->size)
    80004330:	00e7f463          	bgeu	a5,a4,80004338 <readi+0x3e>
    n = ip->size - off;
    80004334:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004338:	0a0b0963          	beqz	s6,800043ea <readi+0xf0>
    8000433c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000433e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004342:	5cfd                	li	s9,-1
    80004344:	a82d                	j	8000437e <readi+0x84>
    80004346:	020a1d93          	slli	s11,s4,0x20
    8000434a:	020ddd93          	srli	s11,s11,0x20
    8000434e:	05890613          	addi	a2,s2,88
    80004352:	86ee                	mv	a3,s11
    80004354:	963a                	add	a2,a2,a4
    80004356:	85d6                	mv	a1,s5
    80004358:	8562                	mv	a0,s8
    8000435a:	ffffe097          	auipc	ra,0xffffe
    8000435e:	4d6080e7          	jalr	1238(ra) # 80002830 <either_copyout>
    80004362:	05950d63          	beq	a0,s9,800043bc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004366:	854a                	mv	a0,s2
    80004368:	fffff097          	auipc	ra,0xfffff
    8000436c:	60c080e7          	jalr	1548(ra) # 80003974 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004370:	013a09bb          	addw	s3,s4,s3
    80004374:	009a04bb          	addw	s1,s4,s1
    80004378:	9aee                	add	s5,s5,s11
    8000437a:	0569f763          	bgeu	s3,s6,800043c8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000437e:	000ba903          	lw	s2,0(s7)
    80004382:	00a4d59b          	srliw	a1,s1,0xa
    80004386:	855e                	mv	a0,s7
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	8b0080e7          	jalr	-1872(ra) # 80003c38 <bmap>
    80004390:	0005059b          	sext.w	a1,a0
    80004394:	854a                	mv	a0,s2
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	4ae080e7          	jalr	1198(ra) # 80003844 <bread>
    8000439e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800043a0:	3ff4f713          	andi	a4,s1,1023
    800043a4:	40ed07bb          	subw	a5,s10,a4
    800043a8:	413b06bb          	subw	a3,s6,s3
    800043ac:	8a3e                	mv	s4,a5
    800043ae:	2781                	sext.w	a5,a5
    800043b0:	0006861b          	sext.w	a2,a3
    800043b4:	f8f679e3          	bgeu	a2,a5,80004346 <readi+0x4c>
    800043b8:	8a36                	mv	s4,a3
    800043ba:	b771                	j	80004346 <readi+0x4c>
      brelse(bp);
    800043bc:	854a                	mv	a0,s2
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	5b6080e7          	jalr	1462(ra) # 80003974 <brelse>
      tot = -1;
    800043c6:	59fd                	li	s3,-1
  }
  return tot;
    800043c8:	0009851b          	sext.w	a0,s3
}
    800043cc:	70a6                	ld	ra,104(sp)
    800043ce:	7406                	ld	s0,96(sp)
    800043d0:	64e6                	ld	s1,88(sp)
    800043d2:	6946                	ld	s2,80(sp)
    800043d4:	69a6                	ld	s3,72(sp)
    800043d6:	6a06                	ld	s4,64(sp)
    800043d8:	7ae2                	ld	s5,56(sp)
    800043da:	7b42                	ld	s6,48(sp)
    800043dc:	7ba2                	ld	s7,40(sp)
    800043de:	7c02                	ld	s8,32(sp)
    800043e0:	6ce2                	ld	s9,24(sp)
    800043e2:	6d42                	ld	s10,16(sp)
    800043e4:	6da2                	ld	s11,8(sp)
    800043e6:	6165                	addi	sp,sp,112
    800043e8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043ea:	89da                	mv	s3,s6
    800043ec:	bff1                	j	800043c8 <readi+0xce>
    return 0;
    800043ee:	4501                	li	a0,0
}
    800043f0:	8082                	ret

00000000800043f2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043f2:	457c                	lw	a5,76(a0)
    800043f4:	10d7e863          	bltu	a5,a3,80004504 <writei+0x112>
{
    800043f8:	7159                	addi	sp,sp,-112
    800043fa:	f486                	sd	ra,104(sp)
    800043fc:	f0a2                	sd	s0,96(sp)
    800043fe:	eca6                	sd	s1,88(sp)
    80004400:	e8ca                	sd	s2,80(sp)
    80004402:	e4ce                	sd	s3,72(sp)
    80004404:	e0d2                	sd	s4,64(sp)
    80004406:	fc56                	sd	s5,56(sp)
    80004408:	f85a                	sd	s6,48(sp)
    8000440a:	f45e                	sd	s7,40(sp)
    8000440c:	f062                	sd	s8,32(sp)
    8000440e:	ec66                	sd	s9,24(sp)
    80004410:	e86a                	sd	s10,16(sp)
    80004412:	e46e                	sd	s11,8(sp)
    80004414:	1880                	addi	s0,sp,112
    80004416:	8b2a                	mv	s6,a0
    80004418:	8c2e                	mv	s8,a1
    8000441a:	8ab2                	mv	s5,a2
    8000441c:	8936                	mv	s2,a3
    8000441e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004420:	00e687bb          	addw	a5,a3,a4
    80004424:	0ed7e263          	bltu	a5,a3,80004508 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004428:	00043737          	lui	a4,0x43
    8000442c:	0ef76063          	bltu	a4,a5,8000450c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004430:	0c0b8863          	beqz	s7,80004500 <writei+0x10e>
    80004434:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004436:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000443a:	5cfd                	li	s9,-1
    8000443c:	a091                	j	80004480 <writei+0x8e>
    8000443e:	02099d93          	slli	s11,s3,0x20
    80004442:	020ddd93          	srli	s11,s11,0x20
    80004446:	05848513          	addi	a0,s1,88
    8000444a:	86ee                	mv	a3,s11
    8000444c:	8656                	mv	a2,s5
    8000444e:	85e2                	mv	a1,s8
    80004450:	953a                	add	a0,a0,a4
    80004452:	ffffe097          	auipc	ra,0xffffe
    80004456:	434080e7          	jalr	1076(ra) # 80002886 <either_copyin>
    8000445a:	07950263          	beq	a0,s9,800044be <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000445e:	8526                	mv	a0,s1
    80004460:	00000097          	auipc	ra,0x0
    80004464:	790080e7          	jalr	1936(ra) # 80004bf0 <log_write>
    brelse(bp);
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	50a080e7          	jalr	1290(ra) # 80003974 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004472:	01498a3b          	addw	s4,s3,s4
    80004476:	0129893b          	addw	s2,s3,s2
    8000447a:	9aee                	add	s5,s5,s11
    8000447c:	057a7663          	bgeu	s4,s7,800044c8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004480:	000b2483          	lw	s1,0(s6)
    80004484:	00a9559b          	srliw	a1,s2,0xa
    80004488:	855a                	mv	a0,s6
    8000448a:	fffff097          	auipc	ra,0xfffff
    8000448e:	7ae080e7          	jalr	1966(ra) # 80003c38 <bmap>
    80004492:	0005059b          	sext.w	a1,a0
    80004496:	8526                	mv	a0,s1
    80004498:	fffff097          	auipc	ra,0xfffff
    8000449c:	3ac080e7          	jalr	940(ra) # 80003844 <bread>
    800044a0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800044a2:	3ff97713          	andi	a4,s2,1023
    800044a6:	40ed07bb          	subw	a5,s10,a4
    800044aa:	414b86bb          	subw	a3,s7,s4
    800044ae:	89be                	mv	s3,a5
    800044b0:	2781                	sext.w	a5,a5
    800044b2:	0006861b          	sext.w	a2,a3
    800044b6:	f8f674e3          	bgeu	a2,a5,8000443e <writei+0x4c>
    800044ba:	89b6                	mv	s3,a3
    800044bc:	b749                	j	8000443e <writei+0x4c>
      brelse(bp);
    800044be:	8526                	mv	a0,s1
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	4b4080e7          	jalr	1204(ra) # 80003974 <brelse>
  }

  if(off > ip->size)
    800044c8:	04cb2783          	lw	a5,76(s6)
    800044cc:	0127f463          	bgeu	a5,s2,800044d4 <writei+0xe2>
    ip->size = off;
    800044d0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800044d4:	855a                	mv	a0,s6
    800044d6:	00000097          	auipc	ra,0x0
    800044da:	aa6080e7          	jalr	-1370(ra) # 80003f7c <iupdate>

  return tot;
    800044de:	000a051b          	sext.w	a0,s4
}
    800044e2:	70a6                	ld	ra,104(sp)
    800044e4:	7406                	ld	s0,96(sp)
    800044e6:	64e6                	ld	s1,88(sp)
    800044e8:	6946                	ld	s2,80(sp)
    800044ea:	69a6                	ld	s3,72(sp)
    800044ec:	6a06                	ld	s4,64(sp)
    800044ee:	7ae2                	ld	s5,56(sp)
    800044f0:	7b42                	ld	s6,48(sp)
    800044f2:	7ba2                	ld	s7,40(sp)
    800044f4:	7c02                	ld	s8,32(sp)
    800044f6:	6ce2                	ld	s9,24(sp)
    800044f8:	6d42                	ld	s10,16(sp)
    800044fa:	6da2                	ld	s11,8(sp)
    800044fc:	6165                	addi	sp,sp,112
    800044fe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004500:	8a5e                	mv	s4,s7
    80004502:	bfc9                	j	800044d4 <writei+0xe2>
    return -1;
    80004504:	557d                	li	a0,-1
}
    80004506:	8082                	ret
    return -1;
    80004508:	557d                	li	a0,-1
    8000450a:	bfe1                	j	800044e2 <writei+0xf0>
    return -1;
    8000450c:	557d                	li	a0,-1
    8000450e:	bfd1                	j	800044e2 <writei+0xf0>

0000000080004510 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004510:	1141                	addi	sp,sp,-16
    80004512:	e406                	sd	ra,8(sp)
    80004514:	e022                	sd	s0,0(sp)
    80004516:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004518:	4639                	li	a2,14
    8000451a:	ffffd097          	auipc	ra,0xffffd
    8000451e:	89e080e7          	jalr	-1890(ra) # 80000db8 <strncmp>
}
    80004522:	60a2                	ld	ra,8(sp)
    80004524:	6402                	ld	s0,0(sp)
    80004526:	0141                	addi	sp,sp,16
    80004528:	8082                	ret

000000008000452a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000452a:	7139                	addi	sp,sp,-64
    8000452c:	fc06                	sd	ra,56(sp)
    8000452e:	f822                	sd	s0,48(sp)
    80004530:	f426                	sd	s1,40(sp)
    80004532:	f04a                	sd	s2,32(sp)
    80004534:	ec4e                	sd	s3,24(sp)
    80004536:	e852                	sd	s4,16(sp)
    80004538:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000453a:	04451703          	lh	a4,68(a0)
    8000453e:	4785                	li	a5,1
    80004540:	00f71a63          	bne	a4,a5,80004554 <dirlookup+0x2a>
    80004544:	892a                	mv	s2,a0
    80004546:	89ae                	mv	s3,a1
    80004548:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000454a:	457c                	lw	a5,76(a0)
    8000454c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000454e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004550:	e79d                	bnez	a5,8000457e <dirlookup+0x54>
    80004552:	a8a5                	j	800045ca <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004554:	00004517          	auipc	a0,0x4
    80004558:	21450513          	addi	a0,a0,532 # 80008768 <syscalls+0x1b8>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004564:	00004517          	auipc	a0,0x4
    80004568:	21c50513          	addi	a0,a0,540 # 80008780 <syscalls+0x1d0>
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	fd2080e7          	jalr	-46(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004574:	24c1                	addiw	s1,s1,16
    80004576:	04c92783          	lw	a5,76(s2)
    8000457a:	04f4f763          	bgeu	s1,a5,800045c8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000457e:	4741                	li	a4,16
    80004580:	86a6                	mv	a3,s1
    80004582:	fc040613          	addi	a2,s0,-64
    80004586:	4581                	li	a1,0
    80004588:	854a                	mv	a0,s2
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	d70080e7          	jalr	-656(ra) # 800042fa <readi>
    80004592:	47c1                	li	a5,16
    80004594:	fcf518e3          	bne	a0,a5,80004564 <dirlookup+0x3a>
    if(de.inum == 0)
    80004598:	fc045783          	lhu	a5,-64(s0)
    8000459c:	dfe1                	beqz	a5,80004574 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000459e:	fc240593          	addi	a1,s0,-62
    800045a2:	854e                	mv	a0,s3
    800045a4:	00000097          	auipc	ra,0x0
    800045a8:	f6c080e7          	jalr	-148(ra) # 80004510 <namecmp>
    800045ac:	f561                	bnez	a0,80004574 <dirlookup+0x4a>
      if(poff)
    800045ae:	000a0463          	beqz	s4,800045b6 <dirlookup+0x8c>
        *poff = off;
    800045b2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800045b6:	fc045583          	lhu	a1,-64(s0)
    800045ba:	00092503          	lw	a0,0(s2)
    800045be:	fffff097          	auipc	ra,0xfffff
    800045c2:	754080e7          	jalr	1876(ra) # 80003d12 <iget>
    800045c6:	a011                	j	800045ca <dirlookup+0xa0>
  return 0;
    800045c8:	4501                	li	a0,0
}
    800045ca:	70e2                	ld	ra,56(sp)
    800045cc:	7442                	ld	s0,48(sp)
    800045ce:	74a2                	ld	s1,40(sp)
    800045d0:	7902                	ld	s2,32(sp)
    800045d2:	69e2                	ld	s3,24(sp)
    800045d4:	6a42                	ld	s4,16(sp)
    800045d6:	6121                	addi	sp,sp,64
    800045d8:	8082                	ret

00000000800045da <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800045da:	711d                	addi	sp,sp,-96
    800045dc:	ec86                	sd	ra,88(sp)
    800045de:	e8a2                	sd	s0,80(sp)
    800045e0:	e4a6                	sd	s1,72(sp)
    800045e2:	e0ca                	sd	s2,64(sp)
    800045e4:	fc4e                	sd	s3,56(sp)
    800045e6:	f852                	sd	s4,48(sp)
    800045e8:	f456                	sd	s5,40(sp)
    800045ea:	f05a                	sd	s6,32(sp)
    800045ec:	ec5e                	sd	s7,24(sp)
    800045ee:	e862                	sd	s8,16(sp)
    800045f0:	e466                	sd	s9,8(sp)
    800045f2:	1080                	addi	s0,sp,96
    800045f4:	84aa                	mv	s1,a0
    800045f6:	8b2e                	mv	s6,a1
    800045f8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800045fa:	00054703          	lbu	a4,0(a0)
    800045fe:	02f00793          	li	a5,47
    80004602:	02f70363          	beq	a4,a5,80004628 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004606:	ffffe097          	auipc	ra,0xffffe
    8000460a:	940080e7          	jalr	-1728(ra) # 80001f46 <myproc>
    8000460e:	15053503          	ld	a0,336(a0)
    80004612:	00000097          	auipc	ra,0x0
    80004616:	9f6080e7          	jalr	-1546(ra) # 80004008 <idup>
    8000461a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000461c:	02f00913          	li	s2,47
  len = path - s;
    80004620:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004622:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004624:	4c05                	li	s8,1
    80004626:	a865                	j	800046de <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004628:	4585                	li	a1,1
    8000462a:	4505                	li	a0,1
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	6e6080e7          	jalr	1766(ra) # 80003d12 <iget>
    80004634:	89aa                	mv	s3,a0
    80004636:	b7dd                	j	8000461c <namex+0x42>
      iunlockput(ip);
    80004638:	854e                	mv	a0,s3
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	c6e080e7          	jalr	-914(ra) # 800042a8 <iunlockput>
      return 0;
    80004642:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004644:	854e                	mv	a0,s3
    80004646:	60e6                	ld	ra,88(sp)
    80004648:	6446                	ld	s0,80(sp)
    8000464a:	64a6                	ld	s1,72(sp)
    8000464c:	6906                	ld	s2,64(sp)
    8000464e:	79e2                	ld	s3,56(sp)
    80004650:	7a42                	ld	s4,48(sp)
    80004652:	7aa2                	ld	s5,40(sp)
    80004654:	7b02                	ld	s6,32(sp)
    80004656:	6be2                	ld	s7,24(sp)
    80004658:	6c42                	ld	s8,16(sp)
    8000465a:	6ca2                	ld	s9,8(sp)
    8000465c:	6125                	addi	sp,sp,96
    8000465e:	8082                	ret
      iunlock(ip);
    80004660:	854e                	mv	a0,s3
    80004662:	00000097          	auipc	ra,0x0
    80004666:	aa6080e7          	jalr	-1370(ra) # 80004108 <iunlock>
      return ip;
    8000466a:	bfe9                	j	80004644 <namex+0x6a>
      iunlockput(ip);
    8000466c:	854e                	mv	a0,s3
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	c3a080e7          	jalr	-966(ra) # 800042a8 <iunlockput>
      return 0;
    80004676:	89d2                	mv	s3,s4
    80004678:	b7f1                	j	80004644 <namex+0x6a>
  len = path - s;
    8000467a:	40b48633          	sub	a2,s1,a1
    8000467e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004682:	094cd463          	bge	s9,s4,8000470a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004686:	4639                	li	a2,14
    80004688:	8556                	mv	a0,s5
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	6b6080e7          	jalr	1718(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004692:	0004c783          	lbu	a5,0(s1)
    80004696:	01279763          	bne	a5,s2,800046a4 <namex+0xca>
    path++;
    8000469a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000469c:	0004c783          	lbu	a5,0(s1)
    800046a0:	ff278de3          	beq	a5,s2,8000469a <namex+0xc0>
    ilock(ip);
    800046a4:	854e                	mv	a0,s3
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	9a0080e7          	jalr	-1632(ra) # 80004046 <ilock>
    if(ip->type != T_DIR){
    800046ae:	04499783          	lh	a5,68(s3)
    800046b2:	f98793e3          	bne	a5,s8,80004638 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800046b6:	000b0563          	beqz	s6,800046c0 <namex+0xe6>
    800046ba:	0004c783          	lbu	a5,0(s1)
    800046be:	d3cd                	beqz	a5,80004660 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800046c0:	865e                	mv	a2,s7
    800046c2:	85d6                	mv	a1,s5
    800046c4:	854e                	mv	a0,s3
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	e64080e7          	jalr	-412(ra) # 8000452a <dirlookup>
    800046ce:	8a2a                	mv	s4,a0
    800046d0:	dd51                	beqz	a0,8000466c <namex+0x92>
    iunlockput(ip);
    800046d2:	854e                	mv	a0,s3
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	bd4080e7          	jalr	-1068(ra) # 800042a8 <iunlockput>
    ip = next;
    800046dc:	89d2                	mv	s3,s4
  while(*path == '/')
    800046de:	0004c783          	lbu	a5,0(s1)
    800046e2:	05279763          	bne	a5,s2,80004730 <namex+0x156>
    path++;
    800046e6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800046e8:	0004c783          	lbu	a5,0(s1)
    800046ec:	ff278de3          	beq	a5,s2,800046e6 <namex+0x10c>
  if(*path == 0)
    800046f0:	c79d                	beqz	a5,8000471e <namex+0x144>
    path++;
    800046f2:	85a6                	mv	a1,s1
  len = path - s;
    800046f4:	8a5e                	mv	s4,s7
    800046f6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800046f8:	01278963          	beq	a5,s2,8000470a <namex+0x130>
    800046fc:	dfbd                	beqz	a5,8000467a <namex+0xa0>
    path++;
    800046fe:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004700:	0004c783          	lbu	a5,0(s1)
    80004704:	ff279ce3          	bne	a5,s2,800046fc <namex+0x122>
    80004708:	bf8d                	j	8000467a <namex+0xa0>
    memmove(name, s, len);
    8000470a:	2601                	sext.w	a2,a2
    8000470c:	8556                	mv	a0,s5
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	632080e7          	jalr	1586(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004716:	9a56                	add	s4,s4,s5
    80004718:	000a0023          	sb	zero,0(s4)
    8000471c:	bf9d                	j	80004692 <namex+0xb8>
  if(nameiparent){
    8000471e:	f20b03e3          	beqz	s6,80004644 <namex+0x6a>
    iput(ip);
    80004722:	854e                	mv	a0,s3
    80004724:	00000097          	auipc	ra,0x0
    80004728:	adc080e7          	jalr	-1316(ra) # 80004200 <iput>
    return 0;
    8000472c:	4981                	li	s3,0
    8000472e:	bf19                	j	80004644 <namex+0x6a>
  if(*path == 0)
    80004730:	d7fd                	beqz	a5,8000471e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004732:	0004c783          	lbu	a5,0(s1)
    80004736:	85a6                	mv	a1,s1
    80004738:	b7d1                	j	800046fc <namex+0x122>

000000008000473a <dirlink>:
{
    8000473a:	7139                	addi	sp,sp,-64
    8000473c:	fc06                	sd	ra,56(sp)
    8000473e:	f822                	sd	s0,48(sp)
    80004740:	f426                	sd	s1,40(sp)
    80004742:	f04a                	sd	s2,32(sp)
    80004744:	ec4e                	sd	s3,24(sp)
    80004746:	e852                	sd	s4,16(sp)
    80004748:	0080                	addi	s0,sp,64
    8000474a:	892a                	mv	s2,a0
    8000474c:	8a2e                	mv	s4,a1
    8000474e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004750:	4601                	li	a2,0
    80004752:	00000097          	auipc	ra,0x0
    80004756:	dd8080e7          	jalr	-552(ra) # 8000452a <dirlookup>
    8000475a:	e93d                	bnez	a0,800047d0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000475c:	04c92483          	lw	s1,76(s2)
    80004760:	c49d                	beqz	s1,8000478e <dirlink+0x54>
    80004762:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004764:	4741                	li	a4,16
    80004766:	86a6                	mv	a3,s1
    80004768:	fc040613          	addi	a2,s0,-64
    8000476c:	4581                	li	a1,0
    8000476e:	854a                	mv	a0,s2
    80004770:	00000097          	auipc	ra,0x0
    80004774:	b8a080e7          	jalr	-1142(ra) # 800042fa <readi>
    80004778:	47c1                	li	a5,16
    8000477a:	06f51163          	bne	a0,a5,800047dc <dirlink+0xa2>
    if(de.inum == 0)
    8000477e:	fc045783          	lhu	a5,-64(s0)
    80004782:	c791                	beqz	a5,8000478e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004784:	24c1                	addiw	s1,s1,16
    80004786:	04c92783          	lw	a5,76(s2)
    8000478a:	fcf4ede3          	bltu	s1,a5,80004764 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000478e:	4639                	li	a2,14
    80004790:	85d2                	mv	a1,s4
    80004792:	fc240513          	addi	a0,s0,-62
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	65e080e7          	jalr	1630(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000479e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047a2:	4741                	li	a4,16
    800047a4:	86a6                	mv	a3,s1
    800047a6:	fc040613          	addi	a2,s0,-64
    800047aa:	4581                	li	a1,0
    800047ac:	854a                	mv	a0,s2
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	c44080e7          	jalr	-956(ra) # 800043f2 <writei>
    800047b6:	872a                	mv	a4,a0
    800047b8:	47c1                	li	a5,16
  return 0;
    800047ba:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047bc:	02f71863          	bne	a4,a5,800047ec <dirlink+0xb2>
}
    800047c0:	70e2                	ld	ra,56(sp)
    800047c2:	7442                	ld	s0,48(sp)
    800047c4:	74a2                	ld	s1,40(sp)
    800047c6:	7902                	ld	s2,32(sp)
    800047c8:	69e2                	ld	s3,24(sp)
    800047ca:	6a42                	ld	s4,16(sp)
    800047cc:	6121                	addi	sp,sp,64
    800047ce:	8082                	ret
    iput(ip);
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	a30080e7          	jalr	-1488(ra) # 80004200 <iput>
    return -1;
    800047d8:	557d                	li	a0,-1
    800047da:	b7dd                	j	800047c0 <dirlink+0x86>
      panic("dirlink read");
    800047dc:	00004517          	auipc	a0,0x4
    800047e0:	fb450513          	addi	a0,a0,-76 # 80008790 <syscalls+0x1e0>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>
    panic("dirlink");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	0b450513          	addi	a0,a0,180 # 800088a0 <syscalls+0x2f0>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d4a080e7          	jalr	-694(ra) # 8000053e <panic>

00000000800047fc <namei>:

struct inode*
namei(char *path)
{
    800047fc:	1101                	addi	sp,sp,-32
    800047fe:	ec06                	sd	ra,24(sp)
    80004800:	e822                	sd	s0,16(sp)
    80004802:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004804:	fe040613          	addi	a2,s0,-32
    80004808:	4581                	li	a1,0
    8000480a:	00000097          	auipc	ra,0x0
    8000480e:	dd0080e7          	jalr	-560(ra) # 800045da <namex>
}
    80004812:	60e2                	ld	ra,24(sp)
    80004814:	6442                	ld	s0,16(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000481a:	1141                	addi	sp,sp,-16
    8000481c:	e406                	sd	ra,8(sp)
    8000481e:	e022                	sd	s0,0(sp)
    80004820:	0800                	addi	s0,sp,16
    80004822:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004824:	4585                	li	a1,1
    80004826:	00000097          	auipc	ra,0x0
    8000482a:	db4080e7          	jalr	-588(ra) # 800045da <namex>
}
    8000482e:	60a2                	ld	ra,8(sp)
    80004830:	6402                	ld	s0,0(sp)
    80004832:	0141                	addi	sp,sp,16
    80004834:	8082                	ret

0000000080004836 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004836:	1101                	addi	sp,sp,-32
    80004838:	ec06                	sd	ra,24(sp)
    8000483a:	e822                	sd	s0,16(sp)
    8000483c:	e426                	sd	s1,8(sp)
    8000483e:	e04a                	sd	s2,0(sp)
    80004840:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004842:	0001d917          	auipc	s2,0x1d
    80004846:	5ae90913          	addi	s2,s2,1454 # 80021df0 <log>
    8000484a:	01892583          	lw	a1,24(s2)
    8000484e:	02892503          	lw	a0,40(s2)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	ff2080e7          	jalr	-14(ra) # 80003844 <bread>
    8000485a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000485c:	02c92683          	lw	a3,44(s2)
    80004860:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004862:	02d05763          	blez	a3,80004890 <write_head+0x5a>
    80004866:	0001d797          	auipc	a5,0x1d
    8000486a:	5ba78793          	addi	a5,a5,1466 # 80021e20 <log+0x30>
    8000486e:	05c50713          	addi	a4,a0,92
    80004872:	36fd                	addiw	a3,a3,-1
    80004874:	1682                	slli	a3,a3,0x20
    80004876:	9281                	srli	a3,a3,0x20
    80004878:	068a                	slli	a3,a3,0x2
    8000487a:	0001d617          	auipc	a2,0x1d
    8000487e:	5aa60613          	addi	a2,a2,1450 # 80021e24 <log+0x34>
    80004882:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004884:	4390                	lw	a2,0(a5)
    80004886:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004888:	0791                	addi	a5,a5,4
    8000488a:	0711                	addi	a4,a4,4
    8000488c:	fed79ce3          	bne	a5,a3,80004884 <write_head+0x4e>
  }
  bwrite(buf);
    80004890:	8526                	mv	a0,s1
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	0a4080e7          	jalr	164(ra) # 80003936 <bwrite>
  brelse(buf);
    8000489a:	8526                	mv	a0,s1
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	0d8080e7          	jalr	216(ra) # 80003974 <brelse>
}
    800048a4:	60e2                	ld	ra,24(sp)
    800048a6:	6442                	ld	s0,16(sp)
    800048a8:	64a2                	ld	s1,8(sp)
    800048aa:	6902                	ld	s2,0(sp)
    800048ac:	6105                	addi	sp,sp,32
    800048ae:	8082                	ret

00000000800048b0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b0:	0001d797          	auipc	a5,0x1d
    800048b4:	56c7a783          	lw	a5,1388(a5) # 80021e1c <log+0x2c>
    800048b8:	0af05d63          	blez	a5,80004972 <install_trans+0xc2>
{
    800048bc:	7139                	addi	sp,sp,-64
    800048be:	fc06                	sd	ra,56(sp)
    800048c0:	f822                	sd	s0,48(sp)
    800048c2:	f426                	sd	s1,40(sp)
    800048c4:	f04a                	sd	s2,32(sp)
    800048c6:	ec4e                	sd	s3,24(sp)
    800048c8:	e852                	sd	s4,16(sp)
    800048ca:	e456                	sd	s5,8(sp)
    800048cc:	e05a                	sd	s6,0(sp)
    800048ce:	0080                	addi	s0,sp,64
    800048d0:	8b2a                	mv	s6,a0
    800048d2:	0001da97          	auipc	s5,0x1d
    800048d6:	54ea8a93          	addi	s5,s5,1358 # 80021e20 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048da:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048dc:	0001d997          	auipc	s3,0x1d
    800048e0:	51498993          	addi	s3,s3,1300 # 80021df0 <log>
    800048e4:	a035                	j	80004910 <install_trans+0x60>
      bunpin(dbuf);
    800048e6:	8526                	mv	a0,s1
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	166080e7          	jalr	358(ra) # 80003a4e <bunpin>
    brelse(lbuf);
    800048f0:	854a                	mv	a0,s2
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	082080e7          	jalr	130(ra) # 80003974 <brelse>
    brelse(dbuf);
    800048fa:	8526                	mv	a0,s1
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	078080e7          	jalr	120(ra) # 80003974 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004904:	2a05                	addiw	s4,s4,1
    80004906:	0a91                	addi	s5,s5,4
    80004908:	02c9a783          	lw	a5,44(s3)
    8000490c:	04fa5963          	bge	s4,a5,8000495e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004910:	0189a583          	lw	a1,24(s3)
    80004914:	014585bb          	addw	a1,a1,s4
    80004918:	2585                	addiw	a1,a1,1
    8000491a:	0289a503          	lw	a0,40(s3)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	f26080e7          	jalr	-218(ra) # 80003844 <bread>
    80004926:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004928:	000aa583          	lw	a1,0(s5)
    8000492c:	0289a503          	lw	a0,40(s3)
    80004930:	fffff097          	auipc	ra,0xfffff
    80004934:	f14080e7          	jalr	-236(ra) # 80003844 <bread>
    80004938:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000493a:	40000613          	li	a2,1024
    8000493e:	05890593          	addi	a1,s2,88
    80004942:	05850513          	addi	a0,a0,88
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	3fa080e7          	jalr	1018(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000494e:	8526                	mv	a0,s1
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	fe6080e7          	jalr	-26(ra) # 80003936 <bwrite>
    if(recovering == 0)
    80004958:	f80b1ce3          	bnez	s6,800048f0 <install_trans+0x40>
    8000495c:	b769                	j	800048e6 <install_trans+0x36>
}
    8000495e:	70e2                	ld	ra,56(sp)
    80004960:	7442                	ld	s0,48(sp)
    80004962:	74a2                	ld	s1,40(sp)
    80004964:	7902                	ld	s2,32(sp)
    80004966:	69e2                	ld	s3,24(sp)
    80004968:	6a42                	ld	s4,16(sp)
    8000496a:	6aa2                	ld	s5,8(sp)
    8000496c:	6b02                	ld	s6,0(sp)
    8000496e:	6121                	addi	sp,sp,64
    80004970:	8082                	ret
    80004972:	8082                	ret

0000000080004974 <initlog>:
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	1800                	addi	s0,sp,48
    80004982:	892a                	mv	s2,a0
    80004984:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004986:	0001d497          	auipc	s1,0x1d
    8000498a:	46a48493          	addi	s1,s1,1130 # 80021df0 <log>
    8000498e:	00004597          	auipc	a1,0x4
    80004992:	e1258593          	addi	a1,a1,-494 # 800087a0 <syscalls+0x1f0>
    80004996:	8526                	mv	a0,s1
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	1bc080e7          	jalr	444(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800049a0:	0149a583          	lw	a1,20(s3)
    800049a4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800049a6:	0109a783          	lw	a5,16(s3)
    800049aa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800049ac:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800049b0:	854a                	mv	a0,s2
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	e92080e7          	jalr	-366(ra) # 80003844 <bread>
  log.lh.n = lh->n;
    800049ba:	4d3c                	lw	a5,88(a0)
    800049bc:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049be:	02f05563          	blez	a5,800049e8 <initlog+0x74>
    800049c2:	05c50713          	addi	a4,a0,92
    800049c6:	0001d697          	auipc	a3,0x1d
    800049ca:	45a68693          	addi	a3,a3,1114 # 80021e20 <log+0x30>
    800049ce:	37fd                	addiw	a5,a5,-1
    800049d0:	1782                	slli	a5,a5,0x20
    800049d2:	9381                	srli	a5,a5,0x20
    800049d4:	078a                	slli	a5,a5,0x2
    800049d6:	06050613          	addi	a2,a0,96
    800049da:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800049dc:	4310                	lw	a2,0(a4)
    800049de:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800049e0:	0711                	addi	a4,a4,4
    800049e2:	0691                	addi	a3,a3,4
    800049e4:	fef71ce3          	bne	a4,a5,800049dc <initlog+0x68>
  brelse(buf);
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	f8c080e7          	jalr	-116(ra) # 80003974 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049f0:	4505                	li	a0,1
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	ebe080e7          	jalr	-322(ra) # 800048b0 <install_trans>
  log.lh.n = 0;
    800049fa:	0001d797          	auipc	a5,0x1d
    800049fe:	4207a123          	sw	zero,1058(a5) # 80021e1c <log+0x2c>
  write_head(); // clear the log
    80004a02:	00000097          	auipc	ra,0x0
    80004a06:	e34080e7          	jalr	-460(ra) # 80004836 <write_head>
}
    80004a0a:	70a2                	ld	ra,40(sp)
    80004a0c:	7402                	ld	s0,32(sp)
    80004a0e:	64e2                	ld	s1,24(sp)
    80004a10:	6942                	ld	s2,16(sp)
    80004a12:	69a2                	ld	s3,8(sp)
    80004a14:	6145                	addi	sp,sp,48
    80004a16:	8082                	ret

0000000080004a18 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004a18:	1101                	addi	sp,sp,-32
    80004a1a:	ec06                	sd	ra,24(sp)
    80004a1c:	e822                	sd	s0,16(sp)
    80004a1e:	e426                	sd	s1,8(sp)
    80004a20:	e04a                	sd	s2,0(sp)
    80004a22:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a24:	0001d517          	auipc	a0,0x1d
    80004a28:	3cc50513          	addi	a0,a0,972 # 80021df0 <log>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	1b8080e7          	jalr	440(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004a34:	0001d497          	auipc	s1,0x1d
    80004a38:	3bc48493          	addi	s1,s1,956 # 80021df0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a3c:	4979                	li	s2,30
    80004a3e:	a039                	j	80004a4c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a40:	85a6                	mv	a1,s1
    80004a42:	8526                	mv	a0,s1
    80004a44:	ffffe097          	auipc	ra,0xffffe
    80004a48:	baa080e7          	jalr	-1110(ra) # 800025ee <sleep>
    if(log.committing){
    80004a4c:	50dc                	lw	a5,36(s1)
    80004a4e:	fbed                	bnez	a5,80004a40 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a50:	509c                	lw	a5,32(s1)
    80004a52:	0017871b          	addiw	a4,a5,1
    80004a56:	0007069b          	sext.w	a3,a4
    80004a5a:	0027179b          	slliw	a5,a4,0x2
    80004a5e:	9fb9                	addw	a5,a5,a4
    80004a60:	0017979b          	slliw	a5,a5,0x1
    80004a64:	54d8                	lw	a4,44(s1)
    80004a66:	9fb9                	addw	a5,a5,a4
    80004a68:	00f95963          	bge	s2,a5,80004a7a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a6c:	85a6                	mv	a1,s1
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffe097          	auipc	ra,0xffffe
    80004a74:	b7e080e7          	jalr	-1154(ra) # 800025ee <sleep>
    80004a78:	bfd1                	j	80004a4c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a7a:	0001d517          	auipc	a0,0x1d
    80004a7e:	37650513          	addi	a0,a0,886 # 80021df0 <log>
    80004a82:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	214080e7          	jalr	532(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	64a2                	ld	s1,8(sp)
    80004a92:	6902                	ld	s2,0(sp)
    80004a94:	6105                	addi	sp,sp,32
    80004a96:	8082                	ret

0000000080004a98 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a98:	7139                	addi	sp,sp,-64
    80004a9a:	fc06                	sd	ra,56(sp)
    80004a9c:	f822                	sd	s0,48(sp)
    80004a9e:	f426                	sd	s1,40(sp)
    80004aa0:	f04a                	sd	s2,32(sp)
    80004aa2:	ec4e                	sd	s3,24(sp)
    80004aa4:	e852                	sd	s4,16(sp)
    80004aa6:	e456                	sd	s5,8(sp)
    80004aa8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004aaa:	0001d497          	auipc	s1,0x1d
    80004aae:	34648493          	addi	s1,s1,838 # 80021df0 <log>
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	130080e7          	jalr	304(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004abc:	509c                	lw	a5,32(s1)
    80004abe:	37fd                	addiw	a5,a5,-1
    80004ac0:	0007891b          	sext.w	s2,a5
    80004ac4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004ac6:	50dc                	lw	a5,36(s1)
    80004ac8:	efb9                	bnez	a5,80004b26 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004aca:	06091663          	bnez	s2,80004b36 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004ace:	0001d497          	auipc	s1,0x1d
    80004ad2:	32248493          	addi	s1,s1,802 # 80021df0 <log>
    80004ad6:	4785                	li	a5,1
    80004ad8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004ada:	8526                	mv	a0,s1
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1bc080e7          	jalr	444(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ae4:	54dc                	lw	a5,44(s1)
    80004ae6:	06f04763          	bgtz	a5,80004b54 <end_op+0xbc>
    acquire(&log.lock);
    80004aea:	0001d497          	auipc	s1,0x1d
    80004aee:	30648493          	addi	s1,s1,774 # 80021df0 <log>
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	0f0080e7          	jalr	240(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004afc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	122080e7          	jalr	290(ra) # 80002c24 <wakeup>
    release(&log.lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	18c080e7          	jalr	396(ra) # 80000c98 <release>
}
    80004b14:	70e2                	ld	ra,56(sp)
    80004b16:	7442                	ld	s0,48(sp)
    80004b18:	74a2                	ld	s1,40(sp)
    80004b1a:	7902                	ld	s2,32(sp)
    80004b1c:	69e2                	ld	s3,24(sp)
    80004b1e:	6a42                	ld	s4,16(sp)
    80004b20:	6aa2                	ld	s5,8(sp)
    80004b22:	6121                	addi	sp,sp,64
    80004b24:	8082                	ret
    panic("log.committing");
    80004b26:	00004517          	auipc	a0,0x4
    80004b2a:	c8250513          	addi	a0,a0,-894 # 800087a8 <syscalls+0x1f8>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	a10080e7          	jalr	-1520(ra) # 8000053e <panic>
    wakeup(&log);
    80004b36:	0001d497          	auipc	s1,0x1d
    80004b3a:	2ba48493          	addi	s1,s1,698 # 80021df0 <log>
    80004b3e:	8526                	mv	a0,s1
    80004b40:	ffffe097          	auipc	ra,0xffffe
    80004b44:	0e4080e7          	jalr	228(ra) # 80002c24 <wakeup>
  release(&log.lock);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(do_commit){
    80004b52:	b7c9                	j	80004b14 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b54:	0001da97          	auipc	s5,0x1d
    80004b58:	2cca8a93          	addi	s5,s5,716 # 80021e20 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b5c:	0001da17          	auipc	s4,0x1d
    80004b60:	294a0a13          	addi	s4,s4,660 # 80021df0 <log>
    80004b64:	018a2583          	lw	a1,24(s4)
    80004b68:	012585bb          	addw	a1,a1,s2
    80004b6c:	2585                	addiw	a1,a1,1
    80004b6e:	028a2503          	lw	a0,40(s4)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	cd2080e7          	jalr	-814(ra) # 80003844 <bread>
    80004b7a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b7c:	000aa583          	lw	a1,0(s5)
    80004b80:	028a2503          	lw	a0,40(s4)
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	cc0080e7          	jalr	-832(ra) # 80003844 <bread>
    80004b8c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b8e:	40000613          	li	a2,1024
    80004b92:	05850593          	addi	a1,a0,88
    80004b96:	05848513          	addi	a0,s1,88
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	1a6080e7          	jalr	422(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	fffff097          	auipc	ra,0xfffff
    80004ba8:	d92080e7          	jalr	-622(ra) # 80003936 <bwrite>
    brelse(from);
    80004bac:	854e                	mv	a0,s3
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	dc6080e7          	jalr	-570(ra) # 80003974 <brelse>
    brelse(to);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	fffff097          	auipc	ra,0xfffff
    80004bbc:	dbc080e7          	jalr	-580(ra) # 80003974 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bc0:	2905                	addiw	s2,s2,1
    80004bc2:	0a91                	addi	s5,s5,4
    80004bc4:	02ca2783          	lw	a5,44(s4)
    80004bc8:	f8f94ee3          	blt	s2,a5,80004b64 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	c6a080e7          	jalr	-918(ra) # 80004836 <write_head>
    install_trans(0); // Now install writes to home locations
    80004bd4:	4501                	li	a0,0
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	cda080e7          	jalr	-806(ra) # 800048b0 <install_trans>
    log.lh.n = 0;
    80004bde:	0001d797          	auipc	a5,0x1d
    80004be2:	2207af23          	sw	zero,574(a5) # 80021e1c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004be6:	00000097          	auipc	ra,0x0
    80004bea:	c50080e7          	jalr	-944(ra) # 80004836 <write_head>
    80004bee:	bdf5                	j	80004aea <end_op+0x52>

0000000080004bf0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bf0:	1101                	addi	sp,sp,-32
    80004bf2:	ec06                	sd	ra,24(sp)
    80004bf4:	e822                	sd	s0,16(sp)
    80004bf6:	e426                	sd	s1,8(sp)
    80004bf8:	e04a                	sd	s2,0(sp)
    80004bfa:	1000                	addi	s0,sp,32
    80004bfc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004bfe:	0001d917          	auipc	s2,0x1d
    80004c02:	1f290913          	addi	s2,s2,498 # 80021df0 <log>
    80004c06:	854a                	mv	a0,s2
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	fdc080e7          	jalr	-36(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004c10:	02c92603          	lw	a2,44(s2)
    80004c14:	47f5                	li	a5,29
    80004c16:	06c7c563          	blt	a5,a2,80004c80 <log_write+0x90>
    80004c1a:	0001d797          	auipc	a5,0x1d
    80004c1e:	1f27a783          	lw	a5,498(a5) # 80021e0c <log+0x1c>
    80004c22:	37fd                	addiw	a5,a5,-1
    80004c24:	04f65e63          	bge	a2,a5,80004c80 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c28:	0001d797          	auipc	a5,0x1d
    80004c2c:	1e87a783          	lw	a5,488(a5) # 80021e10 <log+0x20>
    80004c30:	06f05063          	blez	a5,80004c90 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c34:	4781                	li	a5,0
    80004c36:	06c05563          	blez	a2,80004ca0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c3a:	44cc                	lw	a1,12(s1)
    80004c3c:	0001d717          	auipc	a4,0x1d
    80004c40:	1e470713          	addi	a4,a4,484 # 80021e20 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c44:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004c46:	4314                	lw	a3,0(a4)
    80004c48:	04b68c63          	beq	a3,a1,80004ca0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c4c:	2785                	addiw	a5,a5,1
    80004c4e:	0711                	addi	a4,a4,4
    80004c50:	fef61be3          	bne	a2,a5,80004c46 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c54:	0621                	addi	a2,a2,8
    80004c56:	060a                	slli	a2,a2,0x2
    80004c58:	0001d797          	auipc	a5,0x1d
    80004c5c:	19878793          	addi	a5,a5,408 # 80021df0 <log>
    80004c60:	963e                	add	a2,a2,a5
    80004c62:	44dc                	lw	a5,12(s1)
    80004c64:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c66:	8526                	mv	a0,s1
    80004c68:	fffff097          	auipc	ra,0xfffff
    80004c6c:	daa080e7          	jalr	-598(ra) # 80003a12 <bpin>
    log.lh.n++;
    80004c70:	0001d717          	auipc	a4,0x1d
    80004c74:	18070713          	addi	a4,a4,384 # 80021df0 <log>
    80004c78:	575c                	lw	a5,44(a4)
    80004c7a:	2785                	addiw	a5,a5,1
    80004c7c:	d75c                	sw	a5,44(a4)
    80004c7e:	a835                	j	80004cba <log_write+0xca>
    panic("too big a transaction");
    80004c80:	00004517          	auipc	a0,0x4
    80004c84:	b3850513          	addi	a0,a0,-1224 # 800087b8 <syscalls+0x208>
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	8b6080e7          	jalr	-1866(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004c90:	00004517          	auipc	a0,0x4
    80004c94:	b4050513          	addi	a0,a0,-1216 # 800087d0 <syscalls+0x220>
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	8a6080e7          	jalr	-1882(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004ca0:	00878713          	addi	a4,a5,8
    80004ca4:	00271693          	slli	a3,a4,0x2
    80004ca8:	0001d717          	auipc	a4,0x1d
    80004cac:	14870713          	addi	a4,a4,328 # 80021df0 <log>
    80004cb0:	9736                	add	a4,a4,a3
    80004cb2:	44d4                	lw	a3,12(s1)
    80004cb4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004cb6:	faf608e3          	beq	a2,a5,80004c66 <log_write+0x76>
  }
  release(&log.lock);
    80004cba:	0001d517          	auipc	a0,0x1d
    80004cbe:	13650513          	addi	a0,a0,310 # 80021df0 <log>
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
}
    80004cca:	60e2                	ld	ra,24(sp)
    80004ccc:	6442                	ld	s0,16(sp)
    80004cce:	64a2                	ld	s1,8(sp)
    80004cd0:	6902                	ld	s2,0(sp)
    80004cd2:	6105                	addi	sp,sp,32
    80004cd4:	8082                	ret

0000000080004cd6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cd6:	1101                	addi	sp,sp,-32
    80004cd8:	ec06                	sd	ra,24(sp)
    80004cda:	e822                	sd	s0,16(sp)
    80004cdc:	e426                	sd	s1,8(sp)
    80004cde:	e04a                	sd	s2,0(sp)
    80004ce0:	1000                	addi	s0,sp,32
    80004ce2:	84aa                	mv	s1,a0
    80004ce4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ce6:	00004597          	auipc	a1,0x4
    80004cea:	b0a58593          	addi	a1,a1,-1270 # 800087f0 <syscalls+0x240>
    80004cee:	0521                	addi	a0,a0,8
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	e64080e7          	jalr	-412(ra) # 80000b54 <initlock>
  lk->name = name;
    80004cf8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004cfc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d00:	0204a423          	sw	zero,40(s1)
}
    80004d04:	60e2                	ld	ra,24(sp)
    80004d06:	6442                	ld	s0,16(sp)
    80004d08:	64a2                	ld	s1,8(sp)
    80004d0a:	6902                	ld	s2,0(sp)
    80004d0c:	6105                	addi	sp,sp,32
    80004d0e:	8082                	ret

0000000080004d10 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004d10:	1101                	addi	sp,sp,-32
    80004d12:	ec06                	sd	ra,24(sp)
    80004d14:	e822                	sd	s0,16(sp)
    80004d16:	e426                	sd	s1,8(sp)
    80004d18:	e04a                	sd	s2,0(sp)
    80004d1a:	1000                	addi	s0,sp,32
    80004d1c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d1e:	00850913          	addi	s2,a0,8
    80004d22:	854a                	mv	a0,s2
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	ec0080e7          	jalr	-320(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004d2c:	409c                	lw	a5,0(s1)
    80004d2e:	cb89                	beqz	a5,80004d40 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d30:	85ca                	mv	a1,s2
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffe097          	auipc	ra,0xffffe
    80004d38:	8ba080e7          	jalr	-1862(ra) # 800025ee <sleep>
  while (lk->locked) {
    80004d3c:	409c                	lw	a5,0(s1)
    80004d3e:	fbed                	bnez	a5,80004d30 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d40:	4785                	li	a5,1
    80004d42:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	202080e7          	jalr	514(ra) # 80001f46 <myproc>
    80004d4c:	591c                	lw	a5,48(a0)
    80004d4e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d50:	854a                	mv	a0,s2
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	f46080e7          	jalr	-186(ra) # 80000c98 <release>
}
    80004d5a:	60e2                	ld	ra,24(sp)
    80004d5c:	6442                	ld	s0,16(sp)
    80004d5e:	64a2                	ld	s1,8(sp)
    80004d60:	6902                	ld	s2,0(sp)
    80004d62:	6105                	addi	sp,sp,32
    80004d64:	8082                	ret

0000000080004d66 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d66:	1101                	addi	sp,sp,-32
    80004d68:	ec06                	sd	ra,24(sp)
    80004d6a:	e822                	sd	s0,16(sp)
    80004d6c:	e426                	sd	s1,8(sp)
    80004d6e:	e04a                	sd	s2,0(sp)
    80004d70:	1000                	addi	s0,sp,32
    80004d72:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d74:	00850913          	addi	s2,a0,8
    80004d78:	854a                	mv	a0,s2
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	e6a080e7          	jalr	-406(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004d82:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d86:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffe097          	auipc	ra,0xffffe
    80004d90:	e98080e7          	jalr	-360(ra) # 80002c24 <wakeup>
  release(&lk->lk);
    80004d94:	854a                	mv	a0,s2
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	f02080e7          	jalr	-254(ra) # 80000c98 <release>
}
    80004d9e:	60e2                	ld	ra,24(sp)
    80004da0:	6442                	ld	s0,16(sp)
    80004da2:	64a2                	ld	s1,8(sp)
    80004da4:	6902                	ld	s2,0(sp)
    80004da6:	6105                	addi	sp,sp,32
    80004da8:	8082                	ret

0000000080004daa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004daa:	7179                	addi	sp,sp,-48
    80004dac:	f406                	sd	ra,40(sp)
    80004dae:	f022                	sd	s0,32(sp)
    80004db0:	ec26                	sd	s1,24(sp)
    80004db2:	e84a                	sd	s2,16(sp)
    80004db4:	e44e                	sd	s3,8(sp)
    80004db6:	1800                	addi	s0,sp,48
    80004db8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004dba:	00850913          	addi	s2,a0,8
    80004dbe:	854a                	mv	a0,s2
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	e24080e7          	jalr	-476(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dc8:	409c                	lw	a5,0(s1)
    80004dca:	ef99                	bnez	a5,80004de8 <holdingsleep+0x3e>
    80004dcc:	4481                	li	s1,0
  release(&lk->lk);
    80004dce:	854a                	mv	a0,s2
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	ec8080e7          	jalr	-312(ra) # 80000c98 <release>
  return r;
}
    80004dd8:	8526                	mv	a0,s1
    80004dda:	70a2                	ld	ra,40(sp)
    80004ddc:	7402                	ld	s0,32(sp)
    80004dde:	64e2                	ld	s1,24(sp)
    80004de0:	6942                	ld	s2,16(sp)
    80004de2:	69a2                	ld	s3,8(sp)
    80004de4:	6145                	addi	sp,sp,48
    80004de6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004de8:	0284a983          	lw	s3,40(s1)
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	15a080e7          	jalr	346(ra) # 80001f46 <myproc>
    80004df4:	5904                	lw	s1,48(a0)
    80004df6:	413484b3          	sub	s1,s1,s3
    80004dfa:	0014b493          	seqz	s1,s1
    80004dfe:	bfc1                	j	80004dce <holdingsleep+0x24>

0000000080004e00 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004e00:	1141                	addi	sp,sp,-16
    80004e02:	e406                	sd	ra,8(sp)
    80004e04:	e022                	sd	s0,0(sp)
    80004e06:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004e08:	00004597          	auipc	a1,0x4
    80004e0c:	9f858593          	addi	a1,a1,-1544 # 80008800 <syscalls+0x250>
    80004e10:	0001d517          	auipc	a0,0x1d
    80004e14:	12850513          	addi	a0,a0,296 # 80021f38 <ftable>
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	d3c080e7          	jalr	-708(ra) # 80000b54 <initlock>
}
    80004e20:	60a2                	ld	ra,8(sp)
    80004e22:	6402                	ld	s0,0(sp)
    80004e24:	0141                	addi	sp,sp,16
    80004e26:	8082                	ret

0000000080004e28 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e28:	1101                	addi	sp,sp,-32
    80004e2a:	ec06                	sd	ra,24(sp)
    80004e2c:	e822                	sd	s0,16(sp)
    80004e2e:	e426                	sd	s1,8(sp)
    80004e30:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e32:	0001d517          	auipc	a0,0x1d
    80004e36:	10650513          	addi	a0,a0,262 # 80021f38 <ftable>
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	daa080e7          	jalr	-598(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e42:	0001d497          	auipc	s1,0x1d
    80004e46:	10e48493          	addi	s1,s1,270 # 80021f50 <ftable+0x18>
    80004e4a:	0001e717          	auipc	a4,0x1e
    80004e4e:	0a670713          	addi	a4,a4,166 # 80022ef0 <ftable+0xfb8>
    if(f->ref == 0){
    80004e52:	40dc                	lw	a5,4(s1)
    80004e54:	cf99                	beqz	a5,80004e72 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e56:	02848493          	addi	s1,s1,40
    80004e5a:	fee49ce3          	bne	s1,a4,80004e52 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e5e:	0001d517          	auipc	a0,0x1d
    80004e62:	0da50513          	addi	a0,a0,218 # 80021f38 <ftable>
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	e32080e7          	jalr	-462(ra) # 80000c98 <release>
  return 0;
    80004e6e:	4481                	li	s1,0
    80004e70:	a819                	j	80004e86 <filealloc+0x5e>
      f->ref = 1;
    80004e72:	4785                	li	a5,1
    80004e74:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e76:	0001d517          	auipc	a0,0x1d
    80004e7a:	0c250513          	addi	a0,a0,194 # 80021f38 <ftable>
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	e1a080e7          	jalr	-486(ra) # 80000c98 <release>
}
    80004e86:	8526                	mv	a0,s1
    80004e88:	60e2                	ld	ra,24(sp)
    80004e8a:	6442                	ld	s0,16(sp)
    80004e8c:	64a2                	ld	s1,8(sp)
    80004e8e:	6105                	addi	sp,sp,32
    80004e90:	8082                	ret

0000000080004e92 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e92:	1101                	addi	sp,sp,-32
    80004e94:	ec06                	sd	ra,24(sp)
    80004e96:	e822                	sd	s0,16(sp)
    80004e98:	e426                	sd	s1,8(sp)
    80004e9a:	1000                	addi	s0,sp,32
    80004e9c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e9e:	0001d517          	auipc	a0,0x1d
    80004ea2:	09a50513          	addi	a0,a0,154 # 80021f38 <ftable>
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	d3e080e7          	jalr	-706(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004eae:	40dc                	lw	a5,4(s1)
    80004eb0:	02f05263          	blez	a5,80004ed4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004eb4:	2785                	addiw	a5,a5,1
    80004eb6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004eb8:	0001d517          	auipc	a0,0x1d
    80004ebc:	08050513          	addi	a0,a0,128 # 80021f38 <ftable>
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	dd8080e7          	jalr	-552(ra) # 80000c98 <release>
  return f;
}
    80004ec8:	8526                	mv	a0,s1
    80004eca:	60e2                	ld	ra,24(sp)
    80004ecc:	6442                	ld	s0,16(sp)
    80004ece:	64a2                	ld	s1,8(sp)
    80004ed0:	6105                	addi	sp,sp,32
    80004ed2:	8082                	ret
    panic("filedup");
    80004ed4:	00004517          	auipc	a0,0x4
    80004ed8:	93450513          	addi	a0,a0,-1740 # 80008808 <syscalls+0x258>
    80004edc:	ffffb097          	auipc	ra,0xffffb
    80004ee0:	662080e7          	jalr	1634(ra) # 8000053e <panic>

0000000080004ee4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ee4:	7139                	addi	sp,sp,-64
    80004ee6:	fc06                	sd	ra,56(sp)
    80004ee8:	f822                	sd	s0,48(sp)
    80004eea:	f426                	sd	s1,40(sp)
    80004eec:	f04a                	sd	s2,32(sp)
    80004eee:	ec4e                	sd	s3,24(sp)
    80004ef0:	e852                	sd	s4,16(sp)
    80004ef2:	e456                	sd	s5,8(sp)
    80004ef4:	0080                	addi	s0,sp,64
    80004ef6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ef8:	0001d517          	auipc	a0,0x1d
    80004efc:	04050513          	addi	a0,a0,64 # 80021f38 <ftable>
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004f08:	40dc                	lw	a5,4(s1)
    80004f0a:	06f05163          	blez	a5,80004f6c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004f0e:	37fd                	addiw	a5,a5,-1
    80004f10:	0007871b          	sext.w	a4,a5
    80004f14:	c0dc                	sw	a5,4(s1)
    80004f16:	06e04363          	bgtz	a4,80004f7c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004f1a:	0004a903          	lw	s2,0(s1)
    80004f1e:	0094ca83          	lbu	s5,9(s1)
    80004f22:	0104ba03          	ld	s4,16(s1)
    80004f26:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f2a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f2e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f32:	0001d517          	auipc	a0,0x1d
    80004f36:	00650513          	addi	a0,a0,6 # 80021f38 <ftable>
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	d5e080e7          	jalr	-674(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004f42:	4785                	li	a5,1
    80004f44:	04f90d63          	beq	s2,a5,80004f9e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f48:	3979                	addiw	s2,s2,-2
    80004f4a:	4785                	li	a5,1
    80004f4c:	0527e063          	bltu	a5,s2,80004f8c <fileclose+0xa8>
    begin_op();
    80004f50:	00000097          	auipc	ra,0x0
    80004f54:	ac8080e7          	jalr	-1336(ra) # 80004a18 <begin_op>
    iput(ff.ip);
    80004f58:	854e                	mv	a0,s3
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	2a6080e7          	jalr	678(ra) # 80004200 <iput>
    end_op();
    80004f62:	00000097          	auipc	ra,0x0
    80004f66:	b36080e7          	jalr	-1226(ra) # 80004a98 <end_op>
    80004f6a:	a00d                	j	80004f8c <fileclose+0xa8>
    panic("fileclose");
    80004f6c:	00004517          	auipc	a0,0x4
    80004f70:	8a450513          	addi	a0,a0,-1884 # 80008810 <syscalls+0x260>
    80004f74:	ffffb097          	auipc	ra,0xffffb
    80004f78:	5ca080e7          	jalr	1482(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004f7c:	0001d517          	auipc	a0,0x1d
    80004f80:	fbc50513          	addi	a0,a0,-68 # 80021f38 <ftable>
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
  }
}
    80004f8c:	70e2                	ld	ra,56(sp)
    80004f8e:	7442                	ld	s0,48(sp)
    80004f90:	74a2                	ld	s1,40(sp)
    80004f92:	7902                	ld	s2,32(sp)
    80004f94:	69e2                	ld	s3,24(sp)
    80004f96:	6a42                	ld	s4,16(sp)
    80004f98:	6aa2                	ld	s5,8(sp)
    80004f9a:	6121                	addi	sp,sp,64
    80004f9c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f9e:	85d6                	mv	a1,s5
    80004fa0:	8552                	mv	a0,s4
    80004fa2:	00000097          	auipc	ra,0x0
    80004fa6:	34c080e7          	jalr	844(ra) # 800052ee <pipeclose>
    80004faa:	b7cd                	j	80004f8c <fileclose+0xa8>

0000000080004fac <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004fac:	715d                	addi	sp,sp,-80
    80004fae:	e486                	sd	ra,72(sp)
    80004fb0:	e0a2                	sd	s0,64(sp)
    80004fb2:	fc26                	sd	s1,56(sp)
    80004fb4:	f84a                	sd	s2,48(sp)
    80004fb6:	f44e                	sd	s3,40(sp)
    80004fb8:	0880                	addi	s0,sp,80
    80004fba:	84aa                	mv	s1,a0
    80004fbc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	f88080e7          	jalr	-120(ra) # 80001f46 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004fc6:	409c                	lw	a5,0(s1)
    80004fc8:	37f9                	addiw	a5,a5,-2
    80004fca:	4705                	li	a4,1
    80004fcc:	04f76763          	bltu	a4,a5,8000501a <filestat+0x6e>
    80004fd0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fd2:	6c88                	ld	a0,24(s1)
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	072080e7          	jalr	114(ra) # 80004046 <ilock>
    stati(f->ip, &st);
    80004fdc:	fb840593          	addi	a1,s0,-72
    80004fe0:	6c88                	ld	a0,24(s1)
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	2ee080e7          	jalr	750(ra) # 800042d0 <stati>
    iunlock(f->ip);
    80004fea:	6c88                	ld	a0,24(s1)
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	11c080e7          	jalr	284(ra) # 80004108 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ff4:	46e1                	li	a3,24
    80004ff6:	fb840613          	addi	a2,s0,-72
    80004ffa:	85ce                	mv	a1,s3
    80004ffc:	05093503          	ld	a0,80(s2)
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	672080e7          	jalr	1650(ra) # 80001672 <copyout>
    80005008:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000500c:	60a6                	ld	ra,72(sp)
    8000500e:	6406                	ld	s0,64(sp)
    80005010:	74e2                	ld	s1,56(sp)
    80005012:	7942                	ld	s2,48(sp)
    80005014:	79a2                	ld	s3,40(sp)
    80005016:	6161                	addi	sp,sp,80
    80005018:	8082                	ret
  return -1;
    8000501a:	557d                	li	a0,-1
    8000501c:	bfc5                	j	8000500c <filestat+0x60>

000000008000501e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000501e:	7179                	addi	sp,sp,-48
    80005020:	f406                	sd	ra,40(sp)
    80005022:	f022                	sd	s0,32(sp)
    80005024:	ec26                	sd	s1,24(sp)
    80005026:	e84a                	sd	s2,16(sp)
    80005028:	e44e                	sd	s3,8(sp)
    8000502a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000502c:	00854783          	lbu	a5,8(a0)
    80005030:	c3d5                	beqz	a5,800050d4 <fileread+0xb6>
    80005032:	84aa                	mv	s1,a0
    80005034:	89ae                	mv	s3,a1
    80005036:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005038:	411c                	lw	a5,0(a0)
    8000503a:	4705                	li	a4,1
    8000503c:	04e78963          	beq	a5,a4,8000508e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005040:	470d                	li	a4,3
    80005042:	04e78d63          	beq	a5,a4,8000509c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005046:	4709                	li	a4,2
    80005048:	06e79e63          	bne	a5,a4,800050c4 <fileread+0xa6>
    ilock(f->ip);
    8000504c:	6d08                	ld	a0,24(a0)
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	ff8080e7          	jalr	-8(ra) # 80004046 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005056:	874a                	mv	a4,s2
    80005058:	5094                	lw	a3,32(s1)
    8000505a:	864e                	mv	a2,s3
    8000505c:	4585                	li	a1,1
    8000505e:	6c88                	ld	a0,24(s1)
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	29a080e7          	jalr	666(ra) # 800042fa <readi>
    80005068:	892a                	mv	s2,a0
    8000506a:	00a05563          	blez	a0,80005074 <fileread+0x56>
      f->off += r;
    8000506e:	509c                	lw	a5,32(s1)
    80005070:	9fa9                	addw	a5,a5,a0
    80005072:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005074:	6c88                	ld	a0,24(s1)
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	092080e7          	jalr	146(ra) # 80004108 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000507e:	854a                	mv	a0,s2
    80005080:	70a2                	ld	ra,40(sp)
    80005082:	7402                	ld	s0,32(sp)
    80005084:	64e2                	ld	s1,24(sp)
    80005086:	6942                	ld	s2,16(sp)
    80005088:	69a2                	ld	s3,8(sp)
    8000508a:	6145                	addi	sp,sp,48
    8000508c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000508e:	6908                	ld	a0,16(a0)
    80005090:	00000097          	auipc	ra,0x0
    80005094:	3c8080e7          	jalr	968(ra) # 80005458 <piperead>
    80005098:	892a                	mv	s2,a0
    8000509a:	b7d5                	j	8000507e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000509c:	02451783          	lh	a5,36(a0)
    800050a0:	03079693          	slli	a3,a5,0x30
    800050a4:	92c1                	srli	a3,a3,0x30
    800050a6:	4725                	li	a4,9
    800050a8:	02d76863          	bltu	a4,a3,800050d8 <fileread+0xba>
    800050ac:	0792                	slli	a5,a5,0x4
    800050ae:	0001d717          	auipc	a4,0x1d
    800050b2:	dea70713          	addi	a4,a4,-534 # 80021e98 <devsw>
    800050b6:	97ba                	add	a5,a5,a4
    800050b8:	639c                	ld	a5,0(a5)
    800050ba:	c38d                	beqz	a5,800050dc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050bc:	4505                	li	a0,1
    800050be:	9782                	jalr	a5
    800050c0:	892a                	mv	s2,a0
    800050c2:	bf75                	j	8000507e <fileread+0x60>
    panic("fileread");
    800050c4:	00003517          	auipc	a0,0x3
    800050c8:	75c50513          	addi	a0,a0,1884 # 80008820 <syscalls+0x270>
    800050cc:	ffffb097          	auipc	ra,0xffffb
    800050d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    return -1;
    800050d4:	597d                	li	s2,-1
    800050d6:	b765                	j	8000507e <fileread+0x60>
      return -1;
    800050d8:	597d                	li	s2,-1
    800050da:	b755                	j	8000507e <fileread+0x60>
    800050dc:	597d                	li	s2,-1
    800050de:	b745                	j	8000507e <fileread+0x60>

00000000800050e0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050e0:	715d                	addi	sp,sp,-80
    800050e2:	e486                	sd	ra,72(sp)
    800050e4:	e0a2                	sd	s0,64(sp)
    800050e6:	fc26                	sd	s1,56(sp)
    800050e8:	f84a                	sd	s2,48(sp)
    800050ea:	f44e                	sd	s3,40(sp)
    800050ec:	f052                	sd	s4,32(sp)
    800050ee:	ec56                	sd	s5,24(sp)
    800050f0:	e85a                	sd	s6,16(sp)
    800050f2:	e45e                	sd	s7,8(sp)
    800050f4:	e062                	sd	s8,0(sp)
    800050f6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050f8:	00954783          	lbu	a5,9(a0)
    800050fc:	10078663          	beqz	a5,80005208 <filewrite+0x128>
    80005100:	892a                	mv	s2,a0
    80005102:	8aae                	mv	s5,a1
    80005104:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005106:	411c                	lw	a5,0(a0)
    80005108:	4705                	li	a4,1
    8000510a:	02e78263          	beq	a5,a4,8000512e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000510e:	470d                	li	a4,3
    80005110:	02e78663          	beq	a5,a4,8000513c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005114:	4709                	li	a4,2
    80005116:	0ee79163          	bne	a5,a4,800051f8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000511a:	0ac05d63          	blez	a2,800051d4 <filewrite+0xf4>
    int i = 0;
    8000511e:	4981                	li	s3,0
    80005120:	6b05                	lui	s6,0x1
    80005122:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005126:	6b85                	lui	s7,0x1
    80005128:	c00b8b9b          	addiw	s7,s7,-1024
    8000512c:	a861                	j	800051c4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000512e:	6908                	ld	a0,16(a0)
    80005130:	00000097          	auipc	ra,0x0
    80005134:	22e080e7          	jalr	558(ra) # 8000535e <pipewrite>
    80005138:	8a2a                	mv	s4,a0
    8000513a:	a045                	j	800051da <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000513c:	02451783          	lh	a5,36(a0)
    80005140:	03079693          	slli	a3,a5,0x30
    80005144:	92c1                	srli	a3,a3,0x30
    80005146:	4725                	li	a4,9
    80005148:	0cd76263          	bltu	a4,a3,8000520c <filewrite+0x12c>
    8000514c:	0792                	slli	a5,a5,0x4
    8000514e:	0001d717          	auipc	a4,0x1d
    80005152:	d4a70713          	addi	a4,a4,-694 # 80021e98 <devsw>
    80005156:	97ba                	add	a5,a5,a4
    80005158:	679c                	ld	a5,8(a5)
    8000515a:	cbdd                	beqz	a5,80005210 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000515c:	4505                	li	a0,1
    8000515e:	9782                	jalr	a5
    80005160:	8a2a                	mv	s4,a0
    80005162:	a8a5                	j	800051da <filewrite+0xfa>
    80005164:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	8b0080e7          	jalr	-1872(ra) # 80004a18 <begin_op>
      ilock(f->ip);
    80005170:	01893503          	ld	a0,24(s2)
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	ed2080e7          	jalr	-302(ra) # 80004046 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000517c:	8762                	mv	a4,s8
    8000517e:	02092683          	lw	a3,32(s2)
    80005182:	01598633          	add	a2,s3,s5
    80005186:	4585                	li	a1,1
    80005188:	01893503          	ld	a0,24(s2)
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	266080e7          	jalr	614(ra) # 800043f2 <writei>
    80005194:	84aa                	mv	s1,a0
    80005196:	00a05763          	blez	a0,800051a4 <filewrite+0xc4>
        f->off += r;
    8000519a:	02092783          	lw	a5,32(s2)
    8000519e:	9fa9                	addw	a5,a5,a0
    800051a0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800051a4:	01893503          	ld	a0,24(s2)
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	f60080e7          	jalr	-160(ra) # 80004108 <iunlock>
      end_op();
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	8e8080e7          	jalr	-1816(ra) # 80004a98 <end_op>

      if(r != n1){
    800051b8:	009c1f63          	bne	s8,s1,800051d6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051bc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051c0:	0149db63          	bge	s3,s4,800051d6 <filewrite+0xf6>
      int n1 = n - i;
    800051c4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051c8:	84be                	mv	s1,a5
    800051ca:	2781                	sext.w	a5,a5
    800051cc:	f8fb5ce3          	bge	s6,a5,80005164 <filewrite+0x84>
    800051d0:	84de                	mv	s1,s7
    800051d2:	bf49                	j	80005164 <filewrite+0x84>
    int i = 0;
    800051d4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051d6:	013a1f63          	bne	s4,s3,800051f4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051da:	8552                	mv	a0,s4
    800051dc:	60a6                	ld	ra,72(sp)
    800051de:	6406                	ld	s0,64(sp)
    800051e0:	74e2                	ld	s1,56(sp)
    800051e2:	7942                	ld	s2,48(sp)
    800051e4:	79a2                	ld	s3,40(sp)
    800051e6:	7a02                	ld	s4,32(sp)
    800051e8:	6ae2                	ld	s5,24(sp)
    800051ea:	6b42                	ld	s6,16(sp)
    800051ec:	6ba2                	ld	s7,8(sp)
    800051ee:	6c02                	ld	s8,0(sp)
    800051f0:	6161                	addi	sp,sp,80
    800051f2:	8082                	ret
    ret = (i == n ? n : -1);
    800051f4:	5a7d                	li	s4,-1
    800051f6:	b7d5                	j	800051da <filewrite+0xfa>
    panic("filewrite");
    800051f8:	00003517          	auipc	a0,0x3
    800051fc:	63850513          	addi	a0,a0,1592 # 80008830 <syscalls+0x280>
    80005200:	ffffb097          	auipc	ra,0xffffb
    80005204:	33e080e7          	jalr	830(ra) # 8000053e <panic>
    return -1;
    80005208:	5a7d                	li	s4,-1
    8000520a:	bfc1                	j	800051da <filewrite+0xfa>
      return -1;
    8000520c:	5a7d                	li	s4,-1
    8000520e:	b7f1                	j	800051da <filewrite+0xfa>
    80005210:	5a7d                	li	s4,-1
    80005212:	b7e1                	j	800051da <filewrite+0xfa>

0000000080005214 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005214:	7179                	addi	sp,sp,-48
    80005216:	f406                	sd	ra,40(sp)
    80005218:	f022                	sd	s0,32(sp)
    8000521a:	ec26                	sd	s1,24(sp)
    8000521c:	e84a                	sd	s2,16(sp)
    8000521e:	e44e                	sd	s3,8(sp)
    80005220:	e052                	sd	s4,0(sp)
    80005222:	1800                	addi	s0,sp,48
    80005224:	84aa                	mv	s1,a0
    80005226:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005228:	0005b023          	sd	zero,0(a1)
    8000522c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005230:	00000097          	auipc	ra,0x0
    80005234:	bf8080e7          	jalr	-1032(ra) # 80004e28 <filealloc>
    80005238:	e088                	sd	a0,0(s1)
    8000523a:	c551                	beqz	a0,800052c6 <pipealloc+0xb2>
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	bec080e7          	jalr	-1044(ra) # 80004e28 <filealloc>
    80005244:	00aa3023          	sd	a0,0(s4)
    80005248:	c92d                	beqz	a0,800052ba <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000524a:	ffffc097          	auipc	ra,0xffffc
    8000524e:	8aa080e7          	jalr	-1878(ra) # 80000af4 <kalloc>
    80005252:	892a                	mv	s2,a0
    80005254:	c125                	beqz	a0,800052b4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005256:	4985                	li	s3,1
    80005258:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000525c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005260:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005264:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005268:	00003597          	auipc	a1,0x3
    8000526c:	5d858593          	addi	a1,a1,1496 # 80008840 <syscalls+0x290>
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	8e4080e7          	jalr	-1820(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005278:	609c                	ld	a5,0(s1)
    8000527a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000527e:	609c                	ld	a5,0(s1)
    80005280:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005284:	609c                	ld	a5,0(s1)
    80005286:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000528a:	609c                	ld	a5,0(s1)
    8000528c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005290:	000a3783          	ld	a5,0(s4)
    80005294:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005298:	000a3783          	ld	a5,0(s4)
    8000529c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800052a0:	000a3783          	ld	a5,0(s4)
    800052a4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800052a8:	000a3783          	ld	a5,0(s4)
    800052ac:	0127b823          	sd	s2,16(a5)
  return 0;
    800052b0:	4501                	li	a0,0
    800052b2:	a025                	j	800052da <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800052b4:	6088                	ld	a0,0(s1)
    800052b6:	e501                	bnez	a0,800052be <pipealloc+0xaa>
    800052b8:	a039                	j	800052c6 <pipealloc+0xb2>
    800052ba:	6088                	ld	a0,0(s1)
    800052bc:	c51d                	beqz	a0,800052ea <pipealloc+0xd6>
    fileclose(*f0);
    800052be:	00000097          	auipc	ra,0x0
    800052c2:	c26080e7          	jalr	-986(ra) # 80004ee4 <fileclose>
  if(*f1)
    800052c6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800052ca:	557d                	li	a0,-1
  if(*f1)
    800052cc:	c799                	beqz	a5,800052da <pipealloc+0xc6>
    fileclose(*f1);
    800052ce:	853e                	mv	a0,a5
    800052d0:	00000097          	auipc	ra,0x0
    800052d4:	c14080e7          	jalr	-1004(ra) # 80004ee4 <fileclose>
  return -1;
    800052d8:	557d                	li	a0,-1
}
    800052da:	70a2                	ld	ra,40(sp)
    800052dc:	7402                	ld	s0,32(sp)
    800052de:	64e2                	ld	s1,24(sp)
    800052e0:	6942                	ld	s2,16(sp)
    800052e2:	69a2                	ld	s3,8(sp)
    800052e4:	6a02                	ld	s4,0(sp)
    800052e6:	6145                	addi	sp,sp,48
    800052e8:	8082                	ret
  return -1;
    800052ea:	557d                	li	a0,-1
    800052ec:	b7fd                	j	800052da <pipealloc+0xc6>

00000000800052ee <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800052ee:	1101                	addi	sp,sp,-32
    800052f0:	ec06                	sd	ra,24(sp)
    800052f2:	e822                	sd	s0,16(sp)
    800052f4:	e426                	sd	s1,8(sp)
    800052f6:	e04a                	sd	s2,0(sp)
    800052f8:	1000                	addi	s0,sp,32
    800052fa:	84aa                	mv	s1,a0
    800052fc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	8e6080e7          	jalr	-1818(ra) # 80000be4 <acquire>
  if(writable){
    80005306:	02090d63          	beqz	s2,80005340 <pipeclose+0x52>
    pi->writeopen = 0;
    8000530a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000530e:	21848513          	addi	a0,s1,536
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	912080e7          	jalr	-1774(ra) # 80002c24 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000531a:	2204b783          	ld	a5,544(s1)
    8000531e:	eb95                	bnez	a5,80005352 <pipeclose+0x64>
    release(&pi->lock);
    80005320:	8526                	mv	a0,s1
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000532a:	8526                	mv	a0,s1
    8000532c:	ffffb097          	auipc	ra,0xffffb
    80005330:	6cc080e7          	jalr	1740(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005334:	60e2                	ld	ra,24(sp)
    80005336:	6442                	ld	s0,16(sp)
    80005338:	64a2                	ld	s1,8(sp)
    8000533a:	6902                	ld	s2,0(sp)
    8000533c:	6105                	addi	sp,sp,32
    8000533e:	8082                	ret
    pi->readopen = 0;
    80005340:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005344:	21c48513          	addi	a0,s1,540
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	8dc080e7          	jalr	-1828(ra) # 80002c24 <wakeup>
    80005350:	b7e9                	j	8000531a <pipeclose+0x2c>
    release(&pi->lock);
    80005352:	8526                	mv	a0,s1
    80005354:	ffffc097          	auipc	ra,0xffffc
    80005358:	944080e7          	jalr	-1724(ra) # 80000c98 <release>
}
    8000535c:	bfe1                	j	80005334 <pipeclose+0x46>

000000008000535e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000535e:	7159                	addi	sp,sp,-112
    80005360:	f486                	sd	ra,104(sp)
    80005362:	f0a2                	sd	s0,96(sp)
    80005364:	eca6                	sd	s1,88(sp)
    80005366:	e8ca                	sd	s2,80(sp)
    80005368:	e4ce                	sd	s3,72(sp)
    8000536a:	e0d2                	sd	s4,64(sp)
    8000536c:	fc56                	sd	s5,56(sp)
    8000536e:	f85a                	sd	s6,48(sp)
    80005370:	f45e                	sd	s7,40(sp)
    80005372:	f062                	sd	s8,32(sp)
    80005374:	ec66                	sd	s9,24(sp)
    80005376:	1880                	addi	s0,sp,112
    80005378:	84aa                	mv	s1,a0
    8000537a:	8aae                	mv	s5,a1
    8000537c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000537e:	ffffd097          	auipc	ra,0xffffd
    80005382:	bc8080e7          	jalr	-1080(ra) # 80001f46 <myproc>
    80005386:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	85a080e7          	jalr	-1958(ra) # 80000be4 <acquire>
  while(i < n){
    80005392:	0d405163          	blez	s4,80005454 <pipewrite+0xf6>
    80005396:	8ba6                	mv	s7,s1
  int i = 0;
    80005398:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000539a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000539c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800053a0:	21c48c13          	addi	s8,s1,540
    800053a4:	a08d                	j	80005406 <pipewrite+0xa8>
      release(&pi->lock);
    800053a6:	8526                	mv	a0,s1
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
      return -1;
    800053b0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800053b2:	854a                	mv	a0,s2
    800053b4:	70a6                	ld	ra,104(sp)
    800053b6:	7406                	ld	s0,96(sp)
    800053b8:	64e6                	ld	s1,88(sp)
    800053ba:	6946                	ld	s2,80(sp)
    800053bc:	69a6                	ld	s3,72(sp)
    800053be:	6a06                	ld	s4,64(sp)
    800053c0:	7ae2                	ld	s5,56(sp)
    800053c2:	7b42                	ld	s6,48(sp)
    800053c4:	7ba2                	ld	s7,40(sp)
    800053c6:	7c02                	ld	s8,32(sp)
    800053c8:	6ce2                	ld	s9,24(sp)
    800053ca:	6165                	addi	sp,sp,112
    800053cc:	8082                	ret
      wakeup(&pi->nread);
    800053ce:	8566                	mv	a0,s9
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	854080e7          	jalr	-1964(ra) # 80002c24 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800053d8:	85de                	mv	a1,s7
    800053da:	8562                	mv	a0,s8
    800053dc:	ffffd097          	auipc	ra,0xffffd
    800053e0:	212080e7          	jalr	530(ra) # 800025ee <sleep>
    800053e4:	a839                	j	80005402 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800053e6:	21c4a783          	lw	a5,540(s1)
    800053ea:	0017871b          	addiw	a4,a5,1
    800053ee:	20e4ae23          	sw	a4,540(s1)
    800053f2:	1ff7f793          	andi	a5,a5,511
    800053f6:	97a6                	add	a5,a5,s1
    800053f8:	f9f44703          	lbu	a4,-97(s0)
    800053fc:	00e78c23          	sb	a4,24(a5)
      i++;
    80005400:	2905                	addiw	s2,s2,1
  while(i < n){
    80005402:	03495d63          	bge	s2,s4,8000543c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005406:	2204a783          	lw	a5,544(s1)
    8000540a:	dfd1                	beqz	a5,800053a6 <pipewrite+0x48>
    8000540c:	0289a783          	lw	a5,40(s3)
    80005410:	fbd9                	bnez	a5,800053a6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005412:	2184a783          	lw	a5,536(s1)
    80005416:	21c4a703          	lw	a4,540(s1)
    8000541a:	2007879b          	addiw	a5,a5,512
    8000541e:	faf708e3          	beq	a4,a5,800053ce <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005422:	4685                	li	a3,1
    80005424:	01590633          	add	a2,s2,s5
    80005428:	f9f40593          	addi	a1,s0,-97
    8000542c:	0509b503          	ld	a0,80(s3)
    80005430:	ffffc097          	auipc	ra,0xffffc
    80005434:	2ce080e7          	jalr	718(ra) # 800016fe <copyin>
    80005438:	fb6517e3          	bne	a0,s6,800053e6 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000543c:	21848513          	addi	a0,s1,536
    80005440:	ffffd097          	auipc	ra,0xffffd
    80005444:	7e4080e7          	jalr	2020(ra) # 80002c24 <wakeup>
  release(&pi->lock);
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
  return i;
    80005452:	b785                	j	800053b2 <pipewrite+0x54>
  int i = 0;
    80005454:	4901                	li	s2,0
    80005456:	b7dd                	j	8000543c <pipewrite+0xde>

0000000080005458 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005458:	715d                	addi	sp,sp,-80
    8000545a:	e486                	sd	ra,72(sp)
    8000545c:	e0a2                	sd	s0,64(sp)
    8000545e:	fc26                	sd	s1,56(sp)
    80005460:	f84a                	sd	s2,48(sp)
    80005462:	f44e                	sd	s3,40(sp)
    80005464:	f052                	sd	s4,32(sp)
    80005466:	ec56                	sd	s5,24(sp)
    80005468:	e85a                	sd	s6,16(sp)
    8000546a:	0880                	addi	s0,sp,80
    8000546c:	84aa                	mv	s1,a0
    8000546e:	892e                	mv	s2,a1
    80005470:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005472:	ffffd097          	auipc	ra,0xffffd
    80005476:	ad4080e7          	jalr	-1324(ra) # 80001f46 <myproc>
    8000547a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000547c:	8b26                	mv	s6,s1
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffb097          	auipc	ra,0xffffb
    80005484:	764080e7          	jalr	1892(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005488:	2184a703          	lw	a4,536(s1)
    8000548c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005490:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005494:	02f71463          	bne	a4,a5,800054bc <piperead+0x64>
    80005498:	2244a783          	lw	a5,548(s1)
    8000549c:	c385                	beqz	a5,800054bc <piperead+0x64>
    if(pr->killed){
    8000549e:	028a2783          	lw	a5,40(s4)
    800054a2:	ebc1                	bnez	a5,80005532 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800054a4:	85da                	mv	a1,s6
    800054a6:	854e                	mv	a0,s3
    800054a8:	ffffd097          	auipc	ra,0xffffd
    800054ac:	146080e7          	jalr	326(ra) # 800025ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800054b0:	2184a703          	lw	a4,536(s1)
    800054b4:	21c4a783          	lw	a5,540(s1)
    800054b8:	fef700e3          	beq	a4,a5,80005498 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054bc:	09505263          	blez	s5,80005540 <piperead+0xe8>
    800054c0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054c2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800054c4:	2184a783          	lw	a5,536(s1)
    800054c8:	21c4a703          	lw	a4,540(s1)
    800054cc:	02f70d63          	beq	a4,a5,80005506 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800054d0:	0017871b          	addiw	a4,a5,1
    800054d4:	20e4ac23          	sw	a4,536(s1)
    800054d8:	1ff7f793          	andi	a5,a5,511
    800054dc:	97a6                	add	a5,a5,s1
    800054de:	0187c783          	lbu	a5,24(a5)
    800054e2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800054e6:	4685                	li	a3,1
    800054e8:	fbf40613          	addi	a2,s0,-65
    800054ec:	85ca                	mv	a1,s2
    800054ee:	050a3503          	ld	a0,80(s4)
    800054f2:	ffffc097          	auipc	ra,0xffffc
    800054f6:	180080e7          	jalr	384(ra) # 80001672 <copyout>
    800054fa:	01650663          	beq	a0,s6,80005506 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054fe:	2985                	addiw	s3,s3,1
    80005500:	0905                	addi	s2,s2,1
    80005502:	fd3a91e3          	bne	s5,s3,800054c4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005506:	21c48513          	addi	a0,s1,540
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	71a080e7          	jalr	1818(ra) # 80002c24 <wakeup>
  release(&pi->lock);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffb097          	auipc	ra,0xffffb
    80005518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
  return i;
}
    8000551c:	854e                	mv	a0,s3
    8000551e:	60a6                	ld	ra,72(sp)
    80005520:	6406                	ld	s0,64(sp)
    80005522:	74e2                	ld	s1,56(sp)
    80005524:	7942                	ld	s2,48(sp)
    80005526:	79a2                	ld	s3,40(sp)
    80005528:	7a02                	ld	s4,32(sp)
    8000552a:	6ae2                	ld	s5,24(sp)
    8000552c:	6b42                	ld	s6,16(sp)
    8000552e:	6161                	addi	sp,sp,80
    80005530:	8082                	ret
      release(&pi->lock);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	764080e7          	jalr	1892(ra) # 80000c98 <release>
      return -1;
    8000553c:	59fd                	li	s3,-1
    8000553e:	bff9                	j	8000551c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005540:	4981                	li	s3,0
    80005542:	b7d1                	j	80005506 <piperead+0xae>

0000000080005544 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005544:	df010113          	addi	sp,sp,-528
    80005548:	20113423          	sd	ra,520(sp)
    8000554c:	20813023          	sd	s0,512(sp)
    80005550:	ffa6                	sd	s1,504(sp)
    80005552:	fbca                	sd	s2,496(sp)
    80005554:	f7ce                	sd	s3,488(sp)
    80005556:	f3d2                	sd	s4,480(sp)
    80005558:	efd6                	sd	s5,472(sp)
    8000555a:	ebda                	sd	s6,464(sp)
    8000555c:	e7de                	sd	s7,456(sp)
    8000555e:	e3e2                	sd	s8,448(sp)
    80005560:	ff66                	sd	s9,440(sp)
    80005562:	fb6a                	sd	s10,432(sp)
    80005564:	f76e                	sd	s11,424(sp)
    80005566:	0c00                	addi	s0,sp,528
    80005568:	84aa                	mv	s1,a0
    8000556a:	dea43c23          	sd	a0,-520(s0)
    8000556e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	9d4080e7          	jalr	-1580(ra) # 80001f46 <myproc>
    8000557a:	892a                	mv	s2,a0

  begin_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	49c080e7          	jalr	1180(ra) # 80004a18 <begin_op>

  if((ip = namei(path)) == 0){
    80005584:	8526                	mv	a0,s1
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	276080e7          	jalr	630(ra) # 800047fc <namei>
    8000558e:	c92d                	beqz	a0,80005600 <exec+0xbc>
    80005590:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	ab4080e7          	jalr	-1356(ra) # 80004046 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000559a:	04000713          	li	a4,64
    8000559e:	4681                	li	a3,0
    800055a0:	e5040613          	addi	a2,s0,-432
    800055a4:	4581                	li	a1,0
    800055a6:	8526                	mv	a0,s1
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	d52080e7          	jalr	-686(ra) # 800042fa <readi>
    800055b0:	04000793          	li	a5,64
    800055b4:	00f51a63          	bne	a0,a5,800055c8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800055b8:	e5042703          	lw	a4,-432(s0)
    800055bc:	464c47b7          	lui	a5,0x464c4
    800055c0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800055c4:	04f70463          	beq	a4,a5,8000560c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	cde080e7          	jalr	-802(ra) # 800042a8 <iunlockput>
    end_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	4c6080e7          	jalr	1222(ra) # 80004a98 <end_op>
  }
  return -1;
    800055da:	557d                	li	a0,-1
}
    800055dc:	20813083          	ld	ra,520(sp)
    800055e0:	20013403          	ld	s0,512(sp)
    800055e4:	74fe                	ld	s1,504(sp)
    800055e6:	795e                	ld	s2,496(sp)
    800055e8:	79be                	ld	s3,488(sp)
    800055ea:	7a1e                	ld	s4,480(sp)
    800055ec:	6afe                	ld	s5,472(sp)
    800055ee:	6b5e                	ld	s6,464(sp)
    800055f0:	6bbe                	ld	s7,456(sp)
    800055f2:	6c1e                	ld	s8,448(sp)
    800055f4:	7cfa                	ld	s9,440(sp)
    800055f6:	7d5a                	ld	s10,432(sp)
    800055f8:	7dba                	ld	s11,424(sp)
    800055fa:	21010113          	addi	sp,sp,528
    800055fe:	8082                	ret
    end_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	498080e7          	jalr	1176(ra) # 80004a98 <end_op>
    return -1;
    80005608:	557d                	li	a0,-1
    8000560a:	bfc9                	j	800055dc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000560c:	854a                	mv	a0,s2
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	9f6080e7          	jalr	-1546(ra) # 80002004 <proc_pagetable>
    80005616:	8baa                	mv	s7,a0
    80005618:	d945                	beqz	a0,800055c8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000561a:	e7042983          	lw	s3,-400(s0)
    8000561e:	e8845783          	lhu	a5,-376(s0)
    80005622:	c7ad                	beqz	a5,8000568c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005624:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005626:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005628:	6c85                	lui	s9,0x1
    8000562a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000562e:	def43823          	sd	a5,-528(s0)
    80005632:	a42d                	j	8000585c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005634:	00003517          	auipc	a0,0x3
    80005638:	21450513          	addi	a0,a0,532 # 80008848 <syscalls+0x298>
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005644:	8756                	mv	a4,s5
    80005646:	012d86bb          	addw	a3,s11,s2
    8000564a:	4581                	li	a1,0
    8000564c:	8526                	mv	a0,s1
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	cac080e7          	jalr	-852(ra) # 800042fa <readi>
    80005656:	2501                	sext.w	a0,a0
    80005658:	1aaa9963          	bne	s5,a0,8000580a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000565c:	6785                	lui	a5,0x1
    8000565e:	0127893b          	addw	s2,a5,s2
    80005662:	77fd                	lui	a5,0xfffff
    80005664:	01478a3b          	addw	s4,a5,s4
    80005668:	1f897163          	bgeu	s2,s8,8000584a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000566c:	02091593          	slli	a1,s2,0x20
    80005670:	9181                	srli	a1,a1,0x20
    80005672:	95ea                	add	a1,a1,s10
    80005674:	855e                	mv	a0,s7
    80005676:	ffffc097          	auipc	ra,0xffffc
    8000567a:	9f8080e7          	jalr	-1544(ra) # 8000106e <walkaddr>
    8000567e:	862a                	mv	a2,a0
    if(pa == 0)
    80005680:	d955                	beqz	a0,80005634 <exec+0xf0>
      n = PGSIZE;
    80005682:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005684:	fd9a70e3          	bgeu	s4,s9,80005644 <exec+0x100>
      n = sz - i;
    80005688:	8ad2                	mv	s5,s4
    8000568a:	bf6d                	j	80005644 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000568c:	4901                	li	s2,0
  iunlockput(ip);
    8000568e:	8526                	mv	a0,s1
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	c18080e7          	jalr	-1000(ra) # 800042a8 <iunlockput>
  end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	400080e7          	jalr	1024(ra) # 80004a98 <end_op>
  p = myproc();
    800056a0:	ffffd097          	auipc	ra,0xffffd
    800056a4:	8a6080e7          	jalr	-1882(ra) # 80001f46 <myproc>
    800056a8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800056aa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800056ae:	6785                	lui	a5,0x1
    800056b0:	17fd                	addi	a5,a5,-1
    800056b2:	993e                	add	s2,s2,a5
    800056b4:	757d                	lui	a0,0xfffff
    800056b6:	00a977b3          	and	a5,s2,a0
    800056ba:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056be:	6609                	lui	a2,0x2
    800056c0:	963e                	add	a2,a2,a5
    800056c2:	85be                	mv	a1,a5
    800056c4:	855e                	mv	a0,s7
    800056c6:	ffffc097          	auipc	ra,0xffffc
    800056ca:	d5c080e7          	jalr	-676(ra) # 80001422 <uvmalloc>
    800056ce:	8b2a                	mv	s6,a0
  ip = 0;
    800056d0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800056d2:	12050c63          	beqz	a0,8000580a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800056d6:	75f9                	lui	a1,0xffffe
    800056d8:	95aa                	add	a1,a1,a0
    800056da:	855e                	mv	a0,s7
    800056dc:	ffffc097          	auipc	ra,0xffffc
    800056e0:	f64080e7          	jalr	-156(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800056e4:	7c7d                	lui	s8,0xfffff
    800056e6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800056e8:	e0043783          	ld	a5,-512(s0)
    800056ec:	6388                	ld	a0,0(a5)
    800056ee:	c535                	beqz	a0,8000575a <exec+0x216>
    800056f0:	e9040993          	addi	s3,s0,-368
    800056f4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800056f8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	76a080e7          	jalr	1898(ra) # 80000e64 <strlen>
    80005702:	2505                	addiw	a0,a0,1
    80005704:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005708:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000570c:	13896363          	bltu	s2,s8,80005832 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005710:	e0043d83          	ld	s11,-512(s0)
    80005714:	000dba03          	ld	s4,0(s11)
    80005718:	8552                	mv	a0,s4
    8000571a:	ffffb097          	auipc	ra,0xffffb
    8000571e:	74a080e7          	jalr	1866(ra) # 80000e64 <strlen>
    80005722:	0015069b          	addiw	a3,a0,1
    80005726:	8652                	mv	a2,s4
    80005728:	85ca                	mv	a1,s2
    8000572a:	855e                	mv	a0,s7
    8000572c:	ffffc097          	auipc	ra,0xffffc
    80005730:	f46080e7          	jalr	-186(ra) # 80001672 <copyout>
    80005734:	10054363          	bltz	a0,8000583a <exec+0x2f6>
    ustack[argc] = sp;
    80005738:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000573c:	0485                	addi	s1,s1,1
    8000573e:	008d8793          	addi	a5,s11,8
    80005742:	e0f43023          	sd	a5,-512(s0)
    80005746:	008db503          	ld	a0,8(s11)
    8000574a:	c911                	beqz	a0,8000575e <exec+0x21a>
    if(argc >= MAXARG)
    8000574c:	09a1                	addi	s3,s3,8
    8000574e:	fb3c96e3          	bne	s9,s3,800056fa <exec+0x1b6>
  sz = sz1;
    80005752:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005756:	4481                	li	s1,0
    80005758:	a84d                	j	8000580a <exec+0x2c6>
  sp = sz;
    8000575a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000575c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000575e:	00349793          	slli	a5,s1,0x3
    80005762:	f9040713          	addi	a4,s0,-112
    80005766:	97ba                	add	a5,a5,a4
    80005768:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000576c:	00148693          	addi	a3,s1,1
    80005770:	068e                	slli	a3,a3,0x3
    80005772:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005776:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000577a:	01897663          	bgeu	s2,s8,80005786 <exec+0x242>
  sz = sz1;
    8000577e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005782:	4481                	li	s1,0
    80005784:	a059                	j	8000580a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005786:	e9040613          	addi	a2,s0,-368
    8000578a:	85ca                	mv	a1,s2
    8000578c:	855e                	mv	a0,s7
    8000578e:	ffffc097          	auipc	ra,0xffffc
    80005792:	ee4080e7          	jalr	-284(ra) # 80001672 <copyout>
    80005796:	0a054663          	bltz	a0,80005842 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000579a:	058ab783          	ld	a5,88(s5)
    8000579e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800057a2:	df843783          	ld	a5,-520(s0)
    800057a6:	0007c703          	lbu	a4,0(a5)
    800057aa:	cf11                	beqz	a4,800057c6 <exec+0x282>
    800057ac:	0785                	addi	a5,a5,1
    if(*s == '/')
    800057ae:	02f00693          	li	a3,47
    800057b2:	a039                	j	800057c0 <exec+0x27c>
      last = s+1;
    800057b4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800057b8:	0785                	addi	a5,a5,1
    800057ba:	fff7c703          	lbu	a4,-1(a5)
    800057be:	c701                	beqz	a4,800057c6 <exec+0x282>
    if(*s == '/')
    800057c0:	fed71ce3          	bne	a4,a3,800057b8 <exec+0x274>
    800057c4:	bfc5                	j	800057b4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800057c6:	4641                	li	a2,16
    800057c8:	df843583          	ld	a1,-520(s0)
    800057cc:	158a8513          	addi	a0,s5,344
    800057d0:	ffffb097          	auipc	ra,0xffffb
    800057d4:	662080e7          	jalr	1634(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800057d8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800057dc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800057e0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800057e4:	058ab783          	ld	a5,88(s5)
    800057e8:	e6843703          	ld	a4,-408(s0)
    800057ec:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800057ee:	058ab783          	ld	a5,88(s5)
    800057f2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800057f6:	85ea                	mv	a1,s10
    800057f8:	ffffd097          	auipc	ra,0xffffd
    800057fc:	8a8080e7          	jalr	-1880(ra) # 800020a0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005800:	0004851b          	sext.w	a0,s1
    80005804:	bbe1                	j	800055dc <exec+0x98>
    80005806:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000580a:	e0843583          	ld	a1,-504(s0)
    8000580e:	855e                	mv	a0,s7
    80005810:	ffffd097          	auipc	ra,0xffffd
    80005814:	890080e7          	jalr	-1904(ra) # 800020a0 <proc_freepagetable>
  if(ip){
    80005818:	da0498e3          	bnez	s1,800055c8 <exec+0x84>
  return -1;
    8000581c:	557d                	li	a0,-1
    8000581e:	bb7d                	j	800055dc <exec+0x98>
    80005820:	e1243423          	sd	s2,-504(s0)
    80005824:	b7dd                	j	8000580a <exec+0x2c6>
    80005826:	e1243423          	sd	s2,-504(s0)
    8000582a:	b7c5                	j	8000580a <exec+0x2c6>
    8000582c:	e1243423          	sd	s2,-504(s0)
    80005830:	bfe9                	j	8000580a <exec+0x2c6>
  sz = sz1;
    80005832:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005836:	4481                	li	s1,0
    80005838:	bfc9                	j	8000580a <exec+0x2c6>
  sz = sz1;
    8000583a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000583e:	4481                	li	s1,0
    80005840:	b7e9                	j	8000580a <exec+0x2c6>
  sz = sz1;
    80005842:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005846:	4481                	li	s1,0
    80005848:	b7c9                	j	8000580a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000584a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000584e:	2b05                	addiw	s6,s6,1
    80005850:	0389899b          	addiw	s3,s3,56
    80005854:	e8845783          	lhu	a5,-376(s0)
    80005858:	e2fb5be3          	bge	s6,a5,8000568e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000585c:	2981                	sext.w	s3,s3
    8000585e:	03800713          	li	a4,56
    80005862:	86ce                	mv	a3,s3
    80005864:	e1840613          	addi	a2,s0,-488
    80005868:	4581                	li	a1,0
    8000586a:	8526                	mv	a0,s1
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	a8e080e7          	jalr	-1394(ra) # 800042fa <readi>
    80005874:	03800793          	li	a5,56
    80005878:	f8f517e3          	bne	a0,a5,80005806 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000587c:	e1842783          	lw	a5,-488(s0)
    80005880:	4705                	li	a4,1
    80005882:	fce796e3          	bne	a5,a4,8000584e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005886:	e4043603          	ld	a2,-448(s0)
    8000588a:	e3843783          	ld	a5,-456(s0)
    8000588e:	f8f669e3          	bltu	a2,a5,80005820 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005892:	e2843783          	ld	a5,-472(s0)
    80005896:	963e                	add	a2,a2,a5
    80005898:	f8f667e3          	bltu	a2,a5,80005826 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000589c:	85ca                	mv	a1,s2
    8000589e:	855e                	mv	a0,s7
    800058a0:	ffffc097          	auipc	ra,0xffffc
    800058a4:	b82080e7          	jalr	-1150(ra) # 80001422 <uvmalloc>
    800058a8:	e0a43423          	sd	a0,-504(s0)
    800058ac:	d141                	beqz	a0,8000582c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800058ae:	e2843d03          	ld	s10,-472(s0)
    800058b2:	df043783          	ld	a5,-528(s0)
    800058b6:	00fd77b3          	and	a5,s10,a5
    800058ba:	fba1                	bnez	a5,8000580a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800058bc:	e2042d83          	lw	s11,-480(s0)
    800058c0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800058c4:	f80c03e3          	beqz	s8,8000584a <exec+0x306>
    800058c8:	8a62                	mv	s4,s8
    800058ca:	4901                	li	s2,0
    800058cc:	b345                	j	8000566c <exec+0x128>

00000000800058ce <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800058ce:	7179                	addi	sp,sp,-48
    800058d0:	f406                	sd	ra,40(sp)
    800058d2:	f022                	sd	s0,32(sp)
    800058d4:	ec26                	sd	s1,24(sp)
    800058d6:	e84a                	sd	s2,16(sp)
    800058d8:	1800                	addi	s0,sp,48
    800058da:	892e                	mv	s2,a1
    800058dc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800058de:	fdc40593          	addi	a1,s0,-36
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	b76080e7          	jalr	-1162(ra) # 80003458 <argint>
    800058ea:	04054063          	bltz	a0,8000592a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800058ee:	fdc42703          	lw	a4,-36(s0)
    800058f2:	47bd                	li	a5,15
    800058f4:	02e7ed63          	bltu	a5,a4,8000592e <argfd+0x60>
    800058f8:	ffffc097          	auipc	ra,0xffffc
    800058fc:	64e080e7          	jalr	1614(ra) # 80001f46 <myproc>
    80005900:	fdc42703          	lw	a4,-36(s0)
    80005904:	01a70793          	addi	a5,a4,26
    80005908:	078e                	slli	a5,a5,0x3
    8000590a:	953e                	add	a0,a0,a5
    8000590c:	611c                	ld	a5,0(a0)
    8000590e:	c395                	beqz	a5,80005932 <argfd+0x64>
    return -1;
  if(pfd)
    80005910:	00090463          	beqz	s2,80005918 <argfd+0x4a>
    *pfd = fd;
    80005914:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005918:	4501                	li	a0,0
  if(pf)
    8000591a:	c091                	beqz	s1,8000591e <argfd+0x50>
    *pf = f;
    8000591c:	e09c                	sd	a5,0(s1)
}
    8000591e:	70a2                	ld	ra,40(sp)
    80005920:	7402                	ld	s0,32(sp)
    80005922:	64e2                	ld	s1,24(sp)
    80005924:	6942                	ld	s2,16(sp)
    80005926:	6145                	addi	sp,sp,48
    80005928:	8082                	ret
    return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	bfcd                	j	8000591e <argfd+0x50>
    return -1;
    8000592e:	557d                	li	a0,-1
    80005930:	b7fd                	j	8000591e <argfd+0x50>
    80005932:	557d                	li	a0,-1
    80005934:	b7ed                	j	8000591e <argfd+0x50>

0000000080005936 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005936:	1101                	addi	sp,sp,-32
    80005938:	ec06                	sd	ra,24(sp)
    8000593a:	e822                	sd	s0,16(sp)
    8000593c:	e426                	sd	s1,8(sp)
    8000593e:	1000                	addi	s0,sp,32
    80005940:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005942:	ffffc097          	auipc	ra,0xffffc
    80005946:	604080e7          	jalr	1540(ra) # 80001f46 <myproc>
    8000594a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000594c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005950:	4501                	li	a0,0
    80005952:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005954:	6398                	ld	a4,0(a5)
    80005956:	cb19                	beqz	a4,8000596c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005958:	2505                	addiw	a0,a0,1
    8000595a:	07a1                	addi	a5,a5,8
    8000595c:	fed51ce3          	bne	a0,a3,80005954 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005960:	557d                	li	a0,-1
}
    80005962:	60e2                	ld	ra,24(sp)
    80005964:	6442                	ld	s0,16(sp)
    80005966:	64a2                	ld	s1,8(sp)
    80005968:	6105                	addi	sp,sp,32
    8000596a:	8082                	ret
      p->ofile[fd] = f;
    8000596c:	01a50793          	addi	a5,a0,26
    80005970:	078e                	slli	a5,a5,0x3
    80005972:	963e                	add	a2,a2,a5
    80005974:	e204                	sd	s1,0(a2)
      return fd;
    80005976:	b7f5                	j	80005962 <fdalloc+0x2c>

0000000080005978 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005978:	715d                	addi	sp,sp,-80
    8000597a:	e486                	sd	ra,72(sp)
    8000597c:	e0a2                	sd	s0,64(sp)
    8000597e:	fc26                	sd	s1,56(sp)
    80005980:	f84a                	sd	s2,48(sp)
    80005982:	f44e                	sd	s3,40(sp)
    80005984:	f052                	sd	s4,32(sp)
    80005986:	ec56                	sd	s5,24(sp)
    80005988:	0880                	addi	s0,sp,80
    8000598a:	89ae                	mv	s3,a1
    8000598c:	8ab2                	mv	s5,a2
    8000598e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005990:	fb040593          	addi	a1,s0,-80
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	e86080e7          	jalr	-378(ra) # 8000481a <nameiparent>
    8000599c:	892a                	mv	s2,a0
    8000599e:	12050f63          	beqz	a0,80005adc <create+0x164>
    return 0;

  ilock(dp);
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	6a4080e7          	jalr	1700(ra) # 80004046 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800059aa:	4601                	li	a2,0
    800059ac:	fb040593          	addi	a1,s0,-80
    800059b0:	854a                	mv	a0,s2
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	b78080e7          	jalr	-1160(ra) # 8000452a <dirlookup>
    800059ba:	84aa                	mv	s1,a0
    800059bc:	c921                	beqz	a0,80005a0c <create+0x94>
    iunlockput(dp);
    800059be:	854a                	mv	a0,s2
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	8e8080e7          	jalr	-1816(ra) # 800042a8 <iunlockput>
    ilock(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	67c080e7          	jalr	1660(ra) # 80004046 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800059d2:	2981                	sext.w	s3,s3
    800059d4:	4789                	li	a5,2
    800059d6:	02f99463          	bne	s3,a5,800059fe <create+0x86>
    800059da:	0444d783          	lhu	a5,68(s1)
    800059de:	37f9                	addiw	a5,a5,-2
    800059e0:	17c2                	slli	a5,a5,0x30
    800059e2:	93c1                	srli	a5,a5,0x30
    800059e4:	4705                	li	a4,1
    800059e6:	00f76c63          	bltu	a4,a5,800059fe <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800059ea:	8526                	mv	a0,s1
    800059ec:	60a6                	ld	ra,72(sp)
    800059ee:	6406                	ld	s0,64(sp)
    800059f0:	74e2                	ld	s1,56(sp)
    800059f2:	7942                	ld	s2,48(sp)
    800059f4:	79a2                	ld	s3,40(sp)
    800059f6:	7a02                	ld	s4,32(sp)
    800059f8:	6ae2                	ld	s5,24(sp)
    800059fa:	6161                	addi	sp,sp,80
    800059fc:	8082                	ret
    iunlockput(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	8a8080e7          	jalr	-1880(ra) # 800042a8 <iunlockput>
    return 0;
    80005a08:	4481                	li	s1,0
    80005a0a:	b7c5                	j	800059ea <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005a0c:	85ce                	mv	a1,s3
    80005a0e:	00092503          	lw	a0,0(s2)
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	49c080e7          	jalr	1180(ra) # 80003eae <ialloc>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c529                	beqz	a0,80005a66 <create+0xee>
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	628080e7          	jalr	1576(ra) # 80004046 <ilock>
  ip->major = major;
    80005a26:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005a2a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005a2e:	4785                	li	a5,1
    80005a30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	546080e7          	jalr	1350(ra) # 80003f7c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005a3e:	2981                	sext.w	s3,s3
    80005a40:	4785                	li	a5,1
    80005a42:	02f98a63          	beq	s3,a5,80005a76 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005a46:	40d0                	lw	a2,4(s1)
    80005a48:	fb040593          	addi	a1,s0,-80
    80005a4c:	854a                	mv	a0,s2
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	cec080e7          	jalr	-788(ra) # 8000473a <dirlink>
    80005a56:	06054b63          	bltz	a0,80005acc <create+0x154>
  iunlockput(dp);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	84c080e7          	jalr	-1972(ra) # 800042a8 <iunlockput>
  return ip;
    80005a64:	b759                	j	800059ea <create+0x72>
    panic("create: ialloc");
    80005a66:	00003517          	auipc	a0,0x3
    80005a6a:	e0250513          	addi	a0,a0,-510 # 80008868 <syscalls+0x2b8>
    80005a6e:	ffffb097          	auipc	ra,0xffffb
    80005a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005a76:	04a95783          	lhu	a5,74(s2)
    80005a7a:	2785                	addiw	a5,a5,1
    80005a7c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	4fa080e7          	jalr	1274(ra) # 80003f7c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a8a:	40d0                	lw	a2,4(s1)
    80005a8c:	00003597          	auipc	a1,0x3
    80005a90:	dec58593          	addi	a1,a1,-532 # 80008878 <syscalls+0x2c8>
    80005a94:	8526                	mv	a0,s1
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	ca4080e7          	jalr	-860(ra) # 8000473a <dirlink>
    80005a9e:	00054f63          	bltz	a0,80005abc <create+0x144>
    80005aa2:	00492603          	lw	a2,4(s2)
    80005aa6:	00003597          	auipc	a1,0x3
    80005aaa:	dda58593          	addi	a1,a1,-550 # 80008880 <syscalls+0x2d0>
    80005aae:	8526                	mv	a0,s1
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	c8a080e7          	jalr	-886(ra) # 8000473a <dirlink>
    80005ab8:	f80557e3          	bgez	a0,80005a46 <create+0xce>
      panic("create dots");
    80005abc:	00003517          	auipc	a0,0x3
    80005ac0:	dcc50513          	addi	a0,a0,-564 # 80008888 <syscalls+0x2d8>
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	a7a080e7          	jalr	-1414(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005acc:	00003517          	auipc	a0,0x3
    80005ad0:	dcc50513          	addi	a0,a0,-564 # 80008898 <syscalls+0x2e8>
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>
    return 0;
    80005adc:	84aa                	mv	s1,a0
    80005ade:	b731                	j	800059ea <create+0x72>

0000000080005ae0 <sys_dup>:
{
    80005ae0:	7179                	addi	sp,sp,-48
    80005ae2:	f406                	sd	ra,40(sp)
    80005ae4:	f022                	sd	s0,32(sp)
    80005ae6:	ec26                	sd	s1,24(sp)
    80005ae8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005aea:	fd840613          	addi	a2,s0,-40
    80005aee:	4581                	li	a1,0
    80005af0:	4501                	li	a0,0
    80005af2:	00000097          	auipc	ra,0x0
    80005af6:	ddc080e7          	jalr	-548(ra) # 800058ce <argfd>
    return -1;
    80005afa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005afc:	02054363          	bltz	a0,80005b22 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b00:	fd843503          	ld	a0,-40(s0)
    80005b04:	00000097          	auipc	ra,0x0
    80005b08:	e32080e7          	jalr	-462(ra) # 80005936 <fdalloc>
    80005b0c:	84aa                	mv	s1,a0
    return -1;
    80005b0e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b10:	00054963          	bltz	a0,80005b22 <sys_dup+0x42>
  filedup(f);
    80005b14:	fd843503          	ld	a0,-40(s0)
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	37a080e7          	jalr	890(ra) # 80004e92 <filedup>
  return fd;
    80005b20:	87a6                	mv	a5,s1
}
    80005b22:	853e                	mv	a0,a5
    80005b24:	70a2                	ld	ra,40(sp)
    80005b26:	7402                	ld	s0,32(sp)
    80005b28:	64e2                	ld	s1,24(sp)
    80005b2a:	6145                	addi	sp,sp,48
    80005b2c:	8082                	ret

0000000080005b2e <sys_read>:
{
    80005b2e:	7179                	addi	sp,sp,-48
    80005b30:	f406                	sd	ra,40(sp)
    80005b32:	f022                	sd	s0,32(sp)
    80005b34:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b36:	fe840613          	addi	a2,s0,-24
    80005b3a:	4581                	li	a1,0
    80005b3c:	4501                	li	a0,0
    80005b3e:	00000097          	auipc	ra,0x0
    80005b42:	d90080e7          	jalr	-624(ra) # 800058ce <argfd>
    return -1;
    80005b46:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b48:	04054163          	bltz	a0,80005b8a <sys_read+0x5c>
    80005b4c:	fe440593          	addi	a1,s0,-28
    80005b50:	4509                	li	a0,2
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	906080e7          	jalr	-1786(ra) # 80003458 <argint>
    return -1;
    80005b5a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b5c:	02054763          	bltz	a0,80005b8a <sys_read+0x5c>
    80005b60:	fd840593          	addi	a1,s0,-40
    80005b64:	4505                	li	a0,1
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	914080e7          	jalr	-1772(ra) # 8000347a <argaddr>
    return -1;
    80005b6e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b70:	00054d63          	bltz	a0,80005b8a <sys_read+0x5c>
  return fileread(f, p, n);
    80005b74:	fe442603          	lw	a2,-28(s0)
    80005b78:	fd843583          	ld	a1,-40(s0)
    80005b7c:	fe843503          	ld	a0,-24(s0)
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	49e080e7          	jalr	1182(ra) # 8000501e <fileread>
    80005b88:	87aa                	mv	a5,a0
}
    80005b8a:	853e                	mv	a0,a5
    80005b8c:	70a2                	ld	ra,40(sp)
    80005b8e:	7402                	ld	s0,32(sp)
    80005b90:	6145                	addi	sp,sp,48
    80005b92:	8082                	ret

0000000080005b94 <sys_write>:
{
    80005b94:	7179                	addi	sp,sp,-48
    80005b96:	f406                	sd	ra,40(sp)
    80005b98:	f022                	sd	s0,32(sp)
    80005b9a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b9c:	fe840613          	addi	a2,s0,-24
    80005ba0:	4581                	li	a1,0
    80005ba2:	4501                	li	a0,0
    80005ba4:	00000097          	auipc	ra,0x0
    80005ba8:	d2a080e7          	jalr	-726(ra) # 800058ce <argfd>
    return -1;
    80005bac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bae:	04054163          	bltz	a0,80005bf0 <sys_write+0x5c>
    80005bb2:	fe440593          	addi	a1,s0,-28
    80005bb6:	4509                	li	a0,2
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	8a0080e7          	jalr	-1888(ra) # 80003458 <argint>
    return -1;
    80005bc0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bc2:	02054763          	bltz	a0,80005bf0 <sys_write+0x5c>
    80005bc6:	fd840593          	addi	a1,s0,-40
    80005bca:	4505                	li	a0,1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	8ae080e7          	jalr	-1874(ra) # 8000347a <argaddr>
    return -1;
    80005bd4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bd6:	00054d63          	bltz	a0,80005bf0 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005bda:	fe442603          	lw	a2,-28(s0)
    80005bde:	fd843583          	ld	a1,-40(s0)
    80005be2:	fe843503          	ld	a0,-24(s0)
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	4fa080e7          	jalr	1274(ra) # 800050e0 <filewrite>
    80005bee:	87aa                	mv	a5,a0
}
    80005bf0:	853e                	mv	a0,a5
    80005bf2:	70a2                	ld	ra,40(sp)
    80005bf4:	7402                	ld	s0,32(sp)
    80005bf6:	6145                	addi	sp,sp,48
    80005bf8:	8082                	ret

0000000080005bfa <sys_close>:
{
    80005bfa:	1101                	addi	sp,sp,-32
    80005bfc:	ec06                	sd	ra,24(sp)
    80005bfe:	e822                	sd	s0,16(sp)
    80005c00:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005c02:	fe040613          	addi	a2,s0,-32
    80005c06:	fec40593          	addi	a1,s0,-20
    80005c0a:	4501                	li	a0,0
    80005c0c:	00000097          	auipc	ra,0x0
    80005c10:	cc2080e7          	jalr	-830(ra) # 800058ce <argfd>
    return -1;
    80005c14:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c16:	02054463          	bltz	a0,80005c3e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c1a:	ffffc097          	auipc	ra,0xffffc
    80005c1e:	32c080e7          	jalr	812(ra) # 80001f46 <myproc>
    80005c22:	fec42783          	lw	a5,-20(s0)
    80005c26:	07e9                	addi	a5,a5,26
    80005c28:	078e                	slli	a5,a5,0x3
    80005c2a:	97aa                	add	a5,a5,a0
    80005c2c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005c30:	fe043503          	ld	a0,-32(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	2b0080e7          	jalr	688(ra) # 80004ee4 <fileclose>
  return 0;
    80005c3c:	4781                	li	a5,0
}
    80005c3e:	853e                	mv	a0,a5
    80005c40:	60e2                	ld	ra,24(sp)
    80005c42:	6442                	ld	s0,16(sp)
    80005c44:	6105                	addi	sp,sp,32
    80005c46:	8082                	ret

0000000080005c48 <sys_fstat>:
{
    80005c48:	1101                	addi	sp,sp,-32
    80005c4a:	ec06                	sd	ra,24(sp)
    80005c4c:	e822                	sd	s0,16(sp)
    80005c4e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c50:	fe840613          	addi	a2,s0,-24
    80005c54:	4581                	li	a1,0
    80005c56:	4501                	li	a0,0
    80005c58:	00000097          	auipc	ra,0x0
    80005c5c:	c76080e7          	jalr	-906(ra) # 800058ce <argfd>
    return -1;
    80005c60:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c62:	02054563          	bltz	a0,80005c8c <sys_fstat+0x44>
    80005c66:	fe040593          	addi	a1,s0,-32
    80005c6a:	4505                	li	a0,1
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	80e080e7          	jalr	-2034(ra) # 8000347a <argaddr>
    return -1;
    80005c74:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005c76:	00054b63          	bltz	a0,80005c8c <sys_fstat+0x44>
  return filestat(f, st);
    80005c7a:	fe043583          	ld	a1,-32(s0)
    80005c7e:	fe843503          	ld	a0,-24(s0)
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	32a080e7          	jalr	810(ra) # 80004fac <filestat>
    80005c8a:	87aa                	mv	a5,a0
}
    80005c8c:	853e                	mv	a0,a5
    80005c8e:	60e2                	ld	ra,24(sp)
    80005c90:	6442                	ld	s0,16(sp)
    80005c92:	6105                	addi	sp,sp,32
    80005c94:	8082                	ret

0000000080005c96 <sys_link>:
{
    80005c96:	7169                	addi	sp,sp,-304
    80005c98:	f606                	sd	ra,296(sp)
    80005c9a:	f222                	sd	s0,288(sp)
    80005c9c:	ee26                	sd	s1,280(sp)
    80005c9e:	ea4a                	sd	s2,272(sp)
    80005ca0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ca2:	08000613          	li	a2,128
    80005ca6:	ed040593          	addi	a1,s0,-304
    80005caa:	4501                	li	a0,0
    80005cac:	ffffd097          	auipc	ra,0xffffd
    80005cb0:	7f0080e7          	jalr	2032(ra) # 8000349c <argstr>
    return -1;
    80005cb4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cb6:	10054e63          	bltz	a0,80005dd2 <sys_link+0x13c>
    80005cba:	08000613          	li	a2,128
    80005cbe:	f5040593          	addi	a1,s0,-176
    80005cc2:	4505                	li	a0,1
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	7d8080e7          	jalr	2008(ra) # 8000349c <argstr>
    return -1;
    80005ccc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005cce:	10054263          	bltz	a0,80005dd2 <sys_link+0x13c>
  begin_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	d46080e7          	jalr	-698(ra) # 80004a18 <begin_op>
  if((ip = namei(old)) == 0){
    80005cda:	ed040513          	addi	a0,s0,-304
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	b1e080e7          	jalr	-1250(ra) # 800047fc <namei>
    80005ce6:	84aa                	mv	s1,a0
    80005ce8:	c551                	beqz	a0,80005d74 <sys_link+0xde>
  ilock(ip);
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	35c080e7          	jalr	860(ra) # 80004046 <ilock>
  if(ip->type == T_DIR){
    80005cf2:	04449703          	lh	a4,68(s1)
    80005cf6:	4785                	li	a5,1
    80005cf8:	08f70463          	beq	a4,a5,80005d80 <sys_link+0xea>
  ip->nlink++;
    80005cfc:	04a4d783          	lhu	a5,74(s1)
    80005d00:	2785                	addiw	a5,a5,1
    80005d02:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d06:	8526                	mv	a0,s1
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	274080e7          	jalr	628(ra) # 80003f7c <iupdate>
  iunlock(ip);
    80005d10:	8526                	mv	a0,s1
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	3f6080e7          	jalr	1014(ra) # 80004108 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005d1a:	fd040593          	addi	a1,s0,-48
    80005d1e:	f5040513          	addi	a0,s0,-176
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	af8080e7          	jalr	-1288(ra) # 8000481a <nameiparent>
    80005d2a:	892a                	mv	s2,a0
    80005d2c:	c935                	beqz	a0,80005da0 <sys_link+0x10a>
  ilock(dp);
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	318080e7          	jalr	792(ra) # 80004046 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005d36:	00092703          	lw	a4,0(s2)
    80005d3a:	409c                	lw	a5,0(s1)
    80005d3c:	04f71d63          	bne	a4,a5,80005d96 <sys_link+0x100>
    80005d40:	40d0                	lw	a2,4(s1)
    80005d42:	fd040593          	addi	a1,s0,-48
    80005d46:	854a                	mv	a0,s2
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	9f2080e7          	jalr	-1550(ra) # 8000473a <dirlink>
    80005d50:	04054363          	bltz	a0,80005d96 <sys_link+0x100>
  iunlockput(dp);
    80005d54:	854a                	mv	a0,s2
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	552080e7          	jalr	1362(ra) # 800042a8 <iunlockput>
  iput(ip);
    80005d5e:	8526                	mv	a0,s1
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	4a0080e7          	jalr	1184(ra) # 80004200 <iput>
  end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	d30080e7          	jalr	-720(ra) # 80004a98 <end_op>
  return 0;
    80005d70:	4781                	li	a5,0
    80005d72:	a085                	j	80005dd2 <sys_link+0x13c>
    end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	d24080e7          	jalr	-732(ra) # 80004a98 <end_op>
    return -1;
    80005d7c:	57fd                	li	a5,-1
    80005d7e:	a891                	j	80005dd2 <sys_link+0x13c>
    iunlockput(ip);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	526080e7          	jalr	1318(ra) # 800042a8 <iunlockput>
    end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	d0e080e7          	jalr	-754(ra) # 80004a98 <end_op>
    return -1;
    80005d92:	57fd                	li	a5,-1
    80005d94:	a83d                	j	80005dd2 <sys_link+0x13c>
    iunlockput(dp);
    80005d96:	854a                	mv	a0,s2
    80005d98:	ffffe097          	auipc	ra,0xffffe
    80005d9c:	510080e7          	jalr	1296(ra) # 800042a8 <iunlockput>
  ilock(ip);
    80005da0:	8526                	mv	a0,s1
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	2a4080e7          	jalr	676(ra) # 80004046 <ilock>
  ip->nlink--;
    80005daa:	04a4d783          	lhu	a5,74(s1)
    80005dae:	37fd                	addiw	a5,a5,-1
    80005db0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005db4:	8526                	mv	a0,s1
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	1c6080e7          	jalr	454(ra) # 80003f7c <iupdate>
  iunlockput(ip);
    80005dbe:	8526                	mv	a0,s1
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	4e8080e7          	jalr	1256(ra) # 800042a8 <iunlockput>
  end_op();
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	cd0080e7          	jalr	-816(ra) # 80004a98 <end_op>
  return -1;
    80005dd0:	57fd                	li	a5,-1
}
    80005dd2:	853e                	mv	a0,a5
    80005dd4:	70b2                	ld	ra,296(sp)
    80005dd6:	7412                	ld	s0,288(sp)
    80005dd8:	64f2                	ld	s1,280(sp)
    80005dda:	6952                	ld	s2,272(sp)
    80005ddc:	6155                	addi	sp,sp,304
    80005dde:	8082                	ret

0000000080005de0 <sys_unlink>:
{
    80005de0:	7151                	addi	sp,sp,-240
    80005de2:	f586                	sd	ra,232(sp)
    80005de4:	f1a2                	sd	s0,224(sp)
    80005de6:	eda6                	sd	s1,216(sp)
    80005de8:	e9ca                	sd	s2,208(sp)
    80005dea:	e5ce                	sd	s3,200(sp)
    80005dec:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005dee:	08000613          	li	a2,128
    80005df2:	f3040593          	addi	a1,s0,-208
    80005df6:	4501                	li	a0,0
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	6a4080e7          	jalr	1700(ra) # 8000349c <argstr>
    80005e00:	18054163          	bltz	a0,80005f82 <sys_unlink+0x1a2>
  begin_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	c14080e7          	jalr	-1004(ra) # 80004a18 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005e0c:	fb040593          	addi	a1,s0,-80
    80005e10:	f3040513          	addi	a0,s0,-208
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	a06080e7          	jalr	-1530(ra) # 8000481a <nameiparent>
    80005e1c:	84aa                	mv	s1,a0
    80005e1e:	c979                	beqz	a0,80005ef4 <sys_unlink+0x114>
  ilock(dp);
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	226080e7          	jalr	550(ra) # 80004046 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005e28:	00003597          	auipc	a1,0x3
    80005e2c:	a5058593          	addi	a1,a1,-1456 # 80008878 <syscalls+0x2c8>
    80005e30:	fb040513          	addi	a0,s0,-80
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	6dc080e7          	jalr	1756(ra) # 80004510 <namecmp>
    80005e3c:	14050a63          	beqz	a0,80005f90 <sys_unlink+0x1b0>
    80005e40:	00003597          	auipc	a1,0x3
    80005e44:	a4058593          	addi	a1,a1,-1472 # 80008880 <syscalls+0x2d0>
    80005e48:	fb040513          	addi	a0,s0,-80
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	6c4080e7          	jalr	1732(ra) # 80004510 <namecmp>
    80005e54:	12050e63          	beqz	a0,80005f90 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005e58:	f2c40613          	addi	a2,s0,-212
    80005e5c:	fb040593          	addi	a1,s0,-80
    80005e60:	8526                	mv	a0,s1
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	6c8080e7          	jalr	1736(ra) # 8000452a <dirlookup>
    80005e6a:	892a                	mv	s2,a0
    80005e6c:	12050263          	beqz	a0,80005f90 <sys_unlink+0x1b0>
  ilock(ip);
    80005e70:	ffffe097          	auipc	ra,0xffffe
    80005e74:	1d6080e7          	jalr	470(ra) # 80004046 <ilock>
  if(ip->nlink < 1)
    80005e78:	04a91783          	lh	a5,74(s2)
    80005e7c:	08f05263          	blez	a5,80005f00 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e80:	04491703          	lh	a4,68(s2)
    80005e84:	4785                	li	a5,1
    80005e86:	08f70563          	beq	a4,a5,80005f10 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e8a:	4641                	li	a2,16
    80005e8c:	4581                	li	a1,0
    80005e8e:	fc040513          	addi	a0,s0,-64
    80005e92:	ffffb097          	auipc	ra,0xffffb
    80005e96:	e4e080e7          	jalr	-434(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e9a:	4741                	li	a4,16
    80005e9c:	f2c42683          	lw	a3,-212(s0)
    80005ea0:	fc040613          	addi	a2,s0,-64
    80005ea4:	4581                	li	a1,0
    80005ea6:	8526                	mv	a0,s1
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	54a080e7          	jalr	1354(ra) # 800043f2 <writei>
    80005eb0:	47c1                	li	a5,16
    80005eb2:	0af51563          	bne	a0,a5,80005f5c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005eb6:	04491703          	lh	a4,68(s2)
    80005eba:	4785                	li	a5,1
    80005ebc:	0af70863          	beq	a4,a5,80005f6c <sys_unlink+0x18c>
  iunlockput(dp);
    80005ec0:	8526                	mv	a0,s1
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	3e6080e7          	jalr	998(ra) # 800042a8 <iunlockput>
  ip->nlink--;
    80005eca:	04a95783          	lhu	a5,74(s2)
    80005ece:	37fd                	addiw	a5,a5,-1
    80005ed0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ed4:	854a                	mv	a0,s2
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	0a6080e7          	jalr	166(ra) # 80003f7c <iupdate>
  iunlockput(ip);
    80005ede:	854a                	mv	a0,s2
    80005ee0:	ffffe097          	auipc	ra,0xffffe
    80005ee4:	3c8080e7          	jalr	968(ra) # 800042a8 <iunlockput>
  end_op();
    80005ee8:	fffff097          	auipc	ra,0xfffff
    80005eec:	bb0080e7          	jalr	-1104(ra) # 80004a98 <end_op>
  return 0;
    80005ef0:	4501                	li	a0,0
    80005ef2:	a84d                	j	80005fa4 <sys_unlink+0x1c4>
    end_op();
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	ba4080e7          	jalr	-1116(ra) # 80004a98 <end_op>
    return -1;
    80005efc:	557d                	li	a0,-1
    80005efe:	a05d                	j	80005fa4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005f00:	00003517          	auipc	a0,0x3
    80005f04:	9a850513          	addi	a0,a0,-1624 # 800088a8 <syscalls+0x2f8>
    80005f08:	ffffa097          	auipc	ra,0xffffa
    80005f0c:	636080e7          	jalr	1590(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f10:	04c92703          	lw	a4,76(s2)
    80005f14:	02000793          	li	a5,32
    80005f18:	f6e7f9e3          	bgeu	a5,a4,80005e8a <sys_unlink+0xaa>
    80005f1c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f20:	4741                	li	a4,16
    80005f22:	86ce                	mv	a3,s3
    80005f24:	f1840613          	addi	a2,s0,-232
    80005f28:	4581                	li	a1,0
    80005f2a:	854a                	mv	a0,s2
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	3ce080e7          	jalr	974(ra) # 800042fa <readi>
    80005f34:	47c1                	li	a5,16
    80005f36:	00f51b63          	bne	a0,a5,80005f4c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005f3a:	f1845783          	lhu	a5,-232(s0)
    80005f3e:	e7a1                	bnez	a5,80005f86 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005f40:	29c1                	addiw	s3,s3,16
    80005f42:	04c92783          	lw	a5,76(s2)
    80005f46:	fcf9ede3          	bltu	s3,a5,80005f20 <sys_unlink+0x140>
    80005f4a:	b781                	j	80005e8a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	97450513          	addi	a0,a0,-1676 # 800088c0 <syscalls+0x310>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5ea080e7          	jalr	1514(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	97c50513          	addi	a0,a0,-1668 # 800088d8 <syscalls+0x328>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5da080e7          	jalr	1498(ra) # 8000053e <panic>
    dp->nlink--;
    80005f6c:	04a4d783          	lhu	a5,74(s1)
    80005f70:	37fd                	addiw	a5,a5,-1
    80005f72:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005f76:	8526                	mv	a0,s1
    80005f78:	ffffe097          	auipc	ra,0xffffe
    80005f7c:	004080e7          	jalr	4(ra) # 80003f7c <iupdate>
    80005f80:	b781                	j	80005ec0 <sys_unlink+0xe0>
    return -1;
    80005f82:	557d                	li	a0,-1
    80005f84:	a005                	j	80005fa4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f86:	854a                	mv	a0,s2
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	320080e7          	jalr	800(ra) # 800042a8 <iunlockput>
  iunlockput(dp);
    80005f90:	8526                	mv	a0,s1
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	316080e7          	jalr	790(ra) # 800042a8 <iunlockput>
  end_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	afe080e7          	jalr	-1282(ra) # 80004a98 <end_op>
  return -1;
    80005fa2:	557d                	li	a0,-1
}
    80005fa4:	70ae                	ld	ra,232(sp)
    80005fa6:	740e                	ld	s0,224(sp)
    80005fa8:	64ee                	ld	s1,216(sp)
    80005faa:	694e                	ld	s2,208(sp)
    80005fac:	69ae                	ld	s3,200(sp)
    80005fae:	616d                	addi	sp,sp,240
    80005fb0:	8082                	ret

0000000080005fb2 <sys_open>:

uint64
sys_open(void)
{
    80005fb2:	7131                	addi	sp,sp,-192
    80005fb4:	fd06                	sd	ra,184(sp)
    80005fb6:	f922                	sd	s0,176(sp)
    80005fb8:	f526                	sd	s1,168(sp)
    80005fba:	f14a                	sd	s2,160(sp)
    80005fbc:	ed4e                	sd	s3,152(sp)
    80005fbe:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fc0:	08000613          	li	a2,128
    80005fc4:	f5040593          	addi	a1,s0,-176
    80005fc8:	4501                	li	a0,0
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	4d2080e7          	jalr	1234(ra) # 8000349c <argstr>
    return -1;
    80005fd2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005fd4:	0c054163          	bltz	a0,80006096 <sys_open+0xe4>
    80005fd8:	f4c40593          	addi	a1,s0,-180
    80005fdc:	4505                	li	a0,1
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	47a080e7          	jalr	1146(ra) # 80003458 <argint>
    80005fe6:	0a054863          	bltz	a0,80006096 <sys_open+0xe4>

  begin_op();
    80005fea:	fffff097          	auipc	ra,0xfffff
    80005fee:	a2e080e7          	jalr	-1490(ra) # 80004a18 <begin_op>

  if(omode & O_CREATE){
    80005ff2:	f4c42783          	lw	a5,-180(s0)
    80005ff6:	2007f793          	andi	a5,a5,512
    80005ffa:	cbdd                	beqz	a5,800060b0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ffc:	4681                	li	a3,0
    80005ffe:	4601                	li	a2,0
    80006000:	4589                	li	a1,2
    80006002:	f5040513          	addi	a0,s0,-176
    80006006:	00000097          	auipc	ra,0x0
    8000600a:	972080e7          	jalr	-1678(ra) # 80005978 <create>
    8000600e:	892a                	mv	s2,a0
    if(ip == 0){
    80006010:	c959                	beqz	a0,800060a6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006012:	04491703          	lh	a4,68(s2)
    80006016:	478d                	li	a5,3
    80006018:	00f71763          	bne	a4,a5,80006026 <sys_open+0x74>
    8000601c:	04695703          	lhu	a4,70(s2)
    80006020:	47a5                	li	a5,9
    80006022:	0ce7ec63          	bltu	a5,a4,800060fa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	e02080e7          	jalr	-510(ra) # 80004e28 <filealloc>
    8000602e:	89aa                	mv	s3,a0
    80006030:	10050263          	beqz	a0,80006134 <sys_open+0x182>
    80006034:	00000097          	auipc	ra,0x0
    80006038:	902080e7          	jalr	-1790(ra) # 80005936 <fdalloc>
    8000603c:	84aa                	mv	s1,a0
    8000603e:	0e054663          	bltz	a0,8000612a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006042:	04491703          	lh	a4,68(s2)
    80006046:	478d                	li	a5,3
    80006048:	0cf70463          	beq	a4,a5,80006110 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000604c:	4789                	li	a5,2
    8000604e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006052:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006056:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000605a:	f4c42783          	lw	a5,-180(s0)
    8000605e:	0017c713          	xori	a4,a5,1
    80006062:	8b05                	andi	a4,a4,1
    80006064:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006068:	0037f713          	andi	a4,a5,3
    8000606c:	00e03733          	snez	a4,a4
    80006070:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006074:	4007f793          	andi	a5,a5,1024
    80006078:	c791                	beqz	a5,80006084 <sys_open+0xd2>
    8000607a:	04491703          	lh	a4,68(s2)
    8000607e:	4789                	li	a5,2
    80006080:	08f70f63          	beq	a4,a5,8000611e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006084:	854a                	mv	a0,s2
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	082080e7          	jalr	130(ra) # 80004108 <iunlock>
  end_op();
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	a0a080e7          	jalr	-1526(ra) # 80004a98 <end_op>

  return fd;
}
    80006096:	8526                	mv	a0,s1
    80006098:	70ea                	ld	ra,184(sp)
    8000609a:	744a                	ld	s0,176(sp)
    8000609c:	74aa                	ld	s1,168(sp)
    8000609e:	790a                	ld	s2,160(sp)
    800060a0:	69ea                	ld	s3,152(sp)
    800060a2:	6129                	addi	sp,sp,192
    800060a4:	8082                	ret
      end_op();
    800060a6:	fffff097          	auipc	ra,0xfffff
    800060aa:	9f2080e7          	jalr	-1550(ra) # 80004a98 <end_op>
      return -1;
    800060ae:	b7e5                	j	80006096 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800060b0:	f5040513          	addi	a0,s0,-176
    800060b4:	ffffe097          	auipc	ra,0xffffe
    800060b8:	748080e7          	jalr	1864(ra) # 800047fc <namei>
    800060bc:	892a                	mv	s2,a0
    800060be:	c905                	beqz	a0,800060ee <sys_open+0x13c>
    ilock(ip);
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	f86080e7          	jalr	-122(ra) # 80004046 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800060c8:	04491703          	lh	a4,68(s2)
    800060cc:	4785                	li	a5,1
    800060ce:	f4f712e3          	bne	a4,a5,80006012 <sys_open+0x60>
    800060d2:	f4c42783          	lw	a5,-180(s0)
    800060d6:	dba1                	beqz	a5,80006026 <sys_open+0x74>
      iunlockput(ip);
    800060d8:	854a                	mv	a0,s2
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	1ce080e7          	jalr	462(ra) # 800042a8 <iunlockput>
      end_op();
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	9b6080e7          	jalr	-1610(ra) # 80004a98 <end_op>
      return -1;
    800060ea:	54fd                	li	s1,-1
    800060ec:	b76d                	j	80006096 <sys_open+0xe4>
      end_op();
    800060ee:	fffff097          	auipc	ra,0xfffff
    800060f2:	9aa080e7          	jalr	-1622(ra) # 80004a98 <end_op>
      return -1;
    800060f6:	54fd                	li	s1,-1
    800060f8:	bf79                	j	80006096 <sys_open+0xe4>
    iunlockput(ip);
    800060fa:	854a                	mv	a0,s2
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	1ac080e7          	jalr	428(ra) # 800042a8 <iunlockput>
    end_op();
    80006104:	fffff097          	auipc	ra,0xfffff
    80006108:	994080e7          	jalr	-1644(ra) # 80004a98 <end_op>
    return -1;
    8000610c:	54fd                	li	s1,-1
    8000610e:	b761                	j	80006096 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006110:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006114:	04691783          	lh	a5,70(s2)
    80006118:	02f99223          	sh	a5,36(s3)
    8000611c:	bf2d                	j	80006056 <sys_open+0xa4>
    itrunc(ip);
    8000611e:	854a                	mv	a0,s2
    80006120:	ffffe097          	auipc	ra,0xffffe
    80006124:	034080e7          	jalr	52(ra) # 80004154 <itrunc>
    80006128:	bfb1                	j	80006084 <sys_open+0xd2>
      fileclose(f);
    8000612a:	854e                	mv	a0,s3
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	db8080e7          	jalr	-584(ra) # 80004ee4 <fileclose>
    iunlockput(ip);
    80006134:	854a                	mv	a0,s2
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	172080e7          	jalr	370(ra) # 800042a8 <iunlockput>
    end_op();
    8000613e:	fffff097          	auipc	ra,0xfffff
    80006142:	95a080e7          	jalr	-1702(ra) # 80004a98 <end_op>
    return -1;
    80006146:	54fd                	li	s1,-1
    80006148:	b7b9                	j	80006096 <sys_open+0xe4>

000000008000614a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000614a:	7175                	addi	sp,sp,-144
    8000614c:	e506                	sd	ra,136(sp)
    8000614e:	e122                	sd	s0,128(sp)
    80006150:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006152:	fffff097          	auipc	ra,0xfffff
    80006156:	8c6080e7          	jalr	-1850(ra) # 80004a18 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000615a:	08000613          	li	a2,128
    8000615e:	f7040593          	addi	a1,s0,-144
    80006162:	4501                	li	a0,0
    80006164:	ffffd097          	auipc	ra,0xffffd
    80006168:	338080e7          	jalr	824(ra) # 8000349c <argstr>
    8000616c:	02054963          	bltz	a0,8000619e <sys_mkdir+0x54>
    80006170:	4681                	li	a3,0
    80006172:	4601                	li	a2,0
    80006174:	4585                	li	a1,1
    80006176:	f7040513          	addi	a0,s0,-144
    8000617a:	fffff097          	auipc	ra,0xfffff
    8000617e:	7fe080e7          	jalr	2046(ra) # 80005978 <create>
    80006182:	cd11                	beqz	a0,8000619e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	124080e7          	jalr	292(ra) # 800042a8 <iunlockput>
  end_op();
    8000618c:	fffff097          	auipc	ra,0xfffff
    80006190:	90c080e7          	jalr	-1780(ra) # 80004a98 <end_op>
  return 0;
    80006194:	4501                	li	a0,0
}
    80006196:	60aa                	ld	ra,136(sp)
    80006198:	640a                	ld	s0,128(sp)
    8000619a:	6149                	addi	sp,sp,144
    8000619c:	8082                	ret
    end_op();
    8000619e:	fffff097          	auipc	ra,0xfffff
    800061a2:	8fa080e7          	jalr	-1798(ra) # 80004a98 <end_op>
    return -1;
    800061a6:	557d                	li	a0,-1
    800061a8:	b7fd                	j	80006196 <sys_mkdir+0x4c>

00000000800061aa <sys_mknod>:

uint64
sys_mknod(void)
{
    800061aa:	7135                	addi	sp,sp,-160
    800061ac:	ed06                	sd	ra,152(sp)
    800061ae:	e922                	sd	s0,144(sp)
    800061b0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	866080e7          	jalr	-1946(ra) # 80004a18 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061ba:	08000613          	li	a2,128
    800061be:	f7040593          	addi	a1,s0,-144
    800061c2:	4501                	li	a0,0
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	2d8080e7          	jalr	728(ra) # 8000349c <argstr>
    800061cc:	04054a63          	bltz	a0,80006220 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800061d0:	f6c40593          	addi	a1,s0,-148
    800061d4:	4505                	li	a0,1
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	282080e7          	jalr	642(ra) # 80003458 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800061de:	04054163          	bltz	a0,80006220 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800061e2:	f6840593          	addi	a1,s0,-152
    800061e6:	4509                	li	a0,2
    800061e8:	ffffd097          	auipc	ra,0xffffd
    800061ec:	270080e7          	jalr	624(ra) # 80003458 <argint>
     argint(1, &major) < 0 ||
    800061f0:	02054863          	bltz	a0,80006220 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800061f4:	f6841683          	lh	a3,-152(s0)
    800061f8:	f6c41603          	lh	a2,-148(s0)
    800061fc:	458d                	li	a1,3
    800061fe:	f7040513          	addi	a0,s0,-144
    80006202:	fffff097          	auipc	ra,0xfffff
    80006206:	776080e7          	jalr	1910(ra) # 80005978 <create>
     argint(2, &minor) < 0 ||
    8000620a:	c919                	beqz	a0,80006220 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000620c:	ffffe097          	auipc	ra,0xffffe
    80006210:	09c080e7          	jalr	156(ra) # 800042a8 <iunlockput>
  end_op();
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	884080e7          	jalr	-1916(ra) # 80004a98 <end_op>
  return 0;
    8000621c:	4501                	li	a0,0
    8000621e:	a031                	j	8000622a <sys_mknod+0x80>
    end_op();
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	878080e7          	jalr	-1928(ra) # 80004a98 <end_op>
    return -1;
    80006228:	557d                	li	a0,-1
}
    8000622a:	60ea                	ld	ra,152(sp)
    8000622c:	644a                	ld	s0,144(sp)
    8000622e:	610d                	addi	sp,sp,160
    80006230:	8082                	ret

0000000080006232 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006232:	7135                	addi	sp,sp,-160
    80006234:	ed06                	sd	ra,152(sp)
    80006236:	e922                	sd	s0,144(sp)
    80006238:	e526                	sd	s1,136(sp)
    8000623a:	e14a                	sd	s2,128(sp)
    8000623c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000623e:	ffffc097          	auipc	ra,0xffffc
    80006242:	d08080e7          	jalr	-760(ra) # 80001f46 <myproc>
    80006246:	892a                	mv	s2,a0
  
  begin_op();
    80006248:	ffffe097          	auipc	ra,0xffffe
    8000624c:	7d0080e7          	jalr	2000(ra) # 80004a18 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006250:	08000613          	li	a2,128
    80006254:	f6040593          	addi	a1,s0,-160
    80006258:	4501                	li	a0,0
    8000625a:	ffffd097          	auipc	ra,0xffffd
    8000625e:	242080e7          	jalr	578(ra) # 8000349c <argstr>
    80006262:	04054b63          	bltz	a0,800062b8 <sys_chdir+0x86>
    80006266:	f6040513          	addi	a0,s0,-160
    8000626a:	ffffe097          	auipc	ra,0xffffe
    8000626e:	592080e7          	jalr	1426(ra) # 800047fc <namei>
    80006272:	84aa                	mv	s1,a0
    80006274:	c131                	beqz	a0,800062b8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006276:	ffffe097          	auipc	ra,0xffffe
    8000627a:	dd0080e7          	jalr	-560(ra) # 80004046 <ilock>
  if(ip->type != T_DIR){
    8000627e:	04449703          	lh	a4,68(s1)
    80006282:	4785                	li	a5,1
    80006284:	04f71063          	bne	a4,a5,800062c4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006288:	8526                	mv	a0,s1
    8000628a:	ffffe097          	auipc	ra,0xffffe
    8000628e:	e7e080e7          	jalr	-386(ra) # 80004108 <iunlock>
  iput(p->cwd);
    80006292:	15093503          	ld	a0,336(s2)
    80006296:	ffffe097          	auipc	ra,0xffffe
    8000629a:	f6a080e7          	jalr	-150(ra) # 80004200 <iput>
  end_op();
    8000629e:	ffffe097          	auipc	ra,0xffffe
    800062a2:	7fa080e7          	jalr	2042(ra) # 80004a98 <end_op>
  p->cwd = ip;
    800062a6:	14993823          	sd	s1,336(s2)
  return 0;
    800062aa:	4501                	li	a0,0
}
    800062ac:	60ea                	ld	ra,152(sp)
    800062ae:	644a                	ld	s0,144(sp)
    800062b0:	64aa                	ld	s1,136(sp)
    800062b2:	690a                	ld	s2,128(sp)
    800062b4:	610d                	addi	sp,sp,160
    800062b6:	8082                	ret
    end_op();
    800062b8:	ffffe097          	auipc	ra,0xffffe
    800062bc:	7e0080e7          	jalr	2016(ra) # 80004a98 <end_op>
    return -1;
    800062c0:	557d                	li	a0,-1
    800062c2:	b7ed                	j	800062ac <sys_chdir+0x7a>
    iunlockput(ip);
    800062c4:	8526                	mv	a0,s1
    800062c6:	ffffe097          	auipc	ra,0xffffe
    800062ca:	fe2080e7          	jalr	-30(ra) # 800042a8 <iunlockput>
    end_op();
    800062ce:	ffffe097          	auipc	ra,0xffffe
    800062d2:	7ca080e7          	jalr	1994(ra) # 80004a98 <end_op>
    return -1;
    800062d6:	557d                	li	a0,-1
    800062d8:	bfd1                	j	800062ac <sys_chdir+0x7a>

00000000800062da <sys_exec>:

uint64
sys_exec(void)
{
    800062da:	7145                	addi	sp,sp,-464
    800062dc:	e786                	sd	ra,456(sp)
    800062de:	e3a2                	sd	s0,448(sp)
    800062e0:	ff26                	sd	s1,440(sp)
    800062e2:	fb4a                	sd	s2,432(sp)
    800062e4:	f74e                	sd	s3,424(sp)
    800062e6:	f352                	sd	s4,416(sp)
    800062e8:	ef56                	sd	s5,408(sp)
    800062ea:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800062ec:	08000613          	li	a2,128
    800062f0:	f4040593          	addi	a1,s0,-192
    800062f4:	4501                	li	a0,0
    800062f6:	ffffd097          	auipc	ra,0xffffd
    800062fa:	1a6080e7          	jalr	422(ra) # 8000349c <argstr>
    return -1;
    800062fe:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006300:	0c054a63          	bltz	a0,800063d4 <sys_exec+0xfa>
    80006304:	e3840593          	addi	a1,s0,-456
    80006308:	4505                	li	a0,1
    8000630a:	ffffd097          	auipc	ra,0xffffd
    8000630e:	170080e7          	jalr	368(ra) # 8000347a <argaddr>
    80006312:	0c054163          	bltz	a0,800063d4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006316:	10000613          	li	a2,256
    8000631a:	4581                	li	a1,0
    8000631c:	e4040513          	addi	a0,s0,-448
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	9c0080e7          	jalr	-1600(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006328:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000632c:	89a6                	mv	s3,s1
    8000632e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006330:	02000a13          	li	s4,32
    80006334:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006338:	00391513          	slli	a0,s2,0x3
    8000633c:	e3040593          	addi	a1,s0,-464
    80006340:	e3843783          	ld	a5,-456(s0)
    80006344:	953e                	add	a0,a0,a5
    80006346:	ffffd097          	auipc	ra,0xffffd
    8000634a:	078080e7          	jalr	120(ra) # 800033be <fetchaddr>
    8000634e:	02054a63          	bltz	a0,80006382 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006352:	e3043783          	ld	a5,-464(s0)
    80006356:	c3b9                	beqz	a5,8000639c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006358:	ffffa097          	auipc	ra,0xffffa
    8000635c:	79c080e7          	jalr	1948(ra) # 80000af4 <kalloc>
    80006360:	85aa                	mv	a1,a0
    80006362:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006366:	cd11                	beqz	a0,80006382 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006368:	6605                	lui	a2,0x1
    8000636a:	e3043503          	ld	a0,-464(s0)
    8000636e:	ffffd097          	auipc	ra,0xffffd
    80006372:	0a2080e7          	jalr	162(ra) # 80003410 <fetchstr>
    80006376:	00054663          	bltz	a0,80006382 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000637a:	0905                	addi	s2,s2,1
    8000637c:	09a1                	addi	s3,s3,8
    8000637e:	fb491be3          	bne	s2,s4,80006334 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006382:	10048913          	addi	s2,s1,256
    80006386:	6088                	ld	a0,0(s1)
    80006388:	c529                	beqz	a0,800063d2 <sys_exec+0xf8>
    kfree(argv[i]);
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	66e080e7          	jalr	1646(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006392:	04a1                	addi	s1,s1,8
    80006394:	ff2499e3          	bne	s1,s2,80006386 <sys_exec+0xac>
  return -1;
    80006398:	597d                	li	s2,-1
    8000639a:	a82d                	j	800063d4 <sys_exec+0xfa>
      argv[i] = 0;
    8000639c:	0a8e                	slli	s5,s5,0x3
    8000639e:	fc040793          	addi	a5,s0,-64
    800063a2:	9abe                	add	s5,s5,a5
    800063a4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800063a8:	e4040593          	addi	a1,s0,-448
    800063ac:	f4040513          	addi	a0,s0,-192
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	194080e7          	jalr	404(ra) # 80005544 <exec>
    800063b8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063ba:	10048993          	addi	s3,s1,256
    800063be:	6088                	ld	a0,0(s1)
    800063c0:	c911                	beqz	a0,800063d4 <sys_exec+0xfa>
    kfree(argv[i]);
    800063c2:	ffffa097          	auipc	ra,0xffffa
    800063c6:	636080e7          	jalr	1590(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800063ca:	04a1                	addi	s1,s1,8
    800063cc:	ff3499e3          	bne	s1,s3,800063be <sys_exec+0xe4>
    800063d0:	a011                	j	800063d4 <sys_exec+0xfa>
  return -1;
    800063d2:	597d                	li	s2,-1
}
    800063d4:	854a                	mv	a0,s2
    800063d6:	60be                	ld	ra,456(sp)
    800063d8:	641e                	ld	s0,448(sp)
    800063da:	74fa                	ld	s1,440(sp)
    800063dc:	795a                	ld	s2,432(sp)
    800063de:	79ba                	ld	s3,424(sp)
    800063e0:	7a1a                	ld	s4,416(sp)
    800063e2:	6afa                	ld	s5,408(sp)
    800063e4:	6179                	addi	sp,sp,464
    800063e6:	8082                	ret

00000000800063e8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800063e8:	7139                	addi	sp,sp,-64
    800063ea:	fc06                	sd	ra,56(sp)
    800063ec:	f822                	sd	s0,48(sp)
    800063ee:	f426                	sd	s1,40(sp)
    800063f0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800063f2:	ffffc097          	auipc	ra,0xffffc
    800063f6:	b54080e7          	jalr	-1196(ra) # 80001f46 <myproc>
    800063fa:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800063fc:	fd840593          	addi	a1,s0,-40
    80006400:	4501                	li	a0,0
    80006402:	ffffd097          	auipc	ra,0xffffd
    80006406:	078080e7          	jalr	120(ra) # 8000347a <argaddr>
    return -1;
    8000640a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000640c:	0e054063          	bltz	a0,800064ec <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006410:	fc840593          	addi	a1,s0,-56
    80006414:	fd040513          	addi	a0,s0,-48
    80006418:	fffff097          	auipc	ra,0xfffff
    8000641c:	dfc080e7          	jalr	-516(ra) # 80005214 <pipealloc>
    return -1;
    80006420:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006422:	0c054563          	bltz	a0,800064ec <sys_pipe+0x104>
  fd0 = -1;
    80006426:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000642a:	fd043503          	ld	a0,-48(s0)
    8000642e:	fffff097          	auipc	ra,0xfffff
    80006432:	508080e7          	jalr	1288(ra) # 80005936 <fdalloc>
    80006436:	fca42223          	sw	a0,-60(s0)
    8000643a:	08054c63          	bltz	a0,800064d2 <sys_pipe+0xea>
    8000643e:	fc843503          	ld	a0,-56(s0)
    80006442:	fffff097          	auipc	ra,0xfffff
    80006446:	4f4080e7          	jalr	1268(ra) # 80005936 <fdalloc>
    8000644a:	fca42023          	sw	a0,-64(s0)
    8000644e:	06054863          	bltz	a0,800064be <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006452:	4691                	li	a3,4
    80006454:	fc440613          	addi	a2,s0,-60
    80006458:	fd843583          	ld	a1,-40(s0)
    8000645c:	68a8                	ld	a0,80(s1)
    8000645e:	ffffb097          	auipc	ra,0xffffb
    80006462:	214080e7          	jalr	532(ra) # 80001672 <copyout>
    80006466:	02054063          	bltz	a0,80006486 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000646a:	4691                	li	a3,4
    8000646c:	fc040613          	addi	a2,s0,-64
    80006470:	fd843583          	ld	a1,-40(s0)
    80006474:	0591                	addi	a1,a1,4
    80006476:	68a8                	ld	a0,80(s1)
    80006478:	ffffb097          	auipc	ra,0xffffb
    8000647c:	1fa080e7          	jalr	506(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006480:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006482:	06055563          	bgez	a0,800064ec <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006486:	fc442783          	lw	a5,-60(s0)
    8000648a:	07e9                	addi	a5,a5,26
    8000648c:	078e                	slli	a5,a5,0x3
    8000648e:	97a6                	add	a5,a5,s1
    80006490:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006494:	fc042503          	lw	a0,-64(s0)
    80006498:	0569                	addi	a0,a0,26
    8000649a:	050e                	slli	a0,a0,0x3
    8000649c:	9526                	add	a0,a0,s1
    8000649e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800064a2:	fd043503          	ld	a0,-48(s0)
    800064a6:	fffff097          	auipc	ra,0xfffff
    800064aa:	a3e080e7          	jalr	-1474(ra) # 80004ee4 <fileclose>
    fileclose(wf);
    800064ae:	fc843503          	ld	a0,-56(s0)
    800064b2:	fffff097          	auipc	ra,0xfffff
    800064b6:	a32080e7          	jalr	-1486(ra) # 80004ee4 <fileclose>
    return -1;
    800064ba:	57fd                	li	a5,-1
    800064bc:	a805                	j	800064ec <sys_pipe+0x104>
    if(fd0 >= 0)
    800064be:	fc442783          	lw	a5,-60(s0)
    800064c2:	0007c863          	bltz	a5,800064d2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800064c6:	01a78513          	addi	a0,a5,26
    800064ca:	050e                	slli	a0,a0,0x3
    800064cc:	9526                	add	a0,a0,s1
    800064ce:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800064d2:	fd043503          	ld	a0,-48(s0)
    800064d6:	fffff097          	auipc	ra,0xfffff
    800064da:	a0e080e7          	jalr	-1522(ra) # 80004ee4 <fileclose>
    fileclose(wf);
    800064de:	fc843503          	ld	a0,-56(s0)
    800064e2:	fffff097          	auipc	ra,0xfffff
    800064e6:	a02080e7          	jalr	-1534(ra) # 80004ee4 <fileclose>
    return -1;
    800064ea:	57fd                	li	a5,-1
}
    800064ec:	853e                	mv	a0,a5
    800064ee:	70e2                	ld	ra,56(sp)
    800064f0:	7442                	ld	s0,48(sp)
    800064f2:	74a2                	ld	s1,40(sp)
    800064f4:	6121                	addi	sp,sp,64
    800064f6:	8082                	ret
	...

0000000080006500 <kernelvec>:
    80006500:	7111                	addi	sp,sp,-256
    80006502:	e006                	sd	ra,0(sp)
    80006504:	e40a                	sd	sp,8(sp)
    80006506:	e80e                	sd	gp,16(sp)
    80006508:	ec12                	sd	tp,24(sp)
    8000650a:	f016                	sd	t0,32(sp)
    8000650c:	f41a                	sd	t1,40(sp)
    8000650e:	f81e                	sd	t2,48(sp)
    80006510:	fc22                	sd	s0,56(sp)
    80006512:	e0a6                	sd	s1,64(sp)
    80006514:	e4aa                	sd	a0,72(sp)
    80006516:	e8ae                	sd	a1,80(sp)
    80006518:	ecb2                	sd	a2,88(sp)
    8000651a:	f0b6                	sd	a3,96(sp)
    8000651c:	f4ba                	sd	a4,104(sp)
    8000651e:	f8be                	sd	a5,112(sp)
    80006520:	fcc2                	sd	a6,120(sp)
    80006522:	e146                	sd	a7,128(sp)
    80006524:	e54a                	sd	s2,136(sp)
    80006526:	e94e                	sd	s3,144(sp)
    80006528:	ed52                	sd	s4,152(sp)
    8000652a:	f156                	sd	s5,160(sp)
    8000652c:	f55a                	sd	s6,168(sp)
    8000652e:	f95e                	sd	s7,176(sp)
    80006530:	fd62                	sd	s8,184(sp)
    80006532:	e1e6                	sd	s9,192(sp)
    80006534:	e5ea                	sd	s10,200(sp)
    80006536:	e9ee                	sd	s11,208(sp)
    80006538:	edf2                	sd	t3,216(sp)
    8000653a:	f1f6                	sd	t4,224(sp)
    8000653c:	f5fa                	sd	t5,232(sp)
    8000653e:	f9fe                	sd	t6,240(sp)
    80006540:	d4bfc0ef          	jal	ra,8000328a <kerneltrap>
    80006544:	6082                	ld	ra,0(sp)
    80006546:	6122                	ld	sp,8(sp)
    80006548:	61c2                	ld	gp,16(sp)
    8000654a:	7282                	ld	t0,32(sp)
    8000654c:	7322                	ld	t1,40(sp)
    8000654e:	73c2                	ld	t2,48(sp)
    80006550:	7462                	ld	s0,56(sp)
    80006552:	6486                	ld	s1,64(sp)
    80006554:	6526                	ld	a0,72(sp)
    80006556:	65c6                	ld	a1,80(sp)
    80006558:	6666                	ld	a2,88(sp)
    8000655a:	7686                	ld	a3,96(sp)
    8000655c:	7726                	ld	a4,104(sp)
    8000655e:	77c6                	ld	a5,112(sp)
    80006560:	7866                	ld	a6,120(sp)
    80006562:	688a                	ld	a7,128(sp)
    80006564:	692a                	ld	s2,136(sp)
    80006566:	69ca                	ld	s3,144(sp)
    80006568:	6a6a                	ld	s4,152(sp)
    8000656a:	7a8a                	ld	s5,160(sp)
    8000656c:	7b2a                	ld	s6,168(sp)
    8000656e:	7bca                	ld	s7,176(sp)
    80006570:	7c6a                	ld	s8,184(sp)
    80006572:	6c8e                	ld	s9,192(sp)
    80006574:	6d2e                	ld	s10,200(sp)
    80006576:	6dce                	ld	s11,208(sp)
    80006578:	6e6e                	ld	t3,216(sp)
    8000657a:	7e8e                	ld	t4,224(sp)
    8000657c:	7f2e                	ld	t5,232(sp)
    8000657e:	7fce                	ld	t6,240(sp)
    80006580:	6111                	addi	sp,sp,256
    80006582:	10200073          	sret
    80006586:	00000013          	nop
    8000658a:	00000013          	nop
    8000658e:	0001                	nop

0000000080006590 <timervec>:
    80006590:	34051573          	csrrw	a0,mscratch,a0
    80006594:	e10c                	sd	a1,0(a0)
    80006596:	e510                	sd	a2,8(a0)
    80006598:	e914                	sd	a3,16(a0)
    8000659a:	6d0c                	ld	a1,24(a0)
    8000659c:	7110                	ld	a2,32(a0)
    8000659e:	6194                	ld	a3,0(a1)
    800065a0:	96b2                	add	a3,a3,a2
    800065a2:	e194                	sd	a3,0(a1)
    800065a4:	4589                	li	a1,2
    800065a6:	14459073          	csrw	sip,a1
    800065aa:	6914                	ld	a3,16(a0)
    800065ac:	6510                	ld	a2,8(a0)
    800065ae:	610c                	ld	a1,0(a0)
    800065b0:	34051573          	csrrw	a0,mscratch,a0
    800065b4:	30200073          	mret
	...

00000000800065ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800065ba:	1141                	addi	sp,sp,-16
    800065bc:	e422                	sd	s0,8(sp)
    800065be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800065c0:	0c0007b7          	lui	a5,0xc000
    800065c4:	4705                	li	a4,1
    800065c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800065c8:	c3d8                	sw	a4,4(a5)
}
    800065ca:	6422                	ld	s0,8(sp)
    800065cc:	0141                	addi	sp,sp,16
    800065ce:	8082                	ret

00000000800065d0 <plicinithart>:

void
plicinithart(void)
{
    800065d0:	1141                	addi	sp,sp,-16
    800065d2:	e406                	sd	ra,8(sp)
    800065d4:	e022                	sd	s0,0(sp)
    800065d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800065d8:	ffffc097          	auipc	ra,0xffffc
    800065dc:	93c080e7          	jalr	-1732(ra) # 80001f14 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800065e0:	0085171b          	slliw	a4,a0,0x8
    800065e4:	0c0027b7          	lui	a5,0xc002
    800065e8:	97ba                	add	a5,a5,a4
    800065ea:	40200713          	li	a4,1026
    800065ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800065f2:	00d5151b          	slliw	a0,a0,0xd
    800065f6:	0c2017b7          	lui	a5,0xc201
    800065fa:	953e                	add	a0,a0,a5
    800065fc:	00052023          	sw	zero,0(a0)
}
    80006600:	60a2                	ld	ra,8(sp)
    80006602:	6402                	ld	s0,0(sp)
    80006604:	0141                	addi	sp,sp,16
    80006606:	8082                	ret

0000000080006608 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006608:	1141                	addi	sp,sp,-16
    8000660a:	e406                	sd	ra,8(sp)
    8000660c:	e022                	sd	s0,0(sp)
    8000660e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006610:	ffffc097          	auipc	ra,0xffffc
    80006614:	904080e7          	jalr	-1788(ra) # 80001f14 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006618:	00d5179b          	slliw	a5,a0,0xd
    8000661c:	0c201537          	lui	a0,0xc201
    80006620:	953e                	add	a0,a0,a5
  return irq;
}
    80006622:	4148                	lw	a0,4(a0)
    80006624:	60a2                	ld	ra,8(sp)
    80006626:	6402                	ld	s0,0(sp)
    80006628:	0141                	addi	sp,sp,16
    8000662a:	8082                	ret

000000008000662c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000662c:	1101                	addi	sp,sp,-32
    8000662e:	ec06                	sd	ra,24(sp)
    80006630:	e822                	sd	s0,16(sp)
    80006632:	e426                	sd	s1,8(sp)
    80006634:	1000                	addi	s0,sp,32
    80006636:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006638:	ffffc097          	auipc	ra,0xffffc
    8000663c:	8dc080e7          	jalr	-1828(ra) # 80001f14 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006640:	00d5151b          	slliw	a0,a0,0xd
    80006644:	0c2017b7          	lui	a5,0xc201
    80006648:	97aa                	add	a5,a5,a0
    8000664a:	c3c4                	sw	s1,4(a5)
}
    8000664c:	60e2                	ld	ra,24(sp)
    8000664e:	6442                	ld	s0,16(sp)
    80006650:	64a2                	ld	s1,8(sp)
    80006652:	6105                	addi	sp,sp,32
    80006654:	8082                	ret

0000000080006656 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006656:	1141                	addi	sp,sp,-16
    80006658:	e406                	sd	ra,8(sp)
    8000665a:	e022                	sd	s0,0(sp)
    8000665c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000665e:	479d                	li	a5,7
    80006660:	06a7c963          	blt	a5,a0,800066d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006664:	0001d797          	auipc	a5,0x1d
    80006668:	99c78793          	addi	a5,a5,-1636 # 80023000 <disk>
    8000666c:	00a78733          	add	a4,a5,a0
    80006670:	6789                	lui	a5,0x2
    80006672:	97ba                	add	a5,a5,a4
    80006674:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006678:	e7ad                	bnez	a5,800066e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000667a:	00451793          	slli	a5,a0,0x4
    8000667e:	0001f717          	auipc	a4,0x1f
    80006682:	98270713          	addi	a4,a4,-1662 # 80025000 <disk+0x2000>
    80006686:	6314                	ld	a3,0(a4)
    80006688:	96be                	add	a3,a3,a5
    8000668a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000668e:	6314                	ld	a3,0(a4)
    80006690:	96be                	add	a3,a3,a5
    80006692:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006696:	6314                	ld	a3,0(a4)
    80006698:	96be                	add	a3,a3,a5
    8000669a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000669e:	6318                	ld	a4,0(a4)
    800066a0:	97ba                	add	a5,a5,a4
    800066a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800066a6:	0001d797          	auipc	a5,0x1d
    800066aa:	95a78793          	addi	a5,a5,-1702 # 80023000 <disk>
    800066ae:	97aa                	add	a5,a5,a0
    800066b0:	6509                	lui	a0,0x2
    800066b2:	953e                	add	a0,a0,a5
    800066b4:	4785                	li	a5,1
    800066b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800066ba:	0001f517          	auipc	a0,0x1f
    800066be:	95e50513          	addi	a0,a0,-1698 # 80025018 <disk+0x2018>
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	562080e7          	jalr	1378(ra) # 80002c24 <wakeup>
}
    800066ca:	60a2                	ld	ra,8(sp)
    800066cc:	6402                	ld	s0,0(sp)
    800066ce:	0141                	addi	sp,sp,16
    800066d0:	8082                	ret
    panic("free_desc 1");
    800066d2:	00002517          	auipc	a0,0x2
    800066d6:	21650513          	addi	a0,a0,534 # 800088e8 <syscalls+0x338>
    800066da:	ffffa097          	auipc	ra,0xffffa
    800066de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>
    panic("free_desc 2");
    800066e2:	00002517          	auipc	a0,0x2
    800066e6:	21650513          	addi	a0,a0,534 # 800088f8 <syscalls+0x348>
    800066ea:	ffffa097          	auipc	ra,0xffffa
    800066ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>

00000000800066f2 <virtio_disk_init>:
{
    800066f2:	1101                	addi	sp,sp,-32
    800066f4:	ec06                	sd	ra,24(sp)
    800066f6:	e822                	sd	s0,16(sp)
    800066f8:	e426                	sd	s1,8(sp)
    800066fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800066fc:	00002597          	auipc	a1,0x2
    80006700:	20c58593          	addi	a1,a1,524 # 80008908 <syscalls+0x358>
    80006704:	0001f517          	auipc	a0,0x1f
    80006708:	a2450513          	addi	a0,a0,-1500 # 80025128 <disk+0x2128>
    8000670c:	ffffa097          	auipc	ra,0xffffa
    80006710:	448080e7          	jalr	1096(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006714:	100017b7          	lui	a5,0x10001
    80006718:	4398                	lw	a4,0(a5)
    8000671a:	2701                	sext.w	a4,a4
    8000671c:	747277b7          	lui	a5,0x74727
    80006720:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006724:	0ef71163          	bne	a4,a5,80006806 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006728:	100017b7          	lui	a5,0x10001
    8000672c:	43dc                	lw	a5,4(a5)
    8000672e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006730:	4705                	li	a4,1
    80006732:	0ce79a63          	bne	a5,a4,80006806 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006736:	100017b7          	lui	a5,0x10001
    8000673a:	479c                	lw	a5,8(a5)
    8000673c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000673e:	4709                	li	a4,2
    80006740:	0ce79363          	bne	a5,a4,80006806 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006744:	100017b7          	lui	a5,0x10001
    80006748:	47d8                	lw	a4,12(a5)
    8000674a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000674c:	554d47b7          	lui	a5,0x554d4
    80006750:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006754:	0af71963          	bne	a4,a5,80006806 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006758:	100017b7          	lui	a5,0x10001
    8000675c:	4705                	li	a4,1
    8000675e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006760:	470d                	li	a4,3
    80006762:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006764:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006766:	c7ffe737          	lui	a4,0xc7ffe
    8000676a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000676e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006770:	2701                	sext.w	a4,a4
    80006772:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006774:	472d                	li	a4,11
    80006776:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006778:	473d                	li	a4,15
    8000677a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000677c:	6705                	lui	a4,0x1
    8000677e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006780:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006784:	5bdc                	lw	a5,52(a5)
    80006786:	2781                	sext.w	a5,a5
  if(max == 0)
    80006788:	c7d9                	beqz	a5,80006816 <virtio_disk_init+0x124>
  if(max < NUM)
    8000678a:	471d                	li	a4,7
    8000678c:	08f77d63          	bgeu	a4,a5,80006826 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006790:	100014b7          	lui	s1,0x10001
    80006794:	47a1                	li	a5,8
    80006796:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006798:	6609                	lui	a2,0x2
    8000679a:	4581                	li	a1,0
    8000679c:	0001d517          	auipc	a0,0x1d
    800067a0:	86450513          	addi	a0,a0,-1948 # 80023000 <disk>
    800067a4:	ffffa097          	auipc	ra,0xffffa
    800067a8:	53c080e7          	jalr	1340(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800067ac:	0001d717          	auipc	a4,0x1d
    800067b0:	85470713          	addi	a4,a4,-1964 # 80023000 <disk>
    800067b4:	00c75793          	srli	a5,a4,0xc
    800067b8:	2781                	sext.w	a5,a5
    800067ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800067bc:	0001f797          	auipc	a5,0x1f
    800067c0:	84478793          	addi	a5,a5,-1980 # 80025000 <disk+0x2000>
    800067c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800067c6:	0001d717          	auipc	a4,0x1d
    800067ca:	8ba70713          	addi	a4,a4,-1862 # 80023080 <disk+0x80>
    800067ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800067d0:	0001e717          	auipc	a4,0x1e
    800067d4:	83070713          	addi	a4,a4,-2000 # 80024000 <disk+0x1000>
    800067d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800067da:	4705                	li	a4,1
    800067dc:	00e78c23          	sb	a4,24(a5)
    800067e0:	00e78ca3          	sb	a4,25(a5)
    800067e4:	00e78d23          	sb	a4,26(a5)
    800067e8:	00e78da3          	sb	a4,27(a5)
    800067ec:	00e78e23          	sb	a4,28(a5)
    800067f0:	00e78ea3          	sb	a4,29(a5)
    800067f4:	00e78f23          	sb	a4,30(a5)
    800067f8:	00e78fa3          	sb	a4,31(a5)
}
    800067fc:	60e2                	ld	ra,24(sp)
    800067fe:	6442                	ld	s0,16(sp)
    80006800:	64a2                	ld	s1,8(sp)
    80006802:	6105                	addi	sp,sp,32
    80006804:	8082                	ret
    panic("could not find virtio disk");
    80006806:	00002517          	auipc	a0,0x2
    8000680a:	11250513          	addi	a0,a0,274 # 80008918 <syscalls+0x368>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	d30080e7          	jalr	-720(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006816:	00002517          	auipc	a0,0x2
    8000681a:	12250513          	addi	a0,a0,290 # 80008938 <syscalls+0x388>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	d20080e7          	jalr	-736(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006826:	00002517          	auipc	a0,0x2
    8000682a:	13250513          	addi	a0,a0,306 # 80008958 <syscalls+0x3a8>
    8000682e:	ffffa097          	auipc	ra,0xffffa
    80006832:	d10080e7          	jalr	-752(ra) # 8000053e <panic>

0000000080006836 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006836:	7159                	addi	sp,sp,-112
    80006838:	f486                	sd	ra,104(sp)
    8000683a:	f0a2                	sd	s0,96(sp)
    8000683c:	eca6                	sd	s1,88(sp)
    8000683e:	e8ca                	sd	s2,80(sp)
    80006840:	e4ce                	sd	s3,72(sp)
    80006842:	e0d2                	sd	s4,64(sp)
    80006844:	fc56                	sd	s5,56(sp)
    80006846:	f85a                	sd	s6,48(sp)
    80006848:	f45e                	sd	s7,40(sp)
    8000684a:	f062                	sd	s8,32(sp)
    8000684c:	ec66                	sd	s9,24(sp)
    8000684e:	e86a                	sd	s10,16(sp)
    80006850:	1880                	addi	s0,sp,112
    80006852:	892a                	mv	s2,a0
    80006854:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006856:	00c52c83          	lw	s9,12(a0)
    8000685a:	001c9c9b          	slliw	s9,s9,0x1
    8000685e:	1c82                	slli	s9,s9,0x20
    80006860:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006864:	0001f517          	auipc	a0,0x1f
    80006868:	8c450513          	addi	a0,a0,-1852 # 80025128 <disk+0x2128>
    8000686c:	ffffa097          	auipc	ra,0xffffa
    80006870:	378080e7          	jalr	888(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006874:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006876:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006878:	0001cb97          	auipc	s7,0x1c
    8000687c:	788b8b93          	addi	s7,s7,1928 # 80023000 <disk>
    80006880:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006882:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006884:	8a4e                	mv	s4,s3
    80006886:	a051                	j	8000690a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006888:	00fb86b3          	add	a3,s7,a5
    8000688c:	96da                	add	a3,a3,s6
    8000688e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006892:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006894:	0207c563          	bltz	a5,800068be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006898:	2485                	addiw	s1,s1,1
    8000689a:	0711                	addi	a4,a4,4
    8000689c:	25548063          	beq	s1,s5,80006adc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800068a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800068a2:	0001e697          	auipc	a3,0x1e
    800068a6:	77668693          	addi	a3,a3,1910 # 80025018 <disk+0x2018>
    800068aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800068ac:	0006c583          	lbu	a1,0(a3)
    800068b0:	fde1                	bnez	a1,80006888 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800068b2:	2785                	addiw	a5,a5,1
    800068b4:	0685                	addi	a3,a3,1
    800068b6:	ff879be3          	bne	a5,s8,800068ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800068ba:	57fd                	li	a5,-1
    800068bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800068be:	02905a63          	blez	s1,800068f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068c2:	f9042503          	lw	a0,-112(s0)
    800068c6:	00000097          	auipc	ra,0x0
    800068ca:	d90080e7          	jalr	-624(ra) # 80006656 <free_desc>
      for(int j = 0; j < i; j++)
    800068ce:	4785                	li	a5,1
    800068d0:	0297d163          	bge	a5,s1,800068f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068d4:	f9442503          	lw	a0,-108(s0)
    800068d8:	00000097          	auipc	ra,0x0
    800068dc:	d7e080e7          	jalr	-642(ra) # 80006656 <free_desc>
      for(int j = 0; j < i; j++)
    800068e0:	4789                	li	a5,2
    800068e2:	0097d863          	bge	a5,s1,800068f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800068e6:	f9842503          	lw	a0,-104(s0)
    800068ea:	00000097          	auipc	ra,0x0
    800068ee:	d6c080e7          	jalr	-660(ra) # 80006656 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800068f2:	0001f597          	auipc	a1,0x1f
    800068f6:	83658593          	addi	a1,a1,-1994 # 80025128 <disk+0x2128>
    800068fa:	0001e517          	auipc	a0,0x1e
    800068fe:	71e50513          	addi	a0,a0,1822 # 80025018 <disk+0x2018>
    80006902:	ffffc097          	auipc	ra,0xffffc
    80006906:	cec080e7          	jalr	-788(ra) # 800025ee <sleep>
  for(int i = 0; i < 3; i++){
    8000690a:	f9040713          	addi	a4,s0,-112
    8000690e:	84ce                	mv	s1,s3
    80006910:	bf41                	j	800068a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006912:	20058713          	addi	a4,a1,512
    80006916:	00471693          	slli	a3,a4,0x4
    8000691a:	0001c717          	auipc	a4,0x1c
    8000691e:	6e670713          	addi	a4,a4,1766 # 80023000 <disk>
    80006922:	9736                	add	a4,a4,a3
    80006924:	4685                	li	a3,1
    80006926:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000692a:	20058713          	addi	a4,a1,512
    8000692e:	00471693          	slli	a3,a4,0x4
    80006932:	0001c717          	auipc	a4,0x1c
    80006936:	6ce70713          	addi	a4,a4,1742 # 80023000 <disk>
    8000693a:	9736                	add	a4,a4,a3
    8000693c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006940:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006944:	7679                	lui	a2,0xffffe
    80006946:	963e                	add	a2,a2,a5
    80006948:	0001e697          	auipc	a3,0x1e
    8000694c:	6b868693          	addi	a3,a3,1720 # 80025000 <disk+0x2000>
    80006950:	6298                	ld	a4,0(a3)
    80006952:	9732                	add	a4,a4,a2
    80006954:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006956:	6298                	ld	a4,0(a3)
    80006958:	9732                	add	a4,a4,a2
    8000695a:	4541                	li	a0,16
    8000695c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000695e:	6298                	ld	a4,0(a3)
    80006960:	9732                	add	a4,a4,a2
    80006962:	4505                	li	a0,1
    80006964:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006968:	f9442703          	lw	a4,-108(s0)
    8000696c:	6288                	ld	a0,0(a3)
    8000696e:	962a                	add	a2,a2,a0
    80006970:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006974:	0712                	slli	a4,a4,0x4
    80006976:	6290                	ld	a2,0(a3)
    80006978:	963a                	add	a2,a2,a4
    8000697a:	05890513          	addi	a0,s2,88
    8000697e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006980:	6294                	ld	a3,0(a3)
    80006982:	96ba                	add	a3,a3,a4
    80006984:	40000613          	li	a2,1024
    80006988:	c690                	sw	a2,8(a3)
  if(write)
    8000698a:	140d0063          	beqz	s10,80006aca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000698e:	0001e697          	auipc	a3,0x1e
    80006992:	6726b683          	ld	a3,1650(a3) # 80025000 <disk+0x2000>
    80006996:	96ba                	add	a3,a3,a4
    80006998:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000699c:	0001c817          	auipc	a6,0x1c
    800069a0:	66480813          	addi	a6,a6,1636 # 80023000 <disk>
    800069a4:	0001e517          	auipc	a0,0x1e
    800069a8:	65c50513          	addi	a0,a0,1628 # 80025000 <disk+0x2000>
    800069ac:	6114                	ld	a3,0(a0)
    800069ae:	96ba                	add	a3,a3,a4
    800069b0:	00c6d603          	lhu	a2,12(a3)
    800069b4:	00166613          	ori	a2,a2,1
    800069b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800069bc:	f9842683          	lw	a3,-104(s0)
    800069c0:	6110                	ld	a2,0(a0)
    800069c2:	9732                	add	a4,a4,a2
    800069c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800069c8:	20058613          	addi	a2,a1,512
    800069cc:	0612                	slli	a2,a2,0x4
    800069ce:	9642                	add	a2,a2,a6
    800069d0:	577d                	li	a4,-1
    800069d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800069d6:	00469713          	slli	a4,a3,0x4
    800069da:	6114                	ld	a3,0(a0)
    800069dc:	96ba                	add	a3,a3,a4
    800069de:	03078793          	addi	a5,a5,48
    800069e2:	97c2                	add	a5,a5,a6
    800069e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800069e6:	611c                	ld	a5,0(a0)
    800069e8:	97ba                	add	a5,a5,a4
    800069ea:	4685                	li	a3,1
    800069ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800069ee:	611c                	ld	a5,0(a0)
    800069f0:	97ba                	add	a5,a5,a4
    800069f2:	4809                	li	a6,2
    800069f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800069f8:	611c                	ld	a5,0(a0)
    800069fa:	973e                	add	a4,a4,a5
    800069fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006a00:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006a04:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006a08:	6518                	ld	a4,8(a0)
    80006a0a:	00275783          	lhu	a5,2(a4)
    80006a0e:	8b9d                	andi	a5,a5,7
    80006a10:	0786                	slli	a5,a5,0x1
    80006a12:	97ba                	add	a5,a5,a4
    80006a14:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006a18:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006a1c:	6518                	ld	a4,8(a0)
    80006a1e:	00275783          	lhu	a5,2(a4)
    80006a22:	2785                	addiw	a5,a5,1
    80006a24:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006a28:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006a2c:	100017b7          	lui	a5,0x10001
    80006a30:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006a34:	00492703          	lw	a4,4(s2)
    80006a38:	4785                	li	a5,1
    80006a3a:	02f71163          	bne	a4,a5,80006a5c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80006a3e:	0001e997          	auipc	s3,0x1e
    80006a42:	6ea98993          	addi	s3,s3,1770 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006a46:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006a48:	85ce                	mv	a1,s3
    80006a4a:	854a                	mv	a0,s2
    80006a4c:	ffffc097          	auipc	ra,0xffffc
    80006a50:	ba2080e7          	jalr	-1118(ra) # 800025ee <sleep>
  while(b->disk == 1) {
    80006a54:	00492783          	lw	a5,4(s2)
    80006a58:	fe9788e3          	beq	a5,s1,80006a48 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    80006a5c:	f9042903          	lw	s2,-112(s0)
    80006a60:	20090793          	addi	a5,s2,512
    80006a64:	00479713          	slli	a4,a5,0x4
    80006a68:	0001c797          	auipc	a5,0x1c
    80006a6c:	59878793          	addi	a5,a5,1432 # 80023000 <disk>
    80006a70:	97ba                	add	a5,a5,a4
    80006a72:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006a76:	0001e997          	auipc	s3,0x1e
    80006a7a:	58a98993          	addi	s3,s3,1418 # 80025000 <disk+0x2000>
    80006a7e:	00491713          	slli	a4,s2,0x4
    80006a82:	0009b783          	ld	a5,0(s3)
    80006a86:	97ba                	add	a5,a5,a4
    80006a88:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a8c:	854a                	mv	a0,s2
    80006a8e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a92:	00000097          	auipc	ra,0x0
    80006a96:	bc4080e7          	jalr	-1084(ra) # 80006656 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a9a:	8885                	andi	s1,s1,1
    80006a9c:	f0ed                	bnez	s1,80006a7e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a9e:	0001e517          	auipc	a0,0x1e
    80006aa2:	68a50513          	addi	a0,a0,1674 # 80025128 <disk+0x2128>
    80006aa6:	ffffa097          	auipc	ra,0xffffa
    80006aaa:	1f2080e7          	jalr	498(ra) # 80000c98 <release>
}
    80006aae:	70a6                	ld	ra,104(sp)
    80006ab0:	7406                	ld	s0,96(sp)
    80006ab2:	64e6                	ld	s1,88(sp)
    80006ab4:	6946                	ld	s2,80(sp)
    80006ab6:	69a6                	ld	s3,72(sp)
    80006ab8:	6a06                	ld	s4,64(sp)
    80006aba:	7ae2                	ld	s5,56(sp)
    80006abc:	7b42                	ld	s6,48(sp)
    80006abe:	7ba2                	ld	s7,40(sp)
    80006ac0:	7c02                	ld	s8,32(sp)
    80006ac2:	6ce2                	ld	s9,24(sp)
    80006ac4:	6d42                	ld	s10,16(sp)
    80006ac6:	6165                	addi	sp,sp,112
    80006ac8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006aca:	0001e697          	auipc	a3,0x1e
    80006ace:	5366b683          	ld	a3,1334(a3) # 80025000 <disk+0x2000>
    80006ad2:	96ba                	add	a3,a3,a4
    80006ad4:	4609                	li	a2,2
    80006ad6:	00c69623          	sh	a2,12(a3)
    80006ada:	b5c9                	j	8000699c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006adc:	f9042583          	lw	a1,-112(s0)
    80006ae0:	20058793          	addi	a5,a1,512
    80006ae4:	0792                	slli	a5,a5,0x4
    80006ae6:	0001c517          	auipc	a0,0x1c
    80006aea:	5c250513          	addi	a0,a0,1474 # 800230a8 <disk+0xa8>
    80006aee:	953e                	add	a0,a0,a5
  if(write)
    80006af0:	e20d11e3          	bnez	s10,80006912 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006af4:	20058713          	addi	a4,a1,512
    80006af8:	00471693          	slli	a3,a4,0x4
    80006afc:	0001c717          	auipc	a4,0x1c
    80006b00:	50470713          	addi	a4,a4,1284 # 80023000 <disk>
    80006b04:	9736                	add	a4,a4,a3
    80006b06:	0a072423          	sw	zero,168(a4)
    80006b0a:	b505                	j	8000692a <virtio_disk_rw+0xf4>

0000000080006b0c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006b0c:	1101                	addi	sp,sp,-32
    80006b0e:	ec06                	sd	ra,24(sp)
    80006b10:	e822                	sd	s0,16(sp)
    80006b12:	e426                	sd	s1,8(sp)
    80006b14:	e04a                	sd	s2,0(sp)
    80006b16:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006b18:	0001e517          	auipc	a0,0x1e
    80006b1c:	61050513          	addi	a0,a0,1552 # 80025128 <disk+0x2128>
    80006b20:	ffffa097          	auipc	ra,0xffffa
    80006b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006b28:	10001737          	lui	a4,0x10001
    80006b2c:	533c                	lw	a5,96(a4)
    80006b2e:	8b8d                	andi	a5,a5,3
    80006b30:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006b32:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006b36:	0001e797          	auipc	a5,0x1e
    80006b3a:	4ca78793          	addi	a5,a5,1226 # 80025000 <disk+0x2000>
    80006b3e:	6b94                	ld	a3,16(a5)
    80006b40:	0207d703          	lhu	a4,32(a5)
    80006b44:	0026d783          	lhu	a5,2(a3)
    80006b48:	06f70163          	beq	a4,a5,80006baa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b4c:	0001c917          	auipc	s2,0x1c
    80006b50:	4b490913          	addi	s2,s2,1204 # 80023000 <disk>
    80006b54:	0001e497          	auipc	s1,0x1e
    80006b58:	4ac48493          	addi	s1,s1,1196 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006b5c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006b60:	6898                	ld	a4,16(s1)
    80006b62:	0204d783          	lhu	a5,32(s1)
    80006b66:	8b9d                	andi	a5,a5,7
    80006b68:	078e                	slli	a5,a5,0x3
    80006b6a:	97ba                	add	a5,a5,a4
    80006b6c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006b6e:	20078713          	addi	a4,a5,512
    80006b72:	0712                	slli	a4,a4,0x4
    80006b74:	974a                	add	a4,a4,s2
    80006b76:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006b7a:	e731                	bnez	a4,80006bc6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006b7c:	20078793          	addi	a5,a5,512
    80006b80:	0792                	slli	a5,a5,0x4
    80006b82:	97ca                	add	a5,a5,s2
    80006b84:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b86:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b8a:	ffffc097          	auipc	ra,0xffffc
    80006b8e:	09a080e7          	jalr	154(ra) # 80002c24 <wakeup>

    disk.used_idx += 1;
    80006b92:	0204d783          	lhu	a5,32(s1)
    80006b96:	2785                	addiw	a5,a5,1
    80006b98:	17c2                	slli	a5,a5,0x30
    80006b9a:	93c1                	srli	a5,a5,0x30
    80006b9c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ba0:	6898                	ld	a4,16(s1)
    80006ba2:	00275703          	lhu	a4,2(a4)
    80006ba6:	faf71be3          	bne	a4,a5,80006b5c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006baa:	0001e517          	auipc	a0,0x1e
    80006bae:	57e50513          	addi	a0,a0,1406 # 80025128 <disk+0x2128>
    80006bb2:	ffffa097          	auipc	ra,0xffffa
    80006bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
}
    80006bba:	60e2                	ld	ra,24(sp)
    80006bbc:	6442                	ld	s0,16(sp)
    80006bbe:	64a2                	ld	s1,8(sp)
    80006bc0:	6902                	ld	s2,0(sp)
    80006bc2:	6105                	addi	sp,sp,32
    80006bc4:	8082                	ret
      panic("virtio_disk_intr status");
    80006bc6:	00002517          	auipc	a0,0x2
    80006bca:	db250513          	addi	a0,a0,-590 # 80008978 <syscalls+0x3c8>
    80006bce:	ffffa097          	auipc	ra,0xffffa
    80006bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>

0000000080006bd6 <cas>:
    80006bd6:	100522af          	lr.w	t0,(a0)
    80006bda:	00b29563          	bne	t0,a1,80006be4 <fail>
    80006bde:	18c5252f          	sc.w	a0,a2,(a0)
    80006be2:	8082                	ret

0000000080006be4 <fail>:
    80006be4:	4505                	li	a0,1
    80006be6:	8082                	ret
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
