
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6013103          	ld	sp,-1440(sp) # 80008a60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	0ec78793          	addi	a5,a5,236 # 80006150 <timervec>
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
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8c2080e7          	jalr	-1854(ra) # 800029ee <either_copyin>
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
    800001c8:	b5e080e7          	jalr	-1186(ra) # 80001d22 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	35c080e7          	jalr	860(ra) # 80002530 <sleep>
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
    80000214:	788080e7          	jalr	1928(ra) # 80002998 <either_copyout>
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
    800002f6:	752080e7          	jalr	1874(ra) # 80002a44 <procdump>
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
    8000044a:	29c080e7          	jalr	668(ra) # 800026e2 <wakeup>
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
    8000047c:	32078793          	addi	a5,a5,800 # 80021798 <devsw>
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
    80000570:	dec50513          	addi	a0,a0,-532 # 80008358 <digits+0x318>
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
    800008a4:	e42080e7          	jalr	-446(ra) # 800026e2 <wakeup>
    
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
    80000930:	c04080e7          	jalr	-1020(ra) # 80002530 <sleep>
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
    80000b82:	180080e7          	jalr	384(ra) # 80001cfe <mycpu>
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
    80000bb4:	14e080e7          	jalr	334(ra) # 80001cfe <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	142080e7          	jalr	322(ra) # 80001cfe <mycpu>
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
    80000bd8:	12a080e7          	jalr	298(ra) # 80001cfe <mycpu>
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
    80000c18:	0ea080e7          	jalr	234(ra) # 80001cfe <mycpu>
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
    80000c44:	0be080e7          	jalr	190(ra) # 80001cfe <mycpu>
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
    80000e9a:	e58080e7          	jalr	-424(ra) # 80001cee <cpuid>
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
    80000eb6:	e3c080e7          	jalr	-452(ra) # 80001cee <cpuid>
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
    80000ed8:	d1e080e7          	jalr	-738(ra) # 80002bf2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2b4080e7          	jalr	692(ra) # 80006190 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	418080e7          	jalr	1048(ra) # 800022fc <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	45c50513          	addi	a0,a0,1116 # 80008358 <digits+0x318>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	43c50513          	addi	a0,a0,1084 # 80008358 <digits+0x318>
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
    80000f48:	ca6080e7          	jalr	-858(ra) # 80001bea <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c7e080e7          	jalr	-898(ra) # 80002bca <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c9e080e7          	jalr	-866(ra) # 80002bf2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	21e080e7          	jalr	542(ra) # 8000617a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	22c080e7          	jalr	556(ra) # 80006190 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	412080e7          	jalr	1042(ra) # 8000337e <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	aa2080e7          	jalr	-1374(ra) # 80003a16 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a4c080e7          	jalr	-1460(ra) # 800049c8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	32e080e7          	jalr	814(ra) # 800062b2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	0dc080e7          	jalr	220(ra) # 80002068 <userinit>
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
    80001244:	914080e7          	jalr	-1772(ra) # 80001b54 <proc_mapstacks>
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
struct _list unused_list = {-1, -1};   // contains all UNUSED process entries.
struct _list sleeping_list = {-1, -1}; // contains all SLEEPING processes.
struct _list zombie_list = {-1, -1};   // contains all ZOMBIE processes.

void
print_list(struct _list lst){
    8000183e:	715d                	addi	sp,sp,-80
    80001840:	e486                	sd	ra,72(sp)
    80001842:	e0a2                	sd	s0,64(sp)
    80001844:	fc26                	sd	s1,56(sp)
    80001846:	f84a                	sd	s2,48(sp)
    80001848:	f44e                	sd	s3,40(sp)
    8000184a:	f052                	sd	s4,32(sp)
    8000184c:	ec56                	sd	s5,24(sp)
    8000184e:	0880                	addi	s0,sp,80
    80001850:	faa43c23          	sd	a0,-72(s0)
  int curr = lst.head;
    80001854:	0005049b          	sext.w	s1,a0
  printf("\n[ ");
    80001858:	00007517          	auipc	a0,0x7
    8000185c:	98050513          	addi	a0,a0,-1664 # 800081d8 <digits+0x198>
    80001860:	fffff097          	auipc	ra,0xfffff
    80001864:	d28080e7          	jalr	-728(ra) # 80000588 <printf>
  while(curr != -1){
    80001868:	57fd                	li	a5,-1
    8000186a:	02f48a63          	beq	s1,a5,8000189e <print_list+0x60>
    printf(" %d,", curr);
    8000186e:	00007a97          	auipc	s5,0x7
    80001872:	972a8a93          	addi	s5,s5,-1678 # 800081e0 <digits+0x1a0>
    curr = proc[curr].next_index;
    80001876:	00010a17          	auipc	s4,0x10
    8000187a:	edaa0a13          	addi	s4,s4,-294 # 80011750 <proc>
    8000187e:	17800993          	li	s3,376
  while(curr != -1){
    80001882:	597d                	li	s2,-1
    printf(" %d,", curr);
    80001884:	85a6                	mv	a1,s1
    80001886:	8556                	mv	a0,s5
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	d00080e7          	jalr	-768(ra) # 80000588 <printf>
    curr = proc[curr].next_index;
    80001890:	033484b3          	mul	s1,s1,s3
    80001894:	94d2                	add	s1,s1,s4
    80001896:	1744a483          	lw	s1,372(s1)
  while(curr != -1){
    8000189a:	ff2495e3          	bne	s1,s2,80001884 <print_list+0x46>
  }
  printf(" ]\n");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	94a50513          	addi	a0,a0,-1718 # 800081e8 <digits+0x1a8>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
}
    800018ae:	60a6                	ld	ra,72(sp)
    800018b0:	6406                	ld	s0,64(sp)
    800018b2:	74e2                	ld	s1,56(sp)
    800018b4:	7942                	ld	s2,48(sp)
    800018b6:	79a2                	ld	s3,40(sp)
    800018b8:	7a02                	ld	s4,32(sp)
    800018ba:	6ae2                	ld	s5,24(sp)
    800018bc:	6161                	addi	sp,sp,80
    800018be:	8082                	ret

00000000800018c0 <initialize_runnable_lists>:
    lst->head = p-> index;
  lst->head = -1;
  lst->tail = -1;
}*/

void initialize_runnable_lists(void){
    800018c0:	1141                	addi	sp,sp,-16
    800018c2:	e422                	sd	s0,8(sp)
    800018c4:	0800                	addi	s0,sp,16
  struct cpu *c;
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018c6:	00010797          	auipc	a5,0x10
    800018ca:	9da78793          	addi	a5,a5,-1574 # 800112a0 <cpus>
    c->runnable_list = (struct _list){-1, -1};
    800018ce:	577d                	li	a4,-1
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018d0:	00010697          	auipc	a3,0x10
    800018d4:	e5068693          	addi	a3,a3,-432 # 80011720 <pid_lock>
    c->runnable_list = (struct _list){-1, -1};
    800018d8:	08e7a023          	sw	a4,128(a5)
    800018dc:	08e7a223          	sw	a4,132(a5)
  for(c = cpus; c < &cpus[NCPU] && c != NULL ; c++){
    800018e0:	09078793          	addi	a5,a5,144
    800018e4:	fed79ae3          	bne	a5,a3,800018d8 <initialize_runnable_lists+0x18>
  }
}
    800018e8:	6422                	ld	s0,8(sp)
    800018ea:	0141                	addi	sp,sp,16
    800018ec:	8082                	ret

00000000800018ee <initialize_proc>:

void
initialize_proc(struct proc *p){
    800018ee:	1141                	addi	sp,sp,-16
    800018f0:	e422                	sd	s0,8(sp)
    800018f2:	0800                	addi	s0,sp,16
  proc->next_index = -1;
    800018f4:	00010797          	auipc	a5,0x10
    800018f8:	e5c78793          	addi	a5,a5,-420 # 80011750 <proc>
    800018fc:	577d                	li	a4,-1
    800018fe:	16e7aa23          	sw	a4,372(a5)
  proc->prev_index = -1;
    80001902:	16e7a823          	sw	a4,368(a5)
}
    80001906:	6422                	ld	s0,8(sp)
    80001908:	0141                	addi	sp,sp,16
    8000190a:	8082                	ret

000000008000190c <insert_proc_to_list>:
isEmpty(struct _list *lst){
  return lst->head == -1;
}*/

void 
insert_proc_to_list(struct _list *lst, struct proc *p){
    8000190c:	7179                	addi	sp,sp,-48
    8000190e:	f406                	sd	ra,40(sp)
    80001910:	f022                	sd	s0,32(sp)
    80001912:	ec26                	sd	s1,24(sp)
    80001914:	e84a                	sd	s2,16(sp)
    80001916:	e44e                	sd	s3,8(sp)
    80001918:	e052                	sd	s4,0(sp)
    8000191a:	1800                	addi	s0,sp,48
    8000191c:	84aa                	mv	s1,a0
    8000191e:	89ae                	mv	s3,a1
  printf("before insert: \n");
    80001920:	00007517          	auipc	a0,0x7
    80001924:	8d050513          	addi	a0,a0,-1840 # 800081f0 <digits+0x1b0>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	c60080e7          	jalr	-928(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001930:	0004e503          	lwu	a0,0(s1)
    80001934:	0044e783          	lwu	a5,4(s1)
    80001938:	1782                	slli	a5,a5,0x20
    8000193a:	8d5d                	or	a0,a0,a5
    8000193c:	00000097          	auipc	ra,0x0
    80001940:	f02080e7          	jalr	-254(ra) # 8000183e <print_list>

  if(cas(&lst->tail, -1, p->index) == 0){ // if lst is empty
    80001944:	00448a13          	addi	s4,s1,4
    80001948:	16c9a603          	lw	a2,364(s3) # 116c <_entry-0x7fffee94>
    8000194c:	55fd                	li	a1,-1
    8000194e:	8552                	mv	a0,s4
    80001950:	00005097          	auipc	ra,0x5
    80001954:	e46080e7          	jalr	-442(ra) # 80006796 <cas>
    80001958:	2501                	sext.w	a0,a0
    8000195a:	e509                	bnez	a0,80001964 <insert_proc_to_list+0x58>
    lst->head = p->index; // the only option is to insert another process and change tail, changing head is safe now
    8000195c:	16c9a783          	lw	a5,364(s3)
    80001960:	c09c                	sw	a5,0(s1)
    80001962:	a825                	j	8000199a <insert_proc_to_list+0x8e>
  }
  else {
    int curr_tail;
    struct proc *p_tail;
    do {
      p_tail = &proc[lst->tail];
    80001964:	0044a903          	lw	s2,4(s1)
      curr_tail = lst->tail;
    } while(cas(&lst->tail, curr_tail, p->index)); // try to update tail
    80001968:	16c9a603          	lw	a2,364(s3)
    8000196c:	85ca                	mv	a1,s2
    8000196e:	8552                	mv	a0,s4
    80001970:	00005097          	auipc	ra,0x5
    80001974:	e26080e7          	jalr	-474(ra) # 80006796 <cas>
    80001978:	2501                	sext.w	a0,a0
    8000197a:	f56d                	bnez	a0,80001964 <insert_proc_to_list+0x58>
    p_tail->next_index = p->index; // update next proc of the curr tail
    8000197c:	16c9a683          	lw	a3,364(s3)
    80001980:	17800793          	li	a5,376
    80001984:	02f90733          	mul	a4,s2,a5
    80001988:	00010797          	auipc	a5,0x10
    8000198c:	dc878793          	addi	a5,a5,-568 # 80011750 <proc>
    80001990:	97ba                	add	a5,a5,a4
    80001992:	16d7aa23          	sw	a3,372(a5)
    p->prev_index = curr_tail; // update the prev proc of the new proc
    80001996:	1729a823          	sw	s2,368(s3)
  }
  printf("after insert: \n");
    8000199a:	00007517          	auipc	a0,0x7
    8000199e:	86e50513          	addi	a0,a0,-1938 # 80008208 <digits+0x1c8>
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	be6080e7          	jalr	-1050(ra) # 80000588 <printf>
  print_list(*lst); // delete
    800019aa:	0004e503          	lwu	a0,0(s1)
    800019ae:	0044e783          	lwu	a5,4(s1)
    800019b2:	1782                	slli	a5,a5,0x20
    800019b4:	8d5d                	or	a0,a0,a5
    800019b6:	00000097          	auipc	ra,0x0
    800019ba:	e88080e7          	jalr	-376(ra) # 8000183e <print_list>
}
    800019be:	70a2                	ld	ra,40(sp)
    800019c0:	7402                	ld	s0,32(sp)
    800019c2:	64e2                	ld	s1,24(sp)
    800019c4:	6942                	ld	s2,16(sp)
    800019c6:	69a2                	ld	s3,8(sp)
    800019c8:	6a02                	ld	s4,0(sp)
    800019ca:	6145                	addi	sp,sp,48
    800019cc:	8082                	ret

00000000800019ce <remove_proc_to_list>:

void 
remove_proc_to_list(struct _list *lst, struct proc *p){
    800019ce:	1101                	addi	sp,sp,-32
    800019d0:	ec06                	sd	ra,24(sp)
    800019d2:	e822                	sd	s0,16(sp)
    800019d4:	e426                	sd	s1,8(sp)
    800019d6:	e04a                	sd	s2,0(sp)
    800019d8:	1000                	addi	s0,sp,32
    800019da:	892a                	mv	s2,a0
    800019dc:	84ae                	mv	s1,a1
  printf("before remove: \n");
    800019de:	00007517          	auipc	a0,0x7
    800019e2:	83a50513          	addi	a0,a0,-1990 # 80008218 <digits+0x1d8>
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	ba2080e7          	jalr	-1118(ra) # 80000588 <printf>
  print_list(*lst); // delete
    800019ee:	00096503          	lwu	a0,0(s2) # 1000 <_entry-0x7ffff000>
    800019f2:	00496783          	lwu	a5,4(s2)
    800019f6:	1782                	slli	a5,a5,0x20
    800019f8:	8d5d                	or	a0,a0,a5
    800019fa:	00000097          	auipc	ra,0x0
    800019fe:	e44080e7          	jalr	-444(ra) # 8000183e <print_list>
  if(cas(&lst->tail, p->index, p->prev_index) == 0 && p->prev_index != -1){ // case: p is the list's tail
    80001a02:	1704a603          	lw	a2,368(s1)
    80001a06:	16c4a583          	lw	a1,364(s1)
    80001a0a:	00490513          	addi	a0,s2,4
    80001a0e:	00005097          	auipc	ra,0x5
    80001a12:	d88080e7          	jalr	-632(ra) # 80006796 <cas>
    80001a16:	2501                	sext.w	a0,a0
    80001a18:	e511                	bnez	a0,80001a24 <remove_proc_to_list+0x56>
    80001a1a:	1704a703          	lw	a4,368(s1)
    80001a1e:	57fd                	li	a5,-1
    80001a20:	02f71863          	bne	a4,a5,80001a50 <remove_proc_to_list+0x82>
    struct proc *p_new_tail = &proc[lst->tail];
    int curr_tail_next = p_new_tail->next_index;
    cas(&p_new_tail->next_index, curr_tail_next, -1);
  }
  if(cas(&lst->head, p->index, p->next_index) == 0 && p->next_index != -1){ // case: p is the list's head
    80001a24:	1744a603          	lw	a2,372(s1)
    80001a28:	16c4a583          	lw	a1,364(s1)
    80001a2c:	854a                	mv	a0,s2
    80001a2e:	00005097          	auipc	ra,0x5
    80001a32:	d68080e7          	jalr	-664(ra) # 80006796 <cas>
    80001a36:	2501                	sext.w	a0,a0
    80001a38:	e92d                	bnez	a0,80001aaa <remove_proc_to_list+0xdc>
    80001a3a:	1744a703          	lw	a4,372(s1)
    80001a3e:	57fd                	li	a5,-1
    80001a40:	02f71f63          	bne	a4,a5,80001a7e <remove_proc_to_list+0xb0>
    struct proc *p_new_head = &proc[lst->head];
    int curr_head_prev = p_new_head->prev_index;
    cas(&p_new_head->prev_index, curr_head_prev, -1);
  }
  if(p->prev_index != -1){ // case: p is in the middle
    80001a44:	1704a783          	lw	a5,368(s1)
    80001a48:	577d                	li	a4,-1
    80001a4a:	0ce78463          	beq	a5,a4,80001b12 <remove_proc_to_list+0x144>
    80001a4e:	a09d                	j	80001ab4 <remove_proc_to_list+0xe6>
    struct proc *p_new_tail = &proc[lst->tail];
    80001a50:	00492783          	lw	a5,4(s2)
    int curr_tail_next = p_new_tail->next_index;
    80001a54:	00010517          	auipc	a0,0x10
    80001a58:	cfc50513          	addi	a0,a0,-772 # 80011750 <proc>
    80001a5c:	17800713          	li	a4,376
    80001a60:	02e787b3          	mul	a5,a5,a4
    80001a64:	00f50733          	add	a4,a0,a5
    cas(&p_new_tail->next_index, curr_tail_next, -1);
    80001a68:	17478793          	addi	a5,a5,372
    80001a6c:	567d                	li	a2,-1
    80001a6e:	17472583          	lw	a1,372(a4)
    80001a72:	953e                	add	a0,a0,a5
    80001a74:	00005097          	auipc	ra,0x5
    80001a78:	d22080e7          	jalr	-734(ra) # 80006796 <cas>
    80001a7c:	b765                	j	80001a24 <remove_proc_to_list+0x56>
    struct proc *p_new_head = &proc[lst->head];
    80001a7e:	00092783          	lw	a5,0(s2)
    int curr_head_prev = p_new_head->prev_index;
    80001a82:	00010517          	auipc	a0,0x10
    80001a86:	cce50513          	addi	a0,a0,-818 # 80011750 <proc>
    80001a8a:	17800713          	li	a4,376
    80001a8e:	02e787b3          	mul	a5,a5,a4
    80001a92:	00f50733          	add	a4,a0,a5
    cas(&p_new_head->prev_index, curr_head_prev, -1);
    80001a96:	17078793          	addi	a5,a5,368
    80001a9a:	567d                	li	a2,-1
    80001a9c:	17072583          	lw	a1,368(a4)
    80001aa0:	953e                	add	a0,a0,a5
    80001aa2:	00005097          	auipc	ra,0x5
    80001aa6:	cf4080e7          	jalr	-780(ra) # 80006796 <cas>
  if(p->prev_index != -1){ // case: p is in the middle
    80001aaa:	1704a783          	lw	a5,368(s1)
    80001aae:	577d                	li	a4,-1
    80001ab0:	02e78763          	beq	a5,a4,80001ade <remove_proc_to_list+0x110>
    int prev_next_index = proc[p->prev_index].next_index;
    80001ab4:	00010517          	auipc	a0,0x10
    80001ab8:	c9c50513          	addi	a0,a0,-868 # 80011750 <proc>
    80001abc:	17800713          	li	a4,376
    80001ac0:	02e787b3          	mul	a5,a5,a4
    80001ac4:	00f50733          	add	a4,a0,a5
    cas(&proc[p->prev_index].next_index, prev_next_index, p->next_index);
    80001ac8:	17478793          	addi	a5,a5,372
    80001acc:	1744a603          	lw	a2,372(s1)
    80001ad0:	17472583          	lw	a1,372(a4)
    80001ad4:	953e                	add	a0,a0,a5
    80001ad6:	00005097          	auipc	ra,0x5
    80001ada:	cc0080e7          	jalr	-832(ra) # 80006796 <cas>
  }
  if(p->next_index != -1){
    80001ade:	1744a783          	lw	a5,372(s1)
    80001ae2:	577d                	li	a4,-1
    80001ae4:	02e78763          	beq	a5,a4,80001b12 <remove_proc_to_list+0x144>
    int next_prev_index = proc[p->next_index].prev_index;
    80001ae8:	00010517          	auipc	a0,0x10
    80001aec:	c6850513          	addi	a0,a0,-920 # 80011750 <proc>
    80001af0:	17800713          	li	a4,376
    80001af4:	02e787b3          	mul	a5,a5,a4
    80001af8:	00f50733          	add	a4,a0,a5
    cas(&proc[p->next_index].prev_index, next_prev_index, p->prev_index);
    80001afc:	17078793          	addi	a5,a5,368
    80001b00:	1704a603          	lw	a2,368(s1)
    80001b04:	17072583          	lw	a1,368(a4)
    80001b08:	953e                	add	a0,a0,a5
    80001b0a:	00005097          	auipc	ra,0x5
    80001b0e:	c8c080e7          	jalr	-884(ra) # 80006796 <cas>
  proc->next_index = -1;
    80001b12:	00010797          	auipc	a5,0x10
    80001b16:	c3e78793          	addi	a5,a5,-962 # 80011750 <proc>
    80001b1a:	577d                	li	a4,-1
    80001b1c:	16e7aa23          	sw	a4,372(a5)
  proc->prev_index = -1;
    80001b20:	16e7a823          	sw	a4,368(a5)
  }
  initialize_proc(p);

  printf("after remove: \n");
    80001b24:	00006517          	auipc	a0,0x6
    80001b28:	70c50513          	addi	a0,a0,1804 # 80008230 <digits+0x1f0>
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	a5c080e7          	jalr	-1444(ra) # 80000588 <printf>
  print_list(*lst); // delete
    80001b34:	00096503          	lwu	a0,0(s2)
    80001b38:	00496783          	lwu	a5,4(s2)
    80001b3c:	1782                	slli	a5,a5,0x20
    80001b3e:	8d5d                	or	a0,a0,a5
    80001b40:	00000097          	auipc	ra,0x0
    80001b44:	cfe080e7          	jalr	-770(ra) # 8000183e <print_list>
}
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret

0000000080001b54 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001b54:	7139                	addi	sp,sp,-64
    80001b56:	fc06                	sd	ra,56(sp)
    80001b58:	f822                	sd	s0,48(sp)
    80001b5a:	f426                	sd	s1,40(sp)
    80001b5c:	f04a                	sd	s2,32(sp)
    80001b5e:	ec4e                	sd	s3,24(sp)
    80001b60:	e852                	sd	s4,16(sp)
    80001b62:	e456                	sd	s5,8(sp)
    80001b64:	e05a                	sd	s6,0(sp)
    80001b66:	0080                	addi	s0,sp,64
    80001b68:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6a:	00010497          	auipc	s1,0x10
    80001b6e:	be648493          	addi	s1,s1,-1050 # 80011750 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001b72:	8b26                	mv	s6,s1
    80001b74:	00006a97          	auipc	s5,0x6
    80001b78:	48ca8a93          	addi	s5,s5,1164 # 80008000 <etext>
    80001b7c:	04000937          	lui	s2,0x4000
    80001b80:	197d                	addi	s2,s2,-1
    80001b82:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b84:	00016a17          	auipc	s4,0x16
    80001b88:	9cca0a13          	addi	s4,s4,-1588 # 80017550 <tickslock>
    char *pa = kalloc();
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	f68080e7          	jalr	-152(ra) # 80000af4 <kalloc>
    80001b94:	862a                	mv	a2,a0
    if(pa == 0)
    80001b96:	c131                	beqz	a0,80001bda <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001b98:	416485b3          	sub	a1,s1,s6
    80001b9c:	858d                	srai	a1,a1,0x3
    80001b9e:	000ab783          	ld	a5,0(s5)
    80001ba2:	02f585b3          	mul	a1,a1,a5
    80001ba6:	2585                	addiw	a1,a1,1
    80001ba8:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bac:	4719                	li	a4,6
    80001bae:	6685                	lui	a3,0x1
    80001bb0:	40b905b3          	sub	a1,s2,a1
    80001bb4:	854e                	mv	a0,s3
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	59a080e7          	jalr	1434(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbe:	17848493          	addi	s1,s1,376
    80001bc2:	fd4495e3          	bne	s1,s4,80001b8c <proc_mapstacks+0x38>
  }
}
    80001bc6:	70e2                	ld	ra,56(sp)
    80001bc8:	7442                	ld	s0,48(sp)
    80001bca:	74a2                	ld	s1,40(sp)
    80001bcc:	7902                	ld	s2,32(sp)
    80001bce:	69e2                	ld	s3,24(sp)
    80001bd0:	6a42                	ld	s4,16(sp)
    80001bd2:	6aa2                	ld	s5,8(sp)
    80001bd4:	6b02                	ld	s6,0(sp)
    80001bd6:	6121                	addi	sp,sp,64
    80001bd8:	8082                	ret
      panic("kalloc");
    80001bda:	00006517          	auipc	a0,0x6
    80001bde:	66650513          	addi	a0,a0,1638 # 80008240 <digits+0x200>
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>

0000000080001bea <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001bea:	711d                	addi	sp,sp,-96
    80001bec:	ec86                	sd	ra,88(sp)
    80001bee:	e8a2                	sd	s0,80(sp)
    80001bf0:	e4a6                	sd	s1,72(sp)
    80001bf2:	e0ca                	sd	s2,64(sp)
    80001bf4:	fc4e                	sd	s3,56(sp)
    80001bf6:	f852                	sd	s4,48(sp)
    80001bf8:	f456                	sd	s5,40(sp)
    80001bfa:	f05a                	sd	s6,32(sp)
    80001bfc:	ec5e                	sd	s7,24(sp)
    80001bfe:	e862                	sd	s8,16(sp)
    80001c00:	e466                	sd	s9,8(sp)
    80001c02:	e06a                	sd	s10,0(sp)
    80001c04:	1080                	addi	s0,sp,96
  struct proc *p;

  initialize_runnable_lists();
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	cba080e7          	jalr	-838(ra) # 800018c0 <initialize_runnable_lists>

  initlock(&pid_lock, "nextpid");
    80001c0e:	00006597          	auipc	a1,0x6
    80001c12:	63a58593          	addi	a1,a1,1594 # 80008248 <digits+0x208>
    80001c16:	00010517          	auipc	a0,0x10
    80001c1a:	b0a50513          	addi	a0,a0,-1270 # 80011720 <pid_lock>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	f36080e7          	jalr	-202(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c26:	00006597          	auipc	a1,0x6
    80001c2a:	62a58593          	addi	a1,a1,1578 # 80008250 <digits+0x210>
    80001c2e:	00010517          	auipc	a0,0x10
    80001c32:	b0a50513          	addi	a0,a0,-1270 # 80011738 <wait_lock>
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	f1e080e7          	jalr	-226(ra) # 80000b54 <initlock>

  int i = 0;
    80001c3e:	4981                	li	s3,0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c40:	00010497          	auipc	s1,0x10
    80001c44:	b1048493          	addi	s1,s1,-1264 # 80011750 <proc>
      initlock(&p->lock, "proc");
    80001c48:	00006d17          	auipc	s10,0x6
    80001c4c:	618d0d13          	addi	s10,s10,1560 # 80008260 <digits+0x220>
      p->kstack = KSTACK((int) (p - proc));
    80001c50:	8926                	mv	s2,s1
    80001c52:	00006c97          	auipc	s9,0x6
    80001c56:	3aec8c93          	addi	s9,s9,942 # 80008000 <etext>
    80001c5a:	04000ab7          	lui	s5,0x4000
    80001c5e:	1afd                	addi	s5,s5,-1
    80001c60:	0ab2                	slli	s5,s5,0xc
  proc->next_index = -1;
    80001c62:	5a7d                	li	s4,-1
      p->index = i;
      initialize_proc(p);
      printf("insert procinit unused %d\n", p->index); //delete
    80001c64:	00006c17          	auipc	s8,0x6
    80001c68:	604c0c13          	addi	s8,s8,1540 # 80008268 <digits+0x228>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001c6c:	00007b97          	auipc	s7,0x7
    80001c70:	d9cb8b93          	addi	s7,s7,-612 # 80008a08 <unused_list>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c74:	00016b17          	auipc	s6,0x16
    80001c78:	8dcb0b13          	addi	s6,s6,-1828 # 80017550 <tickslock>
      initlock(&p->lock, "proc");
    80001c7c:	85ea                	mv	a1,s10
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	ed4080e7          	jalr	-300(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001c88:	412487b3          	sub	a5,s1,s2
    80001c8c:	878d                	srai	a5,a5,0x3
    80001c8e:	000cb703          	ld	a4,0(s9)
    80001c92:	02e787b3          	mul	a5,a5,a4
    80001c96:	2785                	addiw	a5,a5,1
    80001c98:	00d7979b          	slliw	a5,a5,0xd
    80001c9c:	40fa87b3          	sub	a5,s5,a5
    80001ca0:	e0bc                	sd	a5,64(s1)
      p->index = i;
    80001ca2:	1734a623          	sw	s3,364(s1)
  proc->next_index = -1;
    80001ca6:	17492a23          	sw	s4,372(s2) # 4000174 <_entry-0x7bfffe8c>
  proc->prev_index = -1;
    80001caa:	17492823          	sw	s4,368(s2)
      printf("insert procinit unused %d\n", p->index); //delete
    80001cae:	16c4a583          	lw	a1,364(s1)
    80001cb2:	8562                	mv	a0,s8
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	8d4080e7          	jalr	-1836(ra) # 80000588 <printf>
      insert_proc_to_list(&unused_list, p); // procinit to admit all UNUSED process entries
    80001cbc:	85a6                	mv	a1,s1
    80001cbe:	855e                	mv	a0,s7
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	c4c080e7          	jalr	-948(ra) # 8000190c <insert_proc_to_list>
      i++;
    80001cc8:	2985                	addiw	s3,s3,1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cca:	17848493          	addi	s1,s1,376
    80001cce:	fb6497e3          	bne	s1,s6,80001c7c <procinit+0x92>
  }
}
    80001cd2:	60e6                	ld	ra,88(sp)
    80001cd4:	6446                	ld	s0,80(sp)
    80001cd6:	64a6                	ld	s1,72(sp)
    80001cd8:	6906                	ld	s2,64(sp)
    80001cda:	79e2                	ld	s3,56(sp)
    80001cdc:	7a42                	ld	s4,48(sp)
    80001cde:	7aa2                	ld	s5,40(sp)
    80001ce0:	7b02                	ld	s6,32(sp)
    80001ce2:	6be2                	ld	s7,24(sp)
    80001ce4:	6c42                	ld	s8,16(sp)
    80001ce6:	6ca2                	ld	s9,8(sp)
    80001ce8:	6d02                	ld	s10,0(sp)
    80001cea:	6125                	addi	sp,sp,96
    80001cec:	8082                	ret

0000000080001cee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001cee:	1141                	addi	sp,sp,-16
    80001cf0:	e422                	sd	s0,8(sp)
    80001cf2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cf4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cf6:	2501                	sext.w	a0,a0
    80001cf8:	6422                	ld	s0,8(sp)
    80001cfa:	0141                	addi	sp,sp,16
    80001cfc:	8082                	ret

0000000080001cfe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001cfe:	1141                	addi	sp,sp,-16
    80001d00:	e422                	sd	s0,8(sp)
    80001d02:	0800                	addi	s0,sp,16
    80001d04:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d06:	0007851b          	sext.w	a0,a5
    80001d0a:	00351793          	slli	a5,a0,0x3
    80001d0e:	97aa                	add	a5,a5,a0
    80001d10:	0792                	slli	a5,a5,0x4
  return c;
}
    80001d12:	0000f517          	auipc	a0,0xf
    80001d16:	58e50513          	addi	a0,a0,1422 # 800112a0 <cpus>
    80001d1a:	953e                	add	a0,a0,a5
    80001d1c:	6422                	ld	s0,8(sp)
    80001d1e:	0141                	addi	sp,sp,16
    80001d20:	8082                	ret

0000000080001d22 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001d22:	1101                	addi	sp,sp,-32
    80001d24:	ec06                	sd	ra,24(sp)
    80001d26:	e822                	sd	s0,16(sp)
    80001d28:	e426                	sd	s1,8(sp)
    80001d2a:	1000                	addi	s0,sp,32
  push_off();
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	e6c080e7          	jalr	-404(ra) # 80000b98 <push_off>
    80001d34:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d36:	0007871b          	sext.w	a4,a5
    80001d3a:	00371793          	slli	a5,a4,0x3
    80001d3e:	97ba                	add	a5,a5,a4
    80001d40:	0792                	slli	a5,a5,0x4
    80001d42:	0000f717          	auipc	a4,0xf
    80001d46:	55e70713          	addi	a4,a4,1374 # 800112a0 <cpus>
    80001d4a:	97ba                	add	a5,a5,a4
    80001d4c:	6384                	ld	s1,0(a5)
  pop_off();
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	eea080e7          	jalr	-278(ra) # 80000c38 <pop_off>
  return p;
}
    80001d56:	8526                	mv	a0,s1
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret

0000000080001d62 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001d62:	1141                	addi	sp,sp,-16
    80001d64:	e406                	sd	ra,8(sp)
    80001d66:	e022                	sd	s0,0(sp)
    80001d68:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	fb8080e7          	jalr	-72(ra) # 80001d22 <myproc>
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f26080e7          	jalr	-218(ra) # 80000c98 <release>

  if (first) {
    80001d7a:	00007797          	auipc	a5,0x7
    80001d7e:	c767a783          	lw	a5,-906(a5) # 800089f0 <first.1753>
    80001d82:	eb89                	bnez	a5,80001d94 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d84:	00001097          	auipc	ra,0x1
    80001d88:	e86080e7          	jalr	-378(ra) # 80002c0a <usertrapret>
}
    80001d8c:	60a2                	ld	ra,8(sp)
    80001d8e:	6402                	ld	s0,0(sp)
    80001d90:	0141                	addi	sp,sp,16
    80001d92:	8082                	ret
    first = 0;
    80001d94:	00007797          	auipc	a5,0x7
    80001d98:	c407ae23          	sw	zero,-932(a5) # 800089f0 <first.1753>
    fsinit(ROOTDEV);
    80001d9c:	4505                	li	a0,1
    80001d9e:	00002097          	auipc	ra,0x2
    80001da2:	bf8080e7          	jalr	-1032(ra) # 80003996 <fsinit>
    80001da6:	bff9                	j	80001d84 <forkret+0x22>

0000000080001da8 <allocpid>:
allocpid() {
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	e04a                	sd	s2,0(sp)
    80001db2:	1000                	addi	s0,sp,32
    pid = nextpid;
    80001db4:	00007917          	auipc	s2,0x7
    80001db8:	c5c90913          	addi	s2,s2,-932 # 80008a10 <nextpid>
    80001dbc:	00092483          	lw	s1,0(s2)
  } while(cas(&nextpid, pid, nextpid + 1));
    80001dc0:	0014861b          	addiw	a2,s1,1
    80001dc4:	85a6                	mv	a1,s1
    80001dc6:	854a                	mv	a0,s2
    80001dc8:	00005097          	auipc	ra,0x5
    80001dcc:	9ce080e7          	jalr	-1586(ra) # 80006796 <cas>
    80001dd0:	2501                	sext.w	a0,a0
    80001dd2:	f56d                	bnez	a0,80001dbc <allocpid+0x14>
}
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	60e2                	ld	ra,24(sp)
    80001dd8:	6442                	ld	s0,16(sp)
    80001dda:	64a2                	ld	s1,8(sp)
    80001ddc:	6902                	ld	s2,0(sp)
    80001dde:	6105                	addi	sp,sp,32
    80001de0:	8082                	ret

0000000080001de2 <proc_pagetable>:
{
    80001de2:	1101                	addi	sp,sp,-32
    80001de4:	ec06                	sd	ra,24(sp)
    80001de6:	e822                	sd	s0,16(sp)
    80001de8:	e426                	sd	s1,8(sp)
    80001dea:	e04a                	sd	s2,0(sp)
    80001dec:	1000                	addi	s0,sp,32
    80001dee:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	54a080e7          	jalr	1354(ra) # 8000133a <uvmcreate>
    80001df8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001dfa:	c121                	beqz	a0,80001e3a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dfc:	4729                	li	a4,10
    80001dfe:	00005697          	auipc	a3,0x5
    80001e02:	20268693          	addi	a3,a3,514 # 80007000 <_trampoline>
    80001e06:	6605                	lui	a2,0x1
    80001e08:	040005b7          	lui	a1,0x4000
    80001e0c:	15fd                	addi	a1,a1,-1
    80001e0e:	05b2                	slli	a1,a1,0xc
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	2a0080e7          	jalr	672(ra) # 800010b0 <mappages>
    80001e18:	02054863          	bltz	a0,80001e48 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e1c:	4719                	li	a4,6
    80001e1e:	05893683          	ld	a3,88(s2)
    80001e22:	6605                	lui	a2,0x1
    80001e24:	020005b7          	lui	a1,0x2000
    80001e28:	15fd                	addi	a1,a1,-1
    80001e2a:	05b6                	slli	a1,a1,0xd
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	282080e7          	jalr	642(ra) # 800010b0 <mappages>
    80001e36:	02054163          	bltz	a0,80001e58 <proc_pagetable+0x76>
}
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	60e2                	ld	ra,24(sp)
    80001e3e:	6442                	ld	s0,16(sp)
    80001e40:	64a2                	ld	s1,8(sp)
    80001e42:	6902                	ld	s2,0(sp)
    80001e44:	6105                	addi	sp,sp,32
    80001e46:	8082                	ret
    uvmfree(pagetable, 0);
    80001e48:	4581                	li	a1,0
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	6ea080e7          	jalr	1770(ra) # 80001536 <uvmfree>
    return 0;
    80001e54:	4481                	li	s1,0
    80001e56:	b7d5                	j	80001e3a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e58:	4681                	li	a3,0
    80001e5a:	4605                	li	a2,1
    80001e5c:	040005b7          	lui	a1,0x4000
    80001e60:	15fd                	addi	a1,a1,-1
    80001e62:	05b2                	slli	a1,a1,0xc
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	410080e7          	jalr	1040(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e6e:	4581                	li	a1,0
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	6c4080e7          	jalr	1732(ra) # 80001536 <uvmfree>
    return 0;
    80001e7a:	4481                	li	s1,0
    80001e7c:	bf7d                	j	80001e3a <proc_pagetable+0x58>

0000000080001e7e <proc_freepagetable>:
{
    80001e7e:	1101                	addi	sp,sp,-32
    80001e80:	ec06                	sd	ra,24(sp)
    80001e82:	e822                	sd	s0,16(sp)
    80001e84:	e426                	sd	s1,8(sp)
    80001e86:	e04a                	sd	s2,0(sp)
    80001e88:	1000                	addi	s0,sp,32
    80001e8a:	84aa                	mv	s1,a0
    80001e8c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e8e:	4681                	li	a3,0
    80001e90:	4605                	li	a2,1
    80001e92:	040005b7          	lui	a1,0x4000
    80001e96:	15fd                	addi	a1,a1,-1
    80001e98:	05b2                	slli	a1,a1,0xc
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	3dc080e7          	jalr	988(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ea2:	4681                	li	a3,0
    80001ea4:	4605                	li	a2,1
    80001ea6:	020005b7          	lui	a1,0x2000
    80001eaa:	15fd                	addi	a1,a1,-1
    80001eac:	05b6                	slli	a1,a1,0xd
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	3c6080e7          	jalr	966(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001eb8:	85ca                	mv	a1,s2
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	67a080e7          	jalr	1658(ra) # 80001536 <uvmfree>
}
    80001ec4:	60e2                	ld	ra,24(sp)
    80001ec6:	6442                	ld	s0,16(sp)
    80001ec8:	64a2                	ld	s1,8(sp)
    80001eca:	6902                	ld	s2,0(sp)
    80001ecc:	6105                	addi	sp,sp,32
    80001ece:	8082                	ret

0000000080001ed0 <freeproc>:
{
    80001ed0:	1101                	addi	sp,sp,-32
    80001ed2:	ec06                	sd	ra,24(sp)
    80001ed4:	e822                	sd	s0,16(sp)
    80001ed6:	e426                	sd	s1,8(sp)
    80001ed8:	1000                	addi	s0,sp,32
    80001eda:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001edc:	6d28                	ld	a0,88(a0)
    80001ede:	c509                	beqz	a0,80001ee8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	b18080e7          	jalr	-1256(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001ee8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001eec:	68a8                	ld	a0,80(s1)
    80001eee:	c511                	beqz	a0,80001efa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ef0:	64ac                	ld	a1,72(s1)
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	f8c080e7          	jalr	-116(ra) # 80001e7e <proc_freepagetable>
  p->pagetable = 0;
    80001efa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001efe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f02:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f06:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001f0a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001f0e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f12:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f16:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f1a:	0004ac23          	sw	zero,24(s1)
  printf("remove free proc zombie %d\n", p->index); //delete
    80001f1e:	16c4a583          	lw	a1,364(s1)
    80001f22:	00006517          	auipc	a0,0x6
    80001f26:	36650513          	addi	a0,a0,870 # 80008288 <digits+0x248>
    80001f2a:	ffffe097          	auipc	ra,0xffffe
    80001f2e:	65e080e7          	jalr	1630(ra) # 80000588 <printf>
  remove_proc_to_list(&zombie_list, p); // remove the freed process from the ZOMBIE list
    80001f32:	85a6                	mv	a1,s1
    80001f34:	00007517          	auipc	a0,0x7
    80001f38:	ac450513          	addi	a0,a0,-1340 # 800089f8 <zombie_list>
    80001f3c:	00000097          	auipc	ra,0x0
    80001f40:	a92080e7          	jalr	-1390(ra) # 800019ce <remove_proc_to_list>
  printf("insert free proc unused %d\n", p->index); //delete
    80001f44:	16c4a583          	lw	a1,364(s1)
    80001f48:	00006517          	auipc	a0,0x6
    80001f4c:	36050513          	addi	a0,a0,864 # 800082a8 <digits+0x268>
    80001f50:	ffffe097          	auipc	ra,0xffffe
    80001f54:	638080e7          	jalr	1592(ra) # 80000588 <printf>
  insert_proc_to_list(&unused_list, p); // admit its entry to the UNUSED entry list.
    80001f58:	85a6                	mv	a1,s1
    80001f5a:	00007517          	auipc	a0,0x7
    80001f5e:	aae50513          	addi	a0,a0,-1362 # 80008a08 <unused_list>
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	9aa080e7          	jalr	-1622(ra) # 8000190c <insert_proc_to_list>
}
    80001f6a:	60e2                	ld	ra,24(sp)
    80001f6c:	6442                	ld	s0,16(sp)
    80001f6e:	64a2                	ld	s1,8(sp)
    80001f70:	6105                	addi	sp,sp,32
    80001f72:	8082                	ret

0000000080001f74 <allocproc>:
{
    80001f74:	1101                	addi	sp,sp,-32
    80001f76:	ec06                	sd	ra,24(sp)
    80001f78:	e822                	sd	s0,16(sp)
    80001f7a:	e426                	sd	s1,8(sp)
    80001f7c:	e04a                	sd	s2,0(sp)
    80001f7e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	0000f497          	auipc	s1,0xf
    80001f84:	7d048493          	addi	s1,s1,2000 # 80011750 <proc>
    80001f88:	00015917          	auipc	s2,0x15
    80001f8c:	5c890913          	addi	s2,s2,1480 # 80017550 <tickslock>
    acquire(&p->lock);
    80001f90:	8526                	mv	a0,s1
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	c52080e7          	jalr	-942(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001f9a:	4c9c                	lw	a5,24(s1)
    80001f9c:	cf81                	beqz	a5,80001fb4 <allocproc+0x40>
      release(&p->lock);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fa8:	17848493          	addi	s1,s1,376
    80001fac:	ff2492e3          	bne	s1,s2,80001f90 <allocproc+0x1c>
  return 0;
    80001fb0:	4481                	li	s1,0
    80001fb2:	a8a5                	j	8000202a <allocproc+0xb6>
      printf("remove allocproc unused %d\n", p->index); //delete
    80001fb4:	16c4a583          	lw	a1,364(s1)
    80001fb8:	00006517          	auipc	a0,0x6
    80001fbc:	31050513          	addi	a0,a0,784 # 800082c8 <digits+0x288>
    80001fc0:	ffffe097          	auipc	ra,0xffffe
    80001fc4:	5c8080e7          	jalr	1480(ra) # 80000588 <printf>
      remove_proc_to_list(&unused_list, p); // choose the new process entry to initialize from the UNUSED entry list.
    80001fc8:	85a6                	mv	a1,s1
    80001fca:	00007517          	auipc	a0,0x7
    80001fce:	a3e50513          	addi	a0,a0,-1474 # 80008a08 <unused_list>
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	9fc080e7          	jalr	-1540(ra) # 800019ce <remove_proc_to_list>
  p->pid = allocpid();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	dce080e7          	jalr	-562(ra) # 80001da8 <allocpid>
    80001fe2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001fe4:	4785                	li	a5,1
    80001fe6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	b0c080e7          	jalr	-1268(ra) # 80000af4 <kalloc>
    80001ff0:	892a                	mv	s2,a0
    80001ff2:	eca8                	sd	a0,88(s1)
    80001ff4:	c131                	beqz	a0,80002038 <allocproc+0xc4>
  p->pagetable = proc_pagetable(p);
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	dea080e7          	jalr	-534(ra) # 80001de2 <proc_pagetable>
    80002000:	892a                	mv	s2,a0
    80002002:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002004:	c531                	beqz	a0,80002050 <allocproc+0xdc>
  memset(&p->context, 0, sizeof(p->context));
    80002006:	07000613          	li	a2,112
    8000200a:	4581                	li	a1,0
    8000200c:	06048513          	addi	a0,s1,96
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	cd0080e7          	jalr	-816(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80002018:	00000797          	auipc	a5,0x0
    8000201c:	d4a78793          	addi	a5,a5,-694 # 80001d62 <forkret>
    80002020:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002022:	60bc                	ld	a5,64(s1)
    80002024:	6705                	lui	a4,0x1
    80002026:	97ba                	add	a5,a5,a4
    80002028:	f4bc                	sd	a5,104(s1)
}
    8000202a:	8526                	mv	a0,s1
    8000202c:	60e2                	ld	ra,24(sp)
    8000202e:	6442                	ld	s0,16(sp)
    80002030:	64a2                	ld	s1,8(sp)
    80002032:	6902                	ld	s2,0(sp)
    80002034:	6105                	addi	sp,sp,32
    80002036:	8082                	ret
    freeproc(p);
    80002038:	8526                	mv	a0,s1
    8000203a:	00000097          	auipc	ra,0x0
    8000203e:	e96080e7          	jalr	-362(ra) # 80001ed0 <freeproc>
    release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c54080e7          	jalr	-940(ra) # 80000c98 <release>
    return 0;
    8000204c:	84ca                	mv	s1,s2
    8000204e:	bff1                	j	8000202a <allocproc+0xb6>
    freeproc(p);
    80002050:	8526                	mv	a0,s1
    80002052:	00000097          	auipc	ra,0x0
    80002056:	e7e080e7          	jalr	-386(ra) # 80001ed0 <freeproc>
    release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	c3c080e7          	jalr	-964(ra) # 80000c98 <release>
    return 0;
    80002064:	84ca                	mv	s1,s2
    80002066:	b7d1                	j	8000202a <allocproc+0xb6>

0000000080002068 <userinit>:
{
    80002068:	1101                	addi	sp,sp,-32
    8000206a:	ec06                	sd	ra,24(sp)
    8000206c:	e822                	sd	s0,16(sp)
    8000206e:	e426                	sd	s1,8(sp)
    80002070:	1000                	addi	s0,sp,32
  p = allocproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	f02080e7          	jalr	-254(ra) # 80001f74 <allocproc>
    8000207a:	84aa                	mv	s1,a0
  initproc = p;
    8000207c:	00007797          	auipc	a5,0x7
    80002080:	faa7b623          	sd	a0,-84(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002084:	03400613          	li	a2,52
    80002088:	00007597          	auipc	a1,0x7
    8000208c:	99858593          	addi	a1,a1,-1640 # 80008a20 <initcode>
    80002090:	6928                	ld	a0,80(a0)
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	2d6080e7          	jalr	726(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    8000209a:	6785                	lui	a5,0x1
    8000209c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000209e:	6cb8                	ld	a4,88(s1)
    800020a0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020a4:	6cb8                	ld	a4,88(s1)
    800020a6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020a8:	4641                	li	a2,16
    800020aa:	00006597          	auipc	a1,0x6
    800020ae:	23e58593          	addi	a1,a1,574 # 800082e8 <digits+0x2a8>
    800020b2:	15848513          	addi	a0,s1,344
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	d7c080e7          	jalr	-644(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	23a50513          	addi	a0,a0,570 # 800082f8 <digits+0x2b8>
    800020c6:	00002097          	auipc	ra,0x2
    800020ca:	2fe080e7          	jalr	766(ra) # 800043c4 <namei>
    800020ce:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020d2:	478d                	li	a5,3
    800020d4:	cc9c                	sw	a5,24(s1)
  printf("insert userinit runnable %d\n", p->index); //delete
    800020d6:	16c4a583          	lw	a1,364(s1)
    800020da:	00006517          	auipc	a0,0x6
    800020de:	22650513          	addi	a0,a0,550 # 80008300 <digits+0x2c0>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	4a6080e7          	jalr	1190(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[0].runnable_list), p); // admit the init process (the first process in the OS) to the first CPU’s list.
    800020ea:	85a6                	mv	a1,s1
    800020ec:	0000f517          	auipc	a0,0xf
    800020f0:	23450513          	addi	a0,a0,564 # 80011320 <cpus+0x80>
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	818080e7          	jalr	-2024(ra) # 8000190c <insert_proc_to_list>
  release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
}
    80002106:	60e2                	ld	ra,24(sp)
    80002108:	6442                	ld	s0,16(sp)
    8000210a:	64a2                	ld	s1,8(sp)
    8000210c:	6105                	addi	sp,sp,32
    8000210e:	8082                	ret

0000000080002110 <growproc>:
{
    80002110:	1101                	addi	sp,sp,-32
    80002112:	ec06                	sd	ra,24(sp)
    80002114:	e822                	sd	s0,16(sp)
    80002116:	e426                	sd	s1,8(sp)
    80002118:	e04a                	sd	s2,0(sp)
    8000211a:	1000                	addi	s0,sp,32
    8000211c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	c04080e7          	jalr	-1020(ra) # 80001d22 <myproc>
    80002126:	892a                	mv	s2,a0
  sz = p->sz;
    80002128:	652c                	ld	a1,72(a0)
    8000212a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    8000212e:	00904f63          	bgtz	s1,8000214c <growproc+0x3c>
  } else if(n < 0){
    80002132:	0204cc63          	bltz	s1,8000216a <growproc+0x5a>
  p->sz = sz;
    80002136:	1602                	slli	a2,a2,0x20
    80002138:	9201                	srli	a2,a2,0x20
    8000213a:	04c93423          	sd	a2,72(s2)
  return 0;
    8000213e:	4501                	li	a0,0
}
    80002140:	60e2                	ld	ra,24(sp)
    80002142:	6442                	ld	s0,16(sp)
    80002144:	64a2                	ld	s1,8(sp)
    80002146:	6902                	ld	s2,0(sp)
    80002148:	6105                	addi	sp,sp,32
    8000214a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000214c:	9e25                	addw	a2,a2,s1
    8000214e:	1602                	slli	a2,a2,0x20
    80002150:	9201                	srli	a2,a2,0x20
    80002152:	1582                	slli	a1,a1,0x20
    80002154:	9181                	srli	a1,a1,0x20
    80002156:	6928                	ld	a0,80(a0)
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	2ca080e7          	jalr	714(ra) # 80001422 <uvmalloc>
    80002160:	0005061b          	sext.w	a2,a0
    80002164:	fa69                	bnez	a2,80002136 <growproc+0x26>
      return -1;
    80002166:	557d                	li	a0,-1
    80002168:	bfe1                	j	80002140 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000216a:	9e25                	addw	a2,a2,s1
    8000216c:	1602                	slli	a2,a2,0x20
    8000216e:	9201                	srli	a2,a2,0x20
    80002170:	1582                	slli	a1,a1,0x20
    80002172:	9181                	srli	a1,a1,0x20
    80002174:	6928                	ld	a0,80(a0)
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	264080e7          	jalr	612(ra) # 800013da <uvmdealloc>
    8000217e:	0005061b          	sext.w	a2,a0
    80002182:	bf55                	j	80002136 <growproc+0x26>

0000000080002184 <fork>:
{
    80002184:	7179                	addi	sp,sp,-48
    80002186:	f406                	sd	ra,40(sp)
    80002188:	f022                	sd	s0,32(sp)
    8000218a:	ec26                	sd	s1,24(sp)
    8000218c:	e84a                	sd	s2,16(sp)
    8000218e:	e44e                	sd	s3,8(sp)
    80002190:	e052                	sd	s4,0(sp)
    80002192:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	b8e080e7          	jalr	-1138(ra) # 80001d22 <myproc>
    8000219c:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	dd6080e7          	jalr	-554(ra) # 80001f74 <allocproc>
    800021a6:	14050963          	beqz	a0,800022f8 <fork+0x174>
    800021aa:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800021ac:	0489b603          	ld	a2,72(s3)
    800021b0:	692c                	ld	a1,80(a0)
    800021b2:	0509b503          	ld	a0,80(s3)
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	3b8080e7          	jalr	952(ra) # 8000156e <uvmcopy>
    800021be:	04054663          	bltz	a0,8000220a <fork+0x86>
  np->sz = p->sz;
    800021c2:	0489b783          	ld	a5,72(s3)
    800021c6:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    800021ca:	0589b683          	ld	a3,88(s3)
    800021ce:	87b6                	mv	a5,a3
    800021d0:	05893703          	ld	a4,88(s2)
    800021d4:	12068693          	addi	a3,a3,288
    800021d8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021dc:	6788                	ld	a0,8(a5)
    800021de:	6b8c                	ld	a1,16(a5)
    800021e0:	6f90                	ld	a2,24(a5)
    800021e2:	01073023          	sd	a6,0(a4)
    800021e6:	e708                	sd	a0,8(a4)
    800021e8:	eb0c                	sd	a1,16(a4)
    800021ea:	ef10                	sd	a2,24(a4)
    800021ec:	02078793          	addi	a5,a5,32
    800021f0:	02070713          	addi	a4,a4,32
    800021f4:	fed792e3          	bne	a5,a3,800021d8 <fork+0x54>
  np->trapframe->a0 = 0;
    800021f8:	05893783          	ld	a5,88(s2)
    800021fc:	0607b823          	sd	zero,112(a5)
    80002200:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002204:	15000a13          	li	s4,336
    80002208:	a03d                	j	80002236 <fork+0xb2>
    freeproc(np);
    8000220a:	854a                	mv	a0,s2
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	cc4080e7          	jalr	-828(ra) # 80001ed0 <freeproc>
    release(&np->lock);
    80002214:	854a                	mv	a0,s2
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
    return -1;
    8000221e:	5a7d                	li	s4,-1
    80002220:	a0d9                	j	800022e6 <fork+0x162>
      np->ofile[i] = filedup(p->ofile[i]);
    80002222:	00003097          	auipc	ra,0x3
    80002226:	838080e7          	jalr	-1992(ra) # 80004a5a <filedup>
    8000222a:	009907b3          	add	a5,s2,s1
    8000222e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002230:	04a1                	addi	s1,s1,8
    80002232:	01448763          	beq	s1,s4,80002240 <fork+0xbc>
    if(p->ofile[i])
    80002236:	009987b3          	add	a5,s3,s1
    8000223a:	6388                	ld	a0,0(a5)
    8000223c:	f17d                	bnez	a0,80002222 <fork+0x9e>
    8000223e:	bfcd                	j	80002230 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002240:	1509b503          	ld	a0,336(s3)
    80002244:	00002097          	auipc	ra,0x2
    80002248:	98c080e7          	jalr	-1652(ra) # 80003bd0 <idup>
    8000224c:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002250:	4641                	li	a2,16
    80002252:	15898593          	addi	a1,s3,344
    80002256:	15890513          	addi	a0,s2,344
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	bd8080e7          	jalr	-1064(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002262:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    80002266:	854a                	mv	a0,s2
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a30080e7          	jalr	-1488(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002270:	0000f497          	auipc	s1,0xf
    80002274:	4c848493          	addi	s1,s1,1224 # 80011738 <wait_lock>
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	96a080e7          	jalr	-1686(ra) # 80000be4 <acquire>
  np->parent = p;
    80002282:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a10080e7          	jalr	-1520(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002290:	854a                	mv	a0,s2
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	952080e7          	jalr	-1710(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    8000229a:	478d                	li	a5,3
    8000229c:	00f92c23          	sw	a5,24(s2)
  np->last_cpu = p->last_cpu; 
    800022a0:	1689a783          	lw	a5,360(s3)
    800022a4:	16f92423          	sw	a5,360(s2)
  printf("insert fork runnable %d\n", np->index); //delete
    800022a8:	16c92583          	lw	a1,364(s2)
    800022ac:	00006517          	auipc	a0,0x6
    800022b0:	07450513          	addi	a0,a0,116 # 80008320 <digits+0x2e0>
    800022b4:	ffffe097          	auipc	ra,0xffffe
    800022b8:	2d4080e7          	jalr	724(ra) # 80000588 <printf>
  insert_proc_to_list(&(cpus[np->last_cpu].runnable_list), np); // admit the new process to the father’s current CPU’s ready list
    800022bc:	16892503          	lw	a0,360(s2)
    800022c0:	00351793          	slli	a5,a0,0x3
    800022c4:	97aa                	add	a5,a5,a0
    800022c6:	0792                	slli	a5,a5,0x4
    800022c8:	85ca                	mv	a1,s2
    800022ca:	0000f517          	auipc	a0,0xf
    800022ce:	05650513          	addi	a0,a0,86 # 80011320 <cpus+0x80>
    800022d2:	953e                	add	a0,a0,a5
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	638080e7          	jalr	1592(ra) # 8000190c <insert_proc_to_list>
  release(&np->lock);
    800022dc:	854a                	mv	a0,s2
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9ba080e7          	jalr	-1606(ra) # 80000c98 <release>
}
    800022e6:	8552                	mv	a0,s4
    800022e8:	70a2                	ld	ra,40(sp)
    800022ea:	7402                	ld	s0,32(sp)
    800022ec:	64e2                	ld	s1,24(sp)
    800022ee:	6942                	ld	s2,16(sp)
    800022f0:	69a2                	ld	s3,8(sp)
    800022f2:	6a02                	ld	s4,0(sp)
    800022f4:	6145                	addi	sp,sp,48
    800022f6:	8082                	ret
    return -1;
    800022f8:	5a7d                	li	s4,-1
    800022fa:	b7f5                	j	800022e6 <fork+0x162>

00000000800022fc <scheduler>:
{
    800022fc:	715d                	addi	sp,sp,-80
    800022fe:	e486                	sd	ra,72(sp)
    80002300:	e0a2                	sd	s0,64(sp)
    80002302:	fc26                	sd	s1,56(sp)
    80002304:	f84a                	sd	s2,48(sp)
    80002306:	f44e                	sd	s3,40(sp)
    80002308:	f052                	sd	s4,32(sp)
    8000230a:	ec56                	sd	s5,24(sp)
    8000230c:	e85a                	sd	s6,16(sp)
    8000230e:	e45e                	sd	s7,8(sp)
    80002310:	0880                	addi	s0,sp,80
    80002312:	8712                	mv	a4,tp
  int id = r_tp();
    80002314:	2701                	sext.w	a4,a4
  c->proc = 0;
    80002316:	0000fa97          	auipc	s5,0xf
    8000231a:	f8aa8a93          	addi	s5,s5,-118 # 800112a0 <cpus>
    8000231e:	00371793          	slli	a5,a4,0x3
    80002322:	00e786b3          	add	a3,a5,a4
    80002326:	0692                	slli	a3,a3,0x4
    80002328:	96d6                	add	a3,a3,s5
    8000232a:	0006b023          	sd	zero,0(a3)
    8000232e:	97ba                	add	a5,a5,a4
    80002330:	0792                	slli	a5,a5,0x4
        remove_proc_to_list(&(c->runnable_list), p);
    80002332:	08078b13          	addi	s6,a5,128
    80002336:	9b56                	add	s6,s6,s5
        swtch(&c->context, &p->context);
    80002338:	07a1                	addi	a5,a5,8
    8000233a:	9abe                	add	s5,s5,a5
      if(p->state == RUNNABLE) { // TODO: remove?
    8000233c:	490d                	li	s2,3
        c->proc = p;
    8000233e:	8a36                	mv	s4,a3
    for(p = proc; p < &proc[NPROC]; p++) { // TODO: remove?
    80002340:	00015997          	auipc	s3,0x15
    80002344:	21098993          	addi	s3,s3,528 # 80017550 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002348:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000234c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002350:	10079073          	csrw	sstatus,a5
    80002354:	0000f497          	auipc	s1,0xf
    80002358:	3fc48493          	addi	s1,s1,1020 # 80011750 <proc>
        p->state = RUNNING;
    8000235c:	4b91                	li	s7,4
    8000235e:	a899                	j	800023b4 <scheduler+0xb8>
    80002360:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002364:	009a3023          	sd	s1,0(s4)
        p->last_cpu = c->cpu_id;
    80002368:	088a2783          	lw	a5,136(s4)
    8000236c:	16f4a423          	sw	a5,360(s1)
        printf("remove sched runnable %d\n", p->index); //delete
    80002370:	16c4a583          	lw	a1,364(s1)
    80002374:	00006517          	auipc	a0,0x6
    80002378:	fcc50513          	addi	a0,a0,-52 # 80008340 <digits+0x300>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	20c080e7          	jalr	524(ra) # 80000588 <printf>
        remove_proc_to_list(&(c->runnable_list), p);
    80002384:	85a6                	mv	a1,s1
    80002386:	855a                	mv	a0,s6
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	646080e7          	jalr	1606(ra) # 800019ce <remove_proc_to_list>
        swtch(&c->context, &p->context);
    80002390:	06048593          	addi	a1,s1,96
    80002394:	8556                	mv	a0,s5
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	7ca080e7          	jalr	1994(ra) # 80002b60 <swtch>
        c->proc = 0;
    8000239e:	000a3023          	sd	zero,0(s4)
      release(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) { // TODO: remove?
    800023ac:	17848493          	addi	s1,s1,376
    800023b0:	f9348ce3          	beq	s1,s3,80002348 <scheduler+0x4c>
      if(p->state == RUNNABLE) { // TODO: remove?
    800023b4:	4c9c                	lw	a5,24(s1)
    800023b6:	ff279be3          	bne	a5,s2,800023ac <scheduler+0xb0>
      acquire(&p->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {  
    800023c4:	4c9c                	lw	a5,24(s1)
    800023c6:	fd279ee3          	bne	a5,s2,800023a2 <scheduler+0xa6>
    800023ca:	bf59                	j	80002360 <scheduler+0x64>

00000000800023cc <sched>:
{
    800023cc:	7179                	addi	sp,sp,-48
    800023ce:	f406                	sd	ra,40(sp)
    800023d0:	f022                	sd	s0,32(sp)
    800023d2:	ec26                	sd	s1,24(sp)
    800023d4:	e84a                	sd	s2,16(sp)
    800023d6:	e44e                	sd	s3,8(sp)
    800023d8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023da:	00000097          	auipc	ra,0x0
    800023de:	948080e7          	jalr	-1720(ra) # 80001d22 <myproc>
    800023e2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	786080e7          	jalr	1926(ra) # 80000b6a <holding>
    800023ec:	c559                	beqz	a0,8000247a <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023f0:	0007871b          	sext.w	a4,a5
    800023f4:	00371793          	slli	a5,a4,0x3
    800023f8:	97ba                	add	a5,a5,a4
    800023fa:	0792                	slli	a5,a5,0x4
    800023fc:	0000f717          	auipc	a4,0xf
    80002400:	ea470713          	addi	a4,a4,-348 # 800112a0 <cpus>
    80002404:	97ba                	add	a5,a5,a4
    80002406:	5fb8                	lw	a4,120(a5)
    80002408:	4785                	li	a5,1
    8000240a:	08f71063          	bne	a4,a5,8000248a <sched+0xbe>
  if(p->state == RUNNING)
    8000240e:	4c98                	lw	a4,24(s1)
    80002410:	4791                	li	a5,4
    80002412:	08f70463          	beq	a4,a5,8000249a <sched+0xce>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002416:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000241a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000241c:	e7d9                	bnez	a5,800024aa <sched+0xde>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002420:	0000f917          	auipc	s2,0xf
    80002424:	e8090913          	addi	s2,s2,-384 # 800112a0 <cpus>
    80002428:	0007871b          	sext.w	a4,a5
    8000242c:	00371793          	slli	a5,a4,0x3
    80002430:	97ba                	add	a5,a5,a4
    80002432:	0792                	slli	a5,a5,0x4
    80002434:	97ca                	add	a5,a5,s2
    80002436:	07c7a983          	lw	s3,124(a5)
    8000243a:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    8000243c:	0005879b          	sext.w	a5,a1
    80002440:	00379593          	slli	a1,a5,0x3
    80002444:	95be                	add	a1,a1,a5
    80002446:	0592                	slli	a1,a1,0x4
    80002448:	05a1                	addi	a1,a1,8
    8000244a:	95ca                	add	a1,a1,s2
    8000244c:	06048513          	addi	a0,s1,96
    80002450:	00000097          	auipc	ra,0x0
    80002454:	710080e7          	jalr	1808(ra) # 80002b60 <swtch>
    80002458:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000245a:	0007871b          	sext.w	a4,a5
    8000245e:	00371793          	slli	a5,a4,0x3
    80002462:	97ba                	add	a5,a5,a4
    80002464:	0792                	slli	a5,a5,0x4
    80002466:	993e                	add	s2,s2,a5
    80002468:	07392e23          	sw	s3,124(s2)
}
    8000246c:	70a2                	ld	ra,40(sp)
    8000246e:	7402                	ld	s0,32(sp)
    80002470:	64e2                	ld	s1,24(sp)
    80002472:	6942                	ld	s2,16(sp)
    80002474:	69a2                	ld	s3,8(sp)
    80002476:	6145                	addi	sp,sp,48
    80002478:	8082                	ret
    panic("sched p->lock");
    8000247a:	00006517          	auipc	a0,0x6
    8000247e:	ee650513          	addi	a0,a0,-282 # 80008360 <digits+0x320>
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>
    panic("sched locks");
    8000248a:	00006517          	auipc	a0,0x6
    8000248e:	ee650513          	addi	a0,a0,-282 # 80008370 <digits+0x330>
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	0ac080e7          	jalr	172(ra) # 8000053e <panic>
    panic("sched running");
    8000249a:	00006517          	auipc	a0,0x6
    8000249e:	ee650513          	addi	a0,a0,-282 # 80008380 <digits+0x340>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	09c080e7          	jalr	156(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024aa:	00006517          	auipc	a0,0x6
    800024ae:	ee650513          	addi	a0,a0,-282 # 80008390 <digits+0x350>
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	08c080e7          	jalr	140(ra) # 8000053e <panic>

00000000800024ba <yield>:
{
    800024ba:	1101                	addi	sp,sp,-32
    800024bc:	ec06                	sd	ra,24(sp)
    800024be:	e822                	sd	s0,16(sp)
    800024c0:	e426                	sd	s1,8(sp)
    800024c2:	e04a                	sd	s2,0(sp)
    800024c4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	85c080e7          	jalr	-1956(ra) # 80001d22 <myproc>
    800024ce:	84aa                	mv	s1,a0
    800024d0:	8912                	mv	s2,tp
  acquire(&p->lock);
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	712080e7          	jalr	1810(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800024da:	478d                	li	a5,3
    800024dc:	cc9c                	sw	a5,24(s1)
  printf("insert yield runnable %d\n", p->index); //delete
    800024de:	16c4a583          	lw	a1,364(s1)
    800024e2:	00006517          	auipc	a0,0x6
    800024e6:	ec650513          	addi	a0,a0,-314 # 800083a8 <digits+0x368>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	09e080e7          	jalr	158(ra) # 80000588 <printf>
  insert_proc_to_list(&(c->runnable_list), p); // TODO: check
    800024f2:	0009051b          	sext.w	a0,s2
    800024f6:	00351793          	slli	a5,a0,0x3
    800024fa:	97aa                	add	a5,a5,a0
    800024fc:	0792                	slli	a5,a5,0x4
    800024fe:	85a6                	mv	a1,s1
    80002500:	0000f517          	auipc	a0,0xf
    80002504:	e2050513          	addi	a0,a0,-480 # 80011320 <cpus+0x80>
    80002508:	953e                	add	a0,a0,a5
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	402080e7          	jalr	1026(ra) # 8000190c <insert_proc_to_list>
  sched();
    80002512:	00000097          	auipc	ra,0x0
    80002516:	eba080e7          	jalr	-326(ra) # 800023cc <sched>
  release(&p->lock);
    8000251a:	8526                	mv	a0,s1
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	77c080e7          	jalr	1916(ra) # 80000c98 <release>
}
    80002524:	60e2                	ld	ra,24(sp)
    80002526:	6442                	ld	s0,16(sp)
    80002528:	64a2                	ld	s1,8(sp)
    8000252a:	6902                	ld	s2,0(sp)
    8000252c:	6105                	addi	sp,sp,32
    8000252e:	8082                	ret

0000000080002530 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	1800                	addi	s0,sp,48
    8000253e:	89aa                	mv	s3,a0
    80002540:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	7e0080e7          	jalr	2016(ra) # 80001d22 <myproc>
    8000254a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	698080e7          	jalr	1688(ra) # 80000be4 <acquire>
  release(lk);
    80002554:	854a                	mv	a0,s2
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	742080e7          	jalr	1858(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000255e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002562:	4789                	li	a5,2
    80002564:	cc9c                	sw	a5,24(s1)
  printf("insert sleep sleep %d\n", p->index); //delete
    80002566:	16c4a583          	lw	a1,364(s1)
    8000256a:	00006517          	auipc	a0,0x6
    8000256e:	e5e50513          	addi	a0,a0,-418 # 800083c8 <digits+0x388>
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	016080e7          	jalr	22(ra) # 80000588 <printf>
  insert_proc_to_list(&sleeping_list, p);
    8000257a:	85a6                	mv	a1,s1
    8000257c:	00006517          	auipc	a0,0x6
    80002580:	48450513          	addi	a0,a0,1156 # 80008a00 <sleeping_list>
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	388080e7          	jalr	904(ra) # 8000190c <insert_proc_to_list>

  sched();
    8000258c:	00000097          	auipc	ra,0x0
    80002590:	e40080e7          	jalr	-448(ra) # 800023cc <sched>

  // Tidy up.
  p->chan = 0;
    80002594:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
  acquire(lk);
    800025a2:	854a                	mv	a0,s2
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
}
    800025ac:	70a2                	ld	ra,40(sp)
    800025ae:	7402                	ld	s0,32(sp)
    800025b0:	64e2                	ld	s1,24(sp)
    800025b2:	6942                	ld	s2,16(sp)
    800025b4:	69a2                	ld	s3,8(sp)
    800025b6:	6145                	addi	sp,sp,48
    800025b8:	8082                	ret

00000000800025ba <wait>:
{
    800025ba:	715d                	addi	sp,sp,-80
    800025bc:	e486                	sd	ra,72(sp)
    800025be:	e0a2                	sd	s0,64(sp)
    800025c0:	fc26                	sd	s1,56(sp)
    800025c2:	f84a                	sd	s2,48(sp)
    800025c4:	f44e                	sd	s3,40(sp)
    800025c6:	f052                	sd	s4,32(sp)
    800025c8:	ec56                	sd	s5,24(sp)
    800025ca:	e85a                	sd	s6,16(sp)
    800025cc:	e45e                	sd	s7,8(sp)
    800025ce:	e062                	sd	s8,0(sp)
    800025d0:	0880                	addi	s0,sp,80
    800025d2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d4:	fffff097          	auipc	ra,0xfffff
    800025d8:	74e080e7          	jalr	1870(ra) # 80001d22 <myproc>
    800025dc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800025de:	0000f517          	auipc	a0,0xf
    800025e2:	15a50513          	addi	a0,a0,346 # 80011738 <wait_lock>
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	5fe080e7          	jalr	1534(ra) # 80000be4 <acquire>
    havekids = 0;
    800025ee:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025f0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800025f2:	00015997          	auipc	s3,0x15
    800025f6:	f5e98993          	addi	s3,s3,-162 # 80017550 <tickslock>
        havekids = 1;
    800025fa:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025fc:	0000fc17          	auipc	s8,0xf
    80002600:	13cc0c13          	addi	s8,s8,316 # 80011738 <wait_lock>
    havekids = 0;
    80002604:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002606:	0000f497          	auipc	s1,0xf
    8000260a:	14a48493          	addi	s1,s1,330 # 80011750 <proc>
    8000260e:	a0bd                	j	8000267c <wait+0xc2>
          pid = np->pid;
    80002610:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002614:	000b0e63          	beqz	s6,80002630 <wait+0x76>
    80002618:	4691                	li	a3,4
    8000261a:	02c48613          	addi	a2,s1,44
    8000261e:	85da                	mv	a1,s6
    80002620:	05093503          	ld	a0,80(s2)
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	04e080e7          	jalr	78(ra) # 80001672 <copyout>
    8000262c:	02054563          	bltz	a0,80002656 <wait+0x9c>
          freeproc(np);
    80002630:	8526                	mv	a0,s1
    80002632:	00000097          	auipc	ra,0x0
    80002636:	89e080e7          	jalr	-1890(ra) # 80001ed0 <freeproc>
          release(&np->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	65c080e7          	jalr	1628(ra) # 80000c98 <release>
          release(&wait_lock);
    80002644:	0000f517          	auipc	a0,0xf
    80002648:	0f450513          	addi	a0,a0,244 # 80011738 <wait_lock>
    8000264c:	ffffe097          	auipc	ra,0xffffe
    80002650:	64c080e7          	jalr	1612(ra) # 80000c98 <release>
          return pid;
    80002654:	a09d                	j	800026ba <wait+0x100>
            release(&np->lock);
    80002656:	8526                	mv	a0,s1
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	640080e7          	jalr	1600(ra) # 80000c98 <release>
            release(&wait_lock);
    80002660:	0000f517          	auipc	a0,0xf
    80002664:	0d850513          	addi	a0,a0,216 # 80011738 <wait_lock>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
            return -1;
    80002670:	59fd                	li	s3,-1
    80002672:	a0a1                	j	800026ba <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002674:	17848493          	addi	s1,s1,376
    80002678:	03348463          	beq	s1,s3,800026a0 <wait+0xe6>
      if(np->parent == p){
    8000267c:	7c9c                	ld	a5,56(s1)
    8000267e:	ff279be3          	bne	a5,s2,80002674 <wait+0xba>
        acquire(&np->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000268c:	4c9c                	lw	a5,24(s1)
    8000268e:	f94781e3          	beq	a5,s4,80002610 <wait+0x56>
        release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
        havekids = 1;
    8000269c:	8756                	mv	a4,s5
    8000269e:	bfd9                	j	80002674 <wait+0xba>
    if(!havekids || p->killed){
    800026a0:	c701                	beqz	a4,800026a8 <wait+0xee>
    800026a2:	02892783          	lw	a5,40(s2)
    800026a6:	c79d                	beqz	a5,800026d4 <wait+0x11a>
      release(&wait_lock);
    800026a8:	0000f517          	auipc	a0,0xf
    800026ac:	09050513          	addi	a0,a0,144 # 80011738 <wait_lock>
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
      return -1;
    800026b8:	59fd                	li	s3,-1
}
    800026ba:	854e                	mv	a0,s3
    800026bc:	60a6                	ld	ra,72(sp)
    800026be:	6406                	ld	s0,64(sp)
    800026c0:	74e2                	ld	s1,56(sp)
    800026c2:	7942                	ld	s2,48(sp)
    800026c4:	79a2                	ld	s3,40(sp)
    800026c6:	7a02                	ld	s4,32(sp)
    800026c8:	6ae2                	ld	s5,24(sp)
    800026ca:	6b42                	ld	s6,16(sp)
    800026cc:	6ba2                	ld	s7,8(sp)
    800026ce:	6c02                	ld	s8,0(sp)
    800026d0:	6161                	addi	sp,sp,80
    800026d2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800026d4:	85e2                	mv	a1,s8
    800026d6:	854a                	mv	a0,s2
    800026d8:	00000097          	auipc	ra,0x0
    800026dc:	e58080e7          	jalr	-424(ra) # 80002530 <sleep>
    havekids = 0;
    800026e0:	b715                	j	80002604 <wait+0x4a>

00000000800026e2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800026e2:	711d                	addi	sp,sp,-96
    800026e4:	ec86                	sd	ra,88(sp)
    800026e6:	e8a2                	sd	s0,80(sp)
    800026e8:	e4a6                	sd	s1,72(sp)
    800026ea:	e0ca                	sd	s2,64(sp)
    800026ec:	fc4e                	sd	s3,56(sp)
    800026ee:	f852                	sd	s4,48(sp)
    800026f0:	f456                	sd	s5,40(sp)
    800026f2:	f05a                	sd	s6,32(sp)
    800026f4:	ec5e                	sd	s7,24(sp)
    800026f6:	e862                	sd	s8,16(sp)
    800026f8:	e466                	sd	s9,8(sp)
    800026fa:	e06a                	sd	s10,0(sp)
    800026fc:	1080                	addi	s0,sp,96
    800026fe:	8a2a                	mv	s4,a0
  struct proc *p;
  struct cpu *c;
  //int curr = sleeping_list.head;
  //int next;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002700:	0000f497          	auipc	s1,0xf
    80002704:	05048493          	addi	s1,s1,80 # 80011750 <proc>
  //while(curr) {
    //p = &proc[curr];
    //next = p->next_index;
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002708:	4989                	li	s3,2
        c = &cpus[p->last_cpu];
        p->state = RUNNABLE;
    8000270a:	4c8d                	li	s9,3
        printf("remove wakeup sleep %d\n", p->index); //delete
    8000270c:	00006c17          	auipc	s8,0x6
    80002710:	cd4c0c13          	addi	s8,s8,-812 # 800083e0 <digits+0x3a0>
        remove_proc_to_list(&sleeping_list, p);
    80002714:	00006b97          	auipc	s7,0x6
    80002718:	2ecb8b93          	addi	s7,s7,748 # 80008a00 <sleeping_list>
        //printf("pp  nexttttt %d\n", p->next_index); //delete
        printf("insert wakeup runnable %d\n", p->index); //delete
    8000271c:	00006b17          	auipc	s6,0x6
    80002720:	cdcb0b13          	addi	s6,s6,-804 # 800083f8 <digits+0x3b8>
        insert_proc_to_list(&(c->runnable_list), p);
    80002724:	0000fa97          	auipc	s5,0xf
    80002728:	b7ca8a93          	addi	s5,s5,-1156 # 800112a0 <cpus>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000272c:	00015917          	auipc	s2,0x15
    80002730:	e2490913          	addi	s2,s2,-476 # 80017550 <tickslock>
    80002734:	a811                	j	80002748 <wakeup+0x66>
      }
      release(&p->lock);
    80002736:	8526                	mv	a0,s1
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	560080e7          	jalr	1376(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002740:	17848493          	addi	s1,s1,376
    80002744:	07248863          	beq	s1,s2,800027b4 <wakeup+0xd2>
    if(p != myproc()){
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	5da080e7          	jalr	1498(ra) # 80001d22 <myproc>
    80002750:	fea488e3          	beq	s1,a0,80002740 <wakeup+0x5e>
      acquire(&p->lock);
    80002754:	8526                	mv	a0,s1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	48e080e7          	jalr	1166(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000275e:	4c9c                	lw	a5,24(s1)
    80002760:	fd379be3          	bne	a5,s3,80002736 <wakeup+0x54>
    80002764:	709c                	ld	a5,32(s1)
    80002766:	fd4798e3          	bne	a5,s4,80002736 <wakeup+0x54>
        c = &cpus[p->last_cpu];
    8000276a:	1684ad03          	lw	s10,360(s1)
        p->state = RUNNABLE;
    8000276e:	0194ac23          	sw	s9,24(s1)
        printf("remove wakeup sleep %d\n", p->index); //delete
    80002772:	16c4a583          	lw	a1,364(s1)
    80002776:	8562                	mv	a0,s8
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	e10080e7          	jalr	-496(ra) # 80000588 <printf>
        remove_proc_to_list(&sleeping_list, p);
    80002780:	85a6                	mv	a1,s1
    80002782:	855e                	mv	a0,s7
    80002784:	fffff097          	auipc	ra,0xfffff
    80002788:	24a080e7          	jalr	586(ra) # 800019ce <remove_proc_to_list>
        printf("insert wakeup runnable %d\n", p->index); //delete
    8000278c:	16c4a583          	lw	a1,364(s1)
    80002790:	855a                	mv	a0,s6
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
        insert_proc_to_list(&(c->runnable_list), p);
    8000279a:	003d1513          	slli	a0,s10,0x3
    8000279e:	956a                	add	a0,a0,s10
    800027a0:	0512                	slli	a0,a0,0x4
    800027a2:	08050513          	addi	a0,a0,128
    800027a6:	85a6                	mv	a1,s1
    800027a8:	9556                	add	a0,a0,s5
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	162080e7          	jalr	354(ra) # 8000190c <insert_proc_to_list>
    800027b2:	b751                	j	80002736 <wakeup+0x54>
    }
    //printf("nexttttt222 %d\n", next); //delete
    //curr = next;
    //printf("currr2222 %d\n", curr); //delete
  }
}
    800027b4:	60e6                	ld	ra,88(sp)
    800027b6:	6446                	ld	s0,80(sp)
    800027b8:	64a6                	ld	s1,72(sp)
    800027ba:	6906                	ld	s2,64(sp)
    800027bc:	79e2                	ld	s3,56(sp)
    800027be:	7a42                	ld	s4,48(sp)
    800027c0:	7aa2                	ld	s5,40(sp)
    800027c2:	7b02                	ld	s6,32(sp)
    800027c4:	6be2                	ld	s7,24(sp)
    800027c6:	6c42                	ld	s8,16(sp)
    800027c8:	6ca2                	ld	s9,8(sp)
    800027ca:	6d02                	ld	s10,0(sp)
    800027cc:	6125                	addi	sp,sp,96
    800027ce:	8082                	ret

00000000800027d0 <reparent>:
{
    800027d0:	7179                	addi	sp,sp,-48
    800027d2:	f406                	sd	ra,40(sp)
    800027d4:	f022                	sd	s0,32(sp)
    800027d6:	ec26                	sd	s1,24(sp)
    800027d8:	e84a                	sd	s2,16(sp)
    800027da:	e44e                	sd	s3,8(sp)
    800027dc:	e052                	sd	s4,0(sp)
    800027de:	1800                	addi	s0,sp,48
    800027e0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027e2:	0000f497          	auipc	s1,0xf
    800027e6:	f6e48493          	addi	s1,s1,-146 # 80011750 <proc>
      pp->parent = initproc;
    800027ea:	00007a17          	auipc	s4,0x7
    800027ee:	83ea0a13          	addi	s4,s4,-1986 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027f2:	00015997          	auipc	s3,0x15
    800027f6:	d5e98993          	addi	s3,s3,-674 # 80017550 <tickslock>
    800027fa:	a029                	j	80002804 <reparent+0x34>
    800027fc:	17848493          	addi	s1,s1,376
    80002800:	01348d63          	beq	s1,s3,8000281a <reparent+0x4a>
    if(pp->parent == p){
    80002804:	7c9c                	ld	a5,56(s1)
    80002806:	ff279be3          	bne	a5,s2,800027fc <reparent+0x2c>
      pp->parent = initproc;
    8000280a:	000a3503          	ld	a0,0(s4)
    8000280e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002810:	00000097          	auipc	ra,0x0
    80002814:	ed2080e7          	jalr	-302(ra) # 800026e2 <wakeup>
    80002818:	b7d5                	j	800027fc <reparent+0x2c>
}
    8000281a:	70a2                	ld	ra,40(sp)
    8000281c:	7402                	ld	s0,32(sp)
    8000281e:	64e2                	ld	s1,24(sp)
    80002820:	6942                	ld	s2,16(sp)
    80002822:	69a2                	ld	s3,8(sp)
    80002824:	6a02                	ld	s4,0(sp)
    80002826:	6145                	addi	sp,sp,48
    80002828:	8082                	ret

000000008000282a <exit>:
{
    8000282a:	7179                	addi	sp,sp,-48
    8000282c:	f406                	sd	ra,40(sp)
    8000282e:	f022                	sd	s0,32(sp)
    80002830:	ec26                	sd	s1,24(sp)
    80002832:	e84a                	sd	s2,16(sp)
    80002834:	e44e                	sd	s3,8(sp)
    80002836:	e052                	sd	s4,0(sp)
    80002838:	1800                	addi	s0,sp,48
    8000283a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	4e6080e7          	jalr	1254(ra) # 80001d22 <myproc>
    80002844:	89aa                	mv	s3,a0
  if(p == initproc)
    80002846:	00006797          	auipc	a5,0x6
    8000284a:	7e27b783          	ld	a5,2018(a5) # 80009028 <initproc>
    8000284e:	0d050493          	addi	s1,a0,208
    80002852:	15050913          	addi	s2,a0,336
    80002856:	02a79363          	bne	a5,a0,8000287c <exit+0x52>
    panic("init exiting");
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	bbe50513          	addi	a0,a0,-1090 # 80008418 <digits+0x3d8>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	cdc080e7          	jalr	-804(ra) # 8000053e <panic>
      fileclose(f);
    8000286a:	00002097          	auipc	ra,0x2
    8000286e:	242080e7          	jalr	578(ra) # 80004aac <fileclose>
      p->ofile[fd] = 0;
    80002872:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002876:	04a1                	addi	s1,s1,8
    80002878:	01248563          	beq	s1,s2,80002882 <exit+0x58>
    if(p->ofile[fd]){
    8000287c:	6088                	ld	a0,0(s1)
    8000287e:	f575                	bnez	a0,8000286a <exit+0x40>
    80002880:	bfdd                	j	80002876 <exit+0x4c>
  begin_op();
    80002882:	00002097          	auipc	ra,0x2
    80002886:	d5e080e7          	jalr	-674(ra) # 800045e0 <begin_op>
  iput(p->cwd);
    8000288a:	1509b503          	ld	a0,336(s3)
    8000288e:	00001097          	auipc	ra,0x1
    80002892:	53a080e7          	jalr	1338(ra) # 80003dc8 <iput>
  end_op();
    80002896:	00002097          	auipc	ra,0x2
    8000289a:	dca080e7          	jalr	-566(ra) # 80004660 <end_op>
  p->cwd = 0;
    8000289e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800028a2:	0000f497          	auipc	s1,0xf
    800028a6:	e9648493          	addi	s1,s1,-362 # 80011738 <wait_lock>
    800028aa:	8526                	mv	a0,s1
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	338080e7          	jalr	824(ra) # 80000be4 <acquire>
  reparent(p);
    800028b4:	854e                	mv	a0,s3
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	f1a080e7          	jalr	-230(ra) # 800027d0 <reparent>
  wakeup(p->parent);
    800028be:	0389b503          	ld	a0,56(s3)
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	e20080e7          	jalr	-480(ra) # 800026e2 <wakeup>
  acquire(&p->lock);
    800028ca:	854e                	mv	a0,s3
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	318080e7          	jalr	792(ra) # 80000be4 <acquire>
  p->xstate = status;
    800028d4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800028d8:	4795                	li	a5,5
    800028da:	00f9ac23          	sw	a5,24(s3)
  printf("insert exit zombie %d\n", p->index); //delete
    800028de:	16c9a583          	lw	a1,364(s3)
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	b4650513          	addi	a0,a0,-1210 # 80008428 <digits+0x3e8>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c9e080e7          	jalr	-866(ra) # 80000588 <printf>
  insert_proc_to_list(&zombie_list, p); // exit to admit the exiting process to the ZOMBIE list
    800028f2:	85ce                	mv	a1,s3
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	10450513          	addi	a0,a0,260 # 800089f8 <zombie_list>
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	010080e7          	jalr	16(ra) # 8000190c <insert_proc_to_list>
  release(&wait_lock);
    80002904:	8526                	mv	a0,s1
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	392080e7          	jalr	914(ra) # 80000c98 <release>
  sched();
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	abe080e7          	jalr	-1346(ra) # 800023cc <sched>
  panic("zombie exit");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	b2a50513          	addi	a0,a0,-1238 # 80008440 <digits+0x400>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>

0000000080002926 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002926:	7179                	addi	sp,sp,-48
    80002928:	f406                	sd	ra,40(sp)
    8000292a:	f022                	sd	s0,32(sp)
    8000292c:	ec26                	sd	s1,24(sp)
    8000292e:	e84a                	sd	s2,16(sp)
    80002930:	e44e                	sd	s3,8(sp)
    80002932:	1800                	addi	s0,sp,48
    80002934:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002936:	0000f497          	auipc	s1,0xf
    8000293a:	e1a48493          	addi	s1,s1,-486 # 80011750 <proc>
    8000293e:	00015997          	auipc	s3,0x15
    80002942:	c1298993          	addi	s3,s3,-1006 # 80017550 <tickslock>
    acquire(&p->lock);
    80002946:	8526                	mv	a0,s1
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002950:	589c                	lw	a5,48(s1)
    80002952:	01278d63          	beq	a5,s2,8000296c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002956:	8526                	mv	a0,s1
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	340080e7          	jalr	832(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002960:	17848493          	addi	s1,s1,376
    80002964:	ff3491e3          	bne	s1,s3,80002946 <kill+0x20>
  }
  return -1;
    80002968:	557d                	li	a0,-1
    8000296a:	a829                	j	80002984 <kill+0x5e>
      p->killed = 1;
    8000296c:	4785                	li	a5,1
    8000296e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002970:	4c98                	lw	a4,24(s1)
    80002972:	4789                	li	a5,2
    80002974:	00f70f63          	beq	a4,a5,80002992 <kill+0x6c>
      release(&p->lock);
    80002978:	8526                	mv	a0,s1
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
      return 0;
    80002982:	4501                	li	a0,0
}
    80002984:	70a2                	ld	ra,40(sp)
    80002986:	7402                	ld	s0,32(sp)
    80002988:	64e2                	ld	s1,24(sp)
    8000298a:	6942                	ld	s2,16(sp)
    8000298c:	69a2                	ld	s3,8(sp)
    8000298e:	6145                	addi	sp,sp,48
    80002990:	8082                	ret
        p->state = RUNNABLE;
    80002992:	478d                	li	a5,3
    80002994:	cc9c                	sw	a5,24(s1)
    80002996:	b7cd                	j	80002978 <kill+0x52>

0000000080002998 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002998:	7179                	addi	sp,sp,-48
    8000299a:	f406                	sd	ra,40(sp)
    8000299c:	f022                	sd	s0,32(sp)
    8000299e:	ec26                	sd	s1,24(sp)
    800029a0:	e84a                	sd	s2,16(sp)
    800029a2:	e44e                	sd	s3,8(sp)
    800029a4:	e052                	sd	s4,0(sp)
    800029a6:	1800                	addi	s0,sp,48
    800029a8:	84aa                	mv	s1,a0
    800029aa:	892e                	mv	s2,a1
    800029ac:	89b2                	mv	s3,a2
    800029ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	372080e7          	jalr	882(ra) # 80001d22 <myproc>
  if(user_dst){
    800029b8:	c08d                	beqz	s1,800029da <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029ba:	86d2                	mv	a3,s4
    800029bc:	864e                	mv	a2,s3
    800029be:	85ca                	mv	a1,s2
    800029c0:	6928                	ld	a0,80(a0)
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	cb0080e7          	jalr	-848(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029ca:	70a2                	ld	ra,40(sp)
    800029cc:	7402                	ld	s0,32(sp)
    800029ce:	64e2                	ld	s1,24(sp)
    800029d0:	6942                	ld	s2,16(sp)
    800029d2:	69a2                	ld	s3,8(sp)
    800029d4:	6a02                	ld	s4,0(sp)
    800029d6:	6145                	addi	sp,sp,48
    800029d8:	8082                	ret
    memmove((char *)dst, src, len);
    800029da:	000a061b          	sext.w	a2,s4
    800029de:	85ce                	mv	a1,s3
    800029e0:	854a                	mv	a0,s2
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	35e080e7          	jalr	862(ra) # 80000d40 <memmove>
    return 0;
    800029ea:	8526                	mv	a0,s1
    800029ec:	bff9                	j	800029ca <either_copyout+0x32>

00000000800029ee <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800029ee:	7179                	addi	sp,sp,-48
    800029f0:	f406                	sd	ra,40(sp)
    800029f2:	f022                	sd	s0,32(sp)
    800029f4:	ec26                	sd	s1,24(sp)
    800029f6:	e84a                	sd	s2,16(sp)
    800029f8:	e44e                	sd	s3,8(sp)
    800029fa:	e052                	sd	s4,0(sp)
    800029fc:	1800                	addi	s0,sp,48
    800029fe:	892a                	mv	s2,a0
    80002a00:	84ae                	mv	s1,a1
    80002a02:	89b2                	mv	s3,a2
    80002a04:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	31c080e7          	jalr	796(ra) # 80001d22 <myproc>
  if(user_src){
    80002a0e:	c08d                	beqz	s1,80002a30 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a10:	86d2                	mv	a3,s4
    80002a12:	864e                	mv	a2,s3
    80002a14:	85ca                	mv	a1,s2
    80002a16:	6928                	ld	a0,80(a0)
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	ce6080e7          	jalr	-794(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a20:	70a2                	ld	ra,40(sp)
    80002a22:	7402                	ld	s0,32(sp)
    80002a24:	64e2                	ld	s1,24(sp)
    80002a26:	6942                	ld	s2,16(sp)
    80002a28:	69a2                	ld	s3,8(sp)
    80002a2a:	6a02                	ld	s4,0(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a30:	000a061b          	sext.w	a2,s4
    80002a34:	85ce                	mv	a1,s3
    80002a36:	854a                	mv	a0,s2
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	308080e7          	jalr	776(ra) # 80000d40 <memmove>
    return 0;
    80002a40:	8526                	mv	a0,s1
    80002a42:	bff9                	j	80002a20 <either_copyin+0x32>

0000000080002a44 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further..
void
procdump(void){
    80002a44:	715d                	addi	sp,sp,-80
    80002a46:	e486                	sd	ra,72(sp)
    80002a48:	e0a2                	sd	s0,64(sp)
    80002a4a:	fc26                	sd	s1,56(sp)
    80002a4c:	f84a                	sd	s2,48(sp)
    80002a4e:	f44e                	sd	s3,40(sp)
    80002a50:	f052                	sd	s4,32(sp)
    80002a52:	ec56                	sd	s5,24(sp)
    80002a54:	e85a                	sd	s6,16(sp)
    80002a56:	e45e                	sd	s7,8(sp)
    80002a58:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	8fe50513          	addi	a0,a0,-1794 # 80008358 <digits+0x318>
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	b26080e7          	jalr	-1242(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a6a:	0000f497          	auipc	s1,0xf
    80002a6e:	e3e48493          	addi	s1,s1,-450 # 800118a8 <proc+0x158>
    80002a72:	00015917          	auipc	s2,0x15
    80002a76:	c3690913          	addi	s2,s2,-970 # 800176a8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a7a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???"; 
    80002a7c:	00006997          	auipc	s3,0x6
    80002a80:	9d498993          	addi	s3,s3,-1580 # 80008450 <digits+0x410>
    printf("%d %s %s", p->pid, state, p->name);
    80002a84:	00006a97          	auipc	s5,0x6
    80002a88:	9d4a8a93          	addi	s5,s5,-1580 # 80008458 <digits+0x418>
    printf("\n");
    80002a8c:	00006a17          	auipc	s4,0x6
    80002a90:	8cca0a13          	addi	s4,s4,-1844 # 80008358 <digits+0x318>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a94:	00006b97          	auipc	s7,0x6
    80002a98:	9fcb8b93          	addi	s7,s7,-1540 # 80008490 <states.1791>
    80002a9c:	a00d                	j	80002abe <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a9e:	ed86a583          	lw	a1,-296(a3)
    80002aa2:	8556                	mv	a0,s5
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	ae4080e7          	jalr	-1308(ra) # 80000588 <printf>
    printf("\n");
    80002aac:	8552                	mv	a0,s4
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	ada080e7          	jalr	-1318(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ab6:	17848493          	addi	s1,s1,376
    80002aba:	03248163          	beq	s1,s2,80002adc <procdump+0x98>
    if(p->state == UNUSED)
    80002abe:	86a6                	mv	a3,s1
    80002ac0:	ec04a783          	lw	a5,-320(s1)
    80002ac4:	dbed                	beqz	a5,80002ab6 <procdump+0x72>
      state = "???"; 
    80002ac6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ac8:	fcfb6be3          	bltu	s6,a5,80002a9e <procdump+0x5a>
    80002acc:	1782                	slli	a5,a5,0x20
    80002ace:	9381                	srli	a5,a5,0x20
    80002ad0:	078e                	slli	a5,a5,0x3
    80002ad2:	97de                	add	a5,a5,s7
    80002ad4:	6390                	ld	a2,0(a5)
    80002ad6:	f661                	bnez	a2,80002a9e <procdump+0x5a>
      state = "???"; 
    80002ad8:	864e                	mv	a2,s3
    80002ada:	b7d1                	j	80002a9e <procdump+0x5a>
  }
}
    80002adc:	60a6                	ld	ra,72(sp)
    80002ade:	6406                	ld	s0,64(sp)
    80002ae0:	74e2                	ld	s1,56(sp)
    80002ae2:	7942                	ld	s2,48(sp)
    80002ae4:	79a2                	ld	s3,40(sp)
    80002ae6:	7a02                	ld	s4,32(sp)
    80002ae8:	6ae2                	ld	s5,24(sp)
    80002aea:	6b42                	ld	s6,16(sp)
    80002aec:	6ba2                	ld	s7,8(sp)
    80002aee:	6161                	addi	sp,sp,80
    80002af0:	8082                	ret

0000000080002af2 <set_cpu>:

// assign current process to a different CPU. 
int
set_cpu(int cpu_num){
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	e04a                	sd	s2,0(sp)
    80002afc:	1000                	addi	s0,sp,32
    80002afe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	222080e7          	jalr	546(ra) # 80001d22 <myproc>
  if(cpu_num >= 0 && cpu_num < NCPU && &cpus[cpu_num] != NULL){
    80002b08:	0004871b          	sext.w	a4,s1
    80002b0c:	479d                	li	a5,7
    80002b0e:	02e7e963          	bltu	a5,a4,80002b40 <set_cpu+0x4e>
    80002b12:	892a                	mv	s2,a0
    acquire(&p->lock);
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	0d0080e7          	jalr	208(ra) # 80000be4 <acquire>
    p->last_cpu = cpu_num;
    80002b1c:	16992423          	sw	s1,360(s2)
    release(&p->lock);
    80002b20:	854a                	mv	a0,s2
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	176080e7          	jalr	374(ra) # 80000c98 <release>

    yield();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	990080e7          	jalr	-1648(ra) # 800024ba <yield>

    return cpu_num;
    80002b32:	8526                	mv	a0,s1
  }
  return -1;
}
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6902                	ld	s2,0(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret
  return -1;
    80002b40:	557d                	li	a0,-1
    80002b42:	bfcd                	j	80002b34 <set_cpu+0x42>

0000000080002b44 <get_cpu>:

// return the current CPU id.
int
get_cpu(void){
    80002b44:	1141                	addi	sp,sp,-16
    80002b46:	e406                	sd	ra,8(sp)
    80002b48:	e022                	sd	s0,0(sp)
    80002b4a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	1d6080e7          	jalr	470(ra) # 80001d22 <myproc>
  return p->last_cpu;
    80002b54:	16852503          	lw	a0,360(a0)
    80002b58:	60a2                	ld	ra,8(sp)
    80002b5a:	6402                	ld	s0,0(sp)
    80002b5c:	0141                	addi	sp,sp,16
    80002b5e:	8082                	ret

0000000080002b60 <swtch>:
    80002b60:	00153023          	sd	ra,0(a0)
    80002b64:	00253423          	sd	sp,8(a0)
    80002b68:	e900                	sd	s0,16(a0)
    80002b6a:	ed04                	sd	s1,24(a0)
    80002b6c:	03253023          	sd	s2,32(a0)
    80002b70:	03353423          	sd	s3,40(a0)
    80002b74:	03453823          	sd	s4,48(a0)
    80002b78:	03553c23          	sd	s5,56(a0)
    80002b7c:	05653023          	sd	s6,64(a0)
    80002b80:	05753423          	sd	s7,72(a0)
    80002b84:	05853823          	sd	s8,80(a0)
    80002b88:	05953c23          	sd	s9,88(a0)
    80002b8c:	07a53023          	sd	s10,96(a0)
    80002b90:	07b53423          	sd	s11,104(a0)
    80002b94:	0005b083          	ld	ra,0(a1)
    80002b98:	0085b103          	ld	sp,8(a1)
    80002b9c:	6980                	ld	s0,16(a1)
    80002b9e:	6d84                	ld	s1,24(a1)
    80002ba0:	0205b903          	ld	s2,32(a1)
    80002ba4:	0285b983          	ld	s3,40(a1)
    80002ba8:	0305ba03          	ld	s4,48(a1)
    80002bac:	0385ba83          	ld	s5,56(a1)
    80002bb0:	0405bb03          	ld	s6,64(a1)
    80002bb4:	0485bb83          	ld	s7,72(a1)
    80002bb8:	0505bc03          	ld	s8,80(a1)
    80002bbc:	0585bc83          	ld	s9,88(a1)
    80002bc0:	0605bd03          	ld	s10,96(a1)
    80002bc4:	0685bd83          	ld	s11,104(a1)
    80002bc8:	8082                	ret

0000000080002bca <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e406                	sd	ra,8(sp)
    80002bce:	e022                	sd	s0,0(sp)
    80002bd0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bd2:	00006597          	auipc	a1,0x6
    80002bd6:	8ee58593          	addi	a1,a1,-1810 # 800084c0 <states.1791+0x30>
    80002bda:	00015517          	auipc	a0,0x15
    80002bde:	97650513          	addi	a0,a0,-1674 # 80017550 <tickslock>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	f72080e7          	jalr	-142(ra) # 80000b54 <initlock>
}
    80002bea:	60a2                	ld	ra,8(sp)
    80002bec:	6402                	ld	s0,0(sp)
    80002bee:	0141                	addi	sp,sp,16
    80002bf0:	8082                	ret

0000000080002bf2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bf2:	1141                	addi	sp,sp,-16
    80002bf4:	e422                	sd	s0,8(sp)
    80002bf6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf8:	00003797          	auipc	a5,0x3
    80002bfc:	4c878793          	addi	a5,a5,1224 # 800060c0 <kernelvec>
    80002c00:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002c04:	6422                	ld	s0,8(sp)
    80002c06:	0141                	addi	sp,sp,16
    80002c08:	8082                	ret

0000000080002c0a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c0a:	1141                	addi	sp,sp,-16
    80002c0c:	e406                	sd	ra,8(sp)
    80002c0e:	e022                	sd	s0,0(sp)
    80002c10:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	110080e7          	jalr	272(ra) # 80001d22 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c1e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c20:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c24:	00004617          	auipc	a2,0x4
    80002c28:	3dc60613          	addi	a2,a2,988 # 80007000 <_trampoline>
    80002c2c:	00004697          	auipc	a3,0x4
    80002c30:	3d468693          	addi	a3,a3,980 # 80007000 <_trampoline>
    80002c34:	8e91                	sub	a3,a3,a2
    80002c36:	040007b7          	lui	a5,0x4000
    80002c3a:	17fd                	addi	a5,a5,-1
    80002c3c:	07b2                	slli	a5,a5,0xc
    80002c3e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c40:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c44:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c46:	180026f3          	csrr	a3,satp
    80002c4a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c4c:	6d38                	ld	a4,88(a0)
    80002c4e:	6134                	ld	a3,64(a0)
    80002c50:	6585                	lui	a1,0x1
    80002c52:	96ae                	add	a3,a3,a1
    80002c54:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c56:	6d38                	ld	a4,88(a0)
    80002c58:	00000697          	auipc	a3,0x0
    80002c5c:	13868693          	addi	a3,a3,312 # 80002d90 <usertrap>
    80002c60:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c62:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c64:	8692                	mv	a3,tp
    80002c66:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c68:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c6c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c70:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c74:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c78:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c7a:	6f18                	ld	a4,24(a4)
    80002c7c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c80:	692c                	ld	a1,80(a0)
    80002c82:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c84:	00004717          	auipc	a4,0x4
    80002c88:	40c70713          	addi	a4,a4,1036 # 80007090 <userret>
    80002c8c:	8f11                	sub	a4,a4,a2
    80002c8e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c90:	577d                	li	a4,-1
    80002c92:	177e                	slli	a4,a4,0x3f
    80002c94:	8dd9                	or	a1,a1,a4
    80002c96:	02000537          	lui	a0,0x2000
    80002c9a:	157d                	addi	a0,a0,-1
    80002c9c:	0536                	slli	a0,a0,0xd
    80002c9e:	9782                	jalr	a5
}
    80002ca0:	60a2                	ld	ra,8(sp)
    80002ca2:	6402                	ld	s0,0(sp)
    80002ca4:	0141                	addi	sp,sp,16
    80002ca6:	8082                	ret

0000000080002ca8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ca8:	1101                	addi	sp,sp,-32
    80002caa:	ec06                	sd	ra,24(sp)
    80002cac:	e822                	sd	s0,16(sp)
    80002cae:	e426                	sd	s1,8(sp)
    80002cb0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002cb2:	00015497          	auipc	s1,0x15
    80002cb6:	89e48493          	addi	s1,s1,-1890 # 80017550 <tickslock>
    80002cba:	8526                	mv	a0,s1
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	f28080e7          	jalr	-216(ra) # 80000be4 <acquire>
  ticks++;
    80002cc4:	00006517          	auipc	a0,0x6
    80002cc8:	36c50513          	addi	a0,a0,876 # 80009030 <ticks>
    80002ccc:	411c                	lw	a5,0(a0)
    80002cce:	2785                	addiw	a5,a5,1
    80002cd0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	a10080e7          	jalr	-1520(ra) # 800026e2 <wakeup>
  release(&tickslock);
    80002cda:	8526                	mv	a0,s1
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	fbc080e7          	jalr	-68(ra) # 80000c98 <release>
}
    80002ce4:	60e2                	ld	ra,24(sp)
    80002ce6:	6442                	ld	s0,16(sp)
    80002ce8:	64a2                	ld	s1,8(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cf8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cfc:	00074d63          	bltz	a4,80002d16 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002d00:	57fd                	li	a5,-1
    80002d02:	17fe                	slli	a5,a5,0x3f
    80002d04:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002d06:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d08:	06f70363          	beq	a4,a5,80002d6e <devintr+0x80>
  }
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6105                	addi	sp,sp,32
    80002d14:	8082                	ret
     (scause & 0xff) == 9){
    80002d16:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d1a:	46a5                	li	a3,9
    80002d1c:	fed792e3          	bne	a5,a3,80002d00 <devintr+0x12>
    int irq = plic_claim();
    80002d20:	00003097          	auipc	ra,0x3
    80002d24:	4a8080e7          	jalr	1192(ra) # 800061c8 <plic_claim>
    80002d28:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d2a:	47a9                	li	a5,10
    80002d2c:	02f50763          	beq	a0,a5,80002d5a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d30:	4785                	li	a5,1
    80002d32:	02f50963          	beq	a0,a5,80002d64 <devintr+0x76>
    return 1;
    80002d36:	4505                	li	a0,1
    } else if(irq){
    80002d38:	d8f1                	beqz	s1,80002d0c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d3a:	85a6                	mv	a1,s1
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	78c50513          	addi	a0,a0,1932 # 800084c8 <states.1791+0x38>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	844080e7          	jalr	-1980(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d4c:	8526                	mv	a0,s1
    80002d4e:	00003097          	auipc	ra,0x3
    80002d52:	49e080e7          	jalr	1182(ra) # 800061ec <plic_complete>
    return 1;
    80002d56:	4505                	li	a0,1
    80002d58:	bf55                	j	80002d0c <devintr+0x1e>
      uartintr();
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	c4e080e7          	jalr	-946(ra) # 800009a8 <uartintr>
    80002d62:	b7ed                	j	80002d4c <devintr+0x5e>
      virtio_disk_intr();
    80002d64:	00004097          	auipc	ra,0x4
    80002d68:	968080e7          	jalr	-1688(ra) # 800066cc <virtio_disk_intr>
    80002d6c:	b7c5                	j	80002d4c <devintr+0x5e>
    if(cpuid() == 0){
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	f80080e7          	jalr	-128(ra) # 80001cee <cpuid>
    80002d76:	c901                	beqz	a0,80002d86 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d78:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d7c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d7e:	14479073          	csrw	sip,a5
    return 2;
    80002d82:	4509                	li	a0,2
    80002d84:	b761                	j	80002d0c <devintr+0x1e>
      clockintr();
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	f22080e7          	jalr	-222(ra) # 80002ca8 <clockintr>
    80002d8e:	b7ed                	j	80002d78 <devintr+0x8a>

0000000080002d90 <usertrap>:
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	e04a                	sd	s2,0(sp)
    80002d9a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002da0:	1007f793          	andi	a5,a5,256
    80002da4:	e3ad                	bnez	a5,80002e06 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002da6:	00003797          	auipc	a5,0x3
    80002daa:	31a78793          	addi	a5,a5,794 # 800060c0 <kernelvec>
    80002dae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	f70080e7          	jalr	-144(ra) # 80001d22 <myproc>
    80002dba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002dbc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dbe:	14102773          	csrr	a4,sepc
    80002dc2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dc4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002dc8:	47a1                	li	a5,8
    80002dca:	04f71c63          	bne	a4,a5,80002e22 <usertrap+0x92>
    if(p->killed)
    80002dce:	551c                	lw	a5,40(a0)
    80002dd0:	e3b9                	bnez	a5,80002e16 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002dd2:	6cb8                	ld	a4,88(s1)
    80002dd4:	6f1c                	ld	a5,24(a4)
    80002dd6:	0791                	addi	a5,a5,4
    80002dd8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002de2:	10079073          	csrw	sstatus,a5
    syscall();
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	2e0080e7          	jalr	736(ra) # 800030c6 <syscall>
  if(p->killed)
    80002dee:	549c                	lw	a5,40(s1)
    80002df0:	ebc1                	bnez	a5,80002e80 <usertrap+0xf0>
  usertrapret();
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	e18080e7          	jalr	-488(ra) # 80002c0a <usertrapret>
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6902                	ld	s2,0(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret
    panic("usertrap: not from user mode");
    80002e06:	00005517          	auipc	a0,0x5
    80002e0a:	6e250513          	addi	a0,a0,1762 # 800084e8 <states.1791+0x58>
    80002e0e:	ffffd097          	auipc	ra,0xffffd
    80002e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>
      exit(-1);
    80002e16:	557d                	li	a0,-1
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	a12080e7          	jalr	-1518(ra) # 8000282a <exit>
    80002e20:	bf4d                	j	80002dd2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	ecc080e7          	jalr	-308(ra) # 80002cee <devintr>
    80002e2a:	892a                	mv	s2,a0
    80002e2c:	c501                	beqz	a0,80002e34 <usertrap+0xa4>
  if(p->killed)
    80002e2e:	549c                	lw	a5,40(s1)
    80002e30:	c3a1                	beqz	a5,80002e70 <usertrap+0xe0>
    80002e32:	a815                	j	80002e66 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e34:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e38:	5890                	lw	a2,48(s1)
    80002e3a:	00005517          	auipc	a0,0x5
    80002e3e:	6ce50513          	addi	a0,a0,1742 # 80008508 <states.1791+0x78>
    80002e42:	ffffd097          	auipc	ra,0xffffd
    80002e46:	746080e7          	jalr	1862(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e4e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e52:	00005517          	auipc	a0,0x5
    80002e56:	6e650513          	addi	a0,a0,1766 # 80008538 <states.1791+0xa8>
    80002e5a:	ffffd097          	auipc	ra,0xffffd
    80002e5e:	72e080e7          	jalr	1838(ra) # 80000588 <printf>
    p->killed = 1;
    80002e62:	4785                	li	a5,1
    80002e64:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e66:	557d                	li	a0,-1
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	9c2080e7          	jalr	-1598(ra) # 8000282a <exit>
  if(which_dev == 2)
    80002e70:	4789                	li	a5,2
    80002e72:	f8f910e3          	bne	s2,a5,80002df2 <usertrap+0x62>
    yield();
    80002e76:	fffff097          	auipc	ra,0xfffff
    80002e7a:	644080e7          	jalr	1604(ra) # 800024ba <yield>
    80002e7e:	bf95                	j	80002df2 <usertrap+0x62>
  int which_dev = 0;
    80002e80:	4901                	li	s2,0
    80002e82:	b7d5                	j	80002e66 <usertrap+0xd6>

0000000080002e84 <kerneltrap>:
{
    80002e84:	7179                	addi	sp,sp,-48
    80002e86:	f406                	sd	ra,40(sp)
    80002e88:	f022                	sd	s0,32(sp)
    80002e8a:	ec26                	sd	s1,24(sp)
    80002e8c:	e84a                	sd	s2,16(sp)
    80002e8e:	e44e                	sd	s3,8(sp)
    80002e90:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e92:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e96:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e9a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e9e:	1004f793          	andi	a5,s1,256
    80002ea2:	cb85                	beqz	a5,80002ed2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ea8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002eaa:	ef85                	bnez	a5,80002ee2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	e42080e7          	jalr	-446(ra) # 80002cee <devintr>
    80002eb4:	cd1d                	beqz	a0,80002ef2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eb6:	4789                	li	a5,2
    80002eb8:	06f50a63          	beq	a0,a5,80002f2c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ebc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ec0:	10049073          	csrw	sstatus,s1
}
    80002ec4:	70a2                	ld	ra,40(sp)
    80002ec6:	7402                	ld	s0,32(sp)
    80002ec8:	64e2                	ld	s1,24(sp)
    80002eca:	6942                	ld	s2,16(sp)
    80002ecc:	69a2                	ld	s3,8(sp)
    80002ece:	6145                	addi	sp,sp,48
    80002ed0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	68650513          	addi	a0,a0,1670 # 80008558 <states.1791+0xc8>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	69e50513          	addi	a0,a0,1694 # 80008580 <states.1791+0xf0>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ef2:	85ce                	mv	a1,s3
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	6ac50513          	addi	a0,a0,1708 # 800085a0 <states.1791+0x110>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	68c080e7          	jalr	1676(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f08:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	6a450513          	addi	a0,a0,1700 # 800085b0 <states.1791+0x120>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f1c:	00005517          	auipc	a0,0x5
    80002f20:	6ac50513          	addi	a0,a0,1708 # 800085c8 <states.1791+0x138>
    80002f24:	ffffd097          	auipc	ra,0xffffd
    80002f28:	61a080e7          	jalr	1562(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f2c:	fffff097          	auipc	ra,0xfffff
    80002f30:	df6080e7          	jalr	-522(ra) # 80001d22 <myproc>
    80002f34:	d541                	beqz	a0,80002ebc <kerneltrap+0x38>
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	dec080e7          	jalr	-532(ra) # 80001d22 <myproc>
    80002f3e:	4d18                	lw	a4,24(a0)
    80002f40:	4791                	li	a5,4
    80002f42:	f6f71de3          	bne	a4,a5,80002ebc <kerneltrap+0x38>
    yield();
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	574080e7          	jalr	1396(ra) # 800024ba <yield>
    80002f4e:	b7bd                	j	80002ebc <kerneltrap+0x38>

0000000080002f50 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f50:	1101                	addi	sp,sp,-32
    80002f52:	ec06                	sd	ra,24(sp)
    80002f54:	e822                	sd	s0,16(sp)
    80002f56:	e426                	sd	s1,8(sp)
    80002f58:	1000                	addi	s0,sp,32
    80002f5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	dc6080e7          	jalr	-570(ra) # 80001d22 <myproc>
  switch (n) {
    80002f64:	4795                	li	a5,5
    80002f66:	0497e163          	bltu	a5,s1,80002fa8 <argraw+0x58>
    80002f6a:	048a                	slli	s1,s1,0x2
    80002f6c:	00005717          	auipc	a4,0x5
    80002f70:	69470713          	addi	a4,a4,1684 # 80008600 <states.1791+0x170>
    80002f74:	94ba                	add	s1,s1,a4
    80002f76:	409c                	lw	a5,0(s1)
    80002f78:	97ba                	add	a5,a5,a4
    80002f7a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f7c:	6d3c                	ld	a5,88(a0)
    80002f7e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	64a2                	ld	s1,8(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret
    return p->trapframe->a1;
    80002f8a:	6d3c                	ld	a5,88(a0)
    80002f8c:	7fa8                	ld	a0,120(a5)
    80002f8e:	bfcd                	j	80002f80 <argraw+0x30>
    return p->trapframe->a2;
    80002f90:	6d3c                	ld	a5,88(a0)
    80002f92:	63c8                	ld	a0,128(a5)
    80002f94:	b7f5                	j	80002f80 <argraw+0x30>
    return p->trapframe->a3;
    80002f96:	6d3c                	ld	a5,88(a0)
    80002f98:	67c8                	ld	a0,136(a5)
    80002f9a:	b7dd                	j	80002f80 <argraw+0x30>
    return p->trapframe->a4;
    80002f9c:	6d3c                	ld	a5,88(a0)
    80002f9e:	6bc8                	ld	a0,144(a5)
    80002fa0:	b7c5                	j	80002f80 <argraw+0x30>
    return p->trapframe->a5;
    80002fa2:	6d3c                	ld	a5,88(a0)
    80002fa4:	6fc8                	ld	a0,152(a5)
    80002fa6:	bfe9                	j	80002f80 <argraw+0x30>
  panic("argraw");
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	63050513          	addi	a0,a0,1584 # 800085d8 <states.1791+0x148>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	58e080e7          	jalr	1422(ra) # 8000053e <panic>

0000000080002fb8 <fetchaddr>:
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	e426                	sd	s1,8(sp)
    80002fc0:	e04a                	sd	s2,0(sp)
    80002fc2:	1000                	addi	s0,sp,32
    80002fc4:	84aa                	mv	s1,a0
    80002fc6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	d5a080e7          	jalr	-678(ra) # 80001d22 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fd0:	653c                	ld	a5,72(a0)
    80002fd2:	02f4f863          	bgeu	s1,a5,80003002 <fetchaddr+0x4a>
    80002fd6:	00848713          	addi	a4,s1,8
    80002fda:	02e7e663          	bltu	a5,a4,80003006 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fde:	46a1                	li	a3,8
    80002fe0:	8626                	mv	a2,s1
    80002fe2:	85ca                	mv	a1,s2
    80002fe4:	6928                	ld	a0,80(a0)
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	718080e7          	jalr	1816(ra) # 800016fe <copyin>
    80002fee:	00a03533          	snez	a0,a0
    80002ff2:	40a00533          	neg	a0,a0
}
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	64a2                	ld	s1,8(sp)
    80002ffc:	6902                	ld	s2,0(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret
    return -1;
    80003002:	557d                	li	a0,-1
    80003004:	bfcd                	j	80002ff6 <fetchaddr+0x3e>
    80003006:	557d                	li	a0,-1
    80003008:	b7fd                	j	80002ff6 <fetchaddr+0x3e>

000000008000300a <fetchstr>:
{
    8000300a:	7179                	addi	sp,sp,-48
    8000300c:	f406                	sd	ra,40(sp)
    8000300e:	f022                	sd	s0,32(sp)
    80003010:	ec26                	sd	s1,24(sp)
    80003012:	e84a                	sd	s2,16(sp)
    80003014:	e44e                	sd	s3,8(sp)
    80003016:	1800                	addi	s0,sp,48
    80003018:	892a                	mv	s2,a0
    8000301a:	84ae                	mv	s1,a1
    8000301c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	d04080e7          	jalr	-764(ra) # 80001d22 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003026:	86ce                	mv	a3,s3
    80003028:	864a                	mv	a2,s2
    8000302a:	85a6                	mv	a1,s1
    8000302c:	6928                	ld	a0,80(a0)
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	75c080e7          	jalr	1884(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003036:	00054763          	bltz	a0,80003044 <fetchstr+0x3a>
  return strlen(buf);
    8000303a:	8526                	mv	a0,s1
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	e28080e7          	jalr	-472(ra) # 80000e64 <strlen>
}
    80003044:	70a2                	ld	ra,40(sp)
    80003046:	7402                	ld	s0,32(sp)
    80003048:	64e2                	ld	s1,24(sp)
    8000304a:	6942                	ld	s2,16(sp)
    8000304c:	69a2                	ld	s3,8(sp)
    8000304e:	6145                	addi	sp,sp,48
    80003050:	8082                	ret

0000000080003052 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	1000                	addi	s0,sp,32
    8000305c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	ef2080e7          	jalr	-270(ra) # 80002f50 <argraw>
    80003066:	c088                	sw	a0,0(s1)
  return 0;
}
    80003068:	4501                	li	a0,0
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	addi	sp,sp,32
    80003072:	8082                	ret

0000000080003074 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003074:	1101                	addi	sp,sp,-32
    80003076:	ec06                	sd	ra,24(sp)
    80003078:	e822                	sd	s0,16(sp)
    8000307a:	e426                	sd	s1,8(sp)
    8000307c:	1000                	addi	s0,sp,32
    8000307e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003080:	00000097          	auipc	ra,0x0
    80003084:	ed0080e7          	jalr	-304(ra) # 80002f50 <argraw>
    80003088:	e088                	sd	a0,0(s1)
  return 0;
}
    8000308a:	4501                	li	a0,0
    8000308c:	60e2                	ld	ra,24(sp)
    8000308e:	6442                	ld	s0,16(sp)
    80003090:	64a2                	ld	s1,8(sp)
    80003092:	6105                	addi	sp,sp,32
    80003094:	8082                	ret

0000000080003096 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	e04a                	sd	s2,0(sp)
    800030a0:	1000                	addi	s0,sp,32
    800030a2:	84ae                	mv	s1,a1
    800030a4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800030a6:	00000097          	auipc	ra,0x0
    800030aa:	eaa080e7          	jalr	-342(ra) # 80002f50 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800030ae:	864a                	mv	a2,s2
    800030b0:	85a6                	mv	a1,s1
    800030b2:	00000097          	auipc	ra,0x0
    800030b6:	f58080e7          	jalr	-168(ra) # 8000300a <fetchstr>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6902                	ld	s2,0(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <syscall>:
[SYS_get_cpu] sys_get_cpu,
};

void
syscall(void)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030d2:	fffff097          	auipc	ra,0xfffff
    800030d6:	c50080e7          	jalr	-944(ra) # 80001d22 <myproc>
    800030da:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030dc:	05853903          	ld	s2,88(a0)
    800030e0:	0a893783          	ld	a5,168(s2)
    800030e4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030e8:	37fd                	addiw	a5,a5,-1
    800030ea:	4759                	li	a4,22
    800030ec:	00f76f63          	bltu	a4,a5,8000310a <syscall+0x44>
    800030f0:	00369713          	slli	a4,a3,0x3
    800030f4:	00005797          	auipc	a5,0x5
    800030f8:	52478793          	addi	a5,a5,1316 # 80008618 <syscalls>
    800030fc:	97ba                	add	a5,a5,a4
    800030fe:	639c                	ld	a5,0(a5)
    80003100:	c789                	beqz	a5,8000310a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003102:	9782                	jalr	a5
    80003104:	06a93823          	sd	a0,112(s2)
    80003108:	a839                	j	80003126 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000310a:	15848613          	addi	a2,s1,344
    8000310e:	588c                	lw	a1,48(s1)
    80003110:	00005517          	auipc	a0,0x5
    80003114:	4d050513          	addi	a0,a0,1232 # 800085e0 <states.1791+0x150>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	470080e7          	jalr	1136(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003120:	6cbc                	ld	a5,88(s1)
    80003122:	577d                	li	a4,-1
    80003124:	fbb8                	sd	a4,112(a5)
  }
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6902                	ld	s2,0(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000313a:	fec40593          	addi	a1,s0,-20
    8000313e:	4501                	li	a0,0
    80003140:	00000097          	auipc	ra,0x0
    80003144:	f12080e7          	jalr	-238(ra) # 80003052 <argint>
    return -1;
    80003148:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000314a:	00054963          	bltz	a0,8000315c <sys_exit+0x2a>
  exit(n);
    8000314e:	fec42503          	lw	a0,-20(s0)
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	6d8080e7          	jalr	1752(ra) # 8000282a <exit>
  return 0;  // not reached
    8000315a:	4781                	li	a5,0
}
    8000315c:	853e                	mv	a0,a5
    8000315e:	60e2                	ld	ra,24(sp)
    80003160:	6442                	ld	s0,16(sp)
    80003162:	6105                	addi	sp,sp,32
    80003164:	8082                	ret

0000000080003166 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003166:	1141                	addi	sp,sp,-16
    80003168:	e406                	sd	ra,8(sp)
    8000316a:	e022                	sd	s0,0(sp)
    8000316c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	bb4080e7          	jalr	-1100(ra) # 80001d22 <myproc>
}
    80003176:	5908                	lw	a0,48(a0)
    80003178:	60a2                	ld	ra,8(sp)
    8000317a:	6402                	ld	s0,0(sp)
    8000317c:	0141                	addi	sp,sp,16
    8000317e:	8082                	ret

0000000080003180 <sys_fork>:

uint64
sys_fork(void)
{
    80003180:	1141                	addi	sp,sp,-16
    80003182:	e406                	sd	ra,8(sp)
    80003184:	e022                	sd	s0,0(sp)
    80003186:	0800                	addi	s0,sp,16
  return fork();
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	ffc080e7          	jalr	-4(ra) # 80002184 <fork>
}
    80003190:	60a2                	ld	ra,8(sp)
    80003192:	6402                	ld	s0,0(sp)
    80003194:	0141                	addi	sp,sp,16
    80003196:	8082                	ret

0000000080003198 <sys_wait>:

uint64
sys_wait(void)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031a0:	fe840593          	addi	a1,s0,-24
    800031a4:	4501                	li	a0,0
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	ece080e7          	jalr	-306(ra) # 80003074 <argaddr>
    800031ae:	87aa                	mv	a5,a0
    return -1;
    800031b0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031b2:	0007c863          	bltz	a5,800031c2 <sys_wait+0x2a>
  return wait(p);
    800031b6:	fe843503          	ld	a0,-24(s0)
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	400080e7          	jalr	1024(ra) # 800025ba <wait>
}
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret

00000000800031ca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031ca:	7179                	addi	sp,sp,-48
    800031cc:	f406                	sd	ra,40(sp)
    800031ce:	f022                	sd	s0,32(sp)
    800031d0:	ec26                	sd	s1,24(sp)
    800031d2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031d4:	fdc40593          	addi	a1,s0,-36
    800031d8:	4501                	li	a0,0
    800031da:	00000097          	auipc	ra,0x0
    800031de:	e78080e7          	jalr	-392(ra) # 80003052 <argint>
    800031e2:	87aa                	mv	a5,a0
    return -1;
    800031e4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031e6:	0207c063          	bltz	a5,80003206 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	b38080e7          	jalr	-1224(ra) # 80001d22 <myproc>
    800031f2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800031f4:	fdc42503          	lw	a0,-36(s0)
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	f18080e7          	jalr	-232(ra) # 80002110 <growproc>
    80003200:	00054863          	bltz	a0,80003210 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003204:	8526                	mv	a0,s1
}
    80003206:	70a2                	ld	ra,40(sp)
    80003208:	7402                	ld	s0,32(sp)
    8000320a:	64e2                	ld	s1,24(sp)
    8000320c:	6145                	addi	sp,sp,48
    8000320e:	8082                	ret
    return -1;
    80003210:	557d                	li	a0,-1
    80003212:	bfd5                	j	80003206 <sys_sbrk+0x3c>

0000000080003214 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003214:	7139                	addi	sp,sp,-64
    80003216:	fc06                	sd	ra,56(sp)
    80003218:	f822                	sd	s0,48(sp)
    8000321a:	f426                	sd	s1,40(sp)
    8000321c:	f04a                	sd	s2,32(sp)
    8000321e:	ec4e                	sd	s3,24(sp)
    80003220:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003222:	fcc40593          	addi	a1,s0,-52
    80003226:	4501                	li	a0,0
    80003228:	00000097          	auipc	ra,0x0
    8000322c:	e2a080e7          	jalr	-470(ra) # 80003052 <argint>
    return -1;
    80003230:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003232:	06054563          	bltz	a0,8000329c <sys_sleep+0x88>
  acquire(&tickslock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	31a50513          	addi	a0,a0,794 # 80017550 <tickslock>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	9a6080e7          	jalr	-1626(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003246:	00006917          	auipc	s2,0x6
    8000324a:	dea92903          	lw	s2,-534(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000324e:	fcc42783          	lw	a5,-52(s0)
    80003252:	cf85                	beqz	a5,8000328a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003254:	00014997          	auipc	s3,0x14
    80003258:	2fc98993          	addi	s3,s3,764 # 80017550 <tickslock>
    8000325c:	00006497          	auipc	s1,0x6
    80003260:	dd448493          	addi	s1,s1,-556 # 80009030 <ticks>
    if(myproc()->killed){
    80003264:	fffff097          	auipc	ra,0xfffff
    80003268:	abe080e7          	jalr	-1346(ra) # 80001d22 <myproc>
    8000326c:	551c                	lw	a5,40(a0)
    8000326e:	ef9d                	bnez	a5,800032ac <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003270:	85ce                	mv	a1,s3
    80003272:	8526                	mv	a0,s1
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	2bc080e7          	jalr	700(ra) # 80002530 <sleep>
  while(ticks - ticks0 < n){
    8000327c:	409c                	lw	a5,0(s1)
    8000327e:	412787bb          	subw	a5,a5,s2
    80003282:	fcc42703          	lw	a4,-52(s0)
    80003286:	fce7efe3          	bltu	a5,a4,80003264 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000328a:	00014517          	auipc	a0,0x14
    8000328e:	2c650513          	addi	a0,a0,710 # 80017550 <tickslock>
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	a06080e7          	jalr	-1530(ra) # 80000c98 <release>
  return 0;
    8000329a:	4781                	li	a5,0
}
    8000329c:	853e                	mv	a0,a5
    8000329e:	70e2                	ld	ra,56(sp)
    800032a0:	7442                	ld	s0,48(sp)
    800032a2:	74a2                	ld	s1,40(sp)
    800032a4:	7902                	ld	s2,32(sp)
    800032a6:	69e2                	ld	s3,24(sp)
    800032a8:	6121                	addi	sp,sp,64
    800032aa:	8082                	ret
      release(&tickslock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	2a450513          	addi	a0,a0,676 # 80017550 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9e4080e7          	jalr	-1564(ra) # 80000c98 <release>
      return -1;
    800032bc:	57fd                	li	a5,-1
    800032be:	bff9                	j	8000329c <sys_sleep+0x88>

00000000800032c0 <sys_kill>:

uint64
sys_kill(void)
{
    800032c0:	1101                	addi	sp,sp,-32
    800032c2:	ec06                	sd	ra,24(sp)
    800032c4:	e822                	sd	s0,16(sp)
    800032c6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032c8:	fec40593          	addi	a1,s0,-20
    800032cc:	4501                	li	a0,0
    800032ce:	00000097          	auipc	ra,0x0
    800032d2:	d84080e7          	jalr	-636(ra) # 80003052 <argint>
    800032d6:	87aa                	mv	a5,a0
    return -1;
    800032d8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032da:	0007c863          	bltz	a5,800032ea <sys_kill+0x2a>
  return kill(pid);
    800032de:	fec42503          	lw	a0,-20(s0)
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	644080e7          	jalr	1604(ra) # 80002926 <kill>
}
    800032ea:	60e2                	ld	ra,24(sp)
    800032ec:	6442                	ld	s0,16(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032fc:	00014517          	auipc	a0,0x14
    80003300:	25450513          	addi	a0,a0,596 # 80017550 <tickslock>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	8e0080e7          	jalr	-1824(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000330c:	00006497          	auipc	s1,0x6
    80003310:	d244a483          	lw	s1,-732(s1) # 80009030 <ticks>
  release(&tickslock);
    80003314:	00014517          	auipc	a0,0x14
    80003318:	23c50513          	addi	a0,a0,572 # 80017550 <tickslock>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
  return xticks;
}
    80003324:	02049513          	slli	a0,s1,0x20
    80003328:	9101                	srli	a0,a0,0x20
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret

0000000080003334 <sys_set_cpu>:

uint64
sys_set_cpu(void)
{
    80003334:	1101                	addi	sp,sp,-32
    80003336:	ec06                	sd	ra,24(sp)
    80003338:	e822                	sd	s0,16(sp)
    8000333a:	1000                	addi	s0,sp,32
  int cpu_id;

  if(argint(0, &cpu_id) < 0)
    8000333c:	fec40593          	addi	a1,s0,-20
    80003340:	4501                	li	a0,0
    80003342:	00000097          	auipc	ra,0x0
    80003346:	d10080e7          	jalr	-752(ra) # 80003052 <argint>
    8000334a:	87aa                	mv	a5,a0
    return -1;
    8000334c:	557d                	li	a0,-1
  if(argint(0, &cpu_id) < 0)
    8000334e:	0007c863          	bltz	a5,8000335e <sys_set_cpu+0x2a>
  return set_cpu(cpu_id);
    80003352:	fec42503          	lw	a0,-20(s0)
    80003356:	fffff097          	auipc	ra,0xfffff
    8000335a:	79c080e7          	jalr	1948(ra) # 80002af2 <set_cpu>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	6105                	addi	sp,sp,32
    80003364:	8082                	ret

0000000080003366 <sys_get_cpu>:

uint64
sys_get_cpu(void)
{
    80003366:	1141                	addi	sp,sp,-16
    80003368:	e406                	sd	ra,8(sp)
    8000336a:	e022                	sd	s0,0(sp)
    8000336c:	0800                	addi	s0,sp,16
  return get_cpu();
    8000336e:	fffff097          	auipc	ra,0xfffff
    80003372:	7d6080e7          	jalr	2006(ra) # 80002b44 <get_cpu>
}
    80003376:	60a2                	ld	ra,8(sp)
    80003378:	6402                	ld	s0,0(sp)
    8000337a:	0141                	addi	sp,sp,16
    8000337c:	8082                	ret

000000008000337e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000337e:	7179                	addi	sp,sp,-48
    80003380:	f406                	sd	ra,40(sp)
    80003382:	f022                	sd	s0,32(sp)
    80003384:	ec26                	sd	s1,24(sp)
    80003386:	e84a                	sd	s2,16(sp)
    80003388:	e44e                	sd	s3,8(sp)
    8000338a:	e052                	sd	s4,0(sp)
    8000338c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000338e:	00005597          	auipc	a1,0x5
    80003392:	34a58593          	addi	a1,a1,842 # 800086d8 <syscalls+0xc0>
    80003396:	00014517          	auipc	a0,0x14
    8000339a:	1d250513          	addi	a0,a0,466 # 80017568 <bcache>
    8000339e:	ffffd097          	auipc	ra,0xffffd
    800033a2:	7b6080e7          	jalr	1974(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033a6:	0001c797          	auipc	a5,0x1c
    800033aa:	1c278793          	addi	a5,a5,450 # 8001f568 <bcache+0x8000>
    800033ae:	0001c717          	auipc	a4,0x1c
    800033b2:	42270713          	addi	a4,a4,1058 # 8001f7d0 <bcache+0x8268>
    800033b6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033ba:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033be:	00014497          	auipc	s1,0x14
    800033c2:	1c248493          	addi	s1,s1,450 # 80017580 <bcache+0x18>
    b->next = bcache.head.next;
    800033c6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033c8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033ca:	00005a17          	auipc	s4,0x5
    800033ce:	316a0a13          	addi	s4,s4,790 # 800086e0 <syscalls+0xc8>
    b->next = bcache.head.next;
    800033d2:	2b893783          	ld	a5,696(s2)
    800033d6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033d8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033dc:	85d2                	mv	a1,s4
    800033de:	01048513          	addi	a0,s1,16
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	4bc080e7          	jalr	1212(ra) # 8000489e <initsleeplock>
    bcache.head.next->prev = b;
    800033ea:	2b893783          	ld	a5,696(s2)
    800033ee:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033f0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033f4:	45848493          	addi	s1,s1,1112
    800033f8:	fd349de3          	bne	s1,s3,800033d2 <binit+0x54>
  }
}
    800033fc:	70a2                	ld	ra,40(sp)
    800033fe:	7402                	ld	s0,32(sp)
    80003400:	64e2                	ld	s1,24(sp)
    80003402:	6942                	ld	s2,16(sp)
    80003404:	69a2                	ld	s3,8(sp)
    80003406:	6a02                	ld	s4,0(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret

000000008000340c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000340c:	7179                	addi	sp,sp,-48
    8000340e:	f406                	sd	ra,40(sp)
    80003410:	f022                	sd	s0,32(sp)
    80003412:	ec26                	sd	s1,24(sp)
    80003414:	e84a                	sd	s2,16(sp)
    80003416:	e44e                	sd	s3,8(sp)
    80003418:	1800                	addi	s0,sp,48
    8000341a:	89aa                	mv	s3,a0
    8000341c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000341e:	00014517          	auipc	a0,0x14
    80003422:	14a50513          	addi	a0,a0,330 # 80017568 <bcache>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	7be080e7          	jalr	1982(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000342e:	0001c497          	auipc	s1,0x1c
    80003432:	3f24b483          	ld	s1,1010(s1) # 8001f820 <bcache+0x82b8>
    80003436:	0001c797          	auipc	a5,0x1c
    8000343a:	39a78793          	addi	a5,a5,922 # 8001f7d0 <bcache+0x8268>
    8000343e:	02f48f63          	beq	s1,a5,8000347c <bread+0x70>
    80003442:	873e                	mv	a4,a5
    80003444:	a021                	j	8000344c <bread+0x40>
    80003446:	68a4                	ld	s1,80(s1)
    80003448:	02e48a63          	beq	s1,a4,8000347c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000344c:	449c                	lw	a5,8(s1)
    8000344e:	ff379ce3          	bne	a5,s3,80003446 <bread+0x3a>
    80003452:	44dc                	lw	a5,12(s1)
    80003454:	ff2799e3          	bne	a5,s2,80003446 <bread+0x3a>
      b->refcnt++;
    80003458:	40bc                	lw	a5,64(s1)
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000345e:	00014517          	auipc	a0,0x14
    80003462:	10a50513          	addi	a0,a0,266 # 80017568 <bcache>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	832080e7          	jalr	-1998(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000346e:	01048513          	addi	a0,s1,16
    80003472:	00001097          	auipc	ra,0x1
    80003476:	466080e7          	jalr	1126(ra) # 800048d8 <acquiresleep>
      return b;
    8000347a:	a8b9                	j	800034d8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000347c:	0001c497          	auipc	s1,0x1c
    80003480:	39c4b483          	ld	s1,924(s1) # 8001f818 <bcache+0x82b0>
    80003484:	0001c797          	auipc	a5,0x1c
    80003488:	34c78793          	addi	a5,a5,844 # 8001f7d0 <bcache+0x8268>
    8000348c:	00f48863          	beq	s1,a5,8000349c <bread+0x90>
    80003490:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003492:	40bc                	lw	a5,64(s1)
    80003494:	cf81                	beqz	a5,800034ac <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003496:	64a4                	ld	s1,72(s1)
    80003498:	fee49de3          	bne	s1,a4,80003492 <bread+0x86>
  panic("bget: no buffers");
    8000349c:	00005517          	auipc	a0,0x5
    800034a0:	24c50513          	addi	a0,a0,588 # 800086e8 <syscalls+0xd0>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	09a080e7          	jalr	154(ra) # 8000053e <panic>
      b->dev = dev;
    800034ac:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034b0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034b4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034b8:	4785                	li	a5,1
    800034ba:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034bc:	00014517          	auipc	a0,0x14
    800034c0:	0ac50513          	addi	a0,a0,172 # 80017568 <bcache>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	7d4080e7          	jalr	2004(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034cc:	01048513          	addi	a0,s1,16
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	408080e7          	jalr	1032(ra) # 800048d8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034d8:	409c                	lw	a5,0(s1)
    800034da:	cb89                	beqz	a5,800034ec <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034dc:	8526                	mv	a0,s1
    800034de:	70a2                	ld	ra,40(sp)
    800034e0:	7402                	ld	s0,32(sp)
    800034e2:	64e2                	ld	s1,24(sp)
    800034e4:	6942                	ld	s2,16(sp)
    800034e6:	69a2                	ld	s3,8(sp)
    800034e8:	6145                	addi	sp,sp,48
    800034ea:	8082                	ret
    virtio_disk_rw(b, 0);
    800034ec:	4581                	li	a1,0
    800034ee:	8526                	mv	a0,s1
    800034f0:	00003097          	auipc	ra,0x3
    800034f4:	f06080e7          	jalr	-250(ra) # 800063f6 <virtio_disk_rw>
    b->valid = 1;
    800034f8:	4785                	li	a5,1
    800034fa:	c09c                	sw	a5,0(s1)
  return b;
    800034fc:	b7c5                	j	800034dc <bread+0xd0>

00000000800034fe <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	1000                	addi	s0,sp,32
    80003508:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000350a:	0541                	addi	a0,a0,16
    8000350c:	00001097          	auipc	ra,0x1
    80003510:	466080e7          	jalr	1126(ra) # 80004972 <holdingsleep>
    80003514:	cd01                	beqz	a0,8000352c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003516:	4585                	li	a1,1
    80003518:	8526                	mv	a0,s1
    8000351a:	00003097          	auipc	ra,0x3
    8000351e:	edc080e7          	jalr	-292(ra) # 800063f6 <virtio_disk_rw>
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret
    panic("bwrite");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	1d450513          	addi	a0,a0,468 # 80008700 <syscalls+0xe8>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	00a080e7          	jalr	10(ra) # 8000053e <panic>

000000008000353c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000353c:	1101                	addi	sp,sp,-32
    8000353e:	ec06                	sd	ra,24(sp)
    80003540:	e822                	sd	s0,16(sp)
    80003542:	e426                	sd	s1,8(sp)
    80003544:	e04a                	sd	s2,0(sp)
    80003546:	1000                	addi	s0,sp,32
    80003548:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000354a:	01050913          	addi	s2,a0,16
    8000354e:	854a                	mv	a0,s2
    80003550:	00001097          	auipc	ra,0x1
    80003554:	422080e7          	jalr	1058(ra) # 80004972 <holdingsleep>
    80003558:	c92d                	beqz	a0,800035ca <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	3d2080e7          	jalr	978(ra) # 8000492e <releasesleep>

  acquire(&bcache.lock);
    80003564:	00014517          	auipc	a0,0x14
    80003568:	00450513          	addi	a0,a0,4 # 80017568 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003574:	40bc                	lw	a5,64(s1)
    80003576:	37fd                	addiw	a5,a5,-1
    80003578:	0007871b          	sext.w	a4,a5
    8000357c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000357e:	eb05                	bnez	a4,800035ae <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003580:	68bc                	ld	a5,80(s1)
    80003582:	64b8                	ld	a4,72(s1)
    80003584:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003586:	64bc                	ld	a5,72(s1)
    80003588:	68b8                	ld	a4,80(s1)
    8000358a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000358c:	0001c797          	auipc	a5,0x1c
    80003590:	fdc78793          	addi	a5,a5,-36 # 8001f568 <bcache+0x8000>
    80003594:	2b87b703          	ld	a4,696(a5)
    80003598:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000359a:	0001c717          	auipc	a4,0x1c
    8000359e:	23670713          	addi	a4,a4,566 # 8001f7d0 <bcache+0x8268>
    800035a2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035a4:	2b87b703          	ld	a4,696(a5)
    800035a8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035aa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035ae:	00014517          	auipc	a0,0x14
    800035b2:	fba50513          	addi	a0,a0,-70 # 80017568 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
}
    800035be:	60e2                	ld	ra,24(sp)
    800035c0:	6442                	ld	s0,16(sp)
    800035c2:	64a2                	ld	s1,8(sp)
    800035c4:	6902                	ld	s2,0(sp)
    800035c6:	6105                	addi	sp,sp,32
    800035c8:	8082                	ret
    panic("brelse");
    800035ca:	00005517          	auipc	a0,0x5
    800035ce:	13e50513          	addi	a0,a0,318 # 80008708 <syscalls+0xf0>
    800035d2:	ffffd097          	auipc	ra,0xffffd
    800035d6:	f6c080e7          	jalr	-148(ra) # 8000053e <panic>

00000000800035da <bpin>:

void
bpin(struct buf *b) {
    800035da:	1101                	addi	sp,sp,-32
    800035dc:	ec06                	sd	ra,24(sp)
    800035de:	e822                	sd	s0,16(sp)
    800035e0:	e426                	sd	s1,8(sp)
    800035e2:	1000                	addi	s0,sp,32
    800035e4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035e6:	00014517          	auipc	a0,0x14
    800035ea:	f8250513          	addi	a0,a0,-126 # 80017568 <bcache>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	5f6080e7          	jalr	1526(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035f6:	40bc                	lw	a5,64(s1)
    800035f8:	2785                	addiw	a5,a5,1
    800035fa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035fc:	00014517          	auipc	a0,0x14
    80003600:	f6c50513          	addi	a0,a0,-148 # 80017568 <bcache>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	694080e7          	jalr	1684(ra) # 80000c98 <release>
}
    8000360c:	60e2                	ld	ra,24(sp)
    8000360e:	6442                	ld	s0,16(sp)
    80003610:	64a2                	ld	s1,8(sp)
    80003612:	6105                	addi	sp,sp,32
    80003614:	8082                	ret

0000000080003616 <bunpin>:

void
bunpin(struct buf *b) {
    80003616:	1101                	addi	sp,sp,-32
    80003618:	ec06                	sd	ra,24(sp)
    8000361a:	e822                	sd	s0,16(sp)
    8000361c:	e426                	sd	s1,8(sp)
    8000361e:	1000                	addi	s0,sp,32
    80003620:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003622:	00014517          	auipc	a0,0x14
    80003626:	f4650513          	addi	a0,a0,-186 # 80017568 <bcache>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	5ba080e7          	jalr	1466(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003632:	40bc                	lw	a5,64(s1)
    80003634:	37fd                	addiw	a5,a5,-1
    80003636:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003638:	00014517          	auipc	a0,0x14
    8000363c:	f3050513          	addi	a0,a0,-208 # 80017568 <bcache>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	658080e7          	jalr	1624(ra) # 80000c98 <release>
}
    80003648:	60e2                	ld	ra,24(sp)
    8000364a:	6442                	ld	s0,16(sp)
    8000364c:	64a2                	ld	s1,8(sp)
    8000364e:	6105                	addi	sp,sp,32
    80003650:	8082                	ret

0000000080003652 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003652:	1101                	addi	sp,sp,-32
    80003654:	ec06                	sd	ra,24(sp)
    80003656:	e822                	sd	s0,16(sp)
    80003658:	e426                	sd	s1,8(sp)
    8000365a:	e04a                	sd	s2,0(sp)
    8000365c:	1000                	addi	s0,sp,32
    8000365e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003660:	00d5d59b          	srliw	a1,a1,0xd
    80003664:	0001c797          	auipc	a5,0x1c
    80003668:	5e07a783          	lw	a5,1504(a5) # 8001fc44 <sb+0x1c>
    8000366c:	9dbd                	addw	a1,a1,a5
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	d9e080e7          	jalr	-610(ra) # 8000340c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003676:	0074f713          	andi	a4,s1,7
    8000367a:	4785                	li	a5,1
    8000367c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003680:	14ce                	slli	s1,s1,0x33
    80003682:	90d9                	srli	s1,s1,0x36
    80003684:	00950733          	add	a4,a0,s1
    80003688:	05874703          	lbu	a4,88(a4)
    8000368c:	00e7f6b3          	and	a3,a5,a4
    80003690:	c69d                	beqz	a3,800036be <bfree+0x6c>
    80003692:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003694:	94aa                	add	s1,s1,a0
    80003696:	fff7c793          	not	a5,a5
    8000369a:	8ff9                	and	a5,a5,a4
    8000369c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	118080e7          	jalr	280(ra) # 800047b8 <log_write>
  brelse(bp);
    800036a8:	854a                	mv	a0,s2
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	e92080e7          	jalr	-366(ra) # 8000353c <brelse>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6902                	ld	s2,0(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret
    panic("freeing free block");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	05250513          	addi	a0,a0,82 # 80008710 <syscalls+0xf8>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e78080e7          	jalr	-392(ra) # 8000053e <panic>

00000000800036ce <balloc>:
{
    800036ce:	711d                	addi	sp,sp,-96
    800036d0:	ec86                	sd	ra,88(sp)
    800036d2:	e8a2                	sd	s0,80(sp)
    800036d4:	e4a6                	sd	s1,72(sp)
    800036d6:	e0ca                	sd	s2,64(sp)
    800036d8:	fc4e                	sd	s3,56(sp)
    800036da:	f852                	sd	s4,48(sp)
    800036dc:	f456                	sd	s5,40(sp)
    800036de:	f05a                	sd	s6,32(sp)
    800036e0:	ec5e                	sd	s7,24(sp)
    800036e2:	e862                	sd	s8,16(sp)
    800036e4:	e466                	sd	s9,8(sp)
    800036e6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036e8:	0001c797          	auipc	a5,0x1c
    800036ec:	5447a783          	lw	a5,1348(a5) # 8001fc2c <sb+0x4>
    800036f0:	cbd1                	beqz	a5,80003784 <balloc+0xb6>
    800036f2:	8baa                	mv	s7,a0
    800036f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036f6:	0001cb17          	auipc	s6,0x1c
    800036fa:	532b0b13          	addi	s6,s6,1330 # 8001fc28 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003700:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003702:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003704:	6c89                	lui	s9,0x2
    80003706:	a831                	j	80003722 <balloc+0x54>
    brelse(bp);
    80003708:	854a                	mv	a0,s2
    8000370a:	00000097          	auipc	ra,0x0
    8000370e:	e32080e7          	jalr	-462(ra) # 8000353c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003712:	015c87bb          	addw	a5,s9,s5
    80003716:	00078a9b          	sext.w	s5,a5
    8000371a:	004b2703          	lw	a4,4(s6)
    8000371e:	06eaf363          	bgeu	s5,a4,80003784 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003722:	41fad79b          	sraiw	a5,s5,0x1f
    80003726:	0137d79b          	srliw	a5,a5,0x13
    8000372a:	015787bb          	addw	a5,a5,s5
    8000372e:	40d7d79b          	sraiw	a5,a5,0xd
    80003732:	01cb2583          	lw	a1,28(s6)
    80003736:	9dbd                	addw	a1,a1,a5
    80003738:	855e                	mv	a0,s7
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	cd2080e7          	jalr	-814(ra) # 8000340c <bread>
    80003742:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003744:	004b2503          	lw	a0,4(s6)
    80003748:	000a849b          	sext.w	s1,s5
    8000374c:	8662                	mv	a2,s8
    8000374e:	faa4fde3          	bgeu	s1,a0,80003708 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003752:	41f6579b          	sraiw	a5,a2,0x1f
    80003756:	01d7d69b          	srliw	a3,a5,0x1d
    8000375a:	00c6873b          	addw	a4,a3,a2
    8000375e:	00777793          	andi	a5,a4,7
    80003762:	9f95                	subw	a5,a5,a3
    80003764:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003768:	4037571b          	sraiw	a4,a4,0x3
    8000376c:	00e906b3          	add	a3,s2,a4
    80003770:	0586c683          	lbu	a3,88(a3)
    80003774:	00d7f5b3          	and	a1,a5,a3
    80003778:	cd91                	beqz	a1,80003794 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377a:	2605                	addiw	a2,a2,1
    8000377c:	2485                	addiw	s1,s1,1
    8000377e:	fd4618e3          	bne	a2,s4,8000374e <balloc+0x80>
    80003782:	b759                	j	80003708 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	fa450513          	addi	a0,a0,-92 # 80008728 <syscalls+0x110>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003794:	974a                	add	a4,a4,s2
    80003796:	8fd5                	or	a5,a5,a3
    80003798:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	01a080e7          	jalr	26(ra) # 800047b8 <log_write>
        brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	d94080e7          	jalr	-620(ra) # 8000353c <brelse>
  bp = bread(dev, bno);
    800037b0:	85a6                	mv	a1,s1
    800037b2:	855e                	mv	a0,s7
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	c58080e7          	jalr	-936(ra) # 8000340c <bread>
    800037bc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037be:	40000613          	li	a2,1024
    800037c2:	4581                	li	a1,0
    800037c4:	05850513          	addi	a0,a0,88
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	518080e7          	jalr	1304(ra) # 80000ce0 <memset>
  log_write(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	fe6080e7          	jalr	-26(ra) # 800047b8 <log_write>
  brelse(bp);
    800037da:	854a                	mv	a0,s2
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	d60080e7          	jalr	-672(ra) # 8000353c <brelse>
}
    800037e4:	8526                	mv	a0,s1
    800037e6:	60e6                	ld	ra,88(sp)
    800037e8:	6446                	ld	s0,80(sp)
    800037ea:	64a6                	ld	s1,72(sp)
    800037ec:	6906                	ld	s2,64(sp)
    800037ee:	79e2                	ld	s3,56(sp)
    800037f0:	7a42                	ld	s4,48(sp)
    800037f2:	7aa2                	ld	s5,40(sp)
    800037f4:	7b02                	ld	s6,32(sp)
    800037f6:	6be2                	ld	s7,24(sp)
    800037f8:	6c42                	ld	s8,16(sp)
    800037fa:	6ca2                	ld	s9,8(sp)
    800037fc:	6125                	addi	sp,sp,96
    800037fe:	8082                	ret

0000000080003800 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003800:	7179                	addi	sp,sp,-48
    80003802:	f406                	sd	ra,40(sp)
    80003804:	f022                	sd	s0,32(sp)
    80003806:	ec26                	sd	s1,24(sp)
    80003808:	e84a                	sd	s2,16(sp)
    8000380a:	e44e                	sd	s3,8(sp)
    8000380c:	e052                	sd	s4,0(sp)
    8000380e:	1800                	addi	s0,sp,48
    80003810:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003812:	47ad                	li	a5,11
    80003814:	04b7fe63          	bgeu	a5,a1,80003870 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003818:	ff45849b          	addiw	s1,a1,-12
    8000381c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003820:	0ff00793          	li	a5,255
    80003824:	0ae7e363          	bltu	a5,a4,800038ca <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003828:	08052583          	lw	a1,128(a0)
    8000382c:	c5ad                	beqz	a1,80003896 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000382e:	00092503          	lw	a0,0(s2)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	bda080e7          	jalr	-1062(ra) # 8000340c <bread>
    8000383a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000383c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003840:	02049593          	slli	a1,s1,0x20
    80003844:	9181                	srli	a1,a1,0x20
    80003846:	058a                	slli	a1,a1,0x2
    80003848:	00b784b3          	add	s1,a5,a1
    8000384c:	0004a983          	lw	s3,0(s1)
    80003850:	04098d63          	beqz	s3,800038aa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003854:	8552                	mv	a0,s4
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	ce6080e7          	jalr	-794(ra) # 8000353c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000385e:	854e                	mv	a0,s3
    80003860:	70a2                	ld	ra,40(sp)
    80003862:	7402                	ld	s0,32(sp)
    80003864:	64e2                	ld	s1,24(sp)
    80003866:	6942                	ld	s2,16(sp)
    80003868:	69a2                	ld	s3,8(sp)
    8000386a:	6a02                	ld	s4,0(sp)
    8000386c:	6145                	addi	sp,sp,48
    8000386e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003870:	02059493          	slli	s1,a1,0x20
    80003874:	9081                	srli	s1,s1,0x20
    80003876:	048a                	slli	s1,s1,0x2
    80003878:	94aa                	add	s1,s1,a0
    8000387a:	0504a983          	lw	s3,80(s1)
    8000387e:	fe0990e3          	bnez	s3,8000385e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003882:	4108                	lw	a0,0(a0)
    80003884:	00000097          	auipc	ra,0x0
    80003888:	e4a080e7          	jalr	-438(ra) # 800036ce <balloc>
    8000388c:	0005099b          	sext.w	s3,a0
    80003890:	0534a823          	sw	s3,80(s1)
    80003894:	b7e9                	j	8000385e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003896:	4108                	lw	a0,0(a0)
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	e36080e7          	jalr	-458(ra) # 800036ce <balloc>
    800038a0:	0005059b          	sext.w	a1,a0
    800038a4:	08b92023          	sw	a1,128(s2)
    800038a8:	b759                	j	8000382e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038aa:	00092503          	lw	a0,0(s2)
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	e20080e7          	jalr	-480(ra) # 800036ce <balloc>
    800038b6:	0005099b          	sext.w	s3,a0
    800038ba:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038be:	8552                	mv	a0,s4
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	ef8080e7          	jalr	-264(ra) # 800047b8 <log_write>
    800038c8:	b771                	j	80003854 <bmap+0x54>
  panic("bmap: out of range");
    800038ca:	00005517          	auipc	a0,0x5
    800038ce:	e7650513          	addi	a0,a0,-394 # 80008740 <syscalls+0x128>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	c6c080e7          	jalr	-916(ra) # 8000053e <panic>

00000000800038da <iget>:
{
    800038da:	7179                	addi	sp,sp,-48
    800038dc:	f406                	sd	ra,40(sp)
    800038de:	f022                	sd	s0,32(sp)
    800038e0:	ec26                	sd	s1,24(sp)
    800038e2:	e84a                	sd	s2,16(sp)
    800038e4:	e44e                	sd	s3,8(sp)
    800038e6:	e052                	sd	s4,0(sp)
    800038e8:	1800                	addi	s0,sp,48
    800038ea:	89aa                	mv	s3,a0
    800038ec:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038ee:	0001c517          	auipc	a0,0x1c
    800038f2:	35a50513          	addi	a0,a0,858 # 8001fc48 <itable>
    800038f6:	ffffd097          	auipc	ra,0xffffd
    800038fa:	2ee080e7          	jalr	750(ra) # 80000be4 <acquire>
  empty = 0;
    800038fe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003900:	0001c497          	auipc	s1,0x1c
    80003904:	36048493          	addi	s1,s1,864 # 8001fc60 <itable+0x18>
    80003908:	0001e697          	auipc	a3,0x1e
    8000390c:	de868693          	addi	a3,a3,-536 # 800216f0 <log>
    80003910:	a039                	j	8000391e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003912:	02090b63          	beqz	s2,80003948 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003916:	08848493          	addi	s1,s1,136
    8000391a:	02d48a63          	beq	s1,a3,8000394e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000391e:	449c                	lw	a5,8(s1)
    80003920:	fef059e3          	blez	a5,80003912 <iget+0x38>
    80003924:	4098                	lw	a4,0(s1)
    80003926:	ff3716e3          	bne	a4,s3,80003912 <iget+0x38>
    8000392a:	40d8                	lw	a4,4(s1)
    8000392c:	ff4713e3          	bne	a4,s4,80003912 <iget+0x38>
      ip->ref++;
    80003930:	2785                	addiw	a5,a5,1
    80003932:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003934:	0001c517          	auipc	a0,0x1c
    80003938:	31450513          	addi	a0,a0,788 # 8001fc48 <itable>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
      return ip;
    80003944:	8926                	mv	s2,s1
    80003946:	a03d                	j	80003974 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003948:	f7f9                	bnez	a5,80003916 <iget+0x3c>
    8000394a:	8926                	mv	s2,s1
    8000394c:	b7e9                	j	80003916 <iget+0x3c>
  if(empty == 0)
    8000394e:	02090c63          	beqz	s2,80003986 <iget+0xac>
  ip->dev = dev;
    80003952:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003956:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000395a:	4785                	li	a5,1
    8000395c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003960:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003964:	0001c517          	auipc	a0,0x1c
    80003968:	2e450513          	addi	a0,a0,740 # 8001fc48 <itable>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	32c080e7          	jalr	812(ra) # 80000c98 <release>
}
    80003974:	854a                	mv	a0,s2
    80003976:	70a2                	ld	ra,40(sp)
    80003978:	7402                	ld	s0,32(sp)
    8000397a:	64e2                	ld	s1,24(sp)
    8000397c:	6942                	ld	s2,16(sp)
    8000397e:	69a2                	ld	s3,8(sp)
    80003980:	6a02                	ld	s4,0(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret
    panic("iget: no inodes");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	dd250513          	addi	a0,a0,-558 # 80008758 <syscalls+0x140>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>

0000000080003996 <fsinit>:
fsinit(int dev) {
    80003996:	7179                	addi	sp,sp,-48
    80003998:	f406                	sd	ra,40(sp)
    8000399a:	f022                	sd	s0,32(sp)
    8000399c:	ec26                	sd	s1,24(sp)
    8000399e:	e84a                	sd	s2,16(sp)
    800039a0:	e44e                	sd	s3,8(sp)
    800039a2:	1800                	addi	s0,sp,48
    800039a4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039a6:	4585                	li	a1,1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	a64080e7          	jalr	-1436(ra) # 8000340c <bread>
    800039b0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039b2:	0001c997          	auipc	s3,0x1c
    800039b6:	27698993          	addi	s3,s3,630 # 8001fc28 <sb>
    800039ba:	02000613          	li	a2,32
    800039be:	05850593          	addi	a1,a0,88
    800039c2:	854e                	mv	a0,s3
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	37c080e7          	jalr	892(ra) # 80000d40 <memmove>
  brelse(bp);
    800039cc:	8526                	mv	a0,s1
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	b6e080e7          	jalr	-1170(ra) # 8000353c <brelse>
  if(sb.magic != FSMAGIC)
    800039d6:	0009a703          	lw	a4,0(s3)
    800039da:	102037b7          	lui	a5,0x10203
    800039de:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039e2:	02f71263          	bne	a4,a5,80003a06 <fsinit+0x70>
  initlog(dev, &sb);
    800039e6:	0001c597          	auipc	a1,0x1c
    800039ea:	24258593          	addi	a1,a1,578 # 8001fc28 <sb>
    800039ee:	854a                	mv	a0,s2
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	b4c080e7          	jalr	-1204(ra) # 8000453c <initlog>
}
    800039f8:	70a2                	ld	ra,40(sp)
    800039fa:	7402                	ld	s0,32(sp)
    800039fc:	64e2                	ld	s1,24(sp)
    800039fe:	6942                	ld	s2,16(sp)
    80003a00:	69a2                	ld	s3,8(sp)
    80003a02:	6145                	addi	sp,sp,48
    80003a04:	8082                	ret
    panic("invalid file system");
    80003a06:	00005517          	auipc	a0,0x5
    80003a0a:	d6250513          	addi	a0,a0,-670 # 80008768 <syscalls+0x150>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	b30080e7          	jalr	-1232(ra) # 8000053e <panic>

0000000080003a16 <iinit>:
{
    80003a16:	7179                	addi	sp,sp,-48
    80003a18:	f406                	sd	ra,40(sp)
    80003a1a:	f022                	sd	s0,32(sp)
    80003a1c:	ec26                	sd	s1,24(sp)
    80003a1e:	e84a                	sd	s2,16(sp)
    80003a20:	e44e                	sd	s3,8(sp)
    80003a22:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a24:	00005597          	auipc	a1,0x5
    80003a28:	d5c58593          	addi	a1,a1,-676 # 80008780 <syscalls+0x168>
    80003a2c:	0001c517          	auipc	a0,0x1c
    80003a30:	21c50513          	addi	a0,a0,540 # 8001fc48 <itable>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	120080e7          	jalr	288(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a3c:	0001c497          	auipc	s1,0x1c
    80003a40:	23448493          	addi	s1,s1,564 # 8001fc70 <itable+0x28>
    80003a44:	0001e997          	auipc	s3,0x1e
    80003a48:	cbc98993          	addi	s3,s3,-836 # 80021700 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a4c:	00005917          	auipc	s2,0x5
    80003a50:	d3c90913          	addi	s2,s2,-708 # 80008788 <syscalls+0x170>
    80003a54:	85ca                	mv	a1,s2
    80003a56:	8526                	mv	a0,s1
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	e46080e7          	jalr	-442(ra) # 8000489e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a60:	08848493          	addi	s1,s1,136
    80003a64:	ff3498e3          	bne	s1,s3,80003a54 <iinit+0x3e>
}
    80003a68:	70a2                	ld	ra,40(sp)
    80003a6a:	7402                	ld	s0,32(sp)
    80003a6c:	64e2                	ld	s1,24(sp)
    80003a6e:	6942                	ld	s2,16(sp)
    80003a70:	69a2                	ld	s3,8(sp)
    80003a72:	6145                	addi	sp,sp,48
    80003a74:	8082                	ret

0000000080003a76 <ialloc>:
{
    80003a76:	715d                	addi	sp,sp,-80
    80003a78:	e486                	sd	ra,72(sp)
    80003a7a:	e0a2                	sd	s0,64(sp)
    80003a7c:	fc26                	sd	s1,56(sp)
    80003a7e:	f84a                	sd	s2,48(sp)
    80003a80:	f44e                	sd	s3,40(sp)
    80003a82:	f052                	sd	s4,32(sp)
    80003a84:	ec56                	sd	s5,24(sp)
    80003a86:	e85a                	sd	s6,16(sp)
    80003a88:	e45e                	sd	s7,8(sp)
    80003a8a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a8c:	0001c717          	auipc	a4,0x1c
    80003a90:	1a872703          	lw	a4,424(a4) # 8001fc34 <sb+0xc>
    80003a94:	4785                	li	a5,1
    80003a96:	04e7fa63          	bgeu	a5,a4,80003aea <ialloc+0x74>
    80003a9a:	8aaa                	mv	s5,a0
    80003a9c:	8bae                	mv	s7,a1
    80003a9e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aa0:	0001ca17          	auipc	s4,0x1c
    80003aa4:	188a0a13          	addi	s4,s4,392 # 8001fc28 <sb>
    80003aa8:	00048b1b          	sext.w	s6,s1
    80003aac:	0044d593          	srli	a1,s1,0x4
    80003ab0:	018a2783          	lw	a5,24(s4)
    80003ab4:	9dbd                	addw	a1,a1,a5
    80003ab6:	8556                	mv	a0,s5
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	954080e7          	jalr	-1708(ra) # 8000340c <bread>
    80003ac0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ac2:	05850993          	addi	s3,a0,88
    80003ac6:	00f4f793          	andi	a5,s1,15
    80003aca:	079a                	slli	a5,a5,0x6
    80003acc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ace:	00099783          	lh	a5,0(s3)
    80003ad2:	c785                	beqz	a5,80003afa <ialloc+0x84>
    brelse(bp);
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	a68080e7          	jalr	-1432(ra) # 8000353c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003adc:	0485                	addi	s1,s1,1
    80003ade:	00ca2703          	lw	a4,12(s4)
    80003ae2:	0004879b          	sext.w	a5,s1
    80003ae6:	fce7e1e3          	bltu	a5,a4,80003aa8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003aea:	00005517          	auipc	a0,0x5
    80003aee:	ca650513          	addi	a0,a0,-858 # 80008790 <syscalls+0x178>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	a4c080e7          	jalr	-1460(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003afa:	04000613          	li	a2,64
    80003afe:	4581                	li	a1,0
    80003b00:	854e                	mv	a0,s3
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	1de080e7          	jalr	478(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b0a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	ca8080e7          	jalr	-856(ra) # 800047b8 <log_write>
      brelse(bp);
    80003b18:	854a                	mv	a0,s2
    80003b1a:	00000097          	auipc	ra,0x0
    80003b1e:	a22080e7          	jalr	-1502(ra) # 8000353c <brelse>
      return iget(dev, inum);
    80003b22:	85da                	mv	a1,s6
    80003b24:	8556                	mv	a0,s5
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	db4080e7          	jalr	-588(ra) # 800038da <iget>
}
    80003b2e:	60a6                	ld	ra,72(sp)
    80003b30:	6406                	ld	s0,64(sp)
    80003b32:	74e2                	ld	s1,56(sp)
    80003b34:	7942                	ld	s2,48(sp)
    80003b36:	79a2                	ld	s3,40(sp)
    80003b38:	7a02                	ld	s4,32(sp)
    80003b3a:	6ae2                	ld	s5,24(sp)
    80003b3c:	6b42                	ld	s6,16(sp)
    80003b3e:	6ba2                	ld	s7,8(sp)
    80003b40:	6161                	addi	sp,sp,80
    80003b42:	8082                	ret

0000000080003b44 <iupdate>:
{
    80003b44:	1101                	addi	sp,sp,-32
    80003b46:	ec06                	sd	ra,24(sp)
    80003b48:	e822                	sd	s0,16(sp)
    80003b4a:	e426                	sd	s1,8(sp)
    80003b4c:	e04a                	sd	s2,0(sp)
    80003b4e:	1000                	addi	s0,sp,32
    80003b50:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b52:	415c                	lw	a5,4(a0)
    80003b54:	0047d79b          	srliw	a5,a5,0x4
    80003b58:	0001c597          	auipc	a1,0x1c
    80003b5c:	0e85a583          	lw	a1,232(a1) # 8001fc40 <sb+0x18>
    80003b60:	9dbd                	addw	a1,a1,a5
    80003b62:	4108                	lw	a0,0(a0)
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	8a8080e7          	jalr	-1880(ra) # 8000340c <bread>
    80003b6c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b6e:	05850793          	addi	a5,a0,88
    80003b72:	40c8                	lw	a0,4(s1)
    80003b74:	893d                	andi	a0,a0,15
    80003b76:	051a                	slli	a0,a0,0x6
    80003b78:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b7a:	04449703          	lh	a4,68(s1)
    80003b7e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b82:	04649703          	lh	a4,70(s1)
    80003b86:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b8a:	04849703          	lh	a4,72(s1)
    80003b8e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b92:	04a49703          	lh	a4,74(s1)
    80003b96:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b9a:	44f8                	lw	a4,76(s1)
    80003b9c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b9e:	03400613          	li	a2,52
    80003ba2:	05048593          	addi	a1,s1,80
    80003ba6:	0531                	addi	a0,a0,12
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	198080e7          	jalr	408(ra) # 80000d40 <memmove>
  log_write(bp);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	c06080e7          	jalr	-1018(ra) # 800047b8 <log_write>
  brelse(bp);
    80003bba:	854a                	mv	a0,s2
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	980080e7          	jalr	-1664(ra) # 8000353c <brelse>
}
    80003bc4:	60e2                	ld	ra,24(sp)
    80003bc6:	6442                	ld	s0,16(sp)
    80003bc8:	64a2                	ld	s1,8(sp)
    80003bca:	6902                	ld	s2,0(sp)
    80003bcc:	6105                	addi	sp,sp,32
    80003bce:	8082                	ret

0000000080003bd0 <idup>:
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	1000                	addi	s0,sp,32
    80003bda:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bdc:	0001c517          	auipc	a0,0x1c
    80003be0:	06c50513          	addi	a0,a0,108 # 8001fc48 <itable>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	000080e7          	jalr	ra # 80000be4 <acquire>
  ip->ref++;
    80003bec:	449c                	lw	a5,8(s1)
    80003bee:	2785                	addiw	a5,a5,1
    80003bf0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bf2:	0001c517          	auipc	a0,0x1c
    80003bf6:	05650513          	addi	a0,a0,86 # 8001fc48 <itable>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	09e080e7          	jalr	158(ra) # 80000c98 <release>
}
    80003c02:	8526                	mv	a0,s1
    80003c04:	60e2                	ld	ra,24(sp)
    80003c06:	6442                	ld	s0,16(sp)
    80003c08:	64a2                	ld	s1,8(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret

0000000080003c0e <ilock>:
{
    80003c0e:	1101                	addi	sp,sp,-32
    80003c10:	ec06                	sd	ra,24(sp)
    80003c12:	e822                	sd	s0,16(sp)
    80003c14:	e426                	sd	s1,8(sp)
    80003c16:	e04a                	sd	s2,0(sp)
    80003c18:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c1a:	c115                	beqz	a0,80003c3e <ilock+0x30>
    80003c1c:	84aa                	mv	s1,a0
    80003c1e:	451c                	lw	a5,8(a0)
    80003c20:	00f05f63          	blez	a5,80003c3e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c24:	0541                	addi	a0,a0,16
    80003c26:	00001097          	auipc	ra,0x1
    80003c2a:	cb2080e7          	jalr	-846(ra) # 800048d8 <acquiresleep>
  if(ip->valid == 0){
    80003c2e:	40bc                	lw	a5,64(s1)
    80003c30:	cf99                	beqz	a5,80003c4e <ilock+0x40>
}
    80003c32:	60e2                	ld	ra,24(sp)
    80003c34:	6442                	ld	s0,16(sp)
    80003c36:	64a2                	ld	s1,8(sp)
    80003c38:	6902                	ld	s2,0(sp)
    80003c3a:	6105                	addi	sp,sp,32
    80003c3c:	8082                	ret
    panic("ilock");
    80003c3e:	00005517          	auipc	a0,0x5
    80003c42:	b6a50513          	addi	a0,a0,-1174 # 800087a8 <syscalls+0x190>
    80003c46:	ffffd097          	auipc	ra,0xffffd
    80003c4a:	8f8080e7          	jalr	-1800(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c4e:	40dc                	lw	a5,4(s1)
    80003c50:	0047d79b          	srliw	a5,a5,0x4
    80003c54:	0001c597          	auipc	a1,0x1c
    80003c58:	fec5a583          	lw	a1,-20(a1) # 8001fc40 <sb+0x18>
    80003c5c:	9dbd                	addw	a1,a1,a5
    80003c5e:	4088                	lw	a0,0(s1)
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	7ac080e7          	jalr	1964(ra) # 8000340c <bread>
    80003c68:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c6a:	05850593          	addi	a1,a0,88
    80003c6e:	40dc                	lw	a5,4(s1)
    80003c70:	8bbd                	andi	a5,a5,15
    80003c72:	079a                	slli	a5,a5,0x6
    80003c74:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c76:	00059783          	lh	a5,0(a1)
    80003c7a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c7e:	00259783          	lh	a5,2(a1)
    80003c82:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c86:	00459783          	lh	a5,4(a1)
    80003c8a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c8e:	00659783          	lh	a5,6(a1)
    80003c92:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c96:	459c                	lw	a5,8(a1)
    80003c98:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c9a:	03400613          	li	a2,52
    80003c9e:	05b1                	addi	a1,a1,12
    80003ca0:	05048513          	addi	a0,s1,80
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	09c080e7          	jalr	156(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cac:	854a                	mv	a0,s2
    80003cae:	00000097          	auipc	ra,0x0
    80003cb2:	88e080e7          	jalr	-1906(ra) # 8000353c <brelse>
    ip->valid = 1;
    80003cb6:	4785                	li	a5,1
    80003cb8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cba:	04449783          	lh	a5,68(s1)
    80003cbe:	fbb5                	bnez	a5,80003c32 <ilock+0x24>
      panic("ilock: no type");
    80003cc0:	00005517          	auipc	a0,0x5
    80003cc4:	af050513          	addi	a0,a0,-1296 # 800087b0 <syscalls+0x198>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	876080e7          	jalr	-1930(ra) # 8000053e <panic>

0000000080003cd0 <iunlock>:
{
    80003cd0:	1101                	addi	sp,sp,-32
    80003cd2:	ec06                	sd	ra,24(sp)
    80003cd4:	e822                	sd	s0,16(sp)
    80003cd6:	e426                	sd	s1,8(sp)
    80003cd8:	e04a                	sd	s2,0(sp)
    80003cda:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cdc:	c905                	beqz	a0,80003d0c <iunlock+0x3c>
    80003cde:	84aa                	mv	s1,a0
    80003ce0:	01050913          	addi	s2,a0,16
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	c8c080e7          	jalr	-884(ra) # 80004972 <holdingsleep>
    80003cee:	cd19                	beqz	a0,80003d0c <iunlock+0x3c>
    80003cf0:	449c                	lw	a5,8(s1)
    80003cf2:	00f05d63          	blez	a5,80003d0c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cf6:	854a                	mv	a0,s2
    80003cf8:	00001097          	auipc	ra,0x1
    80003cfc:	c36080e7          	jalr	-970(ra) # 8000492e <releasesleep>
}
    80003d00:	60e2                	ld	ra,24(sp)
    80003d02:	6442                	ld	s0,16(sp)
    80003d04:	64a2                	ld	s1,8(sp)
    80003d06:	6902                	ld	s2,0(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret
    panic("iunlock");
    80003d0c:	00005517          	auipc	a0,0x5
    80003d10:	ab450513          	addi	a0,a0,-1356 # 800087c0 <syscalls+0x1a8>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	82a080e7          	jalr	-2006(ra) # 8000053e <panic>

0000000080003d1c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d1c:	7179                	addi	sp,sp,-48
    80003d1e:	f406                	sd	ra,40(sp)
    80003d20:	f022                	sd	s0,32(sp)
    80003d22:	ec26                	sd	s1,24(sp)
    80003d24:	e84a                	sd	s2,16(sp)
    80003d26:	e44e                	sd	s3,8(sp)
    80003d28:	e052                	sd	s4,0(sp)
    80003d2a:	1800                	addi	s0,sp,48
    80003d2c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d2e:	05050493          	addi	s1,a0,80
    80003d32:	08050913          	addi	s2,a0,128
    80003d36:	a021                	j	80003d3e <itrunc+0x22>
    80003d38:	0491                	addi	s1,s1,4
    80003d3a:	01248d63          	beq	s1,s2,80003d54 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d3e:	408c                	lw	a1,0(s1)
    80003d40:	dde5                	beqz	a1,80003d38 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d42:	0009a503          	lw	a0,0(s3)
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	90c080e7          	jalr	-1780(ra) # 80003652 <bfree>
      ip->addrs[i] = 0;
    80003d4e:	0004a023          	sw	zero,0(s1)
    80003d52:	b7dd                	j	80003d38 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d54:	0809a583          	lw	a1,128(s3)
    80003d58:	e185                	bnez	a1,80003d78 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d5a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d5e:	854e                	mv	a0,s3
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	de4080e7          	jalr	-540(ra) # 80003b44 <iupdate>
}
    80003d68:	70a2                	ld	ra,40(sp)
    80003d6a:	7402                	ld	s0,32(sp)
    80003d6c:	64e2                	ld	s1,24(sp)
    80003d6e:	6942                	ld	s2,16(sp)
    80003d70:	69a2                	ld	s3,8(sp)
    80003d72:	6a02                	ld	s4,0(sp)
    80003d74:	6145                	addi	sp,sp,48
    80003d76:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d78:	0009a503          	lw	a0,0(s3)
    80003d7c:	fffff097          	auipc	ra,0xfffff
    80003d80:	690080e7          	jalr	1680(ra) # 8000340c <bread>
    80003d84:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d86:	05850493          	addi	s1,a0,88
    80003d8a:	45850913          	addi	s2,a0,1112
    80003d8e:	a811                	j	80003da2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d90:	0009a503          	lw	a0,0(s3)
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	8be080e7          	jalr	-1858(ra) # 80003652 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d9c:	0491                	addi	s1,s1,4
    80003d9e:	01248563          	beq	s1,s2,80003da8 <itrunc+0x8c>
      if(a[j])
    80003da2:	408c                	lw	a1,0(s1)
    80003da4:	dde5                	beqz	a1,80003d9c <itrunc+0x80>
    80003da6:	b7ed                	j	80003d90 <itrunc+0x74>
    brelse(bp);
    80003da8:	8552                	mv	a0,s4
    80003daa:	fffff097          	auipc	ra,0xfffff
    80003dae:	792080e7          	jalr	1938(ra) # 8000353c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003db2:	0809a583          	lw	a1,128(s3)
    80003db6:	0009a503          	lw	a0,0(s3)
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	898080e7          	jalr	-1896(ra) # 80003652 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dc2:	0809a023          	sw	zero,128(s3)
    80003dc6:	bf51                	j	80003d5a <itrunc+0x3e>

0000000080003dc8 <iput>:
{
    80003dc8:	1101                	addi	sp,sp,-32
    80003dca:	ec06                	sd	ra,24(sp)
    80003dcc:	e822                	sd	s0,16(sp)
    80003dce:	e426                	sd	s1,8(sp)
    80003dd0:	e04a                	sd	s2,0(sp)
    80003dd2:	1000                	addi	s0,sp,32
    80003dd4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dd6:	0001c517          	auipc	a0,0x1c
    80003dda:	e7250513          	addi	a0,a0,-398 # 8001fc48 <itable>
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	e06080e7          	jalr	-506(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003de6:	4498                	lw	a4,8(s1)
    80003de8:	4785                	li	a5,1
    80003dea:	02f70363          	beq	a4,a5,80003e10 <iput+0x48>
  ip->ref--;
    80003dee:	449c                	lw	a5,8(s1)
    80003df0:	37fd                	addiw	a5,a5,-1
    80003df2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003df4:	0001c517          	auipc	a0,0x1c
    80003df8:	e5450513          	addi	a0,a0,-428 # 8001fc48 <itable>
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	e9c080e7          	jalr	-356(ra) # 80000c98 <release>
}
    80003e04:	60e2                	ld	ra,24(sp)
    80003e06:	6442                	ld	s0,16(sp)
    80003e08:	64a2                	ld	s1,8(sp)
    80003e0a:	6902                	ld	s2,0(sp)
    80003e0c:	6105                	addi	sp,sp,32
    80003e0e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e10:	40bc                	lw	a5,64(s1)
    80003e12:	dff1                	beqz	a5,80003dee <iput+0x26>
    80003e14:	04a49783          	lh	a5,74(s1)
    80003e18:	fbf9                	bnez	a5,80003dee <iput+0x26>
    acquiresleep(&ip->lock);
    80003e1a:	01048913          	addi	s2,s1,16
    80003e1e:	854a                	mv	a0,s2
    80003e20:	00001097          	auipc	ra,0x1
    80003e24:	ab8080e7          	jalr	-1352(ra) # 800048d8 <acquiresleep>
    release(&itable.lock);
    80003e28:	0001c517          	auipc	a0,0x1c
    80003e2c:	e2050513          	addi	a0,a0,-480 # 8001fc48 <itable>
    80003e30:	ffffd097          	auipc	ra,0xffffd
    80003e34:	e68080e7          	jalr	-408(ra) # 80000c98 <release>
    itrunc(ip);
    80003e38:	8526                	mv	a0,s1
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	ee2080e7          	jalr	-286(ra) # 80003d1c <itrunc>
    ip->type = 0;
    80003e42:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e46:	8526                	mv	a0,s1
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	cfc080e7          	jalr	-772(ra) # 80003b44 <iupdate>
    ip->valid = 0;
    80003e50:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e54:	854a                	mv	a0,s2
    80003e56:	00001097          	auipc	ra,0x1
    80003e5a:	ad8080e7          	jalr	-1320(ra) # 8000492e <releasesleep>
    acquire(&itable.lock);
    80003e5e:	0001c517          	auipc	a0,0x1c
    80003e62:	dea50513          	addi	a0,a0,-534 # 8001fc48 <itable>
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	d7e080e7          	jalr	-642(ra) # 80000be4 <acquire>
    80003e6e:	b741                	j	80003dee <iput+0x26>

0000000080003e70 <iunlockput>:
{
    80003e70:	1101                	addi	sp,sp,-32
    80003e72:	ec06                	sd	ra,24(sp)
    80003e74:	e822                	sd	s0,16(sp)
    80003e76:	e426                	sd	s1,8(sp)
    80003e78:	1000                	addi	s0,sp,32
    80003e7a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	e54080e7          	jalr	-428(ra) # 80003cd0 <iunlock>
  iput(ip);
    80003e84:	8526                	mv	a0,s1
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	f42080e7          	jalr	-190(ra) # 80003dc8 <iput>
}
    80003e8e:	60e2                	ld	ra,24(sp)
    80003e90:	6442                	ld	s0,16(sp)
    80003e92:	64a2                	ld	s1,8(sp)
    80003e94:	6105                	addi	sp,sp,32
    80003e96:	8082                	ret

0000000080003e98 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e98:	1141                	addi	sp,sp,-16
    80003e9a:	e422                	sd	s0,8(sp)
    80003e9c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e9e:	411c                	lw	a5,0(a0)
    80003ea0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ea2:	415c                	lw	a5,4(a0)
    80003ea4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ea6:	04451783          	lh	a5,68(a0)
    80003eaa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eae:	04a51783          	lh	a5,74(a0)
    80003eb2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003eb6:	04c56783          	lwu	a5,76(a0)
    80003eba:	e99c                	sd	a5,16(a1)
}
    80003ebc:	6422                	ld	s0,8(sp)
    80003ebe:	0141                	addi	sp,sp,16
    80003ec0:	8082                	ret

0000000080003ec2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ec2:	457c                	lw	a5,76(a0)
    80003ec4:	0ed7e963          	bltu	a5,a3,80003fb6 <readi+0xf4>
{
    80003ec8:	7159                	addi	sp,sp,-112
    80003eca:	f486                	sd	ra,104(sp)
    80003ecc:	f0a2                	sd	s0,96(sp)
    80003ece:	eca6                	sd	s1,88(sp)
    80003ed0:	e8ca                	sd	s2,80(sp)
    80003ed2:	e4ce                	sd	s3,72(sp)
    80003ed4:	e0d2                	sd	s4,64(sp)
    80003ed6:	fc56                	sd	s5,56(sp)
    80003ed8:	f85a                	sd	s6,48(sp)
    80003eda:	f45e                	sd	s7,40(sp)
    80003edc:	f062                	sd	s8,32(sp)
    80003ede:	ec66                	sd	s9,24(sp)
    80003ee0:	e86a                	sd	s10,16(sp)
    80003ee2:	e46e                	sd	s11,8(sp)
    80003ee4:	1880                	addi	s0,sp,112
    80003ee6:	8baa                	mv	s7,a0
    80003ee8:	8c2e                	mv	s8,a1
    80003eea:	8ab2                	mv	s5,a2
    80003eec:	84b6                	mv	s1,a3
    80003eee:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ef0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ef2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ef4:	0ad76063          	bltu	a4,a3,80003f94 <readi+0xd2>
  if(off + n > ip->size)
    80003ef8:	00e7f463          	bgeu	a5,a4,80003f00 <readi+0x3e>
    n = ip->size - off;
    80003efc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f00:	0a0b0963          	beqz	s6,80003fb2 <readi+0xf0>
    80003f04:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f06:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f0a:	5cfd                	li	s9,-1
    80003f0c:	a82d                	j	80003f46 <readi+0x84>
    80003f0e:	020a1d93          	slli	s11,s4,0x20
    80003f12:	020ddd93          	srli	s11,s11,0x20
    80003f16:	05890613          	addi	a2,s2,88
    80003f1a:	86ee                	mv	a3,s11
    80003f1c:	963a                	add	a2,a2,a4
    80003f1e:	85d6                	mv	a1,s5
    80003f20:	8562                	mv	a0,s8
    80003f22:	fffff097          	auipc	ra,0xfffff
    80003f26:	a76080e7          	jalr	-1418(ra) # 80002998 <either_copyout>
    80003f2a:	05950d63          	beq	a0,s9,80003f84 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f2e:	854a                	mv	a0,s2
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	60c080e7          	jalr	1548(ra) # 8000353c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f38:	013a09bb          	addw	s3,s4,s3
    80003f3c:	009a04bb          	addw	s1,s4,s1
    80003f40:	9aee                	add	s5,s5,s11
    80003f42:	0569f763          	bgeu	s3,s6,80003f90 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f46:	000ba903          	lw	s2,0(s7)
    80003f4a:	00a4d59b          	srliw	a1,s1,0xa
    80003f4e:	855e                	mv	a0,s7
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	8b0080e7          	jalr	-1872(ra) # 80003800 <bmap>
    80003f58:	0005059b          	sext.w	a1,a0
    80003f5c:	854a                	mv	a0,s2
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	4ae080e7          	jalr	1198(ra) # 8000340c <bread>
    80003f66:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f68:	3ff4f713          	andi	a4,s1,1023
    80003f6c:	40ed07bb          	subw	a5,s10,a4
    80003f70:	413b06bb          	subw	a3,s6,s3
    80003f74:	8a3e                	mv	s4,a5
    80003f76:	2781                	sext.w	a5,a5
    80003f78:	0006861b          	sext.w	a2,a3
    80003f7c:	f8f679e3          	bgeu	a2,a5,80003f0e <readi+0x4c>
    80003f80:	8a36                	mv	s4,a3
    80003f82:	b771                	j	80003f0e <readi+0x4c>
      brelse(bp);
    80003f84:	854a                	mv	a0,s2
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	5b6080e7          	jalr	1462(ra) # 8000353c <brelse>
      tot = -1;
    80003f8e:	59fd                	li	s3,-1
  }
  return tot;
    80003f90:	0009851b          	sext.w	a0,s3
}
    80003f94:	70a6                	ld	ra,104(sp)
    80003f96:	7406                	ld	s0,96(sp)
    80003f98:	64e6                	ld	s1,88(sp)
    80003f9a:	6946                	ld	s2,80(sp)
    80003f9c:	69a6                	ld	s3,72(sp)
    80003f9e:	6a06                	ld	s4,64(sp)
    80003fa0:	7ae2                	ld	s5,56(sp)
    80003fa2:	7b42                	ld	s6,48(sp)
    80003fa4:	7ba2                	ld	s7,40(sp)
    80003fa6:	7c02                	ld	s8,32(sp)
    80003fa8:	6ce2                	ld	s9,24(sp)
    80003faa:	6d42                	ld	s10,16(sp)
    80003fac:	6da2                	ld	s11,8(sp)
    80003fae:	6165                	addi	sp,sp,112
    80003fb0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fb2:	89da                	mv	s3,s6
    80003fb4:	bff1                	j	80003f90 <readi+0xce>
    return 0;
    80003fb6:	4501                	li	a0,0
}
    80003fb8:	8082                	ret

0000000080003fba <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fba:	457c                	lw	a5,76(a0)
    80003fbc:	10d7e863          	bltu	a5,a3,800040cc <writei+0x112>
{
    80003fc0:	7159                	addi	sp,sp,-112
    80003fc2:	f486                	sd	ra,104(sp)
    80003fc4:	f0a2                	sd	s0,96(sp)
    80003fc6:	eca6                	sd	s1,88(sp)
    80003fc8:	e8ca                	sd	s2,80(sp)
    80003fca:	e4ce                	sd	s3,72(sp)
    80003fcc:	e0d2                	sd	s4,64(sp)
    80003fce:	fc56                	sd	s5,56(sp)
    80003fd0:	f85a                	sd	s6,48(sp)
    80003fd2:	f45e                	sd	s7,40(sp)
    80003fd4:	f062                	sd	s8,32(sp)
    80003fd6:	ec66                	sd	s9,24(sp)
    80003fd8:	e86a                	sd	s10,16(sp)
    80003fda:	e46e                	sd	s11,8(sp)
    80003fdc:	1880                	addi	s0,sp,112
    80003fde:	8b2a                	mv	s6,a0
    80003fe0:	8c2e                	mv	s8,a1
    80003fe2:	8ab2                	mv	s5,a2
    80003fe4:	8936                	mv	s2,a3
    80003fe6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fe8:	00e687bb          	addw	a5,a3,a4
    80003fec:	0ed7e263          	bltu	a5,a3,800040d0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ff0:	00043737          	lui	a4,0x43
    80003ff4:	0ef76063          	bltu	a4,a5,800040d4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ff8:	0c0b8863          	beqz	s7,800040c8 <writei+0x10e>
    80003ffc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ffe:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004002:	5cfd                	li	s9,-1
    80004004:	a091                	j	80004048 <writei+0x8e>
    80004006:	02099d93          	slli	s11,s3,0x20
    8000400a:	020ddd93          	srli	s11,s11,0x20
    8000400e:	05848513          	addi	a0,s1,88
    80004012:	86ee                	mv	a3,s11
    80004014:	8656                	mv	a2,s5
    80004016:	85e2                	mv	a1,s8
    80004018:	953a                	add	a0,a0,a4
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	9d4080e7          	jalr	-1580(ra) # 800029ee <either_copyin>
    80004022:	07950263          	beq	a0,s9,80004086 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004026:	8526                	mv	a0,s1
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	790080e7          	jalr	1936(ra) # 800047b8 <log_write>
    brelse(bp);
    80004030:	8526                	mv	a0,s1
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	50a080e7          	jalr	1290(ra) # 8000353c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000403a:	01498a3b          	addw	s4,s3,s4
    8000403e:	0129893b          	addw	s2,s3,s2
    80004042:	9aee                	add	s5,s5,s11
    80004044:	057a7663          	bgeu	s4,s7,80004090 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004048:	000b2483          	lw	s1,0(s6)
    8000404c:	00a9559b          	srliw	a1,s2,0xa
    80004050:	855a                	mv	a0,s6
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	7ae080e7          	jalr	1966(ra) # 80003800 <bmap>
    8000405a:	0005059b          	sext.w	a1,a0
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	3ac080e7          	jalr	940(ra) # 8000340c <bread>
    80004068:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406a:	3ff97713          	andi	a4,s2,1023
    8000406e:	40ed07bb          	subw	a5,s10,a4
    80004072:	414b86bb          	subw	a3,s7,s4
    80004076:	89be                	mv	s3,a5
    80004078:	2781                	sext.w	a5,a5
    8000407a:	0006861b          	sext.w	a2,a3
    8000407e:	f8f674e3          	bgeu	a2,a5,80004006 <writei+0x4c>
    80004082:	89b6                	mv	s3,a3
    80004084:	b749                	j	80004006 <writei+0x4c>
      brelse(bp);
    80004086:	8526                	mv	a0,s1
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	4b4080e7          	jalr	1204(ra) # 8000353c <brelse>
  }

  if(off > ip->size)
    80004090:	04cb2783          	lw	a5,76(s6)
    80004094:	0127f463          	bgeu	a5,s2,8000409c <writei+0xe2>
    ip->size = off;
    80004098:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000409c:	855a                	mv	a0,s6
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	aa6080e7          	jalr	-1370(ra) # 80003b44 <iupdate>

  return tot;
    800040a6:	000a051b          	sext.w	a0,s4
}
    800040aa:	70a6                	ld	ra,104(sp)
    800040ac:	7406                	ld	s0,96(sp)
    800040ae:	64e6                	ld	s1,88(sp)
    800040b0:	6946                	ld	s2,80(sp)
    800040b2:	69a6                	ld	s3,72(sp)
    800040b4:	6a06                	ld	s4,64(sp)
    800040b6:	7ae2                	ld	s5,56(sp)
    800040b8:	7b42                	ld	s6,48(sp)
    800040ba:	7ba2                	ld	s7,40(sp)
    800040bc:	7c02                	ld	s8,32(sp)
    800040be:	6ce2                	ld	s9,24(sp)
    800040c0:	6d42                	ld	s10,16(sp)
    800040c2:	6da2                	ld	s11,8(sp)
    800040c4:	6165                	addi	sp,sp,112
    800040c6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040c8:	8a5e                	mv	s4,s7
    800040ca:	bfc9                	j	8000409c <writei+0xe2>
    return -1;
    800040cc:	557d                	li	a0,-1
}
    800040ce:	8082                	ret
    return -1;
    800040d0:	557d                	li	a0,-1
    800040d2:	bfe1                	j	800040aa <writei+0xf0>
    return -1;
    800040d4:	557d                	li	a0,-1
    800040d6:	bfd1                	j	800040aa <writei+0xf0>

00000000800040d8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040d8:	1141                	addi	sp,sp,-16
    800040da:	e406                	sd	ra,8(sp)
    800040dc:	e022                	sd	s0,0(sp)
    800040de:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040e0:	4639                	li	a2,14
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	cd6080e7          	jalr	-810(ra) # 80000db8 <strncmp>
}
    800040ea:	60a2                	ld	ra,8(sp)
    800040ec:	6402                	ld	s0,0(sp)
    800040ee:	0141                	addi	sp,sp,16
    800040f0:	8082                	ret

00000000800040f2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040f2:	7139                	addi	sp,sp,-64
    800040f4:	fc06                	sd	ra,56(sp)
    800040f6:	f822                	sd	s0,48(sp)
    800040f8:	f426                	sd	s1,40(sp)
    800040fa:	f04a                	sd	s2,32(sp)
    800040fc:	ec4e                	sd	s3,24(sp)
    800040fe:	e852                	sd	s4,16(sp)
    80004100:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004102:	04451703          	lh	a4,68(a0)
    80004106:	4785                	li	a5,1
    80004108:	00f71a63          	bne	a4,a5,8000411c <dirlookup+0x2a>
    8000410c:	892a                	mv	s2,a0
    8000410e:	89ae                	mv	s3,a1
    80004110:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004112:	457c                	lw	a5,76(a0)
    80004114:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004116:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004118:	e79d                	bnez	a5,80004146 <dirlookup+0x54>
    8000411a:	a8a5                	j	80004192 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000411c:	00004517          	auipc	a0,0x4
    80004120:	6ac50513          	addi	a0,a0,1708 # 800087c8 <syscalls+0x1b0>
    80004124:	ffffc097          	auipc	ra,0xffffc
    80004128:	41a080e7          	jalr	1050(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000412c:	00004517          	auipc	a0,0x4
    80004130:	6b450513          	addi	a0,a0,1716 # 800087e0 <syscalls+0x1c8>
    80004134:	ffffc097          	auipc	ra,0xffffc
    80004138:	40a080e7          	jalr	1034(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000413c:	24c1                	addiw	s1,s1,16
    8000413e:	04c92783          	lw	a5,76(s2)
    80004142:	04f4f763          	bgeu	s1,a5,80004190 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004146:	4741                	li	a4,16
    80004148:	86a6                	mv	a3,s1
    8000414a:	fc040613          	addi	a2,s0,-64
    8000414e:	4581                	li	a1,0
    80004150:	854a                	mv	a0,s2
    80004152:	00000097          	auipc	ra,0x0
    80004156:	d70080e7          	jalr	-656(ra) # 80003ec2 <readi>
    8000415a:	47c1                	li	a5,16
    8000415c:	fcf518e3          	bne	a0,a5,8000412c <dirlookup+0x3a>
    if(de.inum == 0)
    80004160:	fc045783          	lhu	a5,-64(s0)
    80004164:	dfe1                	beqz	a5,8000413c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004166:	fc240593          	addi	a1,s0,-62
    8000416a:	854e                	mv	a0,s3
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	f6c080e7          	jalr	-148(ra) # 800040d8 <namecmp>
    80004174:	f561                	bnez	a0,8000413c <dirlookup+0x4a>
      if(poff)
    80004176:	000a0463          	beqz	s4,8000417e <dirlookup+0x8c>
        *poff = off;
    8000417a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000417e:	fc045583          	lhu	a1,-64(s0)
    80004182:	00092503          	lw	a0,0(s2)
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	754080e7          	jalr	1876(ra) # 800038da <iget>
    8000418e:	a011                	j	80004192 <dirlookup+0xa0>
  return 0;
    80004190:	4501                	li	a0,0
}
    80004192:	70e2                	ld	ra,56(sp)
    80004194:	7442                	ld	s0,48(sp)
    80004196:	74a2                	ld	s1,40(sp)
    80004198:	7902                	ld	s2,32(sp)
    8000419a:	69e2                	ld	s3,24(sp)
    8000419c:	6a42                	ld	s4,16(sp)
    8000419e:	6121                	addi	sp,sp,64
    800041a0:	8082                	ret

00000000800041a2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041a2:	711d                	addi	sp,sp,-96
    800041a4:	ec86                	sd	ra,88(sp)
    800041a6:	e8a2                	sd	s0,80(sp)
    800041a8:	e4a6                	sd	s1,72(sp)
    800041aa:	e0ca                	sd	s2,64(sp)
    800041ac:	fc4e                	sd	s3,56(sp)
    800041ae:	f852                	sd	s4,48(sp)
    800041b0:	f456                	sd	s5,40(sp)
    800041b2:	f05a                	sd	s6,32(sp)
    800041b4:	ec5e                	sd	s7,24(sp)
    800041b6:	e862                	sd	s8,16(sp)
    800041b8:	e466                	sd	s9,8(sp)
    800041ba:	1080                	addi	s0,sp,96
    800041bc:	84aa                	mv	s1,a0
    800041be:	8b2e                	mv	s6,a1
    800041c0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041c2:	00054703          	lbu	a4,0(a0)
    800041c6:	02f00793          	li	a5,47
    800041ca:	02f70363          	beq	a4,a5,800041f0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041ce:	ffffe097          	auipc	ra,0xffffe
    800041d2:	b54080e7          	jalr	-1196(ra) # 80001d22 <myproc>
    800041d6:	15053503          	ld	a0,336(a0)
    800041da:	00000097          	auipc	ra,0x0
    800041de:	9f6080e7          	jalr	-1546(ra) # 80003bd0 <idup>
    800041e2:	89aa                	mv	s3,a0
  while(*path == '/')
    800041e4:	02f00913          	li	s2,47
  len = path - s;
    800041e8:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041ea:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041ec:	4c05                	li	s8,1
    800041ee:	a865                	j	800042a6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041f0:	4585                	li	a1,1
    800041f2:	4505                	li	a0,1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	6e6080e7          	jalr	1766(ra) # 800038da <iget>
    800041fc:	89aa                	mv	s3,a0
    800041fe:	b7dd                	j	800041e4 <namex+0x42>
      iunlockput(ip);
    80004200:	854e                	mv	a0,s3
    80004202:	00000097          	auipc	ra,0x0
    80004206:	c6e080e7          	jalr	-914(ra) # 80003e70 <iunlockput>
      return 0;
    8000420a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000420c:	854e                	mv	a0,s3
    8000420e:	60e6                	ld	ra,88(sp)
    80004210:	6446                	ld	s0,80(sp)
    80004212:	64a6                	ld	s1,72(sp)
    80004214:	6906                	ld	s2,64(sp)
    80004216:	79e2                	ld	s3,56(sp)
    80004218:	7a42                	ld	s4,48(sp)
    8000421a:	7aa2                	ld	s5,40(sp)
    8000421c:	7b02                	ld	s6,32(sp)
    8000421e:	6be2                	ld	s7,24(sp)
    80004220:	6c42                	ld	s8,16(sp)
    80004222:	6ca2                	ld	s9,8(sp)
    80004224:	6125                	addi	sp,sp,96
    80004226:	8082                	ret
      iunlock(ip);
    80004228:	854e                	mv	a0,s3
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	aa6080e7          	jalr	-1370(ra) # 80003cd0 <iunlock>
      return ip;
    80004232:	bfe9                	j	8000420c <namex+0x6a>
      iunlockput(ip);
    80004234:	854e                	mv	a0,s3
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	c3a080e7          	jalr	-966(ra) # 80003e70 <iunlockput>
      return 0;
    8000423e:	89d2                	mv	s3,s4
    80004240:	b7f1                	j	8000420c <namex+0x6a>
  len = path - s;
    80004242:	40b48633          	sub	a2,s1,a1
    80004246:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000424a:	094cd463          	bge	s9,s4,800042d2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000424e:	4639                	li	a2,14
    80004250:	8556                	mv	a0,s5
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	aee080e7          	jalr	-1298(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000425a:	0004c783          	lbu	a5,0(s1)
    8000425e:	01279763          	bne	a5,s2,8000426c <namex+0xca>
    path++;
    80004262:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004264:	0004c783          	lbu	a5,0(s1)
    80004268:	ff278de3          	beq	a5,s2,80004262 <namex+0xc0>
    ilock(ip);
    8000426c:	854e                	mv	a0,s3
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	9a0080e7          	jalr	-1632(ra) # 80003c0e <ilock>
    if(ip->type != T_DIR){
    80004276:	04499783          	lh	a5,68(s3)
    8000427a:	f98793e3          	bne	a5,s8,80004200 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000427e:	000b0563          	beqz	s6,80004288 <namex+0xe6>
    80004282:	0004c783          	lbu	a5,0(s1)
    80004286:	d3cd                	beqz	a5,80004228 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004288:	865e                	mv	a2,s7
    8000428a:	85d6                	mv	a1,s5
    8000428c:	854e                	mv	a0,s3
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	e64080e7          	jalr	-412(ra) # 800040f2 <dirlookup>
    80004296:	8a2a                	mv	s4,a0
    80004298:	dd51                	beqz	a0,80004234 <namex+0x92>
    iunlockput(ip);
    8000429a:	854e                	mv	a0,s3
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	bd4080e7          	jalr	-1068(ra) # 80003e70 <iunlockput>
    ip = next;
    800042a4:	89d2                	mv	s3,s4
  while(*path == '/')
    800042a6:	0004c783          	lbu	a5,0(s1)
    800042aa:	05279763          	bne	a5,s2,800042f8 <namex+0x156>
    path++;
    800042ae:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042b0:	0004c783          	lbu	a5,0(s1)
    800042b4:	ff278de3          	beq	a5,s2,800042ae <namex+0x10c>
  if(*path == 0)
    800042b8:	c79d                	beqz	a5,800042e6 <namex+0x144>
    path++;
    800042ba:	85a6                	mv	a1,s1
  len = path - s;
    800042bc:	8a5e                	mv	s4,s7
    800042be:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042c0:	01278963          	beq	a5,s2,800042d2 <namex+0x130>
    800042c4:	dfbd                	beqz	a5,80004242 <namex+0xa0>
    path++;
    800042c6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042c8:	0004c783          	lbu	a5,0(s1)
    800042cc:	ff279ce3          	bne	a5,s2,800042c4 <namex+0x122>
    800042d0:	bf8d                	j	80004242 <namex+0xa0>
    memmove(name, s, len);
    800042d2:	2601                	sext.w	a2,a2
    800042d4:	8556                	mv	a0,s5
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	a6a080e7          	jalr	-1430(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042de:	9a56                	add	s4,s4,s5
    800042e0:	000a0023          	sb	zero,0(s4)
    800042e4:	bf9d                	j	8000425a <namex+0xb8>
  if(nameiparent){
    800042e6:	f20b03e3          	beqz	s6,8000420c <namex+0x6a>
    iput(ip);
    800042ea:	854e                	mv	a0,s3
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	adc080e7          	jalr	-1316(ra) # 80003dc8 <iput>
    return 0;
    800042f4:	4981                	li	s3,0
    800042f6:	bf19                	j	8000420c <namex+0x6a>
  if(*path == 0)
    800042f8:	d7fd                	beqz	a5,800042e6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042fa:	0004c783          	lbu	a5,0(s1)
    800042fe:	85a6                	mv	a1,s1
    80004300:	b7d1                	j	800042c4 <namex+0x122>

0000000080004302 <dirlink>:
{
    80004302:	7139                	addi	sp,sp,-64
    80004304:	fc06                	sd	ra,56(sp)
    80004306:	f822                	sd	s0,48(sp)
    80004308:	f426                	sd	s1,40(sp)
    8000430a:	f04a                	sd	s2,32(sp)
    8000430c:	ec4e                	sd	s3,24(sp)
    8000430e:	e852                	sd	s4,16(sp)
    80004310:	0080                	addi	s0,sp,64
    80004312:	892a                	mv	s2,a0
    80004314:	8a2e                	mv	s4,a1
    80004316:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004318:	4601                	li	a2,0
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	dd8080e7          	jalr	-552(ra) # 800040f2 <dirlookup>
    80004322:	e93d                	bnez	a0,80004398 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004324:	04c92483          	lw	s1,76(s2)
    80004328:	c49d                	beqz	s1,80004356 <dirlink+0x54>
    8000432a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000432c:	4741                	li	a4,16
    8000432e:	86a6                	mv	a3,s1
    80004330:	fc040613          	addi	a2,s0,-64
    80004334:	4581                	li	a1,0
    80004336:	854a                	mv	a0,s2
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	b8a080e7          	jalr	-1142(ra) # 80003ec2 <readi>
    80004340:	47c1                	li	a5,16
    80004342:	06f51163          	bne	a0,a5,800043a4 <dirlink+0xa2>
    if(de.inum == 0)
    80004346:	fc045783          	lhu	a5,-64(s0)
    8000434a:	c791                	beqz	a5,80004356 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434c:	24c1                	addiw	s1,s1,16
    8000434e:	04c92783          	lw	a5,76(s2)
    80004352:	fcf4ede3          	bltu	s1,a5,8000432c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004356:	4639                	li	a2,14
    80004358:	85d2                	mv	a1,s4
    8000435a:	fc240513          	addi	a0,s0,-62
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	a96080e7          	jalr	-1386(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004366:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000436a:	4741                	li	a4,16
    8000436c:	86a6                	mv	a3,s1
    8000436e:	fc040613          	addi	a2,s0,-64
    80004372:	4581                	li	a1,0
    80004374:	854a                	mv	a0,s2
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	c44080e7          	jalr	-956(ra) # 80003fba <writei>
    8000437e:	872a                	mv	a4,a0
    80004380:	47c1                	li	a5,16
  return 0;
    80004382:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004384:	02f71863          	bne	a4,a5,800043b4 <dirlink+0xb2>
}
    80004388:	70e2                	ld	ra,56(sp)
    8000438a:	7442                	ld	s0,48(sp)
    8000438c:	74a2                	ld	s1,40(sp)
    8000438e:	7902                	ld	s2,32(sp)
    80004390:	69e2                	ld	s3,24(sp)
    80004392:	6a42                	ld	s4,16(sp)
    80004394:	6121                	addi	sp,sp,64
    80004396:	8082                	ret
    iput(ip);
    80004398:	00000097          	auipc	ra,0x0
    8000439c:	a30080e7          	jalr	-1488(ra) # 80003dc8 <iput>
    return -1;
    800043a0:	557d                	li	a0,-1
    800043a2:	b7dd                	j	80004388 <dirlink+0x86>
      panic("dirlink read");
    800043a4:	00004517          	auipc	a0,0x4
    800043a8:	44c50513          	addi	a0,a0,1100 # 800087f0 <syscalls+0x1d8>
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	192080e7          	jalr	402(ra) # 8000053e <panic>
    panic("dirlink");
    800043b4:	00004517          	auipc	a0,0x4
    800043b8:	54c50513          	addi	a0,a0,1356 # 80008900 <syscalls+0x2e8>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	182080e7          	jalr	386(ra) # 8000053e <panic>

00000000800043c4 <namei>:

struct inode*
namei(char *path)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043cc:	fe040613          	addi	a2,s0,-32
    800043d0:	4581                	li	a1,0
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	dd0080e7          	jalr	-560(ra) # 800041a2 <namex>
}
    800043da:	60e2                	ld	ra,24(sp)
    800043dc:	6442                	ld	s0,16(sp)
    800043de:	6105                	addi	sp,sp,32
    800043e0:	8082                	ret

00000000800043e2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043e2:	1141                	addi	sp,sp,-16
    800043e4:	e406                	sd	ra,8(sp)
    800043e6:	e022                	sd	s0,0(sp)
    800043e8:	0800                	addi	s0,sp,16
    800043ea:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ec:	4585                	li	a1,1
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	db4080e7          	jalr	-588(ra) # 800041a2 <namex>
}
    800043f6:	60a2                	ld	ra,8(sp)
    800043f8:	6402                	ld	s0,0(sp)
    800043fa:	0141                	addi	sp,sp,16
    800043fc:	8082                	ret

00000000800043fe <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043fe:	1101                	addi	sp,sp,-32
    80004400:	ec06                	sd	ra,24(sp)
    80004402:	e822                	sd	s0,16(sp)
    80004404:	e426                	sd	s1,8(sp)
    80004406:	e04a                	sd	s2,0(sp)
    80004408:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000440a:	0001d917          	auipc	s2,0x1d
    8000440e:	2e690913          	addi	s2,s2,742 # 800216f0 <log>
    80004412:	01892583          	lw	a1,24(s2)
    80004416:	02892503          	lw	a0,40(s2)
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	ff2080e7          	jalr	-14(ra) # 8000340c <bread>
    80004422:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004424:	02c92683          	lw	a3,44(s2)
    80004428:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	02d05763          	blez	a3,80004458 <write_head+0x5a>
    8000442e:	0001d797          	auipc	a5,0x1d
    80004432:	2f278793          	addi	a5,a5,754 # 80021720 <log+0x30>
    80004436:	05c50713          	addi	a4,a0,92
    8000443a:	36fd                	addiw	a3,a3,-1
    8000443c:	1682                	slli	a3,a3,0x20
    8000443e:	9281                	srli	a3,a3,0x20
    80004440:	068a                	slli	a3,a3,0x2
    80004442:	0001d617          	auipc	a2,0x1d
    80004446:	2e260613          	addi	a2,a2,738 # 80021724 <log+0x34>
    8000444a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000444c:	4390                	lw	a2,0(a5)
    8000444e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004450:	0791                	addi	a5,a5,4
    80004452:	0711                	addi	a4,a4,4
    80004454:	fed79ce3          	bne	a5,a3,8000444c <write_head+0x4e>
  }
  bwrite(buf);
    80004458:	8526                	mv	a0,s1
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	0a4080e7          	jalr	164(ra) # 800034fe <bwrite>
  brelse(buf);
    80004462:	8526                	mv	a0,s1
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	0d8080e7          	jalr	216(ra) # 8000353c <brelse>
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret

0000000080004478 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004478:	0001d797          	auipc	a5,0x1d
    8000447c:	2a47a783          	lw	a5,676(a5) # 8002171c <log+0x2c>
    80004480:	0af05d63          	blez	a5,8000453a <install_trans+0xc2>
{
    80004484:	7139                	addi	sp,sp,-64
    80004486:	fc06                	sd	ra,56(sp)
    80004488:	f822                	sd	s0,48(sp)
    8000448a:	f426                	sd	s1,40(sp)
    8000448c:	f04a                	sd	s2,32(sp)
    8000448e:	ec4e                	sd	s3,24(sp)
    80004490:	e852                	sd	s4,16(sp)
    80004492:	e456                	sd	s5,8(sp)
    80004494:	e05a                	sd	s6,0(sp)
    80004496:	0080                	addi	s0,sp,64
    80004498:	8b2a                	mv	s6,a0
    8000449a:	0001da97          	auipc	s5,0x1d
    8000449e:	286a8a93          	addi	s5,s5,646 # 80021720 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044a4:	0001d997          	auipc	s3,0x1d
    800044a8:	24c98993          	addi	s3,s3,588 # 800216f0 <log>
    800044ac:	a035                	j	800044d8 <install_trans+0x60>
      bunpin(dbuf);
    800044ae:	8526                	mv	a0,s1
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	166080e7          	jalr	358(ra) # 80003616 <bunpin>
    brelse(lbuf);
    800044b8:	854a                	mv	a0,s2
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	082080e7          	jalr	130(ra) # 8000353c <brelse>
    brelse(dbuf);
    800044c2:	8526                	mv	a0,s1
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	078080e7          	jalr	120(ra) # 8000353c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044cc:	2a05                	addiw	s4,s4,1
    800044ce:	0a91                	addi	s5,s5,4
    800044d0:	02c9a783          	lw	a5,44(s3)
    800044d4:	04fa5963          	bge	s4,a5,80004526 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d8:	0189a583          	lw	a1,24(s3)
    800044dc:	014585bb          	addw	a1,a1,s4
    800044e0:	2585                	addiw	a1,a1,1
    800044e2:	0289a503          	lw	a0,40(s3)
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	f26080e7          	jalr	-218(ra) # 8000340c <bread>
    800044ee:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044f0:	000aa583          	lw	a1,0(s5)
    800044f4:	0289a503          	lw	a0,40(s3)
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	f14080e7          	jalr	-236(ra) # 8000340c <bread>
    80004500:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004502:	40000613          	li	a2,1024
    80004506:	05890593          	addi	a1,s2,88
    8000450a:	05850513          	addi	a0,a0,88
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	832080e7          	jalr	-1998(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004516:	8526                	mv	a0,s1
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	fe6080e7          	jalr	-26(ra) # 800034fe <bwrite>
    if(recovering == 0)
    80004520:	f80b1ce3          	bnez	s6,800044b8 <install_trans+0x40>
    80004524:	b769                	j	800044ae <install_trans+0x36>
}
    80004526:	70e2                	ld	ra,56(sp)
    80004528:	7442                	ld	s0,48(sp)
    8000452a:	74a2                	ld	s1,40(sp)
    8000452c:	7902                	ld	s2,32(sp)
    8000452e:	69e2                	ld	s3,24(sp)
    80004530:	6a42                	ld	s4,16(sp)
    80004532:	6aa2                	ld	s5,8(sp)
    80004534:	6b02                	ld	s6,0(sp)
    80004536:	6121                	addi	sp,sp,64
    80004538:	8082                	ret
    8000453a:	8082                	ret

000000008000453c <initlog>:
{
    8000453c:	7179                	addi	sp,sp,-48
    8000453e:	f406                	sd	ra,40(sp)
    80004540:	f022                	sd	s0,32(sp)
    80004542:	ec26                	sd	s1,24(sp)
    80004544:	e84a                	sd	s2,16(sp)
    80004546:	e44e                	sd	s3,8(sp)
    80004548:	1800                	addi	s0,sp,48
    8000454a:	892a                	mv	s2,a0
    8000454c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000454e:	0001d497          	auipc	s1,0x1d
    80004552:	1a248493          	addi	s1,s1,418 # 800216f0 <log>
    80004556:	00004597          	auipc	a1,0x4
    8000455a:	2aa58593          	addi	a1,a1,682 # 80008800 <syscalls+0x1e8>
    8000455e:	8526                	mv	a0,s1
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	5f4080e7          	jalr	1524(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004568:	0149a583          	lw	a1,20(s3)
    8000456c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000456e:	0109a783          	lw	a5,16(s3)
    80004572:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004574:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004578:	854a                	mv	a0,s2
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	e92080e7          	jalr	-366(ra) # 8000340c <bread>
  log.lh.n = lh->n;
    80004582:	4d3c                	lw	a5,88(a0)
    80004584:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004586:	02f05563          	blez	a5,800045b0 <initlog+0x74>
    8000458a:	05c50713          	addi	a4,a0,92
    8000458e:	0001d697          	auipc	a3,0x1d
    80004592:	19268693          	addi	a3,a3,402 # 80021720 <log+0x30>
    80004596:	37fd                	addiw	a5,a5,-1
    80004598:	1782                	slli	a5,a5,0x20
    8000459a:	9381                	srli	a5,a5,0x20
    8000459c:	078a                	slli	a5,a5,0x2
    8000459e:	06050613          	addi	a2,a0,96
    800045a2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045a4:	4310                	lw	a2,0(a4)
    800045a6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045a8:	0711                	addi	a4,a4,4
    800045aa:	0691                	addi	a3,a3,4
    800045ac:	fef71ce3          	bne	a4,a5,800045a4 <initlog+0x68>
  brelse(buf);
    800045b0:	fffff097          	auipc	ra,0xfffff
    800045b4:	f8c080e7          	jalr	-116(ra) # 8000353c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045b8:	4505                	li	a0,1
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	ebe080e7          	jalr	-322(ra) # 80004478 <install_trans>
  log.lh.n = 0;
    800045c2:	0001d797          	auipc	a5,0x1d
    800045c6:	1407ad23          	sw	zero,346(a5) # 8002171c <log+0x2c>
  write_head(); // clear the log
    800045ca:	00000097          	auipc	ra,0x0
    800045ce:	e34080e7          	jalr	-460(ra) # 800043fe <write_head>
}
    800045d2:	70a2                	ld	ra,40(sp)
    800045d4:	7402                	ld	s0,32(sp)
    800045d6:	64e2                	ld	s1,24(sp)
    800045d8:	6942                	ld	s2,16(sp)
    800045da:	69a2                	ld	s3,8(sp)
    800045dc:	6145                	addi	sp,sp,48
    800045de:	8082                	ret

00000000800045e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045e0:	1101                	addi	sp,sp,-32
    800045e2:	ec06                	sd	ra,24(sp)
    800045e4:	e822                	sd	s0,16(sp)
    800045e6:	e426                	sd	s1,8(sp)
    800045e8:	e04a                	sd	s2,0(sp)
    800045ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045ec:	0001d517          	auipc	a0,0x1d
    800045f0:	10450513          	addi	a0,a0,260 # 800216f0 <log>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045fc:	0001d497          	auipc	s1,0x1d
    80004600:	0f448493          	addi	s1,s1,244 # 800216f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004604:	4979                	li	s2,30
    80004606:	a039                	j	80004614 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004608:	85a6                	mv	a1,s1
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffe097          	auipc	ra,0xffffe
    80004610:	f24080e7          	jalr	-220(ra) # 80002530 <sleep>
    if(log.committing){
    80004614:	50dc                	lw	a5,36(s1)
    80004616:	fbed                	bnez	a5,80004608 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004618:	509c                	lw	a5,32(s1)
    8000461a:	0017871b          	addiw	a4,a5,1
    8000461e:	0007069b          	sext.w	a3,a4
    80004622:	0027179b          	slliw	a5,a4,0x2
    80004626:	9fb9                	addw	a5,a5,a4
    80004628:	0017979b          	slliw	a5,a5,0x1
    8000462c:	54d8                	lw	a4,44(s1)
    8000462e:	9fb9                	addw	a5,a5,a4
    80004630:	00f95963          	bge	s2,a5,80004642 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004634:	85a6                	mv	a1,s1
    80004636:	8526                	mv	a0,s1
    80004638:	ffffe097          	auipc	ra,0xffffe
    8000463c:	ef8080e7          	jalr	-264(ra) # 80002530 <sleep>
    80004640:	bfd1                	j	80004614 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004642:	0001d517          	auipc	a0,0x1d
    80004646:	0ae50513          	addi	a0,a0,174 # 800216f0 <log>
    8000464a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	64c080e7          	jalr	1612(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004654:	60e2                	ld	ra,24(sp)
    80004656:	6442                	ld	s0,16(sp)
    80004658:	64a2                	ld	s1,8(sp)
    8000465a:	6902                	ld	s2,0(sp)
    8000465c:	6105                	addi	sp,sp,32
    8000465e:	8082                	ret

0000000080004660 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004660:	7139                	addi	sp,sp,-64
    80004662:	fc06                	sd	ra,56(sp)
    80004664:	f822                	sd	s0,48(sp)
    80004666:	f426                	sd	s1,40(sp)
    80004668:	f04a                	sd	s2,32(sp)
    8000466a:	ec4e                	sd	s3,24(sp)
    8000466c:	e852                	sd	s4,16(sp)
    8000466e:	e456                	sd	s5,8(sp)
    80004670:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004672:	0001d497          	auipc	s1,0x1d
    80004676:	07e48493          	addi	s1,s1,126 # 800216f0 <log>
    8000467a:	8526                	mv	a0,s1
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004684:	509c                	lw	a5,32(s1)
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	0007891b          	sext.w	s2,a5
    8000468c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000468e:	50dc                	lw	a5,36(s1)
    80004690:	efb9                	bnez	a5,800046ee <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004692:	06091663          	bnez	s2,800046fe <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004696:	0001d497          	auipc	s1,0x1d
    8000469a:	05a48493          	addi	s1,s1,90 # 800216f0 <log>
    8000469e:	4785                	li	a5,1
    800046a0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046a2:	8526                	mv	a0,s1
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046ac:	54dc                	lw	a5,44(s1)
    800046ae:	06f04763          	bgtz	a5,8000471c <end_op+0xbc>
    acquire(&log.lock);
    800046b2:	0001d497          	auipc	s1,0x1d
    800046b6:	03e48493          	addi	s1,s1,62 # 800216f0 <log>
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	528080e7          	jalr	1320(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046c4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	018080e7          	jalr	24(ra) # 800026e2 <wakeup>
    release(&log.lock);
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
}
    800046dc:	70e2                	ld	ra,56(sp)
    800046de:	7442                	ld	s0,48(sp)
    800046e0:	74a2                	ld	s1,40(sp)
    800046e2:	7902                	ld	s2,32(sp)
    800046e4:	69e2                	ld	s3,24(sp)
    800046e6:	6a42                	ld	s4,16(sp)
    800046e8:	6aa2                	ld	s5,8(sp)
    800046ea:	6121                	addi	sp,sp,64
    800046ec:	8082                	ret
    panic("log.committing");
    800046ee:	00004517          	auipc	a0,0x4
    800046f2:	11a50513          	addi	a0,a0,282 # 80008808 <syscalls+0x1f0>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	e48080e7          	jalr	-440(ra) # 8000053e <panic>
    wakeup(&log);
    800046fe:	0001d497          	auipc	s1,0x1d
    80004702:	ff248493          	addi	s1,s1,-14 # 800216f0 <log>
    80004706:	8526                	mv	a0,s1
    80004708:	ffffe097          	auipc	ra,0xffffe
    8000470c:	fda080e7          	jalr	-38(ra) # 800026e2 <wakeup>
  release(&log.lock);
    80004710:	8526                	mv	a0,s1
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	586080e7          	jalr	1414(ra) # 80000c98 <release>
  if(do_commit){
    8000471a:	b7c9                	j	800046dc <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000471c:	0001da97          	auipc	s5,0x1d
    80004720:	004a8a93          	addi	s5,s5,4 # 80021720 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004724:	0001da17          	auipc	s4,0x1d
    80004728:	fcca0a13          	addi	s4,s4,-52 # 800216f0 <log>
    8000472c:	018a2583          	lw	a1,24(s4)
    80004730:	012585bb          	addw	a1,a1,s2
    80004734:	2585                	addiw	a1,a1,1
    80004736:	028a2503          	lw	a0,40(s4)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	cd2080e7          	jalr	-814(ra) # 8000340c <bread>
    80004742:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004744:	000aa583          	lw	a1,0(s5)
    80004748:	028a2503          	lw	a0,40(s4)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	cc0080e7          	jalr	-832(ra) # 8000340c <bread>
    80004754:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004756:	40000613          	li	a2,1024
    8000475a:	05850593          	addi	a1,a0,88
    8000475e:	05848513          	addi	a0,s1,88
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	5de080e7          	jalr	1502(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000476a:	8526                	mv	a0,s1
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	d92080e7          	jalr	-622(ra) # 800034fe <bwrite>
    brelse(from);
    80004774:	854e                	mv	a0,s3
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	dc6080e7          	jalr	-570(ra) # 8000353c <brelse>
    brelse(to);
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	dbc080e7          	jalr	-580(ra) # 8000353c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004788:	2905                	addiw	s2,s2,1
    8000478a:	0a91                	addi	s5,s5,4
    8000478c:	02ca2783          	lw	a5,44(s4)
    80004790:	f8f94ee3          	blt	s2,a5,8000472c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004794:	00000097          	auipc	ra,0x0
    80004798:	c6a080e7          	jalr	-918(ra) # 800043fe <write_head>
    install_trans(0); // Now install writes to home locations
    8000479c:	4501                	li	a0,0
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	cda080e7          	jalr	-806(ra) # 80004478 <install_trans>
    log.lh.n = 0;
    800047a6:	0001d797          	auipc	a5,0x1d
    800047aa:	f607ab23          	sw	zero,-138(a5) # 8002171c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047ae:	00000097          	auipc	ra,0x0
    800047b2:	c50080e7          	jalr	-944(ra) # 800043fe <write_head>
    800047b6:	bdf5                	j	800046b2 <end_op+0x52>

00000000800047b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047b8:	1101                	addi	sp,sp,-32
    800047ba:	ec06                	sd	ra,24(sp)
    800047bc:	e822                	sd	s0,16(sp)
    800047be:	e426                	sd	s1,8(sp)
    800047c0:	e04a                	sd	s2,0(sp)
    800047c2:	1000                	addi	s0,sp,32
    800047c4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047c6:	0001d917          	auipc	s2,0x1d
    800047ca:	f2a90913          	addi	s2,s2,-214 # 800216f0 <log>
    800047ce:	854a                	mv	a0,s2
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	414080e7          	jalr	1044(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047d8:	02c92603          	lw	a2,44(s2)
    800047dc:	47f5                	li	a5,29
    800047de:	06c7c563          	blt	a5,a2,80004848 <log_write+0x90>
    800047e2:	0001d797          	auipc	a5,0x1d
    800047e6:	f2a7a783          	lw	a5,-214(a5) # 8002170c <log+0x1c>
    800047ea:	37fd                	addiw	a5,a5,-1
    800047ec:	04f65e63          	bge	a2,a5,80004848 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047f0:	0001d797          	auipc	a5,0x1d
    800047f4:	f207a783          	lw	a5,-224(a5) # 80021710 <log+0x20>
    800047f8:	06f05063          	blez	a5,80004858 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047fc:	4781                	li	a5,0
    800047fe:	06c05563          	blez	a2,80004868 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004802:	44cc                	lw	a1,12(s1)
    80004804:	0001d717          	auipc	a4,0x1d
    80004808:	f1c70713          	addi	a4,a4,-228 # 80021720 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000480c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000480e:	4314                	lw	a3,0(a4)
    80004810:	04b68c63          	beq	a3,a1,80004868 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004814:	2785                	addiw	a5,a5,1
    80004816:	0711                	addi	a4,a4,4
    80004818:	fef61be3          	bne	a2,a5,8000480e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000481c:	0621                	addi	a2,a2,8
    8000481e:	060a                	slli	a2,a2,0x2
    80004820:	0001d797          	auipc	a5,0x1d
    80004824:	ed078793          	addi	a5,a5,-304 # 800216f0 <log>
    80004828:	963e                	add	a2,a2,a5
    8000482a:	44dc                	lw	a5,12(s1)
    8000482c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000482e:	8526                	mv	a0,s1
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	daa080e7          	jalr	-598(ra) # 800035da <bpin>
    log.lh.n++;
    80004838:	0001d717          	auipc	a4,0x1d
    8000483c:	eb870713          	addi	a4,a4,-328 # 800216f0 <log>
    80004840:	575c                	lw	a5,44(a4)
    80004842:	2785                	addiw	a5,a5,1
    80004844:	d75c                	sw	a5,44(a4)
    80004846:	a835                	j	80004882 <log_write+0xca>
    panic("too big a transaction");
    80004848:	00004517          	auipc	a0,0x4
    8000484c:	fd050513          	addi	a0,a0,-48 # 80008818 <syscalls+0x200>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	cee080e7          	jalr	-786(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004858:	00004517          	auipc	a0,0x4
    8000485c:	fd850513          	addi	a0,a0,-40 # 80008830 <syscalls+0x218>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	cde080e7          	jalr	-802(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004868:	00878713          	addi	a4,a5,8
    8000486c:	00271693          	slli	a3,a4,0x2
    80004870:	0001d717          	auipc	a4,0x1d
    80004874:	e8070713          	addi	a4,a4,-384 # 800216f0 <log>
    80004878:	9736                	add	a4,a4,a3
    8000487a:	44d4                	lw	a3,12(s1)
    8000487c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000487e:	faf608e3          	beq	a2,a5,8000482e <log_write+0x76>
  }
  release(&log.lock);
    80004882:	0001d517          	auipc	a0,0x1d
    80004886:	e6e50513          	addi	a0,a0,-402 # 800216f0 <log>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	40e080e7          	jalr	1038(ra) # 80000c98 <release>
}
    80004892:	60e2                	ld	ra,24(sp)
    80004894:	6442                	ld	s0,16(sp)
    80004896:	64a2                	ld	s1,8(sp)
    80004898:	6902                	ld	s2,0(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret

000000008000489e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000489e:	1101                	addi	sp,sp,-32
    800048a0:	ec06                	sd	ra,24(sp)
    800048a2:	e822                	sd	s0,16(sp)
    800048a4:	e426                	sd	s1,8(sp)
    800048a6:	e04a                	sd	s2,0(sp)
    800048a8:	1000                	addi	s0,sp,32
    800048aa:	84aa                	mv	s1,a0
    800048ac:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048ae:	00004597          	auipc	a1,0x4
    800048b2:	fa258593          	addi	a1,a1,-94 # 80008850 <syscalls+0x238>
    800048b6:	0521                	addi	a0,a0,8
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	29c080e7          	jalr	668(ra) # 80000b54 <initlock>
  lk->name = name;
    800048c0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048c4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048c8:	0204a423          	sw	zero,40(s1)
}
    800048cc:	60e2                	ld	ra,24(sp)
    800048ce:	6442                	ld	s0,16(sp)
    800048d0:	64a2                	ld	s1,8(sp)
    800048d2:	6902                	ld	s2,0(sp)
    800048d4:	6105                	addi	sp,sp,32
    800048d6:	8082                	ret

00000000800048d8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048d8:	1101                	addi	sp,sp,-32
    800048da:	ec06                	sd	ra,24(sp)
    800048dc:	e822                	sd	s0,16(sp)
    800048de:	e426                	sd	s1,8(sp)
    800048e0:	e04a                	sd	s2,0(sp)
    800048e2:	1000                	addi	s0,sp,32
    800048e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048e6:	00850913          	addi	s2,a0,8
    800048ea:	854a                	mv	a0,s2
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	2f8080e7          	jalr	760(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048f4:	409c                	lw	a5,0(s1)
    800048f6:	cb89                	beqz	a5,80004908 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048f8:	85ca                	mv	a1,s2
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffe097          	auipc	ra,0xffffe
    80004900:	c34080e7          	jalr	-972(ra) # 80002530 <sleep>
  while (lk->locked) {
    80004904:	409c                	lw	a5,0(s1)
    80004906:	fbed                	bnez	a5,800048f8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004908:	4785                	li	a5,1
    8000490a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000490c:	ffffd097          	auipc	ra,0xffffd
    80004910:	416080e7          	jalr	1046(ra) # 80001d22 <myproc>
    80004914:	591c                	lw	a5,48(a0)
    80004916:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004918:	854a                	mv	a0,s2
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	37e080e7          	jalr	894(ra) # 80000c98 <release>
}
    80004922:	60e2                	ld	ra,24(sp)
    80004924:	6442                	ld	s0,16(sp)
    80004926:	64a2                	ld	s1,8(sp)
    80004928:	6902                	ld	s2,0(sp)
    8000492a:	6105                	addi	sp,sp,32
    8000492c:	8082                	ret

000000008000492e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000492e:	1101                	addi	sp,sp,-32
    80004930:	ec06                	sd	ra,24(sp)
    80004932:	e822                	sd	s0,16(sp)
    80004934:	e426                	sd	s1,8(sp)
    80004936:	e04a                	sd	s2,0(sp)
    80004938:	1000                	addi	s0,sp,32
    8000493a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000493c:	00850913          	addi	s2,a0,8
    80004940:	854a                	mv	a0,s2
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	2a2080e7          	jalr	674(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000494a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000494e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004952:	8526                	mv	a0,s1
    80004954:	ffffe097          	auipc	ra,0xffffe
    80004958:	d8e080e7          	jalr	-626(ra) # 800026e2 <wakeup>
  release(&lk->lk);
    8000495c:	854a                	mv	a0,s2
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	33a080e7          	jalr	826(ra) # 80000c98 <release>
}
    80004966:	60e2                	ld	ra,24(sp)
    80004968:	6442                	ld	s0,16(sp)
    8000496a:	64a2                	ld	s1,8(sp)
    8000496c:	6902                	ld	s2,0(sp)
    8000496e:	6105                	addi	sp,sp,32
    80004970:	8082                	ret

0000000080004972 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004972:	7179                	addi	sp,sp,-48
    80004974:	f406                	sd	ra,40(sp)
    80004976:	f022                	sd	s0,32(sp)
    80004978:	ec26                	sd	s1,24(sp)
    8000497a:	e84a                	sd	s2,16(sp)
    8000497c:	e44e                	sd	s3,8(sp)
    8000497e:	1800                	addi	s0,sp,48
    80004980:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004982:	00850913          	addi	s2,a0,8
    80004986:	854a                	mv	a0,s2
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	25c080e7          	jalr	604(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004990:	409c                	lw	a5,0(s1)
    80004992:	ef99                	bnez	a5,800049b0 <holdingsleep+0x3e>
    80004994:	4481                	li	s1,0
  release(&lk->lk);
    80004996:	854a                	mv	a0,s2
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	300080e7          	jalr	768(ra) # 80000c98 <release>
  return r;
}
    800049a0:	8526                	mv	a0,s1
    800049a2:	70a2                	ld	ra,40(sp)
    800049a4:	7402                	ld	s0,32(sp)
    800049a6:	64e2                	ld	s1,24(sp)
    800049a8:	6942                	ld	s2,16(sp)
    800049aa:	69a2                	ld	s3,8(sp)
    800049ac:	6145                	addi	sp,sp,48
    800049ae:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049b0:	0284a983          	lw	s3,40(s1)
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	36e080e7          	jalr	878(ra) # 80001d22 <myproc>
    800049bc:	5904                	lw	s1,48(a0)
    800049be:	413484b3          	sub	s1,s1,s3
    800049c2:	0014b493          	seqz	s1,s1
    800049c6:	bfc1                	j	80004996 <holdingsleep+0x24>

00000000800049c8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049c8:	1141                	addi	sp,sp,-16
    800049ca:	e406                	sd	ra,8(sp)
    800049cc:	e022                	sd	s0,0(sp)
    800049ce:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049d0:	00004597          	auipc	a1,0x4
    800049d4:	e9058593          	addi	a1,a1,-368 # 80008860 <syscalls+0x248>
    800049d8:	0001d517          	auipc	a0,0x1d
    800049dc:	e6050513          	addi	a0,a0,-416 # 80021838 <ftable>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	174080e7          	jalr	372(ra) # 80000b54 <initlock>
}
    800049e8:	60a2                	ld	ra,8(sp)
    800049ea:	6402                	ld	s0,0(sp)
    800049ec:	0141                	addi	sp,sp,16
    800049ee:	8082                	ret

00000000800049f0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049f0:	1101                	addi	sp,sp,-32
    800049f2:	ec06                	sd	ra,24(sp)
    800049f4:	e822                	sd	s0,16(sp)
    800049f6:	e426                	sd	s1,8(sp)
    800049f8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049fa:	0001d517          	auipc	a0,0x1d
    800049fe:	e3e50513          	addi	a0,a0,-450 # 80021838 <ftable>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	1e2080e7          	jalr	482(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a0a:	0001d497          	auipc	s1,0x1d
    80004a0e:	e4648493          	addi	s1,s1,-442 # 80021850 <ftable+0x18>
    80004a12:	0001e717          	auipc	a4,0x1e
    80004a16:	dde70713          	addi	a4,a4,-546 # 800227f0 <ftable+0xfb8>
    if(f->ref == 0){
    80004a1a:	40dc                	lw	a5,4(s1)
    80004a1c:	cf99                	beqz	a5,80004a3a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a1e:	02848493          	addi	s1,s1,40
    80004a22:	fee49ce3          	bne	s1,a4,80004a1a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a26:	0001d517          	auipc	a0,0x1d
    80004a2a:	e1250513          	addi	a0,a0,-494 # 80021838 <ftable>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	26a080e7          	jalr	618(ra) # 80000c98 <release>
  return 0;
    80004a36:	4481                	li	s1,0
    80004a38:	a819                	j	80004a4e <filealloc+0x5e>
      f->ref = 1;
    80004a3a:	4785                	li	a5,1
    80004a3c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a3e:	0001d517          	auipc	a0,0x1d
    80004a42:	dfa50513          	addi	a0,a0,-518 # 80021838 <ftable>
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	252080e7          	jalr	594(ra) # 80000c98 <release>
}
    80004a4e:	8526                	mv	a0,s1
    80004a50:	60e2                	ld	ra,24(sp)
    80004a52:	6442                	ld	s0,16(sp)
    80004a54:	64a2                	ld	s1,8(sp)
    80004a56:	6105                	addi	sp,sp,32
    80004a58:	8082                	ret

0000000080004a5a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	1000                	addi	s0,sp,32
    80004a64:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a66:	0001d517          	auipc	a0,0x1d
    80004a6a:	dd250513          	addi	a0,a0,-558 # 80021838 <ftable>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	176080e7          	jalr	374(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a76:	40dc                	lw	a5,4(s1)
    80004a78:	02f05263          	blez	a5,80004a9c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a7c:	2785                	addiw	a5,a5,1
    80004a7e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a80:	0001d517          	auipc	a0,0x1d
    80004a84:	db850513          	addi	a0,a0,-584 # 80021838 <ftable>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	210080e7          	jalr	528(ra) # 80000c98 <release>
  return f;
}
    80004a90:	8526                	mv	a0,s1
    80004a92:	60e2                	ld	ra,24(sp)
    80004a94:	6442                	ld	s0,16(sp)
    80004a96:	64a2                	ld	s1,8(sp)
    80004a98:	6105                	addi	sp,sp,32
    80004a9a:	8082                	ret
    panic("filedup");
    80004a9c:	00004517          	auipc	a0,0x4
    80004aa0:	dcc50513          	addi	a0,a0,-564 # 80008868 <syscalls+0x250>
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	a9a080e7          	jalr	-1382(ra) # 8000053e <panic>

0000000080004aac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004aac:	7139                	addi	sp,sp,-64
    80004aae:	fc06                	sd	ra,56(sp)
    80004ab0:	f822                	sd	s0,48(sp)
    80004ab2:	f426                	sd	s1,40(sp)
    80004ab4:	f04a                	sd	s2,32(sp)
    80004ab6:	ec4e                	sd	s3,24(sp)
    80004ab8:	e852                	sd	s4,16(sp)
    80004aba:	e456                	sd	s5,8(sp)
    80004abc:	0080                	addi	s0,sp,64
    80004abe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ac0:	0001d517          	auipc	a0,0x1d
    80004ac4:	d7850513          	addi	a0,a0,-648 # 80021838 <ftable>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	11c080e7          	jalr	284(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ad0:	40dc                	lw	a5,4(s1)
    80004ad2:	06f05163          	blez	a5,80004b34 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ad6:	37fd                	addiw	a5,a5,-1
    80004ad8:	0007871b          	sext.w	a4,a5
    80004adc:	c0dc                	sw	a5,4(s1)
    80004ade:	06e04363          	bgtz	a4,80004b44 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ae2:	0004a903          	lw	s2,0(s1)
    80004ae6:	0094ca83          	lbu	s5,9(s1)
    80004aea:	0104ba03          	ld	s4,16(s1)
    80004aee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004af2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004af6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004afa:	0001d517          	auipc	a0,0x1d
    80004afe:	d3e50513          	addi	a0,a0,-706 # 80021838 <ftable>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	196080e7          	jalr	406(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b0a:	4785                	li	a5,1
    80004b0c:	04f90d63          	beq	s2,a5,80004b66 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b10:	3979                	addiw	s2,s2,-2
    80004b12:	4785                	li	a5,1
    80004b14:	0527e063          	bltu	a5,s2,80004b54 <fileclose+0xa8>
    begin_op();
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	ac8080e7          	jalr	-1336(ra) # 800045e0 <begin_op>
    iput(ff.ip);
    80004b20:	854e                	mv	a0,s3
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	2a6080e7          	jalr	678(ra) # 80003dc8 <iput>
    end_op();
    80004b2a:	00000097          	auipc	ra,0x0
    80004b2e:	b36080e7          	jalr	-1226(ra) # 80004660 <end_op>
    80004b32:	a00d                	j	80004b54 <fileclose+0xa8>
    panic("fileclose");
    80004b34:	00004517          	auipc	a0,0x4
    80004b38:	d3c50513          	addi	a0,a0,-708 # 80008870 <syscalls+0x258>
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	a02080e7          	jalr	-1534(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b44:	0001d517          	auipc	a0,0x1d
    80004b48:	cf450513          	addi	a0,a0,-780 # 80021838 <ftable>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	14c080e7          	jalr	332(ra) # 80000c98 <release>
  }
}
    80004b54:	70e2                	ld	ra,56(sp)
    80004b56:	7442                	ld	s0,48(sp)
    80004b58:	74a2                	ld	s1,40(sp)
    80004b5a:	7902                	ld	s2,32(sp)
    80004b5c:	69e2                	ld	s3,24(sp)
    80004b5e:	6a42                	ld	s4,16(sp)
    80004b60:	6aa2                	ld	s5,8(sp)
    80004b62:	6121                	addi	sp,sp,64
    80004b64:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b66:	85d6                	mv	a1,s5
    80004b68:	8552                	mv	a0,s4
    80004b6a:	00000097          	auipc	ra,0x0
    80004b6e:	34c080e7          	jalr	844(ra) # 80004eb6 <pipeclose>
    80004b72:	b7cd                	j	80004b54 <fileclose+0xa8>

0000000080004b74 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b74:	715d                	addi	sp,sp,-80
    80004b76:	e486                	sd	ra,72(sp)
    80004b78:	e0a2                	sd	s0,64(sp)
    80004b7a:	fc26                	sd	s1,56(sp)
    80004b7c:	f84a                	sd	s2,48(sp)
    80004b7e:	f44e                	sd	s3,40(sp)
    80004b80:	0880                	addi	s0,sp,80
    80004b82:	84aa                	mv	s1,a0
    80004b84:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b86:	ffffd097          	auipc	ra,0xffffd
    80004b8a:	19c080e7          	jalr	412(ra) # 80001d22 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b8e:	409c                	lw	a5,0(s1)
    80004b90:	37f9                	addiw	a5,a5,-2
    80004b92:	4705                	li	a4,1
    80004b94:	04f76763          	bltu	a4,a5,80004be2 <filestat+0x6e>
    80004b98:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b9a:	6c88                	ld	a0,24(s1)
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	072080e7          	jalr	114(ra) # 80003c0e <ilock>
    stati(f->ip, &st);
    80004ba4:	fb840593          	addi	a1,s0,-72
    80004ba8:	6c88                	ld	a0,24(s1)
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	2ee080e7          	jalr	750(ra) # 80003e98 <stati>
    iunlock(f->ip);
    80004bb2:	6c88                	ld	a0,24(s1)
    80004bb4:	fffff097          	auipc	ra,0xfffff
    80004bb8:	11c080e7          	jalr	284(ra) # 80003cd0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bbc:	46e1                	li	a3,24
    80004bbe:	fb840613          	addi	a2,s0,-72
    80004bc2:	85ce                	mv	a1,s3
    80004bc4:	05093503          	ld	a0,80(s2)
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	aaa080e7          	jalr	-1366(ra) # 80001672 <copyout>
    80004bd0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bd4:	60a6                	ld	ra,72(sp)
    80004bd6:	6406                	ld	s0,64(sp)
    80004bd8:	74e2                	ld	s1,56(sp)
    80004bda:	7942                	ld	s2,48(sp)
    80004bdc:	79a2                	ld	s3,40(sp)
    80004bde:	6161                	addi	sp,sp,80
    80004be0:	8082                	ret
  return -1;
    80004be2:	557d                	li	a0,-1
    80004be4:	bfc5                	j	80004bd4 <filestat+0x60>

0000000080004be6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004be6:	7179                	addi	sp,sp,-48
    80004be8:	f406                	sd	ra,40(sp)
    80004bea:	f022                	sd	s0,32(sp)
    80004bec:	ec26                	sd	s1,24(sp)
    80004bee:	e84a                	sd	s2,16(sp)
    80004bf0:	e44e                	sd	s3,8(sp)
    80004bf2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bf4:	00854783          	lbu	a5,8(a0)
    80004bf8:	c3d5                	beqz	a5,80004c9c <fileread+0xb6>
    80004bfa:	84aa                	mv	s1,a0
    80004bfc:	89ae                	mv	s3,a1
    80004bfe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c00:	411c                	lw	a5,0(a0)
    80004c02:	4705                	li	a4,1
    80004c04:	04e78963          	beq	a5,a4,80004c56 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c08:	470d                	li	a4,3
    80004c0a:	04e78d63          	beq	a5,a4,80004c64 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c0e:	4709                	li	a4,2
    80004c10:	06e79e63          	bne	a5,a4,80004c8c <fileread+0xa6>
    ilock(f->ip);
    80004c14:	6d08                	ld	a0,24(a0)
    80004c16:	fffff097          	auipc	ra,0xfffff
    80004c1a:	ff8080e7          	jalr	-8(ra) # 80003c0e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c1e:	874a                	mv	a4,s2
    80004c20:	5094                	lw	a3,32(s1)
    80004c22:	864e                	mv	a2,s3
    80004c24:	4585                	li	a1,1
    80004c26:	6c88                	ld	a0,24(s1)
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	29a080e7          	jalr	666(ra) # 80003ec2 <readi>
    80004c30:	892a                	mv	s2,a0
    80004c32:	00a05563          	blez	a0,80004c3c <fileread+0x56>
      f->off += r;
    80004c36:	509c                	lw	a5,32(s1)
    80004c38:	9fa9                	addw	a5,a5,a0
    80004c3a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c3c:	6c88                	ld	a0,24(s1)
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	092080e7          	jalr	146(ra) # 80003cd0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c46:	854a                	mv	a0,s2
    80004c48:	70a2                	ld	ra,40(sp)
    80004c4a:	7402                	ld	s0,32(sp)
    80004c4c:	64e2                	ld	s1,24(sp)
    80004c4e:	6942                	ld	s2,16(sp)
    80004c50:	69a2                	ld	s3,8(sp)
    80004c52:	6145                	addi	sp,sp,48
    80004c54:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c56:	6908                	ld	a0,16(a0)
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	3c8080e7          	jalr	968(ra) # 80005020 <piperead>
    80004c60:	892a                	mv	s2,a0
    80004c62:	b7d5                	j	80004c46 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c64:	02451783          	lh	a5,36(a0)
    80004c68:	03079693          	slli	a3,a5,0x30
    80004c6c:	92c1                	srli	a3,a3,0x30
    80004c6e:	4725                	li	a4,9
    80004c70:	02d76863          	bltu	a4,a3,80004ca0 <fileread+0xba>
    80004c74:	0792                	slli	a5,a5,0x4
    80004c76:	0001d717          	auipc	a4,0x1d
    80004c7a:	b2270713          	addi	a4,a4,-1246 # 80021798 <devsw>
    80004c7e:	97ba                	add	a5,a5,a4
    80004c80:	639c                	ld	a5,0(a5)
    80004c82:	c38d                	beqz	a5,80004ca4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c84:	4505                	li	a0,1
    80004c86:	9782                	jalr	a5
    80004c88:	892a                	mv	s2,a0
    80004c8a:	bf75                	j	80004c46 <fileread+0x60>
    panic("fileread");
    80004c8c:	00004517          	auipc	a0,0x4
    80004c90:	bf450513          	addi	a0,a0,-1036 # 80008880 <syscalls+0x268>
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	8aa080e7          	jalr	-1878(ra) # 8000053e <panic>
    return -1;
    80004c9c:	597d                	li	s2,-1
    80004c9e:	b765                	j	80004c46 <fileread+0x60>
      return -1;
    80004ca0:	597d                	li	s2,-1
    80004ca2:	b755                	j	80004c46 <fileread+0x60>
    80004ca4:	597d                	li	s2,-1
    80004ca6:	b745                	j	80004c46 <fileread+0x60>

0000000080004ca8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ca8:	715d                	addi	sp,sp,-80
    80004caa:	e486                	sd	ra,72(sp)
    80004cac:	e0a2                	sd	s0,64(sp)
    80004cae:	fc26                	sd	s1,56(sp)
    80004cb0:	f84a                	sd	s2,48(sp)
    80004cb2:	f44e                	sd	s3,40(sp)
    80004cb4:	f052                	sd	s4,32(sp)
    80004cb6:	ec56                	sd	s5,24(sp)
    80004cb8:	e85a                	sd	s6,16(sp)
    80004cba:	e45e                	sd	s7,8(sp)
    80004cbc:	e062                	sd	s8,0(sp)
    80004cbe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cc0:	00954783          	lbu	a5,9(a0)
    80004cc4:	10078663          	beqz	a5,80004dd0 <filewrite+0x128>
    80004cc8:	892a                	mv	s2,a0
    80004cca:	8aae                	mv	s5,a1
    80004ccc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cce:	411c                	lw	a5,0(a0)
    80004cd0:	4705                	li	a4,1
    80004cd2:	02e78263          	beq	a5,a4,80004cf6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cd6:	470d                	li	a4,3
    80004cd8:	02e78663          	beq	a5,a4,80004d04 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cdc:	4709                	li	a4,2
    80004cde:	0ee79163          	bne	a5,a4,80004dc0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ce2:	0ac05d63          	blez	a2,80004d9c <filewrite+0xf4>
    int i = 0;
    80004ce6:	4981                	li	s3,0
    80004ce8:	6b05                	lui	s6,0x1
    80004cea:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cee:	6b85                	lui	s7,0x1
    80004cf0:	c00b8b9b          	addiw	s7,s7,-1024
    80004cf4:	a861                	j	80004d8c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cf6:	6908                	ld	a0,16(a0)
    80004cf8:	00000097          	auipc	ra,0x0
    80004cfc:	22e080e7          	jalr	558(ra) # 80004f26 <pipewrite>
    80004d00:	8a2a                	mv	s4,a0
    80004d02:	a045                	j	80004da2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d04:	02451783          	lh	a5,36(a0)
    80004d08:	03079693          	slli	a3,a5,0x30
    80004d0c:	92c1                	srli	a3,a3,0x30
    80004d0e:	4725                	li	a4,9
    80004d10:	0cd76263          	bltu	a4,a3,80004dd4 <filewrite+0x12c>
    80004d14:	0792                	slli	a5,a5,0x4
    80004d16:	0001d717          	auipc	a4,0x1d
    80004d1a:	a8270713          	addi	a4,a4,-1406 # 80021798 <devsw>
    80004d1e:	97ba                	add	a5,a5,a4
    80004d20:	679c                	ld	a5,8(a5)
    80004d22:	cbdd                	beqz	a5,80004dd8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d24:	4505                	li	a0,1
    80004d26:	9782                	jalr	a5
    80004d28:	8a2a                	mv	s4,a0
    80004d2a:	a8a5                	j	80004da2 <filewrite+0xfa>
    80004d2c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	8b0080e7          	jalr	-1872(ra) # 800045e0 <begin_op>
      ilock(f->ip);
    80004d38:	01893503          	ld	a0,24(s2)
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	ed2080e7          	jalr	-302(ra) # 80003c0e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d44:	8762                	mv	a4,s8
    80004d46:	02092683          	lw	a3,32(s2)
    80004d4a:	01598633          	add	a2,s3,s5
    80004d4e:	4585                	li	a1,1
    80004d50:	01893503          	ld	a0,24(s2)
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	266080e7          	jalr	614(ra) # 80003fba <writei>
    80004d5c:	84aa                	mv	s1,a0
    80004d5e:	00a05763          	blez	a0,80004d6c <filewrite+0xc4>
        f->off += r;
    80004d62:	02092783          	lw	a5,32(s2)
    80004d66:	9fa9                	addw	a5,a5,a0
    80004d68:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d6c:	01893503          	ld	a0,24(s2)
    80004d70:	fffff097          	auipc	ra,0xfffff
    80004d74:	f60080e7          	jalr	-160(ra) # 80003cd0 <iunlock>
      end_op();
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	8e8080e7          	jalr	-1816(ra) # 80004660 <end_op>

      if(r != n1){
    80004d80:	009c1f63          	bne	s8,s1,80004d9e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d84:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d88:	0149db63          	bge	s3,s4,80004d9e <filewrite+0xf6>
      int n1 = n - i;
    80004d8c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d90:	84be                	mv	s1,a5
    80004d92:	2781                	sext.w	a5,a5
    80004d94:	f8fb5ce3          	bge	s6,a5,80004d2c <filewrite+0x84>
    80004d98:	84de                	mv	s1,s7
    80004d9a:	bf49                	j	80004d2c <filewrite+0x84>
    int i = 0;
    80004d9c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d9e:	013a1f63          	bne	s4,s3,80004dbc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004da2:	8552                	mv	a0,s4
    80004da4:	60a6                	ld	ra,72(sp)
    80004da6:	6406                	ld	s0,64(sp)
    80004da8:	74e2                	ld	s1,56(sp)
    80004daa:	7942                	ld	s2,48(sp)
    80004dac:	79a2                	ld	s3,40(sp)
    80004dae:	7a02                	ld	s4,32(sp)
    80004db0:	6ae2                	ld	s5,24(sp)
    80004db2:	6b42                	ld	s6,16(sp)
    80004db4:	6ba2                	ld	s7,8(sp)
    80004db6:	6c02                	ld	s8,0(sp)
    80004db8:	6161                	addi	sp,sp,80
    80004dba:	8082                	ret
    ret = (i == n ? n : -1);
    80004dbc:	5a7d                	li	s4,-1
    80004dbe:	b7d5                	j	80004da2 <filewrite+0xfa>
    panic("filewrite");
    80004dc0:	00004517          	auipc	a0,0x4
    80004dc4:	ad050513          	addi	a0,a0,-1328 # 80008890 <syscalls+0x278>
    80004dc8:	ffffb097          	auipc	ra,0xffffb
    80004dcc:	776080e7          	jalr	1910(ra) # 8000053e <panic>
    return -1;
    80004dd0:	5a7d                	li	s4,-1
    80004dd2:	bfc1                	j	80004da2 <filewrite+0xfa>
      return -1;
    80004dd4:	5a7d                	li	s4,-1
    80004dd6:	b7f1                	j	80004da2 <filewrite+0xfa>
    80004dd8:	5a7d                	li	s4,-1
    80004dda:	b7e1                	j	80004da2 <filewrite+0xfa>

0000000080004ddc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ddc:	7179                	addi	sp,sp,-48
    80004dde:	f406                	sd	ra,40(sp)
    80004de0:	f022                	sd	s0,32(sp)
    80004de2:	ec26                	sd	s1,24(sp)
    80004de4:	e84a                	sd	s2,16(sp)
    80004de6:	e44e                	sd	s3,8(sp)
    80004de8:	e052                	sd	s4,0(sp)
    80004dea:	1800                	addi	s0,sp,48
    80004dec:	84aa                	mv	s1,a0
    80004dee:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004df0:	0005b023          	sd	zero,0(a1)
    80004df4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004df8:	00000097          	auipc	ra,0x0
    80004dfc:	bf8080e7          	jalr	-1032(ra) # 800049f0 <filealloc>
    80004e00:	e088                	sd	a0,0(s1)
    80004e02:	c551                	beqz	a0,80004e8e <pipealloc+0xb2>
    80004e04:	00000097          	auipc	ra,0x0
    80004e08:	bec080e7          	jalr	-1044(ra) # 800049f0 <filealloc>
    80004e0c:	00aa3023          	sd	a0,0(s4)
    80004e10:	c92d                	beqz	a0,80004e82 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	ce2080e7          	jalr	-798(ra) # 80000af4 <kalloc>
    80004e1a:	892a                	mv	s2,a0
    80004e1c:	c125                	beqz	a0,80004e7c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e1e:	4985                	li	s3,1
    80004e20:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e24:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e28:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e2c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e30:	00004597          	auipc	a1,0x4
    80004e34:	a7058593          	addi	a1,a1,-1424 # 800088a0 <syscalls+0x288>
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	d1c080e7          	jalr	-740(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e40:	609c                	ld	a5,0(s1)
    80004e42:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e46:	609c                	ld	a5,0(s1)
    80004e48:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e4c:	609c                	ld	a5,0(s1)
    80004e4e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e52:	609c                	ld	a5,0(s1)
    80004e54:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e58:	000a3783          	ld	a5,0(s4)
    80004e5c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e60:	000a3783          	ld	a5,0(s4)
    80004e64:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e68:	000a3783          	ld	a5,0(s4)
    80004e6c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e70:	000a3783          	ld	a5,0(s4)
    80004e74:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e78:	4501                	li	a0,0
    80004e7a:	a025                	j	80004ea2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e7c:	6088                	ld	a0,0(s1)
    80004e7e:	e501                	bnez	a0,80004e86 <pipealloc+0xaa>
    80004e80:	a039                	j	80004e8e <pipealloc+0xb2>
    80004e82:	6088                	ld	a0,0(s1)
    80004e84:	c51d                	beqz	a0,80004eb2 <pipealloc+0xd6>
    fileclose(*f0);
    80004e86:	00000097          	auipc	ra,0x0
    80004e8a:	c26080e7          	jalr	-986(ra) # 80004aac <fileclose>
  if(*f1)
    80004e8e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e92:	557d                	li	a0,-1
  if(*f1)
    80004e94:	c799                	beqz	a5,80004ea2 <pipealloc+0xc6>
    fileclose(*f1);
    80004e96:	853e                	mv	a0,a5
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	c14080e7          	jalr	-1004(ra) # 80004aac <fileclose>
  return -1;
    80004ea0:	557d                	li	a0,-1
}
    80004ea2:	70a2                	ld	ra,40(sp)
    80004ea4:	7402                	ld	s0,32(sp)
    80004ea6:	64e2                	ld	s1,24(sp)
    80004ea8:	6942                	ld	s2,16(sp)
    80004eaa:	69a2                	ld	s3,8(sp)
    80004eac:	6a02                	ld	s4,0(sp)
    80004eae:	6145                	addi	sp,sp,48
    80004eb0:	8082                	ret
  return -1;
    80004eb2:	557d                	li	a0,-1
    80004eb4:	b7fd                	j	80004ea2 <pipealloc+0xc6>

0000000080004eb6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eb6:	1101                	addi	sp,sp,-32
    80004eb8:	ec06                	sd	ra,24(sp)
    80004eba:	e822                	sd	s0,16(sp)
    80004ebc:	e426                	sd	s1,8(sp)
    80004ebe:	e04a                	sd	s2,0(sp)
    80004ec0:	1000                	addi	s0,sp,32
    80004ec2:	84aa                	mv	s1,a0
    80004ec4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	d1e080e7          	jalr	-738(ra) # 80000be4 <acquire>
  if(writable){
    80004ece:	02090d63          	beqz	s2,80004f08 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ed2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ed6:	21848513          	addi	a0,s1,536
    80004eda:	ffffe097          	auipc	ra,0xffffe
    80004ede:	808080e7          	jalr	-2040(ra) # 800026e2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ee2:	2204b783          	ld	a5,544(s1)
    80004ee6:	eb95                	bnez	a5,80004f1a <pipeclose+0x64>
    release(&pi->lock);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	dae080e7          	jalr	-594(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	b04080e7          	jalr	-1276(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004efc:	60e2                	ld	ra,24(sp)
    80004efe:	6442                	ld	s0,16(sp)
    80004f00:	64a2                	ld	s1,8(sp)
    80004f02:	6902                	ld	s2,0(sp)
    80004f04:	6105                	addi	sp,sp,32
    80004f06:	8082                	ret
    pi->readopen = 0;
    80004f08:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f0c:	21c48513          	addi	a0,s1,540
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	7d2080e7          	jalr	2002(ra) # 800026e2 <wakeup>
    80004f18:	b7e9                	j	80004ee2 <pipeclose+0x2c>
    release(&pi->lock);
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	d7c080e7          	jalr	-644(ra) # 80000c98 <release>
}
    80004f24:	bfe1                	j	80004efc <pipeclose+0x46>

0000000080004f26 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f26:	7159                	addi	sp,sp,-112
    80004f28:	f486                	sd	ra,104(sp)
    80004f2a:	f0a2                	sd	s0,96(sp)
    80004f2c:	eca6                	sd	s1,88(sp)
    80004f2e:	e8ca                	sd	s2,80(sp)
    80004f30:	e4ce                	sd	s3,72(sp)
    80004f32:	e0d2                	sd	s4,64(sp)
    80004f34:	fc56                	sd	s5,56(sp)
    80004f36:	f85a                	sd	s6,48(sp)
    80004f38:	f45e                	sd	s7,40(sp)
    80004f3a:	f062                	sd	s8,32(sp)
    80004f3c:	ec66                	sd	s9,24(sp)
    80004f3e:	1880                	addi	s0,sp,112
    80004f40:	84aa                	mv	s1,a0
    80004f42:	8aae                	mv	s5,a1
    80004f44:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	ddc080e7          	jalr	-548(ra) # 80001d22 <myproc>
    80004f4e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f50:	8526                	mv	a0,s1
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c92080e7          	jalr	-878(ra) # 80000be4 <acquire>
  while(i < n){
    80004f5a:	0d405163          	blez	s4,8000501c <pipewrite+0xf6>
    80004f5e:	8ba6                	mv	s7,s1
  int i = 0;
    80004f60:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f62:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f64:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f68:	21c48c13          	addi	s8,s1,540
    80004f6c:	a08d                	j	80004fce <pipewrite+0xa8>
      release(&pi->lock);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	d28080e7          	jalr	-728(ra) # 80000c98 <release>
      return -1;
    80004f78:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f7a:	854a                	mv	a0,s2
    80004f7c:	70a6                	ld	ra,104(sp)
    80004f7e:	7406                	ld	s0,96(sp)
    80004f80:	64e6                	ld	s1,88(sp)
    80004f82:	6946                	ld	s2,80(sp)
    80004f84:	69a6                	ld	s3,72(sp)
    80004f86:	6a06                	ld	s4,64(sp)
    80004f88:	7ae2                	ld	s5,56(sp)
    80004f8a:	7b42                	ld	s6,48(sp)
    80004f8c:	7ba2                	ld	s7,40(sp)
    80004f8e:	7c02                	ld	s8,32(sp)
    80004f90:	6ce2                	ld	s9,24(sp)
    80004f92:	6165                	addi	sp,sp,112
    80004f94:	8082                	ret
      wakeup(&pi->nread);
    80004f96:	8566                	mv	a0,s9
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	74a080e7          	jalr	1866(ra) # 800026e2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fa0:	85de                	mv	a1,s7
    80004fa2:	8562                	mv	a0,s8
    80004fa4:	ffffd097          	auipc	ra,0xffffd
    80004fa8:	58c080e7          	jalr	1420(ra) # 80002530 <sleep>
    80004fac:	a839                	j	80004fca <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fae:	21c4a783          	lw	a5,540(s1)
    80004fb2:	0017871b          	addiw	a4,a5,1
    80004fb6:	20e4ae23          	sw	a4,540(s1)
    80004fba:	1ff7f793          	andi	a5,a5,511
    80004fbe:	97a6                	add	a5,a5,s1
    80004fc0:	f9f44703          	lbu	a4,-97(s0)
    80004fc4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fc8:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fca:	03495d63          	bge	s2,s4,80005004 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fce:	2204a783          	lw	a5,544(s1)
    80004fd2:	dfd1                	beqz	a5,80004f6e <pipewrite+0x48>
    80004fd4:	0289a783          	lw	a5,40(s3)
    80004fd8:	fbd9                	bnez	a5,80004f6e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fda:	2184a783          	lw	a5,536(s1)
    80004fde:	21c4a703          	lw	a4,540(s1)
    80004fe2:	2007879b          	addiw	a5,a5,512
    80004fe6:	faf708e3          	beq	a4,a5,80004f96 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fea:	4685                	li	a3,1
    80004fec:	01590633          	add	a2,s2,s5
    80004ff0:	f9f40593          	addi	a1,s0,-97
    80004ff4:	0509b503          	ld	a0,80(s3)
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	706080e7          	jalr	1798(ra) # 800016fe <copyin>
    80005000:	fb6517e3          	bne	a0,s6,80004fae <pipewrite+0x88>
  wakeup(&pi->nread);
    80005004:	21848513          	addi	a0,s1,536
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	6da080e7          	jalr	1754(ra) # 800026e2 <wakeup>
  release(&pi->lock);
    80005010:	8526                	mv	a0,s1
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
  return i;
    8000501a:	b785                	j	80004f7a <pipewrite+0x54>
  int i = 0;
    8000501c:	4901                	li	s2,0
    8000501e:	b7dd                	j	80005004 <pipewrite+0xde>

0000000080005020 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005020:	715d                	addi	sp,sp,-80
    80005022:	e486                	sd	ra,72(sp)
    80005024:	e0a2                	sd	s0,64(sp)
    80005026:	fc26                	sd	s1,56(sp)
    80005028:	f84a                	sd	s2,48(sp)
    8000502a:	f44e                	sd	s3,40(sp)
    8000502c:	f052                	sd	s4,32(sp)
    8000502e:	ec56                	sd	s5,24(sp)
    80005030:	e85a                	sd	s6,16(sp)
    80005032:	0880                	addi	s0,sp,80
    80005034:	84aa                	mv	s1,a0
    80005036:	892e                	mv	s2,a1
    80005038:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	ce8080e7          	jalr	-792(ra) # 80001d22 <myproc>
    80005042:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005044:	8b26                	mv	s6,s1
    80005046:	8526                	mv	a0,s1
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	b9c080e7          	jalr	-1124(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005050:	2184a703          	lw	a4,536(s1)
    80005054:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005058:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505c:	02f71463          	bne	a4,a5,80005084 <piperead+0x64>
    80005060:	2244a783          	lw	a5,548(s1)
    80005064:	c385                	beqz	a5,80005084 <piperead+0x64>
    if(pr->killed){
    80005066:	028a2783          	lw	a5,40(s4)
    8000506a:	ebc1                	bnez	a5,800050fa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000506c:	85da                	mv	a1,s6
    8000506e:	854e                	mv	a0,s3
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	4c0080e7          	jalr	1216(ra) # 80002530 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005078:	2184a703          	lw	a4,536(s1)
    8000507c:	21c4a783          	lw	a5,540(s1)
    80005080:	fef700e3          	beq	a4,a5,80005060 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005084:	09505263          	blez	s5,80005108 <piperead+0xe8>
    80005088:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000508a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000508c:	2184a783          	lw	a5,536(s1)
    80005090:	21c4a703          	lw	a4,540(s1)
    80005094:	02f70d63          	beq	a4,a5,800050ce <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005098:	0017871b          	addiw	a4,a5,1
    8000509c:	20e4ac23          	sw	a4,536(s1)
    800050a0:	1ff7f793          	andi	a5,a5,511
    800050a4:	97a6                	add	a5,a5,s1
    800050a6:	0187c783          	lbu	a5,24(a5)
    800050aa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050ae:	4685                	li	a3,1
    800050b0:	fbf40613          	addi	a2,s0,-65
    800050b4:	85ca                	mv	a1,s2
    800050b6:	050a3503          	ld	a0,80(s4)
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	5b8080e7          	jalr	1464(ra) # 80001672 <copyout>
    800050c2:	01650663          	beq	a0,s6,800050ce <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050c6:	2985                	addiw	s3,s3,1
    800050c8:	0905                	addi	s2,s2,1
    800050ca:	fd3a91e3          	bne	s5,s3,8000508c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050ce:	21c48513          	addi	a0,s1,540
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	610080e7          	jalr	1552(ra) # 800026e2 <wakeup>
  release(&pi->lock);
    800050da:	8526                	mv	a0,s1
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	bbc080e7          	jalr	-1092(ra) # 80000c98 <release>
  return i;
}
    800050e4:	854e                	mv	a0,s3
    800050e6:	60a6                	ld	ra,72(sp)
    800050e8:	6406                	ld	s0,64(sp)
    800050ea:	74e2                	ld	s1,56(sp)
    800050ec:	7942                	ld	s2,48(sp)
    800050ee:	79a2                	ld	s3,40(sp)
    800050f0:	7a02                	ld	s4,32(sp)
    800050f2:	6ae2                	ld	s5,24(sp)
    800050f4:	6b42                	ld	s6,16(sp)
    800050f6:	6161                	addi	sp,sp,80
    800050f8:	8082                	ret
      release(&pi->lock);
    800050fa:	8526                	mv	a0,s1
    800050fc:	ffffc097          	auipc	ra,0xffffc
    80005100:	b9c080e7          	jalr	-1124(ra) # 80000c98 <release>
      return -1;
    80005104:	59fd                	li	s3,-1
    80005106:	bff9                	j	800050e4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005108:	4981                	li	s3,0
    8000510a:	b7d1                	j	800050ce <piperead+0xae>

000000008000510c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000510c:	df010113          	addi	sp,sp,-528
    80005110:	20113423          	sd	ra,520(sp)
    80005114:	20813023          	sd	s0,512(sp)
    80005118:	ffa6                	sd	s1,504(sp)
    8000511a:	fbca                	sd	s2,496(sp)
    8000511c:	f7ce                	sd	s3,488(sp)
    8000511e:	f3d2                	sd	s4,480(sp)
    80005120:	efd6                	sd	s5,472(sp)
    80005122:	ebda                	sd	s6,464(sp)
    80005124:	e7de                	sd	s7,456(sp)
    80005126:	e3e2                	sd	s8,448(sp)
    80005128:	ff66                	sd	s9,440(sp)
    8000512a:	fb6a                	sd	s10,432(sp)
    8000512c:	f76e                	sd	s11,424(sp)
    8000512e:	0c00                	addi	s0,sp,528
    80005130:	84aa                	mv	s1,a0
    80005132:	dea43c23          	sd	a0,-520(s0)
    80005136:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	be8080e7          	jalr	-1048(ra) # 80001d22 <myproc>
    80005142:	892a                	mv	s2,a0

  begin_op();
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	49c080e7          	jalr	1180(ra) # 800045e0 <begin_op>

  if((ip = namei(path)) == 0){
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	276080e7          	jalr	630(ra) # 800043c4 <namei>
    80005156:	c92d                	beqz	a0,800051c8 <exec+0xbc>
    80005158:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	ab4080e7          	jalr	-1356(ra) # 80003c0e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005162:	04000713          	li	a4,64
    80005166:	4681                	li	a3,0
    80005168:	e5040613          	addi	a2,s0,-432
    8000516c:	4581                	li	a1,0
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	d52080e7          	jalr	-686(ra) # 80003ec2 <readi>
    80005178:	04000793          	li	a5,64
    8000517c:	00f51a63          	bne	a0,a5,80005190 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005180:	e5042703          	lw	a4,-432(s0)
    80005184:	464c47b7          	lui	a5,0x464c4
    80005188:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000518c:	04f70463          	beq	a4,a5,800051d4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	cde080e7          	jalr	-802(ra) # 80003e70 <iunlockput>
    end_op();
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	4c6080e7          	jalr	1222(ra) # 80004660 <end_op>
  }
  return -1;
    800051a2:	557d                	li	a0,-1
}
    800051a4:	20813083          	ld	ra,520(sp)
    800051a8:	20013403          	ld	s0,512(sp)
    800051ac:	74fe                	ld	s1,504(sp)
    800051ae:	795e                	ld	s2,496(sp)
    800051b0:	79be                	ld	s3,488(sp)
    800051b2:	7a1e                	ld	s4,480(sp)
    800051b4:	6afe                	ld	s5,472(sp)
    800051b6:	6b5e                	ld	s6,464(sp)
    800051b8:	6bbe                	ld	s7,456(sp)
    800051ba:	6c1e                	ld	s8,448(sp)
    800051bc:	7cfa                	ld	s9,440(sp)
    800051be:	7d5a                	ld	s10,432(sp)
    800051c0:	7dba                	ld	s11,424(sp)
    800051c2:	21010113          	addi	sp,sp,528
    800051c6:	8082                	ret
    end_op();
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	498080e7          	jalr	1176(ra) # 80004660 <end_op>
    return -1;
    800051d0:	557d                	li	a0,-1
    800051d2:	bfc9                	j	800051a4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051d4:	854a                	mv	a0,s2
    800051d6:	ffffd097          	auipc	ra,0xffffd
    800051da:	c0c080e7          	jalr	-1012(ra) # 80001de2 <proc_pagetable>
    800051de:	8baa                	mv	s7,a0
    800051e0:	d945                	beqz	a0,80005190 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e2:	e7042983          	lw	s3,-400(s0)
    800051e6:	e8845783          	lhu	a5,-376(s0)
    800051ea:	c7ad                	beqz	a5,80005254 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ec:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ee:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051f0:	6c85                	lui	s9,0x1
    800051f2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051f6:	def43823          	sd	a5,-528(s0)
    800051fa:	a42d                	j	80005424 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051fc:	00003517          	auipc	a0,0x3
    80005200:	6ac50513          	addi	a0,a0,1708 # 800088a8 <syscalls+0x290>
    80005204:	ffffb097          	auipc	ra,0xffffb
    80005208:	33a080e7          	jalr	826(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000520c:	8756                	mv	a4,s5
    8000520e:	012d86bb          	addw	a3,s11,s2
    80005212:	4581                	li	a1,0
    80005214:	8526                	mv	a0,s1
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	cac080e7          	jalr	-852(ra) # 80003ec2 <readi>
    8000521e:	2501                	sext.w	a0,a0
    80005220:	1aaa9963          	bne	s5,a0,800053d2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005224:	6785                	lui	a5,0x1
    80005226:	0127893b          	addw	s2,a5,s2
    8000522a:	77fd                	lui	a5,0xfffff
    8000522c:	01478a3b          	addw	s4,a5,s4
    80005230:	1f897163          	bgeu	s2,s8,80005412 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005234:	02091593          	slli	a1,s2,0x20
    80005238:	9181                	srli	a1,a1,0x20
    8000523a:	95ea                	add	a1,a1,s10
    8000523c:	855e                	mv	a0,s7
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	e30080e7          	jalr	-464(ra) # 8000106e <walkaddr>
    80005246:	862a                	mv	a2,a0
    if(pa == 0)
    80005248:	d955                	beqz	a0,800051fc <exec+0xf0>
      n = PGSIZE;
    8000524a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000524c:	fd9a70e3          	bgeu	s4,s9,8000520c <exec+0x100>
      n = sz - i;
    80005250:	8ad2                	mv	s5,s4
    80005252:	bf6d                	j	8000520c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005254:	4901                	li	s2,0
  iunlockput(ip);
    80005256:	8526                	mv	a0,s1
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	c18080e7          	jalr	-1000(ra) # 80003e70 <iunlockput>
  end_op();
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	400080e7          	jalr	1024(ra) # 80004660 <end_op>
  p = myproc();
    80005268:	ffffd097          	auipc	ra,0xffffd
    8000526c:	aba080e7          	jalr	-1350(ra) # 80001d22 <myproc>
    80005270:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005272:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005276:	6785                	lui	a5,0x1
    80005278:	17fd                	addi	a5,a5,-1
    8000527a:	993e                	add	s2,s2,a5
    8000527c:	757d                	lui	a0,0xfffff
    8000527e:	00a977b3          	and	a5,s2,a0
    80005282:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005286:	6609                	lui	a2,0x2
    80005288:	963e                	add	a2,a2,a5
    8000528a:	85be                	mv	a1,a5
    8000528c:	855e                	mv	a0,s7
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	194080e7          	jalr	404(ra) # 80001422 <uvmalloc>
    80005296:	8b2a                	mv	s6,a0
  ip = 0;
    80005298:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000529a:	12050c63          	beqz	a0,800053d2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000529e:	75f9                	lui	a1,0xffffe
    800052a0:	95aa                	add	a1,a1,a0
    800052a2:	855e                	mv	a0,s7
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	39c080e7          	jalr	924(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052ac:	7c7d                	lui	s8,0xfffff
    800052ae:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052b0:	e0043783          	ld	a5,-512(s0)
    800052b4:	6388                	ld	a0,0(a5)
    800052b6:	c535                	beqz	a0,80005322 <exec+0x216>
    800052b8:	e9040993          	addi	s3,s0,-368
    800052bc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052c0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052c2:	ffffc097          	auipc	ra,0xffffc
    800052c6:	ba2080e7          	jalr	-1118(ra) # 80000e64 <strlen>
    800052ca:	2505                	addiw	a0,a0,1
    800052cc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052d0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052d4:	13896363          	bltu	s2,s8,800053fa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052d8:	e0043d83          	ld	s11,-512(s0)
    800052dc:	000dba03          	ld	s4,0(s11)
    800052e0:	8552                	mv	a0,s4
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	b82080e7          	jalr	-1150(ra) # 80000e64 <strlen>
    800052ea:	0015069b          	addiw	a3,a0,1
    800052ee:	8652                	mv	a2,s4
    800052f0:	85ca                	mv	a1,s2
    800052f2:	855e                	mv	a0,s7
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	37e080e7          	jalr	894(ra) # 80001672 <copyout>
    800052fc:	10054363          	bltz	a0,80005402 <exec+0x2f6>
    ustack[argc] = sp;
    80005300:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005304:	0485                	addi	s1,s1,1
    80005306:	008d8793          	addi	a5,s11,8
    8000530a:	e0f43023          	sd	a5,-512(s0)
    8000530e:	008db503          	ld	a0,8(s11)
    80005312:	c911                	beqz	a0,80005326 <exec+0x21a>
    if(argc >= MAXARG)
    80005314:	09a1                	addi	s3,s3,8
    80005316:	fb3c96e3          	bne	s9,s3,800052c2 <exec+0x1b6>
  sz = sz1;
    8000531a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000531e:	4481                	li	s1,0
    80005320:	a84d                	j	800053d2 <exec+0x2c6>
  sp = sz;
    80005322:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005324:	4481                	li	s1,0
  ustack[argc] = 0;
    80005326:	00349793          	slli	a5,s1,0x3
    8000532a:	f9040713          	addi	a4,s0,-112
    8000532e:	97ba                	add	a5,a5,a4
    80005330:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005334:	00148693          	addi	a3,s1,1
    80005338:	068e                	slli	a3,a3,0x3
    8000533a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000533e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005342:	01897663          	bgeu	s2,s8,8000534e <exec+0x242>
  sz = sz1;
    80005346:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000534a:	4481                	li	s1,0
    8000534c:	a059                	j	800053d2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000534e:	e9040613          	addi	a2,s0,-368
    80005352:	85ca                	mv	a1,s2
    80005354:	855e                	mv	a0,s7
    80005356:	ffffc097          	auipc	ra,0xffffc
    8000535a:	31c080e7          	jalr	796(ra) # 80001672 <copyout>
    8000535e:	0a054663          	bltz	a0,8000540a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005362:	058ab783          	ld	a5,88(s5)
    80005366:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000536a:	df843783          	ld	a5,-520(s0)
    8000536e:	0007c703          	lbu	a4,0(a5)
    80005372:	cf11                	beqz	a4,8000538e <exec+0x282>
    80005374:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005376:	02f00693          	li	a3,47
    8000537a:	a039                	j	80005388 <exec+0x27c>
      last = s+1;
    8000537c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005380:	0785                	addi	a5,a5,1
    80005382:	fff7c703          	lbu	a4,-1(a5)
    80005386:	c701                	beqz	a4,8000538e <exec+0x282>
    if(*s == '/')
    80005388:	fed71ce3          	bne	a4,a3,80005380 <exec+0x274>
    8000538c:	bfc5                	j	8000537c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000538e:	4641                	li	a2,16
    80005390:	df843583          	ld	a1,-520(s0)
    80005394:	158a8513          	addi	a0,s5,344
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	a9a080e7          	jalr	-1382(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053a0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800053a4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800053a8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053ac:	058ab783          	ld	a5,88(s5)
    800053b0:	e6843703          	ld	a4,-408(s0)
    800053b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053b6:	058ab783          	ld	a5,88(s5)
    800053ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053be:	85ea                	mv	a1,s10
    800053c0:	ffffd097          	auipc	ra,0xffffd
    800053c4:	abe080e7          	jalr	-1346(ra) # 80001e7e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053c8:	0004851b          	sext.w	a0,s1
    800053cc:	bbe1                	j	800051a4 <exec+0x98>
    800053ce:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053d2:	e0843583          	ld	a1,-504(s0)
    800053d6:	855e                	mv	a0,s7
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	aa6080e7          	jalr	-1370(ra) # 80001e7e <proc_freepagetable>
  if(ip){
    800053e0:	da0498e3          	bnez	s1,80005190 <exec+0x84>
  return -1;
    800053e4:	557d                	li	a0,-1
    800053e6:	bb7d                	j	800051a4 <exec+0x98>
    800053e8:	e1243423          	sd	s2,-504(s0)
    800053ec:	b7dd                	j	800053d2 <exec+0x2c6>
    800053ee:	e1243423          	sd	s2,-504(s0)
    800053f2:	b7c5                	j	800053d2 <exec+0x2c6>
    800053f4:	e1243423          	sd	s2,-504(s0)
    800053f8:	bfe9                	j	800053d2 <exec+0x2c6>
  sz = sz1;
    800053fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053fe:	4481                	li	s1,0
    80005400:	bfc9                	j	800053d2 <exec+0x2c6>
  sz = sz1;
    80005402:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005406:	4481                	li	s1,0
    80005408:	b7e9                	j	800053d2 <exec+0x2c6>
  sz = sz1;
    8000540a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000540e:	4481                	li	s1,0
    80005410:	b7c9                	j	800053d2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005412:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005416:	2b05                	addiw	s6,s6,1
    80005418:	0389899b          	addiw	s3,s3,56
    8000541c:	e8845783          	lhu	a5,-376(s0)
    80005420:	e2fb5be3          	bge	s6,a5,80005256 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005424:	2981                	sext.w	s3,s3
    80005426:	03800713          	li	a4,56
    8000542a:	86ce                	mv	a3,s3
    8000542c:	e1840613          	addi	a2,s0,-488
    80005430:	4581                	li	a1,0
    80005432:	8526                	mv	a0,s1
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	a8e080e7          	jalr	-1394(ra) # 80003ec2 <readi>
    8000543c:	03800793          	li	a5,56
    80005440:	f8f517e3          	bne	a0,a5,800053ce <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005444:	e1842783          	lw	a5,-488(s0)
    80005448:	4705                	li	a4,1
    8000544a:	fce796e3          	bne	a5,a4,80005416 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000544e:	e4043603          	ld	a2,-448(s0)
    80005452:	e3843783          	ld	a5,-456(s0)
    80005456:	f8f669e3          	bltu	a2,a5,800053e8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000545a:	e2843783          	ld	a5,-472(s0)
    8000545e:	963e                	add	a2,a2,a5
    80005460:	f8f667e3          	bltu	a2,a5,800053ee <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005464:	85ca                	mv	a1,s2
    80005466:	855e                	mv	a0,s7
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	fba080e7          	jalr	-70(ra) # 80001422 <uvmalloc>
    80005470:	e0a43423          	sd	a0,-504(s0)
    80005474:	d141                	beqz	a0,800053f4 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005476:	e2843d03          	ld	s10,-472(s0)
    8000547a:	df043783          	ld	a5,-528(s0)
    8000547e:	00fd77b3          	and	a5,s10,a5
    80005482:	fba1                	bnez	a5,800053d2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005484:	e2042d83          	lw	s11,-480(s0)
    80005488:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000548c:	f80c03e3          	beqz	s8,80005412 <exec+0x306>
    80005490:	8a62                	mv	s4,s8
    80005492:	4901                	li	s2,0
    80005494:	b345                	j	80005234 <exec+0x128>

0000000080005496 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005496:	7179                	addi	sp,sp,-48
    80005498:	f406                	sd	ra,40(sp)
    8000549a:	f022                	sd	s0,32(sp)
    8000549c:	ec26                	sd	s1,24(sp)
    8000549e:	e84a                	sd	s2,16(sp)
    800054a0:	1800                	addi	s0,sp,48
    800054a2:	892e                	mv	s2,a1
    800054a4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054a6:	fdc40593          	addi	a1,s0,-36
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	ba8080e7          	jalr	-1112(ra) # 80003052 <argint>
    800054b2:	04054063          	bltz	a0,800054f2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054b6:	fdc42703          	lw	a4,-36(s0)
    800054ba:	47bd                	li	a5,15
    800054bc:	02e7ed63          	bltu	a5,a4,800054f6 <argfd+0x60>
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	862080e7          	jalr	-1950(ra) # 80001d22 <myproc>
    800054c8:	fdc42703          	lw	a4,-36(s0)
    800054cc:	01a70793          	addi	a5,a4,26
    800054d0:	078e                	slli	a5,a5,0x3
    800054d2:	953e                	add	a0,a0,a5
    800054d4:	611c                	ld	a5,0(a0)
    800054d6:	c395                	beqz	a5,800054fa <argfd+0x64>
    return -1;
  if(pfd)
    800054d8:	00090463          	beqz	s2,800054e0 <argfd+0x4a>
    *pfd = fd;
    800054dc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054e0:	4501                	li	a0,0
  if(pf)
    800054e2:	c091                	beqz	s1,800054e6 <argfd+0x50>
    *pf = f;
    800054e4:	e09c                	sd	a5,0(s1)
}
    800054e6:	70a2                	ld	ra,40(sp)
    800054e8:	7402                	ld	s0,32(sp)
    800054ea:	64e2                	ld	s1,24(sp)
    800054ec:	6942                	ld	s2,16(sp)
    800054ee:	6145                	addi	sp,sp,48
    800054f0:	8082                	ret
    return -1;
    800054f2:	557d                	li	a0,-1
    800054f4:	bfcd                	j	800054e6 <argfd+0x50>
    return -1;
    800054f6:	557d                	li	a0,-1
    800054f8:	b7fd                	j	800054e6 <argfd+0x50>
    800054fa:	557d                	li	a0,-1
    800054fc:	b7ed                	j	800054e6 <argfd+0x50>

00000000800054fe <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054fe:	1101                	addi	sp,sp,-32
    80005500:	ec06                	sd	ra,24(sp)
    80005502:	e822                	sd	s0,16(sp)
    80005504:	e426                	sd	s1,8(sp)
    80005506:	1000                	addi	s0,sp,32
    80005508:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000550a:	ffffd097          	auipc	ra,0xffffd
    8000550e:	818080e7          	jalr	-2024(ra) # 80001d22 <myproc>
    80005512:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005514:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005518:	4501                	li	a0,0
    8000551a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000551c:	6398                	ld	a4,0(a5)
    8000551e:	cb19                	beqz	a4,80005534 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005520:	2505                	addiw	a0,a0,1
    80005522:	07a1                	addi	a5,a5,8
    80005524:	fed51ce3          	bne	a0,a3,8000551c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005528:	557d                	li	a0,-1
}
    8000552a:	60e2                	ld	ra,24(sp)
    8000552c:	6442                	ld	s0,16(sp)
    8000552e:	64a2                	ld	s1,8(sp)
    80005530:	6105                	addi	sp,sp,32
    80005532:	8082                	ret
      p->ofile[fd] = f;
    80005534:	01a50793          	addi	a5,a0,26
    80005538:	078e                	slli	a5,a5,0x3
    8000553a:	963e                	add	a2,a2,a5
    8000553c:	e204                	sd	s1,0(a2)
      return fd;
    8000553e:	b7f5                	j	8000552a <fdalloc+0x2c>

0000000080005540 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005540:	715d                	addi	sp,sp,-80
    80005542:	e486                	sd	ra,72(sp)
    80005544:	e0a2                	sd	s0,64(sp)
    80005546:	fc26                	sd	s1,56(sp)
    80005548:	f84a                	sd	s2,48(sp)
    8000554a:	f44e                	sd	s3,40(sp)
    8000554c:	f052                	sd	s4,32(sp)
    8000554e:	ec56                	sd	s5,24(sp)
    80005550:	0880                	addi	s0,sp,80
    80005552:	89ae                	mv	s3,a1
    80005554:	8ab2                	mv	s5,a2
    80005556:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	e86080e7          	jalr	-378(ra) # 800043e2 <nameiparent>
    80005564:	892a                	mv	s2,a0
    80005566:	12050f63          	beqz	a0,800056a4 <create+0x164>
    return 0;

  ilock(dp);
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	6a4080e7          	jalr	1700(ra) # 80003c0e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005572:	4601                	li	a2,0
    80005574:	fb040593          	addi	a1,s0,-80
    80005578:	854a                	mv	a0,s2
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	b78080e7          	jalr	-1160(ra) # 800040f2 <dirlookup>
    80005582:	84aa                	mv	s1,a0
    80005584:	c921                	beqz	a0,800055d4 <create+0x94>
    iunlockput(dp);
    80005586:	854a                	mv	a0,s2
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	8e8080e7          	jalr	-1816(ra) # 80003e70 <iunlockput>
    ilock(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	67c080e7          	jalr	1660(ra) # 80003c0e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000559a:	2981                	sext.w	s3,s3
    8000559c:	4789                	li	a5,2
    8000559e:	02f99463          	bne	s3,a5,800055c6 <create+0x86>
    800055a2:	0444d783          	lhu	a5,68(s1)
    800055a6:	37f9                	addiw	a5,a5,-2
    800055a8:	17c2                	slli	a5,a5,0x30
    800055aa:	93c1                	srli	a5,a5,0x30
    800055ac:	4705                	li	a4,1
    800055ae:	00f76c63          	bltu	a4,a5,800055c6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055b2:	8526                	mv	a0,s1
    800055b4:	60a6                	ld	ra,72(sp)
    800055b6:	6406                	ld	s0,64(sp)
    800055b8:	74e2                	ld	s1,56(sp)
    800055ba:	7942                	ld	s2,48(sp)
    800055bc:	79a2                	ld	s3,40(sp)
    800055be:	7a02                	ld	s4,32(sp)
    800055c0:	6ae2                	ld	s5,24(sp)
    800055c2:	6161                	addi	sp,sp,80
    800055c4:	8082                	ret
    iunlockput(ip);
    800055c6:	8526                	mv	a0,s1
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	8a8080e7          	jalr	-1880(ra) # 80003e70 <iunlockput>
    return 0;
    800055d0:	4481                	li	s1,0
    800055d2:	b7c5                	j	800055b2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055d4:	85ce                	mv	a1,s3
    800055d6:	00092503          	lw	a0,0(s2)
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	49c080e7          	jalr	1180(ra) # 80003a76 <ialloc>
    800055e2:	84aa                	mv	s1,a0
    800055e4:	c529                	beqz	a0,8000562e <create+0xee>
  ilock(ip);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	628080e7          	jalr	1576(ra) # 80003c0e <ilock>
  ip->major = major;
    800055ee:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055f2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055f6:	4785                	li	a5,1
    800055f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	546080e7          	jalr	1350(ra) # 80003b44 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005606:	2981                	sext.w	s3,s3
    80005608:	4785                	li	a5,1
    8000560a:	02f98a63          	beq	s3,a5,8000563e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000560e:	40d0                	lw	a2,4(s1)
    80005610:	fb040593          	addi	a1,s0,-80
    80005614:	854a                	mv	a0,s2
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	cec080e7          	jalr	-788(ra) # 80004302 <dirlink>
    8000561e:	06054b63          	bltz	a0,80005694 <create+0x154>
  iunlockput(dp);
    80005622:	854a                	mv	a0,s2
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	84c080e7          	jalr	-1972(ra) # 80003e70 <iunlockput>
  return ip;
    8000562c:	b759                	j	800055b2 <create+0x72>
    panic("create: ialloc");
    8000562e:	00003517          	auipc	a0,0x3
    80005632:	29a50513          	addi	a0,a0,666 # 800088c8 <syscalls+0x2b0>
    80005636:	ffffb097          	auipc	ra,0xffffb
    8000563a:	f08080e7          	jalr	-248(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000563e:	04a95783          	lhu	a5,74(s2)
    80005642:	2785                	addiw	a5,a5,1
    80005644:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005648:	854a                	mv	a0,s2
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	4fa080e7          	jalr	1274(ra) # 80003b44 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005652:	40d0                	lw	a2,4(s1)
    80005654:	00003597          	auipc	a1,0x3
    80005658:	28458593          	addi	a1,a1,644 # 800088d8 <syscalls+0x2c0>
    8000565c:	8526                	mv	a0,s1
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	ca4080e7          	jalr	-860(ra) # 80004302 <dirlink>
    80005666:	00054f63          	bltz	a0,80005684 <create+0x144>
    8000566a:	00492603          	lw	a2,4(s2)
    8000566e:	00003597          	auipc	a1,0x3
    80005672:	27258593          	addi	a1,a1,626 # 800088e0 <syscalls+0x2c8>
    80005676:	8526                	mv	a0,s1
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	c8a080e7          	jalr	-886(ra) # 80004302 <dirlink>
    80005680:	f80557e3          	bgez	a0,8000560e <create+0xce>
      panic("create dots");
    80005684:	00003517          	auipc	a0,0x3
    80005688:	26450513          	addi	a0,a0,612 # 800088e8 <syscalls+0x2d0>
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005694:	00003517          	auipc	a0,0x3
    80005698:	26450513          	addi	a0,a0,612 # 800088f8 <syscalls+0x2e0>
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>
    return 0;
    800056a4:	84aa                	mv	s1,a0
    800056a6:	b731                	j	800055b2 <create+0x72>

00000000800056a8 <sys_dup>:
{
    800056a8:	7179                	addi	sp,sp,-48
    800056aa:	f406                	sd	ra,40(sp)
    800056ac:	f022                	sd	s0,32(sp)
    800056ae:	ec26                	sd	s1,24(sp)
    800056b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056b2:	fd840613          	addi	a2,s0,-40
    800056b6:	4581                	li	a1,0
    800056b8:	4501                	li	a0,0
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	ddc080e7          	jalr	-548(ra) # 80005496 <argfd>
    return -1;
    800056c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056c4:	02054363          	bltz	a0,800056ea <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056c8:	fd843503          	ld	a0,-40(s0)
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	e32080e7          	jalr	-462(ra) # 800054fe <fdalloc>
    800056d4:	84aa                	mv	s1,a0
    return -1;
    800056d6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056d8:	00054963          	bltz	a0,800056ea <sys_dup+0x42>
  filedup(f);
    800056dc:	fd843503          	ld	a0,-40(s0)
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	37a080e7          	jalr	890(ra) # 80004a5a <filedup>
  return fd;
    800056e8:	87a6                	mv	a5,s1
}
    800056ea:	853e                	mv	a0,a5
    800056ec:	70a2                	ld	ra,40(sp)
    800056ee:	7402                	ld	s0,32(sp)
    800056f0:	64e2                	ld	s1,24(sp)
    800056f2:	6145                	addi	sp,sp,48
    800056f4:	8082                	ret

00000000800056f6 <sys_read>:
{
    800056f6:	7179                	addi	sp,sp,-48
    800056f8:	f406                	sd	ra,40(sp)
    800056fa:	f022                	sd	s0,32(sp)
    800056fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056fe:	fe840613          	addi	a2,s0,-24
    80005702:	4581                	li	a1,0
    80005704:	4501                	li	a0,0
    80005706:	00000097          	auipc	ra,0x0
    8000570a:	d90080e7          	jalr	-624(ra) # 80005496 <argfd>
    return -1;
    8000570e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005710:	04054163          	bltz	a0,80005752 <sys_read+0x5c>
    80005714:	fe440593          	addi	a1,s0,-28
    80005718:	4509                	li	a0,2
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	938080e7          	jalr	-1736(ra) # 80003052 <argint>
    return -1;
    80005722:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005724:	02054763          	bltz	a0,80005752 <sys_read+0x5c>
    80005728:	fd840593          	addi	a1,s0,-40
    8000572c:	4505                	li	a0,1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	946080e7          	jalr	-1722(ra) # 80003074 <argaddr>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005738:	00054d63          	bltz	a0,80005752 <sys_read+0x5c>
  return fileread(f, p, n);
    8000573c:	fe442603          	lw	a2,-28(s0)
    80005740:	fd843583          	ld	a1,-40(s0)
    80005744:	fe843503          	ld	a0,-24(s0)
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	49e080e7          	jalr	1182(ra) # 80004be6 <fileread>
    80005750:	87aa                	mv	a5,a0
}
    80005752:	853e                	mv	a0,a5
    80005754:	70a2                	ld	ra,40(sp)
    80005756:	7402                	ld	s0,32(sp)
    80005758:	6145                	addi	sp,sp,48
    8000575a:	8082                	ret

000000008000575c <sys_write>:
{
    8000575c:	7179                	addi	sp,sp,-48
    8000575e:	f406                	sd	ra,40(sp)
    80005760:	f022                	sd	s0,32(sp)
    80005762:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005764:	fe840613          	addi	a2,s0,-24
    80005768:	4581                	li	a1,0
    8000576a:	4501                	li	a0,0
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	d2a080e7          	jalr	-726(ra) # 80005496 <argfd>
    return -1;
    80005774:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005776:	04054163          	bltz	a0,800057b8 <sys_write+0x5c>
    8000577a:	fe440593          	addi	a1,s0,-28
    8000577e:	4509                	li	a0,2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	8d2080e7          	jalr	-1838(ra) # 80003052 <argint>
    return -1;
    80005788:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000578a:	02054763          	bltz	a0,800057b8 <sys_write+0x5c>
    8000578e:	fd840593          	addi	a1,s0,-40
    80005792:	4505                	li	a0,1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	8e0080e7          	jalr	-1824(ra) # 80003074 <argaddr>
    return -1;
    8000579c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000579e:	00054d63          	bltz	a0,800057b8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800057a2:	fe442603          	lw	a2,-28(s0)
    800057a6:	fd843583          	ld	a1,-40(s0)
    800057aa:	fe843503          	ld	a0,-24(s0)
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	4fa080e7          	jalr	1274(ra) # 80004ca8 <filewrite>
    800057b6:	87aa                	mv	a5,a0
}
    800057b8:	853e                	mv	a0,a5
    800057ba:	70a2                	ld	ra,40(sp)
    800057bc:	7402                	ld	s0,32(sp)
    800057be:	6145                	addi	sp,sp,48
    800057c0:	8082                	ret

00000000800057c2 <sys_close>:
{
    800057c2:	1101                	addi	sp,sp,-32
    800057c4:	ec06                	sd	ra,24(sp)
    800057c6:	e822                	sd	s0,16(sp)
    800057c8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057ca:	fe040613          	addi	a2,s0,-32
    800057ce:	fec40593          	addi	a1,s0,-20
    800057d2:	4501                	li	a0,0
    800057d4:	00000097          	auipc	ra,0x0
    800057d8:	cc2080e7          	jalr	-830(ra) # 80005496 <argfd>
    return -1;
    800057dc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057de:	02054463          	bltz	a0,80005806 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057e2:	ffffc097          	auipc	ra,0xffffc
    800057e6:	540080e7          	jalr	1344(ra) # 80001d22 <myproc>
    800057ea:	fec42783          	lw	a5,-20(s0)
    800057ee:	07e9                	addi	a5,a5,26
    800057f0:	078e                	slli	a5,a5,0x3
    800057f2:	97aa                	add	a5,a5,a0
    800057f4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057f8:	fe043503          	ld	a0,-32(s0)
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	2b0080e7          	jalr	688(ra) # 80004aac <fileclose>
  return 0;
    80005804:	4781                	li	a5,0
}
    80005806:	853e                	mv	a0,a5
    80005808:	60e2                	ld	ra,24(sp)
    8000580a:	6442                	ld	s0,16(sp)
    8000580c:	6105                	addi	sp,sp,32
    8000580e:	8082                	ret

0000000080005810 <sys_fstat>:
{
    80005810:	1101                	addi	sp,sp,-32
    80005812:	ec06                	sd	ra,24(sp)
    80005814:	e822                	sd	s0,16(sp)
    80005816:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005818:	fe840613          	addi	a2,s0,-24
    8000581c:	4581                	li	a1,0
    8000581e:	4501                	li	a0,0
    80005820:	00000097          	auipc	ra,0x0
    80005824:	c76080e7          	jalr	-906(ra) # 80005496 <argfd>
    return -1;
    80005828:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000582a:	02054563          	bltz	a0,80005854 <sys_fstat+0x44>
    8000582e:	fe040593          	addi	a1,s0,-32
    80005832:	4505                	li	a0,1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	840080e7          	jalr	-1984(ra) # 80003074 <argaddr>
    return -1;
    8000583c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000583e:	00054b63          	bltz	a0,80005854 <sys_fstat+0x44>
  return filestat(f, st);
    80005842:	fe043583          	ld	a1,-32(s0)
    80005846:	fe843503          	ld	a0,-24(s0)
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	32a080e7          	jalr	810(ra) # 80004b74 <filestat>
    80005852:	87aa                	mv	a5,a0
}
    80005854:	853e                	mv	a0,a5
    80005856:	60e2                	ld	ra,24(sp)
    80005858:	6442                	ld	s0,16(sp)
    8000585a:	6105                	addi	sp,sp,32
    8000585c:	8082                	ret

000000008000585e <sys_link>:
{
    8000585e:	7169                	addi	sp,sp,-304
    80005860:	f606                	sd	ra,296(sp)
    80005862:	f222                	sd	s0,288(sp)
    80005864:	ee26                	sd	s1,280(sp)
    80005866:	ea4a                	sd	s2,272(sp)
    80005868:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000586a:	08000613          	li	a2,128
    8000586e:	ed040593          	addi	a1,s0,-304
    80005872:	4501                	li	a0,0
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	822080e7          	jalr	-2014(ra) # 80003096 <argstr>
    return -1;
    8000587c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000587e:	10054e63          	bltz	a0,8000599a <sys_link+0x13c>
    80005882:	08000613          	li	a2,128
    80005886:	f5040593          	addi	a1,s0,-176
    8000588a:	4505                	li	a0,1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	80a080e7          	jalr	-2038(ra) # 80003096 <argstr>
    return -1;
    80005894:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005896:	10054263          	bltz	a0,8000599a <sys_link+0x13c>
  begin_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	d46080e7          	jalr	-698(ra) # 800045e0 <begin_op>
  if((ip = namei(old)) == 0){
    800058a2:	ed040513          	addi	a0,s0,-304
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	b1e080e7          	jalr	-1250(ra) # 800043c4 <namei>
    800058ae:	84aa                	mv	s1,a0
    800058b0:	c551                	beqz	a0,8000593c <sys_link+0xde>
  ilock(ip);
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	35c080e7          	jalr	860(ra) # 80003c0e <ilock>
  if(ip->type == T_DIR){
    800058ba:	04449703          	lh	a4,68(s1)
    800058be:	4785                	li	a5,1
    800058c0:	08f70463          	beq	a4,a5,80005948 <sys_link+0xea>
  ip->nlink++;
    800058c4:	04a4d783          	lhu	a5,74(s1)
    800058c8:	2785                	addiw	a5,a5,1
    800058ca:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ce:	8526                	mv	a0,s1
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	274080e7          	jalr	628(ra) # 80003b44 <iupdate>
  iunlock(ip);
    800058d8:	8526                	mv	a0,s1
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	3f6080e7          	jalr	1014(ra) # 80003cd0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058e2:	fd040593          	addi	a1,s0,-48
    800058e6:	f5040513          	addi	a0,s0,-176
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	af8080e7          	jalr	-1288(ra) # 800043e2 <nameiparent>
    800058f2:	892a                	mv	s2,a0
    800058f4:	c935                	beqz	a0,80005968 <sys_link+0x10a>
  ilock(dp);
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	318080e7          	jalr	792(ra) # 80003c0e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058fe:	00092703          	lw	a4,0(s2)
    80005902:	409c                	lw	a5,0(s1)
    80005904:	04f71d63          	bne	a4,a5,8000595e <sys_link+0x100>
    80005908:	40d0                	lw	a2,4(s1)
    8000590a:	fd040593          	addi	a1,s0,-48
    8000590e:	854a                	mv	a0,s2
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	9f2080e7          	jalr	-1550(ra) # 80004302 <dirlink>
    80005918:	04054363          	bltz	a0,8000595e <sys_link+0x100>
  iunlockput(dp);
    8000591c:	854a                	mv	a0,s2
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	552080e7          	jalr	1362(ra) # 80003e70 <iunlockput>
  iput(ip);
    80005926:	8526                	mv	a0,s1
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	4a0080e7          	jalr	1184(ra) # 80003dc8 <iput>
  end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	d30080e7          	jalr	-720(ra) # 80004660 <end_op>
  return 0;
    80005938:	4781                	li	a5,0
    8000593a:	a085                	j	8000599a <sys_link+0x13c>
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	d24080e7          	jalr	-732(ra) # 80004660 <end_op>
    return -1;
    80005944:	57fd                	li	a5,-1
    80005946:	a891                	j	8000599a <sys_link+0x13c>
    iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	526080e7          	jalr	1318(ra) # 80003e70 <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	d0e080e7          	jalr	-754(ra) # 80004660 <end_op>
    return -1;
    8000595a:	57fd                	li	a5,-1
    8000595c:	a83d                	j	8000599a <sys_link+0x13c>
    iunlockput(dp);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	510080e7          	jalr	1296(ra) # 80003e70 <iunlockput>
  ilock(ip);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	2a4080e7          	jalr	676(ra) # 80003c0e <ilock>
  ip->nlink--;
    80005972:	04a4d783          	lhu	a5,74(s1)
    80005976:	37fd                	addiw	a5,a5,-1
    80005978:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000597c:	8526                	mv	a0,s1
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	1c6080e7          	jalr	454(ra) # 80003b44 <iupdate>
  iunlockput(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	4e8080e7          	jalr	1256(ra) # 80003e70 <iunlockput>
  end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	cd0080e7          	jalr	-816(ra) # 80004660 <end_op>
  return -1;
    80005998:	57fd                	li	a5,-1
}
    8000599a:	853e                	mv	a0,a5
    8000599c:	70b2                	ld	ra,296(sp)
    8000599e:	7412                	ld	s0,288(sp)
    800059a0:	64f2                	ld	s1,280(sp)
    800059a2:	6952                	ld	s2,272(sp)
    800059a4:	6155                	addi	sp,sp,304
    800059a6:	8082                	ret

00000000800059a8 <sys_unlink>:
{
    800059a8:	7151                	addi	sp,sp,-240
    800059aa:	f586                	sd	ra,232(sp)
    800059ac:	f1a2                	sd	s0,224(sp)
    800059ae:	eda6                	sd	s1,216(sp)
    800059b0:	e9ca                	sd	s2,208(sp)
    800059b2:	e5ce                	sd	s3,200(sp)
    800059b4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059b6:	08000613          	li	a2,128
    800059ba:	f3040593          	addi	a1,s0,-208
    800059be:	4501                	li	a0,0
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	6d6080e7          	jalr	1750(ra) # 80003096 <argstr>
    800059c8:	18054163          	bltz	a0,80005b4a <sys_unlink+0x1a2>
  begin_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	c14080e7          	jalr	-1004(ra) # 800045e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059d4:	fb040593          	addi	a1,s0,-80
    800059d8:	f3040513          	addi	a0,s0,-208
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	a06080e7          	jalr	-1530(ra) # 800043e2 <nameiparent>
    800059e4:	84aa                	mv	s1,a0
    800059e6:	c979                	beqz	a0,80005abc <sys_unlink+0x114>
  ilock(dp);
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	226080e7          	jalr	550(ra) # 80003c0e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059f0:	00003597          	auipc	a1,0x3
    800059f4:	ee858593          	addi	a1,a1,-280 # 800088d8 <syscalls+0x2c0>
    800059f8:	fb040513          	addi	a0,s0,-80
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	6dc080e7          	jalr	1756(ra) # 800040d8 <namecmp>
    80005a04:	14050a63          	beqz	a0,80005b58 <sys_unlink+0x1b0>
    80005a08:	00003597          	auipc	a1,0x3
    80005a0c:	ed858593          	addi	a1,a1,-296 # 800088e0 <syscalls+0x2c8>
    80005a10:	fb040513          	addi	a0,s0,-80
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	6c4080e7          	jalr	1732(ra) # 800040d8 <namecmp>
    80005a1c:	12050e63          	beqz	a0,80005b58 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a20:	f2c40613          	addi	a2,s0,-212
    80005a24:	fb040593          	addi	a1,s0,-80
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	6c8080e7          	jalr	1736(ra) # 800040f2 <dirlookup>
    80005a32:	892a                	mv	s2,a0
    80005a34:	12050263          	beqz	a0,80005b58 <sys_unlink+0x1b0>
  ilock(ip);
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	1d6080e7          	jalr	470(ra) # 80003c0e <ilock>
  if(ip->nlink < 1)
    80005a40:	04a91783          	lh	a5,74(s2)
    80005a44:	08f05263          	blez	a5,80005ac8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a48:	04491703          	lh	a4,68(s2)
    80005a4c:	4785                	li	a5,1
    80005a4e:	08f70563          	beq	a4,a5,80005ad8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a52:	4641                	li	a2,16
    80005a54:	4581                	li	a1,0
    80005a56:	fc040513          	addi	a0,s0,-64
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	286080e7          	jalr	646(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a62:	4741                	li	a4,16
    80005a64:	f2c42683          	lw	a3,-212(s0)
    80005a68:	fc040613          	addi	a2,s0,-64
    80005a6c:	4581                	li	a1,0
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	54a080e7          	jalr	1354(ra) # 80003fba <writei>
    80005a78:	47c1                	li	a5,16
    80005a7a:	0af51563          	bne	a0,a5,80005b24 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a7e:	04491703          	lh	a4,68(s2)
    80005a82:	4785                	li	a5,1
    80005a84:	0af70863          	beq	a4,a5,80005b34 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	3e6080e7          	jalr	998(ra) # 80003e70 <iunlockput>
  ip->nlink--;
    80005a92:	04a95783          	lhu	a5,74(s2)
    80005a96:	37fd                	addiw	a5,a5,-1
    80005a98:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a9c:	854a                	mv	a0,s2
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	0a6080e7          	jalr	166(ra) # 80003b44 <iupdate>
  iunlockput(ip);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	3c8080e7          	jalr	968(ra) # 80003e70 <iunlockput>
  end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	bb0080e7          	jalr	-1104(ra) # 80004660 <end_op>
  return 0;
    80005ab8:	4501                	li	a0,0
    80005aba:	a84d                	j	80005b6c <sys_unlink+0x1c4>
    end_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	ba4080e7          	jalr	-1116(ra) # 80004660 <end_op>
    return -1;
    80005ac4:	557d                	li	a0,-1
    80005ac6:	a05d                	j	80005b6c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ac8:	00003517          	auipc	a0,0x3
    80005acc:	e4050513          	addi	a0,a0,-448 # 80008908 <syscalls+0x2f0>
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	a6e080e7          	jalr	-1426(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ad8:	04c92703          	lw	a4,76(s2)
    80005adc:	02000793          	li	a5,32
    80005ae0:	f6e7f9e3          	bgeu	a5,a4,80005a52 <sys_unlink+0xaa>
    80005ae4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ae8:	4741                	li	a4,16
    80005aea:	86ce                	mv	a3,s3
    80005aec:	f1840613          	addi	a2,s0,-232
    80005af0:	4581                	li	a1,0
    80005af2:	854a                	mv	a0,s2
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	3ce080e7          	jalr	974(ra) # 80003ec2 <readi>
    80005afc:	47c1                	li	a5,16
    80005afe:	00f51b63          	bne	a0,a5,80005b14 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b02:	f1845783          	lhu	a5,-232(s0)
    80005b06:	e7a1                	bnez	a5,80005b4e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b08:	29c1                	addiw	s3,s3,16
    80005b0a:	04c92783          	lw	a5,76(s2)
    80005b0e:	fcf9ede3          	bltu	s3,a5,80005ae8 <sys_unlink+0x140>
    80005b12:	b781                	j	80005a52 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b14:	00003517          	auipc	a0,0x3
    80005b18:	e0c50513          	addi	a0,a0,-500 # 80008920 <syscalls+0x308>
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	a22080e7          	jalr	-1502(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b24:	00003517          	auipc	a0,0x3
    80005b28:	e1450513          	addi	a0,a0,-492 # 80008938 <syscalls+0x320>
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
    dp->nlink--;
    80005b34:	04a4d783          	lhu	a5,74(s1)
    80005b38:	37fd                	addiw	a5,a5,-1
    80005b3a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	004080e7          	jalr	4(ra) # 80003b44 <iupdate>
    80005b48:	b781                	j	80005a88 <sys_unlink+0xe0>
    return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	a005                	j	80005b6c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b4e:	854a                	mv	a0,s2
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	320080e7          	jalr	800(ra) # 80003e70 <iunlockput>
  iunlockput(dp);
    80005b58:	8526                	mv	a0,s1
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	316080e7          	jalr	790(ra) # 80003e70 <iunlockput>
  end_op();
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	afe080e7          	jalr	-1282(ra) # 80004660 <end_op>
  return -1;
    80005b6a:	557d                	li	a0,-1
}
    80005b6c:	70ae                	ld	ra,232(sp)
    80005b6e:	740e                	ld	s0,224(sp)
    80005b70:	64ee                	ld	s1,216(sp)
    80005b72:	694e                	ld	s2,208(sp)
    80005b74:	69ae                	ld	s3,200(sp)
    80005b76:	616d                	addi	sp,sp,240
    80005b78:	8082                	ret

0000000080005b7a <sys_open>:

uint64
sys_open(void)
{
    80005b7a:	7131                	addi	sp,sp,-192
    80005b7c:	fd06                	sd	ra,184(sp)
    80005b7e:	f922                	sd	s0,176(sp)
    80005b80:	f526                	sd	s1,168(sp)
    80005b82:	f14a                	sd	s2,160(sp)
    80005b84:	ed4e                	sd	s3,152(sp)
    80005b86:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b88:	08000613          	li	a2,128
    80005b8c:	f5040593          	addi	a1,s0,-176
    80005b90:	4501                	li	a0,0
    80005b92:	ffffd097          	auipc	ra,0xffffd
    80005b96:	504080e7          	jalr	1284(ra) # 80003096 <argstr>
    return -1;
    80005b9a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b9c:	0c054163          	bltz	a0,80005c5e <sys_open+0xe4>
    80005ba0:	f4c40593          	addi	a1,s0,-180
    80005ba4:	4505                	li	a0,1
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	4ac080e7          	jalr	1196(ra) # 80003052 <argint>
    80005bae:	0a054863          	bltz	a0,80005c5e <sys_open+0xe4>

  begin_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	a2e080e7          	jalr	-1490(ra) # 800045e0 <begin_op>

  if(omode & O_CREATE){
    80005bba:	f4c42783          	lw	a5,-180(s0)
    80005bbe:	2007f793          	andi	a5,a5,512
    80005bc2:	cbdd                	beqz	a5,80005c78 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bc4:	4681                	li	a3,0
    80005bc6:	4601                	li	a2,0
    80005bc8:	4589                	li	a1,2
    80005bca:	f5040513          	addi	a0,s0,-176
    80005bce:	00000097          	auipc	ra,0x0
    80005bd2:	972080e7          	jalr	-1678(ra) # 80005540 <create>
    80005bd6:	892a                	mv	s2,a0
    if(ip == 0){
    80005bd8:	c959                	beqz	a0,80005c6e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bda:	04491703          	lh	a4,68(s2)
    80005bde:	478d                	li	a5,3
    80005be0:	00f71763          	bne	a4,a5,80005bee <sys_open+0x74>
    80005be4:	04695703          	lhu	a4,70(s2)
    80005be8:	47a5                	li	a5,9
    80005bea:	0ce7ec63          	bltu	a5,a4,80005cc2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	e02080e7          	jalr	-510(ra) # 800049f0 <filealloc>
    80005bf6:	89aa                	mv	s3,a0
    80005bf8:	10050263          	beqz	a0,80005cfc <sys_open+0x182>
    80005bfc:	00000097          	auipc	ra,0x0
    80005c00:	902080e7          	jalr	-1790(ra) # 800054fe <fdalloc>
    80005c04:	84aa                	mv	s1,a0
    80005c06:	0e054663          	bltz	a0,80005cf2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c0a:	04491703          	lh	a4,68(s2)
    80005c0e:	478d                	li	a5,3
    80005c10:	0cf70463          	beq	a4,a5,80005cd8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c14:	4789                	li	a5,2
    80005c16:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c1a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c1e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c22:	f4c42783          	lw	a5,-180(s0)
    80005c26:	0017c713          	xori	a4,a5,1
    80005c2a:	8b05                	andi	a4,a4,1
    80005c2c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c30:	0037f713          	andi	a4,a5,3
    80005c34:	00e03733          	snez	a4,a4
    80005c38:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c3c:	4007f793          	andi	a5,a5,1024
    80005c40:	c791                	beqz	a5,80005c4c <sys_open+0xd2>
    80005c42:	04491703          	lh	a4,68(s2)
    80005c46:	4789                	li	a5,2
    80005c48:	08f70f63          	beq	a4,a5,80005ce6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c4c:	854a                	mv	a0,s2
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	082080e7          	jalr	130(ra) # 80003cd0 <iunlock>
  end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	a0a080e7          	jalr	-1526(ra) # 80004660 <end_op>

  return fd;
}
    80005c5e:	8526                	mv	a0,s1
    80005c60:	70ea                	ld	ra,184(sp)
    80005c62:	744a                	ld	s0,176(sp)
    80005c64:	74aa                	ld	s1,168(sp)
    80005c66:	790a                	ld	s2,160(sp)
    80005c68:	69ea                	ld	s3,152(sp)
    80005c6a:	6129                	addi	sp,sp,192
    80005c6c:	8082                	ret
      end_op();
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	9f2080e7          	jalr	-1550(ra) # 80004660 <end_op>
      return -1;
    80005c76:	b7e5                	j	80005c5e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c78:	f5040513          	addi	a0,s0,-176
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	748080e7          	jalr	1864(ra) # 800043c4 <namei>
    80005c84:	892a                	mv	s2,a0
    80005c86:	c905                	beqz	a0,80005cb6 <sys_open+0x13c>
    ilock(ip);
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	f86080e7          	jalr	-122(ra) # 80003c0e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c90:	04491703          	lh	a4,68(s2)
    80005c94:	4785                	li	a5,1
    80005c96:	f4f712e3          	bne	a4,a5,80005bda <sys_open+0x60>
    80005c9a:	f4c42783          	lw	a5,-180(s0)
    80005c9e:	dba1                	beqz	a5,80005bee <sys_open+0x74>
      iunlockput(ip);
    80005ca0:	854a                	mv	a0,s2
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	1ce080e7          	jalr	462(ra) # 80003e70 <iunlockput>
      end_op();
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	9b6080e7          	jalr	-1610(ra) # 80004660 <end_op>
      return -1;
    80005cb2:	54fd                	li	s1,-1
    80005cb4:	b76d                	j	80005c5e <sys_open+0xe4>
      end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	9aa080e7          	jalr	-1622(ra) # 80004660 <end_op>
      return -1;
    80005cbe:	54fd                	li	s1,-1
    80005cc0:	bf79                	j	80005c5e <sys_open+0xe4>
    iunlockput(ip);
    80005cc2:	854a                	mv	a0,s2
    80005cc4:	ffffe097          	auipc	ra,0xffffe
    80005cc8:	1ac080e7          	jalr	428(ra) # 80003e70 <iunlockput>
    end_op();
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	994080e7          	jalr	-1644(ra) # 80004660 <end_op>
    return -1;
    80005cd4:	54fd                	li	s1,-1
    80005cd6:	b761                	j	80005c5e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cd8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cdc:	04691783          	lh	a5,70(s2)
    80005ce0:	02f99223          	sh	a5,36(s3)
    80005ce4:	bf2d                	j	80005c1e <sys_open+0xa4>
    itrunc(ip);
    80005ce6:	854a                	mv	a0,s2
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	034080e7          	jalr	52(ra) # 80003d1c <itrunc>
    80005cf0:	bfb1                	j	80005c4c <sys_open+0xd2>
      fileclose(f);
    80005cf2:	854e                	mv	a0,s3
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	db8080e7          	jalr	-584(ra) # 80004aac <fileclose>
    iunlockput(ip);
    80005cfc:	854a                	mv	a0,s2
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	172080e7          	jalr	370(ra) # 80003e70 <iunlockput>
    end_op();
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	95a080e7          	jalr	-1702(ra) # 80004660 <end_op>
    return -1;
    80005d0e:	54fd                	li	s1,-1
    80005d10:	b7b9                	j	80005c5e <sys_open+0xe4>

0000000080005d12 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d12:	7175                	addi	sp,sp,-144
    80005d14:	e506                	sd	ra,136(sp)
    80005d16:	e122                	sd	s0,128(sp)
    80005d18:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	8c6080e7          	jalr	-1850(ra) # 800045e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d22:	08000613          	li	a2,128
    80005d26:	f7040593          	addi	a1,s0,-144
    80005d2a:	4501                	li	a0,0
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	36a080e7          	jalr	874(ra) # 80003096 <argstr>
    80005d34:	02054963          	bltz	a0,80005d66 <sys_mkdir+0x54>
    80005d38:	4681                	li	a3,0
    80005d3a:	4601                	li	a2,0
    80005d3c:	4585                	li	a1,1
    80005d3e:	f7040513          	addi	a0,s0,-144
    80005d42:	fffff097          	auipc	ra,0xfffff
    80005d46:	7fe080e7          	jalr	2046(ra) # 80005540 <create>
    80005d4a:	cd11                	beqz	a0,80005d66 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	124080e7          	jalr	292(ra) # 80003e70 <iunlockput>
  end_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	90c080e7          	jalr	-1780(ra) # 80004660 <end_op>
  return 0;
    80005d5c:	4501                	li	a0,0
}
    80005d5e:	60aa                	ld	ra,136(sp)
    80005d60:	640a                	ld	s0,128(sp)
    80005d62:	6149                	addi	sp,sp,144
    80005d64:	8082                	ret
    end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	8fa080e7          	jalr	-1798(ra) # 80004660 <end_op>
    return -1;
    80005d6e:	557d                	li	a0,-1
    80005d70:	b7fd                	j	80005d5e <sys_mkdir+0x4c>

0000000080005d72 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d72:	7135                	addi	sp,sp,-160
    80005d74:	ed06                	sd	ra,152(sp)
    80005d76:	e922                	sd	s0,144(sp)
    80005d78:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	866080e7          	jalr	-1946(ra) # 800045e0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d82:	08000613          	li	a2,128
    80005d86:	f7040593          	addi	a1,s0,-144
    80005d8a:	4501                	li	a0,0
    80005d8c:	ffffd097          	auipc	ra,0xffffd
    80005d90:	30a080e7          	jalr	778(ra) # 80003096 <argstr>
    80005d94:	04054a63          	bltz	a0,80005de8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d98:	f6c40593          	addi	a1,s0,-148
    80005d9c:	4505                	li	a0,1
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	2b4080e7          	jalr	692(ra) # 80003052 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005da6:	04054163          	bltz	a0,80005de8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005daa:	f6840593          	addi	a1,s0,-152
    80005dae:	4509                	li	a0,2
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	2a2080e7          	jalr	674(ra) # 80003052 <argint>
     argint(1, &major) < 0 ||
    80005db8:	02054863          	bltz	a0,80005de8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dbc:	f6841683          	lh	a3,-152(s0)
    80005dc0:	f6c41603          	lh	a2,-148(s0)
    80005dc4:	458d                	li	a1,3
    80005dc6:	f7040513          	addi	a0,s0,-144
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	776080e7          	jalr	1910(ra) # 80005540 <create>
     argint(2, &minor) < 0 ||
    80005dd2:	c919                	beqz	a0,80005de8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	09c080e7          	jalr	156(ra) # 80003e70 <iunlockput>
  end_op();
    80005ddc:	fffff097          	auipc	ra,0xfffff
    80005de0:	884080e7          	jalr	-1916(ra) # 80004660 <end_op>
  return 0;
    80005de4:	4501                	li	a0,0
    80005de6:	a031                	j	80005df2 <sys_mknod+0x80>
    end_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	878080e7          	jalr	-1928(ra) # 80004660 <end_op>
    return -1;
    80005df0:	557d                	li	a0,-1
}
    80005df2:	60ea                	ld	ra,152(sp)
    80005df4:	644a                	ld	s0,144(sp)
    80005df6:	610d                	addi	sp,sp,160
    80005df8:	8082                	ret

0000000080005dfa <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dfa:	7135                	addi	sp,sp,-160
    80005dfc:	ed06                	sd	ra,152(sp)
    80005dfe:	e922                	sd	s0,144(sp)
    80005e00:	e526                	sd	s1,136(sp)
    80005e02:	e14a                	sd	s2,128(sp)
    80005e04:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e06:	ffffc097          	auipc	ra,0xffffc
    80005e0a:	f1c080e7          	jalr	-228(ra) # 80001d22 <myproc>
    80005e0e:	892a                	mv	s2,a0
  
  begin_op();
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	7d0080e7          	jalr	2000(ra) # 800045e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e18:	08000613          	li	a2,128
    80005e1c:	f6040593          	addi	a1,s0,-160
    80005e20:	4501                	li	a0,0
    80005e22:	ffffd097          	auipc	ra,0xffffd
    80005e26:	274080e7          	jalr	628(ra) # 80003096 <argstr>
    80005e2a:	04054b63          	bltz	a0,80005e80 <sys_chdir+0x86>
    80005e2e:	f6040513          	addi	a0,s0,-160
    80005e32:	ffffe097          	auipc	ra,0xffffe
    80005e36:	592080e7          	jalr	1426(ra) # 800043c4 <namei>
    80005e3a:	84aa                	mv	s1,a0
    80005e3c:	c131                	beqz	a0,80005e80 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	dd0080e7          	jalr	-560(ra) # 80003c0e <ilock>
  if(ip->type != T_DIR){
    80005e46:	04449703          	lh	a4,68(s1)
    80005e4a:	4785                	li	a5,1
    80005e4c:	04f71063          	bne	a4,a5,80005e8c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e50:	8526                	mv	a0,s1
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	e7e080e7          	jalr	-386(ra) # 80003cd0 <iunlock>
  iput(p->cwd);
    80005e5a:	15093503          	ld	a0,336(s2)
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	f6a080e7          	jalr	-150(ra) # 80003dc8 <iput>
  end_op();
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	7fa080e7          	jalr	2042(ra) # 80004660 <end_op>
  p->cwd = ip;
    80005e6e:	14993823          	sd	s1,336(s2)
  return 0;
    80005e72:	4501                	li	a0,0
}
    80005e74:	60ea                	ld	ra,152(sp)
    80005e76:	644a                	ld	s0,144(sp)
    80005e78:	64aa                	ld	s1,136(sp)
    80005e7a:	690a                	ld	s2,128(sp)
    80005e7c:	610d                	addi	sp,sp,160
    80005e7e:	8082                	ret
    end_op();
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	7e0080e7          	jalr	2016(ra) # 80004660 <end_op>
    return -1;
    80005e88:	557d                	li	a0,-1
    80005e8a:	b7ed                	j	80005e74 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	fe2080e7          	jalr	-30(ra) # 80003e70 <iunlockput>
    end_op();
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	7ca080e7          	jalr	1994(ra) # 80004660 <end_op>
    return -1;
    80005e9e:	557d                	li	a0,-1
    80005ea0:	bfd1                	j	80005e74 <sys_chdir+0x7a>

0000000080005ea2 <sys_exec>:

uint64
sys_exec(void)
{
    80005ea2:	7145                	addi	sp,sp,-464
    80005ea4:	e786                	sd	ra,456(sp)
    80005ea6:	e3a2                	sd	s0,448(sp)
    80005ea8:	ff26                	sd	s1,440(sp)
    80005eaa:	fb4a                	sd	s2,432(sp)
    80005eac:	f74e                	sd	s3,424(sp)
    80005eae:	f352                	sd	s4,416(sp)
    80005eb0:	ef56                	sd	s5,408(sp)
    80005eb2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eb4:	08000613          	li	a2,128
    80005eb8:	f4040593          	addi	a1,s0,-192
    80005ebc:	4501                	li	a0,0
    80005ebe:	ffffd097          	auipc	ra,0xffffd
    80005ec2:	1d8080e7          	jalr	472(ra) # 80003096 <argstr>
    return -1;
    80005ec6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ec8:	0c054a63          	bltz	a0,80005f9c <sys_exec+0xfa>
    80005ecc:	e3840593          	addi	a1,s0,-456
    80005ed0:	4505                	li	a0,1
    80005ed2:	ffffd097          	auipc	ra,0xffffd
    80005ed6:	1a2080e7          	jalr	418(ra) # 80003074 <argaddr>
    80005eda:	0c054163          	bltz	a0,80005f9c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ede:	10000613          	li	a2,256
    80005ee2:	4581                	li	a1,0
    80005ee4:	e4040513          	addi	a0,s0,-448
    80005ee8:	ffffb097          	auipc	ra,0xffffb
    80005eec:	df8080e7          	jalr	-520(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ef0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ef4:	89a6                	mv	s3,s1
    80005ef6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ef8:	02000a13          	li	s4,32
    80005efc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f00:	00391513          	slli	a0,s2,0x3
    80005f04:	e3040593          	addi	a1,s0,-464
    80005f08:	e3843783          	ld	a5,-456(s0)
    80005f0c:	953e                	add	a0,a0,a5
    80005f0e:	ffffd097          	auipc	ra,0xffffd
    80005f12:	0aa080e7          	jalr	170(ra) # 80002fb8 <fetchaddr>
    80005f16:	02054a63          	bltz	a0,80005f4a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f1a:	e3043783          	ld	a5,-464(s0)
    80005f1e:	c3b9                	beqz	a5,80005f64 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	bd4080e7          	jalr	-1068(ra) # 80000af4 <kalloc>
    80005f28:	85aa                	mv	a1,a0
    80005f2a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f2e:	cd11                	beqz	a0,80005f4a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f30:	6605                	lui	a2,0x1
    80005f32:	e3043503          	ld	a0,-464(s0)
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	0d4080e7          	jalr	212(ra) # 8000300a <fetchstr>
    80005f3e:	00054663          	bltz	a0,80005f4a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f42:	0905                	addi	s2,s2,1
    80005f44:	09a1                	addi	s3,s3,8
    80005f46:	fb491be3          	bne	s2,s4,80005efc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f4a:	10048913          	addi	s2,s1,256
    80005f4e:	6088                	ld	a0,0(s1)
    80005f50:	c529                	beqz	a0,80005f9a <sys_exec+0xf8>
    kfree(argv[i]);
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	aa6080e7          	jalr	-1370(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f5a:	04a1                	addi	s1,s1,8
    80005f5c:	ff2499e3          	bne	s1,s2,80005f4e <sys_exec+0xac>
  return -1;
    80005f60:	597d                	li	s2,-1
    80005f62:	a82d                	j	80005f9c <sys_exec+0xfa>
      argv[i] = 0;
    80005f64:	0a8e                	slli	s5,s5,0x3
    80005f66:	fc040793          	addi	a5,s0,-64
    80005f6a:	9abe                	add	s5,s5,a5
    80005f6c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f70:	e4040593          	addi	a1,s0,-448
    80005f74:	f4040513          	addi	a0,s0,-192
    80005f78:	fffff097          	auipc	ra,0xfffff
    80005f7c:	194080e7          	jalr	404(ra) # 8000510c <exec>
    80005f80:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f82:	10048993          	addi	s3,s1,256
    80005f86:	6088                	ld	a0,0(s1)
    80005f88:	c911                	beqz	a0,80005f9c <sys_exec+0xfa>
    kfree(argv[i]);
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	a6e080e7          	jalr	-1426(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f92:	04a1                	addi	s1,s1,8
    80005f94:	ff3499e3          	bne	s1,s3,80005f86 <sys_exec+0xe4>
    80005f98:	a011                	j	80005f9c <sys_exec+0xfa>
  return -1;
    80005f9a:	597d                	li	s2,-1
}
    80005f9c:	854a                	mv	a0,s2
    80005f9e:	60be                	ld	ra,456(sp)
    80005fa0:	641e                	ld	s0,448(sp)
    80005fa2:	74fa                	ld	s1,440(sp)
    80005fa4:	795a                	ld	s2,432(sp)
    80005fa6:	79ba                	ld	s3,424(sp)
    80005fa8:	7a1a                	ld	s4,416(sp)
    80005faa:	6afa                	ld	s5,408(sp)
    80005fac:	6179                	addi	sp,sp,464
    80005fae:	8082                	ret

0000000080005fb0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fb0:	7139                	addi	sp,sp,-64
    80005fb2:	fc06                	sd	ra,56(sp)
    80005fb4:	f822                	sd	s0,48(sp)
    80005fb6:	f426                	sd	s1,40(sp)
    80005fb8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fba:	ffffc097          	auipc	ra,0xffffc
    80005fbe:	d68080e7          	jalr	-664(ra) # 80001d22 <myproc>
    80005fc2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fc4:	fd840593          	addi	a1,s0,-40
    80005fc8:	4501                	li	a0,0
    80005fca:	ffffd097          	auipc	ra,0xffffd
    80005fce:	0aa080e7          	jalr	170(ra) # 80003074 <argaddr>
    return -1;
    80005fd2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fd4:	0e054063          	bltz	a0,800060b4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fd8:	fc840593          	addi	a1,s0,-56
    80005fdc:	fd040513          	addi	a0,s0,-48
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	dfc080e7          	jalr	-516(ra) # 80004ddc <pipealloc>
    return -1;
    80005fe8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fea:	0c054563          	bltz	a0,800060b4 <sys_pipe+0x104>
  fd0 = -1;
    80005fee:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ff2:	fd043503          	ld	a0,-48(s0)
    80005ff6:	fffff097          	auipc	ra,0xfffff
    80005ffa:	508080e7          	jalr	1288(ra) # 800054fe <fdalloc>
    80005ffe:	fca42223          	sw	a0,-60(s0)
    80006002:	08054c63          	bltz	a0,8000609a <sys_pipe+0xea>
    80006006:	fc843503          	ld	a0,-56(s0)
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	4f4080e7          	jalr	1268(ra) # 800054fe <fdalloc>
    80006012:	fca42023          	sw	a0,-64(s0)
    80006016:	06054863          	bltz	a0,80006086 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000601a:	4691                	li	a3,4
    8000601c:	fc440613          	addi	a2,s0,-60
    80006020:	fd843583          	ld	a1,-40(s0)
    80006024:	68a8                	ld	a0,80(s1)
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	64c080e7          	jalr	1612(ra) # 80001672 <copyout>
    8000602e:	02054063          	bltz	a0,8000604e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006032:	4691                	li	a3,4
    80006034:	fc040613          	addi	a2,s0,-64
    80006038:	fd843583          	ld	a1,-40(s0)
    8000603c:	0591                	addi	a1,a1,4
    8000603e:	68a8                	ld	a0,80(s1)
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	632080e7          	jalr	1586(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006048:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000604a:	06055563          	bgez	a0,800060b4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000604e:	fc442783          	lw	a5,-60(s0)
    80006052:	07e9                	addi	a5,a5,26
    80006054:	078e                	slli	a5,a5,0x3
    80006056:	97a6                	add	a5,a5,s1
    80006058:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000605c:	fc042503          	lw	a0,-64(s0)
    80006060:	0569                	addi	a0,a0,26
    80006062:	050e                	slli	a0,a0,0x3
    80006064:	9526                	add	a0,a0,s1
    80006066:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000606a:	fd043503          	ld	a0,-48(s0)
    8000606e:	fffff097          	auipc	ra,0xfffff
    80006072:	a3e080e7          	jalr	-1474(ra) # 80004aac <fileclose>
    fileclose(wf);
    80006076:	fc843503          	ld	a0,-56(s0)
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	a32080e7          	jalr	-1486(ra) # 80004aac <fileclose>
    return -1;
    80006082:	57fd                	li	a5,-1
    80006084:	a805                	j	800060b4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006086:	fc442783          	lw	a5,-60(s0)
    8000608a:	0007c863          	bltz	a5,8000609a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000608e:	01a78513          	addi	a0,a5,26
    80006092:	050e                	slli	a0,a0,0x3
    80006094:	9526                	add	a0,a0,s1
    80006096:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000609a:	fd043503          	ld	a0,-48(s0)
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	a0e080e7          	jalr	-1522(ra) # 80004aac <fileclose>
    fileclose(wf);
    800060a6:	fc843503          	ld	a0,-56(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	a02080e7          	jalr	-1534(ra) # 80004aac <fileclose>
    return -1;
    800060b2:	57fd                	li	a5,-1
}
    800060b4:	853e                	mv	a0,a5
    800060b6:	70e2                	ld	ra,56(sp)
    800060b8:	7442                	ld	s0,48(sp)
    800060ba:	74a2                	ld	s1,40(sp)
    800060bc:	6121                	addi	sp,sp,64
    800060be:	8082                	ret

00000000800060c0 <kernelvec>:
    800060c0:	7111                	addi	sp,sp,-256
    800060c2:	e006                	sd	ra,0(sp)
    800060c4:	e40a                	sd	sp,8(sp)
    800060c6:	e80e                	sd	gp,16(sp)
    800060c8:	ec12                	sd	tp,24(sp)
    800060ca:	f016                	sd	t0,32(sp)
    800060cc:	f41a                	sd	t1,40(sp)
    800060ce:	f81e                	sd	t2,48(sp)
    800060d0:	fc22                	sd	s0,56(sp)
    800060d2:	e0a6                	sd	s1,64(sp)
    800060d4:	e4aa                	sd	a0,72(sp)
    800060d6:	e8ae                	sd	a1,80(sp)
    800060d8:	ecb2                	sd	a2,88(sp)
    800060da:	f0b6                	sd	a3,96(sp)
    800060dc:	f4ba                	sd	a4,104(sp)
    800060de:	f8be                	sd	a5,112(sp)
    800060e0:	fcc2                	sd	a6,120(sp)
    800060e2:	e146                	sd	a7,128(sp)
    800060e4:	e54a                	sd	s2,136(sp)
    800060e6:	e94e                	sd	s3,144(sp)
    800060e8:	ed52                	sd	s4,152(sp)
    800060ea:	f156                	sd	s5,160(sp)
    800060ec:	f55a                	sd	s6,168(sp)
    800060ee:	f95e                	sd	s7,176(sp)
    800060f0:	fd62                	sd	s8,184(sp)
    800060f2:	e1e6                	sd	s9,192(sp)
    800060f4:	e5ea                	sd	s10,200(sp)
    800060f6:	e9ee                	sd	s11,208(sp)
    800060f8:	edf2                	sd	t3,216(sp)
    800060fa:	f1f6                	sd	t4,224(sp)
    800060fc:	f5fa                	sd	t5,232(sp)
    800060fe:	f9fe                	sd	t6,240(sp)
    80006100:	d85fc0ef          	jal	ra,80002e84 <kerneltrap>
    80006104:	6082                	ld	ra,0(sp)
    80006106:	6122                	ld	sp,8(sp)
    80006108:	61c2                	ld	gp,16(sp)
    8000610a:	7282                	ld	t0,32(sp)
    8000610c:	7322                	ld	t1,40(sp)
    8000610e:	73c2                	ld	t2,48(sp)
    80006110:	7462                	ld	s0,56(sp)
    80006112:	6486                	ld	s1,64(sp)
    80006114:	6526                	ld	a0,72(sp)
    80006116:	65c6                	ld	a1,80(sp)
    80006118:	6666                	ld	a2,88(sp)
    8000611a:	7686                	ld	a3,96(sp)
    8000611c:	7726                	ld	a4,104(sp)
    8000611e:	77c6                	ld	a5,112(sp)
    80006120:	7866                	ld	a6,120(sp)
    80006122:	688a                	ld	a7,128(sp)
    80006124:	692a                	ld	s2,136(sp)
    80006126:	69ca                	ld	s3,144(sp)
    80006128:	6a6a                	ld	s4,152(sp)
    8000612a:	7a8a                	ld	s5,160(sp)
    8000612c:	7b2a                	ld	s6,168(sp)
    8000612e:	7bca                	ld	s7,176(sp)
    80006130:	7c6a                	ld	s8,184(sp)
    80006132:	6c8e                	ld	s9,192(sp)
    80006134:	6d2e                	ld	s10,200(sp)
    80006136:	6dce                	ld	s11,208(sp)
    80006138:	6e6e                	ld	t3,216(sp)
    8000613a:	7e8e                	ld	t4,224(sp)
    8000613c:	7f2e                	ld	t5,232(sp)
    8000613e:	7fce                	ld	t6,240(sp)
    80006140:	6111                	addi	sp,sp,256
    80006142:	10200073          	sret
    80006146:	00000013          	nop
    8000614a:	00000013          	nop
    8000614e:	0001                	nop

0000000080006150 <timervec>:
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	e10c                	sd	a1,0(a0)
    80006156:	e510                	sd	a2,8(a0)
    80006158:	e914                	sd	a3,16(a0)
    8000615a:	6d0c                	ld	a1,24(a0)
    8000615c:	7110                	ld	a2,32(a0)
    8000615e:	6194                	ld	a3,0(a1)
    80006160:	96b2                	add	a3,a3,a2
    80006162:	e194                	sd	a3,0(a1)
    80006164:	4589                	li	a1,2
    80006166:	14459073          	csrw	sip,a1
    8000616a:	6914                	ld	a3,16(a0)
    8000616c:	6510                	ld	a2,8(a0)
    8000616e:	610c                	ld	a1,0(a0)
    80006170:	34051573          	csrrw	a0,mscratch,a0
    80006174:	30200073          	mret
	...

000000008000617a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000617a:	1141                	addi	sp,sp,-16
    8000617c:	e422                	sd	s0,8(sp)
    8000617e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006180:	0c0007b7          	lui	a5,0xc000
    80006184:	4705                	li	a4,1
    80006186:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006188:	c3d8                	sw	a4,4(a5)
}
    8000618a:	6422                	ld	s0,8(sp)
    8000618c:	0141                	addi	sp,sp,16
    8000618e:	8082                	ret

0000000080006190 <plicinithart>:

void
plicinithart(void)
{
    80006190:	1141                	addi	sp,sp,-16
    80006192:	e406                	sd	ra,8(sp)
    80006194:	e022                	sd	s0,0(sp)
    80006196:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	b56080e7          	jalr	-1194(ra) # 80001cee <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061a0:	0085171b          	slliw	a4,a0,0x8
    800061a4:	0c0027b7          	lui	a5,0xc002
    800061a8:	97ba                	add	a5,a5,a4
    800061aa:	40200713          	li	a4,1026
    800061ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061b2:	00d5151b          	slliw	a0,a0,0xd
    800061b6:	0c2017b7          	lui	a5,0xc201
    800061ba:	953e                	add	a0,a0,a5
    800061bc:	00052023          	sw	zero,0(a0)
}
    800061c0:	60a2                	ld	ra,8(sp)
    800061c2:	6402                	ld	s0,0(sp)
    800061c4:	0141                	addi	sp,sp,16
    800061c6:	8082                	ret

00000000800061c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061c8:	1141                	addi	sp,sp,-16
    800061ca:	e406                	sd	ra,8(sp)
    800061cc:	e022                	sd	s0,0(sp)
    800061ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061d0:	ffffc097          	auipc	ra,0xffffc
    800061d4:	b1e080e7          	jalr	-1250(ra) # 80001cee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061d8:	00d5179b          	slliw	a5,a0,0xd
    800061dc:	0c201537          	lui	a0,0xc201
    800061e0:	953e                	add	a0,a0,a5
  return irq;
}
    800061e2:	4148                	lw	a0,4(a0)
    800061e4:	60a2                	ld	ra,8(sp)
    800061e6:	6402                	ld	s0,0(sp)
    800061e8:	0141                	addi	sp,sp,16
    800061ea:	8082                	ret

00000000800061ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ec:	1101                	addi	sp,sp,-32
    800061ee:	ec06                	sd	ra,24(sp)
    800061f0:	e822                	sd	s0,16(sp)
    800061f2:	e426                	sd	s1,8(sp)
    800061f4:	1000                	addi	s0,sp,32
    800061f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061f8:	ffffc097          	auipc	ra,0xffffc
    800061fc:	af6080e7          	jalr	-1290(ra) # 80001cee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006200:	00d5151b          	slliw	a0,a0,0xd
    80006204:	0c2017b7          	lui	a5,0xc201
    80006208:	97aa                	add	a5,a5,a0
    8000620a:	c3c4                	sw	s1,4(a5)
}
    8000620c:	60e2                	ld	ra,24(sp)
    8000620e:	6442                	ld	s0,16(sp)
    80006210:	64a2                	ld	s1,8(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret

0000000080006216 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006216:	1141                	addi	sp,sp,-16
    80006218:	e406                	sd	ra,8(sp)
    8000621a:	e022                	sd	s0,0(sp)
    8000621c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000621e:	479d                	li	a5,7
    80006220:	06a7c963          	blt	a5,a0,80006292 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006224:	0001d797          	auipc	a5,0x1d
    80006228:	ddc78793          	addi	a5,a5,-548 # 80023000 <disk>
    8000622c:	00a78733          	add	a4,a5,a0
    80006230:	6789                	lui	a5,0x2
    80006232:	97ba                	add	a5,a5,a4
    80006234:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006238:	e7ad                	bnez	a5,800062a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000623a:	00451793          	slli	a5,a0,0x4
    8000623e:	0001f717          	auipc	a4,0x1f
    80006242:	dc270713          	addi	a4,a4,-574 # 80025000 <disk+0x2000>
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000624e:	6314                	ld	a3,0(a4)
    80006250:	96be                	add	a3,a3,a5
    80006252:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006256:	6314                	ld	a3,0(a4)
    80006258:	96be                	add	a3,a3,a5
    8000625a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000625e:	6318                	ld	a4,0(a4)
    80006260:	97ba                	add	a5,a5,a4
    80006262:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006266:	0001d797          	auipc	a5,0x1d
    8000626a:	d9a78793          	addi	a5,a5,-614 # 80023000 <disk>
    8000626e:	97aa                	add	a5,a5,a0
    80006270:	6509                	lui	a0,0x2
    80006272:	953e                	add	a0,a0,a5
    80006274:	4785                	li	a5,1
    80006276:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000627a:	0001f517          	auipc	a0,0x1f
    8000627e:	d9e50513          	addi	a0,a0,-610 # 80025018 <disk+0x2018>
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	460080e7          	jalr	1120(ra) # 800026e2 <wakeup>
}
    8000628a:	60a2                	ld	ra,8(sp)
    8000628c:	6402                	ld	s0,0(sp)
    8000628e:	0141                	addi	sp,sp,16
    80006290:	8082                	ret
    panic("free_desc 1");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	6b650513          	addi	a0,a0,1718 # 80008948 <syscalls+0x330>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a4080e7          	jalr	676(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	6b650513          	addi	a0,a0,1718 # 80008958 <syscalls+0x340>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	294080e7          	jalr	660(ra) # 8000053e <panic>

00000000800062b2 <virtio_disk_init>:
{
    800062b2:	1101                	addi	sp,sp,-32
    800062b4:	ec06                	sd	ra,24(sp)
    800062b6:	e822                	sd	s0,16(sp)
    800062b8:	e426                	sd	s1,8(sp)
    800062ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062bc:	00002597          	auipc	a1,0x2
    800062c0:	6ac58593          	addi	a1,a1,1708 # 80008968 <syscalls+0x350>
    800062c4:	0001f517          	auipc	a0,0x1f
    800062c8:	e6450513          	addi	a0,a0,-412 # 80025128 <disk+0x2128>
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	888080e7          	jalr	-1912(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062d4:	100017b7          	lui	a5,0x10001
    800062d8:	4398                	lw	a4,0(a5)
    800062da:	2701                	sext.w	a4,a4
    800062dc:	747277b7          	lui	a5,0x74727
    800062e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062e4:	0ef71163          	bne	a4,a5,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062e8:	100017b7          	lui	a5,0x10001
    800062ec:	43dc                	lw	a5,4(a5)
    800062ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062f0:	4705                	li	a4,1
    800062f2:	0ce79a63          	bne	a5,a4,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062f6:	100017b7          	lui	a5,0x10001
    800062fa:	479c                	lw	a5,8(a5)
    800062fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062fe:	4709                	li	a4,2
    80006300:	0ce79363          	bne	a5,a4,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006304:	100017b7          	lui	a5,0x10001
    80006308:	47d8                	lw	a4,12(a5)
    8000630a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000630c:	554d47b7          	lui	a5,0x554d4
    80006310:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006314:	0af71963          	bne	a4,a5,800063c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006318:	100017b7          	lui	a5,0x10001
    8000631c:	4705                	li	a4,1
    8000631e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006320:	470d                	li	a4,3
    80006322:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006324:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006326:	c7ffe737          	lui	a4,0xc7ffe
    8000632a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000632e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006330:	2701                	sext.w	a4,a4
    80006332:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006334:	472d                	li	a4,11
    80006336:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006338:	473d                	li	a4,15
    8000633a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000633c:	6705                	lui	a4,0x1
    8000633e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006340:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006344:	5bdc                	lw	a5,52(a5)
    80006346:	2781                	sext.w	a5,a5
  if(max == 0)
    80006348:	c7d9                	beqz	a5,800063d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000634a:	471d                	li	a4,7
    8000634c:	08f77d63          	bgeu	a4,a5,800063e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006350:	100014b7          	lui	s1,0x10001
    80006354:	47a1                	li	a5,8
    80006356:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006358:	6609                	lui	a2,0x2
    8000635a:	4581                	li	a1,0
    8000635c:	0001d517          	auipc	a0,0x1d
    80006360:	ca450513          	addi	a0,a0,-860 # 80023000 <disk>
    80006364:	ffffb097          	auipc	ra,0xffffb
    80006368:	97c080e7          	jalr	-1668(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000636c:	0001d717          	auipc	a4,0x1d
    80006370:	c9470713          	addi	a4,a4,-876 # 80023000 <disk>
    80006374:	00c75793          	srli	a5,a4,0xc
    80006378:	2781                	sext.w	a5,a5
    8000637a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000637c:	0001f797          	auipc	a5,0x1f
    80006380:	c8478793          	addi	a5,a5,-892 # 80025000 <disk+0x2000>
    80006384:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006386:	0001d717          	auipc	a4,0x1d
    8000638a:	cfa70713          	addi	a4,a4,-774 # 80023080 <disk+0x80>
    8000638e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006390:	0001e717          	auipc	a4,0x1e
    80006394:	c7070713          	addi	a4,a4,-912 # 80024000 <disk+0x1000>
    80006398:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000639a:	4705                	li	a4,1
    8000639c:	00e78c23          	sb	a4,24(a5)
    800063a0:	00e78ca3          	sb	a4,25(a5)
    800063a4:	00e78d23          	sb	a4,26(a5)
    800063a8:	00e78da3          	sb	a4,27(a5)
    800063ac:	00e78e23          	sb	a4,28(a5)
    800063b0:	00e78ea3          	sb	a4,29(a5)
    800063b4:	00e78f23          	sb	a4,30(a5)
    800063b8:	00e78fa3          	sb	a4,31(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
    panic("could not find virtio disk");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	5b250513          	addi	a0,a0,1458 # 80008978 <syscalls+0x360>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	5c250513          	addi	a0,a0,1474 # 80008998 <syscalls+0x380>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	5d250513          	addi	a0,a0,1490 # 800089b8 <syscalls+0x3a0>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	150080e7          	jalr	336(ra) # 8000053e <panic>

00000000800063f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063f6:	7159                	addi	sp,sp,-112
    800063f8:	f486                	sd	ra,104(sp)
    800063fa:	f0a2                	sd	s0,96(sp)
    800063fc:	eca6                	sd	s1,88(sp)
    800063fe:	e8ca                	sd	s2,80(sp)
    80006400:	e4ce                	sd	s3,72(sp)
    80006402:	e0d2                	sd	s4,64(sp)
    80006404:	fc56                	sd	s5,56(sp)
    80006406:	f85a                	sd	s6,48(sp)
    80006408:	f45e                	sd	s7,40(sp)
    8000640a:	f062                	sd	s8,32(sp)
    8000640c:	ec66                	sd	s9,24(sp)
    8000640e:	e86a                	sd	s10,16(sp)
    80006410:	1880                	addi	s0,sp,112
    80006412:	892a                	mv	s2,a0
    80006414:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006416:	00c52c83          	lw	s9,12(a0)
    8000641a:	001c9c9b          	slliw	s9,s9,0x1
    8000641e:	1c82                	slli	s9,s9,0x20
    80006420:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006424:	0001f517          	auipc	a0,0x1f
    80006428:	d0450513          	addi	a0,a0,-764 # 80025128 <disk+0x2128>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	7b8080e7          	jalr	1976(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006434:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006436:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006438:	0001db97          	auipc	s7,0x1d
    8000643c:	bc8b8b93          	addi	s7,s7,-1080 # 80023000 <disk>
    80006440:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006442:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006444:	8a4e                	mv	s4,s3
    80006446:	a051                	j	800064ca <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006448:	00fb86b3          	add	a3,s7,a5
    8000644c:	96da                	add	a3,a3,s6
    8000644e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006452:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006454:	0207c563          	bltz	a5,8000647e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006458:	2485                	addiw	s1,s1,1
    8000645a:	0711                	addi	a4,a4,4
    8000645c:	25548063          	beq	s1,s5,8000669c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006460:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006462:	0001f697          	auipc	a3,0x1f
    80006466:	bb668693          	addi	a3,a3,-1098 # 80025018 <disk+0x2018>
    8000646a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000646c:	0006c583          	lbu	a1,0(a3)
    80006470:	fde1                	bnez	a1,80006448 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006472:	2785                	addiw	a5,a5,1
    80006474:	0685                	addi	a3,a3,1
    80006476:	ff879be3          	bne	a5,s8,8000646c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000647a:	57fd                	li	a5,-1
    8000647c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000647e:	02905a63          	blez	s1,800064b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006482:	f9042503          	lw	a0,-112(s0)
    80006486:	00000097          	auipc	ra,0x0
    8000648a:	d90080e7          	jalr	-624(ra) # 80006216 <free_desc>
      for(int j = 0; j < i; j++)
    8000648e:	4785                	li	a5,1
    80006490:	0297d163          	bge	a5,s1,800064b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006494:	f9442503          	lw	a0,-108(s0)
    80006498:	00000097          	auipc	ra,0x0
    8000649c:	d7e080e7          	jalr	-642(ra) # 80006216 <free_desc>
      for(int j = 0; j < i; j++)
    800064a0:	4789                	li	a5,2
    800064a2:	0097d863          	bge	a5,s1,800064b2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064a6:	f9842503          	lw	a0,-104(s0)
    800064aa:	00000097          	auipc	ra,0x0
    800064ae:	d6c080e7          	jalr	-660(ra) # 80006216 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064b2:	0001f597          	auipc	a1,0x1f
    800064b6:	c7658593          	addi	a1,a1,-906 # 80025128 <disk+0x2128>
    800064ba:	0001f517          	auipc	a0,0x1f
    800064be:	b5e50513          	addi	a0,a0,-1186 # 80025018 <disk+0x2018>
    800064c2:	ffffc097          	auipc	ra,0xffffc
    800064c6:	06e080e7          	jalr	110(ra) # 80002530 <sleep>
  for(int i = 0; i < 3; i++){
    800064ca:	f9040713          	addi	a4,s0,-112
    800064ce:	84ce                	mv	s1,s3
    800064d0:	bf41                	j	80006460 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064d2:	20058713          	addi	a4,a1,512
    800064d6:	00471693          	slli	a3,a4,0x4
    800064da:	0001d717          	auipc	a4,0x1d
    800064de:	b2670713          	addi	a4,a4,-1242 # 80023000 <disk>
    800064e2:	9736                	add	a4,a4,a3
    800064e4:	4685                	li	a3,1
    800064e6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064ea:	20058713          	addi	a4,a1,512
    800064ee:	00471693          	slli	a3,a4,0x4
    800064f2:	0001d717          	auipc	a4,0x1d
    800064f6:	b0e70713          	addi	a4,a4,-1266 # 80023000 <disk>
    800064fa:	9736                	add	a4,a4,a3
    800064fc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006500:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006504:	7679                	lui	a2,0xffffe
    80006506:	963e                	add	a2,a2,a5
    80006508:	0001f697          	auipc	a3,0x1f
    8000650c:	af868693          	addi	a3,a3,-1288 # 80025000 <disk+0x2000>
    80006510:	6298                	ld	a4,0(a3)
    80006512:	9732                	add	a4,a4,a2
    80006514:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006516:	6298                	ld	a4,0(a3)
    80006518:	9732                	add	a4,a4,a2
    8000651a:	4541                	li	a0,16
    8000651c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000651e:	6298                	ld	a4,0(a3)
    80006520:	9732                	add	a4,a4,a2
    80006522:	4505                	li	a0,1
    80006524:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006528:	f9442703          	lw	a4,-108(s0)
    8000652c:	6288                	ld	a0,0(a3)
    8000652e:	962a                	add	a2,a2,a0
    80006530:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006534:	0712                	slli	a4,a4,0x4
    80006536:	6290                	ld	a2,0(a3)
    80006538:	963a                	add	a2,a2,a4
    8000653a:	05890513          	addi	a0,s2,88
    8000653e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006540:	6294                	ld	a3,0(a3)
    80006542:	96ba                	add	a3,a3,a4
    80006544:	40000613          	li	a2,1024
    80006548:	c690                	sw	a2,8(a3)
  if(write)
    8000654a:	140d0063          	beqz	s10,8000668a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000654e:	0001f697          	auipc	a3,0x1f
    80006552:	ab26b683          	ld	a3,-1358(a3) # 80025000 <disk+0x2000>
    80006556:	96ba                	add	a3,a3,a4
    80006558:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000655c:	0001d817          	auipc	a6,0x1d
    80006560:	aa480813          	addi	a6,a6,-1372 # 80023000 <disk>
    80006564:	0001f517          	auipc	a0,0x1f
    80006568:	a9c50513          	addi	a0,a0,-1380 # 80025000 <disk+0x2000>
    8000656c:	6114                	ld	a3,0(a0)
    8000656e:	96ba                	add	a3,a3,a4
    80006570:	00c6d603          	lhu	a2,12(a3)
    80006574:	00166613          	ori	a2,a2,1
    80006578:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000657c:	f9842683          	lw	a3,-104(s0)
    80006580:	6110                	ld	a2,0(a0)
    80006582:	9732                	add	a4,a4,a2
    80006584:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006588:	20058613          	addi	a2,a1,512
    8000658c:	0612                	slli	a2,a2,0x4
    8000658e:	9642                	add	a2,a2,a6
    80006590:	577d                	li	a4,-1
    80006592:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006596:	00469713          	slli	a4,a3,0x4
    8000659a:	6114                	ld	a3,0(a0)
    8000659c:	96ba                	add	a3,a3,a4
    8000659e:	03078793          	addi	a5,a5,48
    800065a2:	97c2                	add	a5,a5,a6
    800065a4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065a6:	611c                	ld	a5,0(a0)
    800065a8:	97ba                	add	a5,a5,a4
    800065aa:	4685                	li	a3,1
    800065ac:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065ae:	611c                	ld	a5,0(a0)
    800065b0:	97ba                	add	a5,a5,a4
    800065b2:	4809                	li	a6,2
    800065b4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065b8:	611c                	ld	a5,0(a0)
    800065ba:	973e                	add	a4,a4,a5
    800065bc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065c0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065c4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065c8:	6518                	ld	a4,8(a0)
    800065ca:	00275783          	lhu	a5,2(a4)
    800065ce:	8b9d                	andi	a5,a5,7
    800065d0:	0786                	slli	a5,a5,0x1
    800065d2:	97ba                	add	a5,a5,a4
    800065d4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065d8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065dc:	6518                	ld	a4,8(a0)
    800065de:	00275783          	lhu	a5,2(a4)
    800065e2:	2785                	addiw	a5,a5,1
    800065e4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065e8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065ec:	100017b7          	lui	a5,0x10001
    800065f0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065f4:	00492703          	lw	a4,4(s2)
    800065f8:	4785                	li	a5,1
    800065fa:	02f71163          	bne	a4,a5,8000661c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065fe:	0001f997          	auipc	s3,0x1f
    80006602:	b2a98993          	addi	s3,s3,-1238 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006606:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006608:	85ce                	mv	a1,s3
    8000660a:	854a                	mv	a0,s2
    8000660c:	ffffc097          	auipc	ra,0xffffc
    80006610:	f24080e7          	jalr	-220(ra) # 80002530 <sleep>
  while(b->disk == 1) {
    80006614:	00492783          	lw	a5,4(s2)
    80006618:	fe9788e3          	beq	a5,s1,80006608 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000661c:	f9042903          	lw	s2,-112(s0)
    80006620:	20090793          	addi	a5,s2,512
    80006624:	00479713          	slli	a4,a5,0x4
    80006628:	0001d797          	auipc	a5,0x1d
    8000662c:	9d878793          	addi	a5,a5,-1576 # 80023000 <disk>
    80006630:	97ba                	add	a5,a5,a4
    80006632:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006636:	0001f997          	auipc	s3,0x1f
    8000663a:	9ca98993          	addi	s3,s3,-1590 # 80025000 <disk+0x2000>
    8000663e:	00491713          	slli	a4,s2,0x4
    80006642:	0009b783          	ld	a5,0(s3)
    80006646:	97ba                	add	a5,a5,a4
    80006648:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000664c:	854a                	mv	a0,s2
    8000664e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006652:	00000097          	auipc	ra,0x0
    80006656:	bc4080e7          	jalr	-1084(ra) # 80006216 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000665a:	8885                	andi	s1,s1,1
    8000665c:	f0ed                	bnez	s1,8000663e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000665e:	0001f517          	auipc	a0,0x1f
    80006662:	aca50513          	addi	a0,a0,-1334 # 80025128 <disk+0x2128>
    80006666:	ffffa097          	auipc	ra,0xffffa
    8000666a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
}
    8000666e:	70a6                	ld	ra,104(sp)
    80006670:	7406                	ld	s0,96(sp)
    80006672:	64e6                	ld	s1,88(sp)
    80006674:	6946                	ld	s2,80(sp)
    80006676:	69a6                	ld	s3,72(sp)
    80006678:	6a06                	ld	s4,64(sp)
    8000667a:	7ae2                	ld	s5,56(sp)
    8000667c:	7b42                	ld	s6,48(sp)
    8000667e:	7ba2                	ld	s7,40(sp)
    80006680:	7c02                	ld	s8,32(sp)
    80006682:	6ce2                	ld	s9,24(sp)
    80006684:	6d42                	ld	s10,16(sp)
    80006686:	6165                	addi	sp,sp,112
    80006688:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000668a:	0001f697          	auipc	a3,0x1f
    8000668e:	9766b683          	ld	a3,-1674(a3) # 80025000 <disk+0x2000>
    80006692:	96ba                	add	a3,a3,a4
    80006694:	4609                	li	a2,2
    80006696:	00c69623          	sh	a2,12(a3)
    8000669a:	b5c9                	j	8000655c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000669c:	f9042583          	lw	a1,-112(s0)
    800066a0:	20058793          	addi	a5,a1,512
    800066a4:	0792                	slli	a5,a5,0x4
    800066a6:	0001d517          	auipc	a0,0x1d
    800066aa:	a0250513          	addi	a0,a0,-1534 # 800230a8 <disk+0xa8>
    800066ae:	953e                	add	a0,a0,a5
  if(write)
    800066b0:	e20d11e3          	bnez	s10,800064d2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066b4:	20058713          	addi	a4,a1,512
    800066b8:	00471693          	slli	a3,a4,0x4
    800066bc:	0001d717          	auipc	a4,0x1d
    800066c0:	94470713          	addi	a4,a4,-1724 # 80023000 <disk>
    800066c4:	9736                	add	a4,a4,a3
    800066c6:	0a072423          	sw	zero,168(a4)
    800066ca:	b505                	j	800064ea <virtio_disk_rw+0xf4>

00000000800066cc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066cc:	1101                	addi	sp,sp,-32
    800066ce:	ec06                	sd	ra,24(sp)
    800066d0:	e822                	sd	s0,16(sp)
    800066d2:	e426                	sd	s1,8(sp)
    800066d4:	e04a                	sd	s2,0(sp)
    800066d6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066d8:	0001f517          	auipc	a0,0x1f
    800066dc:	a5050513          	addi	a0,a0,-1456 # 80025128 <disk+0x2128>
    800066e0:	ffffa097          	auipc	ra,0xffffa
    800066e4:	504080e7          	jalr	1284(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066e8:	10001737          	lui	a4,0x10001
    800066ec:	533c                	lw	a5,96(a4)
    800066ee:	8b8d                	andi	a5,a5,3
    800066f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066f6:	0001f797          	auipc	a5,0x1f
    800066fa:	90a78793          	addi	a5,a5,-1782 # 80025000 <disk+0x2000>
    800066fe:	6b94                	ld	a3,16(a5)
    80006700:	0207d703          	lhu	a4,32(a5)
    80006704:	0026d783          	lhu	a5,2(a3)
    80006708:	06f70163          	beq	a4,a5,8000676a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000670c:	0001d917          	auipc	s2,0x1d
    80006710:	8f490913          	addi	s2,s2,-1804 # 80023000 <disk>
    80006714:	0001f497          	auipc	s1,0x1f
    80006718:	8ec48493          	addi	s1,s1,-1812 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000671c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006720:	6898                	ld	a4,16(s1)
    80006722:	0204d783          	lhu	a5,32(s1)
    80006726:	8b9d                	andi	a5,a5,7
    80006728:	078e                	slli	a5,a5,0x3
    8000672a:	97ba                	add	a5,a5,a4
    8000672c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000672e:	20078713          	addi	a4,a5,512
    80006732:	0712                	slli	a4,a4,0x4
    80006734:	974a                	add	a4,a4,s2
    80006736:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000673a:	e731                	bnez	a4,80006786 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000673c:	20078793          	addi	a5,a5,512
    80006740:	0792                	slli	a5,a5,0x4
    80006742:	97ca                	add	a5,a5,s2
    80006744:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006746:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000674a:	ffffc097          	auipc	ra,0xffffc
    8000674e:	f98080e7          	jalr	-104(ra) # 800026e2 <wakeup>

    disk.used_idx += 1;
    80006752:	0204d783          	lhu	a5,32(s1)
    80006756:	2785                	addiw	a5,a5,1
    80006758:	17c2                	slli	a5,a5,0x30
    8000675a:	93c1                	srli	a5,a5,0x30
    8000675c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006760:	6898                	ld	a4,16(s1)
    80006762:	00275703          	lhu	a4,2(a4)
    80006766:	faf71be3          	bne	a4,a5,8000671c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000676a:	0001f517          	auipc	a0,0x1f
    8000676e:	9be50513          	addi	a0,a0,-1602 # 80025128 <disk+0x2128>
    80006772:	ffffa097          	auipc	ra,0xffffa
    80006776:	526080e7          	jalr	1318(ra) # 80000c98 <release>
}
    8000677a:	60e2                	ld	ra,24(sp)
    8000677c:	6442                	ld	s0,16(sp)
    8000677e:	64a2                	ld	s1,8(sp)
    80006780:	6902                	ld	s2,0(sp)
    80006782:	6105                	addi	sp,sp,32
    80006784:	8082                	ret
      panic("virtio_disk_intr status");
    80006786:	00002517          	auipc	a0,0x2
    8000678a:	25250513          	addi	a0,a0,594 # 800089d8 <syscalls+0x3c0>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>

0000000080006796 <cas>:
    80006796:	100522af          	lr.w	t0,(a0)
    8000679a:	00b29563          	bne	t0,a1,800067a4 <fail>
    8000679e:	18c5252f          	sc.w	a0,a2,(a0)
    800067a2:	8082                	ret

00000000800067a4 <fail>:
    800067a4:	4505                	li	a0,1
    800067a6:	8082                	ret
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
