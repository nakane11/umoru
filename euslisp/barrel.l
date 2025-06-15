(defun generate-barrel-profile-by-arc-radius (height barrel-radius arc-radius &key (arc-segments 20))
  (when (< arc-radius (/ height 2.0))
    (error ":arc-radius must be greater than or equal to half the height."))

  (let* ((h/2 (/ height 2.0))
         (arc-center-x (- barrel-radius (sqrt (- (* arc-radius arc-radius) (* h/2 h/2)))))
         (start-angle (atan (- h/2) (- barrel-radius arc-center-x)))
         (end-angle (atan h/2 (- barrel-radius arc-center-x)))
         (angle-step (/ (- end-angle start-angle) arc-segments))
         points)

    (dotimes (i (1+ arc-segments))
      (let* ((current-angle (+ start-angle (* i angle-step)))
             (x (+ arc-center-x (* arc-radius (cos current-angle))))
             (z (* arc-radius (sin current-angle))))
        (push (float-vector x 0 z) points)))

    (nreverse points)))

(defun make-barrel (height barrel-radius arc-radius &key (arc-segments 20))
  (setq barrel-points (generate-barrel-profile-by-arc-radius height barrel-radius arc-radius :arc-segments arc-segments))
  (make-solid-of-revolution barrel-points))

;; (defun make-hollow-barrel (height barrel-radius arc-radius hole-radius &key (arc-segments 20))
;;   (let ((solid-barrel (make-barrel height barrel-radius arc-radius :arc-segments arc-segments))
;;         (hole (make-cylinder hole-radius (+ height 20))))
;;     (send hole :translate (float-vector 0 0 (- -10 (/ height 2))))
;;     (body- solid-barrel hole)))
