(load "lightsource.l")
(load "pressure-marker.l")
(load "../urdf/umoru.l")
(ros::roseus-add-msgs "std_msgs")
(ros::roseus-add-msgs "rosgraph_msgs")

(defclass ros-visualize-pressure
  :slots (pm topic-tb))

(defmethod ros-visualize-pressure
  (:init
    ()
    (unless (boundp '*irtviewer*)
      (make-irtviewer))
    ;; (send *irtviewer* :viewer :viewing :look #f(6006.5 2694.47 2523.4) #f(98.9507 64.2593 669.127) #f(0.0 0.0 1.0))
    ;; (send *irtviewer* :viewer :viewing :look #f(7367.19 -6884.29 5935.51) #f(-173.266 147.302 682.164) #f(0.0 0.0 1.0))
    (send *irtviewer* :viewer :viewing :look #f(1883.31 -2032.93 2342.38) #f(341.634 434.265 923.437) #f(0.0 0.0 1.0))
    ;; (send *irtviewer* :change-background #f(0.5 0.5 0.5))
    (umoru)
    (setq pm (instance pressure-marker :init *umoru*))

    (send (send *umoru* :r_shoulder_joint) :max-angle 90)
    (send (send *umoru* :l_elbow_joint0) :max-angle 30.0)
    (send (send *umoru* :l_elbow_joint1) :max-angle 30.0)
    (send (send *umoru* :l_elbow_joint2) :max-angle 30.0)
    (send (send *umoru* :l_elbow_joint3) :max-angle 30.0)

    (setq topic-tb (make-hash-table :test #'eq))
    (sethash 47 topic-tb "l_elbow_link0")
    (sethash 49 topic-tb "l_elbow_link1")
    (sethash 51 topic-tb "l_elbow_link2")
    (sethash 53 topic-tb "l_elbow_link3")
    (dolist (id (list 47 49 51 53))
      (ros::subscribe (format nil "scaled_pressure/~A" id) std_msgs::Float32 `(lambda-closure nil 0 0 (msg) (send ,self :pressure-cb msg ,id))))
    (ros::subscribe "rosout" rosgraph_msgs::Log #'send self :rosout-cb)
    )

  (:viewer-update
    ()
    (let ((l (send pm :marker-object)))
      (send *irtviewer* :objects (append (list *umoru*) l))
      (send *irtviewer* :draw-objects)))

  ;; (:pressure-to-alpha
  ;;   (val)
  ;;   (min 1.0 (* val 1.6)))

  (:pressure-to-alpha
    (val)
    (let* ((min-p -0.1)
           (max-p 0.8)
           (gamma 0.7) ; この値を0.4などに変えて調整
           (norm-val (/ (- val min-p) (- max-p min-p))))
                                        ; norm-valが0未満にならないようにmaxでクリップ
      (expt (max 0 norm-val) gamma)))

;; (:pressure-to-color
;;   (val)
;;   (let* ((min-p -0.1)
;;          (max-p 0.8)
;;          ;; valを0.0〜1.0の範囲に正規化・クランプする
;;          (norm-val (max 0.0 (min 1.0 (/ (- val min-p) (- max-p min-p))))))
;;     (cond
;;       ;; 0.0〜0.5の範囲: 緑 (0, 1, 0) から 黄 (1, 1, 0) へ
;;       ((< norm-val 0.5)
;;        (float-vector (* norm-val 2.0) ; R: 0.0 -> 1.0
;;              1.0             ; G: 1.0 (固定)
;;              0.0))           ; B: 0.0 (固定)

;;       ;; 0.5〜1.0の範囲: 黄 (1, 1, 0) から 赤 (1, 0, 0) へ
;;       (t
;;        (float-vector 1.0                                ; R: 1.0 (固定)
;;              (- 1.0 (* (- norm-val 0.5) 2.0)) ; G: 1.0 -> 0.0
;;              0.0)))))                          ; B: 0.0 (固定)

(:pressure-to-color
  (val)
  (let* ((min-p -0.1)
         (max-p 0.8)
         ;; valを0.0〜1.0の範囲に正規化・クランプする
         (norm-val (max 0.0 (min 1.0 (/ (- val min-p) (- max-p min-p))))))
    (cond
      ;; 0.0〜0.5の範囲: シアン (0, 1, 1) から 緑 (0, 1, 0) へ
      ((< norm-val 0.5)
       (float-vector 0.0                              ; R: 0.0 (固定)
             (+ 0.5 norm-val)                ; G: 0.5 -> 1.0
             (- 0.5 norm-val)))               ; B: 0.5 -> 0.0

      ;; 0.5〜1.0の範囲: 緑 (0, 1, 0) から 黄 (1, 1, 0) へ
      (t
       (float-vector (* (- norm-val 0.5) 2.0) ; R: 0.0 -> 1.0
             1.0                      ; G: 1.0 (固定)
             0.0)))))                 ; B: 0.0 (固定)

  (:pressure-cb
   (msg id)
   (setq name (gethash id topic-tb))
   ;; (send pm :set-color name :a (send self :pressure-to-alpha (send msg :data)))
   (send pm :set-color name :rgb (send self :pressure-to-color (send msg :data)))
   )

  (:rosout-cb
   (msg)
   (print (send msg :msg))
   (when (string-equal (send msg :msg) "init pose start")
     (let ((steps 30)
           (target-angle 90.0))
       (dotimes (i (1+ steps))
         (let ((current-angle (* target-angle (/ (float i) steps))))
           (send (send *umoru* :l_shoulder_joint) :joint-angle (- current-angle))
           (send (send *umoru* :r_shoulder_joint) :joint-angle current-angle)
           (send *vis* :viewer-update)
           (ros::duration-sleep 0.05)
           )))
     )
   (when (string-equal (send msg :msg) "reset pose start")
     (let ((steps 30)
           (target-angle 90.0))
       (dotimes (i (1+ steps))
         (let ((current-angle (* target-angle (/ (float i) steps))))
           (send (send *umoru* :l_shoulder_joint) :joint-angle (+ -90.0 current-angle))
           (send (send *umoru* :r_shoulder_joint) :joint-angle (- 90.0 current-angle))
           (send *vis* :viewer-update)
           (ros::duration-sleep 0.05)
           )))
     )
   (when (string-equal (send msg :msg) "hug start")
     (let ((steps 34)
           (target-angle 25.0))
       (dotimes (i (1+ steps))
         (let ((current-angle (* target-angle (/ (float i) steps))))
           (send (send *umoru* :l_elbow_joint0) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint1) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint2) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint3) :joint-angle current-angle)
           (send *vis* :viewer-update)
           (ros::duration-sleep 0.05)
           ))
       )
     )
   (when (string-equal (send msg :msg) "extend start")
          (let ((steps 34)
           (target-angle 25.0))
       (dotimes (i (1+ steps))
         (let ((current-angle (- target-angle (* target-angle (/ (float i) steps)))))
           (send (send *umoru* :l_elbow_joint0) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint1) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint2) :joint-angle current-angle)
           (send (send *umoru* :l_elbow_joint3) :joint-angle current-angle)
           (send *vis* :viewer-update)
           (ros::duration-sleep 0.05)
           ))
       )
     )
   )
  )


(ros::roseus "visualize_marker")
(setq *vis* (instance ros-visualize-pressure :init))
(ros::rate 40)
(do-until-key
 (ros::spin-once)
 (send *vis* :viewer-update)
 (x::window-main-one)
 (ros::sleep)
 )

;; (defun test
;;   ()
;;   (let ((size-list #f(0 0 0 0))
;;         (add-list (list t t t t)))
;;     ;; (send *irtviewer* :logging :start)
;;     (dotimes (i 15)
;;       (setf (elt size-list 0) (* i 0.1))
;;       (setf (elt size-list 1) (* (max 0 (- i 5)) 0.1))
;;       (setf (elt size-list 2) (* (max 0 (- i 10)) 0.1))
;;       (setf (elt size-list 3) (* (max 0 (- i 15)) 0.1))
;;       (dotimes (j 4)
;;         (send *pm* :change-size (format nil "r_elbow_link~A" j) (elt size-list j)))
;;       )
;;     (dotimes (i 145)
;;       (dotimes (j 4)
;;         (if (elt add-list j)
;;             (setq new-size (+ (elt size-list j) 0.1))
;;             (setq new-size (- (elt size-list j) 0.1)))
;;         (when (>= new-size 2.0)
;;           (setf (elt add-list j) nil))
;;         (when (<= new-size 0)
;;           (setf (elt add-list j) t))
;;         (setf (elt size-list j) new-size)
;;         (send *pm* :change-size (format nil "r_elbow_link~A" j) (elt size-list j)))
;;       (viewer-update)
;;       ))
;;   ;; (send *irtviewer* :logging :stop)
;;   ;; (send *irtviewer* :save-animgif :transparent nil)
;;   )
