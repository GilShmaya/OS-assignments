
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
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
    80000068:	ffc78793          	addi	a5,a5,-4 # 80006060 <timervec>
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
    80000130:	722080e7          	jalr	1826(ra) # 8000284e <either_copyin>
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
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
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
    800001c8:	810080e7          	jalr	-2032(ra) # 800019d4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1b2080e7          	jalr	434(ra) # 80002386 <sleep>
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
    80000214:	5e8080e7          	jalr	1512(ra) # 800027f8 <either_copyout>
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
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
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
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
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
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
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
    800002f6:	5b2080e7          	jalr	1458(ra) # 800028a4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
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
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
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
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
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
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
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
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
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
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
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
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	0d6080e7          	jalr	214(ra) # 8000251c <wakeup>
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
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
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
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
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
    80000570:	db450513          	addi	a0,a0,-588 # 80008320 <digits+0x2e0>
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
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
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
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
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
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
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
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
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
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
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
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
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
    800008a4:	c7c080e7          	jalr	-900(ra) # 8000251c <wakeup>
    
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
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
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
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a5a080e7          	jalr	-1446(ra) # 80002386 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
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
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
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
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
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
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
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
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
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
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
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
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
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
    80000b82:	e3a080e7          	jalr	-454(ra) # 800019b8 <mycpu>
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
    80000bb4:	e08080e7          	jalr	-504(ra) # 800019b8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dfc080e7          	jalr	-516(ra) # 800019b8 <mycpu>
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
    80000bd8:	de4080e7          	jalr	-540(ra) # 800019b8 <mycpu>
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
    80000c18:	da4080e7          	jalr	-604(ra) # 800019b8 <mycpu>
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
    80000c44:	d78080e7          	jalr	-648(ra) # 800019b8 <mycpu>
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
    80000e9a:	b12080e7          	jalr	-1262(ra) # 800019a8 <cpuid>
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
    80000eb6:	af6080e7          	jalr	-1290(ra) # 800019a8 <cpuid>
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
    80000ed8:	c50080e7          	jalr	-944(ra) # 80002b24 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	1c4080e7          	jalr	452(ra) # 800060a0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	290080e7          	jalr	656(ra) # 80002174 <scheduler>
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
    80000f08:	41c50513          	addi	a0,a0,1052 # 80008320 <digits+0x2e0>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	3fc50513          	addi	a0,a0,1020 # 80008320 <digits+0x2e0>
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
    80000f50:	99c080e7          	jalr	-1636(ra) # 800018e8 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	ba8080e7          	jalr	-1112(ra) # 80002afc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	bc8080e7          	jalr	-1080(ra) # 80002b24 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	126080e7          	jalr	294(ra) # 8000608a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	134080e7          	jalr	308(ra) # 800060a0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	310080e7          	jalr	784(ra) # 80003284 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	9a0080e7          	jalr	-1632(ra) # 8000391c <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	94a080e7          	jalr	-1718(ra) # 800048ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	236080e7          	jalr	566(ra) # 800061c2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d20080e7          	jalr	-736(ra) # 80001cb4 <userinit>
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
    8000124c:	60a080e7          	jalr	1546(ra) # 80001852 <proc_mapstacks>
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
  #endif
}  
    8000184c:	6422                	ld	s0,8(sp)
    8000184e:	0141                	addi	sp,sp,16
    80001850:	8082                	ret

0000000080001852 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001852:	7139                	addi	sp,sp,-64
    80001854:	fc06                	sd	ra,56(sp)
    80001856:	f822                	sd	s0,48(sp)
    80001858:	f426                	sd	s1,40(sp)
    8000185a:	f04a                	sd	s2,32(sp)
    8000185c:	ec4e                	sd	s3,24(sp)
    8000185e:	e852                	sd	s4,16(sp)
    80001860:	e456                	sd	s5,8(sp)
    80001862:	e05a                	sd	s6,0(sp)
    80001864:	0080                	addi	s0,sp,64
    80001866:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001868:	00010497          	auipc	s1,0x10
    8000186c:	e8848493          	addi	s1,s1,-376 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001870:	8b26                	mv	s6,s1
    80001872:	00006a97          	auipc	s5,0x6
    80001876:	78ea8a93          	addi	s5,s5,1934 # 80008000 <etext>
    8000187a:	04000937          	lui	s2,0x4000
    8000187e:	197d                	addi	s2,s2,-1
    80001880:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001882:	00016a17          	auipc	s4,0x16
    80001886:	06ea0a13          	addi	s4,s4,110 # 800178f0 <tickslock>
    char *pa = kalloc();
    8000188a:	fffff097          	auipc	ra,0xfffff
    8000188e:	26a080e7          	jalr	618(ra) # 80000af4 <kalloc>
    80001892:	862a                	mv	a2,a0
    if(pa == 0)
    80001894:	c131                	beqz	a0,800018d8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001896:	416485b3          	sub	a1,s1,s6
    8000189a:	858d                	srai	a1,a1,0x3
    8000189c:	000ab783          	ld	a5,0(s5)
    800018a0:	02f585b3          	mul	a1,a1,a5
    800018a4:	2585                	addiw	a1,a1,1
    800018a6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018aa:	4719                	li	a4,6
    800018ac:	6685                	lui	a3,0x1
    800018ae:	40b905b3          	sub	a1,s2,a1
    800018b2:	854e                	mv	a0,s3
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	8a4080e7          	jalr	-1884(ra) # 80001158 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018bc:	18848493          	addi	s1,s1,392
    800018c0:	fd4495e3          	bne	s1,s4,8000188a <proc_mapstacks+0x38>
  }
}
    800018c4:	70e2                	ld	ra,56(sp)
    800018c6:	7442                	ld	s0,48(sp)
    800018c8:	74a2                	ld	s1,40(sp)
    800018ca:	7902                	ld	s2,32(sp)
    800018cc:	69e2                	ld	s3,24(sp)
    800018ce:	6a42                	ld	s4,16(sp)
    800018d0:	6aa2                	ld	s5,8(sp)
    800018d2:	6b02                	ld	s6,0(sp)
    800018d4:	6121                	addi	sp,sp,64
    800018d6:	8082                	ret
      panic("kalloc");
    800018d8:	00007517          	auipc	a0,0x7
    800018dc:	90050513          	addi	a0,a0,-1792 # 800081d8 <digits+0x198>
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	c5e080e7          	jalr	-930(ra) # 8000053e <panic>

00000000800018e8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018e8:	7139                	addi	sp,sp,-64
    800018ea:	fc06                	sd	ra,56(sp)
    800018ec:	f822                	sd	s0,48(sp)
    800018ee:	f426                	sd	s1,40(sp)
    800018f0:	f04a                	sd	s2,32(sp)
    800018f2:	ec4e                	sd	s3,24(sp)
    800018f4:	e852                	sd	s4,16(sp)
    800018f6:	e456                	sd	s5,8(sp)
    800018f8:	e05a                	sd	s6,0(sp)
    800018fa:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fc:	00007597          	auipc	a1,0x7
    80001900:	8e458593          	addi	a1,a1,-1820 # 800081e0 <digits+0x1a0>
    80001904:	00010517          	auipc	a0,0x10
    80001908:	9bc50513          	addi	a0,a0,-1604 # 800112c0 <pid_lock>
    8000190c:	fffff097          	auipc	ra,0xfffff
    80001910:	248080e7          	jalr	584(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001914:	00007597          	auipc	a1,0x7
    80001918:	8d458593          	addi	a1,a1,-1836 # 800081e8 <digits+0x1a8>
    8000191c:	00010517          	auipc	a0,0x10
    80001920:	9bc50513          	addi	a0,a0,-1604 # 800112d8 <wait_lock>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	230080e7          	jalr	560(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	00010497          	auipc	s1,0x10
    80001930:	dc448493          	addi	s1,s1,-572 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001934:	00007b17          	auipc	s6,0x7
    80001938:	8c4b0b13          	addi	s6,s6,-1852 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000193c:	8aa6                	mv	s5,s1
    8000193e:	00006a17          	auipc	s4,0x6
    80001942:	6c2a0a13          	addi	s4,s4,1730 # 80008000 <etext>
    80001946:	04000937          	lui	s2,0x4000
    8000194a:	197d                	addi	s2,s2,-1
    8000194c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00016997          	auipc	s3,0x16
    80001952:	fa298993          	addi	s3,s3,-94 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001956:	85da                	mv	a1,s6
    80001958:	8526                	mv	a0,s1
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001962:	415487b3          	sub	a5,s1,s5
    80001966:	878d                	srai	a5,a5,0x3
    80001968:	000a3703          	ld	a4,0(s4)
    8000196c:	02e787b3          	mul	a5,a5,a4
    80001970:	2785                	addiw	a5,a5,1
    80001972:	00d7979b          	slliw	a5,a5,0xd
    80001976:	40f907b3          	sub	a5,s2,a5
    8000197a:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	18848493          	addi	s1,s1,392
    80001980:	fd349be3          	bne	s1,s3,80001956 <procinit+0x6e>
  }

  start_time = ticks;
    80001984:	00007797          	auipc	a5,0x7
    80001988:	6cc7a783          	lw	a5,1740(a5) # 80009050 <ticks>
    8000198c:	00007717          	auipc	a4,0x7
    80001990:	6af72023          	sw	a5,1696(a4) # 8000902c <start_time>
}
    80001994:	70e2                	ld	ra,56(sp)
    80001996:	7442                	ld	s0,48(sp)
    80001998:	74a2                	ld	s1,40(sp)
    8000199a:	7902                	ld	s2,32(sp)
    8000199c:	69e2                	ld	s3,24(sp)
    8000199e:	6a42                	ld	s4,16(sp)
    800019a0:	6aa2                	ld	s5,8(sp)
    800019a2:	6b02                	ld	s6,0(sp)
    800019a4:	6121                	addi	sp,sp,64
    800019a6:	8082                	ret

00000000800019a8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019a8:	1141                	addi	sp,sp,-16
    800019aa:	e422                	sd	s0,8(sp)
    800019ac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019b0:	2501                	sext.w	a0,a0
    800019b2:	6422                	ld	s0,8(sp)
    800019b4:	0141                	addi	sp,sp,16
    800019b6:	8082                	ret

00000000800019b8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e422                	sd	s0,8(sp)
    800019bc:	0800                	addi	s0,sp,16
    800019be:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
  return c;
}
    800019c4:	00010517          	auipc	a0,0x10
    800019c8:	92c50513          	addi	a0,a0,-1748 # 800112f0 <cpus>
    800019cc:	953e                	add	a0,a0,a5
    800019ce:	6422                	ld	s0,8(sp)
    800019d0:	0141                	addi	sp,sp,16
    800019d2:	8082                	ret

00000000800019d4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	1000                	addi	s0,sp,32
  push_off();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	1ba080e7          	jalr	442(ra) # 80000b98 <push_off>
    800019e6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019e8:	2781                	sext.w	a5,a5
    800019ea:	079e                	slli	a5,a5,0x7
    800019ec:	00010717          	auipc	a4,0x10
    800019f0:	8d470713          	addi	a4,a4,-1836 # 800112c0 <pid_lock>
    800019f4:	97ba                	add	a5,a5,a4
    800019f6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	240080e7          	jalr	576(ra) # 80000c38 <pop_off>
  return p;
}
    80001a00:	8526                	mv	a0,s1
    80001a02:	60e2                	ld	ra,24(sp)
    80001a04:	6442                	ld	s0,16(sp)
    80001a06:	64a2                	ld	s1,8(sp)
    80001a08:	6105                	addi	sp,sp,32
    80001a0a:	8082                	ret

0000000080001a0c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a0c:	1141                	addi	sp,sp,-16
    80001a0e:	e406                	sd	ra,8(sp)
    80001a10:	e022                	sd	s0,0(sp)
    80001a12:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a14:	00000097          	auipc	ra,0x0
    80001a18:	fc0080e7          	jalr	-64(ra) # 800019d4 <myproc>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>

  if (first) {
    80001a24:	00007797          	auipc	a5,0x7
    80001a28:	ebc7a783          	lw	a5,-324(a5) # 800088e0 <first.1753>
    80001a2c:	eb89                	bnez	a5,80001a3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a2e:	00001097          	auipc	ra,0x1
    80001a32:	10e080e7          	jalr	270(ra) # 80002b3c <usertrapret>
}
    80001a36:	60a2                	ld	ra,8(sp)
    80001a38:	6402                	ld	s0,0(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret
    first = 0;
    80001a3e:	00007797          	auipc	a5,0x7
    80001a42:	ea07a123          	sw	zero,-350(a5) # 800088e0 <first.1753>
    fsinit(ROOTDEV);
    80001a46:	4505                	li	a0,1
    80001a48:	00002097          	auipc	ra,0x2
    80001a4c:	e54080e7          	jalr	-428(ra) # 8000389c <fsinit>
    80001a50:	bff9                	j	80001a2e <forkret+0x22>

0000000080001a52 <allocpid>:
allocpid() {
    80001a52:	1101                	addi	sp,sp,-32
    80001a54:	ec06                	sd	ra,24(sp)
    80001a56:	e822                	sd	s0,16(sp)
    80001a58:	e426                	sd	s1,8(sp)
    80001a5a:	e04a                	sd	s2,0(sp)
    80001a5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a5e:	00010917          	auipc	s2,0x10
    80001a62:	86290913          	addi	s2,s2,-1950 # 800112c0 <pid_lock>
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	17c080e7          	jalr	380(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a70:	00007797          	auipc	a5,0x7
    80001a74:	e7478793          	addi	a5,a5,-396 # 800088e4 <nextpid>
    80001a78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a7a:	0014871b          	addiw	a4,s1,1
    80001a7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a80:	854a                	mv	a0,s2
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	216080e7          	jalr	534(ra) # 80000c98 <release>
}
    80001a8a:	8526                	mv	a0,s1
    80001a8c:	60e2                	ld	ra,24(sp)
    80001a8e:	6442                	ld	s0,16(sp)
    80001a90:	64a2                	ld	s1,8(sp)
    80001a92:	6902                	ld	s2,0(sp)
    80001a94:	6105                	addi	sp,sp,32
    80001a96:	8082                	ret

0000000080001a98 <proc_pagetable>:
{
    80001a98:	1101                	addi	sp,sp,-32
    80001a9a:	ec06                	sd	ra,24(sp)
    80001a9c:	e822                	sd	s0,16(sp)
    80001a9e:	e426                	sd	s1,8(sp)
    80001aa0:	e04a                	sd	s2,0(sp)
    80001aa2:	1000                	addi	s0,sp,32
    80001aa4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aa6:	00000097          	auipc	ra,0x0
    80001aaa:	89c080e7          	jalr	-1892(ra) # 80001342 <uvmcreate>
    80001aae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ab0:	c121                	beqz	a0,80001af0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ab2:	4729                	li	a4,10
    80001ab4:	00005697          	auipc	a3,0x5
    80001ab8:	54c68693          	addi	a3,a3,1356 # 80007000 <_trampoline>
    80001abc:	6605                	lui	a2,0x1
    80001abe:	040005b7          	lui	a1,0x4000
    80001ac2:	15fd                	addi	a1,a1,-1
    80001ac4:	05b2                	slli	a1,a1,0xc
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	5f2080e7          	jalr	1522(ra) # 800010b8 <mappages>
    80001ace:	02054863          	bltz	a0,80001afe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ad2:	4719                	li	a4,6
    80001ad4:	07893683          	ld	a3,120(s2)
    80001ad8:	6605                	lui	a2,0x1
    80001ada:	020005b7          	lui	a1,0x2000
    80001ade:	15fd                	addi	a1,a1,-1
    80001ae0:	05b6                	slli	a1,a1,0xd
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	5d4080e7          	jalr	1492(ra) # 800010b8 <mappages>
    80001aec:	02054163          	bltz	a0,80001b0e <proc_pagetable+0x76>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6902                	ld	s2,0(sp)
    80001afa:	6105                	addi	sp,sp,32
    80001afc:	8082                	ret
    uvmfree(pagetable, 0);
    80001afe:	4581                	li	a1,0
    80001b00:	8526                	mv	a0,s1
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	a3c080e7          	jalr	-1476(ra) # 8000153e <uvmfree>
    return 0;
    80001b0a:	4481                	li	s1,0
    80001b0c:	b7d5                	j	80001af0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b0e:	4681                	li	a3,0
    80001b10:	4605                	li	a2,1
    80001b12:	040005b7          	lui	a1,0x4000
    80001b16:	15fd                	addi	a1,a1,-1
    80001b18:	05b2                	slli	a1,a1,0xc
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	762080e7          	jalr	1890(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b24:	4581                	li	a1,0
    80001b26:	8526                	mv	a0,s1
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	a16080e7          	jalr	-1514(ra) # 8000153e <uvmfree>
    return 0;
    80001b30:	4481                	li	s1,0
    80001b32:	bf7d                	j	80001af0 <proc_pagetable+0x58>

0000000080001b34 <proc_freepagetable>:
{
    80001b34:	1101                	addi	sp,sp,-32
    80001b36:	ec06                	sd	ra,24(sp)
    80001b38:	e822                	sd	s0,16(sp)
    80001b3a:	e426                	sd	s1,8(sp)
    80001b3c:	e04a                	sd	s2,0(sp)
    80001b3e:	1000                	addi	s0,sp,32
    80001b40:	84aa                	mv	s1,a0
    80001b42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	040005b7          	lui	a1,0x4000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b2                	slli	a1,a1,0xc
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	72e080e7          	jalr	1838(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b58:	4681                	li	a3,0
    80001b5a:	4605                	li	a2,1
    80001b5c:	020005b7          	lui	a1,0x2000
    80001b60:	15fd                	addi	a1,a1,-1
    80001b62:	05b6                	slli	a1,a1,0xd
    80001b64:	8526                	mv	a0,s1
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	718080e7          	jalr	1816(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b6e:	85ca                	mv	a1,s2
    80001b70:	8526                	mv	a0,s1
    80001b72:	00000097          	auipc	ra,0x0
    80001b76:	9cc080e7          	jalr	-1588(ra) # 8000153e <uvmfree>
}
    80001b7a:	60e2                	ld	ra,24(sp)
    80001b7c:	6442                	ld	s0,16(sp)
    80001b7e:	64a2                	ld	s1,8(sp)
    80001b80:	6902                	ld	s2,0(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <freeproc>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b92:	7d28                	ld	a0,120(a0)
    80001b94:	c509                	beqz	a0,80001b9e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	e62080e7          	jalr	-414(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b9e:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001ba2:	78a8                	ld	a0,112(s1)
    80001ba4:	c511                	beqz	a0,80001bb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ba6:	74ac                	ld	a1,104(s1)
    80001ba8:	00000097          	auipc	ra,0x0
    80001bac:	f8c080e7          	jalr	-116(ra) # 80001b34 <proc_freepagetable>
  p->pagetable = 0;
    80001bb0:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001bb4:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001bb8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bbc:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001bc0:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001bc4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bc8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bcc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bd0:	0004ac23          	sw	zero,24(s1)
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6105                	addi	sp,sp,32
    80001bdc:	8082                	ret

0000000080001bde <allocproc>:
{
    80001bde:	1101                	addi	sp,sp,-32
    80001be0:	ec06                	sd	ra,24(sp)
    80001be2:	e822                	sd	s0,16(sp)
    80001be4:	e426                	sd	s1,8(sp)
    80001be6:	e04a                	sd	s2,0(sp)
    80001be8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	00010497          	auipc	s1,0x10
    80001bee:	b0648493          	addi	s1,s1,-1274 # 800116f0 <proc>
    80001bf2:	00016917          	auipc	s2,0x16
    80001bf6:	cfe90913          	addi	s2,s2,-770 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	fe8080e7          	jalr	-24(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c04:	4c9c                	lw	a5,24(s1)
    80001c06:	cf81                	beqz	a5,80001c1e <allocproc+0x40>
      release(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	08e080e7          	jalr	142(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c12:	18848493          	addi	s1,s1,392
    80001c16:	ff2492e3          	bne	s1,s2,80001bfa <allocproc+0x1c>
  return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	a8a9                	j	80001c76 <allocproc+0x98>
  p->pid = allocpid();
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e34080e7          	jalr	-460(ra) # 80001a52 <allocpid>
    80001c26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c28:	4785                	li	a5,1
    80001c2a:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c2c:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c30:	0204ac23          	sw	zero,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	ec0080e7          	jalr	-320(ra) # 80000af4 <kalloc>
    80001c3c:	892a                	mv	s2,a0
    80001c3e:	fca8                	sd	a0,120(s1)
    80001c40:	c131                	beqz	a0,80001c84 <allocproc+0xa6>
  p->pagetable = proc_pagetable(p);
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e54080e7          	jalr	-428(ra) # 80001a98 <proc_pagetable>
    80001c4c:	892a                	mv	s2,a0
    80001c4e:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001c50:	c531                	beqz	a0,80001c9c <allocproc+0xbe>
  memset(&p->context, 0, sizeof(p->context));
    80001c52:	07000613          	li	a2,112
    80001c56:	4581                	li	a1,0
    80001c58:	08048513          	addi	a0,s1,128
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	084080e7          	jalr	132(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c64:	00000797          	auipc	a5,0x0
    80001c68:	da878793          	addi	a5,a5,-600 # 80001a0c <forkret>
    80001c6c:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6e:	70bc                	ld	a5,96(s1)
    80001c70:	6705                	lui	a4,0x1
    80001c72:	97ba                	add	a5,a5,a4
    80001c74:	e4dc                	sd	a5,136(s1)
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	addi	sp,sp,32
    80001c82:	8082                	ret
    freeproc(p);
    80001c84:	8526                	mv	a0,s1
    80001c86:	00000097          	auipc	ra,0x0
    80001c8a:	f00080e7          	jalr	-256(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	008080e7          	jalr	8(ra) # 80000c98 <release>
    return 0;
    80001c98:	84ca                	mv	s1,s2
    80001c9a:	bff1                	j	80001c76 <allocproc+0x98>
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	ee8080e7          	jalr	-280(ra) # 80001b86 <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ff0080e7          	jalr	-16(ra) # 80000c98 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7d1                	j	80001c76 <allocproc+0x98>

0000000080001cb4 <userinit>:
{
    80001cb4:	1101                	addi	sp,sp,-32
    80001cb6:	ec06                	sd	ra,24(sp)
    80001cb8:	e822                	sd	s0,16(sp)
    80001cba:	e426                	sd	s1,8(sp)
    80001cbc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	f20080e7          	jalr	-224(ra) # 80001bde <allocproc>
    80001cc6:	84aa                	mv	s1,a0
  initproc = p;
    80001cc8:	00007797          	auipc	a5,0x7
    80001ccc:	38a7b023          	sd	a0,896(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd0:	03400613          	li	a2,52
    80001cd4:	00007597          	auipc	a1,0x7
    80001cd8:	c1c58593          	addi	a1,a1,-996 # 800088f0 <initcode>
    80001cdc:	7928                	ld	a0,112(a0)
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	692080e7          	jalr	1682(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001ce6:	6785                	lui	a5,0x1
    80001ce8:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cea:	7cb8                	ld	a4,120(s1)
    80001cec:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf0:	7cb8                	ld	a4,120(s1)
    80001cf2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf4:	4641                	li	a2,16
    80001cf6:	00006597          	auipc	a1,0x6
    80001cfa:	50a58593          	addi	a1,a1,1290 # 80008200 <digits+0x1c0>
    80001cfe:	17848513          	addi	a0,s1,376
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	130080e7          	jalr	304(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d0a:	00006517          	auipc	a0,0x6
    80001d0e:	50650513          	addi	a0,a0,1286 # 80008210 <digits+0x1d0>
    80001d12:	00002097          	auipc	ra,0x2
    80001d16:	5b8080e7          	jalr	1464(ra) # 800042ca <namei>
    80001d1a:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	f74080e7          	jalr	-140(ra) # 80000c98 <release>
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <growproc>:
{
    80001d36:	1101                	addi	sp,sp,-32
    80001d38:	ec06                	sd	ra,24(sp)
    80001d3a:	e822                	sd	s0,16(sp)
    80001d3c:	e426                	sd	s1,8(sp)
    80001d3e:	e04a                	sd	s2,0(sp)
    80001d40:	1000                	addi	s0,sp,32
    80001d42:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d44:	00000097          	auipc	ra,0x0
    80001d48:	c90080e7          	jalr	-880(ra) # 800019d4 <myproc>
    80001d4c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d4e:	752c                	ld	a1,104(a0)
    80001d50:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d54:	00904f63          	bgtz	s1,80001d72 <growproc+0x3c>
  } else if(n < 0){
    80001d58:	0204cc63          	bltz	s1,80001d90 <growproc+0x5a>
  p->sz = sz;
    80001d5c:	1602                	slli	a2,a2,0x20
    80001d5e:	9201                	srli	a2,a2,0x20
    80001d60:	06c93423          	sd	a2,104(s2)
  return 0;
    80001d64:	4501                	li	a0,0
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6902                	ld	s2,0(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d72:	9e25                	addw	a2,a2,s1
    80001d74:	1602                	slli	a2,a2,0x20
    80001d76:	9201                	srli	a2,a2,0x20
    80001d78:	1582                	slli	a1,a1,0x20
    80001d7a:	9181                	srli	a1,a1,0x20
    80001d7c:	7928                	ld	a0,112(a0)
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	6ac080e7          	jalr	1708(ra) # 8000142a <uvmalloc>
    80001d86:	0005061b          	sext.w	a2,a0
    80001d8a:	fa69                	bnez	a2,80001d5c <growproc+0x26>
      return -1;
    80001d8c:	557d                	li	a0,-1
    80001d8e:	bfe1                	j	80001d66 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d90:	9e25                	addw	a2,a2,s1
    80001d92:	1602                	slli	a2,a2,0x20
    80001d94:	9201                	srli	a2,a2,0x20
    80001d96:	1582                	slli	a1,a1,0x20
    80001d98:	9181                	srli	a1,a1,0x20
    80001d9a:	7928                	ld	a0,112(a0)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	646080e7          	jalr	1606(ra) # 800013e2 <uvmdealloc>
    80001da4:	0005061b          	sext.w	a2,a0
    80001da8:	bf55                	j	80001d5c <growproc+0x26>

0000000080001daa <fork>:
{
    80001daa:	7179                	addi	sp,sp,-48
    80001dac:	f406                	sd	ra,40(sp)
    80001dae:	f022                	sd	s0,32(sp)
    80001db0:	ec26                	sd	s1,24(sp)
    80001db2:	e84a                	sd	s2,16(sp)
    80001db4:	e44e                	sd	s3,8(sp)
    80001db6:	e052                	sd	s4,0(sp)
    80001db8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c1a080e7          	jalr	-998(ra) # 800019d4 <myproc>
    80001dc2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	e1a080e7          	jalr	-486(ra) # 80001bde <allocproc>
    80001dcc:	10050b63          	beqz	a0,80001ee2 <fork+0x138>
    80001dd0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd2:	06893603          	ld	a2,104(s2)
    80001dd6:	792c                	ld	a1,112(a0)
    80001dd8:	07093503          	ld	a0,112(s2)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	79a080e7          	jalr	1946(ra) # 80001576 <uvmcopy>
    80001de4:	04054663          	bltz	a0,80001e30 <fork+0x86>
  np->sz = p->sz;
    80001de8:	06893783          	ld	a5,104(s2)
    80001dec:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80001df0:	07893683          	ld	a3,120(s2)
    80001df4:	87b6                	mv	a5,a3
    80001df6:	0789b703          	ld	a4,120(s3)
    80001dfa:	12068693          	addi	a3,a3,288
    80001dfe:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e02:	6788                	ld	a0,8(a5)
    80001e04:	6b8c                	ld	a1,16(a5)
    80001e06:	6f90                	ld	a2,24(a5)
    80001e08:	01073023          	sd	a6,0(a4)
    80001e0c:	e708                	sd	a0,8(a4)
    80001e0e:	eb0c                	sd	a1,16(a4)
    80001e10:	ef10                	sd	a2,24(a4)
    80001e12:	02078793          	addi	a5,a5,32
    80001e16:	02070713          	addi	a4,a4,32
    80001e1a:	fed792e3          	bne	a5,a3,80001dfe <fork+0x54>
  np->trapframe->a0 = 0;
    80001e1e:	0789b783          	ld	a5,120(s3)
    80001e22:	0607b823          	sd	zero,112(a5)
    80001e26:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80001e2a:	17000a13          	li	s4,368
    80001e2e:	a03d                	j	80001e5c <fork+0xb2>
    freeproc(np);
    80001e30:	854e                	mv	a0,s3
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	d54080e7          	jalr	-684(ra) # 80001b86 <freeproc>
    release(&np->lock);
    80001e3a:	854e                	mv	a0,s3
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e5c080e7          	jalr	-420(ra) # 80000c98 <release>
    return -1;
    80001e44:	5a7d                	li	s4,-1
    80001e46:	a069                	j	80001ed0 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e48:	00003097          	auipc	ra,0x3
    80001e4c:	b18080e7          	jalr	-1256(ra) # 80004960 <filedup>
    80001e50:	009987b3          	add	a5,s3,s1
    80001e54:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	01448763          	beq	s1,s4,80001e66 <fork+0xbc>
    if(p->ofile[i])
    80001e5c:	009907b3          	add	a5,s2,s1
    80001e60:	6388                	ld	a0,0(a5)
    80001e62:	f17d                	bnez	a0,80001e48 <fork+0x9e>
    80001e64:	bfcd                	j	80001e56 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e66:	17093503          	ld	a0,368(s2)
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	c6c080e7          	jalr	-916(ra) # 80003ad6 <idup>
    80001e72:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e76:	4641                	li	a2,16
    80001e78:	17890593          	addi	a1,s2,376
    80001e7c:	17898513          	addi	a0,s3,376
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	fb2080e7          	jalr	-78(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e88:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e0a080e7          	jalr	-502(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001e96:	0000f497          	auipc	s1,0xf
    80001e9a:	44248493          	addi	s1,s1,1090 # 800112d8 <wait_lock>
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	d44080e7          	jalr	-700(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ea8:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80001eac:	8526                	mv	a0,s1
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001eb6:	854e                	mv	a0,s3
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	d2c080e7          	jalr	-724(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ec0:	478d                	li	a5,3
    80001ec2:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
}
    80001ed0:	8552                	mv	a0,s4
    80001ed2:	70a2                	ld	ra,40(sp)
    80001ed4:	7402                	ld	s0,32(sp)
    80001ed6:	64e2                	ld	s1,24(sp)
    80001ed8:	6942                	ld	s2,16(sp)
    80001eda:	69a2                	ld	s3,8(sp)
    80001edc:	6a02                	ld	s4,0(sp)
    80001ede:	6145                	addi	sp,sp,48
    80001ee0:	8082                	ret
    return -1;
    80001ee2:	5a7d                	li	s4,-1
    80001ee4:	b7f5                	j	80001ed0 <fork+0x126>

0000000080001ee6 <get_mean>:
{
    80001ee6:	1141                	addi	sp,sp,-16
    80001ee8:	e422                	sd	s0,8(sp)
    80001eea:	0800                	addi	s0,sp,16
  return ( last_mean * num_procs + curr_time) / (num_procs + 1);
    80001eec:	02c5053b          	mulw	a0,a0,a2
    80001ef0:	9d2d                	addw	a0,a0,a1
    80001ef2:	2605                	addiw	a2,a2,1
}
    80001ef4:	02c5453b          	divw	a0,a0,a2
    80001ef8:	6422                	ld	s0,8(sp)
    80001efa:	0141                	addi	sp,sp,16
    80001efc:	8082                	ret

0000000080001efe <scheduler_default>:
{
    80001efe:	715d                	addi	sp,sp,-80
    80001f00:	e486                	sd	ra,72(sp)
    80001f02:	e0a2                	sd	s0,64(sp)
    80001f04:	fc26                	sd	s1,56(sp)
    80001f06:	f84a                	sd	s2,48(sp)
    80001f08:	f44e                	sd	s3,40(sp)
    80001f0a:	f052                	sd	s4,32(sp)
    80001f0c:	ec56                	sd	s5,24(sp)
    80001f0e:	e85a                	sd	s6,16(sp)
    80001f10:	e45e                	sd	s7,8(sp)
    80001f12:	e062                	sd	s8,0(sp)
    80001f14:	0880                	addi	s0,sp,80
    80001f16:	8792                	mv	a5,tp
  int id = r_tp();
    80001f18:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f1a:	00779c13          	slli	s8,a5,0x7
    80001f1e:	0000f717          	auipc	a4,0xf
    80001f22:	3a270713          	addi	a4,a4,930 # 800112c0 <pid_lock>
    80001f26:	9762                	add	a4,a4,s8
    80001f28:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f2c:	0000f717          	auipc	a4,0xf
    80001f30:	3cc70713          	addi	a4,a4,972 # 800112f8 <cpus+0x8>
    80001f34:	9c3a                	add	s8,s8,a4
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f36:	00007917          	auipc	s2,0x7
    80001f3a:	11a90913          	addi	s2,s2,282 # 80009050 <ticks>
    80001f3e:	00007a17          	auipc	s4,0x7
    80001f42:	106a0a13          	addi	s4,s4,262 # 80009044 <pause_ticks>
          c->proc = p;
    80001f46:	079e                	slli	a5,a5,0x7
    80001f48:	0000fb17          	auipc	s6,0xf
    80001f4c:	378b0b13          	addi	s6,s6,888 # 800112c0 <pid_lock>
    80001f50:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f52:	00016997          	auipc	s3,0x16
    80001f56:	99e98993          	addi	s3,s3,-1634 # 800178f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f62:	10079073          	csrw	sstatus,a5
    80001f66:	0000f497          	auipc	s1,0xf
    80001f6a:	78a48493          	addi	s1,s1,1930 # 800116f0 <proc>
        if(p->state == RUNNABLE) {
    80001f6e:	4a8d                	li	s5,3
          p->state = RUNNING;
    80001f70:	4b91                	li	s7,4
    80001f72:	a01d                	j	80001f98 <scheduler_default+0x9a>
          p->running_time += ticks - p->start_last_running;
    80001f74:	44bc                	lw	a5,72(s1)
    80001f76:	00092703          	lw	a4,0(s2)
    80001f7a:	9fb9                	addw	a5,a5,a4
    80001f7c:	48f8                	lw	a4,84(s1)
    80001f7e:	9f99                	subw	a5,a5,a4
    80001f80:	c4bc                	sw	a5,72(s1)
          c->proc = 0;
    80001f82:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	d10080e7          	jalr	-752(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f90:	18848493          	addi	s1,s1,392
    80001f94:	fd3483e3          	beq	s1,s3,80001f5a <scheduler_default+0x5c>
      if(ticks >= pause_ticks){ // check if pause signal was called
    80001f98:	00092703          	lw	a4,0(s2)
    80001f9c:	000a2783          	lw	a5,0(s4)
    80001fa0:	fef768e3          	bltu	a4,a5,80001f90 <scheduler_default+0x92>
        acquire(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
        if(p->state == RUNNABLE) {
    80001fae:	4c9c                	lw	a5,24(s1)
    80001fb0:	fd579be3          	bne	a5,s5,80001f86 <scheduler_default+0x88>
          p->state = RUNNING;
    80001fb4:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80001fb8:	029b3823          	sd	s1,48(s6)
          p->runnable_time += ticks - p->start_last_runnable;
    80001fbc:	00092703          	lw	a4,0(s2)
    80001fc0:	40fc                	lw	a5,68(s1)
    80001fc2:	9fb9                	addw	a5,a5,a4
    80001fc4:	48b4                	lw	a3,80(s1)
    80001fc6:	9f95                	subw	a5,a5,a3
    80001fc8:	c0fc                	sw	a5,68(s1)
          p->start_last_running = ticks;
    80001fca:	c8f8                	sw	a4,84(s1)
          swtch(&c->context, &p->context);
    80001fcc:	08048593          	addi	a1,s1,128
    80001fd0:	8562                	mv	a0,s8
    80001fd2:	00001097          	auipc	ra,0x1
    80001fd6:	ac0080e7          	jalr	-1344(ra) # 80002a92 <swtch>
          if(p->state == RUNNABLE)
    80001fda:	4c9c                	lw	a5,24(s1)
    80001fdc:	f9579ce3          	bne	a5,s5,80001f74 <scheduler_default+0x76>
            p->start_last_runnable = ticks;
    80001fe0:	00092783          	lw	a5,0(s2)
    80001fe4:	c8bc                	sw	a5,80(s1)
    80001fe6:	b779                	j	80001f74 <scheduler_default+0x76>

0000000080001fe8 <swap_process_ptr>:
{
    80001fe8:	1141                	addi	sp,sp,-16
    80001fea:	e422                	sd	s0,8(sp)
    80001fec:	0800                	addi	s0,sp,16
  struct proc *temp = *p1;
    80001fee:	611c                	ld	a5,0(a0)
  *p1 = *p2;
    80001ff0:	6198                	ld	a4,0(a1)
    80001ff2:	e118                	sd	a4,0(a0)
  *p2 = temp; 
    80001ff4:	e19c                	sd	a5,0(a1)
}     
    80001ff6:	6422                	ld	s0,8(sp)
    80001ff8:	0141                	addi	sp,sp,16
    80001ffa:	8082                	ret

0000000080001ffc <make_acquired_process_running>:
make_acquired_process_running(struct cpu *c, struct proc *p){
    80001ffc:	1101                	addi	sp,sp,-32
    80001ffe:	ec06                	sd	ra,24(sp)
    80002000:	e822                	sd	s0,16(sp)
    80002002:	e426                	sd	s1,8(sp)
    80002004:	e04a                	sd	s2,0(sp)
    80002006:	1000                	addi	s0,sp,32
    80002008:	892a                	mv	s2,a0
    8000200a:	84ae                	mv	s1,a1
  p->state = RUNNING;
    8000200c:	4791                	li	a5,4
    8000200e:	cd9c                	sw	a5,24(a1)
  c->proc = p;
    80002010:	e10c                	sd	a1,0(a0)
  p->runnable_time += ticks - p->start_last_runnable;
    80002012:	00007717          	auipc	a4,0x7
    80002016:	03e72703          	lw	a4,62(a4) # 80009050 <ticks>
    8000201a:	41fc                	lw	a5,68(a1)
    8000201c:	9fb9                	addw	a5,a5,a4
    8000201e:	49b4                	lw	a3,80(a1)
    80002020:	9f95                	subw	a5,a5,a3
    80002022:	c1fc                	sw	a5,68(a1)
  p->start_last_running = ticks;
    80002024:	c9f8                	sw	a4,84(a1)
  swtch(&c->context, &p->context);
    80002026:	08058593          	addi	a1,a1,128
    8000202a:	0521                	addi	a0,a0,8
    8000202c:	00001097          	auipc	ra,0x1
    80002030:	a66080e7          	jalr	-1434(ra) # 80002a92 <swtch>
  if(p->state == RUNNABLE)
    80002034:	4c98                	lw	a4,24(s1)
    80002036:	478d                	li	a5,3
    80002038:	02f70363          	beq	a4,a5,8000205e <make_acquired_process_running+0x62>
  p->running_time += ticks - p->start_last_running;
    8000203c:	44bc                	lw	a5,72(s1)
    8000203e:	00007717          	auipc	a4,0x7
    80002042:	01272703          	lw	a4,18(a4) # 80009050 <ticks>
    80002046:	9fb9                	addw	a5,a5,a4
    80002048:	48f8                	lw	a4,84(s1)
    8000204a:	9f99                	subw	a5,a5,a4
    8000204c:	c4bc                	sw	a5,72(s1)
  c->proc = 0;
    8000204e:	00093023          	sd	zero,0(s2)
}
    80002052:	60e2                	ld	ra,24(sp)
    80002054:	6442                	ld	s0,16(sp)
    80002056:	64a2                	ld	s1,8(sp)
    80002058:	6902                	ld	s2,0(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret
      p->start_last_runnable = ticks;
    8000205e:	00007797          	auipc	a5,0x7
    80002062:	ff27a783          	lw	a5,-14(a5) # 80009050 <ticks>
    80002066:	c8bc                	sw	a5,80(s1)
    80002068:	bfd1                	j	8000203c <make_acquired_process_running+0x40>

000000008000206a <scheduler_sjf>:
void scheduler_sjf(void){
    8000206a:	711d                	addi	sp,sp,-96
    8000206c:	ec86                	sd	ra,88(sp)
    8000206e:	e8a2                	sd	s0,80(sp)
    80002070:	e4a6                	sd	s1,72(sp)
    80002072:	e0ca                	sd	s2,64(sp)
    80002074:	fc4e                	sd	s3,56(sp)
    80002076:	f852                	sd	s4,48(sp)
    80002078:	f456                	sd	s5,40(sp)
    8000207a:	f05a                	sd	s6,32(sp)
    8000207c:	ec5e                	sd	s7,24(sp)
    8000207e:	e862                	sd	s8,16(sp)
    80002080:	e466                	sd	s9,8(sp)
    80002082:	e06a                	sd	s10,0(sp)
    80002084:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002086:	8792                	mv	a5,tp
  int id = r_tp();
    80002088:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    8000208a:	079e                	slli	a5,a5,0x7
    8000208c:	0000f717          	auipc	a4,0xf
    80002090:	26470713          	addi	a4,a4,612 # 800112f0 <cpus>
    80002094:	00f70d33          	add	s10,a4,a5
  c->proc = 0;
    80002098:	0000f717          	auipc	a4,0xf
    8000209c:	22870713          	addi	a4,a4,552 # 800112c0 <pid_lock>
    800020a0:	97ba                	add	a5,a5,a4
    800020a2:	0207b823          	sd	zero,48(a5)
      if(ticks >= pause_ticks){ // check if pause signal was called
    800020a6:	00007917          	auipc	s2,0x7
    800020aa:	faa90913          	addi	s2,s2,-86 # 80009050 <ticks>
    800020ae:	00007a17          	auipc	s4,0x7
    800020b2:	f96a0a13          	addi	s4,s4,-106 # 80009044 <pause_ticks>
        if(curr->state == RUNNABLE) {
    800020b6:	4a8d                	li	s5,3
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800020b8:	00016997          	auipc	s3,0x16
    800020bc:	83898993          	addi	s3,s3,-1992 # 800178f0 <tickslock>
    p = NULL;
    800020c0:	4b81                	li	s7,0
        p->mean_ticks = ((SECONDS_TO_TICKS - RATE) * p->mean_ticks + p->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    800020c2:	4c29                	li	s8,10
    800020c4:	a0a1                	j	8000210c <scheduler_sjf+0xa2>
    800020c6:	8b26                	mv	s6,s1
        release(&curr->lock);
    800020c8:	8526                	mv	a0,s1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	bce080e7          	jalr	-1074(ra) # 80000c98 <release>
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800020d2:	18848493          	addi	s1,s1,392
    800020d6:	03348963          	beq	s1,s3,80002108 <scheduler_sjf+0x9e>
      if(ticks >= pause_ticks){ // check if pause signal was called
    800020da:	00092703          	lw	a4,0(s2)
    800020de:	000a2783          	lw	a5,0(s4)
    800020e2:	fef768e3          	bltu	a4,a5,800020d2 <scheduler_sjf+0x68>
        acquire(&curr->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    800020f0:	4c9c                	lw	a5,24(s1)
    800020f2:	fd579be3          	bne	a5,s5,800020c8 <scheduler_sjf+0x5e>
          if(p == NULL || p->mean_ticks >= curr->mean_ticks) {
    800020f6:	fc0b08e3          	beqz	s6,800020c6 <scheduler_sjf+0x5c>
    800020fa:	034b2703          	lw	a4,52(s6)
    800020fe:	58dc                	lw	a5,52(s1)
    80002100:	fcf764e3          	bltu	a4,a5,800020c8 <scheduler_sjf+0x5e>
    80002104:	8b26                	mv	s6,s1
    80002106:	b7c9                	j	800020c8 <scheduler_sjf+0x5e>
    if(p != NULL){
    80002108:	000b1e63          	bnez	s6,80002124 <scheduler_sjf+0xba>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002110:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002114:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    80002118:	0000f497          	auipc	s1,0xf
    8000211c:	5d848493          	addi	s1,s1,1496 # 800116f0 <proc>
    p = NULL;
    80002120:	8b5e                	mv	s6,s7
    80002122:	bf65                	j	800020da <scheduler_sjf+0x70>
      acquire(&p->lock);
    80002124:	84da                	mv	s1,s6
    80002126:	855a                	mv	a0,s6
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE){
    80002130:	018b2783          	lw	a5,24(s6)
    80002134:	03579a63          	bne	a5,s5,80002168 <scheduler_sjf+0xfe>
        uint start = ticks;
    80002138:	00092c83          	lw	s9,0(s2)
        make_acquired_process_running(c, p);
    8000213c:	85da                	mv	a1,s6
    8000213e:	856a                	mv	a0,s10
    80002140:	00000097          	auipc	ra,0x0
    80002144:	ebc080e7          	jalr	-324(ra) # 80001ffc <make_acquired_process_running>
        p->last_ticks = ticks - start;
    80002148:	00092703          	lw	a4,0(s2)
    8000214c:	4197073b          	subw	a4,a4,s9
    80002150:	02eb2c23          	sw	a4,56(s6)
        p->mean_ticks = ((SECONDS_TO_TICKS - RATE) * p->mean_ticks + p->last_ticks * (RATE)) / SECONDS_TO_TICKS;
    80002154:	034b2783          	lw	a5,52(s6)
    80002158:	9f3d                	addw	a4,a4,a5
    8000215a:	0027179b          	slliw	a5,a4,0x2
    8000215e:	9fb9                	addw	a5,a5,a4
    80002160:	0387d7bb          	divuw	a5,a5,s8
    80002164:	02fb2a23          	sw	a5,52(s6)
      release(&p->lock);
    80002168:	8526                	mv	a0,s1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	b2e080e7          	jalr	-1234(ra) # 80000c98 <release>
    80002172:	bf69                	j	8000210c <scheduler_sjf+0xa2>

0000000080002174 <scheduler>:
{
    80002174:	1141                	addi	sp,sp,-16
    80002176:	e406                	sd	ra,8(sp)
    80002178:	e022                	sd	s0,0(sp)
    8000217a:	0800                	addi	s0,sp,16
    printf("SJF scheduler mode\n");
    8000217c:	00006517          	auipc	a0,0x6
    80002180:	09c50513          	addi	a0,a0,156 # 80008218 <digits+0x1d8>
    80002184:	ffffe097          	auipc	ra,0xffffe
    80002188:	404080e7          	jalr	1028(ra) # 80000588 <printf>
    scheduler_sjf();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	ede080e7          	jalr	-290(ra) # 8000206a <scheduler_sjf>

0000000080002194 <scheduler_fcfs>:
scheduler_fcfs(void) {
    80002194:	715d                	addi	sp,sp,-80
    80002196:	e486                	sd	ra,72(sp)
    80002198:	e0a2                	sd	s0,64(sp)
    8000219a:	fc26                	sd	s1,56(sp)
    8000219c:	f84a                	sd	s2,48(sp)
    8000219e:	f44e                	sd	s3,40(sp)
    800021a0:	f052                	sd	s4,32(sp)
    800021a2:	ec56                	sd	s5,24(sp)
    800021a4:	e85a                	sd	s6,16(sp)
    800021a6:	e45e                	sd	s7,8(sp)
    800021a8:	e062                	sd	s8,0(sp)
    800021aa:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ac:	8792                	mv	a5,tp
  int id = r_tp();
    800021ae:	2781                	sext.w	a5,a5
  struct cpu *c = &cpus[id];
    800021b0:	079e                	slli	a5,a5,0x7
    800021b2:	0000f717          	auipc	a4,0xf
    800021b6:	13e70713          	addi	a4,a4,318 # 800112f0 <cpus>
    800021ba:	00f70c33          	add	s8,a4,a5
  c->proc = 0;
    800021be:	0000f717          	auipc	a4,0xf
    800021c2:	10270713          	addi	a4,a4,258 # 800112c0 <pid_lock>
    800021c6:	97ba                	add	a5,a5,a4
    800021c8:	0207b823          	sd	zero,48(a5)
      if(ticks >= pause_ticks){ // check if pause signal was called
    800021cc:	00007a17          	auipc	s4,0x7
    800021d0:	e84a0a13          	addi	s4,s4,-380 # 80009050 <ticks>
    800021d4:	00007997          	auipc	s3,0x7
    800021d8:	e7098993          	addi	s3,s3,-400 # 80009044 <pause_ticks>
        if(curr->state == RUNNABLE) {
    800021dc:	4a8d                	li	s5,3
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800021de:	00015917          	auipc	s2,0x15
    800021e2:	71290913          	addi	s2,s2,1810 # 800178f0 <tickslock>
    p = NULL;
    800021e6:	4b81                	li	s7,0
    800021e8:	a0a1                	j	80002230 <scheduler_fcfs+0x9c>
    800021ea:	8b26                	mv	s6,s1
        release(&curr->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    800021f6:	18848493          	addi	s1,s1,392
    800021fa:	03248963          	beq	s1,s2,8000222c <scheduler_fcfs+0x98>
      if(ticks >= pause_ticks){ // check if pause signal was called
    800021fe:	000a2703          	lw	a4,0(s4)
    80002202:	0009a783          	lw	a5,0(s3)
    80002206:	fef768e3          	bltu	a4,a5,800021f6 <scheduler_fcfs+0x62>
        acquire(&curr->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9d8080e7          	jalr	-1576(ra) # 80000be4 <acquire>
        if(curr->state == RUNNABLE) {
    80002214:	4c9c                	lw	a5,24(s1)
    80002216:	fd579be3          	bne	a5,s5,800021ec <scheduler_fcfs+0x58>
          if(p == NULL || p->last_runnable_time > curr->last_runnable_time) {
    8000221a:	fc0b08e3          	beqz	s6,800021ea <scheduler_fcfs+0x56>
    8000221e:	03cb2703          	lw	a4,60(s6)
    80002222:	5cdc                	lw	a5,60(s1)
    80002224:	fce7f4e3          	bgeu	a5,a4,800021ec <scheduler_fcfs+0x58>
    80002228:	8b26                	mv	s6,s1
    8000222a:	b7c9                	j	800021ec <scheduler_fcfs+0x58>
    if(p != NULL){
    8000222c:	000b1e63          	bnez	s6,80002248 <scheduler_fcfs+0xb4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002230:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002234:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002238:	10079073          	csrw	sstatus,a5
    for(curr = proc; curr < &proc[NPROC]; curr++) {
    8000223c:	0000f497          	auipc	s1,0xf
    80002240:	4b448493          	addi	s1,s1,1204 # 800116f0 <proc>
    p = NULL;
    80002244:	8b5e                	mv	s6,s7
    80002246:	bf65                	j	800021fe <scheduler_fcfs+0x6a>
      acquire(&p->lock);
    80002248:	84da                	mv	s1,s6
    8000224a:	855a                	mv	a0,s6
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	998080e7          	jalr	-1640(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE){
    80002254:	018b2783          	lw	a5,24(s6)
    80002258:	01579863          	bne	a5,s5,80002268 <scheduler_fcfs+0xd4>
        make_acquired_process_running(c, p);
    8000225c:	85da                	mv	a1,s6
    8000225e:	8562                	mv	a0,s8
    80002260:	00000097          	auipc	ra,0x0
    80002264:	d9c080e7          	jalr	-612(ra) # 80001ffc <make_acquired_process_running>
      release(&p->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
    80002272:	bf7d                	j	80002230 <scheduler_fcfs+0x9c>

0000000080002274 <sched>:
{
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	752080e7          	jalr	1874(ra) # 800019d4 <myproc>
    8000228a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	8de080e7          	jalr	-1826(ra) # 80000b6a <holding>
    80002294:	c93d                	beqz	a0,8000230a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002296:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002298:	2781                	sext.w	a5,a5
    8000229a:	079e                	slli	a5,a5,0x7
    8000229c:	0000f717          	auipc	a4,0xf
    800022a0:	02470713          	addi	a4,a4,36 # 800112c0 <pid_lock>
    800022a4:	97ba                	add	a5,a5,a4
    800022a6:	0a87a703          	lw	a4,168(a5)
    800022aa:	4785                	li	a5,1
    800022ac:	06f71763          	bne	a4,a5,8000231a <sched+0xa6>
  if(p->state == RUNNING)
    800022b0:	4c98                	lw	a4,24(s1)
    800022b2:	4791                	li	a5,4
    800022b4:	06f70b63          	beq	a4,a5,8000232a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022bc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022be:	efb5                	bnez	a5,8000233a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022c2:	0000f917          	auipc	s2,0xf
    800022c6:	ffe90913          	addi	s2,s2,-2 # 800112c0 <pid_lock>
    800022ca:	2781                	sext.w	a5,a5
    800022cc:	079e                	slli	a5,a5,0x7
    800022ce:	97ca                	add	a5,a5,s2
    800022d0:	0ac7a983          	lw	s3,172(a5)
    800022d4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d6:	2781                	sext.w	a5,a5
    800022d8:	079e                	slli	a5,a5,0x7
    800022da:	0000f597          	auipc	a1,0xf
    800022de:	01e58593          	addi	a1,a1,30 # 800112f8 <cpus+0x8>
    800022e2:	95be                	add	a1,a1,a5
    800022e4:	08048513          	addi	a0,s1,128
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	7aa080e7          	jalr	1962(ra) # 80002a92 <swtch>
    800022f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022f2:	2781                	sext.w	a5,a5
    800022f4:	079e                	slli	a5,a5,0x7
    800022f6:	97ca                	add	a5,a5,s2
    800022f8:	0b37a623          	sw	s3,172(a5)
}
    800022fc:	70a2                	ld	ra,40(sp)
    800022fe:	7402                	ld	s0,32(sp)
    80002300:	64e2                	ld	s1,24(sp)
    80002302:	6942                	ld	s2,16(sp)
    80002304:	69a2                	ld	s3,8(sp)
    80002306:	6145                	addi	sp,sp,48
    80002308:	8082                	ret
    panic("sched p->lock");
    8000230a:	00006517          	auipc	a0,0x6
    8000230e:	f2650513          	addi	a0,a0,-218 # 80008230 <digits+0x1f0>
    80002312:	ffffe097          	auipc	ra,0xffffe
    80002316:	22c080e7          	jalr	556(ra) # 8000053e <panic>
    panic("sched locks");
    8000231a:	00006517          	auipc	a0,0x6
    8000231e:	f2650513          	addi	a0,a0,-218 # 80008240 <digits+0x200>
    80002322:	ffffe097          	auipc	ra,0xffffe
    80002326:	21c080e7          	jalr	540(ra) # 8000053e <panic>
    panic("sched running");
    8000232a:	00006517          	auipc	a0,0x6
    8000232e:	f2650513          	addi	a0,a0,-218 # 80008250 <digits+0x210>
    80002332:	ffffe097          	auipc	ra,0xffffe
    80002336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	f2650513          	addi	a0,a0,-218 # 80008260 <digits+0x220>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>

000000008000234a <yield>:
{
    8000234a:	1101                	addi	sp,sp,-32
    8000234c:	ec06                	sd	ra,24(sp)
    8000234e:	e822                	sd	s0,16(sp)
    80002350:	e426                	sd	s1,8(sp)
    80002352:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	680080e7          	jalr	1664(ra) # 800019d4 <myproc>
    8000235c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	886080e7          	jalr	-1914(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002366:	478d                	li	a5,3
    80002368:	cc9c                	sw	a5,24(s1)
  sched();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	f0a080e7          	jalr	-246(ra) # 80002274 <sched>
  release(&p->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
}
    8000237c:	60e2                	ld	ra,24(sp)
    8000237e:	6442                	ld	s0,16(sp)
    80002380:	64a2                	ld	s1,8(sp)
    80002382:	6105                	addi	sp,sp,32
    80002384:	8082                	ret

0000000080002386 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002386:	7179                	addi	sp,sp,-48
    80002388:	f406                	sd	ra,40(sp)
    8000238a:	f022                	sd	s0,32(sp)
    8000238c:	ec26                	sd	s1,24(sp)
    8000238e:	e84a                	sd	s2,16(sp)
    80002390:	e44e                	sd	s3,8(sp)
    80002392:	1800                	addi	s0,sp,48
    80002394:	89aa                	mv	s3,a0
    80002396:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	63c080e7          	jalr	1596(ra) # 800019d4 <myproc>
    800023a0:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	842080e7          	jalr	-1982(ra) # 80000be4 <acquire>
  release(lk);
    800023aa:	854a                	mv	a0,s2
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800023b4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023b8:	4789                	li	a5,2
    800023ba:	cc9c                	sw	a5,24(s1)

  //update start sleep time
  p->start_last_sleeping = ticks;
    800023bc:	00007797          	auipc	a5,0x7
    800023c0:	c947a783          	lw	a5,-876(a5) # 80009050 <ticks>
    800023c4:	c4fc                	sw	a5,76(s1)

  sched();
    800023c6:	00000097          	auipc	ra,0x0
    800023ca:	eae080e7          	jalr	-338(ra) # 80002274 <sched>

  // Tidy up.
  p->chan = 0;
    800023ce:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	8c4080e7          	jalr	-1852(ra) # 80000c98 <release>
  acquire(lk);
    800023dc:	854a                	mv	a0,s2
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
}
    800023e6:	70a2                	ld	ra,40(sp)
    800023e8:	7402                	ld	s0,32(sp)
    800023ea:	64e2                	ld	s1,24(sp)
    800023ec:	6942                	ld	s2,16(sp)
    800023ee:	69a2                	ld	s3,8(sp)
    800023f0:	6145                	addi	sp,sp,48
    800023f2:	8082                	ret

00000000800023f4 <wait>:
{
    800023f4:	715d                	addi	sp,sp,-80
    800023f6:	e486                	sd	ra,72(sp)
    800023f8:	e0a2                	sd	s0,64(sp)
    800023fa:	fc26                	sd	s1,56(sp)
    800023fc:	f84a                	sd	s2,48(sp)
    800023fe:	f44e                	sd	s3,40(sp)
    80002400:	f052                	sd	s4,32(sp)
    80002402:	ec56                	sd	s5,24(sp)
    80002404:	e85a                	sd	s6,16(sp)
    80002406:	e45e                	sd	s7,8(sp)
    80002408:	e062                	sd	s8,0(sp)
    8000240a:	0880                	addi	s0,sp,80
    8000240c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	5c6080e7          	jalr	1478(ra) # 800019d4 <myproc>
    80002416:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002418:	0000f517          	auipc	a0,0xf
    8000241c:	ec050513          	addi	a0,a0,-320 # 800112d8 <wait_lock>
    80002420:	ffffe097          	auipc	ra,0xffffe
    80002424:	7c4080e7          	jalr	1988(ra) # 80000be4 <acquire>
    havekids = 0;
    80002428:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000242a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000242c:	00015997          	auipc	s3,0x15
    80002430:	4c498993          	addi	s3,s3,1220 # 800178f0 <tickslock>
        havekids = 1;
    80002434:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002436:	0000fc17          	auipc	s8,0xf
    8000243a:	ea2c0c13          	addi	s8,s8,-350 # 800112d8 <wait_lock>
    havekids = 0;
    8000243e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002440:	0000f497          	auipc	s1,0xf
    80002444:	2b048493          	addi	s1,s1,688 # 800116f0 <proc>
    80002448:	a0bd                	j	800024b6 <wait+0xc2>
          pid = np->pid;
    8000244a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000244e:	000b0e63          	beqz	s6,8000246a <wait+0x76>
    80002452:	4691                	li	a3,4
    80002454:	02c48613          	addi	a2,s1,44
    80002458:	85da                	mv	a1,s6
    8000245a:	07093503          	ld	a0,112(s2)
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	21c080e7          	jalr	540(ra) # 8000167a <copyout>
    80002466:	02054563          	bltz	a0,80002490 <wait+0x9c>
          freeproc(np);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	71a080e7          	jalr	1818(ra) # 80001b86 <freeproc>
          release(&np->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	822080e7          	jalr	-2014(ra) # 80000c98 <release>
          release(&wait_lock);
    8000247e:	0000f517          	auipc	a0,0xf
    80002482:	e5a50513          	addi	a0,a0,-422 # 800112d8 <wait_lock>
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
          return pid;
    8000248e:	a09d                	j	800024f4 <wait+0x100>
            release(&np->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
            release(&wait_lock);
    8000249a:	0000f517          	auipc	a0,0xf
    8000249e:	e3e50513          	addi	a0,a0,-450 # 800112d8 <wait_lock>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	7f6080e7          	jalr	2038(ra) # 80000c98 <release>
            return -1;
    800024aa:	59fd                	li	s3,-1
    800024ac:	a0a1                	j	800024f4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800024ae:	18848493          	addi	s1,s1,392
    800024b2:	03348463          	beq	s1,s3,800024da <wait+0xe6>
      if(np->parent == p){
    800024b6:	6cbc                	ld	a5,88(s1)
    800024b8:	ff279be3          	bne	a5,s2,800024ae <wait+0xba>
        acquire(&np->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	726080e7          	jalr	1830(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800024c6:	4c9c                	lw	a5,24(s1)
    800024c8:	f94781e3          	beq	a5,s4,8000244a <wait+0x56>
        release(&np->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7ca080e7          	jalr	1994(ra) # 80000c98 <release>
        havekids = 1;
    800024d6:	8756                	mv	a4,s5
    800024d8:	bfd9                	j	800024ae <wait+0xba>
    if(!havekids || p->killed){
    800024da:	c701                	beqz	a4,800024e2 <wait+0xee>
    800024dc:	02892783          	lw	a5,40(s2)
    800024e0:	c79d                	beqz	a5,8000250e <wait+0x11a>
      release(&wait_lock);
    800024e2:	0000f517          	auipc	a0,0xf
    800024e6:	df650513          	addi	a0,a0,-522 # 800112d8 <wait_lock>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7ae080e7          	jalr	1966(ra) # 80000c98 <release>
      return -1;
    800024f2:	59fd                	li	s3,-1
}
    800024f4:	854e                	mv	a0,s3
    800024f6:	60a6                	ld	ra,72(sp)
    800024f8:	6406                	ld	s0,64(sp)
    800024fa:	74e2                	ld	s1,56(sp)
    800024fc:	7942                	ld	s2,48(sp)
    800024fe:	79a2                	ld	s3,40(sp)
    80002500:	7a02                	ld	s4,32(sp)
    80002502:	6ae2                	ld	s5,24(sp)
    80002504:	6b42                	ld	s6,16(sp)
    80002506:	6ba2                	ld	s7,8(sp)
    80002508:	6c02                	ld	s8,0(sp)
    8000250a:	6161                	addi	sp,sp,80
    8000250c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000250e:	85e2                	mv	a1,s8
    80002510:	854a                	mv	a0,s2
    80002512:	00000097          	auipc	ra,0x0
    80002516:	e74080e7          	jalr	-396(ra) # 80002386 <sleep>
    havekids = 0;
    8000251a:	b715                	j	8000243e <wait+0x4a>

000000008000251c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000251c:	7139                	addi	sp,sp,-64
    8000251e:	fc06                	sd	ra,56(sp)
    80002520:	f822                	sd	s0,48(sp)
    80002522:	f426                	sd	s1,40(sp)
    80002524:	f04a                	sd	s2,32(sp)
    80002526:	ec4e                	sd	s3,24(sp)
    80002528:	e852                	sd	s4,16(sp)
    8000252a:	e456                	sd	s5,8(sp)
    8000252c:	e05a                	sd	s6,0(sp)
    8000252e:	0080                	addi	s0,sp,64
    80002530:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002532:	0000f497          	auipc	s1,0xf
    80002536:	1be48493          	addi	s1,s1,446 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000253a:	4989                	li	s3,2
        p->sleeping_time += ticks - p->start_last_sleeping;
    8000253c:	00007b17          	auipc	s6,0x7
    80002540:	b14b0b13          	addi	s6,s6,-1260 # 80009050 <ticks>
        p->start_last_runnable = ticks;
        p->state = RUNNABLE;
    80002544:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002546:	00015917          	auipc	s2,0x15
    8000254a:	3aa90913          	addi	s2,s2,938 # 800178f0 <tickslock>
    8000254e:	a025                	j	80002576 <wakeup+0x5a>
        p->sleeping_time += ticks - p->start_last_sleeping;
    80002550:	000b2703          	lw	a4,0(s6)
    80002554:	40bc                	lw	a5,64(s1)
    80002556:	9fb9                	addw	a5,a5,a4
    80002558:	44f4                	lw	a3,76(s1)
    8000255a:	9f95                	subw	a5,a5,a3
    8000255c:	c0bc                	sw	a5,64(s1)
        p->start_last_runnable = ticks;
    8000255e:	c8b8                	sw	a4,80(s1)
        p->state = RUNNABLE;
    80002560:	0154ac23          	sw	s5,24(s1)
        update_last_runnable_time(p);
      }
      release(&p->lock);
    80002564:	8526                	mv	a0,s1
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	732080e7          	jalr	1842(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000256e:	18848493          	addi	s1,s1,392
    80002572:	03248463          	beq	s1,s2,8000259a <wakeup+0x7e>
    if(p != myproc()){
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	45e080e7          	jalr	1118(ra) # 800019d4 <myproc>
    8000257e:	fea488e3          	beq	s1,a0,8000256e <wakeup+0x52>
      acquire(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000258c:	4c9c                	lw	a5,24(s1)
    8000258e:	fd379be3          	bne	a5,s3,80002564 <wakeup+0x48>
    80002592:	709c                	ld	a5,32(s1)
    80002594:	fd4798e3          	bne	a5,s4,80002564 <wakeup+0x48>
    80002598:	bf65                	j	80002550 <wakeup+0x34>
    }
  }
}
    8000259a:	70e2                	ld	ra,56(sp)
    8000259c:	7442                	ld	s0,48(sp)
    8000259e:	74a2                	ld	s1,40(sp)
    800025a0:	7902                	ld	s2,32(sp)
    800025a2:	69e2                	ld	s3,24(sp)
    800025a4:	6a42                	ld	s4,16(sp)
    800025a6:	6aa2                	ld	s5,8(sp)
    800025a8:	6b02                	ld	s6,0(sp)
    800025aa:	6121                	addi	sp,sp,64
    800025ac:	8082                	ret

00000000800025ae <reparent>:
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	e052                	sd	s4,0(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	13048493          	addi	s1,s1,304 # 800116f0 <proc>
      pp->parent = initproc;
    800025c8:	00007a17          	auipc	s4,0x7
    800025cc:	a80a0a13          	addi	s4,s4,-1408 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d0:	00015997          	auipc	s3,0x15
    800025d4:	32098993          	addi	s3,s3,800 # 800178f0 <tickslock>
    800025d8:	a029                	j	800025e2 <reparent+0x34>
    800025da:	18848493          	addi	s1,s1,392
    800025de:	01348d63          	beq	s1,s3,800025f8 <reparent+0x4a>
    if(pp->parent == p){
    800025e2:	6cbc                	ld	a5,88(s1)
    800025e4:	ff279be3          	bne	a5,s2,800025da <reparent+0x2c>
      pp->parent = initproc;
    800025e8:	000a3503          	ld	a0,0(s4)
    800025ec:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	f2e080e7          	jalr	-210(ra) # 8000251c <wakeup>
    800025f6:	b7d5                	j	800025da <reparent+0x2c>
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6a02                	ld	s4,0(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret

0000000080002608 <exit>:
{
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	e052                	sd	s4,0(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	3ba080e7          	jalr	954(ra) # 800019d4 <myproc>
    80002622:	892a                	mv	s2,a0
  sleeping_processes_mean = get_mean(sleeping_processes_mean, p->sleeping_time, number_processes);
    80002624:	00007517          	auipc	a0,0x7
    80002628:	a0450513          	addi	a0,a0,-1532 # 80009028 <number_processes>
    8000262c:	4110                	lw	a2,0(a0)
  return ( last_mean * num_procs + curr_time) / (num_procs + 1);
    8000262e:	0016069b          	addiw	a3,a2,1
  sleeping_processes_mean = get_mean(sleeping_processes_mean, p->sleeping_time, number_processes);
    80002632:	00007797          	auipc	a5,0x7
    80002636:	a0e78793          	addi	a5,a5,-1522 # 80009040 <sleeping_processes_mean>
  return ( last_mean * num_procs + curr_time) / (num_procs + 1);
    8000263a:	4398                	lw	a4,0(a5)
    8000263c:	02c7073b          	mulw	a4,a4,a2
    80002640:	04092583          	lw	a1,64(s2)
    80002644:	9f2d                	addw	a4,a4,a1
    80002646:	02d7473b          	divw	a4,a4,a3
  sleeping_processes_mean = get_mean(sleeping_processes_mean, p->sleeping_time, number_processes);
    8000264a:	c398                	sw	a4,0(a5)
  running_processes_mean = get_mean(running_processes_mean, p->running_time, number_processes);
    8000264c:	04892583          	lw	a1,72(s2)
    80002650:	00007797          	auipc	a5,0x7
    80002654:	9ec78793          	addi	a5,a5,-1556 # 8000903c <running_processes_mean>
  return ( last_mean * num_procs + curr_time) / (num_procs + 1);
    80002658:	4398                	lw	a4,0(a5)
    8000265a:	02c7073b          	mulw	a4,a4,a2
    8000265e:	9f2d                	addw	a4,a4,a1
    80002660:	02d7473b          	divw	a4,a4,a3
  running_processes_mean = get_mean(running_processes_mean, p->running_time, number_processes);
    80002664:	c398                	sw	a4,0(a5)
  runnable_processes_mean = get_mean(runnable_processes_mean, p->runnable_time, number_processes);
    80002666:	00007717          	auipc	a4,0x7
    8000266a:	9d270713          	addi	a4,a4,-1582 # 80009038 <runnable_processes_mean>
  return ( last_mean * num_procs + curr_time) / (num_procs + 1);
    8000266e:	431c                	lw	a5,0(a4)
    80002670:	02c787bb          	mulw	a5,a5,a2
    80002674:	04492603          	lw	a2,68(s2)
    80002678:	9fb1                	addw	a5,a5,a2
    8000267a:	02d7c7bb          	divw	a5,a5,a3
  runnable_processes_mean = get_mean(runnable_processes_mean, p->runnable_time, number_processes);
    8000267e:	c31c                	sw	a5,0(a4)
  number_processes++;
    80002680:	c114                	sw	a3,0(a0)
  program_time += p->running_time;
    80002682:	00007697          	auipc	a3,0x7
    80002686:	9b268693          	addi	a3,a3,-1614 # 80009034 <program_time>
    8000268a:	429c                	lw	a5,0(a3)
    8000268c:	00b7873b          	addw	a4,a5,a1
    80002690:	c298                	sw	a4,0(a3)
  cpu_utilization = 100*program_time / (ticks-start_time);
    80002692:	06400793          	li	a5,100
    80002696:	02e787bb          	mulw	a5,a5,a4
    8000269a:	00007717          	auipc	a4,0x7
    8000269e:	9b672703          	lw	a4,-1610(a4) # 80009050 <ticks>
    800026a2:	00007697          	auipc	a3,0x7
    800026a6:	98a6a683          	lw	a3,-1654(a3) # 8000902c <start_time>
    800026aa:	9f15                	subw	a4,a4,a3
    800026ac:	02e7d7bb          	divuw	a5,a5,a4
    800026b0:	00007717          	auipc	a4,0x7
    800026b4:	98f72023          	sw	a5,-1664(a4) # 80009030 <cpu_utilization>
  if(p == initproc)
    800026b8:	00007797          	auipc	a5,0x7
    800026bc:	9907b783          	ld	a5,-1648(a5) # 80009048 <initproc>
    800026c0:	0f090493          	addi	s1,s2,240
    800026c4:	17090993          	addi	s3,s2,368
    800026c8:	03279363          	bne	a5,s2,800026ee <exit+0xe6>
    panic("init exiting");
    800026cc:	00006517          	auipc	a0,0x6
    800026d0:	bac50513          	addi	a0,a0,-1108 # 80008278 <digits+0x238>
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
      fileclose(f);
    800026dc:	00002097          	auipc	ra,0x2
    800026e0:	2d6080e7          	jalr	726(ra) # 800049b2 <fileclose>
      p->ofile[fd] = 0;
    800026e4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026e8:	04a1                	addi	s1,s1,8
    800026ea:	01348563          	beq	s1,s3,800026f4 <exit+0xec>
    if(p->ofile[fd]){
    800026ee:	6088                	ld	a0,0(s1)
    800026f0:	f575                	bnez	a0,800026dc <exit+0xd4>
    800026f2:	bfdd                	j	800026e8 <exit+0xe0>
  begin_op();
    800026f4:	00002097          	auipc	ra,0x2
    800026f8:	df2080e7          	jalr	-526(ra) # 800044e6 <begin_op>
  iput(p->cwd);
    800026fc:	17093503          	ld	a0,368(s2)
    80002700:	00001097          	auipc	ra,0x1
    80002704:	5ce080e7          	jalr	1486(ra) # 80003cce <iput>
  end_op();
    80002708:	00002097          	auipc	ra,0x2
    8000270c:	e5e080e7          	jalr	-418(ra) # 80004566 <end_op>
  p->cwd = 0;
    80002710:	16093823          	sd	zero,368(s2)
  acquire(&wait_lock);
    80002714:	0000f497          	auipc	s1,0xf
    80002718:	bc448493          	addi	s1,s1,-1084 # 800112d8 <wait_lock>
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	4c6080e7          	jalr	1222(ra) # 80000be4 <acquire>
  reparent(p);
    80002726:	854a                	mv	a0,s2
    80002728:	00000097          	auipc	ra,0x0
    8000272c:	e86080e7          	jalr	-378(ra) # 800025ae <reparent>
  wakeup(p->parent);
    80002730:	05893503          	ld	a0,88(s2)
    80002734:	00000097          	auipc	ra,0x0
    80002738:	de8080e7          	jalr	-536(ra) # 8000251c <wakeup>
  acquire(&p->lock);
    8000273c:	854a                	mv	a0,s2
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002746:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000274a:	4795                	li	a5,5
    8000274c:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
  sched();
    8000275a:	00000097          	auipc	ra,0x0
    8000275e:	b1a080e7          	jalr	-1254(ra) # 80002274 <sched>
  panic("zombie exit");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	b2650513          	addi	a0,a0,-1242 # 80008288 <digits+0x248>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>

0000000080002772 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002772:	7179                	addi	sp,sp,-48
    80002774:	f406                	sd	ra,40(sp)
    80002776:	f022                	sd	s0,32(sp)
    80002778:	ec26                	sd	s1,24(sp)
    8000277a:	e84a                	sd	s2,16(sp)
    8000277c:	e44e                	sd	s3,8(sp)
    8000277e:	1800                	addi	s0,sp,48
    80002780:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002782:	0000f497          	auipc	s1,0xf
    80002786:	f6e48493          	addi	s1,s1,-146 # 800116f0 <proc>
    8000278a:	00015997          	auipc	s3,0x15
    8000278e:	16698993          	addi	s3,s3,358 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	450080e7          	jalr	1104(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000279c:	589c                	lw	a5,48(s1)
    8000279e:	01278d63          	beq	a5,s2,800027b8 <kill+0x46>
        update_last_runnable_time(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4f4080e7          	jalr	1268(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ac:	18848493          	addi	s1,s1,392
    800027b0:	ff3491e3          	bne	s1,s3,80002792 <kill+0x20>
  }
  return -1;
    800027b4:	557d                	li	a0,-1
    800027b6:	a829                	j	800027d0 <kill+0x5e>
      p->killed = 1;
    800027b8:	4785                	li	a5,1
    800027ba:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027bc:	4c98                	lw	a4,24(s1)
    800027be:	4789                	li	a5,2
    800027c0:	00f70f63          	beq	a4,a5,800027de <kill+0x6c>
      release(&p->lock);
    800027c4:	8526                	mv	a0,s1
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	4d2080e7          	jalr	1234(ra) # 80000c98 <release>
      return 0;
    800027ce:	4501                	li	a0,0
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6145                	addi	sp,sp,48
    800027dc:	8082                	ret
        p->sleeping_time += ticks - p->start_last_sleeping;
    800027de:	00007717          	auipc	a4,0x7
    800027e2:	87272703          	lw	a4,-1934(a4) # 80009050 <ticks>
    800027e6:	40bc                	lw	a5,64(s1)
    800027e8:	9fb9                	addw	a5,a5,a4
    800027ea:	44f4                	lw	a3,76(s1)
    800027ec:	9f95                	subw	a5,a5,a3
    800027ee:	c0bc                	sw	a5,64(s1)
        p->start_last_runnable = ticks;
    800027f0:	c8b8                	sw	a4,80(s1)
        p->state = RUNNABLE;
    800027f2:	478d                	li	a5,3
    800027f4:	cc9c                	sw	a5,24(s1)
        update_last_runnable_time(p);
    800027f6:	b7f9                	j	800027c4 <kill+0x52>

00000000800027f8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027f8:	7179                	addi	sp,sp,-48
    800027fa:	f406                	sd	ra,40(sp)
    800027fc:	f022                	sd	s0,32(sp)
    800027fe:	ec26                	sd	s1,24(sp)
    80002800:	e84a                	sd	s2,16(sp)
    80002802:	e44e                	sd	s3,8(sp)
    80002804:	e052                	sd	s4,0(sp)
    80002806:	1800                	addi	s0,sp,48
    80002808:	84aa                	mv	s1,a0
    8000280a:	892e                	mv	s2,a1
    8000280c:	89b2                	mv	s3,a2
    8000280e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	1c4080e7          	jalr	452(ra) # 800019d4 <myproc>
  if(user_dst){
    80002818:	c08d                	beqz	s1,8000283a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000281a:	86d2                	mv	a3,s4
    8000281c:	864e                	mv	a2,s3
    8000281e:	85ca                	mv	a1,s2
    80002820:	7928                	ld	a0,112(a0)
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	e58080e7          	jalr	-424(ra) # 8000167a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000282a:	70a2                	ld	ra,40(sp)
    8000282c:	7402                	ld	s0,32(sp)
    8000282e:	64e2                	ld	s1,24(sp)
    80002830:	6942                	ld	s2,16(sp)
    80002832:	69a2                	ld	s3,8(sp)
    80002834:	6a02                	ld	s4,0(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret
    memmove((char *)dst, src, len);
    8000283a:	000a061b          	sext.w	a2,s4
    8000283e:	85ce                	mv	a1,s3
    80002840:	854a                	mv	a0,s2
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	4fe080e7          	jalr	1278(ra) # 80000d40 <memmove>
    return 0;
    8000284a:	8526                	mv	a0,s1
    8000284c:	bff9                	j	8000282a <either_copyout+0x32>

000000008000284e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000284e:	7179                	addi	sp,sp,-48
    80002850:	f406                	sd	ra,40(sp)
    80002852:	f022                	sd	s0,32(sp)
    80002854:	ec26                	sd	s1,24(sp)
    80002856:	e84a                	sd	s2,16(sp)
    80002858:	e44e                	sd	s3,8(sp)
    8000285a:	e052                	sd	s4,0(sp)
    8000285c:	1800                	addi	s0,sp,48
    8000285e:	892a                	mv	s2,a0
    80002860:	84ae                	mv	s1,a1
    80002862:	89b2                	mv	s3,a2
    80002864:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	16e080e7          	jalr	366(ra) # 800019d4 <myproc>
  if(user_src){
    8000286e:	c08d                	beqz	s1,80002890 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002870:	86d2                	mv	a3,s4
    80002872:	864e                	mv	a2,s3
    80002874:	85ca                	mv	a1,s2
    80002876:	7928                	ld	a0,112(a0)
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	e8e080e7          	jalr	-370(ra) # 80001706 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002880:	70a2                	ld	ra,40(sp)
    80002882:	7402                	ld	s0,32(sp)
    80002884:	64e2                	ld	s1,24(sp)
    80002886:	6942                	ld	s2,16(sp)
    80002888:	69a2                	ld	s3,8(sp)
    8000288a:	6a02                	ld	s4,0(sp)
    8000288c:	6145                	addi	sp,sp,48
    8000288e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002890:	000a061b          	sext.w	a2,s4
    80002894:	85ce                	mv	a1,s3
    80002896:	854a                	mv	a0,s2
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	4a8080e7          	jalr	1192(ra) # 80000d40 <memmove>
    return 0;
    800028a0:	8526                	mv	a0,s1
    800028a2:	bff9                	j	80002880 <either_copyin+0x32>

00000000800028a4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028a4:	715d                	addi	sp,sp,-80
    800028a6:	e486                	sd	ra,72(sp)
    800028a8:	e0a2                	sd	s0,64(sp)
    800028aa:	fc26                	sd	s1,56(sp)
    800028ac:	f84a                	sd	s2,48(sp)
    800028ae:	f44e                	sd	s3,40(sp)
    800028b0:	f052                	sd	s4,32(sp)
    800028b2:	ec56                	sd	s5,24(sp)
    800028b4:	e85a                	sd	s6,16(sp)
    800028b6:	e45e                	sd	s7,8(sp)
    800028b8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	a6650513          	addi	a0,a0,-1434 # 80008320 <digits+0x2e0>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ca:	0000f497          	auipc	s1,0xf
    800028ce:	f9e48493          	addi	s1,s1,-98 # 80011868 <proc+0x178>
    800028d2:	00015917          	auipc	s2,0x15
    800028d6:	19690913          	addi	s2,s2,406 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028da:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028dc:	00006997          	auipc	s3,0x6
    800028e0:	9bc98993          	addi	s3,s3,-1604 # 80008298 <digits+0x258>
    printf("%d %s %s", p->pid, state, p->name);
    800028e4:	00006a97          	auipc	s5,0x6
    800028e8:	9bca8a93          	addi	s5,s5,-1604 # 800082a0 <digits+0x260>
    printf("\n");
    800028ec:	00006a17          	auipc	s4,0x6
    800028f0:	a34a0a13          	addi	s4,s4,-1484 # 80008320 <digits+0x2e0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f4:	00006b97          	auipc	s7,0x6
    800028f8:	a84b8b93          	addi	s7,s7,-1404 # 80008378 <states.1790>
    800028fc:	a00d                	j	8000291e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028fe:	eb86a583          	lw	a1,-328(a3)
    80002902:	8556                	mv	a0,s5
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c84080e7          	jalr	-892(ra) # 80000588 <printf>
    printf("\n");
    8000290c:	8552                	mv	a0,s4
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c7a080e7          	jalr	-902(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002916:	18848493          	addi	s1,s1,392
    8000291a:	03248163          	beq	s1,s2,8000293c <procdump+0x98>
    if(p->state == UNUSED)
    8000291e:	86a6                	mv	a3,s1
    80002920:	ea04a783          	lw	a5,-352(s1)
    80002924:	dbed                	beqz	a5,80002916 <procdump+0x72>
      state = "???";
    80002926:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002928:	fcfb6be3          	bltu	s6,a5,800028fe <procdump+0x5a>
    8000292c:	1782                	slli	a5,a5,0x20
    8000292e:	9381                	srli	a5,a5,0x20
    80002930:	078e                	slli	a5,a5,0x3
    80002932:	97de                	add	a5,a5,s7
    80002934:	6390                	ld	a2,0(a5)
    80002936:	f661                	bnez	a2,800028fe <procdump+0x5a>
      state = "???";
    80002938:	864e                	mv	a2,s3
    8000293a:	b7d1                	j	800028fe <procdump+0x5a>
  }
}
    8000293c:	60a6                	ld	ra,72(sp)
    8000293e:	6406                	ld	s0,64(sp)
    80002940:	74e2                	ld	s1,56(sp)
    80002942:	7942                	ld	s2,48(sp)
    80002944:	79a2                	ld	s3,40(sp)
    80002946:	7a02                	ld	s4,32(sp)
    80002948:	6ae2                	ld	s5,24(sp)
    8000294a:	6b42                	ld	s6,16(sp)
    8000294c:	6ba2                	ld	s7,8(sp)
    8000294e:	6161                	addi	sp,sp,80
    80002950:	8082                	ret

0000000080002952 <pause_system>:

// pause all user processes for the number of seconds specified by thesecond's integer parameter.
int pause_system(int seconds){
    80002952:	1141                	addi	sp,sp,-16
    80002954:	e406                	sd	ra,8(sp)
    80002956:	e022                	sd	s0,0(sp)
    80002958:	0800                	addi	s0,sp,16
  pause_ticks = ticks + seconds * SECONDS_TO_TICKS;
    8000295a:	0025179b          	slliw	a5,a0,0x2
    8000295e:	9fa9                	addw	a5,a5,a0
    80002960:	0017979b          	slliw	a5,a5,0x1
    80002964:	00006517          	auipc	a0,0x6
    80002968:	6ec52503          	lw	a0,1772(a0) # 80009050 <ticks>
    8000296c:	9fa9                	addw	a5,a5,a0
    8000296e:	00006717          	auipc	a4,0x6
    80002972:	6cf72b23          	sw	a5,1750(a4) # 80009044 <pause_ticks>
  yield();
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	9d4080e7          	jalr	-1580(ra) # 8000234a <yield>

  return 0;
}
    8000297e:	4501                	li	a0,0
    80002980:	60a2                	ld	ra,8(sp)
    80002982:	6402                	ld	s0,0(sp)
    80002984:	0141                	addi	sp,sp,16
    80002986:	8082                	ret

0000000080002988 <kill_system>:

// terminate all user processes
int 
kill_system(void) {
    80002988:	7179                	addi	sp,sp,-48
    8000298a:	f406                	sd	ra,40(sp)
    8000298c:	f022                	sd	s0,32(sp)
    8000298e:	ec26                	sd	s1,24(sp)
    80002990:	e84a                	sd	s2,16(sp)
    80002992:	e44e                	sd	s3,8(sp)
    80002994:	e052                	sd	s4,0(sp)
    80002996:	1800                	addi	s0,sp,48
  struct proc *p;
  int pid;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002998:	0000f497          	auipc	s1,0xf
    8000299c:	d5848493          	addi	s1,s1,-680 # 800116f0 <proc>
      acquire(&p->lock);
      pid = p->pid;
      release(&p->lock);
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    800029a0:	4a05                	li	s4,1
  for(p = proc; p < &proc[NPROC]; p++) {
    800029a2:	00015997          	auipc	s3,0x15
    800029a6:	f4e98993          	addi	s3,s3,-178 # 800178f0 <tickslock>
    800029aa:	a029                	j	800029b4 <kill_system+0x2c>
    800029ac:	18848493          	addi	s1,s1,392
    800029b0:	03348863          	beq	s1,s3,800029e0 <kill_system+0x58>
      acquire(&p->lock);
    800029b4:	8526                	mv	a0,s1
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	22e080e7          	jalr	558(ra) # 80000be4 <acquire>
      pid = p->pid;
    800029be:	0304a903          	lw	s2,48(s1)
      release(&p->lock);
    800029c2:	8526                	mv	a0,s1
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	2d4080e7          	jalr	724(ra) # 80000c98 <release>
      if(pid != INIT_PROC_ID && pid != SHELL_PROC_ID)
    800029cc:	fff9079b          	addiw	a5,s2,-1
    800029d0:	fcfa7ee3          	bgeu	s4,a5,800029ac <kill_system+0x24>
        kill(pid);
    800029d4:	854a                	mv	a0,s2
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	d9c080e7          	jalr	-612(ra) # 80002772 <kill>
    800029de:	b7f9                	j	800029ac <kill_system+0x24>
  }
  return 0;
}
    800029e0:	4501                	li	a0,0
    800029e2:	70a2                	ld	ra,40(sp)
    800029e4:	7402                	ld	s0,32(sp)
    800029e6:	64e2                	ld	s1,24(sp)
    800029e8:	6942                	ld	s2,16(sp)
    800029ea:	69a2                	ld	s3,8(sp)
    800029ec:	6a02                	ld	s4,0(sp)
    800029ee:	6145                	addi	sp,sp,48
    800029f0:	8082                	ret

00000000800029f2 <print_stats>:

void
print_stats(void) {
    800029f2:	1141                	addi	sp,sp,-16
    800029f4:	e406                	sd	ra,8(sp)
    800029f6:	e022                	sd	s0,0(sp)
    800029f8:	0800                	addi	s0,sp,16
    printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800029fa:	00006597          	auipc	a1,0x6
    800029fe:	6465a583          	lw	a1,1606(a1) # 80009040 <sleeping_processes_mean>
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	8ae50513          	addi	a0,a0,-1874 # 800082b0 <digits+0x270>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
    printf("runnable_processes_mean: %d\n", runnable_processes_mean);
    80002a12:	00006597          	auipc	a1,0x6
    80002a16:	6265a583          	lw	a1,1574(a1) # 80009038 <runnable_processes_mean>
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	8b650513          	addi	a0,a0,-1866 # 800082d0 <digits+0x290>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b66080e7          	jalr	-1178(ra) # 80000588 <printf>
    printf("running_processes_mean: %d\n", running_processes_mean);
    80002a2a:	00006597          	auipc	a1,0x6
    80002a2e:	6125a583          	lw	a1,1554(a1) # 8000903c <running_processes_mean>
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	8be50513          	addi	a0,a0,-1858 # 800082f0 <digits+0x2b0>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b4e080e7          	jalr	-1202(ra) # 80000588 <printf>
    printf("program_time: %d\n", program_time);
    80002a42:	00006597          	auipc	a1,0x6
    80002a46:	5f25a583          	lw	a1,1522(a1) # 80009034 <program_time>
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	8c650513          	addi	a0,a0,-1850 # 80008310 <digits+0x2d0>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	b36080e7          	jalr	-1226(ra) # 80000588 <printf>
    printf("cpu_utilization: %d%\n", cpu_utilization);
    80002a5a:	00006597          	auipc	a1,0x6
    80002a5e:	5d65a583          	lw	a1,1494(a1) # 80009030 <cpu_utilization>
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	8c650513          	addi	a0,a0,-1850 # 80008328 <digits+0x2e8>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b1e080e7          	jalr	-1250(ra) # 80000588 <printf>
    printf ("ticks : %d\n", ticks);
    80002a72:	00006597          	auipc	a1,0x6
    80002a76:	5de5a583          	lw	a1,1502(a1) # 80009050 <ticks>
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	8c650513          	addi	a0,a0,-1850 # 80008340 <digits+0x300>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b06080e7          	jalr	-1274(ra) # 80000588 <printf>
}
    80002a8a:	60a2                	ld	ra,8(sp)
    80002a8c:	6402                	ld	s0,0(sp)
    80002a8e:	0141                	addi	sp,sp,16
    80002a90:	8082                	ret

0000000080002a92 <swtch>:
    80002a92:	00153023          	sd	ra,0(a0)
    80002a96:	00253423          	sd	sp,8(a0)
    80002a9a:	e900                	sd	s0,16(a0)
    80002a9c:	ed04                	sd	s1,24(a0)
    80002a9e:	03253023          	sd	s2,32(a0)
    80002aa2:	03353423          	sd	s3,40(a0)
    80002aa6:	03453823          	sd	s4,48(a0)
    80002aaa:	03553c23          	sd	s5,56(a0)
    80002aae:	05653023          	sd	s6,64(a0)
    80002ab2:	05753423          	sd	s7,72(a0)
    80002ab6:	05853823          	sd	s8,80(a0)
    80002aba:	05953c23          	sd	s9,88(a0)
    80002abe:	07a53023          	sd	s10,96(a0)
    80002ac2:	07b53423          	sd	s11,104(a0)
    80002ac6:	0005b083          	ld	ra,0(a1)
    80002aca:	0085b103          	ld	sp,8(a1)
    80002ace:	6980                	ld	s0,16(a1)
    80002ad0:	6d84                	ld	s1,24(a1)
    80002ad2:	0205b903          	ld	s2,32(a1)
    80002ad6:	0285b983          	ld	s3,40(a1)
    80002ada:	0305ba03          	ld	s4,48(a1)
    80002ade:	0385ba83          	ld	s5,56(a1)
    80002ae2:	0405bb03          	ld	s6,64(a1)
    80002ae6:	0485bb83          	ld	s7,72(a1)
    80002aea:	0505bc03          	ld	s8,80(a1)
    80002aee:	0585bc83          	ld	s9,88(a1)
    80002af2:	0605bd03          	ld	s10,96(a1)
    80002af6:	0685bd83          	ld	s11,104(a1)
    80002afa:	8082                	ret

0000000080002afc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002afc:	1141                	addi	sp,sp,-16
    80002afe:	e406                	sd	ra,8(sp)
    80002b00:	e022                	sd	s0,0(sp)
    80002b02:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b04:	00006597          	auipc	a1,0x6
    80002b08:	8a458593          	addi	a1,a1,-1884 # 800083a8 <states.1790+0x30>
    80002b0c:	00015517          	auipc	a0,0x15
    80002b10:	de450513          	addi	a0,a0,-540 # 800178f0 <tickslock>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	040080e7          	jalr	64(ra) # 80000b54 <initlock>
}
    80002b1c:	60a2                	ld	ra,8(sp)
    80002b1e:	6402                	ld	s0,0(sp)
    80002b20:	0141                	addi	sp,sp,16
    80002b22:	8082                	ret

0000000080002b24 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e422                	sd	s0,8(sp)
    80002b28:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b2a:	00003797          	auipc	a5,0x3
    80002b2e:	4a678793          	addi	a5,a5,1190 # 80005fd0 <kernelvec>
    80002b32:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b36:	6422                	ld	s0,8(sp)
    80002b38:	0141                	addi	sp,sp,16
    80002b3a:	8082                	ret

0000000080002b3c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e406                	sd	ra,8(sp)
    80002b40:	e022                	sd	s0,0(sp)
    80002b42:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	e90080e7          	jalr	-368(ra) # 800019d4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b50:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b52:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b56:	00004617          	auipc	a2,0x4
    80002b5a:	4aa60613          	addi	a2,a2,1194 # 80007000 <_trampoline>
    80002b5e:	00004697          	auipc	a3,0x4
    80002b62:	4a268693          	addi	a3,a3,1186 # 80007000 <_trampoline>
    80002b66:	8e91                	sub	a3,a3,a2
    80002b68:	040007b7          	lui	a5,0x4000
    80002b6c:	17fd                	addi	a5,a5,-1
    80002b6e:	07b2                	slli	a5,a5,0xc
    80002b70:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b72:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b76:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b78:	180026f3          	csrr	a3,satp
    80002b7c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b7e:	7d38                	ld	a4,120(a0)
    80002b80:	7134                	ld	a3,96(a0)
    80002b82:	6585                	lui	a1,0x1
    80002b84:	96ae                	add	a3,a3,a1
    80002b86:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b88:	7d38                	ld	a4,120(a0)
    80002b8a:	00000697          	auipc	a3,0x0
    80002b8e:	13868693          	addi	a3,a3,312 # 80002cc2 <usertrap>
    80002b92:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b94:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b96:	8692                	mv	a3,tp
    80002b98:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b9a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b9e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ba2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ba6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002baa:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bac:	6f18                	ld	a4,24(a4)
    80002bae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bb2:	792c                	ld	a1,112(a0)
    80002bb4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002bb6:	00004717          	auipc	a4,0x4
    80002bba:	4da70713          	addi	a4,a4,1242 # 80007090 <userret>
    80002bbe:	8f11                	sub	a4,a4,a2
    80002bc0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002bc2:	577d                	li	a4,-1
    80002bc4:	177e                	slli	a4,a4,0x3f
    80002bc6:	8dd9                	or	a1,a1,a4
    80002bc8:	02000537          	lui	a0,0x2000
    80002bcc:	157d                	addi	a0,a0,-1
    80002bce:	0536                	slli	a0,a0,0xd
    80002bd0:	9782                	jalr	a5
}
    80002bd2:	60a2                	ld	ra,8(sp)
    80002bd4:	6402                	ld	s0,0(sp)
    80002bd6:	0141                	addi	sp,sp,16
    80002bd8:	8082                	ret

0000000080002bda <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bda:	1101                	addi	sp,sp,-32
    80002bdc:	ec06                	sd	ra,24(sp)
    80002bde:	e822                	sd	s0,16(sp)
    80002be0:	e426                	sd	s1,8(sp)
    80002be2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002be4:	00015497          	auipc	s1,0x15
    80002be8:	d0c48493          	addi	s1,s1,-756 # 800178f0 <tickslock>
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	ff6080e7          	jalr	-10(ra) # 80000be4 <acquire>
  ticks++;
    80002bf6:	00006517          	auipc	a0,0x6
    80002bfa:	45a50513          	addi	a0,a0,1114 # 80009050 <ticks>
    80002bfe:	411c                	lw	a5,0(a0)
    80002c00:	2785                	addiw	a5,a5,1
    80002c02:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	918080e7          	jalr	-1768(ra) # 8000251c <wakeup>
  release(&tickslock);
    80002c0c:	8526                	mv	a0,s1
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	08a080e7          	jalr	138(ra) # 80000c98 <release>
}
    80002c16:	60e2                	ld	ra,24(sp)
    80002c18:	6442                	ld	s0,16(sp)
    80002c1a:	64a2                	ld	s1,8(sp)
    80002c1c:	6105                	addi	sp,sp,32
    80002c1e:	8082                	ret

0000000080002c20 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c20:	1101                	addi	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	e426                	sd	s1,8(sp)
    80002c28:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c2a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c2e:	00074d63          	bltz	a4,80002c48 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c32:	57fd                	li	a5,-1
    80002c34:	17fe                	slli	a5,a5,0x3f
    80002c36:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c38:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c3a:	06f70363          	beq	a4,a5,80002ca0 <devintr+0x80>
  }
}
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	64a2                	ld	s1,8(sp)
    80002c44:	6105                	addi	sp,sp,32
    80002c46:	8082                	ret
     (scause & 0xff) == 9){
    80002c48:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c4c:	46a5                	li	a3,9
    80002c4e:	fed792e3          	bne	a5,a3,80002c32 <devintr+0x12>
    int irq = plic_claim();
    80002c52:	00003097          	auipc	ra,0x3
    80002c56:	486080e7          	jalr	1158(ra) # 800060d8 <plic_claim>
    80002c5a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c5c:	47a9                	li	a5,10
    80002c5e:	02f50763          	beq	a0,a5,80002c8c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c62:	4785                	li	a5,1
    80002c64:	02f50963          	beq	a0,a5,80002c96 <devintr+0x76>
    return 1;
    80002c68:	4505                	li	a0,1
    } else if(irq){
    80002c6a:	d8f1                	beqz	s1,80002c3e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c6c:	85a6                	mv	a1,s1
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	74250513          	addi	a0,a0,1858 # 800083b0 <states.1790+0x38>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	912080e7          	jalr	-1774(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c7e:	8526                	mv	a0,s1
    80002c80:	00003097          	auipc	ra,0x3
    80002c84:	47c080e7          	jalr	1148(ra) # 800060fc <plic_complete>
    return 1;
    80002c88:	4505                	li	a0,1
    80002c8a:	bf55                	j	80002c3e <devintr+0x1e>
      uartintr();
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	d1c080e7          	jalr	-740(ra) # 800009a8 <uartintr>
    80002c94:	b7ed                	j	80002c7e <devintr+0x5e>
      virtio_disk_intr();
    80002c96:	00004097          	auipc	ra,0x4
    80002c9a:	946080e7          	jalr	-1722(ra) # 800065dc <virtio_disk_intr>
    80002c9e:	b7c5                	j	80002c7e <devintr+0x5e>
    if(cpuid() == 0){
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d08080e7          	jalr	-760(ra) # 800019a8 <cpuid>
    80002ca8:	c901                	beqz	a0,80002cb8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002caa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cb0:	14479073          	csrw	sip,a5
    return 2;
    80002cb4:	4509                	li	a0,2
    80002cb6:	b761                	j	80002c3e <devintr+0x1e>
      clockintr();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	f22080e7          	jalr	-222(ra) # 80002bda <clockintr>
    80002cc0:	b7ed                	j	80002caa <devintr+0x8a>

0000000080002cc2 <usertrap>:
{
    80002cc2:	1101                	addi	sp,sp,-32
    80002cc4:	ec06                	sd	ra,24(sp)
    80002cc6:	e822                	sd	s0,16(sp)
    80002cc8:	e426                	sd	s1,8(sp)
    80002cca:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ccc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cd0:	1007f793          	andi	a5,a5,256
    80002cd4:	e3a5                	bnez	a5,80002d34 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cd6:	00003797          	auipc	a5,0x3
    80002cda:	2fa78793          	addi	a5,a5,762 # 80005fd0 <kernelvec>
    80002cde:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	cf2080e7          	jalr	-782(ra) # 800019d4 <myproc>
    80002cea:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cec:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cee:	14102773          	csrr	a4,sepc
    80002cf2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cf4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cf8:	47a1                	li	a5,8
    80002cfa:	04f71b63          	bne	a4,a5,80002d50 <usertrap+0x8e>
    if(p->killed)
    80002cfe:	551c                	lw	a5,40(a0)
    80002d00:	e3b1                	bnez	a5,80002d44 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002d02:	7cb8                	ld	a4,120(s1)
    80002d04:	6f1c                	ld	a5,24(a4)
    80002d06:	0791                	addi	a5,a5,4
    80002d08:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d0e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d12:	10079073          	csrw	sstatus,a5
    syscall();
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	29a080e7          	jalr	666(ra) # 80002fb0 <syscall>
  if(p->killed)
    80002d1e:	549c                	lw	a5,40(s1)
    80002d20:	e7b5                	bnez	a5,80002d8c <usertrap+0xca>
  usertrapret();
    80002d22:	00000097          	auipc	ra,0x0
    80002d26:	e1a080e7          	jalr	-486(ra) # 80002b3c <usertrapret>
}
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	64a2                	ld	s1,8(sp)
    80002d30:	6105                	addi	sp,sp,32
    80002d32:	8082                	ret
    panic("usertrap: not from user mode");
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	69c50513          	addi	a0,a0,1692 # 800083d0 <states.1790+0x58>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	802080e7          	jalr	-2046(ra) # 8000053e <panic>
      exit(-1);
    80002d44:	557d                	li	a0,-1
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	8c2080e7          	jalr	-1854(ra) # 80002608 <exit>
    80002d4e:	bf55                	j	80002d02 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	ed0080e7          	jalr	-304(ra) # 80002c20 <devintr>
    80002d58:	f179                	bnez	a0,80002d1e <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d5e:	5890                	lw	a2,48(s1)
    80002d60:	00005517          	auipc	a0,0x5
    80002d64:	69050513          	addi	a0,a0,1680 # 800083f0 <states.1790+0x78>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	820080e7          	jalr	-2016(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d74:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d78:	00005517          	auipc	a0,0x5
    80002d7c:	6a850513          	addi	a0,a0,1704 # 80008420 <states.1790+0xa8>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	808080e7          	jalr	-2040(ra) # 80000588 <printf>
    p->killed = 1;
    80002d88:	4785                	li	a5,1
    80002d8a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d8c:	557d                	li	a0,-1
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	87a080e7          	jalr	-1926(ra) # 80002608 <exit>
    80002d96:	b771                	j	80002d22 <usertrap+0x60>

0000000080002d98 <kerneltrap>:
{
    80002d98:	7179                	addi	sp,sp,-48
    80002d9a:	f406                	sd	ra,40(sp)
    80002d9c:	f022                	sd	s0,32(sp)
    80002d9e:	ec26                	sd	s1,24(sp)
    80002da0:	e84a                	sd	s2,16(sp)
    80002da2:	e44e                	sd	s3,8(sp)
    80002da4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002da6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002daa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dae:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002db2:	1004f793          	andi	a5,s1,256
    80002db6:	c78d                	beqz	a5,80002de0 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dbc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002dbe:	eb8d                	bnez	a5,80002df0 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	e60080e7          	jalr	-416(ra) # 80002c20 <devintr>
    80002dc8:	cd05                	beqz	a0,80002e00 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dca:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dce:	10049073          	csrw	sstatus,s1
}
    80002dd2:	70a2                	ld	ra,40(sp)
    80002dd4:	7402                	ld	s0,32(sp)
    80002dd6:	64e2                	ld	s1,24(sp)
    80002dd8:	6942                	ld	s2,16(sp)
    80002dda:	69a2                	ld	s3,8(sp)
    80002ddc:	6145                	addi	sp,sp,48
    80002dde:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002de0:	00005517          	auipc	a0,0x5
    80002de4:	66050513          	addi	a0,a0,1632 # 80008440 <states.1790+0xc8>
    80002de8:	ffffd097          	auipc	ra,0xffffd
    80002dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002df0:	00005517          	auipc	a0,0x5
    80002df4:	67850513          	addi	a0,a0,1656 # 80008468 <states.1790+0xf0>
    80002df8:	ffffd097          	auipc	ra,0xffffd
    80002dfc:	746080e7          	jalr	1862(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e00:	85ce                	mv	a1,s3
    80002e02:	00005517          	auipc	a0,0x5
    80002e06:	68650513          	addi	a0,a0,1670 # 80008488 <states.1790+0x110>
    80002e0a:	ffffd097          	auipc	ra,0xffffd
    80002e0e:	77e080e7          	jalr	1918(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e16:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e1a:	00005517          	auipc	a0,0x5
    80002e1e:	67e50513          	addi	a0,a0,1662 # 80008498 <states.1790+0x120>
    80002e22:	ffffd097          	auipc	ra,0xffffd
    80002e26:	766080e7          	jalr	1894(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e2a:	00005517          	auipc	a0,0x5
    80002e2e:	68650513          	addi	a0,a0,1670 # 800084b0 <states.1790+0x138>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	70c080e7          	jalr	1804(ra) # 8000053e <panic>

0000000080002e3a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e3a:	1101                	addi	sp,sp,-32
    80002e3c:	ec06                	sd	ra,24(sp)
    80002e3e:	e822                	sd	s0,16(sp)
    80002e40:	e426                	sd	s1,8(sp)
    80002e42:	1000                	addi	s0,sp,32
    80002e44:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e46:	fffff097          	auipc	ra,0xfffff
    80002e4a:	b8e080e7          	jalr	-1138(ra) # 800019d4 <myproc>
  switch (n) {
    80002e4e:	4795                	li	a5,5
    80002e50:	0497e163          	bltu	a5,s1,80002e92 <argraw+0x58>
    80002e54:	048a                	slli	s1,s1,0x2
    80002e56:	00005717          	auipc	a4,0x5
    80002e5a:	69270713          	addi	a4,a4,1682 # 800084e8 <states.1790+0x170>
    80002e5e:	94ba                	add	s1,s1,a4
    80002e60:	409c                	lw	a5,0(s1)
    80002e62:	97ba                	add	a5,a5,a4
    80002e64:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e66:	7d3c                	ld	a5,120(a0)
    80002e68:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret
    return p->trapframe->a1;
    80002e74:	7d3c                	ld	a5,120(a0)
    80002e76:	7fa8                	ld	a0,120(a5)
    80002e78:	bfcd                	j	80002e6a <argraw+0x30>
    return p->trapframe->a2;
    80002e7a:	7d3c                	ld	a5,120(a0)
    80002e7c:	63c8                	ld	a0,128(a5)
    80002e7e:	b7f5                	j	80002e6a <argraw+0x30>
    return p->trapframe->a3;
    80002e80:	7d3c                	ld	a5,120(a0)
    80002e82:	67c8                	ld	a0,136(a5)
    80002e84:	b7dd                	j	80002e6a <argraw+0x30>
    return p->trapframe->a4;
    80002e86:	7d3c                	ld	a5,120(a0)
    80002e88:	6bc8                	ld	a0,144(a5)
    80002e8a:	b7c5                	j	80002e6a <argraw+0x30>
    return p->trapframe->a5;
    80002e8c:	7d3c                	ld	a5,120(a0)
    80002e8e:	6fc8                	ld	a0,152(a5)
    80002e90:	bfe9                	j	80002e6a <argraw+0x30>
  panic("argraw");
    80002e92:	00005517          	auipc	a0,0x5
    80002e96:	62e50513          	addi	a0,a0,1582 # 800084c0 <states.1790+0x148>
    80002e9a:	ffffd097          	auipc	ra,0xffffd
    80002e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>

0000000080002ea2 <fetchaddr>:
{
    80002ea2:	1101                	addi	sp,sp,-32
    80002ea4:	ec06                	sd	ra,24(sp)
    80002ea6:	e822                	sd	s0,16(sp)
    80002ea8:	e426                	sd	s1,8(sp)
    80002eaa:	e04a                	sd	s2,0(sp)
    80002eac:	1000                	addi	s0,sp,32
    80002eae:	84aa                	mv	s1,a0
    80002eb0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	b22080e7          	jalr	-1246(ra) # 800019d4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002eba:	753c                	ld	a5,104(a0)
    80002ebc:	02f4f863          	bgeu	s1,a5,80002eec <fetchaddr+0x4a>
    80002ec0:	00848713          	addi	a4,s1,8
    80002ec4:	02e7e663          	bltu	a5,a4,80002ef0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ec8:	46a1                	li	a3,8
    80002eca:	8626                	mv	a2,s1
    80002ecc:	85ca                	mv	a1,s2
    80002ece:	7928                	ld	a0,112(a0)
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	836080e7          	jalr	-1994(ra) # 80001706 <copyin>
    80002ed8:	00a03533          	snez	a0,a0
    80002edc:	40a00533          	neg	a0,a0
}
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6902                	ld	s2,0(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret
    return -1;
    80002eec:	557d                	li	a0,-1
    80002eee:	bfcd                	j	80002ee0 <fetchaddr+0x3e>
    80002ef0:	557d                	li	a0,-1
    80002ef2:	b7fd                	j	80002ee0 <fetchaddr+0x3e>

0000000080002ef4 <fetchstr>:
{
    80002ef4:	7179                	addi	sp,sp,-48
    80002ef6:	f406                	sd	ra,40(sp)
    80002ef8:	f022                	sd	s0,32(sp)
    80002efa:	ec26                	sd	s1,24(sp)
    80002efc:	e84a                	sd	s2,16(sp)
    80002efe:	e44e                	sd	s3,8(sp)
    80002f00:	1800                	addi	s0,sp,48
    80002f02:	892a                	mv	s2,a0
    80002f04:	84ae                	mv	s1,a1
    80002f06:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	acc080e7          	jalr	-1332(ra) # 800019d4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f10:	86ce                	mv	a3,s3
    80002f12:	864a                	mv	a2,s2
    80002f14:	85a6                	mv	a1,s1
    80002f16:	7928                	ld	a0,112(a0)
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	87a080e7          	jalr	-1926(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002f20:	00054763          	bltz	a0,80002f2e <fetchstr+0x3a>
  return strlen(buf);
    80002f24:	8526                	mv	a0,s1
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	f3e080e7          	jalr	-194(ra) # 80000e64 <strlen>
}
    80002f2e:	70a2                	ld	ra,40(sp)
    80002f30:	7402                	ld	s0,32(sp)
    80002f32:	64e2                	ld	s1,24(sp)
    80002f34:	6942                	ld	s2,16(sp)
    80002f36:	69a2                	ld	s3,8(sp)
    80002f38:	6145                	addi	sp,sp,48
    80002f3a:	8082                	ret

0000000080002f3c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	e426                	sd	s1,8(sp)
    80002f44:	1000                	addi	s0,sp,32
    80002f46:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	ef2080e7          	jalr	-270(ra) # 80002e3a <argraw>
    80002f50:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f52:	4501                	li	a0,0
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret

0000000080002f5e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	1000                	addi	s0,sp,32
    80002f68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	ed0080e7          	jalr	-304(ra) # 80002e3a <argraw>
    80002f72:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f74:	4501                	li	a0,0
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	e426                	sd	s1,8(sp)
    80002f88:	e04a                	sd	s2,0(sp)
    80002f8a:	1000                	addi	s0,sp,32
    80002f8c:	84ae                	mv	s1,a1
    80002f8e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	eaa080e7          	jalr	-342(ra) # 80002e3a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f98:	864a                	mv	a2,s2
    80002f9a:	85a6                	mv	a1,s1
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	f58080e7          	jalr	-168(ra) # 80002ef4 <fetchstr>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	64a2                	ld	s1,8(sp)
    80002faa:	6902                	ld	s2,0(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret

0000000080002fb0 <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    80002fb0:	1101                	addi	sp,sp,-32
    80002fb2:	ec06                	sd	ra,24(sp)
    80002fb4:	e822                	sd	s0,16(sp)
    80002fb6:	e426                	sd	s1,8(sp)
    80002fb8:	e04a                	sd	s2,0(sp)
    80002fba:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	a18080e7          	jalr	-1512(ra) # 800019d4 <myproc>
    80002fc4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fc6:	07853903          	ld	s2,120(a0)
    80002fca:	0a893783          	ld	a5,168(s2)
    80002fce:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fd2:	37fd                	addiw	a5,a5,-1
    80002fd4:	475d                	li	a4,23
    80002fd6:	00f76f63          	bltu	a4,a5,80002ff4 <syscall+0x44>
    80002fda:	00369713          	slli	a4,a3,0x3
    80002fde:	00005797          	auipc	a5,0x5
    80002fe2:	52278793          	addi	a5,a5,1314 # 80008500 <syscalls>
    80002fe6:	97ba                	add	a5,a5,a4
    80002fe8:	639c                	ld	a5,0(a5)
    80002fea:	c789                	beqz	a5,80002ff4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002fec:	9782                	jalr	a5
    80002fee:	06a93823          	sd	a0,112(s2)
    80002ff2:	a839                	j	80003010 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ff4:	17848613          	addi	a2,s1,376
    80002ff8:	588c                	lw	a1,48(s1)
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	4ce50513          	addi	a0,a0,1230 # 800084c8 <states.1790+0x150>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	586080e7          	jalr	1414(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000300a:	7cbc                	ld	a5,120(s1)
    8000300c:	577d                	li	a4,-1
    8000300e:	fbb8                	sd	a4,112(a5)
  }
}
    80003010:	60e2                	ld	ra,24(sp)
    80003012:	6442                	ld	s0,16(sp)
    80003014:	64a2                	ld	s1,8(sp)
    80003016:	6902                	ld	s2,0(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003024:	fec40593          	addi	a1,s0,-20
    80003028:	4501                	li	a0,0
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	f12080e7          	jalr	-238(ra) # 80002f3c <argint>
    return -1;
    80003032:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003034:	00054963          	bltz	a0,80003046 <sys_exit+0x2a>
  exit(n);
    80003038:	fec42503          	lw	a0,-20(s0)
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	5cc080e7          	jalr	1484(ra) # 80002608 <exit>
  return 0;  // not reached
    80003044:	4781                	li	a5,0
}
    80003046:	853e                	mv	a0,a5
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	6105                	addi	sp,sp,32
    8000304e:	8082                	ret

0000000080003050 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003050:	1141                	addi	sp,sp,-16
    80003052:	e406                	sd	ra,8(sp)
    80003054:	e022                	sd	s0,0(sp)
    80003056:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	97c080e7          	jalr	-1668(ra) # 800019d4 <myproc>
}
    80003060:	5908                	lw	a0,48(a0)
    80003062:	60a2                	ld	ra,8(sp)
    80003064:	6402                	ld	s0,0(sp)
    80003066:	0141                	addi	sp,sp,16
    80003068:	8082                	ret

000000008000306a <sys_fork>:

uint64
sys_fork(void)
{
    8000306a:	1141                	addi	sp,sp,-16
    8000306c:	e406                	sd	ra,8(sp)
    8000306e:	e022                	sd	s0,0(sp)
    80003070:	0800                	addi	s0,sp,16
  return fork();
    80003072:	fffff097          	auipc	ra,0xfffff
    80003076:	d38080e7          	jalr	-712(ra) # 80001daa <fork>
}
    8000307a:	60a2                	ld	ra,8(sp)
    8000307c:	6402                	ld	s0,0(sp)
    8000307e:	0141                	addi	sp,sp,16
    80003080:	8082                	ret

0000000080003082 <sys_wait>:

uint64
sys_wait(void)
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000308a:	fe840593          	addi	a1,s0,-24
    8000308e:	4501                	li	a0,0
    80003090:	00000097          	auipc	ra,0x0
    80003094:	ece080e7          	jalr	-306(ra) # 80002f5e <argaddr>
    80003098:	87aa                	mv	a5,a0
    return -1;
    8000309a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000309c:	0007c863          	bltz	a5,800030ac <sys_wait+0x2a>
  return wait(p);
    800030a0:	fe843503          	ld	a0,-24(s0)
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	350080e7          	jalr	848(ra) # 800023f4 <wait>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret

00000000800030b4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030b4:	7179                	addi	sp,sp,-48
    800030b6:	f406                	sd	ra,40(sp)
    800030b8:	f022                	sd	s0,32(sp)
    800030ba:	ec26                	sd	s1,24(sp)
    800030bc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800030be:	fdc40593          	addi	a1,s0,-36
    800030c2:	4501                	li	a0,0
    800030c4:	00000097          	auipc	ra,0x0
    800030c8:	e78080e7          	jalr	-392(ra) # 80002f3c <argint>
    800030cc:	87aa                	mv	a5,a0
    return -1;
    800030ce:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030d0:	0207c063          	bltz	a5,800030f0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	900080e7          	jalr	-1792(ra) # 800019d4 <myproc>
    800030dc:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800030de:	fdc42503          	lw	a0,-36(s0)
    800030e2:	fffff097          	auipc	ra,0xfffff
    800030e6:	c54080e7          	jalr	-940(ra) # 80001d36 <growproc>
    800030ea:	00054863          	bltz	a0,800030fa <sys_sbrk+0x46>
    return -1;
  return addr;
    800030ee:	8526                	mv	a0,s1
}
    800030f0:	70a2                	ld	ra,40(sp)
    800030f2:	7402                	ld	s0,32(sp)
    800030f4:	64e2                	ld	s1,24(sp)
    800030f6:	6145                	addi	sp,sp,48
    800030f8:	8082                	ret
    return -1;
    800030fa:	557d                	li	a0,-1
    800030fc:	bfd5                	j	800030f0 <sys_sbrk+0x3c>

00000000800030fe <sys_sleep>:

uint64
sys_sleep(void)
{
    800030fe:	7139                	addi	sp,sp,-64
    80003100:	fc06                	sd	ra,56(sp)
    80003102:	f822                	sd	s0,48(sp)
    80003104:	f426                	sd	s1,40(sp)
    80003106:	f04a                	sd	s2,32(sp)
    80003108:	ec4e                	sd	s3,24(sp)
    8000310a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000310c:	fcc40593          	addi	a1,s0,-52
    80003110:	4501                	li	a0,0
    80003112:	00000097          	auipc	ra,0x0
    80003116:	e2a080e7          	jalr	-470(ra) # 80002f3c <argint>
    return -1;
    8000311a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000311c:	06054563          	bltz	a0,80003186 <sys_sleep+0x88>
  acquire(&tickslock);
    80003120:	00014517          	auipc	a0,0x14
    80003124:	7d050513          	addi	a0,a0,2000 # 800178f0 <tickslock>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003130:	00006917          	auipc	s2,0x6
    80003134:	f2092903          	lw	s2,-224(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80003138:	fcc42783          	lw	a5,-52(s0)
    8000313c:	cf85                	beqz	a5,80003174 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000313e:	00014997          	auipc	s3,0x14
    80003142:	7b298993          	addi	s3,s3,1970 # 800178f0 <tickslock>
    80003146:	00006497          	auipc	s1,0x6
    8000314a:	f0a48493          	addi	s1,s1,-246 # 80009050 <ticks>
    if(myproc()->killed){
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	886080e7          	jalr	-1914(ra) # 800019d4 <myproc>
    80003156:	551c                	lw	a5,40(a0)
    80003158:	ef9d                	bnez	a5,80003196 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000315a:	85ce                	mv	a1,s3
    8000315c:	8526                	mv	a0,s1
    8000315e:	fffff097          	auipc	ra,0xfffff
    80003162:	228080e7          	jalr	552(ra) # 80002386 <sleep>
  while(ticks - ticks0 < n){
    80003166:	409c                	lw	a5,0(s1)
    80003168:	412787bb          	subw	a5,a5,s2
    8000316c:	fcc42703          	lw	a4,-52(s0)
    80003170:	fce7efe3          	bltu	a5,a4,8000314e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003174:	00014517          	auipc	a0,0x14
    80003178:	77c50513          	addi	a0,a0,1916 # 800178f0 <tickslock>
    8000317c:	ffffe097          	auipc	ra,0xffffe
    80003180:	b1c080e7          	jalr	-1252(ra) # 80000c98 <release>
  return 0;
    80003184:	4781                	li	a5,0
}
    80003186:	853e                	mv	a0,a5
    80003188:	70e2                	ld	ra,56(sp)
    8000318a:	7442                	ld	s0,48(sp)
    8000318c:	74a2                	ld	s1,40(sp)
    8000318e:	7902                	ld	s2,32(sp)
    80003190:	69e2                	ld	s3,24(sp)
    80003192:	6121                	addi	sp,sp,64
    80003194:	8082                	ret
      release(&tickslock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	75a50513          	addi	a0,a0,1882 # 800178f0 <tickslock>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
      return -1;
    800031a6:	57fd                	li	a5,-1
    800031a8:	bff9                	j	80003186 <sys_sleep+0x88>

00000000800031aa <sys_kill>:

uint64
sys_kill(void)
{
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800031b2:	fec40593          	addi	a1,s0,-20
    800031b6:	4501                	li	a0,0
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	d84080e7          	jalr	-636(ra) # 80002f3c <argint>
    800031c0:	87aa                	mv	a5,a0
    return -1;
    800031c2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031c4:	0007c863          	bltz	a5,800031d4 <sys_kill+0x2a>
  return kill(pid);
    800031c8:	fec42503          	lw	a0,-20(s0)
    800031cc:	fffff097          	auipc	ra,0xfffff
    800031d0:	5a6080e7          	jalr	1446(ra) # 80002772 <kill>
}
    800031d4:	60e2                	ld	ra,24(sp)
    800031d6:	6442                	ld	s0,16(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031e6:	00014517          	auipc	a0,0x14
    800031ea:	70a50513          	addi	a0,a0,1802 # 800178f0 <tickslock>
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	9f6080e7          	jalr	-1546(ra) # 80000be4 <acquire>
  xticks = ticks;
    800031f6:	00006497          	auipc	s1,0x6
    800031fa:	e5a4a483          	lw	s1,-422(s1) # 80009050 <ticks>
  release(&tickslock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	6f250513          	addi	a0,a0,1778 # 800178f0 <tickslock>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
  return xticks;
}
    8000320e:	02049513          	slli	a0,s1,0x20
    80003212:	9101                	srli	a0,a0,0x20
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	64a2                	ld	s1,8(sp)
    8000321a:	6105                	addi	sp,sp,32
    8000321c:	8082                	ret

000000008000321e <sys_pause_system>:

uint64
sys_pause_system(void)
{
    8000321e:	1101                	addi	sp,sp,-32
    80003220:	ec06                	sd	ra,24(sp)
    80003222:	e822                	sd	s0,16(sp)
    80003224:	1000                	addi	s0,sp,32
  int seconds;
  if(argint(0, &seconds) >= 0)
    80003226:	fec40593          	addi	a1,s0,-20
    8000322a:	4501                	li	a0,0
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	d10080e7          	jalr	-752(ra) # 80002f3c <argint>
    80003234:	87aa                	mv	a5,a0
  {
    return pause_system(seconds);
  }
  return -1;
    80003236:	557d                	li	a0,-1
  if(argint(0, &seconds) >= 0)
    80003238:	0007d663          	bgez	a5,80003244 <sys_pause_system+0x26>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret
    return pause_system(seconds);
    80003244:	fec42503          	lw	a0,-20(s0)
    80003248:	fffff097          	auipc	ra,0xfffff
    8000324c:	70a080e7          	jalr	1802(ra) # 80002952 <pause_system>
    80003250:	b7f5                	j	8000323c <sys_pause_system+0x1e>

0000000080003252 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003252:	1141                	addi	sp,sp,-16
    80003254:	e406                	sd	ra,8(sp)
    80003256:	e022                	sd	s0,0(sp)
    80003258:	0800                	addi	s0,sp,16
  return kill_system();
    8000325a:	fffff097          	auipc	ra,0xfffff
    8000325e:	72e080e7          	jalr	1838(ra) # 80002988 <kill_system>
}
    80003262:	60a2                	ld	ra,8(sp)
    80003264:	6402                	ld	s0,0(sp)
    80003266:	0141                	addi	sp,sp,16
    80003268:	8082                	ret

000000008000326a <sys_print_stats>:

uint64
sys_print_stats(void)
{
    8000326a:	1141                	addi	sp,sp,-16
    8000326c:	e406                	sd	ra,8(sp)
    8000326e:	e022                	sd	s0,0(sp)
    80003270:	0800                	addi	s0,sp,16
  print_stats();
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	780080e7          	jalr	1920(ra) # 800029f2 <print_stats>
  return 0;
    8000327a:	4501                	li	a0,0
    8000327c:	60a2                	ld	ra,8(sp)
    8000327e:	6402                	ld	s0,0(sp)
    80003280:	0141                	addi	sp,sp,16
    80003282:	8082                	ret

0000000080003284 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003284:	7179                	addi	sp,sp,-48
    80003286:	f406                	sd	ra,40(sp)
    80003288:	f022                	sd	s0,32(sp)
    8000328a:	ec26                	sd	s1,24(sp)
    8000328c:	e84a                	sd	s2,16(sp)
    8000328e:	e44e                	sd	s3,8(sp)
    80003290:	e052                	sd	s4,0(sp)
    80003292:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003294:	00005597          	auipc	a1,0x5
    80003298:	33458593          	addi	a1,a1,820 # 800085c8 <syscalls+0xc8>
    8000329c:	00014517          	auipc	a0,0x14
    800032a0:	66c50513          	addi	a0,a0,1644 # 80017908 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	8b0080e7          	jalr	-1872(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032ac:	0001c797          	auipc	a5,0x1c
    800032b0:	65c78793          	addi	a5,a5,1628 # 8001f908 <bcache+0x8000>
    800032b4:	0001d717          	auipc	a4,0x1d
    800032b8:	8bc70713          	addi	a4,a4,-1860 # 8001fb70 <bcache+0x8268>
    800032bc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032c0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032c4:	00014497          	auipc	s1,0x14
    800032c8:	65c48493          	addi	s1,s1,1628 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800032cc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032ce:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032d0:	00005a17          	auipc	s4,0x5
    800032d4:	300a0a13          	addi	s4,s4,768 # 800085d0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800032d8:	2b893783          	ld	a5,696(s2)
    800032dc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032de:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032e2:	85d2                	mv	a1,s4
    800032e4:	01048513          	addi	a0,s1,16
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	4bc080e7          	jalr	1212(ra) # 800047a4 <initsleeplock>
    bcache.head.next->prev = b;
    800032f0:	2b893783          	ld	a5,696(s2)
    800032f4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032f6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032fa:	45848493          	addi	s1,s1,1112
    800032fe:	fd349de3          	bne	s1,s3,800032d8 <binit+0x54>
  }
}
    80003302:	70a2                	ld	ra,40(sp)
    80003304:	7402                	ld	s0,32(sp)
    80003306:	64e2                	ld	s1,24(sp)
    80003308:	6942                	ld	s2,16(sp)
    8000330a:	69a2                	ld	s3,8(sp)
    8000330c:	6a02                	ld	s4,0(sp)
    8000330e:	6145                	addi	sp,sp,48
    80003310:	8082                	ret

0000000080003312 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003312:	7179                	addi	sp,sp,-48
    80003314:	f406                	sd	ra,40(sp)
    80003316:	f022                	sd	s0,32(sp)
    80003318:	ec26                	sd	s1,24(sp)
    8000331a:	e84a                	sd	s2,16(sp)
    8000331c:	e44e                	sd	s3,8(sp)
    8000331e:	1800                	addi	s0,sp,48
    80003320:	89aa                	mv	s3,a0
    80003322:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003324:	00014517          	auipc	a0,0x14
    80003328:	5e450513          	addi	a0,a0,1508 # 80017908 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	8b8080e7          	jalr	-1864(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003334:	0001d497          	auipc	s1,0x1d
    80003338:	88c4b483          	ld	s1,-1908(s1) # 8001fbc0 <bcache+0x82b8>
    8000333c:	0001d797          	auipc	a5,0x1d
    80003340:	83478793          	addi	a5,a5,-1996 # 8001fb70 <bcache+0x8268>
    80003344:	02f48f63          	beq	s1,a5,80003382 <bread+0x70>
    80003348:	873e                	mv	a4,a5
    8000334a:	a021                	j	80003352 <bread+0x40>
    8000334c:	68a4                	ld	s1,80(s1)
    8000334e:	02e48a63          	beq	s1,a4,80003382 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003352:	449c                	lw	a5,8(s1)
    80003354:	ff379ce3          	bne	a5,s3,8000334c <bread+0x3a>
    80003358:	44dc                	lw	a5,12(s1)
    8000335a:	ff2799e3          	bne	a5,s2,8000334c <bread+0x3a>
      b->refcnt++;
    8000335e:	40bc                	lw	a5,64(s1)
    80003360:	2785                	addiw	a5,a5,1
    80003362:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003364:	00014517          	auipc	a0,0x14
    80003368:	5a450513          	addi	a0,a0,1444 # 80017908 <bcache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003374:	01048513          	addi	a0,s1,16
    80003378:	00001097          	auipc	ra,0x1
    8000337c:	466080e7          	jalr	1126(ra) # 800047de <acquiresleep>
      return b;
    80003380:	a8b9                	j	800033de <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003382:	0001d497          	auipc	s1,0x1d
    80003386:	8364b483          	ld	s1,-1994(s1) # 8001fbb8 <bcache+0x82b0>
    8000338a:	0001c797          	auipc	a5,0x1c
    8000338e:	7e678793          	addi	a5,a5,2022 # 8001fb70 <bcache+0x8268>
    80003392:	00f48863          	beq	s1,a5,800033a2 <bread+0x90>
    80003396:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003398:	40bc                	lw	a5,64(s1)
    8000339a:	cf81                	beqz	a5,800033b2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000339c:	64a4                	ld	s1,72(s1)
    8000339e:	fee49de3          	bne	s1,a4,80003398 <bread+0x86>
  panic("bget: no buffers");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	23650513          	addi	a0,a0,566 # 800085d8 <syscalls+0xd8>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	194080e7          	jalr	404(ra) # 8000053e <panic>
      b->dev = dev;
    800033b2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800033b6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800033ba:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033be:	4785                	li	a5,1
    800033c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	54650513          	addi	a0,a0,1350 # 80017908 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8ce080e7          	jalr	-1842(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033d2:	01048513          	addi	a0,s1,16
    800033d6:	00001097          	auipc	ra,0x1
    800033da:	408080e7          	jalr	1032(ra) # 800047de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033de:	409c                	lw	a5,0(s1)
    800033e0:	cb89                	beqz	a5,800033f2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033e2:	8526                	mv	a0,s1
    800033e4:	70a2                	ld	ra,40(sp)
    800033e6:	7402                	ld	s0,32(sp)
    800033e8:	64e2                	ld	s1,24(sp)
    800033ea:	6942                	ld	s2,16(sp)
    800033ec:	69a2                	ld	s3,8(sp)
    800033ee:	6145                	addi	sp,sp,48
    800033f0:	8082                	ret
    virtio_disk_rw(b, 0);
    800033f2:	4581                	li	a1,0
    800033f4:	8526                	mv	a0,s1
    800033f6:	00003097          	auipc	ra,0x3
    800033fa:	f10080e7          	jalr	-240(ra) # 80006306 <virtio_disk_rw>
    b->valid = 1;
    800033fe:	4785                	li	a5,1
    80003400:	c09c                	sw	a5,0(s1)
  return b;
    80003402:	b7c5                	j	800033e2 <bread+0xd0>

0000000080003404 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	1000                	addi	s0,sp,32
    8000340e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003410:	0541                	addi	a0,a0,16
    80003412:	00001097          	auipc	ra,0x1
    80003416:	466080e7          	jalr	1126(ra) # 80004878 <holdingsleep>
    8000341a:	cd01                	beqz	a0,80003432 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000341c:	4585                	li	a1,1
    8000341e:	8526                	mv	a0,s1
    80003420:	00003097          	auipc	ra,0x3
    80003424:	ee6080e7          	jalr	-282(ra) # 80006306 <virtio_disk_rw>
}
    80003428:	60e2                	ld	ra,24(sp)
    8000342a:	6442                	ld	s0,16(sp)
    8000342c:	64a2                	ld	s1,8(sp)
    8000342e:	6105                	addi	sp,sp,32
    80003430:	8082                	ret
    panic("bwrite");
    80003432:	00005517          	auipc	a0,0x5
    80003436:	1be50513          	addi	a0,a0,446 # 800085f0 <syscalls+0xf0>
    8000343a:	ffffd097          	auipc	ra,0xffffd
    8000343e:	104080e7          	jalr	260(ra) # 8000053e <panic>

0000000080003442 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003442:	1101                	addi	sp,sp,-32
    80003444:	ec06                	sd	ra,24(sp)
    80003446:	e822                	sd	s0,16(sp)
    80003448:	e426                	sd	s1,8(sp)
    8000344a:	e04a                	sd	s2,0(sp)
    8000344c:	1000                	addi	s0,sp,32
    8000344e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003450:	01050913          	addi	s2,a0,16
    80003454:	854a                	mv	a0,s2
    80003456:	00001097          	auipc	ra,0x1
    8000345a:	422080e7          	jalr	1058(ra) # 80004878 <holdingsleep>
    8000345e:	c92d                	beqz	a0,800034d0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003460:	854a                	mv	a0,s2
    80003462:	00001097          	auipc	ra,0x1
    80003466:	3d2080e7          	jalr	978(ra) # 80004834 <releasesleep>

  acquire(&bcache.lock);
    8000346a:	00014517          	auipc	a0,0x14
    8000346e:	49e50513          	addi	a0,a0,1182 # 80017908 <bcache>
    80003472:	ffffd097          	auipc	ra,0xffffd
    80003476:	772080e7          	jalr	1906(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000347a:	40bc                	lw	a5,64(s1)
    8000347c:	37fd                	addiw	a5,a5,-1
    8000347e:	0007871b          	sext.w	a4,a5
    80003482:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003484:	eb05                	bnez	a4,800034b4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003486:	68bc                	ld	a5,80(s1)
    80003488:	64b8                	ld	a4,72(s1)
    8000348a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000348c:	64bc                	ld	a5,72(s1)
    8000348e:	68b8                	ld	a4,80(s1)
    80003490:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003492:	0001c797          	auipc	a5,0x1c
    80003496:	47678793          	addi	a5,a5,1142 # 8001f908 <bcache+0x8000>
    8000349a:	2b87b703          	ld	a4,696(a5)
    8000349e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034a0:	0001c717          	auipc	a4,0x1c
    800034a4:	6d070713          	addi	a4,a4,1744 # 8001fb70 <bcache+0x8268>
    800034a8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034aa:	2b87b703          	ld	a4,696(a5)
    800034ae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034b0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034b4:	00014517          	auipc	a0,0x14
    800034b8:	45450513          	addi	a0,a0,1108 # 80017908 <bcache>
    800034bc:	ffffd097          	auipc	ra,0xffffd
    800034c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
}
    800034c4:	60e2                	ld	ra,24(sp)
    800034c6:	6442                	ld	s0,16(sp)
    800034c8:	64a2                	ld	s1,8(sp)
    800034ca:	6902                	ld	s2,0(sp)
    800034cc:	6105                	addi	sp,sp,32
    800034ce:	8082                	ret
    panic("brelse");
    800034d0:	00005517          	auipc	a0,0x5
    800034d4:	12850513          	addi	a0,a0,296 # 800085f8 <syscalls+0xf8>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	066080e7          	jalr	102(ra) # 8000053e <panic>

00000000800034e0 <bpin>:

void
bpin(struct buf *b) {
    800034e0:	1101                	addi	sp,sp,-32
    800034e2:	ec06                	sd	ra,24(sp)
    800034e4:	e822                	sd	s0,16(sp)
    800034e6:	e426                	sd	s1,8(sp)
    800034e8:	1000                	addi	s0,sp,32
    800034ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034ec:	00014517          	auipc	a0,0x14
    800034f0:	41c50513          	addi	a0,a0,1052 # 80017908 <bcache>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	6f0080e7          	jalr	1776(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034fc:	40bc                	lw	a5,64(s1)
    800034fe:	2785                	addiw	a5,a5,1
    80003500:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003502:	00014517          	auipc	a0,0x14
    80003506:	40650513          	addi	a0,a0,1030 # 80017908 <bcache>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	78e080e7          	jalr	1934(ra) # 80000c98 <release>
}
    80003512:	60e2                	ld	ra,24(sp)
    80003514:	6442                	ld	s0,16(sp)
    80003516:	64a2                	ld	s1,8(sp)
    80003518:	6105                	addi	sp,sp,32
    8000351a:	8082                	ret

000000008000351c <bunpin>:

void
bunpin(struct buf *b) {
    8000351c:	1101                	addi	sp,sp,-32
    8000351e:	ec06                	sd	ra,24(sp)
    80003520:	e822                	sd	s0,16(sp)
    80003522:	e426                	sd	s1,8(sp)
    80003524:	1000                	addi	s0,sp,32
    80003526:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003528:	00014517          	auipc	a0,0x14
    8000352c:	3e050513          	addi	a0,a0,992 # 80017908 <bcache>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003538:	40bc                	lw	a5,64(s1)
    8000353a:	37fd                	addiw	a5,a5,-1
    8000353c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000353e:	00014517          	auipc	a0,0x14
    80003542:	3ca50513          	addi	a0,a0,970 # 80017908 <bcache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret

0000000080003558 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003558:	1101                	addi	sp,sp,-32
    8000355a:	ec06                	sd	ra,24(sp)
    8000355c:	e822                	sd	s0,16(sp)
    8000355e:	e426                	sd	s1,8(sp)
    80003560:	e04a                	sd	s2,0(sp)
    80003562:	1000                	addi	s0,sp,32
    80003564:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003566:	00d5d59b          	srliw	a1,a1,0xd
    8000356a:	0001d797          	auipc	a5,0x1d
    8000356e:	a7a7a783          	lw	a5,-1414(a5) # 8001ffe4 <sb+0x1c>
    80003572:	9dbd                	addw	a1,a1,a5
    80003574:	00000097          	auipc	ra,0x0
    80003578:	d9e080e7          	jalr	-610(ra) # 80003312 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000357c:	0074f713          	andi	a4,s1,7
    80003580:	4785                	li	a5,1
    80003582:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003586:	14ce                	slli	s1,s1,0x33
    80003588:	90d9                	srli	s1,s1,0x36
    8000358a:	00950733          	add	a4,a0,s1
    8000358e:	05874703          	lbu	a4,88(a4)
    80003592:	00e7f6b3          	and	a3,a5,a4
    80003596:	c69d                	beqz	a3,800035c4 <bfree+0x6c>
    80003598:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000359a:	94aa                	add	s1,s1,a0
    8000359c:	fff7c793          	not	a5,a5
    800035a0:	8ff9                	and	a5,a5,a4
    800035a2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	118080e7          	jalr	280(ra) # 800046be <log_write>
  brelse(bp);
    800035ae:	854a                	mv	a0,s2
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	e92080e7          	jalr	-366(ra) # 80003442 <brelse>
}
    800035b8:	60e2                	ld	ra,24(sp)
    800035ba:	6442                	ld	s0,16(sp)
    800035bc:	64a2                	ld	s1,8(sp)
    800035be:	6902                	ld	s2,0(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret
    panic("freeing free block");
    800035c4:	00005517          	auipc	a0,0x5
    800035c8:	03c50513          	addi	a0,a0,60 # 80008600 <syscalls+0x100>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	f72080e7          	jalr	-142(ra) # 8000053e <panic>

00000000800035d4 <balloc>:
{
    800035d4:	711d                	addi	sp,sp,-96
    800035d6:	ec86                	sd	ra,88(sp)
    800035d8:	e8a2                	sd	s0,80(sp)
    800035da:	e4a6                	sd	s1,72(sp)
    800035dc:	e0ca                	sd	s2,64(sp)
    800035de:	fc4e                	sd	s3,56(sp)
    800035e0:	f852                	sd	s4,48(sp)
    800035e2:	f456                	sd	s5,40(sp)
    800035e4:	f05a                	sd	s6,32(sp)
    800035e6:	ec5e                	sd	s7,24(sp)
    800035e8:	e862                	sd	s8,16(sp)
    800035ea:	e466                	sd	s9,8(sp)
    800035ec:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035ee:	0001d797          	auipc	a5,0x1d
    800035f2:	9de7a783          	lw	a5,-1570(a5) # 8001ffcc <sb+0x4>
    800035f6:	cbd1                	beqz	a5,8000368a <balloc+0xb6>
    800035f8:	8baa                	mv	s7,a0
    800035fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035fc:	0001db17          	auipc	s6,0x1d
    80003600:	9ccb0b13          	addi	s6,s6,-1588 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003604:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003606:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003608:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000360a:	6c89                	lui	s9,0x2
    8000360c:	a831                	j	80003628 <balloc+0x54>
    brelse(bp);
    8000360e:	854a                	mv	a0,s2
    80003610:	00000097          	auipc	ra,0x0
    80003614:	e32080e7          	jalr	-462(ra) # 80003442 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003618:	015c87bb          	addw	a5,s9,s5
    8000361c:	00078a9b          	sext.w	s5,a5
    80003620:	004b2703          	lw	a4,4(s6)
    80003624:	06eaf363          	bgeu	s5,a4,8000368a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003628:	41fad79b          	sraiw	a5,s5,0x1f
    8000362c:	0137d79b          	srliw	a5,a5,0x13
    80003630:	015787bb          	addw	a5,a5,s5
    80003634:	40d7d79b          	sraiw	a5,a5,0xd
    80003638:	01cb2583          	lw	a1,28(s6)
    8000363c:	9dbd                	addw	a1,a1,a5
    8000363e:	855e                	mv	a0,s7
    80003640:	00000097          	auipc	ra,0x0
    80003644:	cd2080e7          	jalr	-814(ra) # 80003312 <bread>
    80003648:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000364a:	004b2503          	lw	a0,4(s6)
    8000364e:	000a849b          	sext.w	s1,s5
    80003652:	8662                	mv	a2,s8
    80003654:	faa4fde3          	bgeu	s1,a0,8000360e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003658:	41f6579b          	sraiw	a5,a2,0x1f
    8000365c:	01d7d69b          	srliw	a3,a5,0x1d
    80003660:	00c6873b          	addw	a4,a3,a2
    80003664:	00777793          	andi	a5,a4,7
    80003668:	9f95                	subw	a5,a5,a3
    8000366a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000366e:	4037571b          	sraiw	a4,a4,0x3
    80003672:	00e906b3          	add	a3,s2,a4
    80003676:	0586c683          	lbu	a3,88(a3)
    8000367a:	00d7f5b3          	and	a1,a5,a3
    8000367e:	cd91                	beqz	a1,8000369a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003680:	2605                	addiw	a2,a2,1
    80003682:	2485                	addiw	s1,s1,1
    80003684:	fd4618e3          	bne	a2,s4,80003654 <balloc+0x80>
    80003688:	b759                	j	8000360e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000368a:	00005517          	auipc	a0,0x5
    8000368e:	f8e50513          	addi	a0,a0,-114 # 80008618 <syscalls+0x118>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000369a:	974a                	add	a4,a4,s2
    8000369c:	8fd5                	or	a5,a5,a3
    8000369e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036a2:	854a                	mv	a0,s2
    800036a4:	00001097          	auipc	ra,0x1
    800036a8:	01a080e7          	jalr	26(ra) # 800046be <log_write>
        brelse(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	d94080e7          	jalr	-620(ra) # 80003442 <brelse>
  bp = bread(dev, bno);
    800036b6:	85a6                	mv	a1,s1
    800036b8:	855e                	mv	a0,s7
    800036ba:	00000097          	auipc	ra,0x0
    800036be:	c58080e7          	jalr	-936(ra) # 80003312 <bread>
    800036c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036c4:	40000613          	li	a2,1024
    800036c8:	4581                	li	a1,0
    800036ca:	05850513          	addi	a0,a0,88
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	612080e7          	jalr	1554(ra) # 80000ce0 <memset>
  log_write(bp);
    800036d6:	854a                	mv	a0,s2
    800036d8:	00001097          	auipc	ra,0x1
    800036dc:	fe6080e7          	jalr	-26(ra) # 800046be <log_write>
  brelse(bp);
    800036e0:	854a                	mv	a0,s2
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	d60080e7          	jalr	-672(ra) # 80003442 <brelse>
}
    800036ea:	8526                	mv	a0,s1
    800036ec:	60e6                	ld	ra,88(sp)
    800036ee:	6446                	ld	s0,80(sp)
    800036f0:	64a6                	ld	s1,72(sp)
    800036f2:	6906                	ld	s2,64(sp)
    800036f4:	79e2                	ld	s3,56(sp)
    800036f6:	7a42                	ld	s4,48(sp)
    800036f8:	7aa2                	ld	s5,40(sp)
    800036fa:	7b02                	ld	s6,32(sp)
    800036fc:	6be2                	ld	s7,24(sp)
    800036fe:	6c42                	ld	s8,16(sp)
    80003700:	6ca2                	ld	s9,8(sp)
    80003702:	6125                	addi	sp,sp,96
    80003704:	8082                	ret

0000000080003706 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003706:	7179                	addi	sp,sp,-48
    80003708:	f406                	sd	ra,40(sp)
    8000370a:	f022                	sd	s0,32(sp)
    8000370c:	ec26                	sd	s1,24(sp)
    8000370e:	e84a                	sd	s2,16(sp)
    80003710:	e44e                	sd	s3,8(sp)
    80003712:	e052                	sd	s4,0(sp)
    80003714:	1800                	addi	s0,sp,48
    80003716:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003718:	47ad                	li	a5,11
    8000371a:	04b7fe63          	bgeu	a5,a1,80003776 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000371e:	ff45849b          	addiw	s1,a1,-12
    80003722:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003726:	0ff00793          	li	a5,255
    8000372a:	0ae7e363          	bltu	a5,a4,800037d0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000372e:	08052583          	lw	a1,128(a0)
    80003732:	c5ad                	beqz	a1,8000379c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003734:	00092503          	lw	a0,0(s2)
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	bda080e7          	jalr	-1062(ra) # 80003312 <bread>
    80003740:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003742:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003746:	02049593          	slli	a1,s1,0x20
    8000374a:	9181                	srli	a1,a1,0x20
    8000374c:	058a                	slli	a1,a1,0x2
    8000374e:	00b784b3          	add	s1,a5,a1
    80003752:	0004a983          	lw	s3,0(s1)
    80003756:	04098d63          	beqz	s3,800037b0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000375a:	8552                	mv	a0,s4
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	ce6080e7          	jalr	-794(ra) # 80003442 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003764:	854e                	mv	a0,s3
    80003766:	70a2                	ld	ra,40(sp)
    80003768:	7402                	ld	s0,32(sp)
    8000376a:	64e2                	ld	s1,24(sp)
    8000376c:	6942                	ld	s2,16(sp)
    8000376e:	69a2                	ld	s3,8(sp)
    80003770:	6a02                	ld	s4,0(sp)
    80003772:	6145                	addi	sp,sp,48
    80003774:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003776:	02059493          	slli	s1,a1,0x20
    8000377a:	9081                	srli	s1,s1,0x20
    8000377c:	048a                	slli	s1,s1,0x2
    8000377e:	94aa                	add	s1,s1,a0
    80003780:	0504a983          	lw	s3,80(s1)
    80003784:	fe0990e3          	bnez	s3,80003764 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003788:	4108                	lw	a0,0(a0)
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	e4a080e7          	jalr	-438(ra) # 800035d4 <balloc>
    80003792:	0005099b          	sext.w	s3,a0
    80003796:	0534a823          	sw	s3,80(s1)
    8000379a:	b7e9                	j	80003764 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000379c:	4108                	lw	a0,0(a0)
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	e36080e7          	jalr	-458(ra) # 800035d4 <balloc>
    800037a6:	0005059b          	sext.w	a1,a0
    800037aa:	08b92023          	sw	a1,128(s2)
    800037ae:	b759                	j	80003734 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037b0:	00092503          	lw	a0,0(s2)
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	e20080e7          	jalr	-480(ra) # 800035d4 <balloc>
    800037bc:	0005099b          	sext.w	s3,a0
    800037c0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037c4:	8552                	mv	a0,s4
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	ef8080e7          	jalr	-264(ra) # 800046be <log_write>
    800037ce:	b771                	j	8000375a <bmap+0x54>
  panic("bmap: out of range");
    800037d0:	00005517          	auipc	a0,0x5
    800037d4:	e6050513          	addi	a0,a0,-416 # 80008630 <syscalls+0x130>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	d66080e7          	jalr	-666(ra) # 8000053e <panic>

00000000800037e0 <iget>:
{
    800037e0:	7179                	addi	sp,sp,-48
    800037e2:	f406                	sd	ra,40(sp)
    800037e4:	f022                	sd	s0,32(sp)
    800037e6:	ec26                	sd	s1,24(sp)
    800037e8:	e84a                	sd	s2,16(sp)
    800037ea:	e44e                	sd	s3,8(sp)
    800037ec:	e052                	sd	s4,0(sp)
    800037ee:	1800                	addi	s0,sp,48
    800037f0:	89aa                	mv	s3,a0
    800037f2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037f4:	0001c517          	auipc	a0,0x1c
    800037f8:	7f450513          	addi	a0,a0,2036 # 8001ffe8 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	3e8080e7          	jalr	1000(ra) # 80000be4 <acquire>
  empty = 0;
    80003804:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003806:	0001c497          	auipc	s1,0x1c
    8000380a:	7fa48493          	addi	s1,s1,2042 # 80020000 <itable+0x18>
    8000380e:	0001e697          	auipc	a3,0x1e
    80003812:	28268693          	addi	a3,a3,642 # 80021a90 <log>
    80003816:	a039                	j	80003824 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003818:	02090b63          	beqz	s2,8000384e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000381c:	08848493          	addi	s1,s1,136
    80003820:	02d48a63          	beq	s1,a3,80003854 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003824:	449c                	lw	a5,8(s1)
    80003826:	fef059e3          	blez	a5,80003818 <iget+0x38>
    8000382a:	4098                	lw	a4,0(s1)
    8000382c:	ff3716e3          	bne	a4,s3,80003818 <iget+0x38>
    80003830:	40d8                	lw	a4,4(s1)
    80003832:	ff4713e3          	bne	a4,s4,80003818 <iget+0x38>
      ip->ref++;
    80003836:	2785                	addiw	a5,a5,1
    80003838:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000383a:	0001c517          	auipc	a0,0x1c
    8000383e:	7ae50513          	addi	a0,a0,1966 # 8001ffe8 <itable>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	456080e7          	jalr	1110(ra) # 80000c98 <release>
      return ip;
    8000384a:	8926                	mv	s2,s1
    8000384c:	a03d                	j	8000387a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000384e:	f7f9                	bnez	a5,8000381c <iget+0x3c>
    80003850:	8926                	mv	s2,s1
    80003852:	b7e9                	j	8000381c <iget+0x3c>
  if(empty == 0)
    80003854:	02090c63          	beqz	s2,8000388c <iget+0xac>
  ip->dev = dev;
    80003858:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000385c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003860:	4785                	li	a5,1
    80003862:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003866:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000386a:	0001c517          	auipc	a0,0x1c
    8000386e:	77e50513          	addi	a0,a0,1918 # 8001ffe8 <itable>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}
    8000387a:	854a                	mv	a0,s2
    8000387c:	70a2                	ld	ra,40(sp)
    8000387e:	7402                	ld	s0,32(sp)
    80003880:	64e2                	ld	s1,24(sp)
    80003882:	6942                	ld	s2,16(sp)
    80003884:	69a2                	ld	s3,8(sp)
    80003886:	6a02                	ld	s4,0(sp)
    80003888:	6145                	addi	sp,sp,48
    8000388a:	8082                	ret
    panic("iget: no inodes");
    8000388c:	00005517          	auipc	a0,0x5
    80003890:	dbc50513          	addi	a0,a0,-580 # 80008648 <syscalls+0x148>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>

000000008000389c <fsinit>:
fsinit(int dev) {
    8000389c:	7179                	addi	sp,sp,-48
    8000389e:	f406                	sd	ra,40(sp)
    800038a0:	f022                	sd	s0,32(sp)
    800038a2:	ec26                	sd	s1,24(sp)
    800038a4:	e84a                	sd	s2,16(sp)
    800038a6:	e44e                	sd	s3,8(sp)
    800038a8:	1800                	addi	s0,sp,48
    800038aa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038ac:	4585                	li	a1,1
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	a64080e7          	jalr	-1436(ra) # 80003312 <bread>
    800038b6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038b8:	0001c997          	auipc	s3,0x1c
    800038bc:	71098993          	addi	s3,s3,1808 # 8001ffc8 <sb>
    800038c0:	02000613          	li	a2,32
    800038c4:	05850593          	addi	a1,a0,88
    800038c8:	854e                	mv	a0,s3
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	476080e7          	jalr	1142(ra) # 80000d40 <memmove>
  brelse(bp);
    800038d2:	8526                	mv	a0,s1
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	b6e080e7          	jalr	-1170(ra) # 80003442 <brelse>
  if(sb.magic != FSMAGIC)
    800038dc:	0009a703          	lw	a4,0(s3)
    800038e0:	102037b7          	lui	a5,0x10203
    800038e4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038e8:	02f71263          	bne	a4,a5,8000390c <fsinit+0x70>
  initlog(dev, &sb);
    800038ec:	0001c597          	auipc	a1,0x1c
    800038f0:	6dc58593          	addi	a1,a1,1756 # 8001ffc8 <sb>
    800038f4:	854a                	mv	a0,s2
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	b4c080e7          	jalr	-1204(ra) # 80004442 <initlog>
}
    800038fe:	70a2                	ld	ra,40(sp)
    80003900:	7402                	ld	s0,32(sp)
    80003902:	64e2                	ld	s1,24(sp)
    80003904:	6942                	ld	s2,16(sp)
    80003906:	69a2                	ld	s3,8(sp)
    80003908:	6145                	addi	sp,sp,48
    8000390a:	8082                	ret
    panic("invalid file system");
    8000390c:	00005517          	auipc	a0,0x5
    80003910:	d4c50513          	addi	a0,a0,-692 # 80008658 <syscalls+0x158>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	c2a080e7          	jalr	-982(ra) # 8000053e <panic>

000000008000391c <iinit>:
{
    8000391c:	7179                	addi	sp,sp,-48
    8000391e:	f406                	sd	ra,40(sp)
    80003920:	f022                	sd	s0,32(sp)
    80003922:	ec26                	sd	s1,24(sp)
    80003924:	e84a                	sd	s2,16(sp)
    80003926:	e44e                	sd	s3,8(sp)
    80003928:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000392a:	00005597          	auipc	a1,0x5
    8000392e:	d4658593          	addi	a1,a1,-698 # 80008670 <syscalls+0x170>
    80003932:	0001c517          	auipc	a0,0x1c
    80003936:	6b650513          	addi	a0,a0,1718 # 8001ffe8 <itable>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	21a080e7          	jalr	538(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003942:	0001c497          	auipc	s1,0x1c
    80003946:	6ce48493          	addi	s1,s1,1742 # 80020010 <itable+0x28>
    8000394a:	0001e997          	auipc	s3,0x1e
    8000394e:	15698993          	addi	s3,s3,342 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003952:	00005917          	auipc	s2,0x5
    80003956:	d2690913          	addi	s2,s2,-730 # 80008678 <syscalls+0x178>
    8000395a:	85ca                	mv	a1,s2
    8000395c:	8526                	mv	a0,s1
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	e46080e7          	jalr	-442(ra) # 800047a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003966:	08848493          	addi	s1,s1,136
    8000396a:	ff3498e3          	bne	s1,s3,8000395a <iinit+0x3e>
}
    8000396e:	70a2                	ld	ra,40(sp)
    80003970:	7402                	ld	s0,32(sp)
    80003972:	64e2                	ld	s1,24(sp)
    80003974:	6942                	ld	s2,16(sp)
    80003976:	69a2                	ld	s3,8(sp)
    80003978:	6145                	addi	sp,sp,48
    8000397a:	8082                	ret

000000008000397c <ialloc>:
{
    8000397c:	715d                	addi	sp,sp,-80
    8000397e:	e486                	sd	ra,72(sp)
    80003980:	e0a2                	sd	s0,64(sp)
    80003982:	fc26                	sd	s1,56(sp)
    80003984:	f84a                	sd	s2,48(sp)
    80003986:	f44e                	sd	s3,40(sp)
    80003988:	f052                	sd	s4,32(sp)
    8000398a:	ec56                	sd	s5,24(sp)
    8000398c:	e85a                	sd	s6,16(sp)
    8000398e:	e45e                	sd	s7,8(sp)
    80003990:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003992:	0001c717          	auipc	a4,0x1c
    80003996:	64272703          	lw	a4,1602(a4) # 8001ffd4 <sb+0xc>
    8000399a:	4785                	li	a5,1
    8000399c:	04e7fa63          	bgeu	a5,a4,800039f0 <ialloc+0x74>
    800039a0:	8aaa                	mv	s5,a0
    800039a2:	8bae                	mv	s7,a1
    800039a4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039a6:	0001ca17          	auipc	s4,0x1c
    800039aa:	622a0a13          	addi	s4,s4,1570 # 8001ffc8 <sb>
    800039ae:	00048b1b          	sext.w	s6,s1
    800039b2:	0044d593          	srli	a1,s1,0x4
    800039b6:	018a2783          	lw	a5,24(s4)
    800039ba:	9dbd                	addw	a1,a1,a5
    800039bc:	8556                	mv	a0,s5
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	954080e7          	jalr	-1708(ra) # 80003312 <bread>
    800039c6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039c8:	05850993          	addi	s3,a0,88
    800039cc:	00f4f793          	andi	a5,s1,15
    800039d0:	079a                	slli	a5,a5,0x6
    800039d2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039d4:	00099783          	lh	a5,0(s3)
    800039d8:	c785                	beqz	a5,80003a00 <ialloc+0x84>
    brelse(bp);
    800039da:	00000097          	auipc	ra,0x0
    800039de:	a68080e7          	jalr	-1432(ra) # 80003442 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e2:	0485                	addi	s1,s1,1
    800039e4:	00ca2703          	lw	a4,12(s4)
    800039e8:	0004879b          	sext.w	a5,s1
    800039ec:	fce7e1e3          	bltu	a5,a4,800039ae <ialloc+0x32>
  panic("ialloc: no inodes");
    800039f0:	00005517          	auipc	a0,0x5
    800039f4:	c9050513          	addi	a0,a0,-880 # 80008680 <syscalls+0x180>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a00:	04000613          	li	a2,64
    80003a04:	4581                	li	a1,0
    80003a06:	854e                	mv	a0,s3
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	2d8080e7          	jalr	728(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a10:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a14:	854a                	mv	a0,s2
    80003a16:	00001097          	auipc	ra,0x1
    80003a1a:	ca8080e7          	jalr	-856(ra) # 800046be <log_write>
      brelse(bp);
    80003a1e:	854a                	mv	a0,s2
    80003a20:	00000097          	auipc	ra,0x0
    80003a24:	a22080e7          	jalr	-1502(ra) # 80003442 <brelse>
      return iget(dev, inum);
    80003a28:	85da                	mv	a1,s6
    80003a2a:	8556                	mv	a0,s5
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	db4080e7          	jalr	-588(ra) # 800037e0 <iget>
}
    80003a34:	60a6                	ld	ra,72(sp)
    80003a36:	6406                	ld	s0,64(sp)
    80003a38:	74e2                	ld	s1,56(sp)
    80003a3a:	7942                	ld	s2,48(sp)
    80003a3c:	79a2                	ld	s3,40(sp)
    80003a3e:	7a02                	ld	s4,32(sp)
    80003a40:	6ae2                	ld	s5,24(sp)
    80003a42:	6b42                	ld	s6,16(sp)
    80003a44:	6ba2                	ld	s7,8(sp)
    80003a46:	6161                	addi	sp,sp,80
    80003a48:	8082                	ret

0000000080003a4a <iupdate>:
{
    80003a4a:	1101                	addi	sp,sp,-32
    80003a4c:	ec06                	sd	ra,24(sp)
    80003a4e:	e822                	sd	s0,16(sp)
    80003a50:	e426                	sd	s1,8(sp)
    80003a52:	e04a                	sd	s2,0(sp)
    80003a54:	1000                	addi	s0,sp,32
    80003a56:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a58:	415c                	lw	a5,4(a0)
    80003a5a:	0047d79b          	srliw	a5,a5,0x4
    80003a5e:	0001c597          	auipc	a1,0x1c
    80003a62:	5825a583          	lw	a1,1410(a1) # 8001ffe0 <sb+0x18>
    80003a66:	9dbd                	addw	a1,a1,a5
    80003a68:	4108                	lw	a0,0(a0)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	8a8080e7          	jalr	-1880(ra) # 80003312 <bread>
    80003a72:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a74:	05850793          	addi	a5,a0,88
    80003a78:	40c8                	lw	a0,4(s1)
    80003a7a:	893d                	andi	a0,a0,15
    80003a7c:	051a                	slli	a0,a0,0x6
    80003a7e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a80:	04449703          	lh	a4,68(s1)
    80003a84:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a88:	04649703          	lh	a4,70(s1)
    80003a8c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a90:	04849703          	lh	a4,72(s1)
    80003a94:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a98:	04a49703          	lh	a4,74(s1)
    80003a9c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003aa0:	44f8                	lw	a4,76(s1)
    80003aa2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003aa4:	03400613          	li	a2,52
    80003aa8:	05048593          	addi	a1,s1,80
    80003aac:	0531                	addi	a0,a0,12
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	292080e7          	jalr	658(ra) # 80000d40 <memmove>
  log_write(bp);
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	00001097          	auipc	ra,0x1
    80003abc:	c06080e7          	jalr	-1018(ra) # 800046be <log_write>
  brelse(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	980080e7          	jalr	-1664(ra) # 80003442 <brelse>
}
    80003aca:	60e2                	ld	ra,24(sp)
    80003acc:	6442                	ld	s0,16(sp)
    80003ace:	64a2                	ld	s1,8(sp)
    80003ad0:	6902                	ld	s2,0(sp)
    80003ad2:	6105                	addi	sp,sp,32
    80003ad4:	8082                	ret

0000000080003ad6 <idup>:
{
    80003ad6:	1101                	addi	sp,sp,-32
    80003ad8:	ec06                	sd	ra,24(sp)
    80003ada:	e822                	sd	s0,16(sp)
    80003adc:	e426                	sd	s1,8(sp)
    80003ade:	1000                	addi	s0,sp,32
    80003ae0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ae2:	0001c517          	auipc	a0,0x1c
    80003ae6:	50650513          	addi	a0,a0,1286 # 8001ffe8 <itable>
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	0fa080e7          	jalr	250(ra) # 80000be4 <acquire>
  ip->ref++;
    80003af2:	449c                	lw	a5,8(s1)
    80003af4:	2785                	addiw	a5,a5,1
    80003af6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003af8:	0001c517          	auipc	a0,0x1c
    80003afc:	4f050513          	addi	a0,a0,1264 # 8001ffe8 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	198080e7          	jalr	408(ra) # 80000c98 <release>
}
    80003b08:	8526                	mv	a0,s1
    80003b0a:	60e2                	ld	ra,24(sp)
    80003b0c:	6442                	ld	s0,16(sp)
    80003b0e:	64a2                	ld	s1,8(sp)
    80003b10:	6105                	addi	sp,sp,32
    80003b12:	8082                	ret

0000000080003b14 <ilock>:
{
    80003b14:	1101                	addi	sp,sp,-32
    80003b16:	ec06                	sd	ra,24(sp)
    80003b18:	e822                	sd	s0,16(sp)
    80003b1a:	e426                	sd	s1,8(sp)
    80003b1c:	e04a                	sd	s2,0(sp)
    80003b1e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b20:	c115                	beqz	a0,80003b44 <ilock+0x30>
    80003b22:	84aa                	mv	s1,a0
    80003b24:	451c                	lw	a5,8(a0)
    80003b26:	00f05f63          	blez	a5,80003b44 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b2a:	0541                	addi	a0,a0,16
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	cb2080e7          	jalr	-846(ra) # 800047de <acquiresleep>
  if(ip->valid == 0){
    80003b34:	40bc                	lw	a5,64(s1)
    80003b36:	cf99                	beqz	a5,80003b54 <ilock+0x40>
}
    80003b38:	60e2                	ld	ra,24(sp)
    80003b3a:	6442                	ld	s0,16(sp)
    80003b3c:	64a2                	ld	s1,8(sp)
    80003b3e:	6902                	ld	s2,0(sp)
    80003b40:	6105                	addi	sp,sp,32
    80003b42:	8082                	ret
    panic("ilock");
    80003b44:	00005517          	auipc	a0,0x5
    80003b48:	b5450513          	addi	a0,a0,-1196 # 80008698 <syscalls+0x198>
    80003b4c:	ffffd097          	auipc	ra,0xffffd
    80003b50:	9f2080e7          	jalr	-1550(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b54:	40dc                	lw	a5,4(s1)
    80003b56:	0047d79b          	srliw	a5,a5,0x4
    80003b5a:	0001c597          	auipc	a1,0x1c
    80003b5e:	4865a583          	lw	a1,1158(a1) # 8001ffe0 <sb+0x18>
    80003b62:	9dbd                	addw	a1,a1,a5
    80003b64:	4088                	lw	a0,0(s1)
    80003b66:	fffff097          	auipc	ra,0xfffff
    80003b6a:	7ac080e7          	jalr	1964(ra) # 80003312 <bread>
    80003b6e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b70:	05850593          	addi	a1,a0,88
    80003b74:	40dc                	lw	a5,4(s1)
    80003b76:	8bbd                	andi	a5,a5,15
    80003b78:	079a                	slli	a5,a5,0x6
    80003b7a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b7c:	00059783          	lh	a5,0(a1)
    80003b80:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b84:	00259783          	lh	a5,2(a1)
    80003b88:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b8c:	00459783          	lh	a5,4(a1)
    80003b90:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b94:	00659783          	lh	a5,6(a1)
    80003b98:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b9c:	459c                	lw	a5,8(a1)
    80003b9e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ba0:	03400613          	li	a2,52
    80003ba4:	05b1                	addi	a1,a1,12
    80003ba6:	05048513          	addi	a0,s1,80
    80003baa:	ffffd097          	auipc	ra,0xffffd
    80003bae:	196080e7          	jalr	406(ra) # 80000d40 <memmove>
    brelse(bp);
    80003bb2:	854a                	mv	a0,s2
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	88e080e7          	jalr	-1906(ra) # 80003442 <brelse>
    ip->valid = 1;
    80003bbc:	4785                	li	a5,1
    80003bbe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bc0:	04449783          	lh	a5,68(s1)
    80003bc4:	fbb5                	bnez	a5,80003b38 <ilock+0x24>
      panic("ilock: no type");
    80003bc6:	00005517          	auipc	a0,0x5
    80003bca:	ada50513          	addi	a0,a0,-1318 # 800086a0 <syscalls+0x1a0>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	970080e7          	jalr	-1680(ra) # 8000053e <panic>

0000000080003bd6 <iunlock>:
{
    80003bd6:	1101                	addi	sp,sp,-32
    80003bd8:	ec06                	sd	ra,24(sp)
    80003bda:	e822                	sd	s0,16(sp)
    80003bdc:	e426                	sd	s1,8(sp)
    80003bde:	e04a                	sd	s2,0(sp)
    80003be0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003be2:	c905                	beqz	a0,80003c12 <iunlock+0x3c>
    80003be4:	84aa                	mv	s1,a0
    80003be6:	01050913          	addi	s2,a0,16
    80003bea:	854a                	mv	a0,s2
    80003bec:	00001097          	auipc	ra,0x1
    80003bf0:	c8c080e7          	jalr	-884(ra) # 80004878 <holdingsleep>
    80003bf4:	cd19                	beqz	a0,80003c12 <iunlock+0x3c>
    80003bf6:	449c                	lw	a5,8(s1)
    80003bf8:	00f05d63          	blez	a5,80003c12 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	c36080e7          	jalr	-970(ra) # 80004834 <releasesleep>
}
    80003c06:	60e2                	ld	ra,24(sp)
    80003c08:	6442                	ld	s0,16(sp)
    80003c0a:	64a2                	ld	s1,8(sp)
    80003c0c:	6902                	ld	s2,0(sp)
    80003c0e:	6105                	addi	sp,sp,32
    80003c10:	8082                	ret
    panic("iunlock");
    80003c12:	00005517          	auipc	a0,0x5
    80003c16:	a9e50513          	addi	a0,a0,-1378 # 800086b0 <syscalls+0x1b0>
    80003c1a:	ffffd097          	auipc	ra,0xffffd
    80003c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>

0000000080003c22 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c22:	7179                	addi	sp,sp,-48
    80003c24:	f406                	sd	ra,40(sp)
    80003c26:	f022                	sd	s0,32(sp)
    80003c28:	ec26                	sd	s1,24(sp)
    80003c2a:	e84a                	sd	s2,16(sp)
    80003c2c:	e44e                	sd	s3,8(sp)
    80003c2e:	e052                	sd	s4,0(sp)
    80003c30:	1800                	addi	s0,sp,48
    80003c32:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c34:	05050493          	addi	s1,a0,80
    80003c38:	08050913          	addi	s2,a0,128
    80003c3c:	a021                	j	80003c44 <itrunc+0x22>
    80003c3e:	0491                	addi	s1,s1,4
    80003c40:	01248d63          	beq	s1,s2,80003c5a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c44:	408c                	lw	a1,0(s1)
    80003c46:	dde5                	beqz	a1,80003c3e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c48:	0009a503          	lw	a0,0(s3)
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	90c080e7          	jalr	-1780(ra) # 80003558 <bfree>
      ip->addrs[i] = 0;
    80003c54:	0004a023          	sw	zero,0(s1)
    80003c58:	b7dd                	j	80003c3e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c5a:	0809a583          	lw	a1,128(s3)
    80003c5e:	e185                	bnez	a1,80003c7e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c60:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c64:	854e                	mv	a0,s3
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	de4080e7          	jalr	-540(ra) # 80003a4a <iupdate>
}
    80003c6e:	70a2                	ld	ra,40(sp)
    80003c70:	7402                	ld	s0,32(sp)
    80003c72:	64e2                	ld	s1,24(sp)
    80003c74:	6942                	ld	s2,16(sp)
    80003c76:	69a2                	ld	s3,8(sp)
    80003c78:	6a02                	ld	s4,0(sp)
    80003c7a:	6145                	addi	sp,sp,48
    80003c7c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c7e:	0009a503          	lw	a0,0(s3)
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	690080e7          	jalr	1680(ra) # 80003312 <bread>
    80003c8a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c8c:	05850493          	addi	s1,a0,88
    80003c90:	45850913          	addi	s2,a0,1112
    80003c94:	a811                	j	80003ca8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c96:	0009a503          	lw	a0,0(s3)
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	8be080e7          	jalr	-1858(ra) # 80003558 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ca2:	0491                	addi	s1,s1,4
    80003ca4:	01248563          	beq	s1,s2,80003cae <itrunc+0x8c>
      if(a[j])
    80003ca8:	408c                	lw	a1,0(s1)
    80003caa:	dde5                	beqz	a1,80003ca2 <itrunc+0x80>
    80003cac:	b7ed                	j	80003c96 <itrunc+0x74>
    brelse(bp);
    80003cae:	8552                	mv	a0,s4
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	792080e7          	jalr	1938(ra) # 80003442 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cb8:	0809a583          	lw	a1,128(s3)
    80003cbc:	0009a503          	lw	a0,0(s3)
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	898080e7          	jalr	-1896(ra) # 80003558 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cc8:	0809a023          	sw	zero,128(s3)
    80003ccc:	bf51                	j	80003c60 <itrunc+0x3e>

0000000080003cce <iput>:
{
    80003cce:	1101                	addi	sp,sp,-32
    80003cd0:	ec06                	sd	ra,24(sp)
    80003cd2:	e822                	sd	s0,16(sp)
    80003cd4:	e426                	sd	s1,8(sp)
    80003cd6:	e04a                	sd	s2,0(sp)
    80003cd8:	1000                	addi	s0,sp,32
    80003cda:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cdc:	0001c517          	auipc	a0,0x1c
    80003ce0:	30c50513          	addi	a0,a0,780 # 8001ffe8 <itable>
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	f00080e7          	jalr	-256(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cec:	4498                	lw	a4,8(s1)
    80003cee:	4785                	li	a5,1
    80003cf0:	02f70363          	beq	a4,a5,80003d16 <iput+0x48>
  ip->ref--;
    80003cf4:	449c                	lw	a5,8(s1)
    80003cf6:	37fd                	addiw	a5,a5,-1
    80003cf8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cfa:	0001c517          	auipc	a0,0x1c
    80003cfe:	2ee50513          	addi	a0,a0,750 # 8001ffe8 <itable>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	f96080e7          	jalr	-106(ra) # 80000c98 <release>
}
    80003d0a:	60e2                	ld	ra,24(sp)
    80003d0c:	6442                	ld	s0,16(sp)
    80003d0e:	64a2                	ld	s1,8(sp)
    80003d10:	6902                	ld	s2,0(sp)
    80003d12:	6105                	addi	sp,sp,32
    80003d14:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d16:	40bc                	lw	a5,64(s1)
    80003d18:	dff1                	beqz	a5,80003cf4 <iput+0x26>
    80003d1a:	04a49783          	lh	a5,74(s1)
    80003d1e:	fbf9                	bnez	a5,80003cf4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d20:	01048913          	addi	s2,s1,16
    80003d24:	854a                	mv	a0,s2
    80003d26:	00001097          	auipc	ra,0x1
    80003d2a:	ab8080e7          	jalr	-1352(ra) # 800047de <acquiresleep>
    release(&itable.lock);
    80003d2e:	0001c517          	auipc	a0,0x1c
    80003d32:	2ba50513          	addi	a0,a0,698 # 8001ffe8 <itable>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	f62080e7          	jalr	-158(ra) # 80000c98 <release>
    itrunc(ip);
    80003d3e:	8526                	mv	a0,s1
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	ee2080e7          	jalr	-286(ra) # 80003c22 <itrunc>
    ip->type = 0;
    80003d48:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	cfc080e7          	jalr	-772(ra) # 80003a4a <iupdate>
    ip->valid = 0;
    80003d56:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00001097          	auipc	ra,0x1
    80003d60:	ad8080e7          	jalr	-1320(ra) # 80004834 <releasesleep>
    acquire(&itable.lock);
    80003d64:	0001c517          	auipc	a0,0x1c
    80003d68:	28450513          	addi	a0,a0,644 # 8001ffe8 <itable>
    80003d6c:	ffffd097          	auipc	ra,0xffffd
    80003d70:	e78080e7          	jalr	-392(ra) # 80000be4 <acquire>
    80003d74:	b741                	j	80003cf4 <iput+0x26>

0000000080003d76 <iunlockput>:
{
    80003d76:	1101                	addi	sp,sp,-32
    80003d78:	ec06                	sd	ra,24(sp)
    80003d7a:	e822                	sd	s0,16(sp)
    80003d7c:	e426                	sd	s1,8(sp)
    80003d7e:	1000                	addi	s0,sp,32
    80003d80:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	e54080e7          	jalr	-428(ra) # 80003bd6 <iunlock>
  iput(ip);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	f42080e7          	jalr	-190(ra) # 80003cce <iput>
}
    80003d94:	60e2                	ld	ra,24(sp)
    80003d96:	6442                	ld	s0,16(sp)
    80003d98:	64a2                	ld	s1,8(sp)
    80003d9a:	6105                	addi	sp,sp,32
    80003d9c:	8082                	ret

0000000080003d9e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d9e:	1141                	addi	sp,sp,-16
    80003da0:	e422                	sd	s0,8(sp)
    80003da2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003da4:	411c                	lw	a5,0(a0)
    80003da6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003da8:	415c                	lw	a5,4(a0)
    80003daa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dac:	04451783          	lh	a5,68(a0)
    80003db0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003db4:	04a51783          	lh	a5,74(a0)
    80003db8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dbc:	04c56783          	lwu	a5,76(a0)
    80003dc0:	e99c                	sd	a5,16(a1)
}
    80003dc2:	6422                	ld	s0,8(sp)
    80003dc4:	0141                	addi	sp,sp,16
    80003dc6:	8082                	ret

0000000080003dc8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dc8:	457c                	lw	a5,76(a0)
    80003dca:	0ed7e963          	bltu	a5,a3,80003ebc <readi+0xf4>
{
    80003dce:	7159                	addi	sp,sp,-112
    80003dd0:	f486                	sd	ra,104(sp)
    80003dd2:	f0a2                	sd	s0,96(sp)
    80003dd4:	eca6                	sd	s1,88(sp)
    80003dd6:	e8ca                	sd	s2,80(sp)
    80003dd8:	e4ce                	sd	s3,72(sp)
    80003dda:	e0d2                	sd	s4,64(sp)
    80003ddc:	fc56                	sd	s5,56(sp)
    80003dde:	f85a                	sd	s6,48(sp)
    80003de0:	f45e                	sd	s7,40(sp)
    80003de2:	f062                	sd	s8,32(sp)
    80003de4:	ec66                	sd	s9,24(sp)
    80003de6:	e86a                	sd	s10,16(sp)
    80003de8:	e46e                	sd	s11,8(sp)
    80003dea:	1880                	addi	s0,sp,112
    80003dec:	8baa                	mv	s7,a0
    80003dee:	8c2e                	mv	s8,a1
    80003df0:	8ab2                	mv	s5,a2
    80003df2:	84b6                	mv	s1,a3
    80003df4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003df6:	9f35                	addw	a4,a4,a3
    return 0;
    80003df8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dfa:	0ad76063          	bltu	a4,a3,80003e9a <readi+0xd2>
  if(off + n > ip->size)
    80003dfe:	00e7f463          	bgeu	a5,a4,80003e06 <readi+0x3e>
    n = ip->size - off;
    80003e02:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e06:	0a0b0963          	beqz	s6,80003eb8 <readi+0xf0>
    80003e0a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e0c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e10:	5cfd                	li	s9,-1
    80003e12:	a82d                	j	80003e4c <readi+0x84>
    80003e14:	020a1d93          	slli	s11,s4,0x20
    80003e18:	020ddd93          	srli	s11,s11,0x20
    80003e1c:	05890613          	addi	a2,s2,88
    80003e20:	86ee                	mv	a3,s11
    80003e22:	963a                	add	a2,a2,a4
    80003e24:	85d6                	mv	a1,s5
    80003e26:	8562                	mv	a0,s8
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	9d0080e7          	jalr	-1584(ra) # 800027f8 <either_copyout>
    80003e30:	05950d63          	beq	a0,s9,80003e8a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e34:	854a                	mv	a0,s2
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	60c080e7          	jalr	1548(ra) # 80003442 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e3e:	013a09bb          	addw	s3,s4,s3
    80003e42:	009a04bb          	addw	s1,s4,s1
    80003e46:	9aee                	add	s5,s5,s11
    80003e48:	0569f763          	bgeu	s3,s6,80003e96 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e4c:	000ba903          	lw	s2,0(s7)
    80003e50:	00a4d59b          	srliw	a1,s1,0xa
    80003e54:	855e                	mv	a0,s7
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	8b0080e7          	jalr	-1872(ra) # 80003706 <bmap>
    80003e5e:	0005059b          	sext.w	a1,a0
    80003e62:	854a                	mv	a0,s2
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	4ae080e7          	jalr	1198(ra) # 80003312 <bread>
    80003e6c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e6e:	3ff4f713          	andi	a4,s1,1023
    80003e72:	40ed07bb          	subw	a5,s10,a4
    80003e76:	413b06bb          	subw	a3,s6,s3
    80003e7a:	8a3e                	mv	s4,a5
    80003e7c:	2781                	sext.w	a5,a5
    80003e7e:	0006861b          	sext.w	a2,a3
    80003e82:	f8f679e3          	bgeu	a2,a5,80003e14 <readi+0x4c>
    80003e86:	8a36                	mv	s4,a3
    80003e88:	b771                	j	80003e14 <readi+0x4c>
      brelse(bp);
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	5b6080e7          	jalr	1462(ra) # 80003442 <brelse>
      tot = -1;
    80003e94:	59fd                	li	s3,-1
  }
  return tot;
    80003e96:	0009851b          	sext.w	a0,s3
}
    80003e9a:	70a6                	ld	ra,104(sp)
    80003e9c:	7406                	ld	s0,96(sp)
    80003e9e:	64e6                	ld	s1,88(sp)
    80003ea0:	6946                	ld	s2,80(sp)
    80003ea2:	69a6                	ld	s3,72(sp)
    80003ea4:	6a06                	ld	s4,64(sp)
    80003ea6:	7ae2                	ld	s5,56(sp)
    80003ea8:	7b42                	ld	s6,48(sp)
    80003eaa:	7ba2                	ld	s7,40(sp)
    80003eac:	7c02                	ld	s8,32(sp)
    80003eae:	6ce2                	ld	s9,24(sp)
    80003eb0:	6d42                	ld	s10,16(sp)
    80003eb2:	6da2                	ld	s11,8(sp)
    80003eb4:	6165                	addi	sp,sp,112
    80003eb6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eb8:	89da                	mv	s3,s6
    80003eba:	bff1                	j	80003e96 <readi+0xce>
    return 0;
    80003ebc:	4501                	li	a0,0
}
    80003ebe:	8082                	ret

0000000080003ec0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ec0:	457c                	lw	a5,76(a0)
    80003ec2:	10d7e863          	bltu	a5,a3,80003fd2 <writei+0x112>
{
    80003ec6:	7159                	addi	sp,sp,-112
    80003ec8:	f486                	sd	ra,104(sp)
    80003eca:	f0a2                	sd	s0,96(sp)
    80003ecc:	eca6                	sd	s1,88(sp)
    80003ece:	e8ca                	sd	s2,80(sp)
    80003ed0:	e4ce                	sd	s3,72(sp)
    80003ed2:	e0d2                	sd	s4,64(sp)
    80003ed4:	fc56                	sd	s5,56(sp)
    80003ed6:	f85a                	sd	s6,48(sp)
    80003ed8:	f45e                	sd	s7,40(sp)
    80003eda:	f062                	sd	s8,32(sp)
    80003edc:	ec66                	sd	s9,24(sp)
    80003ede:	e86a                	sd	s10,16(sp)
    80003ee0:	e46e                	sd	s11,8(sp)
    80003ee2:	1880                	addi	s0,sp,112
    80003ee4:	8b2a                	mv	s6,a0
    80003ee6:	8c2e                	mv	s8,a1
    80003ee8:	8ab2                	mv	s5,a2
    80003eea:	8936                	mv	s2,a3
    80003eec:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003eee:	00e687bb          	addw	a5,a3,a4
    80003ef2:	0ed7e263          	bltu	a5,a3,80003fd6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ef6:	00043737          	lui	a4,0x43
    80003efa:	0ef76063          	bltu	a4,a5,80003fda <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003efe:	0c0b8863          	beqz	s7,80003fce <writei+0x10e>
    80003f02:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f04:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f08:	5cfd                	li	s9,-1
    80003f0a:	a091                	j	80003f4e <writei+0x8e>
    80003f0c:	02099d93          	slli	s11,s3,0x20
    80003f10:	020ddd93          	srli	s11,s11,0x20
    80003f14:	05848513          	addi	a0,s1,88
    80003f18:	86ee                	mv	a3,s11
    80003f1a:	8656                	mv	a2,s5
    80003f1c:	85e2                	mv	a1,s8
    80003f1e:	953a                	add	a0,a0,a4
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	92e080e7          	jalr	-1746(ra) # 8000284e <either_copyin>
    80003f28:	07950263          	beq	a0,s9,80003f8c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f2c:	8526                	mv	a0,s1
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	790080e7          	jalr	1936(ra) # 800046be <log_write>
    brelse(bp);
    80003f36:	8526                	mv	a0,s1
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	50a080e7          	jalr	1290(ra) # 80003442 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f40:	01498a3b          	addw	s4,s3,s4
    80003f44:	0129893b          	addw	s2,s3,s2
    80003f48:	9aee                	add	s5,s5,s11
    80003f4a:	057a7663          	bgeu	s4,s7,80003f96 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f4e:	000b2483          	lw	s1,0(s6)
    80003f52:	00a9559b          	srliw	a1,s2,0xa
    80003f56:	855a                	mv	a0,s6
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	7ae080e7          	jalr	1966(ra) # 80003706 <bmap>
    80003f60:	0005059b          	sext.w	a1,a0
    80003f64:	8526                	mv	a0,s1
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	3ac080e7          	jalr	940(ra) # 80003312 <bread>
    80003f6e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f70:	3ff97713          	andi	a4,s2,1023
    80003f74:	40ed07bb          	subw	a5,s10,a4
    80003f78:	414b86bb          	subw	a3,s7,s4
    80003f7c:	89be                	mv	s3,a5
    80003f7e:	2781                	sext.w	a5,a5
    80003f80:	0006861b          	sext.w	a2,a3
    80003f84:	f8f674e3          	bgeu	a2,a5,80003f0c <writei+0x4c>
    80003f88:	89b6                	mv	s3,a3
    80003f8a:	b749                	j	80003f0c <writei+0x4c>
      brelse(bp);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	4b4080e7          	jalr	1204(ra) # 80003442 <brelse>
  }

  if(off > ip->size)
    80003f96:	04cb2783          	lw	a5,76(s6)
    80003f9a:	0127f463          	bgeu	a5,s2,80003fa2 <writei+0xe2>
    ip->size = off;
    80003f9e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fa2:	855a                	mv	a0,s6
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	aa6080e7          	jalr	-1370(ra) # 80003a4a <iupdate>

  return tot;
    80003fac:	000a051b          	sext.w	a0,s4
}
    80003fb0:	70a6                	ld	ra,104(sp)
    80003fb2:	7406                	ld	s0,96(sp)
    80003fb4:	64e6                	ld	s1,88(sp)
    80003fb6:	6946                	ld	s2,80(sp)
    80003fb8:	69a6                	ld	s3,72(sp)
    80003fba:	6a06                	ld	s4,64(sp)
    80003fbc:	7ae2                	ld	s5,56(sp)
    80003fbe:	7b42                	ld	s6,48(sp)
    80003fc0:	7ba2                	ld	s7,40(sp)
    80003fc2:	7c02                	ld	s8,32(sp)
    80003fc4:	6ce2                	ld	s9,24(sp)
    80003fc6:	6d42                	ld	s10,16(sp)
    80003fc8:	6da2                	ld	s11,8(sp)
    80003fca:	6165                	addi	sp,sp,112
    80003fcc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fce:	8a5e                	mv	s4,s7
    80003fd0:	bfc9                	j	80003fa2 <writei+0xe2>
    return -1;
    80003fd2:	557d                	li	a0,-1
}
    80003fd4:	8082                	ret
    return -1;
    80003fd6:	557d                	li	a0,-1
    80003fd8:	bfe1                	j	80003fb0 <writei+0xf0>
    return -1;
    80003fda:	557d                	li	a0,-1
    80003fdc:	bfd1                	j	80003fb0 <writei+0xf0>

0000000080003fde <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fde:	1141                	addi	sp,sp,-16
    80003fe0:	e406                	sd	ra,8(sp)
    80003fe2:	e022                	sd	s0,0(sp)
    80003fe4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fe6:	4639                	li	a2,14
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	dd0080e7          	jalr	-560(ra) # 80000db8 <strncmp>
}
    80003ff0:	60a2                	ld	ra,8(sp)
    80003ff2:	6402                	ld	s0,0(sp)
    80003ff4:	0141                	addi	sp,sp,16
    80003ff6:	8082                	ret

0000000080003ff8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ff8:	7139                	addi	sp,sp,-64
    80003ffa:	fc06                	sd	ra,56(sp)
    80003ffc:	f822                	sd	s0,48(sp)
    80003ffe:	f426                	sd	s1,40(sp)
    80004000:	f04a                	sd	s2,32(sp)
    80004002:	ec4e                	sd	s3,24(sp)
    80004004:	e852                	sd	s4,16(sp)
    80004006:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004008:	04451703          	lh	a4,68(a0)
    8000400c:	4785                	li	a5,1
    8000400e:	00f71a63          	bne	a4,a5,80004022 <dirlookup+0x2a>
    80004012:	892a                	mv	s2,a0
    80004014:	89ae                	mv	s3,a1
    80004016:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004018:	457c                	lw	a5,76(a0)
    8000401a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000401c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000401e:	e79d                	bnez	a5,8000404c <dirlookup+0x54>
    80004020:	a8a5                	j	80004098 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004022:	00004517          	auipc	a0,0x4
    80004026:	69650513          	addi	a0,a0,1686 # 800086b8 <syscalls+0x1b8>
    8000402a:	ffffc097          	auipc	ra,0xffffc
    8000402e:	514080e7          	jalr	1300(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004032:	00004517          	auipc	a0,0x4
    80004036:	69e50513          	addi	a0,a0,1694 # 800086d0 <syscalls+0x1d0>
    8000403a:	ffffc097          	auipc	ra,0xffffc
    8000403e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004042:	24c1                	addiw	s1,s1,16
    80004044:	04c92783          	lw	a5,76(s2)
    80004048:	04f4f763          	bgeu	s1,a5,80004096 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000404c:	4741                	li	a4,16
    8000404e:	86a6                	mv	a3,s1
    80004050:	fc040613          	addi	a2,s0,-64
    80004054:	4581                	li	a1,0
    80004056:	854a                	mv	a0,s2
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	d70080e7          	jalr	-656(ra) # 80003dc8 <readi>
    80004060:	47c1                	li	a5,16
    80004062:	fcf518e3          	bne	a0,a5,80004032 <dirlookup+0x3a>
    if(de.inum == 0)
    80004066:	fc045783          	lhu	a5,-64(s0)
    8000406a:	dfe1                	beqz	a5,80004042 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000406c:	fc240593          	addi	a1,s0,-62
    80004070:	854e                	mv	a0,s3
    80004072:	00000097          	auipc	ra,0x0
    80004076:	f6c080e7          	jalr	-148(ra) # 80003fde <namecmp>
    8000407a:	f561                	bnez	a0,80004042 <dirlookup+0x4a>
      if(poff)
    8000407c:	000a0463          	beqz	s4,80004084 <dirlookup+0x8c>
        *poff = off;
    80004080:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004084:	fc045583          	lhu	a1,-64(s0)
    80004088:	00092503          	lw	a0,0(s2)
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	754080e7          	jalr	1876(ra) # 800037e0 <iget>
    80004094:	a011                	j	80004098 <dirlookup+0xa0>
  return 0;
    80004096:	4501                	li	a0,0
}
    80004098:	70e2                	ld	ra,56(sp)
    8000409a:	7442                	ld	s0,48(sp)
    8000409c:	74a2                	ld	s1,40(sp)
    8000409e:	7902                	ld	s2,32(sp)
    800040a0:	69e2                	ld	s3,24(sp)
    800040a2:	6a42                	ld	s4,16(sp)
    800040a4:	6121                	addi	sp,sp,64
    800040a6:	8082                	ret

00000000800040a8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040a8:	711d                	addi	sp,sp,-96
    800040aa:	ec86                	sd	ra,88(sp)
    800040ac:	e8a2                	sd	s0,80(sp)
    800040ae:	e4a6                	sd	s1,72(sp)
    800040b0:	e0ca                	sd	s2,64(sp)
    800040b2:	fc4e                	sd	s3,56(sp)
    800040b4:	f852                	sd	s4,48(sp)
    800040b6:	f456                	sd	s5,40(sp)
    800040b8:	f05a                	sd	s6,32(sp)
    800040ba:	ec5e                	sd	s7,24(sp)
    800040bc:	e862                	sd	s8,16(sp)
    800040be:	e466                	sd	s9,8(sp)
    800040c0:	1080                	addi	s0,sp,96
    800040c2:	84aa                	mv	s1,a0
    800040c4:	8b2e                	mv	s6,a1
    800040c6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040c8:	00054703          	lbu	a4,0(a0)
    800040cc:	02f00793          	li	a5,47
    800040d0:	02f70363          	beq	a4,a5,800040f6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040d4:	ffffe097          	auipc	ra,0xffffe
    800040d8:	900080e7          	jalr	-1792(ra) # 800019d4 <myproc>
    800040dc:	17053503          	ld	a0,368(a0)
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	9f6080e7          	jalr	-1546(ra) # 80003ad6 <idup>
    800040e8:	89aa                	mv	s3,a0
  while(*path == '/')
    800040ea:	02f00913          	li	s2,47
  len = path - s;
    800040ee:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040f0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040f2:	4c05                	li	s8,1
    800040f4:	a865                	j	800041ac <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040f6:	4585                	li	a1,1
    800040f8:	4505                	li	a0,1
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	6e6080e7          	jalr	1766(ra) # 800037e0 <iget>
    80004102:	89aa                	mv	s3,a0
    80004104:	b7dd                	j	800040ea <namex+0x42>
      iunlockput(ip);
    80004106:	854e                	mv	a0,s3
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	c6e080e7          	jalr	-914(ra) # 80003d76 <iunlockput>
      return 0;
    80004110:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004112:	854e                	mv	a0,s3
    80004114:	60e6                	ld	ra,88(sp)
    80004116:	6446                	ld	s0,80(sp)
    80004118:	64a6                	ld	s1,72(sp)
    8000411a:	6906                	ld	s2,64(sp)
    8000411c:	79e2                	ld	s3,56(sp)
    8000411e:	7a42                	ld	s4,48(sp)
    80004120:	7aa2                	ld	s5,40(sp)
    80004122:	7b02                	ld	s6,32(sp)
    80004124:	6be2                	ld	s7,24(sp)
    80004126:	6c42                	ld	s8,16(sp)
    80004128:	6ca2                	ld	s9,8(sp)
    8000412a:	6125                	addi	sp,sp,96
    8000412c:	8082                	ret
      iunlock(ip);
    8000412e:	854e                	mv	a0,s3
    80004130:	00000097          	auipc	ra,0x0
    80004134:	aa6080e7          	jalr	-1370(ra) # 80003bd6 <iunlock>
      return ip;
    80004138:	bfe9                	j	80004112 <namex+0x6a>
      iunlockput(ip);
    8000413a:	854e                	mv	a0,s3
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	c3a080e7          	jalr	-966(ra) # 80003d76 <iunlockput>
      return 0;
    80004144:	89d2                	mv	s3,s4
    80004146:	b7f1                	j	80004112 <namex+0x6a>
  len = path - s;
    80004148:	40b48633          	sub	a2,s1,a1
    8000414c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004150:	094cd463          	bge	s9,s4,800041d8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004154:	4639                	li	a2,14
    80004156:	8556                	mv	a0,s5
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	be8080e7          	jalr	-1048(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004160:	0004c783          	lbu	a5,0(s1)
    80004164:	01279763          	bne	a5,s2,80004172 <namex+0xca>
    path++;
    80004168:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000416a:	0004c783          	lbu	a5,0(s1)
    8000416e:	ff278de3          	beq	a5,s2,80004168 <namex+0xc0>
    ilock(ip);
    80004172:	854e                	mv	a0,s3
    80004174:	00000097          	auipc	ra,0x0
    80004178:	9a0080e7          	jalr	-1632(ra) # 80003b14 <ilock>
    if(ip->type != T_DIR){
    8000417c:	04499783          	lh	a5,68(s3)
    80004180:	f98793e3          	bne	a5,s8,80004106 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004184:	000b0563          	beqz	s6,8000418e <namex+0xe6>
    80004188:	0004c783          	lbu	a5,0(s1)
    8000418c:	d3cd                	beqz	a5,8000412e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000418e:	865e                	mv	a2,s7
    80004190:	85d6                	mv	a1,s5
    80004192:	854e                	mv	a0,s3
    80004194:	00000097          	auipc	ra,0x0
    80004198:	e64080e7          	jalr	-412(ra) # 80003ff8 <dirlookup>
    8000419c:	8a2a                	mv	s4,a0
    8000419e:	dd51                	beqz	a0,8000413a <namex+0x92>
    iunlockput(ip);
    800041a0:	854e                	mv	a0,s3
    800041a2:	00000097          	auipc	ra,0x0
    800041a6:	bd4080e7          	jalr	-1068(ra) # 80003d76 <iunlockput>
    ip = next;
    800041aa:	89d2                	mv	s3,s4
  while(*path == '/')
    800041ac:	0004c783          	lbu	a5,0(s1)
    800041b0:	05279763          	bne	a5,s2,800041fe <namex+0x156>
    path++;
    800041b4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041b6:	0004c783          	lbu	a5,0(s1)
    800041ba:	ff278de3          	beq	a5,s2,800041b4 <namex+0x10c>
  if(*path == 0)
    800041be:	c79d                	beqz	a5,800041ec <namex+0x144>
    path++;
    800041c0:	85a6                	mv	a1,s1
  len = path - s;
    800041c2:	8a5e                	mv	s4,s7
    800041c4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041c6:	01278963          	beq	a5,s2,800041d8 <namex+0x130>
    800041ca:	dfbd                	beqz	a5,80004148 <namex+0xa0>
    path++;
    800041cc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041ce:	0004c783          	lbu	a5,0(s1)
    800041d2:	ff279ce3          	bne	a5,s2,800041ca <namex+0x122>
    800041d6:	bf8d                	j	80004148 <namex+0xa0>
    memmove(name, s, len);
    800041d8:	2601                	sext.w	a2,a2
    800041da:	8556                	mv	a0,s5
    800041dc:	ffffd097          	auipc	ra,0xffffd
    800041e0:	b64080e7          	jalr	-1180(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041e4:	9a56                	add	s4,s4,s5
    800041e6:	000a0023          	sb	zero,0(s4)
    800041ea:	bf9d                	j	80004160 <namex+0xb8>
  if(nameiparent){
    800041ec:	f20b03e3          	beqz	s6,80004112 <namex+0x6a>
    iput(ip);
    800041f0:	854e                	mv	a0,s3
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	adc080e7          	jalr	-1316(ra) # 80003cce <iput>
    return 0;
    800041fa:	4981                	li	s3,0
    800041fc:	bf19                	j	80004112 <namex+0x6a>
  if(*path == 0)
    800041fe:	d7fd                	beqz	a5,800041ec <namex+0x144>
  while(*path != '/' && *path != 0)
    80004200:	0004c783          	lbu	a5,0(s1)
    80004204:	85a6                	mv	a1,s1
    80004206:	b7d1                	j	800041ca <namex+0x122>

0000000080004208 <dirlink>:
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	0080                	addi	s0,sp,64
    80004218:	892a                	mv	s2,a0
    8000421a:	8a2e                	mv	s4,a1
    8000421c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000421e:	4601                	li	a2,0
    80004220:	00000097          	auipc	ra,0x0
    80004224:	dd8080e7          	jalr	-552(ra) # 80003ff8 <dirlookup>
    80004228:	e93d                	bnez	a0,8000429e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000422a:	04c92483          	lw	s1,76(s2)
    8000422e:	c49d                	beqz	s1,8000425c <dirlink+0x54>
    80004230:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004232:	4741                	li	a4,16
    80004234:	86a6                	mv	a3,s1
    80004236:	fc040613          	addi	a2,s0,-64
    8000423a:	4581                	li	a1,0
    8000423c:	854a                	mv	a0,s2
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	b8a080e7          	jalr	-1142(ra) # 80003dc8 <readi>
    80004246:	47c1                	li	a5,16
    80004248:	06f51163          	bne	a0,a5,800042aa <dirlink+0xa2>
    if(de.inum == 0)
    8000424c:	fc045783          	lhu	a5,-64(s0)
    80004250:	c791                	beqz	a5,8000425c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004252:	24c1                	addiw	s1,s1,16
    80004254:	04c92783          	lw	a5,76(s2)
    80004258:	fcf4ede3          	bltu	s1,a5,80004232 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000425c:	4639                	li	a2,14
    8000425e:	85d2                	mv	a1,s4
    80004260:	fc240513          	addi	a0,s0,-62
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	b90080e7          	jalr	-1136(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000426c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004270:	4741                	li	a4,16
    80004272:	86a6                	mv	a3,s1
    80004274:	fc040613          	addi	a2,s0,-64
    80004278:	4581                	li	a1,0
    8000427a:	854a                	mv	a0,s2
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c44080e7          	jalr	-956(ra) # 80003ec0 <writei>
    80004284:	872a                	mv	a4,a0
    80004286:	47c1                	li	a5,16
  return 0;
    80004288:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000428a:	02f71863          	bne	a4,a5,800042ba <dirlink+0xb2>
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6121                	addi	sp,sp,64
    8000429c:	8082                	ret
    iput(ip);
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	a30080e7          	jalr	-1488(ra) # 80003cce <iput>
    return -1;
    800042a6:	557d                	li	a0,-1
    800042a8:	b7dd                	j	8000428e <dirlink+0x86>
      panic("dirlink read");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	43650513          	addi	a0,a0,1078 # 800086e0 <syscalls+0x1e0>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
    panic("dirlink");
    800042ba:	00004517          	auipc	a0,0x4
    800042be:	53650513          	addi	a0,a0,1334 # 800087f0 <syscalls+0x2f0>
    800042c2:	ffffc097          	auipc	ra,0xffffc
    800042c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>

00000000800042ca <namei>:

struct inode*
namei(char *path)
{
    800042ca:	1101                	addi	sp,sp,-32
    800042cc:	ec06                	sd	ra,24(sp)
    800042ce:	e822                	sd	s0,16(sp)
    800042d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042d2:	fe040613          	addi	a2,s0,-32
    800042d6:	4581                	li	a1,0
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	dd0080e7          	jalr	-560(ra) # 800040a8 <namex>
}
    800042e0:	60e2                	ld	ra,24(sp)
    800042e2:	6442                	ld	s0,16(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042e8:	1141                	addi	sp,sp,-16
    800042ea:	e406                	sd	ra,8(sp)
    800042ec:	e022                	sd	s0,0(sp)
    800042ee:	0800                	addi	s0,sp,16
    800042f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042f2:	4585                	li	a1,1
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	db4080e7          	jalr	-588(ra) # 800040a8 <namex>
}
    800042fc:	60a2                	ld	ra,8(sp)
    800042fe:	6402                	ld	s0,0(sp)
    80004300:	0141                	addi	sp,sp,16
    80004302:	8082                	ret

0000000080004304 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004304:	1101                	addi	sp,sp,-32
    80004306:	ec06                	sd	ra,24(sp)
    80004308:	e822                	sd	s0,16(sp)
    8000430a:	e426                	sd	s1,8(sp)
    8000430c:	e04a                	sd	s2,0(sp)
    8000430e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004310:	0001d917          	auipc	s2,0x1d
    80004314:	78090913          	addi	s2,s2,1920 # 80021a90 <log>
    80004318:	01892583          	lw	a1,24(s2)
    8000431c:	02892503          	lw	a0,40(s2)
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	ff2080e7          	jalr	-14(ra) # 80003312 <bread>
    80004328:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000432a:	02c92683          	lw	a3,44(s2)
    8000432e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004330:	02d05763          	blez	a3,8000435e <write_head+0x5a>
    80004334:	0001d797          	auipc	a5,0x1d
    80004338:	78c78793          	addi	a5,a5,1932 # 80021ac0 <log+0x30>
    8000433c:	05c50713          	addi	a4,a0,92
    80004340:	36fd                	addiw	a3,a3,-1
    80004342:	1682                	slli	a3,a3,0x20
    80004344:	9281                	srli	a3,a3,0x20
    80004346:	068a                	slli	a3,a3,0x2
    80004348:	0001d617          	auipc	a2,0x1d
    8000434c:	77c60613          	addi	a2,a2,1916 # 80021ac4 <log+0x34>
    80004350:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004352:	4390                	lw	a2,0(a5)
    80004354:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004356:	0791                	addi	a5,a5,4
    80004358:	0711                	addi	a4,a4,4
    8000435a:	fed79ce3          	bne	a5,a3,80004352 <write_head+0x4e>
  }
  bwrite(buf);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	0a4080e7          	jalr	164(ra) # 80003404 <bwrite>
  brelse(buf);
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	0d8080e7          	jalr	216(ra) # 80003442 <brelse>
}
    80004372:	60e2                	ld	ra,24(sp)
    80004374:	6442                	ld	s0,16(sp)
    80004376:	64a2                	ld	s1,8(sp)
    80004378:	6902                	ld	s2,0(sp)
    8000437a:	6105                	addi	sp,sp,32
    8000437c:	8082                	ret

000000008000437e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000437e:	0001d797          	auipc	a5,0x1d
    80004382:	73e7a783          	lw	a5,1854(a5) # 80021abc <log+0x2c>
    80004386:	0af05d63          	blez	a5,80004440 <install_trans+0xc2>
{
    8000438a:	7139                	addi	sp,sp,-64
    8000438c:	fc06                	sd	ra,56(sp)
    8000438e:	f822                	sd	s0,48(sp)
    80004390:	f426                	sd	s1,40(sp)
    80004392:	f04a                	sd	s2,32(sp)
    80004394:	ec4e                	sd	s3,24(sp)
    80004396:	e852                	sd	s4,16(sp)
    80004398:	e456                	sd	s5,8(sp)
    8000439a:	e05a                	sd	s6,0(sp)
    8000439c:	0080                	addi	s0,sp,64
    8000439e:	8b2a                	mv	s6,a0
    800043a0:	0001da97          	auipc	s5,0x1d
    800043a4:	720a8a93          	addi	s5,s5,1824 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043aa:	0001d997          	auipc	s3,0x1d
    800043ae:	6e698993          	addi	s3,s3,1766 # 80021a90 <log>
    800043b2:	a035                	j	800043de <install_trans+0x60>
      bunpin(dbuf);
    800043b4:	8526                	mv	a0,s1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	166080e7          	jalr	358(ra) # 8000351c <bunpin>
    brelse(lbuf);
    800043be:	854a                	mv	a0,s2
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	082080e7          	jalr	130(ra) # 80003442 <brelse>
    brelse(dbuf);
    800043c8:	8526                	mv	a0,s1
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	078080e7          	jalr	120(ra) # 80003442 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d2:	2a05                	addiw	s4,s4,1
    800043d4:	0a91                	addi	s5,s5,4
    800043d6:	02c9a783          	lw	a5,44(s3)
    800043da:	04fa5963          	bge	s4,a5,8000442c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043de:	0189a583          	lw	a1,24(s3)
    800043e2:	014585bb          	addw	a1,a1,s4
    800043e6:	2585                	addiw	a1,a1,1
    800043e8:	0289a503          	lw	a0,40(s3)
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	f26080e7          	jalr	-218(ra) # 80003312 <bread>
    800043f4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043f6:	000aa583          	lw	a1,0(s5)
    800043fa:	0289a503          	lw	a0,40(s3)
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	f14080e7          	jalr	-236(ra) # 80003312 <bread>
    80004406:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004408:	40000613          	li	a2,1024
    8000440c:	05890593          	addi	a1,s2,88
    80004410:	05850513          	addi	a0,a0,88
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	92c080e7          	jalr	-1748(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000441c:	8526                	mv	a0,s1
    8000441e:	fffff097          	auipc	ra,0xfffff
    80004422:	fe6080e7          	jalr	-26(ra) # 80003404 <bwrite>
    if(recovering == 0)
    80004426:	f80b1ce3          	bnez	s6,800043be <install_trans+0x40>
    8000442a:	b769                	j	800043b4 <install_trans+0x36>
}
    8000442c:	70e2                	ld	ra,56(sp)
    8000442e:	7442                	ld	s0,48(sp)
    80004430:	74a2                	ld	s1,40(sp)
    80004432:	7902                	ld	s2,32(sp)
    80004434:	69e2                	ld	s3,24(sp)
    80004436:	6a42                	ld	s4,16(sp)
    80004438:	6aa2                	ld	s5,8(sp)
    8000443a:	6b02                	ld	s6,0(sp)
    8000443c:	6121                	addi	sp,sp,64
    8000443e:	8082                	ret
    80004440:	8082                	ret

0000000080004442 <initlog>:
{
    80004442:	7179                	addi	sp,sp,-48
    80004444:	f406                	sd	ra,40(sp)
    80004446:	f022                	sd	s0,32(sp)
    80004448:	ec26                	sd	s1,24(sp)
    8000444a:	e84a                	sd	s2,16(sp)
    8000444c:	e44e                	sd	s3,8(sp)
    8000444e:	1800                	addi	s0,sp,48
    80004450:	892a                	mv	s2,a0
    80004452:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004454:	0001d497          	auipc	s1,0x1d
    80004458:	63c48493          	addi	s1,s1,1596 # 80021a90 <log>
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	29458593          	addi	a1,a1,660 # 800086f0 <syscalls+0x1f0>
    80004464:	8526                	mv	a0,s1
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	6ee080e7          	jalr	1774(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000446e:	0149a583          	lw	a1,20(s3)
    80004472:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004474:	0109a783          	lw	a5,16(s3)
    80004478:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000447a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000447e:	854a                	mv	a0,s2
    80004480:	fffff097          	auipc	ra,0xfffff
    80004484:	e92080e7          	jalr	-366(ra) # 80003312 <bread>
  log.lh.n = lh->n;
    80004488:	4d3c                	lw	a5,88(a0)
    8000448a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	02f05563          	blez	a5,800044b6 <initlog+0x74>
    80004490:	05c50713          	addi	a4,a0,92
    80004494:	0001d697          	auipc	a3,0x1d
    80004498:	62c68693          	addi	a3,a3,1580 # 80021ac0 <log+0x30>
    8000449c:	37fd                	addiw	a5,a5,-1
    8000449e:	1782                	slli	a5,a5,0x20
    800044a0:	9381                	srli	a5,a5,0x20
    800044a2:	078a                	slli	a5,a5,0x2
    800044a4:	06050613          	addi	a2,a0,96
    800044a8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044aa:	4310                	lw	a2,0(a4)
    800044ac:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044ae:	0711                	addi	a4,a4,4
    800044b0:	0691                	addi	a3,a3,4
    800044b2:	fef71ce3          	bne	a4,a5,800044aa <initlog+0x68>
  brelse(buf);
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	f8c080e7          	jalr	-116(ra) # 80003442 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044be:	4505                	li	a0,1
    800044c0:	00000097          	auipc	ra,0x0
    800044c4:	ebe080e7          	jalr	-322(ra) # 8000437e <install_trans>
  log.lh.n = 0;
    800044c8:	0001d797          	auipc	a5,0x1d
    800044cc:	5e07aa23          	sw	zero,1524(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	e34080e7          	jalr	-460(ra) # 80004304 <write_head>
}
    800044d8:	70a2                	ld	ra,40(sp)
    800044da:	7402                	ld	s0,32(sp)
    800044dc:	64e2                	ld	s1,24(sp)
    800044de:	6942                	ld	s2,16(sp)
    800044e0:	69a2                	ld	s3,8(sp)
    800044e2:	6145                	addi	sp,sp,48
    800044e4:	8082                	ret

00000000800044e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044f2:	0001d517          	auipc	a0,0x1d
    800044f6:	59e50513          	addi	a0,a0,1438 # 80021a90 <log>
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004502:	0001d497          	auipc	s1,0x1d
    80004506:	58e48493          	addi	s1,s1,1422 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000450a:	4979                	li	s2,30
    8000450c:	a039                	j	8000451a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000450e:	85a6                	mv	a1,s1
    80004510:	8526                	mv	a0,s1
    80004512:	ffffe097          	auipc	ra,0xffffe
    80004516:	e74080e7          	jalr	-396(ra) # 80002386 <sleep>
    if(log.committing){
    8000451a:	50dc                	lw	a5,36(s1)
    8000451c:	fbed                	bnez	a5,8000450e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000451e:	509c                	lw	a5,32(s1)
    80004520:	0017871b          	addiw	a4,a5,1
    80004524:	0007069b          	sext.w	a3,a4
    80004528:	0027179b          	slliw	a5,a4,0x2
    8000452c:	9fb9                	addw	a5,a5,a4
    8000452e:	0017979b          	slliw	a5,a5,0x1
    80004532:	54d8                	lw	a4,44(s1)
    80004534:	9fb9                	addw	a5,a5,a4
    80004536:	00f95963          	bge	s2,a5,80004548 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000453a:	85a6                	mv	a1,s1
    8000453c:	8526                	mv	a0,s1
    8000453e:	ffffe097          	auipc	ra,0xffffe
    80004542:	e48080e7          	jalr	-440(ra) # 80002386 <sleep>
    80004546:	bfd1                	j	8000451a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004548:	0001d517          	auipc	a0,0x1d
    8000454c:	54850513          	addi	a0,a0,1352 # 80021a90 <log>
    80004550:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6902                	ld	s2,0(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004566:	7139                	addi	sp,sp,-64
    80004568:	fc06                	sd	ra,56(sp)
    8000456a:	f822                	sd	s0,48(sp)
    8000456c:	f426                	sd	s1,40(sp)
    8000456e:	f04a                	sd	s2,32(sp)
    80004570:	ec4e                	sd	s3,24(sp)
    80004572:	e852                	sd	s4,16(sp)
    80004574:	e456                	sd	s5,8(sp)
    80004576:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004578:	0001d497          	auipc	s1,0x1d
    8000457c:	51848493          	addi	s1,s1,1304 # 80021a90 <log>
    80004580:	8526                	mv	a0,s1
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000458a:	509c                	lw	a5,32(s1)
    8000458c:	37fd                	addiw	a5,a5,-1
    8000458e:	0007891b          	sext.w	s2,a5
    80004592:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004594:	50dc                	lw	a5,36(s1)
    80004596:	efb9                	bnez	a5,800045f4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004598:	06091663          	bnez	s2,80004604 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000459c:	0001d497          	auipc	s1,0x1d
    800045a0:	4f448493          	addi	s1,s1,1268 # 80021a90 <log>
    800045a4:	4785                	li	a5,1
    800045a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045a8:	8526                	mv	a0,s1
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6ee080e7          	jalr	1774(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045b2:	54dc                	lw	a5,44(s1)
    800045b4:	06f04763          	bgtz	a5,80004622 <end_op+0xbc>
    acquire(&log.lock);
    800045b8:	0001d497          	auipc	s1,0x1d
    800045bc:	4d848493          	addi	s1,s1,1240 # 80021a90 <log>
    800045c0:	8526                	mv	a0,s1
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	622080e7          	jalr	1570(ra) # 80000be4 <acquire>
    log.committing = 0;
    800045ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045ce:	8526                	mv	a0,s1
    800045d0:	ffffe097          	auipc	ra,0xffffe
    800045d4:	f4c080e7          	jalr	-180(ra) # 8000251c <wakeup>
    release(&log.lock);
    800045d8:	8526                	mv	a0,s1
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
}
    800045e2:	70e2                	ld	ra,56(sp)
    800045e4:	7442                	ld	s0,48(sp)
    800045e6:	74a2                	ld	s1,40(sp)
    800045e8:	7902                	ld	s2,32(sp)
    800045ea:	69e2                	ld	s3,24(sp)
    800045ec:	6a42                	ld	s4,16(sp)
    800045ee:	6aa2                	ld	s5,8(sp)
    800045f0:	6121                	addi	sp,sp,64
    800045f2:	8082                	ret
    panic("log.committing");
    800045f4:	00004517          	auipc	a0,0x4
    800045f8:	10450513          	addi	a0,a0,260 # 800086f8 <syscalls+0x1f8>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>
    wakeup(&log);
    80004604:	0001d497          	auipc	s1,0x1d
    80004608:	48c48493          	addi	s1,s1,1164 # 80021a90 <log>
    8000460c:	8526                	mv	a0,s1
    8000460e:	ffffe097          	auipc	ra,0xffffe
    80004612:	f0e080e7          	jalr	-242(ra) # 8000251c <wakeup>
  release(&log.lock);
    80004616:	8526                	mv	a0,s1
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
  if(do_commit){
    80004620:	b7c9                	j	800045e2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004622:	0001da97          	auipc	s5,0x1d
    80004626:	49ea8a93          	addi	s5,s5,1182 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000462a:	0001da17          	auipc	s4,0x1d
    8000462e:	466a0a13          	addi	s4,s4,1126 # 80021a90 <log>
    80004632:	018a2583          	lw	a1,24(s4)
    80004636:	012585bb          	addw	a1,a1,s2
    8000463a:	2585                	addiw	a1,a1,1
    8000463c:	028a2503          	lw	a0,40(s4)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	cd2080e7          	jalr	-814(ra) # 80003312 <bread>
    80004648:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000464a:	000aa583          	lw	a1,0(s5)
    8000464e:	028a2503          	lw	a0,40(s4)
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	cc0080e7          	jalr	-832(ra) # 80003312 <bread>
    8000465a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000465c:	40000613          	li	a2,1024
    80004660:	05850593          	addi	a1,a0,88
    80004664:	05848513          	addi	a0,s1,88
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	6d8080e7          	jalr	1752(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004670:	8526                	mv	a0,s1
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	d92080e7          	jalr	-622(ra) # 80003404 <bwrite>
    brelse(from);
    8000467a:	854e                	mv	a0,s3
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	dc6080e7          	jalr	-570(ra) # 80003442 <brelse>
    brelse(to);
    80004684:	8526                	mv	a0,s1
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	dbc080e7          	jalr	-580(ra) # 80003442 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468e:	2905                	addiw	s2,s2,1
    80004690:	0a91                	addi	s5,s5,4
    80004692:	02ca2783          	lw	a5,44(s4)
    80004696:	f8f94ee3          	blt	s2,a5,80004632 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000469a:	00000097          	auipc	ra,0x0
    8000469e:	c6a080e7          	jalr	-918(ra) # 80004304 <write_head>
    install_trans(0); // Now install writes to home locations
    800046a2:	4501                	li	a0,0
    800046a4:	00000097          	auipc	ra,0x0
    800046a8:	cda080e7          	jalr	-806(ra) # 8000437e <install_trans>
    log.lh.n = 0;
    800046ac:	0001d797          	auipc	a5,0x1d
    800046b0:	4007a823          	sw	zero,1040(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	c50080e7          	jalr	-944(ra) # 80004304 <write_head>
    800046bc:	bdf5                	j	800045b8 <end_op+0x52>

00000000800046be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046be:	1101                	addi	sp,sp,-32
    800046c0:	ec06                	sd	ra,24(sp)
    800046c2:	e822                	sd	s0,16(sp)
    800046c4:	e426                	sd	s1,8(sp)
    800046c6:	e04a                	sd	s2,0(sp)
    800046c8:	1000                	addi	s0,sp,32
    800046ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046cc:	0001d917          	auipc	s2,0x1d
    800046d0:	3c490913          	addi	s2,s2,964 # 80021a90 <log>
    800046d4:	854a                	mv	a0,s2
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	50e080e7          	jalr	1294(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046de:	02c92603          	lw	a2,44(s2)
    800046e2:	47f5                	li	a5,29
    800046e4:	06c7c563          	blt	a5,a2,8000474e <log_write+0x90>
    800046e8:	0001d797          	auipc	a5,0x1d
    800046ec:	3c47a783          	lw	a5,964(a5) # 80021aac <log+0x1c>
    800046f0:	37fd                	addiw	a5,a5,-1
    800046f2:	04f65e63          	bge	a2,a5,8000474e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046f6:	0001d797          	auipc	a5,0x1d
    800046fa:	3ba7a783          	lw	a5,954(a5) # 80021ab0 <log+0x20>
    800046fe:	06f05063          	blez	a5,8000475e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004702:	4781                	li	a5,0
    80004704:	06c05563          	blez	a2,8000476e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004708:	44cc                	lw	a1,12(s1)
    8000470a:	0001d717          	auipc	a4,0x1d
    8000470e:	3b670713          	addi	a4,a4,950 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004712:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004714:	4314                	lw	a3,0(a4)
    80004716:	04b68c63          	beq	a3,a1,8000476e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000471a:	2785                	addiw	a5,a5,1
    8000471c:	0711                	addi	a4,a4,4
    8000471e:	fef61be3          	bne	a2,a5,80004714 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004722:	0621                	addi	a2,a2,8
    80004724:	060a                	slli	a2,a2,0x2
    80004726:	0001d797          	auipc	a5,0x1d
    8000472a:	36a78793          	addi	a5,a5,874 # 80021a90 <log>
    8000472e:	963e                	add	a2,a2,a5
    80004730:	44dc                	lw	a5,12(s1)
    80004732:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004734:	8526                	mv	a0,s1
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	daa080e7          	jalr	-598(ra) # 800034e0 <bpin>
    log.lh.n++;
    8000473e:	0001d717          	auipc	a4,0x1d
    80004742:	35270713          	addi	a4,a4,850 # 80021a90 <log>
    80004746:	575c                	lw	a5,44(a4)
    80004748:	2785                	addiw	a5,a5,1
    8000474a:	d75c                	sw	a5,44(a4)
    8000474c:	a835                	j	80004788 <log_write+0xca>
    panic("too big a transaction");
    8000474e:	00004517          	auipc	a0,0x4
    80004752:	fba50513          	addi	a0,a0,-70 # 80008708 <syscalls+0x208>
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	de8080e7          	jalr	-536(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000475e:	00004517          	auipc	a0,0x4
    80004762:	fc250513          	addi	a0,a0,-62 # 80008720 <syscalls+0x220>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	dd8080e7          	jalr	-552(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000476e:	00878713          	addi	a4,a5,8
    80004772:	00271693          	slli	a3,a4,0x2
    80004776:	0001d717          	auipc	a4,0x1d
    8000477a:	31a70713          	addi	a4,a4,794 # 80021a90 <log>
    8000477e:	9736                	add	a4,a4,a3
    80004780:	44d4                	lw	a3,12(s1)
    80004782:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004784:	faf608e3          	beq	a2,a5,80004734 <log_write+0x76>
  }
  release(&log.lock);
    80004788:	0001d517          	auipc	a0,0x1d
    8000478c:	30850513          	addi	a0,a0,776 # 80021a90 <log>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	508080e7          	jalr	1288(ra) # 80000c98 <release>
}
    80004798:	60e2                	ld	ra,24(sp)
    8000479a:	6442                	ld	s0,16(sp)
    8000479c:	64a2                	ld	s1,8(sp)
    8000479e:	6902                	ld	s2,0(sp)
    800047a0:	6105                	addi	sp,sp,32
    800047a2:	8082                	ret

00000000800047a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047a4:	1101                	addi	sp,sp,-32
    800047a6:	ec06                	sd	ra,24(sp)
    800047a8:	e822                	sd	s0,16(sp)
    800047aa:	e426                	sd	s1,8(sp)
    800047ac:	e04a                	sd	s2,0(sp)
    800047ae:	1000                	addi	s0,sp,32
    800047b0:	84aa                	mv	s1,a0
    800047b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047b4:	00004597          	auipc	a1,0x4
    800047b8:	f8c58593          	addi	a1,a1,-116 # 80008740 <syscalls+0x240>
    800047bc:	0521                	addi	a0,a0,8
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	396080e7          	jalr	918(ra) # 80000b54 <initlock>
  lk->name = name;
    800047c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ce:	0204a423          	sw	zero,40(s1)
}
    800047d2:	60e2                	ld	ra,24(sp)
    800047d4:	6442                	ld	s0,16(sp)
    800047d6:	64a2                	ld	s1,8(sp)
    800047d8:	6902                	ld	s2,0(sp)
    800047da:	6105                	addi	sp,sp,32
    800047dc:	8082                	ret

00000000800047de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047de:	1101                	addi	sp,sp,-32
    800047e0:	ec06                	sd	ra,24(sp)
    800047e2:	e822                	sd	s0,16(sp)
    800047e4:	e426                	sd	s1,8(sp)
    800047e6:	e04a                	sd	s2,0(sp)
    800047e8:	1000                	addi	s0,sp,32
    800047ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ec:	00850913          	addi	s2,a0,8
    800047f0:	854a                	mv	a0,s2
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047fa:	409c                	lw	a5,0(s1)
    800047fc:	cb89                	beqz	a5,8000480e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047fe:	85ca                	mv	a1,s2
    80004800:	8526                	mv	a0,s1
    80004802:	ffffe097          	auipc	ra,0xffffe
    80004806:	b84080e7          	jalr	-1148(ra) # 80002386 <sleep>
  while (lk->locked) {
    8000480a:	409c                	lw	a5,0(s1)
    8000480c:	fbed                	bnez	a5,800047fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000480e:	4785                	li	a5,1
    80004810:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004812:	ffffd097          	auipc	ra,0xffffd
    80004816:	1c2080e7          	jalr	450(ra) # 800019d4 <myproc>
    8000481a:	591c                	lw	a5,48(a0)
    8000481c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000481e:	854a                	mv	a0,s2
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	478080e7          	jalr	1144(ra) # 80000c98 <release>
}
    80004828:	60e2                	ld	ra,24(sp)
    8000482a:	6442                	ld	s0,16(sp)
    8000482c:	64a2                	ld	s1,8(sp)
    8000482e:	6902                	ld	s2,0(sp)
    80004830:	6105                	addi	sp,sp,32
    80004832:	8082                	ret

0000000080004834 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004834:	1101                	addi	sp,sp,-32
    80004836:	ec06                	sd	ra,24(sp)
    80004838:	e822                	sd	s0,16(sp)
    8000483a:	e426                	sd	s1,8(sp)
    8000483c:	e04a                	sd	s2,0(sp)
    8000483e:	1000                	addi	s0,sp,32
    80004840:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004842:	00850913          	addi	s2,a0,8
    80004846:	854a                	mv	a0,s2
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	39c080e7          	jalr	924(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004850:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004854:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004858:	8526                	mv	a0,s1
    8000485a:	ffffe097          	auipc	ra,0xffffe
    8000485e:	cc2080e7          	jalr	-830(ra) # 8000251c <wakeup>
  release(&lk->lk);
    80004862:	854a                	mv	a0,s2
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	434080e7          	jalr	1076(ra) # 80000c98 <release>
}
    8000486c:	60e2                	ld	ra,24(sp)
    8000486e:	6442                	ld	s0,16(sp)
    80004870:	64a2                	ld	s1,8(sp)
    80004872:	6902                	ld	s2,0(sp)
    80004874:	6105                	addi	sp,sp,32
    80004876:	8082                	ret

0000000080004878 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004878:	7179                	addi	sp,sp,-48
    8000487a:	f406                	sd	ra,40(sp)
    8000487c:	f022                	sd	s0,32(sp)
    8000487e:	ec26                	sd	s1,24(sp)
    80004880:	e84a                	sd	s2,16(sp)
    80004882:	e44e                	sd	s3,8(sp)
    80004884:	1800                	addi	s0,sp,48
    80004886:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004888:	00850913          	addi	s2,a0,8
    8000488c:	854a                	mv	a0,s2
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	356080e7          	jalr	854(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004896:	409c                	lw	a5,0(s1)
    80004898:	ef99                	bnez	a5,800048b6 <holdingsleep+0x3e>
    8000489a:	4481                	li	s1,0
  release(&lk->lk);
    8000489c:	854a                	mv	a0,s2
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
  return r;
}
    800048a6:	8526                	mv	a0,s1
    800048a8:	70a2                	ld	ra,40(sp)
    800048aa:	7402                	ld	s0,32(sp)
    800048ac:	64e2                	ld	s1,24(sp)
    800048ae:	6942                	ld	s2,16(sp)
    800048b0:	69a2                	ld	s3,8(sp)
    800048b2:	6145                	addi	sp,sp,48
    800048b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048b6:	0284a983          	lw	s3,40(s1)
    800048ba:	ffffd097          	auipc	ra,0xffffd
    800048be:	11a080e7          	jalr	282(ra) # 800019d4 <myproc>
    800048c2:	5904                	lw	s1,48(a0)
    800048c4:	413484b3          	sub	s1,s1,s3
    800048c8:	0014b493          	seqz	s1,s1
    800048cc:	bfc1                	j	8000489c <holdingsleep+0x24>

00000000800048ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048ce:	1141                	addi	sp,sp,-16
    800048d0:	e406                	sd	ra,8(sp)
    800048d2:	e022                	sd	s0,0(sp)
    800048d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048d6:	00004597          	auipc	a1,0x4
    800048da:	e7a58593          	addi	a1,a1,-390 # 80008750 <syscalls+0x250>
    800048de:	0001d517          	auipc	a0,0x1d
    800048e2:	2fa50513          	addi	a0,a0,762 # 80021bd8 <ftable>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	26e080e7          	jalr	622(ra) # 80000b54 <initlock>
}
    800048ee:	60a2                	ld	ra,8(sp)
    800048f0:	6402                	ld	s0,0(sp)
    800048f2:	0141                	addi	sp,sp,16
    800048f4:	8082                	ret

00000000800048f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004900:	0001d517          	auipc	a0,0x1d
    80004904:	2d850513          	addi	a0,a0,728 # 80021bd8 <ftable>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	2dc080e7          	jalr	732(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004910:	0001d497          	auipc	s1,0x1d
    80004914:	2e048493          	addi	s1,s1,736 # 80021bf0 <ftable+0x18>
    80004918:	0001e717          	auipc	a4,0x1e
    8000491c:	27870713          	addi	a4,a4,632 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004920:	40dc                	lw	a5,4(s1)
    80004922:	cf99                	beqz	a5,80004940 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004924:	02848493          	addi	s1,s1,40
    80004928:	fee49ce3          	bne	s1,a4,80004920 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000492c:	0001d517          	auipc	a0,0x1d
    80004930:	2ac50513          	addi	a0,a0,684 # 80021bd8 <ftable>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	364080e7          	jalr	868(ra) # 80000c98 <release>
  return 0;
    8000493c:	4481                	li	s1,0
    8000493e:	a819                	j	80004954 <filealloc+0x5e>
      f->ref = 1;
    80004940:	4785                	li	a5,1
    80004942:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004944:	0001d517          	auipc	a0,0x1d
    80004948:	29450513          	addi	a0,a0,660 # 80021bd8 <ftable>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	34c080e7          	jalr	844(ra) # 80000c98 <release>
}
    80004954:	8526                	mv	a0,s1
    80004956:	60e2                	ld	ra,24(sp)
    80004958:	6442                	ld	s0,16(sp)
    8000495a:	64a2                	ld	s1,8(sp)
    8000495c:	6105                	addi	sp,sp,32
    8000495e:	8082                	ret

0000000080004960 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004960:	1101                	addi	sp,sp,-32
    80004962:	ec06                	sd	ra,24(sp)
    80004964:	e822                	sd	s0,16(sp)
    80004966:	e426                	sd	s1,8(sp)
    80004968:	1000                	addi	s0,sp,32
    8000496a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000496c:	0001d517          	auipc	a0,0x1d
    80004970:	26c50513          	addi	a0,a0,620 # 80021bd8 <ftable>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	270080e7          	jalr	624(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000497c:	40dc                	lw	a5,4(s1)
    8000497e:	02f05263          	blez	a5,800049a2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004982:	2785                	addiw	a5,a5,1
    80004984:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004986:	0001d517          	auipc	a0,0x1d
    8000498a:	25250513          	addi	a0,a0,594 # 80021bd8 <ftable>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
  return f;
}
    80004996:	8526                	mv	a0,s1
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6105                	addi	sp,sp,32
    800049a0:	8082                	ret
    panic("filedup");
    800049a2:	00004517          	auipc	a0,0x4
    800049a6:	db650513          	addi	a0,a0,-586 # 80008758 <syscalls+0x258>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>

00000000800049b2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049b2:	7139                	addi	sp,sp,-64
    800049b4:	fc06                	sd	ra,56(sp)
    800049b6:	f822                	sd	s0,48(sp)
    800049b8:	f426                	sd	s1,40(sp)
    800049ba:	f04a                	sd	s2,32(sp)
    800049bc:	ec4e                	sd	s3,24(sp)
    800049be:	e852                	sd	s4,16(sp)
    800049c0:	e456                	sd	s5,8(sp)
    800049c2:	0080                	addi	s0,sp,64
    800049c4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049c6:	0001d517          	auipc	a0,0x1d
    800049ca:	21250513          	addi	a0,a0,530 # 80021bd8 <ftable>
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	216080e7          	jalr	534(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049d6:	40dc                	lw	a5,4(s1)
    800049d8:	06f05163          	blez	a5,80004a3a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049dc:	37fd                	addiw	a5,a5,-1
    800049de:	0007871b          	sext.w	a4,a5
    800049e2:	c0dc                	sw	a5,4(s1)
    800049e4:	06e04363          	bgtz	a4,80004a4a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049e8:	0004a903          	lw	s2,0(s1)
    800049ec:	0094ca83          	lbu	s5,9(s1)
    800049f0:	0104ba03          	ld	s4,16(s1)
    800049f4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049f8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049fc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a00:	0001d517          	auipc	a0,0x1d
    80004a04:	1d850513          	addi	a0,a0,472 # 80021bd8 <ftable>
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a10:	4785                	li	a5,1
    80004a12:	04f90d63          	beq	s2,a5,80004a6c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a16:	3979                	addiw	s2,s2,-2
    80004a18:	4785                	li	a5,1
    80004a1a:	0527e063          	bltu	a5,s2,80004a5a <fileclose+0xa8>
    begin_op();
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	ac8080e7          	jalr	-1336(ra) # 800044e6 <begin_op>
    iput(ff.ip);
    80004a26:	854e                	mv	a0,s3
    80004a28:	fffff097          	auipc	ra,0xfffff
    80004a2c:	2a6080e7          	jalr	678(ra) # 80003cce <iput>
    end_op();
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	b36080e7          	jalr	-1226(ra) # 80004566 <end_op>
    80004a38:	a00d                	j	80004a5a <fileclose+0xa8>
    panic("fileclose");
    80004a3a:	00004517          	auipc	a0,0x4
    80004a3e:	d2650513          	addi	a0,a0,-730 # 80008760 <syscalls+0x260>
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	afc080e7          	jalr	-1284(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a4a:	0001d517          	auipc	a0,0x1d
    80004a4e:	18e50513          	addi	a0,a0,398 # 80021bd8 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
  }
}
    80004a5a:	70e2                	ld	ra,56(sp)
    80004a5c:	7442                	ld	s0,48(sp)
    80004a5e:	74a2                	ld	s1,40(sp)
    80004a60:	7902                	ld	s2,32(sp)
    80004a62:	69e2                	ld	s3,24(sp)
    80004a64:	6a42                	ld	s4,16(sp)
    80004a66:	6aa2                	ld	s5,8(sp)
    80004a68:	6121                	addi	sp,sp,64
    80004a6a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a6c:	85d6                	mv	a1,s5
    80004a6e:	8552                	mv	a0,s4
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	34c080e7          	jalr	844(ra) # 80004dbc <pipeclose>
    80004a78:	b7cd                	j	80004a5a <fileclose+0xa8>

0000000080004a7a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a7a:	715d                	addi	sp,sp,-80
    80004a7c:	e486                	sd	ra,72(sp)
    80004a7e:	e0a2                	sd	s0,64(sp)
    80004a80:	fc26                	sd	s1,56(sp)
    80004a82:	f84a                	sd	s2,48(sp)
    80004a84:	f44e                	sd	s3,40(sp)
    80004a86:	0880                	addi	s0,sp,80
    80004a88:	84aa                	mv	s1,a0
    80004a8a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	f48080e7          	jalr	-184(ra) # 800019d4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a94:	409c                	lw	a5,0(s1)
    80004a96:	37f9                	addiw	a5,a5,-2
    80004a98:	4705                	li	a4,1
    80004a9a:	04f76763          	bltu	a4,a5,80004ae8 <filestat+0x6e>
    80004a9e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004aa0:	6c88                	ld	a0,24(s1)
    80004aa2:	fffff097          	auipc	ra,0xfffff
    80004aa6:	072080e7          	jalr	114(ra) # 80003b14 <ilock>
    stati(f->ip, &st);
    80004aaa:	fb840593          	addi	a1,s0,-72
    80004aae:	6c88                	ld	a0,24(s1)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	2ee080e7          	jalr	750(ra) # 80003d9e <stati>
    iunlock(f->ip);
    80004ab8:	6c88                	ld	a0,24(s1)
    80004aba:	fffff097          	auipc	ra,0xfffff
    80004abe:	11c080e7          	jalr	284(ra) # 80003bd6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ac2:	46e1                	li	a3,24
    80004ac4:	fb840613          	addi	a2,s0,-72
    80004ac8:	85ce                	mv	a1,s3
    80004aca:	07093503          	ld	a0,112(s2)
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	bac080e7          	jalr	-1108(ra) # 8000167a <copyout>
    80004ad6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ada:	60a6                	ld	ra,72(sp)
    80004adc:	6406                	ld	s0,64(sp)
    80004ade:	74e2                	ld	s1,56(sp)
    80004ae0:	7942                	ld	s2,48(sp)
    80004ae2:	79a2                	ld	s3,40(sp)
    80004ae4:	6161                	addi	sp,sp,80
    80004ae6:	8082                	ret
  return -1;
    80004ae8:	557d                	li	a0,-1
    80004aea:	bfc5                	j	80004ada <filestat+0x60>

0000000080004aec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aec:	7179                	addi	sp,sp,-48
    80004aee:	f406                	sd	ra,40(sp)
    80004af0:	f022                	sd	s0,32(sp)
    80004af2:	ec26                	sd	s1,24(sp)
    80004af4:	e84a                	sd	s2,16(sp)
    80004af6:	e44e                	sd	s3,8(sp)
    80004af8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004afa:	00854783          	lbu	a5,8(a0)
    80004afe:	c3d5                	beqz	a5,80004ba2 <fileread+0xb6>
    80004b00:	84aa                	mv	s1,a0
    80004b02:	89ae                	mv	s3,a1
    80004b04:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b06:	411c                	lw	a5,0(a0)
    80004b08:	4705                	li	a4,1
    80004b0a:	04e78963          	beq	a5,a4,80004b5c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b0e:	470d                	li	a4,3
    80004b10:	04e78d63          	beq	a5,a4,80004b6a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b14:	4709                	li	a4,2
    80004b16:	06e79e63          	bne	a5,a4,80004b92 <fileread+0xa6>
    ilock(f->ip);
    80004b1a:	6d08                	ld	a0,24(a0)
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	ff8080e7          	jalr	-8(ra) # 80003b14 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b24:	874a                	mv	a4,s2
    80004b26:	5094                	lw	a3,32(s1)
    80004b28:	864e                	mv	a2,s3
    80004b2a:	4585                	li	a1,1
    80004b2c:	6c88                	ld	a0,24(s1)
    80004b2e:	fffff097          	auipc	ra,0xfffff
    80004b32:	29a080e7          	jalr	666(ra) # 80003dc8 <readi>
    80004b36:	892a                	mv	s2,a0
    80004b38:	00a05563          	blez	a0,80004b42 <fileread+0x56>
      f->off += r;
    80004b3c:	509c                	lw	a5,32(s1)
    80004b3e:	9fa9                	addw	a5,a5,a0
    80004b40:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b42:	6c88                	ld	a0,24(s1)
    80004b44:	fffff097          	auipc	ra,0xfffff
    80004b48:	092080e7          	jalr	146(ra) # 80003bd6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b4c:	854a                	mv	a0,s2
    80004b4e:	70a2                	ld	ra,40(sp)
    80004b50:	7402                	ld	s0,32(sp)
    80004b52:	64e2                	ld	s1,24(sp)
    80004b54:	6942                	ld	s2,16(sp)
    80004b56:	69a2                	ld	s3,8(sp)
    80004b58:	6145                	addi	sp,sp,48
    80004b5a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b5c:	6908                	ld	a0,16(a0)
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	3c8080e7          	jalr	968(ra) # 80004f26 <piperead>
    80004b66:	892a                	mv	s2,a0
    80004b68:	b7d5                	j	80004b4c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b6a:	02451783          	lh	a5,36(a0)
    80004b6e:	03079693          	slli	a3,a5,0x30
    80004b72:	92c1                	srli	a3,a3,0x30
    80004b74:	4725                	li	a4,9
    80004b76:	02d76863          	bltu	a4,a3,80004ba6 <fileread+0xba>
    80004b7a:	0792                	slli	a5,a5,0x4
    80004b7c:	0001d717          	auipc	a4,0x1d
    80004b80:	fbc70713          	addi	a4,a4,-68 # 80021b38 <devsw>
    80004b84:	97ba                	add	a5,a5,a4
    80004b86:	639c                	ld	a5,0(a5)
    80004b88:	c38d                	beqz	a5,80004baa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b8a:	4505                	li	a0,1
    80004b8c:	9782                	jalr	a5
    80004b8e:	892a                	mv	s2,a0
    80004b90:	bf75                	j	80004b4c <fileread+0x60>
    panic("fileread");
    80004b92:	00004517          	auipc	a0,0x4
    80004b96:	bde50513          	addi	a0,a0,-1058 # 80008770 <syscalls+0x270>
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>
    return -1;
    80004ba2:	597d                	li	s2,-1
    80004ba4:	b765                	j	80004b4c <fileread+0x60>
      return -1;
    80004ba6:	597d                	li	s2,-1
    80004ba8:	b755                	j	80004b4c <fileread+0x60>
    80004baa:	597d                	li	s2,-1
    80004bac:	b745                	j	80004b4c <fileread+0x60>

0000000080004bae <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bae:	715d                	addi	sp,sp,-80
    80004bb0:	e486                	sd	ra,72(sp)
    80004bb2:	e0a2                	sd	s0,64(sp)
    80004bb4:	fc26                	sd	s1,56(sp)
    80004bb6:	f84a                	sd	s2,48(sp)
    80004bb8:	f44e                	sd	s3,40(sp)
    80004bba:	f052                	sd	s4,32(sp)
    80004bbc:	ec56                	sd	s5,24(sp)
    80004bbe:	e85a                	sd	s6,16(sp)
    80004bc0:	e45e                	sd	s7,8(sp)
    80004bc2:	e062                	sd	s8,0(sp)
    80004bc4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bc6:	00954783          	lbu	a5,9(a0)
    80004bca:	10078663          	beqz	a5,80004cd6 <filewrite+0x128>
    80004bce:	892a                	mv	s2,a0
    80004bd0:	8aae                	mv	s5,a1
    80004bd2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd4:	411c                	lw	a5,0(a0)
    80004bd6:	4705                	li	a4,1
    80004bd8:	02e78263          	beq	a5,a4,80004bfc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bdc:	470d                	li	a4,3
    80004bde:	02e78663          	beq	a5,a4,80004c0a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be2:	4709                	li	a4,2
    80004be4:	0ee79163          	bne	a5,a4,80004cc6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004be8:	0ac05d63          	blez	a2,80004ca2 <filewrite+0xf4>
    int i = 0;
    80004bec:	4981                	li	s3,0
    80004bee:	6b05                	lui	s6,0x1
    80004bf0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bf4:	6b85                	lui	s7,0x1
    80004bf6:	c00b8b9b          	addiw	s7,s7,-1024
    80004bfa:	a861                	j	80004c92 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bfc:	6908                	ld	a0,16(a0)
    80004bfe:	00000097          	auipc	ra,0x0
    80004c02:	22e080e7          	jalr	558(ra) # 80004e2c <pipewrite>
    80004c06:	8a2a                	mv	s4,a0
    80004c08:	a045                	j	80004ca8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c0a:	02451783          	lh	a5,36(a0)
    80004c0e:	03079693          	slli	a3,a5,0x30
    80004c12:	92c1                	srli	a3,a3,0x30
    80004c14:	4725                	li	a4,9
    80004c16:	0cd76263          	bltu	a4,a3,80004cda <filewrite+0x12c>
    80004c1a:	0792                	slli	a5,a5,0x4
    80004c1c:	0001d717          	auipc	a4,0x1d
    80004c20:	f1c70713          	addi	a4,a4,-228 # 80021b38 <devsw>
    80004c24:	97ba                	add	a5,a5,a4
    80004c26:	679c                	ld	a5,8(a5)
    80004c28:	cbdd                	beqz	a5,80004cde <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c2a:	4505                	li	a0,1
    80004c2c:	9782                	jalr	a5
    80004c2e:	8a2a                	mv	s4,a0
    80004c30:	a8a5                	j	80004ca8 <filewrite+0xfa>
    80004c32:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c36:	00000097          	auipc	ra,0x0
    80004c3a:	8b0080e7          	jalr	-1872(ra) # 800044e6 <begin_op>
      ilock(f->ip);
    80004c3e:	01893503          	ld	a0,24(s2)
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	ed2080e7          	jalr	-302(ra) # 80003b14 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c4a:	8762                	mv	a4,s8
    80004c4c:	02092683          	lw	a3,32(s2)
    80004c50:	01598633          	add	a2,s3,s5
    80004c54:	4585                	li	a1,1
    80004c56:	01893503          	ld	a0,24(s2)
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	266080e7          	jalr	614(ra) # 80003ec0 <writei>
    80004c62:	84aa                	mv	s1,a0
    80004c64:	00a05763          	blez	a0,80004c72 <filewrite+0xc4>
        f->off += r;
    80004c68:	02092783          	lw	a5,32(s2)
    80004c6c:	9fa9                	addw	a5,a5,a0
    80004c6e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c72:	01893503          	ld	a0,24(s2)
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	f60080e7          	jalr	-160(ra) # 80003bd6 <iunlock>
      end_op();
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	8e8080e7          	jalr	-1816(ra) # 80004566 <end_op>

      if(r != n1){
    80004c86:	009c1f63          	bne	s8,s1,80004ca4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c8a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c8e:	0149db63          	bge	s3,s4,80004ca4 <filewrite+0xf6>
      int n1 = n - i;
    80004c92:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c96:	84be                	mv	s1,a5
    80004c98:	2781                	sext.w	a5,a5
    80004c9a:	f8fb5ce3          	bge	s6,a5,80004c32 <filewrite+0x84>
    80004c9e:	84de                	mv	s1,s7
    80004ca0:	bf49                	j	80004c32 <filewrite+0x84>
    int i = 0;
    80004ca2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ca4:	013a1f63          	bne	s4,s3,80004cc2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ca8:	8552                	mv	a0,s4
    80004caa:	60a6                	ld	ra,72(sp)
    80004cac:	6406                	ld	s0,64(sp)
    80004cae:	74e2                	ld	s1,56(sp)
    80004cb0:	7942                	ld	s2,48(sp)
    80004cb2:	79a2                	ld	s3,40(sp)
    80004cb4:	7a02                	ld	s4,32(sp)
    80004cb6:	6ae2                	ld	s5,24(sp)
    80004cb8:	6b42                	ld	s6,16(sp)
    80004cba:	6ba2                	ld	s7,8(sp)
    80004cbc:	6c02                	ld	s8,0(sp)
    80004cbe:	6161                	addi	sp,sp,80
    80004cc0:	8082                	ret
    ret = (i == n ? n : -1);
    80004cc2:	5a7d                	li	s4,-1
    80004cc4:	b7d5                	j	80004ca8 <filewrite+0xfa>
    panic("filewrite");
    80004cc6:	00004517          	auipc	a0,0x4
    80004cca:	aba50513          	addi	a0,a0,-1350 # 80008780 <syscalls+0x280>
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>
    return -1;
    80004cd6:	5a7d                	li	s4,-1
    80004cd8:	bfc1                	j	80004ca8 <filewrite+0xfa>
      return -1;
    80004cda:	5a7d                	li	s4,-1
    80004cdc:	b7f1                	j	80004ca8 <filewrite+0xfa>
    80004cde:	5a7d                	li	s4,-1
    80004ce0:	b7e1                	j	80004ca8 <filewrite+0xfa>

0000000080004ce2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ce2:	7179                	addi	sp,sp,-48
    80004ce4:	f406                	sd	ra,40(sp)
    80004ce6:	f022                	sd	s0,32(sp)
    80004ce8:	ec26                	sd	s1,24(sp)
    80004cea:	e84a                	sd	s2,16(sp)
    80004cec:	e44e                	sd	s3,8(sp)
    80004cee:	e052                	sd	s4,0(sp)
    80004cf0:	1800                	addi	s0,sp,48
    80004cf2:	84aa                	mv	s1,a0
    80004cf4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cf6:	0005b023          	sd	zero,0(a1)
    80004cfa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	bf8080e7          	jalr	-1032(ra) # 800048f6 <filealloc>
    80004d06:	e088                	sd	a0,0(s1)
    80004d08:	c551                	beqz	a0,80004d94 <pipealloc+0xb2>
    80004d0a:	00000097          	auipc	ra,0x0
    80004d0e:	bec080e7          	jalr	-1044(ra) # 800048f6 <filealloc>
    80004d12:	00aa3023          	sd	a0,0(s4)
    80004d16:	c92d                	beqz	a0,80004d88 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	ddc080e7          	jalr	-548(ra) # 80000af4 <kalloc>
    80004d20:	892a                	mv	s2,a0
    80004d22:	c125                	beqz	a0,80004d82 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d24:	4985                	li	s3,1
    80004d26:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d2a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d2e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d32:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d36:	00004597          	auipc	a1,0x4
    80004d3a:	a5a58593          	addi	a1,a1,-1446 # 80008790 <syscalls+0x290>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	e16080e7          	jalr	-490(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d46:	609c                	ld	a5,0(s1)
    80004d48:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d4c:	609c                	ld	a5,0(s1)
    80004d4e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d52:	609c                	ld	a5,0(s1)
    80004d54:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d58:	609c                	ld	a5,0(s1)
    80004d5a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d5e:	000a3783          	ld	a5,0(s4)
    80004d62:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d66:	000a3783          	ld	a5,0(s4)
    80004d6a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d6e:	000a3783          	ld	a5,0(s4)
    80004d72:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d76:	000a3783          	ld	a5,0(s4)
    80004d7a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d7e:	4501                	li	a0,0
    80004d80:	a025                	j	80004da8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d82:	6088                	ld	a0,0(s1)
    80004d84:	e501                	bnez	a0,80004d8c <pipealloc+0xaa>
    80004d86:	a039                	j	80004d94 <pipealloc+0xb2>
    80004d88:	6088                	ld	a0,0(s1)
    80004d8a:	c51d                	beqz	a0,80004db8 <pipealloc+0xd6>
    fileclose(*f0);
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	c26080e7          	jalr	-986(ra) # 800049b2 <fileclose>
  if(*f1)
    80004d94:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d98:	557d                	li	a0,-1
  if(*f1)
    80004d9a:	c799                	beqz	a5,80004da8 <pipealloc+0xc6>
    fileclose(*f1);
    80004d9c:	853e                	mv	a0,a5
    80004d9e:	00000097          	auipc	ra,0x0
    80004da2:	c14080e7          	jalr	-1004(ra) # 800049b2 <fileclose>
  return -1;
    80004da6:	557d                	li	a0,-1
}
    80004da8:	70a2                	ld	ra,40(sp)
    80004daa:	7402                	ld	s0,32(sp)
    80004dac:	64e2                	ld	s1,24(sp)
    80004dae:	6942                	ld	s2,16(sp)
    80004db0:	69a2                	ld	s3,8(sp)
    80004db2:	6a02                	ld	s4,0(sp)
    80004db4:	6145                	addi	sp,sp,48
    80004db6:	8082                	ret
  return -1;
    80004db8:	557d                	li	a0,-1
    80004dba:	b7fd                	j	80004da8 <pipealloc+0xc6>

0000000080004dbc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dbc:	1101                	addi	sp,sp,-32
    80004dbe:	ec06                	sd	ra,24(sp)
    80004dc0:	e822                	sd	s0,16(sp)
    80004dc2:	e426                	sd	s1,8(sp)
    80004dc4:	e04a                	sd	s2,0(sp)
    80004dc6:	1000                	addi	s0,sp,32
    80004dc8:	84aa                	mv	s1,a0
    80004dca:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dcc:	ffffc097          	auipc	ra,0xffffc
    80004dd0:	e18080e7          	jalr	-488(ra) # 80000be4 <acquire>
  if(writable){
    80004dd4:	02090d63          	beqz	s2,80004e0e <pipeclose+0x52>
    pi->writeopen = 0;
    80004dd8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ddc:	21848513          	addi	a0,s1,536
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	73c080e7          	jalr	1852(ra) # 8000251c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004de8:	2204b783          	ld	a5,544(s1)
    80004dec:	eb95                	bnez	a5,80004e20 <pipeclose+0x64>
    release(&pi->lock);
    80004dee:	8526                	mv	a0,s1
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	ea8080e7          	jalr	-344(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004df8:	8526                	mv	a0,s1
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	bfe080e7          	jalr	-1026(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e02:	60e2                	ld	ra,24(sp)
    80004e04:	6442                	ld	s0,16(sp)
    80004e06:	64a2                	ld	s1,8(sp)
    80004e08:	6902                	ld	s2,0(sp)
    80004e0a:	6105                	addi	sp,sp,32
    80004e0c:	8082                	ret
    pi->readopen = 0;
    80004e0e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e12:	21c48513          	addi	a0,s1,540
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	706080e7          	jalr	1798(ra) # 8000251c <wakeup>
    80004e1e:	b7e9                	j	80004de8 <pipeclose+0x2c>
    release(&pi->lock);
    80004e20:	8526                	mv	a0,s1
    80004e22:	ffffc097          	auipc	ra,0xffffc
    80004e26:	e76080e7          	jalr	-394(ra) # 80000c98 <release>
}
    80004e2a:	bfe1                	j	80004e02 <pipeclose+0x46>

0000000080004e2c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e2c:	7159                	addi	sp,sp,-112
    80004e2e:	f486                	sd	ra,104(sp)
    80004e30:	f0a2                	sd	s0,96(sp)
    80004e32:	eca6                	sd	s1,88(sp)
    80004e34:	e8ca                	sd	s2,80(sp)
    80004e36:	e4ce                	sd	s3,72(sp)
    80004e38:	e0d2                	sd	s4,64(sp)
    80004e3a:	fc56                	sd	s5,56(sp)
    80004e3c:	f85a                	sd	s6,48(sp)
    80004e3e:	f45e                	sd	s7,40(sp)
    80004e40:	f062                	sd	s8,32(sp)
    80004e42:	ec66                	sd	s9,24(sp)
    80004e44:	1880                	addi	s0,sp,112
    80004e46:	84aa                	mv	s1,a0
    80004e48:	8aae                	mv	s5,a1
    80004e4a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	b88080e7          	jalr	-1144(ra) # 800019d4 <myproc>
    80004e54:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e56:	8526                	mv	a0,s1
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	d8c080e7          	jalr	-628(ra) # 80000be4 <acquire>
  while(i < n){
    80004e60:	0d405163          	blez	s4,80004f22 <pipewrite+0xf6>
    80004e64:	8ba6                	mv	s7,s1
  int i = 0;
    80004e66:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e68:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e6a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e6e:	21c48c13          	addi	s8,s1,540
    80004e72:	a08d                	j	80004ed4 <pipewrite+0xa8>
      release(&pi->lock);
    80004e74:	8526                	mv	a0,s1
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
      return -1;
    80004e7e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e80:	854a                	mv	a0,s2
    80004e82:	70a6                	ld	ra,104(sp)
    80004e84:	7406                	ld	s0,96(sp)
    80004e86:	64e6                	ld	s1,88(sp)
    80004e88:	6946                	ld	s2,80(sp)
    80004e8a:	69a6                	ld	s3,72(sp)
    80004e8c:	6a06                	ld	s4,64(sp)
    80004e8e:	7ae2                	ld	s5,56(sp)
    80004e90:	7b42                	ld	s6,48(sp)
    80004e92:	7ba2                	ld	s7,40(sp)
    80004e94:	7c02                	ld	s8,32(sp)
    80004e96:	6ce2                	ld	s9,24(sp)
    80004e98:	6165                	addi	sp,sp,112
    80004e9a:	8082                	ret
      wakeup(&pi->nread);
    80004e9c:	8566                	mv	a0,s9
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	67e080e7          	jalr	1662(ra) # 8000251c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ea6:	85de                	mv	a1,s7
    80004ea8:	8562                	mv	a0,s8
    80004eaa:	ffffd097          	auipc	ra,0xffffd
    80004eae:	4dc080e7          	jalr	1244(ra) # 80002386 <sleep>
    80004eb2:	a839                	j	80004ed0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004eb4:	21c4a783          	lw	a5,540(s1)
    80004eb8:	0017871b          	addiw	a4,a5,1
    80004ebc:	20e4ae23          	sw	a4,540(s1)
    80004ec0:	1ff7f793          	andi	a5,a5,511
    80004ec4:	97a6                	add	a5,a5,s1
    80004ec6:	f9f44703          	lbu	a4,-97(s0)
    80004eca:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ece:	2905                	addiw	s2,s2,1
  while(i < n){
    80004ed0:	03495d63          	bge	s2,s4,80004f0a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ed4:	2204a783          	lw	a5,544(s1)
    80004ed8:	dfd1                	beqz	a5,80004e74 <pipewrite+0x48>
    80004eda:	0289a783          	lw	a5,40(s3)
    80004ede:	fbd9                	bnez	a5,80004e74 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee0:	2184a783          	lw	a5,536(s1)
    80004ee4:	21c4a703          	lw	a4,540(s1)
    80004ee8:	2007879b          	addiw	a5,a5,512
    80004eec:	faf708e3          	beq	a4,a5,80004e9c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef0:	4685                	li	a3,1
    80004ef2:	01590633          	add	a2,s2,s5
    80004ef6:	f9f40593          	addi	a1,s0,-97
    80004efa:	0709b503          	ld	a0,112(s3)
    80004efe:	ffffd097          	auipc	ra,0xffffd
    80004f02:	808080e7          	jalr	-2040(ra) # 80001706 <copyin>
    80004f06:	fb6517e3          	bne	a0,s6,80004eb4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f0a:	21848513          	addi	a0,s1,536
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	60e080e7          	jalr	1550(ra) # 8000251c <wakeup>
  release(&pi->lock);
    80004f16:	8526                	mv	a0,s1
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	d80080e7          	jalr	-640(ra) # 80000c98 <release>
  return i;
    80004f20:	b785                	j	80004e80 <pipewrite+0x54>
  int i = 0;
    80004f22:	4901                	li	s2,0
    80004f24:	b7dd                	j	80004f0a <pipewrite+0xde>

0000000080004f26 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f26:	715d                	addi	sp,sp,-80
    80004f28:	e486                	sd	ra,72(sp)
    80004f2a:	e0a2                	sd	s0,64(sp)
    80004f2c:	fc26                	sd	s1,56(sp)
    80004f2e:	f84a                	sd	s2,48(sp)
    80004f30:	f44e                	sd	s3,40(sp)
    80004f32:	f052                	sd	s4,32(sp)
    80004f34:	ec56                	sd	s5,24(sp)
    80004f36:	e85a                	sd	s6,16(sp)
    80004f38:	0880                	addi	s0,sp,80
    80004f3a:	84aa                	mv	s1,a0
    80004f3c:	892e                	mv	s2,a1
    80004f3e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	a94080e7          	jalr	-1388(ra) # 800019d4 <myproc>
    80004f48:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f4a:	8b26                	mv	s6,s1
    80004f4c:	8526                	mv	a0,s1
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	c96080e7          	jalr	-874(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f56:	2184a703          	lw	a4,536(s1)
    80004f5a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f5e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f62:	02f71463          	bne	a4,a5,80004f8a <piperead+0x64>
    80004f66:	2244a783          	lw	a5,548(s1)
    80004f6a:	c385                	beqz	a5,80004f8a <piperead+0x64>
    if(pr->killed){
    80004f6c:	028a2783          	lw	a5,40(s4)
    80004f70:	ebc1                	bnez	a5,80005000 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f72:	85da                	mv	a1,s6
    80004f74:	854e                	mv	a0,s3
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	410080e7          	jalr	1040(ra) # 80002386 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f7e:	2184a703          	lw	a4,536(s1)
    80004f82:	21c4a783          	lw	a5,540(s1)
    80004f86:	fef700e3          	beq	a4,a5,80004f66 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f8a:	09505263          	blez	s5,8000500e <piperead+0xe8>
    80004f8e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f90:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f92:	2184a783          	lw	a5,536(s1)
    80004f96:	21c4a703          	lw	a4,540(s1)
    80004f9a:	02f70d63          	beq	a4,a5,80004fd4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f9e:	0017871b          	addiw	a4,a5,1
    80004fa2:	20e4ac23          	sw	a4,536(s1)
    80004fa6:	1ff7f793          	andi	a5,a5,511
    80004faa:	97a6                	add	a5,a5,s1
    80004fac:	0187c783          	lbu	a5,24(a5)
    80004fb0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fb4:	4685                	li	a3,1
    80004fb6:	fbf40613          	addi	a2,s0,-65
    80004fba:	85ca                	mv	a1,s2
    80004fbc:	070a3503          	ld	a0,112(s4)
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	6ba080e7          	jalr	1722(ra) # 8000167a <copyout>
    80004fc8:	01650663          	beq	a0,s6,80004fd4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fcc:	2985                	addiw	s3,s3,1
    80004fce:	0905                	addi	s2,s2,1
    80004fd0:	fd3a91e3          	bne	s5,s3,80004f92 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fd4:	21c48513          	addi	a0,s1,540
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	544080e7          	jalr	1348(ra) # 8000251c <wakeup>
  release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
  return i;
}
    80004fea:	854e                	mv	a0,s3
    80004fec:	60a6                	ld	ra,72(sp)
    80004fee:	6406                	ld	s0,64(sp)
    80004ff0:	74e2                	ld	s1,56(sp)
    80004ff2:	7942                	ld	s2,48(sp)
    80004ff4:	79a2                	ld	s3,40(sp)
    80004ff6:	7a02                	ld	s4,32(sp)
    80004ff8:	6ae2                	ld	s5,24(sp)
    80004ffa:	6b42                	ld	s6,16(sp)
    80004ffc:	6161                	addi	sp,sp,80
    80004ffe:	8082                	ret
      release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c96080e7          	jalr	-874(ra) # 80000c98 <release>
      return -1;
    8000500a:	59fd                	li	s3,-1
    8000500c:	bff9                	j	80004fea <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000500e:	4981                	li	s3,0
    80005010:	b7d1                	j	80004fd4 <piperead+0xae>

0000000080005012 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005012:	df010113          	addi	sp,sp,-528
    80005016:	20113423          	sd	ra,520(sp)
    8000501a:	20813023          	sd	s0,512(sp)
    8000501e:	ffa6                	sd	s1,504(sp)
    80005020:	fbca                	sd	s2,496(sp)
    80005022:	f7ce                	sd	s3,488(sp)
    80005024:	f3d2                	sd	s4,480(sp)
    80005026:	efd6                	sd	s5,472(sp)
    80005028:	ebda                	sd	s6,464(sp)
    8000502a:	e7de                	sd	s7,456(sp)
    8000502c:	e3e2                	sd	s8,448(sp)
    8000502e:	ff66                	sd	s9,440(sp)
    80005030:	fb6a                	sd	s10,432(sp)
    80005032:	f76e                	sd	s11,424(sp)
    80005034:	0c00                	addi	s0,sp,528
    80005036:	84aa                	mv	s1,a0
    80005038:	dea43c23          	sd	a0,-520(s0)
    8000503c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	994080e7          	jalr	-1644(ra) # 800019d4 <myproc>
    80005048:	892a                	mv	s2,a0

  begin_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	49c080e7          	jalr	1180(ra) # 800044e6 <begin_op>

  if((ip = namei(path)) == 0){
    80005052:	8526                	mv	a0,s1
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	276080e7          	jalr	630(ra) # 800042ca <namei>
    8000505c:	c92d                	beqz	a0,800050ce <exec+0xbc>
    8000505e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	ab4080e7          	jalr	-1356(ra) # 80003b14 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005068:	04000713          	li	a4,64
    8000506c:	4681                	li	a3,0
    8000506e:	e5040613          	addi	a2,s0,-432
    80005072:	4581                	li	a1,0
    80005074:	8526                	mv	a0,s1
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	d52080e7          	jalr	-686(ra) # 80003dc8 <readi>
    8000507e:	04000793          	li	a5,64
    80005082:	00f51a63          	bne	a0,a5,80005096 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005086:	e5042703          	lw	a4,-432(s0)
    8000508a:	464c47b7          	lui	a5,0x464c4
    8000508e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005092:	04f70463          	beq	a4,a5,800050da <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005096:	8526                	mv	a0,s1
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	cde080e7          	jalr	-802(ra) # 80003d76 <iunlockput>
    end_op();
    800050a0:	fffff097          	auipc	ra,0xfffff
    800050a4:	4c6080e7          	jalr	1222(ra) # 80004566 <end_op>
  }
  return -1;
    800050a8:	557d                	li	a0,-1
}
    800050aa:	20813083          	ld	ra,520(sp)
    800050ae:	20013403          	ld	s0,512(sp)
    800050b2:	74fe                	ld	s1,504(sp)
    800050b4:	795e                	ld	s2,496(sp)
    800050b6:	79be                	ld	s3,488(sp)
    800050b8:	7a1e                	ld	s4,480(sp)
    800050ba:	6afe                	ld	s5,472(sp)
    800050bc:	6b5e                	ld	s6,464(sp)
    800050be:	6bbe                	ld	s7,456(sp)
    800050c0:	6c1e                	ld	s8,448(sp)
    800050c2:	7cfa                	ld	s9,440(sp)
    800050c4:	7d5a                	ld	s10,432(sp)
    800050c6:	7dba                	ld	s11,424(sp)
    800050c8:	21010113          	addi	sp,sp,528
    800050cc:	8082                	ret
    end_op();
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	498080e7          	jalr	1176(ra) # 80004566 <end_op>
    return -1;
    800050d6:	557d                	li	a0,-1
    800050d8:	bfc9                	j	800050aa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050da:	854a                	mv	a0,s2
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	9bc080e7          	jalr	-1604(ra) # 80001a98 <proc_pagetable>
    800050e4:	8baa                	mv	s7,a0
    800050e6:	d945                	beqz	a0,80005096 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e8:	e7042983          	lw	s3,-400(s0)
    800050ec:	e8845783          	lhu	a5,-376(s0)
    800050f0:	c7ad                	beqz	a5,8000515a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050f2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050f4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050f6:	6c85                	lui	s9,0x1
    800050f8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050fc:	def43823          	sd	a5,-528(s0)
    80005100:	a42d                	j	8000532a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005102:	00003517          	auipc	a0,0x3
    80005106:	69650513          	addi	a0,a0,1686 # 80008798 <syscalls+0x298>
    8000510a:	ffffb097          	auipc	ra,0xffffb
    8000510e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005112:	8756                	mv	a4,s5
    80005114:	012d86bb          	addw	a3,s11,s2
    80005118:	4581                	li	a1,0
    8000511a:	8526                	mv	a0,s1
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	cac080e7          	jalr	-852(ra) # 80003dc8 <readi>
    80005124:	2501                	sext.w	a0,a0
    80005126:	1aaa9963          	bne	s5,a0,800052d8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000512a:	6785                	lui	a5,0x1
    8000512c:	0127893b          	addw	s2,a5,s2
    80005130:	77fd                	lui	a5,0xfffff
    80005132:	01478a3b          	addw	s4,a5,s4
    80005136:	1f897163          	bgeu	s2,s8,80005318 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000513a:	02091593          	slli	a1,s2,0x20
    8000513e:	9181                	srli	a1,a1,0x20
    80005140:	95ea                	add	a1,a1,s10
    80005142:	855e                	mv	a0,s7
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	f32080e7          	jalr	-206(ra) # 80001076 <walkaddr>
    8000514c:	862a                	mv	a2,a0
    if(pa == 0)
    8000514e:	d955                	beqz	a0,80005102 <exec+0xf0>
      n = PGSIZE;
    80005150:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005152:	fd9a70e3          	bgeu	s4,s9,80005112 <exec+0x100>
      n = sz - i;
    80005156:	8ad2                	mv	s5,s4
    80005158:	bf6d                	j	80005112 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000515a:	4901                	li	s2,0
  iunlockput(ip);
    8000515c:	8526                	mv	a0,s1
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	c18080e7          	jalr	-1000(ra) # 80003d76 <iunlockput>
  end_op();
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	400080e7          	jalr	1024(ra) # 80004566 <end_op>
  p = myproc();
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	866080e7          	jalr	-1946(ra) # 800019d4 <myproc>
    80005176:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005178:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000517c:	6785                	lui	a5,0x1
    8000517e:	17fd                	addi	a5,a5,-1
    80005180:	993e                	add	s2,s2,a5
    80005182:	757d                	lui	a0,0xfffff
    80005184:	00a977b3          	and	a5,s2,a0
    80005188:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000518c:	6609                	lui	a2,0x2
    8000518e:	963e                	add	a2,a2,a5
    80005190:	85be                	mv	a1,a5
    80005192:	855e                	mv	a0,s7
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	296080e7          	jalr	662(ra) # 8000142a <uvmalloc>
    8000519c:	8b2a                	mv	s6,a0
  ip = 0;
    8000519e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051a0:	12050c63          	beqz	a0,800052d8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051a4:	75f9                	lui	a1,0xffffe
    800051a6:	95aa                	add	a1,a1,a0
    800051a8:	855e                	mv	a0,s7
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	49e080e7          	jalr	1182(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    800051b2:	7c7d                	lui	s8,0xfffff
    800051b4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800051b6:	e0043783          	ld	a5,-512(s0)
    800051ba:	6388                	ld	a0,0(a5)
    800051bc:	c535                	beqz	a0,80005228 <exec+0x216>
    800051be:	e9040993          	addi	s3,s0,-368
    800051c2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051c6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	c9c080e7          	jalr	-868(ra) # 80000e64 <strlen>
    800051d0:	2505                	addiw	a0,a0,1
    800051d2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051d6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051da:	13896363          	bltu	s2,s8,80005300 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051de:	e0043d83          	ld	s11,-512(s0)
    800051e2:	000dba03          	ld	s4,0(s11)
    800051e6:	8552                	mv	a0,s4
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	c7c080e7          	jalr	-900(ra) # 80000e64 <strlen>
    800051f0:	0015069b          	addiw	a3,a0,1
    800051f4:	8652                	mv	a2,s4
    800051f6:	85ca                	mv	a1,s2
    800051f8:	855e                	mv	a0,s7
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	480080e7          	jalr	1152(ra) # 8000167a <copyout>
    80005202:	10054363          	bltz	a0,80005308 <exec+0x2f6>
    ustack[argc] = sp;
    80005206:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000520a:	0485                	addi	s1,s1,1
    8000520c:	008d8793          	addi	a5,s11,8
    80005210:	e0f43023          	sd	a5,-512(s0)
    80005214:	008db503          	ld	a0,8(s11)
    80005218:	c911                	beqz	a0,8000522c <exec+0x21a>
    if(argc >= MAXARG)
    8000521a:	09a1                	addi	s3,s3,8
    8000521c:	fb3c96e3          	bne	s9,s3,800051c8 <exec+0x1b6>
  sz = sz1;
    80005220:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005224:	4481                	li	s1,0
    80005226:	a84d                	j	800052d8 <exec+0x2c6>
  sp = sz;
    80005228:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000522a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000522c:	00349793          	slli	a5,s1,0x3
    80005230:	f9040713          	addi	a4,s0,-112
    80005234:	97ba                	add	a5,a5,a4
    80005236:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000523a:	00148693          	addi	a3,s1,1
    8000523e:	068e                	slli	a3,a3,0x3
    80005240:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005244:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005248:	01897663          	bgeu	s2,s8,80005254 <exec+0x242>
  sz = sz1;
    8000524c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005250:	4481                	li	s1,0
    80005252:	a059                	j	800052d8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005254:	e9040613          	addi	a2,s0,-368
    80005258:	85ca                	mv	a1,s2
    8000525a:	855e                	mv	a0,s7
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	41e080e7          	jalr	1054(ra) # 8000167a <copyout>
    80005264:	0a054663          	bltz	a0,80005310 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005268:	078ab783          	ld	a5,120(s5)
    8000526c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005270:	df843783          	ld	a5,-520(s0)
    80005274:	0007c703          	lbu	a4,0(a5)
    80005278:	cf11                	beqz	a4,80005294 <exec+0x282>
    8000527a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000527c:	02f00693          	li	a3,47
    80005280:	a039                	j	8000528e <exec+0x27c>
      last = s+1;
    80005282:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005286:	0785                	addi	a5,a5,1
    80005288:	fff7c703          	lbu	a4,-1(a5)
    8000528c:	c701                	beqz	a4,80005294 <exec+0x282>
    if(*s == '/')
    8000528e:	fed71ce3          	bne	a4,a3,80005286 <exec+0x274>
    80005292:	bfc5                	j	80005282 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005294:	4641                	li	a2,16
    80005296:	df843583          	ld	a1,-520(s0)
    8000529a:	178a8513          	addi	a0,s5,376
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	b94080e7          	jalr	-1132(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800052a6:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800052aa:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800052ae:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052b2:	078ab783          	ld	a5,120(s5)
    800052b6:	e6843703          	ld	a4,-408(s0)
    800052ba:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052bc:	078ab783          	ld	a5,120(s5)
    800052c0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052c4:	85ea                	mv	a1,s10
    800052c6:	ffffd097          	auipc	ra,0xffffd
    800052ca:	86e080e7          	jalr	-1938(ra) # 80001b34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052ce:	0004851b          	sext.w	a0,s1
    800052d2:	bbe1                	j	800050aa <exec+0x98>
    800052d4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052d8:	e0843583          	ld	a1,-504(s0)
    800052dc:	855e                	mv	a0,s7
    800052de:	ffffd097          	auipc	ra,0xffffd
    800052e2:	856080e7          	jalr	-1962(ra) # 80001b34 <proc_freepagetable>
  if(ip){
    800052e6:	da0498e3          	bnez	s1,80005096 <exec+0x84>
  return -1;
    800052ea:	557d                	li	a0,-1
    800052ec:	bb7d                	j	800050aa <exec+0x98>
    800052ee:	e1243423          	sd	s2,-504(s0)
    800052f2:	b7dd                	j	800052d8 <exec+0x2c6>
    800052f4:	e1243423          	sd	s2,-504(s0)
    800052f8:	b7c5                	j	800052d8 <exec+0x2c6>
    800052fa:	e1243423          	sd	s2,-504(s0)
    800052fe:	bfe9                	j	800052d8 <exec+0x2c6>
  sz = sz1;
    80005300:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005304:	4481                	li	s1,0
    80005306:	bfc9                	j	800052d8 <exec+0x2c6>
  sz = sz1;
    80005308:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000530c:	4481                	li	s1,0
    8000530e:	b7e9                	j	800052d8 <exec+0x2c6>
  sz = sz1;
    80005310:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005314:	4481                	li	s1,0
    80005316:	b7c9                	j	800052d8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005318:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000531c:	2b05                	addiw	s6,s6,1
    8000531e:	0389899b          	addiw	s3,s3,56
    80005322:	e8845783          	lhu	a5,-376(s0)
    80005326:	e2fb5be3          	bge	s6,a5,8000515c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000532a:	2981                	sext.w	s3,s3
    8000532c:	03800713          	li	a4,56
    80005330:	86ce                	mv	a3,s3
    80005332:	e1840613          	addi	a2,s0,-488
    80005336:	4581                	li	a1,0
    80005338:	8526                	mv	a0,s1
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	a8e080e7          	jalr	-1394(ra) # 80003dc8 <readi>
    80005342:	03800793          	li	a5,56
    80005346:	f8f517e3          	bne	a0,a5,800052d4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000534a:	e1842783          	lw	a5,-488(s0)
    8000534e:	4705                	li	a4,1
    80005350:	fce796e3          	bne	a5,a4,8000531c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005354:	e4043603          	ld	a2,-448(s0)
    80005358:	e3843783          	ld	a5,-456(s0)
    8000535c:	f8f669e3          	bltu	a2,a5,800052ee <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005360:	e2843783          	ld	a5,-472(s0)
    80005364:	963e                	add	a2,a2,a5
    80005366:	f8f667e3          	bltu	a2,a5,800052f4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000536a:	85ca                	mv	a1,s2
    8000536c:	855e                	mv	a0,s7
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	0bc080e7          	jalr	188(ra) # 8000142a <uvmalloc>
    80005376:	e0a43423          	sd	a0,-504(s0)
    8000537a:	d141                	beqz	a0,800052fa <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000537c:	e2843d03          	ld	s10,-472(s0)
    80005380:	df043783          	ld	a5,-528(s0)
    80005384:	00fd77b3          	and	a5,s10,a5
    80005388:	fba1                	bnez	a5,800052d8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000538a:	e2042d83          	lw	s11,-480(s0)
    8000538e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005392:	f80c03e3          	beqz	s8,80005318 <exec+0x306>
    80005396:	8a62                	mv	s4,s8
    80005398:	4901                	li	s2,0
    8000539a:	b345                	j	8000513a <exec+0x128>

000000008000539c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000539c:	7179                	addi	sp,sp,-48
    8000539e:	f406                	sd	ra,40(sp)
    800053a0:	f022                	sd	s0,32(sp)
    800053a2:	ec26                	sd	s1,24(sp)
    800053a4:	e84a                	sd	s2,16(sp)
    800053a6:	1800                	addi	s0,sp,48
    800053a8:	892e                	mv	s2,a1
    800053aa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053ac:	fdc40593          	addi	a1,s0,-36
    800053b0:	ffffe097          	auipc	ra,0xffffe
    800053b4:	b8c080e7          	jalr	-1140(ra) # 80002f3c <argint>
    800053b8:	04054063          	bltz	a0,800053f8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053bc:	fdc42703          	lw	a4,-36(s0)
    800053c0:	47bd                	li	a5,15
    800053c2:	02e7ed63          	bltu	a5,a4,800053fc <argfd+0x60>
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	60e080e7          	jalr	1550(ra) # 800019d4 <myproc>
    800053ce:	fdc42703          	lw	a4,-36(s0)
    800053d2:	01e70793          	addi	a5,a4,30
    800053d6:	078e                	slli	a5,a5,0x3
    800053d8:	953e                	add	a0,a0,a5
    800053da:	611c                	ld	a5,0(a0)
    800053dc:	c395                	beqz	a5,80005400 <argfd+0x64>
    return -1;
  if(pfd)
    800053de:	00090463          	beqz	s2,800053e6 <argfd+0x4a>
    *pfd = fd;
    800053e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053e6:	4501                	li	a0,0
  if(pf)
    800053e8:	c091                	beqz	s1,800053ec <argfd+0x50>
    *pf = f;
    800053ea:	e09c                	sd	a5,0(s1)
}
    800053ec:	70a2                	ld	ra,40(sp)
    800053ee:	7402                	ld	s0,32(sp)
    800053f0:	64e2                	ld	s1,24(sp)
    800053f2:	6942                	ld	s2,16(sp)
    800053f4:	6145                	addi	sp,sp,48
    800053f6:	8082                	ret
    return -1;
    800053f8:	557d                	li	a0,-1
    800053fa:	bfcd                	j	800053ec <argfd+0x50>
    return -1;
    800053fc:	557d                	li	a0,-1
    800053fe:	b7fd                	j	800053ec <argfd+0x50>
    80005400:	557d                	li	a0,-1
    80005402:	b7ed                	j	800053ec <argfd+0x50>

0000000080005404 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	e426                	sd	s1,8(sp)
    8000540c:	1000                	addi	s0,sp,32
    8000540e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	5c4080e7          	jalr	1476(ra) # 800019d4 <myproc>
    80005418:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000541a:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000541e:	4501                	li	a0,0
    80005420:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005422:	6398                	ld	a4,0(a5)
    80005424:	cb19                	beqz	a4,8000543a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005426:	2505                	addiw	a0,a0,1
    80005428:	07a1                	addi	a5,a5,8
    8000542a:	fed51ce3          	bne	a0,a3,80005422 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000542e:	557d                	li	a0,-1
}
    80005430:	60e2                	ld	ra,24(sp)
    80005432:	6442                	ld	s0,16(sp)
    80005434:	64a2                	ld	s1,8(sp)
    80005436:	6105                	addi	sp,sp,32
    80005438:	8082                	ret
      p->ofile[fd] = f;
    8000543a:	01e50793          	addi	a5,a0,30
    8000543e:	078e                	slli	a5,a5,0x3
    80005440:	963e                	add	a2,a2,a5
    80005442:	e204                	sd	s1,0(a2)
      return fd;
    80005444:	b7f5                	j	80005430 <fdalloc+0x2c>

0000000080005446 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005446:	715d                	addi	sp,sp,-80
    80005448:	e486                	sd	ra,72(sp)
    8000544a:	e0a2                	sd	s0,64(sp)
    8000544c:	fc26                	sd	s1,56(sp)
    8000544e:	f84a                	sd	s2,48(sp)
    80005450:	f44e                	sd	s3,40(sp)
    80005452:	f052                	sd	s4,32(sp)
    80005454:	ec56                	sd	s5,24(sp)
    80005456:	0880                	addi	s0,sp,80
    80005458:	89ae                	mv	s3,a1
    8000545a:	8ab2                	mv	s5,a2
    8000545c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000545e:	fb040593          	addi	a1,s0,-80
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	e86080e7          	jalr	-378(ra) # 800042e8 <nameiparent>
    8000546a:	892a                	mv	s2,a0
    8000546c:	12050f63          	beqz	a0,800055aa <create+0x164>
    return 0;

  ilock(dp);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	6a4080e7          	jalr	1700(ra) # 80003b14 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005478:	4601                	li	a2,0
    8000547a:	fb040593          	addi	a1,s0,-80
    8000547e:	854a                	mv	a0,s2
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	b78080e7          	jalr	-1160(ra) # 80003ff8 <dirlookup>
    80005488:	84aa                	mv	s1,a0
    8000548a:	c921                	beqz	a0,800054da <create+0x94>
    iunlockput(dp);
    8000548c:	854a                	mv	a0,s2
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	8e8080e7          	jalr	-1816(ra) # 80003d76 <iunlockput>
    ilock(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	67c080e7          	jalr	1660(ra) # 80003b14 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054a0:	2981                	sext.w	s3,s3
    800054a2:	4789                	li	a5,2
    800054a4:	02f99463          	bne	s3,a5,800054cc <create+0x86>
    800054a8:	0444d783          	lhu	a5,68(s1)
    800054ac:	37f9                	addiw	a5,a5,-2
    800054ae:	17c2                	slli	a5,a5,0x30
    800054b0:	93c1                	srli	a5,a5,0x30
    800054b2:	4705                	li	a4,1
    800054b4:	00f76c63          	bltu	a4,a5,800054cc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054b8:	8526                	mv	a0,s1
    800054ba:	60a6                	ld	ra,72(sp)
    800054bc:	6406                	ld	s0,64(sp)
    800054be:	74e2                	ld	s1,56(sp)
    800054c0:	7942                	ld	s2,48(sp)
    800054c2:	79a2                	ld	s3,40(sp)
    800054c4:	7a02                	ld	s4,32(sp)
    800054c6:	6ae2                	ld	s5,24(sp)
    800054c8:	6161                	addi	sp,sp,80
    800054ca:	8082                	ret
    iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	8a8080e7          	jalr	-1880(ra) # 80003d76 <iunlockput>
    return 0;
    800054d6:	4481                	li	s1,0
    800054d8:	b7c5                	j	800054b8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054da:	85ce                	mv	a1,s3
    800054dc:	00092503          	lw	a0,0(s2)
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	49c080e7          	jalr	1180(ra) # 8000397c <ialloc>
    800054e8:	84aa                	mv	s1,a0
    800054ea:	c529                	beqz	a0,80005534 <create+0xee>
  ilock(ip);
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	628080e7          	jalr	1576(ra) # 80003b14 <ilock>
  ip->major = major;
    800054f4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054f8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054fc:	4785                	li	a5,1
    800054fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	546080e7          	jalr	1350(ra) # 80003a4a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000550c:	2981                	sext.w	s3,s3
    8000550e:	4785                	li	a5,1
    80005510:	02f98a63          	beq	s3,a5,80005544 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005514:	40d0                	lw	a2,4(s1)
    80005516:	fb040593          	addi	a1,s0,-80
    8000551a:	854a                	mv	a0,s2
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	cec080e7          	jalr	-788(ra) # 80004208 <dirlink>
    80005524:	06054b63          	bltz	a0,8000559a <create+0x154>
  iunlockput(dp);
    80005528:	854a                	mv	a0,s2
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	84c080e7          	jalr	-1972(ra) # 80003d76 <iunlockput>
  return ip;
    80005532:	b759                	j	800054b8 <create+0x72>
    panic("create: ialloc");
    80005534:	00003517          	auipc	a0,0x3
    80005538:	28450513          	addi	a0,a0,644 # 800087b8 <syscalls+0x2b8>
    8000553c:	ffffb097          	auipc	ra,0xffffb
    80005540:	002080e7          	jalr	2(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005544:	04a95783          	lhu	a5,74(s2)
    80005548:	2785                	addiw	a5,a5,1
    8000554a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000554e:	854a                	mv	a0,s2
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	4fa080e7          	jalr	1274(ra) # 80003a4a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005558:	40d0                	lw	a2,4(s1)
    8000555a:	00003597          	auipc	a1,0x3
    8000555e:	26e58593          	addi	a1,a1,622 # 800087c8 <syscalls+0x2c8>
    80005562:	8526                	mv	a0,s1
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	ca4080e7          	jalr	-860(ra) # 80004208 <dirlink>
    8000556c:	00054f63          	bltz	a0,8000558a <create+0x144>
    80005570:	00492603          	lw	a2,4(s2)
    80005574:	00003597          	auipc	a1,0x3
    80005578:	25c58593          	addi	a1,a1,604 # 800087d0 <syscalls+0x2d0>
    8000557c:	8526                	mv	a0,s1
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	c8a080e7          	jalr	-886(ra) # 80004208 <dirlink>
    80005586:	f80557e3          	bgez	a0,80005514 <create+0xce>
      panic("create dots");
    8000558a:	00003517          	auipc	a0,0x3
    8000558e:	24e50513          	addi	a0,a0,590 # 800087d8 <syscalls+0x2d8>
    80005592:	ffffb097          	auipc	ra,0xffffb
    80005596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000559a:	00003517          	auipc	a0,0x3
    8000559e:	24e50513          	addi	a0,a0,590 # 800087e8 <syscalls+0x2e8>
    800055a2:	ffffb097          	auipc	ra,0xffffb
    800055a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
    return 0;
    800055aa:	84aa                	mv	s1,a0
    800055ac:	b731                	j	800054b8 <create+0x72>

00000000800055ae <sys_dup>:
{
    800055ae:	7179                	addi	sp,sp,-48
    800055b0:	f406                	sd	ra,40(sp)
    800055b2:	f022                	sd	s0,32(sp)
    800055b4:	ec26                	sd	s1,24(sp)
    800055b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055b8:	fd840613          	addi	a2,s0,-40
    800055bc:	4581                	li	a1,0
    800055be:	4501                	li	a0,0
    800055c0:	00000097          	auipc	ra,0x0
    800055c4:	ddc080e7          	jalr	-548(ra) # 8000539c <argfd>
    return -1;
    800055c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055ca:	02054363          	bltz	a0,800055f0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055ce:	fd843503          	ld	a0,-40(s0)
    800055d2:	00000097          	auipc	ra,0x0
    800055d6:	e32080e7          	jalr	-462(ra) # 80005404 <fdalloc>
    800055da:	84aa                	mv	s1,a0
    return -1;
    800055dc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055de:	00054963          	bltz	a0,800055f0 <sys_dup+0x42>
  filedup(f);
    800055e2:	fd843503          	ld	a0,-40(s0)
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	37a080e7          	jalr	890(ra) # 80004960 <filedup>
  return fd;
    800055ee:	87a6                	mv	a5,s1
}
    800055f0:	853e                	mv	a0,a5
    800055f2:	70a2                	ld	ra,40(sp)
    800055f4:	7402                	ld	s0,32(sp)
    800055f6:	64e2                	ld	s1,24(sp)
    800055f8:	6145                	addi	sp,sp,48
    800055fa:	8082                	ret

00000000800055fc <sys_read>:
{
    800055fc:	7179                	addi	sp,sp,-48
    800055fe:	f406                	sd	ra,40(sp)
    80005600:	f022                	sd	s0,32(sp)
    80005602:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005604:	fe840613          	addi	a2,s0,-24
    80005608:	4581                	li	a1,0
    8000560a:	4501                	li	a0,0
    8000560c:	00000097          	auipc	ra,0x0
    80005610:	d90080e7          	jalr	-624(ra) # 8000539c <argfd>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005616:	04054163          	bltz	a0,80005658 <sys_read+0x5c>
    8000561a:	fe440593          	addi	a1,s0,-28
    8000561e:	4509                	li	a0,2
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	91c080e7          	jalr	-1764(ra) # 80002f3c <argint>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562a:	02054763          	bltz	a0,80005658 <sys_read+0x5c>
    8000562e:	fd840593          	addi	a1,s0,-40
    80005632:	4505                	li	a0,1
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	92a080e7          	jalr	-1750(ra) # 80002f5e <argaddr>
    return -1;
    8000563c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563e:	00054d63          	bltz	a0,80005658 <sys_read+0x5c>
  return fileread(f, p, n);
    80005642:	fe442603          	lw	a2,-28(s0)
    80005646:	fd843583          	ld	a1,-40(s0)
    8000564a:	fe843503          	ld	a0,-24(s0)
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	49e080e7          	jalr	1182(ra) # 80004aec <fileread>
    80005656:	87aa                	mv	a5,a0
}
    80005658:	853e                	mv	a0,a5
    8000565a:	70a2                	ld	ra,40(sp)
    8000565c:	7402                	ld	s0,32(sp)
    8000565e:	6145                	addi	sp,sp,48
    80005660:	8082                	ret

0000000080005662 <sys_write>:
{
    80005662:	7179                	addi	sp,sp,-48
    80005664:	f406                	sd	ra,40(sp)
    80005666:	f022                	sd	s0,32(sp)
    80005668:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566a:	fe840613          	addi	a2,s0,-24
    8000566e:	4581                	li	a1,0
    80005670:	4501                	li	a0,0
    80005672:	00000097          	auipc	ra,0x0
    80005676:	d2a080e7          	jalr	-726(ra) # 8000539c <argfd>
    return -1;
    8000567a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	04054163          	bltz	a0,800056be <sys_write+0x5c>
    80005680:	fe440593          	addi	a1,s0,-28
    80005684:	4509                	li	a0,2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	8b6080e7          	jalr	-1866(ra) # 80002f3c <argint>
    return -1;
    8000568e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005690:	02054763          	bltz	a0,800056be <sys_write+0x5c>
    80005694:	fd840593          	addi	a1,s0,-40
    80005698:	4505                	li	a0,1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	8c4080e7          	jalr	-1852(ra) # 80002f5e <argaddr>
    return -1;
    800056a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a4:	00054d63          	bltz	a0,800056be <sys_write+0x5c>
  return filewrite(f, p, n);
    800056a8:	fe442603          	lw	a2,-28(s0)
    800056ac:	fd843583          	ld	a1,-40(s0)
    800056b0:	fe843503          	ld	a0,-24(s0)
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	4fa080e7          	jalr	1274(ra) # 80004bae <filewrite>
    800056bc:	87aa                	mv	a5,a0
}
    800056be:	853e                	mv	a0,a5
    800056c0:	70a2                	ld	ra,40(sp)
    800056c2:	7402                	ld	s0,32(sp)
    800056c4:	6145                	addi	sp,sp,48
    800056c6:	8082                	ret

00000000800056c8 <sys_close>:
{
    800056c8:	1101                	addi	sp,sp,-32
    800056ca:	ec06                	sd	ra,24(sp)
    800056cc:	e822                	sd	s0,16(sp)
    800056ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056d0:	fe040613          	addi	a2,s0,-32
    800056d4:	fec40593          	addi	a1,s0,-20
    800056d8:	4501                	li	a0,0
    800056da:	00000097          	auipc	ra,0x0
    800056de:	cc2080e7          	jalr	-830(ra) # 8000539c <argfd>
    return -1;
    800056e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056e4:	02054463          	bltz	a0,8000570c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	2ec080e7          	jalr	748(ra) # 800019d4 <myproc>
    800056f0:	fec42783          	lw	a5,-20(s0)
    800056f4:	07f9                	addi	a5,a5,30
    800056f6:	078e                	slli	a5,a5,0x3
    800056f8:	97aa                	add	a5,a5,a0
    800056fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056fe:	fe043503          	ld	a0,-32(s0)
    80005702:	fffff097          	auipc	ra,0xfffff
    80005706:	2b0080e7          	jalr	688(ra) # 800049b2 <fileclose>
  return 0;
    8000570a:	4781                	li	a5,0
}
    8000570c:	853e                	mv	a0,a5
    8000570e:	60e2                	ld	ra,24(sp)
    80005710:	6442                	ld	s0,16(sp)
    80005712:	6105                	addi	sp,sp,32
    80005714:	8082                	ret

0000000080005716 <sys_fstat>:
{
    80005716:	1101                	addi	sp,sp,-32
    80005718:	ec06                	sd	ra,24(sp)
    8000571a:	e822                	sd	s0,16(sp)
    8000571c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000571e:	fe840613          	addi	a2,s0,-24
    80005722:	4581                	li	a1,0
    80005724:	4501                	li	a0,0
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	c76080e7          	jalr	-906(ra) # 8000539c <argfd>
    return -1;
    8000572e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005730:	02054563          	bltz	a0,8000575a <sys_fstat+0x44>
    80005734:	fe040593          	addi	a1,s0,-32
    80005738:	4505                	li	a0,1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	824080e7          	jalr	-2012(ra) # 80002f5e <argaddr>
    return -1;
    80005742:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005744:	00054b63          	bltz	a0,8000575a <sys_fstat+0x44>
  return filestat(f, st);
    80005748:	fe043583          	ld	a1,-32(s0)
    8000574c:	fe843503          	ld	a0,-24(s0)
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	32a080e7          	jalr	810(ra) # 80004a7a <filestat>
    80005758:	87aa                	mv	a5,a0
}
    8000575a:	853e                	mv	a0,a5
    8000575c:	60e2                	ld	ra,24(sp)
    8000575e:	6442                	ld	s0,16(sp)
    80005760:	6105                	addi	sp,sp,32
    80005762:	8082                	ret

0000000080005764 <sys_link>:
{
    80005764:	7169                	addi	sp,sp,-304
    80005766:	f606                	sd	ra,296(sp)
    80005768:	f222                	sd	s0,288(sp)
    8000576a:	ee26                	sd	s1,280(sp)
    8000576c:	ea4a                	sd	s2,272(sp)
    8000576e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005770:	08000613          	li	a2,128
    80005774:	ed040593          	addi	a1,s0,-304
    80005778:	4501                	li	a0,0
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	806080e7          	jalr	-2042(ra) # 80002f80 <argstr>
    return -1;
    80005782:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005784:	10054e63          	bltz	a0,800058a0 <sys_link+0x13c>
    80005788:	08000613          	li	a2,128
    8000578c:	f5040593          	addi	a1,s0,-176
    80005790:	4505                	li	a0,1
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	7ee080e7          	jalr	2030(ra) # 80002f80 <argstr>
    return -1;
    8000579a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000579c:	10054263          	bltz	a0,800058a0 <sys_link+0x13c>
  begin_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	d46080e7          	jalr	-698(ra) # 800044e6 <begin_op>
  if((ip = namei(old)) == 0){
    800057a8:	ed040513          	addi	a0,s0,-304
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	b1e080e7          	jalr	-1250(ra) # 800042ca <namei>
    800057b4:	84aa                	mv	s1,a0
    800057b6:	c551                	beqz	a0,80005842 <sys_link+0xde>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	35c080e7          	jalr	860(ra) # 80003b14 <ilock>
  if(ip->type == T_DIR){
    800057c0:	04449703          	lh	a4,68(s1)
    800057c4:	4785                	li	a5,1
    800057c6:	08f70463          	beq	a4,a5,8000584e <sys_link+0xea>
  ip->nlink++;
    800057ca:	04a4d783          	lhu	a5,74(s1)
    800057ce:	2785                	addiw	a5,a5,1
    800057d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057d4:	8526                	mv	a0,s1
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	274080e7          	jalr	628(ra) # 80003a4a <iupdate>
  iunlock(ip);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	3f6080e7          	jalr	1014(ra) # 80003bd6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057e8:	fd040593          	addi	a1,s0,-48
    800057ec:	f5040513          	addi	a0,s0,-176
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	af8080e7          	jalr	-1288(ra) # 800042e8 <nameiparent>
    800057f8:	892a                	mv	s2,a0
    800057fa:	c935                	beqz	a0,8000586e <sys_link+0x10a>
  ilock(dp);
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	318080e7          	jalr	792(ra) # 80003b14 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005804:	00092703          	lw	a4,0(s2)
    80005808:	409c                	lw	a5,0(s1)
    8000580a:	04f71d63          	bne	a4,a5,80005864 <sys_link+0x100>
    8000580e:	40d0                	lw	a2,4(s1)
    80005810:	fd040593          	addi	a1,s0,-48
    80005814:	854a                	mv	a0,s2
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	9f2080e7          	jalr	-1550(ra) # 80004208 <dirlink>
    8000581e:	04054363          	bltz	a0,80005864 <sys_link+0x100>
  iunlockput(dp);
    80005822:	854a                	mv	a0,s2
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	552080e7          	jalr	1362(ra) # 80003d76 <iunlockput>
  iput(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	4a0080e7          	jalr	1184(ra) # 80003cce <iput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	d30080e7          	jalr	-720(ra) # 80004566 <end_op>
  return 0;
    8000583e:	4781                	li	a5,0
    80005840:	a085                	j	800058a0 <sys_link+0x13c>
    end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	d24080e7          	jalr	-732(ra) # 80004566 <end_op>
    return -1;
    8000584a:	57fd                	li	a5,-1
    8000584c:	a891                	j	800058a0 <sys_link+0x13c>
    iunlockput(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	526080e7          	jalr	1318(ra) # 80003d76 <iunlockput>
    end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	d0e080e7          	jalr	-754(ra) # 80004566 <end_op>
    return -1;
    80005860:	57fd                	li	a5,-1
    80005862:	a83d                	j	800058a0 <sys_link+0x13c>
    iunlockput(dp);
    80005864:	854a                	mv	a0,s2
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	510080e7          	jalr	1296(ra) # 80003d76 <iunlockput>
  ilock(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	2a4080e7          	jalr	676(ra) # 80003b14 <ilock>
  ip->nlink--;
    80005878:	04a4d783          	lhu	a5,74(s1)
    8000587c:	37fd                	addiw	a5,a5,-1
    8000587e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005882:	8526                	mv	a0,s1
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	1c6080e7          	jalr	454(ra) # 80003a4a <iupdate>
  iunlockput(ip);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	4e8080e7          	jalr	1256(ra) # 80003d76 <iunlockput>
  end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	cd0080e7          	jalr	-816(ra) # 80004566 <end_op>
  return -1;
    8000589e:	57fd                	li	a5,-1
}
    800058a0:	853e                	mv	a0,a5
    800058a2:	70b2                	ld	ra,296(sp)
    800058a4:	7412                	ld	s0,288(sp)
    800058a6:	64f2                	ld	s1,280(sp)
    800058a8:	6952                	ld	s2,272(sp)
    800058aa:	6155                	addi	sp,sp,304
    800058ac:	8082                	ret

00000000800058ae <sys_unlink>:
{
    800058ae:	7151                	addi	sp,sp,-240
    800058b0:	f586                	sd	ra,232(sp)
    800058b2:	f1a2                	sd	s0,224(sp)
    800058b4:	eda6                	sd	s1,216(sp)
    800058b6:	e9ca                	sd	s2,208(sp)
    800058b8:	e5ce                	sd	s3,200(sp)
    800058ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058bc:	08000613          	li	a2,128
    800058c0:	f3040593          	addi	a1,s0,-208
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	6ba080e7          	jalr	1722(ra) # 80002f80 <argstr>
    800058ce:	18054163          	bltz	a0,80005a50 <sys_unlink+0x1a2>
  begin_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	c14080e7          	jalr	-1004(ra) # 800044e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058da:	fb040593          	addi	a1,s0,-80
    800058de:	f3040513          	addi	a0,s0,-208
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	a06080e7          	jalr	-1530(ra) # 800042e8 <nameiparent>
    800058ea:	84aa                	mv	s1,a0
    800058ec:	c979                	beqz	a0,800059c2 <sys_unlink+0x114>
  ilock(dp);
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	226080e7          	jalr	550(ra) # 80003b14 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058f6:	00003597          	auipc	a1,0x3
    800058fa:	ed258593          	addi	a1,a1,-302 # 800087c8 <syscalls+0x2c8>
    800058fe:	fb040513          	addi	a0,s0,-80
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	6dc080e7          	jalr	1756(ra) # 80003fde <namecmp>
    8000590a:	14050a63          	beqz	a0,80005a5e <sys_unlink+0x1b0>
    8000590e:	00003597          	auipc	a1,0x3
    80005912:	ec258593          	addi	a1,a1,-318 # 800087d0 <syscalls+0x2d0>
    80005916:	fb040513          	addi	a0,s0,-80
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	6c4080e7          	jalr	1732(ra) # 80003fde <namecmp>
    80005922:	12050e63          	beqz	a0,80005a5e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005926:	f2c40613          	addi	a2,s0,-212
    8000592a:	fb040593          	addi	a1,s0,-80
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	6c8080e7          	jalr	1736(ra) # 80003ff8 <dirlookup>
    80005938:	892a                	mv	s2,a0
    8000593a:	12050263          	beqz	a0,80005a5e <sys_unlink+0x1b0>
  ilock(ip);
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	1d6080e7          	jalr	470(ra) # 80003b14 <ilock>
  if(ip->nlink < 1)
    80005946:	04a91783          	lh	a5,74(s2)
    8000594a:	08f05263          	blez	a5,800059ce <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000594e:	04491703          	lh	a4,68(s2)
    80005952:	4785                	li	a5,1
    80005954:	08f70563          	beq	a4,a5,800059de <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005958:	4641                	li	a2,16
    8000595a:	4581                	li	a1,0
    8000595c:	fc040513          	addi	a0,s0,-64
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	380080e7          	jalr	896(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005968:	4741                	li	a4,16
    8000596a:	f2c42683          	lw	a3,-212(s0)
    8000596e:	fc040613          	addi	a2,s0,-64
    80005972:	4581                	li	a1,0
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	54a080e7          	jalr	1354(ra) # 80003ec0 <writei>
    8000597e:	47c1                	li	a5,16
    80005980:	0af51563          	bne	a0,a5,80005a2a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005984:	04491703          	lh	a4,68(s2)
    80005988:	4785                	li	a5,1
    8000598a:	0af70863          	beq	a4,a5,80005a3a <sys_unlink+0x18c>
  iunlockput(dp);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	3e6080e7          	jalr	998(ra) # 80003d76 <iunlockput>
  ip->nlink--;
    80005998:	04a95783          	lhu	a5,74(s2)
    8000599c:	37fd                	addiw	a5,a5,-1
    8000599e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059a2:	854a                	mv	a0,s2
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	0a6080e7          	jalr	166(ra) # 80003a4a <iupdate>
  iunlockput(ip);
    800059ac:	854a                	mv	a0,s2
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	3c8080e7          	jalr	968(ra) # 80003d76 <iunlockput>
  end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	bb0080e7          	jalr	-1104(ra) # 80004566 <end_op>
  return 0;
    800059be:	4501                	li	a0,0
    800059c0:	a84d                	j	80005a72 <sys_unlink+0x1c4>
    end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	ba4080e7          	jalr	-1116(ra) # 80004566 <end_op>
    return -1;
    800059ca:	557d                	li	a0,-1
    800059cc:	a05d                	j	80005a72 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ce:	00003517          	auipc	a0,0x3
    800059d2:	e2a50513          	addi	a0,a0,-470 # 800087f8 <syscalls+0x2f8>
    800059d6:	ffffb097          	auipc	ra,0xffffb
    800059da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059de:	04c92703          	lw	a4,76(s2)
    800059e2:	02000793          	li	a5,32
    800059e6:	f6e7f9e3          	bgeu	a5,a4,80005958 <sys_unlink+0xaa>
    800059ea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ee:	4741                	li	a4,16
    800059f0:	86ce                	mv	a3,s3
    800059f2:	f1840613          	addi	a2,s0,-232
    800059f6:	4581                	li	a1,0
    800059f8:	854a                	mv	a0,s2
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	3ce080e7          	jalr	974(ra) # 80003dc8 <readi>
    80005a02:	47c1                	li	a5,16
    80005a04:	00f51b63          	bne	a0,a5,80005a1a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a08:	f1845783          	lhu	a5,-232(s0)
    80005a0c:	e7a1                	bnez	a5,80005a54 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a0e:	29c1                	addiw	s3,s3,16
    80005a10:	04c92783          	lw	a5,76(s2)
    80005a14:	fcf9ede3          	bltu	s3,a5,800059ee <sys_unlink+0x140>
    80005a18:	b781                	j	80005958 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a1a:	00003517          	auipc	a0,0x3
    80005a1e:	df650513          	addi	a0,a0,-522 # 80008810 <syscalls+0x310>
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a2a:	00003517          	auipc	a0,0x3
    80005a2e:	dfe50513          	addi	a0,a0,-514 # 80008828 <syscalls+0x328>
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	b0c080e7          	jalr	-1268(ra) # 8000053e <panic>
    dp->nlink--;
    80005a3a:	04a4d783          	lhu	a5,74(s1)
    80005a3e:	37fd                	addiw	a5,a5,-1
    80005a40:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	004080e7          	jalr	4(ra) # 80003a4a <iupdate>
    80005a4e:	b781                	j	8000598e <sys_unlink+0xe0>
    return -1;
    80005a50:	557d                	li	a0,-1
    80005a52:	a005                	j	80005a72 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	320080e7          	jalr	800(ra) # 80003d76 <iunlockput>
  iunlockput(dp);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	316080e7          	jalr	790(ra) # 80003d76 <iunlockput>
  end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	afe080e7          	jalr	-1282(ra) # 80004566 <end_op>
  return -1;
    80005a70:	557d                	li	a0,-1
}
    80005a72:	70ae                	ld	ra,232(sp)
    80005a74:	740e                	ld	s0,224(sp)
    80005a76:	64ee                	ld	s1,216(sp)
    80005a78:	694e                	ld	s2,208(sp)
    80005a7a:	69ae                	ld	s3,200(sp)
    80005a7c:	616d                	addi	sp,sp,240
    80005a7e:	8082                	ret

0000000080005a80 <sys_open>:

uint64
sys_open(void)
{
    80005a80:	7131                	addi	sp,sp,-192
    80005a82:	fd06                	sd	ra,184(sp)
    80005a84:	f922                	sd	s0,176(sp)
    80005a86:	f526                	sd	s1,168(sp)
    80005a88:	f14a                	sd	s2,160(sp)
    80005a8a:	ed4e                	sd	s3,152(sp)
    80005a8c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a8e:	08000613          	li	a2,128
    80005a92:	f5040593          	addi	a1,s0,-176
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	4e8080e7          	jalr	1256(ra) # 80002f80 <argstr>
    return -1;
    80005aa0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aa2:	0c054163          	bltz	a0,80005b64 <sys_open+0xe4>
    80005aa6:	f4c40593          	addi	a1,s0,-180
    80005aaa:	4505                	li	a0,1
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	490080e7          	jalr	1168(ra) # 80002f3c <argint>
    80005ab4:	0a054863          	bltz	a0,80005b64 <sys_open+0xe4>

  begin_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	a2e080e7          	jalr	-1490(ra) # 800044e6 <begin_op>

  if(omode & O_CREATE){
    80005ac0:	f4c42783          	lw	a5,-180(s0)
    80005ac4:	2007f793          	andi	a5,a5,512
    80005ac8:	cbdd                	beqz	a5,80005b7e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005aca:	4681                	li	a3,0
    80005acc:	4601                	li	a2,0
    80005ace:	4589                	li	a1,2
    80005ad0:	f5040513          	addi	a0,s0,-176
    80005ad4:	00000097          	auipc	ra,0x0
    80005ad8:	972080e7          	jalr	-1678(ra) # 80005446 <create>
    80005adc:	892a                	mv	s2,a0
    if(ip == 0){
    80005ade:	c959                	beqz	a0,80005b74 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ae0:	04491703          	lh	a4,68(s2)
    80005ae4:	478d                	li	a5,3
    80005ae6:	00f71763          	bne	a4,a5,80005af4 <sys_open+0x74>
    80005aea:	04695703          	lhu	a4,70(s2)
    80005aee:	47a5                	li	a5,9
    80005af0:	0ce7ec63          	bltu	a5,a4,80005bc8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	e02080e7          	jalr	-510(ra) # 800048f6 <filealloc>
    80005afc:	89aa                	mv	s3,a0
    80005afe:	10050263          	beqz	a0,80005c02 <sys_open+0x182>
    80005b02:	00000097          	auipc	ra,0x0
    80005b06:	902080e7          	jalr	-1790(ra) # 80005404 <fdalloc>
    80005b0a:	84aa                	mv	s1,a0
    80005b0c:	0e054663          	bltz	a0,80005bf8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b10:	04491703          	lh	a4,68(s2)
    80005b14:	478d                	li	a5,3
    80005b16:	0cf70463          	beq	a4,a5,80005bde <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b1a:	4789                	li	a5,2
    80005b1c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b20:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b24:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b28:	f4c42783          	lw	a5,-180(s0)
    80005b2c:	0017c713          	xori	a4,a5,1
    80005b30:	8b05                	andi	a4,a4,1
    80005b32:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b36:	0037f713          	andi	a4,a5,3
    80005b3a:	00e03733          	snez	a4,a4
    80005b3e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b42:	4007f793          	andi	a5,a5,1024
    80005b46:	c791                	beqz	a5,80005b52 <sys_open+0xd2>
    80005b48:	04491703          	lh	a4,68(s2)
    80005b4c:	4789                	li	a5,2
    80005b4e:	08f70f63          	beq	a4,a5,80005bec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b52:	854a                	mv	a0,s2
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	082080e7          	jalr	130(ra) # 80003bd6 <iunlock>
  end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	a0a080e7          	jalr	-1526(ra) # 80004566 <end_op>

  return fd;
}
    80005b64:	8526                	mv	a0,s1
    80005b66:	70ea                	ld	ra,184(sp)
    80005b68:	744a                	ld	s0,176(sp)
    80005b6a:	74aa                	ld	s1,168(sp)
    80005b6c:	790a                	ld	s2,160(sp)
    80005b6e:	69ea                	ld	s3,152(sp)
    80005b70:	6129                	addi	sp,sp,192
    80005b72:	8082                	ret
      end_op();
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	9f2080e7          	jalr	-1550(ra) # 80004566 <end_op>
      return -1;
    80005b7c:	b7e5                	j	80005b64 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b7e:	f5040513          	addi	a0,s0,-176
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	748080e7          	jalr	1864(ra) # 800042ca <namei>
    80005b8a:	892a                	mv	s2,a0
    80005b8c:	c905                	beqz	a0,80005bbc <sys_open+0x13c>
    ilock(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	f86080e7          	jalr	-122(ra) # 80003b14 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b96:	04491703          	lh	a4,68(s2)
    80005b9a:	4785                	li	a5,1
    80005b9c:	f4f712e3          	bne	a4,a5,80005ae0 <sys_open+0x60>
    80005ba0:	f4c42783          	lw	a5,-180(s0)
    80005ba4:	dba1                	beqz	a5,80005af4 <sys_open+0x74>
      iunlockput(ip);
    80005ba6:	854a                	mv	a0,s2
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	1ce080e7          	jalr	462(ra) # 80003d76 <iunlockput>
      end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	9b6080e7          	jalr	-1610(ra) # 80004566 <end_op>
      return -1;
    80005bb8:	54fd                	li	s1,-1
    80005bba:	b76d                	j	80005b64 <sys_open+0xe4>
      end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	9aa080e7          	jalr	-1622(ra) # 80004566 <end_op>
      return -1;
    80005bc4:	54fd                	li	s1,-1
    80005bc6:	bf79                	j	80005b64 <sys_open+0xe4>
    iunlockput(ip);
    80005bc8:	854a                	mv	a0,s2
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	1ac080e7          	jalr	428(ra) # 80003d76 <iunlockput>
    end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	994080e7          	jalr	-1644(ra) # 80004566 <end_op>
    return -1;
    80005bda:	54fd                	li	s1,-1
    80005bdc:	b761                	j	80005b64 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bde:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005be2:	04691783          	lh	a5,70(s2)
    80005be6:	02f99223          	sh	a5,36(s3)
    80005bea:	bf2d                	j	80005b24 <sys_open+0xa4>
    itrunc(ip);
    80005bec:	854a                	mv	a0,s2
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	034080e7          	jalr	52(ra) # 80003c22 <itrunc>
    80005bf6:	bfb1                	j	80005b52 <sys_open+0xd2>
      fileclose(f);
    80005bf8:	854e                	mv	a0,s3
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	db8080e7          	jalr	-584(ra) # 800049b2 <fileclose>
    iunlockput(ip);
    80005c02:	854a                	mv	a0,s2
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	172080e7          	jalr	370(ra) # 80003d76 <iunlockput>
    end_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	95a080e7          	jalr	-1702(ra) # 80004566 <end_op>
    return -1;
    80005c14:	54fd                	li	s1,-1
    80005c16:	b7b9                	j	80005b64 <sys_open+0xe4>

0000000080005c18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c18:	7175                	addi	sp,sp,-144
    80005c1a:	e506                	sd	ra,136(sp)
    80005c1c:	e122                	sd	s0,128(sp)
    80005c1e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	8c6080e7          	jalr	-1850(ra) # 800044e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c28:	08000613          	li	a2,128
    80005c2c:	f7040593          	addi	a1,s0,-144
    80005c30:	4501                	li	a0,0
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	34e080e7          	jalr	846(ra) # 80002f80 <argstr>
    80005c3a:	02054963          	bltz	a0,80005c6c <sys_mkdir+0x54>
    80005c3e:	4681                	li	a3,0
    80005c40:	4601                	li	a2,0
    80005c42:	4585                	li	a1,1
    80005c44:	f7040513          	addi	a0,s0,-144
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	7fe080e7          	jalr	2046(ra) # 80005446 <create>
    80005c50:	cd11                	beqz	a0,80005c6c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	124080e7          	jalr	292(ra) # 80003d76 <iunlockput>
  end_op();
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	90c080e7          	jalr	-1780(ra) # 80004566 <end_op>
  return 0;
    80005c62:	4501                	li	a0,0
}
    80005c64:	60aa                	ld	ra,136(sp)
    80005c66:	640a                	ld	s0,128(sp)
    80005c68:	6149                	addi	sp,sp,144
    80005c6a:	8082                	ret
    end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	8fa080e7          	jalr	-1798(ra) # 80004566 <end_op>
    return -1;
    80005c74:	557d                	li	a0,-1
    80005c76:	b7fd                	j	80005c64 <sys_mkdir+0x4c>

0000000080005c78 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c78:	7135                	addi	sp,sp,-160
    80005c7a:	ed06                	sd	ra,152(sp)
    80005c7c:	e922                	sd	s0,144(sp)
    80005c7e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	866080e7          	jalr	-1946(ra) # 800044e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c88:	08000613          	li	a2,128
    80005c8c:	f7040593          	addi	a1,s0,-144
    80005c90:	4501                	li	a0,0
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	2ee080e7          	jalr	750(ra) # 80002f80 <argstr>
    80005c9a:	04054a63          	bltz	a0,80005cee <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c9e:	f6c40593          	addi	a1,s0,-148
    80005ca2:	4505                	li	a0,1
    80005ca4:	ffffd097          	auipc	ra,0xffffd
    80005ca8:	298080e7          	jalr	664(ra) # 80002f3c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cac:	04054163          	bltz	a0,80005cee <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005cb0:	f6840593          	addi	a1,s0,-152
    80005cb4:	4509                	li	a0,2
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	286080e7          	jalr	646(ra) # 80002f3c <argint>
     argint(1, &major) < 0 ||
    80005cbe:	02054863          	bltz	a0,80005cee <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cc2:	f6841683          	lh	a3,-152(s0)
    80005cc6:	f6c41603          	lh	a2,-148(s0)
    80005cca:	458d                	li	a1,3
    80005ccc:	f7040513          	addi	a0,s0,-144
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	776080e7          	jalr	1910(ra) # 80005446 <create>
     argint(2, &minor) < 0 ||
    80005cd8:	c919                	beqz	a0,80005cee <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	09c080e7          	jalr	156(ra) # 80003d76 <iunlockput>
  end_op();
    80005ce2:	fffff097          	auipc	ra,0xfffff
    80005ce6:	884080e7          	jalr	-1916(ra) # 80004566 <end_op>
  return 0;
    80005cea:	4501                	li	a0,0
    80005cec:	a031                	j	80005cf8 <sys_mknod+0x80>
    end_op();
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	878080e7          	jalr	-1928(ra) # 80004566 <end_op>
    return -1;
    80005cf6:	557d                	li	a0,-1
}
    80005cf8:	60ea                	ld	ra,152(sp)
    80005cfa:	644a                	ld	s0,144(sp)
    80005cfc:	610d                	addi	sp,sp,160
    80005cfe:	8082                	ret

0000000080005d00 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d00:	7135                	addi	sp,sp,-160
    80005d02:	ed06                	sd	ra,152(sp)
    80005d04:	e922                	sd	s0,144(sp)
    80005d06:	e526                	sd	s1,136(sp)
    80005d08:	e14a                	sd	s2,128(sp)
    80005d0a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d0c:	ffffc097          	auipc	ra,0xffffc
    80005d10:	cc8080e7          	jalr	-824(ra) # 800019d4 <myproc>
    80005d14:	892a                	mv	s2,a0
  
  begin_op();
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	7d0080e7          	jalr	2000(ra) # 800044e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d1e:	08000613          	li	a2,128
    80005d22:	f6040593          	addi	a1,s0,-160
    80005d26:	4501                	li	a0,0
    80005d28:	ffffd097          	auipc	ra,0xffffd
    80005d2c:	258080e7          	jalr	600(ra) # 80002f80 <argstr>
    80005d30:	04054b63          	bltz	a0,80005d86 <sys_chdir+0x86>
    80005d34:	f6040513          	addi	a0,s0,-160
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	592080e7          	jalr	1426(ra) # 800042ca <namei>
    80005d40:	84aa                	mv	s1,a0
    80005d42:	c131                	beqz	a0,80005d86 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	dd0080e7          	jalr	-560(ra) # 80003b14 <ilock>
  if(ip->type != T_DIR){
    80005d4c:	04449703          	lh	a4,68(s1)
    80005d50:	4785                	li	a5,1
    80005d52:	04f71063          	bne	a4,a5,80005d92 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d56:	8526                	mv	a0,s1
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	e7e080e7          	jalr	-386(ra) # 80003bd6 <iunlock>
  iput(p->cwd);
    80005d60:	17093503          	ld	a0,368(s2)
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	f6a080e7          	jalr	-150(ra) # 80003cce <iput>
  end_op();
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	7fa080e7          	jalr	2042(ra) # 80004566 <end_op>
  p->cwd = ip;
    80005d74:	16993823          	sd	s1,368(s2)
  return 0;
    80005d78:	4501                	li	a0,0
}
    80005d7a:	60ea                	ld	ra,152(sp)
    80005d7c:	644a                	ld	s0,144(sp)
    80005d7e:	64aa                	ld	s1,136(sp)
    80005d80:	690a                	ld	s2,128(sp)
    80005d82:	610d                	addi	sp,sp,160
    80005d84:	8082                	ret
    end_op();
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	7e0080e7          	jalr	2016(ra) # 80004566 <end_op>
    return -1;
    80005d8e:	557d                	li	a0,-1
    80005d90:	b7ed                	j	80005d7a <sys_chdir+0x7a>
    iunlockput(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	fe2080e7          	jalr	-30(ra) # 80003d76 <iunlockput>
    end_op();
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	7ca080e7          	jalr	1994(ra) # 80004566 <end_op>
    return -1;
    80005da4:	557d                	li	a0,-1
    80005da6:	bfd1                	j	80005d7a <sys_chdir+0x7a>

0000000080005da8 <sys_exec>:

uint64
sys_exec(void)
{
    80005da8:	7145                	addi	sp,sp,-464
    80005daa:	e786                	sd	ra,456(sp)
    80005dac:	e3a2                	sd	s0,448(sp)
    80005dae:	ff26                	sd	s1,440(sp)
    80005db0:	fb4a                	sd	s2,432(sp)
    80005db2:	f74e                	sd	s3,424(sp)
    80005db4:	f352                	sd	s4,416(sp)
    80005db6:	ef56                	sd	s5,408(sp)
    80005db8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dba:	08000613          	li	a2,128
    80005dbe:	f4040593          	addi	a1,s0,-192
    80005dc2:	4501                	li	a0,0
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	1bc080e7          	jalr	444(ra) # 80002f80 <argstr>
    return -1;
    80005dcc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dce:	0c054a63          	bltz	a0,80005ea2 <sys_exec+0xfa>
    80005dd2:	e3840593          	addi	a1,s0,-456
    80005dd6:	4505                	li	a0,1
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	186080e7          	jalr	390(ra) # 80002f5e <argaddr>
    80005de0:	0c054163          	bltz	a0,80005ea2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005de4:	10000613          	li	a2,256
    80005de8:	4581                	li	a1,0
    80005dea:	e4040513          	addi	a0,s0,-448
    80005dee:	ffffb097          	auipc	ra,0xffffb
    80005df2:	ef2080e7          	jalr	-270(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005df6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dfa:	89a6                	mv	s3,s1
    80005dfc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dfe:	02000a13          	li	s4,32
    80005e02:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e06:	00391513          	slli	a0,s2,0x3
    80005e0a:	e3040593          	addi	a1,s0,-464
    80005e0e:	e3843783          	ld	a5,-456(s0)
    80005e12:	953e                	add	a0,a0,a5
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	08e080e7          	jalr	142(ra) # 80002ea2 <fetchaddr>
    80005e1c:	02054a63          	bltz	a0,80005e50 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e20:	e3043783          	ld	a5,-464(s0)
    80005e24:	c3b9                	beqz	a5,80005e6a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e26:	ffffb097          	auipc	ra,0xffffb
    80005e2a:	cce080e7          	jalr	-818(ra) # 80000af4 <kalloc>
    80005e2e:	85aa                	mv	a1,a0
    80005e30:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e34:	cd11                	beqz	a0,80005e50 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e36:	6605                	lui	a2,0x1
    80005e38:	e3043503          	ld	a0,-464(s0)
    80005e3c:	ffffd097          	auipc	ra,0xffffd
    80005e40:	0b8080e7          	jalr	184(ra) # 80002ef4 <fetchstr>
    80005e44:	00054663          	bltz	a0,80005e50 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e48:	0905                	addi	s2,s2,1
    80005e4a:	09a1                	addi	s3,s3,8
    80005e4c:	fb491be3          	bne	s2,s4,80005e02 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e50:	10048913          	addi	s2,s1,256
    80005e54:	6088                	ld	a0,0(s1)
    80005e56:	c529                	beqz	a0,80005ea0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e58:	ffffb097          	auipc	ra,0xffffb
    80005e5c:	ba0080e7          	jalr	-1120(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e60:	04a1                	addi	s1,s1,8
    80005e62:	ff2499e3          	bne	s1,s2,80005e54 <sys_exec+0xac>
  return -1;
    80005e66:	597d                	li	s2,-1
    80005e68:	a82d                	j	80005ea2 <sys_exec+0xfa>
      argv[i] = 0;
    80005e6a:	0a8e                	slli	s5,s5,0x3
    80005e6c:	fc040793          	addi	a5,s0,-64
    80005e70:	9abe                	add	s5,s5,a5
    80005e72:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e76:	e4040593          	addi	a1,s0,-448
    80005e7a:	f4040513          	addi	a0,s0,-192
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	194080e7          	jalr	404(ra) # 80005012 <exec>
    80005e86:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e88:	10048993          	addi	s3,s1,256
    80005e8c:	6088                	ld	a0,0(s1)
    80005e8e:	c911                	beqz	a0,80005ea2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e90:	ffffb097          	auipc	ra,0xffffb
    80005e94:	b68080e7          	jalr	-1176(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e98:	04a1                	addi	s1,s1,8
    80005e9a:	ff3499e3          	bne	s1,s3,80005e8c <sys_exec+0xe4>
    80005e9e:	a011                	j	80005ea2 <sys_exec+0xfa>
  return -1;
    80005ea0:	597d                	li	s2,-1
}
    80005ea2:	854a                	mv	a0,s2
    80005ea4:	60be                	ld	ra,456(sp)
    80005ea6:	641e                	ld	s0,448(sp)
    80005ea8:	74fa                	ld	s1,440(sp)
    80005eaa:	795a                	ld	s2,432(sp)
    80005eac:	79ba                	ld	s3,424(sp)
    80005eae:	7a1a                	ld	s4,416(sp)
    80005eb0:	6afa                	ld	s5,408(sp)
    80005eb2:	6179                	addi	sp,sp,464
    80005eb4:	8082                	ret

0000000080005eb6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eb6:	7139                	addi	sp,sp,-64
    80005eb8:	fc06                	sd	ra,56(sp)
    80005eba:	f822                	sd	s0,48(sp)
    80005ebc:	f426                	sd	s1,40(sp)
    80005ebe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	b14080e7          	jalr	-1260(ra) # 800019d4 <myproc>
    80005ec8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005eca:	fd840593          	addi	a1,s0,-40
    80005ece:	4501                	li	a0,0
    80005ed0:	ffffd097          	auipc	ra,0xffffd
    80005ed4:	08e080e7          	jalr	142(ra) # 80002f5e <argaddr>
    return -1;
    80005ed8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005eda:	0e054063          	bltz	a0,80005fba <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ede:	fc840593          	addi	a1,s0,-56
    80005ee2:	fd040513          	addi	a0,s0,-48
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	dfc080e7          	jalr	-516(ra) # 80004ce2 <pipealloc>
    return -1;
    80005eee:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ef0:	0c054563          	bltz	a0,80005fba <sys_pipe+0x104>
  fd0 = -1;
    80005ef4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ef8:	fd043503          	ld	a0,-48(s0)
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	508080e7          	jalr	1288(ra) # 80005404 <fdalloc>
    80005f04:	fca42223          	sw	a0,-60(s0)
    80005f08:	08054c63          	bltz	a0,80005fa0 <sys_pipe+0xea>
    80005f0c:	fc843503          	ld	a0,-56(s0)
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	4f4080e7          	jalr	1268(ra) # 80005404 <fdalloc>
    80005f18:	fca42023          	sw	a0,-64(s0)
    80005f1c:	06054863          	bltz	a0,80005f8c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f20:	4691                	li	a3,4
    80005f22:	fc440613          	addi	a2,s0,-60
    80005f26:	fd843583          	ld	a1,-40(s0)
    80005f2a:	78a8                	ld	a0,112(s1)
    80005f2c:	ffffb097          	auipc	ra,0xffffb
    80005f30:	74e080e7          	jalr	1870(ra) # 8000167a <copyout>
    80005f34:	02054063          	bltz	a0,80005f54 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f38:	4691                	li	a3,4
    80005f3a:	fc040613          	addi	a2,s0,-64
    80005f3e:	fd843583          	ld	a1,-40(s0)
    80005f42:	0591                	addi	a1,a1,4
    80005f44:	78a8                	ld	a0,112(s1)
    80005f46:	ffffb097          	auipc	ra,0xffffb
    80005f4a:	734080e7          	jalr	1844(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f4e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f50:	06055563          	bgez	a0,80005fba <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f54:	fc442783          	lw	a5,-60(s0)
    80005f58:	07f9                	addi	a5,a5,30
    80005f5a:	078e                	slli	a5,a5,0x3
    80005f5c:	97a6                	add	a5,a5,s1
    80005f5e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f62:	fc042503          	lw	a0,-64(s0)
    80005f66:	0579                	addi	a0,a0,30
    80005f68:	050e                	slli	a0,a0,0x3
    80005f6a:	9526                	add	a0,a0,s1
    80005f6c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f70:	fd043503          	ld	a0,-48(s0)
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	a3e080e7          	jalr	-1474(ra) # 800049b2 <fileclose>
    fileclose(wf);
    80005f7c:	fc843503          	ld	a0,-56(s0)
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	a32080e7          	jalr	-1486(ra) # 800049b2 <fileclose>
    return -1;
    80005f88:	57fd                	li	a5,-1
    80005f8a:	a805                	j	80005fba <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f8c:	fc442783          	lw	a5,-60(s0)
    80005f90:	0007c863          	bltz	a5,80005fa0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f94:	01e78513          	addi	a0,a5,30
    80005f98:	050e                	slli	a0,a0,0x3
    80005f9a:	9526                	add	a0,a0,s1
    80005f9c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fa0:	fd043503          	ld	a0,-48(s0)
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	a0e080e7          	jalr	-1522(ra) # 800049b2 <fileclose>
    fileclose(wf);
    80005fac:	fc843503          	ld	a0,-56(s0)
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	a02080e7          	jalr	-1534(ra) # 800049b2 <fileclose>
    return -1;
    80005fb8:	57fd                	li	a5,-1
}
    80005fba:	853e                	mv	a0,a5
    80005fbc:	70e2                	ld	ra,56(sp)
    80005fbe:	7442                	ld	s0,48(sp)
    80005fc0:	74a2                	ld	s1,40(sp)
    80005fc2:	6121                	addi	sp,sp,64
    80005fc4:	8082                	ret
	...

0000000080005fd0 <kernelvec>:
    80005fd0:	7111                	addi	sp,sp,-256
    80005fd2:	e006                	sd	ra,0(sp)
    80005fd4:	e40a                	sd	sp,8(sp)
    80005fd6:	e80e                	sd	gp,16(sp)
    80005fd8:	ec12                	sd	tp,24(sp)
    80005fda:	f016                	sd	t0,32(sp)
    80005fdc:	f41a                	sd	t1,40(sp)
    80005fde:	f81e                	sd	t2,48(sp)
    80005fe0:	fc22                	sd	s0,56(sp)
    80005fe2:	e0a6                	sd	s1,64(sp)
    80005fe4:	e4aa                	sd	a0,72(sp)
    80005fe6:	e8ae                	sd	a1,80(sp)
    80005fe8:	ecb2                	sd	a2,88(sp)
    80005fea:	f0b6                	sd	a3,96(sp)
    80005fec:	f4ba                	sd	a4,104(sp)
    80005fee:	f8be                	sd	a5,112(sp)
    80005ff0:	fcc2                	sd	a6,120(sp)
    80005ff2:	e146                	sd	a7,128(sp)
    80005ff4:	e54a                	sd	s2,136(sp)
    80005ff6:	e94e                	sd	s3,144(sp)
    80005ff8:	ed52                	sd	s4,152(sp)
    80005ffa:	f156                	sd	s5,160(sp)
    80005ffc:	f55a                	sd	s6,168(sp)
    80005ffe:	f95e                	sd	s7,176(sp)
    80006000:	fd62                	sd	s8,184(sp)
    80006002:	e1e6                	sd	s9,192(sp)
    80006004:	e5ea                	sd	s10,200(sp)
    80006006:	e9ee                	sd	s11,208(sp)
    80006008:	edf2                	sd	t3,216(sp)
    8000600a:	f1f6                	sd	t4,224(sp)
    8000600c:	f5fa                	sd	t5,232(sp)
    8000600e:	f9fe                	sd	t6,240(sp)
    80006010:	d89fc0ef          	jal	ra,80002d98 <kerneltrap>
    80006014:	6082                	ld	ra,0(sp)
    80006016:	6122                	ld	sp,8(sp)
    80006018:	61c2                	ld	gp,16(sp)
    8000601a:	7282                	ld	t0,32(sp)
    8000601c:	7322                	ld	t1,40(sp)
    8000601e:	73c2                	ld	t2,48(sp)
    80006020:	7462                	ld	s0,56(sp)
    80006022:	6486                	ld	s1,64(sp)
    80006024:	6526                	ld	a0,72(sp)
    80006026:	65c6                	ld	a1,80(sp)
    80006028:	6666                	ld	a2,88(sp)
    8000602a:	7686                	ld	a3,96(sp)
    8000602c:	7726                	ld	a4,104(sp)
    8000602e:	77c6                	ld	a5,112(sp)
    80006030:	7866                	ld	a6,120(sp)
    80006032:	688a                	ld	a7,128(sp)
    80006034:	692a                	ld	s2,136(sp)
    80006036:	69ca                	ld	s3,144(sp)
    80006038:	6a6a                	ld	s4,152(sp)
    8000603a:	7a8a                	ld	s5,160(sp)
    8000603c:	7b2a                	ld	s6,168(sp)
    8000603e:	7bca                	ld	s7,176(sp)
    80006040:	7c6a                	ld	s8,184(sp)
    80006042:	6c8e                	ld	s9,192(sp)
    80006044:	6d2e                	ld	s10,200(sp)
    80006046:	6dce                	ld	s11,208(sp)
    80006048:	6e6e                	ld	t3,216(sp)
    8000604a:	7e8e                	ld	t4,224(sp)
    8000604c:	7f2e                	ld	t5,232(sp)
    8000604e:	7fce                	ld	t6,240(sp)
    80006050:	6111                	addi	sp,sp,256
    80006052:	10200073          	sret
    80006056:	00000013          	nop
    8000605a:	00000013          	nop
    8000605e:	0001                	nop

0000000080006060 <timervec>:
    80006060:	34051573          	csrrw	a0,mscratch,a0
    80006064:	e10c                	sd	a1,0(a0)
    80006066:	e510                	sd	a2,8(a0)
    80006068:	e914                	sd	a3,16(a0)
    8000606a:	6d0c                	ld	a1,24(a0)
    8000606c:	7110                	ld	a2,32(a0)
    8000606e:	6194                	ld	a3,0(a1)
    80006070:	96b2                	add	a3,a3,a2
    80006072:	e194                	sd	a3,0(a1)
    80006074:	4589                	li	a1,2
    80006076:	14459073          	csrw	sip,a1
    8000607a:	6914                	ld	a3,16(a0)
    8000607c:	6510                	ld	a2,8(a0)
    8000607e:	610c                	ld	a1,0(a0)
    80006080:	34051573          	csrrw	a0,mscratch,a0
    80006084:	30200073          	mret
	...

000000008000608a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000608a:	1141                	addi	sp,sp,-16
    8000608c:	e422                	sd	s0,8(sp)
    8000608e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006090:	0c0007b7          	lui	a5,0xc000
    80006094:	4705                	li	a4,1
    80006096:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006098:	c3d8                	sw	a4,4(a5)
}
    8000609a:	6422                	ld	s0,8(sp)
    8000609c:	0141                	addi	sp,sp,16
    8000609e:	8082                	ret

00000000800060a0 <plicinithart>:

void
plicinithart(void)
{
    800060a0:	1141                	addi	sp,sp,-16
    800060a2:	e406                	sd	ra,8(sp)
    800060a4:	e022                	sd	s0,0(sp)
    800060a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	900080e7          	jalr	-1792(ra) # 800019a8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060b0:	0085171b          	slliw	a4,a0,0x8
    800060b4:	0c0027b7          	lui	a5,0xc002
    800060b8:	97ba                	add	a5,a5,a4
    800060ba:	40200713          	li	a4,1026
    800060be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060c2:	00d5151b          	slliw	a0,a0,0xd
    800060c6:	0c2017b7          	lui	a5,0xc201
    800060ca:	953e                	add	a0,a0,a5
    800060cc:	00052023          	sw	zero,0(a0)
}
    800060d0:	60a2                	ld	ra,8(sp)
    800060d2:	6402                	ld	s0,0(sp)
    800060d4:	0141                	addi	sp,sp,16
    800060d6:	8082                	ret

00000000800060d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060d8:	1141                	addi	sp,sp,-16
    800060da:	e406                	sd	ra,8(sp)
    800060dc:	e022                	sd	s0,0(sp)
    800060de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e0:	ffffc097          	auipc	ra,0xffffc
    800060e4:	8c8080e7          	jalr	-1848(ra) # 800019a8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060e8:	00d5179b          	slliw	a5,a0,0xd
    800060ec:	0c201537          	lui	a0,0xc201
    800060f0:	953e                	add	a0,a0,a5
  return irq;
}
    800060f2:	4148                	lw	a0,4(a0)
    800060f4:	60a2                	ld	ra,8(sp)
    800060f6:	6402                	ld	s0,0(sp)
    800060f8:	0141                	addi	sp,sp,16
    800060fa:	8082                	ret

00000000800060fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060fc:	1101                	addi	sp,sp,-32
    800060fe:	ec06                	sd	ra,24(sp)
    80006100:	e822                	sd	s0,16(sp)
    80006102:	e426                	sd	s1,8(sp)
    80006104:	1000                	addi	s0,sp,32
    80006106:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	8a0080e7          	jalr	-1888(ra) # 800019a8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006110:	00d5151b          	slliw	a0,a0,0xd
    80006114:	0c2017b7          	lui	a5,0xc201
    80006118:	97aa                	add	a5,a5,a0
    8000611a:	c3c4                	sw	s1,4(a5)
}
    8000611c:	60e2                	ld	ra,24(sp)
    8000611e:	6442                	ld	s0,16(sp)
    80006120:	64a2                	ld	s1,8(sp)
    80006122:	6105                	addi	sp,sp,32
    80006124:	8082                	ret

0000000080006126 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006126:	1141                	addi	sp,sp,-16
    80006128:	e406                	sd	ra,8(sp)
    8000612a:	e022                	sd	s0,0(sp)
    8000612c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000612e:	479d                	li	a5,7
    80006130:	06a7c963          	blt	a5,a0,800061a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006134:	0001d797          	auipc	a5,0x1d
    80006138:	ecc78793          	addi	a5,a5,-308 # 80023000 <disk>
    8000613c:	00a78733          	add	a4,a5,a0
    80006140:	6789                	lui	a5,0x2
    80006142:	97ba                	add	a5,a5,a4
    80006144:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006148:	e7ad                	bnez	a5,800061b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000614a:	00451793          	slli	a5,a0,0x4
    8000614e:	0001f717          	auipc	a4,0x1f
    80006152:	eb270713          	addi	a4,a4,-334 # 80025000 <disk+0x2000>
    80006156:	6314                	ld	a3,0(a4)
    80006158:	96be                	add	a3,a3,a5
    8000615a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000615e:	6314                	ld	a3,0(a4)
    80006160:	96be                	add	a3,a3,a5
    80006162:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006166:	6314                	ld	a3,0(a4)
    80006168:	96be                	add	a3,a3,a5
    8000616a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000616e:	6318                	ld	a4,0(a4)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006176:	0001d797          	auipc	a5,0x1d
    8000617a:	e8a78793          	addi	a5,a5,-374 # 80023000 <disk>
    8000617e:	97aa                	add	a5,a5,a0
    80006180:	6509                	lui	a0,0x2
    80006182:	953e                	add	a0,a0,a5
    80006184:	4785                	li	a5,1
    80006186:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000618a:	0001f517          	auipc	a0,0x1f
    8000618e:	e8e50513          	addi	a0,a0,-370 # 80025018 <disk+0x2018>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	38a080e7          	jalr	906(ra) # 8000251c <wakeup>
}
    8000619a:	60a2                	ld	ra,8(sp)
    8000619c:	6402                	ld	s0,0(sp)
    8000619e:	0141                	addi	sp,sp,16
    800061a0:	8082                	ret
    panic("free_desc 1");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	69650513          	addi	a0,a0,1686 # 80008838 <syscalls+0x338>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	394080e7          	jalr	916(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	69650513          	addi	a0,a0,1686 # 80008848 <syscalls+0x348>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	384080e7          	jalr	900(ra) # 8000053e <panic>

00000000800061c2 <virtio_disk_init>:
{
    800061c2:	1101                	addi	sp,sp,-32
    800061c4:	ec06                	sd	ra,24(sp)
    800061c6:	e822                	sd	s0,16(sp)
    800061c8:	e426                	sd	s1,8(sp)
    800061ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061cc:	00002597          	auipc	a1,0x2
    800061d0:	68c58593          	addi	a1,a1,1676 # 80008858 <syscalls+0x358>
    800061d4:	0001f517          	auipc	a0,0x1f
    800061d8:	f5450513          	addi	a0,a0,-172 # 80025128 <disk+0x2128>
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	978080e7          	jalr	-1672(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061e4:	100017b7          	lui	a5,0x10001
    800061e8:	4398                	lw	a4,0(a5)
    800061ea:	2701                	sext.w	a4,a4
    800061ec:	747277b7          	lui	a5,0x74727
    800061f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061f4:	0ef71163          	bne	a4,a5,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061f8:	100017b7          	lui	a5,0x10001
    800061fc:	43dc                	lw	a5,4(a5)
    800061fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006200:	4705                	li	a4,1
    80006202:	0ce79a63          	bne	a5,a4,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006206:	100017b7          	lui	a5,0x10001
    8000620a:	479c                	lw	a5,8(a5)
    8000620c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000620e:	4709                	li	a4,2
    80006210:	0ce79363          	bne	a5,a4,800062d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006214:	100017b7          	lui	a5,0x10001
    80006218:	47d8                	lw	a4,12(a5)
    8000621a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000621c:	554d47b7          	lui	a5,0x554d4
    80006220:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006224:	0af71963          	bne	a4,a5,800062d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006228:	100017b7          	lui	a5,0x10001
    8000622c:	4705                	li	a4,1
    8000622e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006230:	470d                	li	a4,3
    80006232:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006234:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006236:	c7ffe737          	lui	a4,0xc7ffe
    8000623a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000623e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006240:	2701                	sext.w	a4,a4
    80006242:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006244:	472d                	li	a4,11
    80006246:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006248:	473d                	li	a4,15
    8000624a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000624c:	6705                	lui	a4,0x1
    8000624e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006250:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006254:	5bdc                	lw	a5,52(a5)
    80006256:	2781                	sext.w	a5,a5
  if(max == 0)
    80006258:	c7d9                	beqz	a5,800062e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000625a:	471d                	li	a4,7
    8000625c:	08f77d63          	bgeu	a4,a5,800062f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006260:	100014b7          	lui	s1,0x10001
    80006264:	47a1                	li	a5,8
    80006266:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006268:	6609                	lui	a2,0x2
    8000626a:	4581                	li	a1,0
    8000626c:	0001d517          	auipc	a0,0x1d
    80006270:	d9450513          	addi	a0,a0,-620 # 80023000 <disk>
    80006274:	ffffb097          	auipc	ra,0xffffb
    80006278:	a6c080e7          	jalr	-1428(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000627c:	0001d717          	auipc	a4,0x1d
    80006280:	d8470713          	addi	a4,a4,-636 # 80023000 <disk>
    80006284:	00c75793          	srli	a5,a4,0xc
    80006288:	2781                	sext.w	a5,a5
    8000628a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000628c:	0001f797          	auipc	a5,0x1f
    80006290:	d7478793          	addi	a5,a5,-652 # 80025000 <disk+0x2000>
    80006294:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006296:	0001d717          	auipc	a4,0x1d
    8000629a:	dea70713          	addi	a4,a4,-534 # 80023080 <disk+0x80>
    8000629e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062a0:	0001e717          	auipc	a4,0x1e
    800062a4:	d6070713          	addi	a4,a4,-672 # 80024000 <disk+0x1000>
    800062a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062aa:	4705                	li	a4,1
    800062ac:	00e78c23          	sb	a4,24(a5)
    800062b0:	00e78ca3          	sb	a4,25(a5)
    800062b4:	00e78d23          	sb	a4,26(a5)
    800062b8:	00e78da3          	sb	a4,27(a5)
    800062bc:	00e78e23          	sb	a4,28(a5)
    800062c0:	00e78ea3          	sb	a4,29(a5)
    800062c4:	00e78f23          	sb	a4,30(a5)
    800062c8:	00e78fa3          	sb	a4,31(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret
    panic("could not find virtio disk");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	59250513          	addi	a0,a0,1426 # 80008868 <syscalls+0x368>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	260080e7          	jalr	608(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	5a250513          	addi	a0,a0,1442 # 80008888 <syscalls+0x388>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062f6:	00002517          	auipc	a0,0x2
    800062fa:	5b250513          	addi	a0,a0,1458 # 800088a8 <syscalls+0x3a8>
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	240080e7          	jalr	576(ra) # 8000053e <panic>

0000000080006306 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006306:	7159                	addi	sp,sp,-112
    80006308:	f486                	sd	ra,104(sp)
    8000630a:	f0a2                	sd	s0,96(sp)
    8000630c:	eca6                	sd	s1,88(sp)
    8000630e:	e8ca                	sd	s2,80(sp)
    80006310:	e4ce                	sd	s3,72(sp)
    80006312:	e0d2                	sd	s4,64(sp)
    80006314:	fc56                	sd	s5,56(sp)
    80006316:	f85a                	sd	s6,48(sp)
    80006318:	f45e                	sd	s7,40(sp)
    8000631a:	f062                	sd	s8,32(sp)
    8000631c:	ec66                	sd	s9,24(sp)
    8000631e:	e86a                	sd	s10,16(sp)
    80006320:	1880                	addi	s0,sp,112
    80006322:	892a                	mv	s2,a0
    80006324:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006326:	00c52c83          	lw	s9,12(a0)
    8000632a:	001c9c9b          	slliw	s9,s9,0x1
    8000632e:	1c82                	slli	s9,s9,0x20
    80006330:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006334:	0001f517          	auipc	a0,0x1f
    80006338:	df450513          	addi	a0,a0,-524 # 80025128 <disk+0x2128>
    8000633c:	ffffb097          	auipc	ra,0xffffb
    80006340:	8a8080e7          	jalr	-1880(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006344:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006346:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006348:	0001db97          	auipc	s7,0x1d
    8000634c:	cb8b8b93          	addi	s7,s7,-840 # 80023000 <disk>
    80006350:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006352:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006354:	8a4e                	mv	s4,s3
    80006356:	a051                	j	800063da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006358:	00fb86b3          	add	a3,s7,a5
    8000635c:	96da                	add	a3,a3,s6
    8000635e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006362:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006364:	0207c563          	bltz	a5,8000638e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006368:	2485                	addiw	s1,s1,1
    8000636a:	0711                	addi	a4,a4,4
    8000636c:	25548063          	beq	s1,s5,800065ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006370:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006372:	0001f697          	auipc	a3,0x1f
    80006376:	ca668693          	addi	a3,a3,-858 # 80025018 <disk+0x2018>
    8000637a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000637c:	0006c583          	lbu	a1,0(a3)
    80006380:	fde1                	bnez	a1,80006358 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006382:	2785                	addiw	a5,a5,1
    80006384:	0685                	addi	a3,a3,1
    80006386:	ff879be3          	bne	a5,s8,8000637c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000638a:	57fd                	li	a5,-1
    8000638c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000638e:	02905a63          	blez	s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006392:	f9042503          	lw	a0,-112(s0)
    80006396:	00000097          	auipc	ra,0x0
    8000639a:	d90080e7          	jalr	-624(ra) # 80006126 <free_desc>
      for(int j = 0; j < i; j++)
    8000639e:	4785                	li	a5,1
    800063a0:	0297d163          	bge	a5,s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063a4:	f9442503          	lw	a0,-108(s0)
    800063a8:	00000097          	auipc	ra,0x0
    800063ac:	d7e080e7          	jalr	-642(ra) # 80006126 <free_desc>
      for(int j = 0; j < i; j++)
    800063b0:	4789                	li	a5,2
    800063b2:	0097d863          	bge	a5,s1,800063c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063b6:	f9842503          	lw	a0,-104(s0)
    800063ba:	00000097          	auipc	ra,0x0
    800063be:	d6c080e7          	jalr	-660(ra) # 80006126 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063c2:	0001f597          	auipc	a1,0x1f
    800063c6:	d6658593          	addi	a1,a1,-666 # 80025128 <disk+0x2128>
    800063ca:	0001f517          	auipc	a0,0x1f
    800063ce:	c4e50513          	addi	a0,a0,-946 # 80025018 <disk+0x2018>
    800063d2:	ffffc097          	auipc	ra,0xffffc
    800063d6:	fb4080e7          	jalr	-76(ra) # 80002386 <sleep>
  for(int i = 0; i < 3; i++){
    800063da:	f9040713          	addi	a4,s0,-112
    800063de:	84ce                	mv	s1,s3
    800063e0:	bf41                	j	80006370 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063e2:	20058713          	addi	a4,a1,512
    800063e6:	00471693          	slli	a3,a4,0x4
    800063ea:	0001d717          	auipc	a4,0x1d
    800063ee:	c1670713          	addi	a4,a4,-1002 # 80023000 <disk>
    800063f2:	9736                	add	a4,a4,a3
    800063f4:	4685                	li	a3,1
    800063f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063fa:	20058713          	addi	a4,a1,512
    800063fe:	00471693          	slli	a3,a4,0x4
    80006402:	0001d717          	auipc	a4,0x1d
    80006406:	bfe70713          	addi	a4,a4,-1026 # 80023000 <disk>
    8000640a:	9736                	add	a4,a4,a3
    8000640c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006410:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006414:	7679                	lui	a2,0xffffe
    80006416:	963e                	add	a2,a2,a5
    80006418:	0001f697          	auipc	a3,0x1f
    8000641c:	be868693          	addi	a3,a3,-1048 # 80025000 <disk+0x2000>
    80006420:	6298                	ld	a4,0(a3)
    80006422:	9732                	add	a4,a4,a2
    80006424:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006426:	6298                	ld	a4,0(a3)
    80006428:	9732                	add	a4,a4,a2
    8000642a:	4541                	li	a0,16
    8000642c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000642e:	6298                	ld	a4,0(a3)
    80006430:	9732                	add	a4,a4,a2
    80006432:	4505                	li	a0,1
    80006434:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006438:	f9442703          	lw	a4,-108(s0)
    8000643c:	6288                	ld	a0,0(a3)
    8000643e:	962a                	add	a2,a2,a0
    80006440:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006444:	0712                	slli	a4,a4,0x4
    80006446:	6290                	ld	a2,0(a3)
    80006448:	963a                	add	a2,a2,a4
    8000644a:	05890513          	addi	a0,s2,88
    8000644e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006450:	6294                	ld	a3,0(a3)
    80006452:	96ba                	add	a3,a3,a4
    80006454:	40000613          	li	a2,1024
    80006458:	c690                	sw	a2,8(a3)
  if(write)
    8000645a:	140d0063          	beqz	s10,8000659a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000645e:	0001f697          	auipc	a3,0x1f
    80006462:	ba26b683          	ld	a3,-1118(a3) # 80025000 <disk+0x2000>
    80006466:	96ba                	add	a3,a3,a4
    80006468:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000646c:	0001d817          	auipc	a6,0x1d
    80006470:	b9480813          	addi	a6,a6,-1132 # 80023000 <disk>
    80006474:	0001f517          	auipc	a0,0x1f
    80006478:	b8c50513          	addi	a0,a0,-1140 # 80025000 <disk+0x2000>
    8000647c:	6114                	ld	a3,0(a0)
    8000647e:	96ba                	add	a3,a3,a4
    80006480:	00c6d603          	lhu	a2,12(a3)
    80006484:	00166613          	ori	a2,a2,1
    80006488:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000648c:	f9842683          	lw	a3,-104(s0)
    80006490:	6110                	ld	a2,0(a0)
    80006492:	9732                	add	a4,a4,a2
    80006494:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006498:	20058613          	addi	a2,a1,512
    8000649c:	0612                	slli	a2,a2,0x4
    8000649e:	9642                	add	a2,a2,a6
    800064a0:	577d                	li	a4,-1
    800064a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064a6:	00469713          	slli	a4,a3,0x4
    800064aa:	6114                	ld	a3,0(a0)
    800064ac:	96ba                	add	a3,a3,a4
    800064ae:	03078793          	addi	a5,a5,48
    800064b2:	97c2                	add	a5,a5,a6
    800064b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064b6:	611c                	ld	a5,0(a0)
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	4685                	li	a3,1
    800064bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064be:	611c                	ld	a5,0(a0)
    800064c0:	97ba                	add	a5,a5,a4
    800064c2:	4809                	li	a6,2
    800064c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064c8:	611c                	ld	a5,0(a0)
    800064ca:	973e                	add	a4,a4,a5
    800064cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d8:	6518                	ld	a4,8(a0)
    800064da:	00275783          	lhu	a5,2(a4)
    800064de:	8b9d                	andi	a5,a5,7
    800064e0:	0786                	slli	a5,a5,0x1
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ec:	6518                	ld	a4,8(a0)
    800064ee:	00275783          	lhu	a5,2(a4)
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064fc:	100017b7          	lui	a5,0x10001
    80006500:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006504:	00492703          	lw	a4,4(s2)
    80006508:	4785                	li	a5,1
    8000650a:	02f71163          	bne	a4,a5,8000652c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000650e:	0001f997          	auipc	s3,0x1f
    80006512:	c1a98993          	addi	s3,s3,-998 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006516:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006518:	85ce                	mv	a1,s3
    8000651a:	854a                	mv	a0,s2
    8000651c:	ffffc097          	auipc	ra,0xffffc
    80006520:	e6a080e7          	jalr	-406(ra) # 80002386 <sleep>
  while(b->disk == 1) {
    80006524:	00492783          	lw	a5,4(s2)
    80006528:	fe9788e3          	beq	a5,s1,80006518 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000652c:	f9042903          	lw	s2,-112(s0)
    80006530:	20090793          	addi	a5,s2,512
    80006534:	00479713          	slli	a4,a5,0x4
    80006538:	0001d797          	auipc	a5,0x1d
    8000653c:	ac878793          	addi	a5,a5,-1336 # 80023000 <disk>
    80006540:	97ba                	add	a5,a5,a4
    80006542:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006546:	0001f997          	auipc	s3,0x1f
    8000654a:	aba98993          	addi	s3,s3,-1350 # 80025000 <disk+0x2000>
    8000654e:	00491713          	slli	a4,s2,0x4
    80006552:	0009b783          	ld	a5,0(s3)
    80006556:	97ba                	add	a5,a5,a4
    80006558:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000655c:	854a                	mv	a0,s2
    8000655e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006562:	00000097          	auipc	ra,0x0
    80006566:	bc4080e7          	jalr	-1084(ra) # 80006126 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000656a:	8885                	andi	s1,s1,1
    8000656c:	f0ed                	bnez	s1,8000654e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000656e:	0001f517          	auipc	a0,0x1f
    80006572:	bba50513          	addi	a0,a0,-1094 # 80025128 <disk+0x2128>
    80006576:	ffffa097          	auipc	ra,0xffffa
    8000657a:	722080e7          	jalr	1826(ra) # 80000c98 <release>
}
    8000657e:	70a6                	ld	ra,104(sp)
    80006580:	7406                	ld	s0,96(sp)
    80006582:	64e6                	ld	s1,88(sp)
    80006584:	6946                	ld	s2,80(sp)
    80006586:	69a6                	ld	s3,72(sp)
    80006588:	6a06                	ld	s4,64(sp)
    8000658a:	7ae2                	ld	s5,56(sp)
    8000658c:	7b42                	ld	s6,48(sp)
    8000658e:	7ba2                	ld	s7,40(sp)
    80006590:	7c02                	ld	s8,32(sp)
    80006592:	6ce2                	ld	s9,24(sp)
    80006594:	6d42                	ld	s10,16(sp)
    80006596:	6165                	addi	sp,sp,112
    80006598:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000659a:	0001f697          	auipc	a3,0x1f
    8000659e:	a666b683          	ld	a3,-1434(a3) # 80025000 <disk+0x2000>
    800065a2:	96ba                	add	a3,a3,a4
    800065a4:	4609                	li	a2,2
    800065a6:	00c69623          	sh	a2,12(a3)
    800065aa:	b5c9                	j	8000646c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065ac:	f9042583          	lw	a1,-112(s0)
    800065b0:	20058793          	addi	a5,a1,512
    800065b4:	0792                	slli	a5,a5,0x4
    800065b6:	0001d517          	auipc	a0,0x1d
    800065ba:	af250513          	addi	a0,a0,-1294 # 800230a8 <disk+0xa8>
    800065be:	953e                	add	a0,a0,a5
  if(write)
    800065c0:	e20d11e3          	bnez	s10,800063e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065c4:	20058713          	addi	a4,a1,512
    800065c8:	00471693          	slli	a3,a4,0x4
    800065cc:	0001d717          	auipc	a4,0x1d
    800065d0:	a3470713          	addi	a4,a4,-1484 # 80023000 <disk>
    800065d4:	9736                	add	a4,a4,a3
    800065d6:	0a072423          	sw	zero,168(a4)
    800065da:	b505                	j	800063fa <virtio_disk_rw+0xf4>

00000000800065dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065dc:	1101                	addi	sp,sp,-32
    800065de:	ec06                	sd	ra,24(sp)
    800065e0:	e822                	sd	s0,16(sp)
    800065e2:	e426                	sd	s1,8(sp)
    800065e4:	e04a                	sd	s2,0(sp)
    800065e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065e8:	0001f517          	auipc	a0,0x1f
    800065ec:	b4050513          	addi	a0,a0,-1216 # 80025128 <disk+0x2128>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	5f4080e7          	jalr	1524(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065f8:	10001737          	lui	a4,0x10001
    800065fc:	533c                	lw	a5,96(a4)
    800065fe:	8b8d                	andi	a5,a5,3
    80006600:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006602:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006606:	0001f797          	auipc	a5,0x1f
    8000660a:	9fa78793          	addi	a5,a5,-1542 # 80025000 <disk+0x2000>
    8000660e:	6b94                	ld	a3,16(a5)
    80006610:	0207d703          	lhu	a4,32(a5)
    80006614:	0026d783          	lhu	a5,2(a3)
    80006618:	06f70163          	beq	a4,a5,8000667a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000661c:	0001d917          	auipc	s2,0x1d
    80006620:	9e490913          	addi	s2,s2,-1564 # 80023000 <disk>
    80006624:	0001f497          	auipc	s1,0x1f
    80006628:	9dc48493          	addi	s1,s1,-1572 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000662c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006630:	6898                	ld	a4,16(s1)
    80006632:	0204d783          	lhu	a5,32(s1)
    80006636:	8b9d                	andi	a5,a5,7
    80006638:	078e                	slli	a5,a5,0x3
    8000663a:	97ba                	add	a5,a5,a4
    8000663c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000663e:	20078713          	addi	a4,a5,512
    80006642:	0712                	slli	a4,a4,0x4
    80006644:	974a                	add	a4,a4,s2
    80006646:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000664a:	e731                	bnez	a4,80006696 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000664c:	20078793          	addi	a5,a5,512
    80006650:	0792                	slli	a5,a5,0x4
    80006652:	97ca                	add	a5,a5,s2
    80006654:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006656:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000665a:	ffffc097          	auipc	ra,0xffffc
    8000665e:	ec2080e7          	jalr	-318(ra) # 8000251c <wakeup>

    disk.used_idx += 1;
    80006662:	0204d783          	lhu	a5,32(s1)
    80006666:	2785                	addiw	a5,a5,1
    80006668:	17c2                	slli	a5,a5,0x30
    8000666a:	93c1                	srli	a5,a5,0x30
    8000666c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006670:	6898                	ld	a4,16(s1)
    80006672:	00275703          	lhu	a4,2(a4)
    80006676:	faf71be3          	bne	a4,a5,8000662c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000667a:	0001f517          	auipc	a0,0x1f
    8000667e:	aae50513          	addi	a0,a0,-1362 # 80025128 <disk+0x2128>
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	616080e7          	jalr	1558(ra) # 80000c98 <release>
}
    8000668a:	60e2                	ld	ra,24(sp)
    8000668c:	6442                	ld	s0,16(sp)
    8000668e:	64a2                	ld	s1,8(sp)
    80006690:	6902                	ld	s2,0(sp)
    80006692:	6105                	addi	sp,sp,32
    80006694:	8082                	ret
      panic("virtio_disk_intr status");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	23250513          	addi	a0,a0,562 # 800088c8 <syscalls+0x3c8>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
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
