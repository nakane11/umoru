(load "barrel.l")

(defclass pressure-marker
  :slots (robot-model marker-list))

(defmethod pressure-marker
  (:init
    (robot)
    (setq robot-model robot)
    (send self :initialize-markers))

  (:initialize-markers
    ()
    (setq marker-list nil)
    (dolist (lk (send robot-model :links))
      (when (and (substringp "elbow" (send lk :name))
                 (not (substringp "4" (send lk :name))))
        (setq coords (send lk :copy-worldcoords))
        (setq cyl (make-barrel 75 40 120))
        (send cyl :newcoords coords)
        (send cyl :rotate (deg2rad 90) :y)
        (send cyl :translate (float-vector 45 0 0) :world)
        (send cyl :set-color #f(0 0.2 0.7 0.7))
        (send lk :assoc cyl)
        (setq marker-list (acons (send lk :name) cyl marker-list)))
      ))

  (:marker-object
    ()
    (mapcar #'cdr marker-list))

  (:set-color
    (name rgb &optional (a 1.0))
    (setq target (cdr (assoc name marker-list :test #'string-equal)))
    (send target :set-color rgb a))

  )
