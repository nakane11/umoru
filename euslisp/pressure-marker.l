(load "barrel.l")

(defclass pressure-marker
  :slots (robot-model marker-list))

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
    (mapcar #'cdr marker-list))

  (:make-marker
    (coords size color)
    (setq barrel (+ 45 (* 25 (min 1.0 size))))
    (setq arc (- 120 (* 80 (min 1 (max 0 (- size 1))))));;1.0~2.0
    (setq cyl (make-barrel 75 barrel arc))
    (send cyl :newcoords coords)
    (send cyl :set-color color)
    (send cyl :put :color color)
    cyl)

  (:initialize-markers
    ()
    (setq marker-list nil)
    (dolist (lk (send robot-model :links))
      (when (and (substringp "elbow" (send lk :name))
                 (not (substringp "4" (send lk :name))))
        (let* ((coords (send lk :copy-worldcoords))
               (cyl (send self :make-marker coords 0 #f(0.65 0.65 1.0 0.6))))
          (send cyl :rotate (deg2rad 90) :y)
          (send cyl :translate (float-vector 45 0 0) :world)
          (send lk :assoc cyl)
          (setq marker-list (acons (send lk :name) cyl marker-list)))
        )))

  (:change-size
    (name size)
    (let ((pair (assoc name marker-list :test #'string-equal)))
      (when pair
        (let* ((old-marker (cdr pair))
               (color (send old-marker :get :color))
               (coords (send old-marker :worldcoords))
               (link (send self :get-link-by-name name))
               (new-cyl (send self :make-marker coords size color)))
          ;; update assoc
          (when link
            (send link :dissoc old-marker)
            (send link :assoc new-cyl))
          ;; update marker-list
          (setf (cdr pair) new-cyl)
          ))))

  (:set-color
    (name &key rgb a)
    (let ((target (cdr (assoc name marker-list :test #'string-equal))))
      (when target
        (let ((new-color (copy-seq (send target :get :color))))
          (when rgb
            (replace new-color rgb :end1 3))
          (when a
            (setf (elt new-color 3) a))
          (send target :set-color new-color)
          (send target :put :color new-color)))))
  )
