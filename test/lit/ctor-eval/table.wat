;; NOTE: Assertions have been generated by update_lit_checks.py --all-items and should not be edited.
;; RUN: wasm-ctor-eval %s --ctors=run --kept-exports=run --quiet -all -S -o - | filecheck %s

(module
 ;; CHECK:      (type $none_=>_none (func))
 (type $none_=>_none (func))

 ;; CHECK:      (table $0 22 funcref)
 (table $0 22 funcref)

 (elem (i32.const 0) $nop)

 ;; CHECK:      (elem (i32.const 0) $nop)

 ;; CHECK:      (elem declare func $trap)

 ;; CHECK:      (export "run" (func $run_0))
 (export "run" (func $run))

 (func $run (type $none_=>_none)
  ;; This call can be evalled away (it does nothing as the target is a nop).
  (call_indirect $0 (type $none_=>_none)
   (i32.const 0)
  )

  ;; We stop at this table.set, which is not handled yet. The call after it
  ;; should also remain where it is. Note that if we just ignore the set then
  ;; we'd call the wrong function later (we should call $trap, not $nop).
  (table.set $0
   (i32.const 0)
   (ref.func $trap)
  )
  (call_indirect $0 (type $none_=>_none)
   (i32.const 0)
  )
 )

 ;; CHECK:      (func $nop (type $none_=>_none)
 ;; CHECK-NEXT:  (nop)
 ;; CHECK-NEXT: )
 (func $nop (type $none_=>_none)
  (nop)
 )

 ;; CHECK:      (func $trap (type $none_=>_none)
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT: )
 (func $trap (type $none_=>_none)
  (unreachable)
 )
)
;; CHECK:      (func $run_0 (type $none_=>_none)
;; CHECK-NEXT:  (table.set $0
;; CHECK-NEXT:   (i32.const 0)
;; CHECK-NEXT:   (ref.func $trap)
;; CHECK-NEXT:  )
;; CHECK-NEXT:  (call_indirect $0 (type $none_=>_none)
;; CHECK-NEXT:   (i32.const 0)
;; CHECK-NEXT:  )
;; CHECK-NEXT: )