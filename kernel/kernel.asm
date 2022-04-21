
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a1013103          	ld	sp,-1520(sp) # 80008a10 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	20c78793          	addi	a5,a5,524 # 80006270 <timervec>
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
    80000130:	924080e7          	jalr	-1756(ra) # 80002a50 <either_copyin>
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
    800001c8:	9ee080e7          	jalr	-1554(ra) # 80001bb2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	420080e7          	jalr	1056(ra) # 800025f4 <sleep>
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
    80000214:	7ea080e7          	jalr	2026(ra) # 800029fa <either_copyout>
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
    800002f6:	7b4080e7          	jalr	1972(ra) # 80002aa6 <procdump>
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
    8000044a:	354080e7          	jalr	852(ra) # 8000279a <wakeup>
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
    80000570:	dbc50513          	addi	a0,a0,-580 # 80008328 <digits+0x2e8>
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
    800008a4:	efa080e7          	jalr	-262(ra) # 8000279a <wakeup>
    
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
    80000930:	cc8080e7          	jalr	-824(ra) # 800025f4 <sleep>
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
    80000b82:	018080e7          	jalr	24(ra) # 80001b96 <mycpu>
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
    80000bb4:	fe6080e7          	jalr	-26(ra) # 80001b96 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	fda080e7          	jalr	-38(ra) # 80001b96 <mycpu>
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
    80000bd8:	fc2080e7          	jalr	-62(ra) # 80001b96 <mycpu>
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
    80000c18:	f82080e7          	jalr	-126(ra) # 80001b96 <mycpu>
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
    80000c44:	f56080e7          	jalr	-170(ra) # 80001b96 <mycpu>
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
    80000e9a:	cf0080e7          	jalr	-784(ra) # 80001b86 <cpuid>
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
    80000eb6:	cd4080e7          	jalr	-812(ra) # 80001b86 <cpuid>
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
    80000ed8:	e24080e7          	jalr	-476(ra) # 80002cf8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	3d4080e7          	jalr	980(ra) # 800062b0 <plicinithart>
    
  }
 

  scheduler();      
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	5c8080e7          	jalr	1480(ra) # 800024ac <scheduler>
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
    80000f08:	42450513          	addi	a0,a0,1060 # 80008328 <digits+0x2e8>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	40450513          	addi	a0,a0,1028 # 80008328 <digits+0x2e8>
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
    80000f50:	b7a080e7          	jalr	-1158(ra) # 80001ac6 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	d7c080e7          	jalr	-644(ra) # 80002cd0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	d9c080e7          	jalr	-612(ra) # 80002cf8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	336080e7          	jalr	822(ra) # 8000629a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	344080e7          	jalr	836(ra) # 800062b0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	52a080e7          	jalr	1322(ra) # 8000349e <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	bba080e7          	jalr	-1094(ra) # 80003b36 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	b64080e7          	jalr	-1180(ra) # 80004ae8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	446080e7          	jalr	1094(ra) # 800063d2 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	f16080e7          	jalr	-234(ra) # 80001eaa <userinit>
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
    8000124c:	7e8080e7          	jalr	2024(ra) # 80001a30 <proc_mapstacks>
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

0000000080001846 <check_name>:

int running_procs = 0;

// 1 = sh or init, 0 = else
int check_name(char name[])
{
    80001846:	1141                	addi	sp,sp,-16
    80001848:	e422                	sd	s0,8(sp)
    8000184a:	0800                	addi	s0,sp,16
    8000184c:	87aa                	mv	a5,a0
  if (name[0] == 105 && name[1] == 110 && name[2] == 105 && name[3] == 116)
    8000184e:	00054703          	lbu	a4,0(a0)
    80001852:	06900693          	li	a3,105
    80001856:	02d70263          	beq	a4,a3,8000187a <check_name+0x34>
      }
      return 1;
    }
  }

  if (name[0] == 115 && name[1] == 104)
    8000185a:	07300693          	li	a3,115
        return 0;
      }
      return 1;
    }
  }
  return 0;
    8000185e:	4501                	li	a0,0
  if (name[0] == 115 && name[1] == 104)
    80001860:	02d71463          	bne	a4,a3,80001888 <check_name+0x42>
    80001864:	0017c683          	lbu	a3,1(a5)
    80001868:	06800713          	li	a4,104
    8000186c:	00e69e63          	bne	a3,a4,80001888 <check_name+0x42>
      if (name[i] != 0)
    80001870:	0027c503          	lbu	a0,2(a5)
        return 0;
    80001874:	00153513          	seqz	a0,a0
    80001878:	a801                	j	80001888 <check_name+0x42>
  if (name[0] == 105 && name[1] == 110 && name[2] == 105 && name[3] == 116)
    8000187a:	00154683          	lbu	a3,1(a0)
    8000187e:	06e00713          	li	a4,110
  return 0;
    80001882:	4501                	li	a0,0
  if (name[0] == 105 && name[1] == 110 && name[2] == 105 && name[3] == 116)
    80001884:	00e68563          	beq	a3,a4,8000188e <check_name+0x48>
}
    80001888:	6422                	ld	s0,8(sp)
    8000188a:	0141                	addi	sp,sp,16
    8000188c:	8082                	ret
  if (name[0] == 105 && name[1] == 110 && name[2] == 105 && name[3] == 116)
    8000188e:	0027c683          	lbu	a3,2(a5)
    80001892:	06900713          	li	a4,105
    80001896:	fee699e3          	bne	a3,a4,80001888 <check_name+0x42>
    8000189a:	0037c683          	lbu	a3,3(a5)
    8000189e:	07400713          	li	a4,116
    800018a2:	fee693e3          	bne	a3,a4,80001888 <check_name+0x42>
      if (name[i] != 0)
    800018a6:	0047c503          	lbu	a0,4(a5)
        return 0;
    800018aa:	00153513          	seqz	a0,a0
    800018ae:	bfe9                	j	80001888 <check_name+0x42>

00000000800018b0 <print_stats>:
void print_stats (void)
{
    800018b0:	1141                	addi	sp,sp,-16
    800018b2:	e406                	sd	ra,8(sp)
    800018b4:	e022                	sd	s0,0(sp)
    800018b6:	0800                	addi	s0,sp,16
  printf("program_time:%d  \ncpu_utilization:%d precent \nrunning_processes_mean:%d  \nrunnable_processes_mean:%d  \nsleeping_processes_mean:%d\n\n",program_time,cpu_utilization,running_processes_mean,runnable_processes_mean,sleeping_processes_mean);
    800018b8:	00007797          	auipc	a5,0x7
    800018bc:	77c7a783          	lw	a5,1916(a5) # 80009034 <sleeping_processes_mean>
    800018c0:	00007717          	auipc	a4,0x7
    800018c4:	76c72703          	lw	a4,1900(a4) # 8000902c <runnable_processes_mean>
    800018c8:	00007697          	auipc	a3,0x7
    800018cc:	7686a683          	lw	a3,1896(a3) # 80009030 <running_processes_mean>
    800018d0:	00007617          	auipc	a2,0x7
    800018d4:	76862603          	lw	a2,1896(a2) # 80009038 <cpu_utilization>
    800018d8:	00007597          	auipc	a1,0x7
    800018dc:	7685a583          	lw	a1,1896(a1) # 80009040 <program_time>
    800018e0:	00007517          	auipc	a0,0x7
    800018e4:	8f850513          	addi	a0,a0,-1800 # 800081d8 <digits+0x198>
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	ca0080e7          	jalr	-864(ra) # 80000588 <printf>
}
    800018f0:	60a2                	ld	ra,8(sp)
    800018f2:	6402                	ld	s0,0(sp)
    800018f4:	0141                	addi	sp,sp,16
    800018f6:	8082                	ret

00000000800018f8 <update_time>:

// updates sleep/runnable/running times
void update_time(struct proc *p)
{
    800018f8:	1141                	addi	sp,sp,-16
    800018fa:	e422                	sd	s0,8(sp)
    800018fc:	0800                	addi	s0,sp,16
   //if (check_name(p->name) != 0)
   //{
      if (p->state == RUNNABLE)
    800018fe:	4d1c                	lw	a5,24(a0)
    80001900:	470d                	li	a4,3
    80001902:	00e78f63          	beq	a5,a4,80001920 <update_time+0x28>
      {
        p->runnable_time = p->runnable_time + (ticks - p->counter);
      }
      if (p->state == RUNNING)
    80001906:	4711                	li	a4,4
    80001908:	02e79863          	bne	a5,a4,80001938 <update_time+0x40>
      {
        p->running_time = p->running_time + (ticks - p->counter);
    8000190c:	457c                	lw	a5,76(a0)
    8000190e:	00007717          	auipc	a4,0x7
    80001912:	74a72703          	lw	a4,1866(a4) # 80009058 <ticks>
    80001916:	9fb9                	addw	a5,a5,a4
    80001918:	4938                	lw	a4,80(a0)
    8000191a:	9f99                	subw	a5,a5,a4
    8000191c:	c57c                	sw	a5,76(a0)
      }
      if (p->state == SLEEPING)
    8000191e:	a811                	j	80001932 <update_time+0x3a>
        p->runnable_time = p->runnable_time + (ticks - p->counter);
    80001920:	453c                	lw	a5,72(a0)
    80001922:	00007717          	auipc	a4,0x7
    80001926:	73672703          	lw	a4,1846(a4) # 80009058 <ticks>
    8000192a:	9fb9                	addw	a5,a5,a4
    8000192c:	4938                	lw	a4,80(a0)
    8000192e:	9f99                	subw	a5,a5,a4
    80001930:	c53c                	sw	a5,72(a0)
      {
       // printf("SLEEP UPDATE: ticks:%d counter:%d\n",ticks,p->counter);
        p->sleep_time = p->sleep_time + (ticks - p->counter);
      }
   //}
 }
    80001932:	6422                	ld	s0,8(sp)
    80001934:	0141                	addi	sp,sp,16
    80001936:	8082                	ret
      if (p->state == SLEEPING)
    80001938:	4709                	li	a4,2
    8000193a:	fee79ce3          	bne	a5,a4,80001932 <update_time+0x3a>
        p->sleep_time = p->sleep_time + (ticks - p->counter);
    8000193e:	417c                	lw	a5,68(a0)
    80001940:	00007717          	auipc	a4,0x7
    80001944:	71872703          	lw	a4,1816(a4) # 80009058 <ticks>
    80001948:	9fb9                	addw	a5,a5,a4
    8000194a:	4938                	lw	a4,80(a0)
    8000194c:	9f99                	subw	a5,a5,a4
    8000194e:	c17c                	sw	a5,68(a0)
 }
    80001950:	b7cd                	j	80001932 <update_time+0x3a>

0000000080001952 <update_time_mean>:

void update_time_mean(struct proc *p)
{
    80001952:	7179                	addi	sp,sp,-48
    80001954:	f406                	sd	ra,40(sp)
    80001956:	f022                	sd	s0,32(sp)
    80001958:	ec26                	sd	s1,24(sp)
    8000195a:	e84a                	sd	s2,16(sp)
    8000195c:	e44e                	sd	s3,8(sp)
    8000195e:	1800                	addi	s0,sp,48
    80001960:	84aa                	mv	s1,a0
  printf("UPDATE IN PROGRESS  %d\n", ticks - start_time);
    80001962:	00007997          	auipc	s3,0x7
    80001966:	6f698993          	addi	s3,s3,1782 # 80009058 <ticks>
    8000196a:	00007917          	auipc	s2,0x7
    8000196e:	6d290913          	addi	s2,s2,1746 # 8000903c <start_time>
    80001972:	0009a583          	lw	a1,0(s3)
    80001976:	00092783          	lw	a5,0(s2)
    8000197a:	9d9d                	subw	a1,a1,a5
    8000197c:	00007517          	auipc	a0,0x7
    80001980:	8e450513          	addi	a0,a0,-1820 # 80008260 <digits+0x220>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	c04080e7          	jalr	-1020(ra) # 80000588 <printf>
  update_time(p);
    8000198c:	8526                	mv	a0,s1
    8000198e:	00000097          	auipc	ra,0x0
    80001992:	f6a080e7          	jalr	-150(ra) # 800018f8 <update_time>
  program_time = program_time + p->running_time;
    80001996:	44e8                	lw	a0,76(s1)
    80001998:	00007717          	auipc	a4,0x7
    8000199c:	6a870713          	addi	a4,a4,1704 # 80009040 <program_time>
    800019a0:	431c                	lw	a5,0(a4)
    800019a2:	00a786bb          	addw	a3,a5,a0
    800019a6:	c314                	sw	a3,0(a4)
  cpu_utilization = (program_time* 100) / (ticks - start_time);
    800019a8:	06400793          	li	a5,100
    800019ac:	02d787bb          	mulw	a5,a5,a3
    800019b0:	0009a683          	lw	a3,0(s3)
    800019b4:	00092703          	lw	a4,0(s2)
    800019b8:	9e99                	subw	a3,a3,a4
    800019ba:	02d7d7bb          	divuw	a5,a5,a3
    800019be:	00007717          	auipc	a4,0x7
    800019c2:	66f72d23          	sw	a5,1658(a4) # 80009038 <cpu_utilization>
  running_processes_mean = ((running_processes_mean * running_procs) + p->running_time) / (running_procs + 1);
    800019c6:	00007597          	auipc	a1,0x7
    800019ca:	66258593          	addi	a1,a1,1634 # 80009028 <running_procs>
    800019ce:	4190                	lw	a2,0(a1)
    800019d0:	0016069b          	addiw	a3,a2,1
    800019d4:	00007797          	auipc	a5,0x7
    800019d8:	65c78793          	addi	a5,a5,1628 # 80009030 <running_processes_mean>
    800019dc:	4398                	lw	a4,0(a5)
    800019de:	02c7073b          	mulw	a4,a4,a2
    800019e2:	9f29                	addw	a4,a4,a0
    800019e4:	02d7573b          	divuw	a4,a4,a3
    800019e8:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * running_procs) + p->runnable_time) / (running_procs + 1);
    800019ea:	44a8                	lw	a0,72(s1)
    800019ec:	00007797          	auipc	a5,0x7
    800019f0:	64078793          	addi	a5,a5,1600 # 8000902c <runnable_processes_mean>
    800019f4:	4398                	lw	a4,0(a5)
    800019f6:	02c7073b          	mulw	a4,a4,a2
    800019fa:	9f29                	addw	a4,a4,a0
    800019fc:	02d7573b          	divuw	a4,a4,a3
    80001a00:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ((sleeping_processes_mean * running_procs) + p->runnable_time) / (running_procs + 1);
    80001a02:	00007717          	auipc	a4,0x7
    80001a06:	63270713          	addi	a4,a4,1586 # 80009034 <sleeping_processes_mean>
    80001a0a:	431c                	lw	a5,0(a4)
    80001a0c:	02c787bb          	mulw	a5,a5,a2
    80001a10:	9fa9                	addw	a5,a5,a0
    80001a12:	02d7d7bb          	divuw	a5,a5,a3
    80001a16:	c31c                	sw	a5,0(a4)
  running_procs = running_procs + 1;
    80001a18:	c194                	sw	a3,0(a1)
  print_stats();
    80001a1a:	00000097          	auipc	ra,0x0
    80001a1e:	e96080e7          	jalr	-362(ra) # 800018b0 <print_stats>
}
    80001a22:	70a2                	ld	ra,40(sp)
    80001a24:	7402                	ld	s0,32(sp)
    80001a26:	64e2                	ld	s1,24(sp)
    80001a28:	6942                	ld	s2,16(sp)
    80001a2a:	69a2                	ld	s3,8(sp)
    80001a2c:	6145                	addi	sp,sp,48
    80001a2e:	8082                	ret

0000000080001a30 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a30:	7139                	addi	sp,sp,-64
    80001a32:	fc06                	sd	ra,56(sp)
    80001a34:	f822                	sd	s0,48(sp)
    80001a36:	f426                	sd	s1,40(sp)
    80001a38:	f04a                	sd	s2,32(sp)
    80001a3a:	ec4e                	sd	s3,24(sp)
    80001a3c:	e852                	sd	s4,16(sp)
    80001a3e:	e456                	sd	s5,8(sp)
    80001a40:	e05a                	sd	s6,0(sp)
    80001a42:	0080                	addi	s0,sp,64
    80001a44:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a46:	00010497          	auipc	s1,0x10
    80001a4a:	caa48493          	addi	s1,s1,-854 # 800116f0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a4e:	8b26                	mv	s6,s1
    80001a50:	00006a97          	auipc	s5,0x6
    80001a54:	5b0a8a93          	addi	s5,s5,1456 # 80008000 <etext>
    80001a58:	04000937          	lui	s2,0x4000
    80001a5c:	197d                	addi	s2,s2,-1
    80001a5e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a60:	00016a17          	auipc	s4,0x16
    80001a64:	e90a0a13          	addi	s4,s4,-368 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	08c080e7          	jalr	140(ra) # 80000af4 <kalloc>
    80001a70:	862a                	mv	a2,a0
    if (pa == 0)
    80001a72:	c131                	beqz	a0,80001ab6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a74:	416485b3          	sub	a1,s1,s6
    80001a78:	858d                	srai	a1,a1,0x3
    80001a7a:	000ab783          	ld	a5,0(s5)
    80001a7e:	02f585b3          	mul	a1,a1,a5
    80001a82:	2585                	addiw	a1,a1,1
    80001a84:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a88:	4719                	li	a4,6
    80001a8a:	6685                	lui	a3,0x1
    80001a8c:	40b905b3          	sub	a1,s2,a1
    80001a90:	854e                	mv	a0,s3
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	6c6080e7          	jalr	1734(ra) # 80001158 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a9a:	18848493          	addi	s1,s1,392
    80001a9e:	fd4495e3          	bne	s1,s4,80001a68 <proc_mapstacks+0x38>
  }
}
    80001aa2:	70e2                	ld	ra,56(sp)
    80001aa4:	7442                	ld	s0,48(sp)
    80001aa6:	74a2                	ld	s1,40(sp)
    80001aa8:	7902                	ld	s2,32(sp)
    80001aaa:	69e2                	ld	s3,24(sp)
    80001aac:	6a42                	ld	s4,16(sp)
    80001aae:	6aa2                	ld	s5,8(sp)
    80001ab0:	6b02                	ld	s6,0(sp)
    80001ab2:	6121                	addi	sp,sp,64
    80001ab4:	8082                	ret
      panic("kalloc");
    80001ab6:	00006517          	auipc	a0,0x6
    80001aba:	7c250513          	addi	a0,a0,1986 # 80008278 <digits+0x238>
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	a80080e7          	jalr	-1408(ra) # 8000053e <panic>

0000000080001ac6 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001ac6:	7139                	addi	sp,sp,-64
    80001ac8:	fc06                	sd	ra,56(sp)
    80001aca:	f822                	sd	s0,48(sp)
    80001acc:	f426                	sd	s1,40(sp)
    80001ace:	f04a                	sd	s2,32(sp)
    80001ad0:	ec4e                	sd	s3,24(sp)
    80001ad2:	e852                	sd	s4,16(sp)
    80001ad4:	e456                	sd	s5,8(sp)
    80001ad6:	e05a                	sd	s6,0(sp)
    80001ad8:	0080                	addi	s0,sp,64
  struct proc *p;
  start_time = ticks;
    80001ada:	00007797          	auipc	a5,0x7
    80001ade:	57e7a783          	lw	a5,1406(a5) # 80009058 <ticks>
    80001ae2:	00007717          	auipc	a4,0x7
    80001ae6:	54f72d23          	sw	a5,1370(a4) # 8000903c <start_time>
  initlock(&pid_lock, "nextpid");
    80001aea:	00006597          	auipc	a1,0x6
    80001aee:	79658593          	addi	a1,a1,1942 # 80008280 <digits+0x240>
    80001af2:	0000f517          	auipc	a0,0xf
    80001af6:	7ce50513          	addi	a0,a0,1998 # 800112c0 <pid_lock>
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	05a080e7          	jalr	90(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b02:	00006597          	auipc	a1,0x6
    80001b06:	78658593          	addi	a1,a1,1926 # 80008288 <digits+0x248>
    80001b0a:	0000f517          	auipc	a0,0xf
    80001b0e:	7ce50513          	addi	a0,a0,1998 # 800112d8 <wait_lock>
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	042080e7          	jalr	66(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b1a:	00010497          	auipc	s1,0x10
    80001b1e:	bd648493          	addi	s1,s1,-1066 # 800116f0 <proc>
  {
    initlock(&p->lock, "proc");
    80001b22:	00006b17          	auipc	s6,0x6
    80001b26:	776b0b13          	addi	s6,s6,1910 # 80008298 <digits+0x258>
    p->kstack = KSTACK((int)(p - proc));
    80001b2a:	8aa6                	mv	s5,s1
    80001b2c:	00006a17          	auipc	s4,0x6
    80001b30:	4d4a0a13          	addi	s4,s4,1236 # 80008000 <etext>
    80001b34:	04000937          	lui	s2,0x4000
    80001b38:	197d                	addi	s2,s2,-1
    80001b3a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b3c:	00016997          	auipc	s3,0x16
    80001b40:	db498993          	addi	s3,s3,-588 # 800178f0 <tickslock>
    initlock(&p->lock, "proc");
    80001b44:	85da                	mv	a1,s6
    80001b46:	8526                	mv	a0,s1
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	00c080e7          	jalr	12(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001b50:	415487b3          	sub	a5,s1,s5
    80001b54:	878d                	srai	a5,a5,0x3
    80001b56:	000a3703          	ld	a4,0(s4)
    80001b5a:	02e787b3          	mul	a5,a5,a4
    80001b5e:	2785                	addiw	a5,a5,1
    80001b60:	00d7979b          	slliw	a5,a5,0xd
    80001b64:	40f907b3          	sub	a5,s2,a5
    80001b68:	f0bc                	sd	a5,96(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b6a:	18848493          	addi	s1,s1,392
    80001b6e:	fd349be3          	bne	s1,s3,80001b44 <procinit+0x7e>
  }
}
    80001b72:	70e2                	ld	ra,56(sp)
    80001b74:	7442                	ld	s0,48(sp)
    80001b76:	74a2                	ld	s1,40(sp)
    80001b78:	7902                	ld	s2,32(sp)
    80001b7a:	69e2                	ld	s3,24(sp)
    80001b7c:	6a42                	ld	s4,16(sp)
    80001b7e:	6aa2                	ld	s5,8(sp)
    80001b80:	6b02                	ld	s6,0(sp)
    80001b82:	6121                	addi	sp,sp,64
    80001b84:	8082                	ret

0000000080001b86 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b86:	1141                	addi	sp,sp,-16
    80001b88:	e422                	sd	s0,8(sp)
    80001b8a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b8e:	2501                	sext.w	a0,a0
    80001b90:	6422                	ld	s0,8(sp)
    80001b92:	0141                	addi	sp,sp,16
    80001b94:	8082                	ret

0000000080001b96 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b96:	1141                	addi	sp,sp,-16
    80001b98:	e422                	sd	s0,8(sp)
    80001b9a:	0800                	addi	s0,sp,16
    80001b9c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b9e:	2781                	sext.w	a5,a5
    80001ba0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ba2:	0000f517          	auipc	a0,0xf
    80001ba6:	74e50513          	addi	a0,a0,1870 # 800112f0 <cpus>
    80001baa:	953e                	add	a0,a0,a5
    80001bac:	6422                	ld	s0,8(sp)
    80001bae:	0141                	addi	sp,sp,16
    80001bb0:	8082                	ret

0000000080001bb2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001bb2:	1101                	addi	sp,sp,-32
    80001bb4:	ec06                	sd	ra,24(sp)
    80001bb6:	e822                	sd	s0,16(sp)
    80001bb8:	e426                	sd	s1,8(sp)
    80001bba:	1000                	addi	s0,sp,32
  push_off();
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	fdc080e7          	jalr	-36(ra) # 80000b98 <push_off>
    80001bc4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bc6:	2781                	sext.w	a5,a5
    80001bc8:	079e                	slli	a5,a5,0x7
    80001bca:	0000f717          	auipc	a4,0xf
    80001bce:	6f670713          	addi	a4,a4,1782 # 800112c0 <pid_lock>
    80001bd2:	97ba                	add	a5,a5,a4
    80001bd4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	062080e7          	jalr	98(ra) # 80000c38 <pop_off>
  return p;
}
    80001bde:	8526                	mv	a0,s1
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6105                	addi	sp,sp,32
    80001be8:	8082                	ret

0000000080001bea <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bea:	1141                	addi	sp,sp,-16
    80001bec:	e406                	sd	ra,8(sp)
    80001bee:	e022                	sd	s0,0(sp)
    80001bf0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	fc0080e7          	jalr	-64(ra) # 80001bb2 <myproc>
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	09e080e7          	jalr	158(ra) # 80000c98 <release>

  if (first)
    80001c02:	00007797          	auipc	a5,0x7
    80001c06:	dbe7a783          	lw	a5,-578(a5) # 800089c0 <first.1754>
    80001c0a:	eb89                	bnez	a5,80001c1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c0c:	00001097          	auipc	ra,0x1
    80001c10:	104080e7          	jalr	260(ra) # 80002d10 <usertrapret>
}
    80001c14:	60a2                	ld	ra,8(sp)
    80001c16:	6402                	ld	s0,0(sp)
    80001c18:	0141                	addi	sp,sp,16
    80001c1a:	8082                	ret
    first = 0;
    80001c1c:	00007797          	auipc	a5,0x7
    80001c20:	da07a223          	sw	zero,-604(a5) # 800089c0 <first.1754>
    fsinit(ROOTDEV);
    80001c24:	4505                	li	a0,1
    80001c26:	00002097          	auipc	ra,0x2
    80001c2a:	e90080e7          	jalr	-368(ra) # 80003ab6 <fsinit>
    80001c2e:	bff9                	j	80001c0c <forkret+0x22>

0000000080001c30 <allocpid>:
{
    80001c30:	1101                	addi	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	e04a                	sd	s2,0(sp)
    80001c3a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c3c:	0000f917          	auipc	s2,0xf
    80001c40:	68490913          	addi	s2,s2,1668 # 800112c0 <pid_lock>
    80001c44:	854a                	mv	a0,s2
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	f9e080e7          	jalr	-98(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	d7a78793          	addi	a5,a5,-646 # 800089c8 <nextpid>
    80001c56:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c58:	0014871b          	addiw	a4,s1,1
    80001c5c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c5e:	854a                	mv	a0,s2
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	038080e7          	jalr	56(ra) # 80000c98 <release>
}
    80001c68:	8526                	mv	a0,s1
    80001c6a:	60e2                	ld	ra,24(sp)
    80001c6c:	6442                	ld	s0,16(sp)
    80001c6e:	64a2                	ld	s1,8(sp)
    80001c70:	6902                	ld	s2,0(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret

0000000080001c76 <proc_pagetable>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	e04a                	sd	s2,0(sp)
    80001c80:	1000                	addi	s0,sp,32
    80001c82:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	6be080e7          	jalr	1726(ra) # 80001342 <uvmcreate>
    80001c8c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c8e:	c121                	beqz	a0,80001cce <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c90:	4729                	li	a4,10
    80001c92:	00005697          	auipc	a3,0x5
    80001c96:	36e68693          	addi	a3,a3,878 # 80007000 <_trampoline>
    80001c9a:	6605                	lui	a2,0x1
    80001c9c:	040005b7          	lui	a1,0x4000
    80001ca0:	15fd                	addi	a1,a1,-1
    80001ca2:	05b2                	slli	a1,a1,0xc
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	414080e7          	jalr	1044(ra) # 800010b8 <mappages>
    80001cac:	02054863          	bltz	a0,80001cdc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb0:	4719                	li	a4,6
    80001cb2:	07893683          	ld	a3,120(s2)
    80001cb6:	6605                	lui	a2,0x1
    80001cb8:	020005b7          	lui	a1,0x2000
    80001cbc:	15fd                	addi	a1,a1,-1
    80001cbe:	05b6                	slli	a1,a1,0xd
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	3f6080e7          	jalr	1014(ra) # 800010b8 <mappages>
    80001cca:	02054163          	bltz	a0,80001cec <proc_pagetable+0x76>
}
    80001cce:	8526                	mv	a0,s1
    80001cd0:	60e2                	ld	ra,24(sp)
    80001cd2:	6442                	ld	s0,16(sp)
    80001cd4:	64a2                	ld	s1,8(sp)
    80001cd6:	6902                	ld	s2,0(sp)
    80001cd8:	6105                	addi	sp,sp,32
    80001cda:	8082                	ret
    uvmfree(pagetable, 0);
    80001cdc:	4581                	li	a1,0
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	85e080e7          	jalr	-1954(ra) # 8000153e <uvmfree>
    return 0;
    80001ce8:	4481                	li	s1,0
    80001cea:	b7d5                	j	80001cce <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cec:	4681                	li	a3,0
    80001cee:	4605                	li	a2,1
    80001cf0:	040005b7          	lui	a1,0x4000
    80001cf4:	15fd                	addi	a1,a1,-1
    80001cf6:	05b2                	slli	a1,a1,0xc
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	584080e7          	jalr	1412(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001d02:	4581                	li	a1,0
    80001d04:	8526                	mv	a0,s1
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	838080e7          	jalr	-1992(ra) # 8000153e <uvmfree>
    return 0;
    80001d0e:	4481                	li	s1,0
    80001d10:	bf7d                	j	80001cce <proc_pagetable+0x58>

0000000080001d12 <proc_freepagetable>:
{
    80001d12:	1101                	addi	sp,sp,-32
    80001d14:	ec06                	sd	ra,24(sp)
    80001d16:	e822                	sd	s0,16(sp)
    80001d18:	e426                	sd	s1,8(sp)
    80001d1a:	e04a                	sd	s2,0(sp)
    80001d1c:	1000                	addi	s0,sp,32
    80001d1e:	84aa                	mv	s1,a0
    80001d20:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d22:	4681                	li	a3,0
    80001d24:	4605                	li	a2,1
    80001d26:	040005b7          	lui	a1,0x4000
    80001d2a:	15fd                	addi	a1,a1,-1
    80001d2c:	05b2                	slli	a1,a1,0xc
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	550080e7          	jalr	1360(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d36:	4681                	li	a3,0
    80001d38:	4605                	li	a2,1
    80001d3a:	020005b7          	lui	a1,0x2000
    80001d3e:	15fd                	addi	a1,a1,-1
    80001d40:	05b6                	slli	a1,a1,0xd
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	53a080e7          	jalr	1338(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001d4c:	85ca                	mv	a1,s2
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	7ee080e7          	jalr	2030(ra) # 8000153e <uvmfree>
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6902                	ld	s2,0(sp)
    80001d60:	6105                	addi	sp,sp,32
    80001d62:	8082                	ret

0000000080001d64 <freeproc>:
{
    80001d64:	1101                	addi	sp,sp,-32
    80001d66:	ec06                	sd	ra,24(sp)
    80001d68:	e822                	sd	s0,16(sp)
    80001d6a:	e426                	sd	s1,8(sp)
    80001d6c:	1000                	addi	s0,sp,32
    80001d6e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d70:	7d28                	ld	a0,120(a0)
    80001d72:	c509                	beqz	a0,80001d7c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	c84080e7          	jalr	-892(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d7c:	0604bc23          	sd	zero,120(s1)
  if (p->pagetable)
    80001d80:	78a8                	ld	a0,112(s1)
    80001d82:	c511                	beqz	a0,80001d8e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d84:	74ac                	ld	a1,104(s1)
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	f8c080e7          	jalr	-116(ra) # 80001d12 <proc_freepagetable>
  p->pagetable = 0;
    80001d8e:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001d92:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001d96:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d9a:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001d9e:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001da2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001da6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001daa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dae:	0004ac23          	sw	zero,24(s1)
}
    80001db2:	60e2                	ld	ra,24(sp)
    80001db4:	6442                	ld	s0,16(sp)
    80001db6:	64a2                	ld	s1,8(sp)
    80001db8:	6105                	addi	sp,sp,32
    80001dba:	8082                	ret

0000000080001dbc <allocproc>:
{
    80001dbc:	1101                	addi	sp,sp,-32
    80001dbe:	ec06                	sd	ra,24(sp)
    80001dc0:	e822                	sd	s0,16(sp)
    80001dc2:	e426                	sd	s1,8(sp)
    80001dc4:	e04a                	sd	s2,0(sp)
    80001dc6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001dc8:	00010497          	auipc	s1,0x10
    80001dcc:	92848493          	addi	s1,s1,-1752 # 800116f0 <proc>
    80001dd0:	00016917          	auipc	s2,0x16
    80001dd4:	b2090913          	addi	s2,s2,-1248 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	e0a080e7          	jalr	-502(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001de2:	4c9c                	lw	a5,24(s1)
    80001de4:	cf81                	beqz	a5,80001dfc <allocproc+0x40>
      release(&p->lock);
    80001de6:	8526                	mv	a0,s1
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	eb0080e7          	jalr	-336(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001df0:	18848493          	addi	s1,s1,392
    80001df4:	ff2492e3          	bne	s1,s2,80001dd8 <allocproc+0x1c>
  return 0;
    80001df8:	4481                	li	s1,0
    80001dfa:	a88d                	j	80001e6c <allocproc+0xb0>
  p->pid = allocpid();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	e34080e7          	jalr	-460(ra) # 80001c30 <allocpid>
    80001e04:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e06:	4785                	li	a5,1
    80001e08:	cc9c                	sw	a5,24(s1)
  p->pause = 0;
    80001e0a:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001e0e:	0204ae23          	sw	zero,60(s1)
  p->mean_ticks = 0;
    80001e12:	0204ac23          	sw	zero,56(s1)
  p->last_runnable_time = 0;
    80001e16:	0404a023          	sw	zero,64(s1)
  p->sleep_time = 0;
    80001e1a:	0404a223          	sw	zero,68(s1)
  p->runnable_time = 0;
    80001e1e:	0404a423          	sw	zero,72(s1)
  p->running_time = 0;
    80001e22:	0404a623          	sw	zero,76(s1)
  p->counter = 0;
    80001e26:	0404a823          	sw	zero,80(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	cca080e7          	jalr	-822(ra) # 80000af4 <kalloc>
    80001e32:	892a                	mv	s2,a0
    80001e34:	fca8                	sd	a0,120(s1)
    80001e36:	c131                	beqz	a0,80001e7a <allocproc+0xbe>
  p->pagetable = proc_pagetable(p);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80001c76 <proc_pagetable>
    80001e42:	892a                	mv	s2,a0
    80001e44:	f8a8                	sd	a0,112(s1)
  if (p->pagetable == 0)
    80001e46:	c531                	beqz	a0,80001e92 <allocproc+0xd6>
  memset(&p->context, 0, sizeof(p->context));
    80001e48:	07000613          	li	a2,112
    80001e4c:	4581                	li	a1,0
    80001e4e:	08048513          	addi	a0,s1,128
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e8e080e7          	jalr	-370(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001e5a:	00000797          	auipc	a5,0x0
    80001e5e:	d9078793          	addi	a5,a5,-624 # 80001bea <forkret>
    80001e62:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e64:	70bc                	ld	a5,96(s1)
    80001e66:	6705                	lui	a4,0x1
    80001e68:	97ba                	add	a5,a5,a4
    80001e6a:	e4dc                	sd	a5,136(s1)
}
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	60e2                	ld	ra,24(sp)
    80001e70:	6442                	ld	s0,16(sp)
    80001e72:	64a2                	ld	s1,8(sp)
    80001e74:	6902                	ld	s2,0(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret
    freeproc(p);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	ee8080e7          	jalr	-280(ra) # 80001d64 <freeproc>
    release(&p->lock);
    80001e84:	8526                	mv	a0,s1
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e12080e7          	jalr	-494(ra) # 80000c98 <release>
    return 0;
    80001e8e:	84ca                	mv	s1,s2
    80001e90:	bff1                	j	80001e6c <allocproc+0xb0>
    freeproc(p);
    80001e92:	8526                	mv	a0,s1
    80001e94:	00000097          	auipc	ra,0x0
    80001e98:	ed0080e7          	jalr	-304(ra) # 80001d64 <freeproc>
    release(&p->lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	dfa080e7          	jalr	-518(ra) # 80000c98 <release>
    return 0;
    80001ea6:	84ca                	mv	s1,s2
    80001ea8:	b7d1                	j	80001e6c <allocproc+0xb0>

0000000080001eaa <userinit>:
{
    80001eaa:	1101                	addi	sp,sp,-32
    80001eac:	ec06                	sd	ra,24(sp)
    80001eae:	e822                	sd	s0,16(sp)
    80001eb0:	e426                	sd	s1,8(sp)
    80001eb2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001eb4:	00000097          	auipc	ra,0x0
    80001eb8:	f08080e7          	jalr	-248(ra) # 80001dbc <allocproc>
    80001ebc:	84aa                	mv	s1,a0
  initproc = p;
    80001ebe:	00007797          	auipc	a5,0x7
    80001ec2:	18a7b923          	sd	a0,402(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ec6:	03400613          	li	a2,52
    80001eca:	00007597          	auipc	a1,0x7
    80001ece:	b0658593          	addi	a1,a1,-1274 # 800089d0 <initcode>
    80001ed2:	7928                	ld	a0,112(a0)
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	49c080e7          	jalr	1180(ra) # 80001370 <uvminit>
  p->sz = PGSIZE;
    80001edc:	6785                	lui	a5,0x1
    80001ede:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ee0:	7cb8                	ld	a4,120(s1)
    80001ee2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ee6:	7cb8                	ld	a4,120(s1)
    80001ee8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eea:	4641                	li	a2,16
    80001eec:	00006597          	auipc	a1,0x6
    80001ef0:	3b458593          	addi	a1,a1,948 # 800082a0 <digits+0x260>
    80001ef4:	17848513          	addi	a0,s1,376
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	f3a080e7          	jalr	-198(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001f00:	00006517          	auipc	a0,0x6
    80001f04:	3b050513          	addi	a0,a0,944 # 800082b0 <digits+0x270>
    80001f08:	00002097          	auipc	ra,0x2
    80001f0c:	5dc080e7          	jalr	1500(ra) # 800044e4 <namei>
    80001f10:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001f14:	478d                	li	a5,3
    80001f16:	cc9c                	sw	a5,24(s1)
  p->counter = ticks;
    80001f18:	00007797          	auipc	a5,0x7
    80001f1c:	1407a783          	lw	a5,320(a5) # 80009058 <ticks>
    80001f20:	c8bc                	sw	a5,80(s1)
  p->last_runnable_time = ticks;
    80001f22:	c0bc                	sw	a5,64(s1)
  release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d72080e7          	jalr	-654(ra) # 80000c98 <release>
}
    80001f2e:	60e2                	ld	ra,24(sp)
    80001f30:	6442                	ld	s0,16(sp)
    80001f32:	64a2                	ld	s1,8(sp)
    80001f34:	6105                	addi	sp,sp,32
    80001f36:	8082                	ret

0000000080001f38 <growproc>:
{
    80001f38:	1101                	addi	sp,sp,-32
    80001f3a:	ec06                	sd	ra,24(sp)
    80001f3c:	e822                	sd	s0,16(sp)
    80001f3e:	e426                	sd	s1,8(sp)
    80001f40:	e04a                	sd	s2,0(sp)
    80001f42:	1000                	addi	s0,sp,32
    80001f44:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	c6c080e7          	jalr	-916(ra) # 80001bb2 <myproc>
    80001f4e:	892a                	mv	s2,a0
  sz = p->sz;
    80001f50:	752c                	ld	a1,104(a0)
    80001f52:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001f56:	00904f63          	bgtz	s1,80001f74 <growproc+0x3c>
  else if (n < 0)
    80001f5a:	0204cc63          	bltz	s1,80001f92 <growproc+0x5a>
  p->sz = sz;
    80001f5e:	1602                	slli	a2,a2,0x20
    80001f60:	9201                	srli	a2,a2,0x20
    80001f62:	06c93423          	sd	a2,104(s2)
  return 0;
    80001f66:	4501                	li	a0,0
}
    80001f68:	60e2                	ld	ra,24(sp)
    80001f6a:	6442                	ld	s0,16(sp)
    80001f6c:	64a2                	ld	s1,8(sp)
    80001f6e:	6902                	ld	s2,0(sp)
    80001f70:	6105                	addi	sp,sp,32
    80001f72:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f74:	9e25                	addw	a2,a2,s1
    80001f76:	1602                	slli	a2,a2,0x20
    80001f78:	9201                	srli	a2,a2,0x20
    80001f7a:	1582                	slli	a1,a1,0x20
    80001f7c:	9181                	srli	a1,a1,0x20
    80001f7e:	7928                	ld	a0,112(a0)
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	4aa080e7          	jalr	1194(ra) # 8000142a <uvmalloc>
    80001f88:	0005061b          	sext.w	a2,a0
    80001f8c:	fa69                	bnez	a2,80001f5e <growproc+0x26>
      return -1;
    80001f8e:	557d                	li	a0,-1
    80001f90:	bfe1                	j	80001f68 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f92:	9e25                	addw	a2,a2,s1
    80001f94:	1602                	slli	a2,a2,0x20
    80001f96:	9201                	srli	a2,a2,0x20
    80001f98:	1582                	slli	a1,a1,0x20
    80001f9a:	9181                	srli	a1,a1,0x20
    80001f9c:	7928                	ld	a0,112(a0)
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	444080e7          	jalr	1092(ra) # 800013e2 <uvmdealloc>
    80001fa6:	0005061b          	sext.w	a2,a0
    80001faa:	bf55                	j	80001f5e <growproc+0x26>

0000000080001fac <fork>:
{
    80001fac:	7179                	addi	sp,sp,-48
    80001fae:	f406                	sd	ra,40(sp)
    80001fb0:	f022                	sd	s0,32(sp)
    80001fb2:	ec26                	sd	s1,24(sp)
    80001fb4:	e84a                	sd	s2,16(sp)
    80001fb6:	e44e                	sd	s3,8(sp)
    80001fb8:	e052                	sd	s4,0(sp)
    80001fba:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	bf6080e7          	jalr	-1034(ra) # 80001bb2 <myproc>
    80001fc4:	89aa                	mv	s3,a0
  if ((np = allocproc()) == 0)
    80001fc6:	00000097          	auipc	ra,0x0
    80001fca:	df6080e7          	jalr	-522(ra) # 80001dbc <allocproc>
    80001fce:	12050863          	beqz	a0,800020fe <fork+0x152>
    80001fd2:	892a                	mv	s2,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fd4:	0689b603          	ld	a2,104(s3)
    80001fd8:	792c                	ld	a1,112(a0)
    80001fda:	0709b503          	ld	a0,112(s3)
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	598080e7          	jalr	1432(ra) # 80001576 <uvmcopy>
    80001fe6:	04054663          	bltz	a0,80002032 <fork+0x86>
  np->sz = p->sz;
    80001fea:	0689b783          	ld	a5,104(s3)
    80001fee:	06f93423          	sd	a5,104(s2)
  *(np->trapframe) = *(p->trapframe);
    80001ff2:	0789b683          	ld	a3,120(s3)
    80001ff6:	87b6                	mv	a5,a3
    80001ff8:	07893703          	ld	a4,120(s2)
    80001ffc:	12068693          	addi	a3,a3,288
    80002000:	0007b803          	ld	a6,0(a5)
    80002004:	6788                	ld	a0,8(a5)
    80002006:	6b8c                	ld	a1,16(a5)
    80002008:	6f90                	ld	a2,24(a5)
    8000200a:	01073023          	sd	a6,0(a4)
    8000200e:	e708                	sd	a0,8(a4)
    80002010:	eb0c                	sd	a1,16(a4)
    80002012:	ef10                	sd	a2,24(a4)
    80002014:	02078793          	addi	a5,a5,32
    80002018:	02070713          	addi	a4,a4,32
    8000201c:	fed792e3          	bne	a5,a3,80002000 <fork+0x54>
  np->trapframe->a0 = 0;
    80002020:	07893783          	ld	a5,120(s2)
    80002024:	0607b823          	sd	zero,112(a5)
    80002028:	0f000493          	li	s1,240
  for (i = 0; i < NOFILE; i++)
    8000202c:	17000a13          	li	s4,368
    80002030:	a03d                	j	8000205e <fork+0xb2>
    freeproc(np);
    80002032:	854a                	mv	a0,s2
    80002034:	00000097          	auipc	ra,0x0
    80002038:	d30080e7          	jalr	-720(ra) # 80001d64 <freeproc>
    release(&np->lock);
    8000203c:	854a                	mv	a0,s2
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
    return -1;
    80002046:	5a7d                	li	s4,-1
    80002048:	a055                	j	800020ec <fork+0x140>
      np->ofile[i] = filedup(p->ofile[i]);
    8000204a:	00003097          	auipc	ra,0x3
    8000204e:	b30080e7          	jalr	-1232(ra) # 80004b7a <filedup>
    80002052:	009907b3          	add	a5,s2,s1
    80002056:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002058:	04a1                	addi	s1,s1,8
    8000205a:	01448763          	beq	s1,s4,80002068 <fork+0xbc>
    if (p->ofile[i])
    8000205e:	009987b3          	add	a5,s3,s1
    80002062:	6388                	ld	a0,0(a5)
    80002064:	f17d                	bnez	a0,8000204a <fork+0x9e>
    80002066:	bfcd                	j	80002058 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002068:	1709b503          	ld	a0,368(s3)
    8000206c:	00002097          	auipc	ra,0x2
    80002070:	c84080e7          	jalr	-892(ra) # 80003cf0 <idup>
    80002074:	16a93823          	sd	a0,368(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002078:	4641                	li	a2,16
    8000207a:	17898593          	addi	a1,s3,376
    8000207e:	17890513          	addi	a0,s2,376
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	db0080e7          	jalr	-592(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    8000208a:	03092a03          	lw	s4,48(s2)
  release(&np->lock);
    8000208e:	854a                	mv	a0,s2
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c08080e7          	jalr	-1016(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002098:	0000f497          	auipc	s1,0xf
    8000209c:	24048493          	addi	s1,s1,576 # 800112d8 <wait_lock>
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b42080e7          	jalr	-1214(ra) # 80000be4 <acquire>
  np->parent = p;
    800020aa:	05393c23          	sd	s3,88(s2)
  release(&wait_lock);
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	be8080e7          	jalr	-1048(ra) # 80000c98 <release>
  acquire(&np->lock);
    800020b8:	854a                	mv	a0,s2
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2a080e7          	jalr	-1238(ra) # 80000be4 <acquire>
  update_time(np);
    800020c2:	854a                	mv	a0,s2
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	834080e7          	jalr	-1996(ra) # 800018f8 <update_time>
  np->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	00f92c23          	sw	a5,24(s2)
  np->counter = ticks;
    800020d2:	00007797          	auipc	a5,0x7
    800020d6:	f867a783          	lw	a5,-122(a5) # 80009058 <ticks>
    800020da:	04f92823          	sw	a5,80(s2)
  np->last_runnable_time = ticks;
    800020de:	04f92023          	sw	a5,64(s2)
  release(&np->lock);
    800020e2:	854a                	mv	a0,s2
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	bb4080e7          	jalr	-1100(ra) # 80000c98 <release>
}
    800020ec:	8552                	mv	a0,s4
    800020ee:	70a2                	ld	ra,40(sp)
    800020f0:	7402                	ld	s0,32(sp)
    800020f2:	64e2                	ld	s1,24(sp)
    800020f4:	6942                	ld	s2,16(sp)
    800020f6:	69a2                	ld	s3,8(sp)
    800020f8:	6a02                	ld	s4,0(sp)
    800020fa:	6145                	addi	sp,sp,48
    800020fc:	8082                	ret
    return -1;
    800020fe:	5a7d                	li	s4,-1
    80002100:	b7f5                	j	800020ec <fork+0x140>

0000000080002102 <unpause>:
{
    80002102:	1101                	addi	sp,sp,-32
    80002104:	ec06                	sd	ra,24(sp)
    80002106:	e822                	sd	s0,16(sp)
    80002108:	e426                	sd	s1,8(sp)
    8000210a:	e04a                	sd	s2,0(sp)
    8000210c:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    8000210e:	0000f497          	auipc	s1,0xf
    80002112:	5e248493          	addi	s1,s1,1506 # 800116f0 <proc>
    80002116:	00015917          	auipc	s2,0x15
    8000211a:	7da90913          	addi	s2,s2,2010 # 800178f0 <tickslock>
    acquire(&p->lock);
    8000211e:	8526                	mv	a0,s1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	ac4080e7          	jalr	-1340(ra) # 80000be4 <acquire>
    p->pause = 0;
    80002128:	0204aa23          	sw	zero,52(s1)
    release(&p->lock);
    8000212c:	8526                	mv	a0,s1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b6a080e7          	jalr	-1174(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002136:	18848493          	addi	s1,s1,392
    8000213a:	ff2492e3          	bne	s1,s2,8000211e <unpause+0x1c>
}
    8000213e:	60e2                	ld	ra,24(sp)
    80002140:	6442                	ld	s0,16(sp)
    80002142:	64a2                	ld	s1,8(sp)
    80002144:	6902                	ld	s2,0(sp)
    80002146:	6105                	addi	sp,sp,32
    80002148:	8082                	ret

000000008000214a <printall>:
{
    8000214a:	7139                	addi	sp,sp,-64
    8000214c:	fc06                	sd	ra,56(sp)
    8000214e:	f822                	sd	s0,48(sp)
    80002150:	f426                	sd	s1,40(sp)
    80002152:	f04a                	sd	s2,32(sp)
    80002154:	ec4e                	sd	s3,24(sp)
    80002156:	e852                	sd	s4,16(sp)
    80002158:	e456                	sd	s5,8(sp)
    8000215a:	0080                	addi	s0,sp,64
    8000215c:	8a2a                	mv	s4,a0
  printf("LOWEST RUNNING PORCCESS!\nPID: %d   name:%s last_runnable_time:%d \n\n", pillow->pid, pillow->name, pillow->last_runnable_time);
    8000215e:	4134                	lw	a3,64(a0)
    80002160:	17850613          	addi	a2,a0,376
    80002164:	590c                	lw	a1,48(a0)
    80002166:	00006517          	auipc	a0,0x6
    8000216a:	15250513          	addi	a0,a0,338 # 800082b8 <digits+0x278>
    8000216e:	ffffe097          	auipc	ra,0xffffe
    80002172:	41a080e7          	jalr	1050(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002176:	0000f497          	auipc	s1,0xf
    8000217a:	57a48493          	addi	s1,s1,1402 # 800116f0 <proc>
    if (p->state == RUNNABLE && p != pillow)
    8000217e:	498d                	li	s3,3
      printf("PID: %d   name:%s last_runnable_time:%d \n", p->pid, p->name, p->last_runnable_time);
    80002180:	00006a97          	auipc	s5,0x6
    80002184:	180a8a93          	addi	s5,s5,384 # 80008300 <digits+0x2c0>
  for (p = proc; p < &proc[NPROC]; p++)
    80002188:	00015917          	auipc	s2,0x15
    8000218c:	76890913          	addi	s2,s2,1896 # 800178f0 <tickslock>
    80002190:	a831                	j	800021ac <printall+0x62>
      printf("PID: %d   name:%s last_runnable_time:%d \n", p->pid, p->name, p->last_runnable_time);
    80002192:	40b4                	lw	a3,64(s1)
    80002194:	17848613          	addi	a2,s1,376
    80002198:	588c                	lw	a1,48(s1)
    8000219a:	8556                	mv	a0,s5
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	3ec080e7          	jalr	1004(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800021a4:	18848493          	addi	s1,s1,392
    800021a8:	01248863          	beq	s1,s2,800021b8 <printall+0x6e>
    if (p->state == RUNNABLE && p != pillow)
    800021ac:	4c9c                	lw	a5,24(s1)
    800021ae:	ff379be3          	bne	a5,s3,800021a4 <printall+0x5a>
    800021b2:	fe9a10e3          	bne	s4,s1,80002192 <printall+0x48>
    800021b6:	b7fd                	j	800021a4 <printall+0x5a>
}
    800021b8:	70e2                	ld	ra,56(sp)
    800021ba:	7442                	ld	s0,48(sp)
    800021bc:	74a2                	ld	s1,40(sp)
    800021be:	7902                	ld	s2,32(sp)
    800021c0:	69e2                	ld	s3,24(sp)
    800021c2:	6a42                	ld	s4,16(sp)
    800021c4:	6aa2                	ld	s5,8(sp)
    800021c6:	6121                	addi	sp,sp,64
    800021c8:	8082                	ret

00000000800021ca <FCFS_scheduler>:
{
    800021ca:	711d                	addi	sp,sp,-96
    800021cc:	ec86                	sd	ra,88(sp)
    800021ce:	e8a2                	sd	s0,80(sp)
    800021d0:	e4a6                	sd	s1,72(sp)
    800021d2:	e0ca                	sd	s2,64(sp)
    800021d4:	fc4e                	sd	s3,56(sp)
    800021d6:	f852                	sd	s4,48(sp)
    800021d8:	f456                	sd	s5,40(sp)
    800021da:	f05a                	sd	s6,32(sp)
    800021dc:	ec5e                	sd	s7,24(sp)
    800021de:	e862                	sd	s8,16(sp)
    800021e0:	e466                	sd	s9,8(sp)
    800021e2:	e06a                	sd	s10,0(sp)
    800021e4:	1080                	addi	s0,sp,96
    800021e6:	8792                	mv	a5,tp
  int id = r_tp();
    800021e8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021ea:	00779b93          	slli	s7,a5,0x7
    800021ee:	0000f717          	auipc	a4,0xf
    800021f2:	0d270713          	addi	a4,a4,210 # 800112c0 <pid_lock>
    800021f6:	975e                	add	a4,a4,s7
    800021f8:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &pillow->context);
    800021fc:	0000f717          	auipc	a4,0xf
    80002200:	0fc70713          	addi	a4,a4,252 # 800112f8 <cpus+0x8>
    80002204:	9bba                	add	s7,s7,a4
  struct proc *pillow = proc;
    80002206:	0000fa17          	auipc	s4,0xf
    8000220a:	4eaa0a13          	addi	s4,s4,1258 # 800116f0 <proc>
      if (p->state == RUNNABLE && p->pause == 0)
    8000220e:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002210:	00015917          	auipc	s2,0x15
    80002214:	6e090913          	addi	s2,s2,1760 # 800178f0 <tickslock>
    pillow->state = RUNNING;
    80002218:	4c91                	li	s9,4
    pillow->counter = ticks;
    8000221a:	00007b17          	auipc	s6,0x7
    8000221e:	e3eb0b13          	addi	s6,s6,-450 # 80009058 <ticks>
    c->proc = pillow;
    80002222:	079e                	slli	a5,a5,0x7
    80002224:	0000fa97          	auipc	s5,0xf
    80002228:	09ca8a93          	addi	s5,s5,156 # 800112c0 <pid_lock>
    8000222c:	9abe                	add	s5,s5,a5
    if (ticks >= p_time && toRelease == 1)
    8000222e:	00007c17          	auipc	s8,0x7
    80002232:	e1ac0c13          	addi	s8,s8,-486 # 80009048 <p_time>
    80002236:	00007d17          	auipc	s10,0x7
    8000223a:	e0ed0d13          	addi	s10,s10,-498 # 80009044 <toRelease>
    8000223e:	a841                	j	800022ce <FCFS_scheduler+0x104>
      release(&p->lock);
    80002240:	8526                	mv	a0,s1
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000224a:	18848493          	addi	s1,s1,392
    8000224e:	03248363          	beq	s1,s2,80002274 <FCFS_scheduler+0xaa>
      acquire(&p->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	990080e7          	jalr	-1648(ra) # 80000be4 <acquire>
      if (p->state == RUNNABLE && p->pause == 0)
    8000225c:	4c9c                	lw	a5,24(s1)
    8000225e:	ff3791e3          	bne	a5,s3,80002240 <FCFS_scheduler+0x76>
    80002262:	58dc                	lw	a5,52(s1)
    80002264:	fff1                	bnez	a5,80002240 <FCFS_scheduler+0x76>
        if (p->last_runnable_time <= pillow->last_runnable_time)
    80002266:	40b8                	lw	a4,64(s1)
    80002268:	040a2783          	lw	a5,64(s4)
    8000226c:	fce7eae3          	bltu	a5,a4,80002240 <FCFS_scheduler+0x76>
    80002270:	8a26                	mv	s4,s1
    80002272:	b7f9                	j	80002240 <FCFS_scheduler+0x76>
    acquire(&pillow->lock);
    80002274:	8552                	mv	a0,s4
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	96e080e7          	jalr	-1682(ra) # 80000be4 <acquire>
    update_time(pillow);
    8000227e:	8552                	mv	a0,s4
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	678080e7          	jalr	1656(ra) # 800018f8 <update_time>
    pillow->state = RUNNING;
    80002288:	019a2c23          	sw	s9,24(s4)
    pillow->counter = ticks;
    8000228c:	000b2783          	lw	a5,0(s6)
    80002290:	04fa2823          	sw	a5,80(s4)
    c->proc = pillow;
    80002294:	034ab823          	sd	s4,48(s5)
    swtch(&c->context, &pillow->context);
    80002298:	080a0593          	addi	a1,s4,128
    8000229c:	855e                	mv	a0,s7
    8000229e:	00001097          	auipc	ra,0x1
    800022a2:	9c8080e7          	jalr	-1592(ra) # 80002c66 <swtch>
    c->proc = 0;
    800022a6:	020ab823          	sd	zero,48(s5)
    release(&pillow->lock);
    800022aa:	8552                	mv	a0,s4
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	9ec080e7          	jalr	-1556(ra) # 80000c98 <release>
    if (ticks >= p_time && toRelease == 1)
    800022b4:	000b2583          	lw	a1,0(s6)
    800022b8:	000c2603          	lw	a2,0(s8)
    800022bc:	0006079b          	sext.w	a5,a2
    800022c0:	00f5e763          	bltu	a1,a5,800022ce <FCFS_scheduler+0x104>
    800022c4:	000d2703          	lw	a4,0(s10)
    800022c8:	4785                	li	a5,1
    800022ca:	00f70d63          	beq	a4,a5,800022e4 <FCFS_scheduler+0x11a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022d6:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800022da:	0000f497          	auipc	s1,0xf
    800022de:	41648493          	addi	s1,s1,1046 # 800116f0 <proc>
    800022e2:	bf85                	j	80002252 <FCFS_scheduler+0x88>
      toRelease = 0;
    800022e4:	000d2023          	sw	zero,0(s10)
      printf("RELEASING! ticks:%d   p_time:%d  \n", ticks, p_time);
    800022e8:	00006517          	auipc	a0,0x6
    800022ec:	04850513          	addi	a0,a0,72 # 80008330 <digits+0x2f0>
    800022f0:	ffffe097          	auipc	ra,0xffffe
    800022f4:	298080e7          	jalr	664(ra) # 80000588 <printf>
      unpause();
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	e0a080e7          	jalr	-502(ra) # 80002102 <unpause>
    80002300:	b7f9                	j	800022ce <FCFS_scheduler+0x104>

0000000080002302 <SJF_scheduler>:
{
    80002302:	7119                	addi	sp,sp,-128
    80002304:	fc86                	sd	ra,120(sp)
    80002306:	f8a2                	sd	s0,112(sp)
    80002308:	f4a6                	sd	s1,104(sp)
    8000230a:	f0ca                	sd	s2,96(sp)
    8000230c:	ecce                	sd	s3,88(sp)
    8000230e:	e8d2                	sd	s4,80(sp)
    80002310:	e4d6                	sd	s5,72(sp)
    80002312:	e0da                	sd	s6,64(sp)
    80002314:	fc5e                	sd	s7,56(sp)
    80002316:	f862                	sd	s8,48(sp)
    80002318:	f466                	sd	s9,40(sp)
    8000231a:	f06a                	sd	s10,32(sp)
    8000231c:	ec6e                	sd	s11,24(sp)
    8000231e:	0100                	addi	s0,sp,128
  printf("SJFFFF im here\n");
    80002320:	00006517          	auipc	a0,0x6
    80002324:	03850513          	addi	a0,a0,56 # 80008358 <digits+0x318>
    80002328:	ffffe097          	auipc	ra,0xffffe
    8000232c:	260080e7          	jalr	608(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002330:	8792                	mv	a5,tp
  int id = r_tp();
    80002332:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002334:	00779693          	slli	a3,a5,0x7
    80002338:	0000f717          	auipc	a4,0xf
    8000233c:	f8870713          	addi	a4,a4,-120 # 800112c0 <pid_lock>
    80002340:	9736                	add	a4,a4,a3
    80002342:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &min_pointer->context);
    80002346:	0000f717          	auipc	a4,0xf
    8000234a:	fb270713          	addi	a4,a4,-78 # 800112f8 <cpus+0x8>
    8000234e:	9736                	add	a4,a4,a3
    80002350:	f8e43423          	sd	a4,-120(s0)
        printf("init: min_ticks:%d  min_pointer_name:%s \n", min_ticks, min_pointer->name);
    80002354:	00006c97          	auipc	s9,0x6
    80002358:	014c8c93          	addi	s9,s9,20 # 80008368 <digits+0x328>
        initi = 1;
    8000235c:	4985                	li	s3,1
    for (p = proc + 2; p < &proc[NPROC]; p++)
    8000235e:	00015a17          	auipc	s4,0x15
    80002362:	592a0a13          	addi	s4,s4,1426 # 800178f0 <tickslock>
        initi = 1;
    80002366:	8c4e                	mv	s8,s3
    min_pointer->counter = ticks;
    80002368:	00007d97          	auipc	s11,0x7
    8000236c:	cf0d8d93          	addi	s11,s11,-784 # 80009058 <ticks>
    c->proc = min_pointer;
    80002370:	0000fd17          	auipc	s10,0xf
    80002374:	f50d0d13          	addi	s10,s10,-176 # 800112c0 <pid_lock>
    80002378:	9d36                	add	s10,s10,a3
    8000237a:	a8f5                	j	80002476 <SJF_scheduler+0x174>
        min_ticks = p->mean_ticks;
    8000237c:	0384ab83          	lw	s7,56(s1)
        printf("init: min_ticks:%d  min_pointer_name:%s \n", min_ticks, min_pointer->name);
    80002380:	17848613          	addi	a2,s1,376
    80002384:	85de                	mv	a1,s7
    80002386:	8566                	mv	a0,s9
    80002388:	ffffe097          	auipc	ra,0xffffe
    8000238c:	200080e7          	jalr	512(ra) # 80000588 <printf>
    80002390:	8b26                	mv	s6,s1
        initi = 1;
    80002392:	8962                	mv	s2,s8
    80002394:	a839                	j	800023b2 <SJF_scheduler+0xb0>
      release(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
    for (p = proc + 2; p < &proc[NPROC]; p++)
    800023a0:	18848493          	addi	s1,s1,392
    800023a4:	05448163          	beq	s1,s4,800023e6 <SJF_scheduler+0xe4>
      if (initi == 0 && p->state == RUNNABLE)
    800023a8:	00091563          	bnez	s2,800023b2 <SJF_scheduler+0xb0>
    800023ac:	4c9c                	lw	a5,24(s1)
    800023ae:	fd5787e3          	beq	a5,s5,8000237c <SJF_scheduler+0x7a>
      acquire(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	830080e7          	jalr	-2000(ra) # 80000be4 <acquire>
      if (p->pid != 0 && p->pid != 1 && check_name(p->name) == 0 && p->state == RUNNABLE && p->pause == 0)
    800023bc:	589c                	lw	a5,48(s1)
    800023be:	fcf9fce3          	bgeu	s3,a5,80002396 <SJF_scheduler+0x94>
    800023c2:	17848513          	addi	a0,s1,376
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	480080e7          	jalr	1152(ra) # 80001846 <check_name>
    800023ce:	f561                	bnez	a0,80002396 <SJF_scheduler+0x94>
    800023d0:	4c9c                	lw	a5,24(s1)
    800023d2:	fd5792e3          	bne	a5,s5,80002396 <SJF_scheduler+0x94>
    800023d6:	58dc                	lw	a5,52(s1)
    800023d8:	ffdd                	bnez	a5,80002396 <SJF_scheduler+0x94>
        if (min_ticks <= p->mean_ticks)
    800023da:	5c9c                	lw	a5,56(s1)
    800023dc:	fb77ede3          	bltu	a5,s7,80002396 <SJF_scheduler+0x94>
    800023e0:	8b26                	mv	s6,s1
          min_ticks = p->mean_ticks;
    800023e2:	8bbe                	mv	s7,a5
    800023e4:	bf4d                	j	80002396 <SJF_scheduler+0x94>
    acquire(&min_pointer->lock);
    800023e6:	855a                	mv	a0,s6
    800023e8:	ffffe097          	auipc	ra,0xffffe
    800023ec:	7fc080e7          	jalr	2044(ra) # 80000be4 <acquire>
    update_time(min_pointer);
    800023f0:	855a                	mv	a0,s6
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	506080e7          	jalr	1286(ra) # 800018f8 <update_time>
    min_pointer->state = RUNNING;
    800023fa:	4791                	li	a5,4
    800023fc:	00fb2c23          	sw	a5,24(s6)
    min_pointer->counter = ticks;
    80002400:	000da783          	lw	a5,0(s11)
    80002404:	04fb2823          	sw	a5,80(s6)
    c->proc = min_pointer;
    80002408:	036d3823          	sd	s6,48(s10)
    min_pointer->last_ticks = ticks;
    8000240c:	02fb2e23          	sw	a5,60(s6)
    swtch(&c->context, &min_pointer->context);
    80002410:	080b0593          	addi	a1,s6,128
    80002414:	f8843503          	ld	a0,-120(s0)
    80002418:	00001097          	auipc	ra,0x1
    8000241c:	84e080e7          	jalr	-1970(ra) # 80002c66 <swtch>
    min_pointer->mean_ticks = ((10 - rate) * min_pointer->mean_ticks + min_pointer->last_ticks * (rate)) / 10;
    80002420:	00006617          	auipc	a2,0x6
    80002424:	5a462603          	lw	a2,1444(a2) # 800089c4 <rate>
    80002428:	46a9                	li	a3,10
    8000242a:	40c687bb          	subw	a5,a3,a2
    8000242e:	038b2703          	lw	a4,56(s6)
    80002432:	02e787bb          	mulw	a5,a5,a4
    80002436:	03cb2703          	lw	a4,60(s6)
    8000243a:	02c7073b          	mulw	a4,a4,a2
    8000243e:	9fb9                	addw	a5,a5,a4
    80002440:	02d7d7bb          	divuw	a5,a5,a3
    80002444:	02fb2c23          	sw	a5,56(s6)
    c->proc = 0;
    80002448:	020d3823          	sd	zero,48(s10)
    release(&min_pointer->lock);
    8000244c:	855a                	mv	a0,s6
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
    if (ticks >= p_time && toRelease == 1)
    80002456:	000da583          	lw	a1,0(s11)
    8000245a:	00007617          	auipc	a2,0x7
    8000245e:	bee62603          	lw	a2,-1042(a2) # 80009048 <p_time>
    80002462:	0006079b          	sext.w	a5,a2
    80002466:	00f5e863          	bltu	a1,a5,80002476 <SJF_scheduler+0x174>
    8000246a:	00007797          	auipc	a5,0x7
    8000246e:	bda7a783          	lw	a5,-1062(a5) # 80009044 <toRelease>
    80002472:	01378c63          	beq	a5,s3,8000248a <SJF_scheduler+0x188>
    int initi = 0;
    80002476:	4901                	li	s2,0
    struct proc *min_pointer = proc + 2;
    80002478:	0000fb17          	auipc	s6,0xf
    8000247c:	588b0b13          	addi	s6,s6,1416 # 80011a00 <proc+0x310>
    uint min_ticks = 1000;
    80002480:	3e800b93          	li	s7,1000
    for (p = proc + 2; p < &proc[NPROC]; p++)
    80002484:	84da                	mv	s1,s6
      if (initi == 0 && p->state == RUNNABLE)
    80002486:	4a8d                	li	s5,3
    80002488:	b705                	j	800023a8 <SJF_scheduler+0xa6>
      toRelease = 0;
    8000248a:	00007797          	auipc	a5,0x7
    8000248e:	ba07ad23          	sw	zero,-1094(a5) # 80009044 <toRelease>
      printf("RELEASING! ticks:%d   p_time:%d  \n", ticks, p_time);
    80002492:	00006517          	auipc	a0,0x6
    80002496:	e9e50513          	addi	a0,a0,-354 # 80008330 <digits+0x2f0>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	0ee080e7          	jalr	238(ra) # 80000588 <printf>
      unpause();
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	c60080e7          	jalr	-928(ra) # 80002102 <unpause>
    800024aa:	b7f1                	j	80002476 <SJF_scheduler+0x174>

00000000800024ac <scheduler>:
{
    800024ac:	1141                	addi	sp,sp,-16
    800024ae:	e406                	sd	ra,8(sp)
    800024b0:	e022                	sd	s0,0(sp)
    800024b2:	0800                	addi	s0,sp,16
  printf("FCFS is selected\n");
    800024b4:	00006517          	auipc	a0,0x6
    800024b8:	ee450513          	addi	a0,a0,-284 # 80008398 <digits+0x358>
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	0cc080e7          	jalr	204(ra) # 80000588 <printf>
    FCFS_scheduler();
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	d06080e7          	jalr	-762(ra) # 800021ca <FCFS_scheduler>

00000000800024cc <sched>:
{
    800024cc:	7179                	addi	sp,sp,-48
    800024ce:	f406                	sd	ra,40(sp)
    800024d0:	f022                	sd	s0,32(sp)
    800024d2:	ec26                	sd	s1,24(sp)
    800024d4:	e84a                	sd	s2,16(sp)
    800024d6:	e44e                	sd	s3,8(sp)
    800024d8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	6d8080e7          	jalr	1752(ra) # 80001bb2 <myproc>
    800024e2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	686080e7          	jalr	1670(ra) # 80000b6a <holding>
    800024ec:	c93d                	beqz	a0,80002562 <sched+0x96>
    800024ee:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800024f0:	2781                	sext.w	a5,a5
    800024f2:	079e                	slli	a5,a5,0x7
    800024f4:	0000f717          	auipc	a4,0xf
    800024f8:	dcc70713          	addi	a4,a4,-564 # 800112c0 <pid_lock>
    800024fc:	97ba                	add	a5,a5,a4
    800024fe:	0a87a703          	lw	a4,168(a5)
    80002502:	4785                	li	a5,1
    80002504:	06f71763          	bne	a4,a5,80002572 <sched+0xa6>
  if (p->state == RUNNING)
    80002508:	4c98                	lw	a4,24(s1)
    8000250a:	4791                	li	a5,4
    8000250c:	06f70b63          	beq	a4,a5,80002582 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002510:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002514:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002516:	efb5                	bnez	a5,80002592 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002518:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000251a:	0000f917          	auipc	s2,0xf
    8000251e:	da690913          	addi	s2,s2,-602 # 800112c0 <pid_lock>
    80002522:	2781                	sext.w	a5,a5
    80002524:	079e                	slli	a5,a5,0x7
    80002526:	97ca                	add	a5,a5,s2
    80002528:	0ac7a983          	lw	s3,172(a5)
    8000252c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000252e:	2781                	sext.w	a5,a5
    80002530:	079e                	slli	a5,a5,0x7
    80002532:	0000f597          	auipc	a1,0xf
    80002536:	dc658593          	addi	a1,a1,-570 # 800112f8 <cpus+0x8>
    8000253a:	95be                	add	a1,a1,a5
    8000253c:	08048513          	addi	a0,s1,128
    80002540:	00000097          	auipc	ra,0x0
    80002544:	726080e7          	jalr	1830(ra) # 80002c66 <swtch>
    80002548:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000254a:	2781                	sext.w	a5,a5
    8000254c:	079e                	slli	a5,a5,0x7
    8000254e:	97ca                	add	a5,a5,s2
    80002550:	0b37a623          	sw	s3,172(a5)
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6145                	addi	sp,sp,48
    80002560:	8082                	ret
    panic("sched p->lock");
    80002562:	00006517          	auipc	a0,0x6
    80002566:	e4e50513          	addi	a0,a0,-434 # 800083b0 <digits+0x370>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>
    panic("sched locks");
    80002572:	00006517          	auipc	a0,0x6
    80002576:	e4e50513          	addi	a0,a0,-434 # 800083c0 <digits+0x380>
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	fc4080e7          	jalr	-60(ra) # 8000053e <panic>
    panic("sched running");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	e4e50513          	addi	a0,a0,-434 # 800083d0 <digits+0x390>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	fb4080e7          	jalr	-76(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	e4e50513          	addi	a0,a0,-434 # 800083e0 <digits+0x3a0>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>

00000000800025a2 <yield>:
{
    800025a2:	1101                	addi	sp,sp,-32
    800025a4:	ec06                	sd	ra,24(sp)
    800025a6:	e822                	sd	s0,16(sp)
    800025a8:	e426                	sd	s1,8(sp)
    800025aa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	606080e7          	jalr	1542(ra) # 80001bb2 <myproc>
    800025b4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  update_time(p);
    800025be:	8526                	mv	a0,s1
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	338080e7          	jalr	824(ra) # 800018f8 <update_time>
  p->state = RUNNABLE;
    800025c8:	478d                	li	a5,3
    800025ca:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800025cc:	00007797          	auipc	a5,0x7
    800025d0:	a8c7a783          	lw	a5,-1396(a5) # 80009058 <ticks>
    800025d4:	c0bc                	sw	a5,64(s1)
  p->counter = ticks;
    800025d6:	c8bc                	sw	a5,80(s1)
  sched();
    800025d8:	00000097          	auipc	ra,0x0
    800025dc:	ef4080e7          	jalr	-268(ra) # 800024cc <sched>
  release(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
}
    800025ea:	60e2                	ld	ra,24(sp)
    800025ec:	6442                	ld	s0,16(sp)
    800025ee:	64a2                	ld	s1,8(sp)
    800025f0:	6105                	addi	sp,sp,32
    800025f2:	8082                	ret

00000000800025f4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800025f4:	7179                	addi	sp,sp,-48
    800025f6:	f406                	sd	ra,40(sp)
    800025f8:	f022                	sd	s0,32(sp)
    800025fa:	ec26                	sd	s1,24(sp)
    800025fc:	e84a                	sd	s2,16(sp)
    800025fe:	e44e                	sd	s3,8(sp)
    80002600:	1800                	addi	s0,sp,48
    80002602:	89aa                	mv	s3,a0
    80002604:	892e                	mv	s2,a1

  struct proc *p = myproc();
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	5ac080e7          	jalr	1452(ra) # 80001bb2 <myproc>
    8000260e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
  release(lk);
    80002618:	854a                	mv	a0,s2
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	67e080e7          	jalr	1662(ra) # 80000c98 <release>
  // Go to sleep.
  update_time(p);
    80002622:	8526                	mv	a0,s1
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	2d4080e7          	jalr	724(ra) # 800018f8 <update_time>
  p->chan = chan;
    8000262c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002630:	4789                	li	a5,2
    80002632:	cc9c                	sw	a5,24(s1)
  // printf("CHANGE TO SLEEP, last_ticks:%d   ticks%:%d \n",p->last_ticks,ticks);
  p->counter = ticks;
    80002634:	00007797          	auipc	a5,0x7
    80002638:	a247a783          	lw	a5,-1500(a5) # 80009058 <ticks>
    8000263c:	c8bc                	sw	a5,80(s1)
  p->last_ticks = ticks - p->last_ticks;
    8000263e:	5cd8                	lw	a4,60(s1)
    80002640:	9f99                	subw	a5,a5,a4
    80002642:	dcdc                	sw	a5,60(s1)
  sched();
    80002644:	00000097          	auipc	ra,0x0
    80002648:	e88080e7          	jalr	-376(ra) # 800024cc <sched>

  // Tidy up.
  p->chan = 0;
    8000264c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
  acquire(lk);
    8000265a:	854a                	mv	a0,s2
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	588080e7          	jalr	1416(ra) # 80000be4 <acquire>
}
    80002664:	70a2                	ld	ra,40(sp)
    80002666:	7402                	ld	s0,32(sp)
    80002668:	64e2                	ld	s1,24(sp)
    8000266a:	6942                	ld	s2,16(sp)
    8000266c:	69a2                	ld	s3,8(sp)
    8000266e:	6145                	addi	sp,sp,48
    80002670:	8082                	ret

0000000080002672 <wait>:
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
    80002686:	e062                	sd	s8,0(sp)
    80002688:	0880                	addi	s0,sp,80
    8000268a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	526080e7          	jalr	1318(ra) # 80001bb2 <myproc>
    80002694:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002696:	0000f517          	auipc	a0,0xf
    8000269a:	c4250513          	addi	a0,a0,-958 # 800112d8 <wait_lock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	546080e7          	jalr	1350(ra) # 80000be4 <acquire>
    havekids = 0;
    800026a6:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800026a8:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800026aa:	00015997          	auipc	s3,0x15
    800026ae:	24698993          	addi	s3,s3,582 # 800178f0 <tickslock>
        havekids = 1;
    800026b2:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026b4:	0000fc17          	auipc	s8,0xf
    800026b8:	c24c0c13          	addi	s8,s8,-988 # 800112d8 <wait_lock>
    havekids = 0;
    800026bc:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800026be:	0000f497          	auipc	s1,0xf
    800026c2:	03248493          	addi	s1,s1,50 # 800116f0 <proc>
    800026c6:	a0bd                	j	80002734 <wait+0xc2>
          pid = np->pid;
    800026c8:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026cc:	000b0e63          	beqz	s6,800026e8 <wait+0x76>
    800026d0:	4691                	li	a3,4
    800026d2:	02c48613          	addi	a2,s1,44
    800026d6:	85da                	mv	a1,s6
    800026d8:	07093503          	ld	a0,112(s2)
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	f9e080e7          	jalr	-98(ra) # 8000167a <copyout>
    800026e4:	02054563          	bltz	a0,8000270e <wait+0x9c>
          freeproc(np);
    800026e8:	8526                	mv	a0,s1
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	67a080e7          	jalr	1658(ra) # 80001d64 <freeproc>
          release(&np->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
          release(&wait_lock);
    800026fc:	0000f517          	auipc	a0,0xf
    80002700:	bdc50513          	addi	a0,a0,-1060 # 800112d8 <wait_lock>
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	594080e7          	jalr	1428(ra) # 80000c98 <release>
          return pid;
    8000270c:	a09d                	j	80002772 <wait+0x100>
            release(&np->lock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	588080e7          	jalr	1416(ra) # 80000c98 <release>
            release(&wait_lock);
    80002718:	0000f517          	auipc	a0,0xf
    8000271c:	bc050513          	addi	a0,a0,-1088 # 800112d8 <wait_lock>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	578080e7          	jalr	1400(ra) # 80000c98 <release>
            return -1;
    80002728:	59fd                	li	s3,-1
    8000272a:	a0a1                	j	80002772 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    8000272c:	18848493          	addi	s1,s1,392
    80002730:	03348463          	beq	s1,s3,80002758 <wait+0xe6>
      if (np->parent == p)
    80002734:	6cbc                	ld	a5,88(s1)
    80002736:	ff279be3          	bne	a5,s2,8000272c <wait+0xba>
        acquire(&np->lock);
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	4a8080e7          	jalr	1192(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    80002744:	4c9c                	lw	a5,24(s1)
    80002746:	f94781e3          	beq	a5,s4,800026c8 <wait+0x56>
        release(&np->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	54c080e7          	jalr	1356(ra) # 80000c98 <release>
        havekids = 1;
    80002754:	8756                	mv	a4,s5
    80002756:	bfd9                	j	8000272c <wait+0xba>
    if (!havekids || p->killed)
    80002758:	c701                	beqz	a4,80002760 <wait+0xee>
    8000275a:	02892783          	lw	a5,40(s2)
    8000275e:	c79d                	beqz	a5,8000278c <wait+0x11a>
      release(&wait_lock);
    80002760:	0000f517          	auipc	a0,0xf
    80002764:	b7850513          	addi	a0,a0,-1160 # 800112d8 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	530080e7          	jalr	1328(ra) # 80000c98 <release>
      return -1;
    80002770:	59fd                	li	s3,-1
}
    80002772:	854e                	mv	a0,s3
    80002774:	60a6                	ld	ra,72(sp)
    80002776:	6406                	ld	s0,64(sp)
    80002778:	74e2                	ld	s1,56(sp)
    8000277a:	7942                	ld	s2,48(sp)
    8000277c:	79a2                	ld	s3,40(sp)
    8000277e:	7a02                	ld	s4,32(sp)
    80002780:	6ae2                	ld	s5,24(sp)
    80002782:	6b42                	ld	s6,16(sp)
    80002784:	6ba2                	ld	s7,8(sp)
    80002786:	6c02                	ld	s8,0(sp)
    80002788:	6161                	addi	sp,sp,80
    8000278a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000278c:	85e2                	mv	a1,s8
    8000278e:	854a                	mv	a0,s2
    80002790:	00000097          	auipc	ra,0x0
    80002794:	e64080e7          	jalr	-412(ra) # 800025f4 <sleep>
    havekids = 0;
    80002798:	b715                	j	800026bc <wait+0x4a>

000000008000279a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000279a:	7139                	addi	sp,sp,-64
    8000279c:	fc06                	sd	ra,56(sp)
    8000279e:	f822                	sd	s0,48(sp)
    800027a0:	f426                	sd	s1,40(sp)
    800027a2:	f04a                	sd	s2,32(sp)
    800027a4:	ec4e                	sd	s3,24(sp)
    800027a6:	e852                	sd	s4,16(sp)
    800027a8:	e456                	sd	s5,8(sp)
    800027aa:	e05a                	sd	s6,0(sp)
    800027ac:	0080                	addi	s0,sp,64
    800027ae:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027b0:	0000f497          	auipc	s1,0xf
    800027b4:	f4048493          	addi	s1,s1,-192 # 800116f0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800027b8:	4989                	li	s3,2
      {
        // added update_time and counter
        update_time(p);
        p->state = RUNNABLE;
    800027ba:	4b0d                	li	s6,3
        // added
        p->last_runnable_time = ticks;
    800027bc:	00007a97          	auipc	s5,0x7
    800027c0:	89ca8a93          	addi	s5,s5,-1892 # 80009058 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800027c4:	00015917          	auipc	s2,0x15
    800027c8:	12c90913          	addi	s2,s2,300 # 800178f0 <tickslock>
    800027cc:	a811                	j	800027e0 <wakeup+0x46>
        p->counter = ticks;
      }
      release(&p->lock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	4c8080e7          	jalr	1224(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d8:	18848493          	addi	s1,s1,392
    800027dc:	03248f63          	beq	s1,s2,8000281a <wakeup+0x80>
    if (p != myproc())
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	3d2080e7          	jalr	978(ra) # 80001bb2 <myproc>
    800027e8:	fea488e3          	beq	s1,a0,800027d8 <wakeup+0x3e>
      acquire(&p->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	3f6080e7          	jalr	1014(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800027f6:	4c9c                	lw	a5,24(s1)
    800027f8:	fd379be3          	bne	a5,s3,800027ce <wakeup+0x34>
    800027fc:	709c                	ld	a5,32(s1)
    800027fe:	fd4798e3          	bne	a5,s4,800027ce <wakeup+0x34>
        update_time(p);
    80002802:	8526                	mv	a0,s1
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	0f4080e7          	jalr	244(ra) # 800018f8 <update_time>
        p->state = RUNNABLE;
    8000280c:	0164ac23          	sw	s6,24(s1)
        p->last_runnable_time = ticks;
    80002810:	000aa783          	lw	a5,0(s5)
    80002814:	c0bc                	sw	a5,64(s1)
        p->counter = ticks;
    80002816:	c8bc                	sw	a5,80(s1)
    80002818:	bf5d                	j	800027ce <wakeup+0x34>
    }
  }
}
    8000281a:	70e2                	ld	ra,56(sp)
    8000281c:	7442                	ld	s0,48(sp)
    8000281e:	74a2                	ld	s1,40(sp)
    80002820:	7902                	ld	s2,32(sp)
    80002822:	69e2                	ld	s3,24(sp)
    80002824:	6a42                	ld	s4,16(sp)
    80002826:	6aa2                	ld	s5,8(sp)
    80002828:	6b02                	ld	s6,0(sp)
    8000282a:	6121                	addi	sp,sp,64
    8000282c:	8082                	ret

000000008000282e <reparent>:
{
    8000282e:	7179                	addi	sp,sp,-48
    80002830:	f406                	sd	ra,40(sp)
    80002832:	f022                	sd	s0,32(sp)
    80002834:	ec26                	sd	s1,24(sp)
    80002836:	e84a                	sd	s2,16(sp)
    80002838:	e44e                	sd	s3,8(sp)
    8000283a:	e052                	sd	s4,0(sp)
    8000283c:	1800                	addi	s0,sp,48
    8000283e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002840:	0000f497          	auipc	s1,0xf
    80002844:	eb048493          	addi	s1,s1,-336 # 800116f0 <proc>
      pp->parent = initproc;
    80002848:	00007a17          	auipc	s4,0x7
    8000284c:	808a0a13          	addi	s4,s4,-2040 # 80009050 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002850:	00015997          	auipc	s3,0x15
    80002854:	0a098993          	addi	s3,s3,160 # 800178f0 <tickslock>
    80002858:	a029                	j	80002862 <reparent+0x34>
    8000285a:	18848493          	addi	s1,s1,392
    8000285e:	01348d63          	beq	s1,s3,80002878 <reparent+0x4a>
    if (pp->parent == p)
    80002862:	6cbc                	ld	a5,88(s1)
    80002864:	ff279be3          	bne	a5,s2,8000285a <reparent+0x2c>
      pp->parent = initproc;
    80002868:	000a3503          	ld	a0,0(s4)
    8000286c:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    8000286e:	00000097          	auipc	ra,0x0
    80002872:	f2c080e7          	jalr	-212(ra) # 8000279a <wakeup>
    80002876:	b7d5                	j	8000285a <reparent+0x2c>
}
    80002878:	70a2                	ld	ra,40(sp)
    8000287a:	7402                	ld	s0,32(sp)
    8000287c:	64e2                	ld	s1,24(sp)
    8000287e:	6942                	ld	s2,16(sp)
    80002880:	69a2                	ld	s3,8(sp)
    80002882:	6a02                	ld	s4,0(sp)
    80002884:	6145                	addi	sp,sp,48
    80002886:	8082                	ret

0000000080002888 <exit>:
{
    80002888:	7179                	addi	sp,sp,-48
    8000288a:	f406                	sd	ra,40(sp)
    8000288c:	f022                	sd	s0,32(sp)
    8000288e:	ec26                	sd	s1,24(sp)
    80002890:	e84a                	sd	s2,16(sp)
    80002892:	e44e                	sd	s3,8(sp)
    80002894:	e052                	sd	s4,0(sp)
    80002896:	1800                	addi	s0,sp,48
    80002898:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	318080e7          	jalr	792(ra) # 80001bb2 <myproc>
    800028a2:	89aa                	mv	s3,a0
  if (p == initproc)
    800028a4:	00006797          	auipc	a5,0x6
    800028a8:	7ac7b783          	ld	a5,1964(a5) # 80009050 <initproc>
    800028ac:	0f050493          	addi	s1,a0,240
    800028b0:	17050913          	addi	s2,a0,368
    800028b4:	02a79363          	bne	a5,a0,800028da <exit+0x52>
    panic("init exiting");
    800028b8:	00006517          	auipc	a0,0x6
    800028bc:	b4050513          	addi	a0,a0,-1216 # 800083f8 <digits+0x3b8>
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	c7e080e7          	jalr	-898(ra) # 8000053e <panic>
      fileclose(f);
    800028c8:	00002097          	auipc	ra,0x2
    800028cc:	304080e7          	jalr	772(ra) # 80004bcc <fileclose>
      p->ofile[fd] = 0;
    800028d0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800028d4:	04a1                	addi	s1,s1,8
    800028d6:	01248563          	beq	s1,s2,800028e0 <exit+0x58>
    if (p->ofile[fd])
    800028da:	6088                	ld	a0,0(s1)
    800028dc:	f575                	bnez	a0,800028c8 <exit+0x40>
    800028de:	bfdd                	j	800028d4 <exit+0x4c>
  begin_op();
    800028e0:	00002097          	auipc	ra,0x2
    800028e4:	e20080e7          	jalr	-480(ra) # 80004700 <begin_op>
  iput(p->cwd);
    800028e8:	1709b503          	ld	a0,368(s3)
    800028ec:	00001097          	auipc	ra,0x1
    800028f0:	5fc080e7          	jalr	1532(ra) # 80003ee8 <iput>
  end_op();
    800028f4:	00002097          	auipc	ra,0x2
    800028f8:	e8c080e7          	jalr	-372(ra) # 80004780 <end_op>
  p->cwd = 0;
    800028fc:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002900:	0000f497          	auipc	s1,0xf
    80002904:	9d848493          	addi	s1,s1,-1576 # 800112d8 <wait_lock>
    80002908:	8526                	mv	a0,s1
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	2da080e7          	jalr	730(ra) # 80000be4 <acquire>
  reparent(p);
    80002912:	854e                	mv	a0,s3
    80002914:	00000097          	auipc	ra,0x0
    80002918:	f1a080e7          	jalr	-230(ra) # 8000282e <reparent>
  wakeup(p->parent);
    8000291c:	0589b503          	ld	a0,88(s3)
    80002920:	00000097          	auipc	ra,0x0
    80002924:	e7a080e7          	jalr	-390(ra) # 8000279a <wakeup>
  acquire(&p->lock);
    80002928:	854e                	mv	a0,s3
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	2ba080e7          	jalr	698(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002932:	0349a623          	sw	s4,44(s3)
  update_time(p);
    80002936:	854e                	mv	a0,s3
    80002938:	fffff097          	auipc	ra,0xfffff
    8000293c:	fc0080e7          	jalr	-64(ra) # 800018f8 <update_time>
  p->state = ZOMBIE;
    80002940:	4795                	li	a5,5
    80002942:	00f9ac23          	sw	a5,24(s3)
  update_time_mean(p);
    80002946:	854e                	mv	a0,s3
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	00a080e7          	jalr	10(ra) # 80001952 <update_time_mean>
  release(&wait_lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	346080e7          	jalr	838(ra) # 80000c98 <release>
  sched();
    8000295a:	00000097          	auipc	ra,0x0
    8000295e:	b72080e7          	jalr	-1166(ra) # 800024cc <sched>
  panic("zombie exit");
    80002962:	00006517          	auipc	a0,0x6
    80002966:	aa650513          	addi	a0,a0,-1370 # 80008408 <digits+0x3c8>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	bd4080e7          	jalr	-1068(ra) # 8000053e <panic>

0000000080002972 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002972:	7179                	addi	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	1800                	addi	s0,sp,48
    80002980:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002982:	0000f497          	auipc	s1,0xf
    80002986:	d6e48493          	addi	s1,s1,-658 # 800116f0 <proc>
    8000298a:	00015997          	auipc	s3,0x15
    8000298e:	f6698993          	addi	s3,s3,-154 # 800178f0 <tickslock>
  {
    acquire(&p->lock);
    80002992:	8526                	mv	a0,s1
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	250080e7          	jalr	592(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000299c:	589c                	lw	a5,48(s1)
    8000299e:	01278d63          	beq	a5,s2,800029b8 <kill+0x46>
        p->last_runnable_time = ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800029a2:	8526                	mv	a0,s1
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	2f4080e7          	jalr	756(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800029ac:	18848493          	addi	s1,s1,392
    800029b0:	ff3491e3          	bne	s1,s3,80002992 <kill+0x20>
  }
  return -1;
    800029b4:	557d                	li	a0,-1
    800029b6:	a829                	j	800029d0 <kill+0x5e>
      p->killed = 1;
    800029b8:	4785                	li	a5,1
    800029ba:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800029bc:	4c98                	lw	a4,24(s1)
    800029be:	4789                	li	a5,2
    800029c0:	00f70f63          	beq	a4,a5,800029de <kill+0x6c>
      release(&p->lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	2d2080e7          	jalr	722(ra) # 80000c98 <release>
      return 0;
    800029ce:	4501                	li	a0,0
}
    800029d0:	70a2                	ld	ra,40(sp)
    800029d2:	7402                	ld	s0,32(sp)
    800029d4:	64e2                	ld	s1,24(sp)
    800029d6:	6942                	ld	s2,16(sp)
    800029d8:	69a2                	ld	s3,8(sp)
    800029da:	6145                	addi	sp,sp,48
    800029dc:	8082                	ret
        update_time(p);
    800029de:	8526                	mv	a0,s1
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	f18080e7          	jalr	-232(ra) # 800018f8 <update_time>
        p->state = RUNNABLE;
    800029e8:	478d                	li	a5,3
    800029ea:	cc9c                	sw	a5,24(s1)
        p->counter = ticks;
    800029ec:	00006797          	auipc	a5,0x6
    800029f0:	66c7a783          	lw	a5,1644(a5) # 80009058 <ticks>
    800029f4:	c8bc                	sw	a5,80(s1)
        p->last_runnable_time = ticks;
    800029f6:	c0bc                	sw	a5,64(s1)
    800029f8:	b7f1                	j	800029c4 <kill+0x52>

00000000800029fa <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029fa:	7179                	addi	sp,sp,-48
    800029fc:	f406                	sd	ra,40(sp)
    800029fe:	f022                	sd	s0,32(sp)
    80002a00:	ec26                	sd	s1,24(sp)
    80002a02:	e84a                	sd	s2,16(sp)
    80002a04:	e44e                	sd	s3,8(sp)
    80002a06:	e052                	sd	s4,0(sp)
    80002a08:	1800                	addi	s0,sp,48
    80002a0a:	84aa                	mv	s1,a0
    80002a0c:	892e                	mv	s2,a1
    80002a0e:	89b2                	mv	s3,a2
    80002a10:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	1a0080e7          	jalr	416(ra) # 80001bb2 <myproc>
  if (user_dst)
    80002a1a:	c08d                	beqz	s1,80002a3c <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a1c:	86d2                	mv	a3,s4
    80002a1e:	864e                	mv	a2,s3
    80002a20:	85ca                	mv	a1,s2
    80002a22:	7928                	ld	a0,112(a0)
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	c56080e7          	jalr	-938(ra) # 8000167a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	69a2                	ld	s3,8(sp)
    80002a36:	6a02                	ld	s4,0(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    memmove((char *)dst, src, len);
    80002a3c:	000a061b          	sext.w	a2,s4
    80002a40:	85ce                	mv	a1,s3
    80002a42:	854a                	mv	a0,s2
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	2fc080e7          	jalr	764(ra) # 80000d40 <memmove>
    return 0;
    80002a4c:	8526                	mv	a0,s1
    80002a4e:	bff9                	j	80002a2c <either_copyout+0x32>

0000000080002a50 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a50:	7179                	addi	sp,sp,-48
    80002a52:	f406                	sd	ra,40(sp)
    80002a54:	f022                	sd	s0,32(sp)
    80002a56:	ec26                	sd	s1,24(sp)
    80002a58:	e84a                	sd	s2,16(sp)
    80002a5a:	e44e                	sd	s3,8(sp)
    80002a5c:	e052                	sd	s4,0(sp)
    80002a5e:	1800                	addi	s0,sp,48
    80002a60:	892a                	mv	s2,a0
    80002a62:	84ae                	mv	s1,a1
    80002a64:	89b2                	mv	s3,a2
    80002a66:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	14a080e7          	jalr	330(ra) # 80001bb2 <myproc>
  if (user_src)
    80002a70:	c08d                	beqz	s1,80002a92 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a72:	86d2                	mv	a3,s4
    80002a74:	864e                	mv	a2,s3
    80002a76:	85ca                	mv	a1,s2
    80002a78:	7928                	ld	a0,112(a0)
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	c8c080e7          	jalr	-884(ra) # 80001706 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a82:	70a2                	ld	ra,40(sp)
    80002a84:	7402                	ld	s0,32(sp)
    80002a86:	64e2                	ld	s1,24(sp)
    80002a88:	6942                	ld	s2,16(sp)
    80002a8a:	69a2                	ld	s3,8(sp)
    80002a8c:	6a02                	ld	s4,0(sp)
    80002a8e:	6145                	addi	sp,sp,48
    80002a90:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a92:	000a061b          	sext.w	a2,s4
    80002a96:	85ce                	mv	a1,s3
    80002a98:	854a                	mv	a0,s2
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	2a6080e7          	jalr	678(ra) # 80000d40 <memmove>
    return 0;
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	bff9                	j	80002a82 <either_copyin+0x32>

0000000080002aa6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002aa6:	715d                	addi	sp,sp,-80
    80002aa8:	e486                	sd	ra,72(sp)
    80002aaa:	e0a2                	sd	s0,64(sp)
    80002aac:	fc26                	sd	s1,56(sp)
    80002aae:	f84a                	sd	s2,48(sp)
    80002ab0:	f44e                	sd	s3,40(sp)
    80002ab2:	f052                	sd	s4,32(sp)
    80002ab4:	ec56                	sd	s5,24(sp)
    80002ab6:	e85a                	sd	s6,16(sp)
    80002ab8:	e45e                	sd	s7,8(sp)
    80002aba:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	86c50513          	addi	a0,a0,-1940 # 80008328 <digits+0x2e8>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	ac4080e7          	jalr	-1340(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002acc:	0000f497          	auipc	s1,0xf
    80002ad0:	d9c48493          	addi	s1,s1,-612 # 80011868 <proc+0x178>
    80002ad4:	00015917          	auipc	s2,0x15
    80002ad8:	f9490913          	addi	s2,s2,-108 # 80017a68 <bcache+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002adc:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002ade:	00006997          	auipc	s3,0x6
    80002ae2:	93a98993          	addi	s3,s3,-1734 # 80008418 <digits+0x3d8>
    printf("%d %s %s", p->pid, state, p->name);
    80002ae6:	00006a97          	auipc	s5,0x6
    80002aea:	93aa8a93          	addi	s5,s5,-1734 # 80008420 <digits+0x3e0>
    printf("\n");
    80002aee:	00006a17          	auipc	s4,0x6
    80002af2:	83aa0a13          	addi	s4,s4,-1990 # 80008328 <digits+0x2e8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002af6:	00006b97          	auipc	s7,0x6
    80002afa:	962b8b93          	addi	s7,s7,-1694 # 80008458 <states.1791>
    80002afe:	a00d                	j	80002b20 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b00:	eb86a583          	lw	a1,-328(a3)
    80002b04:	8556                	mv	a0,s5
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a82080e7          	jalr	-1406(ra) # 80000588 <printf>
    printf("\n");
    80002b0e:	8552                	mv	a0,s4
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	a78080e7          	jalr	-1416(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b18:	18848493          	addi	s1,s1,392
    80002b1c:	03248163          	beq	s1,s2,80002b3e <procdump+0x98>
    if (p->state == UNUSED)
    80002b20:	86a6                	mv	a3,s1
    80002b22:	ea04a783          	lw	a5,-352(s1)
    80002b26:	dbed                	beqz	a5,80002b18 <procdump+0x72>
      state = "???";
    80002b28:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b2a:	fcfb6be3          	bltu	s6,a5,80002b00 <procdump+0x5a>
    80002b2e:	1782                	slli	a5,a5,0x20
    80002b30:	9381                	srli	a5,a5,0x20
    80002b32:	078e                	slli	a5,a5,0x3
    80002b34:	97de                	add	a5,a5,s7
    80002b36:	6390                	ld	a2,0(a5)
    80002b38:	f661                	bnez	a2,80002b00 <procdump+0x5a>
      state = "???";
    80002b3a:	864e                	mv	a2,s3
    80002b3c:	b7d1                	j	80002b00 <procdump+0x5a>
  }
}
    80002b3e:	60a6                	ld	ra,72(sp)
    80002b40:	6406                	ld	s0,64(sp)
    80002b42:	74e2                	ld	s1,56(sp)
    80002b44:	7942                	ld	s2,48(sp)
    80002b46:	79a2                	ld	s3,40(sp)
    80002b48:	7a02                	ld	s4,32(sp)
    80002b4a:	6ae2                	ld	s5,24(sp)
    80002b4c:	6b42                	ld	s6,16(sp)
    80002b4e:	6ba2                	ld	s7,8(sp)
    80002b50:	6161                	addi	sp,sp,80
    80002b52:	8082                	ret

0000000080002b54 <pause_system>:

//---------- OUR ADDITION -------------------------

int pause_system(int seconds)
{
    80002b54:	7139                	addi	sp,sp,-64
    80002b56:	fc06                	sd	ra,56(sp)
    80002b58:	f822                	sd	s0,48(sp)
    80002b5a:	f426                	sd	s1,40(sp)
    80002b5c:	f04a                	sd	s2,32(sp)
    80002b5e:	ec4e                	sd	s3,24(sp)
    80002b60:	e852                	sd	s4,16(sp)
    80002b62:	e456                	sd	s5,8(sp)
    80002b64:	e05a                	sd	s6,0(sp)
    80002b66:	0080                	addi	s0,sp,64
    80002b68:	8b2a                	mv	s6,a0
  toRelease = 1;
    80002b6a:	4785                	li	a5,1
    80002b6c:	00006717          	auipc	a4,0x6
    80002b70:	4cf72c23          	sw	a5,1240(a4) # 80009044 <toRelease>

  int sec = 10; //!!!!!!!!!!!!!!!!!!! CHANGE TO 10e6
  p_time = ticks + seconds * sec;
    80002b74:	0025179b          	slliw	a5,a0,0x2
    80002b78:	9fa9                	addw	a5,a5,a0
    80002b7a:	0017979b          	slliw	a5,a5,0x1
    80002b7e:	00006717          	auipc	a4,0x6
    80002b82:	4da72703          	lw	a4,1242(a4) # 80009058 <ticks>
    80002b86:	9fb9                	addw	a5,a5,a4
    80002b88:	00006717          	auipc	a4,0x6
    80002b8c:	4cf72023          	sw	a5,1216(a4) # 80009048 <p_time>
  // struct proc *p = myproc();
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002b90:	0000f497          	auipc	s1,0xf
    80002b94:	b6048493          	addi	s1,s1,-1184 # 800116f0 <proc>
    int x = check_name(p->name);
    //  printf("x=%d, name:%s\n" ,x,p->name);
    // printf("PID: %d STATE: %d  name: %s\n", p->pid, p->state, p->name);
    if (x == 0)
    {
      p->pause = 1;
    80002b98:	4a05                	li	s4,1
      // printf("PID: %d STATE: %d  name: %s pause_flag is on\n", p->pid, p->state,p->name);
    }
    release(&p->lock);
    if (p->pause == 1 && p->state == 4)
    80002b9a:	4985                	li	s3,1
    80002b9c:	4a91                	li	s5,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002b9e:	00015917          	auipc	s2,0x15
    80002ba2:	d5290913          	addi	s2,s2,-686 # 800178f0 <tickslock>
    80002ba6:	a829                	j	80002bc0 <pause_system+0x6c>
    release(&p->lock);
    80002ba8:	8526                	mv	a0,s1
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	0ee080e7          	jalr	238(ra) # 80000c98 <release>
    if (p->pause == 1 && p->state == 4)
    80002bb2:	58dc                	lw	a5,52(s1)
    80002bb4:	03378563          	beq	a5,s3,80002bde <pause_system+0x8a>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bb8:	18848493          	addi	s1,s1,392
    80002bbc:	03248963          	beq	s1,s2,80002bee <pause_system+0x9a>
    acquire(&p->lock);
    80002bc0:	8526                	mv	a0,s1
    80002bc2:	ffffe097          	auipc	ra,0xffffe
    80002bc6:	022080e7          	jalr	34(ra) # 80000be4 <acquire>
    int x = check_name(p->name);
    80002bca:	17848513          	addi	a0,s1,376
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	c78080e7          	jalr	-904(ra) # 80001846 <check_name>
    if (x == 0)
    80002bd6:	f969                	bnez	a0,80002ba8 <pause_system+0x54>
      p->pause = 1;
    80002bd8:	0344aa23          	sw	s4,52(s1)
    80002bdc:	b7f1                	j	80002ba8 <pause_system+0x54>
    if (p->pause == 1 && p->state == 4)
    80002bde:	4c9c                	lw	a5,24(s1)
    80002be0:	fd579ce3          	bne	a5,s5,80002bb8 <pause_system+0x64>
    {
      // printf("myproc: %d\n",myproc()->pid);
      yield();
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	9be080e7          	jalr	-1602(ra) # 800025a2 <yield>
    80002bec:	b7f1                	j	80002bb8 <pause_system+0x64>
    }
    // printf("PID: %d STATE: %d  pause_flag: %d\n", p->pid, p->state,p->pause);
  }

  return seconds;
}
    80002bee:	855a                	mv	a0,s6
    80002bf0:	70e2                	ld	ra,56(sp)
    80002bf2:	7442                	ld	s0,48(sp)
    80002bf4:	74a2                	ld	s1,40(sp)
    80002bf6:	7902                	ld	s2,32(sp)
    80002bf8:	69e2                	ld	s3,24(sp)
    80002bfa:	6a42                	ld	s4,16(sp)
    80002bfc:	6aa2                	ld	s5,8(sp)
    80002bfe:	6b02                	ld	s6,0(sp)
    80002c00:	6121                	addi	sp,sp,64
    80002c02:	8082                	ret

0000000080002c04 <kill_system>:

int kill_system(void)
{
    80002c04:	7179                	addi	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	e44e                	sd	s3,8(sp)
    80002c10:	1800                	addi	s0,sp,48
  struct proc *p;
  // int my_pid = myproc()->pid;
  for (p = proc; p < &proc[NPROC]; p++)
    80002c12:	0000f497          	auipc	s1,0xf
    80002c16:	c5648493          	addi	s1,s1,-938 # 80011868 <proc+0x178>
    80002c1a:	00015997          	auipc	s3,0x15
    80002c1e:	e4e98993          	addi	s3,s3,-434 # 80017a68 <bcache+0x160>
    80002c22:	a029                	j	80002c2c <kill_system+0x28>
    80002c24:	18848493          	addi	s1,s1,392
    80002c28:	03348763          	beq	s1,s3,80002c56 <kill_system+0x52>
  {

    int x = check_name(p->name);
    80002c2c:	8526                	mv	a0,s1
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	c18080e7          	jalr	-1000(ra) # 80001846 <check_name>
    if (x == 0 && p != myproc())
    80002c36:	f57d                	bnez	a0,80002c24 <kill_system+0x20>
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	f7a080e7          	jalr	-134(ra) # 80001bb2 <myproc>
    80002c40:	e8848793          	addi	a5,s1,-376
    80002c44:	fef500e3          	beq	a0,a5,80002c24 <kill_system+0x20>
    {
      kill(p->pid);
    80002c48:	eb84a503          	lw	a0,-328(s1)
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	d26080e7          	jalr	-730(ra) # 80002972 <kill>
    80002c54:	bfc1                	j	80002c24 <kill_system+0x20>
    }
  }

  return 0;
    80002c56:	4501                	li	a0,0
    80002c58:	70a2                	ld	ra,40(sp)
    80002c5a:	7402                	ld	s0,32(sp)
    80002c5c:	64e2                	ld	s1,24(sp)
    80002c5e:	6942                	ld	s2,16(sp)
    80002c60:	69a2                	ld	s3,8(sp)
    80002c62:	6145                	addi	sp,sp,48
    80002c64:	8082                	ret

0000000080002c66 <swtch>:
    80002c66:	00153023          	sd	ra,0(a0)
    80002c6a:	00253423          	sd	sp,8(a0)
    80002c6e:	e900                	sd	s0,16(a0)
    80002c70:	ed04                	sd	s1,24(a0)
    80002c72:	03253023          	sd	s2,32(a0)
    80002c76:	03353423          	sd	s3,40(a0)
    80002c7a:	03453823          	sd	s4,48(a0)
    80002c7e:	03553c23          	sd	s5,56(a0)
    80002c82:	05653023          	sd	s6,64(a0)
    80002c86:	05753423          	sd	s7,72(a0)
    80002c8a:	05853823          	sd	s8,80(a0)
    80002c8e:	05953c23          	sd	s9,88(a0)
    80002c92:	07a53023          	sd	s10,96(a0)
    80002c96:	07b53423          	sd	s11,104(a0)
    80002c9a:	0005b083          	ld	ra,0(a1)
    80002c9e:	0085b103          	ld	sp,8(a1)
    80002ca2:	6980                	ld	s0,16(a1)
    80002ca4:	6d84                	ld	s1,24(a1)
    80002ca6:	0205b903          	ld	s2,32(a1)
    80002caa:	0285b983          	ld	s3,40(a1)
    80002cae:	0305ba03          	ld	s4,48(a1)
    80002cb2:	0385ba83          	ld	s5,56(a1)
    80002cb6:	0405bb03          	ld	s6,64(a1)
    80002cba:	0485bb83          	ld	s7,72(a1)
    80002cbe:	0505bc03          	ld	s8,80(a1)
    80002cc2:	0585bc83          	ld	s9,88(a1)
    80002cc6:	0605bd03          	ld	s10,96(a1)
    80002cca:	0685bd83          	ld	s11,104(a1)
    80002cce:	8082                	ret

0000000080002cd0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cd0:	1141                	addi	sp,sp,-16
    80002cd2:	e406                	sd	ra,8(sp)
    80002cd4:	e022                	sd	s0,0(sp)
    80002cd6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cd8:	00005597          	auipc	a1,0x5
    80002cdc:	7b058593          	addi	a1,a1,1968 # 80008488 <states.1791+0x30>
    80002ce0:	00015517          	auipc	a0,0x15
    80002ce4:	c1050513          	addi	a0,a0,-1008 # 800178f0 <tickslock>
    80002ce8:	ffffe097          	auipc	ra,0xffffe
    80002cec:	e6c080e7          	jalr	-404(ra) # 80000b54 <initlock>
}
    80002cf0:	60a2                	ld	ra,8(sp)
    80002cf2:	6402                	ld	s0,0(sp)
    80002cf4:	0141                	addi	sp,sp,16
    80002cf6:	8082                	ret

0000000080002cf8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cf8:	1141                	addi	sp,sp,-16
    80002cfa:	e422                	sd	s0,8(sp)
    80002cfc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cfe:	00003797          	auipc	a5,0x3
    80002d02:	4e278793          	addi	a5,a5,1250 # 800061e0 <kernelvec>
    80002d06:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d0a:	6422                	ld	s0,8(sp)
    80002d0c:	0141                	addi	sp,sp,16
    80002d0e:	8082                	ret

0000000080002d10 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d10:	1141                	addi	sp,sp,-16
    80002d12:	e406                	sd	ra,8(sp)
    80002d14:	e022                	sd	s0,0(sp)
    80002d16:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	e9a080e7          	jalr	-358(ra) # 80001bb2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d24:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d26:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d2a:	00004617          	auipc	a2,0x4
    80002d2e:	2d660613          	addi	a2,a2,726 # 80007000 <_trampoline>
    80002d32:	00004697          	auipc	a3,0x4
    80002d36:	2ce68693          	addi	a3,a3,718 # 80007000 <_trampoline>
    80002d3a:	8e91                	sub	a3,a3,a2
    80002d3c:	040007b7          	lui	a5,0x4000
    80002d40:	17fd                	addi	a5,a5,-1
    80002d42:	07b2                	slli	a5,a5,0xc
    80002d44:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d46:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d4a:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d4c:	180026f3          	csrr	a3,satp
    80002d50:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d52:	7d38                	ld	a4,120(a0)
    80002d54:	7134                	ld	a3,96(a0)
    80002d56:	6585                	lui	a1,0x1
    80002d58:	96ae                	add	a3,a3,a1
    80002d5a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d5c:	7d38                	ld	a4,120(a0)
    80002d5e:	00000697          	auipc	a3,0x0
    80002d62:	13868693          	addi	a3,a3,312 # 80002e96 <usertrap>
    80002d66:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d68:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d6a:	8692                	mv	a3,tp
    80002d6c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d72:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d76:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d7a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d7e:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d80:	6f18                	ld	a4,24(a4)
    80002d82:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d86:	792c                	ld	a1,112(a0)
    80002d88:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d8a:	00004717          	auipc	a4,0x4
    80002d8e:	30670713          	addi	a4,a4,774 # 80007090 <userret>
    80002d92:	8f11                	sub	a4,a4,a2
    80002d94:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d96:	577d                	li	a4,-1
    80002d98:	177e                	slli	a4,a4,0x3f
    80002d9a:	8dd9                	or	a1,a1,a4
    80002d9c:	02000537          	lui	a0,0x2000
    80002da0:	157d                	addi	a0,a0,-1
    80002da2:	0536                	slli	a0,a0,0xd
    80002da4:	9782                	jalr	a5
}
    80002da6:	60a2                	ld	ra,8(sp)
    80002da8:	6402                	ld	s0,0(sp)
    80002daa:	0141                	addi	sp,sp,16
    80002dac:	8082                	ret

0000000080002dae <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	e426                	sd	s1,8(sp)
    80002db6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002db8:	00015497          	auipc	s1,0x15
    80002dbc:	b3848493          	addi	s1,s1,-1224 # 800178f0 <tickslock>
    80002dc0:	8526                	mv	a0,s1
    80002dc2:	ffffe097          	auipc	ra,0xffffe
    80002dc6:	e22080e7          	jalr	-478(ra) # 80000be4 <acquire>
  ticks++;
    80002dca:	00006517          	auipc	a0,0x6
    80002dce:	28e50513          	addi	a0,a0,654 # 80009058 <ticks>
    80002dd2:	411c                	lw	a5,0(a0)
    80002dd4:	2785                	addiw	a5,a5,1
    80002dd6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	9c2080e7          	jalr	-1598(ra) # 8000279a <wakeup>
  release(&tickslock);
    80002de0:	8526                	mv	a0,s1
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	eb6080e7          	jalr	-330(ra) # 80000c98 <release>
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	64a2                	ld	s1,8(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dfe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e02:	00074d63          	bltz	a4,80002e1c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e06:	57fd                	li	a5,-1
    80002e08:	17fe                	slli	a5,a5,0x3f
    80002e0a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e0c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e0e:	06f70363          	beq	a4,a5,80002e74 <devintr+0x80>
  }
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret
     (scause & 0xff) == 9){
    80002e1c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e20:	46a5                	li	a3,9
    80002e22:	fed792e3          	bne	a5,a3,80002e06 <devintr+0x12>
    int irq = plic_claim();
    80002e26:	00003097          	auipc	ra,0x3
    80002e2a:	4c2080e7          	jalr	1218(ra) # 800062e8 <plic_claim>
    80002e2e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e30:	47a9                	li	a5,10
    80002e32:	02f50763          	beq	a0,a5,80002e60 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e36:	4785                	li	a5,1
    80002e38:	02f50963          	beq	a0,a5,80002e6a <devintr+0x76>
    return 1;
    80002e3c:	4505                	li	a0,1
    } else if(irq){
    80002e3e:	d8f1                	beqz	s1,80002e12 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e40:	85a6                	mv	a1,s1
    80002e42:	00005517          	auipc	a0,0x5
    80002e46:	64e50513          	addi	a0,a0,1614 # 80008490 <states.1791+0x38>
    80002e4a:	ffffd097          	auipc	ra,0xffffd
    80002e4e:	73e080e7          	jalr	1854(ra) # 80000588 <printf>
      plic_complete(irq);
    80002e52:	8526                	mv	a0,s1
    80002e54:	00003097          	auipc	ra,0x3
    80002e58:	4b8080e7          	jalr	1208(ra) # 8000630c <plic_complete>
    return 1;
    80002e5c:	4505                	li	a0,1
    80002e5e:	bf55                	j	80002e12 <devintr+0x1e>
      uartintr();
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	b48080e7          	jalr	-1208(ra) # 800009a8 <uartintr>
    80002e68:	b7ed                	j	80002e52 <devintr+0x5e>
      virtio_disk_intr();
    80002e6a:	00004097          	auipc	ra,0x4
    80002e6e:	982080e7          	jalr	-1662(ra) # 800067ec <virtio_disk_intr>
    80002e72:	b7c5                	j	80002e52 <devintr+0x5e>
    if(cpuid() == 0){
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	d12080e7          	jalr	-750(ra) # 80001b86 <cpuid>
    80002e7c:	c901                	beqz	a0,80002e8c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e7e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e82:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e84:	14479073          	csrw	sip,a5
    return 2;
    80002e88:	4509                	li	a0,2
    80002e8a:	b761                	j	80002e12 <devintr+0x1e>
      clockintr();
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	f22080e7          	jalr	-222(ra) # 80002dae <clockintr>
    80002e94:	b7ed                	j	80002e7e <devintr+0x8a>

0000000080002e96 <usertrap>:
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	e04a                	sd	s2,0(sp)
    80002ea0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ea6:	1007f793          	andi	a5,a5,256
    80002eaa:	e3ad                	bnez	a5,80002f0c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eac:	00003797          	auipc	a5,0x3
    80002eb0:	33478793          	addi	a5,a5,820 # 800061e0 <kernelvec>
    80002eb4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	cfa080e7          	jalr	-774(ra) # 80001bb2 <myproc>
    80002ec0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ec2:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec4:	14102773          	csrr	a4,sepc
    80002ec8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eca:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ece:	47a1                	li	a5,8
    80002ed0:	04f71c63          	bne	a4,a5,80002f28 <usertrap+0x92>
    if(p->killed)
    80002ed4:	551c                	lw	a5,40(a0)
    80002ed6:	e3b9                	bnez	a5,80002f1c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ed8:	7cb8                	ld	a4,120(s1)
    80002eda:	6f1c                	ld	a5,24(a4)
    80002edc:	0791                	addi	a5,a5,4
    80002ede:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ee4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ee8:	10079073          	csrw	sstatus,a5
    syscall();
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	2e0080e7          	jalr	736(ra) # 800031cc <syscall>
  if(p->killed)
    80002ef4:	549c                	lw	a5,40(s1)
    80002ef6:	ebc1                	bnez	a5,80002f86 <usertrap+0xf0>
  usertrapret();
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	e18080e7          	jalr	-488(ra) # 80002d10 <usertrapret>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6902                	ld	s2,0(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret
    panic("usertrap: not from user mode");
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	5a450513          	addi	a0,a0,1444 # 800084b0 <states.1791+0x58>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	62a080e7          	jalr	1578(ra) # 8000053e <panic>
      exit(-1);
    80002f1c:	557d                	li	a0,-1
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	96a080e7          	jalr	-1686(ra) # 80002888 <exit>
    80002f26:	bf4d                	j	80002ed8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	ecc080e7          	jalr	-308(ra) # 80002df4 <devintr>
    80002f30:	892a                	mv	s2,a0
    80002f32:	c501                	beqz	a0,80002f3a <usertrap+0xa4>
  if(p->killed)
    80002f34:	549c                	lw	a5,40(s1)
    80002f36:	c3a1                	beqz	a5,80002f76 <usertrap+0xe0>
    80002f38:	a815                	j	80002f6c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f3a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f3e:	5890                	lw	a2,48(s1)
    80002f40:	00005517          	auipc	a0,0x5
    80002f44:	59050513          	addi	a0,a0,1424 # 800084d0 <states.1791+0x78>
    80002f48:	ffffd097          	auipc	ra,0xffffd
    80002f4c:	640080e7          	jalr	1600(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f50:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f54:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f58:	00005517          	auipc	a0,0x5
    80002f5c:	5a850513          	addi	a0,a0,1448 # 80008500 <states.1791+0xa8>
    80002f60:	ffffd097          	auipc	ra,0xffffd
    80002f64:	628080e7          	jalr	1576(ra) # 80000588 <printf>
    p->killed = 1;
    80002f68:	4785                	li	a5,1
    80002f6a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f6c:	557d                	li	a0,-1
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	91a080e7          	jalr	-1766(ra) # 80002888 <exit>
  if(which_dev == 2){
    80002f76:	4789                	li	a5,2
    80002f78:	f8f910e3          	bne	s2,a5,80002ef8 <usertrap+0x62>
    yield();
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	626080e7          	jalr	1574(ra) # 800025a2 <yield>
    80002f84:	bf95                	j	80002ef8 <usertrap+0x62>
  int which_dev = 0;
    80002f86:	4901                	li	s2,0
    80002f88:	b7d5                	j	80002f6c <usertrap+0xd6>

0000000080002f8a <kerneltrap>:
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	e84a                	sd	s2,16(sp)
    80002f94:	e44e                	sd	s3,8(sp)
    80002f96:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f98:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f9c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fa0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fa4:	1004f793          	andi	a5,s1,256
    80002fa8:	cb85                	beqz	a5,80002fd8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002faa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fae:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fb0:	ef85                	bnez	a5,80002fe8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fb2:	00000097          	auipc	ra,0x0
    80002fb6:	e42080e7          	jalr	-446(ra) # 80002df4 <devintr>
    80002fba:	cd1d                	beqz	a0,80002ff8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002fbc:	4789                	li	a5,2
    80002fbe:	06f50a63          	beq	a0,a5,80003032 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fc2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fc6:	10049073          	csrw	sstatus,s1
}
    80002fca:	70a2                	ld	ra,40(sp)
    80002fcc:	7402                	ld	s0,32(sp)
    80002fce:	64e2                	ld	s1,24(sp)
    80002fd0:	6942                	ld	s2,16(sp)
    80002fd2:	69a2                	ld	s3,8(sp)
    80002fd4:	6145                	addi	sp,sp,48
    80002fd6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fd8:	00005517          	auipc	a0,0x5
    80002fdc:	54850513          	addi	a0,a0,1352 # 80008520 <states.1791+0xc8>
    80002fe0:	ffffd097          	auipc	ra,0xffffd
    80002fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	56050513          	addi	a0,a0,1376 # 80008548 <states.1791+0xf0>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ff8:	85ce                	mv	a1,s3
    80002ffa:	00005517          	auipc	a0,0x5
    80002ffe:	56e50513          	addi	a0,a0,1390 # 80008568 <states.1791+0x110>
    80003002:	ffffd097          	auipc	ra,0xffffd
    80003006:	586080e7          	jalr	1414(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000300a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000300e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003012:	00005517          	auipc	a0,0x5
    80003016:	56650513          	addi	a0,a0,1382 # 80008578 <states.1791+0x120>
    8000301a:	ffffd097          	auipc	ra,0xffffd
    8000301e:	56e080e7          	jalr	1390(ra) # 80000588 <printf>
    panic("kerneltrap");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	56e50513          	addi	a0,a0,1390 # 80008590 <states.1791+0x138>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	514080e7          	jalr	1300(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	b80080e7          	jalr	-1152(ra) # 80001bb2 <myproc>
    8000303a:	d541                	beqz	a0,80002fc2 <kerneltrap+0x38>
    8000303c:	fffff097          	auipc	ra,0xfffff
    80003040:	b76080e7          	jalr	-1162(ra) # 80001bb2 <myproc>
    80003044:	4d18                	lw	a4,24(a0)
    80003046:	4791                	li	a5,4
    80003048:	f6f71de3          	bne	a4,a5,80002fc2 <kerneltrap+0x38>
    yield();
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	556080e7          	jalr	1366(ra) # 800025a2 <yield>
    80003054:	b7bd                	j	80002fc2 <kerneltrap+0x38>

0000000080003056 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	b50080e7          	jalr	-1200(ra) # 80001bb2 <myproc>
  switch (n) {
    8000306a:	4795                	li	a5,5
    8000306c:	0497e163          	bltu	a5,s1,800030ae <argraw+0x58>
    80003070:	048a                	slli	s1,s1,0x2
    80003072:	00005717          	auipc	a4,0x5
    80003076:	55670713          	addi	a4,a4,1366 # 800085c8 <states.1791+0x170>
    8000307a:	94ba                	add	s1,s1,a4
    8000307c:	409c                	lw	a5,0(s1)
    8000307e:	97ba                	add	a5,a5,a4
    80003080:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003082:	7d3c                	ld	a5,120(a0)
    80003084:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003086:	60e2                	ld	ra,24(sp)
    80003088:	6442                	ld	s0,16(sp)
    8000308a:	64a2                	ld	s1,8(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret
    return p->trapframe->a1;
    80003090:	7d3c                	ld	a5,120(a0)
    80003092:	7fa8                	ld	a0,120(a5)
    80003094:	bfcd                	j	80003086 <argraw+0x30>
    return p->trapframe->a2;
    80003096:	7d3c                	ld	a5,120(a0)
    80003098:	63c8                	ld	a0,128(a5)
    8000309a:	b7f5                	j	80003086 <argraw+0x30>
    return p->trapframe->a3;
    8000309c:	7d3c                	ld	a5,120(a0)
    8000309e:	67c8                	ld	a0,136(a5)
    800030a0:	b7dd                	j	80003086 <argraw+0x30>
    return p->trapframe->a4;
    800030a2:	7d3c                	ld	a5,120(a0)
    800030a4:	6bc8                	ld	a0,144(a5)
    800030a6:	b7c5                	j	80003086 <argraw+0x30>
    return p->trapframe->a5;
    800030a8:	7d3c                	ld	a5,120(a0)
    800030aa:	6fc8                	ld	a0,152(a5)
    800030ac:	bfe9                	j	80003086 <argraw+0x30>
  panic("argraw");
    800030ae:	00005517          	auipc	a0,0x5
    800030b2:	4f250513          	addi	a0,a0,1266 # 800085a0 <states.1791+0x148>
    800030b6:	ffffd097          	auipc	ra,0xffffd
    800030ba:	488080e7          	jalr	1160(ra) # 8000053e <panic>

00000000800030be <fetchaddr>:
{
    800030be:	1101                	addi	sp,sp,-32
    800030c0:	ec06                	sd	ra,24(sp)
    800030c2:	e822                	sd	s0,16(sp)
    800030c4:	e426                	sd	s1,8(sp)
    800030c6:	e04a                	sd	s2,0(sp)
    800030c8:	1000                	addi	s0,sp,32
    800030ca:	84aa                	mv	s1,a0
    800030cc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	ae4080e7          	jalr	-1308(ra) # 80001bb2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030d6:	753c                	ld	a5,104(a0)
    800030d8:	02f4f863          	bgeu	s1,a5,80003108 <fetchaddr+0x4a>
    800030dc:	00848713          	addi	a4,s1,8
    800030e0:	02e7e663          	bltu	a5,a4,8000310c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030e4:	46a1                	li	a3,8
    800030e6:	8626                	mv	a2,s1
    800030e8:	85ca                	mv	a1,s2
    800030ea:	7928                	ld	a0,112(a0)
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	61a080e7          	jalr	1562(ra) # 80001706 <copyin>
    800030f4:	00a03533          	snez	a0,a0
    800030f8:	40a00533          	neg	a0,a0
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6902                	ld	s2,0(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret
    return -1;
    80003108:	557d                	li	a0,-1
    8000310a:	bfcd                	j	800030fc <fetchaddr+0x3e>
    8000310c:	557d                	li	a0,-1
    8000310e:	b7fd                	j	800030fc <fetchaddr+0x3e>

0000000080003110 <fetchstr>:
{
    80003110:	7179                	addi	sp,sp,-48
    80003112:	f406                	sd	ra,40(sp)
    80003114:	f022                	sd	s0,32(sp)
    80003116:	ec26                	sd	s1,24(sp)
    80003118:	e84a                	sd	s2,16(sp)
    8000311a:	e44e                	sd	s3,8(sp)
    8000311c:	1800                	addi	s0,sp,48
    8000311e:	892a                	mv	s2,a0
    80003120:	84ae                	mv	s1,a1
    80003122:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003124:	fffff097          	auipc	ra,0xfffff
    80003128:	a8e080e7          	jalr	-1394(ra) # 80001bb2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000312c:	86ce                	mv	a3,s3
    8000312e:	864a                	mv	a2,s2
    80003130:	85a6                	mv	a1,s1
    80003132:	7928                	ld	a0,112(a0)
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	65e080e7          	jalr	1630(ra) # 80001792 <copyinstr>
  if(err < 0)
    8000313c:	00054763          	bltz	a0,8000314a <fetchstr+0x3a>
  return strlen(buf);
    80003140:	8526                	mv	a0,s1
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	d22080e7          	jalr	-734(ra) # 80000e64 <strlen>
}
    8000314a:	70a2                	ld	ra,40(sp)
    8000314c:	7402                	ld	s0,32(sp)
    8000314e:	64e2                	ld	s1,24(sp)
    80003150:	6942                	ld	s2,16(sp)
    80003152:	69a2                	ld	s3,8(sp)
    80003154:	6145                	addi	sp,sp,48
    80003156:	8082                	ret

0000000080003158 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	e426                	sd	s1,8(sp)
    80003160:	1000                	addi	s0,sp,32
    80003162:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003164:	00000097          	auipc	ra,0x0
    80003168:	ef2080e7          	jalr	-270(ra) # 80003056 <argraw>
    8000316c:	c088                	sw	a0,0(s1)
  return 0;
}
    8000316e:	4501                	li	a0,0
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret

000000008000317a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	e426                	sd	s1,8(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	ed0080e7          	jalr	-304(ra) # 80003056 <argraw>
    8000318e:	e088                	sd	a0,0(s1)
  return 0;
}
    80003190:	4501                	li	a0,0
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret

000000008000319c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	e426                	sd	s1,8(sp)
    800031a4:	e04a                	sd	s2,0(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84ae                	mv	s1,a1
    800031aa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	eaa080e7          	jalr	-342(ra) # 80003056 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031b4:	864a                	mv	a2,s2
    800031b6:	85a6                	mv	a1,s1
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	f58080e7          	jalr	-168(ra) # 80003110 <fetchstr>
}
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6902                	ld	s2,0(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret

00000000800031cc <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    800031cc:	1101                	addi	sp,sp,-32
    800031ce:	ec06                	sd	ra,24(sp)
    800031d0:	e822                	sd	s0,16(sp)
    800031d2:	e426                	sd	s1,8(sp)
    800031d4:	e04a                	sd	s2,0(sp)
    800031d6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	9da080e7          	jalr	-1574(ra) # 80001bb2 <myproc>
    800031e0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031e2:	07853903          	ld	s2,120(a0)
    800031e6:	0a893783          	ld	a5,168(s2)
    800031ea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031ee:	37fd                	addiw	a5,a5,-1
    800031f0:	475d                	li	a4,23
    800031f2:	00f76f63          	bltu	a4,a5,80003210 <syscall+0x44>
    800031f6:	00369713          	slli	a4,a3,0x3
    800031fa:	00005797          	auipc	a5,0x5
    800031fe:	3e678793          	addi	a5,a5,998 # 800085e0 <syscalls>
    80003202:	97ba                	add	a5,a5,a4
    80003204:	639c                	ld	a5,0(a5)
    80003206:	c789                	beqz	a5,80003210 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003208:	9782                	jalr	a5
    8000320a:	06a93823          	sd	a0,112(s2)
    8000320e:	a839                	j	8000322c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003210:	17848613          	addi	a2,s1,376
    80003214:	588c                	lw	a1,48(s1)
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	39250513          	addi	a0,a0,914 # 800085a8 <states.1791+0x150>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	36a080e7          	jalr	874(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003226:	7cbc                	ld	a5,120(s1)
    80003228:	577d                	li	a4,-1
    8000322a:	fbb8                	sd	a4,112(a5)
  }
}
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6902                	ld	s2,0(sp)
    80003234:	6105                	addi	sp,sp,32
    80003236:	8082                	ret

0000000080003238 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003238:	1101                	addi	sp,sp,-32
    8000323a:	ec06                	sd	ra,24(sp)
    8000323c:	e822                	sd	s0,16(sp)
    8000323e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003240:	fec40593          	addi	a1,s0,-20
    80003244:	4501                	li	a0,0
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	f12080e7          	jalr	-238(ra) # 80003158 <argint>
    return -1;
    8000324e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003250:	00054963          	bltz	a0,80003262 <sys_exit+0x2a>
  exit(n);
    80003254:	fec42503          	lw	a0,-20(s0)
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	630080e7          	jalr	1584(ra) # 80002888 <exit>
  return 0;  // not reached
    80003260:	4781                	li	a5,0
}
    80003262:	853e                	mv	a0,a5
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	6105                	addi	sp,sp,32
    8000326a:	8082                	ret

000000008000326c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000326c:	1141                	addi	sp,sp,-16
    8000326e:	e406                	sd	ra,8(sp)
    80003270:	e022                	sd	s0,0(sp)
    80003272:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	93e080e7          	jalr	-1730(ra) # 80001bb2 <myproc>
}
    8000327c:	5908                	lw	a0,48(a0)
    8000327e:	60a2                	ld	ra,8(sp)
    80003280:	6402                	ld	s0,0(sp)
    80003282:	0141                	addi	sp,sp,16
    80003284:	8082                	ret

0000000080003286 <sys_fork>:

uint64
sys_fork(void)
{
    80003286:	1141                	addi	sp,sp,-16
    80003288:	e406                	sd	ra,8(sp)
    8000328a:	e022                	sd	s0,0(sp)
    8000328c:	0800                	addi	s0,sp,16
  return fork();
    8000328e:	fffff097          	auipc	ra,0xfffff
    80003292:	d1e080e7          	jalr	-738(ra) # 80001fac <fork>
}
    80003296:	60a2                	ld	ra,8(sp)
    80003298:	6402                	ld	s0,0(sp)
    8000329a:	0141                	addi	sp,sp,16
    8000329c:	8082                	ret

000000008000329e <sys_wait>:

uint64
sys_wait(void)
{
    8000329e:	1101                	addi	sp,sp,-32
    800032a0:	ec06                	sd	ra,24(sp)
    800032a2:	e822                	sd	s0,16(sp)
    800032a4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032a6:	fe840593          	addi	a1,s0,-24
    800032aa:	4501                	li	a0,0
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	ece080e7          	jalr	-306(ra) # 8000317a <argaddr>
    800032b4:	87aa                	mv	a5,a0
    return -1;
    800032b6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032b8:	0007c863          	bltz	a5,800032c8 <sys_wait+0x2a>
  return wait(p);
    800032bc:	fe843503          	ld	a0,-24(s0)
    800032c0:	fffff097          	auipc	ra,0xfffff
    800032c4:	3b2080e7          	jalr	946(ra) # 80002672 <wait>
}
    800032c8:	60e2                	ld	ra,24(sp)
    800032ca:	6442                	ld	s0,16(sp)
    800032cc:	6105                	addi	sp,sp,32
    800032ce:	8082                	ret

00000000800032d0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032d0:	7179                	addi	sp,sp,-48
    800032d2:	f406                	sd	ra,40(sp)
    800032d4:	f022                	sd	s0,32(sp)
    800032d6:	ec26                	sd	s1,24(sp)
    800032d8:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032da:	fdc40593          	addi	a1,s0,-36
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	e78080e7          	jalr	-392(ra) # 80003158 <argint>
    800032e8:	87aa                	mv	a5,a0
    return -1;
    800032ea:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032ec:	0207c063          	bltz	a5,8000330c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	8c2080e7          	jalr	-1854(ra) # 80001bb2 <myproc>
    800032f8:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800032fa:	fdc42503          	lw	a0,-36(s0)
    800032fe:	fffff097          	auipc	ra,0xfffff
    80003302:	c3a080e7          	jalr	-966(ra) # 80001f38 <growproc>
    80003306:	00054863          	bltz	a0,80003316 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000330a:	8526                	mv	a0,s1
}
    8000330c:	70a2                	ld	ra,40(sp)
    8000330e:	7402                	ld	s0,32(sp)
    80003310:	64e2                	ld	s1,24(sp)
    80003312:	6145                	addi	sp,sp,48
    80003314:	8082                	ret
    return -1;
    80003316:	557d                	li	a0,-1
    80003318:	bfd5                	j	8000330c <sys_sbrk+0x3c>

000000008000331a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000331a:	7139                	addi	sp,sp,-64
    8000331c:	fc06                	sd	ra,56(sp)
    8000331e:	f822                	sd	s0,48(sp)
    80003320:	f426                	sd	s1,40(sp)
    80003322:	f04a                	sd	s2,32(sp)
    80003324:	ec4e                	sd	s3,24(sp)
    80003326:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003328:	fcc40593          	addi	a1,s0,-52
    8000332c:	4501                	li	a0,0
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	e2a080e7          	jalr	-470(ra) # 80003158 <argint>
    return -1;
    80003336:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003338:	06054563          	bltz	a0,800033a2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000333c:	00014517          	auipc	a0,0x14
    80003340:	5b450513          	addi	a0,a0,1460 # 800178f0 <tickslock>
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	8a0080e7          	jalr	-1888(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000334c:	00006917          	auipc	s2,0x6
    80003350:	d0c92903          	lw	s2,-756(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    80003354:	fcc42783          	lw	a5,-52(s0)
    80003358:	cf85                	beqz	a5,80003390 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000335a:	00014997          	auipc	s3,0x14
    8000335e:	59698993          	addi	s3,s3,1430 # 800178f0 <tickslock>
    80003362:	00006497          	auipc	s1,0x6
    80003366:	cf648493          	addi	s1,s1,-778 # 80009058 <ticks>
    if(myproc()->killed){
    8000336a:	fffff097          	auipc	ra,0xfffff
    8000336e:	848080e7          	jalr	-1976(ra) # 80001bb2 <myproc>
    80003372:	551c                	lw	a5,40(a0)
    80003374:	ef9d                	bnez	a5,800033b2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003376:	85ce                	mv	a1,s3
    80003378:	8526                	mv	a0,s1
    8000337a:	fffff097          	auipc	ra,0xfffff
    8000337e:	27a080e7          	jalr	634(ra) # 800025f4 <sleep>
  while(ticks - ticks0 < n){
    80003382:	409c                	lw	a5,0(s1)
    80003384:	412787bb          	subw	a5,a5,s2
    80003388:	fcc42703          	lw	a4,-52(s0)
    8000338c:	fce7efe3          	bltu	a5,a4,8000336a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003390:	00014517          	auipc	a0,0x14
    80003394:	56050513          	addi	a0,a0,1376 # 800178f0 <tickslock>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
  return 0;
    800033a0:	4781                	li	a5,0
}
    800033a2:	853e                	mv	a0,a5
    800033a4:	70e2                	ld	ra,56(sp)
    800033a6:	7442                	ld	s0,48(sp)
    800033a8:	74a2                	ld	s1,40(sp)
    800033aa:	7902                	ld	s2,32(sp)
    800033ac:	69e2                	ld	s3,24(sp)
    800033ae:	6121                	addi	sp,sp,64
    800033b0:	8082                	ret
      release(&tickslock);
    800033b2:	00014517          	auipc	a0,0x14
    800033b6:	53e50513          	addi	a0,a0,1342 # 800178f0 <tickslock>
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	8de080e7          	jalr	-1826(ra) # 80000c98 <release>
      return -1;
    800033c2:	57fd                	li	a5,-1
    800033c4:	bff9                	j	800033a2 <sys_sleep+0x88>

00000000800033c6 <sys_kill>:

uint64
sys_kill(void)
{
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033ce:	fec40593          	addi	a1,s0,-20
    800033d2:	4501                	li	a0,0
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	d84080e7          	jalr	-636(ra) # 80003158 <argint>
    800033dc:	87aa                	mv	a5,a0
    return -1;
    800033de:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033e0:	0007c863          	bltz	a5,800033f0 <sys_kill+0x2a>
  return kill(pid);
    800033e4:	fec42503          	lw	a0,-20(s0)
    800033e8:	fffff097          	auipc	ra,0xfffff
    800033ec:	58a080e7          	jalr	1418(ra) # 80002972 <kill>
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	6105                	addi	sp,sp,32
    800033f6:	8082                	ret

00000000800033f8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003402:	00014517          	auipc	a0,0x14
    80003406:	4ee50513          	addi	a0,a0,1262 # 800178f0 <tickslock>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	7da080e7          	jalr	2010(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003412:	00006497          	auipc	s1,0x6
    80003416:	c464a483          	lw	s1,-954(s1) # 80009058 <ticks>
  release(&tickslock);
    8000341a:	00014517          	auipc	a0,0x14
    8000341e:	4d650513          	addi	a0,a0,1238 # 800178f0 <tickslock>
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	876080e7          	jalr	-1930(ra) # 80000c98 <release>
  return xticks;
}
    8000342a:	02049513          	slli	a0,s1,0x20
    8000342e:	9101                	srli	a0,a0,0x20
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	64a2                	ld	s1,8(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret

000000008000343a <sys_pause_system>:

//-----------OUR ADDITION-------------
uint64
sys_pause_system(void)
{
    8000343a:	1101                	addi	sp,sp,-32
    8000343c:	ec06                	sd	ra,24(sp)
    8000343e:	e822                	sd	s0,16(sp)
    80003440:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003442:	fec40593          	addi	a1,s0,-20
    80003446:	4501                	li	a0,0
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	d10080e7          	jalr	-752(ra) # 80003158 <argint>
    80003450:	87aa                	mv	a5,a0
    return -1;
    80003452:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80003454:	0007c863          	bltz	a5,80003464 <sys_pause_system+0x2a>
  return pause_system(seconds);
    80003458:	fec42503          	lw	a0,-20(s0)
    8000345c:	fffff097          	auipc	ra,0xfffff
    80003460:	6f8080e7          	jalr	1784(ra) # 80002b54 <pause_system>
}
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	6105                	addi	sp,sp,32
    8000346a:	8082                	ret

000000008000346c <sys_kill_system>:

uint64
sys_kill_system(void)
{
    8000346c:	1141                	addi	sp,sp,-16
    8000346e:	e406                	sd	ra,8(sp)
    80003470:	e022                	sd	s0,0(sp)
    80003472:	0800                	addi	s0,sp,16
 
  return kill_system();
    80003474:	fffff097          	auipc	ra,0xfffff
    80003478:	790080e7          	jalr	1936(ra) # 80002c04 <kill_system>
}
    8000347c:	60a2                	ld	ra,8(sp)
    8000347e:	6402                	ld	s0,0(sp)
    80003480:	0141                	addi	sp,sp,16
    80003482:	8082                	ret

0000000080003484 <sys_print_stats>:

uint64
sys_print_stats(void)
{
    80003484:	1141                	addi	sp,sp,-16
    80003486:	e406                	sd	ra,8(sp)
    80003488:	e022                	sd	s0,0(sp)
    8000348a:	0800                	addi	s0,sp,16
   print_stats();
    8000348c:	ffffe097          	auipc	ra,0xffffe
    80003490:	424080e7          	jalr	1060(ra) # 800018b0 <print_stats>
   return 0;
}
    80003494:	4501                	li	a0,0
    80003496:	60a2                	ld	ra,8(sp)
    80003498:	6402                	ld	s0,0(sp)
    8000349a:	0141                	addi	sp,sp,16
    8000349c:	8082                	ret

000000008000349e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000349e:	7179                	addi	sp,sp,-48
    800034a0:	f406                	sd	ra,40(sp)
    800034a2:	f022                	sd	s0,32(sp)
    800034a4:	ec26                	sd	s1,24(sp)
    800034a6:	e84a                	sd	s2,16(sp)
    800034a8:	e44e                	sd	s3,8(sp)
    800034aa:	e052                	sd	s4,0(sp)
    800034ac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034ae:	00005597          	auipc	a1,0x5
    800034b2:	1fa58593          	addi	a1,a1,506 # 800086a8 <syscalls+0xc8>
    800034b6:	00014517          	auipc	a0,0x14
    800034ba:	45250513          	addi	a0,a0,1106 # 80017908 <bcache>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	696080e7          	jalr	1686(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034c6:	0001c797          	auipc	a5,0x1c
    800034ca:	44278793          	addi	a5,a5,1090 # 8001f908 <bcache+0x8000>
    800034ce:	0001c717          	auipc	a4,0x1c
    800034d2:	6a270713          	addi	a4,a4,1698 # 8001fb70 <bcache+0x8268>
    800034d6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034da:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034de:	00014497          	auipc	s1,0x14
    800034e2:	44248493          	addi	s1,s1,1090 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800034e6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034e8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ea:	00005a17          	auipc	s4,0x5
    800034ee:	1c6a0a13          	addi	s4,s4,454 # 800086b0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034f2:	2b893783          	ld	a5,696(s2)
    800034f6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034f8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034fc:	85d2                	mv	a1,s4
    800034fe:	01048513          	addi	a0,s1,16
    80003502:	00001097          	auipc	ra,0x1
    80003506:	4bc080e7          	jalr	1212(ra) # 800049be <initsleeplock>
    bcache.head.next->prev = b;
    8000350a:	2b893783          	ld	a5,696(s2)
    8000350e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003510:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003514:	45848493          	addi	s1,s1,1112
    80003518:	fd349de3          	bne	s1,s3,800034f2 <binit+0x54>
  }
}
    8000351c:	70a2                	ld	ra,40(sp)
    8000351e:	7402                	ld	s0,32(sp)
    80003520:	64e2                	ld	s1,24(sp)
    80003522:	6942                	ld	s2,16(sp)
    80003524:	69a2                	ld	s3,8(sp)
    80003526:	6a02                	ld	s4,0(sp)
    80003528:	6145                	addi	sp,sp,48
    8000352a:	8082                	ret

000000008000352c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000352c:	7179                	addi	sp,sp,-48
    8000352e:	f406                	sd	ra,40(sp)
    80003530:	f022                	sd	s0,32(sp)
    80003532:	ec26                	sd	s1,24(sp)
    80003534:	e84a                	sd	s2,16(sp)
    80003536:	e44e                	sd	s3,8(sp)
    80003538:	1800                	addi	s0,sp,48
    8000353a:	89aa                	mv	s3,a0
    8000353c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000353e:	00014517          	auipc	a0,0x14
    80003542:	3ca50513          	addi	a0,a0,970 # 80017908 <bcache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	69e080e7          	jalr	1694(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000354e:	0001c497          	auipc	s1,0x1c
    80003552:	6724b483          	ld	s1,1650(s1) # 8001fbc0 <bcache+0x82b8>
    80003556:	0001c797          	auipc	a5,0x1c
    8000355a:	61a78793          	addi	a5,a5,1562 # 8001fb70 <bcache+0x8268>
    8000355e:	02f48f63          	beq	s1,a5,8000359c <bread+0x70>
    80003562:	873e                	mv	a4,a5
    80003564:	a021                	j	8000356c <bread+0x40>
    80003566:	68a4                	ld	s1,80(s1)
    80003568:	02e48a63          	beq	s1,a4,8000359c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000356c:	449c                	lw	a5,8(s1)
    8000356e:	ff379ce3          	bne	a5,s3,80003566 <bread+0x3a>
    80003572:	44dc                	lw	a5,12(s1)
    80003574:	ff2799e3          	bne	a5,s2,80003566 <bread+0x3a>
      b->refcnt++;
    80003578:	40bc                	lw	a5,64(s1)
    8000357a:	2785                	addiw	a5,a5,1
    8000357c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000357e:	00014517          	auipc	a0,0x14
    80003582:	38a50513          	addi	a0,a0,906 # 80017908 <bcache>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	712080e7          	jalr	1810(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000358e:	01048513          	addi	a0,s1,16
    80003592:	00001097          	auipc	ra,0x1
    80003596:	466080e7          	jalr	1126(ra) # 800049f8 <acquiresleep>
      return b;
    8000359a:	a8b9                	j	800035f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000359c:	0001c497          	auipc	s1,0x1c
    800035a0:	61c4b483          	ld	s1,1564(s1) # 8001fbb8 <bcache+0x82b0>
    800035a4:	0001c797          	auipc	a5,0x1c
    800035a8:	5cc78793          	addi	a5,a5,1484 # 8001fb70 <bcache+0x8268>
    800035ac:	00f48863          	beq	s1,a5,800035bc <bread+0x90>
    800035b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035b2:	40bc                	lw	a5,64(s1)
    800035b4:	cf81                	beqz	a5,800035cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035b6:	64a4                	ld	s1,72(s1)
    800035b8:	fee49de3          	bne	s1,a4,800035b2 <bread+0x86>
  panic("bget: no buffers");
    800035bc:	00005517          	auipc	a0,0x5
    800035c0:	0fc50513          	addi	a0,a0,252 # 800086b8 <syscalls+0xd8>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	f7a080e7          	jalr	-134(ra) # 8000053e <panic>
      b->dev = dev;
    800035cc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035d0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035d8:	4785                	li	a5,1
    800035da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035dc:	00014517          	auipc	a0,0x14
    800035e0:	32c50513          	addi	a0,a0,812 # 80017908 <bcache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800035ec:	01048513          	addi	a0,s1,16
    800035f0:	00001097          	auipc	ra,0x1
    800035f4:	408080e7          	jalr	1032(ra) # 800049f8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035f8:	409c                	lw	a5,0(s1)
    800035fa:	cb89                	beqz	a5,8000360c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035fc:	8526                	mv	a0,s1
    800035fe:	70a2                	ld	ra,40(sp)
    80003600:	7402                	ld	s0,32(sp)
    80003602:	64e2                	ld	s1,24(sp)
    80003604:	6942                	ld	s2,16(sp)
    80003606:	69a2                	ld	s3,8(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000360c:	4581                	li	a1,0
    8000360e:	8526                	mv	a0,s1
    80003610:	00003097          	auipc	ra,0x3
    80003614:	f06080e7          	jalr	-250(ra) # 80006516 <virtio_disk_rw>
    b->valid = 1;
    80003618:	4785                	li	a5,1
    8000361a:	c09c                	sw	a5,0(s1)
  return b;
    8000361c:	b7c5                	j	800035fc <bread+0xd0>

000000008000361e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000361e:	1101                	addi	sp,sp,-32
    80003620:	ec06                	sd	ra,24(sp)
    80003622:	e822                	sd	s0,16(sp)
    80003624:	e426                	sd	s1,8(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000362a:	0541                	addi	a0,a0,16
    8000362c:	00001097          	auipc	ra,0x1
    80003630:	466080e7          	jalr	1126(ra) # 80004a92 <holdingsleep>
    80003634:	cd01                	beqz	a0,8000364c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003636:	4585                	li	a1,1
    80003638:	8526                	mv	a0,s1
    8000363a:	00003097          	auipc	ra,0x3
    8000363e:	edc080e7          	jalr	-292(ra) # 80006516 <virtio_disk_rw>
}
    80003642:	60e2                	ld	ra,24(sp)
    80003644:	6442                	ld	s0,16(sp)
    80003646:	64a2                	ld	s1,8(sp)
    80003648:	6105                	addi	sp,sp,32
    8000364a:	8082                	ret
    panic("bwrite");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	08450513          	addi	a0,a0,132 # 800086d0 <syscalls+0xf0>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>

000000008000365c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000365c:	1101                	addi	sp,sp,-32
    8000365e:	ec06                	sd	ra,24(sp)
    80003660:	e822                	sd	s0,16(sp)
    80003662:	e426                	sd	s1,8(sp)
    80003664:	e04a                	sd	s2,0(sp)
    80003666:	1000                	addi	s0,sp,32
    80003668:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000366a:	01050913          	addi	s2,a0,16
    8000366e:	854a                	mv	a0,s2
    80003670:	00001097          	auipc	ra,0x1
    80003674:	422080e7          	jalr	1058(ra) # 80004a92 <holdingsleep>
    80003678:	c92d                	beqz	a0,800036ea <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	3d2080e7          	jalr	978(ra) # 80004a4e <releasesleep>

  acquire(&bcache.lock);
    80003684:	00014517          	auipc	a0,0x14
    80003688:	28450513          	addi	a0,a0,644 # 80017908 <bcache>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	558080e7          	jalr	1368(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003694:	40bc                	lw	a5,64(s1)
    80003696:	37fd                	addiw	a5,a5,-1
    80003698:	0007871b          	sext.w	a4,a5
    8000369c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000369e:	eb05                	bnez	a4,800036ce <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036a0:	68bc                	ld	a5,80(s1)
    800036a2:	64b8                	ld	a4,72(s1)
    800036a4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036a6:	64bc                	ld	a5,72(s1)
    800036a8:	68b8                	ld	a4,80(s1)
    800036aa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036ac:	0001c797          	auipc	a5,0x1c
    800036b0:	25c78793          	addi	a5,a5,604 # 8001f908 <bcache+0x8000>
    800036b4:	2b87b703          	ld	a4,696(a5)
    800036b8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036ba:	0001c717          	auipc	a4,0x1c
    800036be:	4b670713          	addi	a4,a4,1206 # 8001fb70 <bcache+0x8268>
    800036c2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036c4:	2b87b703          	ld	a4,696(a5)
    800036c8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ca:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ce:	00014517          	auipc	a0,0x14
    800036d2:	23a50513          	addi	a0,a0,570 # 80017908 <bcache>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	5c2080e7          	jalr	1474(ra) # 80000c98 <release>
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6902                	ld	s2,0(sp)
    800036e6:	6105                	addi	sp,sp,32
    800036e8:	8082                	ret
    panic("brelse");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	fee50513          	addi	a0,a0,-18 # 800086d8 <syscalls+0xf8>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4c080e7          	jalr	-436(ra) # 8000053e <panic>

00000000800036fa <bpin>:

void
bpin(struct buf *b) {
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	1000                	addi	s0,sp,32
    80003704:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003706:	00014517          	auipc	a0,0x14
    8000370a:	20250513          	addi	a0,a0,514 # 80017908 <bcache>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	4d6080e7          	jalr	1238(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003716:	40bc                	lw	a5,64(s1)
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000371c:	00014517          	auipc	a0,0x14
    80003720:	1ec50513          	addi	a0,a0,492 # 80017908 <bcache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	574080e7          	jalr	1396(ra) # 80000c98 <release>
}
    8000372c:	60e2                	ld	ra,24(sp)
    8000372e:	6442                	ld	s0,16(sp)
    80003730:	64a2                	ld	s1,8(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret

0000000080003736 <bunpin>:

void
bunpin(struct buf *b) {
    80003736:	1101                	addi	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	e426                	sd	s1,8(sp)
    8000373e:	1000                	addi	s0,sp,32
    80003740:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003742:	00014517          	auipc	a0,0x14
    80003746:	1c650513          	addi	a0,a0,454 # 80017908 <bcache>
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	49a080e7          	jalr	1178(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003752:	40bc                	lw	a5,64(s1)
    80003754:	37fd                	addiw	a5,a5,-1
    80003756:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003758:	00014517          	auipc	a0,0x14
    8000375c:	1b050513          	addi	a0,a0,432 # 80017908 <bcache>
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	538080e7          	jalr	1336(ra) # 80000c98 <release>
}
    80003768:	60e2                	ld	ra,24(sp)
    8000376a:	6442                	ld	s0,16(sp)
    8000376c:	64a2                	ld	s1,8(sp)
    8000376e:	6105                	addi	sp,sp,32
    80003770:	8082                	ret

0000000080003772 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003772:	1101                	addi	sp,sp,-32
    80003774:	ec06                	sd	ra,24(sp)
    80003776:	e822                	sd	s0,16(sp)
    80003778:	e426                	sd	s1,8(sp)
    8000377a:	e04a                	sd	s2,0(sp)
    8000377c:	1000                	addi	s0,sp,32
    8000377e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003780:	00d5d59b          	srliw	a1,a1,0xd
    80003784:	0001d797          	auipc	a5,0x1d
    80003788:	8607a783          	lw	a5,-1952(a5) # 8001ffe4 <sb+0x1c>
    8000378c:	9dbd                	addw	a1,a1,a5
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	d9e080e7          	jalr	-610(ra) # 8000352c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003796:	0074f713          	andi	a4,s1,7
    8000379a:	4785                	li	a5,1
    8000379c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037a0:	14ce                	slli	s1,s1,0x33
    800037a2:	90d9                	srli	s1,s1,0x36
    800037a4:	00950733          	add	a4,a0,s1
    800037a8:	05874703          	lbu	a4,88(a4)
    800037ac:	00e7f6b3          	and	a3,a5,a4
    800037b0:	c69d                	beqz	a3,800037de <bfree+0x6c>
    800037b2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037b4:	94aa                	add	s1,s1,a0
    800037b6:	fff7c793          	not	a5,a5
    800037ba:	8ff9                	and	a5,a5,a4
    800037bc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	118080e7          	jalr	280(ra) # 800048d8 <log_write>
  brelse(bp);
    800037c8:	854a                	mv	a0,s2
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	e92080e7          	jalr	-366(ra) # 8000365c <brelse>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6902                	ld	s2,0(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret
    panic("freeing free block");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	f0250513          	addi	a0,a0,-254 # 800086e0 <syscalls+0x100>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>

00000000800037ee <balloc>:
{
    800037ee:	711d                	addi	sp,sp,-96
    800037f0:	ec86                	sd	ra,88(sp)
    800037f2:	e8a2                	sd	s0,80(sp)
    800037f4:	e4a6                	sd	s1,72(sp)
    800037f6:	e0ca                	sd	s2,64(sp)
    800037f8:	fc4e                	sd	s3,56(sp)
    800037fa:	f852                	sd	s4,48(sp)
    800037fc:	f456                	sd	s5,40(sp)
    800037fe:	f05a                	sd	s6,32(sp)
    80003800:	ec5e                	sd	s7,24(sp)
    80003802:	e862                	sd	s8,16(sp)
    80003804:	e466                	sd	s9,8(sp)
    80003806:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003808:	0001c797          	auipc	a5,0x1c
    8000380c:	7c47a783          	lw	a5,1988(a5) # 8001ffcc <sb+0x4>
    80003810:	cbd1                	beqz	a5,800038a4 <balloc+0xb6>
    80003812:	8baa                	mv	s7,a0
    80003814:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003816:	0001cb17          	auipc	s6,0x1c
    8000381a:	7b2b0b13          	addi	s6,s6,1970 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000381e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003820:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003822:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003824:	6c89                	lui	s9,0x2
    80003826:	a831                	j	80003842 <balloc+0x54>
    brelse(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	e32080e7          	jalr	-462(ra) # 8000365c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003832:	015c87bb          	addw	a5,s9,s5
    80003836:	00078a9b          	sext.w	s5,a5
    8000383a:	004b2703          	lw	a4,4(s6)
    8000383e:	06eaf363          	bgeu	s5,a4,800038a4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003842:	41fad79b          	sraiw	a5,s5,0x1f
    80003846:	0137d79b          	srliw	a5,a5,0x13
    8000384a:	015787bb          	addw	a5,a5,s5
    8000384e:	40d7d79b          	sraiw	a5,a5,0xd
    80003852:	01cb2583          	lw	a1,28(s6)
    80003856:	9dbd                	addw	a1,a1,a5
    80003858:	855e                	mv	a0,s7
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	cd2080e7          	jalr	-814(ra) # 8000352c <bread>
    80003862:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003864:	004b2503          	lw	a0,4(s6)
    80003868:	000a849b          	sext.w	s1,s5
    8000386c:	8662                	mv	a2,s8
    8000386e:	faa4fde3          	bgeu	s1,a0,80003828 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003872:	41f6579b          	sraiw	a5,a2,0x1f
    80003876:	01d7d69b          	srliw	a3,a5,0x1d
    8000387a:	00c6873b          	addw	a4,a3,a2
    8000387e:	00777793          	andi	a5,a4,7
    80003882:	9f95                	subw	a5,a5,a3
    80003884:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003888:	4037571b          	sraiw	a4,a4,0x3
    8000388c:	00e906b3          	add	a3,s2,a4
    80003890:	0586c683          	lbu	a3,88(a3)
    80003894:	00d7f5b3          	and	a1,a5,a3
    80003898:	cd91                	beqz	a1,800038b4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000389a:	2605                	addiw	a2,a2,1
    8000389c:	2485                	addiw	s1,s1,1
    8000389e:	fd4618e3          	bne	a2,s4,8000386e <balloc+0x80>
    800038a2:	b759                	j	80003828 <balloc+0x3a>
  panic("balloc: out of blocks");
    800038a4:	00005517          	auipc	a0,0x5
    800038a8:	e5450513          	addi	a0,a0,-428 # 800086f8 <syscalls+0x118>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	c92080e7          	jalr	-878(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038b4:	974a                	add	a4,a4,s2
    800038b6:	8fd5                	or	a5,a5,a3
    800038b8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038bc:	854a                	mv	a0,s2
    800038be:	00001097          	auipc	ra,0x1
    800038c2:	01a080e7          	jalr	26(ra) # 800048d8 <log_write>
        brelse(bp);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	d94080e7          	jalr	-620(ra) # 8000365c <brelse>
  bp = bread(dev, bno);
    800038d0:	85a6                	mv	a1,s1
    800038d2:	855e                	mv	a0,s7
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	c58080e7          	jalr	-936(ra) # 8000352c <bread>
    800038dc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038de:	40000613          	li	a2,1024
    800038e2:	4581                	li	a1,0
    800038e4:	05850513          	addi	a0,a0,88
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	3f8080e7          	jalr	1016(ra) # 80000ce0 <memset>
  log_write(bp);
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	fe6080e7          	jalr	-26(ra) # 800048d8 <log_write>
  brelse(bp);
    800038fa:	854a                	mv	a0,s2
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	d60080e7          	jalr	-672(ra) # 8000365c <brelse>
}
    80003904:	8526                	mv	a0,s1
    80003906:	60e6                	ld	ra,88(sp)
    80003908:	6446                	ld	s0,80(sp)
    8000390a:	64a6                	ld	s1,72(sp)
    8000390c:	6906                	ld	s2,64(sp)
    8000390e:	79e2                	ld	s3,56(sp)
    80003910:	7a42                	ld	s4,48(sp)
    80003912:	7aa2                	ld	s5,40(sp)
    80003914:	7b02                	ld	s6,32(sp)
    80003916:	6be2                	ld	s7,24(sp)
    80003918:	6c42                	ld	s8,16(sp)
    8000391a:	6ca2                	ld	s9,8(sp)
    8000391c:	6125                	addi	sp,sp,96
    8000391e:	8082                	ret

0000000080003920 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003920:	7179                	addi	sp,sp,-48
    80003922:	f406                	sd	ra,40(sp)
    80003924:	f022                	sd	s0,32(sp)
    80003926:	ec26                	sd	s1,24(sp)
    80003928:	e84a                	sd	s2,16(sp)
    8000392a:	e44e                	sd	s3,8(sp)
    8000392c:	e052                	sd	s4,0(sp)
    8000392e:	1800                	addi	s0,sp,48
    80003930:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003932:	47ad                	li	a5,11
    80003934:	04b7fe63          	bgeu	a5,a1,80003990 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003938:	ff45849b          	addiw	s1,a1,-12
    8000393c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003940:	0ff00793          	li	a5,255
    80003944:	0ae7e363          	bltu	a5,a4,800039ea <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003948:	08052583          	lw	a1,128(a0)
    8000394c:	c5ad                	beqz	a1,800039b6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000394e:	00092503          	lw	a0,0(s2)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	bda080e7          	jalr	-1062(ra) # 8000352c <bread>
    8000395a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000395c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003960:	02049593          	slli	a1,s1,0x20
    80003964:	9181                	srli	a1,a1,0x20
    80003966:	058a                	slli	a1,a1,0x2
    80003968:	00b784b3          	add	s1,a5,a1
    8000396c:	0004a983          	lw	s3,0(s1)
    80003970:	04098d63          	beqz	s3,800039ca <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003974:	8552                	mv	a0,s4
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	ce6080e7          	jalr	-794(ra) # 8000365c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000397e:	854e                	mv	a0,s3
    80003980:	70a2                	ld	ra,40(sp)
    80003982:	7402                	ld	s0,32(sp)
    80003984:	64e2                	ld	s1,24(sp)
    80003986:	6942                	ld	s2,16(sp)
    80003988:	69a2                	ld	s3,8(sp)
    8000398a:	6a02                	ld	s4,0(sp)
    8000398c:	6145                	addi	sp,sp,48
    8000398e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003990:	02059493          	slli	s1,a1,0x20
    80003994:	9081                	srli	s1,s1,0x20
    80003996:	048a                	slli	s1,s1,0x2
    80003998:	94aa                	add	s1,s1,a0
    8000399a:	0504a983          	lw	s3,80(s1)
    8000399e:	fe0990e3          	bnez	s3,8000397e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800039a2:	4108                	lw	a0,0(a0)
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	e4a080e7          	jalr	-438(ra) # 800037ee <balloc>
    800039ac:	0005099b          	sext.w	s3,a0
    800039b0:	0534a823          	sw	s3,80(s1)
    800039b4:	b7e9                	j	8000397e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039b6:	4108                	lw	a0,0(a0)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	e36080e7          	jalr	-458(ra) # 800037ee <balloc>
    800039c0:	0005059b          	sext.w	a1,a0
    800039c4:	08b92023          	sw	a1,128(s2)
    800039c8:	b759                	j	8000394e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039ca:	00092503          	lw	a0,0(s2)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	e20080e7          	jalr	-480(ra) # 800037ee <balloc>
    800039d6:	0005099b          	sext.w	s3,a0
    800039da:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039de:	8552                	mv	a0,s4
    800039e0:	00001097          	auipc	ra,0x1
    800039e4:	ef8080e7          	jalr	-264(ra) # 800048d8 <log_write>
    800039e8:	b771                	j	80003974 <bmap+0x54>
  panic("bmap: out of range");
    800039ea:	00005517          	auipc	a0,0x5
    800039ee:	d2650513          	addi	a0,a0,-730 # 80008710 <syscalls+0x130>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>

00000000800039fa <iget>:
{
    800039fa:	7179                	addi	sp,sp,-48
    800039fc:	f406                	sd	ra,40(sp)
    800039fe:	f022                	sd	s0,32(sp)
    80003a00:	ec26                	sd	s1,24(sp)
    80003a02:	e84a                	sd	s2,16(sp)
    80003a04:	e44e                	sd	s3,8(sp)
    80003a06:	e052                	sd	s4,0(sp)
    80003a08:	1800                	addi	s0,sp,48
    80003a0a:	89aa                	mv	s3,a0
    80003a0c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a0e:	0001c517          	auipc	a0,0x1c
    80003a12:	5da50513          	addi	a0,a0,1498 # 8001ffe8 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	1ce080e7          	jalr	462(ra) # 80000be4 <acquire>
  empty = 0;
    80003a1e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a20:	0001c497          	auipc	s1,0x1c
    80003a24:	5e048493          	addi	s1,s1,1504 # 80020000 <itable+0x18>
    80003a28:	0001e697          	auipc	a3,0x1e
    80003a2c:	06868693          	addi	a3,a3,104 # 80021a90 <log>
    80003a30:	a039                	j	80003a3e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a32:	02090b63          	beqz	s2,80003a68 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a36:	08848493          	addi	s1,s1,136
    80003a3a:	02d48a63          	beq	s1,a3,80003a6e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a3e:	449c                	lw	a5,8(s1)
    80003a40:	fef059e3          	blez	a5,80003a32 <iget+0x38>
    80003a44:	4098                	lw	a4,0(s1)
    80003a46:	ff3716e3          	bne	a4,s3,80003a32 <iget+0x38>
    80003a4a:	40d8                	lw	a4,4(s1)
    80003a4c:	ff4713e3          	bne	a4,s4,80003a32 <iget+0x38>
      ip->ref++;
    80003a50:	2785                	addiw	a5,a5,1
    80003a52:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a54:	0001c517          	auipc	a0,0x1c
    80003a58:	59450513          	addi	a0,a0,1428 # 8001ffe8 <itable>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	23c080e7          	jalr	572(ra) # 80000c98 <release>
      return ip;
    80003a64:	8926                	mv	s2,s1
    80003a66:	a03d                	j	80003a94 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a68:	f7f9                	bnez	a5,80003a36 <iget+0x3c>
    80003a6a:	8926                	mv	s2,s1
    80003a6c:	b7e9                	j	80003a36 <iget+0x3c>
  if(empty == 0)
    80003a6e:	02090c63          	beqz	s2,80003aa6 <iget+0xac>
  ip->dev = dev;
    80003a72:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a76:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a7a:	4785                	li	a5,1
    80003a7c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a80:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a84:	0001c517          	auipc	a0,0x1c
    80003a88:	56450513          	addi	a0,a0,1380 # 8001ffe8 <itable>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	20c080e7          	jalr	524(ra) # 80000c98 <release>
}
    80003a94:	854a                	mv	a0,s2
    80003a96:	70a2                	ld	ra,40(sp)
    80003a98:	7402                	ld	s0,32(sp)
    80003a9a:	64e2                	ld	s1,24(sp)
    80003a9c:	6942                	ld	s2,16(sp)
    80003a9e:	69a2                	ld	s3,8(sp)
    80003aa0:	6a02                	ld	s4,0(sp)
    80003aa2:	6145                	addi	sp,sp,48
    80003aa4:	8082                	ret
    panic("iget: no inodes");
    80003aa6:	00005517          	auipc	a0,0x5
    80003aaa:	c8250513          	addi	a0,a0,-894 # 80008728 <syscalls+0x148>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a90080e7          	jalr	-1392(ra) # 8000053e <panic>

0000000080003ab6 <fsinit>:
fsinit(int dev) {
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	1800                	addi	s0,sp,48
    80003ac4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ac6:	4585                	li	a1,1
    80003ac8:	00000097          	auipc	ra,0x0
    80003acc:	a64080e7          	jalr	-1436(ra) # 8000352c <bread>
    80003ad0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ad2:	0001c997          	auipc	s3,0x1c
    80003ad6:	4f698993          	addi	s3,s3,1270 # 8001ffc8 <sb>
    80003ada:	02000613          	li	a2,32
    80003ade:	05850593          	addi	a1,a0,88
    80003ae2:	854e                	mv	a0,s3
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	25c080e7          	jalr	604(ra) # 80000d40 <memmove>
  brelse(bp);
    80003aec:	8526                	mv	a0,s1
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	b6e080e7          	jalr	-1170(ra) # 8000365c <brelse>
  if(sb.magic != FSMAGIC)
    80003af6:	0009a703          	lw	a4,0(s3)
    80003afa:	102037b7          	lui	a5,0x10203
    80003afe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b02:	02f71263          	bne	a4,a5,80003b26 <fsinit+0x70>
  initlog(dev, &sb);
    80003b06:	0001c597          	auipc	a1,0x1c
    80003b0a:	4c258593          	addi	a1,a1,1218 # 8001ffc8 <sb>
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	b4c080e7          	jalr	-1204(ra) # 8000465c <initlog>
}
    80003b18:	70a2                	ld	ra,40(sp)
    80003b1a:	7402                	ld	s0,32(sp)
    80003b1c:	64e2                	ld	s1,24(sp)
    80003b1e:	6942                	ld	s2,16(sp)
    80003b20:	69a2                	ld	s3,8(sp)
    80003b22:	6145                	addi	sp,sp,48
    80003b24:	8082                	ret
    panic("invalid file system");
    80003b26:	00005517          	auipc	a0,0x5
    80003b2a:	c1250513          	addi	a0,a0,-1006 # 80008738 <syscalls+0x158>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	a10080e7          	jalr	-1520(ra) # 8000053e <panic>

0000000080003b36 <iinit>:
{
    80003b36:	7179                	addi	sp,sp,-48
    80003b38:	f406                	sd	ra,40(sp)
    80003b3a:	f022                	sd	s0,32(sp)
    80003b3c:	ec26                	sd	s1,24(sp)
    80003b3e:	e84a                	sd	s2,16(sp)
    80003b40:	e44e                	sd	s3,8(sp)
    80003b42:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b44:	00005597          	auipc	a1,0x5
    80003b48:	c0c58593          	addi	a1,a1,-1012 # 80008750 <syscalls+0x170>
    80003b4c:	0001c517          	auipc	a0,0x1c
    80003b50:	49c50513          	addi	a0,a0,1180 # 8001ffe8 <itable>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	000080e7          	jalr	ra # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b5c:	0001c497          	auipc	s1,0x1c
    80003b60:	4b448493          	addi	s1,s1,1204 # 80020010 <itable+0x28>
    80003b64:	0001e997          	auipc	s3,0x1e
    80003b68:	f3c98993          	addi	s3,s3,-196 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b6c:	00005917          	auipc	s2,0x5
    80003b70:	bec90913          	addi	s2,s2,-1044 # 80008758 <syscalls+0x178>
    80003b74:	85ca                	mv	a1,s2
    80003b76:	8526                	mv	a0,s1
    80003b78:	00001097          	auipc	ra,0x1
    80003b7c:	e46080e7          	jalr	-442(ra) # 800049be <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b80:	08848493          	addi	s1,s1,136
    80003b84:	ff3498e3          	bne	s1,s3,80003b74 <iinit+0x3e>
}
    80003b88:	70a2                	ld	ra,40(sp)
    80003b8a:	7402                	ld	s0,32(sp)
    80003b8c:	64e2                	ld	s1,24(sp)
    80003b8e:	6942                	ld	s2,16(sp)
    80003b90:	69a2                	ld	s3,8(sp)
    80003b92:	6145                	addi	sp,sp,48
    80003b94:	8082                	ret

0000000080003b96 <ialloc>:
{
    80003b96:	715d                	addi	sp,sp,-80
    80003b98:	e486                	sd	ra,72(sp)
    80003b9a:	e0a2                	sd	s0,64(sp)
    80003b9c:	fc26                	sd	s1,56(sp)
    80003b9e:	f84a                	sd	s2,48(sp)
    80003ba0:	f44e                	sd	s3,40(sp)
    80003ba2:	f052                	sd	s4,32(sp)
    80003ba4:	ec56                	sd	s5,24(sp)
    80003ba6:	e85a                	sd	s6,16(sp)
    80003ba8:	e45e                	sd	s7,8(sp)
    80003baa:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bac:	0001c717          	auipc	a4,0x1c
    80003bb0:	42872703          	lw	a4,1064(a4) # 8001ffd4 <sb+0xc>
    80003bb4:	4785                	li	a5,1
    80003bb6:	04e7fa63          	bgeu	a5,a4,80003c0a <ialloc+0x74>
    80003bba:	8aaa                	mv	s5,a0
    80003bbc:	8bae                	mv	s7,a1
    80003bbe:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bc0:	0001ca17          	auipc	s4,0x1c
    80003bc4:	408a0a13          	addi	s4,s4,1032 # 8001ffc8 <sb>
    80003bc8:	00048b1b          	sext.w	s6,s1
    80003bcc:	0044d593          	srli	a1,s1,0x4
    80003bd0:	018a2783          	lw	a5,24(s4)
    80003bd4:	9dbd                	addw	a1,a1,a5
    80003bd6:	8556                	mv	a0,s5
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	954080e7          	jalr	-1708(ra) # 8000352c <bread>
    80003be0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003be2:	05850993          	addi	s3,a0,88
    80003be6:	00f4f793          	andi	a5,s1,15
    80003bea:	079a                	slli	a5,a5,0x6
    80003bec:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bee:	00099783          	lh	a5,0(s3)
    80003bf2:	c785                	beqz	a5,80003c1a <ialloc+0x84>
    brelse(bp);
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	a68080e7          	jalr	-1432(ra) # 8000365c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bfc:	0485                	addi	s1,s1,1
    80003bfe:	00ca2703          	lw	a4,12(s4)
    80003c02:	0004879b          	sext.w	a5,s1
    80003c06:	fce7e1e3          	bltu	a5,a4,80003bc8 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c0a:	00005517          	auipc	a0,0x5
    80003c0e:	b5650513          	addi	a0,a0,-1194 # 80008760 <syscalls+0x180>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	92c080e7          	jalr	-1748(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003c1a:	04000613          	li	a2,64
    80003c1e:	4581                	li	a1,0
    80003c20:	854e                	mv	a0,s3
    80003c22:	ffffd097          	auipc	ra,0xffffd
    80003c26:	0be080e7          	jalr	190(ra) # 80000ce0 <memset>
      dip->type = type;
    80003c2a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c2e:	854a                	mv	a0,s2
    80003c30:	00001097          	auipc	ra,0x1
    80003c34:	ca8080e7          	jalr	-856(ra) # 800048d8 <log_write>
      brelse(bp);
    80003c38:	854a                	mv	a0,s2
    80003c3a:	00000097          	auipc	ra,0x0
    80003c3e:	a22080e7          	jalr	-1502(ra) # 8000365c <brelse>
      return iget(dev, inum);
    80003c42:	85da                	mv	a1,s6
    80003c44:	8556                	mv	a0,s5
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	db4080e7          	jalr	-588(ra) # 800039fa <iget>
}
    80003c4e:	60a6                	ld	ra,72(sp)
    80003c50:	6406                	ld	s0,64(sp)
    80003c52:	74e2                	ld	s1,56(sp)
    80003c54:	7942                	ld	s2,48(sp)
    80003c56:	79a2                	ld	s3,40(sp)
    80003c58:	7a02                	ld	s4,32(sp)
    80003c5a:	6ae2                	ld	s5,24(sp)
    80003c5c:	6b42                	ld	s6,16(sp)
    80003c5e:	6ba2                	ld	s7,8(sp)
    80003c60:	6161                	addi	sp,sp,80
    80003c62:	8082                	ret

0000000080003c64 <iupdate>:
{
    80003c64:	1101                	addi	sp,sp,-32
    80003c66:	ec06                	sd	ra,24(sp)
    80003c68:	e822                	sd	s0,16(sp)
    80003c6a:	e426                	sd	s1,8(sp)
    80003c6c:	e04a                	sd	s2,0(sp)
    80003c6e:	1000                	addi	s0,sp,32
    80003c70:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c72:	415c                	lw	a5,4(a0)
    80003c74:	0047d79b          	srliw	a5,a5,0x4
    80003c78:	0001c597          	auipc	a1,0x1c
    80003c7c:	3685a583          	lw	a1,872(a1) # 8001ffe0 <sb+0x18>
    80003c80:	9dbd                	addw	a1,a1,a5
    80003c82:	4108                	lw	a0,0(a0)
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	8a8080e7          	jalr	-1880(ra) # 8000352c <bread>
    80003c8c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c8e:	05850793          	addi	a5,a0,88
    80003c92:	40c8                	lw	a0,4(s1)
    80003c94:	893d                	andi	a0,a0,15
    80003c96:	051a                	slli	a0,a0,0x6
    80003c98:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c9a:	04449703          	lh	a4,68(s1)
    80003c9e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ca2:	04649703          	lh	a4,70(s1)
    80003ca6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003caa:	04849703          	lh	a4,72(s1)
    80003cae:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cb2:	04a49703          	lh	a4,74(s1)
    80003cb6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cba:	44f8                	lw	a4,76(s1)
    80003cbc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cbe:	03400613          	li	a2,52
    80003cc2:	05048593          	addi	a1,s1,80
    80003cc6:	0531                	addi	a0,a0,12
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	078080e7          	jalr	120(ra) # 80000d40 <memmove>
  log_write(bp);
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00001097          	auipc	ra,0x1
    80003cd6:	c06080e7          	jalr	-1018(ra) # 800048d8 <log_write>
  brelse(bp);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	980080e7          	jalr	-1664(ra) # 8000365c <brelse>
}
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6902                	ld	s2,0(sp)
    80003cec:	6105                	addi	sp,sp,32
    80003cee:	8082                	ret

0000000080003cf0 <idup>:
{
    80003cf0:	1101                	addi	sp,sp,-32
    80003cf2:	ec06                	sd	ra,24(sp)
    80003cf4:	e822                	sd	s0,16(sp)
    80003cf6:	e426                	sd	s1,8(sp)
    80003cf8:	1000                	addi	s0,sp,32
    80003cfa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cfc:	0001c517          	auipc	a0,0x1c
    80003d00:	2ec50513          	addi	a0,a0,748 # 8001ffe8 <itable>
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	ee0080e7          	jalr	-288(ra) # 80000be4 <acquire>
  ip->ref++;
    80003d0c:	449c                	lw	a5,8(s1)
    80003d0e:	2785                	addiw	a5,a5,1
    80003d10:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d12:	0001c517          	auipc	a0,0x1c
    80003d16:	2d650513          	addi	a0,a0,726 # 8001ffe8 <itable>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	f7e080e7          	jalr	-130(ra) # 80000c98 <release>
}
    80003d22:	8526                	mv	a0,s1
    80003d24:	60e2                	ld	ra,24(sp)
    80003d26:	6442                	ld	s0,16(sp)
    80003d28:	64a2                	ld	s1,8(sp)
    80003d2a:	6105                	addi	sp,sp,32
    80003d2c:	8082                	ret

0000000080003d2e <ilock>:
{
    80003d2e:	1101                	addi	sp,sp,-32
    80003d30:	ec06                	sd	ra,24(sp)
    80003d32:	e822                	sd	s0,16(sp)
    80003d34:	e426                	sd	s1,8(sp)
    80003d36:	e04a                	sd	s2,0(sp)
    80003d38:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d3a:	c115                	beqz	a0,80003d5e <ilock+0x30>
    80003d3c:	84aa                	mv	s1,a0
    80003d3e:	451c                	lw	a5,8(a0)
    80003d40:	00f05f63          	blez	a5,80003d5e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d44:	0541                	addi	a0,a0,16
    80003d46:	00001097          	auipc	ra,0x1
    80003d4a:	cb2080e7          	jalr	-846(ra) # 800049f8 <acquiresleep>
  if(ip->valid == 0){
    80003d4e:	40bc                	lw	a5,64(s1)
    80003d50:	cf99                	beqz	a5,80003d6e <ilock+0x40>
}
    80003d52:	60e2                	ld	ra,24(sp)
    80003d54:	6442                	ld	s0,16(sp)
    80003d56:	64a2                	ld	s1,8(sp)
    80003d58:	6902                	ld	s2,0(sp)
    80003d5a:	6105                	addi	sp,sp,32
    80003d5c:	8082                	ret
    panic("ilock");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	a1a50513          	addi	a0,a0,-1510 # 80008778 <syscalls+0x198>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d6e:	40dc                	lw	a5,4(s1)
    80003d70:	0047d79b          	srliw	a5,a5,0x4
    80003d74:	0001c597          	auipc	a1,0x1c
    80003d78:	26c5a583          	lw	a1,620(a1) # 8001ffe0 <sb+0x18>
    80003d7c:	9dbd                	addw	a1,a1,a5
    80003d7e:	4088                	lw	a0,0(s1)
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	7ac080e7          	jalr	1964(ra) # 8000352c <bread>
    80003d88:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d8a:	05850593          	addi	a1,a0,88
    80003d8e:	40dc                	lw	a5,4(s1)
    80003d90:	8bbd                	andi	a5,a5,15
    80003d92:	079a                	slli	a5,a5,0x6
    80003d94:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d96:	00059783          	lh	a5,0(a1)
    80003d9a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d9e:	00259783          	lh	a5,2(a1)
    80003da2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003da6:	00459783          	lh	a5,4(a1)
    80003daa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dae:	00659783          	lh	a5,6(a1)
    80003db2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003db6:	459c                	lw	a5,8(a1)
    80003db8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dba:	03400613          	li	a2,52
    80003dbe:	05b1                	addi	a1,a1,12
    80003dc0:	05048513          	addi	a0,s1,80
    80003dc4:	ffffd097          	auipc	ra,0xffffd
    80003dc8:	f7c080e7          	jalr	-132(ra) # 80000d40 <memmove>
    brelse(bp);
    80003dcc:	854a                	mv	a0,s2
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	88e080e7          	jalr	-1906(ra) # 8000365c <brelse>
    ip->valid = 1;
    80003dd6:	4785                	li	a5,1
    80003dd8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dda:	04449783          	lh	a5,68(s1)
    80003dde:	fbb5                	bnez	a5,80003d52 <ilock+0x24>
      panic("ilock: no type");
    80003de0:	00005517          	auipc	a0,0x5
    80003de4:	9a050513          	addi	a0,a0,-1632 # 80008780 <syscalls+0x1a0>
    80003de8:	ffffc097          	auipc	ra,0xffffc
    80003dec:	756080e7          	jalr	1878(ra) # 8000053e <panic>

0000000080003df0 <iunlock>:
{
    80003df0:	1101                	addi	sp,sp,-32
    80003df2:	ec06                	sd	ra,24(sp)
    80003df4:	e822                	sd	s0,16(sp)
    80003df6:	e426                	sd	s1,8(sp)
    80003df8:	e04a                	sd	s2,0(sp)
    80003dfa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dfc:	c905                	beqz	a0,80003e2c <iunlock+0x3c>
    80003dfe:	84aa                	mv	s1,a0
    80003e00:	01050913          	addi	s2,a0,16
    80003e04:	854a                	mv	a0,s2
    80003e06:	00001097          	auipc	ra,0x1
    80003e0a:	c8c080e7          	jalr	-884(ra) # 80004a92 <holdingsleep>
    80003e0e:	cd19                	beqz	a0,80003e2c <iunlock+0x3c>
    80003e10:	449c                	lw	a5,8(s1)
    80003e12:	00f05d63          	blez	a5,80003e2c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e16:	854a                	mv	a0,s2
    80003e18:	00001097          	auipc	ra,0x1
    80003e1c:	c36080e7          	jalr	-970(ra) # 80004a4e <releasesleep>
}
    80003e20:	60e2                	ld	ra,24(sp)
    80003e22:	6442                	ld	s0,16(sp)
    80003e24:	64a2                	ld	s1,8(sp)
    80003e26:	6902                	ld	s2,0(sp)
    80003e28:	6105                	addi	sp,sp,32
    80003e2a:	8082                	ret
    panic("iunlock");
    80003e2c:	00005517          	auipc	a0,0x5
    80003e30:	96450513          	addi	a0,a0,-1692 # 80008790 <syscalls+0x1b0>
    80003e34:	ffffc097          	auipc	ra,0xffffc
    80003e38:	70a080e7          	jalr	1802(ra) # 8000053e <panic>

0000000080003e3c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e3c:	7179                	addi	sp,sp,-48
    80003e3e:	f406                	sd	ra,40(sp)
    80003e40:	f022                	sd	s0,32(sp)
    80003e42:	ec26                	sd	s1,24(sp)
    80003e44:	e84a                	sd	s2,16(sp)
    80003e46:	e44e                	sd	s3,8(sp)
    80003e48:	e052                	sd	s4,0(sp)
    80003e4a:	1800                	addi	s0,sp,48
    80003e4c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e4e:	05050493          	addi	s1,a0,80
    80003e52:	08050913          	addi	s2,a0,128
    80003e56:	a021                	j	80003e5e <itrunc+0x22>
    80003e58:	0491                	addi	s1,s1,4
    80003e5a:	01248d63          	beq	s1,s2,80003e74 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e5e:	408c                	lw	a1,0(s1)
    80003e60:	dde5                	beqz	a1,80003e58 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e62:	0009a503          	lw	a0,0(s3)
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	90c080e7          	jalr	-1780(ra) # 80003772 <bfree>
      ip->addrs[i] = 0;
    80003e6e:	0004a023          	sw	zero,0(s1)
    80003e72:	b7dd                	j	80003e58 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e74:	0809a583          	lw	a1,128(s3)
    80003e78:	e185                	bnez	a1,80003e98 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e7a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e7e:	854e                	mv	a0,s3
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	de4080e7          	jalr	-540(ra) # 80003c64 <iupdate>
}
    80003e88:	70a2                	ld	ra,40(sp)
    80003e8a:	7402                	ld	s0,32(sp)
    80003e8c:	64e2                	ld	s1,24(sp)
    80003e8e:	6942                	ld	s2,16(sp)
    80003e90:	69a2                	ld	s3,8(sp)
    80003e92:	6a02                	ld	s4,0(sp)
    80003e94:	6145                	addi	sp,sp,48
    80003e96:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e98:	0009a503          	lw	a0,0(s3)
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	690080e7          	jalr	1680(ra) # 8000352c <bread>
    80003ea4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ea6:	05850493          	addi	s1,a0,88
    80003eaa:	45850913          	addi	s2,a0,1112
    80003eae:	a811                	j	80003ec2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003eb0:	0009a503          	lw	a0,0(s3)
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	8be080e7          	jalr	-1858(ra) # 80003772 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ebc:	0491                	addi	s1,s1,4
    80003ebe:	01248563          	beq	s1,s2,80003ec8 <itrunc+0x8c>
      if(a[j])
    80003ec2:	408c                	lw	a1,0(s1)
    80003ec4:	dde5                	beqz	a1,80003ebc <itrunc+0x80>
    80003ec6:	b7ed                	j	80003eb0 <itrunc+0x74>
    brelse(bp);
    80003ec8:	8552                	mv	a0,s4
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	792080e7          	jalr	1938(ra) # 8000365c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ed2:	0809a583          	lw	a1,128(s3)
    80003ed6:	0009a503          	lw	a0,0(s3)
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	898080e7          	jalr	-1896(ra) # 80003772 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ee2:	0809a023          	sw	zero,128(s3)
    80003ee6:	bf51                	j	80003e7a <itrunc+0x3e>

0000000080003ee8 <iput>:
{
    80003ee8:	1101                	addi	sp,sp,-32
    80003eea:	ec06                	sd	ra,24(sp)
    80003eec:	e822                	sd	s0,16(sp)
    80003eee:	e426                	sd	s1,8(sp)
    80003ef0:	e04a                	sd	s2,0(sp)
    80003ef2:	1000                	addi	s0,sp,32
    80003ef4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ef6:	0001c517          	auipc	a0,0x1c
    80003efa:	0f250513          	addi	a0,a0,242 # 8001ffe8 <itable>
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	ce6080e7          	jalr	-794(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f06:	4498                	lw	a4,8(s1)
    80003f08:	4785                	li	a5,1
    80003f0a:	02f70363          	beq	a4,a5,80003f30 <iput+0x48>
  ip->ref--;
    80003f0e:	449c                	lw	a5,8(s1)
    80003f10:	37fd                	addiw	a5,a5,-1
    80003f12:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f14:	0001c517          	auipc	a0,0x1c
    80003f18:	0d450513          	addi	a0,a0,212 # 8001ffe8 <itable>
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	d7c080e7          	jalr	-644(ra) # 80000c98 <release>
}
    80003f24:	60e2                	ld	ra,24(sp)
    80003f26:	6442                	ld	s0,16(sp)
    80003f28:	64a2                	ld	s1,8(sp)
    80003f2a:	6902                	ld	s2,0(sp)
    80003f2c:	6105                	addi	sp,sp,32
    80003f2e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f30:	40bc                	lw	a5,64(s1)
    80003f32:	dff1                	beqz	a5,80003f0e <iput+0x26>
    80003f34:	04a49783          	lh	a5,74(s1)
    80003f38:	fbf9                	bnez	a5,80003f0e <iput+0x26>
    acquiresleep(&ip->lock);
    80003f3a:	01048913          	addi	s2,s1,16
    80003f3e:	854a                	mv	a0,s2
    80003f40:	00001097          	auipc	ra,0x1
    80003f44:	ab8080e7          	jalr	-1352(ra) # 800049f8 <acquiresleep>
    release(&itable.lock);
    80003f48:	0001c517          	auipc	a0,0x1c
    80003f4c:	0a050513          	addi	a0,a0,160 # 8001ffe8 <itable>
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	d48080e7          	jalr	-696(ra) # 80000c98 <release>
    itrunc(ip);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	ee2080e7          	jalr	-286(ra) # 80003e3c <itrunc>
    ip->type = 0;
    80003f62:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f66:	8526                	mv	a0,s1
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	cfc080e7          	jalr	-772(ra) # 80003c64 <iupdate>
    ip->valid = 0;
    80003f70:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f74:	854a                	mv	a0,s2
    80003f76:	00001097          	auipc	ra,0x1
    80003f7a:	ad8080e7          	jalr	-1320(ra) # 80004a4e <releasesleep>
    acquire(&itable.lock);
    80003f7e:	0001c517          	auipc	a0,0x1c
    80003f82:	06a50513          	addi	a0,a0,106 # 8001ffe8 <itable>
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	c5e080e7          	jalr	-930(ra) # 80000be4 <acquire>
    80003f8e:	b741                	j	80003f0e <iput+0x26>

0000000080003f90 <iunlockput>:
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	1000                	addi	s0,sp,32
    80003f9a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	e54080e7          	jalr	-428(ra) # 80003df0 <iunlock>
  iput(ip);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	f42080e7          	jalr	-190(ra) # 80003ee8 <iput>
}
    80003fae:	60e2                	ld	ra,24(sp)
    80003fb0:	6442                	ld	s0,16(sp)
    80003fb2:	64a2                	ld	s1,8(sp)
    80003fb4:	6105                	addi	sp,sp,32
    80003fb6:	8082                	ret

0000000080003fb8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fb8:	1141                	addi	sp,sp,-16
    80003fba:	e422                	sd	s0,8(sp)
    80003fbc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fbe:	411c                	lw	a5,0(a0)
    80003fc0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fc2:	415c                	lw	a5,4(a0)
    80003fc4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fc6:	04451783          	lh	a5,68(a0)
    80003fca:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fce:	04a51783          	lh	a5,74(a0)
    80003fd2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fd6:	04c56783          	lwu	a5,76(a0)
    80003fda:	e99c                	sd	a5,16(a1)
}
    80003fdc:	6422                	ld	s0,8(sp)
    80003fde:	0141                	addi	sp,sp,16
    80003fe0:	8082                	ret

0000000080003fe2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fe2:	457c                	lw	a5,76(a0)
    80003fe4:	0ed7e963          	bltu	a5,a3,800040d6 <readi+0xf4>
{
    80003fe8:	7159                	addi	sp,sp,-112
    80003fea:	f486                	sd	ra,104(sp)
    80003fec:	f0a2                	sd	s0,96(sp)
    80003fee:	eca6                	sd	s1,88(sp)
    80003ff0:	e8ca                	sd	s2,80(sp)
    80003ff2:	e4ce                	sd	s3,72(sp)
    80003ff4:	e0d2                	sd	s4,64(sp)
    80003ff6:	fc56                	sd	s5,56(sp)
    80003ff8:	f85a                	sd	s6,48(sp)
    80003ffa:	f45e                	sd	s7,40(sp)
    80003ffc:	f062                	sd	s8,32(sp)
    80003ffe:	ec66                	sd	s9,24(sp)
    80004000:	e86a                	sd	s10,16(sp)
    80004002:	e46e                	sd	s11,8(sp)
    80004004:	1880                	addi	s0,sp,112
    80004006:	8baa                	mv	s7,a0
    80004008:	8c2e                	mv	s8,a1
    8000400a:	8ab2                	mv	s5,a2
    8000400c:	84b6                	mv	s1,a3
    8000400e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004010:	9f35                	addw	a4,a4,a3
    return 0;
    80004012:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004014:	0ad76063          	bltu	a4,a3,800040b4 <readi+0xd2>
  if(off + n > ip->size)
    80004018:	00e7f463          	bgeu	a5,a4,80004020 <readi+0x3e>
    n = ip->size - off;
    8000401c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004020:	0a0b0963          	beqz	s6,800040d2 <readi+0xf0>
    80004024:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004026:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000402a:	5cfd                	li	s9,-1
    8000402c:	a82d                	j	80004066 <readi+0x84>
    8000402e:	020a1d93          	slli	s11,s4,0x20
    80004032:	020ddd93          	srli	s11,s11,0x20
    80004036:	05890613          	addi	a2,s2,88
    8000403a:	86ee                	mv	a3,s11
    8000403c:	963a                	add	a2,a2,a4
    8000403e:	85d6                	mv	a1,s5
    80004040:	8562                	mv	a0,s8
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	9b8080e7          	jalr	-1608(ra) # 800029fa <either_copyout>
    8000404a:	05950d63          	beq	a0,s9,800040a4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000404e:	854a                	mv	a0,s2
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	60c080e7          	jalr	1548(ra) # 8000365c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004058:	013a09bb          	addw	s3,s4,s3
    8000405c:	009a04bb          	addw	s1,s4,s1
    80004060:	9aee                	add	s5,s5,s11
    80004062:	0569f763          	bgeu	s3,s6,800040b0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004066:	000ba903          	lw	s2,0(s7)
    8000406a:	00a4d59b          	srliw	a1,s1,0xa
    8000406e:	855e                	mv	a0,s7
    80004070:	00000097          	auipc	ra,0x0
    80004074:	8b0080e7          	jalr	-1872(ra) # 80003920 <bmap>
    80004078:	0005059b          	sext.w	a1,a0
    8000407c:	854a                	mv	a0,s2
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	4ae080e7          	jalr	1198(ra) # 8000352c <bread>
    80004086:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004088:	3ff4f713          	andi	a4,s1,1023
    8000408c:	40ed07bb          	subw	a5,s10,a4
    80004090:	413b06bb          	subw	a3,s6,s3
    80004094:	8a3e                	mv	s4,a5
    80004096:	2781                	sext.w	a5,a5
    80004098:	0006861b          	sext.w	a2,a3
    8000409c:	f8f679e3          	bgeu	a2,a5,8000402e <readi+0x4c>
    800040a0:	8a36                	mv	s4,a3
    800040a2:	b771                	j	8000402e <readi+0x4c>
      brelse(bp);
    800040a4:	854a                	mv	a0,s2
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	5b6080e7          	jalr	1462(ra) # 8000365c <brelse>
      tot = -1;
    800040ae:	59fd                	li	s3,-1
  }
  return tot;
    800040b0:	0009851b          	sext.w	a0,s3
}
    800040b4:	70a6                	ld	ra,104(sp)
    800040b6:	7406                	ld	s0,96(sp)
    800040b8:	64e6                	ld	s1,88(sp)
    800040ba:	6946                	ld	s2,80(sp)
    800040bc:	69a6                	ld	s3,72(sp)
    800040be:	6a06                	ld	s4,64(sp)
    800040c0:	7ae2                	ld	s5,56(sp)
    800040c2:	7b42                	ld	s6,48(sp)
    800040c4:	7ba2                	ld	s7,40(sp)
    800040c6:	7c02                	ld	s8,32(sp)
    800040c8:	6ce2                	ld	s9,24(sp)
    800040ca:	6d42                	ld	s10,16(sp)
    800040cc:	6da2                	ld	s11,8(sp)
    800040ce:	6165                	addi	sp,sp,112
    800040d0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d2:	89da                	mv	s3,s6
    800040d4:	bff1                	j	800040b0 <readi+0xce>
    return 0;
    800040d6:	4501                	li	a0,0
}
    800040d8:	8082                	ret

00000000800040da <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040da:	457c                	lw	a5,76(a0)
    800040dc:	10d7e863          	bltu	a5,a3,800041ec <writei+0x112>
{
    800040e0:	7159                	addi	sp,sp,-112
    800040e2:	f486                	sd	ra,104(sp)
    800040e4:	f0a2                	sd	s0,96(sp)
    800040e6:	eca6                	sd	s1,88(sp)
    800040e8:	e8ca                	sd	s2,80(sp)
    800040ea:	e4ce                	sd	s3,72(sp)
    800040ec:	e0d2                	sd	s4,64(sp)
    800040ee:	fc56                	sd	s5,56(sp)
    800040f0:	f85a                	sd	s6,48(sp)
    800040f2:	f45e                	sd	s7,40(sp)
    800040f4:	f062                	sd	s8,32(sp)
    800040f6:	ec66                	sd	s9,24(sp)
    800040f8:	e86a                	sd	s10,16(sp)
    800040fa:	e46e                	sd	s11,8(sp)
    800040fc:	1880                	addi	s0,sp,112
    800040fe:	8b2a                	mv	s6,a0
    80004100:	8c2e                	mv	s8,a1
    80004102:	8ab2                	mv	s5,a2
    80004104:	8936                	mv	s2,a3
    80004106:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004108:	00e687bb          	addw	a5,a3,a4
    8000410c:	0ed7e263          	bltu	a5,a3,800041f0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004110:	00043737          	lui	a4,0x43
    80004114:	0ef76063          	bltu	a4,a5,800041f4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004118:	0c0b8863          	beqz	s7,800041e8 <writei+0x10e>
    8000411c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000411e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004122:	5cfd                	li	s9,-1
    80004124:	a091                	j	80004168 <writei+0x8e>
    80004126:	02099d93          	slli	s11,s3,0x20
    8000412a:	020ddd93          	srli	s11,s11,0x20
    8000412e:	05848513          	addi	a0,s1,88
    80004132:	86ee                	mv	a3,s11
    80004134:	8656                	mv	a2,s5
    80004136:	85e2                	mv	a1,s8
    80004138:	953a                	add	a0,a0,a4
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	916080e7          	jalr	-1770(ra) # 80002a50 <either_copyin>
    80004142:	07950263          	beq	a0,s9,800041a6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004146:	8526                	mv	a0,s1
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	790080e7          	jalr	1936(ra) # 800048d8 <log_write>
    brelse(bp);
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	50a080e7          	jalr	1290(ra) # 8000365c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000415a:	01498a3b          	addw	s4,s3,s4
    8000415e:	0129893b          	addw	s2,s3,s2
    80004162:	9aee                	add	s5,s5,s11
    80004164:	057a7663          	bgeu	s4,s7,800041b0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004168:	000b2483          	lw	s1,0(s6)
    8000416c:	00a9559b          	srliw	a1,s2,0xa
    80004170:	855a                	mv	a0,s6
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	7ae080e7          	jalr	1966(ra) # 80003920 <bmap>
    8000417a:	0005059b          	sext.w	a1,a0
    8000417e:	8526                	mv	a0,s1
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	3ac080e7          	jalr	940(ra) # 8000352c <bread>
    80004188:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000418a:	3ff97713          	andi	a4,s2,1023
    8000418e:	40ed07bb          	subw	a5,s10,a4
    80004192:	414b86bb          	subw	a3,s7,s4
    80004196:	89be                	mv	s3,a5
    80004198:	2781                	sext.w	a5,a5
    8000419a:	0006861b          	sext.w	a2,a3
    8000419e:	f8f674e3          	bgeu	a2,a5,80004126 <writei+0x4c>
    800041a2:	89b6                	mv	s3,a3
    800041a4:	b749                	j	80004126 <writei+0x4c>
      brelse(bp);
    800041a6:	8526                	mv	a0,s1
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	4b4080e7          	jalr	1204(ra) # 8000365c <brelse>
  }

  if(off > ip->size)
    800041b0:	04cb2783          	lw	a5,76(s6)
    800041b4:	0127f463          	bgeu	a5,s2,800041bc <writei+0xe2>
    ip->size = off;
    800041b8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041bc:	855a                	mv	a0,s6
    800041be:	00000097          	auipc	ra,0x0
    800041c2:	aa6080e7          	jalr	-1370(ra) # 80003c64 <iupdate>

  return tot;
    800041c6:	000a051b          	sext.w	a0,s4
}
    800041ca:	70a6                	ld	ra,104(sp)
    800041cc:	7406                	ld	s0,96(sp)
    800041ce:	64e6                	ld	s1,88(sp)
    800041d0:	6946                	ld	s2,80(sp)
    800041d2:	69a6                	ld	s3,72(sp)
    800041d4:	6a06                	ld	s4,64(sp)
    800041d6:	7ae2                	ld	s5,56(sp)
    800041d8:	7b42                	ld	s6,48(sp)
    800041da:	7ba2                	ld	s7,40(sp)
    800041dc:	7c02                	ld	s8,32(sp)
    800041de:	6ce2                	ld	s9,24(sp)
    800041e0:	6d42                	ld	s10,16(sp)
    800041e2:	6da2                	ld	s11,8(sp)
    800041e4:	6165                	addi	sp,sp,112
    800041e6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041e8:	8a5e                	mv	s4,s7
    800041ea:	bfc9                	j	800041bc <writei+0xe2>
    return -1;
    800041ec:	557d                	li	a0,-1
}
    800041ee:	8082                	ret
    return -1;
    800041f0:	557d                	li	a0,-1
    800041f2:	bfe1                	j	800041ca <writei+0xf0>
    return -1;
    800041f4:	557d                	li	a0,-1
    800041f6:	bfd1                	j	800041ca <writei+0xf0>

00000000800041f8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041f8:	1141                	addi	sp,sp,-16
    800041fa:	e406                	sd	ra,8(sp)
    800041fc:	e022                	sd	s0,0(sp)
    800041fe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004200:	4639                	li	a2,14
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	bb6080e7          	jalr	-1098(ra) # 80000db8 <strncmp>
}
    8000420a:	60a2                	ld	ra,8(sp)
    8000420c:	6402                	ld	s0,0(sp)
    8000420e:	0141                	addi	sp,sp,16
    80004210:	8082                	ret

0000000080004212 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004212:	7139                	addi	sp,sp,-64
    80004214:	fc06                	sd	ra,56(sp)
    80004216:	f822                	sd	s0,48(sp)
    80004218:	f426                	sd	s1,40(sp)
    8000421a:	f04a                	sd	s2,32(sp)
    8000421c:	ec4e                	sd	s3,24(sp)
    8000421e:	e852                	sd	s4,16(sp)
    80004220:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004222:	04451703          	lh	a4,68(a0)
    80004226:	4785                	li	a5,1
    80004228:	00f71a63          	bne	a4,a5,8000423c <dirlookup+0x2a>
    8000422c:	892a                	mv	s2,a0
    8000422e:	89ae                	mv	s3,a1
    80004230:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004232:	457c                	lw	a5,76(a0)
    80004234:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004236:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004238:	e79d                	bnez	a5,80004266 <dirlookup+0x54>
    8000423a:	a8a5                	j	800042b2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000423c:	00004517          	auipc	a0,0x4
    80004240:	55c50513          	addi	a0,a0,1372 # 80008798 <syscalls+0x1b8>
    80004244:	ffffc097          	auipc	ra,0xffffc
    80004248:	2fa080e7          	jalr	762(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000424c:	00004517          	auipc	a0,0x4
    80004250:	56450513          	addi	a0,a0,1380 # 800087b0 <syscalls+0x1d0>
    80004254:	ffffc097          	auipc	ra,0xffffc
    80004258:	2ea080e7          	jalr	746(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000425c:	24c1                	addiw	s1,s1,16
    8000425e:	04c92783          	lw	a5,76(s2)
    80004262:	04f4f763          	bgeu	s1,a5,800042b0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004266:	4741                	li	a4,16
    80004268:	86a6                	mv	a3,s1
    8000426a:	fc040613          	addi	a2,s0,-64
    8000426e:	4581                	li	a1,0
    80004270:	854a                	mv	a0,s2
    80004272:	00000097          	auipc	ra,0x0
    80004276:	d70080e7          	jalr	-656(ra) # 80003fe2 <readi>
    8000427a:	47c1                	li	a5,16
    8000427c:	fcf518e3          	bne	a0,a5,8000424c <dirlookup+0x3a>
    if(de.inum == 0)
    80004280:	fc045783          	lhu	a5,-64(s0)
    80004284:	dfe1                	beqz	a5,8000425c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004286:	fc240593          	addi	a1,s0,-62
    8000428a:	854e                	mv	a0,s3
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	f6c080e7          	jalr	-148(ra) # 800041f8 <namecmp>
    80004294:	f561                	bnez	a0,8000425c <dirlookup+0x4a>
      if(poff)
    80004296:	000a0463          	beqz	s4,8000429e <dirlookup+0x8c>
        *poff = off;
    8000429a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000429e:	fc045583          	lhu	a1,-64(s0)
    800042a2:	00092503          	lw	a0,0(s2)
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	754080e7          	jalr	1876(ra) # 800039fa <iget>
    800042ae:	a011                	j	800042b2 <dirlookup+0xa0>
  return 0;
    800042b0:	4501                	li	a0,0
}
    800042b2:	70e2                	ld	ra,56(sp)
    800042b4:	7442                	ld	s0,48(sp)
    800042b6:	74a2                	ld	s1,40(sp)
    800042b8:	7902                	ld	s2,32(sp)
    800042ba:	69e2                	ld	s3,24(sp)
    800042bc:	6a42                	ld	s4,16(sp)
    800042be:	6121                	addi	sp,sp,64
    800042c0:	8082                	ret

00000000800042c2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042c2:	711d                	addi	sp,sp,-96
    800042c4:	ec86                	sd	ra,88(sp)
    800042c6:	e8a2                	sd	s0,80(sp)
    800042c8:	e4a6                	sd	s1,72(sp)
    800042ca:	e0ca                	sd	s2,64(sp)
    800042cc:	fc4e                	sd	s3,56(sp)
    800042ce:	f852                	sd	s4,48(sp)
    800042d0:	f456                	sd	s5,40(sp)
    800042d2:	f05a                	sd	s6,32(sp)
    800042d4:	ec5e                	sd	s7,24(sp)
    800042d6:	e862                	sd	s8,16(sp)
    800042d8:	e466                	sd	s9,8(sp)
    800042da:	1080                	addi	s0,sp,96
    800042dc:	84aa                	mv	s1,a0
    800042de:	8b2e                	mv	s6,a1
    800042e0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042e2:	00054703          	lbu	a4,0(a0)
    800042e6:	02f00793          	li	a5,47
    800042ea:	02f70363          	beq	a4,a5,80004310 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ee:	ffffe097          	auipc	ra,0xffffe
    800042f2:	8c4080e7          	jalr	-1852(ra) # 80001bb2 <myproc>
    800042f6:	17053503          	ld	a0,368(a0)
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	9f6080e7          	jalr	-1546(ra) # 80003cf0 <idup>
    80004302:	89aa                	mv	s3,a0
  while(*path == '/')
    80004304:	02f00913          	li	s2,47
  len = path - s;
    80004308:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000430a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000430c:	4c05                	li	s8,1
    8000430e:	a865                	j	800043c6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004310:	4585                	li	a1,1
    80004312:	4505                	li	a0,1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	6e6080e7          	jalr	1766(ra) # 800039fa <iget>
    8000431c:	89aa                	mv	s3,a0
    8000431e:	b7dd                	j	80004304 <namex+0x42>
      iunlockput(ip);
    80004320:	854e                	mv	a0,s3
    80004322:	00000097          	auipc	ra,0x0
    80004326:	c6e080e7          	jalr	-914(ra) # 80003f90 <iunlockput>
      return 0;
    8000432a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000432c:	854e                	mv	a0,s3
    8000432e:	60e6                	ld	ra,88(sp)
    80004330:	6446                	ld	s0,80(sp)
    80004332:	64a6                	ld	s1,72(sp)
    80004334:	6906                	ld	s2,64(sp)
    80004336:	79e2                	ld	s3,56(sp)
    80004338:	7a42                	ld	s4,48(sp)
    8000433a:	7aa2                	ld	s5,40(sp)
    8000433c:	7b02                	ld	s6,32(sp)
    8000433e:	6be2                	ld	s7,24(sp)
    80004340:	6c42                	ld	s8,16(sp)
    80004342:	6ca2                	ld	s9,8(sp)
    80004344:	6125                	addi	sp,sp,96
    80004346:	8082                	ret
      iunlock(ip);
    80004348:	854e                	mv	a0,s3
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	aa6080e7          	jalr	-1370(ra) # 80003df0 <iunlock>
      return ip;
    80004352:	bfe9                	j	8000432c <namex+0x6a>
      iunlockput(ip);
    80004354:	854e                	mv	a0,s3
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c3a080e7          	jalr	-966(ra) # 80003f90 <iunlockput>
      return 0;
    8000435e:	89d2                	mv	s3,s4
    80004360:	b7f1                	j	8000432c <namex+0x6a>
  len = path - s;
    80004362:	40b48633          	sub	a2,s1,a1
    80004366:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000436a:	094cd463          	bge	s9,s4,800043f2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000436e:	4639                	li	a2,14
    80004370:	8556                	mv	a0,s5
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	9ce080e7          	jalr	-1586(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000437a:	0004c783          	lbu	a5,0(s1)
    8000437e:	01279763          	bne	a5,s2,8000438c <namex+0xca>
    path++;
    80004382:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004384:	0004c783          	lbu	a5,0(s1)
    80004388:	ff278de3          	beq	a5,s2,80004382 <namex+0xc0>
    ilock(ip);
    8000438c:	854e                	mv	a0,s3
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	9a0080e7          	jalr	-1632(ra) # 80003d2e <ilock>
    if(ip->type != T_DIR){
    80004396:	04499783          	lh	a5,68(s3)
    8000439a:	f98793e3          	bne	a5,s8,80004320 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000439e:	000b0563          	beqz	s6,800043a8 <namex+0xe6>
    800043a2:	0004c783          	lbu	a5,0(s1)
    800043a6:	d3cd                	beqz	a5,80004348 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043a8:	865e                	mv	a2,s7
    800043aa:	85d6                	mv	a1,s5
    800043ac:	854e                	mv	a0,s3
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	e64080e7          	jalr	-412(ra) # 80004212 <dirlookup>
    800043b6:	8a2a                	mv	s4,a0
    800043b8:	dd51                	beqz	a0,80004354 <namex+0x92>
    iunlockput(ip);
    800043ba:	854e                	mv	a0,s3
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	bd4080e7          	jalr	-1068(ra) # 80003f90 <iunlockput>
    ip = next;
    800043c4:	89d2                	mv	s3,s4
  while(*path == '/')
    800043c6:	0004c783          	lbu	a5,0(s1)
    800043ca:	05279763          	bne	a5,s2,80004418 <namex+0x156>
    path++;
    800043ce:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043d0:	0004c783          	lbu	a5,0(s1)
    800043d4:	ff278de3          	beq	a5,s2,800043ce <namex+0x10c>
  if(*path == 0)
    800043d8:	c79d                	beqz	a5,80004406 <namex+0x144>
    path++;
    800043da:	85a6                	mv	a1,s1
  len = path - s;
    800043dc:	8a5e                	mv	s4,s7
    800043de:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043e0:	01278963          	beq	a5,s2,800043f2 <namex+0x130>
    800043e4:	dfbd                	beqz	a5,80004362 <namex+0xa0>
    path++;
    800043e6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043e8:	0004c783          	lbu	a5,0(s1)
    800043ec:	ff279ce3          	bne	a5,s2,800043e4 <namex+0x122>
    800043f0:	bf8d                	j	80004362 <namex+0xa0>
    memmove(name, s, len);
    800043f2:	2601                	sext.w	a2,a2
    800043f4:	8556                	mv	a0,s5
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	94a080e7          	jalr	-1718(ra) # 80000d40 <memmove>
    name[len] = 0;
    800043fe:	9a56                	add	s4,s4,s5
    80004400:	000a0023          	sb	zero,0(s4)
    80004404:	bf9d                	j	8000437a <namex+0xb8>
  if(nameiparent){
    80004406:	f20b03e3          	beqz	s6,8000432c <namex+0x6a>
    iput(ip);
    8000440a:	854e                	mv	a0,s3
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	adc080e7          	jalr	-1316(ra) # 80003ee8 <iput>
    return 0;
    80004414:	4981                	li	s3,0
    80004416:	bf19                	j	8000432c <namex+0x6a>
  if(*path == 0)
    80004418:	d7fd                	beqz	a5,80004406 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000441a:	0004c783          	lbu	a5,0(s1)
    8000441e:	85a6                	mv	a1,s1
    80004420:	b7d1                	j	800043e4 <namex+0x122>

0000000080004422 <dirlink>:
{
    80004422:	7139                	addi	sp,sp,-64
    80004424:	fc06                	sd	ra,56(sp)
    80004426:	f822                	sd	s0,48(sp)
    80004428:	f426                	sd	s1,40(sp)
    8000442a:	f04a                	sd	s2,32(sp)
    8000442c:	ec4e                	sd	s3,24(sp)
    8000442e:	e852                	sd	s4,16(sp)
    80004430:	0080                	addi	s0,sp,64
    80004432:	892a                	mv	s2,a0
    80004434:	8a2e                	mv	s4,a1
    80004436:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004438:	4601                	li	a2,0
    8000443a:	00000097          	auipc	ra,0x0
    8000443e:	dd8080e7          	jalr	-552(ra) # 80004212 <dirlookup>
    80004442:	e93d                	bnez	a0,800044b8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004444:	04c92483          	lw	s1,76(s2)
    80004448:	c49d                	beqz	s1,80004476 <dirlink+0x54>
    8000444a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444c:	4741                	li	a4,16
    8000444e:	86a6                	mv	a3,s1
    80004450:	fc040613          	addi	a2,s0,-64
    80004454:	4581                	li	a1,0
    80004456:	854a                	mv	a0,s2
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	b8a080e7          	jalr	-1142(ra) # 80003fe2 <readi>
    80004460:	47c1                	li	a5,16
    80004462:	06f51163          	bne	a0,a5,800044c4 <dirlink+0xa2>
    if(de.inum == 0)
    80004466:	fc045783          	lhu	a5,-64(s0)
    8000446a:	c791                	beqz	a5,80004476 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000446c:	24c1                	addiw	s1,s1,16
    8000446e:	04c92783          	lw	a5,76(s2)
    80004472:	fcf4ede3          	bltu	s1,a5,8000444c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004476:	4639                	li	a2,14
    80004478:	85d2                	mv	a1,s4
    8000447a:	fc240513          	addi	a0,s0,-62
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	976080e7          	jalr	-1674(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004486:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000448a:	4741                	li	a4,16
    8000448c:	86a6                	mv	a3,s1
    8000448e:	fc040613          	addi	a2,s0,-64
    80004492:	4581                	li	a1,0
    80004494:	854a                	mv	a0,s2
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	c44080e7          	jalr	-956(ra) # 800040da <writei>
    8000449e:	872a                	mv	a4,a0
    800044a0:	47c1                	li	a5,16
  return 0;
    800044a2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044a4:	02f71863          	bne	a4,a5,800044d4 <dirlink+0xb2>
}
    800044a8:	70e2                	ld	ra,56(sp)
    800044aa:	7442                	ld	s0,48(sp)
    800044ac:	74a2                	ld	s1,40(sp)
    800044ae:	7902                	ld	s2,32(sp)
    800044b0:	69e2                	ld	s3,24(sp)
    800044b2:	6a42                	ld	s4,16(sp)
    800044b4:	6121                	addi	sp,sp,64
    800044b6:	8082                	ret
    iput(ip);
    800044b8:	00000097          	auipc	ra,0x0
    800044bc:	a30080e7          	jalr	-1488(ra) # 80003ee8 <iput>
    return -1;
    800044c0:	557d                	li	a0,-1
    800044c2:	b7dd                	j	800044a8 <dirlink+0x86>
      panic("dirlink read");
    800044c4:	00004517          	auipc	a0,0x4
    800044c8:	2fc50513          	addi	a0,a0,764 # 800087c0 <syscalls+0x1e0>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	072080e7          	jalr	114(ra) # 8000053e <panic>
    panic("dirlink");
    800044d4:	00004517          	auipc	a0,0x4
    800044d8:	3fc50513          	addi	a0,a0,1020 # 800088d0 <syscalls+0x2f0>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	062080e7          	jalr	98(ra) # 8000053e <panic>

00000000800044e4 <namei>:

struct inode*
namei(char *path)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ec:	fe040613          	addi	a2,s0,-32
    800044f0:	4581                	li	a1,0
    800044f2:	00000097          	auipc	ra,0x0
    800044f6:	dd0080e7          	jalr	-560(ra) # 800042c2 <namex>
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	6105                	addi	sp,sp,32
    80004500:	8082                	ret

0000000080004502 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004502:	1141                	addi	sp,sp,-16
    80004504:	e406                	sd	ra,8(sp)
    80004506:	e022                	sd	s0,0(sp)
    80004508:	0800                	addi	s0,sp,16
    8000450a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000450c:	4585                	li	a1,1
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	db4080e7          	jalr	-588(ra) # 800042c2 <namex>
}
    80004516:	60a2                	ld	ra,8(sp)
    80004518:	6402                	ld	s0,0(sp)
    8000451a:	0141                	addi	sp,sp,16
    8000451c:	8082                	ret

000000008000451e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000451e:	1101                	addi	sp,sp,-32
    80004520:	ec06                	sd	ra,24(sp)
    80004522:	e822                	sd	s0,16(sp)
    80004524:	e426                	sd	s1,8(sp)
    80004526:	e04a                	sd	s2,0(sp)
    80004528:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000452a:	0001d917          	auipc	s2,0x1d
    8000452e:	56690913          	addi	s2,s2,1382 # 80021a90 <log>
    80004532:	01892583          	lw	a1,24(s2)
    80004536:	02892503          	lw	a0,40(s2)
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	ff2080e7          	jalr	-14(ra) # 8000352c <bread>
    80004542:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004544:	02c92683          	lw	a3,44(s2)
    80004548:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000454a:	02d05763          	blez	a3,80004578 <write_head+0x5a>
    8000454e:	0001d797          	auipc	a5,0x1d
    80004552:	57278793          	addi	a5,a5,1394 # 80021ac0 <log+0x30>
    80004556:	05c50713          	addi	a4,a0,92
    8000455a:	36fd                	addiw	a3,a3,-1
    8000455c:	1682                	slli	a3,a3,0x20
    8000455e:	9281                	srli	a3,a3,0x20
    80004560:	068a                	slli	a3,a3,0x2
    80004562:	0001d617          	auipc	a2,0x1d
    80004566:	56260613          	addi	a2,a2,1378 # 80021ac4 <log+0x34>
    8000456a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000456c:	4390                	lw	a2,0(a5)
    8000456e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004570:	0791                	addi	a5,a5,4
    80004572:	0711                	addi	a4,a4,4
    80004574:	fed79ce3          	bne	a5,a3,8000456c <write_head+0x4e>
  }
  bwrite(buf);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	0a4080e7          	jalr	164(ra) # 8000361e <bwrite>
  brelse(buf);
    80004582:	8526                	mv	a0,s1
    80004584:	fffff097          	auipc	ra,0xfffff
    80004588:	0d8080e7          	jalr	216(ra) # 8000365c <brelse>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004598:	0001d797          	auipc	a5,0x1d
    8000459c:	5247a783          	lw	a5,1316(a5) # 80021abc <log+0x2c>
    800045a0:	0af05d63          	blez	a5,8000465a <install_trans+0xc2>
{
    800045a4:	7139                	addi	sp,sp,-64
    800045a6:	fc06                	sd	ra,56(sp)
    800045a8:	f822                	sd	s0,48(sp)
    800045aa:	f426                	sd	s1,40(sp)
    800045ac:	f04a                	sd	s2,32(sp)
    800045ae:	ec4e                	sd	s3,24(sp)
    800045b0:	e852                	sd	s4,16(sp)
    800045b2:	e456                	sd	s5,8(sp)
    800045b4:	e05a                	sd	s6,0(sp)
    800045b6:	0080                	addi	s0,sp,64
    800045b8:	8b2a                	mv	s6,a0
    800045ba:	0001da97          	auipc	s5,0x1d
    800045be:	506a8a93          	addi	s5,s5,1286 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045c4:	0001d997          	auipc	s3,0x1d
    800045c8:	4cc98993          	addi	s3,s3,1228 # 80021a90 <log>
    800045cc:	a035                	j	800045f8 <install_trans+0x60>
      bunpin(dbuf);
    800045ce:	8526                	mv	a0,s1
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	166080e7          	jalr	358(ra) # 80003736 <bunpin>
    brelse(lbuf);
    800045d8:	854a                	mv	a0,s2
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	082080e7          	jalr	130(ra) # 8000365c <brelse>
    brelse(dbuf);
    800045e2:	8526                	mv	a0,s1
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	078080e7          	jalr	120(ra) # 8000365c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ec:	2a05                	addiw	s4,s4,1
    800045ee:	0a91                	addi	s5,s5,4
    800045f0:	02c9a783          	lw	a5,44(s3)
    800045f4:	04fa5963          	bge	s4,a5,80004646 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045f8:	0189a583          	lw	a1,24(s3)
    800045fc:	014585bb          	addw	a1,a1,s4
    80004600:	2585                	addiw	a1,a1,1
    80004602:	0289a503          	lw	a0,40(s3)
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	f26080e7          	jalr	-218(ra) # 8000352c <bread>
    8000460e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004610:	000aa583          	lw	a1,0(s5)
    80004614:	0289a503          	lw	a0,40(s3)
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	f14080e7          	jalr	-236(ra) # 8000352c <bread>
    80004620:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004622:	40000613          	li	a2,1024
    80004626:	05890593          	addi	a1,s2,88
    8000462a:	05850513          	addi	a0,a0,88
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	712080e7          	jalr	1810(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004636:	8526                	mv	a0,s1
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	fe6080e7          	jalr	-26(ra) # 8000361e <bwrite>
    if(recovering == 0)
    80004640:	f80b1ce3          	bnez	s6,800045d8 <install_trans+0x40>
    80004644:	b769                	j	800045ce <install_trans+0x36>
}
    80004646:	70e2                	ld	ra,56(sp)
    80004648:	7442                	ld	s0,48(sp)
    8000464a:	74a2                	ld	s1,40(sp)
    8000464c:	7902                	ld	s2,32(sp)
    8000464e:	69e2                	ld	s3,24(sp)
    80004650:	6a42                	ld	s4,16(sp)
    80004652:	6aa2                	ld	s5,8(sp)
    80004654:	6b02                	ld	s6,0(sp)
    80004656:	6121                	addi	sp,sp,64
    80004658:	8082                	ret
    8000465a:	8082                	ret

000000008000465c <initlog>:
{
    8000465c:	7179                	addi	sp,sp,-48
    8000465e:	f406                	sd	ra,40(sp)
    80004660:	f022                	sd	s0,32(sp)
    80004662:	ec26                	sd	s1,24(sp)
    80004664:	e84a                	sd	s2,16(sp)
    80004666:	e44e                	sd	s3,8(sp)
    80004668:	1800                	addi	s0,sp,48
    8000466a:	892a                	mv	s2,a0
    8000466c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000466e:	0001d497          	auipc	s1,0x1d
    80004672:	42248493          	addi	s1,s1,1058 # 80021a90 <log>
    80004676:	00004597          	auipc	a1,0x4
    8000467a:	15a58593          	addi	a1,a1,346 # 800087d0 <syscalls+0x1f0>
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	4d4080e7          	jalr	1236(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004688:	0149a583          	lw	a1,20(s3)
    8000468c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000468e:	0109a783          	lw	a5,16(s3)
    80004692:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004694:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004698:	854a                	mv	a0,s2
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	e92080e7          	jalr	-366(ra) # 8000352c <bread>
  log.lh.n = lh->n;
    800046a2:	4d3c                	lw	a5,88(a0)
    800046a4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046a6:	02f05563          	blez	a5,800046d0 <initlog+0x74>
    800046aa:	05c50713          	addi	a4,a0,92
    800046ae:	0001d697          	auipc	a3,0x1d
    800046b2:	41268693          	addi	a3,a3,1042 # 80021ac0 <log+0x30>
    800046b6:	37fd                	addiw	a5,a5,-1
    800046b8:	1782                	slli	a5,a5,0x20
    800046ba:	9381                	srli	a5,a5,0x20
    800046bc:	078a                	slli	a5,a5,0x2
    800046be:	06050613          	addi	a2,a0,96
    800046c2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046c4:	4310                	lw	a2,0(a4)
    800046c6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046c8:	0711                	addi	a4,a4,4
    800046ca:	0691                	addi	a3,a3,4
    800046cc:	fef71ce3          	bne	a4,a5,800046c4 <initlog+0x68>
  brelse(buf);
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	f8c080e7          	jalr	-116(ra) # 8000365c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046d8:	4505                	li	a0,1
    800046da:	00000097          	auipc	ra,0x0
    800046de:	ebe080e7          	jalr	-322(ra) # 80004598 <install_trans>
  log.lh.n = 0;
    800046e2:	0001d797          	auipc	a5,0x1d
    800046e6:	3c07ad23          	sw	zero,986(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	e34080e7          	jalr	-460(ra) # 8000451e <write_head>
}
    800046f2:	70a2                	ld	ra,40(sp)
    800046f4:	7402                	ld	s0,32(sp)
    800046f6:	64e2                	ld	s1,24(sp)
    800046f8:	6942                	ld	s2,16(sp)
    800046fa:	69a2                	ld	s3,8(sp)
    800046fc:	6145                	addi	sp,sp,48
    800046fe:	8082                	ret

0000000080004700 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004700:	1101                	addi	sp,sp,-32
    80004702:	ec06                	sd	ra,24(sp)
    80004704:	e822                	sd	s0,16(sp)
    80004706:	e426                	sd	s1,8(sp)
    80004708:	e04a                	sd	s2,0(sp)
    8000470a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000470c:	0001d517          	auipc	a0,0x1d
    80004710:	38450513          	addi	a0,a0,900 # 80021a90 <log>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	4d0080e7          	jalr	1232(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000471c:	0001d497          	auipc	s1,0x1d
    80004720:	37448493          	addi	s1,s1,884 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004724:	4979                	li	s2,30
    80004726:	a039                	j	80004734 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004728:	85a6                	mv	a1,s1
    8000472a:	8526                	mv	a0,s1
    8000472c:	ffffe097          	auipc	ra,0xffffe
    80004730:	ec8080e7          	jalr	-312(ra) # 800025f4 <sleep>
    if(log.committing){
    80004734:	50dc                	lw	a5,36(s1)
    80004736:	fbed                	bnez	a5,80004728 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004738:	509c                	lw	a5,32(s1)
    8000473a:	0017871b          	addiw	a4,a5,1
    8000473e:	0007069b          	sext.w	a3,a4
    80004742:	0027179b          	slliw	a5,a4,0x2
    80004746:	9fb9                	addw	a5,a5,a4
    80004748:	0017979b          	slliw	a5,a5,0x1
    8000474c:	54d8                	lw	a4,44(s1)
    8000474e:	9fb9                	addw	a5,a5,a4
    80004750:	00f95963          	bge	s2,a5,80004762 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004754:	85a6                	mv	a1,s1
    80004756:	8526                	mv	a0,s1
    80004758:	ffffe097          	auipc	ra,0xffffe
    8000475c:	e9c080e7          	jalr	-356(ra) # 800025f4 <sleep>
    80004760:	bfd1                	j	80004734 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004762:	0001d517          	auipc	a0,0x1d
    80004766:	32e50513          	addi	a0,a0,814 # 80021a90 <log>
    8000476a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	52c080e7          	jalr	1324(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6902                	ld	s2,0(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret

0000000080004780 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004780:	7139                	addi	sp,sp,-64
    80004782:	fc06                	sd	ra,56(sp)
    80004784:	f822                	sd	s0,48(sp)
    80004786:	f426                	sd	s1,40(sp)
    80004788:	f04a                	sd	s2,32(sp)
    8000478a:	ec4e                	sd	s3,24(sp)
    8000478c:	e852                	sd	s4,16(sp)
    8000478e:	e456                	sd	s5,8(sp)
    80004790:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004792:	0001d497          	auipc	s1,0x1d
    80004796:	2fe48493          	addi	s1,s1,766 # 80021a90 <log>
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	448080e7          	jalr	1096(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800047a4:	509c                	lw	a5,32(s1)
    800047a6:	37fd                	addiw	a5,a5,-1
    800047a8:	0007891b          	sext.w	s2,a5
    800047ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047ae:	50dc                	lw	a5,36(s1)
    800047b0:	efb9                	bnez	a5,8000480e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047b2:	06091663          	bnez	s2,8000481e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047b6:	0001d497          	auipc	s1,0x1d
    800047ba:	2da48493          	addi	s1,s1,730 # 80021a90 <log>
    800047be:	4785                	li	a5,1
    800047c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047c2:	8526                	mv	a0,s1
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	4d4080e7          	jalr	1236(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047cc:	54dc                	lw	a5,44(s1)
    800047ce:	06f04763          	bgtz	a5,8000483c <end_op+0xbc>
    acquire(&log.lock);
    800047d2:	0001d497          	auipc	s1,0x1d
    800047d6:	2be48493          	addi	s1,s1,702 # 80021a90 <log>
    800047da:	8526                	mv	a0,s1
    800047dc:	ffffc097          	auipc	ra,0xffffc
    800047e0:	408080e7          	jalr	1032(ra) # 80000be4 <acquire>
    log.committing = 0;
    800047e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047e8:	8526                	mv	a0,s1
    800047ea:	ffffe097          	auipc	ra,0xffffe
    800047ee:	fb0080e7          	jalr	-80(ra) # 8000279a <wakeup>
    release(&log.lock);
    800047f2:	8526                	mv	a0,s1
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	4a4080e7          	jalr	1188(ra) # 80000c98 <release>
}
    800047fc:	70e2                	ld	ra,56(sp)
    800047fe:	7442                	ld	s0,48(sp)
    80004800:	74a2                	ld	s1,40(sp)
    80004802:	7902                	ld	s2,32(sp)
    80004804:	69e2                	ld	s3,24(sp)
    80004806:	6a42                	ld	s4,16(sp)
    80004808:	6aa2                	ld	s5,8(sp)
    8000480a:	6121                	addi	sp,sp,64
    8000480c:	8082                	ret
    panic("log.committing");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	fca50513          	addi	a0,a0,-54 # 800087d8 <syscalls+0x1f8>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	d28080e7          	jalr	-728(ra) # 8000053e <panic>
    wakeup(&log);
    8000481e:	0001d497          	auipc	s1,0x1d
    80004822:	27248493          	addi	s1,s1,626 # 80021a90 <log>
    80004826:	8526                	mv	a0,s1
    80004828:	ffffe097          	auipc	ra,0xffffe
    8000482c:	f72080e7          	jalr	-142(ra) # 8000279a <wakeup>
  release(&log.lock);
    80004830:	8526                	mv	a0,s1
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
  if(do_commit){
    8000483a:	b7c9                	j	800047fc <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000483c:	0001da97          	auipc	s5,0x1d
    80004840:	284a8a93          	addi	s5,s5,644 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004844:	0001da17          	auipc	s4,0x1d
    80004848:	24ca0a13          	addi	s4,s4,588 # 80021a90 <log>
    8000484c:	018a2583          	lw	a1,24(s4)
    80004850:	012585bb          	addw	a1,a1,s2
    80004854:	2585                	addiw	a1,a1,1
    80004856:	028a2503          	lw	a0,40(s4)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	cd2080e7          	jalr	-814(ra) # 8000352c <bread>
    80004862:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004864:	000aa583          	lw	a1,0(s5)
    80004868:	028a2503          	lw	a0,40(s4)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	cc0080e7          	jalr	-832(ra) # 8000352c <bread>
    80004874:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004876:	40000613          	li	a2,1024
    8000487a:	05850593          	addi	a1,a0,88
    8000487e:	05848513          	addi	a0,s1,88
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	4be080e7          	jalr	1214(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000488a:	8526                	mv	a0,s1
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	d92080e7          	jalr	-622(ra) # 8000361e <bwrite>
    brelse(from);
    80004894:	854e                	mv	a0,s3
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	dc6080e7          	jalr	-570(ra) # 8000365c <brelse>
    brelse(to);
    8000489e:	8526                	mv	a0,s1
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	dbc080e7          	jalr	-580(ra) # 8000365c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048a8:	2905                	addiw	s2,s2,1
    800048aa:	0a91                	addi	s5,s5,4
    800048ac:	02ca2783          	lw	a5,44(s4)
    800048b0:	f8f94ee3          	blt	s2,a5,8000484c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	c6a080e7          	jalr	-918(ra) # 8000451e <write_head>
    install_trans(0); // Now install writes to home locations
    800048bc:	4501                	li	a0,0
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	cda080e7          	jalr	-806(ra) # 80004598 <install_trans>
    log.lh.n = 0;
    800048c6:	0001d797          	auipc	a5,0x1d
    800048ca:	1e07ab23          	sw	zero,502(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	c50080e7          	jalr	-944(ra) # 8000451e <write_head>
    800048d6:	bdf5                	j	800047d2 <end_op+0x52>

00000000800048d8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048d8:	1101                	addi	sp,sp,-32
    800048da:	ec06                	sd	ra,24(sp)
    800048dc:	e822                	sd	s0,16(sp)
    800048de:	e426                	sd	s1,8(sp)
    800048e0:	e04a                	sd	s2,0(sp)
    800048e2:	1000                	addi	s0,sp,32
    800048e4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048e6:	0001d917          	auipc	s2,0x1d
    800048ea:	1aa90913          	addi	s2,s2,426 # 80021a90 <log>
    800048ee:	854a                	mv	a0,s2
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	2f4080e7          	jalr	756(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048f8:	02c92603          	lw	a2,44(s2)
    800048fc:	47f5                	li	a5,29
    800048fe:	06c7c563          	blt	a5,a2,80004968 <log_write+0x90>
    80004902:	0001d797          	auipc	a5,0x1d
    80004906:	1aa7a783          	lw	a5,426(a5) # 80021aac <log+0x1c>
    8000490a:	37fd                	addiw	a5,a5,-1
    8000490c:	04f65e63          	bge	a2,a5,80004968 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004910:	0001d797          	auipc	a5,0x1d
    80004914:	1a07a783          	lw	a5,416(a5) # 80021ab0 <log+0x20>
    80004918:	06f05063          	blez	a5,80004978 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000491c:	4781                	li	a5,0
    8000491e:	06c05563          	blez	a2,80004988 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004922:	44cc                	lw	a1,12(s1)
    80004924:	0001d717          	auipc	a4,0x1d
    80004928:	19c70713          	addi	a4,a4,412 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000492c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000492e:	4314                	lw	a3,0(a4)
    80004930:	04b68c63          	beq	a3,a1,80004988 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004934:	2785                	addiw	a5,a5,1
    80004936:	0711                	addi	a4,a4,4
    80004938:	fef61be3          	bne	a2,a5,8000492e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000493c:	0621                	addi	a2,a2,8
    8000493e:	060a                	slli	a2,a2,0x2
    80004940:	0001d797          	auipc	a5,0x1d
    80004944:	15078793          	addi	a5,a5,336 # 80021a90 <log>
    80004948:	963e                	add	a2,a2,a5
    8000494a:	44dc                	lw	a5,12(s1)
    8000494c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000494e:	8526                	mv	a0,s1
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	daa080e7          	jalr	-598(ra) # 800036fa <bpin>
    log.lh.n++;
    80004958:	0001d717          	auipc	a4,0x1d
    8000495c:	13870713          	addi	a4,a4,312 # 80021a90 <log>
    80004960:	575c                	lw	a5,44(a4)
    80004962:	2785                	addiw	a5,a5,1
    80004964:	d75c                	sw	a5,44(a4)
    80004966:	a835                	j	800049a2 <log_write+0xca>
    panic("too big a transaction");
    80004968:	00004517          	auipc	a0,0x4
    8000496c:	e8050513          	addi	a0,a0,-384 # 800087e8 <syscalls+0x208>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	e8850513          	addi	a0,a0,-376 # 80008800 <syscalls+0x220>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	bbe080e7          	jalr	-1090(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004988:	00878713          	addi	a4,a5,8
    8000498c:	00271693          	slli	a3,a4,0x2
    80004990:	0001d717          	auipc	a4,0x1d
    80004994:	10070713          	addi	a4,a4,256 # 80021a90 <log>
    80004998:	9736                	add	a4,a4,a3
    8000499a:	44d4                	lw	a3,12(s1)
    8000499c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000499e:	faf608e3          	beq	a2,a5,8000494e <log_write+0x76>
  }
  release(&log.lock);
    800049a2:	0001d517          	auipc	a0,0x1d
    800049a6:	0ee50513          	addi	a0,a0,238 # 80021a90 <log>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2ee080e7          	jalr	750(ra) # 80000c98 <release>
}
    800049b2:	60e2                	ld	ra,24(sp)
    800049b4:	6442                	ld	s0,16(sp)
    800049b6:	64a2                	ld	s1,8(sp)
    800049b8:	6902                	ld	s2,0(sp)
    800049ba:	6105                	addi	sp,sp,32
    800049bc:	8082                	ret

00000000800049be <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049be:	1101                	addi	sp,sp,-32
    800049c0:	ec06                	sd	ra,24(sp)
    800049c2:	e822                	sd	s0,16(sp)
    800049c4:	e426                	sd	s1,8(sp)
    800049c6:	e04a                	sd	s2,0(sp)
    800049c8:	1000                	addi	s0,sp,32
    800049ca:	84aa                	mv	s1,a0
    800049cc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ce:	00004597          	auipc	a1,0x4
    800049d2:	e5258593          	addi	a1,a1,-430 # 80008820 <syscalls+0x240>
    800049d6:	0521                	addi	a0,a0,8
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	17c080e7          	jalr	380(ra) # 80000b54 <initlock>
  lk->name = name;
    800049e0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049e8:	0204a423          	sw	zero,40(s1)
}
    800049ec:	60e2                	ld	ra,24(sp)
    800049ee:	6442                	ld	s0,16(sp)
    800049f0:	64a2                	ld	s1,8(sp)
    800049f2:	6902                	ld	s2,0(sp)
    800049f4:	6105                	addi	sp,sp,32
    800049f6:	8082                	ret

00000000800049f8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049f8:	1101                	addi	sp,sp,-32
    800049fa:	ec06                	sd	ra,24(sp)
    800049fc:	e822                	sd	s0,16(sp)
    800049fe:	e426                	sd	s1,8(sp)
    80004a00:	e04a                	sd	s2,0(sp)
    80004a02:	1000                	addi	s0,sp,32
    80004a04:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a06:	00850913          	addi	s2,a0,8
    80004a0a:	854a                	mv	a0,s2
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1d8080e7          	jalr	472(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004a14:	409c                	lw	a5,0(s1)
    80004a16:	cb89                	beqz	a5,80004a28 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a18:	85ca                	mv	a1,s2
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	ffffe097          	auipc	ra,0xffffe
    80004a20:	bd8080e7          	jalr	-1064(ra) # 800025f4 <sleep>
  while (lk->locked) {
    80004a24:	409c                	lw	a5,0(s1)
    80004a26:	fbed                	bnez	a5,80004a18 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a28:	4785                	li	a5,1
    80004a2a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	186080e7          	jalr	390(ra) # 80001bb2 <myproc>
    80004a34:	591c                	lw	a5,48(a0)
    80004a36:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a38:	854a                	mv	a0,s2
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	25e080e7          	jalr	606(ra) # 80000c98 <release>
}
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	64a2                	ld	s1,8(sp)
    80004a48:	6902                	ld	s2,0(sp)
    80004a4a:	6105                	addi	sp,sp,32
    80004a4c:	8082                	ret

0000000080004a4e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a4e:	1101                	addi	sp,sp,-32
    80004a50:	ec06                	sd	ra,24(sp)
    80004a52:	e822                	sd	s0,16(sp)
    80004a54:	e426                	sd	s1,8(sp)
    80004a56:	e04a                	sd	s2,0(sp)
    80004a58:	1000                	addi	s0,sp,32
    80004a5a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a5c:	00850913          	addi	s2,a0,8
    80004a60:	854a                	mv	a0,s2
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	182080e7          	jalr	386(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004a6a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a6e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffe097          	auipc	ra,0xffffe
    80004a78:	d26080e7          	jalr	-730(ra) # 8000279a <wakeup>
  release(&lk->lk);
    80004a7c:	854a                	mv	a0,s2
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	21a080e7          	jalr	538(ra) # 80000c98 <release>
}
    80004a86:	60e2                	ld	ra,24(sp)
    80004a88:	6442                	ld	s0,16(sp)
    80004a8a:	64a2                	ld	s1,8(sp)
    80004a8c:	6902                	ld	s2,0(sp)
    80004a8e:	6105                	addi	sp,sp,32
    80004a90:	8082                	ret

0000000080004a92 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a92:	7179                	addi	sp,sp,-48
    80004a94:	f406                	sd	ra,40(sp)
    80004a96:	f022                	sd	s0,32(sp)
    80004a98:	ec26                	sd	s1,24(sp)
    80004a9a:	e84a                	sd	s2,16(sp)
    80004a9c:	e44e                	sd	s3,8(sp)
    80004a9e:	1800                	addi	s0,sp,48
    80004aa0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004aa2:	00850913          	addi	s2,a0,8
    80004aa6:	854a                	mv	a0,s2
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	13c080e7          	jalr	316(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ab0:	409c                	lw	a5,0(s1)
    80004ab2:	ef99                	bnez	a5,80004ad0 <holdingsleep+0x3e>
    80004ab4:	4481                	li	s1,0
  release(&lk->lk);
    80004ab6:	854a                	mv	a0,s2
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	1e0080e7          	jalr	480(ra) # 80000c98 <release>
  return r;
}
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	70a2                	ld	ra,40(sp)
    80004ac4:	7402                	ld	s0,32(sp)
    80004ac6:	64e2                	ld	s1,24(sp)
    80004ac8:	6942                	ld	s2,16(sp)
    80004aca:	69a2                	ld	s3,8(sp)
    80004acc:	6145                	addi	sp,sp,48
    80004ace:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ad0:	0284a983          	lw	s3,40(s1)
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	0de080e7          	jalr	222(ra) # 80001bb2 <myproc>
    80004adc:	5904                	lw	s1,48(a0)
    80004ade:	413484b3          	sub	s1,s1,s3
    80004ae2:	0014b493          	seqz	s1,s1
    80004ae6:	bfc1                	j	80004ab6 <holdingsleep+0x24>

0000000080004ae8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ae8:	1141                	addi	sp,sp,-16
    80004aea:	e406                	sd	ra,8(sp)
    80004aec:	e022                	sd	s0,0(sp)
    80004aee:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004af0:	00004597          	auipc	a1,0x4
    80004af4:	d4058593          	addi	a1,a1,-704 # 80008830 <syscalls+0x250>
    80004af8:	0001d517          	auipc	a0,0x1d
    80004afc:	0e050513          	addi	a0,a0,224 # 80021bd8 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	054080e7          	jalr	84(ra) # 80000b54 <initlock>
}
    80004b08:	60a2                	ld	ra,8(sp)
    80004b0a:	6402                	ld	s0,0(sp)
    80004b0c:	0141                	addi	sp,sp,16
    80004b0e:	8082                	ret

0000000080004b10 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b10:	1101                	addi	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b1a:	0001d517          	auipc	a0,0x1d
    80004b1e:	0be50513          	addi	a0,a0,190 # 80021bd8 <ftable>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	0c2080e7          	jalr	194(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b2a:	0001d497          	auipc	s1,0x1d
    80004b2e:	0c648493          	addi	s1,s1,198 # 80021bf0 <ftable+0x18>
    80004b32:	0001e717          	auipc	a4,0x1e
    80004b36:	05e70713          	addi	a4,a4,94 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004b3a:	40dc                	lw	a5,4(s1)
    80004b3c:	cf99                	beqz	a5,80004b5a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b3e:	02848493          	addi	s1,s1,40
    80004b42:	fee49ce3          	bne	s1,a4,80004b3a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b46:	0001d517          	auipc	a0,0x1d
    80004b4a:	09250513          	addi	a0,a0,146 # 80021bd8 <ftable>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
  return 0;
    80004b56:	4481                	li	s1,0
    80004b58:	a819                	j	80004b6e <filealloc+0x5e>
      f->ref = 1;
    80004b5a:	4785                	li	a5,1
    80004b5c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b5e:	0001d517          	auipc	a0,0x1d
    80004b62:	07a50513          	addi	a0,a0,122 # 80021bd8 <ftable>
    80004b66:	ffffc097          	auipc	ra,0xffffc
    80004b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
}
    80004b6e:	8526                	mv	a0,s1
    80004b70:	60e2                	ld	ra,24(sp)
    80004b72:	6442                	ld	s0,16(sp)
    80004b74:	64a2                	ld	s1,8(sp)
    80004b76:	6105                	addi	sp,sp,32
    80004b78:	8082                	ret

0000000080004b7a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b7a:	1101                	addi	sp,sp,-32
    80004b7c:	ec06                	sd	ra,24(sp)
    80004b7e:	e822                	sd	s0,16(sp)
    80004b80:	e426                	sd	s1,8(sp)
    80004b82:	1000                	addi	s0,sp,32
    80004b84:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b86:	0001d517          	auipc	a0,0x1d
    80004b8a:	05250513          	addi	a0,a0,82 # 80021bd8 <ftable>
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	056080e7          	jalr	86(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004b96:	40dc                	lw	a5,4(s1)
    80004b98:	02f05263          	blez	a5,80004bbc <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b9c:	2785                	addiw	a5,a5,1
    80004b9e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ba0:	0001d517          	auipc	a0,0x1d
    80004ba4:	03850513          	addi	a0,a0,56 # 80021bd8 <ftable>
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	0f0080e7          	jalr	240(ra) # 80000c98 <release>
  return f;
}
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	60e2                	ld	ra,24(sp)
    80004bb4:	6442                	ld	s0,16(sp)
    80004bb6:	64a2                	ld	s1,8(sp)
    80004bb8:	6105                	addi	sp,sp,32
    80004bba:	8082                	ret
    panic("filedup");
    80004bbc:	00004517          	auipc	a0,0x4
    80004bc0:	c7c50513          	addi	a0,a0,-900 # 80008838 <syscalls+0x258>
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	97a080e7          	jalr	-1670(ra) # 8000053e <panic>

0000000080004bcc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004bcc:	7139                	addi	sp,sp,-64
    80004bce:	fc06                	sd	ra,56(sp)
    80004bd0:	f822                	sd	s0,48(sp)
    80004bd2:	f426                	sd	s1,40(sp)
    80004bd4:	f04a                	sd	s2,32(sp)
    80004bd6:	ec4e                	sd	s3,24(sp)
    80004bd8:	e852                	sd	s4,16(sp)
    80004bda:	e456                	sd	s5,8(sp)
    80004bdc:	0080                	addi	s0,sp,64
    80004bde:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004be0:	0001d517          	auipc	a0,0x1d
    80004be4:	ff850513          	addi	a0,a0,-8 # 80021bd8 <ftable>
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	ffc080e7          	jalr	-4(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004bf0:	40dc                	lw	a5,4(s1)
    80004bf2:	06f05163          	blez	a5,80004c54 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bf6:	37fd                	addiw	a5,a5,-1
    80004bf8:	0007871b          	sext.w	a4,a5
    80004bfc:	c0dc                	sw	a5,4(s1)
    80004bfe:	06e04363          	bgtz	a4,80004c64 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c02:	0004a903          	lw	s2,0(s1)
    80004c06:	0094ca83          	lbu	s5,9(s1)
    80004c0a:	0104ba03          	ld	s4,16(s1)
    80004c0e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c12:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c16:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c1a:	0001d517          	auipc	a0,0x1d
    80004c1e:	fbe50513          	addi	a0,a0,-66 # 80021bd8 <ftable>
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	076080e7          	jalr	118(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004c2a:	4785                	li	a5,1
    80004c2c:	04f90d63          	beq	s2,a5,80004c86 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c30:	3979                	addiw	s2,s2,-2
    80004c32:	4785                	li	a5,1
    80004c34:	0527e063          	bltu	a5,s2,80004c74 <fileclose+0xa8>
    begin_op();
    80004c38:	00000097          	auipc	ra,0x0
    80004c3c:	ac8080e7          	jalr	-1336(ra) # 80004700 <begin_op>
    iput(ff.ip);
    80004c40:	854e                	mv	a0,s3
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	2a6080e7          	jalr	678(ra) # 80003ee8 <iput>
    end_op();
    80004c4a:	00000097          	auipc	ra,0x0
    80004c4e:	b36080e7          	jalr	-1226(ra) # 80004780 <end_op>
    80004c52:	a00d                	j	80004c74 <fileclose+0xa8>
    panic("fileclose");
    80004c54:	00004517          	auipc	a0,0x4
    80004c58:	bec50513          	addi	a0,a0,-1044 # 80008840 <syscalls+0x260>
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	8e2080e7          	jalr	-1822(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004c64:	0001d517          	auipc	a0,0x1d
    80004c68:	f7450513          	addi	a0,a0,-140 # 80021bd8 <ftable>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	02c080e7          	jalr	44(ra) # 80000c98 <release>
  }
}
    80004c74:	70e2                	ld	ra,56(sp)
    80004c76:	7442                	ld	s0,48(sp)
    80004c78:	74a2                	ld	s1,40(sp)
    80004c7a:	7902                	ld	s2,32(sp)
    80004c7c:	69e2                	ld	s3,24(sp)
    80004c7e:	6a42                	ld	s4,16(sp)
    80004c80:	6aa2                	ld	s5,8(sp)
    80004c82:	6121                	addi	sp,sp,64
    80004c84:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c86:	85d6                	mv	a1,s5
    80004c88:	8552                	mv	a0,s4
    80004c8a:	00000097          	auipc	ra,0x0
    80004c8e:	34c080e7          	jalr	844(ra) # 80004fd6 <pipeclose>
    80004c92:	b7cd                	j	80004c74 <fileclose+0xa8>

0000000080004c94 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c94:	715d                	addi	sp,sp,-80
    80004c96:	e486                	sd	ra,72(sp)
    80004c98:	e0a2                	sd	s0,64(sp)
    80004c9a:	fc26                	sd	s1,56(sp)
    80004c9c:	f84a                	sd	s2,48(sp)
    80004c9e:	f44e                	sd	s3,40(sp)
    80004ca0:	0880                	addi	s0,sp,80
    80004ca2:	84aa                	mv	s1,a0
    80004ca4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	f0c080e7          	jalr	-244(ra) # 80001bb2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cae:	409c                	lw	a5,0(s1)
    80004cb0:	37f9                	addiw	a5,a5,-2
    80004cb2:	4705                	li	a4,1
    80004cb4:	04f76763          	bltu	a4,a5,80004d02 <filestat+0x6e>
    80004cb8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cba:	6c88                	ld	a0,24(s1)
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	072080e7          	jalr	114(ra) # 80003d2e <ilock>
    stati(f->ip, &st);
    80004cc4:	fb840593          	addi	a1,s0,-72
    80004cc8:	6c88                	ld	a0,24(s1)
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	2ee080e7          	jalr	750(ra) # 80003fb8 <stati>
    iunlock(f->ip);
    80004cd2:	6c88                	ld	a0,24(s1)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	11c080e7          	jalr	284(ra) # 80003df0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cdc:	46e1                	li	a3,24
    80004cde:	fb840613          	addi	a2,s0,-72
    80004ce2:	85ce                	mv	a1,s3
    80004ce4:	07093503          	ld	a0,112(s2)
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	992080e7          	jalr	-1646(ra) # 8000167a <copyout>
    80004cf0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cf4:	60a6                	ld	ra,72(sp)
    80004cf6:	6406                	ld	s0,64(sp)
    80004cf8:	74e2                	ld	s1,56(sp)
    80004cfa:	7942                	ld	s2,48(sp)
    80004cfc:	79a2                	ld	s3,40(sp)
    80004cfe:	6161                	addi	sp,sp,80
    80004d00:	8082                	ret
  return -1;
    80004d02:	557d                	li	a0,-1
    80004d04:	bfc5                	j	80004cf4 <filestat+0x60>

0000000080004d06 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d06:	7179                	addi	sp,sp,-48
    80004d08:	f406                	sd	ra,40(sp)
    80004d0a:	f022                	sd	s0,32(sp)
    80004d0c:	ec26                	sd	s1,24(sp)
    80004d0e:	e84a                	sd	s2,16(sp)
    80004d10:	e44e                	sd	s3,8(sp)
    80004d12:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d14:	00854783          	lbu	a5,8(a0)
    80004d18:	c3d5                	beqz	a5,80004dbc <fileread+0xb6>
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	89ae                	mv	s3,a1
    80004d1e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d20:	411c                	lw	a5,0(a0)
    80004d22:	4705                	li	a4,1
    80004d24:	04e78963          	beq	a5,a4,80004d76 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d28:	470d                	li	a4,3
    80004d2a:	04e78d63          	beq	a5,a4,80004d84 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d2e:	4709                	li	a4,2
    80004d30:	06e79e63          	bne	a5,a4,80004dac <fileread+0xa6>
    ilock(f->ip);
    80004d34:	6d08                	ld	a0,24(a0)
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	ff8080e7          	jalr	-8(ra) # 80003d2e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d3e:	874a                	mv	a4,s2
    80004d40:	5094                	lw	a3,32(s1)
    80004d42:	864e                	mv	a2,s3
    80004d44:	4585                	li	a1,1
    80004d46:	6c88                	ld	a0,24(s1)
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	29a080e7          	jalr	666(ra) # 80003fe2 <readi>
    80004d50:	892a                	mv	s2,a0
    80004d52:	00a05563          	blez	a0,80004d5c <fileread+0x56>
      f->off += r;
    80004d56:	509c                	lw	a5,32(s1)
    80004d58:	9fa9                	addw	a5,a5,a0
    80004d5a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d5c:	6c88                	ld	a0,24(s1)
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	092080e7          	jalr	146(ra) # 80003df0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d66:	854a                	mv	a0,s2
    80004d68:	70a2                	ld	ra,40(sp)
    80004d6a:	7402                	ld	s0,32(sp)
    80004d6c:	64e2                	ld	s1,24(sp)
    80004d6e:	6942                	ld	s2,16(sp)
    80004d70:	69a2                	ld	s3,8(sp)
    80004d72:	6145                	addi	sp,sp,48
    80004d74:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d76:	6908                	ld	a0,16(a0)
    80004d78:	00000097          	auipc	ra,0x0
    80004d7c:	3c8080e7          	jalr	968(ra) # 80005140 <piperead>
    80004d80:	892a                	mv	s2,a0
    80004d82:	b7d5                	j	80004d66 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d84:	02451783          	lh	a5,36(a0)
    80004d88:	03079693          	slli	a3,a5,0x30
    80004d8c:	92c1                	srli	a3,a3,0x30
    80004d8e:	4725                	li	a4,9
    80004d90:	02d76863          	bltu	a4,a3,80004dc0 <fileread+0xba>
    80004d94:	0792                	slli	a5,a5,0x4
    80004d96:	0001d717          	auipc	a4,0x1d
    80004d9a:	da270713          	addi	a4,a4,-606 # 80021b38 <devsw>
    80004d9e:	97ba                	add	a5,a5,a4
    80004da0:	639c                	ld	a5,0(a5)
    80004da2:	c38d                	beqz	a5,80004dc4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004da4:	4505                	li	a0,1
    80004da6:	9782                	jalr	a5
    80004da8:	892a                	mv	s2,a0
    80004daa:	bf75                	j	80004d66 <fileread+0x60>
    panic("fileread");
    80004dac:	00004517          	auipc	a0,0x4
    80004db0:	aa450513          	addi	a0,a0,-1372 # 80008850 <syscalls+0x270>
    80004db4:	ffffb097          	auipc	ra,0xffffb
    80004db8:	78a080e7          	jalr	1930(ra) # 8000053e <panic>
    return -1;
    80004dbc:	597d                	li	s2,-1
    80004dbe:	b765                	j	80004d66 <fileread+0x60>
      return -1;
    80004dc0:	597d                	li	s2,-1
    80004dc2:	b755                	j	80004d66 <fileread+0x60>
    80004dc4:	597d                	li	s2,-1
    80004dc6:	b745                	j	80004d66 <fileread+0x60>

0000000080004dc8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004dc8:	715d                	addi	sp,sp,-80
    80004dca:	e486                	sd	ra,72(sp)
    80004dcc:	e0a2                	sd	s0,64(sp)
    80004dce:	fc26                	sd	s1,56(sp)
    80004dd0:	f84a                	sd	s2,48(sp)
    80004dd2:	f44e                	sd	s3,40(sp)
    80004dd4:	f052                	sd	s4,32(sp)
    80004dd6:	ec56                	sd	s5,24(sp)
    80004dd8:	e85a                	sd	s6,16(sp)
    80004dda:	e45e                	sd	s7,8(sp)
    80004ddc:	e062                	sd	s8,0(sp)
    80004dde:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004de0:	00954783          	lbu	a5,9(a0)
    80004de4:	10078663          	beqz	a5,80004ef0 <filewrite+0x128>
    80004de8:	892a                	mv	s2,a0
    80004dea:	8aae                	mv	s5,a1
    80004dec:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dee:	411c                	lw	a5,0(a0)
    80004df0:	4705                	li	a4,1
    80004df2:	02e78263          	beq	a5,a4,80004e16 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004df6:	470d                	li	a4,3
    80004df8:	02e78663          	beq	a5,a4,80004e24 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dfc:	4709                	li	a4,2
    80004dfe:	0ee79163          	bne	a5,a4,80004ee0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e02:	0ac05d63          	blez	a2,80004ebc <filewrite+0xf4>
    int i = 0;
    80004e06:	4981                	li	s3,0
    80004e08:	6b05                	lui	s6,0x1
    80004e0a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e0e:	6b85                	lui	s7,0x1
    80004e10:	c00b8b9b          	addiw	s7,s7,-1024
    80004e14:	a861                	j	80004eac <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e16:	6908                	ld	a0,16(a0)
    80004e18:	00000097          	auipc	ra,0x0
    80004e1c:	22e080e7          	jalr	558(ra) # 80005046 <pipewrite>
    80004e20:	8a2a                	mv	s4,a0
    80004e22:	a045                	j	80004ec2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e24:	02451783          	lh	a5,36(a0)
    80004e28:	03079693          	slli	a3,a5,0x30
    80004e2c:	92c1                	srli	a3,a3,0x30
    80004e2e:	4725                	li	a4,9
    80004e30:	0cd76263          	bltu	a4,a3,80004ef4 <filewrite+0x12c>
    80004e34:	0792                	slli	a5,a5,0x4
    80004e36:	0001d717          	auipc	a4,0x1d
    80004e3a:	d0270713          	addi	a4,a4,-766 # 80021b38 <devsw>
    80004e3e:	97ba                	add	a5,a5,a4
    80004e40:	679c                	ld	a5,8(a5)
    80004e42:	cbdd                	beqz	a5,80004ef8 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e44:	4505                	li	a0,1
    80004e46:	9782                	jalr	a5
    80004e48:	8a2a                	mv	s4,a0
    80004e4a:	a8a5                	j	80004ec2 <filewrite+0xfa>
    80004e4c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e50:	00000097          	auipc	ra,0x0
    80004e54:	8b0080e7          	jalr	-1872(ra) # 80004700 <begin_op>
      ilock(f->ip);
    80004e58:	01893503          	ld	a0,24(s2)
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	ed2080e7          	jalr	-302(ra) # 80003d2e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e64:	8762                	mv	a4,s8
    80004e66:	02092683          	lw	a3,32(s2)
    80004e6a:	01598633          	add	a2,s3,s5
    80004e6e:	4585                	li	a1,1
    80004e70:	01893503          	ld	a0,24(s2)
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	266080e7          	jalr	614(ra) # 800040da <writei>
    80004e7c:	84aa                	mv	s1,a0
    80004e7e:	00a05763          	blez	a0,80004e8c <filewrite+0xc4>
        f->off += r;
    80004e82:	02092783          	lw	a5,32(s2)
    80004e86:	9fa9                	addw	a5,a5,a0
    80004e88:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e8c:	01893503          	ld	a0,24(s2)
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	f60080e7          	jalr	-160(ra) # 80003df0 <iunlock>
      end_op();
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	8e8080e7          	jalr	-1816(ra) # 80004780 <end_op>

      if(r != n1){
    80004ea0:	009c1f63          	bne	s8,s1,80004ebe <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ea4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ea8:	0149db63          	bge	s3,s4,80004ebe <filewrite+0xf6>
      int n1 = n - i;
    80004eac:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004eb0:	84be                	mv	s1,a5
    80004eb2:	2781                	sext.w	a5,a5
    80004eb4:	f8fb5ce3          	bge	s6,a5,80004e4c <filewrite+0x84>
    80004eb8:	84de                	mv	s1,s7
    80004eba:	bf49                	j	80004e4c <filewrite+0x84>
    int i = 0;
    80004ebc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ebe:	013a1f63          	bne	s4,s3,80004edc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ec2:	8552                	mv	a0,s4
    80004ec4:	60a6                	ld	ra,72(sp)
    80004ec6:	6406                	ld	s0,64(sp)
    80004ec8:	74e2                	ld	s1,56(sp)
    80004eca:	7942                	ld	s2,48(sp)
    80004ecc:	79a2                	ld	s3,40(sp)
    80004ece:	7a02                	ld	s4,32(sp)
    80004ed0:	6ae2                	ld	s5,24(sp)
    80004ed2:	6b42                	ld	s6,16(sp)
    80004ed4:	6ba2                	ld	s7,8(sp)
    80004ed6:	6c02                	ld	s8,0(sp)
    80004ed8:	6161                	addi	sp,sp,80
    80004eda:	8082                	ret
    ret = (i == n ? n : -1);
    80004edc:	5a7d                	li	s4,-1
    80004ede:	b7d5                	j	80004ec2 <filewrite+0xfa>
    panic("filewrite");
    80004ee0:	00004517          	auipc	a0,0x4
    80004ee4:	98050513          	addi	a0,a0,-1664 # 80008860 <syscalls+0x280>
    80004ee8:	ffffb097          	auipc	ra,0xffffb
    80004eec:	656080e7          	jalr	1622(ra) # 8000053e <panic>
    return -1;
    80004ef0:	5a7d                	li	s4,-1
    80004ef2:	bfc1                	j	80004ec2 <filewrite+0xfa>
      return -1;
    80004ef4:	5a7d                	li	s4,-1
    80004ef6:	b7f1                	j	80004ec2 <filewrite+0xfa>
    80004ef8:	5a7d                	li	s4,-1
    80004efa:	b7e1                	j	80004ec2 <filewrite+0xfa>

0000000080004efc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004efc:	7179                	addi	sp,sp,-48
    80004efe:	f406                	sd	ra,40(sp)
    80004f00:	f022                	sd	s0,32(sp)
    80004f02:	ec26                	sd	s1,24(sp)
    80004f04:	e84a                	sd	s2,16(sp)
    80004f06:	e44e                	sd	s3,8(sp)
    80004f08:	e052                	sd	s4,0(sp)
    80004f0a:	1800                	addi	s0,sp,48
    80004f0c:	84aa                	mv	s1,a0
    80004f0e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f10:	0005b023          	sd	zero,0(a1)
    80004f14:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f18:	00000097          	auipc	ra,0x0
    80004f1c:	bf8080e7          	jalr	-1032(ra) # 80004b10 <filealloc>
    80004f20:	e088                	sd	a0,0(s1)
    80004f22:	c551                	beqz	a0,80004fae <pipealloc+0xb2>
    80004f24:	00000097          	auipc	ra,0x0
    80004f28:	bec080e7          	jalr	-1044(ra) # 80004b10 <filealloc>
    80004f2c:	00aa3023          	sd	a0,0(s4)
    80004f30:	c92d                	beqz	a0,80004fa2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	bc2080e7          	jalr	-1086(ra) # 80000af4 <kalloc>
    80004f3a:	892a                	mv	s2,a0
    80004f3c:	c125                	beqz	a0,80004f9c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f3e:	4985                	li	s3,1
    80004f40:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f44:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f48:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f4c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f50:	00004597          	auipc	a1,0x4
    80004f54:	92058593          	addi	a1,a1,-1760 # 80008870 <syscalls+0x290>
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	bfc080e7          	jalr	-1028(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004f60:	609c                	ld	a5,0(s1)
    80004f62:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f66:	609c                	ld	a5,0(s1)
    80004f68:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f6c:	609c                	ld	a5,0(s1)
    80004f6e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f72:	609c                	ld	a5,0(s1)
    80004f74:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f78:	000a3783          	ld	a5,0(s4)
    80004f7c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f80:	000a3783          	ld	a5,0(s4)
    80004f84:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f88:	000a3783          	ld	a5,0(s4)
    80004f8c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f90:	000a3783          	ld	a5,0(s4)
    80004f94:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f98:	4501                	li	a0,0
    80004f9a:	a025                	j	80004fc2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f9c:	6088                	ld	a0,0(s1)
    80004f9e:	e501                	bnez	a0,80004fa6 <pipealloc+0xaa>
    80004fa0:	a039                	j	80004fae <pipealloc+0xb2>
    80004fa2:	6088                	ld	a0,0(s1)
    80004fa4:	c51d                	beqz	a0,80004fd2 <pipealloc+0xd6>
    fileclose(*f0);
    80004fa6:	00000097          	auipc	ra,0x0
    80004faa:	c26080e7          	jalr	-986(ra) # 80004bcc <fileclose>
  if(*f1)
    80004fae:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fb2:	557d                	li	a0,-1
  if(*f1)
    80004fb4:	c799                	beqz	a5,80004fc2 <pipealloc+0xc6>
    fileclose(*f1);
    80004fb6:	853e                	mv	a0,a5
    80004fb8:	00000097          	auipc	ra,0x0
    80004fbc:	c14080e7          	jalr	-1004(ra) # 80004bcc <fileclose>
  return -1;
    80004fc0:	557d                	li	a0,-1
}
    80004fc2:	70a2                	ld	ra,40(sp)
    80004fc4:	7402                	ld	s0,32(sp)
    80004fc6:	64e2                	ld	s1,24(sp)
    80004fc8:	6942                	ld	s2,16(sp)
    80004fca:	69a2                	ld	s3,8(sp)
    80004fcc:	6a02                	ld	s4,0(sp)
    80004fce:	6145                	addi	sp,sp,48
    80004fd0:	8082                	ret
  return -1;
    80004fd2:	557d                	li	a0,-1
    80004fd4:	b7fd                	j	80004fc2 <pipealloc+0xc6>

0000000080004fd6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fd6:	1101                	addi	sp,sp,-32
    80004fd8:	ec06                	sd	ra,24(sp)
    80004fda:	e822                	sd	s0,16(sp)
    80004fdc:	e426                	sd	s1,8(sp)
    80004fde:	e04a                	sd	s2,0(sp)
    80004fe0:	1000                	addi	s0,sp,32
    80004fe2:	84aa                	mv	s1,a0
    80004fe4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	bfe080e7          	jalr	-1026(ra) # 80000be4 <acquire>
  if(writable){
    80004fee:	02090d63          	beqz	s2,80005028 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ff2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ff6:	21848513          	addi	a0,s1,536
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	7a0080e7          	jalr	1952(ra) # 8000279a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005002:	2204b783          	ld	a5,544(s1)
    80005006:	eb95                	bnez	a5,8000503a <pipeclose+0x64>
    release(&pi->lock);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	c8e080e7          	jalr	-882(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005012:	8526                	mv	a0,s1
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	9e4080e7          	jalr	-1564(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000501c:	60e2                	ld	ra,24(sp)
    8000501e:	6442                	ld	s0,16(sp)
    80005020:	64a2                	ld	s1,8(sp)
    80005022:	6902                	ld	s2,0(sp)
    80005024:	6105                	addi	sp,sp,32
    80005026:	8082                	ret
    pi->readopen = 0;
    80005028:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000502c:	21c48513          	addi	a0,s1,540
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	76a080e7          	jalr	1898(ra) # 8000279a <wakeup>
    80005038:	b7e9                	j	80005002 <pipeclose+0x2c>
    release(&pi->lock);
    8000503a:	8526                	mv	a0,s1
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	c5c080e7          	jalr	-932(ra) # 80000c98 <release>
}
    80005044:	bfe1                	j	8000501c <pipeclose+0x46>

0000000080005046 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005046:	7159                	addi	sp,sp,-112
    80005048:	f486                	sd	ra,104(sp)
    8000504a:	f0a2                	sd	s0,96(sp)
    8000504c:	eca6                	sd	s1,88(sp)
    8000504e:	e8ca                	sd	s2,80(sp)
    80005050:	e4ce                	sd	s3,72(sp)
    80005052:	e0d2                	sd	s4,64(sp)
    80005054:	fc56                	sd	s5,56(sp)
    80005056:	f85a                	sd	s6,48(sp)
    80005058:	f45e                	sd	s7,40(sp)
    8000505a:	f062                	sd	s8,32(sp)
    8000505c:	ec66                	sd	s9,24(sp)
    8000505e:	1880                	addi	s0,sp,112
    80005060:	84aa                	mv	s1,a0
    80005062:	8aae                	mv	s5,a1
    80005064:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	b4c080e7          	jalr	-1204(ra) # 80001bb2 <myproc>
    8000506e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	b72080e7          	jalr	-1166(ra) # 80000be4 <acquire>
  while(i < n){
    8000507a:	0d405163          	blez	s4,8000513c <pipewrite+0xf6>
    8000507e:	8ba6                	mv	s7,s1
  int i = 0;
    80005080:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005082:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005084:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005088:	21c48c13          	addi	s8,s1,540
    8000508c:	a08d                	j	800050ee <pipewrite+0xa8>
      release(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	c08080e7          	jalr	-1016(ra) # 80000c98 <release>
      return -1;
    80005098:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000509a:	854a                	mv	a0,s2
    8000509c:	70a6                	ld	ra,104(sp)
    8000509e:	7406                	ld	s0,96(sp)
    800050a0:	64e6                	ld	s1,88(sp)
    800050a2:	6946                	ld	s2,80(sp)
    800050a4:	69a6                	ld	s3,72(sp)
    800050a6:	6a06                	ld	s4,64(sp)
    800050a8:	7ae2                	ld	s5,56(sp)
    800050aa:	7b42                	ld	s6,48(sp)
    800050ac:	7ba2                	ld	s7,40(sp)
    800050ae:	7c02                	ld	s8,32(sp)
    800050b0:	6ce2                	ld	s9,24(sp)
    800050b2:	6165                	addi	sp,sp,112
    800050b4:	8082                	ret
      wakeup(&pi->nread);
    800050b6:	8566                	mv	a0,s9
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	6e2080e7          	jalr	1762(ra) # 8000279a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050c0:	85de                	mv	a1,s7
    800050c2:	8562                	mv	a0,s8
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	530080e7          	jalr	1328(ra) # 800025f4 <sleep>
    800050cc:	a839                	j	800050ea <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ce:	21c4a783          	lw	a5,540(s1)
    800050d2:	0017871b          	addiw	a4,a5,1
    800050d6:	20e4ae23          	sw	a4,540(s1)
    800050da:	1ff7f793          	andi	a5,a5,511
    800050de:	97a6                	add	a5,a5,s1
    800050e0:	f9f44703          	lbu	a4,-97(s0)
    800050e4:	00e78c23          	sb	a4,24(a5)
      i++;
    800050e8:	2905                	addiw	s2,s2,1
  while(i < n){
    800050ea:	03495d63          	bge	s2,s4,80005124 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800050ee:	2204a783          	lw	a5,544(s1)
    800050f2:	dfd1                	beqz	a5,8000508e <pipewrite+0x48>
    800050f4:	0289a783          	lw	a5,40(s3)
    800050f8:	fbd9                	bnez	a5,8000508e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050fa:	2184a783          	lw	a5,536(s1)
    800050fe:	21c4a703          	lw	a4,540(s1)
    80005102:	2007879b          	addiw	a5,a5,512
    80005106:	faf708e3          	beq	a4,a5,800050b6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000510a:	4685                	li	a3,1
    8000510c:	01590633          	add	a2,s2,s5
    80005110:	f9f40593          	addi	a1,s0,-97
    80005114:	0709b503          	ld	a0,112(s3)
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	5ee080e7          	jalr	1518(ra) # 80001706 <copyin>
    80005120:	fb6517e3          	bne	a0,s6,800050ce <pipewrite+0x88>
  wakeup(&pi->nread);
    80005124:	21848513          	addi	a0,s1,536
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	672080e7          	jalr	1650(ra) # 8000279a <wakeup>
  release(&pi->lock);
    80005130:	8526                	mv	a0,s1
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
  return i;
    8000513a:	b785                	j	8000509a <pipewrite+0x54>
  int i = 0;
    8000513c:	4901                	li	s2,0
    8000513e:	b7dd                	j	80005124 <pipewrite+0xde>

0000000080005140 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005140:	715d                	addi	sp,sp,-80
    80005142:	e486                	sd	ra,72(sp)
    80005144:	e0a2                	sd	s0,64(sp)
    80005146:	fc26                	sd	s1,56(sp)
    80005148:	f84a                	sd	s2,48(sp)
    8000514a:	f44e                	sd	s3,40(sp)
    8000514c:	f052                	sd	s4,32(sp)
    8000514e:	ec56                	sd	s5,24(sp)
    80005150:	e85a                	sd	s6,16(sp)
    80005152:	0880                	addi	s0,sp,80
    80005154:	84aa                	mv	s1,a0
    80005156:	892e                	mv	s2,a1
    80005158:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	a58080e7          	jalr	-1448(ra) # 80001bb2 <myproc>
    80005162:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005164:	8b26                	mv	s6,s1
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005170:	2184a703          	lw	a4,536(s1)
    80005174:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005178:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517c:	02f71463          	bne	a4,a5,800051a4 <piperead+0x64>
    80005180:	2244a783          	lw	a5,548(s1)
    80005184:	c385                	beqz	a5,800051a4 <piperead+0x64>
    if(pr->killed){
    80005186:	028a2783          	lw	a5,40(s4)
    8000518a:	ebc1                	bnez	a5,8000521a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000518c:	85da                	mv	a1,s6
    8000518e:	854e                	mv	a0,s3
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	464080e7          	jalr	1124(ra) # 800025f4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005198:	2184a703          	lw	a4,536(s1)
    8000519c:	21c4a783          	lw	a5,540(s1)
    800051a0:	fef700e3          	beq	a4,a5,80005180 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a4:	09505263          	blez	s5,80005228 <piperead+0xe8>
    800051a8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051aa:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051ac:	2184a783          	lw	a5,536(s1)
    800051b0:	21c4a703          	lw	a4,540(s1)
    800051b4:	02f70d63          	beq	a4,a5,800051ee <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051b8:	0017871b          	addiw	a4,a5,1
    800051bc:	20e4ac23          	sw	a4,536(s1)
    800051c0:	1ff7f793          	andi	a5,a5,511
    800051c4:	97a6                	add	a5,a5,s1
    800051c6:	0187c783          	lbu	a5,24(a5)
    800051ca:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051ce:	4685                	li	a3,1
    800051d0:	fbf40613          	addi	a2,s0,-65
    800051d4:	85ca                	mv	a1,s2
    800051d6:	070a3503          	ld	a0,112(s4)
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	4a0080e7          	jalr	1184(ra) # 8000167a <copyout>
    800051e2:	01650663          	beq	a0,s6,800051ee <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051e6:	2985                	addiw	s3,s3,1
    800051e8:	0905                	addi	s2,s2,1
    800051ea:	fd3a91e3          	bne	s5,s3,800051ac <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051ee:	21c48513          	addi	a0,s1,540
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	5a8080e7          	jalr	1448(ra) # 8000279a <wakeup>
  release(&pi->lock);
    800051fa:	8526                	mv	a0,s1
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	a9c080e7          	jalr	-1380(ra) # 80000c98 <release>
  return i;
}
    80005204:	854e                	mv	a0,s3
    80005206:	60a6                	ld	ra,72(sp)
    80005208:	6406                	ld	s0,64(sp)
    8000520a:	74e2                	ld	s1,56(sp)
    8000520c:	7942                	ld	s2,48(sp)
    8000520e:	79a2                	ld	s3,40(sp)
    80005210:	7a02                	ld	s4,32(sp)
    80005212:	6ae2                	ld	s5,24(sp)
    80005214:	6b42                	ld	s6,16(sp)
    80005216:	6161                	addi	sp,sp,80
    80005218:	8082                	ret
      release(&pi->lock);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
      return -1;
    80005224:	59fd                	li	s3,-1
    80005226:	bff9                	j	80005204 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005228:	4981                	li	s3,0
    8000522a:	b7d1                	j	800051ee <piperead+0xae>

000000008000522c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000522c:	df010113          	addi	sp,sp,-528
    80005230:	20113423          	sd	ra,520(sp)
    80005234:	20813023          	sd	s0,512(sp)
    80005238:	ffa6                	sd	s1,504(sp)
    8000523a:	fbca                	sd	s2,496(sp)
    8000523c:	f7ce                	sd	s3,488(sp)
    8000523e:	f3d2                	sd	s4,480(sp)
    80005240:	efd6                	sd	s5,472(sp)
    80005242:	ebda                	sd	s6,464(sp)
    80005244:	e7de                	sd	s7,456(sp)
    80005246:	e3e2                	sd	s8,448(sp)
    80005248:	ff66                	sd	s9,440(sp)
    8000524a:	fb6a                	sd	s10,432(sp)
    8000524c:	f76e                	sd	s11,424(sp)
    8000524e:	0c00                	addi	s0,sp,528
    80005250:	84aa                	mv	s1,a0
    80005252:	dea43c23          	sd	a0,-520(s0)
    80005256:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000525a:	ffffd097          	auipc	ra,0xffffd
    8000525e:	958080e7          	jalr	-1704(ra) # 80001bb2 <myproc>
    80005262:	892a                	mv	s2,a0

  begin_op();
    80005264:	fffff097          	auipc	ra,0xfffff
    80005268:	49c080e7          	jalr	1180(ra) # 80004700 <begin_op>

  if((ip = namei(path)) == 0){
    8000526c:	8526                	mv	a0,s1
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	276080e7          	jalr	630(ra) # 800044e4 <namei>
    80005276:	c92d                	beqz	a0,800052e8 <exec+0xbc>
    80005278:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	ab4080e7          	jalr	-1356(ra) # 80003d2e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005282:	04000713          	li	a4,64
    80005286:	4681                	li	a3,0
    80005288:	e5040613          	addi	a2,s0,-432
    8000528c:	4581                	li	a1,0
    8000528e:	8526                	mv	a0,s1
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	d52080e7          	jalr	-686(ra) # 80003fe2 <readi>
    80005298:	04000793          	li	a5,64
    8000529c:	00f51a63          	bne	a0,a5,800052b0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800052a0:	e5042703          	lw	a4,-432(s0)
    800052a4:	464c47b7          	lui	a5,0x464c4
    800052a8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052ac:	04f70463          	beq	a4,a5,800052f4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052b0:	8526                	mv	a0,s1
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	cde080e7          	jalr	-802(ra) # 80003f90 <iunlockput>
    end_op();
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	4c6080e7          	jalr	1222(ra) # 80004780 <end_op>
  }
  return -1;
    800052c2:	557d                	li	a0,-1
}
    800052c4:	20813083          	ld	ra,520(sp)
    800052c8:	20013403          	ld	s0,512(sp)
    800052cc:	74fe                	ld	s1,504(sp)
    800052ce:	795e                	ld	s2,496(sp)
    800052d0:	79be                	ld	s3,488(sp)
    800052d2:	7a1e                	ld	s4,480(sp)
    800052d4:	6afe                	ld	s5,472(sp)
    800052d6:	6b5e                	ld	s6,464(sp)
    800052d8:	6bbe                	ld	s7,456(sp)
    800052da:	6c1e                	ld	s8,448(sp)
    800052dc:	7cfa                	ld	s9,440(sp)
    800052de:	7d5a                	ld	s10,432(sp)
    800052e0:	7dba                	ld	s11,424(sp)
    800052e2:	21010113          	addi	sp,sp,528
    800052e6:	8082                	ret
    end_op();
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	498080e7          	jalr	1176(ra) # 80004780 <end_op>
    return -1;
    800052f0:	557d                	li	a0,-1
    800052f2:	bfc9                	j	800052c4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052f4:	854a                	mv	a0,s2
    800052f6:	ffffd097          	auipc	ra,0xffffd
    800052fa:	980080e7          	jalr	-1664(ra) # 80001c76 <proc_pagetable>
    800052fe:	8baa                	mv	s7,a0
    80005300:	d945                	beqz	a0,800052b0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005302:	e7042983          	lw	s3,-400(s0)
    80005306:	e8845783          	lhu	a5,-376(s0)
    8000530a:	c7ad                	beqz	a5,80005374 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000530c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000530e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005310:	6c85                	lui	s9,0x1
    80005312:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005316:	def43823          	sd	a5,-528(s0)
    8000531a:	a42d                	j	80005544 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000531c:	00003517          	auipc	a0,0x3
    80005320:	55c50513          	addi	a0,a0,1372 # 80008878 <syscalls+0x298>
    80005324:	ffffb097          	auipc	ra,0xffffb
    80005328:	21a080e7          	jalr	538(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000532c:	8756                	mv	a4,s5
    8000532e:	012d86bb          	addw	a3,s11,s2
    80005332:	4581                	li	a1,0
    80005334:	8526                	mv	a0,s1
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	cac080e7          	jalr	-852(ra) # 80003fe2 <readi>
    8000533e:	2501                	sext.w	a0,a0
    80005340:	1aaa9963          	bne	s5,a0,800054f2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005344:	6785                	lui	a5,0x1
    80005346:	0127893b          	addw	s2,a5,s2
    8000534a:	77fd                	lui	a5,0xfffff
    8000534c:	01478a3b          	addw	s4,a5,s4
    80005350:	1f897163          	bgeu	s2,s8,80005532 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005354:	02091593          	slli	a1,s2,0x20
    80005358:	9181                	srli	a1,a1,0x20
    8000535a:	95ea                	add	a1,a1,s10
    8000535c:	855e                	mv	a0,s7
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	d18080e7          	jalr	-744(ra) # 80001076 <walkaddr>
    80005366:	862a                	mv	a2,a0
    if(pa == 0)
    80005368:	d955                	beqz	a0,8000531c <exec+0xf0>
      n = PGSIZE;
    8000536a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000536c:	fd9a70e3          	bgeu	s4,s9,8000532c <exec+0x100>
      n = sz - i;
    80005370:	8ad2                	mv	s5,s4
    80005372:	bf6d                	j	8000532c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005374:	4901                	li	s2,0
  iunlockput(ip);
    80005376:	8526                	mv	a0,s1
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	c18080e7          	jalr	-1000(ra) # 80003f90 <iunlockput>
  end_op();
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	400080e7          	jalr	1024(ra) # 80004780 <end_op>
  p = myproc();
    80005388:	ffffd097          	auipc	ra,0xffffd
    8000538c:	82a080e7          	jalr	-2006(ra) # 80001bb2 <myproc>
    80005390:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005392:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005396:	6785                	lui	a5,0x1
    80005398:	17fd                	addi	a5,a5,-1
    8000539a:	993e                	add	s2,s2,a5
    8000539c:	757d                	lui	a0,0xfffff
    8000539e:	00a977b3          	and	a5,s2,a0
    800053a2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053a6:	6609                	lui	a2,0x2
    800053a8:	963e                	add	a2,a2,a5
    800053aa:	85be                	mv	a1,a5
    800053ac:	855e                	mv	a0,s7
    800053ae:	ffffc097          	auipc	ra,0xffffc
    800053b2:	07c080e7          	jalr	124(ra) # 8000142a <uvmalloc>
    800053b6:	8b2a                	mv	s6,a0
  ip = 0;
    800053b8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053ba:	12050c63          	beqz	a0,800054f2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053be:	75f9                	lui	a1,0xffffe
    800053c0:	95aa                	add	a1,a1,a0
    800053c2:	855e                	mv	a0,s7
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	284080e7          	jalr	644(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    800053cc:	7c7d                	lui	s8,0xfffff
    800053ce:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053d0:	e0043783          	ld	a5,-512(s0)
    800053d4:	6388                	ld	a0,0(a5)
    800053d6:	c535                	beqz	a0,80005442 <exec+0x216>
    800053d8:	e9040993          	addi	s3,s0,-368
    800053dc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053e0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053e2:	ffffc097          	auipc	ra,0xffffc
    800053e6:	a82080e7          	jalr	-1406(ra) # 80000e64 <strlen>
    800053ea:	2505                	addiw	a0,a0,1
    800053ec:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053f0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053f4:	13896363          	bltu	s2,s8,8000551a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053f8:	e0043d83          	ld	s11,-512(s0)
    800053fc:	000dba03          	ld	s4,0(s11)
    80005400:	8552                	mv	a0,s4
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	a62080e7          	jalr	-1438(ra) # 80000e64 <strlen>
    8000540a:	0015069b          	addiw	a3,a0,1
    8000540e:	8652                	mv	a2,s4
    80005410:	85ca                	mv	a1,s2
    80005412:	855e                	mv	a0,s7
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	266080e7          	jalr	614(ra) # 8000167a <copyout>
    8000541c:	10054363          	bltz	a0,80005522 <exec+0x2f6>
    ustack[argc] = sp;
    80005420:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005424:	0485                	addi	s1,s1,1
    80005426:	008d8793          	addi	a5,s11,8
    8000542a:	e0f43023          	sd	a5,-512(s0)
    8000542e:	008db503          	ld	a0,8(s11)
    80005432:	c911                	beqz	a0,80005446 <exec+0x21a>
    if(argc >= MAXARG)
    80005434:	09a1                	addi	s3,s3,8
    80005436:	fb3c96e3          	bne	s9,s3,800053e2 <exec+0x1b6>
  sz = sz1;
    8000543a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000543e:	4481                	li	s1,0
    80005440:	a84d                	j	800054f2 <exec+0x2c6>
  sp = sz;
    80005442:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005444:	4481                	li	s1,0
  ustack[argc] = 0;
    80005446:	00349793          	slli	a5,s1,0x3
    8000544a:	f9040713          	addi	a4,s0,-112
    8000544e:	97ba                	add	a5,a5,a4
    80005450:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005454:	00148693          	addi	a3,s1,1
    80005458:	068e                	slli	a3,a3,0x3
    8000545a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000545e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005462:	01897663          	bgeu	s2,s8,8000546e <exec+0x242>
  sz = sz1;
    80005466:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000546a:	4481                	li	s1,0
    8000546c:	a059                	j	800054f2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000546e:	e9040613          	addi	a2,s0,-368
    80005472:	85ca                	mv	a1,s2
    80005474:	855e                	mv	a0,s7
    80005476:	ffffc097          	auipc	ra,0xffffc
    8000547a:	204080e7          	jalr	516(ra) # 8000167a <copyout>
    8000547e:	0a054663          	bltz	a0,8000552a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005482:	078ab783          	ld	a5,120(s5)
    80005486:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000548a:	df843783          	ld	a5,-520(s0)
    8000548e:	0007c703          	lbu	a4,0(a5)
    80005492:	cf11                	beqz	a4,800054ae <exec+0x282>
    80005494:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005496:	02f00693          	li	a3,47
    8000549a:	a039                	j	800054a8 <exec+0x27c>
      last = s+1;
    8000549c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054a0:	0785                	addi	a5,a5,1
    800054a2:	fff7c703          	lbu	a4,-1(a5)
    800054a6:	c701                	beqz	a4,800054ae <exec+0x282>
    if(*s == '/')
    800054a8:	fed71ce3          	bne	a4,a3,800054a0 <exec+0x274>
    800054ac:	bfc5                	j	8000549c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800054ae:	4641                	li	a2,16
    800054b0:	df843583          	ld	a1,-520(s0)
    800054b4:	178a8513          	addi	a0,s5,376
    800054b8:	ffffc097          	auipc	ra,0xffffc
    800054bc:	97a080e7          	jalr	-1670(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800054c0:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800054c4:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800054c8:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054cc:	078ab783          	ld	a5,120(s5)
    800054d0:	e6843703          	ld	a4,-408(s0)
    800054d4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054d6:	078ab783          	ld	a5,120(s5)
    800054da:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054de:	85ea                	mv	a1,s10
    800054e0:	ffffd097          	auipc	ra,0xffffd
    800054e4:	832080e7          	jalr	-1998(ra) # 80001d12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054e8:	0004851b          	sext.w	a0,s1
    800054ec:	bbe1                	j	800052c4 <exec+0x98>
    800054ee:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054f2:	e0843583          	ld	a1,-504(s0)
    800054f6:	855e                	mv	a0,s7
    800054f8:	ffffd097          	auipc	ra,0xffffd
    800054fc:	81a080e7          	jalr	-2022(ra) # 80001d12 <proc_freepagetable>
  if(ip){
    80005500:	da0498e3          	bnez	s1,800052b0 <exec+0x84>
  return -1;
    80005504:	557d                	li	a0,-1
    80005506:	bb7d                	j	800052c4 <exec+0x98>
    80005508:	e1243423          	sd	s2,-504(s0)
    8000550c:	b7dd                	j	800054f2 <exec+0x2c6>
    8000550e:	e1243423          	sd	s2,-504(s0)
    80005512:	b7c5                	j	800054f2 <exec+0x2c6>
    80005514:	e1243423          	sd	s2,-504(s0)
    80005518:	bfe9                	j	800054f2 <exec+0x2c6>
  sz = sz1;
    8000551a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000551e:	4481                	li	s1,0
    80005520:	bfc9                	j	800054f2 <exec+0x2c6>
  sz = sz1;
    80005522:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005526:	4481                	li	s1,0
    80005528:	b7e9                	j	800054f2 <exec+0x2c6>
  sz = sz1;
    8000552a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000552e:	4481                	li	s1,0
    80005530:	b7c9                	j	800054f2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005532:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005536:	2b05                	addiw	s6,s6,1
    80005538:	0389899b          	addiw	s3,s3,56
    8000553c:	e8845783          	lhu	a5,-376(s0)
    80005540:	e2fb5be3          	bge	s6,a5,80005376 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005544:	2981                	sext.w	s3,s3
    80005546:	03800713          	li	a4,56
    8000554a:	86ce                	mv	a3,s3
    8000554c:	e1840613          	addi	a2,s0,-488
    80005550:	4581                	li	a1,0
    80005552:	8526                	mv	a0,s1
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	a8e080e7          	jalr	-1394(ra) # 80003fe2 <readi>
    8000555c:	03800793          	li	a5,56
    80005560:	f8f517e3          	bne	a0,a5,800054ee <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005564:	e1842783          	lw	a5,-488(s0)
    80005568:	4705                	li	a4,1
    8000556a:	fce796e3          	bne	a5,a4,80005536 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000556e:	e4043603          	ld	a2,-448(s0)
    80005572:	e3843783          	ld	a5,-456(s0)
    80005576:	f8f669e3          	bltu	a2,a5,80005508 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000557a:	e2843783          	ld	a5,-472(s0)
    8000557e:	963e                	add	a2,a2,a5
    80005580:	f8f667e3          	bltu	a2,a5,8000550e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005584:	85ca                	mv	a1,s2
    80005586:	855e                	mv	a0,s7
    80005588:	ffffc097          	auipc	ra,0xffffc
    8000558c:	ea2080e7          	jalr	-350(ra) # 8000142a <uvmalloc>
    80005590:	e0a43423          	sd	a0,-504(s0)
    80005594:	d141                	beqz	a0,80005514 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005596:	e2843d03          	ld	s10,-472(s0)
    8000559a:	df043783          	ld	a5,-528(s0)
    8000559e:	00fd77b3          	and	a5,s10,a5
    800055a2:	fba1                	bnez	a5,800054f2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055a4:	e2042d83          	lw	s11,-480(s0)
    800055a8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055ac:	f80c03e3          	beqz	s8,80005532 <exec+0x306>
    800055b0:	8a62                	mv	s4,s8
    800055b2:	4901                	li	s2,0
    800055b4:	b345                	j	80005354 <exec+0x128>

00000000800055b6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055b6:	7179                	addi	sp,sp,-48
    800055b8:	f406                	sd	ra,40(sp)
    800055ba:	f022                	sd	s0,32(sp)
    800055bc:	ec26                	sd	s1,24(sp)
    800055be:	e84a                	sd	s2,16(sp)
    800055c0:	1800                	addi	s0,sp,48
    800055c2:	892e                	mv	s2,a1
    800055c4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055c6:	fdc40593          	addi	a1,s0,-36
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	b8e080e7          	jalr	-1138(ra) # 80003158 <argint>
    800055d2:	04054063          	bltz	a0,80005612 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055d6:	fdc42703          	lw	a4,-36(s0)
    800055da:	47bd                	li	a5,15
    800055dc:	02e7ed63          	bltu	a5,a4,80005616 <argfd+0x60>
    800055e0:	ffffc097          	auipc	ra,0xffffc
    800055e4:	5d2080e7          	jalr	1490(ra) # 80001bb2 <myproc>
    800055e8:	fdc42703          	lw	a4,-36(s0)
    800055ec:	01e70793          	addi	a5,a4,30
    800055f0:	078e                	slli	a5,a5,0x3
    800055f2:	953e                	add	a0,a0,a5
    800055f4:	611c                	ld	a5,0(a0)
    800055f6:	c395                	beqz	a5,8000561a <argfd+0x64>
    return -1;
  if(pfd)
    800055f8:	00090463          	beqz	s2,80005600 <argfd+0x4a>
    *pfd = fd;
    800055fc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005600:	4501                	li	a0,0
  if(pf)
    80005602:	c091                	beqz	s1,80005606 <argfd+0x50>
    *pf = f;
    80005604:	e09c                	sd	a5,0(s1)
}
    80005606:	70a2                	ld	ra,40(sp)
    80005608:	7402                	ld	s0,32(sp)
    8000560a:	64e2                	ld	s1,24(sp)
    8000560c:	6942                	ld	s2,16(sp)
    8000560e:	6145                	addi	sp,sp,48
    80005610:	8082                	ret
    return -1;
    80005612:	557d                	li	a0,-1
    80005614:	bfcd                	j	80005606 <argfd+0x50>
    return -1;
    80005616:	557d                	li	a0,-1
    80005618:	b7fd                	j	80005606 <argfd+0x50>
    8000561a:	557d                	li	a0,-1
    8000561c:	b7ed                	j	80005606 <argfd+0x50>

000000008000561e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000561e:	1101                	addi	sp,sp,-32
    80005620:	ec06                	sd	ra,24(sp)
    80005622:	e822                	sd	s0,16(sp)
    80005624:	e426                	sd	s1,8(sp)
    80005626:	1000                	addi	s0,sp,32
    80005628:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000562a:	ffffc097          	auipc	ra,0xffffc
    8000562e:	588080e7          	jalr	1416(ra) # 80001bb2 <myproc>
    80005632:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005634:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005638:	4501                	li	a0,0
    8000563a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000563c:	6398                	ld	a4,0(a5)
    8000563e:	cb19                	beqz	a4,80005654 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005640:	2505                	addiw	a0,a0,1
    80005642:	07a1                	addi	a5,a5,8
    80005644:	fed51ce3          	bne	a0,a3,8000563c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005648:	557d                	li	a0,-1
}
    8000564a:	60e2                	ld	ra,24(sp)
    8000564c:	6442                	ld	s0,16(sp)
    8000564e:	64a2                	ld	s1,8(sp)
    80005650:	6105                	addi	sp,sp,32
    80005652:	8082                	ret
      p->ofile[fd] = f;
    80005654:	01e50793          	addi	a5,a0,30
    80005658:	078e                	slli	a5,a5,0x3
    8000565a:	963e                	add	a2,a2,a5
    8000565c:	e204                	sd	s1,0(a2)
      return fd;
    8000565e:	b7f5                	j	8000564a <fdalloc+0x2c>

0000000080005660 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005660:	715d                	addi	sp,sp,-80
    80005662:	e486                	sd	ra,72(sp)
    80005664:	e0a2                	sd	s0,64(sp)
    80005666:	fc26                	sd	s1,56(sp)
    80005668:	f84a                	sd	s2,48(sp)
    8000566a:	f44e                	sd	s3,40(sp)
    8000566c:	f052                	sd	s4,32(sp)
    8000566e:	ec56                	sd	s5,24(sp)
    80005670:	0880                	addi	s0,sp,80
    80005672:	89ae                	mv	s3,a1
    80005674:	8ab2                	mv	s5,a2
    80005676:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005678:	fb040593          	addi	a1,s0,-80
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	e86080e7          	jalr	-378(ra) # 80004502 <nameiparent>
    80005684:	892a                	mv	s2,a0
    80005686:	12050f63          	beqz	a0,800057c4 <create+0x164>
    return 0;

  ilock(dp);
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	6a4080e7          	jalr	1700(ra) # 80003d2e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005692:	4601                	li	a2,0
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	854a                	mv	a0,s2
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	b78080e7          	jalr	-1160(ra) # 80004212 <dirlookup>
    800056a2:	84aa                	mv	s1,a0
    800056a4:	c921                	beqz	a0,800056f4 <create+0x94>
    iunlockput(dp);
    800056a6:	854a                	mv	a0,s2
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	8e8080e7          	jalr	-1816(ra) # 80003f90 <iunlockput>
    ilock(ip);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	67c080e7          	jalr	1660(ra) # 80003d2e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056ba:	2981                	sext.w	s3,s3
    800056bc:	4789                	li	a5,2
    800056be:	02f99463          	bne	s3,a5,800056e6 <create+0x86>
    800056c2:	0444d783          	lhu	a5,68(s1)
    800056c6:	37f9                	addiw	a5,a5,-2
    800056c8:	17c2                	slli	a5,a5,0x30
    800056ca:	93c1                	srli	a5,a5,0x30
    800056cc:	4705                	li	a4,1
    800056ce:	00f76c63          	bltu	a4,a5,800056e6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056d2:	8526                	mv	a0,s1
    800056d4:	60a6                	ld	ra,72(sp)
    800056d6:	6406                	ld	s0,64(sp)
    800056d8:	74e2                	ld	s1,56(sp)
    800056da:	7942                	ld	s2,48(sp)
    800056dc:	79a2                	ld	s3,40(sp)
    800056de:	7a02                	ld	s4,32(sp)
    800056e0:	6ae2                	ld	s5,24(sp)
    800056e2:	6161                	addi	sp,sp,80
    800056e4:	8082                	ret
    iunlockput(ip);
    800056e6:	8526                	mv	a0,s1
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	8a8080e7          	jalr	-1880(ra) # 80003f90 <iunlockput>
    return 0;
    800056f0:	4481                	li	s1,0
    800056f2:	b7c5                	j	800056d2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056f4:	85ce                	mv	a1,s3
    800056f6:	00092503          	lw	a0,0(s2)
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	49c080e7          	jalr	1180(ra) # 80003b96 <ialloc>
    80005702:	84aa                	mv	s1,a0
    80005704:	c529                	beqz	a0,8000574e <create+0xee>
  ilock(ip);
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	628080e7          	jalr	1576(ra) # 80003d2e <ilock>
  ip->major = major;
    8000570e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005712:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005716:	4785                	li	a5,1
    80005718:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	546080e7          	jalr	1350(ra) # 80003c64 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005726:	2981                	sext.w	s3,s3
    80005728:	4785                	li	a5,1
    8000572a:	02f98a63          	beq	s3,a5,8000575e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000572e:	40d0                	lw	a2,4(s1)
    80005730:	fb040593          	addi	a1,s0,-80
    80005734:	854a                	mv	a0,s2
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	cec080e7          	jalr	-788(ra) # 80004422 <dirlink>
    8000573e:	06054b63          	bltz	a0,800057b4 <create+0x154>
  iunlockput(dp);
    80005742:	854a                	mv	a0,s2
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	84c080e7          	jalr	-1972(ra) # 80003f90 <iunlockput>
  return ip;
    8000574c:	b759                	j	800056d2 <create+0x72>
    panic("create: ialloc");
    8000574e:	00003517          	auipc	a0,0x3
    80005752:	14a50513          	addi	a0,a0,330 # 80008898 <syscalls+0x2b8>
    80005756:	ffffb097          	auipc	ra,0xffffb
    8000575a:	de8080e7          	jalr	-536(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000575e:	04a95783          	lhu	a5,74(s2)
    80005762:	2785                	addiw	a5,a5,1
    80005764:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	4fa080e7          	jalr	1274(ra) # 80003c64 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005772:	40d0                	lw	a2,4(s1)
    80005774:	00003597          	auipc	a1,0x3
    80005778:	13458593          	addi	a1,a1,308 # 800088a8 <syscalls+0x2c8>
    8000577c:	8526                	mv	a0,s1
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	ca4080e7          	jalr	-860(ra) # 80004422 <dirlink>
    80005786:	00054f63          	bltz	a0,800057a4 <create+0x144>
    8000578a:	00492603          	lw	a2,4(s2)
    8000578e:	00003597          	auipc	a1,0x3
    80005792:	12258593          	addi	a1,a1,290 # 800088b0 <syscalls+0x2d0>
    80005796:	8526                	mv	a0,s1
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	c8a080e7          	jalr	-886(ra) # 80004422 <dirlink>
    800057a0:	f80557e3          	bgez	a0,8000572e <create+0xce>
      panic("create dots");
    800057a4:	00003517          	auipc	a0,0x3
    800057a8:	11450513          	addi	a0,a0,276 # 800088b8 <syscalls+0x2d8>
    800057ac:	ffffb097          	auipc	ra,0xffffb
    800057b0:	d92080e7          	jalr	-622(ra) # 8000053e <panic>
    panic("create: dirlink");
    800057b4:	00003517          	auipc	a0,0x3
    800057b8:	11450513          	addi	a0,a0,276 # 800088c8 <syscalls+0x2e8>
    800057bc:	ffffb097          	auipc	ra,0xffffb
    800057c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>
    return 0;
    800057c4:	84aa                	mv	s1,a0
    800057c6:	b731                	j	800056d2 <create+0x72>

00000000800057c8 <sys_dup>:
{
    800057c8:	7179                	addi	sp,sp,-48
    800057ca:	f406                	sd	ra,40(sp)
    800057cc:	f022                	sd	s0,32(sp)
    800057ce:	ec26                	sd	s1,24(sp)
    800057d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057d2:	fd840613          	addi	a2,s0,-40
    800057d6:	4581                	li	a1,0
    800057d8:	4501                	li	a0,0
    800057da:	00000097          	auipc	ra,0x0
    800057de:	ddc080e7          	jalr	-548(ra) # 800055b6 <argfd>
    return -1;
    800057e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057e4:	02054363          	bltz	a0,8000580a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057e8:	fd843503          	ld	a0,-40(s0)
    800057ec:	00000097          	auipc	ra,0x0
    800057f0:	e32080e7          	jalr	-462(ra) # 8000561e <fdalloc>
    800057f4:	84aa                	mv	s1,a0
    return -1;
    800057f6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057f8:	00054963          	bltz	a0,8000580a <sys_dup+0x42>
  filedup(f);
    800057fc:	fd843503          	ld	a0,-40(s0)
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	37a080e7          	jalr	890(ra) # 80004b7a <filedup>
  return fd;
    80005808:	87a6                	mv	a5,s1
}
    8000580a:	853e                	mv	a0,a5
    8000580c:	70a2                	ld	ra,40(sp)
    8000580e:	7402                	ld	s0,32(sp)
    80005810:	64e2                	ld	s1,24(sp)
    80005812:	6145                	addi	sp,sp,48
    80005814:	8082                	ret

0000000080005816 <sys_read>:
{
    80005816:	7179                	addi	sp,sp,-48
    80005818:	f406                	sd	ra,40(sp)
    8000581a:	f022                	sd	s0,32(sp)
    8000581c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000581e:	fe840613          	addi	a2,s0,-24
    80005822:	4581                	li	a1,0
    80005824:	4501                	li	a0,0
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	d90080e7          	jalr	-624(ra) # 800055b6 <argfd>
    return -1;
    8000582e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005830:	04054163          	bltz	a0,80005872 <sys_read+0x5c>
    80005834:	fe440593          	addi	a1,s0,-28
    80005838:	4509                	li	a0,2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	91e080e7          	jalr	-1762(ra) # 80003158 <argint>
    return -1;
    80005842:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005844:	02054763          	bltz	a0,80005872 <sys_read+0x5c>
    80005848:	fd840593          	addi	a1,s0,-40
    8000584c:	4505                	li	a0,1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	92c080e7          	jalr	-1748(ra) # 8000317a <argaddr>
    return -1;
    80005856:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005858:	00054d63          	bltz	a0,80005872 <sys_read+0x5c>
  return fileread(f, p, n);
    8000585c:	fe442603          	lw	a2,-28(s0)
    80005860:	fd843583          	ld	a1,-40(s0)
    80005864:	fe843503          	ld	a0,-24(s0)
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	49e080e7          	jalr	1182(ra) # 80004d06 <fileread>
    80005870:	87aa                	mv	a5,a0
}
    80005872:	853e                	mv	a0,a5
    80005874:	70a2                	ld	ra,40(sp)
    80005876:	7402                	ld	s0,32(sp)
    80005878:	6145                	addi	sp,sp,48
    8000587a:	8082                	ret

000000008000587c <sys_write>:
{
    8000587c:	7179                	addi	sp,sp,-48
    8000587e:	f406                	sd	ra,40(sp)
    80005880:	f022                	sd	s0,32(sp)
    80005882:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005884:	fe840613          	addi	a2,s0,-24
    80005888:	4581                	li	a1,0
    8000588a:	4501                	li	a0,0
    8000588c:	00000097          	auipc	ra,0x0
    80005890:	d2a080e7          	jalr	-726(ra) # 800055b6 <argfd>
    return -1;
    80005894:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005896:	04054163          	bltz	a0,800058d8 <sys_write+0x5c>
    8000589a:	fe440593          	addi	a1,s0,-28
    8000589e:	4509                	li	a0,2
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	8b8080e7          	jalr	-1864(ra) # 80003158 <argint>
    return -1;
    800058a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058aa:	02054763          	bltz	a0,800058d8 <sys_write+0x5c>
    800058ae:	fd840593          	addi	a1,s0,-40
    800058b2:	4505                	li	a0,1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	8c6080e7          	jalr	-1850(ra) # 8000317a <argaddr>
    return -1;
    800058bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058be:	00054d63          	bltz	a0,800058d8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800058c2:	fe442603          	lw	a2,-28(s0)
    800058c6:	fd843583          	ld	a1,-40(s0)
    800058ca:	fe843503          	ld	a0,-24(s0)
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	4fa080e7          	jalr	1274(ra) # 80004dc8 <filewrite>
    800058d6:	87aa                	mv	a5,a0
}
    800058d8:	853e                	mv	a0,a5
    800058da:	70a2                	ld	ra,40(sp)
    800058dc:	7402                	ld	s0,32(sp)
    800058de:	6145                	addi	sp,sp,48
    800058e0:	8082                	ret

00000000800058e2 <sys_close>:
{
    800058e2:	1101                	addi	sp,sp,-32
    800058e4:	ec06                	sd	ra,24(sp)
    800058e6:	e822                	sd	s0,16(sp)
    800058e8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058ea:	fe040613          	addi	a2,s0,-32
    800058ee:	fec40593          	addi	a1,s0,-20
    800058f2:	4501                	li	a0,0
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	cc2080e7          	jalr	-830(ra) # 800055b6 <argfd>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058fe:	02054463          	bltz	a0,80005926 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005902:	ffffc097          	auipc	ra,0xffffc
    80005906:	2b0080e7          	jalr	688(ra) # 80001bb2 <myproc>
    8000590a:	fec42783          	lw	a5,-20(s0)
    8000590e:	07f9                	addi	a5,a5,30
    80005910:	078e                	slli	a5,a5,0x3
    80005912:	97aa                	add	a5,a5,a0
    80005914:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005918:	fe043503          	ld	a0,-32(s0)
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	2b0080e7          	jalr	688(ra) # 80004bcc <fileclose>
  return 0;
    80005924:	4781                	li	a5,0
}
    80005926:	853e                	mv	a0,a5
    80005928:	60e2                	ld	ra,24(sp)
    8000592a:	6442                	ld	s0,16(sp)
    8000592c:	6105                	addi	sp,sp,32
    8000592e:	8082                	ret

0000000080005930 <sys_fstat>:
{
    80005930:	1101                	addi	sp,sp,-32
    80005932:	ec06                	sd	ra,24(sp)
    80005934:	e822                	sd	s0,16(sp)
    80005936:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005938:	fe840613          	addi	a2,s0,-24
    8000593c:	4581                	li	a1,0
    8000593e:	4501                	li	a0,0
    80005940:	00000097          	auipc	ra,0x0
    80005944:	c76080e7          	jalr	-906(ra) # 800055b6 <argfd>
    return -1;
    80005948:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000594a:	02054563          	bltz	a0,80005974 <sys_fstat+0x44>
    8000594e:	fe040593          	addi	a1,s0,-32
    80005952:	4505                	li	a0,1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	826080e7          	jalr	-2010(ra) # 8000317a <argaddr>
    return -1;
    8000595c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000595e:	00054b63          	bltz	a0,80005974 <sys_fstat+0x44>
  return filestat(f, st);
    80005962:	fe043583          	ld	a1,-32(s0)
    80005966:	fe843503          	ld	a0,-24(s0)
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	32a080e7          	jalr	810(ra) # 80004c94 <filestat>
    80005972:	87aa                	mv	a5,a0
}
    80005974:	853e                	mv	a0,a5
    80005976:	60e2                	ld	ra,24(sp)
    80005978:	6442                	ld	s0,16(sp)
    8000597a:	6105                	addi	sp,sp,32
    8000597c:	8082                	ret

000000008000597e <sys_link>:
{
    8000597e:	7169                	addi	sp,sp,-304
    80005980:	f606                	sd	ra,296(sp)
    80005982:	f222                	sd	s0,288(sp)
    80005984:	ee26                	sd	s1,280(sp)
    80005986:	ea4a                	sd	s2,272(sp)
    80005988:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000598a:	08000613          	li	a2,128
    8000598e:	ed040593          	addi	a1,s0,-304
    80005992:	4501                	li	a0,0
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	808080e7          	jalr	-2040(ra) # 8000319c <argstr>
    return -1;
    8000599c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000599e:	10054e63          	bltz	a0,80005aba <sys_link+0x13c>
    800059a2:	08000613          	li	a2,128
    800059a6:	f5040593          	addi	a1,s0,-176
    800059aa:	4505                	li	a0,1
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	7f0080e7          	jalr	2032(ra) # 8000319c <argstr>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b6:	10054263          	bltz	a0,80005aba <sys_link+0x13c>
  begin_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	d46080e7          	jalr	-698(ra) # 80004700 <begin_op>
  if((ip = namei(old)) == 0){
    800059c2:	ed040513          	addi	a0,s0,-304
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	b1e080e7          	jalr	-1250(ra) # 800044e4 <namei>
    800059ce:	84aa                	mv	s1,a0
    800059d0:	c551                	beqz	a0,80005a5c <sys_link+0xde>
  ilock(ip);
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	35c080e7          	jalr	860(ra) # 80003d2e <ilock>
  if(ip->type == T_DIR){
    800059da:	04449703          	lh	a4,68(s1)
    800059de:	4785                	li	a5,1
    800059e0:	08f70463          	beq	a4,a5,80005a68 <sys_link+0xea>
  ip->nlink++;
    800059e4:	04a4d783          	lhu	a5,74(s1)
    800059e8:	2785                	addiw	a5,a5,1
    800059ea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059ee:	8526                	mv	a0,s1
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	274080e7          	jalr	628(ra) # 80003c64 <iupdate>
  iunlock(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	3f6080e7          	jalr	1014(ra) # 80003df0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a02:	fd040593          	addi	a1,s0,-48
    80005a06:	f5040513          	addi	a0,s0,-176
    80005a0a:	fffff097          	auipc	ra,0xfffff
    80005a0e:	af8080e7          	jalr	-1288(ra) # 80004502 <nameiparent>
    80005a12:	892a                	mv	s2,a0
    80005a14:	c935                	beqz	a0,80005a88 <sys_link+0x10a>
  ilock(dp);
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	318080e7          	jalr	792(ra) # 80003d2e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a1e:	00092703          	lw	a4,0(s2)
    80005a22:	409c                	lw	a5,0(s1)
    80005a24:	04f71d63          	bne	a4,a5,80005a7e <sys_link+0x100>
    80005a28:	40d0                	lw	a2,4(s1)
    80005a2a:	fd040593          	addi	a1,s0,-48
    80005a2e:	854a                	mv	a0,s2
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	9f2080e7          	jalr	-1550(ra) # 80004422 <dirlink>
    80005a38:	04054363          	bltz	a0,80005a7e <sys_link+0x100>
  iunlockput(dp);
    80005a3c:	854a                	mv	a0,s2
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	552080e7          	jalr	1362(ra) # 80003f90 <iunlockput>
  iput(ip);
    80005a46:	8526                	mv	a0,s1
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	4a0080e7          	jalr	1184(ra) # 80003ee8 <iput>
  end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	d30080e7          	jalr	-720(ra) # 80004780 <end_op>
  return 0;
    80005a58:	4781                	li	a5,0
    80005a5a:	a085                	j	80005aba <sys_link+0x13c>
    end_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	d24080e7          	jalr	-732(ra) # 80004780 <end_op>
    return -1;
    80005a64:	57fd                	li	a5,-1
    80005a66:	a891                	j	80005aba <sys_link+0x13c>
    iunlockput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	526080e7          	jalr	1318(ra) # 80003f90 <iunlockput>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	d0e080e7          	jalr	-754(ra) # 80004780 <end_op>
    return -1;
    80005a7a:	57fd                	li	a5,-1
    80005a7c:	a83d                	j	80005aba <sys_link+0x13c>
    iunlockput(dp);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	510080e7          	jalr	1296(ra) # 80003f90 <iunlockput>
  ilock(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	2a4080e7          	jalr	676(ra) # 80003d2e <ilock>
  ip->nlink--;
    80005a92:	04a4d783          	lhu	a5,74(s1)
    80005a96:	37fd                	addiw	a5,a5,-1
    80005a98:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	1c6080e7          	jalr	454(ra) # 80003c64 <iupdate>
  iunlockput(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	4e8080e7          	jalr	1256(ra) # 80003f90 <iunlockput>
  end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	cd0080e7          	jalr	-816(ra) # 80004780 <end_op>
  return -1;
    80005ab8:	57fd                	li	a5,-1
}
    80005aba:	853e                	mv	a0,a5
    80005abc:	70b2                	ld	ra,296(sp)
    80005abe:	7412                	ld	s0,288(sp)
    80005ac0:	64f2                	ld	s1,280(sp)
    80005ac2:	6952                	ld	s2,272(sp)
    80005ac4:	6155                	addi	sp,sp,304
    80005ac6:	8082                	ret

0000000080005ac8 <sys_unlink>:
{
    80005ac8:	7151                	addi	sp,sp,-240
    80005aca:	f586                	sd	ra,232(sp)
    80005acc:	f1a2                	sd	s0,224(sp)
    80005ace:	eda6                	sd	s1,216(sp)
    80005ad0:	e9ca                	sd	s2,208(sp)
    80005ad2:	e5ce                	sd	s3,200(sp)
    80005ad4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ad6:	08000613          	li	a2,128
    80005ada:	f3040593          	addi	a1,s0,-208
    80005ade:	4501                	li	a0,0
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	6bc080e7          	jalr	1724(ra) # 8000319c <argstr>
    80005ae8:	18054163          	bltz	a0,80005c6a <sys_unlink+0x1a2>
  begin_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	c14080e7          	jalr	-1004(ra) # 80004700 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005af4:	fb040593          	addi	a1,s0,-80
    80005af8:	f3040513          	addi	a0,s0,-208
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	a06080e7          	jalr	-1530(ra) # 80004502 <nameiparent>
    80005b04:	84aa                	mv	s1,a0
    80005b06:	c979                	beqz	a0,80005bdc <sys_unlink+0x114>
  ilock(dp);
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	226080e7          	jalr	550(ra) # 80003d2e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b10:	00003597          	auipc	a1,0x3
    80005b14:	d9858593          	addi	a1,a1,-616 # 800088a8 <syscalls+0x2c8>
    80005b18:	fb040513          	addi	a0,s0,-80
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	6dc080e7          	jalr	1756(ra) # 800041f8 <namecmp>
    80005b24:	14050a63          	beqz	a0,80005c78 <sys_unlink+0x1b0>
    80005b28:	00003597          	auipc	a1,0x3
    80005b2c:	d8858593          	addi	a1,a1,-632 # 800088b0 <syscalls+0x2d0>
    80005b30:	fb040513          	addi	a0,s0,-80
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	6c4080e7          	jalr	1732(ra) # 800041f8 <namecmp>
    80005b3c:	12050e63          	beqz	a0,80005c78 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b40:	f2c40613          	addi	a2,s0,-212
    80005b44:	fb040593          	addi	a1,s0,-80
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	6c8080e7          	jalr	1736(ra) # 80004212 <dirlookup>
    80005b52:	892a                	mv	s2,a0
    80005b54:	12050263          	beqz	a0,80005c78 <sys_unlink+0x1b0>
  ilock(ip);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	1d6080e7          	jalr	470(ra) # 80003d2e <ilock>
  if(ip->nlink < 1)
    80005b60:	04a91783          	lh	a5,74(s2)
    80005b64:	08f05263          	blez	a5,80005be8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b68:	04491703          	lh	a4,68(s2)
    80005b6c:	4785                	li	a5,1
    80005b6e:	08f70563          	beq	a4,a5,80005bf8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b72:	4641                	li	a2,16
    80005b74:	4581                	li	a1,0
    80005b76:	fc040513          	addi	a0,s0,-64
    80005b7a:	ffffb097          	auipc	ra,0xffffb
    80005b7e:	166080e7          	jalr	358(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b82:	4741                	li	a4,16
    80005b84:	f2c42683          	lw	a3,-212(s0)
    80005b88:	fc040613          	addi	a2,s0,-64
    80005b8c:	4581                	li	a1,0
    80005b8e:	8526                	mv	a0,s1
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	54a080e7          	jalr	1354(ra) # 800040da <writei>
    80005b98:	47c1                	li	a5,16
    80005b9a:	0af51563          	bne	a0,a5,80005c44 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b9e:	04491703          	lh	a4,68(s2)
    80005ba2:	4785                	li	a5,1
    80005ba4:	0af70863          	beq	a4,a5,80005c54 <sys_unlink+0x18c>
  iunlockput(dp);
    80005ba8:	8526                	mv	a0,s1
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	3e6080e7          	jalr	998(ra) # 80003f90 <iunlockput>
  ip->nlink--;
    80005bb2:	04a95783          	lhu	a5,74(s2)
    80005bb6:	37fd                	addiw	a5,a5,-1
    80005bb8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bbc:	854a                	mv	a0,s2
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	0a6080e7          	jalr	166(ra) # 80003c64 <iupdate>
  iunlockput(ip);
    80005bc6:	854a                	mv	a0,s2
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	3c8080e7          	jalr	968(ra) # 80003f90 <iunlockput>
  end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	bb0080e7          	jalr	-1104(ra) # 80004780 <end_op>
  return 0;
    80005bd8:	4501                	li	a0,0
    80005bda:	a84d                	j	80005c8c <sys_unlink+0x1c4>
    end_op();
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	ba4080e7          	jalr	-1116(ra) # 80004780 <end_op>
    return -1;
    80005be4:	557d                	li	a0,-1
    80005be6:	a05d                	j	80005c8c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005be8:	00003517          	auipc	a0,0x3
    80005bec:	cf050513          	addi	a0,a0,-784 # 800088d8 <syscalls+0x2f8>
    80005bf0:	ffffb097          	auipc	ra,0xffffb
    80005bf4:	94e080e7          	jalr	-1714(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bf8:	04c92703          	lw	a4,76(s2)
    80005bfc:	02000793          	li	a5,32
    80005c00:	f6e7f9e3          	bgeu	a5,a4,80005b72 <sys_unlink+0xaa>
    80005c04:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c08:	4741                	li	a4,16
    80005c0a:	86ce                	mv	a3,s3
    80005c0c:	f1840613          	addi	a2,s0,-232
    80005c10:	4581                	li	a1,0
    80005c12:	854a                	mv	a0,s2
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	3ce080e7          	jalr	974(ra) # 80003fe2 <readi>
    80005c1c:	47c1                	li	a5,16
    80005c1e:	00f51b63          	bne	a0,a5,80005c34 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c22:	f1845783          	lhu	a5,-232(s0)
    80005c26:	e7a1                	bnez	a5,80005c6e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c28:	29c1                	addiw	s3,s3,16
    80005c2a:	04c92783          	lw	a5,76(s2)
    80005c2e:	fcf9ede3          	bltu	s3,a5,80005c08 <sys_unlink+0x140>
    80005c32:	b781                	j	80005b72 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c34:	00003517          	auipc	a0,0x3
    80005c38:	cbc50513          	addi	a0,a0,-836 # 800088f0 <syscalls+0x310>
    80005c3c:	ffffb097          	auipc	ra,0xffffb
    80005c40:	902080e7          	jalr	-1790(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005c44:	00003517          	auipc	a0,0x3
    80005c48:	cc450513          	addi	a0,a0,-828 # 80008908 <syscalls+0x328>
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>
    dp->nlink--;
    80005c54:	04a4d783          	lhu	a5,74(s1)
    80005c58:	37fd                	addiw	a5,a5,-1
    80005c5a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c5e:	8526                	mv	a0,s1
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	004080e7          	jalr	4(ra) # 80003c64 <iupdate>
    80005c68:	b781                	j	80005ba8 <sys_unlink+0xe0>
    return -1;
    80005c6a:	557d                	li	a0,-1
    80005c6c:	a005                	j	80005c8c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c6e:	854a                	mv	a0,s2
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	320080e7          	jalr	800(ra) # 80003f90 <iunlockput>
  iunlockput(dp);
    80005c78:	8526                	mv	a0,s1
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	316080e7          	jalr	790(ra) # 80003f90 <iunlockput>
  end_op();
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	afe080e7          	jalr	-1282(ra) # 80004780 <end_op>
  return -1;
    80005c8a:	557d                	li	a0,-1
}
    80005c8c:	70ae                	ld	ra,232(sp)
    80005c8e:	740e                	ld	s0,224(sp)
    80005c90:	64ee                	ld	s1,216(sp)
    80005c92:	694e                	ld	s2,208(sp)
    80005c94:	69ae                	ld	s3,200(sp)
    80005c96:	616d                	addi	sp,sp,240
    80005c98:	8082                	ret

0000000080005c9a <sys_open>:

uint64
sys_open(void)
{
    80005c9a:	7131                	addi	sp,sp,-192
    80005c9c:	fd06                	sd	ra,184(sp)
    80005c9e:	f922                	sd	s0,176(sp)
    80005ca0:	f526                	sd	s1,168(sp)
    80005ca2:	f14a                	sd	s2,160(sp)
    80005ca4:	ed4e                	sd	s3,152(sp)
    80005ca6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ca8:	08000613          	li	a2,128
    80005cac:	f5040593          	addi	a1,s0,-176
    80005cb0:	4501                	li	a0,0
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	4ea080e7          	jalr	1258(ra) # 8000319c <argstr>
    return -1;
    80005cba:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cbc:	0c054163          	bltz	a0,80005d7e <sys_open+0xe4>
    80005cc0:	f4c40593          	addi	a1,s0,-180
    80005cc4:	4505                	li	a0,1
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	492080e7          	jalr	1170(ra) # 80003158 <argint>
    80005cce:	0a054863          	bltz	a0,80005d7e <sys_open+0xe4>

  begin_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a2e080e7          	jalr	-1490(ra) # 80004700 <begin_op>

  if(omode & O_CREATE){
    80005cda:	f4c42783          	lw	a5,-180(s0)
    80005cde:	2007f793          	andi	a5,a5,512
    80005ce2:	cbdd                	beqz	a5,80005d98 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ce4:	4681                	li	a3,0
    80005ce6:	4601                	li	a2,0
    80005ce8:	4589                	li	a1,2
    80005cea:	f5040513          	addi	a0,s0,-176
    80005cee:	00000097          	auipc	ra,0x0
    80005cf2:	972080e7          	jalr	-1678(ra) # 80005660 <create>
    80005cf6:	892a                	mv	s2,a0
    if(ip == 0){
    80005cf8:	c959                	beqz	a0,80005d8e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cfa:	04491703          	lh	a4,68(s2)
    80005cfe:	478d                	li	a5,3
    80005d00:	00f71763          	bne	a4,a5,80005d0e <sys_open+0x74>
    80005d04:	04695703          	lhu	a4,70(s2)
    80005d08:	47a5                	li	a5,9
    80005d0a:	0ce7ec63          	bltu	a5,a4,80005de2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d0e:	fffff097          	auipc	ra,0xfffff
    80005d12:	e02080e7          	jalr	-510(ra) # 80004b10 <filealloc>
    80005d16:	89aa                	mv	s3,a0
    80005d18:	10050263          	beqz	a0,80005e1c <sys_open+0x182>
    80005d1c:	00000097          	auipc	ra,0x0
    80005d20:	902080e7          	jalr	-1790(ra) # 8000561e <fdalloc>
    80005d24:	84aa                	mv	s1,a0
    80005d26:	0e054663          	bltz	a0,80005e12 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d2a:	04491703          	lh	a4,68(s2)
    80005d2e:	478d                	li	a5,3
    80005d30:	0cf70463          	beq	a4,a5,80005df8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d34:	4789                	li	a5,2
    80005d36:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d3a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d3e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d42:	f4c42783          	lw	a5,-180(s0)
    80005d46:	0017c713          	xori	a4,a5,1
    80005d4a:	8b05                	andi	a4,a4,1
    80005d4c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d50:	0037f713          	andi	a4,a5,3
    80005d54:	00e03733          	snez	a4,a4
    80005d58:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d5c:	4007f793          	andi	a5,a5,1024
    80005d60:	c791                	beqz	a5,80005d6c <sys_open+0xd2>
    80005d62:	04491703          	lh	a4,68(s2)
    80005d66:	4789                	li	a5,2
    80005d68:	08f70f63          	beq	a4,a5,80005e06 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d6c:	854a                	mv	a0,s2
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	082080e7          	jalr	130(ra) # 80003df0 <iunlock>
  end_op();
    80005d76:	fffff097          	auipc	ra,0xfffff
    80005d7a:	a0a080e7          	jalr	-1526(ra) # 80004780 <end_op>

  return fd;
}
    80005d7e:	8526                	mv	a0,s1
    80005d80:	70ea                	ld	ra,184(sp)
    80005d82:	744a                	ld	s0,176(sp)
    80005d84:	74aa                	ld	s1,168(sp)
    80005d86:	790a                	ld	s2,160(sp)
    80005d88:	69ea                	ld	s3,152(sp)
    80005d8a:	6129                	addi	sp,sp,192
    80005d8c:	8082                	ret
      end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	9f2080e7          	jalr	-1550(ra) # 80004780 <end_op>
      return -1;
    80005d96:	b7e5                	j	80005d7e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d98:	f5040513          	addi	a0,s0,-176
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	748080e7          	jalr	1864(ra) # 800044e4 <namei>
    80005da4:	892a                	mv	s2,a0
    80005da6:	c905                	beqz	a0,80005dd6 <sys_open+0x13c>
    ilock(ip);
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	f86080e7          	jalr	-122(ra) # 80003d2e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005db0:	04491703          	lh	a4,68(s2)
    80005db4:	4785                	li	a5,1
    80005db6:	f4f712e3          	bne	a4,a5,80005cfa <sys_open+0x60>
    80005dba:	f4c42783          	lw	a5,-180(s0)
    80005dbe:	dba1                	beqz	a5,80005d0e <sys_open+0x74>
      iunlockput(ip);
    80005dc0:	854a                	mv	a0,s2
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	1ce080e7          	jalr	462(ra) # 80003f90 <iunlockput>
      end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	9b6080e7          	jalr	-1610(ra) # 80004780 <end_op>
      return -1;
    80005dd2:	54fd                	li	s1,-1
    80005dd4:	b76d                	j	80005d7e <sys_open+0xe4>
      end_op();
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	9aa080e7          	jalr	-1622(ra) # 80004780 <end_op>
      return -1;
    80005dde:	54fd                	li	s1,-1
    80005de0:	bf79                	j	80005d7e <sys_open+0xe4>
    iunlockput(ip);
    80005de2:	854a                	mv	a0,s2
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	1ac080e7          	jalr	428(ra) # 80003f90 <iunlockput>
    end_op();
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	994080e7          	jalr	-1644(ra) # 80004780 <end_op>
    return -1;
    80005df4:	54fd                	li	s1,-1
    80005df6:	b761                	j	80005d7e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005df8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dfc:	04691783          	lh	a5,70(s2)
    80005e00:	02f99223          	sh	a5,36(s3)
    80005e04:	bf2d                	j	80005d3e <sys_open+0xa4>
    itrunc(ip);
    80005e06:	854a                	mv	a0,s2
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	034080e7          	jalr	52(ra) # 80003e3c <itrunc>
    80005e10:	bfb1                	j	80005d6c <sys_open+0xd2>
      fileclose(f);
    80005e12:	854e                	mv	a0,s3
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	db8080e7          	jalr	-584(ra) # 80004bcc <fileclose>
    iunlockput(ip);
    80005e1c:	854a                	mv	a0,s2
    80005e1e:	ffffe097          	auipc	ra,0xffffe
    80005e22:	172080e7          	jalr	370(ra) # 80003f90 <iunlockput>
    end_op();
    80005e26:	fffff097          	auipc	ra,0xfffff
    80005e2a:	95a080e7          	jalr	-1702(ra) # 80004780 <end_op>
    return -1;
    80005e2e:	54fd                	li	s1,-1
    80005e30:	b7b9                	j	80005d7e <sys_open+0xe4>

0000000080005e32 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e32:	7175                	addi	sp,sp,-144
    80005e34:	e506                	sd	ra,136(sp)
    80005e36:	e122                	sd	s0,128(sp)
    80005e38:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	8c6080e7          	jalr	-1850(ra) # 80004700 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e42:	08000613          	li	a2,128
    80005e46:	f7040593          	addi	a1,s0,-144
    80005e4a:	4501                	li	a0,0
    80005e4c:	ffffd097          	auipc	ra,0xffffd
    80005e50:	350080e7          	jalr	848(ra) # 8000319c <argstr>
    80005e54:	02054963          	bltz	a0,80005e86 <sys_mkdir+0x54>
    80005e58:	4681                	li	a3,0
    80005e5a:	4601                	li	a2,0
    80005e5c:	4585                	li	a1,1
    80005e5e:	f7040513          	addi	a0,s0,-144
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	7fe080e7          	jalr	2046(ra) # 80005660 <create>
    80005e6a:	cd11                	beqz	a0,80005e86 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	124080e7          	jalr	292(ra) # 80003f90 <iunlockput>
  end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	90c080e7          	jalr	-1780(ra) # 80004780 <end_op>
  return 0;
    80005e7c:	4501                	li	a0,0
}
    80005e7e:	60aa                	ld	ra,136(sp)
    80005e80:	640a                	ld	s0,128(sp)
    80005e82:	6149                	addi	sp,sp,144
    80005e84:	8082                	ret
    end_op();
    80005e86:	fffff097          	auipc	ra,0xfffff
    80005e8a:	8fa080e7          	jalr	-1798(ra) # 80004780 <end_op>
    return -1;
    80005e8e:	557d                	li	a0,-1
    80005e90:	b7fd                	j	80005e7e <sys_mkdir+0x4c>

0000000080005e92 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e92:	7135                	addi	sp,sp,-160
    80005e94:	ed06                	sd	ra,152(sp)
    80005e96:	e922                	sd	s0,144(sp)
    80005e98:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	866080e7          	jalr	-1946(ra) # 80004700 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea2:	08000613          	li	a2,128
    80005ea6:	f7040593          	addi	a1,s0,-144
    80005eaa:	4501                	li	a0,0
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	2f0080e7          	jalr	752(ra) # 8000319c <argstr>
    80005eb4:	04054a63          	bltz	a0,80005f08 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005eb8:	f6c40593          	addi	a1,s0,-148
    80005ebc:	4505                	li	a0,1
    80005ebe:	ffffd097          	auipc	ra,0xffffd
    80005ec2:	29a080e7          	jalr	666(ra) # 80003158 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ec6:	04054163          	bltz	a0,80005f08 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005eca:	f6840593          	addi	a1,s0,-152
    80005ece:	4509                	li	a0,2
    80005ed0:	ffffd097          	auipc	ra,0xffffd
    80005ed4:	288080e7          	jalr	648(ra) # 80003158 <argint>
     argint(1, &major) < 0 ||
    80005ed8:	02054863          	bltz	a0,80005f08 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005edc:	f6841683          	lh	a3,-152(s0)
    80005ee0:	f6c41603          	lh	a2,-148(s0)
    80005ee4:	458d                	li	a1,3
    80005ee6:	f7040513          	addi	a0,s0,-144
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	776080e7          	jalr	1910(ra) # 80005660 <create>
     argint(2, &minor) < 0 ||
    80005ef2:	c919                	beqz	a0,80005f08 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ef4:	ffffe097          	auipc	ra,0xffffe
    80005ef8:	09c080e7          	jalr	156(ra) # 80003f90 <iunlockput>
  end_op();
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	884080e7          	jalr	-1916(ra) # 80004780 <end_op>
  return 0;
    80005f04:	4501                	li	a0,0
    80005f06:	a031                	j	80005f12 <sys_mknod+0x80>
    end_op();
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	878080e7          	jalr	-1928(ra) # 80004780 <end_op>
    return -1;
    80005f10:	557d                	li	a0,-1
}
    80005f12:	60ea                	ld	ra,152(sp)
    80005f14:	644a                	ld	s0,144(sp)
    80005f16:	610d                	addi	sp,sp,160
    80005f18:	8082                	ret

0000000080005f1a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f1a:	7135                	addi	sp,sp,-160
    80005f1c:	ed06                	sd	ra,152(sp)
    80005f1e:	e922                	sd	s0,144(sp)
    80005f20:	e526                	sd	s1,136(sp)
    80005f22:	e14a                	sd	s2,128(sp)
    80005f24:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f26:	ffffc097          	auipc	ra,0xffffc
    80005f2a:	c8c080e7          	jalr	-884(ra) # 80001bb2 <myproc>
    80005f2e:	892a                	mv	s2,a0
  
  begin_op();
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	7d0080e7          	jalr	2000(ra) # 80004700 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f38:	08000613          	li	a2,128
    80005f3c:	f6040593          	addi	a1,s0,-160
    80005f40:	4501                	li	a0,0
    80005f42:	ffffd097          	auipc	ra,0xffffd
    80005f46:	25a080e7          	jalr	602(ra) # 8000319c <argstr>
    80005f4a:	04054b63          	bltz	a0,80005fa0 <sys_chdir+0x86>
    80005f4e:	f6040513          	addi	a0,s0,-160
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	592080e7          	jalr	1426(ra) # 800044e4 <namei>
    80005f5a:	84aa                	mv	s1,a0
    80005f5c:	c131                	beqz	a0,80005fa0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f5e:	ffffe097          	auipc	ra,0xffffe
    80005f62:	dd0080e7          	jalr	-560(ra) # 80003d2e <ilock>
  if(ip->type != T_DIR){
    80005f66:	04449703          	lh	a4,68(s1)
    80005f6a:	4785                	li	a5,1
    80005f6c:	04f71063          	bne	a4,a5,80005fac <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f70:	8526                	mv	a0,s1
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	e7e080e7          	jalr	-386(ra) # 80003df0 <iunlock>
  iput(p->cwd);
    80005f7a:	17093503          	ld	a0,368(s2)
    80005f7e:	ffffe097          	auipc	ra,0xffffe
    80005f82:	f6a080e7          	jalr	-150(ra) # 80003ee8 <iput>
  end_op();
    80005f86:	ffffe097          	auipc	ra,0xffffe
    80005f8a:	7fa080e7          	jalr	2042(ra) # 80004780 <end_op>
  p->cwd = ip;
    80005f8e:	16993823          	sd	s1,368(s2)
  return 0;
    80005f92:	4501                	li	a0,0
}
    80005f94:	60ea                	ld	ra,152(sp)
    80005f96:	644a                	ld	s0,144(sp)
    80005f98:	64aa                	ld	s1,136(sp)
    80005f9a:	690a                	ld	s2,128(sp)
    80005f9c:	610d                	addi	sp,sp,160
    80005f9e:	8082                	ret
    end_op();
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	7e0080e7          	jalr	2016(ra) # 80004780 <end_op>
    return -1;
    80005fa8:	557d                	li	a0,-1
    80005faa:	b7ed                	j	80005f94 <sys_chdir+0x7a>
    iunlockput(ip);
    80005fac:	8526                	mv	a0,s1
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	fe2080e7          	jalr	-30(ra) # 80003f90 <iunlockput>
    end_op();
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	7ca080e7          	jalr	1994(ra) # 80004780 <end_op>
    return -1;
    80005fbe:	557d                	li	a0,-1
    80005fc0:	bfd1                	j	80005f94 <sys_chdir+0x7a>

0000000080005fc2 <sys_exec>:

uint64
sys_exec(void)
{
    80005fc2:	7145                	addi	sp,sp,-464
    80005fc4:	e786                	sd	ra,456(sp)
    80005fc6:	e3a2                	sd	s0,448(sp)
    80005fc8:	ff26                	sd	s1,440(sp)
    80005fca:	fb4a                	sd	s2,432(sp)
    80005fcc:	f74e                	sd	s3,424(sp)
    80005fce:	f352                	sd	s4,416(sp)
    80005fd0:	ef56                	sd	s5,408(sp)
    80005fd2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fd4:	08000613          	li	a2,128
    80005fd8:	f4040593          	addi	a1,s0,-192
    80005fdc:	4501                	li	a0,0
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	1be080e7          	jalr	446(ra) # 8000319c <argstr>
    return -1;
    80005fe6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fe8:	0c054a63          	bltz	a0,800060bc <sys_exec+0xfa>
    80005fec:	e3840593          	addi	a1,s0,-456
    80005ff0:	4505                	li	a0,1
    80005ff2:	ffffd097          	auipc	ra,0xffffd
    80005ff6:	188080e7          	jalr	392(ra) # 8000317a <argaddr>
    80005ffa:	0c054163          	bltz	a0,800060bc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ffe:	10000613          	li	a2,256
    80006002:	4581                	li	a1,0
    80006004:	e4040513          	addi	a0,s0,-448
    80006008:	ffffb097          	auipc	ra,0xffffb
    8000600c:	cd8080e7          	jalr	-808(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006010:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006014:	89a6                	mv	s3,s1
    80006016:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006018:	02000a13          	li	s4,32
    8000601c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006020:	00391513          	slli	a0,s2,0x3
    80006024:	e3040593          	addi	a1,s0,-464
    80006028:	e3843783          	ld	a5,-456(s0)
    8000602c:	953e                	add	a0,a0,a5
    8000602e:	ffffd097          	auipc	ra,0xffffd
    80006032:	090080e7          	jalr	144(ra) # 800030be <fetchaddr>
    80006036:	02054a63          	bltz	a0,8000606a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000603a:	e3043783          	ld	a5,-464(s0)
    8000603e:	c3b9                	beqz	a5,80006084 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	ab4080e7          	jalr	-1356(ra) # 80000af4 <kalloc>
    80006048:	85aa                	mv	a1,a0
    8000604a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000604e:	cd11                	beqz	a0,8000606a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006050:	6605                	lui	a2,0x1
    80006052:	e3043503          	ld	a0,-464(s0)
    80006056:	ffffd097          	auipc	ra,0xffffd
    8000605a:	0ba080e7          	jalr	186(ra) # 80003110 <fetchstr>
    8000605e:	00054663          	bltz	a0,8000606a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006062:	0905                	addi	s2,s2,1
    80006064:	09a1                	addi	s3,s3,8
    80006066:	fb491be3          	bne	s2,s4,8000601c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000606a:	10048913          	addi	s2,s1,256
    8000606e:	6088                	ld	a0,0(s1)
    80006070:	c529                	beqz	a0,800060ba <sys_exec+0xf8>
    kfree(argv[i]);
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	986080e7          	jalr	-1658(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000607a:	04a1                	addi	s1,s1,8
    8000607c:	ff2499e3          	bne	s1,s2,8000606e <sys_exec+0xac>
  return -1;
    80006080:	597d                	li	s2,-1
    80006082:	a82d                	j	800060bc <sys_exec+0xfa>
      argv[i] = 0;
    80006084:	0a8e                	slli	s5,s5,0x3
    80006086:	fc040793          	addi	a5,s0,-64
    8000608a:	9abe                	add	s5,s5,a5
    8000608c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006090:	e4040593          	addi	a1,s0,-448
    80006094:	f4040513          	addi	a0,s0,-192
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	194080e7          	jalr	404(ra) # 8000522c <exec>
    800060a0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060a2:	10048993          	addi	s3,s1,256
    800060a6:	6088                	ld	a0,0(s1)
    800060a8:	c911                	beqz	a0,800060bc <sys_exec+0xfa>
    kfree(argv[i]);
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	94e080e7          	jalr	-1714(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060b2:	04a1                	addi	s1,s1,8
    800060b4:	ff3499e3          	bne	s1,s3,800060a6 <sys_exec+0xe4>
    800060b8:	a011                	j	800060bc <sys_exec+0xfa>
  return -1;
    800060ba:	597d                	li	s2,-1
}
    800060bc:	854a                	mv	a0,s2
    800060be:	60be                	ld	ra,456(sp)
    800060c0:	641e                	ld	s0,448(sp)
    800060c2:	74fa                	ld	s1,440(sp)
    800060c4:	795a                	ld	s2,432(sp)
    800060c6:	79ba                	ld	s3,424(sp)
    800060c8:	7a1a                	ld	s4,416(sp)
    800060ca:	6afa                	ld	s5,408(sp)
    800060cc:	6179                	addi	sp,sp,464
    800060ce:	8082                	ret

00000000800060d0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060d0:	7139                	addi	sp,sp,-64
    800060d2:	fc06                	sd	ra,56(sp)
    800060d4:	f822                	sd	s0,48(sp)
    800060d6:	f426                	sd	s1,40(sp)
    800060d8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060da:	ffffc097          	auipc	ra,0xffffc
    800060de:	ad8080e7          	jalr	-1320(ra) # 80001bb2 <myproc>
    800060e2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060e4:	fd840593          	addi	a1,s0,-40
    800060e8:	4501                	li	a0,0
    800060ea:	ffffd097          	auipc	ra,0xffffd
    800060ee:	090080e7          	jalr	144(ra) # 8000317a <argaddr>
    return -1;
    800060f2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060f4:	0e054063          	bltz	a0,800061d4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060f8:	fc840593          	addi	a1,s0,-56
    800060fc:	fd040513          	addi	a0,s0,-48
    80006100:	fffff097          	auipc	ra,0xfffff
    80006104:	dfc080e7          	jalr	-516(ra) # 80004efc <pipealloc>
    return -1;
    80006108:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000610a:	0c054563          	bltz	a0,800061d4 <sys_pipe+0x104>
  fd0 = -1;
    8000610e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006112:	fd043503          	ld	a0,-48(s0)
    80006116:	fffff097          	auipc	ra,0xfffff
    8000611a:	508080e7          	jalr	1288(ra) # 8000561e <fdalloc>
    8000611e:	fca42223          	sw	a0,-60(s0)
    80006122:	08054c63          	bltz	a0,800061ba <sys_pipe+0xea>
    80006126:	fc843503          	ld	a0,-56(s0)
    8000612a:	fffff097          	auipc	ra,0xfffff
    8000612e:	4f4080e7          	jalr	1268(ra) # 8000561e <fdalloc>
    80006132:	fca42023          	sw	a0,-64(s0)
    80006136:	06054863          	bltz	a0,800061a6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000613a:	4691                	li	a3,4
    8000613c:	fc440613          	addi	a2,s0,-60
    80006140:	fd843583          	ld	a1,-40(s0)
    80006144:	78a8                	ld	a0,112(s1)
    80006146:	ffffb097          	auipc	ra,0xffffb
    8000614a:	534080e7          	jalr	1332(ra) # 8000167a <copyout>
    8000614e:	02054063          	bltz	a0,8000616e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006152:	4691                	li	a3,4
    80006154:	fc040613          	addi	a2,s0,-64
    80006158:	fd843583          	ld	a1,-40(s0)
    8000615c:	0591                	addi	a1,a1,4
    8000615e:	78a8                	ld	a0,112(s1)
    80006160:	ffffb097          	auipc	ra,0xffffb
    80006164:	51a080e7          	jalr	1306(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006168:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000616a:	06055563          	bgez	a0,800061d4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000616e:	fc442783          	lw	a5,-60(s0)
    80006172:	07f9                	addi	a5,a5,30
    80006174:	078e                	slli	a5,a5,0x3
    80006176:	97a6                	add	a5,a5,s1
    80006178:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000617c:	fc042503          	lw	a0,-64(s0)
    80006180:	0579                	addi	a0,a0,30
    80006182:	050e                	slli	a0,a0,0x3
    80006184:	9526                	add	a0,a0,s1
    80006186:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000618a:	fd043503          	ld	a0,-48(s0)
    8000618e:	fffff097          	auipc	ra,0xfffff
    80006192:	a3e080e7          	jalr	-1474(ra) # 80004bcc <fileclose>
    fileclose(wf);
    80006196:	fc843503          	ld	a0,-56(s0)
    8000619a:	fffff097          	auipc	ra,0xfffff
    8000619e:	a32080e7          	jalr	-1486(ra) # 80004bcc <fileclose>
    return -1;
    800061a2:	57fd                	li	a5,-1
    800061a4:	a805                	j	800061d4 <sys_pipe+0x104>
    if(fd0 >= 0)
    800061a6:	fc442783          	lw	a5,-60(s0)
    800061aa:	0007c863          	bltz	a5,800061ba <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061ae:	01e78513          	addi	a0,a5,30
    800061b2:	050e                	slli	a0,a0,0x3
    800061b4:	9526                	add	a0,a0,s1
    800061b6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061ba:	fd043503          	ld	a0,-48(s0)
    800061be:	fffff097          	auipc	ra,0xfffff
    800061c2:	a0e080e7          	jalr	-1522(ra) # 80004bcc <fileclose>
    fileclose(wf);
    800061c6:	fc843503          	ld	a0,-56(s0)
    800061ca:	fffff097          	auipc	ra,0xfffff
    800061ce:	a02080e7          	jalr	-1534(ra) # 80004bcc <fileclose>
    return -1;
    800061d2:	57fd                	li	a5,-1
}
    800061d4:	853e                	mv	a0,a5
    800061d6:	70e2                	ld	ra,56(sp)
    800061d8:	7442                	ld	s0,48(sp)
    800061da:	74a2                	ld	s1,40(sp)
    800061dc:	6121                	addi	sp,sp,64
    800061de:	8082                	ret

00000000800061e0 <kernelvec>:
    800061e0:	7111                	addi	sp,sp,-256
    800061e2:	e006                	sd	ra,0(sp)
    800061e4:	e40a                	sd	sp,8(sp)
    800061e6:	e80e                	sd	gp,16(sp)
    800061e8:	ec12                	sd	tp,24(sp)
    800061ea:	f016                	sd	t0,32(sp)
    800061ec:	f41a                	sd	t1,40(sp)
    800061ee:	f81e                	sd	t2,48(sp)
    800061f0:	fc22                	sd	s0,56(sp)
    800061f2:	e0a6                	sd	s1,64(sp)
    800061f4:	e4aa                	sd	a0,72(sp)
    800061f6:	e8ae                	sd	a1,80(sp)
    800061f8:	ecb2                	sd	a2,88(sp)
    800061fa:	f0b6                	sd	a3,96(sp)
    800061fc:	f4ba                	sd	a4,104(sp)
    800061fe:	f8be                	sd	a5,112(sp)
    80006200:	fcc2                	sd	a6,120(sp)
    80006202:	e146                	sd	a7,128(sp)
    80006204:	e54a                	sd	s2,136(sp)
    80006206:	e94e                	sd	s3,144(sp)
    80006208:	ed52                	sd	s4,152(sp)
    8000620a:	f156                	sd	s5,160(sp)
    8000620c:	f55a                	sd	s6,168(sp)
    8000620e:	f95e                	sd	s7,176(sp)
    80006210:	fd62                	sd	s8,184(sp)
    80006212:	e1e6                	sd	s9,192(sp)
    80006214:	e5ea                	sd	s10,200(sp)
    80006216:	e9ee                	sd	s11,208(sp)
    80006218:	edf2                	sd	t3,216(sp)
    8000621a:	f1f6                	sd	t4,224(sp)
    8000621c:	f5fa                	sd	t5,232(sp)
    8000621e:	f9fe                	sd	t6,240(sp)
    80006220:	d6bfc0ef          	jal	ra,80002f8a <kerneltrap>
    80006224:	6082                	ld	ra,0(sp)
    80006226:	6122                	ld	sp,8(sp)
    80006228:	61c2                	ld	gp,16(sp)
    8000622a:	7282                	ld	t0,32(sp)
    8000622c:	7322                	ld	t1,40(sp)
    8000622e:	73c2                	ld	t2,48(sp)
    80006230:	7462                	ld	s0,56(sp)
    80006232:	6486                	ld	s1,64(sp)
    80006234:	6526                	ld	a0,72(sp)
    80006236:	65c6                	ld	a1,80(sp)
    80006238:	6666                	ld	a2,88(sp)
    8000623a:	7686                	ld	a3,96(sp)
    8000623c:	7726                	ld	a4,104(sp)
    8000623e:	77c6                	ld	a5,112(sp)
    80006240:	7866                	ld	a6,120(sp)
    80006242:	688a                	ld	a7,128(sp)
    80006244:	692a                	ld	s2,136(sp)
    80006246:	69ca                	ld	s3,144(sp)
    80006248:	6a6a                	ld	s4,152(sp)
    8000624a:	7a8a                	ld	s5,160(sp)
    8000624c:	7b2a                	ld	s6,168(sp)
    8000624e:	7bca                	ld	s7,176(sp)
    80006250:	7c6a                	ld	s8,184(sp)
    80006252:	6c8e                	ld	s9,192(sp)
    80006254:	6d2e                	ld	s10,200(sp)
    80006256:	6dce                	ld	s11,208(sp)
    80006258:	6e6e                	ld	t3,216(sp)
    8000625a:	7e8e                	ld	t4,224(sp)
    8000625c:	7f2e                	ld	t5,232(sp)
    8000625e:	7fce                	ld	t6,240(sp)
    80006260:	6111                	addi	sp,sp,256
    80006262:	10200073          	sret
    80006266:	00000013          	nop
    8000626a:	00000013          	nop
    8000626e:	0001                	nop

0000000080006270 <timervec>:
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	e10c                	sd	a1,0(a0)
    80006276:	e510                	sd	a2,8(a0)
    80006278:	e914                	sd	a3,16(a0)
    8000627a:	6d0c                	ld	a1,24(a0)
    8000627c:	7110                	ld	a2,32(a0)
    8000627e:	6194                	ld	a3,0(a1)
    80006280:	96b2                	add	a3,a3,a2
    80006282:	e194                	sd	a3,0(a1)
    80006284:	4589                	li	a1,2
    80006286:	14459073          	csrw	sip,a1
    8000628a:	6914                	ld	a3,16(a0)
    8000628c:	6510                	ld	a2,8(a0)
    8000628e:	610c                	ld	a1,0(a0)
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	30200073          	mret
	...

000000008000629a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000629a:	1141                	addi	sp,sp,-16
    8000629c:	e422                	sd	s0,8(sp)
    8000629e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062a0:	0c0007b7          	lui	a5,0xc000
    800062a4:	4705                	li	a4,1
    800062a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062a8:	c3d8                	sw	a4,4(a5)
}
    800062aa:	6422                	ld	s0,8(sp)
    800062ac:	0141                	addi	sp,sp,16
    800062ae:	8082                	ret

00000000800062b0 <plicinithart>:

void
plicinithart(void)
{
    800062b0:	1141                	addi	sp,sp,-16
    800062b2:	e406                	sd	ra,8(sp)
    800062b4:	e022                	sd	s0,0(sp)
    800062b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	8ce080e7          	jalr	-1842(ra) # 80001b86 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062c0:	0085171b          	slliw	a4,a0,0x8
    800062c4:	0c0027b7          	lui	a5,0xc002
    800062c8:	97ba                	add	a5,a5,a4
    800062ca:	40200713          	li	a4,1026
    800062ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062d2:	00d5151b          	slliw	a0,a0,0xd
    800062d6:	0c2017b7          	lui	a5,0xc201
    800062da:	953e                	add	a0,a0,a5
    800062dc:	00052023          	sw	zero,0(a0)
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret

00000000800062e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062e8:	1141                	addi	sp,sp,-16
    800062ea:	e406                	sd	ra,8(sp)
    800062ec:	e022                	sd	s0,0(sp)
    800062ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062f0:	ffffc097          	auipc	ra,0xffffc
    800062f4:	896080e7          	jalr	-1898(ra) # 80001b86 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062f8:	00d5179b          	slliw	a5,a0,0xd
    800062fc:	0c201537          	lui	a0,0xc201
    80006300:	953e                	add	a0,a0,a5
  return irq;
}
    80006302:	4148                	lw	a0,4(a0)
    80006304:	60a2                	ld	ra,8(sp)
    80006306:	6402                	ld	s0,0(sp)
    80006308:	0141                	addi	sp,sp,16
    8000630a:	8082                	ret

000000008000630c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	1000                	addi	s0,sp,32
    80006316:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	86e080e7          	jalr	-1938(ra) # 80001b86 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006320:	00d5151b          	slliw	a0,a0,0xd
    80006324:	0c2017b7          	lui	a5,0xc201
    80006328:	97aa                	add	a5,a5,a0
    8000632a:	c3c4                	sw	s1,4(a5)
}
    8000632c:	60e2                	ld	ra,24(sp)
    8000632e:	6442                	ld	s0,16(sp)
    80006330:	64a2                	ld	s1,8(sp)
    80006332:	6105                	addi	sp,sp,32
    80006334:	8082                	ret

0000000080006336 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006336:	1141                	addi	sp,sp,-16
    80006338:	e406                	sd	ra,8(sp)
    8000633a:	e022                	sd	s0,0(sp)
    8000633c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000633e:	479d                	li	a5,7
    80006340:	06a7c963          	blt	a5,a0,800063b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006344:	0001d797          	auipc	a5,0x1d
    80006348:	cbc78793          	addi	a5,a5,-836 # 80023000 <disk>
    8000634c:	00a78733          	add	a4,a5,a0
    80006350:	6789                	lui	a5,0x2
    80006352:	97ba                	add	a5,a5,a4
    80006354:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006358:	e7ad                	bnez	a5,800063c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000635a:	00451793          	slli	a5,a0,0x4
    8000635e:	0001f717          	auipc	a4,0x1f
    80006362:	ca270713          	addi	a4,a4,-862 # 80025000 <disk+0x2000>
    80006366:	6314                	ld	a3,0(a4)
    80006368:	96be                	add	a3,a3,a5
    8000636a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000636e:	6314                	ld	a3,0(a4)
    80006370:	96be                	add	a3,a3,a5
    80006372:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006376:	6314                	ld	a3,0(a4)
    80006378:	96be                	add	a3,a3,a5
    8000637a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000637e:	6318                	ld	a4,0(a4)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006386:	0001d797          	auipc	a5,0x1d
    8000638a:	c7a78793          	addi	a5,a5,-902 # 80023000 <disk>
    8000638e:	97aa                	add	a5,a5,a0
    80006390:	6509                	lui	a0,0x2
    80006392:	953e                	add	a0,a0,a5
    80006394:	4785                	li	a5,1
    80006396:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000639a:	0001f517          	auipc	a0,0x1f
    8000639e:	c7e50513          	addi	a0,a0,-898 # 80025018 <disk+0x2018>
    800063a2:	ffffc097          	auipc	ra,0xffffc
    800063a6:	3f8080e7          	jalr	1016(ra) # 8000279a <wakeup>
}
    800063aa:	60a2                	ld	ra,8(sp)
    800063ac:	6402                	ld	s0,0(sp)
    800063ae:	0141                	addi	sp,sp,16
    800063b0:	8082                	ret
    panic("free_desc 1");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	56650513          	addi	a0,a0,1382 # 80008918 <syscalls+0x338>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	184080e7          	jalr	388(ra) # 8000053e <panic>
    panic("free_desc 2");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	56650513          	addi	a0,a0,1382 # 80008928 <syscalls+0x348>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	174080e7          	jalr	372(ra) # 8000053e <panic>

00000000800063d2 <virtio_disk_init>:
{
    800063d2:	1101                	addi	sp,sp,-32
    800063d4:	ec06                	sd	ra,24(sp)
    800063d6:	e822                	sd	s0,16(sp)
    800063d8:	e426                	sd	s1,8(sp)
    800063da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063dc:	00002597          	auipc	a1,0x2
    800063e0:	55c58593          	addi	a1,a1,1372 # 80008938 <syscalls+0x358>
    800063e4:	0001f517          	auipc	a0,0x1f
    800063e8:	d4450513          	addi	a0,a0,-700 # 80025128 <disk+0x2128>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	768080e7          	jalr	1896(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f4:	100017b7          	lui	a5,0x10001
    800063f8:	4398                	lw	a4,0(a5)
    800063fa:	2701                	sext.w	a4,a4
    800063fc:	747277b7          	lui	a5,0x74727
    80006400:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006404:	0ef71163          	bne	a4,a5,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006408:	100017b7          	lui	a5,0x10001
    8000640c:	43dc                	lw	a5,4(a5)
    8000640e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006410:	4705                	li	a4,1
    80006412:	0ce79a63          	bne	a5,a4,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006416:	100017b7          	lui	a5,0x10001
    8000641a:	479c                	lw	a5,8(a5)
    8000641c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000641e:	4709                	li	a4,2
    80006420:	0ce79363          	bne	a5,a4,800064e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006424:	100017b7          	lui	a5,0x10001
    80006428:	47d8                	lw	a4,12(a5)
    8000642a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000642c:	554d47b7          	lui	a5,0x554d4
    80006430:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006434:	0af71963          	bne	a4,a5,800064e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006438:	100017b7          	lui	a5,0x10001
    8000643c:	4705                	li	a4,1
    8000643e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006440:	470d                	li	a4,3
    80006442:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006444:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006446:	c7ffe737          	lui	a4,0xc7ffe
    8000644a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000644e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006450:	2701                	sext.w	a4,a4
    80006452:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006454:	472d                	li	a4,11
    80006456:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006458:	473d                	li	a4,15
    8000645a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000645c:	6705                	lui	a4,0x1
    8000645e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006460:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006464:	5bdc                	lw	a5,52(a5)
    80006466:	2781                	sext.w	a5,a5
  if(max == 0)
    80006468:	c7d9                	beqz	a5,800064f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000646a:	471d                	li	a4,7
    8000646c:	08f77d63          	bgeu	a4,a5,80006506 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006470:	100014b7          	lui	s1,0x10001
    80006474:	47a1                	li	a5,8
    80006476:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006478:	6609                	lui	a2,0x2
    8000647a:	4581                	li	a1,0
    8000647c:	0001d517          	auipc	a0,0x1d
    80006480:	b8450513          	addi	a0,a0,-1148 # 80023000 <disk>
    80006484:	ffffb097          	auipc	ra,0xffffb
    80006488:	85c080e7          	jalr	-1956(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000648c:	0001d717          	auipc	a4,0x1d
    80006490:	b7470713          	addi	a4,a4,-1164 # 80023000 <disk>
    80006494:	00c75793          	srli	a5,a4,0xc
    80006498:	2781                	sext.w	a5,a5
    8000649a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000649c:	0001f797          	auipc	a5,0x1f
    800064a0:	b6478793          	addi	a5,a5,-1180 # 80025000 <disk+0x2000>
    800064a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064a6:	0001d717          	auipc	a4,0x1d
    800064aa:	bda70713          	addi	a4,a4,-1062 # 80023080 <disk+0x80>
    800064ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064b0:	0001e717          	auipc	a4,0x1e
    800064b4:	b5070713          	addi	a4,a4,-1200 # 80024000 <disk+0x1000>
    800064b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064ba:	4705                	li	a4,1
    800064bc:	00e78c23          	sb	a4,24(a5)
    800064c0:	00e78ca3          	sb	a4,25(a5)
    800064c4:	00e78d23          	sb	a4,26(a5)
    800064c8:	00e78da3          	sb	a4,27(a5)
    800064cc:	00e78e23          	sb	a4,28(a5)
    800064d0:	00e78ea3          	sb	a4,29(a5)
    800064d4:	00e78f23          	sb	a4,30(a5)
    800064d8:	00e78fa3          	sb	a4,31(a5)
}
    800064dc:	60e2                	ld	ra,24(sp)
    800064de:	6442                	ld	s0,16(sp)
    800064e0:	64a2                	ld	s1,8(sp)
    800064e2:	6105                	addi	sp,sp,32
    800064e4:	8082                	ret
    panic("could not find virtio disk");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	46250513          	addi	a0,a0,1122 # 80008948 <syscalls+0x368>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	050080e7          	jalr	80(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	47250513          	addi	a0,a0,1138 # 80008968 <syscalls+0x388>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	040080e7          	jalr	64(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	48250513          	addi	a0,a0,1154 # 80008988 <syscalls+0x3a8>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	030080e7          	jalr	48(ra) # 8000053e <panic>

0000000080006516 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006516:	7159                	addi	sp,sp,-112
    80006518:	f486                	sd	ra,104(sp)
    8000651a:	f0a2                	sd	s0,96(sp)
    8000651c:	eca6                	sd	s1,88(sp)
    8000651e:	e8ca                	sd	s2,80(sp)
    80006520:	e4ce                	sd	s3,72(sp)
    80006522:	e0d2                	sd	s4,64(sp)
    80006524:	fc56                	sd	s5,56(sp)
    80006526:	f85a                	sd	s6,48(sp)
    80006528:	f45e                	sd	s7,40(sp)
    8000652a:	f062                	sd	s8,32(sp)
    8000652c:	ec66                	sd	s9,24(sp)
    8000652e:	e86a                	sd	s10,16(sp)
    80006530:	1880                	addi	s0,sp,112
    80006532:	892a                	mv	s2,a0
    80006534:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006536:	00c52c83          	lw	s9,12(a0)
    8000653a:	001c9c9b          	slliw	s9,s9,0x1
    8000653e:	1c82                	slli	s9,s9,0x20
    80006540:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006544:	0001f517          	auipc	a0,0x1f
    80006548:	be450513          	addi	a0,a0,-1052 # 80025128 <disk+0x2128>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	698080e7          	jalr	1688(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006554:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006556:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006558:	0001db97          	auipc	s7,0x1d
    8000655c:	aa8b8b93          	addi	s7,s7,-1368 # 80023000 <disk>
    80006560:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006562:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006564:	8a4e                	mv	s4,s3
    80006566:	a051                	j	800065ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006568:	00fb86b3          	add	a3,s7,a5
    8000656c:	96da                	add	a3,a3,s6
    8000656e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006572:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006574:	0207c563          	bltz	a5,8000659e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006578:	2485                	addiw	s1,s1,1
    8000657a:	0711                	addi	a4,a4,4
    8000657c:	25548063          	beq	s1,s5,800067bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006580:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006582:	0001f697          	auipc	a3,0x1f
    80006586:	a9668693          	addi	a3,a3,-1386 # 80025018 <disk+0x2018>
    8000658a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000658c:	0006c583          	lbu	a1,0(a3)
    80006590:	fde1                	bnez	a1,80006568 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006592:	2785                	addiw	a5,a5,1
    80006594:	0685                	addi	a3,a3,1
    80006596:	ff879be3          	bne	a5,s8,8000658c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000659a:	57fd                	li	a5,-1
    8000659c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000659e:	02905a63          	blez	s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a2:	f9042503          	lw	a0,-112(s0)
    800065a6:	00000097          	auipc	ra,0x0
    800065aa:	d90080e7          	jalr	-624(ra) # 80006336 <free_desc>
      for(int j = 0; j < i; j++)
    800065ae:	4785                	li	a5,1
    800065b0:	0297d163          	bge	a5,s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b4:	f9442503          	lw	a0,-108(s0)
    800065b8:	00000097          	auipc	ra,0x0
    800065bc:	d7e080e7          	jalr	-642(ra) # 80006336 <free_desc>
      for(int j = 0; j < i; j++)
    800065c0:	4789                	li	a5,2
    800065c2:	0097d863          	bge	a5,s1,800065d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065c6:	f9842503          	lw	a0,-104(s0)
    800065ca:	00000097          	auipc	ra,0x0
    800065ce:	d6c080e7          	jalr	-660(ra) # 80006336 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065d2:	0001f597          	auipc	a1,0x1f
    800065d6:	b5658593          	addi	a1,a1,-1194 # 80025128 <disk+0x2128>
    800065da:	0001f517          	auipc	a0,0x1f
    800065de:	a3e50513          	addi	a0,a0,-1474 # 80025018 <disk+0x2018>
    800065e2:	ffffc097          	auipc	ra,0xffffc
    800065e6:	012080e7          	jalr	18(ra) # 800025f4 <sleep>
  for(int i = 0; i < 3; i++){
    800065ea:	f9040713          	addi	a4,s0,-112
    800065ee:	84ce                	mv	s1,s3
    800065f0:	bf41                	j	80006580 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065f2:	20058713          	addi	a4,a1,512
    800065f6:	00471693          	slli	a3,a4,0x4
    800065fa:	0001d717          	auipc	a4,0x1d
    800065fe:	a0670713          	addi	a4,a4,-1530 # 80023000 <disk>
    80006602:	9736                	add	a4,a4,a3
    80006604:	4685                	li	a3,1
    80006606:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000660a:	20058713          	addi	a4,a1,512
    8000660e:	00471693          	slli	a3,a4,0x4
    80006612:	0001d717          	auipc	a4,0x1d
    80006616:	9ee70713          	addi	a4,a4,-1554 # 80023000 <disk>
    8000661a:	9736                	add	a4,a4,a3
    8000661c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006620:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006624:	7679                	lui	a2,0xffffe
    80006626:	963e                	add	a2,a2,a5
    80006628:	0001f697          	auipc	a3,0x1f
    8000662c:	9d868693          	addi	a3,a3,-1576 # 80025000 <disk+0x2000>
    80006630:	6298                	ld	a4,0(a3)
    80006632:	9732                	add	a4,a4,a2
    80006634:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006636:	6298                	ld	a4,0(a3)
    80006638:	9732                	add	a4,a4,a2
    8000663a:	4541                	li	a0,16
    8000663c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000663e:	6298                	ld	a4,0(a3)
    80006640:	9732                	add	a4,a4,a2
    80006642:	4505                	li	a0,1
    80006644:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006648:	f9442703          	lw	a4,-108(s0)
    8000664c:	6288                	ld	a0,0(a3)
    8000664e:	962a                	add	a2,a2,a0
    80006650:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006654:	0712                	slli	a4,a4,0x4
    80006656:	6290                	ld	a2,0(a3)
    80006658:	963a                	add	a2,a2,a4
    8000665a:	05890513          	addi	a0,s2,88
    8000665e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006660:	6294                	ld	a3,0(a3)
    80006662:	96ba                	add	a3,a3,a4
    80006664:	40000613          	li	a2,1024
    80006668:	c690                	sw	a2,8(a3)
  if(write)
    8000666a:	140d0063          	beqz	s10,800067aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000666e:	0001f697          	auipc	a3,0x1f
    80006672:	9926b683          	ld	a3,-1646(a3) # 80025000 <disk+0x2000>
    80006676:	96ba                	add	a3,a3,a4
    80006678:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000667c:	0001d817          	auipc	a6,0x1d
    80006680:	98480813          	addi	a6,a6,-1660 # 80023000 <disk>
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	97c50513          	addi	a0,a0,-1668 # 80025000 <disk+0x2000>
    8000668c:	6114                	ld	a3,0(a0)
    8000668e:	96ba                	add	a3,a3,a4
    80006690:	00c6d603          	lhu	a2,12(a3)
    80006694:	00166613          	ori	a2,a2,1
    80006698:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000669c:	f9842683          	lw	a3,-104(s0)
    800066a0:	6110                	ld	a2,0(a0)
    800066a2:	9732                	add	a4,a4,a2
    800066a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066a8:	20058613          	addi	a2,a1,512
    800066ac:	0612                	slli	a2,a2,0x4
    800066ae:	9642                	add	a2,a2,a6
    800066b0:	577d                	li	a4,-1
    800066b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066b6:	00469713          	slli	a4,a3,0x4
    800066ba:	6114                	ld	a3,0(a0)
    800066bc:	96ba                	add	a3,a3,a4
    800066be:	03078793          	addi	a5,a5,48
    800066c2:	97c2                	add	a5,a5,a6
    800066c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066c6:	611c                	ld	a5,0(a0)
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	4685                	li	a3,1
    800066cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ce:	611c                	ld	a5,0(a0)
    800066d0:	97ba                	add	a5,a5,a4
    800066d2:	4809                	li	a6,2
    800066d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066d8:	611c                	ld	a5,0(a0)
    800066da:	973e                	add	a4,a4,a5
    800066dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066e8:	6518                	ld	a4,8(a0)
    800066ea:	00275783          	lhu	a5,2(a4)
    800066ee:	8b9d                	andi	a5,a5,7
    800066f0:	0786                	slli	a5,a5,0x1
    800066f2:	97ba                	add	a5,a5,a4
    800066f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066fc:	6518                	ld	a4,8(a0)
    800066fe:	00275783          	lhu	a5,2(a4)
    80006702:	2785                	addiw	a5,a5,1
    80006704:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006708:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000670c:	100017b7          	lui	a5,0x10001
    80006710:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006714:	00492703          	lw	a4,4(s2)
    80006718:	4785                	li	a5,1
    8000671a:	02f71163          	bne	a4,a5,8000673c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000671e:	0001f997          	auipc	s3,0x1f
    80006722:	a0a98993          	addi	s3,s3,-1526 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006726:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006728:	85ce                	mv	a1,s3
    8000672a:	854a                	mv	a0,s2
    8000672c:	ffffc097          	auipc	ra,0xffffc
    80006730:	ec8080e7          	jalr	-312(ra) # 800025f4 <sleep>
  while(b->disk == 1) {
    80006734:	00492783          	lw	a5,4(s2)
    80006738:	fe9788e3          	beq	a5,s1,80006728 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000673c:	f9042903          	lw	s2,-112(s0)
    80006740:	20090793          	addi	a5,s2,512
    80006744:	00479713          	slli	a4,a5,0x4
    80006748:	0001d797          	auipc	a5,0x1d
    8000674c:	8b878793          	addi	a5,a5,-1864 # 80023000 <disk>
    80006750:	97ba                	add	a5,a5,a4
    80006752:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006756:	0001f997          	auipc	s3,0x1f
    8000675a:	8aa98993          	addi	s3,s3,-1878 # 80025000 <disk+0x2000>
    8000675e:	00491713          	slli	a4,s2,0x4
    80006762:	0009b783          	ld	a5,0(s3)
    80006766:	97ba                	add	a5,a5,a4
    80006768:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000676c:	854a                	mv	a0,s2
    8000676e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006772:	00000097          	auipc	ra,0x0
    80006776:	bc4080e7          	jalr	-1084(ra) # 80006336 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000677a:	8885                	andi	s1,s1,1
    8000677c:	f0ed                	bnez	s1,8000675e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000677e:	0001f517          	auipc	a0,0x1f
    80006782:	9aa50513          	addi	a0,a0,-1622 # 80025128 <disk+0x2128>
    80006786:	ffffa097          	auipc	ra,0xffffa
    8000678a:	512080e7          	jalr	1298(ra) # 80000c98 <release>
}
    8000678e:	70a6                	ld	ra,104(sp)
    80006790:	7406                	ld	s0,96(sp)
    80006792:	64e6                	ld	s1,88(sp)
    80006794:	6946                	ld	s2,80(sp)
    80006796:	69a6                	ld	s3,72(sp)
    80006798:	6a06                	ld	s4,64(sp)
    8000679a:	7ae2                	ld	s5,56(sp)
    8000679c:	7b42                	ld	s6,48(sp)
    8000679e:	7ba2                	ld	s7,40(sp)
    800067a0:	7c02                	ld	s8,32(sp)
    800067a2:	6ce2                	ld	s9,24(sp)
    800067a4:	6d42                	ld	s10,16(sp)
    800067a6:	6165                	addi	sp,sp,112
    800067a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067aa:	0001f697          	auipc	a3,0x1f
    800067ae:	8566b683          	ld	a3,-1962(a3) # 80025000 <disk+0x2000>
    800067b2:	96ba                	add	a3,a3,a4
    800067b4:	4609                	li	a2,2
    800067b6:	00c69623          	sh	a2,12(a3)
    800067ba:	b5c9                	j	8000667c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067bc:	f9042583          	lw	a1,-112(s0)
    800067c0:	20058793          	addi	a5,a1,512
    800067c4:	0792                	slli	a5,a5,0x4
    800067c6:	0001d517          	auipc	a0,0x1d
    800067ca:	8e250513          	addi	a0,a0,-1822 # 800230a8 <disk+0xa8>
    800067ce:	953e                	add	a0,a0,a5
  if(write)
    800067d0:	e20d11e3          	bnez	s10,800065f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067d4:	20058713          	addi	a4,a1,512
    800067d8:	00471693          	slli	a3,a4,0x4
    800067dc:	0001d717          	auipc	a4,0x1d
    800067e0:	82470713          	addi	a4,a4,-2012 # 80023000 <disk>
    800067e4:	9736                	add	a4,a4,a3
    800067e6:	0a072423          	sw	zero,168(a4)
    800067ea:	b505                	j	8000660a <virtio_disk_rw+0xf4>

00000000800067ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067ec:	1101                	addi	sp,sp,-32
    800067ee:	ec06                	sd	ra,24(sp)
    800067f0:	e822                	sd	s0,16(sp)
    800067f2:	e426                	sd	s1,8(sp)
    800067f4:	e04a                	sd	s2,0(sp)
    800067f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067f8:	0001f517          	auipc	a0,0x1f
    800067fc:	93050513          	addi	a0,a0,-1744 # 80025128 <disk+0x2128>
    80006800:	ffffa097          	auipc	ra,0xffffa
    80006804:	3e4080e7          	jalr	996(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006808:	10001737          	lui	a4,0x10001
    8000680c:	533c                	lw	a5,96(a4)
    8000680e:	8b8d                	andi	a5,a5,3
    80006810:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006812:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006816:	0001e797          	auipc	a5,0x1e
    8000681a:	7ea78793          	addi	a5,a5,2026 # 80025000 <disk+0x2000>
    8000681e:	6b94                	ld	a3,16(a5)
    80006820:	0207d703          	lhu	a4,32(a5)
    80006824:	0026d783          	lhu	a5,2(a3)
    80006828:	06f70163          	beq	a4,a5,8000688a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000682c:	0001c917          	auipc	s2,0x1c
    80006830:	7d490913          	addi	s2,s2,2004 # 80023000 <disk>
    80006834:	0001e497          	auipc	s1,0x1e
    80006838:	7cc48493          	addi	s1,s1,1996 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000683c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006840:	6898                	ld	a4,16(s1)
    80006842:	0204d783          	lhu	a5,32(s1)
    80006846:	8b9d                	andi	a5,a5,7
    80006848:	078e                	slli	a5,a5,0x3
    8000684a:	97ba                	add	a5,a5,a4
    8000684c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000684e:	20078713          	addi	a4,a5,512
    80006852:	0712                	slli	a4,a4,0x4
    80006854:	974a                	add	a4,a4,s2
    80006856:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000685a:	e731                	bnez	a4,800068a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000685c:	20078793          	addi	a5,a5,512
    80006860:	0792                	slli	a5,a5,0x4
    80006862:	97ca                	add	a5,a5,s2
    80006864:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006866:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000686a:	ffffc097          	auipc	ra,0xffffc
    8000686e:	f30080e7          	jalr	-208(ra) # 8000279a <wakeup>

    disk.used_idx += 1;
    80006872:	0204d783          	lhu	a5,32(s1)
    80006876:	2785                	addiw	a5,a5,1
    80006878:	17c2                	slli	a5,a5,0x30
    8000687a:	93c1                	srli	a5,a5,0x30
    8000687c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006880:	6898                	ld	a4,16(s1)
    80006882:	00275703          	lhu	a4,2(a4)
    80006886:	faf71be3          	bne	a4,a5,8000683c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000688a:	0001f517          	auipc	a0,0x1f
    8000688e:	89e50513          	addi	a0,a0,-1890 # 80025128 <disk+0x2128>
    80006892:	ffffa097          	auipc	ra,0xffffa
    80006896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000689a:	60e2                	ld	ra,24(sp)
    8000689c:	6442                	ld	s0,16(sp)
    8000689e:	64a2                	ld	s1,8(sp)
    800068a0:	6902                	ld	s2,0(sp)
    800068a2:	6105                	addi	sp,sp,32
    800068a4:	8082                	ret
      panic("virtio_disk_intr status");
    800068a6:	00002517          	auipc	a0,0x2
    800068aa:	10250513          	addi	a0,a0,258 # 800089a8 <syscalls+0x3c8>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	c90080e7          	jalr	-880(ra) # 8000053e <panic>
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
