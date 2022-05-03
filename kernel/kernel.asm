
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	c8c78793          	addi	a5,a5,-884 # 80005cf0 <timervec>
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
    80000130:	518080e7          	jalr	1304(ra) # 80002644 <either_copyin>
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
    80000190:	00450513          	addi	a0,a0,4 # 80011190 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ff448493          	addi	s1,s1,-12 # 80011190 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	08290913          	addi	s2,s2,130 # 80011228 <cons+0x98>
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
    800001c8:	98c080e7          	jalr	-1652(ra) # 80001b50 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	076080e7          	jalr	118(ra) # 8000224a <sleep>
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
    80000214:	3de080e7          	jalr	990(ra) # 800025ee <either_copyout>
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
    80000228:	f6c50513          	addi	a0,a0,-148 # 80011190 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f5650513          	addi	a0,a0,-170 # 80011190 <cons>
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
    80000276:	faf72b23          	sw	a5,-74(a4) # 80011228 <cons+0x98>
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
    800002d0:	ec450513          	addi	a0,a0,-316 # 80011190 <cons>
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
    800002f6:	3a8080e7          	jalr	936(ra) # 8000269a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e9650513          	addi	a0,a0,-362 # 80011190 <cons>
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
    80000322:	e7270713          	addi	a4,a4,-398 # 80011190 <cons>
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
    8000034c:	e4878793          	addi	a5,a5,-440 # 80011190 <cons>
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
    8000037a:	eb27a783          	lw	a5,-334(a5) # 80011228 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e0670713          	addi	a4,a4,-506 # 80011190 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	df648493          	addi	s1,s1,-522 # 80011190 <cons>
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
    800003da:	dba70713          	addi	a4,a4,-582 # 80011190 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72223          	sw	a5,-444(a4) # 80011230 <cons+0xa0>
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
    80000416:	d7e78793          	addi	a5,a5,-642 # 80011190 <cons>
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
    8000043a:	dec7ab23          	sw	a2,-522(a5) # 8001122c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dea50513          	addi	a0,a0,-534 # 80011228 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f90080e7          	jalr	-112(ra) # 800023d6 <wakeup>
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
    80000464:	d3050513          	addi	a0,a0,-720 # 80011190 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	33078793          	addi	a5,a5,816 # 800217a8 <devsw>
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
    8000054e:	d007a323          	sw	zero,-762(a5) # 80011250 <pr+0x18>
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
    800005be:	c96dad83          	lw	s11,-874(s11) # 80011250 <pr+0x18>
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
    800005fc:	c4050513          	addi	a0,a0,-960 # 80011238 <pr>
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
    80000760:	adc50513          	addi	a0,a0,-1316 # 80011238 <pr>
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
    8000077c:	ac048493          	addi	s1,s1,-1344 # 80011238 <pr>
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
    800007dc:	a8050513          	addi	a0,a0,-1408 # 80011258 <uart_tx_lock>
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
    8000086e:	9eea0a13          	addi	s4,s4,-1554 # 80011258 <uart_tx_lock>
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
    800008a4:	b36080e7          	jalr	-1226(ra) # 800023d6 <wakeup>
    
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
    800008e0:	97c50513          	addi	a0,a0,-1668 # 80011258 <uart_tx_lock>
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
    80000914:	948a0a13          	addi	s4,s4,-1720 # 80011258 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	91e080e7          	jalr	-1762(ra) # 8000224a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	91648493          	addi	s1,s1,-1770 # 80011258 <uart_tx_lock>
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
    800009ce:	88e48493          	addi	s1,s1,-1906 # 80011258 <uart_tx_lock>
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
    80000a30:	86490913          	addi	s2,s2,-1948 # 80011290 <kmem>
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
    80000acc:	7c850513          	addi	a0,a0,1992 # 80011290 <kmem>
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
    80000b02:	79248493          	addi	s1,s1,1938 # 80011290 <kmem>
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
    80000b1a:	77a50513          	addi	a0,a0,1914 # 80011290 <kmem>
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
    80000b46:	74e50513          	addi	a0,a0,1870 # 80011290 <kmem>
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
    80000b82:	fae080e7          	jalr	-82(ra) # 80001b2c <mycpu>
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
    80000bb4:	f7c080e7          	jalr	-132(ra) # 80001b2c <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f70080e7          	jalr	-144(ra) # 80001b2c <mycpu>
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
    80000bd8:	f58080e7          	jalr	-168(ra) # 80001b2c <mycpu>
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
    80000c18:	f18080e7          	jalr	-232(ra) # 80001b2c <mycpu>
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
    80000c44:	eec080e7          	jalr	-276(ra) # 80001b2c <mycpu>
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
    80000e9a:	c86080e7          	jalr	-890(ra) # 80001b1c <cpuid>
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
    80000eb6:	c6a080e7          	jalr	-918(ra) # 80001b1c <cpuid>
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
    80000ed8:	906080e7          	jalr	-1786(ra) # 800027da <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e54080e7          	jalr	-428(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1a2080e7          	jalr	418(ra) # 80002086 <scheduler>
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
    80000f48:	b28080e7          	jalr	-1240(ra) # 80001a6c <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	866080e7          	jalr	-1946(ra) # 800027b2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	886080e7          	jalr	-1914(ra) # 800027da <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	dbe080e7          	jalr	-578(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	dcc080e7          	jalr	-564(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	fb0080e7          	jalr	-80(ra) # 80002f1c <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	640080e7          	jalr	1600(ra) # 800035b4 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	5ea080e7          	jalr	1514(ra) # 80004566 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ece080e7          	jalr	-306(ra) # 80005e52 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	e98080e7          	jalr	-360(ra) # 80001e24 <userinit>
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
    80001240:	00000097          	auipc	ra,0x0
    80001244:	796080e7          	jalr	1942(ra) # 800019d6 <proc_mapstacks>
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

000000008000183e <initialize_list>:

struct _list *unused_list;   // contains all UNUSED process entries.
struct _list *sleeping_list; // contains all SLEEPING processes.
struct _list *zombie_list;   // contains all ZOMBIE processes.

void initialize_list(struct _list *lst){
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e422                	sd	s0,8(sp)
    80001842:	0800                	addi	s0,sp,16
  lst->head = -1;
    80001844:	57fd                	li	a5,-1
    80001846:	c11c                	sw	a5,0(a0)
  lst->tail = -1;
    80001848:	c15c                	sw	a5,4(a0)
}
    8000184a:	6422                	ld	s0,8(sp)
    8000184c:	0141                	addi	sp,sp,16
    8000184e:	8082                	ret

0000000080001850 <initialize_lists>:

void initialize_lists(void){
    80001850:	1141                	addi	sp,sp,-16
    80001852:	e406                	sd	ra,8(sp)
    80001854:	e022                	sd	s0,0(sp)
    80001856:	0800                	addi	s0,sp,16
  initialize_list(unused_list);
    80001858:	00007717          	auipc	a4,0x7
    8000185c:	7e073703          	ld	a4,2016(a4) # 80009038 <unused_list>
  lst->head = -1;
    80001860:	57fd                	li	a5,-1
    80001862:	c31c                	sw	a5,0(a4)
  lst->tail = -1;
    80001864:	c35c                	sw	a5,4(a4)
  initialize_list(sleeping_list);
    80001866:	00007717          	auipc	a4,0x7
    8000186a:	7ca73703          	ld	a4,1994(a4) # 80009030 <sleeping_list>
  lst->head = -1;
    8000186e:	c31c                	sw	a5,0(a4)
  lst->tail = -1;
    80001870:	c35c                	sw	a5,4(a4)
  initialize_list(zombie_list);
    80001872:	00007717          	auipc	a4,0x7
    80001876:	7b673703          	ld	a4,1974(a4) # 80009028 <zombie_list>
  lst->head = -1;
    8000187a:	c31c                	sw	a5,0(a4)
  lst->tail = -1;
    8000187c:	c35c                	sw	a5,4(a4)

  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU]; c++)
    8000187e:	00010797          	auipc	a5,0x10
    80001882:	a3278793          	addi	a5,a5,-1486 # 800112b0 <cpus>
  lst->head = -1;
    80001886:	56fd                	li	a3,-1
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001888:	00010617          	auipc	a2,0x10
    8000188c:	ea860613          	addi	a2,a2,-344 # 80011730 <pid_lock>
   initialize_list(c->runnable_list);
    80001890:	63d8                	ld	a4,128(a5)
  lst->head = -1;
    80001892:	c314                	sw	a3,0(a4)
  lst->tail = -1;
    80001894:	c354                	sw	a3,4(a4)
  for(c = cpus; c < &cpus[NCPU]; c++)
    80001896:	09078793          	addi	a5,a5,144
    8000189a:	fec79be3          	bne	a5,a2,80001890 <initialize_lists+0x40>
  printf("here");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	93a50513          	addi	a0,a0,-1734 # 800081d8 <digits+0x198>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
}
    800018ae:	60a2                	ld	ra,8(sp)
    800018b0:	6402                	ld	s0,0(sp)
    800018b2:	0141                	addi	sp,sp,16
    800018b4:	8082                	ret

00000000800018b6 <initialize_proc>:

void
initialize_proc(struct proc *p){
    800018b6:	1141                	addi	sp,sp,-16
    800018b8:	e422                	sd	s0,8(sp)
    800018ba:	0800                	addi	s0,sp,16
  proc->next_index = -1;
    800018bc:	00010797          	auipc	a5,0x10
    800018c0:	ea478793          	addi	a5,a5,-348 # 80011760 <proc>
    800018c4:	577d                	li	a4,-1
    800018c6:	16e7a823          	sw	a4,368(a5)
  proc->prev_index = -1;
    800018ca:	16e7a623          	sw	a4,364(a5)
}
    800018ce:	6422                	ld	s0,8(sp)
    800018d0:	0141                	addi	sp,sp,16
    800018d2:	8082                	ret

00000000800018d4 <isEmpty>:

int
isEmpty(struct _list *lst){
    800018d4:	1141                	addi	sp,sp,-16
    800018d6:	e422                	sd	s0,8(sp)
    800018d8:	0800                	addi	s0,sp,16
  return lst->tail == -1;
    800018da:	4148                	lw	a0,4(a0)
    800018dc:	0505                	addi	a0,a0,1
}
    800018de:	00153513          	seqz	a0,a0
    800018e2:	6422                	ld	s0,8(sp)
    800018e4:	0141                	addi	sp,sp,16
    800018e6:	8082                	ret

00000000800018e8 <insert_proc_to_list>:

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    800018e8:	1141                	addi	sp,sp,-16
    800018ea:	e422                	sd	s0,8(sp)
    800018ec:	0800                	addi	s0,sp,16
  return lst->tail == -1;
    800018ee:	415c                	lw	a5,4(a0)
  if(isEmpty(lst)){
    800018f0:	577d                	li	a4,-1
    800018f2:	00e79b63          	bne	a5,a4,80001908 <insert_proc_to_list+0x20>
    lst->head = p->index;
    800018f6:	1685a783          	lw	a5,360(a1) # 4000168 <_entry-0x7bfffe98>
    800018fa:	c11c                	sw	a5,0(a0)
    lst->tail = p-> index;
    800018fc:	1685a783          	lw	a5,360(a1)
    80001900:	c15c                	sw	a5,4(a0)
    struct proc *p_tail = &proc[lst->tail];
    p_tail->next_index = p->index; // update next proc of the curr tail
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    lst->tail = p->index;          // update tail
  }
}
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret
    p_tail->next_index = p->index; // update next proc of the curr tail
    80001908:	1685a683          	lw	a3,360(a1)
    8000190c:	17800713          	li	a4,376
    80001910:	02e787b3          	mul	a5,a5,a4
    80001914:	00010717          	auipc	a4,0x10
    80001918:	e4c70713          	addi	a4,a4,-436 # 80011760 <proc>
    8000191c:	97ba                	add	a5,a5,a4
    8000191e:	16d7a823          	sw	a3,368(a5)
    p->prev_index = p_tail->index; // update the prev proc of the new proc
    80001922:	1687a783          	lw	a5,360(a5)
    80001926:	16f5a623          	sw	a5,364(a1)
    lst->tail = p->index;          // update tail
    8000192a:	c154                	sw	a3,4(a0)
}
    8000192c:	bfd9                	j	80001902 <insert_proc_to_list+0x1a>

000000008000192e <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    8000192e:	1141                	addi	sp,sp,-16
    80001930:	e422                	sd	s0,8(sp)
    80001932:	0800                	addi	s0,sp,16
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    80001934:	1685a783          	lw	a5,360(a1)
    80001938:	4118                	lw	a4,0(a0)
    8000193a:	04f70763          	beq	a4,a5,80001988 <remove_proc_to_list+0x5a>
    initialize_list(lst);
  else if(lst->head == p-> index) {  // p is the head of the list
    lst->head = p->next_index;
    proc[lst->head].prev_index = -1;
  }
  else if(lst->tail == p-> index) { // p is the tail of the list
    8000193e:	4158                	lw	a4,4(a0)
    80001940:	06f70b63          	beq	a4,a5,800019b6 <remove_proc_to_list+0x88>
    lst->tail = p->prev_index;
    proc[lst->tail].next_index = -1;
  }
  else {
    proc[p->prev_index].next_index = p->next_index;
    80001944:	16c5a783          	lw	a5,364(a1)
    80001948:	1705a683          	lw	a3,368(a1)
    8000194c:	00010717          	auipc	a4,0x10
    80001950:	e1470713          	addi	a4,a4,-492 # 80011760 <proc>
    80001954:	17800613          	li	a2,376
    80001958:	02c787b3          	mul	a5,a5,a2
    8000195c:	97ba                	add	a5,a5,a4
    8000195e:	16d7a823          	sw	a3,368(a5)
    proc[p->next_index].prev_index = p->prev_index;
    80001962:	16c5a783          	lw	a5,364(a1)
    80001966:	02c686b3          	mul	a3,a3,a2
    8000196a:	9736                	add	a4,a4,a3
    8000196c:	16f72623          	sw	a5,364(a4)
  proc->next_index = -1;
    80001970:	00010797          	auipc	a5,0x10
    80001974:	df078793          	addi	a5,a5,-528 # 80011760 <proc>
    80001978:	577d                	li	a4,-1
    8000197a:	16e7a823          	sw	a4,368(a5)
  proc->prev_index = -1;
    8000197e:	16e7a623          	sw	a4,364(a5)
  }
  initialize_proc(p);
}
    80001982:	6422                	ld	s0,8(sp)
    80001984:	0141                	addi	sp,sp,16
    80001986:	8082                	ret
  if(lst->head == p->index && lst->tail == p->index) // p is the only proc in the list
    80001988:	4158                	lw	a4,4(a0)
    8000198a:	02f70263          	beq	a4,a5,800019ae <remove_proc_to_list+0x80>
    lst->head = p->next_index;
    8000198e:	1705a783          	lw	a5,368(a1)
    80001992:	c11c                	sw	a5,0(a0)
    proc[lst->head].prev_index = -1;
    80001994:	17800713          	li	a4,376
    80001998:	02e787b3          	mul	a5,a5,a4
    8000199c:	00010717          	auipc	a4,0x10
    800019a0:	dc470713          	addi	a4,a4,-572 # 80011760 <proc>
    800019a4:	97ba                	add	a5,a5,a4
    800019a6:	577d                	li	a4,-1
    800019a8:	16e7a623          	sw	a4,364(a5)
    800019ac:	b7d1                	j	80001970 <remove_proc_to_list+0x42>
  lst->head = -1;
    800019ae:	57fd                	li	a5,-1
    800019b0:	c11c                	sw	a5,0(a0)
  lst->tail = -1;
    800019b2:	c15c                	sw	a5,4(a0)
}
    800019b4:	bf75                	j	80001970 <remove_proc_to_list+0x42>
    lst->tail = p->prev_index;
    800019b6:	16c5a783          	lw	a5,364(a1)
    800019ba:	c15c                	sw	a5,4(a0)
    proc[lst->tail].next_index = -1;
    800019bc:	17800713          	li	a4,376
    800019c0:	02e787b3          	mul	a5,a5,a4
    800019c4:	00010717          	auipc	a4,0x10
    800019c8:	d9c70713          	addi	a4,a4,-612 # 80011760 <proc>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	577d                	li	a4,-1
    800019d0:	16e7a823          	sw	a4,368(a5)
    800019d4:	bf71                	j	80001970 <remove_proc_to_list+0x42>

00000000800019d6 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800019d6:	7139                	addi	sp,sp,-64
    800019d8:	fc06                	sd	ra,56(sp)
    800019da:	f822                	sd	s0,48(sp)
    800019dc:	f426                	sd	s1,40(sp)
    800019de:	f04a                	sd	s2,32(sp)
    800019e0:	ec4e                	sd	s3,24(sp)
    800019e2:	e852                	sd	s4,16(sp)
    800019e4:	e456                	sd	s5,8(sp)
    800019e6:	e05a                	sd	s6,0(sp)
    800019e8:	0080                	addi	s0,sp,64
    800019ea:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ec:	00010497          	auipc	s1,0x10
    800019f0:	d7448493          	addi	s1,s1,-652 # 80011760 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019f4:	8b26                	mv	s6,s1
    800019f6:	00006a97          	auipc	s5,0x6
    800019fa:	60aa8a93          	addi	s5,s5,1546 # 80008000 <etext>
    800019fe:	04000937          	lui	s2,0x4000
    80001a02:	197d                	addi	s2,s2,-1
    80001a04:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a06:	00016a17          	auipc	s4,0x16
    80001a0a:	b5aa0a13          	addi	s4,s4,-1190 # 80017560 <tickslock>
    char *pa = kalloc();
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	0e6080e7          	jalr	230(ra) # 80000af4 <kalloc>
    80001a16:	862a                	mv	a2,a0
    if(pa == 0)
    80001a18:	c131                	beqz	a0,80001a5c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a1a:	416485b3          	sub	a1,s1,s6
    80001a1e:	858d                	srai	a1,a1,0x3
    80001a20:	000ab783          	ld	a5,0(s5)
    80001a24:	02f585b3          	mul	a1,a1,a5
    80001a28:	2585                	addiw	a1,a1,1
    80001a2a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a2e:	4719                	li	a4,6
    80001a30:	6685                	lui	a3,0x1
    80001a32:	40b905b3          	sub	a1,s2,a1
    80001a36:	854e                	mv	a0,s3
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	718080e7          	jalr	1816(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a40:	17848493          	addi	s1,s1,376
    80001a44:	fd4495e3          	bne	s1,s4,80001a0e <proc_mapstacks+0x38>
  }
}
    80001a48:	70e2                	ld	ra,56(sp)
    80001a4a:	7442                	ld	s0,48(sp)
    80001a4c:	74a2                	ld	s1,40(sp)
    80001a4e:	7902                	ld	s2,32(sp)
    80001a50:	69e2                	ld	s3,24(sp)
    80001a52:	6a42                	ld	s4,16(sp)
    80001a54:	6aa2                	ld	s5,8(sp)
    80001a56:	6b02                	ld	s6,0(sp)
    80001a58:	6121                	addi	sp,sp,64
    80001a5a:	8082                	ret
      panic("kalloc");
    80001a5c:	00006517          	auipc	a0,0x6
    80001a60:	78450513          	addi	a0,a0,1924 # 800081e0 <digits+0x1a0>
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>

0000000080001a6c <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a6c:	7139                	addi	sp,sp,-64
    80001a6e:	fc06                	sd	ra,56(sp)
    80001a70:	f822                	sd	s0,48(sp)
    80001a72:	f426                	sd	s1,40(sp)
    80001a74:	f04a                	sd	s2,32(sp)
    80001a76:	ec4e                	sd	s3,24(sp)
    80001a78:	e852                	sd	s4,16(sp)
    80001a7a:	e456                	sd	s5,8(sp)
    80001a7c:	e05a                	sd	s6,0(sp)
    80001a7e:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a80:	00006597          	auipc	a1,0x6
    80001a84:	76858593          	addi	a1,a1,1896 # 800081e8 <digits+0x1a8>
    80001a88:	00010517          	auipc	a0,0x10
    80001a8c:	ca850513          	addi	a0,a0,-856 # 80011730 <pid_lock>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	0c4080e7          	jalr	196(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a98:	00006597          	auipc	a1,0x6
    80001a9c:	75858593          	addi	a1,a1,1880 # 800081f0 <digits+0x1b0>
    80001aa0:	00010517          	auipc	a0,0x10
    80001aa4:	ca850513          	addi	a0,a0,-856 # 80011748 <wait_lock>
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	0ac080e7          	jalr	172(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab0:	00010497          	auipc	s1,0x10
    80001ab4:	cb048493          	addi	s1,s1,-848 # 80011760 <proc>
      initlock(&p->lock, "proc");
    80001ab8:	00006b17          	auipc	s6,0x6
    80001abc:	748b0b13          	addi	s6,s6,1864 # 80008200 <digits+0x1c0>
      p->kstack = KSTACK((int) (p - proc));
    80001ac0:	8aa6                	mv	s5,s1
    80001ac2:	00006a17          	auipc	s4,0x6
    80001ac6:	53ea0a13          	addi	s4,s4,1342 # 80008000 <etext>
    80001aca:	04000937          	lui	s2,0x4000
    80001ace:	197d                	addi	s2,s2,-1
    80001ad0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad2:	00016997          	auipc	s3,0x16
    80001ad6:	a8e98993          	addi	s3,s3,-1394 # 80017560 <tickslock>
      initlock(&p->lock, "proc");
    80001ada:	85da                	mv	a1,s6
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	076080e7          	jalr	118(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ae6:	415487b3          	sub	a5,s1,s5
    80001aea:	878d                	srai	a5,a5,0x3
    80001aec:	000a3703          	ld	a4,0(s4)
    80001af0:	02e787b3          	mul	a5,a5,a4
    80001af4:	2785                	addiw	a5,a5,1
    80001af6:	00d7979b          	slliw	a5,a5,0xd
    80001afa:	40f907b3          	sub	a5,s2,a5
    80001afe:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b00:	17848493          	addi	s1,s1,376
    80001b04:	fd349be3          	bne	s1,s3,80001ada <procinit+0x6e>
  }
}
    80001b08:	70e2                	ld	ra,56(sp)
    80001b0a:	7442                	ld	s0,48(sp)
    80001b0c:	74a2                	ld	s1,40(sp)
    80001b0e:	7902                	ld	s2,32(sp)
    80001b10:	69e2                	ld	s3,24(sp)
    80001b12:	6a42                	ld	s4,16(sp)
    80001b14:	6aa2                	ld	s5,8(sp)
    80001b16:	6b02                	ld	s6,0(sp)
    80001b18:	6121                	addi	sp,sp,64
    80001b1a:	8082                	ret

0000000080001b1c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b1c:	1141                	addi	sp,sp,-16
    80001b1e:	e422                	sd	s0,8(sp)
    80001b20:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b22:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b24:	2501                	sext.w	a0,a0
    80001b26:	6422                	ld	s0,8(sp)
    80001b28:	0141                	addi	sp,sp,16
    80001b2a:	8082                	ret

0000000080001b2c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b2c:	1141                	addi	sp,sp,-16
    80001b2e:	e422                	sd	s0,8(sp)
    80001b30:	0800                	addi	s0,sp,16
    80001b32:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b34:	0007851b          	sext.w	a0,a5
    80001b38:	00351793          	slli	a5,a0,0x3
    80001b3c:	97aa                	add	a5,a5,a0
    80001b3e:	0792                	slli	a5,a5,0x4
  return c;
}
    80001b40:	0000f517          	auipc	a0,0xf
    80001b44:	77050513          	addi	a0,a0,1904 # 800112b0 <cpus>
    80001b48:	953e                	add	a0,a0,a5
    80001b4a:	6422                	ld	s0,8(sp)
    80001b4c:	0141                	addi	sp,sp,16
    80001b4e:	8082                	ret

0000000080001b50 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	1000                	addi	s0,sp,32
  push_off();
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	03e080e7          	jalr	62(ra) # 80000b98 <push_off>
    80001b62:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b64:	0007871b          	sext.w	a4,a5
    80001b68:	00371793          	slli	a5,a4,0x3
    80001b6c:	97ba                	add	a5,a5,a4
    80001b6e:	0792                	slli	a5,a5,0x4
    80001b70:	0000f717          	auipc	a4,0xf
    80001b74:	74070713          	addi	a4,a4,1856 # 800112b0 <cpus>
    80001b78:	97ba                	add	a5,a5,a4
    80001b7a:	6384                	ld	s1,0(a5)
  pop_off();
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	0bc080e7          	jalr	188(ra) # 80000c38 <pop_off>
  return p;
}
    80001b84:	8526                	mv	a0,s1
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b90:	1141                	addi	sp,sp,-16
    80001b92:	e406                	sd	ra,8(sp)
    80001b94:	e022                	sd	s0,0(sp)
    80001b96:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	fb8080e7          	jalr	-72(ra) # 80001b50 <myproc>
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	0f8080e7          	jalr	248(ra) # 80000c98 <release>

  if (first) {
    80001ba8:	00007797          	auipc	a5,0x7
    80001bac:	c787a783          	lw	a5,-904(a5) # 80008820 <first.1728>
    80001bb0:	eb89                	bnez	a5,80001bc2 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bb2:	00001097          	auipc	ra,0x1
    80001bb6:	c40080e7          	jalr	-960(ra) # 800027f2 <usertrapret>
}
    80001bba:	60a2                	ld	ra,8(sp)
    80001bbc:	6402                	ld	s0,0(sp)
    80001bbe:	0141                	addi	sp,sp,16
    80001bc0:	8082                	ret
    first = 0;
    80001bc2:	00007797          	auipc	a5,0x7
    80001bc6:	c407af23          	sw	zero,-930(a5) # 80008820 <first.1728>
    fsinit(ROOTDEV);
    80001bca:	4505                	li	a0,1
    80001bcc:	00002097          	auipc	ra,0x2
    80001bd0:	968080e7          	jalr	-1688(ra) # 80003534 <fsinit>
    80001bd4:	bff9                	j	80001bb2 <forkret+0x22>

0000000080001bd6 <allocpid>:
allocpid() {
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001be2:	00007917          	auipc	s2,0x7
    80001be6:	c4290913          	addi	s2,s2,-958 # 80008824 <nextpid>
    80001bea:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001bee:	0014861b          	addiw	a2,s1,1
    80001bf2:	85a6                	mv	a1,s1
    80001bf4:	854a                	mv	a0,s2
    80001bf6:	00004097          	auipc	ra,0x4
    80001bfa:	740080e7          	jalr	1856(ra) # 80006336 <cas>
    80001bfe:	2501                	sext.w	a0,a0
    80001c00:	f56d                	bnez	a0,80001bea <allocpid+0x14>
}
    80001c02:	8526                	mv	a0,s1
    80001c04:	60e2                	ld	ra,24(sp)
    80001c06:	6442                	ld	s0,16(sp)
    80001c08:	64a2                	ld	s1,8(sp)
    80001c0a:	6902                	ld	s2,0(sp)
    80001c0c:	6105                	addi	sp,sp,32
    80001c0e:	8082                	ret

0000000080001c10 <proc_pagetable>:
{
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	e04a                	sd	s2,0(sp)
    80001c1a:	1000                	addi	s0,sp,32
    80001c1c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	71c080e7          	jalr	1820(ra) # 8000133a <uvmcreate>
    80001c26:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c28:	c121                	beqz	a0,80001c68 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c2a:	4729                	li	a4,10
    80001c2c:	00005697          	auipc	a3,0x5
    80001c30:	3d468693          	addi	a3,a3,980 # 80007000 <_trampoline>
    80001c34:	6605                	lui	a2,0x1
    80001c36:	040005b7          	lui	a1,0x4000
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05b2                	slli	a1,a1,0xc
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	472080e7          	jalr	1138(ra) # 800010b0 <mappages>
    80001c46:	02054863          	bltz	a0,80001c76 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c4a:	4719                	li	a4,6
    80001c4c:	05893683          	ld	a3,88(s2)
    80001c50:	6605                	lui	a2,0x1
    80001c52:	020005b7          	lui	a1,0x2000
    80001c56:	15fd                	addi	a1,a1,-1
    80001c58:	05b6                	slli	a1,a1,0xd
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	454080e7          	jalr	1108(ra) # 800010b0 <mappages>
    80001c64:	02054163          	bltz	a0,80001c86 <proc_pagetable+0x76>
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret
    uvmfree(pagetable, 0);
    80001c76:	4581                	li	a1,0
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	8bc080e7          	jalr	-1860(ra) # 80001536 <uvmfree>
    return 0;
    80001c82:	4481                	li	s1,0
    80001c84:	b7d5                	j	80001c68 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c86:	4681                	li	a3,0
    80001c88:	4605                	li	a2,1
    80001c8a:	040005b7          	lui	a1,0x4000
    80001c8e:	15fd                	addi	a1,a1,-1
    80001c90:	05b2                	slli	a1,a1,0xc
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	5e2080e7          	jalr	1506(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c9c:	4581                	li	a1,0
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	896080e7          	jalr	-1898(ra) # 80001536 <uvmfree>
    return 0;
    80001ca8:	4481                	li	s1,0
    80001caa:	bf7d                	j	80001c68 <proc_pagetable+0x58>

0000000080001cac <proc_freepagetable>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	e04a                	sd	s2,0(sp)
    80001cb6:	1000                	addi	s0,sp,32
    80001cb8:	84aa                	mv	s1,a0
    80001cba:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cbc:	4681                	li	a3,0
    80001cbe:	4605                	li	a2,1
    80001cc0:	040005b7          	lui	a1,0x4000
    80001cc4:	15fd                	addi	a1,a1,-1
    80001cc6:	05b2                	slli	a1,a1,0xc
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	5ae080e7          	jalr	1454(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cd0:	4681                	li	a3,0
    80001cd2:	4605                	li	a2,1
    80001cd4:	020005b7          	lui	a1,0x2000
    80001cd8:	15fd                	addi	a1,a1,-1
    80001cda:	05b6                	slli	a1,a1,0xd
    80001cdc:	8526                	mv	a0,s1
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	598080e7          	jalr	1432(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ce6:	85ca                	mv	a1,s2
    80001ce8:	8526                	mv	a0,s1
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	84c080e7          	jalr	-1972(ra) # 80001536 <uvmfree>
}
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6902                	ld	s2,0(sp)
    80001cfa:	6105                	addi	sp,sp,32
    80001cfc:	8082                	ret

0000000080001cfe <freeproc>:
{
    80001cfe:	1101                	addi	sp,sp,-32
    80001d00:	ec06                	sd	ra,24(sp)
    80001d02:	e822                	sd	s0,16(sp)
    80001d04:	e426                	sd	s1,8(sp)
    80001d06:	1000                	addi	s0,sp,32
    80001d08:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d0a:	6d28                	ld	a0,88(a0)
    80001d0c:	c509                	beqz	a0,80001d16 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	cea080e7          	jalr	-790(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d16:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d1a:	68a8                	ld	a0,80(s1)
    80001d1c:	c511                	beqz	a0,80001d28 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d1e:	64ac                	ld	a1,72(s1)
    80001d20:	00000097          	auipc	ra,0x0
    80001d24:	f8c080e7          	jalr	-116(ra) # 80001cac <proc_freepagetable>
  p->pagetable = 0;
    80001d28:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d2c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d30:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d34:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d38:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d3c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d40:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d44:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d48:	0004ac23          	sw	zero,24(s1)
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret

0000000080001d56 <allocproc>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	e04a                	sd	s2,0(sp)
    80001d60:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d62:	00010497          	auipc	s1,0x10
    80001d66:	9fe48493          	addi	s1,s1,-1538 # 80011760 <proc>
    80001d6a:	00015917          	auipc	s2,0x15
    80001d6e:	7f690913          	addi	s2,s2,2038 # 80017560 <tickslock>
    acquire(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	e70080e7          	jalr	-400(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d7c:	4c9c                	lw	a5,24(s1)
    80001d7e:	cf81                	beqz	a5,80001d96 <allocproc+0x40>
      release(&p->lock);
    80001d80:	8526                	mv	a0,s1
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8a:	17848493          	addi	s1,s1,376
    80001d8e:	ff2492e3          	bne	s1,s2,80001d72 <allocproc+0x1c>
  return 0;
    80001d92:	4481                	li	s1,0
    80001d94:	a889                	j	80001de6 <allocproc+0x90>
  p->pid = allocpid();
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e40080e7          	jalr	-448(ra) # 80001bd6 <allocpid>
    80001d9e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001da0:	4785                	li	a5,1
    80001da2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	d50080e7          	jalr	-688(ra) # 80000af4 <kalloc>
    80001dac:	892a                	mv	s2,a0
    80001dae:	eca8                	sd	a0,88(s1)
    80001db0:	c131                	beqz	a0,80001df4 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001db2:	8526                	mv	a0,s1
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	e5c080e7          	jalr	-420(ra) # 80001c10 <proc_pagetable>
    80001dbc:	892a                	mv	s2,a0
    80001dbe:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dc0:	c531                	beqz	a0,80001e0c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001dc2:	07000613          	li	a2,112
    80001dc6:	4581                	li	a1,0
    80001dc8:	06048513          	addi	a0,s1,96
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	f14080e7          	jalr	-236(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001dd4:	00000797          	auipc	a5,0x0
    80001dd8:	dbc78793          	addi	a5,a5,-580 # 80001b90 <forkret>
    80001ddc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dde:	60bc                	ld	a5,64(s1)
    80001de0:	6705                	lui	a4,0x1
    80001de2:	97ba                	add	a5,a5,a4
    80001de4:	f4bc                	sd	a5,104(s1)
}
    80001de6:	8526                	mv	a0,s1
    80001de8:	60e2                	ld	ra,24(sp)
    80001dea:	6442                	ld	s0,16(sp)
    80001dec:	64a2                	ld	s1,8(sp)
    80001dee:	6902                	ld	s2,0(sp)
    80001df0:	6105                	addi	sp,sp,32
    80001df2:	8082                	ret
    freeproc(p);
    80001df4:	8526                	mv	a0,s1
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	f08080e7          	jalr	-248(ra) # 80001cfe <freeproc>
    release(&p->lock);
    80001dfe:	8526                	mv	a0,s1
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	e98080e7          	jalr	-360(ra) # 80000c98 <release>
    return 0;
    80001e08:	84ca                	mv	s1,s2
    80001e0a:	bff1                	j	80001de6 <allocproc+0x90>
    freeproc(p);
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	ef0080e7          	jalr	-272(ra) # 80001cfe <freeproc>
    release(&p->lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	e80080e7          	jalr	-384(ra) # 80000c98 <release>
    return 0;
    80001e20:	84ca                	mv	s1,s2
    80001e22:	b7d1                	j	80001de6 <allocproc+0x90>

0000000080001e24 <userinit>:
{
    80001e24:	1101                	addi	sp,sp,-32
    80001e26:	ec06                	sd	ra,24(sp)
    80001e28:	e822                	sd	s0,16(sp)
    80001e2a:	e426                	sd	s1,8(sp)
    80001e2c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	f28080e7          	jalr	-216(ra) # 80001d56 <allocproc>
    80001e36:	84aa                	mv	s1,a0
  initproc = p;
    80001e38:	00007797          	auipc	a5,0x7
    80001e3c:	20a7b423          	sd	a0,520(a5) # 80009040 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e40:	03400613          	li	a2,52
    80001e44:	00007597          	auipc	a1,0x7
    80001e48:	9ec58593          	addi	a1,a1,-1556 # 80008830 <initcode>
    80001e4c:	6928                	ld	a0,80(a0)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	51a080e7          	jalr	1306(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001e56:	6785                	lui	a5,0x1
    80001e58:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e5a:	6cb8                	ld	a4,88(s1)
    80001e5c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e60:	6cb8                	ld	a4,88(s1)
    80001e62:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e64:	4641                	li	a2,16
    80001e66:	00006597          	auipc	a1,0x6
    80001e6a:	3a258593          	addi	a1,a1,930 # 80008208 <digits+0x1c8>
    80001e6e:	15848513          	addi	a0,s1,344
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	fc0080e7          	jalr	-64(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e7a:	00006517          	auipc	a0,0x6
    80001e7e:	39e50513          	addi	a0,a0,926 # 80008218 <digits+0x1d8>
    80001e82:	00002097          	auipc	ra,0x2
    80001e86:	0e0080e7          	jalr	224(ra) # 80003f62 <namei>
    80001e8a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e04080e7          	jalr	-508(ra) # 80000c98 <release>
}
    80001e9c:	60e2                	ld	ra,24(sp)
    80001e9e:	6442                	ld	s0,16(sp)
    80001ea0:	64a2                	ld	s1,8(sp)
    80001ea2:	6105                	addi	sp,sp,32
    80001ea4:	8082                	ret

0000000080001ea6 <growproc>:
{
    80001ea6:	1101                	addi	sp,sp,-32
    80001ea8:	ec06                	sd	ra,24(sp)
    80001eaa:	e822                	sd	s0,16(sp)
    80001eac:	e426                	sd	s1,8(sp)
    80001eae:	e04a                	sd	s2,0(sp)
    80001eb0:	1000                	addi	s0,sp,32
    80001eb2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	c9c080e7          	jalr	-868(ra) # 80001b50 <myproc>
    80001ebc:	892a                	mv	s2,a0
  sz = p->sz;
    80001ebe:	652c                	ld	a1,72(a0)
    80001ec0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ec4:	00904f63          	bgtz	s1,80001ee2 <growproc+0x3c>
  } else if(n < 0){
    80001ec8:	0204cc63          	bltz	s1,80001f00 <growproc+0x5a>
  p->sz = sz;
    80001ecc:	1602                	slli	a2,a2,0x20
    80001ece:	9201                	srli	a2,a2,0x20
    80001ed0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ed4:	4501                	li	a0,0
}
    80001ed6:	60e2                	ld	ra,24(sp)
    80001ed8:	6442                	ld	s0,16(sp)
    80001eda:	64a2                	ld	s1,8(sp)
    80001edc:	6902                	ld	s2,0(sp)
    80001ede:	6105                	addi	sp,sp,32
    80001ee0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ee2:	9e25                	addw	a2,a2,s1
    80001ee4:	1602                	slli	a2,a2,0x20
    80001ee6:	9201                	srli	a2,a2,0x20
    80001ee8:	1582                	slli	a1,a1,0x20
    80001eea:	9181                	srli	a1,a1,0x20
    80001eec:	6928                	ld	a0,80(a0)
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	534080e7          	jalr	1332(ra) # 80001422 <uvmalloc>
    80001ef6:	0005061b          	sext.w	a2,a0
    80001efa:	fa69                	bnez	a2,80001ecc <growproc+0x26>
      return -1;
    80001efc:	557d                	li	a0,-1
    80001efe:	bfe1                	j	80001ed6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f00:	9e25                	addw	a2,a2,s1
    80001f02:	1602                	slli	a2,a2,0x20
    80001f04:	9201                	srli	a2,a2,0x20
    80001f06:	1582                	slli	a1,a1,0x20
    80001f08:	9181                	srli	a1,a1,0x20
    80001f0a:	6928                	ld	a0,80(a0)
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	4ce080e7          	jalr	1230(ra) # 800013da <uvmdealloc>
    80001f14:	0005061b          	sext.w	a2,a0
    80001f18:	bf55                	j	80001ecc <growproc+0x26>

0000000080001f1a <fork>:
{
    80001f1a:	7139                	addi	sp,sp,-64
    80001f1c:	fc06                	sd	ra,56(sp)
    80001f1e:	f822                	sd	s0,48(sp)
    80001f20:	f426                	sd	s1,40(sp)
    80001f22:	f04a                	sd	s2,32(sp)
    80001f24:	ec4e                	sd	s3,24(sp)
    80001f26:	e852                	sd	s4,16(sp)
    80001f28:	e456                	sd	s5,8(sp)
    80001f2a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	c24080e7          	jalr	-988(ra) # 80001b50 <myproc>
    80001f34:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	e20080e7          	jalr	-480(ra) # 80001d56 <allocproc>
    80001f3e:	14050263          	beqz	a0,80002082 <fork+0x168>
    80001f42:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f44:	04893603          	ld	a2,72(s2)
    80001f48:	692c                	ld	a1,80(a0)
    80001f4a:	05093503          	ld	a0,80(s2)
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	620080e7          	jalr	1568(ra) # 8000156e <uvmcopy>
    80001f56:	04054663          	bltz	a0,80001fa2 <fork+0x88>
  np->sz = p->sz;
    80001f5a:	04893783          	ld	a5,72(s2)
    80001f5e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f62:	05893683          	ld	a3,88(s2)
    80001f66:	87b6                	mv	a5,a3
    80001f68:	0589b703          	ld	a4,88(s3)
    80001f6c:	12068693          	addi	a3,a3,288
    80001f70:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f74:	6788                	ld	a0,8(a5)
    80001f76:	6b8c                	ld	a1,16(a5)
    80001f78:	6f90                	ld	a2,24(a5)
    80001f7a:	01073023          	sd	a6,0(a4)
    80001f7e:	e708                	sd	a0,8(a4)
    80001f80:	eb0c                	sd	a1,16(a4)
    80001f82:	ef10                	sd	a2,24(a4)
    80001f84:	02078793          	addi	a5,a5,32
    80001f88:	02070713          	addi	a4,a4,32
    80001f8c:	fed792e3          	bne	a5,a3,80001f70 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f90:	0589b783          	ld	a5,88(s3)
    80001f94:	0607b823          	sd	zero,112(a5)
    80001f98:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f9c:	15000a13          	li	s4,336
    80001fa0:	a03d                	j	80001fce <fork+0xb4>
    freeproc(np);
    80001fa2:	854e                	mv	a0,s3
    80001fa4:	00000097          	auipc	ra,0x0
    80001fa8:	d5a080e7          	jalr	-678(ra) # 80001cfe <freeproc>
    release(&np->lock);
    80001fac:	854e                	mv	a0,s3
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	cea080e7          	jalr	-790(ra) # 80000c98 <release>
    return -1;
    80001fb6:	5afd                	li	s5,-1
    80001fb8:	a85d                	j	8000206e <fork+0x154>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fba:	00002097          	auipc	ra,0x2
    80001fbe:	63e080e7          	jalr	1598(ra) # 800045f8 <filedup>
    80001fc2:	009987b3          	add	a5,s3,s1
    80001fc6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fc8:	04a1                	addi	s1,s1,8
    80001fca:	01448763          	beq	s1,s4,80001fd8 <fork+0xbe>
    if(p->ofile[i])
    80001fce:	009907b3          	add	a5,s2,s1
    80001fd2:	6388                	ld	a0,0(a5)
    80001fd4:	f17d                	bnez	a0,80001fba <fork+0xa0>
    80001fd6:	bfcd                	j	80001fc8 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001fd8:	15093503          	ld	a0,336(s2)
    80001fdc:	00001097          	auipc	ra,0x1
    80001fe0:	792080e7          	jalr	1938(ra) # 8000376e <idup>
    80001fe4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fe8:	4641                	li	a2,16
    80001fea:	15890593          	addi	a1,s2,344
    80001fee:	15898513          	addi	a0,s3,344
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	e40080e7          	jalr	-448(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ffa:	0309aa83          	lw	s5,48(s3)
  release(&np->lock);
    80001ffe:	854e                	mv	a0,s3
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	c98080e7          	jalr	-872(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002008:	0000f497          	auipc	s1,0xf
    8000200c:	74048493          	addi	s1,s1,1856 # 80011748 <wait_lock>
    80002010:	8526                	mv	a0,s1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	bd2080e7          	jalr	-1070(ra) # 80000be4 <acquire>
  np->parent = p;
    8000201a:	0329bc23          	sd	s2,56(s3)
  insert_proc_to_list(unused_list, p); //test
    8000201e:	00007a17          	auipc	s4,0x7
    80002022:	01aa0a13          	addi	s4,s4,26 # 80009038 <unused_list>
    80002026:	85ca                	mv	a1,s2
    80002028:	000a3503          	ld	a0,0(s4)
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	8bc080e7          	jalr	-1860(ra) # 800018e8 <insert_proc_to_list>
  printf("%d\n ", unused_list->head); //test
    80002034:	000a3783          	ld	a5,0(s4)
    80002038:	438c                	lw	a1,0(a5)
    8000203a:	00006517          	auipc	a0,0x6
    8000203e:	1e650513          	addi	a0,a0,486 # 80008220 <digits+0x1e0>
    80002042:	ffffe097          	auipc	ra,0xffffe
    80002046:	546080e7          	jalr	1350(ra) # 80000588 <printf>
  release(&wait_lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c4c080e7          	jalr	-948(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002054:	854e                	mv	a0,s3
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b8e080e7          	jalr	-1138(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000205e:	478d                	li	a5,3
    80002060:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002064:	854e                	mv	a0,s3
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	c32080e7          	jalr	-974(ra) # 80000c98 <release>
}
    8000206e:	8556                	mv	a0,s5
    80002070:	70e2                	ld	ra,56(sp)
    80002072:	7442                	ld	s0,48(sp)
    80002074:	74a2                	ld	s1,40(sp)
    80002076:	7902                	ld	s2,32(sp)
    80002078:	69e2                	ld	s3,24(sp)
    8000207a:	6a42                	ld	s4,16(sp)
    8000207c:	6aa2                	ld	s5,8(sp)
    8000207e:	6121                	addi	sp,sp,64
    80002080:	8082                	ret
    return -1;
    80002082:	5afd                	li	s5,-1
    80002084:	b7ed                	j	8000206e <fork+0x154>

0000000080002086 <scheduler>:
{
    80002086:	7139                	addi	sp,sp,-64
    80002088:	fc06                	sd	ra,56(sp)
    8000208a:	f822                	sd	s0,48(sp)
    8000208c:	f426                	sd	s1,40(sp)
    8000208e:	f04a                	sd	s2,32(sp)
    80002090:	ec4e                	sd	s3,24(sp)
    80002092:	e852                	sd	s4,16(sp)
    80002094:	e456                	sd	s5,8(sp)
    80002096:	e05a                	sd	s6,0(sp)
    80002098:	0080                	addi	s0,sp,64
    8000209a:	8712                	mv	a4,tp
  int id = r_tp();
    8000209c:	2701                	sext.w	a4,a4
  c->proc = 0;
    8000209e:	0000fb17          	auipc	s6,0xf
    800020a2:	212b0b13          	addi	s6,s6,530 # 800112b0 <cpus>
    800020a6:	00371793          	slli	a5,a4,0x3
    800020aa:	00e786b3          	add	a3,a5,a4
    800020ae:	0692                	slli	a3,a3,0x4
    800020b0:	96da                	add	a3,a3,s6
    800020b2:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p->context);
    800020b6:	97ba                	add	a5,a5,a4
    800020b8:	0792                	slli	a5,a5,0x4
    800020ba:	07a1                	addi	a5,a5,8
    800020bc:	9b3e                	add	s6,s6,a5
      if(p->state == RUNNABLE) {
    800020be:	498d                	li	s3,3
        c->proc = p;
    800020c0:	8a36                	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c2:	00015917          	auipc	s2,0x15
    800020c6:	49e90913          	addi	s2,s2,1182 # 80017560 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020d2:	10079073          	csrw	sstatus,a5
    800020d6:	0000f497          	auipc	s1,0xf
    800020da:	68a48493          	addi	s1,s1,1674 # 80011760 <proc>
        p->state = RUNNING;
    800020de:	4a91                	li	s5,4
    800020e0:	a03d                	j	8000210e <scheduler+0x88>
    800020e2:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800020e6:	009a3023          	sd	s1,0(s4)
        swtch(&c->context, &p->context);
    800020ea:	06048593          	addi	a1,s1,96
    800020ee:	855a                	mv	a0,s6
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	658080e7          	jalr	1624(ra) # 80002748 <swtch>
        c->proc = 0;
    800020f8:	000a3023          	sd	zero,0(s4)
      release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	17848493          	addi	s1,s1,376
    8000210a:	fd2480e3          	beq	s1,s2,800020ca <scheduler+0x44>
      acquire(&p->lock);
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ad4080e7          	jalr	-1324(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002118:	4c9c                	lw	a5,24(s1)
    8000211a:	ff3791e3          	bne	a5,s3,800020fc <scheduler+0x76>
    8000211e:	b7d1                	j	800020e2 <scheduler+0x5c>

0000000080002120 <sched>:
{
    80002120:	7179                	addi	sp,sp,-48
    80002122:	f406                	sd	ra,40(sp)
    80002124:	f022                	sd	s0,32(sp)
    80002126:	ec26                	sd	s1,24(sp)
    80002128:	e84a                	sd	s2,16(sp)
    8000212a:	e44e                	sd	s3,8(sp)
    8000212c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	a22080e7          	jalr	-1502(ra) # 80001b50 <myproc>
    80002136:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	a32080e7          	jalr	-1486(ra) # 80000b6a <holding>
    80002140:	c559                	beqz	a0,800021ce <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002142:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002144:	0007871b          	sext.w	a4,a5
    80002148:	00371793          	slli	a5,a4,0x3
    8000214c:	97ba                	add	a5,a5,a4
    8000214e:	0792                	slli	a5,a5,0x4
    80002150:	0000f717          	auipc	a4,0xf
    80002154:	16070713          	addi	a4,a4,352 # 800112b0 <cpus>
    80002158:	97ba                	add	a5,a5,a4
    8000215a:	5fb8                	lw	a4,120(a5)
    8000215c:	4785                	li	a5,1
    8000215e:	08f71063          	bne	a4,a5,800021de <sched+0xbe>
  if(p->state == RUNNING)
    80002162:	4c98                	lw	a4,24(s1)
    80002164:	4791                	li	a5,4
    80002166:	08f70463          	beq	a4,a5,800021ee <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000216e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002170:	e7d9                	bnez	a5,800021fe <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002172:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002174:	0000f917          	auipc	s2,0xf
    80002178:	13c90913          	addi	s2,s2,316 # 800112b0 <cpus>
    8000217c:	0007871b          	sext.w	a4,a5
    80002180:	00371793          	slli	a5,a4,0x3
    80002184:	97ba                	add	a5,a5,a4
    80002186:	0792                	slli	a5,a5,0x4
    80002188:	97ca                	add	a5,a5,s2
    8000218a:	07c7a983          	lw	s3,124(a5)
    8000218e:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    80002190:	0005879b          	sext.w	a5,a1
    80002194:	00379593          	slli	a1,a5,0x3
    80002198:	95be                	add	a1,a1,a5
    8000219a:	0592                	slli	a1,a1,0x4
    8000219c:	05a1                	addi	a1,a1,8
    8000219e:	95ca                	add	a1,a1,s2
    800021a0:	06048513          	addi	a0,s1,96
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	5a4080e7          	jalr	1444(ra) # 80002748 <swtch>
    800021ac:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ae:	0007871b          	sext.w	a4,a5
    800021b2:	00371793          	slli	a5,a4,0x3
    800021b6:	97ba                	add	a5,a5,a4
    800021b8:	0792                	slli	a5,a5,0x4
    800021ba:	993e                	add	s2,s2,a5
    800021bc:	07392e23          	sw	s3,124(s2)
}
    800021c0:	70a2                	ld	ra,40(sp)
    800021c2:	7402                	ld	s0,32(sp)
    800021c4:	64e2                	ld	s1,24(sp)
    800021c6:	6942                	ld	s2,16(sp)
    800021c8:	69a2                	ld	s3,8(sp)
    800021ca:	6145                	addi	sp,sp,48
    800021cc:	8082                	ret
    panic("sched p->lock");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	05a50513          	addi	a0,a0,90 # 80008228 <digits+0x1e8>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	368080e7          	jalr	872(ra) # 8000053e <panic>
    panic("sched locks");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	05a50513          	addi	a0,a0,90 # 80008238 <digits+0x1f8>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	358080e7          	jalr	856(ra) # 8000053e <panic>
    panic("sched running");
    800021ee:	00006517          	auipc	a0,0x6
    800021f2:	05a50513          	addi	a0,a0,90 # 80008248 <digits+0x208>
    800021f6:	ffffe097          	auipc	ra,0xffffe
    800021fa:	348080e7          	jalr	840(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021fe:	00006517          	auipc	a0,0x6
    80002202:	05a50513          	addi	a0,a0,90 # 80008258 <digits+0x218>
    80002206:	ffffe097          	auipc	ra,0xffffe
    8000220a:	338080e7          	jalr	824(ra) # 8000053e <panic>

000000008000220e <yield>:
{
    8000220e:	1101                	addi	sp,sp,-32
    80002210:	ec06                	sd	ra,24(sp)
    80002212:	e822                	sd	s0,16(sp)
    80002214:	e426                	sd	s1,8(sp)
    80002216:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	938080e7          	jalr	-1736(ra) # 80001b50 <myproc>
    80002220:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9c2080e7          	jalr	-1598(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000222a:	478d                	li	a5,3
    8000222c:	cc9c                	sw	a5,24(s1)
  sched();
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	ef2080e7          	jalr	-270(ra) # 80002120 <sched>
  release(&p->lock);
    80002236:	8526                	mv	a0,s1
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a60080e7          	jalr	-1440(ra) # 80000c98 <release>
}
    80002240:	60e2                	ld	ra,24(sp)
    80002242:	6442                	ld	s0,16(sp)
    80002244:	64a2                	ld	s1,8(sp)
    80002246:	6105                	addi	sp,sp,32
    80002248:	8082                	ret

000000008000224a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000224a:	7179                	addi	sp,sp,-48
    8000224c:	f406                	sd	ra,40(sp)
    8000224e:	f022                	sd	s0,32(sp)
    80002250:	ec26                	sd	s1,24(sp)
    80002252:	e84a                	sd	s2,16(sp)
    80002254:	e44e                	sd	s3,8(sp)
    80002256:	1800                	addi	s0,sp,48
    80002258:	89aa                	mv	s3,a0
    8000225a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	8f4080e7          	jalr	-1804(ra) # 80001b50 <myproc>
    80002264:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
  release(lk);
    8000226e:	854a                	mv	a0,s2
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002278:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000227c:	4789                	li	a5,2
    8000227e:	cc9c                	sw	a5,24(s1)

  sched();
    80002280:	00000097          	auipc	ra,0x0
    80002284:	ea0080e7          	jalr	-352(ra) # 80002120 <sched>

  // Tidy up.
  p->chan = 0;
    80002288:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
  acquire(lk);
    80002296:	854a                	mv	a0,s2
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	94c080e7          	jalr	-1716(ra) # 80000be4 <acquire>
}
    800022a0:	70a2                	ld	ra,40(sp)
    800022a2:	7402                	ld	s0,32(sp)
    800022a4:	64e2                	ld	s1,24(sp)
    800022a6:	6942                	ld	s2,16(sp)
    800022a8:	69a2                	ld	s3,8(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret

00000000800022ae <wait>:
{
    800022ae:	715d                	addi	sp,sp,-80
    800022b0:	e486                	sd	ra,72(sp)
    800022b2:	e0a2                	sd	s0,64(sp)
    800022b4:	fc26                	sd	s1,56(sp)
    800022b6:	f84a                	sd	s2,48(sp)
    800022b8:	f44e                	sd	s3,40(sp)
    800022ba:	f052                	sd	s4,32(sp)
    800022bc:	ec56                	sd	s5,24(sp)
    800022be:	e85a                	sd	s6,16(sp)
    800022c0:	e45e                	sd	s7,8(sp)
    800022c2:	e062                	sd	s8,0(sp)
    800022c4:	0880                	addi	s0,sp,80
    800022c6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	888080e7          	jalr	-1912(ra) # 80001b50 <myproc>
    800022d0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022d2:	0000f517          	auipc	a0,0xf
    800022d6:	47650513          	addi	a0,a0,1142 # 80011748 <wait_lock>
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	90a080e7          	jalr	-1782(ra) # 80000be4 <acquire>
    havekids = 0;
    800022e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022e4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022e6:	00015997          	auipc	s3,0x15
    800022ea:	27a98993          	addi	s3,s3,634 # 80017560 <tickslock>
        havekids = 1;
    800022ee:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f0:	0000fc17          	auipc	s8,0xf
    800022f4:	458c0c13          	addi	s8,s8,1112 # 80011748 <wait_lock>
    havekids = 0;
    800022f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fa:	0000f497          	auipc	s1,0xf
    800022fe:	46648493          	addi	s1,s1,1126 # 80011760 <proc>
    80002302:	a0bd                	j	80002370 <wait+0xc2>
          pid = np->pid;
    80002304:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002308:	000b0e63          	beqz	s6,80002324 <wait+0x76>
    8000230c:	4691                	li	a3,4
    8000230e:	02c48613          	addi	a2,s1,44
    80002312:	85da                	mv	a1,s6
    80002314:	05093503          	ld	a0,80(s2)
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	35a080e7          	jalr	858(ra) # 80001672 <copyout>
    80002320:	02054563          	bltz	a0,8000234a <wait+0x9c>
          freeproc(np);
    80002324:	8526                	mv	a0,s1
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	9d8080e7          	jalr	-1576(ra) # 80001cfe <freeproc>
          release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
          release(&wait_lock);
    80002338:	0000f517          	auipc	a0,0xf
    8000233c:	41050513          	addi	a0,a0,1040 # 80011748 <wait_lock>
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
          return pid;
    80002348:	a09d                	j	800023ae <wait+0x100>
            release(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
            release(&wait_lock);
    80002354:	0000f517          	auipc	a0,0xf
    80002358:	3f450513          	addi	a0,a0,1012 # 80011748 <wait_lock>
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	93c080e7          	jalr	-1732(ra) # 80000c98 <release>
            return -1;
    80002364:	59fd                	li	s3,-1
    80002366:	a0a1                	j	800023ae <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002368:	17848493          	addi	s1,s1,376
    8000236c:	03348463          	beq	s1,s3,80002394 <wait+0xe6>
      if(np->parent == p){
    80002370:	7c9c                	ld	a5,56(s1)
    80002372:	ff279be3          	bne	a5,s2,80002368 <wait+0xba>
        acquire(&np->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002380:	4c9c                	lw	a5,24(s1)
    80002382:	f94781e3          	beq	a5,s4,80002304 <wait+0x56>
        release(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
        havekids = 1;
    80002390:	8756                	mv	a4,s5
    80002392:	bfd9                	j	80002368 <wait+0xba>
    if(!havekids || p->killed){
    80002394:	c701                	beqz	a4,8000239c <wait+0xee>
    80002396:	02892783          	lw	a5,40(s2)
    8000239a:	c79d                	beqz	a5,800023c8 <wait+0x11a>
      release(&wait_lock);
    8000239c:	0000f517          	auipc	a0,0xf
    800023a0:	3ac50513          	addi	a0,a0,940 # 80011748 <wait_lock>
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
      return -1;
    800023ac:	59fd                	li	s3,-1
}
    800023ae:	854e                	mv	a0,s3
    800023b0:	60a6                	ld	ra,72(sp)
    800023b2:	6406                	ld	s0,64(sp)
    800023b4:	74e2                	ld	s1,56(sp)
    800023b6:	7942                	ld	s2,48(sp)
    800023b8:	79a2                	ld	s3,40(sp)
    800023ba:	7a02                	ld	s4,32(sp)
    800023bc:	6ae2                	ld	s5,24(sp)
    800023be:	6b42                	ld	s6,16(sp)
    800023c0:	6ba2                	ld	s7,8(sp)
    800023c2:	6c02                	ld	s8,0(sp)
    800023c4:	6161                	addi	sp,sp,80
    800023c6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c8:	85e2                	mv	a1,s8
    800023ca:	854a                	mv	a0,s2
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	e7e080e7          	jalr	-386(ra) # 8000224a <sleep>
    havekids = 0;
    800023d4:	b715                	j	800022f8 <wait+0x4a>

00000000800023d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023d6:	7139                	addi	sp,sp,-64
    800023d8:	fc06                	sd	ra,56(sp)
    800023da:	f822                	sd	s0,48(sp)
    800023dc:	f426                	sd	s1,40(sp)
    800023de:	f04a                	sd	s2,32(sp)
    800023e0:	ec4e                	sd	s3,24(sp)
    800023e2:	e852                	sd	s4,16(sp)
    800023e4:	e456                	sd	s5,8(sp)
    800023e6:	0080                	addi	s0,sp,64
    800023e8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023ea:	0000f497          	auipc	s1,0xf
    800023ee:	37648493          	addi	s1,s1,886 # 80011760 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023f2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023f4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f6:	00015917          	auipc	s2,0x15
    800023fa:	16a90913          	addi	s2,s2,362 # 80017560 <tickslock>
    800023fe:	a821                	j	80002416 <wakeup+0x40>
        p->state = RUNNABLE;
    80002400:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	892080e7          	jalr	-1902(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240e:	17848493          	addi	s1,s1,376
    80002412:	03248463          	beq	s1,s2,8000243a <wakeup+0x64>
    if(p != myproc()){
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	73a080e7          	jalr	1850(ra) # 80001b50 <myproc>
    8000241e:	fea488e3          	beq	s1,a0,8000240e <wakeup+0x38>
      acquire(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7c0080e7          	jalr	1984(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000242c:	4c9c                	lw	a5,24(s1)
    8000242e:	fd379be3          	bne	a5,s3,80002404 <wakeup+0x2e>
    80002432:	709c                	ld	a5,32(s1)
    80002434:	fd4798e3          	bne	a5,s4,80002404 <wakeup+0x2e>
    80002438:	b7e1                	j	80002400 <wakeup+0x2a>
    }
  }
}
    8000243a:	70e2                	ld	ra,56(sp)
    8000243c:	7442                	ld	s0,48(sp)
    8000243e:	74a2                	ld	s1,40(sp)
    80002440:	7902                	ld	s2,32(sp)
    80002442:	69e2                	ld	s3,24(sp)
    80002444:	6a42                	ld	s4,16(sp)
    80002446:	6aa2                	ld	s5,8(sp)
    80002448:	6121                	addi	sp,sp,64
    8000244a:	8082                	ret

000000008000244c <reparent>:
{
    8000244c:	7179                	addi	sp,sp,-48
    8000244e:	f406                	sd	ra,40(sp)
    80002450:	f022                	sd	s0,32(sp)
    80002452:	ec26                	sd	s1,24(sp)
    80002454:	e84a                	sd	s2,16(sp)
    80002456:	e44e                	sd	s3,8(sp)
    80002458:	e052                	sd	s4,0(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245e:	0000f497          	auipc	s1,0xf
    80002462:	30248493          	addi	s1,s1,770 # 80011760 <proc>
      pp->parent = initproc;
    80002466:	00007a17          	auipc	s4,0x7
    8000246a:	bdaa0a13          	addi	s4,s4,-1062 # 80009040 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246e:	00015997          	auipc	s3,0x15
    80002472:	0f298993          	addi	s3,s3,242 # 80017560 <tickslock>
    80002476:	a029                	j	80002480 <reparent+0x34>
    80002478:	17848493          	addi	s1,s1,376
    8000247c:	01348d63          	beq	s1,s3,80002496 <reparent+0x4a>
    if(pp->parent == p){
    80002480:	7c9c                	ld	a5,56(s1)
    80002482:	ff279be3          	bne	a5,s2,80002478 <reparent+0x2c>
      pp->parent = initproc;
    80002486:	000a3503          	ld	a0,0(s4)
    8000248a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	f4a080e7          	jalr	-182(ra) # 800023d6 <wakeup>
    80002494:	b7d5                	j	80002478 <reparent+0x2c>
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret

00000000800024a6 <exit>:
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	698080e7          	jalr	1688(ra) # 80001b50 <myproc>
    800024c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800024c2:	00007797          	auipc	a5,0x7
    800024c6:	b7e7b783          	ld	a5,-1154(a5) # 80009040 <initproc>
    800024ca:	0d050493          	addi	s1,a0,208
    800024ce:	15050913          	addi	s2,a0,336
    800024d2:	02a79363          	bne	a5,a0,800024f8 <exit+0x52>
    panic("init exiting");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	d9a50513          	addi	a0,a0,-614 # 80008270 <digits+0x230>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
      fileclose(f);
    800024e6:	00002097          	auipc	ra,0x2
    800024ea:	164080e7          	jalr	356(ra) # 8000464a <fileclose>
      p->ofile[fd] = 0;
    800024ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024f2:	04a1                	addi	s1,s1,8
    800024f4:	01248563          	beq	s1,s2,800024fe <exit+0x58>
    if(p->ofile[fd]){
    800024f8:	6088                	ld	a0,0(s1)
    800024fa:	f575                	bnez	a0,800024e6 <exit+0x40>
    800024fc:	bfdd                	j	800024f2 <exit+0x4c>
  begin_op();
    800024fe:	00002097          	auipc	ra,0x2
    80002502:	c80080e7          	jalr	-896(ra) # 8000417e <begin_op>
  iput(p->cwd);
    80002506:	1509b503          	ld	a0,336(s3)
    8000250a:	00001097          	auipc	ra,0x1
    8000250e:	45c080e7          	jalr	1116(ra) # 80003966 <iput>
  end_op();
    80002512:	00002097          	auipc	ra,0x2
    80002516:	cec080e7          	jalr	-788(ra) # 800041fe <end_op>
  p->cwd = 0;
    8000251a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000251e:	0000f497          	auipc	s1,0xf
    80002522:	22a48493          	addi	s1,s1,554 # 80011748 <wait_lock>
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
  reparent(p);
    80002530:	854e                	mv	a0,s3
    80002532:	00000097          	auipc	ra,0x0
    80002536:	f1a080e7          	jalr	-230(ra) # 8000244c <reparent>
  wakeup(p->parent);
    8000253a:	0389b503          	ld	a0,56(s3)
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	e98080e7          	jalr	-360(ra) # 800023d6 <wakeup>
  acquire(&p->lock);
    80002546:	854e                	mv	a0,s3
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002550:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002554:	4795                	li	a5,5
    80002556:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
  sched();
    80002564:	00000097          	auipc	ra,0x0
    80002568:	bbc080e7          	jalr	-1092(ra) # 80002120 <sched>
  panic("zombie exit");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	d1450513          	addi	a0,a0,-748 # 80008280 <digits+0x240>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	fca080e7          	jalr	-54(ra) # 8000053e <panic>

000000008000257c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000257c:	7179                	addi	sp,sp,-48
    8000257e:	f406                	sd	ra,40(sp)
    80002580:	f022                	sd	s0,32(sp)
    80002582:	ec26                	sd	s1,24(sp)
    80002584:	e84a                	sd	s2,16(sp)
    80002586:	e44e                	sd	s3,8(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	0000f497          	auipc	s1,0xf
    80002590:	1d448493          	addi	s1,s1,468 # 80011760 <proc>
    80002594:	00015997          	auipc	s3,0x15
    80002598:	fcc98993          	addi	s3,s3,-52 # 80017560 <tickslock>
    acquire(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	646080e7          	jalr	1606(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025a6:	589c                	lw	a5,48(s1)
    800025a8:	01278d63          	beq	a5,s2,800025c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b6:	17848493          	addi	s1,s1,376
    800025ba:	ff3491e3          	bne	s1,s3,8000259c <kill+0x20>
  }
  return -1;
    800025be:	557d                	li	a0,-1
    800025c0:	a829                	j	800025da <kill+0x5e>
      p->killed = 1;
    800025c2:	4785                	li	a5,1
    800025c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025c6:	4c98                	lw	a4,24(s1)
    800025c8:	4789                	li	a5,2
    800025ca:	00f70f63          	beq	a4,a5,800025e8 <kill+0x6c>
      release(&p->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6c8080e7          	jalr	1736(ra) # 80000c98 <release>
      return 0;
    800025d8:	4501                	li	a0,0
}
    800025da:	70a2                	ld	ra,40(sp)
    800025dc:	7402                	ld	s0,32(sp)
    800025de:	64e2                	ld	s1,24(sp)
    800025e0:	6942                	ld	s2,16(sp)
    800025e2:	69a2                	ld	s3,8(sp)
    800025e4:	6145                	addi	sp,sp,48
    800025e6:	8082                	ret
        p->state = RUNNABLE;
    800025e8:	478d                	li	a5,3
    800025ea:	cc9c                	sw	a5,24(s1)
    800025ec:	b7cd                	j	800025ce <kill+0x52>

00000000800025ee <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	e052                	sd	s4,0(sp)
    800025fc:	1800                	addi	s0,sp,48
    800025fe:	84aa                	mv	s1,a0
    80002600:	892e                	mv	s2,a1
    80002602:	89b2                	mv	s3,a2
    80002604:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	54a080e7          	jalr	1354(ra) # 80001b50 <myproc>
  if(user_dst){
    8000260e:	c08d                	beqz	s1,80002630 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002610:	86d2                	mv	a3,s4
    80002612:	864e                	mv	a2,s3
    80002614:	85ca                	mv	a1,s2
    80002616:	6928                	ld	a0,80(a0)
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	05a080e7          	jalr	90(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002620:	70a2                	ld	ra,40(sp)
    80002622:	7402                	ld	s0,32(sp)
    80002624:	64e2                	ld	s1,24(sp)
    80002626:	6942                	ld	s2,16(sp)
    80002628:	69a2                	ld	s3,8(sp)
    8000262a:	6a02                	ld	s4,0(sp)
    8000262c:	6145                	addi	sp,sp,48
    8000262e:	8082                	ret
    memmove((char *)dst, src, len);
    80002630:	000a061b          	sext.w	a2,s4
    80002634:	85ce                	mv	a1,s3
    80002636:	854a                	mv	a0,s2
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	708080e7          	jalr	1800(ra) # 80000d40 <memmove>
    return 0;
    80002640:	8526                	mv	a0,s1
    80002642:	bff9                	j	80002620 <either_copyout+0x32>

0000000080002644 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002644:	7179                	addi	sp,sp,-48
    80002646:	f406                	sd	ra,40(sp)
    80002648:	f022                	sd	s0,32(sp)
    8000264a:	ec26                	sd	s1,24(sp)
    8000264c:	e84a                	sd	s2,16(sp)
    8000264e:	e44e                	sd	s3,8(sp)
    80002650:	e052                	sd	s4,0(sp)
    80002652:	1800                	addi	s0,sp,48
    80002654:	892a                	mv	s2,a0
    80002656:	84ae                	mv	s1,a1
    80002658:	89b2                	mv	s3,a2
    8000265a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000265c:	fffff097          	auipc	ra,0xfffff
    80002660:	4f4080e7          	jalr	1268(ra) # 80001b50 <myproc>
  if(user_src){
    80002664:	c08d                	beqz	s1,80002686 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002666:	86d2                	mv	a3,s4
    80002668:	864e                	mv	a2,s3
    8000266a:	85ca                	mv	a1,s2
    8000266c:	6928                	ld	a0,80(a0)
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	090080e7          	jalr	144(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002676:	70a2                	ld	ra,40(sp)
    80002678:	7402                	ld	s0,32(sp)
    8000267a:	64e2                	ld	s1,24(sp)
    8000267c:	6942                	ld	s2,16(sp)
    8000267e:	69a2                	ld	s3,8(sp)
    80002680:	6a02                	ld	s4,0(sp)
    80002682:	6145                	addi	sp,sp,48
    80002684:	8082                	ret
    memmove(dst, (char*)src, len);
    80002686:	000a061b          	sext.w	a2,s4
    8000268a:	85ce                	mv	a1,s3
    8000268c:	854a                	mv	a0,s2
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	6b2080e7          	jalr	1714(ra) # 80000d40 <memmove>
    return 0;
    80002696:	8526                	mv	a0,s1
    80002698:	bff9                	j	80002676 <either_copyin+0x32>

000000008000269a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void)
{
    8000269a:	715d                	addi	sp,sp,-80
    8000269c:	e486                	sd	ra,72(sp)
    8000269e:	e0a2                	sd	s0,64(sp)
    800026a0:	fc26                	sd	s1,56(sp)
    800026a2:	f84a                	sd	s2,48(sp)
    800026a4:	f44e                	sd	s3,40(sp)
    800026a6:	f052                	sd	s4,32(sp)
    800026a8:	ec56                	sd	s5,24(sp)
    800026aa:	e85a                	sd	s6,16(sp)
    800026ac:	e45e                	sd	s7,8(sp)
    800026ae:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026b0:	00006517          	auipc	a0,0x6
    800026b4:	a1850513          	addi	a0,a0,-1512 # 800080c8 <digits+0x88>
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	ed0080e7          	jalr	-304(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026c0:	0000f497          	auipc	s1,0xf
    800026c4:	1f848493          	addi	s1,s1,504 # 800118b8 <proc+0x158>
    800026c8:	00015917          	auipc	s2,0x15
    800026cc:	ff090913          	addi	s2,s2,-16 # 800176b8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    800026d2:	00006997          	auipc	s3,0x6
    800026d6:	bbe98993          	addi	s3,s3,-1090 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800026da:	00006a97          	auipc	s5,0x6
    800026de:	bbea8a93          	addi	s5,s5,-1090 # 80008298 <digits+0x258>
    printf("\n");
    800026e2:	00006a17          	auipc	s4,0x6
    800026e6:	9e6a0a13          	addi	s4,s4,-1562 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026ea:	00006b97          	auipc	s7,0x6
    800026ee:	be6b8b93          	addi	s7,s7,-1050 # 800082d0 <states.1765>
    800026f2:	a00d                	j	80002714 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026f4:	ed86a583          	lw	a1,-296(a3)
    800026f8:	8556                	mv	a0,s5
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	e8e080e7          	jalr	-370(ra) # 80000588 <printf>
    printf("\n");
    80002702:	8552                	mv	a0,s4
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	e84080e7          	jalr	-380(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000270c:	17848493          	addi	s1,s1,376
    80002710:	03248163          	beq	s1,s2,80002732 <procdump+0x98>
    if(p->state == UNUSED)
    80002714:	86a6                	mv	a3,s1
    80002716:	ec04a783          	lw	a5,-320(s1)
    8000271a:	dbed                	beqz	a5,8000270c <procdump+0x72>
      state = "???"; 
    8000271c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271e:	fcfb6be3          	bltu	s6,a5,800026f4 <procdump+0x5a>
    80002722:	1782                	slli	a5,a5,0x20
    80002724:	9381                	srli	a5,a5,0x20
    80002726:	078e                	slli	a5,a5,0x3
    80002728:	97de                	add	a5,a5,s7
    8000272a:	6390                	ld	a2,0(a5)
    8000272c:	f661                	bnez	a2,800026f4 <procdump+0x5a>
      state = "???"; 
    8000272e:	864e                	mv	a2,s3
    80002730:	b7d1                	j	800026f4 <procdump+0x5a>
  }
}
    80002732:	60a6                	ld	ra,72(sp)
    80002734:	6406                	ld	s0,64(sp)
    80002736:	74e2                	ld	s1,56(sp)
    80002738:	7942                	ld	s2,48(sp)
    8000273a:	79a2                	ld	s3,40(sp)
    8000273c:	7a02                	ld	s4,32(sp)
    8000273e:	6ae2                	ld	s5,24(sp)
    80002740:	6b42                	ld	s6,16(sp)
    80002742:	6ba2                	ld	s7,8(sp)
    80002744:	6161                	addi	sp,sp,80
    80002746:	8082                	ret

0000000080002748 <swtch>:
    80002748:	00153023          	sd	ra,0(a0)
    8000274c:	00253423          	sd	sp,8(a0)
    80002750:	e900                	sd	s0,16(a0)
    80002752:	ed04                	sd	s1,24(a0)
    80002754:	03253023          	sd	s2,32(a0)
    80002758:	03353423          	sd	s3,40(a0)
    8000275c:	03453823          	sd	s4,48(a0)
    80002760:	03553c23          	sd	s5,56(a0)
    80002764:	05653023          	sd	s6,64(a0)
    80002768:	05753423          	sd	s7,72(a0)
    8000276c:	05853823          	sd	s8,80(a0)
    80002770:	05953c23          	sd	s9,88(a0)
    80002774:	07a53023          	sd	s10,96(a0)
    80002778:	07b53423          	sd	s11,104(a0)
    8000277c:	0005b083          	ld	ra,0(a1)
    80002780:	0085b103          	ld	sp,8(a1)
    80002784:	6980                	ld	s0,16(a1)
    80002786:	6d84                	ld	s1,24(a1)
    80002788:	0205b903          	ld	s2,32(a1)
    8000278c:	0285b983          	ld	s3,40(a1)
    80002790:	0305ba03          	ld	s4,48(a1)
    80002794:	0385ba83          	ld	s5,56(a1)
    80002798:	0405bb03          	ld	s6,64(a1)
    8000279c:	0485bb83          	ld	s7,72(a1)
    800027a0:	0505bc03          	ld	s8,80(a1)
    800027a4:	0585bc83          	ld	s9,88(a1)
    800027a8:	0605bd03          	ld	s10,96(a1)
    800027ac:	0685bd83          	ld	s11,104(a1)
    800027b0:	8082                	ret

00000000800027b2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027b2:	1141                	addi	sp,sp,-16
    800027b4:	e406                	sd	ra,8(sp)
    800027b6:	e022                	sd	s0,0(sp)
    800027b8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ba:	00006597          	auipc	a1,0x6
    800027be:	b4658593          	addi	a1,a1,-1210 # 80008300 <states.1765+0x30>
    800027c2:	00015517          	auipc	a0,0x15
    800027c6:	d9e50513          	addi	a0,a0,-610 # 80017560 <tickslock>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	38a080e7          	jalr	906(ra) # 80000b54 <initlock>
}
    800027d2:	60a2                	ld	ra,8(sp)
    800027d4:	6402                	ld	s0,0(sp)
    800027d6:	0141                	addi	sp,sp,16
    800027d8:	8082                	ret

00000000800027da <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027da:	1141                	addi	sp,sp,-16
    800027dc:	e422                	sd	s0,8(sp)
    800027de:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027e0:	00003797          	auipc	a5,0x3
    800027e4:	48078793          	addi	a5,a5,1152 # 80005c60 <kernelvec>
    800027e8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027ec:	6422                	ld	s0,8(sp)
    800027ee:	0141                	addi	sp,sp,16
    800027f0:	8082                	ret

00000000800027f2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027f2:	1141                	addi	sp,sp,-16
    800027f4:	e406                	sd	ra,8(sp)
    800027f6:	e022                	sd	s0,0(sp)
    800027f8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027fa:	fffff097          	auipc	ra,0xfffff
    800027fe:	356080e7          	jalr	854(ra) # 80001b50 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002802:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002806:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002808:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000280c:	00004617          	auipc	a2,0x4
    80002810:	7f460613          	addi	a2,a2,2036 # 80007000 <_trampoline>
    80002814:	00004697          	auipc	a3,0x4
    80002818:	7ec68693          	addi	a3,a3,2028 # 80007000 <_trampoline>
    8000281c:	8e91                	sub	a3,a3,a2
    8000281e:	040007b7          	lui	a5,0x4000
    80002822:	17fd                	addi	a5,a5,-1
    80002824:	07b2                	slli	a5,a5,0xc
    80002826:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002828:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000282c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000282e:	180026f3          	csrr	a3,satp
    80002832:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002834:	6d38                	ld	a4,88(a0)
    80002836:	6134                	ld	a3,64(a0)
    80002838:	6585                	lui	a1,0x1
    8000283a:	96ae                	add	a3,a3,a1
    8000283c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000283e:	6d38                	ld	a4,88(a0)
    80002840:	00000697          	auipc	a3,0x0
    80002844:	13868693          	addi	a3,a3,312 # 80002978 <usertrap>
    80002848:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000284a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000284c:	8692                	mv	a3,tp
    8000284e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002850:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002854:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002858:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000285c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002860:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002862:	6f18                	ld	a4,24(a4)
    80002864:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002868:	692c                	ld	a1,80(a0)
    8000286a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000286c:	00005717          	auipc	a4,0x5
    80002870:	82470713          	addi	a4,a4,-2012 # 80007090 <userret>
    80002874:	8f11                	sub	a4,a4,a2
    80002876:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002878:	577d                	li	a4,-1
    8000287a:	177e                	slli	a4,a4,0x3f
    8000287c:	8dd9                	or	a1,a1,a4
    8000287e:	02000537          	lui	a0,0x2000
    80002882:	157d                	addi	a0,a0,-1
    80002884:	0536                	slli	a0,a0,0xd
    80002886:	9782                	jalr	a5
}
    80002888:	60a2                	ld	ra,8(sp)
    8000288a:	6402                	ld	s0,0(sp)
    8000288c:	0141                	addi	sp,sp,16
    8000288e:	8082                	ret

0000000080002890 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002890:	1101                	addi	sp,sp,-32
    80002892:	ec06                	sd	ra,24(sp)
    80002894:	e822                	sd	s0,16(sp)
    80002896:	e426                	sd	s1,8(sp)
    80002898:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000289a:	00015497          	auipc	s1,0x15
    8000289e:	cc648493          	addi	s1,s1,-826 # 80017560 <tickslock>
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  ticks++;
    800028ac:	00006517          	auipc	a0,0x6
    800028b0:	79c50513          	addi	a0,a0,1948 # 80009048 <ticks>
    800028b4:	411c                	lw	a5,0(a0)
    800028b6:	2785                	addiw	a5,a5,1
    800028b8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028ba:	00000097          	auipc	ra,0x0
    800028be:	b1c080e7          	jalr	-1252(ra) # 800023d6 <wakeup>
  release(&tickslock);
    800028c2:	8526                	mv	a0,s1
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	3d4080e7          	jalr	980(ra) # 80000c98 <release>
}
    800028cc:	60e2                	ld	ra,24(sp)
    800028ce:	6442                	ld	s0,16(sp)
    800028d0:	64a2                	ld	s1,8(sp)
    800028d2:	6105                	addi	sp,sp,32
    800028d4:	8082                	ret

00000000800028d6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028d6:	1101                	addi	sp,sp,-32
    800028d8:	ec06                	sd	ra,24(sp)
    800028da:	e822                	sd	s0,16(sp)
    800028dc:	e426                	sd	s1,8(sp)
    800028de:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028e4:	00074d63          	bltz	a4,800028fe <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028e8:	57fd                	li	a5,-1
    800028ea:	17fe                	slli	a5,a5,0x3f
    800028ec:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028ee:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028f0:	06f70363          	beq	a4,a5,80002956 <devintr+0x80>
  }
}
    800028f4:	60e2                	ld	ra,24(sp)
    800028f6:	6442                	ld	s0,16(sp)
    800028f8:	64a2                	ld	s1,8(sp)
    800028fa:	6105                	addi	sp,sp,32
    800028fc:	8082                	ret
     (scause & 0xff) == 9){
    800028fe:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002902:	46a5                	li	a3,9
    80002904:	fed792e3          	bne	a5,a3,800028e8 <devintr+0x12>
    int irq = plic_claim();
    80002908:	00003097          	auipc	ra,0x3
    8000290c:	460080e7          	jalr	1120(ra) # 80005d68 <plic_claim>
    80002910:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002912:	47a9                	li	a5,10
    80002914:	02f50763          	beq	a0,a5,80002942 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002918:	4785                	li	a5,1
    8000291a:	02f50963          	beq	a0,a5,8000294c <devintr+0x76>
    return 1;
    8000291e:	4505                	li	a0,1
    } else if(irq){
    80002920:	d8f1                	beqz	s1,800028f4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002922:	85a6                	mv	a1,s1
    80002924:	00006517          	auipc	a0,0x6
    80002928:	9e450513          	addi	a0,a0,-1564 # 80008308 <states.1765+0x38>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c5c080e7          	jalr	-932(ra) # 80000588 <printf>
      plic_complete(irq);
    80002934:	8526                	mv	a0,s1
    80002936:	00003097          	auipc	ra,0x3
    8000293a:	456080e7          	jalr	1110(ra) # 80005d8c <plic_complete>
    return 1;
    8000293e:	4505                	li	a0,1
    80002940:	bf55                	j	800028f4 <devintr+0x1e>
      uartintr();
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	066080e7          	jalr	102(ra) # 800009a8 <uartintr>
    8000294a:	b7ed                	j	80002934 <devintr+0x5e>
      virtio_disk_intr();
    8000294c:	00004097          	auipc	ra,0x4
    80002950:	920080e7          	jalr	-1760(ra) # 8000626c <virtio_disk_intr>
    80002954:	b7c5                	j	80002934 <devintr+0x5e>
    if(cpuid() == 0){
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	1c6080e7          	jalr	454(ra) # 80001b1c <cpuid>
    8000295e:	c901                	beqz	a0,8000296e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002960:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002964:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002966:	14479073          	csrw	sip,a5
    return 2;
    8000296a:	4509                	li	a0,2
    8000296c:	b761                	j	800028f4 <devintr+0x1e>
      clockintr();
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	f22080e7          	jalr	-222(ra) # 80002890 <clockintr>
    80002976:	b7ed                	j	80002960 <devintr+0x8a>

0000000080002978 <usertrap>:
{
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	e426                	sd	s1,8(sp)
    80002980:	e04a                	sd	s2,0(sp)
    80002982:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002984:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002988:	1007f793          	andi	a5,a5,256
    8000298c:	e3ad                	bnez	a5,800029ee <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298e:	00003797          	auipc	a5,0x3
    80002992:	2d278793          	addi	a5,a5,722 # 80005c60 <kernelvec>
    80002996:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	1b6080e7          	jalr	438(ra) # 80001b50 <myproc>
    800029a2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029a4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a6:	14102773          	csrr	a4,sepc
    800029aa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ac:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029b0:	47a1                	li	a5,8
    800029b2:	04f71c63          	bne	a4,a5,80002a0a <usertrap+0x92>
    if(p->killed)
    800029b6:	551c                	lw	a5,40(a0)
    800029b8:	e3b9                	bnez	a5,800029fe <usertrap+0x86>
    p->trapframe->epc += 4;
    800029ba:	6cb8                	ld	a4,88(s1)
    800029bc:	6f1c                	ld	a5,24(a4)
    800029be:	0791                	addi	a5,a5,4
    800029c0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ca:	10079073          	csrw	sstatus,a5
    syscall();
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	2e0080e7          	jalr	736(ra) # 80002cae <syscall>
  if(p->killed)
    800029d6:	549c                	lw	a5,40(s1)
    800029d8:	ebc1                	bnez	a5,80002a68 <usertrap+0xf0>
  usertrapret();
    800029da:	00000097          	auipc	ra,0x0
    800029de:	e18080e7          	jalr	-488(ra) # 800027f2 <usertrapret>
}
    800029e2:	60e2                	ld	ra,24(sp)
    800029e4:	6442                	ld	s0,16(sp)
    800029e6:	64a2                	ld	s1,8(sp)
    800029e8:	6902                	ld	s2,0(sp)
    800029ea:	6105                	addi	sp,sp,32
    800029ec:	8082                	ret
    panic("usertrap: not from user mode");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	93a50513          	addi	a0,a0,-1734 # 80008328 <states.1765+0x58>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>
      exit(-1);
    800029fe:	557d                	li	a0,-1
    80002a00:	00000097          	auipc	ra,0x0
    80002a04:	aa6080e7          	jalr	-1370(ra) # 800024a6 <exit>
    80002a08:	bf4d                	j	800029ba <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	ecc080e7          	jalr	-308(ra) # 800028d6 <devintr>
    80002a12:	892a                	mv	s2,a0
    80002a14:	c501                	beqz	a0,80002a1c <usertrap+0xa4>
  if(p->killed)
    80002a16:	549c                	lw	a5,40(s1)
    80002a18:	c3a1                	beqz	a5,80002a58 <usertrap+0xe0>
    80002a1a:	a815                	j	80002a4e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a20:	5890                	lw	a2,48(s1)
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	92650513          	addi	a0,a0,-1754 # 80008348 <states.1765+0x78>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b5e080e7          	jalr	-1186(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a36:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	93e50513          	addi	a0,a0,-1730 # 80008378 <states.1765+0xa8>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
    p->killed = 1;
    80002a4a:	4785                	li	a5,1
    80002a4c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a4e:	557d                	li	a0,-1
    80002a50:	00000097          	auipc	ra,0x0
    80002a54:	a56080e7          	jalr	-1450(ra) # 800024a6 <exit>
  if(which_dev == 2)
    80002a58:	4789                	li	a5,2
    80002a5a:	f8f910e3          	bne	s2,a5,800029da <usertrap+0x62>
    yield();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	7b0080e7          	jalr	1968(ra) # 8000220e <yield>
    80002a66:	bf95                	j	800029da <usertrap+0x62>
  int which_dev = 0;
    80002a68:	4901                	li	s2,0
    80002a6a:	b7d5                	j	80002a4e <usertrap+0xd6>

0000000080002a6c <kerneltrap>:
{
    80002a6c:	7179                	addi	sp,sp,-48
    80002a6e:	f406                	sd	ra,40(sp)
    80002a70:	f022                	sd	s0,32(sp)
    80002a72:	ec26                	sd	s1,24(sp)
    80002a74:	e84a                	sd	s2,16(sp)
    80002a76:	e44e                	sd	s3,8(sp)
    80002a78:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a82:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a86:	1004f793          	andi	a5,s1,256
    80002a8a:	cb85                	beqz	a5,80002aba <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a90:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a92:	ef85                	bnez	a5,80002aca <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	e42080e7          	jalr	-446(ra) # 800028d6 <devintr>
    80002a9c:	cd1d                	beqz	a0,80002ada <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a9e:	4789                	li	a5,2
    80002aa0:	06f50a63          	beq	a0,a5,80002b14 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aa4:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa8:	10049073          	csrw	sstatus,s1
}
    80002aac:	70a2                	ld	ra,40(sp)
    80002aae:	7402                	ld	s0,32(sp)
    80002ab0:	64e2                	ld	s1,24(sp)
    80002ab2:	6942                	ld	s2,16(sp)
    80002ab4:	69a2                	ld	s3,8(sp)
    80002ab6:	6145                	addi	sp,sp,48
    80002ab8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	8de50513          	addi	a0,a0,-1826 # 80008398 <states.1765+0xc8>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	a7c080e7          	jalr	-1412(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002aca:	00006517          	auipc	a0,0x6
    80002ace:	8f650513          	addi	a0,a0,-1802 # 800083c0 <states.1765+0xf0>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	a6c080e7          	jalr	-1428(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ada:	85ce                	mv	a1,s3
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	90450513          	addi	a0,a0,-1788 # 800083e0 <states.1765+0x110>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	aa4080e7          	jalr	-1372(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002af0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002af4:	00006517          	auipc	a0,0x6
    80002af8:	8fc50513          	addi	a0,a0,-1796 # 800083f0 <states.1765+0x120>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	a8c080e7          	jalr	-1396(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	90450513          	addi	a0,a0,-1788 # 80008408 <states.1765+0x138>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	03c080e7          	jalr	60(ra) # 80001b50 <myproc>
    80002b1c:	d541                	beqz	a0,80002aa4 <kerneltrap+0x38>
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	032080e7          	jalr	50(ra) # 80001b50 <myproc>
    80002b26:	4d18                	lw	a4,24(a0)
    80002b28:	4791                	li	a5,4
    80002b2a:	f6f71de3          	bne	a4,a5,80002aa4 <kerneltrap+0x38>
    yield();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	6e0080e7          	jalr	1760(ra) # 8000220e <yield>
    80002b36:	b7bd                	j	80002aa4 <kerneltrap+0x38>

0000000080002b38 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	1000                	addi	s0,sp,32
    80002b42:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	00c080e7          	jalr	12(ra) # 80001b50 <myproc>
  switch (n) {
    80002b4c:	4795                	li	a5,5
    80002b4e:	0497e163          	bltu	a5,s1,80002b90 <argraw+0x58>
    80002b52:	048a                	slli	s1,s1,0x2
    80002b54:	00006717          	auipc	a4,0x6
    80002b58:	8ec70713          	addi	a4,a4,-1812 # 80008440 <states.1765+0x170>
    80002b5c:	94ba                	add	s1,s1,a4
    80002b5e:	409c                	lw	a5,0(s1)
    80002b60:	97ba                	add	a5,a5,a4
    80002b62:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b64:	6d3c                	ld	a5,88(a0)
    80002b66:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	64a2                	ld	s1,8(sp)
    80002b6e:	6105                	addi	sp,sp,32
    80002b70:	8082                	ret
    return p->trapframe->a1;
    80002b72:	6d3c                	ld	a5,88(a0)
    80002b74:	7fa8                	ld	a0,120(a5)
    80002b76:	bfcd                	j	80002b68 <argraw+0x30>
    return p->trapframe->a2;
    80002b78:	6d3c                	ld	a5,88(a0)
    80002b7a:	63c8                	ld	a0,128(a5)
    80002b7c:	b7f5                	j	80002b68 <argraw+0x30>
    return p->trapframe->a3;
    80002b7e:	6d3c                	ld	a5,88(a0)
    80002b80:	67c8                	ld	a0,136(a5)
    80002b82:	b7dd                	j	80002b68 <argraw+0x30>
    return p->trapframe->a4;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	6bc8                	ld	a0,144(a5)
    80002b88:	b7c5                	j	80002b68 <argraw+0x30>
    return p->trapframe->a5;
    80002b8a:	6d3c                	ld	a5,88(a0)
    80002b8c:	6fc8                	ld	a0,152(a5)
    80002b8e:	bfe9                	j	80002b68 <argraw+0x30>
  panic("argraw");
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	88850513          	addi	a0,a0,-1912 # 80008418 <states.1765+0x148>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9a6080e7          	jalr	-1626(ra) # 8000053e <panic>

0000000080002ba0 <fetchaddr>:
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	e04a                	sd	s2,0(sp)
    80002baa:	1000                	addi	s0,sp,32
    80002bac:	84aa                	mv	s1,a0
    80002bae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	fa0080e7          	jalr	-96(ra) # 80001b50 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bb8:	653c                	ld	a5,72(a0)
    80002bba:	02f4f863          	bgeu	s1,a5,80002bea <fetchaddr+0x4a>
    80002bbe:	00848713          	addi	a4,s1,8
    80002bc2:	02e7e663          	bltu	a5,a4,80002bee <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bc6:	46a1                	li	a3,8
    80002bc8:	8626                	mv	a2,s1
    80002bca:	85ca                	mv	a1,s2
    80002bcc:	6928                	ld	a0,80(a0)
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	b30080e7          	jalr	-1232(ra) # 800016fe <copyin>
    80002bd6:	00a03533          	snez	a0,a0
    80002bda:	40a00533          	neg	a0,a0
}
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	64a2                	ld	s1,8(sp)
    80002be4:	6902                	ld	s2,0(sp)
    80002be6:	6105                	addi	sp,sp,32
    80002be8:	8082                	ret
    return -1;
    80002bea:	557d                	li	a0,-1
    80002bec:	bfcd                	j	80002bde <fetchaddr+0x3e>
    80002bee:	557d                	li	a0,-1
    80002bf0:	b7fd                	j	80002bde <fetchaddr+0x3e>

0000000080002bf2 <fetchstr>:
{
    80002bf2:	7179                	addi	sp,sp,-48
    80002bf4:	f406                	sd	ra,40(sp)
    80002bf6:	f022                	sd	s0,32(sp)
    80002bf8:	ec26                	sd	s1,24(sp)
    80002bfa:	e84a                	sd	s2,16(sp)
    80002bfc:	e44e                	sd	s3,8(sp)
    80002bfe:	1800                	addi	s0,sp,48
    80002c00:	892a                	mv	s2,a0
    80002c02:	84ae                	mv	s1,a1
    80002c04:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	f4a080e7          	jalr	-182(ra) # 80001b50 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c0e:	86ce                	mv	a3,s3
    80002c10:	864a                	mv	a2,s2
    80002c12:	85a6                	mv	a1,s1
    80002c14:	6928                	ld	a0,80(a0)
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	b74080e7          	jalr	-1164(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002c1e:	00054763          	bltz	a0,80002c2c <fetchstr+0x3a>
  return strlen(buf);
    80002c22:	8526                	mv	a0,s1
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	240080e7          	jalr	576(ra) # 80000e64 <strlen>
}
    80002c2c:	70a2                	ld	ra,40(sp)
    80002c2e:	7402                	ld	s0,32(sp)
    80002c30:	64e2                	ld	s1,24(sp)
    80002c32:	6942                	ld	s2,16(sp)
    80002c34:	69a2                	ld	s3,8(sp)
    80002c36:	6145                	addi	sp,sp,48
    80002c38:	8082                	ret

0000000080002c3a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	1000                	addi	s0,sp,32
    80002c44:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	ef2080e7          	jalr	-270(ra) # 80002b38 <argraw>
    80002c4e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c50:	4501                	li	a0,0
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6105                	addi	sp,sp,32
    80002c5a:	8082                	ret

0000000080002c5c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c5c:	1101                	addi	sp,sp,-32
    80002c5e:	ec06                	sd	ra,24(sp)
    80002c60:	e822                	sd	s0,16(sp)
    80002c62:	e426                	sd	s1,8(sp)
    80002c64:	1000                	addi	s0,sp,32
    80002c66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	ed0080e7          	jalr	-304(ra) # 80002b38 <argraw>
    80002c70:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c72:	4501                	li	a0,0
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	64a2                	ld	s1,8(sp)
    80002c7a:	6105                	addi	sp,sp,32
    80002c7c:	8082                	ret

0000000080002c7e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c7e:	1101                	addi	sp,sp,-32
    80002c80:	ec06                	sd	ra,24(sp)
    80002c82:	e822                	sd	s0,16(sp)
    80002c84:	e426                	sd	s1,8(sp)
    80002c86:	e04a                	sd	s2,0(sp)
    80002c88:	1000                	addi	s0,sp,32
    80002c8a:	84ae                	mv	s1,a1
    80002c8c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	eaa080e7          	jalr	-342(ra) # 80002b38 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c96:	864a                	mv	a2,s2
    80002c98:	85a6                	mv	a1,s1
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	f58080e7          	jalr	-168(ra) # 80002bf2 <fetchstr>
}
    80002ca2:	60e2                	ld	ra,24(sp)
    80002ca4:	6442                	ld	s0,16(sp)
    80002ca6:	64a2                	ld	s1,8(sp)
    80002ca8:	6902                	ld	s2,0(sp)
    80002caa:	6105                	addi	sp,sp,32
    80002cac:	8082                	ret

0000000080002cae <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	e426                	sd	s1,8(sp)
    80002cb6:	e04a                	sd	s2,0(sp)
    80002cb8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	e96080e7          	jalr	-362(ra) # 80001b50 <myproc>
    80002cc2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cc4:	05853903          	ld	s2,88(a0)
    80002cc8:	0a893783          	ld	a5,168(s2)
    80002ccc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cd0:	37fd                	addiw	a5,a5,-1
    80002cd2:	4751                	li	a4,20
    80002cd4:	00f76f63          	bltu	a4,a5,80002cf2 <syscall+0x44>
    80002cd8:	00369713          	slli	a4,a3,0x3
    80002cdc:	00005797          	auipc	a5,0x5
    80002ce0:	77c78793          	addi	a5,a5,1916 # 80008458 <syscalls>
    80002ce4:	97ba                	add	a5,a5,a4
    80002ce6:	639c                	ld	a5,0(a5)
    80002ce8:	c789                	beqz	a5,80002cf2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cea:	9782                	jalr	a5
    80002cec:	06a93823          	sd	a0,112(s2)
    80002cf0:	a839                	j	80002d0e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cf2:	15848613          	addi	a2,s1,344
    80002cf6:	588c                	lw	a1,48(s1)
    80002cf8:	00005517          	auipc	a0,0x5
    80002cfc:	72850513          	addi	a0,a0,1832 # 80008420 <states.1765+0x150>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d08:	6cbc                	ld	a5,88(s1)
    80002d0a:	577d                	li	a4,-1
    80002d0c:	fbb8                	sd	a4,112(a5)
  }
}
    80002d0e:	60e2                	ld	ra,24(sp)
    80002d10:	6442                	ld	s0,16(sp)
    80002d12:	64a2                	ld	s1,8(sp)
    80002d14:	6902                	ld	s2,0(sp)
    80002d16:	6105                	addi	sp,sp,32
    80002d18:	8082                	ret

0000000080002d1a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d1a:	1101                	addi	sp,sp,-32
    80002d1c:	ec06                	sd	ra,24(sp)
    80002d1e:	e822                	sd	s0,16(sp)
    80002d20:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d22:	fec40593          	addi	a1,s0,-20
    80002d26:	4501                	li	a0,0
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	f12080e7          	jalr	-238(ra) # 80002c3a <argint>
    return -1;
    80002d30:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d32:	00054963          	bltz	a0,80002d44 <sys_exit+0x2a>
  exit(n);
    80002d36:	fec42503          	lw	a0,-20(s0)
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	76c080e7          	jalr	1900(ra) # 800024a6 <exit>
  return 0;  // not reached
    80002d42:	4781                	li	a5,0
}
    80002d44:	853e                	mv	a0,a5
    80002d46:	60e2                	ld	ra,24(sp)
    80002d48:	6442                	ld	s0,16(sp)
    80002d4a:	6105                	addi	sp,sp,32
    80002d4c:	8082                	ret

0000000080002d4e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d4e:	1141                	addi	sp,sp,-16
    80002d50:	e406                	sd	ra,8(sp)
    80002d52:	e022                	sd	s0,0(sp)
    80002d54:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	dfa080e7          	jalr	-518(ra) # 80001b50 <myproc>
}
    80002d5e:	5908                	lw	a0,48(a0)
    80002d60:	60a2                	ld	ra,8(sp)
    80002d62:	6402                	ld	s0,0(sp)
    80002d64:	0141                	addi	sp,sp,16
    80002d66:	8082                	ret

0000000080002d68 <sys_fork>:

uint64
sys_fork(void)
{
    80002d68:	1141                	addi	sp,sp,-16
    80002d6a:	e406                	sd	ra,8(sp)
    80002d6c:	e022                	sd	s0,0(sp)
    80002d6e:	0800                	addi	s0,sp,16
  return fork();
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	1aa080e7          	jalr	426(ra) # 80001f1a <fork>
}
    80002d78:	60a2                	ld	ra,8(sp)
    80002d7a:	6402                	ld	s0,0(sp)
    80002d7c:	0141                	addi	sp,sp,16
    80002d7e:	8082                	ret

0000000080002d80 <sys_wait>:

uint64
sys_wait(void)
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d88:	fe840593          	addi	a1,s0,-24
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	ece080e7          	jalr	-306(ra) # 80002c5c <argaddr>
    80002d96:	87aa                	mv	a5,a0
    return -1;
    80002d98:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d9a:	0007c863          	bltz	a5,80002daa <sys_wait+0x2a>
  return wait(p);
    80002d9e:	fe843503          	ld	a0,-24(s0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	50c080e7          	jalr	1292(ra) # 800022ae <wait>
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002db2:	7179                	addi	sp,sp,-48
    80002db4:	f406                	sd	ra,40(sp)
    80002db6:	f022                	sd	s0,32(sp)
    80002db8:	ec26                	sd	s1,24(sp)
    80002dba:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dbc:	fdc40593          	addi	a1,s0,-36
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	e78080e7          	jalr	-392(ra) # 80002c3a <argint>
    80002dca:	87aa                	mv	a5,a0
    return -1;
    80002dcc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dce:	0207c063          	bltz	a5,80002dee <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	d7e080e7          	jalr	-642(ra) # 80001b50 <myproc>
    80002dda:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ddc:	fdc42503          	lw	a0,-36(s0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	0c6080e7          	jalr	198(ra) # 80001ea6 <growproc>
    80002de8:	00054863          	bltz	a0,80002df8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dec:	8526                	mv	a0,s1
}
    80002dee:	70a2                	ld	ra,40(sp)
    80002df0:	7402                	ld	s0,32(sp)
    80002df2:	64e2                	ld	s1,24(sp)
    80002df4:	6145                	addi	sp,sp,48
    80002df6:	8082                	ret
    return -1;
    80002df8:	557d                	li	a0,-1
    80002dfa:	bfd5                	j	80002dee <sys_sbrk+0x3c>

0000000080002dfc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dfc:	7139                	addi	sp,sp,-64
    80002dfe:	fc06                	sd	ra,56(sp)
    80002e00:	f822                	sd	s0,48(sp)
    80002e02:	f426                	sd	s1,40(sp)
    80002e04:	f04a                	sd	s2,32(sp)
    80002e06:	ec4e                	sd	s3,24(sp)
    80002e08:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e0a:	fcc40593          	addi	a1,s0,-52
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	e2a080e7          	jalr	-470(ra) # 80002c3a <argint>
    return -1;
    80002e18:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e1a:	06054563          	bltz	a0,80002e84 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	74250513          	addi	a0,a0,1858 # 80017560 <tickslock>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	dbe080e7          	jalr	-578(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e2e:	00006917          	auipc	s2,0x6
    80002e32:	21a92903          	lw	s2,538(s2) # 80009048 <ticks>
  while(ticks - ticks0 < n){
    80002e36:	fcc42783          	lw	a5,-52(s0)
    80002e3a:	cf85                	beqz	a5,80002e72 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e3c:	00014997          	auipc	s3,0x14
    80002e40:	72498993          	addi	s3,s3,1828 # 80017560 <tickslock>
    80002e44:	00006497          	auipc	s1,0x6
    80002e48:	20448493          	addi	s1,s1,516 # 80009048 <ticks>
    if(myproc()->killed){
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	d04080e7          	jalr	-764(ra) # 80001b50 <myproc>
    80002e54:	551c                	lw	a5,40(a0)
    80002e56:	ef9d                	bnez	a5,80002e94 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e58:	85ce                	mv	a1,s3
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	3ee080e7          	jalr	1006(ra) # 8000224a <sleep>
  while(ticks - ticks0 < n){
    80002e64:	409c                	lw	a5,0(s1)
    80002e66:	412787bb          	subw	a5,a5,s2
    80002e6a:	fcc42703          	lw	a4,-52(s0)
    80002e6e:	fce7efe3          	bltu	a5,a4,80002e4c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e72:	00014517          	auipc	a0,0x14
    80002e76:	6ee50513          	addi	a0,a0,1774 # 80017560 <tickslock>
    80002e7a:	ffffe097          	auipc	ra,0xffffe
    80002e7e:	e1e080e7          	jalr	-482(ra) # 80000c98 <release>
  return 0;
    80002e82:	4781                	li	a5,0
}
    80002e84:	853e                	mv	a0,a5
    80002e86:	70e2                	ld	ra,56(sp)
    80002e88:	7442                	ld	s0,48(sp)
    80002e8a:	74a2                	ld	s1,40(sp)
    80002e8c:	7902                	ld	s2,32(sp)
    80002e8e:	69e2                	ld	s3,24(sp)
    80002e90:	6121                	addi	sp,sp,64
    80002e92:	8082                	ret
      release(&tickslock);
    80002e94:	00014517          	auipc	a0,0x14
    80002e98:	6cc50513          	addi	a0,a0,1740 # 80017560 <tickslock>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	dfc080e7          	jalr	-516(ra) # 80000c98 <release>
      return -1;
    80002ea4:	57fd                	li	a5,-1
    80002ea6:	bff9                	j	80002e84 <sys_sleep+0x88>

0000000080002ea8 <sys_kill>:

uint64
sys_kill(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002eb0:	fec40593          	addi	a1,s0,-20
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	d84080e7          	jalr	-636(ra) # 80002c3a <argint>
    80002ebe:	87aa                	mv	a5,a0
    return -1;
    80002ec0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ec2:	0007c863          	bltz	a5,80002ed2 <sys_kill+0x2a>
  return kill(pid);
    80002ec6:	fec42503          	lw	a0,-20(s0)
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	6b2080e7          	jalr	1714(ra) # 8000257c <kill>
}
    80002ed2:	60e2                	ld	ra,24(sp)
    80002ed4:	6442                	ld	s0,16(sp)
    80002ed6:	6105                	addi	sp,sp,32
    80002ed8:	8082                	ret

0000000080002eda <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	e426                	sd	s1,8(sp)
    80002ee2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ee4:	00014517          	auipc	a0,0x14
    80002ee8:	67c50513          	addi	a0,a0,1660 # 80017560 <tickslock>
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	cf8080e7          	jalr	-776(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002ef4:	00006497          	auipc	s1,0x6
    80002ef8:	1544a483          	lw	s1,340(s1) # 80009048 <ticks>
  release(&tickslock);
    80002efc:	00014517          	auipc	a0,0x14
    80002f00:	66450513          	addi	a0,a0,1636 # 80017560 <tickslock>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
  return xticks;
}
    80002f0c:	02049513          	slli	a0,s1,0x20
    80002f10:	9101                	srli	a0,a0,0x20
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	64a2                	ld	s1,8(sp)
    80002f18:	6105                	addi	sp,sp,32
    80002f1a:	8082                	ret

0000000080002f1c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f1c:	7179                	addi	sp,sp,-48
    80002f1e:	f406                	sd	ra,40(sp)
    80002f20:	f022                	sd	s0,32(sp)
    80002f22:	ec26                	sd	s1,24(sp)
    80002f24:	e84a                	sd	s2,16(sp)
    80002f26:	e44e                	sd	s3,8(sp)
    80002f28:	e052                	sd	s4,0(sp)
    80002f2a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f2c:	00005597          	auipc	a1,0x5
    80002f30:	5dc58593          	addi	a1,a1,1500 # 80008508 <syscalls+0xb0>
    80002f34:	00014517          	auipc	a0,0x14
    80002f38:	64450513          	addi	a0,a0,1604 # 80017578 <bcache>
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	c18080e7          	jalr	-1000(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f44:	0001c797          	auipc	a5,0x1c
    80002f48:	63478793          	addi	a5,a5,1588 # 8001f578 <bcache+0x8000>
    80002f4c:	0001d717          	auipc	a4,0x1d
    80002f50:	89470713          	addi	a4,a4,-1900 # 8001f7e0 <bcache+0x8268>
    80002f54:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f58:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f5c:	00014497          	auipc	s1,0x14
    80002f60:	63448493          	addi	s1,s1,1588 # 80017590 <bcache+0x18>
    b->next = bcache.head.next;
    80002f64:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f66:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f68:	00005a17          	auipc	s4,0x5
    80002f6c:	5a8a0a13          	addi	s4,s4,1448 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f70:	2b893783          	ld	a5,696(s2)
    80002f74:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f76:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f7a:	85d2                	mv	a1,s4
    80002f7c:	01048513          	addi	a0,s1,16
    80002f80:	00001097          	auipc	ra,0x1
    80002f84:	4bc080e7          	jalr	1212(ra) # 8000443c <initsleeplock>
    bcache.head.next->prev = b;
    80002f88:	2b893783          	ld	a5,696(s2)
    80002f8c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f8e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f92:	45848493          	addi	s1,s1,1112
    80002f96:	fd349de3          	bne	s1,s3,80002f70 <binit+0x54>
  }
}
    80002f9a:	70a2                	ld	ra,40(sp)
    80002f9c:	7402                	ld	s0,32(sp)
    80002f9e:	64e2                	ld	s1,24(sp)
    80002fa0:	6942                	ld	s2,16(sp)
    80002fa2:	69a2                	ld	s3,8(sp)
    80002fa4:	6a02                	ld	s4,0(sp)
    80002fa6:	6145                	addi	sp,sp,48
    80002fa8:	8082                	ret

0000000080002faa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002faa:	7179                	addi	sp,sp,-48
    80002fac:	f406                	sd	ra,40(sp)
    80002fae:	f022                	sd	s0,32(sp)
    80002fb0:	ec26                	sd	s1,24(sp)
    80002fb2:	e84a                	sd	s2,16(sp)
    80002fb4:	e44e                	sd	s3,8(sp)
    80002fb6:	1800                	addi	s0,sp,48
    80002fb8:	89aa                	mv	s3,a0
    80002fba:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	5bc50513          	addi	a0,a0,1468 # 80017578 <bcache>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	c20080e7          	jalr	-992(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fcc:	0001d497          	auipc	s1,0x1d
    80002fd0:	8644b483          	ld	s1,-1948(s1) # 8001f830 <bcache+0x82b8>
    80002fd4:	0001d797          	auipc	a5,0x1d
    80002fd8:	80c78793          	addi	a5,a5,-2036 # 8001f7e0 <bcache+0x8268>
    80002fdc:	02f48f63          	beq	s1,a5,8000301a <bread+0x70>
    80002fe0:	873e                	mv	a4,a5
    80002fe2:	a021                	j	80002fea <bread+0x40>
    80002fe4:	68a4                	ld	s1,80(s1)
    80002fe6:	02e48a63          	beq	s1,a4,8000301a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fea:	449c                	lw	a5,8(s1)
    80002fec:	ff379ce3          	bne	a5,s3,80002fe4 <bread+0x3a>
    80002ff0:	44dc                	lw	a5,12(s1)
    80002ff2:	ff2799e3          	bne	a5,s2,80002fe4 <bread+0x3a>
      b->refcnt++;
    80002ff6:	40bc                	lw	a5,64(s1)
    80002ff8:	2785                	addiw	a5,a5,1
    80002ffa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ffc:	00014517          	auipc	a0,0x14
    80003000:	57c50513          	addi	a0,a0,1404 # 80017578 <bcache>
    80003004:	ffffe097          	auipc	ra,0xffffe
    80003008:	c94080e7          	jalr	-876(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000300c:	01048513          	addi	a0,s1,16
    80003010:	00001097          	auipc	ra,0x1
    80003014:	466080e7          	jalr	1126(ra) # 80004476 <acquiresleep>
      return b;
    80003018:	a8b9                	j	80003076 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301a:	0001d497          	auipc	s1,0x1d
    8000301e:	80e4b483          	ld	s1,-2034(s1) # 8001f828 <bcache+0x82b0>
    80003022:	0001c797          	auipc	a5,0x1c
    80003026:	7be78793          	addi	a5,a5,1982 # 8001f7e0 <bcache+0x8268>
    8000302a:	00f48863          	beq	s1,a5,8000303a <bread+0x90>
    8000302e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003030:	40bc                	lw	a5,64(s1)
    80003032:	cf81                	beqz	a5,8000304a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003034:	64a4                	ld	s1,72(s1)
    80003036:	fee49de3          	bne	s1,a4,80003030 <bread+0x86>
  panic("bget: no buffers");
    8000303a:	00005517          	auipc	a0,0x5
    8000303e:	4de50513          	addi	a0,a0,1246 # 80008518 <syscalls+0xc0>
    80003042:	ffffd097          	auipc	ra,0xffffd
    80003046:	4fc080e7          	jalr	1276(ra) # 8000053e <panic>
      b->dev = dev;
    8000304a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000304e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003052:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003056:	4785                	li	a5,1
    80003058:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000305a:	00014517          	auipc	a0,0x14
    8000305e:	51e50513          	addi	a0,a0,1310 # 80017578 <bcache>
    80003062:	ffffe097          	auipc	ra,0xffffe
    80003066:	c36080e7          	jalr	-970(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000306a:	01048513          	addi	a0,s1,16
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	408080e7          	jalr	1032(ra) # 80004476 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003076:	409c                	lw	a5,0(s1)
    80003078:	cb89                	beqz	a5,8000308a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000307a:	8526                	mv	a0,s1
    8000307c:	70a2                	ld	ra,40(sp)
    8000307e:	7402                	ld	s0,32(sp)
    80003080:	64e2                	ld	s1,24(sp)
    80003082:	6942                	ld	s2,16(sp)
    80003084:	69a2                	ld	s3,8(sp)
    80003086:	6145                	addi	sp,sp,48
    80003088:	8082                	ret
    virtio_disk_rw(b, 0);
    8000308a:	4581                	li	a1,0
    8000308c:	8526                	mv	a0,s1
    8000308e:	00003097          	auipc	ra,0x3
    80003092:	f08080e7          	jalr	-248(ra) # 80005f96 <virtio_disk_rw>
    b->valid = 1;
    80003096:	4785                	li	a5,1
    80003098:	c09c                	sw	a5,0(s1)
  return b;
    8000309a:	b7c5                	j	8000307a <bread+0xd0>

000000008000309c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000309c:	1101                	addi	sp,sp,-32
    8000309e:	ec06                	sd	ra,24(sp)
    800030a0:	e822                	sd	s0,16(sp)
    800030a2:	e426                	sd	s1,8(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a8:	0541                	addi	a0,a0,16
    800030aa:	00001097          	auipc	ra,0x1
    800030ae:	466080e7          	jalr	1126(ra) # 80004510 <holdingsleep>
    800030b2:	cd01                	beqz	a0,800030ca <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030b4:	4585                	li	a1,1
    800030b6:	8526                	mv	a0,s1
    800030b8:	00003097          	auipc	ra,0x3
    800030bc:	ede080e7          	jalr	-290(ra) # 80005f96 <virtio_disk_rw>
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
    panic("bwrite");
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	46650513          	addi	a0,a0,1126 # 80008530 <syscalls+0xd8>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>

00000000800030da <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	e04a                	sd	s2,0(sp)
    800030e4:	1000                	addi	s0,sp,32
    800030e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e8:	01050913          	addi	s2,a0,16
    800030ec:	854a                	mv	a0,s2
    800030ee:	00001097          	auipc	ra,0x1
    800030f2:	422080e7          	jalr	1058(ra) # 80004510 <holdingsleep>
    800030f6:	c92d                	beqz	a0,80003168 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030f8:	854a                	mv	a0,s2
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	3d2080e7          	jalr	978(ra) # 800044cc <releasesleep>

  acquire(&bcache.lock);
    80003102:	00014517          	auipc	a0,0x14
    80003106:	47650513          	addi	a0,a0,1142 # 80017578 <bcache>
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003112:	40bc                	lw	a5,64(s1)
    80003114:	37fd                	addiw	a5,a5,-1
    80003116:	0007871b          	sext.w	a4,a5
    8000311a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000311c:	eb05                	bnez	a4,8000314c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000311e:	68bc                	ld	a5,80(s1)
    80003120:	64b8                	ld	a4,72(s1)
    80003122:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003124:	64bc                	ld	a5,72(s1)
    80003126:	68b8                	ld	a4,80(s1)
    80003128:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000312a:	0001c797          	auipc	a5,0x1c
    8000312e:	44e78793          	addi	a5,a5,1102 # 8001f578 <bcache+0x8000>
    80003132:	2b87b703          	ld	a4,696(a5)
    80003136:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003138:	0001c717          	auipc	a4,0x1c
    8000313c:	6a870713          	addi	a4,a4,1704 # 8001f7e0 <bcache+0x8268>
    80003140:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003142:	2b87b703          	ld	a4,696(a5)
    80003146:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003148:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	42c50513          	addi	a0,a0,1068 # 80017578 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
}
    8000315c:	60e2                	ld	ra,24(sp)
    8000315e:	6442                	ld	s0,16(sp)
    80003160:	64a2                	ld	s1,8(sp)
    80003162:	6902                	ld	s2,0(sp)
    80003164:	6105                	addi	sp,sp,32
    80003166:	8082                	ret
    panic("brelse");
    80003168:	00005517          	auipc	a0,0x5
    8000316c:	3d050513          	addi	a0,a0,976 # 80008538 <syscalls+0xe0>
    80003170:	ffffd097          	auipc	ra,0xffffd
    80003174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>

0000000080003178 <bpin>:

void
bpin(struct buf *b) {
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	3f450513          	addi	a0,a0,1012 # 80017578 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a58080e7          	jalr	-1448(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003194:	40bc                	lw	a5,64(s1)
    80003196:	2785                	addiw	a5,a5,1
    80003198:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000319a:	00014517          	auipc	a0,0x14
    8000319e:	3de50513          	addi	a0,a0,990 # 80017578 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <bunpin>:

void
bunpin(struct buf *b) {
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c0:	00014517          	auipc	a0,0x14
    800031c4:	3b850513          	addi	a0,a0,952 # 80017578 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	a1c080e7          	jalr	-1508(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031d0:	40bc                	lw	a5,64(s1)
    800031d2:	37fd                	addiw	a5,a5,-1
    800031d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d6:	00014517          	auipc	a0,0x14
    800031da:	3a250513          	addi	a0,a0,930 # 80017578 <bcache>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
}
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	64a2                	ld	s1,8(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret

00000000800031f0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	e04a                	sd	s2,0(sp)
    800031fa:	1000                	addi	s0,sp,32
    800031fc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031fe:	00d5d59b          	srliw	a1,a1,0xd
    80003202:	0001d797          	auipc	a5,0x1d
    80003206:	a527a783          	lw	a5,-1454(a5) # 8001fc54 <sb+0x1c>
    8000320a:	9dbd                	addw	a1,a1,a5
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	d9e080e7          	jalr	-610(ra) # 80002faa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003214:	0074f713          	andi	a4,s1,7
    80003218:	4785                	li	a5,1
    8000321a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000321e:	14ce                	slli	s1,s1,0x33
    80003220:	90d9                	srli	s1,s1,0x36
    80003222:	00950733          	add	a4,a0,s1
    80003226:	05874703          	lbu	a4,88(a4)
    8000322a:	00e7f6b3          	and	a3,a5,a4
    8000322e:	c69d                	beqz	a3,8000325c <bfree+0x6c>
    80003230:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003232:	94aa                	add	s1,s1,a0
    80003234:	fff7c793          	not	a5,a5
    80003238:	8ff9                	and	a5,a5,a4
    8000323a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000323e:	00001097          	auipc	ra,0x1
    80003242:	118080e7          	jalr	280(ra) # 80004356 <log_write>
  brelse(bp);
    80003246:	854a                	mv	a0,s2
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	e92080e7          	jalr	-366(ra) # 800030da <brelse>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6902                	ld	s2,0(sp)
    80003258:	6105                	addi	sp,sp,32
    8000325a:	8082                	ret
    panic("freeing free block");
    8000325c:	00005517          	auipc	a0,0x5
    80003260:	2e450513          	addi	a0,a0,740 # 80008540 <syscalls+0xe8>
    80003264:	ffffd097          	auipc	ra,0xffffd
    80003268:	2da080e7          	jalr	730(ra) # 8000053e <panic>

000000008000326c <balloc>:
{
    8000326c:	711d                	addi	sp,sp,-96
    8000326e:	ec86                	sd	ra,88(sp)
    80003270:	e8a2                	sd	s0,80(sp)
    80003272:	e4a6                	sd	s1,72(sp)
    80003274:	e0ca                	sd	s2,64(sp)
    80003276:	fc4e                	sd	s3,56(sp)
    80003278:	f852                	sd	s4,48(sp)
    8000327a:	f456                	sd	s5,40(sp)
    8000327c:	f05a                	sd	s6,32(sp)
    8000327e:	ec5e                	sd	s7,24(sp)
    80003280:	e862                	sd	s8,16(sp)
    80003282:	e466                	sd	s9,8(sp)
    80003284:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003286:	0001d797          	auipc	a5,0x1d
    8000328a:	9b67a783          	lw	a5,-1610(a5) # 8001fc3c <sb+0x4>
    8000328e:	cbd1                	beqz	a5,80003322 <balloc+0xb6>
    80003290:	8baa                	mv	s7,a0
    80003292:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003294:	0001db17          	auipc	s6,0x1d
    80003298:	9a4b0b13          	addi	s6,s6,-1628 # 8001fc38 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000329e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032a2:	6c89                	lui	s9,0x2
    800032a4:	a831                	j	800032c0 <balloc+0x54>
    brelse(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	e32080e7          	jalr	-462(ra) # 800030da <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032b0:	015c87bb          	addw	a5,s9,s5
    800032b4:	00078a9b          	sext.w	s5,a5
    800032b8:	004b2703          	lw	a4,4(s6)
    800032bc:	06eaf363          	bgeu	s5,a4,80003322 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032c0:	41fad79b          	sraiw	a5,s5,0x1f
    800032c4:	0137d79b          	srliw	a5,a5,0x13
    800032c8:	015787bb          	addw	a5,a5,s5
    800032cc:	40d7d79b          	sraiw	a5,a5,0xd
    800032d0:	01cb2583          	lw	a1,28(s6)
    800032d4:	9dbd                	addw	a1,a1,a5
    800032d6:	855e                	mv	a0,s7
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	cd2080e7          	jalr	-814(ra) # 80002faa <bread>
    800032e0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e2:	004b2503          	lw	a0,4(s6)
    800032e6:	000a849b          	sext.w	s1,s5
    800032ea:	8662                	mv	a2,s8
    800032ec:	faa4fde3          	bgeu	s1,a0,800032a6 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032f0:	41f6579b          	sraiw	a5,a2,0x1f
    800032f4:	01d7d69b          	srliw	a3,a5,0x1d
    800032f8:	00c6873b          	addw	a4,a3,a2
    800032fc:	00777793          	andi	a5,a4,7
    80003300:	9f95                	subw	a5,a5,a3
    80003302:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003306:	4037571b          	sraiw	a4,a4,0x3
    8000330a:	00e906b3          	add	a3,s2,a4
    8000330e:	0586c683          	lbu	a3,88(a3)
    80003312:	00d7f5b3          	and	a1,a5,a3
    80003316:	cd91                	beqz	a1,80003332 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003318:	2605                	addiw	a2,a2,1
    8000331a:	2485                	addiw	s1,s1,1
    8000331c:	fd4618e3          	bne	a2,s4,800032ec <balloc+0x80>
    80003320:	b759                	j	800032a6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003322:	00005517          	auipc	a0,0x5
    80003326:	23650513          	addi	a0,a0,566 # 80008558 <syscalls+0x100>
    8000332a:	ffffd097          	auipc	ra,0xffffd
    8000332e:	214080e7          	jalr	532(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003332:	974a                	add	a4,a4,s2
    80003334:	8fd5                	or	a5,a5,a3
    80003336:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	01a080e7          	jalr	26(ra) # 80004356 <log_write>
        brelse(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	d94080e7          	jalr	-620(ra) # 800030da <brelse>
  bp = bread(dev, bno);
    8000334e:	85a6                	mv	a1,s1
    80003350:	855e                	mv	a0,s7
    80003352:	00000097          	auipc	ra,0x0
    80003356:	c58080e7          	jalr	-936(ra) # 80002faa <bread>
    8000335a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000335c:	40000613          	li	a2,1024
    80003360:	4581                	li	a1,0
    80003362:	05850513          	addi	a0,a0,88
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	97a080e7          	jalr	-1670(ra) # 80000ce0 <memset>
  log_write(bp);
    8000336e:	854a                	mv	a0,s2
    80003370:	00001097          	auipc	ra,0x1
    80003374:	fe6080e7          	jalr	-26(ra) # 80004356 <log_write>
  brelse(bp);
    80003378:	854a                	mv	a0,s2
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	d60080e7          	jalr	-672(ra) # 800030da <brelse>
}
    80003382:	8526                	mv	a0,s1
    80003384:	60e6                	ld	ra,88(sp)
    80003386:	6446                	ld	s0,80(sp)
    80003388:	64a6                	ld	s1,72(sp)
    8000338a:	6906                	ld	s2,64(sp)
    8000338c:	79e2                	ld	s3,56(sp)
    8000338e:	7a42                	ld	s4,48(sp)
    80003390:	7aa2                	ld	s5,40(sp)
    80003392:	7b02                	ld	s6,32(sp)
    80003394:	6be2                	ld	s7,24(sp)
    80003396:	6c42                	ld	s8,16(sp)
    80003398:	6ca2                	ld	s9,8(sp)
    8000339a:	6125                	addi	sp,sp,96
    8000339c:	8082                	ret

000000008000339e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000339e:	7179                	addi	sp,sp,-48
    800033a0:	f406                	sd	ra,40(sp)
    800033a2:	f022                	sd	s0,32(sp)
    800033a4:	ec26                	sd	s1,24(sp)
    800033a6:	e84a                	sd	s2,16(sp)
    800033a8:	e44e                	sd	s3,8(sp)
    800033aa:	e052                	sd	s4,0(sp)
    800033ac:	1800                	addi	s0,sp,48
    800033ae:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033b0:	47ad                	li	a5,11
    800033b2:	04b7fe63          	bgeu	a5,a1,8000340e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033b6:	ff45849b          	addiw	s1,a1,-12
    800033ba:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033be:	0ff00793          	li	a5,255
    800033c2:	0ae7e363          	bltu	a5,a4,80003468 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033c6:	08052583          	lw	a1,128(a0)
    800033ca:	c5ad                	beqz	a1,80003434 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033cc:	00092503          	lw	a0,0(s2)
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	bda080e7          	jalr	-1062(ra) # 80002faa <bread>
    800033d8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033da:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033de:	02049593          	slli	a1,s1,0x20
    800033e2:	9181                	srli	a1,a1,0x20
    800033e4:	058a                	slli	a1,a1,0x2
    800033e6:	00b784b3          	add	s1,a5,a1
    800033ea:	0004a983          	lw	s3,0(s1)
    800033ee:	04098d63          	beqz	s3,80003448 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033f2:	8552                	mv	a0,s4
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	ce6080e7          	jalr	-794(ra) # 800030da <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033fc:	854e                	mv	a0,s3
    800033fe:	70a2                	ld	ra,40(sp)
    80003400:	7402                	ld	s0,32(sp)
    80003402:	64e2                	ld	s1,24(sp)
    80003404:	6942                	ld	s2,16(sp)
    80003406:	69a2                	ld	s3,8(sp)
    80003408:	6a02                	ld	s4,0(sp)
    8000340a:	6145                	addi	sp,sp,48
    8000340c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000340e:	02059493          	slli	s1,a1,0x20
    80003412:	9081                	srli	s1,s1,0x20
    80003414:	048a                	slli	s1,s1,0x2
    80003416:	94aa                	add	s1,s1,a0
    80003418:	0504a983          	lw	s3,80(s1)
    8000341c:	fe0990e3          	bnez	s3,800033fc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003420:	4108                	lw	a0,0(a0)
    80003422:	00000097          	auipc	ra,0x0
    80003426:	e4a080e7          	jalr	-438(ra) # 8000326c <balloc>
    8000342a:	0005099b          	sext.w	s3,a0
    8000342e:	0534a823          	sw	s3,80(s1)
    80003432:	b7e9                	j	800033fc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003434:	4108                	lw	a0,0(a0)
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e36080e7          	jalr	-458(ra) # 8000326c <balloc>
    8000343e:	0005059b          	sext.w	a1,a0
    80003442:	08b92023          	sw	a1,128(s2)
    80003446:	b759                	j	800033cc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003448:	00092503          	lw	a0,0(s2)
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e20080e7          	jalr	-480(ra) # 8000326c <balloc>
    80003454:	0005099b          	sext.w	s3,a0
    80003458:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000345c:	8552                	mv	a0,s4
    8000345e:	00001097          	auipc	ra,0x1
    80003462:	ef8080e7          	jalr	-264(ra) # 80004356 <log_write>
    80003466:	b771                	j	800033f2 <bmap+0x54>
  panic("bmap: out of range");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	10850513          	addi	a0,a0,264 # 80008570 <syscalls+0x118>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>

0000000080003478 <iget>:
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
    80003488:	89aa                	mv	s3,a0
    8000348a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000348c:	0001c517          	auipc	a0,0x1c
    80003490:	7cc50513          	addi	a0,a0,1996 # 8001fc58 <itable>
    80003494:	ffffd097          	auipc	ra,0xffffd
    80003498:	750080e7          	jalr	1872(ra) # 80000be4 <acquire>
  empty = 0;
    8000349c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	0001c497          	auipc	s1,0x1c
    800034a2:	7d248493          	addi	s1,s1,2002 # 8001fc70 <itable+0x18>
    800034a6:	0001e697          	auipc	a3,0x1e
    800034aa:	25a68693          	addi	a3,a3,602 # 80021700 <log>
    800034ae:	a039                	j	800034bc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b0:	02090b63          	beqz	s2,800034e6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b4:	08848493          	addi	s1,s1,136
    800034b8:	02d48a63          	beq	s1,a3,800034ec <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034bc:	449c                	lw	a5,8(s1)
    800034be:	fef059e3          	blez	a5,800034b0 <iget+0x38>
    800034c2:	4098                	lw	a4,0(s1)
    800034c4:	ff3716e3          	bne	a4,s3,800034b0 <iget+0x38>
    800034c8:	40d8                	lw	a4,4(s1)
    800034ca:	ff4713e3          	bne	a4,s4,800034b0 <iget+0x38>
      ip->ref++;
    800034ce:	2785                	addiw	a5,a5,1
    800034d0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034d2:	0001c517          	auipc	a0,0x1c
    800034d6:	78650513          	addi	a0,a0,1926 # 8001fc58 <itable>
    800034da:	ffffd097          	auipc	ra,0xffffd
    800034de:	7be080e7          	jalr	1982(ra) # 80000c98 <release>
      return ip;
    800034e2:	8926                	mv	s2,s1
    800034e4:	a03d                	j	80003512 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e6:	f7f9                	bnez	a5,800034b4 <iget+0x3c>
    800034e8:	8926                	mv	s2,s1
    800034ea:	b7e9                	j	800034b4 <iget+0x3c>
  if(empty == 0)
    800034ec:	02090c63          	beqz	s2,80003524 <iget+0xac>
  ip->dev = dev;
    800034f0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034f4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f8:	4785                	li	a5,1
    800034fa:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034fe:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003502:	0001c517          	auipc	a0,0x1c
    80003506:	75650513          	addi	a0,a0,1878 # 8001fc58 <itable>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	78e080e7          	jalr	1934(ra) # 80000c98 <release>
}
    80003512:	854a                	mv	a0,s2
    80003514:	70a2                	ld	ra,40(sp)
    80003516:	7402                	ld	s0,32(sp)
    80003518:	64e2                	ld	s1,24(sp)
    8000351a:	6942                	ld	s2,16(sp)
    8000351c:	69a2                	ld	s3,8(sp)
    8000351e:	6a02                	ld	s4,0(sp)
    80003520:	6145                	addi	sp,sp,48
    80003522:	8082                	ret
    panic("iget: no inodes");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	06450513          	addi	a0,a0,100 # 80008588 <syscalls+0x130>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	012080e7          	jalr	18(ra) # 8000053e <panic>

0000000080003534 <fsinit>:
fsinit(int dev) {
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	1800                	addi	s0,sp,48
    80003542:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003544:	4585                	li	a1,1
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	a64080e7          	jalr	-1436(ra) # 80002faa <bread>
    8000354e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003550:	0001c997          	auipc	s3,0x1c
    80003554:	6e898993          	addi	s3,s3,1768 # 8001fc38 <sb>
    80003558:	02000613          	li	a2,32
    8000355c:	05850593          	addi	a1,a0,88
    80003560:	854e                	mv	a0,s3
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	7de080e7          	jalr	2014(ra) # 80000d40 <memmove>
  brelse(bp);
    8000356a:	8526                	mv	a0,s1
    8000356c:	00000097          	auipc	ra,0x0
    80003570:	b6e080e7          	jalr	-1170(ra) # 800030da <brelse>
  if(sb.magic != FSMAGIC)
    80003574:	0009a703          	lw	a4,0(s3)
    80003578:	102037b7          	lui	a5,0x10203
    8000357c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003580:	02f71263          	bne	a4,a5,800035a4 <fsinit+0x70>
  initlog(dev, &sb);
    80003584:	0001c597          	auipc	a1,0x1c
    80003588:	6b458593          	addi	a1,a1,1716 # 8001fc38 <sb>
    8000358c:	854a                	mv	a0,s2
    8000358e:	00001097          	auipc	ra,0x1
    80003592:	b4c080e7          	jalr	-1204(ra) # 800040da <initlog>
}
    80003596:	70a2                	ld	ra,40(sp)
    80003598:	7402                	ld	s0,32(sp)
    8000359a:	64e2                	ld	s1,24(sp)
    8000359c:	6942                	ld	s2,16(sp)
    8000359e:	69a2                	ld	s3,8(sp)
    800035a0:	6145                	addi	sp,sp,48
    800035a2:	8082                	ret
    panic("invalid file system");
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	ff450513          	addi	a0,a0,-12 # 80008598 <syscalls+0x140>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800035b4 <iinit>:
{
    800035b4:	7179                	addi	sp,sp,-48
    800035b6:	f406                	sd	ra,40(sp)
    800035b8:	f022                	sd	s0,32(sp)
    800035ba:	ec26                	sd	s1,24(sp)
    800035bc:	e84a                	sd	s2,16(sp)
    800035be:	e44e                	sd	s3,8(sp)
    800035c0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035c2:	00005597          	auipc	a1,0x5
    800035c6:	fee58593          	addi	a1,a1,-18 # 800085b0 <syscalls+0x158>
    800035ca:	0001c517          	auipc	a0,0x1c
    800035ce:	68e50513          	addi	a0,a0,1678 # 8001fc58 <itable>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	582080e7          	jalr	1410(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035da:	0001c497          	auipc	s1,0x1c
    800035de:	6a648493          	addi	s1,s1,1702 # 8001fc80 <itable+0x28>
    800035e2:	0001e997          	auipc	s3,0x1e
    800035e6:	12e98993          	addi	s3,s3,302 # 80021710 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ea:	00005917          	auipc	s2,0x5
    800035ee:	fce90913          	addi	s2,s2,-50 # 800085b8 <syscalls+0x160>
    800035f2:	85ca                	mv	a1,s2
    800035f4:	8526                	mv	a0,s1
    800035f6:	00001097          	auipc	ra,0x1
    800035fa:	e46080e7          	jalr	-442(ra) # 8000443c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035fe:	08848493          	addi	s1,s1,136
    80003602:	ff3498e3          	bne	s1,s3,800035f2 <iinit+0x3e>
}
    80003606:	70a2                	ld	ra,40(sp)
    80003608:	7402                	ld	s0,32(sp)
    8000360a:	64e2                	ld	s1,24(sp)
    8000360c:	6942                	ld	s2,16(sp)
    8000360e:	69a2                	ld	s3,8(sp)
    80003610:	6145                	addi	sp,sp,48
    80003612:	8082                	ret

0000000080003614 <ialloc>:
{
    80003614:	715d                	addi	sp,sp,-80
    80003616:	e486                	sd	ra,72(sp)
    80003618:	e0a2                	sd	s0,64(sp)
    8000361a:	fc26                	sd	s1,56(sp)
    8000361c:	f84a                	sd	s2,48(sp)
    8000361e:	f44e                	sd	s3,40(sp)
    80003620:	f052                	sd	s4,32(sp)
    80003622:	ec56                	sd	s5,24(sp)
    80003624:	e85a                	sd	s6,16(sp)
    80003626:	e45e                	sd	s7,8(sp)
    80003628:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000362a:	0001c717          	auipc	a4,0x1c
    8000362e:	61a72703          	lw	a4,1562(a4) # 8001fc44 <sb+0xc>
    80003632:	4785                	li	a5,1
    80003634:	04e7fa63          	bgeu	a5,a4,80003688 <ialloc+0x74>
    80003638:	8aaa                	mv	s5,a0
    8000363a:	8bae                	mv	s7,a1
    8000363c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000363e:	0001ca17          	auipc	s4,0x1c
    80003642:	5faa0a13          	addi	s4,s4,1530 # 8001fc38 <sb>
    80003646:	00048b1b          	sext.w	s6,s1
    8000364a:	0044d593          	srli	a1,s1,0x4
    8000364e:	018a2783          	lw	a5,24(s4)
    80003652:	9dbd                	addw	a1,a1,a5
    80003654:	8556                	mv	a0,s5
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	954080e7          	jalr	-1708(ra) # 80002faa <bread>
    8000365e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003660:	05850993          	addi	s3,a0,88
    80003664:	00f4f793          	andi	a5,s1,15
    80003668:	079a                	slli	a5,a5,0x6
    8000366a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000366c:	00099783          	lh	a5,0(s3)
    80003670:	c785                	beqz	a5,80003698 <ialloc+0x84>
    brelse(bp);
    80003672:	00000097          	auipc	ra,0x0
    80003676:	a68080e7          	jalr	-1432(ra) # 800030da <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000367a:	0485                	addi	s1,s1,1
    8000367c:	00ca2703          	lw	a4,12(s4)
    80003680:	0004879b          	sext.w	a5,s1
    80003684:	fce7e1e3          	bltu	a5,a4,80003646 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	f3850513          	addi	a0,a0,-200 # 800085c0 <syscalls+0x168>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	eae080e7          	jalr	-338(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003698:	04000613          	li	a2,64
    8000369c:	4581                	li	a1,0
    8000369e:	854e                	mv	a0,s3
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	640080e7          	jalr	1600(ra) # 80000ce0 <memset>
      dip->type = type;
    800036a8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	ca8080e7          	jalr	-856(ra) # 80004356 <log_write>
      brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	a22080e7          	jalr	-1502(ra) # 800030da <brelse>
      return iget(dev, inum);
    800036c0:	85da                	mv	a1,s6
    800036c2:	8556                	mv	a0,s5
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	db4080e7          	jalr	-588(ra) # 80003478 <iget>
}
    800036cc:	60a6                	ld	ra,72(sp)
    800036ce:	6406                	ld	s0,64(sp)
    800036d0:	74e2                	ld	s1,56(sp)
    800036d2:	7942                	ld	s2,48(sp)
    800036d4:	79a2                	ld	s3,40(sp)
    800036d6:	7a02                	ld	s4,32(sp)
    800036d8:	6ae2                	ld	s5,24(sp)
    800036da:	6b42                	ld	s6,16(sp)
    800036dc:	6ba2                	ld	s7,8(sp)
    800036de:	6161                	addi	sp,sp,80
    800036e0:	8082                	ret

00000000800036e2 <iupdate>:
{
    800036e2:	1101                	addi	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	e04a                	sd	s2,0(sp)
    800036ec:	1000                	addi	s0,sp,32
    800036ee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f0:	415c                	lw	a5,4(a0)
    800036f2:	0047d79b          	srliw	a5,a5,0x4
    800036f6:	0001c597          	auipc	a1,0x1c
    800036fa:	55a5a583          	lw	a1,1370(a1) # 8001fc50 <sb+0x18>
    800036fe:	9dbd                	addw	a1,a1,a5
    80003700:	4108                	lw	a0,0(a0)
    80003702:	00000097          	auipc	ra,0x0
    80003706:	8a8080e7          	jalr	-1880(ra) # 80002faa <bread>
    8000370a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000370c:	05850793          	addi	a5,a0,88
    80003710:	40c8                	lw	a0,4(s1)
    80003712:	893d                	andi	a0,a0,15
    80003714:	051a                	slli	a0,a0,0x6
    80003716:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003718:	04449703          	lh	a4,68(s1)
    8000371c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003720:	04649703          	lh	a4,70(s1)
    80003724:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003728:	04849703          	lh	a4,72(s1)
    8000372c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003730:	04a49703          	lh	a4,74(s1)
    80003734:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003738:	44f8                	lw	a4,76(s1)
    8000373a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000373c:	03400613          	li	a2,52
    80003740:	05048593          	addi	a1,s1,80
    80003744:	0531                	addi	a0,a0,12
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	5fa080e7          	jalr	1530(ra) # 80000d40 <memmove>
  log_write(bp);
    8000374e:	854a                	mv	a0,s2
    80003750:	00001097          	auipc	ra,0x1
    80003754:	c06080e7          	jalr	-1018(ra) # 80004356 <log_write>
  brelse(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	980080e7          	jalr	-1664(ra) # 800030da <brelse>
}
    80003762:	60e2                	ld	ra,24(sp)
    80003764:	6442                	ld	s0,16(sp)
    80003766:	64a2                	ld	s1,8(sp)
    80003768:	6902                	ld	s2,0(sp)
    8000376a:	6105                	addi	sp,sp,32
    8000376c:	8082                	ret

000000008000376e <idup>:
{
    8000376e:	1101                	addi	sp,sp,-32
    80003770:	ec06                	sd	ra,24(sp)
    80003772:	e822                	sd	s0,16(sp)
    80003774:	e426                	sd	s1,8(sp)
    80003776:	1000                	addi	s0,sp,32
    80003778:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	4de50513          	addi	a0,a0,1246 # 8001fc58 <itable>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	462080e7          	jalr	1122(ra) # 80000be4 <acquire>
  ip->ref++;
    8000378a:	449c                	lw	a5,8(s1)
    8000378c:	2785                	addiw	a5,a5,1
    8000378e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003790:	0001c517          	auipc	a0,0x1c
    80003794:	4c850513          	addi	a0,a0,1224 # 8001fc58 <itable>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	500080e7          	jalr	1280(ra) # 80000c98 <release>
}
    800037a0:	8526                	mv	a0,s1
    800037a2:	60e2                	ld	ra,24(sp)
    800037a4:	6442                	ld	s0,16(sp)
    800037a6:	64a2                	ld	s1,8(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret

00000000800037ac <ilock>:
{
    800037ac:	1101                	addi	sp,sp,-32
    800037ae:	ec06                	sd	ra,24(sp)
    800037b0:	e822                	sd	s0,16(sp)
    800037b2:	e426                	sd	s1,8(sp)
    800037b4:	e04a                	sd	s2,0(sp)
    800037b6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037b8:	c115                	beqz	a0,800037dc <ilock+0x30>
    800037ba:	84aa                	mv	s1,a0
    800037bc:	451c                	lw	a5,8(a0)
    800037be:	00f05f63          	blez	a5,800037dc <ilock+0x30>
  acquiresleep(&ip->lock);
    800037c2:	0541                	addi	a0,a0,16
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	cb2080e7          	jalr	-846(ra) # 80004476 <acquiresleep>
  if(ip->valid == 0){
    800037cc:	40bc                	lw	a5,64(s1)
    800037ce:	cf99                	beqz	a5,800037ec <ilock+0x40>
}
    800037d0:	60e2                	ld	ra,24(sp)
    800037d2:	6442                	ld	s0,16(sp)
    800037d4:	64a2                	ld	s1,8(sp)
    800037d6:	6902                	ld	s2,0(sp)
    800037d8:	6105                	addi	sp,sp,32
    800037da:	8082                	ret
    panic("ilock");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	dfc50513          	addi	a0,a0,-516 # 800085d8 <syscalls+0x180>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d5a080e7          	jalr	-678(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ec:	40dc                	lw	a5,4(s1)
    800037ee:	0047d79b          	srliw	a5,a5,0x4
    800037f2:	0001c597          	auipc	a1,0x1c
    800037f6:	45e5a583          	lw	a1,1118(a1) # 8001fc50 <sb+0x18>
    800037fa:	9dbd                	addw	a1,a1,a5
    800037fc:	4088                	lw	a0,0(s1)
    800037fe:	fffff097          	auipc	ra,0xfffff
    80003802:	7ac080e7          	jalr	1964(ra) # 80002faa <bread>
    80003806:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003808:	05850593          	addi	a1,a0,88
    8000380c:	40dc                	lw	a5,4(s1)
    8000380e:	8bbd                	andi	a5,a5,15
    80003810:	079a                	slli	a5,a5,0x6
    80003812:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003814:	00059783          	lh	a5,0(a1)
    80003818:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000381c:	00259783          	lh	a5,2(a1)
    80003820:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003824:	00459783          	lh	a5,4(a1)
    80003828:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000382c:	00659783          	lh	a5,6(a1)
    80003830:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003834:	459c                	lw	a5,8(a1)
    80003836:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003838:	03400613          	li	a2,52
    8000383c:	05b1                	addi	a1,a1,12
    8000383e:	05048513          	addi	a0,s1,80
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	4fe080e7          	jalr	1278(ra) # 80000d40 <memmove>
    brelse(bp);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	88e080e7          	jalr	-1906(ra) # 800030da <brelse>
    ip->valid = 1;
    80003854:	4785                	li	a5,1
    80003856:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003858:	04449783          	lh	a5,68(s1)
    8000385c:	fbb5                	bnez	a5,800037d0 <ilock+0x24>
      panic("ilock: no type");
    8000385e:	00005517          	auipc	a0,0x5
    80003862:	d8250513          	addi	a0,a0,-638 # 800085e0 <syscalls+0x188>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	cd8080e7          	jalr	-808(ra) # 8000053e <panic>

000000008000386e <iunlock>:
{
    8000386e:	1101                	addi	sp,sp,-32
    80003870:	ec06                	sd	ra,24(sp)
    80003872:	e822                	sd	s0,16(sp)
    80003874:	e426                	sd	s1,8(sp)
    80003876:	e04a                	sd	s2,0(sp)
    80003878:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000387a:	c905                	beqz	a0,800038aa <iunlock+0x3c>
    8000387c:	84aa                	mv	s1,a0
    8000387e:	01050913          	addi	s2,a0,16
    80003882:	854a                	mv	a0,s2
    80003884:	00001097          	auipc	ra,0x1
    80003888:	c8c080e7          	jalr	-884(ra) # 80004510 <holdingsleep>
    8000388c:	cd19                	beqz	a0,800038aa <iunlock+0x3c>
    8000388e:	449c                	lw	a5,8(s1)
    80003890:	00f05d63          	blez	a5,800038aa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	c36080e7          	jalr	-970(ra) # 800044cc <releasesleep>
}
    8000389e:	60e2                	ld	ra,24(sp)
    800038a0:	6442                	ld	s0,16(sp)
    800038a2:	64a2                	ld	s1,8(sp)
    800038a4:	6902                	ld	s2,0(sp)
    800038a6:	6105                	addi	sp,sp,32
    800038a8:	8082                	ret
    panic("iunlock");
    800038aa:	00005517          	auipc	a0,0x5
    800038ae:	d4650513          	addi	a0,a0,-698 # 800085f0 <syscalls+0x198>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	c8c080e7          	jalr	-884(ra) # 8000053e <panic>

00000000800038ba <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038ba:	7179                	addi	sp,sp,-48
    800038bc:	f406                	sd	ra,40(sp)
    800038be:	f022                	sd	s0,32(sp)
    800038c0:	ec26                	sd	s1,24(sp)
    800038c2:	e84a                	sd	s2,16(sp)
    800038c4:	e44e                	sd	s3,8(sp)
    800038c6:	e052                	sd	s4,0(sp)
    800038c8:	1800                	addi	s0,sp,48
    800038ca:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038cc:	05050493          	addi	s1,a0,80
    800038d0:	08050913          	addi	s2,a0,128
    800038d4:	a021                	j	800038dc <itrunc+0x22>
    800038d6:	0491                	addi	s1,s1,4
    800038d8:	01248d63          	beq	s1,s2,800038f2 <itrunc+0x38>
    if(ip->addrs[i]){
    800038dc:	408c                	lw	a1,0(s1)
    800038de:	dde5                	beqz	a1,800038d6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038e0:	0009a503          	lw	a0,0(s3)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	90c080e7          	jalr	-1780(ra) # 800031f0 <bfree>
      ip->addrs[i] = 0;
    800038ec:	0004a023          	sw	zero,0(s1)
    800038f0:	b7dd                	j	800038d6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038f2:	0809a583          	lw	a1,128(s3)
    800038f6:	e185                	bnez	a1,80003916 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038f8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038fc:	854e                	mv	a0,s3
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	de4080e7          	jalr	-540(ra) # 800036e2 <iupdate>
}
    80003906:	70a2                	ld	ra,40(sp)
    80003908:	7402                	ld	s0,32(sp)
    8000390a:	64e2                	ld	s1,24(sp)
    8000390c:	6942                	ld	s2,16(sp)
    8000390e:	69a2                	ld	s3,8(sp)
    80003910:	6a02                	ld	s4,0(sp)
    80003912:	6145                	addi	sp,sp,48
    80003914:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	fffff097          	auipc	ra,0xfffff
    8000391e:	690080e7          	jalr	1680(ra) # 80002faa <bread>
    80003922:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003924:	05850493          	addi	s1,a0,88
    80003928:	45850913          	addi	s2,a0,1112
    8000392c:	a811                	j	80003940 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000392e:	0009a503          	lw	a0,0(s3)
    80003932:	00000097          	auipc	ra,0x0
    80003936:	8be080e7          	jalr	-1858(ra) # 800031f0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000393a:	0491                	addi	s1,s1,4
    8000393c:	01248563          	beq	s1,s2,80003946 <itrunc+0x8c>
      if(a[j])
    80003940:	408c                	lw	a1,0(s1)
    80003942:	dde5                	beqz	a1,8000393a <itrunc+0x80>
    80003944:	b7ed                	j	8000392e <itrunc+0x74>
    brelse(bp);
    80003946:	8552                	mv	a0,s4
    80003948:	fffff097          	auipc	ra,0xfffff
    8000394c:	792080e7          	jalr	1938(ra) # 800030da <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003950:	0809a583          	lw	a1,128(s3)
    80003954:	0009a503          	lw	a0,0(s3)
    80003958:	00000097          	auipc	ra,0x0
    8000395c:	898080e7          	jalr	-1896(ra) # 800031f0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003960:	0809a023          	sw	zero,128(s3)
    80003964:	bf51                	j	800038f8 <itrunc+0x3e>

0000000080003966 <iput>:
{
    80003966:	1101                	addi	sp,sp,-32
    80003968:	ec06                	sd	ra,24(sp)
    8000396a:	e822                	sd	s0,16(sp)
    8000396c:	e426                	sd	s1,8(sp)
    8000396e:	e04a                	sd	s2,0(sp)
    80003970:	1000                	addi	s0,sp,32
    80003972:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003974:	0001c517          	auipc	a0,0x1c
    80003978:	2e450513          	addi	a0,a0,740 # 8001fc58 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	268080e7          	jalr	616(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003984:	4498                	lw	a4,8(s1)
    80003986:	4785                	li	a5,1
    80003988:	02f70363          	beq	a4,a5,800039ae <iput+0x48>
  ip->ref--;
    8000398c:	449c                	lw	a5,8(s1)
    8000398e:	37fd                	addiw	a5,a5,-1
    80003990:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003992:	0001c517          	auipc	a0,0x1c
    80003996:	2c650513          	addi	a0,a0,710 # 8001fc58 <itable>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	2fe080e7          	jalr	766(ra) # 80000c98 <release>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ae:	40bc                	lw	a5,64(s1)
    800039b0:	dff1                	beqz	a5,8000398c <iput+0x26>
    800039b2:	04a49783          	lh	a5,74(s1)
    800039b6:	fbf9                	bnez	a5,8000398c <iput+0x26>
    acquiresleep(&ip->lock);
    800039b8:	01048913          	addi	s2,s1,16
    800039bc:	854a                	mv	a0,s2
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	ab8080e7          	jalr	-1352(ra) # 80004476 <acquiresleep>
    release(&itable.lock);
    800039c6:	0001c517          	auipc	a0,0x1c
    800039ca:	29250513          	addi	a0,a0,658 # 8001fc58 <itable>
    800039ce:	ffffd097          	auipc	ra,0xffffd
    800039d2:	2ca080e7          	jalr	714(ra) # 80000c98 <release>
    itrunc(ip);
    800039d6:	8526                	mv	a0,s1
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	ee2080e7          	jalr	-286(ra) # 800038ba <itrunc>
    ip->type = 0;
    800039e0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e4:	8526                	mv	a0,s1
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	cfc080e7          	jalr	-772(ra) # 800036e2 <iupdate>
    ip->valid = 0;
    800039ee:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	ad8080e7          	jalr	-1320(ra) # 800044cc <releasesleep>
    acquire(&itable.lock);
    800039fc:	0001c517          	auipc	a0,0x1c
    80003a00:	25c50513          	addi	a0,a0,604 # 8001fc58 <itable>
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	1e0080e7          	jalr	480(ra) # 80000be4 <acquire>
    80003a0c:	b741                	j	8000398c <iput+0x26>

0000000080003a0e <iunlockput>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	1000                	addi	s0,sp,32
    80003a18:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	e54080e7          	jalr	-428(ra) # 8000386e <iunlock>
  iput(ip);
    80003a22:	8526                	mv	a0,s1
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	f42080e7          	jalr	-190(ra) # 80003966 <iput>
}
    80003a2c:	60e2                	ld	ra,24(sp)
    80003a2e:	6442                	ld	s0,16(sp)
    80003a30:	64a2                	ld	s1,8(sp)
    80003a32:	6105                	addi	sp,sp,32
    80003a34:	8082                	ret

0000000080003a36 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a36:	1141                	addi	sp,sp,-16
    80003a38:	e422                	sd	s0,8(sp)
    80003a3a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a3c:	411c                	lw	a5,0(a0)
    80003a3e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a40:	415c                	lw	a5,4(a0)
    80003a42:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a44:	04451783          	lh	a5,68(a0)
    80003a48:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a4c:	04a51783          	lh	a5,74(a0)
    80003a50:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a54:	04c56783          	lwu	a5,76(a0)
    80003a58:	e99c                	sd	a5,16(a1)
}
    80003a5a:	6422                	ld	s0,8(sp)
    80003a5c:	0141                	addi	sp,sp,16
    80003a5e:	8082                	ret

0000000080003a60 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a60:	457c                	lw	a5,76(a0)
    80003a62:	0ed7e963          	bltu	a5,a3,80003b54 <readi+0xf4>
{
    80003a66:	7159                	addi	sp,sp,-112
    80003a68:	f486                	sd	ra,104(sp)
    80003a6a:	f0a2                	sd	s0,96(sp)
    80003a6c:	eca6                	sd	s1,88(sp)
    80003a6e:	e8ca                	sd	s2,80(sp)
    80003a70:	e4ce                	sd	s3,72(sp)
    80003a72:	e0d2                	sd	s4,64(sp)
    80003a74:	fc56                	sd	s5,56(sp)
    80003a76:	f85a                	sd	s6,48(sp)
    80003a78:	f45e                	sd	s7,40(sp)
    80003a7a:	f062                	sd	s8,32(sp)
    80003a7c:	ec66                	sd	s9,24(sp)
    80003a7e:	e86a                	sd	s10,16(sp)
    80003a80:	e46e                	sd	s11,8(sp)
    80003a82:	1880                	addi	s0,sp,112
    80003a84:	8baa                	mv	s7,a0
    80003a86:	8c2e                	mv	s8,a1
    80003a88:	8ab2                	mv	s5,a2
    80003a8a:	84b6                	mv	s1,a3
    80003a8c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a8e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a90:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a92:	0ad76063          	bltu	a4,a3,80003b32 <readi+0xd2>
  if(off + n > ip->size)
    80003a96:	00e7f463          	bgeu	a5,a4,80003a9e <readi+0x3e>
    n = ip->size - off;
    80003a9a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a9e:	0a0b0963          	beqz	s6,80003b50 <readi+0xf0>
    80003aa2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aa8:	5cfd                	li	s9,-1
    80003aaa:	a82d                	j	80003ae4 <readi+0x84>
    80003aac:	020a1d93          	slli	s11,s4,0x20
    80003ab0:	020ddd93          	srli	s11,s11,0x20
    80003ab4:	05890613          	addi	a2,s2,88
    80003ab8:	86ee                	mv	a3,s11
    80003aba:	963a                	add	a2,a2,a4
    80003abc:	85d6                	mv	a1,s5
    80003abe:	8562                	mv	a0,s8
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	b2e080e7          	jalr	-1234(ra) # 800025ee <either_copyout>
    80003ac8:	05950d63          	beq	a0,s9,80003b22 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003acc:	854a                	mv	a0,s2
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	60c080e7          	jalr	1548(ra) # 800030da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad6:	013a09bb          	addw	s3,s4,s3
    80003ada:	009a04bb          	addw	s1,s4,s1
    80003ade:	9aee                	add	s5,s5,s11
    80003ae0:	0569f763          	bgeu	s3,s6,80003b2e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ae4:	000ba903          	lw	s2,0(s7)
    80003ae8:	00a4d59b          	srliw	a1,s1,0xa
    80003aec:	855e                	mv	a0,s7
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	8b0080e7          	jalr	-1872(ra) # 8000339e <bmap>
    80003af6:	0005059b          	sext.w	a1,a0
    80003afa:	854a                	mv	a0,s2
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	4ae080e7          	jalr	1198(ra) # 80002faa <bread>
    80003b04:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b06:	3ff4f713          	andi	a4,s1,1023
    80003b0a:	40ed07bb          	subw	a5,s10,a4
    80003b0e:	413b06bb          	subw	a3,s6,s3
    80003b12:	8a3e                	mv	s4,a5
    80003b14:	2781                	sext.w	a5,a5
    80003b16:	0006861b          	sext.w	a2,a3
    80003b1a:	f8f679e3          	bgeu	a2,a5,80003aac <readi+0x4c>
    80003b1e:	8a36                	mv	s4,a3
    80003b20:	b771                	j	80003aac <readi+0x4c>
      brelse(bp);
    80003b22:	854a                	mv	a0,s2
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	5b6080e7          	jalr	1462(ra) # 800030da <brelse>
      tot = -1;
    80003b2c:	59fd                	li	s3,-1
  }
  return tot;
    80003b2e:	0009851b          	sext.w	a0,s3
}
    80003b32:	70a6                	ld	ra,104(sp)
    80003b34:	7406                	ld	s0,96(sp)
    80003b36:	64e6                	ld	s1,88(sp)
    80003b38:	6946                	ld	s2,80(sp)
    80003b3a:	69a6                	ld	s3,72(sp)
    80003b3c:	6a06                	ld	s4,64(sp)
    80003b3e:	7ae2                	ld	s5,56(sp)
    80003b40:	7b42                	ld	s6,48(sp)
    80003b42:	7ba2                	ld	s7,40(sp)
    80003b44:	7c02                	ld	s8,32(sp)
    80003b46:	6ce2                	ld	s9,24(sp)
    80003b48:	6d42                	ld	s10,16(sp)
    80003b4a:	6da2                	ld	s11,8(sp)
    80003b4c:	6165                	addi	sp,sp,112
    80003b4e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b50:	89da                	mv	s3,s6
    80003b52:	bff1                	j	80003b2e <readi+0xce>
    return 0;
    80003b54:	4501                	li	a0,0
}
    80003b56:	8082                	ret

0000000080003b58 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b58:	457c                	lw	a5,76(a0)
    80003b5a:	10d7e863          	bltu	a5,a3,80003c6a <writei+0x112>
{
    80003b5e:	7159                	addi	sp,sp,-112
    80003b60:	f486                	sd	ra,104(sp)
    80003b62:	f0a2                	sd	s0,96(sp)
    80003b64:	eca6                	sd	s1,88(sp)
    80003b66:	e8ca                	sd	s2,80(sp)
    80003b68:	e4ce                	sd	s3,72(sp)
    80003b6a:	e0d2                	sd	s4,64(sp)
    80003b6c:	fc56                	sd	s5,56(sp)
    80003b6e:	f85a                	sd	s6,48(sp)
    80003b70:	f45e                	sd	s7,40(sp)
    80003b72:	f062                	sd	s8,32(sp)
    80003b74:	ec66                	sd	s9,24(sp)
    80003b76:	e86a                	sd	s10,16(sp)
    80003b78:	e46e                	sd	s11,8(sp)
    80003b7a:	1880                	addi	s0,sp,112
    80003b7c:	8b2a                	mv	s6,a0
    80003b7e:	8c2e                	mv	s8,a1
    80003b80:	8ab2                	mv	s5,a2
    80003b82:	8936                	mv	s2,a3
    80003b84:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b86:	00e687bb          	addw	a5,a3,a4
    80003b8a:	0ed7e263          	bltu	a5,a3,80003c6e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b8e:	00043737          	lui	a4,0x43
    80003b92:	0ef76063          	bltu	a4,a5,80003c72 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b96:	0c0b8863          	beqz	s7,80003c66 <writei+0x10e>
    80003b9a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ba0:	5cfd                	li	s9,-1
    80003ba2:	a091                	j	80003be6 <writei+0x8e>
    80003ba4:	02099d93          	slli	s11,s3,0x20
    80003ba8:	020ddd93          	srli	s11,s11,0x20
    80003bac:	05848513          	addi	a0,s1,88
    80003bb0:	86ee                	mv	a3,s11
    80003bb2:	8656                	mv	a2,s5
    80003bb4:	85e2                	mv	a1,s8
    80003bb6:	953a                	add	a0,a0,a4
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	a8c080e7          	jalr	-1396(ra) # 80002644 <either_copyin>
    80003bc0:	07950263          	beq	a0,s9,80003c24 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	790080e7          	jalr	1936(ra) # 80004356 <log_write>
    brelse(bp);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	50a080e7          	jalr	1290(ra) # 800030da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd8:	01498a3b          	addw	s4,s3,s4
    80003bdc:	0129893b          	addw	s2,s3,s2
    80003be0:	9aee                	add	s5,s5,s11
    80003be2:	057a7663          	bgeu	s4,s7,80003c2e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003be6:	000b2483          	lw	s1,0(s6)
    80003bea:	00a9559b          	srliw	a1,s2,0xa
    80003bee:	855a                	mv	a0,s6
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	7ae080e7          	jalr	1966(ra) # 8000339e <bmap>
    80003bf8:	0005059b          	sext.w	a1,a0
    80003bfc:	8526                	mv	a0,s1
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	3ac080e7          	jalr	940(ra) # 80002faa <bread>
    80003c06:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c08:	3ff97713          	andi	a4,s2,1023
    80003c0c:	40ed07bb          	subw	a5,s10,a4
    80003c10:	414b86bb          	subw	a3,s7,s4
    80003c14:	89be                	mv	s3,a5
    80003c16:	2781                	sext.w	a5,a5
    80003c18:	0006861b          	sext.w	a2,a3
    80003c1c:	f8f674e3          	bgeu	a2,a5,80003ba4 <writei+0x4c>
    80003c20:	89b6                	mv	s3,a3
    80003c22:	b749                	j	80003ba4 <writei+0x4c>
      brelse(bp);
    80003c24:	8526                	mv	a0,s1
    80003c26:	fffff097          	auipc	ra,0xfffff
    80003c2a:	4b4080e7          	jalr	1204(ra) # 800030da <brelse>
  }

  if(off > ip->size)
    80003c2e:	04cb2783          	lw	a5,76(s6)
    80003c32:	0127f463          	bgeu	a5,s2,80003c3a <writei+0xe2>
    ip->size = off;
    80003c36:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c3a:	855a                	mv	a0,s6
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	aa6080e7          	jalr	-1370(ra) # 800036e2 <iupdate>

  return tot;
    80003c44:	000a051b          	sext.w	a0,s4
}
    80003c48:	70a6                	ld	ra,104(sp)
    80003c4a:	7406                	ld	s0,96(sp)
    80003c4c:	64e6                	ld	s1,88(sp)
    80003c4e:	6946                	ld	s2,80(sp)
    80003c50:	69a6                	ld	s3,72(sp)
    80003c52:	6a06                	ld	s4,64(sp)
    80003c54:	7ae2                	ld	s5,56(sp)
    80003c56:	7b42                	ld	s6,48(sp)
    80003c58:	7ba2                	ld	s7,40(sp)
    80003c5a:	7c02                	ld	s8,32(sp)
    80003c5c:	6ce2                	ld	s9,24(sp)
    80003c5e:	6d42                	ld	s10,16(sp)
    80003c60:	6da2                	ld	s11,8(sp)
    80003c62:	6165                	addi	sp,sp,112
    80003c64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c66:	8a5e                	mv	s4,s7
    80003c68:	bfc9                	j	80003c3a <writei+0xe2>
    return -1;
    80003c6a:	557d                	li	a0,-1
}
    80003c6c:	8082                	ret
    return -1;
    80003c6e:	557d                	li	a0,-1
    80003c70:	bfe1                	j	80003c48 <writei+0xf0>
    return -1;
    80003c72:	557d                	li	a0,-1
    80003c74:	bfd1                	j	80003c48 <writei+0xf0>

0000000080003c76 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c76:	1141                	addi	sp,sp,-16
    80003c78:	e406                	sd	ra,8(sp)
    80003c7a:	e022                	sd	s0,0(sp)
    80003c7c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c7e:	4639                	li	a2,14
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	138080e7          	jalr	312(ra) # 80000db8 <strncmp>
}
    80003c88:	60a2                	ld	ra,8(sp)
    80003c8a:	6402                	ld	s0,0(sp)
    80003c8c:	0141                	addi	sp,sp,16
    80003c8e:	8082                	ret

0000000080003c90 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c90:	7139                	addi	sp,sp,-64
    80003c92:	fc06                	sd	ra,56(sp)
    80003c94:	f822                	sd	s0,48(sp)
    80003c96:	f426                	sd	s1,40(sp)
    80003c98:	f04a                	sd	s2,32(sp)
    80003c9a:	ec4e                	sd	s3,24(sp)
    80003c9c:	e852                	sd	s4,16(sp)
    80003c9e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca0:	04451703          	lh	a4,68(a0)
    80003ca4:	4785                	li	a5,1
    80003ca6:	00f71a63          	bne	a4,a5,80003cba <dirlookup+0x2a>
    80003caa:	892a                	mv	s2,a0
    80003cac:	89ae                	mv	s3,a1
    80003cae:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb0:	457c                	lw	a5,76(a0)
    80003cb2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb6:	e79d                	bnez	a5,80003ce4 <dirlookup+0x54>
    80003cb8:	a8a5                	j	80003d30 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cba:	00005517          	auipc	a0,0x5
    80003cbe:	93e50513          	addi	a0,a0,-1730 # 800085f8 <syscalls+0x1a0>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	87c080e7          	jalr	-1924(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cca:	00005517          	auipc	a0,0x5
    80003cce:	94650513          	addi	a0,a0,-1722 # 80008610 <syscalls+0x1b8>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	86c080e7          	jalr	-1940(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cda:	24c1                	addiw	s1,s1,16
    80003cdc:	04c92783          	lw	a5,76(s2)
    80003ce0:	04f4f763          	bgeu	s1,a5,80003d2e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce4:	4741                	li	a4,16
    80003ce6:	86a6                	mv	a3,s1
    80003ce8:	fc040613          	addi	a2,s0,-64
    80003cec:	4581                	li	a1,0
    80003cee:	854a                	mv	a0,s2
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	d70080e7          	jalr	-656(ra) # 80003a60 <readi>
    80003cf8:	47c1                	li	a5,16
    80003cfa:	fcf518e3          	bne	a0,a5,80003cca <dirlookup+0x3a>
    if(de.inum == 0)
    80003cfe:	fc045783          	lhu	a5,-64(s0)
    80003d02:	dfe1                	beqz	a5,80003cda <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d04:	fc240593          	addi	a1,s0,-62
    80003d08:	854e                	mv	a0,s3
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	f6c080e7          	jalr	-148(ra) # 80003c76 <namecmp>
    80003d12:	f561                	bnez	a0,80003cda <dirlookup+0x4a>
      if(poff)
    80003d14:	000a0463          	beqz	s4,80003d1c <dirlookup+0x8c>
        *poff = off;
    80003d18:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d1c:	fc045583          	lhu	a1,-64(s0)
    80003d20:	00092503          	lw	a0,0(s2)
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	754080e7          	jalr	1876(ra) # 80003478 <iget>
    80003d2c:	a011                	j	80003d30 <dirlookup+0xa0>
  return 0;
    80003d2e:	4501                	li	a0,0
}
    80003d30:	70e2                	ld	ra,56(sp)
    80003d32:	7442                	ld	s0,48(sp)
    80003d34:	74a2                	ld	s1,40(sp)
    80003d36:	7902                	ld	s2,32(sp)
    80003d38:	69e2                	ld	s3,24(sp)
    80003d3a:	6a42                	ld	s4,16(sp)
    80003d3c:	6121                	addi	sp,sp,64
    80003d3e:	8082                	ret

0000000080003d40 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d40:	711d                	addi	sp,sp,-96
    80003d42:	ec86                	sd	ra,88(sp)
    80003d44:	e8a2                	sd	s0,80(sp)
    80003d46:	e4a6                	sd	s1,72(sp)
    80003d48:	e0ca                	sd	s2,64(sp)
    80003d4a:	fc4e                	sd	s3,56(sp)
    80003d4c:	f852                	sd	s4,48(sp)
    80003d4e:	f456                	sd	s5,40(sp)
    80003d50:	f05a                	sd	s6,32(sp)
    80003d52:	ec5e                	sd	s7,24(sp)
    80003d54:	e862                	sd	s8,16(sp)
    80003d56:	e466                	sd	s9,8(sp)
    80003d58:	1080                	addi	s0,sp,96
    80003d5a:	84aa                	mv	s1,a0
    80003d5c:	8b2e                	mv	s6,a1
    80003d5e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d60:	00054703          	lbu	a4,0(a0)
    80003d64:	02f00793          	li	a5,47
    80003d68:	02f70363          	beq	a4,a5,80003d8e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d6c:	ffffe097          	auipc	ra,0xffffe
    80003d70:	de4080e7          	jalr	-540(ra) # 80001b50 <myproc>
    80003d74:	15053503          	ld	a0,336(a0)
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	9f6080e7          	jalr	-1546(ra) # 8000376e <idup>
    80003d80:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d82:	02f00913          	li	s2,47
  len = path - s;
    80003d86:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d88:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d8a:	4c05                	li	s8,1
    80003d8c:	a865                	j	80003e44 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d8e:	4585                	li	a1,1
    80003d90:	4505                	li	a0,1
    80003d92:	fffff097          	auipc	ra,0xfffff
    80003d96:	6e6080e7          	jalr	1766(ra) # 80003478 <iget>
    80003d9a:	89aa                	mv	s3,a0
    80003d9c:	b7dd                	j	80003d82 <namex+0x42>
      iunlockput(ip);
    80003d9e:	854e                	mv	a0,s3
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	c6e080e7          	jalr	-914(ra) # 80003a0e <iunlockput>
      return 0;
    80003da8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003daa:	854e                	mv	a0,s3
    80003dac:	60e6                	ld	ra,88(sp)
    80003dae:	6446                	ld	s0,80(sp)
    80003db0:	64a6                	ld	s1,72(sp)
    80003db2:	6906                	ld	s2,64(sp)
    80003db4:	79e2                	ld	s3,56(sp)
    80003db6:	7a42                	ld	s4,48(sp)
    80003db8:	7aa2                	ld	s5,40(sp)
    80003dba:	7b02                	ld	s6,32(sp)
    80003dbc:	6be2                	ld	s7,24(sp)
    80003dbe:	6c42                	ld	s8,16(sp)
    80003dc0:	6ca2                	ld	s9,8(sp)
    80003dc2:	6125                	addi	sp,sp,96
    80003dc4:	8082                	ret
      iunlock(ip);
    80003dc6:	854e                	mv	a0,s3
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	aa6080e7          	jalr	-1370(ra) # 8000386e <iunlock>
      return ip;
    80003dd0:	bfe9                	j	80003daa <namex+0x6a>
      iunlockput(ip);
    80003dd2:	854e                	mv	a0,s3
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	c3a080e7          	jalr	-966(ra) # 80003a0e <iunlockput>
      return 0;
    80003ddc:	89d2                	mv	s3,s4
    80003dde:	b7f1                	j	80003daa <namex+0x6a>
  len = path - s;
    80003de0:	40b48633          	sub	a2,s1,a1
    80003de4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003de8:	094cd463          	bge	s9,s4,80003e70 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dec:	4639                	li	a2,14
    80003dee:	8556                	mv	a0,s5
    80003df0:	ffffd097          	auipc	ra,0xffffd
    80003df4:	f50080e7          	jalr	-176(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003df8:	0004c783          	lbu	a5,0(s1)
    80003dfc:	01279763          	bne	a5,s2,80003e0a <namex+0xca>
    path++;
    80003e00:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	ff278de3          	beq	a5,s2,80003e00 <namex+0xc0>
    ilock(ip);
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	9a0080e7          	jalr	-1632(ra) # 800037ac <ilock>
    if(ip->type != T_DIR){
    80003e14:	04499783          	lh	a5,68(s3)
    80003e18:	f98793e3          	bne	a5,s8,80003d9e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e1c:	000b0563          	beqz	s6,80003e26 <namex+0xe6>
    80003e20:	0004c783          	lbu	a5,0(s1)
    80003e24:	d3cd                	beqz	a5,80003dc6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e26:	865e                	mv	a2,s7
    80003e28:	85d6                	mv	a1,s5
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	e64080e7          	jalr	-412(ra) # 80003c90 <dirlookup>
    80003e34:	8a2a                	mv	s4,a0
    80003e36:	dd51                	beqz	a0,80003dd2 <namex+0x92>
    iunlockput(ip);
    80003e38:	854e                	mv	a0,s3
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	bd4080e7          	jalr	-1068(ra) # 80003a0e <iunlockput>
    ip = next;
    80003e42:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	05279763          	bne	a5,s2,80003e96 <namex+0x156>
    path++;
    80003e4c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	ff278de3          	beq	a5,s2,80003e4c <namex+0x10c>
  if(*path == 0)
    80003e56:	c79d                	beqz	a5,80003e84 <namex+0x144>
    path++;
    80003e58:	85a6                	mv	a1,s1
  len = path - s;
    80003e5a:	8a5e                	mv	s4,s7
    80003e5c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e5e:	01278963          	beq	a5,s2,80003e70 <namex+0x130>
    80003e62:	dfbd                	beqz	a5,80003de0 <namex+0xa0>
    path++;
    80003e64:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e66:	0004c783          	lbu	a5,0(s1)
    80003e6a:	ff279ce3          	bne	a5,s2,80003e62 <namex+0x122>
    80003e6e:	bf8d                	j	80003de0 <namex+0xa0>
    memmove(name, s, len);
    80003e70:	2601                	sext.w	a2,a2
    80003e72:	8556                	mv	a0,s5
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	ecc080e7          	jalr	-308(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e7c:	9a56                	add	s4,s4,s5
    80003e7e:	000a0023          	sb	zero,0(s4)
    80003e82:	bf9d                	j	80003df8 <namex+0xb8>
  if(nameiparent){
    80003e84:	f20b03e3          	beqz	s6,80003daa <namex+0x6a>
    iput(ip);
    80003e88:	854e                	mv	a0,s3
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	adc080e7          	jalr	-1316(ra) # 80003966 <iput>
    return 0;
    80003e92:	4981                	li	s3,0
    80003e94:	bf19                	j	80003daa <namex+0x6a>
  if(*path == 0)
    80003e96:	d7fd                	beqz	a5,80003e84 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	85a6                	mv	a1,s1
    80003e9e:	b7d1                	j	80003e62 <namex+0x122>

0000000080003ea0 <dirlink>:
{
    80003ea0:	7139                	addi	sp,sp,-64
    80003ea2:	fc06                	sd	ra,56(sp)
    80003ea4:	f822                	sd	s0,48(sp)
    80003ea6:	f426                	sd	s1,40(sp)
    80003ea8:	f04a                	sd	s2,32(sp)
    80003eaa:	ec4e                	sd	s3,24(sp)
    80003eac:	e852                	sd	s4,16(sp)
    80003eae:	0080                	addi	s0,sp,64
    80003eb0:	892a                	mv	s2,a0
    80003eb2:	8a2e                	mv	s4,a1
    80003eb4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb6:	4601                	li	a2,0
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	dd8080e7          	jalr	-552(ra) # 80003c90 <dirlookup>
    80003ec0:	e93d                	bnez	a0,80003f36 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec2:	04c92483          	lw	s1,76(s2)
    80003ec6:	c49d                	beqz	s1,80003ef4 <dirlink+0x54>
    80003ec8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eca:	4741                	li	a4,16
    80003ecc:	86a6                	mv	a3,s1
    80003ece:	fc040613          	addi	a2,s0,-64
    80003ed2:	4581                	li	a1,0
    80003ed4:	854a                	mv	a0,s2
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	b8a080e7          	jalr	-1142(ra) # 80003a60 <readi>
    80003ede:	47c1                	li	a5,16
    80003ee0:	06f51163          	bne	a0,a5,80003f42 <dirlink+0xa2>
    if(de.inum == 0)
    80003ee4:	fc045783          	lhu	a5,-64(s0)
    80003ee8:	c791                	beqz	a5,80003ef4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eea:	24c1                	addiw	s1,s1,16
    80003eec:	04c92783          	lw	a5,76(s2)
    80003ef0:	fcf4ede3          	bltu	s1,a5,80003eca <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef4:	4639                	li	a2,14
    80003ef6:	85d2                	mv	a1,s4
    80003ef8:	fc240513          	addi	a0,s0,-62
    80003efc:	ffffd097          	auipc	ra,0xffffd
    80003f00:	ef8080e7          	jalr	-264(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f04:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f08:	4741                	li	a4,16
    80003f0a:	86a6                	mv	a3,s1
    80003f0c:	fc040613          	addi	a2,s0,-64
    80003f10:	4581                	li	a1,0
    80003f12:	854a                	mv	a0,s2
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	c44080e7          	jalr	-956(ra) # 80003b58 <writei>
    80003f1c:	872a                	mv	a4,a0
    80003f1e:	47c1                	li	a5,16
  return 0;
    80003f20:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f22:	02f71863          	bne	a4,a5,80003f52 <dirlink+0xb2>
}
    80003f26:	70e2                	ld	ra,56(sp)
    80003f28:	7442                	ld	s0,48(sp)
    80003f2a:	74a2                	ld	s1,40(sp)
    80003f2c:	7902                	ld	s2,32(sp)
    80003f2e:	69e2                	ld	s3,24(sp)
    80003f30:	6a42                	ld	s4,16(sp)
    80003f32:	6121                	addi	sp,sp,64
    80003f34:	8082                	ret
    iput(ip);
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	a30080e7          	jalr	-1488(ra) # 80003966 <iput>
    return -1;
    80003f3e:	557d                	li	a0,-1
    80003f40:	b7dd                	j	80003f26 <dirlink+0x86>
      panic("dirlink read");
    80003f42:	00004517          	auipc	a0,0x4
    80003f46:	6de50513          	addi	a0,a0,1758 # 80008620 <syscalls+0x1c8>
    80003f4a:	ffffc097          	auipc	ra,0xffffc
    80003f4e:	5f4080e7          	jalr	1524(ra) # 8000053e <panic>
    panic("dirlink");
    80003f52:	00004517          	auipc	a0,0x4
    80003f56:	7de50513          	addi	a0,a0,2014 # 80008730 <syscalls+0x2d8>
    80003f5a:	ffffc097          	auipc	ra,0xffffc
    80003f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>

0000000080003f62 <namei>:

struct inode*
namei(char *path)
{
    80003f62:	1101                	addi	sp,sp,-32
    80003f64:	ec06                	sd	ra,24(sp)
    80003f66:	e822                	sd	s0,16(sp)
    80003f68:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f6a:	fe040613          	addi	a2,s0,-32
    80003f6e:	4581                	li	a1,0
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	dd0080e7          	jalr	-560(ra) # 80003d40 <namex>
}
    80003f78:	60e2                	ld	ra,24(sp)
    80003f7a:	6442                	ld	s0,16(sp)
    80003f7c:	6105                	addi	sp,sp,32
    80003f7e:	8082                	ret

0000000080003f80 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f80:	1141                	addi	sp,sp,-16
    80003f82:	e406                	sd	ra,8(sp)
    80003f84:	e022                	sd	s0,0(sp)
    80003f86:	0800                	addi	s0,sp,16
    80003f88:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f8a:	4585                	li	a1,1
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	db4080e7          	jalr	-588(ra) # 80003d40 <namex>
}
    80003f94:	60a2                	ld	ra,8(sp)
    80003f96:	6402                	ld	s0,0(sp)
    80003f98:	0141                	addi	sp,sp,16
    80003f9a:	8082                	ret

0000000080003f9c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f9c:	1101                	addi	sp,sp,-32
    80003f9e:	ec06                	sd	ra,24(sp)
    80003fa0:	e822                	sd	s0,16(sp)
    80003fa2:	e426                	sd	s1,8(sp)
    80003fa4:	e04a                	sd	s2,0(sp)
    80003fa6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fa8:	0001d917          	auipc	s2,0x1d
    80003fac:	75890913          	addi	s2,s2,1880 # 80021700 <log>
    80003fb0:	01892583          	lw	a1,24(s2)
    80003fb4:	02892503          	lw	a0,40(s2)
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	ff2080e7          	jalr	-14(ra) # 80002faa <bread>
    80003fc0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fc2:	02c92683          	lw	a3,44(s2)
    80003fc6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fc8:	02d05763          	blez	a3,80003ff6 <write_head+0x5a>
    80003fcc:	0001d797          	auipc	a5,0x1d
    80003fd0:	76478793          	addi	a5,a5,1892 # 80021730 <log+0x30>
    80003fd4:	05c50713          	addi	a4,a0,92
    80003fd8:	36fd                	addiw	a3,a3,-1
    80003fda:	1682                	slli	a3,a3,0x20
    80003fdc:	9281                	srli	a3,a3,0x20
    80003fde:	068a                	slli	a3,a3,0x2
    80003fe0:	0001d617          	auipc	a2,0x1d
    80003fe4:	75460613          	addi	a2,a2,1876 # 80021734 <log+0x34>
    80003fe8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fea:	4390                	lw	a2,0(a5)
    80003fec:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fee:	0791                	addi	a5,a5,4
    80003ff0:	0711                	addi	a4,a4,4
    80003ff2:	fed79ce3          	bne	a5,a3,80003fea <write_head+0x4e>
  }
  bwrite(buf);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	0a4080e7          	jalr	164(ra) # 8000309c <bwrite>
  brelse(buf);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	0d8080e7          	jalr	216(ra) # 800030da <brelse>
}
    8000400a:	60e2                	ld	ra,24(sp)
    8000400c:	6442                	ld	s0,16(sp)
    8000400e:	64a2                	ld	s1,8(sp)
    80004010:	6902                	ld	s2,0(sp)
    80004012:	6105                	addi	sp,sp,32
    80004014:	8082                	ret

0000000080004016 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004016:	0001d797          	auipc	a5,0x1d
    8000401a:	7167a783          	lw	a5,1814(a5) # 8002172c <log+0x2c>
    8000401e:	0af05d63          	blez	a5,800040d8 <install_trans+0xc2>
{
    80004022:	7139                	addi	sp,sp,-64
    80004024:	fc06                	sd	ra,56(sp)
    80004026:	f822                	sd	s0,48(sp)
    80004028:	f426                	sd	s1,40(sp)
    8000402a:	f04a                	sd	s2,32(sp)
    8000402c:	ec4e                	sd	s3,24(sp)
    8000402e:	e852                	sd	s4,16(sp)
    80004030:	e456                	sd	s5,8(sp)
    80004032:	e05a                	sd	s6,0(sp)
    80004034:	0080                	addi	s0,sp,64
    80004036:	8b2a                	mv	s6,a0
    80004038:	0001da97          	auipc	s5,0x1d
    8000403c:	6f8a8a93          	addi	s5,s5,1784 # 80021730 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004040:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004042:	0001d997          	auipc	s3,0x1d
    80004046:	6be98993          	addi	s3,s3,1726 # 80021700 <log>
    8000404a:	a035                	j	80004076 <install_trans+0x60>
      bunpin(dbuf);
    8000404c:	8526                	mv	a0,s1
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	166080e7          	jalr	358(ra) # 800031b4 <bunpin>
    brelse(lbuf);
    80004056:	854a                	mv	a0,s2
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	082080e7          	jalr	130(ra) # 800030da <brelse>
    brelse(dbuf);
    80004060:	8526                	mv	a0,s1
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	078080e7          	jalr	120(ra) # 800030da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000406a:	2a05                	addiw	s4,s4,1
    8000406c:	0a91                	addi	s5,s5,4
    8000406e:	02c9a783          	lw	a5,44(s3)
    80004072:	04fa5963          	bge	s4,a5,800040c4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004076:	0189a583          	lw	a1,24(s3)
    8000407a:	014585bb          	addw	a1,a1,s4
    8000407e:	2585                	addiw	a1,a1,1
    80004080:	0289a503          	lw	a0,40(s3)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	f26080e7          	jalr	-218(ra) # 80002faa <bread>
    8000408c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000408e:	000aa583          	lw	a1,0(s5)
    80004092:	0289a503          	lw	a0,40(s3)
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	f14080e7          	jalr	-236(ra) # 80002faa <bread>
    8000409e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040a0:	40000613          	li	a2,1024
    800040a4:	05890593          	addi	a1,s2,88
    800040a8:	05850513          	addi	a0,a0,88
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	c94080e7          	jalr	-876(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040b4:	8526                	mv	a0,s1
    800040b6:	fffff097          	auipc	ra,0xfffff
    800040ba:	fe6080e7          	jalr	-26(ra) # 8000309c <bwrite>
    if(recovering == 0)
    800040be:	f80b1ce3          	bnez	s6,80004056 <install_trans+0x40>
    800040c2:	b769                	j	8000404c <install_trans+0x36>
}
    800040c4:	70e2                	ld	ra,56(sp)
    800040c6:	7442                	ld	s0,48(sp)
    800040c8:	74a2                	ld	s1,40(sp)
    800040ca:	7902                	ld	s2,32(sp)
    800040cc:	69e2                	ld	s3,24(sp)
    800040ce:	6a42                	ld	s4,16(sp)
    800040d0:	6aa2                	ld	s5,8(sp)
    800040d2:	6b02                	ld	s6,0(sp)
    800040d4:	6121                	addi	sp,sp,64
    800040d6:	8082                	ret
    800040d8:	8082                	ret

00000000800040da <initlog>:
{
    800040da:	7179                	addi	sp,sp,-48
    800040dc:	f406                	sd	ra,40(sp)
    800040de:	f022                	sd	s0,32(sp)
    800040e0:	ec26                	sd	s1,24(sp)
    800040e2:	e84a                	sd	s2,16(sp)
    800040e4:	e44e                	sd	s3,8(sp)
    800040e6:	1800                	addi	s0,sp,48
    800040e8:	892a                	mv	s2,a0
    800040ea:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ec:	0001d497          	auipc	s1,0x1d
    800040f0:	61448493          	addi	s1,s1,1556 # 80021700 <log>
    800040f4:	00004597          	auipc	a1,0x4
    800040f8:	53c58593          	addi	a1,a1,1340 # 80008630 <syscalls+0x1d8>
    800040fc:	8526                	mv	a0,s1
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	a56080e7          	jalr	-1450(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004106:	0149a583          	lw	a1,20(s3)
    8000410a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000410c:	0109a783          	lw	a5,16(s3)
    80004110:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004112:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004116:	854a                	mv	a0,s2
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	e92080e7          	jalr	-366(ra) # 80002faa <bread>
  log.lh.n = lh->n;
    80004120:	4d3c                	lw	a5,88(a0)
    80004122:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004124:	02f05563          	blez	a5,8000414e <initlog+0x74>
    80004128:	05c50713          	addi	a4,a0,92
    8000412c:	0001d697          	auipc	a3,0x1d
    80004130:	60468693          	addi	a3,a3,1540 # 80021730 <log+0x30>
    80004134:	37fd                	addiw	a5,a5,-1
    80004136:	1782                	slli	a5,a5,0x20
    80004138:	9381                	srli	a5,a5,0x20
    8000413a:	078a                	slli	a5,a5,0x2
    8000413c:	06050613          	addi	a2,a0,96
    80004140:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004142:	4310                	lw	a2,0(a4)
    80004144:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004146:	0711                	addi	a4,a4,4
    80004148:	0691                	addi	a3,a3,4
    8000414a:	fef71ce3          	bne	a4,a5,80004142 <initlog+0x68>
  brelse(buf);
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	f8c080e7          	jalr	-116(ra) # 800030da <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004156:	4505                	li	a0,1
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	ebe080e7          	jalr	-322(ra) # 80004016 <install_trans>
  log.lh.n = 0;
    80004160:	0001d797          	auipc	a5,0x1d
    80004164:	5c07a623          	sw	zero,1484(a5) # 8002172c <log+0x2c>
  write_head(); // clear the log
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	e34080e7          	jalr	-460(ra) # 80003f9c <write_head>
}
    80004170:	70a2                	ld	ra,40(sp)
    80004172:	7402                	ld	s0,32(sp)
    80004174:	64e2                	ld	s1,24(sp)
    80004176:	6942                	ld	s2,16(sp)
    80004178:	69a2                	ld	s3,8(sp)
    8000417a:	6145                	addi	sp,sp,48
    8000417c:	8082                	ret

000000008000417e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	e426                	sd	s1,8(sp)
    80004186:	e04a                	sd	s2,0(sp)
    80004188:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000418a:	0001d517          	auipc	a0,0x1d
    8000418e:	57650513          	addi	a0,a0,1398 # 80021700 <log>
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	a52080e7          	jalr	-1454(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000419a:	0001d497          	auipc	s1,0x1d
    8000419e:	56648493          	addi	s1,s1,1382 # 80021700 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a2:	4979                	li	s2,30
    800041a4:	a039                	j	800041b2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a6:	85a6                	mv	a1,s1
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffe097          	auipc	ra,0xffffe
    800041ae:	0a0080e7          	jalr	160(ra) # 8000224a <sleep>
    if(log.committing){
    800041b2:	50dc                	lw	a5,36(s1)
    800041b4:	fbed                	bnez	a5,800041a6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b6:	509c                	lw	a5,32(s1)
    800041b8:	0017871b          	addiw	a4,a5,1
    800041bc:	0007069b          	sext.w	a3,a4
    800041c0:	0027179b          	slliw	a5,a4,0x2
    800041c4:	9fb9                	addw	a5,a5,a4
    800041c6:	0017979b          	slliw	a5,a5,0x1
    800041ca:	54d8                	lw	a4,44(s1)
    800041cc:	9fb9                	addw	a5,a5,a4
    800041ce:	00f95963          	bge	s2,a5,800041e0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	074080e7          	jalr	116(ra) # 8000224a <sleep>
    800041de:	bfd1                	j	800041b2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e0:	0001d517          	auipc	a0,0x1d
    800041e4:	52050513          	addi	a0,a0,1312 # 80021700 <log>
    800041e8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041f2:	60e2                	ld	ra,24(sp)
    800041f4:	6442                	ld	s0,16(sp)
    800041f6:	64a2                	ld	s1,8(sp)
    800041f8:	6902                	ld	s2,0(sp)
    800041fa:	6105                	addi	sp,sp,32
    800041fc:	8082                	ret

00000000800041fe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	e456                	sd	s5,8(sp)
    8000420e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004210:	0001d497          	auipc	s1,0x1d
    80004214:	4f048493          	addi	s1,s1,1264 # 80021700 <log>
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9ca080e7          	jalr	-1590(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004222:	509c                	lw	a5,32(s1)
    80004224:	37fd                	addiw	a5,a5,-1
    80004226:	0007891b          	sext.w	s2,a5
    8000422a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000422c:	50dc                	lw	a5,36(s1)
    8000422e:	efb9                	bnez	a5,8000428c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004230:	06091663          	bnez	s2,8000429c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004234:	0001d497          	auipc	s1,0x1d
    80004238:	4cc48493          	addi	s1,s1,1228 # 80021700 <log>
    8000423c:	4785                	li	a5,1
    8000423e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004240:	8526                	mv	a0,s1
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000424a:	54dc                	lw	a5,44(s1)
    8000424c:	06f04763          	bgtz	a5,800042ba <end_op+0xbc>
    acquire(&log.lock);
    80004250:	0001d497          	auipc	s1,0x1d
    80004254:	4b048493          	addi	s1,s1,1200 # 80021700 <log>
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	98a080e7          	jalr	-1654(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004262:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004266:	8526                	mv	a0,s1
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	16e080e7          	jalr	366(ra) # 800023d6 <wakeup>
    release(&log.lock);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	a26080e7          	jalr	-1498(ra) # 80000c98 <release>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	69e2                	ld	s3,24(sp)
    80004284:	6a42                	ld	s4,16(sp)
    80004286:	6aa2                	ld	s5,8(sp)
    80004288:	6121                	addi	sp,sp,64
    8000428a:	8082                	ret
    panic("log.committing");
    8000428c:	00004517          	auipc	a0,0x4
    80004290:	3ac50513          	addi	a0,a0,940 # 80008638 <syscalls+0x1e0>
    80004294:	ffffc097          	auipc	ra,0xffffc
    80004298:	2aa080e7          	jalr	682(ra) # 8000053e <panic>
    wakeup(&log);
    8000429c:	0001d497          	auipc	s1,0x1d
    800042a0:	46448493          	addi	s1,s1,1124 # 80021700 <log>
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffe097          	auipc	ra,0xffffe
    800042aa:	130080e7          	jalr	304(ra) # 800023d6 <wakeup>
  release(&log.lock);
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	9e8080e7          	jalr	-1560(ra) # 80000c98 <release>
  if(do_commit){
    800042b8:	b7c9                	j	8000427a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ba:	0001da97          	auipc	s5,0x1d
    800042be:	476a8a93          	addi	s5,s5,1142 # 80021730 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042c2:	0001da17          	auipc	s4,0x1d
    800042c6:	43ea0a13          	addi	s4,s4,1086 # 80021700 <log>
    800042ca:	018a2583          	lw	a1,24(s4)
    800042ce:	012585bb          	addw	a1,a1,s2
    800042d2:	2585                	addiw	a1,a1,1
    800042d4:	028a2503          	lw	a0,40(s4)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	cd2080e7          	jalr	-814(ra) # 80002faa <bread>
    800042e0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042e2:	000aa583          	lw	a1,0(s5)
    800042e6:	028a2503          	lw	a0,40(s4)
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	cc0080e7          	jalr	-832(ra) # 80002faa <bread>
    800042f2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042f4:	40000613          	li	a2,1024
    800042f8:	05850593          	addi	a1,a0,88
    800042fc:	05848513          	addi	a0,s1,88
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	a40080e7          	jalr	-1472(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004308:	8526                	mv	a0,s1
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	d92080e7          	jalr	-622(ra) # 8000309c <bwrite>
    brelse(from);
    80004312:	854e                	mv	a0,s3
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	dc6080e7          	jalr	-570(ra) # 800030da <brelse>
    brelse(to);
    8000431c:	8526                	mv	a0,s1
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	dbc080e7          	jalr	-580(ra) # 800030da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004326:	2905                	addiw	s2,s2,1
    80004328:	0a91                	addi	s5,s5,4
    8000432a:	02ca2783          	lw	a5,44(s4)
    8000432e:	f8f94ee3          	blt	s2,a5,800042ca <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004332:	00000097          	auipc	ra,0x0
    80004336:	c6a080e7          	jalr	-918(ra) # 80003f9c <write_head>
    install_trans(0); // Now install writes to home locations
    8000433a:	4501                	li	a0,0
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	cda080e7          	jalr	-806(ra) # 80004016 <install_trans>
    log.lh.n = 0;
    80004344:	0001d797          	auipc	a5,0x1d
    80004348:	3e07a423          	sw	zero,1000(a5) # 8002172c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000434c:	00000097          	auipc	ra,0x0
    80004350:	c50080e7          	jalr	-944(ra) # 80003f9c <write_head>
    80004354:	bdf5                	j	80004250 <end_op+0x52>

0000000080004356 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004356:	1101                	addi	sp,sp,-32
    80004358:	ec06                	sd	ra,24(sp)
    8000435a:	e822                	sd	s0,16(sp)
    8000435c:	e426                	sd	s1,8(sp)
    8000435e:	e04a                	sd	s2,0(sp)
    80004360:	1000                	addi	s0,sp,32
    80004362:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004364:	0001d917          	auipc	s2,0x1d
    80004368:	39c90913          	addi	s2,s2,924 # 80021700 <log>
    8000436c:	854a                	mv	a0,s2
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004376:	02c92603          	lw	a2,44(s2)
    8000437a:	47f5                	li	a5,29
    8000437c:	06c7c563          	blt	a5,a2,800043e6 <log_write+0x90>
    80004380:	0001d797          	auipc	a5,0x1d
    80004384:	39c7a783          	lw	a5,924(a5) # 8002171c <log+0x1c>
    80004388:	37fd                	addiw	a5,a5,-1
    8000438a:	04f65e63          	bge	a2,a5,800043e6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000438e:	0001d797          	auipc	a5,0x1d
    80004392:	3927a783          	lw	a5,914(a5) # 80021720 <log+0x20>
    80004396:	06f05063          	blez	a5,800043f6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000439a:	4781                	li	a5,0
    8000439c:	06c05563          	blez	a2,80004406 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a0:	44cc                	lw	a1,12(s1)
    800043a2:	0001d717          	auipc	a4,0x1d
    800043a6:	38e70713          	addi	a4,a4,910 # 80021730 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043aa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043ac:	4314                	lw	a3,0(a4)
    800043ae:	04b68c63          	beq	a3,a1,80004406 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043b2:	2785                	addiw	a5,a5,1
    800043b4:	0711                	addi	a4,a4,4
    800043b6:	fef61be3          	bne	a2,a5,800043ac <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ba:	0621                	addi	a2,a2,8
    800043bc:	060a                	slli	a2,a2,0x2
    800043be:	0001d797          	auipc	a5,0x1d
    800043c2:	34278793          	addi	a5,a5,834 # 80021700 <log>
    800043c6:	963e                	add	a2,a2,a5
    800043c8:	44dc                	lw	a5,12(s1)
    800043ca:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	daa080e7          	jalr	-598(ra) # 80003178 <bpin>
    log.lh.n++;
    800043d6:	0001d717          	auipc	a4,0x1d
    800043da:	32a70713          	addi	a4,a4,810 # 80021700 <log>
    800043de:	575c                	lw	a5,44(a4)
    800043e0:	2785                	addiw	a5,a5,1
    800043e2:	d75c                	sw	a5,44(a4)
    800043e4:	a835                	j	80004420 <log_write+0xca>
    panic("too big a transaction");
    800043e6:	00004517          	auipc	a0,0x4
    800043ea:	26250513          	addi	a0,a0,610 # 80008648 <syscalls+0x1f0>
    800043ee:	ffffc097          	auipc	ra,0xffffc
    800043f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	26a50513          	addi	a0,a0,618 # 80008660 <syscalls+0x208>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	140080e7          	jalr	320(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004406:	00878713          	addi	a4,a5,8
    8000440a:	00271693          	slli	a3,a4,0x2
    8000440e:	0001d717          	auipc	a4,0x1d
    80004412:	2f270713          	addi	a4,a4,754 # 80021700 <log>
    80004416:	9736                	add	a4,a4,a3
    80004418:	44d4                	lw	a3,12(s1)
    8000441a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000441c:	faf608e3          	beq	a2,a5,800043cc <log_write+0x76>
  }
  release(&log.lock);
    80004420:	0001d517          	auipc	a0,0x1d
    80004424:	2e050513          	addi	a0,a0,736 # 80021700 <log>
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	870080e7          	jalr	-1936(ra) # 80000c98 <release>
}
    80004430:	60e2                	ld	ra,24(sp)
    80004432:	6442                	ld	s0,16(sp)
    80004434:	64a2                	ld	s1,8(sp)
    80004436:	6902                	ld	s2,0(sp)
    80004438:	6105                	addi	sp,sp,32
    8000443a:	8082                	ret

000000008000443c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000443c:	1101                	addi	sp,sp,-32
    8000443e:	ec06                	sd	ra,24(sp)
    80004440:	e822                	sd	s0,16(sp)
    80004442:	e426                	sd	s1,8(sp)
    80004444:	e04a                	sd	s2,0(sp)
    80004446:	1000                	addi	s0,sp,32
    80004448:	84aa                	mv	s1,a0
    8000444a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000444c:	00004597          	auipc	a1,0x4
    80004450:	23458593          	addi	a1,a1,564 # 80008680 <syscalls+0x228>
    80004454:	0521                	addi	a0,a0,8
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	6fe080e7          	jalr	1790(ra) # 80000b54 <initlock>
  lk->name = name;
    8000445e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004462:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004466:	0204a423          	sw	zero,40(s1)
}
    8000446a:	60e2                	ld	ra,24(sp)
    8000446c:	6442                	ld	s0,16(sp)
    8000446e:	64a2                	ld	s1,8(sp)
    80004470:	6902                	ld	s2,0(sp)
    80004472:	6105                	addi	sp,sp,32
    80004474:	8082                	ret

0000000080004476 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004476:	1101                	addi	sp,sp,-32
    80004478:	ec06                	sd	ra,24(sp)
    8000447a:	e822                	sd	s0,16(sp)
    8000447c:	e426                	sd	s1,8(sp)
    8000447e:	e04a                	sd	s2,0(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004484:	00850913          	addi	s2,a0,8
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	75a080e7          	jalr	1882(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004492:	409c                	lw	a5,0(s1)
    80004494:	cb89                	beqz	a5,800044a6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004496:	85ca                	mv	a1,s2
    80004498:	8526                	mv	a0,s1
    8000449a:	ffffe097          	auipc	ra,0xffffe
    8000449e:	db0080e7          	jalr	-592(ra) # 8000224a <sleep>
  while (lk->locked) {
    800044a2:	409c                	lw	a5,0(s1)
    800044a4:	fbed                	bnez	a5,80004496 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a6:	4785                	li	a5,1
    800044a8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	6a6080e7          	jalr	1702(ra) # 80001b50 <myproc>
    800044b2:	591c                	lw	a5,48(a0)
    800044b4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b6:	854a                	mv	a0,s2
    800044b8:	ffffc097          	auipc	ra,0xffffc
    800044bc:	7e0080e7          	jalr	2016(ra) # 80000c98 <release>
}
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6902                	ld	s2,0(sp)
    800044c8:	6105                	addi	sp,sp,32
    800044ca:	8082                	ret

00000000800044cc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044cc:	1101                	addi	sp,sp,-32
    800044ce:	ec06                	sd	ra,24(sp)
    800044d0:	e822                	sd	s0,16(sp)
    800044d2:	e426                	sd	s1,8(sp)
    800044d4:	e04a                	sd	s2,0(sp)
    800044d6:	1000                	addi	s0,sp,32
    800044d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044da:	00850913          	addi	s2,a0,8
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	704080e7          	jalr	1796(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ec:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	ee4080e7          	jalr	-284(ra) # 800023d6 <wakeup>
  release(&lk->lk);
    800044fa:	854a                	mv	a0,s2
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	79c080e7          	jalr	1948(ra) # 80000c98 <release>
}
    80004504:	60e2                	ld	ra,24(sp)
    80004506:	6442                	ld	s0,16(sp)
    80004508:	64a2                	ld	s1,8(sp)
    8000450a:	6902                	ld	s2,0(sp)
    8000450c:	6105                	addi	sp,sp,32
    8000450e:	8082                	ret

0000000080004510 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004510:	7179                	addi	sp,sp,-48
    80004512:	f406                	sd	ra,40(sp)
    80004514:	f022                	sd	s0,32(sp)
    80004516:	ec26                	sd	s1,24(sp)
    80004518:	e84a                	sd	s2,16(sp)
    8000451a:	e44e                	sd	s3,8(sp)
    8000451c:	1800                	addi	s0,sp,48
    8000451e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004520:	00850913          	addi	s2,a0,8
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6be080e7          	jalr	1726(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452e:	409c                	lw	a5,0(s1)
    80004530:	ef99                	bnez	a5,8000454e <holdingsleep+0x3e>
    80004532:	4481                	li	s1,0
  release(&lk->lk);
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
  return r;
}
    8000453e:	8526                	mv	a0,s1
    80004540:	70a2                	ld	ra,40(sp)
    80004542:	7402                	ld	s0,32(sp)
    80004544:	64e2                	ld	s1,24(sp)
    80004546:	6942                	ld	s2,16(sp)
    80004548:	69a2                	ld	s3,8(sp)
    8000454a:	6145                	addi	sp,sp,48
    8000454c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454e:	0284a983          	lw	s3,40(s1)
    80004552:	ffffd097          	auipc	ra,0xffffd
    80004556:	5fe080e7          	jalr	1534(ra) # 80001b50 <myproc>
    8000455a:	5904                	lw	s1,48(a0)
    8000455c:	413484b3          	sub	s1,s1,s3
    80004560:	0014b493          	seqz	s1,s1
    80004564:	bfc1                	j	80004534 <holdingsleep+0x24>

0000000080004566 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004566:	1141                	addi	sp,sp,-16
    80004568:	e406                	sd	ra,8(sp)
    8000456a:	e022                	sd	s0,0(sp)
    8000456c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000456e:	00004597          	auipc	a1,0x4
    80004572:	12258593          	addi	a1,a1,290 # 80008690 <syscalls+0x238>
    80004576:	0001d517          	auipc	a0,0x1d
    8000457a:	2d250513          	addi	a0,a0,722 # 80021848 <ftable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	5d6080e7          	jalr	1494(ra) # 80000b54 <initlock>
}
    80004586:	60a2                	ld	ra,8(sp)
    80004588:	6402                	ld	s0,0(sp)
    8000458a:	0141                	addi	sp,sp,16
    8000458c:	8082                	ret

000000008000458e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	2b050513          	addi	a0,a0,688 # 80021848 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	644080e7          	jalr	1604(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a8:	0001d497          	auipc	s1,0x1d
    800045ac:	2b848493          	addi	s1,s1,696 # 80021860 <ftable+0x18>
    800045b0:	0001e717          	auipc	a4,0x1e
    800045b4:	25070713          	addi	a4,a4,592 # 80022800 <ftable+0xfb8>
    if(f->ref == 0){
    800045b8:	40dc                	lw	a5,4(s1)
    800045ba:	cf99                	beqz	a5,800045d8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045bc:	02848493          	addi	s1,s1,40
    800045c0:	fee49ce3          	bne	s1,a4,800045b8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	28450513          	addi	a0,a0,644 # 80021848 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
  return 0;
    800045d4:	4481                	li	s1,0
    800045d6:	a819                	j	800045ec <filealloc+0x5e>
      f->ref = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	26c50513          	addi	a0,a0,620 # 80021848 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>
}
    800045ec:	8526                	mv	a0,s1
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	24450513          	addi	a0,a0,580 # 80021848 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	5d8080e7          	jalr	1496(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004614:	40dc                	lw	a5,4(s1)
    80004616:	02f05263          	blez	a5,8000463a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000461a:	2785                	addiw	a5,a5,1
    8000461c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	22a50513          	addi	a0,a0,554 # 80021848 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	672080e7          	jalr	1650(ra) # 80000c98 <release>
  return f;
}
    8000462e:	8526                	mv	a0,s1
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret
    panic("filedup");
    8000463a:	00004517          	auipc	a0,0x4
    8000463e:	05e50513          	addi	a0,a0,94 # 80008698 <syscalls+0x240>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>

000000008000464a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000464a:	7139                	addi	sp,sp,-64
    8000464c:	fc06                	sd	ra,56(sp)
    8000464e:	f822                	sd	s0,48(sp)
    80004650:	f426                	sd	s1,40(sp)
    80004652:	f04a                	sd	s2,32(sp)
    80004654:	ec4e                	sd	s3,24(sp)
    80004656:	e852                	sd	s4,16(sp)
    80004658:	e456                	sd	s5,8(sp)
    8000465a:	0080                	addi	s0,sp,64
    8000465c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	1ea50513          	addi	a0,a0,490 # 80021848 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	57e080e7          	jalr	1406(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000466e:	40dc                	lw	a5,4(s1)
    80004670:	06f05163          	blez	a5,800046d2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004674:	37fd                	addiw	a5,a5,-1
    80004676:	0007871b          	sext.w	a4,a5
    8000467a:	c0dc                	sw	a5,4(s1)
    8000467c:	06e04363          	bgtz	a4,800046e2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004680:	0004a903          	lw	s2,0(s1)
    80004684:	0094ca83          	lbu	s5,9(s1)
    80004688:	0104ba03          	ld	s4,16(s1)
    8000468c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004690:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004694:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	1b050513          	addi	a0,a0,432 # 80021848 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800046a8:	4785                	li	a5,1
    800046aa:	04f90d63          	beq	s2,a5,80004704 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ae:	3979                	addiw	s2,s2,-2
    800046b0:	4785                	li	a5,1
    800046b2:	0527e063          	bltu	a5,s2,800046f2 <fileclose+0xa8>
    begin_op();
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	ac8080e7          	jalr	-1336(ra) # 8000417e <begin_op>
    iput(ff.ip);
    800046be:	854e                	mv	a0,s3
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	2a6080e7          	jalr	678(ra) # 80003966 <iput>
    end_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	b36080e7          	jalr	-1226(ra) # 800041fe <end_op>
    800046d0:	a00d                	j	800046f2 <fileclose+0xa8>
    panic("fileclose");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	fce50513          	addi	a0,a0,-50 # 800086a0 <syscalls+0x248>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046e2:	0001d517          	auipc	a0,0x1d
    800046e6:	16650513          	addi	a0,a0,358 # 80021848 <ftable>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5ae080e7          	jalr	1454(ra) # 80000c98 <release>
  }
}
    800046f2:	70e2                	ld	ra,56(sp)
    800046f4:	7442                	ld	s0,48(sp)
    800046f6:	74a2                	ld	s1,40(sp)
    800046f8:	7902                	ld	s2,32(sp)
    800046fa:	69e2                	ld	s3,24(sp)
    800046fc:	6a42                	ld	s4,16(sp)
    800046fe:	6aa2                	ld	s5,8(sp)
    80004700:	6121                	addi	sp,sp,64
    80004702:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004704:	85d6                	mv	a1,s5
    80004706:	8552                	mv	a0,s4
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	34c080e7          	jalr	844(ra) # 80004a54 <pipeclose>
    80004710:	b7cd                	j	800046f2 <fileclose+0xa8>

0000000080004712 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004712:	715d                	addi	sp,sp,-80
    80004714:	e486                	sd	ra,72(sp)
    80004716:	e0a2                	sd	s0,64(sp)
    80004718:	fc26                	sd	s1,56(sp)
    8000471a:	f84a                	sd	s2,48(sp)
    8000471c:	f44e                	sd	s3,40(sp)
    8000471e:	0880                	addi	s0,sp,80
    80004720:	84aa                	mv	s1,a0
    80004722:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	42c080e7          	jalr	1068(ra) # 80001b50 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000472c:	409c                	lw	a5,0(s1)
    8000472e:	37f9                	addiw	a5,a5,-2
    80004730:	4705                	li	a4,1
    80004732:	04f76763          	bltu	a4,a5,80004780 <filestat+0x6e>
    80004736:	892a                	mv	s2,a0
    ilock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	072080e7          	jalr	114(ra) # 800037ac <ilock>
    stati(f->ip, &st);
    80004742:	fb840593          	addi	a1,s0,-72
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2ee080e7          	jalr	750(ra) # 80003a36 <stati>
    iunlock(f->ip);
    80004750:	6c88                	ld	a0,24(s1)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	11c080e7          	jalr	284(ra) # 8000386e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000475a:	46e1                	li	a3,24
    8000475c:	fb840613          	addi	a2,s0,-72
    80004760:	85ce                	mv	a1,s3
    80004762:	05093503          	ld	a0,80(s2)
    80004766:	ffffd097          	auipc	ra,0xffffd
    8000476a:	f0c080e7          	jalr	-244(ra) # 80001672 <copyout>
    8000476e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004772:	60a6                	ld	ra,72(sp)
    80004774:	6406                	ld	s0,64(sp)
    80004776:	74e2                	ld	s1,56(sp)
    80004778:	7942                	ld	s2,48(sp)
    8000477a:	79a2                	ld	s3,40(sp)
    8000477c:	6161                	addi	sp,sp,80
    8000477e:	8082                	ret
  return -1;
    80004780:	557d                	li	a0,-1
    80004782:	bfc5                	j	80004772 <filestat+0x60>

0000000080004784 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004784:	7179                	addi	sp,sp,-48
    80004786:	f406                	sd	ra,40(sp)
    80004788:	f022                	sd	s0,32(sp)
    8000478a:	ec26                	sd	s1,24(sp)
    8000478c:	e84a                	sd	s2,16(sp)
    8000478e:	e44e                	sd	s3,8(sp)
    80004790:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004792:	00854783          	lbu	a5,8(a0)
    80004796:	c3d5                	beqz	a5,8000483a <fileread+0xb6>
    80004798:	84aa                	mv	s1,a0
    8000479a:	89ae                	mv	s3,a1
    8000479c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479e:	411c                	lw	a5,0(a0)
    800047a0:	4705                	li	a4,1
    800047a2:	04e78963          	beq	a5,a4,800047f4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a6:	470d                	li	a4,3
    800047a8:	04e78d63          	beq	a5,a4,80004802 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ac:	4709                	li	a4,2
    800047ae:	06e79e63          	bne	a5,a4,8000482a <fileread+0xa6>
    ilock(f->ip);
    800047b2:	6d08                	ld	a0,24(a0)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	ff8080e7          	jalr	-8(ra) # 800037ac <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047bc:	874a                	mv	a4,s2
    800047be:	5094                	lw	a3,32(s1)
    800047c0:	864e                	mv	a2,s3
    800047c2:	4585                	li	a1,1
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	29a080e7          	jalr	666(ra) # 80003a60 <readi>
    800047ce:	892a                	mv	s2,a0
    800047d0:	00a05563          	blez	a0,800047da <fileread+0x56>
      f->off += r;
    800047d4:	509c                	lw	a5,32(s1)
    800047d6:	9fa9                	addw	a5,a5,a0
    800047d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	092080e7          	jalr	146(ra) # 8000386e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e4:	854a                	mv	a0,s2
    800047e6:	70a2                	ld	ra,40(sp)
    800047e8:	7402                	ld	s0,32(sp)
    800047ea:	64e2                	ld	s1,24(sp)
    800047ec:	6942                	ld	s2,16(sp)
    800047ee:	69a2                	ld	s3,8(sp)
    800047f0:	6145                	addi	sp,sp,48
    800047f2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f4:	6908                	ld	a0,16(a0)
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	3c8080e7          	jalr	968(ra) # 80004bbe <piperead>
    800047fe:	892a                	mv	s2,a0
    80004800:	b7d5                	j	800047e4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004802:	02451783          	lh	a5,36(a0)
    80004806:	03079693          	slli	a3,a5,0x30
    8000480a:	92c1                	srli	a3,a3,0x30
    8000480c:	4725                	li	a4,9
    8000480e:	02d76863          	bltu	a4,a3,8000483e <fileread+0xba>
    80004812:	0792                	slli	a5,a5,0x4
    80004814:	0001d717          	auipc	a4,0x1d
    80004818:	f9470713          	addi	a4,a4,-108 # 800217a8 <devsw>
    8000481c:	97ba                	add	a5,a5,a4
    8000481e:	639c                	ld	a5,0(a5)
    80004820:	c38d                	beqz	a5,80004842 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004822:	4505                	li	a0,1
    80004824:	9782                	jalr	a5
    80004826:	892a                	mv	s2,a0
    80004828:	bf75                	j	800047e4 <fileread+0x60>
    panic("fileread");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	e8650513          	addi	a0,a0,-378 # 800086b0 <syscalls+0x258>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d0c080e7          	jalr	-756(ra) # 8000053e <panic>
    return -1;
    8000483a:	597d                	li	s2,-1
    8000483c:	b765                	j	800047e4 <fileread+0x60>
      return -1;
    8000483e:	597d                	li	s2,-1
    80004840:	b755                	j	800047e4 <fileread+0x60>
    80004842:	597d                	li	s2,-1
    80004844:	b745                	j	800047e4 <fileread+0x60>

0000000080004846 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004846:	715d                	addi	sp,sp,-80
    80004848:	e486                	sd	ra,72(sp)
    8000484a:	e0a2                	sd	s0,64(sp)
    8000484c:	fc26                	sd	s1,56(sp)
    8000484e:	f84a                	sd	s2,48(sp)
    80004850:	f44e                	sd	s3,40(sp)
    80004852:	f052                	sd	s4,32(sp)
    80004854:	ec56                	sd	s5,24(sp)
    80004856:	e85a                	sd	s6,16(sp)
    80004858:	e45e                	sd	s7,8(sp)
    8000485a:	e062                	sd	s8,0(sp)
    8000485c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000485e:	00954783          	lbu	a5,9(a0)
    80004862:	10078663          	beqz	a5,8000496e <filewrite+0x128>
    80004866:	892a                	mv	s2,a0
    80004868:	8aae                	mv	s5,a1
    8000486a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486c:	411c                	lw	a5,0(a0)
    8000486e:	4705                	li	a4,1
    80004870:	02e78263          	beq	a5,a4,80004894 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004874:	470d                	li	a4,3
    80004876:	02e78663          	beq	a5,a4,800048a2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487a:	4709                	li	a4,2
    8000487c:	0ee79163          	bne	a5,a4,8000495e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004880:	0ac05d63          	blez	a2,8000493a <filewrite+0xf4>
    int i = 0;
    80004884:	4981                	li	s3,0
    80004886:	6b05                	lui	s6,0x1
    80004888:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000488c:	6b85                	lui	s7,0x1
    8000488e:	c00b8b9b          	addiw	s7,s7,-1024
    80004892:	a861                	j	8000492a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004894:	6908                	ld	a0,16(a0)
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	22e080e7          	jalr	558(ra) # 80004ac4 <pipewrite>
    8000489e:	8a2a                	mv	s4,a0
    800048a0:	a045                	j	80004940 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a2:	02451783          	lh	a5,36(a0)
    800048a6:	03079693          	slli	a3,a5,0x30
    800048aa:	92c1                	srli	a3,a3,0x30
    800048ac:	4725                	li	a4,9
    800048ae:	0cd76263          	bltu	a4,a3,80004972 <filewrite+0x12c>
    800048b2:	0792                	slli	a5,a5,0x4
    800048b4:	0001d717          	auipc	a4,0x1d
    800048b8:	ef470713          	addi	a4,a4,-268 # 800217a8 <devsw>
    800048bc:	97ba                	add	a5,a5,a4
    800048be:	679c                	ld	a5,8(a5)
    800048c0:	cbdd                	beqz	a5,80004976 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048c2:	4505                	li	a0,1
    800048c4:	9782                	jalr	a5
    800048c6:	8a2a                	mv	s4,a0
    800048c8:	a8a5                	j	80004940 <filewrite+0xfa>
    800048ca:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	8b0080e7          	jalr	-1872(ra) # 8000417e <begin_op>
      ilock(f->ip);
    800048d6:	01893503          	ld	a0,24(s2)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	ed2080e7          	jalr	-302(ra) # 800037ac <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e2:	8762                	mv	a4,s8
    800048e4:	02092683          	lw	a3,32(s2)
    800048e8:	01598633          	add	a2,s3,s5
    800048ec:	4585                	li	a1,1
    800048ee:	01893503          	ld	a0,24(s2)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	266080e7          	jalr	614(ra) # 80003b58 <writei>
    800048fa:	84aa                	mv	s1,a0
    800048fc:	00a05763          	blez	a0,8000490a <filewrite+0xc4>
        f->off += r;
    80004900:	02092783          	lw	a5,32(s2)
    80004904:	9fa9                	addw	a5,a5,a0
    80004906:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000490a:	01893503          	ld	a0,24(s2)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	f60080e7          	jalr	-160(ra) # 8000386e <iunlock>
      end_op();
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	8e8080e7          	jalr	-1816(ra) # 800041fe <end_op>

      if(r != n1){
    8000491e:	009c1f63          	bne	s8,s1,8000493c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004922:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004926:	0149db63          	bge	s3,s4,8000493c <filewrite+0xf6>
      int n1 = n - i;
    8000492a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000492e:	84be                	mv	s1,a5
    80004930:	2781                	sext.w	a5,a5
    80004932:	f8fb5ce3          	bge	s6,a5,800048ca <filewrite+0x84>
    80004936:	84de                	mv	s1,s7
    80004938:	bf49                	j	800048ca <filewrite+0x84>
    int i = 0;
    8000493a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000493c:	013a1f63          	bne	s4,s3,8000495a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004940:	8552                	mv	a0,s4
    80004942:	60a6                	ld	ra,72(sp)
    80004944:	6406                	ld	s0,64(sp)
    80004946:	74e2                	ld	s1,56(sp)
    80004948:	7942                	ld	s2,48(sp)
    8000494a:	79a2                	ld	s3,40(sp)
    8000494c:	7a02                	ld	s4,32(sp)
    8000494e:	6ae2                	ld	s5,24(sp)
    80004950:	6b42                	ld	s6,16(sp)
    80004952:	6ba2                	ld	s7,8(sp)
    80004954:	6c02                	ld	s8,0(sp)
    80004956:	6161                	addi	sp,sp,80
    80004958:	8082                	ret
    ret = (i == n ? n : -1);
    8000495a:	5a7d                	li	s4,-1
    8000495c:	b7d5                	j	80004940 <filewrite+0xfa>
    panic("filewrite");
    8000495e:	00004517          	auipc	a0,0x4
    80004962:	d6250513          	addi	a0,a0,-670 # 800086c0 <syscalls+0x268>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	bd8080e7          	jalr	-1064(ra) # 8000053e <panic>
    return -1;
    8000496e:	5a7d                	li	s4,-1
    80004970:	bfc1                	j	80004940 <filewrite+0xfa>
      return -1;
    80004972:	5a7d                	li	s4,-1
    80004974:	b7f1                	j	80004940 <filewrite+0xfa>
    80004976:	5a7d                	li	s4,-1
    80004978:	b7e1                	j	80004940 <filewrite+0xfa>

000000008000497a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000497a:	7179                	addi	sp,sp,-48
    8000497c:	f406                	sd	ra,40(sp)
    8000497e:	f022                	sd	s0,32(sp)
    80004980:	ec26                	sd	s1,24(sp)
    80004982:	e84a                	sd	s2,16(sp)
    80004984:	e44e                	sd	s3,8(sp)
    80004986:	e052                	sd	s4,0(sp)
    80004988:	1800                	addi	s0,sp,48
    8000498a:	84aa                	mv	s1,a0
    8000498c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000498e:	0005b023          	sd	zero,0(a1)
    80004992:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	bf8080e7          	jalr	-1032(ra) # 8000458e <filealloc>
    8000499e:	e088                	sd	a0,0(s1)
    800049a0:	c551                	beqz	a0,80004a2c <pipealloc+0xb2>
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	bec080e7          	jalr	-1044(ra) # 8000458e <filealloc>
    800049aa:	00aa3023          	sd	a0,0(s4)
    800049ae:	c92d                	beqz	a0,80004a20 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	144080e7          	jalr	324(ra) # 80000af4 <kalloc>
    800049b8:	892a                	mv	s2,a0
    800049ba:	c125                	beqz	a0,80004a1a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049bc:	4985                	li	s3,1
    800049be:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049c2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049c6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ca:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ce:	00004597          	auipc	a1,0x4
    800049d2:	d0258593          	addi	a1,a1,-766 # 800086d0 <syscalls+0x278>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	17e080e7          	jalr	382(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ea:	609c                	ld	a5,0(s1)
    800049ec:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049f0:	609c                	ld	a5,0(s1)
    800049f2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049f6:	000a3783          	ld	a5,0(s4)
    800049fa:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049fe:	000a3783          	ld	a5,0(s4)
    80004a02:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a06:	000a3783          	ld	a5,0(s4)
    80004a0a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a0e:	000a3783          	ld	a5,0(s4)
    80004a12:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a16:	4501                	li	a0,0
    80004a18:	a025                	j	80004a40 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a1a:	6088                	ld	a0,0(s1)
    80004a1c:	e501                	bnez	a0,80004a24 <pipealloc+0xaa>
    80004a1e:	a039                	j	80004a2c <pipealloc+0xb2>
    80004a20:	6088                	ld	a0,0(s1)
    80004a22:	c51d                	beqz	a0,80004a50 <pipealloc+0xd6>
    fileclose(*f0);
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	c26080e7          	jalr	-986(ra) # 8000464a <fileclose>
  if(*f1)
    80004a2c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a30:	557d                	li	a0,-1
  if(*f1)
    80004a32:	c799                	beqz	a5,80004a40 <pipealloc+0xc6>
    fileclose(*f1);
    80004a34:	853e                	mv	a0,a5
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	c14080e7          	jalr	-1004(ra) # 8000464a <fileclose>
  return -1;
    80004a3e:	557d                	li	a0,-1
}
    80004a40:	70a2                	ld	ra,40(sp)
    80004a42:	7402                	ld	s0,32(sp)
    80004a44:	64e2                	ld	s1,24(sp)
    80004a46:	6942                	ld	s2,16(sp)
    80004a48:	69a2                	ld	s3,8(sp)
    80004a4a:	6a02                	ld	s4,0(sp)
    80004a4c:	6145                	addi	sp,sp,48
    80004a4e:	8082                	ret
  return -1;
    80004a50:	557d                	li	a0,-1
    80004a52:	b7fd                	j	80004a40 <pipealloc+0xc6>

0000000080004a54 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a54:	1101                	addi	sp,sp,-32
    80004a56:	ec06                	sd	ra,24(sp)
    80004a58:	e822                	sd	s0,16(sp)
    80004a5a:	e426                	sd	s1,8(sp)
    80004a5c:	e04a                	sd	s2,0(sp)
    80004a5e:	1000                	addi	s0,sp,32
    80004a60:	84aa                	mv	s1,a0
    80004a62:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  if(writable){
    80004a6c:	02090d63          	beqz	s2,80004aa6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a70:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a74:	21848513          	addi	a0,s1,536
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	95e080e7          	jalr	-1698(ra) # 800023d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a80:	2204b783          	ld	a5,544(s1)
    80004a84:	eb95                	bnez	a5,80004ab8 <pipeclose+0x64>
    release(&pi->lock);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a90:	8526                	mv	a0,s1
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	f66080e7          	jalr	-154(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a9a:	60e2                	ld	ra,24(sp)
    80004a9c:	6442                	ld	s0,16(sp)
    80004a9e:	64a2                	ld	s1,8(sp)
    80004aa0:	6902                	ld	s2,0(sp)
    80004aa2:	6105                	addi	sp,sp,32
    80004aa4:	8082                	ret
    pi->readopen = 0;
    80004aa6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aaa:	21c48513          	addi	a0,s1,540
    80004aae:	ffffe097          	auipc	ra,0xffffe
    80004ab2:	928080e7          	jalr	-1752(ra) # 800023d6 <wakeup>
    80004ab6:	b7e9                	j	80004a80 <pipeclose+0x2c>
    release(&pi->lock);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	1de080e7          	jalr	478(ra) # 80000c98 <release>
}
    80004ac2:	bfe1                	j	80004a9a <pipeclose+0x46>

0000000080004ac4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ac4:	7159                	addi	sp,sp,-112
    80004ac6:	f486                	sd	ra,104(sp)
    80004ac8:	f0a2                	sd	s0,96(sp)
    80004aca:	eca6                	sd	s1,88(sp)
    80004acc:	e8ca                	sd	s2,80(sp)
    80004ace:	e4ce                	sd	s3,72(sp)
    80004ad0:	e0d2                	sd	s4,64(sp)
    80004ad2:	fc56                	sd	s5,56(sp)
    80004ad4:	f85a                	sd	s6,48(sp)
    80004ad6:	f45e                	sd	s7,40(sp)
    80004ad8:	f062                	sd	s8,32(sp)
    80004ada:	ec66                	sd	s9,24(sp)
    80004adc:	1880                	addi	s0,sp,112
    80004ade:	84aa                	mv	s1,a0
    80004ae0:	8aae                	mv	s5,a1
    80004ae2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ae4:	ffffd097          	auipc	ra,0xffffd
    80004ae8:	06c080e7          	jalr	108(ra) # 80001b50 <myproc>
    80004aec:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	0f4080e7          	jalr	244(ra) # 80000be4 <acquire>
  while(i < n){
    80004af8:	0d405163          	blez	s4,80004bba <pipewrite+0xf6>
    80004afc:	8ba6                	mv	s7,s1
  int i = 0;
    80004afe:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b00:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b02:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b06:	21c48c13          	addi	s8,s1,540
    80004b0a:	a08d                	j	80004b6c <pipewrite+0xa8>
      release(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
      return -1;
    80004b16:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b18:	854a                	mv	a0,s2
    80004b1a:	70a6                	ld	ra,104(sp)
    80004b1c:	7406                	ld	s0,96(sp)
    80004b1e:	64e6                	ld	s1,88(sp)
    80004b20:	6946                	ld	s2,80(sp)
    80004b22:	69a6                	ld	s3,72(sp)
    80004b24:	6a06                	ld	s4,64(sp)
    80004b26:	7ae2                	ld	s5,56(sp)
    80004b28:	7b42                	ld	s6,48(sp)
    80004b2a:	7ba2                	ld	s7,40(sp)
    80004b2c:	7c02                	ld	s8,32(sp)
    80004b2e:	6ce2                	ld	s9,24(sp)
    80004b30:	6165                	addi	sp,sp,112
    80004b32:	8082                	ret
      wakeup(&pi->nread);
    80004b34:	8566                	mv	a0,s9
    80004b36:	ffffe097          	auipc	ra,0xffffe
    80004b3a:	8a0080e7          	jalr	-1888(ra) # 800023d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b3e:	85de                	mv	a1,s7
    80004b40:	8562                	mv	a0,s8
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	708080e7          	jalr	1800(ra) # 8000224a <sleep>
    80004b4a:	a839                	j	80004b68 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b4c:	21c4a783          	lw	a5,540(s1)
    80004b50:	0017871b          	addiw	a4,a5,1
    80004b54:	20e4ae23          	sw	a4,540(s1)
    80004b58:	1ff7f793          	andi	a5,a5,511
    80004b5c:	97a6                	add	a5,a5,s1
    80004b5e:	f9f44703          	lbu	a4,-97(s0)
    80004b62:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b66:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b68:	03495d63          	bge	s2,s4,80004ba2 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b6c:	2204a783          	lw	a5,544(s1)
    80004b70:	dfd1                	beqz	a5,80004b0c <pipewrite+0x48>
    80004b72:	0289a783          	lw	a5,40(s3)
    80004b76:	fbd9                	bnez	a5,80004b0c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b78:	2184a783          	lw	a5,536(s1)
    80004b7c:	21c4a703          	lw	a4,540(s1)
    80004b80:	2007879b          	addiw	a5,a5,512
    80004b84:	faf708e3          	beq	a4,a5,80004b34 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b88:	4685                	li	a3,1
    80004b8a:	01590633          	add	a2,s2,s5
    80004b8e:	f9f40593          	addi	a1,s0,-97
    80004b92:	0509b503          	ld	a0,80(s3)
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	b68080e7          	jalr	-1176(ra) # 800016fe <copyin>
    80004b9e:	fb6517e3          	bne	a0,s6,80004b4c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ba2:	21848513          	addi	a0,s1,536
    80004ba6:	ffffe097          	auipc	ra,0xffffe
    80004baa:	830080e7          	jalr	-2000(ra) # 800023d6 <wakeup>
  release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	0e8080e7          	jalr	232(ra) # 80000c98 <release>
  return i;
    80004bb8:	b785                	j	80004b18 <pipewrite+0x54>
  int i = 0;
    80004bba:	4901                	li	s2,0
    80004bbc:	b7dd                	j	80004ba2 <pipewrite+0xde>

0000000080004bbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bbe:	715d                	addi	sp,sp,-80
    80004bc0:	e486                	sd	ra,72(sp)
    80004bc2:	e0a2                	sd	s0,64(sp)
    80004bc4:	fc26                	sd	s1,56(sp)
    80004bc6:	f84a                	sd	s2,48(sp)
    80004bc8:	f44e                	sd	s3,40(sp)
    80004bca:	f052                	sd	s4,32(sp)
    80004bcc:	ec56                	sd	s5,24(sp)
    80004bce:	e85a                	sd	s6,16(sp)
    80004bd0:	0880                	addi	s0,sp,80
    80004bd2:	84aa                	mv	s1,a0
    80004bd4:	892e                	mv	s2,a1
    80004bd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	f78080e7          	jalr	-136(ra) # 80001b50 <myproc>
    80004be0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004be2:	8b26                	mv	s6,s1
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	ffe080e7          	jalr	-2(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bee:	2184a703          	lw	a4,536(s1)
    80004bf2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	02f71463          	bne	a4,a5,80004c22 <piperead+0x64>
    80004bfe:	2244a783          	lw	a5,548(s1)
    80004c02:	c385                	beqz	a5,80004c22 <piperead+0x64>
    if(pr->killed){
    80004c04:	028a2783          	lw	a5,40(s4)
    80004c08:	ebc1                	bnez	a5,80004c98 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c0a:	85da                	mv	a1,s6
    80004c0c:	854e                	mv	a0,s3
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	63c080e7          	jalr	1596(ra) # 8000224a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c16:	2184a703          	lw	a4,536(s1)
    80004c1a:	21c4a783          	lw	a5,540(s1)
    80004c1e:	fef700e3          	beq	a4,a5,80004bfe <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c22:	09505263          	blez	s5,80004ca6 <piperead+0xe8>
    80004c26:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c28:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c2a:	2184a783          	lw	a5,536(s1)
    80004c2e:	21c4a703          	lw	a4,540(s1)
    80004c32:	02f70d63          	beq	a4,a5,80004c6c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c36:	0017871b          	addiw	a4,a5,1
    80004c3a:	20e4ac23          	sw	a4,536(s1)
    80004c3e:	1ff7f793          	andi	a5,a5,511
    80004c42:	97a6                	add	a5,a5,s1
    80004c44:	0187c783          	lbu	a5,24(a5)
    80004c48:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4c:	4685                	li	a3,1
    80004c4e:	fbf40613          	addi	a2,s0,-65
    80004c52:	85ca                	mv	a1,s2
    80004c54:	050a3503          	ld	a0,80(s4)
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	a1a080e7          	jalr	-1510(ra) # 80001672 <copyout>
    80004c60:	01650663          	beq	a0,s6,80004c6c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c64:	2985                	addiw	s3,s3,1
    80004c66:	0905                	addi	s2,s2,1
    80004c68:	fd3a91e3          	bne	s5,s3,80004c2a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c6c:	21c48513          	addi	a0,s1,540
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	766080e7          	jalr	1894(ra) # 800023d6 <wakeup>
  release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
  return i;
}
    80004c82:	854e                	mv	a0,s3
    80004c84:	60a6                	ld	ra,72(sp)
    80004c86:	6406                	ld	s0,64(sp)
    80004c88:	74e2                	ld	s1,56(sp)
    80004c8a:	7942                	ld	s2,48(sp)
    80004c8c:	79a2                	ld	s3,40(sp)
    80004c8e:	7a02                	ld	s4,32(sp)
    80004c90:	6ae2                	ld	s5,24(sp)
    80004c92:	6b42                	ld	s6,16(sp)
    80004c94:	6161                	addi	sp,sp,80
    80004c96:	8082                	ret
      release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	ffe080e7          	jalr	-2(ra) # 80000c98 <release>
      return -1;
    80004ca2:	59fd                	li	s3,-1
    80004ca4:	bff9                	j	80004c82 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca6:	4981                	li	s3,0
    80004ca8:	b7d1                	j	80004c6c <piperead+0xae>

0000000080004caa <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004caa:	df010113          	addi	sp,sp,-528
    80004cae:	20113423          	sd	ra,520(sp)
    80004cb2:	20813023          	sd	s0,512(sp)
    80004cb6:	ffa6                	sd	s1,504(sp)
    80004cb8:	fbca                	sd	s2,496(sp)
    80004cba:	f7ce                	sd	s3,488(sp)
    80004cbc:	f3d2                	sd	s4,480(sp)
    80004cbe:	efd6                	sd	s5,472(sp)
    80004cc0:	ebda                	sd	s6,464(sp)
    80004cc2:	e7de                	sd	s7,456(sp)
    80004cc4:	e3e2                	sd	s8,448(sp)
    80004cc6:	ff66                	sd	s9,440(sp)
    80004cc8:	fb6a                	sd	s10,432(sp)
    80004cca:	f76e                	sd	s11,424(sp)
    80004ccc:	0c00                	addi	s0,sp,528
    80004cce:	84aa                	mv	s1,a0
    80004cd0:	dea43c23          	sd	a0,-520(s0)
    80004cd4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	e78080e7          	jalr	-392(ra) # 80001b50 <myproc>
    80004ce0:	892a                	mv	s2,a0

  begin_op();
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	49c080e7          	jalr	1180(ra) # 8000417e <begin_op>

  if((ip = namei(path)) == 0){
    80004cea:	8526                	mv	a0,s1
    80004cec:	fffff097          	auipc	ra,0xfffff
    80004cf0:	276080e7          	jalr	630(ra) # 80003f62 <namei>
    80004cf4:	c92d                	beqz	a0,80004d66 <exec+0xbc>
    80004cf6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	ab4080e7          	jalr	-1356(ra) # 800037ac <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d00:	04000713          	li	a4,64
    80004d04:	4681                	li	a3,0
    80004d06:	e5040613          	addi	a2,s0,-432
    80004d0a:	4581                	li	a1,0
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	d52080e7          	jalr	-686(ra) # 80003a60 <readi>
    80004d16:	04000793          	li	a5,64
    80004d1a:	00f51a63          	bne	a0,a5,80004d2e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d1e:	e5042703          	lw	a4,-432(s0)
    80004d22:	464c47b7          	lui	a5,0x464c4
    80004d26:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d2a:	04f70463          	beq	a4,a5,80004d72 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	cde080e7          	jalr	-802(ra) # 80003a0e <iunlockput>
    end_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	4c6080e7          	jalr	1222(ra) # 800041fe <end_op>
  }
  return -1;
    80004d40:	557d                	li	a0,-1
}
    80004d42:	20813083          	ld	ra,520(sp)
    80004d46:	20013403          	ld	s0,512(sp)
    80004d4a:	74fe                	ld	s1,504(sp)
    80004d4c:	795e                	ld	s2,496(sp)
    80004d4e:	79be                	ld	s3,488(sp)
    80004d50:	7a1e                	ld	s4,480(sp)
    80004d52:	6afe                	ld	s5,472(sp)
    80004d54:	6b5e                	ld	s6,464(sp)
    80004d56:	6bbe                	ld	s7,456(sp)
    80004d58:	6c1e                	ld	s8,448(sp)
    80004d5a:	7cfa                	ld	s9,440(sp)
    80004d5c:	7d5a                	ld	s10,432(sp)
    80004d5e:	7dba                	ld	s11,424(sp)
    80004d60:	21010113          	addi	sp,sp,528
    80004d64:	8082                	ret
    end_op();
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	498080e7          	jalr	1176(ra) # 800041fe <end_op>
    return -1;
    80004d6e:	557d                	li	a0,-1
    80004d70:	bfc9                	j	80004d42 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d72:	854a                	mv	a0,s2
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	e9c080e7          	jalr	-356(ra) # 80001c10 <proc_pagetable>
    80004d7c:	8baa                	mv	s7,a0
    80004d7e:	d945                	beqz	a0,80004d2e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d80:	e7042983          	lw	s3,-400(s0)
    80004d84:	e8845783          	lhu	a5,-376(s0)
    80004d88:	c7ad                	beqz	a5,80004df2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d8a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d8c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d8e:	6c85                	lui	s9,0x1
    80004d90:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d94:	def43823          	sd	a5,-528(s0)
    80004d98:	a42d                	j	80004fc2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d9a:	00004517          	auipc	a0,0x4
    80004d9e:	93e50513          	addi	a0,a0,-1730 # 800086d8 <syscalls+0x280>
    80004da2:	ffffb097          	auipc	ra,0xffffb
    80004da6:	79c080e7          	jalr	1948(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004daa:	8756                	mv	a4,s5
    80004dac:	012d86bb          	addw	a3,s11,s2
    80004db0:	4581                	li	a1,0
    80004db2:	8526                	mv	a0,s1
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	cac080e7          	jalr	-852(ra) # 80003a60 <readi>
    80004dbc:	2501                	sext.w	a0,a0
    80004dbe:	1aaa9963          	bne	s5,a0,80004f70 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dc2:	6785                	lui	a5,0x1
    80004dc4:	0127893b          	addw	s2,a5,s2
    80004dc8:	77fd                	lui	a5,0xfffff
    80004dca:	01478a3b          	addw	s4,a5,s4
    80004dce:	1f897163          	bgeu	s2,s8,80004fb0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dd2:	02091593          	slli	a1,s2,0x20
    80004dd6:	9181                	srli	a1,a1,0x20
    80004dd8:	95ea                	add	a1,a1,s10
    80004dda:	855e                	mv	a0,s7
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	292080e7          	jalr	658(ra) # 8000106e <walkaddr>
    80004de4:	862a                	mv	a2,a0
    if(pa == 0)
    80004de6:	d955                	beqz	a0,80004d9a <exec+0xf0>
      n = PGSIZE;
    80004de8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dea:	fd9a70e3          	bgeu	s4,s9,80004daa <exec+0x100>
      n = sz - i;
    80004dee:	8ad2                	mv	s5,s4
    80004df0:	bf6d                	j	80004daa <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df2:	4901                	li	s2,0
  iunlockput(ip);
    80004df4:	8526                	mv	a0,s1
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	c18080e7          	jalr	-1000(ra) # 80003a0e <iunlockput>
  end_op();
    80004dfe:	fffff097          	auipc	ra,0xfffff
    80004e02:	400080e7          	jalr	1024(ra) # 800041fe <end_op>
  p = myproc();
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	d4a080e7          	jalr	-694(ra) # 80001b50 <myproc>
    80004e0e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e10:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e14:	6785                	lui	a5,0x1
    80004e16:	17fd                	addi	a5,a5,-1
    80004e18:	993e                	add	s2,s2,a5
    80004e1a:	757d                	lui	a0,0xfffff
    80004e1c:	00a977b3          	and	a5,s2,a0
    80004e20:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e24:	6609                	lui	a2,0x2
    80004e26:	963e                	add	a2,a2,a5
    80004e28:	85be                	mv	a1,a5
    80004e2a:	855e                	mv	a0,s7
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	5f6080e7          	jalr	1526(ra) # 80001422 <uvmalloc>
    80004e34:	8b2a                	mv	s6,a0
  ip = 0;
    80004e36:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e38:	12050c63          	beqz	a0,80004f70 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e3c:	75f9                	lui	a1,0xffffe
    80004e3e:	95aa                	add	a1,a1,a0
    80004e40:	855e                	mv	a0,s7
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	7fe080e7          	jalr	2046(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e4a:	7c7d                	lui	s8,0xfffff
    80004e4c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e4e:	e0043783          	ld	a5,-512(s0)
    80004e52:	6388                	ld	a0,0(a5)
    80004e54:	c535                	beqz	a0,80004ec0 <exec+0x216>
    80004e56:	e9040993          	addi	s3,s0,-368
    80004e5a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e5e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	004080e7          	jalr	4(ra) # 80000e64 <strlen>
    80004e68:	2505                	addiw	a0,a0,1
    80004e6a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e6e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e72:	13896363          	bltu	s2,s8,80004f98 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e76:	e0043d83          	ld	s11,-512(s0)
    80004e7a:	000dba03          	ld	s4,0(s11)
    80004e7e:	8552                	mv	a0,s4
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	fe4080e7          	jalr	-28(ra) # 80000e64 <strlen>
    80004e88:	0015069b          	addiw	a3,a0,1
    80004e8c:	8652                	mv	a2,s4
    80004e8e:	85ca                	mv	a1,s2
    80004e90:	855e                	mv	a0,s7
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	7e0080e7          	jalr	2016(ra) # 80001672 <copyout>
    80004e9a:	10054363          	bltz	a0,80004fa0 <exec+0x2f6>
    ustack[argc] = sp;
    80004e9e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ea2:	0485                	addi	s1,s1,1
    80004ea4:	008d8793          	addi	a5,s11,8
    80004ea8:	e0f43023          	sd	a5,-512(s0)
    80004eac:	008db503          	ld	a0,8(s11)
    80004eb0:	c911                	beqz	a0,80004ec4 <exec+0x21a>
    if(argc >= MAXARG)
    80004eb2:	09a1                	addi	s3,s3,8
    80004eb4:	fb3c96e3          	bne	s9,s3,80004e60 <exec+0x1b6>
  sz = sz1;
    80004eb8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ebc:	4481                	li	s1,0
    80004ebe:	a84d                	j	80004f70 <exec+0x2c6>
  sp = sz;
    80004ec0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ec2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ec4:	00349793          	slli	a5,s1,0x3
    80004ec8:	f9040713          	addi	a4,s0,-112
    80004ecc:	97ba                	add	a5,a5,a4
    80004ece:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ed2:	00148693          	addi	a3,s1,1
    80004ed6:	068e                	slli	a3,a3,0x3
    80004ed8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004edc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee0:	01897663          	bgeu	s2,s8,80004eec <exec+0x242>
  sz = sz1;
    80004ee4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee8:	4481                	li	s1,0
    80004eea:	a059                	j	80004f70 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eec:	e9040613          	addi	a2,s0,-368
    80004ef0:	85ca                	mv	a1,s2
    80004ef2:	855e                	mv	a0,s7
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	77e080e7          	jalr	1918(ra) # 80001672 <copyout>
    80004efc:	0a054663          	bltz	a0,80004fa8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f00:	058ab783          	ld	a5,88(s5)
    80004f04:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f08:	df843783          	ld	a5,-520(s0)
    80004f0c:	0007c703          	lbu	a4,0(a5)
    80004f10:	cf11                	beqz	a4,80004f2c <exec+0x282>
    80004f12:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f14:	02f00693          	li	a3,47
    80004f18:	a039                	j	80004f26 <exec+0x27c>
      last = s+1;
    80004f1a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f1e:	0785                	addi	a5,a5,1
    80004f20:	fff7c703          	lbu	a4,-1(a5)
    80004f24:	c701                	beqz	a4,80004f2c <exec+0x282>
    if(*s == '/')
    80004f26:	fed71ce3          	bne	a4,a3,80004f1e <exec+0x274>
    80004f2a:	bfc5                	j	80004f1a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f2c:	4641                	li	a2,16
    80004f2e:	df843583          	ld	a1,-520(s0)
    80004f32:	158a8513          	addi	a0,s5,344
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	efc080e7          	jalr	-260(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f3e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f42:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f46:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f4a:	058ab783          	ld	a5,88(s5)
    80004f4e:	e6843703          	ld	a4,-408(s0)
    80004f52:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f54:	058ab783          	ld	a5,88(s5)
    80004f58:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f5c:	85ea                	mv	a1,s10
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	d4e080e7          	jalr	-690(ra) # 80001cac <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f66:	0004851b          	sext.w	a0,s1
    80004f6a:	bbe1                	j	80004d42 <exec+0x98>
    80004f6c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f70:	e0843583          	ld	a1,-504(s0)
    80004f74:	855e                	mv	a0,s7
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	d36080e7          	jalr	-714(ra) # 80001cac <proc_freepagetable>
  if(ip){
    80004f7e:	da0498e3          	bnez	s1,80004d2e <exec+0x84>
  return -1;
    80004f82:	557d                	li	a0,-1
    80004f84:	bb7d                	j	80004d42 <exec+0x98>
    80004f86:	e1243423          	sd	s2,-504(s0)
    80004f8a:	b7dd                	j	80004f70 <exec+0x2c6>
    80004f8c:	e1243423          	sd	s2,-504(s0)
    80004f90:	b7c5                	j	80004f70 <exec+0x2c6>
    80004f92:	e1243423          	sd	s2,-504(s0)
    80004f96:	bfe9                	j	80004f70 <exec+0x2c6>
  sz = sz1;
    80004f98:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f9c:	4481                	li	s1,0
    80004f9e:	bfc9                	j	80004f70 <exec+0x2c6>
  sz = sz1;
    80004fa0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa4:	4481                	li	s1,0
    80004fa6:	b7e9                	j	80004f70 <exec+0x2c6>
  sz = sz1;
    80004fa8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fac:	4481                	li	s1,0
    80004fae:	b7c9                	j	80004f70 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb4:	2b05                	addiw	s6,s6,1
    80004fb6:	0389899b          	addiw	s3,s3,56
    80004fba:	e8845783          	lhu	a5,-376(s0)
    80004fbe:	e2fb5be3          	bge	s6,a5,80004df4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fc2:	2981                	sext.w	s3,s3
    80004fc4:	03800713          	li	a4,56
    80004fc8:	86ce                	mv	a3,s3
    80004fca:	e1840613          	addi	a2,s0,-488
    80004fce:	4581                	li	a1,0
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	a8e080e7          	jalr	-1394(ra) # 80003a60 <readi>
    80004fda:	03800793          	li	a5,56
    80004fde:	f8f517e3          	bne	a0,a5,80004f6c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fe2:	e1842783          	lw	a5,-488(s0)
    80004fe6:	4705                	li	a4,1
    80004fe8:	fce796e3          	bne	a5,a4,80004fb4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fec:	e4043603          	ld	a2,-448(s0)
    80004ff0:	e3843783          	ld	a5,-456(s0)
    80004ff4:	f8f669e3          	bltu	a2,a5,80004f86 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ff8:	e2843783          	ld	a5,-472(s0)
    80004ffc:	963e                	add	a2,a2,a5
    80004ffe:	f8f667e3          	bltu	a2,a5,80004f8c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005002:	85ca                	mv	a1,s2
    80005004:	855e                	mv	a0,s7
    80005006:	ffffc097          	auipc	ra,0xffffc
    8000500a:	41c080e7          	jalr	1052(ra) # 80001422 <uvmalloc>
    8000500e:	e0a43423          	sd	a0,-504(s0)
    80005012:	d141                	beqz	a0,80004f92 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005014:	e2843d03          	ld	s10,-472(s0)
    80005018:	df043783          	ld	a5,-528(s0)
    8000501c:	00fd77b3          	and	a5,s10,a5
    80005020:	fba1                	bnez	a5,80004f70 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005022:	e2042d83          	lw	s11,-480(s0)
    80005026:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000502a:	f80c03e3          	beqz	s8,80004fb0 <exec+0x306>
    8000502e:	8a62                	mv	s4,s8
    80005030:	4901                	li	s2,0
    80005032:	b345                	j	80004dd2 <exec+0x128>

0000000080005034 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005034:	7179                	addi	sp,sp,-48
    80005036:	f406                	sd	ra,40(sp)
    80005038:	f022                	sd	s0,32(sp)
    8000503a:	ec26                	sd	s1,24(sp)
    8000503c:	e84a                	sd	s2,16(sp)
    8000503e:	1800                	addi	s0,sp,48
    80005040:	892e                	mv	s2,a1
    80005042:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005044:	fdc40593          	addi	a1,s0,-36
    80005048:	ffffe097          	auipc	ra,0xffffe
    8000504c:	bf2080e7          	jalr	-1038(ra) # 80002c3a <argint>
    80005050:	04054063          	bltz	a0,80005090 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005054:	fdc42703          	lw	a4,-36(s0)
    80005058:	47bd                	li	a5,15
    8000505a:	02e7ed63          	bltu	a5,a4,80005094 <argfd+0x60>
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	af2080e7          	jalr	-1294(ra) # 80001b50 <myproc>
    80005066:	fdc42703          	lw	a4,-36(s0)
    8000506a:	01a70793          	addi	a5,a4,26
    8000506e:	078e                	slli	a5,a5,0x3
    80005070:	953e                	add	a0,a0,a5
    80005072:	611c                	ld	a5,0(a0)
    80005074:	c395                	beqz	a5,80005098 <argfd+0x64>
    return -1;
  if(pfd)
    80005076:	00090463          	beqz	s2,8000507e <argfd+0x4a>
    *pfd = fd;
    8000507a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000507e:	4501                	li	a0,0
  if(pf)
    80005080:	c091                	beqz	s1,80005084 <argfd+0x50>
    *pf = f;
    80005082:	e09c                	sd	a5,0(s1)
}
    80005084:	70a2                	ld	ra,40(sp)
    80005086:	7402                	ld	s0,32(sp)
    80005088:	64e2                	ld	s1,24(sp)
    8000508a:	6942                	ld	s2,16(sp)
    8000508c:	6145                	addi	sp,sp,48
    8000508e:	8082                	ret
    return -1;
    80005090:	557d                	li	a0,-1
    80005092:	bfcd                	j	80005084 <argfd+0x50>
    return -1;
    80005094:	557d                	li	a0,-1
    80005096:	b7fd                	j	80005084 <argfd+0x50>
    80005098:	557d                	li	a0,-1
    8000509a:	b7ed                	j	80005084 <argfd+0x50>

000000008000509c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000509c:	1101                	addi	sp,sp,-32
    8000509e:	ec06                	sd	ra,24(sp)
    800050a0:	e822                	sd	s0,16(sp)
    800050a2:	e426                	sd	s1,8(sp)
    800050a4:	1000                	addi	s0,sp,32
    800050a6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	aa8080e7          	jalr	-1368(ra) # 80001b50 <myproc>
    800050b0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050b2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050b6:	4501                	li	a0,0
    800050b8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ba:	6398                	ld	a4,0(a5)
    800050bc:	cb19                	beqz	a4,800050d2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050be:	2505                	addiw	a0,a0,1
    800050c0:	07a1                	addi	a5,a5,8
    800050c2:	fed51ce3          	bne	a0,a3,800050ba <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050c6:	557d                	li	a0,-1
}
    800050c8:	60e2                	ld	ra,24(sp)
    800050ca:	6442                	ld	s0,16(sp)
    800050cc:	64a2                	ld	s1,8(sp)
    800050ce:	6105                	addi	sp,sp,32
    800050d0:	8082                	ret
      p->ofile[fd] = f;
    800050d2:	01a50793          	addi	a5,a0,26
    800050d6:	078e                	slli	a5,a5,0x3
    800050d8:	963e                	add	a2,a2,a5
    800050da:	e204                	sd	s1,0(a2)
      return fd;
    800050dc:	b7f5                	j	800050c8 <fdalloc+0x2c>

00000000800050de <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050de:	715d                	addi	sp,sp,-80
    800050e0:	e486                	sd	ra,72(sp)
    800050e2:	e0a2                	sd	s0,64(sp)
    800050e4:	fc26                	sd	s1,56(sp)
    800050e6:	f84a                	sd	s2,48(sp)
    800050e8:	f44e                	sd	s3,40(sp)
    800050ea:	f052                	sd	s4,32(sp)
    800050ec:	ec56                	sd	s5,24(sp)
    800050ee:	0880                	addi	s0,sp,80
    800050f0:	89ae                	mv	s3,a1
    800050f2:	8ab2                	mv	s5,a2
    800050f4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050f6:	fb040593          	addi	a1,s0,-80
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	e86080e7          	jalr	-378(ra) # 80003f80 <nameiparent>
    80005102:	892a                	mv	s2,a0
    80005104:	12050f63          	beqz	a0,80005242 <create+0x164>
    return 0;

  ilock(dp);
    80005108:	ffffe097          	auipc	ra,0xffffe
    8000510c:	6a4080e7          	jalr	1700(ra) # 800037ac <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005110:	4601                	li	a2,0
    80005112:	fb040593          	addi	a1,s0,-80
    80005116:	854a                	mv	a0,s2
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	b78080e7          	jalr	-1160(ra) # 80003c90 <dirlookup>
    80005120:	84aa                	mv	s1,a0
    80005122:	c921                	beqz	a0,80005172 <create+0x94>
    iunlockput(dp);
    80005124:	854a                	mv	a0,s2
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	8e8080e7          	jalr	-1816(ra) # 80003a0e <iunlockput>
    ilock(ip);
    8000512e:	8526                	mv	a0,s1
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	67c080e7          	jalr	1660(ra) # 800037ac <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005138:	2981                	sext.w	s3,s3
    8000513a:	4789                	li	a5,2
    8000513c:	02f99463          	bne	s3,a5,80005164 <create+0x86>
    80005140:	0444d783          	lhu	a5,68(s1)
    80005144:	37f9                	addiw	a5,a5,-2
    80005146:	17c2                	slli	a5,a5,0x30
    80005148:	93c1                	srli	a5,a5,0x30
    8000514a:	4705                	li	a4,1
    8000514c:	00f76c63          	bltu	a4,a5,80005164 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005150:	8526                	mv	a0,s1
    80005152:	60a6                	ld	ra,72(sp)
    80005154:	6406                	ld	s0,64(sp)
    80005156:	74e2                	ld	s1,56(sp)
    80005158:	7942                	ld	s2,48(sp)
    8000515a:	79a2                	ld	s3,40(sp)
    8000515c:	7a02                	ld	s4,32(sp)
    8000515e:	6ae2                	ld	s5,24(sp)
    80005160:	6161                	addi	sp,sp,80
    80005162:	8082                	ret
    iunlockput(ip);
    80005164:	8526                	mv	a0,s1
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	8a8080e7          	jalr	-1880(ra) # 80003a0e <iunlockput>
    return 0;
    8000516e:	4481                	li	s1,0
    80005170:	b7c5                	j	80005150 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005172:	85ce                	mv	a1,s3
    80005174:	00092503          	lw	a0,0(s2)
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	49c080e7          	jalr	1180(ra) # 80003614 <ialloc>
    80005180:	84aa                	mv	s1,a0
    80005182:	c529                	beqz	a0,800051cc <create+0xee>
  ilock(ip);
    80005184:	ffffe097          	auipc	ra,0xffffe
    80005188:	628080e7          	jalr	1576(ra) # 800037ac <ilock>
  ip->major = major;
    8000518c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005190:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005194:	4785                	li	a5,1
    80005196:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000519a:	8526                	mv	a0,s1
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	546080e7          	jalr	1350(ra) # 800036e2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051a4:	2981                	sext.w	s3,s3
    800051a6:	4785                	li	a5,1
    800051a8:	02f98a63          	beq	s3,a5,800051dc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ac:	40d0                	lw	a2,4(s1)
    800051ae:	fb040593          	addi	a1,s0,-80
    800051b2:	854a                	mv	a0,s2
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	cec080e7          	jalr	-788(ra) # 80003ea0 <dirlink>
    800051bc:	06054b63          	bltz	a0,80005232 <create+0x154>
  iunlockput(dp);
    800051c0:	854a                	mv	a0,s2
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	84c080e7          	jalr	-1972(ra) # 80003a0e <iunlockput>
  return ip;
    800051ca:	b759                	j	80005150 <create+0x72>
    panic("create: ialloc");
    800051cc:	00003517          	auipc	a0,0x3
    800051d0:	52c50513          	addi	a0,a0,1324 # 800086f8 <syscalls+0x2a0>
    800051d4:	ffffb097          	auipc	ra,0xffffb
    800051d8:	36a080e7          	jalr	874(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051dc:	04a95783          	lhu	a5,74(s2)
    800051e0:	2785                	addiw	a5,a5,1
    800051e2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051e6:	854a                	mv	a0,s2
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	4fa080e7          	jalr	1274(ra) # 800036e2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f0:	40d0                	lw	a2,4(s1)
    800051f2:	00003597          	auipc	a1,0x3
    800051f6:	51658593          	addi	a1,a1,1302 # 80008708 <syscalls+0x2b0>
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	ca4080e7          	jalr	-860(ra) # 80003ea0 <dirlink>
    80005204:	00054f63          	bltz	a0,80005222 <create+0x144>
    80005208:	00492603          	lw	a2,4(s2)
    8000520c:	00003597          	auipc	a1,0x3
    80005210:	50458593          	addi	a1,a1,1284 # 80008710 <syscalls+0x2b8>
    80005214:	8526                	mv	a0,s1
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	c8a080e7          	jalr	-886(ra) # 80003ea0 <dirlink>
    8000521e:	f80557e3          	bgez	a0,800051ac <create+0xce>
      panic("create dots");
    80005222:	00003517          	auipc	a0,0x3
    80005226:	4f650513          	addi	a0,a0,1270 # 80008718 <syscalls+0x2c0>
    8000522a:	ffffb097          	auipc	ra,0xffffb
    8000522e:	314080e7          	jalr	788(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005232:	00003517          	auipc	a0,0x3
    80005236:	4f650513          	addi	a0,a0,1270 # 80008728 <syscalls+0x2d0>
    8000523a:	ffffb097          	auipc	ra,0xffffb
    8000523e:	304080e7          	jalr	772(ra) # 8000053e <panic>
    return 0;
    80005242:	84aa                	mv	s1,a0
    80005244:	b731                	j	80005150 <create+0x72>

0000000080005246 <sys_dup>:
{
    80005246:	7179                	addi	sp,sp,-48
    80005248:	f406                	sd	ra,40(sp)
    8000524a:	f022                	sd	s0,32(sp)
    8000524c:	ec26                	sd	s1,24(sp)
    8000524e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005250:	fd840613          	addi	a2,s0,-40
    80005254:	4581                	li	a1,0
    80005256:	4501                	li	a0,0
    80005258:	00000097          	auipc	ra,0x0
    8000525c:	ddc080e7          	jalr	-548(ra) # 80005034 <argfd>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005262:	02054363          	bltz	a0,80005288 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005266:	fd843503          	ld	a0,-40(s0)
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	e32080e7          	jalr	-462(ra) # 8000509c <fdalloc>
    80005272:	84aa                	mv	s1,a0
    return -1;
    80005274:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005276:	00054963          	bltz	a0,80005288 <sys_dup+0x42>
  filedup(f);
    8000527a:	fd843503          	ld	a0,-40(s0)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	37a080e7          	jalr	890(ra) # 800045f8 <filedup>
  return fd;
    80005286:	87a6                	mv	a5,s1
}
    80005288:	853e                	mv	a0,a5
    8000528a:	70a2                	ld	ra,40(sp)
    8000528c:	7402                	ld	s0,32(sp)
    8000528e:	64e2                	ld	s1,24(sp)
    80005290:	6145                	addi	sp,sp,48
    80005292:	8082                	ret

0000000080005294 <sys_read>:
{
    80005294:	7179                	addi	sp,sp,-48
    80005296:	f406                	sd	ra,40(sp)
    80005298:	f022                	sd	s0,32(sp)
    8000529a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529c:	fe840613          	addi	a2,s0,-24
    800052a0:	4581                	li	a1,0
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	d90080e7          	jalr	-624(ra) # 80005034 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	04054163          	bltz	a0,800052f0 <sys_read+0x5c>
    800052b2:	fe440593          	addi	a1,s0,-28
    800052b6:	4509                	li	a0,2
    800052b8:	ffffe097          	auipc	ra,0xffffe
    800052bc:	982080e7          	jalr	-1662(ra) # 80002c3a <argint>
    return -1;
    800052c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c2:	02054763          	bltz	a0,800052f0 <sys_read+0x5c>
    800052c6:	fd840593          	addi	a1,s0,-40
    800052ca:	4505                	li	a0,1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	990080e7          	jalr	-1648(ra) # 80002c5c <argaddr>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d6:	00054d63          	bltz	a0,800052f0 <sys_read+0x5c>
  return fileread(f, p, n);
    800052da:	fe442603          	lw	a2,-28(s0)
    800052de:	fd843583          	ld	a1,-40(s0)
    800052e2:	fe843503          	ld	a0,-24(s0)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	49e080e7          	jalr	1182(ra) # 80004784 <fileread>
    800052ee:	87aa                	mv	a5,a0
}
    800052f0:	853e                	mv	a0,a5
    800052f2:	70a2                	ld	ra,40(sp)
    800052f4:	7402                	ld	s0,32(sp)
    800052f6:	6145                	addi	sp,sp,48
    800052f8:	8082                	ret

00000000800052fa <sys_write>:
{
    800052fa:	7179                	addi	sp,sp,-48
    800052fc:	f406                	sd	ra,40(sp)
    800052fe:	f022                	sd	s0,32(sp)
    80005300:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005302:	fe840613          	addi	a2,s0,-24
    80005306:	4581                	li	a1,0
    80005308:	4501                	li	a0,0
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	d2a080e7          	jalr	-726(ra) # 80005034 <argfd>
    return -1;
    80005312:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	04054163          	bltz	a0,80005356 <sys_write+0x5c>
    80005318:	fe440593          	addi	a1,s0,-28
    8000531c:	4509                	li	a0,2
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	91c080e7          	jalr	-1764(ra) # 80002c3a <argint>
    return -1;
    80005326:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005328:	02054763          	bltz	a0,80005356 <sys_write+0x5c>
    8000532c:	fd840593          	addi	a1,s0,-40
    80005330:	4505                	li	a0,1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	92a080e7          	jalr	-1750(ra) # 80002c5c <argaddr>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533c:	00054d63          	bltz	a0,80005356 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005340:	fe442603          	lw	a2,-28(s0)
    80005344:	fd843583          	ld	a1,-40(s0)
    80005348:	fe843503          	ld	a0,-24(s0)
    8000534c:	fffff097          	auipc	ra,0xfffff
    80005350:	4fa080e7          	jalr	1274(ra) # 80004846 <filewrite>
    80005354:	87aa                	mv	a5,a0
}
    80005356:	853e                	mv	a0,a5
    80005358:	70a2                	ld	ra,40(sp)
    8000535a:	7402                	ld	s0,32(sp)
    8000535c:	6145                	addi	sp,sp,48
    8000535e:	8082                	ret

0000000080005360 <sys_close>:
{
    80005360:	1101                	addi	sp,sp,-32
    80005362:	ec06                	sd	ra,24(sp)
    80005364:	e822                	sd	s0,16(sp)
    80005366:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005368:	fe040613          	addi	a2,s0,-32
    8000536c:	fec40593          	addi	a1,s0,-20
    80005370:	4501                	li	a0,0
    80005372:	00000097          	auipc	ra,0x0
    80005376:	cc2080e7          	jalr	-830(ra) # 80005034 <argfd>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000537c:	02054463          	bltz	a0,800053a4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	7d0080e7          	jalr	2000(ra) # 80001b50 <myproc>
    80005388:	fec42783          	lw	a5,-20(s0)
    8000538c:	07e9                	addi	a5,a5,26
    8000538e:	078e                	slli	a5,a5,0x3
    80005390:	97aa                	add	a5,a5,a0
    80005392:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005396:	fe043503          	ld	a0,-32(s0)
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	2b0080e7          	jalr	688(ra) # 8000464a <fileclose>
  return 0;
    800053a2:	4781                	li	a5,0
}
    800053a4:	853e                	mv	a0,a5
    800053a6:	60e2                	ld	ra,24(sp)
    800053a8:	6442                	ld	s0,16(sp)
    800053aa:	6105                	addi	sp,sp,32
    800053ac:	8082                	ret

00000000800053ae <sys_fstat>:
{
    800053ae:	1101                	addi	sp,sp,-32
    800053b0:	ec06                	sd	ra,24(sp)
    800053b2:	e822                	sd	s0,16(sp)
    800053b4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b6:	fe840613          	addi	a2,s0,-24
    800053ba:	4581                	li	a1,0
    800053bc:	4501                	li	a0,0
    800053be:	00000097          	auipc	ra,0x0
    800053c2:	c76080e7          	jalr	-906(ra) # 80005034 <argfd>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c8:	02054563          	bltz	a0,800053f2 <sys_fstat+0x44>
    800053cc:	fe040593          	addi	a1,s0,-32
    800053d0:	4505                	li	a0,1
    800053d2:	ffffe097          	auipc	ra,0xffffe
    800053d6:	88a080e7          	jalr	-1910(ra) # 80002c5c <argaddr>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053dc:	00054b63          	bltz	a0,800053f2 <sys_fstat+0x44>
  return filestat(f, st);
    800053e0:	fe043583          	ld	a1,-32(s0)
    800053e4:	fe843503          	ld	a0,-24(s0)
    800053e8:	fffff097          	auipc	ra,0xfffff
    800053ec:	32a080e7          	jalr	810(ra) # 80004712 <filestat>
    800053f0:	87aa                	mv	a5,a0
}
    800053f2:	853e                	mv	a0,a5
    800053f4:	60e2                	ld	ra,24(sp)
    800053f6:	6442                	ld	s0,16(sp)
    800053f8:	6105                	addi	sp,sp,32
    800053fa:	8082                	ret

00000000800053fc <sys_link>:
{
    800053fc:	7169                	addi	sp,sp,-304
    800053fe:	f606                	sd	ra,296(sp)
    80005400:	f222                	sd	s0,288(sp)
    80005402:	ee26                	sd	s1,280(sp)
    80005404:	ea4a                	sd	s2,272(sp)
    80005406:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005408:	08000613          	li	a2,128
    8000540c:	ed040593          	addi	a1,s0,-304
    80005410:	4501                	li	a0,0
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	86c080e7          	jalr	-1940(ra) # 80002c7e <argstr>
    return -1;
    8000541a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541c:	10054e63          	bltz	a0,80005538 <sys_link+0x13c>
    80005420:	08000613          	li	a2,128
    80005424:	f5040593          	addi	a1,s0,-176
    80005428:	4505                	li	a0,1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	854080e7          	jalr	-1964(ra) # 80002c7e <argstr>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005434:	10054263          	bltz	a0,80005538 <sys_link+0x13c>
  begin_op();
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	d46080e7          	jalr	-698(ra) # 8000417e <begin_op>
  if((ip = namei(old)) == 0){
    80005440:	ed040513          	addi	a0,s0,-304
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	b1e080e7          	jalr	-1250(ra) # 80003f62 <namei>
    8000544c:	84aa                	mv	s1,a0
    8000544e:	c551                	beqz	a0,800054da <sys_link+0xde>
  ilock(ip);
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	35c080e7          	jalr	860(ra) # 800037ac <ilock>
  if(ip->type == T_DIR){
    80005458:	04449703          	lh	a4,68(s1)
    8000545c:	4785                	li	a5,1
    8000545e:	08f70463          	beq	a4,a5,800054e6 <sys_link+0xea>
  ip->nlink++;
    80005462:	04a4d783          	lhu	a5,74(s1)
    80005466:	2785                	addiw	a5,a5,1
    80005468:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	274080e7          	jalr	628(ra) # 800036e2 <iupdate>
  iunlock(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	3f6080e7          	jalr	1014(ra) # 8000386e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005480:	fd040593          	addi	a1,s0,-48
    80005484:	f5040513          	addi	a0,s0,-176
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	af8080e7          	jalr	-1288(ra) # 80003f80 <nameiparent>
    80005490:	892a                	mv	s2,a0
    80005492:	c935                	beqz	a0,80005506 <sys_link+0x10a>
  ilock(dp);
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	318080e7          	jalr	792(ra) # 800037ac <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000549c:	00092703          	lw	a4,0(s2)
    800054a0:	409c                	lw	a5,0(s1)
    800054a2:	04f71d63          	bne	a4,a5,800054fc <sys_link+0x100>
    800054a6:	40d0                	lw	a2,4(s1)
    800054a8:	fd040593          	addi	a1,s0,-48
    800054ac:	854a                	mv	a0,s2
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	9f2080e7          	jalr	-1550(ra) # 80003ea0 <dirlink>
    800054b6:	04054363          	bltz	a0,800054fc <sys_link+0x100>
  iunlockput(dp);
    800054ba:	854a                	mv	a0,s2
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	552080e7          	jalr	1362(ra) # 80003a0e <iunlockput>
  iput(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	4a0080e7          	jalr	1184(ra) # 80003966 <iput>
  end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	d30080e7          	jalr	-720(ra) # 800041fe <end_op>
  return 0;
    800054d6:	4781                	li	a5,0
    800054d8:	a085                	j	80005538 <sys_link+0x13c>
    end_op();
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	d24080e7          	jalr	-732(ra) # 800041fe <end_op>
    return -1;
    800054e2:	57fd                	li	a5,-1
    800054e4:	a891                	j	80005538 <sys_link+0x13c>
    iunlockput(ip);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	526080e7          	jalr	1318(ra) # 80003a0e <iunlockput>
    end_op();
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	d0e080e7          	jalr	-754(ra) # 800041fe <end_op>
    return -1;
    800054f8:	57fd                	li	a5,-1
    800054fa:	a83d                	j	80005538 <sys_link+0x13c>
    iunlockput(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	510080e7          	jalr	1296(ra) # 80003a0e <iunlockput>
  ilock(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	2a4080e7          	jalr	676(ra) # 800037ac <ilock>
  ip->nlink--;
    80005510:	04a4d783          	lhu	a5,74(s1)
    80005514:	37fd                	addiw	a5,a5,-1
    80005516:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	1c6080e7          	jalr	454(ra) # 800036e2 <iupdate>
  iunlockput(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	4e8080e7          	jalr	1256(ra) # 80003a0e <iunlockput>
  end_op();
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	cd0080e7          	jalr	-816(ra) # 800041fe <end_op>
  return -1;
    80005536:	57fd                	li	a5,-1
}
    80005538:	853e                	mv	a0,a5
    8000553a:	70b2                	ld	ra,296(sp)
    8000553c:	7412                	ld	s0,288(sp)
    8000553e:	64f2                	ld	s1,280(sp)
    80005540:	6952                	ld	s2,272(sp)
    80005542:	6155                	addi	sp,sp,304
    80005544:	8082                	ret

0000000080005546 <sys_unlink>:
{
    80005546:	7151                	addi	sp,sp,-240
    80005548:	f586                	sd	ra,232(sp)
    8000554a:	f1a2                	sd	s0,224(sp)
    8000554c:	eda6                	sd	s1,216(sp)
    8000554e:	e9ca                	sd	s2,208(sp)
    80005550:	e5ce                	sd	s3,200(sp)
    80005552:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005554:	08000613          	li	a2,128
    80005558:	f3040593          	addi	a1,s0,-208
    8000555c:	4501                	li	a0,0
    8000555e:	ffffd097          	auipc	ra,0xffffd
    80005562:	720080e7          	jalr	1824(ra) # 80002c7e <argstr>
    80005566:	18054163          	bltz	a0,800056e8 <sys_unlink+0x1a2>
  begin_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	c14080e7          	jalr	-1004(ra) # 8000417e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005572:	fb040593          	addi	a1,s0,-80
    80005576:	f3040513          	addi	a0,s0,-208
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	a06080e7          	jalr	-1530(ra) # 80003f80 <nameiparent>
    80005582:	84aa                	mv	s1,a0
    80005584:	c979                	beqz	a0,8000565a <sys_unlink+0x114>
  ilock(dp);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	226080e7          	jalr	550(ra) # 800037ac <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000558e:	00003597          	auipc	a1,0x3
    80005592:	17a58593          	addi	a1,a1,378 # 80008708 <syscalls+0x2b0>
    80005596:	fb040513          	addi	a0,s0,-80
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	6dc080e7          	jalr	1756(ra) # 80003c76 <namecmp>
    800055a2:	14050a63          	beqz	a0,800056f6 <sys_unlink+0x1b0>
    800055a6:	00003597          	auipc	a1,0x3
    800055aa:	16a58593          	addi	a1,a1,362 # 80008710 <syscalls+0x2b8>
    800055ae:	fb040513          	addi	a0,s0,-80
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	6c4080e7          	jalr	1732(ra) # 80003c76 <namecmp>
    800055ba:	12050e63          	beqz	a0,800056f6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055be:	f2c40613          	addi	a2,s0,-212
    800055c2:	fb040593          	addi	a1,s0,-80
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	6c8080e7          	jalr	1736(ra) # 80003c90 <dirlookup>
    800055d0:	892a                	mv	s2,a0
    800055d2:	12050263          	beqz	a0,800056f6 <sys_unlink+0x1b0>
  ilock(ip);
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	1d6080e7          	jalr	470(ra) # 800037ac <ilock>
  if(ip->nlink < 1)
    800055de:	04a91783          	lh	a5,74(s2)
    800055e2:	08f05263          	blez	a5,80005666 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055e6:	04491703          	lh	a4,68(s2)
    800055ea:	4785                	li	a5,1
    800055ec:	08f70563          	beq	a4,a5,80005676 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055f0:	4641                	li	a2,16
    800055f2:	4581                	li	a1,0
    800055f4:	fc040513          	addi	a0,s0,-64
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	6e8080e7          	jalr	1768(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005600:	4741                	li	a4,16
    80005602:	f2c42683          	lw	a3,-212(s0)
    80005606:	fc040613          	addi	a2,s0,-64
    8000560a:	4581                	li	a1,0
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	54a080e7          	jalr	1354(ra) # 80003b58 <writei>
    80005616:	47c1                	li	a5,16
    80005618:	0af51563          	bne	a0,a5,800056c2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000561c:	04491703          	lh	a4,68(s2)
    80005620:	4785                	li	a5,1
    80005622:	0af70863          	beq	a4,a5,800056d2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	3e6080e7          	jalr	998(ra) # 80003a0e <iunlockput>
  ip->nlink--;
    80005630:	04a95783          	lhu	a5,74(s2)
    80005634:	37fd                	addiw	a5,a5,-1
    80005636:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000563a:	854a                	mv	a0,s2
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	0a6080e7          	jalr	166(ra) # 800036e2 <iupdate>
  iunlockput(ip);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3c8080e7          	jalr	968(ra) # 80003a0e <iunlockput>
  end_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	bb0080e7          	jalr	-1104(ra) # 800041fe <end_op>
  return 0;
    80005656:	4501                	li	a0,0
    80005658:	a84d                	j	8000570a <sys_unlink+0x1c4>
    end_op();
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	ba4080e7          	jalr	-1116(ra) # 800041fe <end_op>
    return -1;
    80005662:	557d                	li	a0,-1
    80005664:	a05d                	j	8000570a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005666:	00003517          	auipc	a0,0x3
    8000566a:	0d250513          	addi	a0,a0,210 # 80008738 <syscalls+0x2e0>
    8000566e:	ffffb097          	auipc	ra,0xffffb
    80005672:	ed0080e7          	jalr	-304(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005676:	04c92703          	lw	a4,76(s2)
    8000567a:	02000793          	li	a5,32
    8000567e:	f6e7f9e3          	bgeu	a5,a4,800055f0 <sys_unlink+0xaa>
    80005682:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005686:	4741                	li	a4,16
    80005688:	86ce                	mv	a3,s3
    8000568a:	f1840613          	addi	a2,s0,-232
    8000568e:	4581                	li	a1,0
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	3ce080e7          	jalr	974(ra) # 80003a60 <readi>
    8000569a:	47c1                	li	a5,16
    8000569c:	00f51b63          	bne	a0,a5,800056b2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056a0:	f1845783          	lhu	a5,-232(s0)
    800056a4:	e7a1                	bnez	a5,800056ec <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a6:	29c1                	addiw	s3,s3,16
    800056a8:	04c92783          	lw	a5,76(s2)
    800056ac:	fcf9ede3          	bltu	s3,a5,80005686 <sys_unlink+0x140>
    800056b0:	b781                	j	800055f0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056b2:	00003517          	auipc	a0,0x3
    800056b6:	09e50513          	addi	a0,a0,158 # 80008750 <syscalls+0x2f8>
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	e84080e7          	jalr	-380(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056c2:	00003517          	auipc	a0,0x3
    800056c6:	0a650513          	addi	a0,a0,166 # 80008768 <syscalls+0x310>
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	e74080e7          	jalr	-396(ra) # 8000053e <panic>
    dp->nlink--;
    800056d2:	04a4d783          	lhu	a5,74(s1)
    800056d6:	37fd                	addiw	a5,a5,-1
    800056d8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	004080e7          	jalr	4(ra) # 800036e2 <iupdate>
    800056e6:	b781                	j	80005626 <sys_unlink+0xe0>
    return -1;
    800056e8:	557d                	li	a0,-1
    800056ea:	a005                	j	8000570a <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ec:	854a                	mv	a0,s2
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	320080e7          	jalr	800(ra) # 80003a0e <iunlockput>
  iunlockput(dp);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	316080e7          	jalr	790(ra) # 80003a0e <iunlockput>
  end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	afe080e7          	jalr	-1282(ra) # 800041fe <end_op>
  return -1;
    80005708:	557d                	li	a0,-1
}
    8000570a:	70ae                	ld	ra,232(sp)
    8000570c:	740e                	ld	s0,224(sp)
    8000570e:	64ee                	ld	s1,216(sp)
    80005710:	694e                	ld	s2,208(sp)
    80005712:	69ae                	ld	s3,200(sp)
    80005714:	616d                	addi	sp,sp,240
    80005716:	8082                	ret

0000000080005718 <sys_open>:

uint64
sys_open(void)
{
    80005718:	7131                	addi	sp,sp,-192
    8000571a:	fd06                	sd	ra,184(sp)
    8000571c:	f922                	sd	s0,176(sp)
    8000571e:	f526                	sd	s1,168(sp)
    80005720:	f14a                	sd	s2,160(sp)
    80005722:	ed4e                	sd	s3,152(sp)
    80005724:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005726:	08000613          	li	a2,128
    8000572a:	f5040593          	addi	a1,s0,-176
    8000572e:	4501                	li	a0,0
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	54e080e7          	jalr	1358(ra) # 80002c7e <argstr>
    return -1;
    80005738:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000573a:	0c054163          	bltz	a0,800057fc <sys_open+0xe4>
    8000573e:	f4c40593          	addi	a1,s0,-180
    80005742:	4505                	li	a0,1
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	4f6080e7          	jalr	1270(ra) # 80002c3a <argint>
    8000574c:	0a054863          	bltz	a0,800057fc <sys_open+0xe4>

  begin_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	a2e080e7          	jalr	-1490(ra) # 8000417e <begin_op>

  if(omode & O_CREATE){
    80005758:	f4c42783          	lw	a5,-180(s0)
    8000575c:	2007f793          	andi	a5,a5,512
    80005760:	cbdd                	beqz	a5,80005816 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005762:	4681                	li	a3,0
    80005764:	4601                	li	a2,0
    80005766:	4589                	li	a1,2
    80005768:	f5040513          	addi	a0,s0,-176
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	972080e7          	jalr	-1678(ra) # 800050de <create>
    80005774:	892a                	mv	s2,a0
    if(ip == 0){
    80005776:	c959                	beqz	a0,8000580c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005778:	04491703          	lh	a4,68(s2)
    8000577c:	478d                	li	a5,3
    8000577e:	00f71763          	bne	a4,a5,8000578c <sys_open+0x74>
    80005782:	04695703          	lhu	a4,70(s2)
    80005786:	47a5                	li	a5,9
    80005788:	0ce7ec63          	bltu	a5,a4,80005860 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	e02080e7          	jalr	-510(ra) # 8000458e <filealloc>
    80005794:	89aa                	mv	s3,a0
    80005796:	10050263          	beqz	a0,8000589a <sys_open+0x182>
    8000579a:	00000097          	auipc	ra,0x0
    8000579e:	902080e7          	jalr	-1790(ra) # 8000509c <fdalloc>
    800057a2:	84aa                	mv	s1,a0
    800057a4:	0e054663          	bltz	a0,80005890 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057a8:	04491703          	lh	a4,68(s2)
    800057ac:	478d                	li	a5,3
    800057ae:	0cf70463          	beq	a4,a5,80005876 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057b2:	4789                	li	a5,2
    800057b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057bc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057c0:	f4c42783          	lw	a5,-180(s0)
    800057c4:	0017c713          	xori	a4,a5,1
    800057c8:	8b05                	andi	a4,a4,1
    800057ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ce:	0037f713          	andi	a4,a5,3
    800057d2:	00e03733          	snez	a4,a4
    800057d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057da:	4007f793          	andi	a5,a5,1024
    800057de:	c791                	beqz	a5,800057ea <sys_open+0xd2>
    800057e0:	04491703          	lh	a4,68(s2)
    800057e4:	4789                	li	a5,2
    800057e6:	08f70f63          	beq	a4,a5,80005884 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ea:	854a                	mv	a0,s2
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	082080e7          	jalr	130(ra) # 8000386e <iunlock>
  end_op();
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	a0a080e7          	jalr	-1526(ra) # 800041fe <end_op>

  return fd;
}
    800057fc:	8526                	mv	a0,s1
    800057fe:	70ea                	ld	ra,184(sp)
    80005800:	744a                	ld	s0,176(sp)
    80005802:	74aa                	ld	s1,168(sp)
    80005804:	790a                	ld	s2,160(sp)
    80005806:	69ea                	ld	s3,152(sp)
    80005808:	6129                	addi	sp,sp,192
    8000580a:	8082                	ret
      end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	9f2080e7          	jalr	-1550(ra) # 800041fe <end_op>
      return -1;
    80005814:	b7e5                	j	800057fc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	748080e7          	jalr	1864(ra) # 80003f62 <namei>
    80005822:	892a                	mv	s2,a0
    80005824:	c905                	beqz	a0,80005854 <sys_open+0x13c>
    ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	f86080e7          	jalr	-122(ra) # 800037ac <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000582e:	04491703          	lh	a4,68(s2)
    80005832:	4785                	li	a5,1
    80005834:	f4f712e3          	bne	a4,a5,80005778 <sys_open+0x60>
    80005838:	f4c42783          	lw	a5,-180(s0)
    8000583c:	dba1                	beqz	a5,8000578c <sys_open+0x74>
      iunlockput(ip);
    8000583e:	854a                	mv	a0,s2
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	1ce080e7          	jalr	462(ra) # 80003a0e <iunlockput>
      end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	9b6080e7          	jalr	-1610(ra) # 800041fe <end_op>
      return -1;
    80005850:	54fd                	li	s1,-1
    80005852:	b76d                	j	800057fc <sys_open+0xe4>
      end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	9aa080e7          	jalr	-1622(ra) # 800041fe <end_op>
      return -1;
    8000585c:	54fd                	li	s1,-1
    8000585e:	bf79                	j	800057fc <sys_open+0xe4>
    iunlockput(ip);
    80005860:	854a                	mv	a0,s2
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	1ac080e7          	jalr	428(ra) # 80003a0e <iunlockput>
    end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	994080e7          	jalr	-1644(ra) # 800041fe <end_op>
    return -1;
    80005872:	54fd                	li	s1,-1
    80005874:	b761                	j	800057fc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005876:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000587a:	04691783          	lh	a5,70(s2)
    8000587e:	02f99223          	sh	a5,36(s3)
    80005882:	bf2d                	j	800057bc <sys_open+0xa4>
    itrunc(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	034080e7          	jalr	52(ra) # 800038ba <itrunc>
    8000588e:	bfb1                	j	800057ea <sys_open+0xd2>
      fileclose(f);
    80005890:	854e                	mv	a0,s3
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	db8080e7          	jalr	-584(ra) # 8000464a <fileclose>
    iunlockput(ip);
    8000589a:	854a                	mv	a0,s2
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	172080e7          	jalr	370(ra) # 80003a0e <iunlockput>
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	95a080e7          	jalr	-1702(ra) # 800041fe <end_op>
    return -1;
    800058ac:	54fd                	li	s1,-1
    800058ae:	b7b9                	j	800057fc <sys_open+0xe4>

00000000800058b0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058b0:	7175                	addi	sp,sp,-144
    800058b2:	e506                	sd	ra,136(sp)
    800058b4:	e122                	sd	s0,128(sp)
    800058b6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	8c6080e7          	jalr	-1850(ra) # 8000417e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058c0:	08000613          	li	a2,128
    800058c4:	f7040593          	addi	a1,s0,-144
    800058c8:	4501                	li	a0,0
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	3b4080e7          	jalr	948(ra) # 80002c7e <argstr>
    800058d2:	02054963          	bltz	a0,80005904 <sys_mkdir+0x54>
    800058d6:	4681                	li	a3,0
    800058d8:	4601                	li	a2,0
    800058da:	4585                	li	a1,1
    800058dc:	f7040513          	addi	a0,s0,-144
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	7fe080e7          	jalr	2046(ra) # 800050de <create>
    800058e8:	cd11                	beqz	a0,80005904 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	124080e7          	jalr	292(ra) # 80003a0e <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	90c080e7          	jalr	-1780(ra) # 800041fe <end_op>
  return 0;
    800058fa:	4501                	li	a0,0
}
    800058fc:	60aa                	ld	ra,136(sp)
    800058fe:	640a                	ld	s0,128(sp)
    80005900:	6149                	addi	sp,sp,144
    80005902:	8082                	ret
    end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8fa080e7          	jalr	-1798(ra) # 800041fe <end_op>
    return -1;
    8000590c:	557d                	li	a0,-1
    8000590e:	b7fd                	j	800058fc <sys_mkdir+0x4c>

0000000080005910 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005910:	7135                	addi	sp,sp,-160
    80005912:	ed06                	sd	ra,152(sp)
    80005914:	e922                	sd	s0,144(sp)
    80005916:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	866080e7          	jalr	-1946(ra) # 8000417e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005920:	08000613          	li	a2,128
    80005924:	f7040593          	addi	a1,s0,-144
    80005928:	4501                	li	a0,0
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	354080e7          	jalr	852(ra) # 80002c7e <argstr>
    80005932:	04054a63          	bltz	a0,80005986 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005936:	f6c40593          	addi	a1,s0,-148
    8000593a:	4505                	li	a0,1
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	2fe080e7          	jalr	766(ra) # 80002c3a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005944:	04054163          	bltz	a0,80005986 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005948:	f6840593          	addi	a1,s0,-152
    8000594c:	4509                	li	a0,2
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	2ec080e7          	jalr	748(ra) # 80002c3a <argint>
     argint(1, &major) < 0 ||
    80005956:	02054863          	bltz	a0,80005986 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000595a:	f6841683          	lh	a3,-152(s0)
    8000595e:	f6c41603          	lh	a2,-148(s0)
    80005962:	458d                	li	a1,3
    80005964:	f7040513          	addi	a0,s0,-144
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	776080e7          	jalr	1910(ra) # 800050de <create>
     argint(2, &minor) < 0 ||
    80005970:	c919                	beqz	a0,80005986 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	09c080e7          	jalr	156(ra) # 80003a0e <iunlockput>
  end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	884080e7          	jalr	-1916(ra) # 800041fe <end_op>
  return 0;
    80005982:	4501                	li	a0,0
    80005984:	a031                	j	80005990 <sys_mknod+0x80>
    end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	878080e7          	jalr	-1928(ra) # 800041fe <end_op>
    return -1;
    8000598e:	557d                	li	a0,-1
}
    80005990:	60ea                	ld	ra,152(sp)
    80005992:	644a                	ld	s0,144(sp)
    80005994:	610d                	addi	sp,sp,160
    80005996:	8082                	ret

0000000080005998 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005998:	7135                	addi	sp,sp,-160
    8000599a:	ed06                	sd	ra,152(sp)
    8000599c:	e922                	sd	s0,144(sp)
    8000599e:	e526                	sd	s1,136(sp)
    800059a0:	e14a                	sd	s2,128(sp)
    800059a2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059a4:	ffffc097          	auipc	ra,0xffffc
    800059a8:	1ac080e7          	jalr	428(ra) # 80001b50 <myproc>
    800059ac:	892a                	mv	s2,a0
  
  begin_op();
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	7d0080e7          	jalr	2000(ra) # 8000417e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059b6:	08000613          	li	a2,128
    800059ba:	f6040593          	addi	a1,s0,-160
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	2be080e7          	jalr	702(ra) # 80002c7e <argstr>
    800059c8:	04054b63          	bltz	a0,80005a1e <sys_chdir+0x86>
    800059cc:	f6040513          	addi	a0,s0,-160
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	592080e7          	jalr	1426(ra) # 80003f62 <namei>
    800059d8:	84aa                	mv	s1,a0
    800059da:	c131                	beqz	a0,80005a1e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	dd0080e7          	jalr	-560(ra) # 800037ac <ilock>
  if(ip->type != T_DIR){
    800059e4:	04449703          	lh	a4,68(s1)
    800059e8:	4785                	li	a5,1
    800059ea:	04f71063          	bne	a4,a5,80005a2a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	e7e080e7          	jalr	-386(ra) # 8000386e <iunlock>
  iput(p->cwd);
    800059f8:	15093503          	ld	a0,336(s2)
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	f6a080e7          	jalr	-150(ra) # 80003966 <iput>
  end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	7fa080e7          	jalr	2042(ra) # 800041fe <end_op>
  p->cwd = ip;
    80005a0c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a10:	4501                	li	a0,0
}
    80005a12:	60ea                	ld	ra,152(sp)
    80005a14:	644a                	ld	s0,144(sp)
    80005a16:	64aa                	ld	s1,136(sp)
    80005a18:	690a                	ld	s2,128(sp)
    80005a1a:	610d                	addi	sp,sp,160
    80005a1c:	8082                	ret
    end_op();
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	7e0080e7          	jalr	2016(ra) # 800041fe <end_op>
    return -1;
    80005a26:	557d                	li	a0,-1
    80005a28:	b7ed                	j	80005a12 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a2a:	8526                	mv	a0,s1
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	fe2080e7          	jalr	-30(ra) # 80003a0e <iunlockput>
    end_op();
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	7ca080e7          	jalr	1994(ra) # 800041fe <end_op>
    return -1;
    80005a3c:	557d                	li	a0,-1
    80005a3e:	bfd1                	j	80005a12 <sys_chdir+0x7a>

0000000080005a40 <sys_exec>:

uint64
sys_exec(void)
{
    80005a40:	7145                	addi	sp,sp,-464
    80005a42:	e786                	sd	ra,456(sp)
    80005a44:	e3a2                	sd	s0,448(sp)
    80005a46:	ff26                	sd	s1,440(sp)
    80005a48:	fb4a                	sd	s2,432(sp)
    80005a4a:	f74e                	sd	s3,424(sp)
    80005a4c:	f352                	sd	s4,416(sp)
    80005a4e:	ef56                	sd	s5,408(sp)
    80005a50:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a52:	08000613          	li	a2,128
    80005a56:	f4040593          	addi	a1,s0,-192
    80005a5a:	4501                	li	a0,0
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	222080e7          	jalr	546(ra) # 80002c7e <argstr>
    return -1;
    80005a64:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a66:	0c054a63          	bltz	a0,80005b3a <sys_exec+0xfa>
    80005a6a:	e3840593          	addi	a1,s0,-456
    80005a6e:	4505                	li	a0,1
    80005a70:	ffffd097          	auipc	ra,0xffffd
    80005a74:	1ec080e7          	jalr	492(ra) # 80002c5c <argaddr>
    80005a78:	0c054163          	bltz	a0,80005b3a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a7c:	10000613          	li	a2,256
    80005a80:	4581                	li	a1,0
    80005a82:	e4040513          	addi	a0,s0,-448
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	25a080e7          	jalr	602(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a8e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a92:	89a6                	mv	s3,s1
    80005a94:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a96:	02000a13          	li	s4,32
    80005a9a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a9e:	00391513          	slli	a0,s2,0x3
    80005aa2:	e3040593          	addi	a1,s0,-464
    80005aa6:	e3843783          	ld	a5,-456(s0)
    80005aaa:	953e                	add	a0,a0,a5
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	0f4080e7          	jalr	244(ra) # 80002ba0 <fetchaddr>
    80005ab4:	02054a63          	bltz	a0,80005ae8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ab8:	e3043783          	ld	a5,-464(s0)
    80005abc:	c3b9                	beqz	a5,80005b02 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005abe:	ffffb097          	auipc	ra,0xffffb
    80005ac2:	036080e7          	jalr	54(ra) # 80000af4 <kalloc>
    80005ac6:	85aa                	mv	a1,a0
    80005ac8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005acc:	cd11                	beqz	a0,80005ae8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ace:	6605                	lui	a2,0x1
    80005ad0:	e3043503          	ld	a0,-464(s0)
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	11e080e7          	jalr	286(ra) # 80002bf2 <fetchstr>
    80005adc:	00054663          	bltz	a0,80005ae8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ae0:	0905                	addi	s2,s2,1
    80005ae2:	09a1                	addi	s3,s3,8
    80005ae4:	fb491be3          	bne	s2,s4,80005a9a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae8:	10048913          	addi	s2,s1,256
    80005aec:	6088                	ld	a0,0(s1)
    80005aee:	c529                	beqz	a0,80005b38 <sys_exec+0xf8>
    kfree(argv[i]);
    80005af0:	ffffb097          	auipc	ra,0xffffb
    80005af4:	f08080e7          	jalr	-248(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af8:	04a1                	addi	s1,s1,8
    80005afa:	ff2499e3          	bne	s1,s2,80005aec <sys_exec+0xac>
  return -1;
    80005afe:	597d                	li	s2,-1
    80005b00:	a82d                	j	80005b3a <sys_exec+0xfa>
      argv[i] = 0;
    80005b02:	0a8e                	slli	s5,s5,0x3
    80005b04:	fc040793          	addi	a5,s0,-64
    80005b08:	9abe                	add	s5,s5,a5
    80005b0a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b0e:	e4040593          	addi	a1,s0,-448
    80005b12:	f4040513          	addi	a0,s0,-192
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	194080e7          	jalr	404(ra) # 80004caa <exec>
    80005b1e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b20:	10048993          	addi	s3,s1,256
    80005b24:	6088                	ld	a0,0(s1)
    80005b26:	c911                	beqz	a0,80005b3a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b28:	ffffb097          	auipc	ra,0xffffb
    80005b2c:	ed0080e7          	jalr	-304(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b30:	04a1                	addi	s1,s1,8
    80005b32:	ff3499e3          	bne	s1,s3,80005b24 <sys_exec+0xe4>
    80005b36:	a011                	j	80005b3a <sys_exec+0xfa>
  return -1;
    80005b38:	597d                	li	s2,-1
}
    80005b3a:	854a                	mv	a0,s2
    80005b3c:	60be                	ld	ra,456(sp)
    80005b3e:	641e                	ld	s0,448(sp)
    80005b40:	74fa                	ld	s1,440(sp)
    80005b42:	795a                	ld	s2,432(sp)
    80005b44:	79ba                	ld	s3,424(sp)
    80005b46:	7a1a                	ld	s4,416(sp)
    80005b48:	6afa                	ld	s5,408(sp)
    80005b4a:	6179                	addi	sp,sp,464
    80005b4c:	8082                	ret

0000000080005b4e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b4e:	7139                	addi	sp,sp,-64
    80005b50:	fc06                	sd	ra,56(sp)
    80005b52:	f822                	sd	s0,48(sp)
    80005b54:	f426                	sd	s1,40(sp)
    80005b56:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b58:	ffffc097          	auipc	ra,0xffffc
    80005b5c:	ff8080e7          	jalr	-8(ra) # 80001b50 <myproc>
    80005b60:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b62:	fd840593          	addi	a1,s0,-40
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	0f4080e7          	jalr	244(ra) # 80002c5c <argaddr>
    return -1;
    80005b70:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b72:	0e054063          	bltz	a0,80005c52 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b76:	fc840593          	addi	a1,s0,-56
    80005b7a:	fd040513          	addi	a0,s0,-48
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	dfc080e7          	jalr	-516(ra) # 8000497a <pipealloc>
    return -1;
    80005b86:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b88:	0c054563          	bltz	a0,80005c52 <sys_pipe+0x104>
  fd0 = -1;
    80005b8c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b90:	fd043503          	ld	a0,-48(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	508080e7          	jalr	1288(ra) # 8000509c <fdalloc>
    80005b9c:	fca42223          	sw	a0,-60(s0)
    80005ba0:	08054c63          	bltz	a0,80005c38 <sys_pipe+0xea>
    80005ba4:	fc843503          	ld	a0,-56(s0)
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	4f4080e7          	jalr	1268(ra) # 8000509c <fdalloc>
    80005bb0:	fca42023          	sw	a0,-64(s0)
    80005bb4:	06054863          	bltz	a0,80005c24 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb8:	4691                	li	a3,4
    80005bba:	fc440613          	addi	a2,s0,-60
    80005bbe:	fd843583          	ld	a1,-40(s0)
    80005bc2:	68a8                	ld	a0,80(s1)
    80005bc4:	ffffc097          	auipc	ra,0xffffc
    80005bc8:	aae080e7          	jalr	-1362(ra) # 80001672 <copyout>
    80005bcc:	02054063          	bltz	a0,80005bec <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd0:	4691                	li	a3,4
    80005bd2:	fc040613          	addi	a2,s0,-64
    80005bd6:	fd843583          	ld	a1,-40(s0)
    80005bda:	0591                	addi	a1,a1,4
    80005bdc:	68a8                	ld	a0,80(s1)
    80005bde:	ffffc097          	auipc	ra,0xffffc
    80005be2:	a94080e7          	jalr	-1388(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005be6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be8:	06055563          	bgez	a0,80005c52 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bec:	fc442783          	lw	a5,-60(s0)
    80005bf0:	07e9                	addi	a5,a5,26
    80005bf2:	078e                	slli	a5,a5,0x3
    80005bf4:	97a6                	add	a5,a5,s1
    80005bf6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bfa:	fc042503          	lw	a0,-64(s0)
    80005bfe:	0569                	addi	a0,a0,26
    80005c00:	050e                	slli	a0,a0,0x3
    80005c02:	9526                	add	a0,a0,s1
    80005c04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	a3e080e7          	jalr	-1474(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	a32080e7          	jalr	-1486(ra) # 8000464a <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
    80005c22:	a805                	j	80005c52 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c24:	fc442783          	lw	a5,-60(s0)
    80005c28:	0007c863          	bltz	a5,80005c38 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c2c:	01a78513          	addi	a0,a5,26
    80005c30:	050e                	slli	a0,a0,0x3
    80005c32:	9526                	add	a0,a0,s1
    80005c34:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c38:	fd043503          	ld	a0,-48(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a0e080e7          	jalr	-1522(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	a02080e7          	jalr	-1534(ra) # 8000464a <fileclose>
    return -1;
    80005c50:	57fd                	li	a5,-1
}
    80005c52:	853e                	mv	a0,a5
    80005c54:	70e2                	ld	ra,56(sp)
    80005c56:	7442                	ld	s0,48(sp)
    80005c58:	74a2                	ld	s1,40(sp)
    80005c5a:	6121                	addi	sp,sp,64
    80005c5c:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	dcdfc0ef          	jal	ra,80002a6c <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	de4080e7          	jalr	-540(ra) # 80001b1c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	dac080e7          	jalr	-596(ra) # 80001b1c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	d84080e7          	jalr	-636(ra) # 80001b1c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	06a7c963          	blt	a5,a0,80005e32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001d797          	auipc	a5,0x1d
    80005dc8:	23c78793          	addi	a5,a5,572 # 80023000 <disk>
    80005dcc:	00a78733          	add	a4,a5,a0
    80005dd0:	6789                	lui	a5,0x2
    80005dd2:	97ba                	add	a5,a5,a4
    80005dd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dd8:	e7ad                	bnez	a5,80005e42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dda:	00451793          	slli	a5,a0,0x4
    80005dde:	0001f717          	auipc	a4,0x1f
    80005de2:	22270713          	addi	a4,a4,546 # 80025000 <disk+0x2000>
    80005de6:	6314                	ld	a3,0(a4)
    80005de8:	96be                	add	a3,a3,a5
    80005dea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dee:	6314                	ld	a3,0(a4)
    80005df0:	96be                	add	a3,a3,a5
    80005df2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dfe:	6318                	ld	a4,0(a4)
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e06:	0001d797          	auipc	a5,0x1d
    80005e0a:	1fa78793          	addi	a5,a5,506 # 80023000 <disk>
    80005e0e:	97aa                	add	a5,a5,a0
    80005e10:	6509                	lui	a0,0x2
    80005e12:	953e                	add	a0,a0,a5
    80005e14:	4785                	li	a5,1
    80005e16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	1fe50513          	addi	a0,a0,510 # 80025018 <disk+0x2018>
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	5b4080e7          	jalr	1460(ra) # 800023d6 <wakeup>
}
    80005e2a:	60a2                	ld	ra,8(sp)
    80005e2c:	6402                	ld	s0,0(sp)
    80005e2e:	0141                	addi	sp,sp,16
    80005e30:	8082                	ret
    panic("free_desc 1");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	94650513          	addi	a0,a0,-1722 # 80008778 <syscalls+0x320>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	704080e7          	jalr	1796(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	94650513          	addi	a0,a0,-1722 # 80008788 <syscalls+0x330>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>

0000000080005e52 <virtio_disk_init>:
{
    80005e52:	1101                	addi	sp,sp,-32
    80005e54:	ec06                	sd	ra,24(sp)
    80005e56:	e822                	sd	s0,16(sp)
    80005e58:	e426                	sd	s1,8(sp)
    80005e5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e5c:	00003597          	auipc	a1,0x3
    80005e60:	93c58593          	addi	a1,a1,-1732 # 80008798 <syscalls+0x340>
    80005e64:	0001f517          	auipc	a0,0x1f
    80005e68:	2c450513          	addi	a0,a0,708 # 80025128 <disk+0x2128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	ce8080e7          	jalr	-792(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	4398                	lw	a4,0(a5)
    80005e7a:	2701                	sext.w	a4,a4
    80005e7c:	747277b7          	lui	a5,0x74727
    80005e80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e84:	0ef71163          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	43dc                	lw	a5,4(a5)
    80005e8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e90:	4705                	li	a4,1
    80005e92:	0ce79a63          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	479c                	lw	a5,8(a5)
    80005e9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e9e:	4709                	li	a4,2
    80005ea0:	0ce79363          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ea4:	100017b7          	lui	a5,0x10001
    80005ea8:	47d8                	lw	a4,12(a5)
    80005eaa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eac:	554d47b7          	lui	a5,0x554d4
    80005eb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eb4:	0af71963          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4705                	li	a4,1
    80005ebe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec0:	470d                	li	a4,3
    80005ec2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ec4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ec6:	c7ffe737          	lui	a4,0xc7ffe
    80005eca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ece:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed4:	472d                	li	a4,11
    80005ed6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	473d                	li	a4,15
    80005eda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005edc:	6705                	lui	a4,0x1
    80005ede:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ee0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ee4:	5bdc                	lw	a5,52(a5)
    80005ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee8:	c7d9                	beqz	a5,80005f76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eea:	471d                	li	a4,7
    80005eec:	08f77d63          	bgeu	a4,a5,80005f86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ef0:	100014b7          	lui	s1,0x10001
    80005ef4:	47a1                	li	a5,8
    80005ef6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ef8:	6609                	lui	a2,0x2
    80005efa:	4581                	li	a1,0
    80005efc:	0001d517          	auipc	a0,0x1d
    80005f00:	10450513          	addi	a0,a0,260 # 80023000 <disk>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	ddc080e7          	jalr	-548(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f0c:	0001d717          	auipc	a4,0x1d
    80005f10:	0f470713          	addi	a4,a4,244 # 80023000 <disk>
    80005f14:	00c75793          	srli	a5,a4,0xc
    80005f18:	2781                	sext.w	a5,a5
    80005f1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f1c:	0001f797          	auipc	a5,0x1f
    80005f20:	0e478793          	addi	a5,a5,228 # 80025000 <disk+0x2000>
    80005f24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f26:	0001d717          	auipc	a4,0x1d
    80005f2a:	15a70713          	addi	a4,a4,346 # 80023080 <disk+0x80>
    80005f2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f30:	0001e717          	auipc	a4,0x1e
    80005f34:	0d070713          	addi	a4,a4,208 # 80024000 <disk+0x1000>
    80005f38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	00e78c23          	sb	a4,24(a5)
    80005f40:	00e78ca3          	sb	a4,25(a5)
    80005f44:	00e78d23          	sb	a4,26(a5)
    80005f48:	00e78da3          	sb	a4,27(a5)
    80005f4c:	00e78e23          	sb	a4,28(a5)
    80005f50:	00e78ea3          	sb	a4,29(a5)
    80005f54:	00e78f23          	sb	a4,30(a5)
    80005f58:	00e78fa3          	sb	a4,31(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret
    panic("could not find virtio disk");
    80005f66:	00003517          	auipc	a0,0x3
    80005f6a:	84250513          	addi	a0,a0,-1982 # 800087a8 <syscalls+0x350>
    80005f6e:	ffffa097          	auipc	ra,0xffffa
    80005f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	85250513          	addi	a0,a0,-1966 # 800087c8 <syscalls+0x370>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	86250513          	addi	a0,a0,-1950 # 800087e8 <syscalls+0x390>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>

0000000080005f96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f96:	7159                	addi	sp,sp,-112
    80005f98:	f486                	sd	ra,104(sp)
    80005f9a:	f0a2                	sd	s0,96(sp)
    80005f9c:	eca6                	sd	s1,88(sp)
    80005f9e:	e8ca                	sd	s2,80(sp)
    80005fa0:	e4ce                	sd	s3,72(sp)
    80005fa2:	e0d2                	sd	s4,64(sp)
    80005fa4:	fc56                	sd	s5,56(sp)
    80005fa6:	f85a                	sd	s6,48(sp)
    80005fa8:	f45e                	sd	s7,40(sp)
    80005faa:	f062                	sd	s8,32(sp)
    80005fac:	ec66                	sd	s9,24(sp)
    80005fae:	e86a                	sd	s10,16(sp)
    80005fb0:	1880                	addi	s0,sp,112
    80005fb2:	892a                	mv	s2,a0
    80005fb4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fb6:	00c52c83          	lw	s9,12(a0)
    80005fba:	001c9c9b          	slliw	s9,s9,0x1
    80005fbe:	1c82                	slli	s9,s9,0x20
    80005fc0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fc4:	0001f517          	auipc	a0,0x1f
    80005fc8:	16450513          	addi	a0,a0,356 # 80025128 <disk+0x2128>
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	c18080e7          	jalr	-1000(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005fd4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fd6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fd8:	0001db97          	auipc	s7,0x1d
    80005fdc:	028b8b93          	addi	s7,s7,40 # 80023000 <disk>
    80005fe0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fe2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fe4:	8a4e                	mv	s4,s3
    80005fe6:	a051                	j	8000606a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fe8:	00fb86b3          	add	a3,s7,a5
    80005fec:	96da                	add	a3,a3,s6
    80005fee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ff2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ff4:	0207c563          	bltz	a5,8000601e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ff8:	2485                	addiw	s1,s1,1
    80005ffa:	0711                	addi	a4,a4,4
    80005ffc:	25548063          	beq	s1,s5,8000623c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006000:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006002:	0001f697          	auipc	a3,0x1f
    80006006:	01668693          	addi	a3,a3,22 # 80025018 <disk+0x2018>
    8000600a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000600c:	0006c583          	lbu	a1,0(a3)
    80006010:	fde1                	bnez	a1,80005fe8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006012:	2785                	addiw	a5,a5,1
    80006014:	0685                	addi	a3,a3,1
    80006016:	ff879be3          	bne	a5,s8,8000600c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000601a:	57fd                	li	a5,-1
    8000601c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000601e:	02905a63          	blez	s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006022:	f9042503          	lw	a0,-112(s0)
    80006026:	00000097          	auipc	ra,0x0
    8000602a:	d90080e7          	jalr	-624(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    8000602e:	4785                	li	a5,1
    80006030:	0297d163          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006034:	f9442503          	lw	a0,-108(s0)
    80006038:	00000097          	auipc	ra,0x0
    8000603c:	d7e080e7          	jalr	-642(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006040:	4789                	li	a5,2
    80006042:	0097d863          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006046:	f9842503          	lw	a0,-104(s0)
    8000604a:	00000097          	auipc	ra,0x0
    8000604e:	d6c080e7          	jalr	-660(ra) # 80005db6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006052:	0001f597          	auipc	a1,0x1f
    80006056:	0d658593          	addi	a1,a1,214 # 80025128 <disk+0x2128>
    8000605a:	0001f517          	auipc	a0,0x1f
    8000605e:	fbe50513          	addi	a0,a0,-66 # 80025018 <disk+0x2018>
    80006062:	ffffc097          	auipc	ra,0xffffc
    80006066:	1e8080e7          	jalr	488(ra) # 8000224a <sleep>
  for(int i = 0; i < 3; i++){
    8000606a:	f9040713          	addi	a4,s0,-112
    8000606e:	84ce                	mv	s1,s3
    80006070:	bf41                	j	80006000 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006072:	20058713          	addi	a4,a1,512
    80006076:	00471693          	slli	a3,a4,0x4
    8000607a:	0001d717          	auipc	a4,0x1d
    8000607e:	f8670713          	addi	a4,a4,-122 # 80023000 <disk>
    80006082:	9736                	add	a4,a4,a3
    80006084:	4685                	li	a3,1
    80006086:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000608a:	20058713          	addi	a4,a1,512
    8000608e:	00471693          	slli	a3,a4,0x4
    80006092:	0001d717          	auipc	a4,0x1d
    80006096:	f6e70713          	addi	a4,a4,-146 # 80023000 <disk>
    8000609a:	9736                	add	a4,a4,a3
    8000609c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060a4:	7679                	lui	a2,0xffffe
    800060a6:	963e                	add	a2,a2,a5
    800060a8:	0001f697          	auipc	a3,0x1f
    800060ac:	f5868693          	addi	a3,a3,-168 # 80025000 <disk+0x2000>
    800060b0:	6298                	ld	a4,0(a3)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060b6:	6298                	ld	a4,0(a3)
    800060b8:	9732                	add	a4,a4,a2
    800060ba:	4541                	li	a0,16
    800060bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060be:	6298                	ld	a4,0(a3)
    800060c0:	9732                	add	a4,a4,a2
    800060c2:	4505                	li	a0,1
    800060c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060c8:	f9442703          	lw	a4,-108(s0)
    800060cc:	6288                	ld	a0,0(a3)
    800060ce:	962a                	add	a2,a2,a0
    800060d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060d4:	0712                	slli	a4,a4,0x4
    800060d6:	6290                	ld	a2,0(a3)
    800060d8:	963a                	add	a2,a2,a4
    800060da:	05890513          	addi	a0,s2,88
    800060de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060e0:	6294                	ld	a3,0(a3)
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	40000613          	li	a2,1024
    800060e8:	c690                	sw	a2,8(a3)
  if(write)
    800060ea:	140d0063          	beqz	s10,8000622a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ee:	0001f697          	auipc	a3,0x1f
    800060f2:	f126b683          	ld	a3,-238(a3) # 80025000 <disk+0x2000>
    800060f6:	96ba                	add	a3,a3,a4
    800060f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060fc:	0001d817          	auipc	a6,0x1d
    80006100:	f0480813          	addi	a6,a6,-252 # 80023000 <disk>
    80006104:	0001f517          	auipc	a0,0x1f
    80006108:	efc50513          	addi	a0,a0,-260 # 80025000 <disk+0x2000>
    8000610c:	6114                	ld	a3,0(a0)
    8000610e:	96ba                	add	a3,a3,a4
    80006110:	00c6d603          	lhu	a2,12(a3)
    80006114:	00166613          	ori	a2,a2,1
    80006118:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000611c:	f9842683          	lw	a3,-104(s0)
    80006120:	6110                	ld	a2,0(a0)
    80006122:	9732                	add	a4,a4,a2
    80006124:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006128:	20058613          	addi	a2,a1,512
    8000612c:	0612                	slli	a2,a2,0x4
    8000612e:	9642                	add	a2,a2,a6
    80006130:	577d                	li	a4,-1
    80006132:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006136:	00469713          	slli	a4,a3,0x4
    8000613a:	6114                	ld	a3,0(a0)
    8000613c:	96ba                	add	a3,a3,a4
    8000613e:	03078793          	addi	a5,a5,48
    80006142:	97c2                	add	a5,a5,a6
    80006144:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006146:	611c                	ld	a5,0(a0)
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	4685                	li	a3,1
    8000614c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000614e:	611c                	ld	a5,0(a0)
    80006150:	97ba                	add	a5,a5,a4
    80006152:	4809                	li	a6,2
    80006154:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006158:	611c                	ld	a5,0(a0)
    8000615a:	973e                	add	a4,a4,a5
    8000615c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006160:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006164:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006168:	6518                	ld	a4,8(a0)
    8000616a:	00275783          	lhu	a5,2(a4)
    8000616e:	8b9d                	andi	a5,a5,7
    80006170:	0786                	slli	a5,a5,0x1
    80006172:	97ba                	add	a5,a5,a4
    80006174:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006178:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000617c:	6518                	ld	a4,8(a0)
    8000617e:	00275783          	lhu	a5,2(a4)
    80006182:	2785                	addiw	a5,a5,1
    80006184:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006188:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006194:	00492703          	lw	a4,4(s2)
    80006198:	4785                	li	a5,1
    8000619a:	02f71163          	bne	a4,a5,800061bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000619e:	0001f997          	auipc	s3,0x1f
    800061a2:	f8a98993          	addi	s3,s3,-118 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a8:	85ce                	mv	a1,s3
    800061aa:	854a                	mv	a0,s2
    800061ac:	ffffc097          	auipc	ra,0xffffc
    800061b0:	09e080e7          	jalr	158(ra) # 8000224a <sleep>
  while(b->disk == 1) {
    800061b4:	00492783          	lw	a5,4(s2)
    800061b8:	fe9788e3          	beq	a5,s1,800061a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061bc:	f9042903          	lw	s2,-112(s0)
    800061c0:	20090793          	addi	a5,s2,512
    800061c4:	00479713          	slli	a4,a5,0x4
    800061c8:	0001d797          	auipc	a5,0x1d
    800061cc:	e3878793          	addi	a5,a5,-456 # 80023000 <disk>
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061d6:	0001f997          	auipc	s3,0x1f
    800061da:	e2a98993          	addi	s3,s3,-470 # 80025000 <disk+0x2000>
    800061de:	00491713          	slli	a4,s2,0x4
    800061e2:	0009b783          	ld	a5,0(s3)
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061ec:	854a                	mv	a0,s2
    800061ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061f2:	00000097          	auipc	ra,0x0
    800061f6:	bc4080e7          	jalr	-1084(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061fa:	8885                	andi	s1,s1,1
    800061fc:	f0ed                	bnez	s1,800061de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061fe:	0001f517          	auipc	a0,0x1f
    80006202:	f2a50513          	addi	a0,a0,-214 # 80025128 <disk+0x2128>
    80006206:	ffffb097          	auipc	ra,0xffffb
    8000620a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
}
    8000620e:	70a6                	ld	ra,104(sp)
    80006210:	7406                	ld	s0,96(sp)
    80006212:	64e6                	ld	s1,88(sp)
    80006214:	6946                	ld	s2,80(sp)
    80006216:	69a6                	ld	s3,72(sp)
    80006218:	6a06                	ld	s4,64(sp)
    8000621a:	7ae2                	ld	s5,56(sp)
    8000621c:	7b42                	ld	s6,48(sp)
    8000621e:	7ba2                	ld	s7,40(sp)
    80006220:	7c02                	ld	s8,32(sp)
    80006222:	6ce2                	ld	s9,24(sp)
    80006224:	6d42                	ld	s10,16(sp)
    80006226:	6165                	addi	sp,sp,112
    80006228:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000622a:	0001f697          	auipc	a3,0x1f
    8000622e:	dd66b683          	ld	a3,-554(a3) # 80025000 <disk+0x2000>
    80006232:	96ba                	add	a3,a3,a4
    80006234:	4609                	li	a2,2
    80006236:	00c69623          	sh	a2,12(a3)
    8000623a:	b5c9                	j	800060fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000623c:	f9042583          	lw	a1,-112(s0)
    80006240:	20058793          	addi	a5,a1,512
    80006244:	0792                	slli	a5,a5,0x4
    80006246:	0001d517          	auipc	a0,0x1d
    8000624a:	e6250513          	addi	a0,a0,-414 # 800230a8 <disk+0xa8>
    8000624e:	953e                	add	a0,a0,a5
  if(write)
    80006250:	e20d11e3          	bnez	s10,80006072 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006254:	20058713          	addi	a4,a1,512
    80006258:	00471693          	slli	a3,a4,0x4
    8000625c:	0001d717          	auipc	a4,0x1d
    80006260:	da470713          	addi	a4,a4,-604 # 80023000 <disk>
    80006264:	9736                	add	a4,a4,a3
    80006266:	0a072423          	sw	zero,168(a4)
    8000626a:	b505                	j	8000608a <virtio_disk_rw+0xf4>

000000008000626c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	e04a                	sd	s2,0(sp)
    80006276:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006278:	0001f517          	auipc	a0,0x1f
    8000627c:	eb050513          	addi	a0,a0,-336 # 80025128 <disk+0x2128>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	964080e7          	jalr	-1692(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006288:	10001737          	lui	a4,0x10001
    8000628c:	533c                	lw	a5,96(a4)
    8000628e:	8b8d                	andi	a5,a5,3
    80006290:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006292:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006296:	0001f797          	auipc	a5,0x1f
    8000629a:	d6a78793          	addi	a5,a5,-662 # 80025000 <disk+0x2000>
    8000629e:	6b94                	ld	a3,16(a5)
    800062a0:	0207d703          	lhu	a4,32(a5)
    800062a4:	0026d783          	lhu	a5,2(a3)
    800062a8:	06f70163          	beq	a4,a5,8000630a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ac:	0001d917          	auipc	s2,0x1d
    800062b0:	d5490913          	addi	s2,s2,-684 # 80023000 <disk>
    800062b4:	0001f497          	auipc	s1,0x1f
    800062b8:	d4c48493          	addi	s1,s1,-692 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062c0:	6898                	ld	a4,16(s1)
    800062c2:	0204d783          	lhu	a5,32(s1)
    800062c6:	8b9d                	andi	a5,a5,7
    800062c8:	078e                	slli	a5,a5,0x3
    800062ca:	97ba                	add	a5,a5,a4
    800062cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ce:	20078713          	addi	a4,a5,512
    800062d2:	0712                	slli	a4,a4,0x4
    800062d4:	974a                	add	a4,a4,s2
    800062d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062da:	e731                	bnez	a4,80006326 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062dc:	20078793          	addi	a5,a5,512
    800062e0:	0792                	slli	a5,a5,0x4
    800062e2:	97ca                	add	a5,a5,s2
    800062e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ea:	ffffc097          	auipc	ra,0xffffc
    800062ee:	0ec080e7          	jalr	236(ra) # 800023d6 <wakeup>

    disk.used_idx += 1;
    800062f2:	0204d783          	lhu	a5,32(s1)
    800062f6:	2785                	addiw	a5,a5,1
    800062f8:	17c2                	slli	a5,a5,0x30
    800062fa:	93c1                	srli	a5,a5,0x30
    800062fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006300:	6898                	ld	a4,16(s1)
    80006302:	00275703          	lhu	a4,2(a4)
    80006306:	faf71be3          	bne	a4,a5,800062bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000630a:	0001f517          	auipc	a0,0x1f
    8000630e:	e1e50513          	addi	a0,a0,-482 # 80025128 <disk+0x2128>
    80006312:	ffffb097          	auipc	ra,0xffffb
    80006316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
}
    8000631a:	60e2                	ld	ra,24(sp)
    8000631c:	6442                	ld	s0,16(sp)
    8000631e:	64a2                	ld	s1,8(sp)
    80006320:	6902                	ld	s2,0(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret
      panic("virtio_disk_intr status");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	4e250513          	addi	a0,a0,1250 # 80008808 <syscalls+0x3b0>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>

0000000080006336 <cas>:
    80006336:	100522af          	lr.w	t0,(a0)
    8000633a:	00b29563          	bne	t0,a1,80006344 <fail>
    8000633e:	18c5252f          	sc.w	a0,a2,(a0)
    80006342:	8082                	ret

0000000080006344 <fail>:
    80006344:	4505                	li	a0,1
    80006346:	8082                	ret
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
