;; (load "barrel.l")
(load "airbag.l")

(defclass pressure-marker
  :slots (robot-model marker-tb))

(defmethod pressure-marker
  (:init
    (robot)
    (setq robot-model robot)
    (send self :initialize-markers))

  (:get-link-by-name
    (name)
    (dolist (lk (send robot-model :links))
      (when (string-equal (send lk :name) name)
        (return-from :get-link-by-name lk)))
    nil)

  (:marker-object
    ()
    (let ((value-list nil))
      (maphash #'(lambda (key val) (push val value-list))
               marker-tb)
      (nreverse value-list)))

  (:make-marker
    (coords size color)
    ;; (setq barrel (+ 45 (* 25 (min 1.0 size))))
    ;; (setq arc (- 120 (* 80 (min 1 (max 0 (- size 1))))));;1.0~2.0
    ;; (setq cyl (make-barrel 75 barrel arc))
    (setq cyl (make-airbag))
    (send cyl :newcoords coords)
    ;; (send cyl :rotate (deg2rad 90) :x :world)
    (send cyl :set-color color)
    cyl)

  (:initialize-markers
    ()
    (setq marker-tb (make-hash-table :test #'string-equal))
    (dolist (lk (send robot-model :links))
      (when (and (substringp "elbow" (send lk :name))
                 (not (substringp "4" (send lk :name))))
        (let* ((coords (send lk :copy-worldcoords))
               (cyl (send self :make-marker coords 0 #f(0.0 0.5 0.5 0.7))))
          (send cyl :rotate (deg2rad 90) :y)
          (when (substringp "r_" (send lk :name))
            (send cyl :translate (float-vector 0 15 0))
            (send cyl :rotate (deg2rad 90) :z))
          (when (substringp "l_" (send lk :name))
            (send cyl :translate (float-vector 0 -15 0))
            (send cyl :rotate (deg2rad -90) :z))
          (send cyl :translate (float-vector 45 0 0) :world)
          (send lk :assoc cyl)
          (sethash (send lk :name) marker-tb cyl)
          )
        ))
    ;; (send self :set-color "l_elbow_link0" :rgb (float-vector (/ 247.0 255) (/ 150.0 255) (/ 70.0 255)))
    ;; (send self :set-color "l_elbow_link1" :rgb (float-vector (/ 75.0 255) (/ 172.0 255) (/ 198.0 255)))
    ;; (send self :set-color "l_elbow_link2" :rgb (float-vector (/ 128.0 255) (/ 100.0 255) (/ 162.0 255)))
    ;; (send self :set-color "l_elbow_link3" :rgb (float-vector (/ 155.0 255) (/ 187.0 255) (/ 89.0 255)))
    )

  (:change-size
    (name size)
    (let ((old-cyl (gethash name marker-tb)))
      (when old-cyl
        (let* ((color (send old-cyl :get :face-color))
               (coords (send old-cyl :worldcoords))
               (link (send self :get-link-by-name name))
               (new-cyl (send self :make-marker coords size color)))
          ;; update assoc
          (when link
            (send link :dissoc old-cyl)
            (send link :assoc new-cyl))
          ;; update marker-tb
          (setf (gethash name marker-tb) new-cyl)
          ))))

  (:set-color
    (name &key rgb a)
    (let ((target (gethash name marker-tb)))
      (when target
        (let ((new-color (copy-seq (send target :get :face-color))))
          (when rgb
            (replace new-color rgb :end1 3))
          (when a
            (setf (elt new-color 3) a))
          (send target :set-color new-color)
          ))))
  )
