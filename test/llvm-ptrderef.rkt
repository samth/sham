#lang racket
(require "../llvm/ffi/all.rkt")
(require ffi/unsafe)

(LLVMInitializeX86Target)
(LLVMInitializeX86AsmParser)
(LLVMInitializeX86AsmPrinter)
(define module (LLVMModuleCreateWithName "test_module"))


(define ptr-i32 (LLVMPointerType (LLVMInt32Type) 0))
(define param-types (list ptr-i32 (LLVMInt32Type)))
(define ret-type (LLVMFunctionType (LLVMInt32Type) param-types #f))
(define indx (LLVMAddFunction module "indx" ret-type))

(define entry-block (LLVMAppendBasicBlock indx "entry"))

(define builder (LLVMCreateBuilder))

(LLVMPositionBuilderAtEnd builder entry-block)
(define tmpptr (LLVMBuildGEP builder
                          (LLVMGetParam indx 0)
                          (list(LLVMGetParam indx 1))
                          "tmpptr"))
(define tmp (LLVMBuildLoad builder tmpptr "tmp"))
(define ret (LLVMBuildRet builder tmp))

(define verif (LLVMVerifyModule module 'LLVMPrintMessageAction #f))



(define args (list (LLVMCreateGenericValueOfPointer (list->cblock '(1 2 3 4 5) _int32))
                  (LLVMCreateGenericValueOfInt (LLVMInt32Type) 3 #f)))

(define-values (engine status err) (LLVMCreateExecutionEngineForModule module))
(define fptr (LLVMGetFunctionAddress engine "indx"))
(define res (LLVMRunFunction engine indx args))
(printf "result: ~a\n" (LLVMGenericValueToInt res #f))


;; (LLVMDisposeBuilder builder)
;; (LLVMDisposeModule module)

(define fpm (LLVMCreateFunctionPassManagerForModule module))
(define fbpm (LLVMPassManagerBuilderCreate))
(LLVMPassManagerBuilderSetOptLevel fbpm 3)
(LLVMPassManagerBuilderPopulateFunctionPassManager fbpm fpm)
(LLVMPassManagerBuilderDispose fbpm)
(define change (LLVMRunFunctionPassManager fpm indx))
(printf "change: ~a" change)
(LLVMDumpModule module)