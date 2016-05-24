Number.prototype.mod = (n) ->
    ((this%n)+n)%n

rand = (min, max) -> Math.floor Math.random()*(max - min + 1) + min

r = (a) -> Math.sqrt a / Math.PI

yShift = 550
instanceHeight = 50
instanceScale = 1

class Color
    constructor: (@h,@s,@l,@a) ->
        # nop
    @rand: -> new Color rand(0, 360), 100, rand(20, 40), 0.8
    string: -> "hsla("+@h+","+@s+"%,"+@l+"%,"+@a+")"
    gray: -> new Color @h, 0, @l, @a

class Instance
    constructor: (circles) ->
        @circles = circles ? []
        @visible = false
        @mina = 0

    clone: ->
        i = new Instance
        for circle in @circles
            c = new Circle circle.a
            c.color = circle.color
            i.push c
        i

    @rand: -> new Instance(new Circle rand(10, 2000)**5 for [0...rand(3,100)])

    length: -> @circles.length

    sum: (from=0, to=-1) -> @circles[from..to].reduce ((a, b) -> a + b.a), 0

    width: -> canvas.width

    height: -> @sum()/@width()

    push: (c) -> @circles.push c

    normalize: (target_sum) ->
        current_sum = @sum()
        for circle in @circles
            circle.a *= target_sum/current_sum

    draw: ->
        for circle in @circles
            circle.draw(circle.pos)
    tikz: ->
        text = ""
        for circle in @circles
            text += circle.tikz()
        return text

    draw3: ->
        x = 0
        for circle in @circles
            if @visible
                ctx.fillStyle = circle.color.string()
            else
                ctx.fillStyle = circle.color.gray().string()

            w = circle.a/@sum()*@width()
            ctx.fillRect(x, 0, w, instanceHeight*instanceScale)
            x += w

    clearMinA: -> circle.mina = 0 for circle in @circles

    sort: ->
        @sortedCircles = @circles.slice().sort((a, b) ->
            b.a - (a.a)
        )

    # traditional greedy split. assumption: instance is sorted.
    split: (f = [1,1]) ->
        circs = @sortedCircles ? @circles
        n = f.length
        buckets = Array.apply(null, Array(n)).map(->
            new Instance
        )
        j = 0
        while j < circs.length
            x = circs[j].a
            minFill = 999999999999999 # TODO
            minI = 0
            i = 0
            while i < n
                sum = buckets[i].sum()
                if sum / f[i] < minFill
                    minFill = sum / f[i]
                    minI = i
                i++
            buckets[minI].push circs[j]
            j++
        minFill = 999999999999999 # TODO
        minI = 0
        i = 0
        while i < n
            sum = buckets[i].sum()
            if sum / f[i] < minFill
                minFill = sum / f[i]
                minI = i
            i++
        rad = buckets[minI].sum() / f[minI]
        i = 0
        while i < f.length
            mina = buckets[i].sum() - (f[i] * rad)
            if 2*mina > buckets[i].sum() and object != "circle"
                mina = buckets[i].sum()
            buckets[i].mina = Math.max(mina, @mina)
            j = 0
            while j < buckets[i].length()
                if mina > buckets[i].circles[j].mina or buckets[i].circles[j].mina == undefined
                    buckets[i].circles[j].mina = mina
                j++
            i++
        buckets

    # kP sorted split. assumption: instance is sorted.
    split3: (f) ->
        circs = @sortedCircles ? @circles
        totalf = f.reduce((a, b) ->
            a + b
        )
        total = circs.sum()
        n = f.length
        buckets = Array.apply(null, Array(n)).map(->
            new Instance
        )
        i = 0
        nowa = false
        if f[0] < f[1]
            i = 0
        else
            i = 1
        j = 0
        while j < circs.length
            if buckets[i].sum() >= f[i] / totalf * total
                i = (i + 1) % n
            buckets[i].push circs[j]
            j++
        buckets

    # cut and take current into first. assumption: instance is sorted.
    split2: (f) ->
        circs = @sortedCircles ? @circles
        totalf = f.reduce((a, b) ->
            a + b
        )
        total = circs.sum()
        n = f.length
        buckets = Array.apply(null, Array(n)).map(->
            new Instance
        )
        i = 0
        for circle in circs
            if i == 0 and buckets[i].sum()+circle.a/2 > f[i]/totalf*total
                i++
            buckets[i].push circle
        #console.log(f)
        #console.log(circs.length)
        #console.log(buckets[1].length())
        #console.log("")
        #return [new Instance([new Circle(1)]), new Instance([new Circle(1)])]
        buckets

class Circle
    constructor: (@a) ->
        @mina = 0
        @color = Color.rand()
        @pos = [0,0]
        @rot = 0
        @flip = false
        @vertices = []

    draw: (pos) ->
        #if shape.gamma() < Math.PI/2
        #    return

        ctx.fillStyle = @color.string()
        ctx.beginPath()

        switch object
            when "circle"
                ctx.arc @pos[0], @pos[1], r(@a), 0, 2 * Math.PI
            when "octagon"
                l = r(@a)/Math.cos(Math.PI/8)
                p = @pos.add([l,0].rot(Math.PI/8+@rot))
                ctx.moveTo p[0], p[1]
                for i in [1..7]
                    pp = @pos.add([l,0].rot(Math.PI/8+i*Math.PI/4+@rot))
                    ctx.lineTo pp[0], pp[1]
                ctx.lineTo p[0], p[1]
            when "square"
                l = (1+Math.sqrt(2))*r(@a)/2
                x = r(@a)/2*(Math.sqrt(2)-1)
                pp = @pos.add([0,-x].rot(@rot)).add([l,0].rot(@rot))
                ctx.moveTo pp[0], pp[1]
                for ang in [Math.PI/2, Math.PI, Math.PI/2*3]
                    pp = @pos.add([0,-x].rot(@rot)).add([l,0].rot(ang+@rot))
                    ctx.lineTo pp[0], pp[1]
            when "ruby"
                t = new Triangle([
                    @pos.add([0,-Math.sqrt(2)*r(@a)].rot(@rot))
                    @pos.add([-(Math.sqrt(2)+1)*r(@a),r(@a)].rot(@rot))
                    @pos.add([(Math.sqrt(2)+1)*r(@a),r(@a)].rot(@rot))
                ])
                t.mina = @a
                t.color = @color
                t.flip = @flip
                t.rotateLargestAngleUp()
                t.drawShape()

        ctx.fill()

        if false#@mina
            c = new Circle @mina
            c.pos = @pos
            c.rot = @rot
            c.flip = @flip
            c.color = @color
            c.draw()
    tikz: ->
        text = "\\draw[filled]"
        switch object
            when "circle"
                text += " ("+@pos[0]+","+(-@pos[1])+") circle ("+r(@a)+");\n"
            when "octagon"
                l = r(@a)/Math.cos(Math.PI/8)
                p = @pos.add([l,0].rot(Math.PI/8+@rot))
                text += " ("+p[0]+","+(-p[1])+")"
                for i in [1..7]
                    pp = @pos.add([l,0].rot(Math.PI/8+i*Math.PI/4+@rot))
                    text += " -- ("+pp[0]+","+(-pp[1])+")"
                text += " -- cycle;\n"
            when "square"
                l = (1+Math.sqrt(2))*r(@a)/2
                x = r(@a)/2*(Math.sqrt(2)-1)
                pp = @pos.add([0,-x].rot(@rot)).add([l,0].rot(@rot))
                text += " ("+pp[0]+","+(-pp[1])+")"
                for ang in [Math.PI/2, Math.PI, Math.PI/2*3]
                    pp = @pos.add([0,-x].rot(@rot)).add([l,0].rot(ang+@rot))
                    text += " -- ("+pp[0]+","+(-pp[1])+")"
                text += " -- cycle;\n"
            when "ruby"
                t = new Triangle([
                    @pos.add([0,-Math.sqrt(2)*r(@a)].rot(@rot))
                    @pos.add([-(Math.sqrt(2)+1)*r(@a),r(@a)].rot(@rot))
                    @pos.add([(Math.sqrt(2)+1)*r(@a),r(@a)].rot(@rot))
                ])
                t.flip = @flip
                t.mina = @a
                t.rotateLargestAngleUp()
                text += t.tikzShape()
        return text

    pack: (instance) ->
        circs = instance.circles.slice().sort((a, b) -> a.a - b.a)
        circs[0].pos = @pos.add([r(@a)-r(circs[0].a),0])
        stopAng = -Math.asin(r(circs[0].a)/(r(@a)-r(circs[0].a)))

        if circs.length > 1
            ang = 0
            circleArea = 0
            for i in [1..(circs.length-1)]
                a = r(circs[i-1].a)
                b = r(circs[i].a)
                c = r(@a)
                ang += Math.acos(-((a+b)**2-(c-a)**2-(c-b)**2)/(2*(c-a)*(c-b)))

                if i == 1
                    prevRingArea = 0
                else
                    prevRingArea = Math.PI*(r(@a)**2-(r(@a)-r(circs[i-1].a)*2)**2)
                ringArea = Math.PI*(r(@a)**2-(r(@a)-r(circs[i].a)*2)**2)

                if isNaN(ang)
                    pos = @pos
                else
                    pos = @pos.add([c-b,0].rot(-ang))
                    endAng = ang + Math.asin(r(circs[i].a)/(r(@a)-r(circs[i].a)))
                    if i > 1 and (endAng > stopAng + 2*Math.PI or (circleArea/prevRingArea >= 1/2 and (circleArea+circs[i].a)/ringArea < 1/2))
                        circ = new Circle Math.PI*(c-2*a)**2
                        circ.pos = @pos
                        circ.pack(new Instance circs[i..-1])
                        break
                circs[i].pos = pos
                circleArea += circs[i].a
        return []

    cover: (instance) ->
        []

    packArea: -> 2*Math.PI*(r(@a)/2)**2

    coverArea: -> 9/4*@a # 3 equal circles

class Vertex
    constructor: (@pos) ->
        # nop

class Triangle
    constructor: (vertex_coordinates, mina=0) ->
        @vertices = ((new Vertex coordinate) for coordinate in vertex_coordinates)
        @shift = [0,0]
        @color = Color.rand()
        @mina = mina
        @flip = false

    draw: ->
        ctx.fillStyle = @color.string()
        ctx.lineWidth = 0.5
        ctx.beginPath()
        @drawShape()
        ctx.fill()

    drawHelper: ->
        ctx.strokeStyle = "black"
        ctx.lineWidth = 0.3
        ctx.beginPath()
        @drawShape()
        ctx.stroke()

    drawShape: ->
        if object != "circle"
            l = 2*(1+Math.sqrt(2))*(Math.sqrt(4*Math.sqrt(2)-4)-1)*Math.sqrt(2/((4*Math.sqrt(2)-4)*Math.PI))*Math.sqrt(@mina)
            x = Math.sqrt(2)*l/(1/Math.tan(@beta()/2)+1)

            if @flip == null or not @flip
                p1 = @B().add(@a().nor().mul(l))
                p2 = p1.add(@c().nor().rot(Math.PI/2).mul(x))
                p3 = @B().add(@c().nor().mul(-l))
            else
                p1 = p2 = p3 = @B()

            if @flip == null or @flip
                p4 = @A().add(@c().nor().mul(l))
                p6 = @A().add(@b().nor().mul(-l))
                p5 = p6.add(@c().nor().rot(Math.PI/2).mul(x))
            else
                p4 = p5 = p6 = @A()

            ctx.moveTo @C()[0], @C()[1]
            for vertex in [p1, p2, p3, p4, p5, p6]
                ctx.lineTo vertex[0], vertex[1]
            ctx.lineTo @C()[0], @C()[1]
        else
            da = r(@mina)/Math.tan(@alpha()/2)
            db = r(@mina)/Math.tan(@beta()/2)
            dc = r(@mina)/Math.tan(@gamma()/2)
            p1 = @A().add(@c().nor().mul(da))
            p2 = @B().add(@c().nor().mul(-db))
            p3 = @B().add(@a().nor().mul(db))
            p4 = @C().add(@a().nor().mul(-dc))
            p5 = @C().add(@b().nor().mul(dc))
            p6 = @A().add(@b().nor().mul(-da))
            ctx.moveTo(p1[0], p1[1])
            ctx.lineTo(p2[0], p2[1])
            ctx.arcTo(@B()[0], @B()[1], @C()[0], @C()[1], r(@mina))
            ctx.lineTo(p3[0], p3[1])
            ctx.lineTo(p4[0], p4[1])
            ctx.arcTo(@C()[0], @C()[1], @A()[0], @A()[1], r(@mina))
            ctx.lineTo(p5[0], p5[1])
            ctx.lineTo(p6[0], p6[1])
            ctx.arcTo(@A()[0], @A()[1], @B()[0], @B()[1], r(@mina))
            #ctx.closePath()
    tikzShape: ->
        text = ""

        if object != "circle"
            l = 2*(1+Math.sqrt(2))*(Math.sqrt(4*Math.sqrt(2)-4)-1)*Math.sqrt(2/((4*Math.sqrt(2)-4)*Math.PI))*Math.sqrt(@mina)
            x = Math.sqrt(2)*l/(1/Math.tan(@beta()/2)+1)

            if @flip == null or not @flip
                p1 = @B().add(@a().nor().mul(l))
                p2 = p1.add(@c().nor().rot(Math.PI/2).mul(x))
                p3 = @B().add(@c().nor().mul(-l))
            else
                p1 = p2 = p3 = @B()

            if @flip == null or @flip
                p4 = @A().add(@c().nor().mul(l))
                p6 = @A().add(@b().nor().mul(-l))
                p5 = p6.add(@c().nor().rot(Math.PI/2).mul(x))
            else
                p4 = p5 = p6 = @A()

            text += " ("+@C()[0]+","+(-@C()[1])+")"
            for vertex in [p1, p2, p3, p4, p5, p6]
                text += " -- ("+vertex[0]+","+(-vertex[1])+")"
            text += " -- cycle;\n"
        else
            da = r(@mina)/Math.tan(@alpha()/2)
            db = r(@mina)/Math.tan(@beta()/2)
            dc = r(@mina)/Math.tan(@gamma()/2)
            p1 = @A().add(@c().nor().mul(da))
            p2 = @B().add(@c().nor().mul(-db))
            p3 = @B().add(@a().nor().mul(db))
            p4 = @C().add(@a().nor().mul(-dc))
            p5 = @C().add(@b().nor().mul(dc))
            p6 = @A().add(@b().nor().mul(-da))

            text +=    " ("+p1[0]+","+(-p1[1])+")"
            text += " -- ("+p2[0]+","+(-p2[1])+")"
            text += " arc ("+Math.atan2(-@c().rot(Math.PI/2)[1],@c().rot(Math.PI/2)[0])*180/Math.PI+":"+(Math.atan2(-@c().rot(Math.PI/2)[1],@c().rot(Math.PI/2)[0])*180/Math.PI+180-@beta()*180/Math.PI)+":"+r(@mina)+")"
            text += " ("+p3[0]+","+(-p3[1])+")"
            text += " -- ("+p4[0]+","+(-p4[1])+")"
            text += " arc ("+Math.atan2(-@a().rot(Math.PI/2)[1],@a().rot(Math.PI/2)[0])*180/Math.PI+":"+(Math.atan2(-@a().rot(Math.PI/2)[1],@a().rot(Math.PI/2)[0])*180/Math.PI+180-@gamma()*180/Math.PI)+":"+r(@mina)+")"
            text += " -- ("+p5[0]+","+(-p5[1])+")"
            text += " -- ("+p6[0]+","+(-p6[1])+")"
            text += " arc ("+Math.atan2(-@b().rot(Math.PI/2)[1],@b().rot(Math.PI/2)[0])*180/Math.PI+":"+(Math.atan2(-@b().rot(Math.PI/2)[1],@b().rot(Math.PI/2)[0])*180/Math.PI+180-@alpha()*180/Math.PI)+":"+r(@mina)+")"
            text += ";\n"
        return text
    tikzHelper: ->
        "\\draw[helper]"+@tikzShape()
    tikz: ->
        "\\draw"+@tikzShape()

    A: -> @vertices[0].pos
    B: -> @vertices[1].pos
    C: -> @vertices[2].pos

    rotateLargestAngleUp: ->
        while @gamma() < Math.max(@alpha(), @beta())
            @vertices = @vertices.slice(1, @vertices.length).concat(@vertices.slice(0, 1))

    rotateSmallestAngleUp: ->
        while @gamma() > Math.min(@alpha(), @beta())
            @vertices = @vertices.slice(1, @vertices.length).concat(@vertices.slice(0, 1))

    a: -> @C().sub(@B())
    b: -> @A().sub(@C())
    c: -> @B().sub(@A())

    alpha: -> Math.acos((-@c()[0] * @b()[0] - (@c()[1] * @b()[1])) / (@b().len() * @c().len()))
    beta: -> Math.acos((-@a()[0] * @c()[0] - (@a()[1] * @c()[1])) / (@c().len() * @a().len()))
    gamma: -> Math.PI - @alpha() - @beta()

    symmetric: -> Math.abs(@alpha() - @beta()) < 0.01

    packsRubies: -> Math.abs(@a().len() - @b().len()) < 0.002*@a().len() and Math.abs(@a().len() - @c().len()/Math.sqrt(2)) < 0.002*@a().len()

    pack: (instance) ->
        @rotateLargestAngleUp()
        @draw()
        if instance.length() == 1
            instance.circles[0].pos = [
                (@a().len() * @A()[0] + @b().len() * @B()[0] + @c().len() * @C()[0]) / (@a().len() + @b().len() + @c().len())
                (@a().len() * @A()[1] + @b().len() * @B()[1] + @c().len() * @C()[1]) / (@a().len() + @b().len() + @c().len())
            ]
            instance.circles[0].rot = Math.atan2(@c().rot(0)[1],@c().rot(0)[0])
            instance.circles[0].flip = @flip
            return []
        else
            D = @A().add(@c().nor().mul(Math.cos(@alpha()) * @b().len()))
            #h = (new Quad [@A(), D, @B(), @C()]).pack instance, flip
            #return h

            a1 = (new Triangle([@A(), D, @C()])).packArea()
            a2 = (new Triangle([@B(), @C(), D])).packArea()
            buckets = instance.split([a1, a2])

            sum1 = buckets[0].sum()
            sum2 = buckets[1].sum()

            if @symmetric()
                # put larger bucket left
                if (sum1 < sum2 and not @flip) or (sum1 > sum2 and @flip)
                    [a1, a2] = [a2, a1]
                    [sum1, sum2] = [sum2, sum1]
                    [buckets[0], buckets[1]] = [buckets[1], buckets[0]]

            f1 = Math.sqrt(sum1/a1)
            f2 = Math.sqrt(sum2/a2)

            a = shape.a().len()
            b = shape.b().len()
            c = shape.c().len()

            if @flip
                [a,b] = [b,a]

            flip1 = sum1/sum2 >= 2*b/(c-b) and @symmetric()
            flip2 = sum2/sum1 >= 2*a/(c-a) and @symmetric()

            t1 = if flip1
                new Triangle([@A(), @A().add(@c().nor().mul(@C().sub(@A()).mul(f1).len())), @A().add(@b().nor().mul(-D.sub(@A()).mul(f1).len()))])
            else
                new Triangle([@A(), @A().add(D.sub(@A()).mul(f1)), @A().add(@C().sub(@A()).mul(f1))])

            t2 = if flip2
                new Triangle([@B(), @B().add(@a().nor().mul(D.sub(@B()).mul(f2).len())), @B().add(@c().nor().mul(-@C().sub(@B()).mul(f2).len()))])
            else
                new Triangle([@B(), @B().add(@C().sub(@B()).mul(f2)), @B().add(D.sub(@B()).mul(f2))])

            t1.mina = buckets[0].mina
            t2.mina = buckets[1].mina

            if flip1
                t1.flip = @flip
                tr1 = t1.pack(buckets[0])
            else
                t1.flip = (if @flip == null then null else not @flip)
                tr1 = t1.pack(buckets[0])

            if flip2
                t2.flip = @flip
                tr2 = t2.pack(buckets[1])
            else
                t2.flip = (if @flip == null then null else not @flip)
                tr2 = t2.pack(buckets[1])
            return [t1, t2].concat(tr1).concat(tr2)

    # shelf packing
    pack2: (instance) ->
        @rotateSmallestAngleUp()
        used = 0
        j = 0
        h = r(circs[0].a) * 2
        while j < circs.length
            rad = r(circs[j].a)
            if j == 0
                shift = rad / Math.tan(@alpha() / 2)
                used = shift + rad
            else
                shift = used + rad
                required = rad / Math.tan(@beta() / 2)
                if shift + required > @c().len()
                    l = h / Math.sin(@alpha())
                    l2 = h / Math.sin(@beta())
                    A2 = @A().add(@b().nor().mul(-l))
                    B2 = @B().add(@a().nor().mul(l2))
                    remaining = circs.slice(j)
                    (new Triangle [A2, B2, @C()]).pack(new Instance remaining)
                    return
                else
                    used = used + 2 * rad
            x = @A().add(@c().nor().mul(shift))
            pos = x.add(@c().nor().mul(rad).rot(-Math.PI / 2))
            circs[j].pos = pos
            j++
        return []

    # packing-inspired
    cover4: (instance) ->
        instance.normalize(instance.sum()/(1+2*Math.sqrt(2)+2))
        h = @pack(instance)
        instance.normalize(instance.sum()*(1+2*Math.sqrt(2)+2))
        return h

    # larger triangle closes up to smaller one, but diagonal is a bit tilted
    cover3: (instance) ->
        @rotateLargestAngleUp()
        @draw()
        if instance.length() == 1
            instance.circles[0].pos = @A().add(@B()).div(2)
            return []
        else if instance.length() > 1
            buckets = instance.split([1,1])

            sum1 = buckets[0].sum()
            sum2 = buckets[1].sum()

            # put larger bucket right
            if sum1 > sum2
                [sum1, sum2] = [sum2, sum1]
                [buckets[0], buckets[1]] = [buckets[1], buckets[0]]

            # diameters of both recursive triangles
            d1 = 2*Math.sqrt(sum1/Math.PI)
            d2 = 2*Math.sqrt(sum2/Math.PI)

            # diameter of parent triangle
            d3 = @A().sub(@B()).len()

            # length of lower side of right triangle
            b = (d3-d1/Math.sqrt(2))

            # height of right triangle
            h = Math.sqrt(d2**2-b**2)

            t1 = new Triangle([@A(), @A().add(@c().nor().mul(d1/Math.sqrt(2))), @A().add(@b().nor().mul(-d1))])
            tr1 = t1.cover(buckets[0])
            t2 = new Triangle([@B(), @A().add(@c().nor().mul(d1/Math.sqrt(2))).add((@c().nor().mul(h).rot(-Math.PI/2))), @A().add(@c().nor().mul(d1/Math.sqrt(2)))])
            tr2 = t2.cover(buckets[1])
            return [t1, t2].concat(tr1).concat(tr2)

    # like packing
    cover: (instance) ->
        @rotateLargestAngleUp()
        @draw()
        if instance.length() == 1
            instance.circles[0].pos = @A().add(@B()).div(2)
            return []
        else if instance.length() > 1
            buckets = instance.split([1,1])

            sum1 = buckets[0].sum()
            sum2 = buckets[1].sum()

            # put larger bucket right
            if sum1 > sum2
                [sum1, sum2] = [sum2, sum1]
                [buckets[0], buckets[1]] = [buckets[1], buckets[0]]

            # diameters of both recursive triangles
            d1 = 2*Math.sqrt(sum1/Math.PI)
            d2 = 2*Math.sqrt(sum2/Math.PI)

            # diameter of parent triangle
            d3 = @A().sub(@B()).len()

            # length of lower side of right triangle
            b = (d3-d1/Math.sqrt(2))

            t1 = new Triangle([@A(), @A().add(@c().nor().mul(d1/Math.sqrt(2))), @A().add(@b().nor().mul(-d1))])
            t2 = new Triangle([@B(), @B().add(@a().nor().mul(d2)), @B().add(@c().nor().mul(-d2/Math.sqrt(2)))])
            #t2 = new Triangle([@B(), @B().add(@a().nor().mul(b*Math.sqrt(2))), @A().add(@c().nor().mul(d1/Math.sqrt(2)))])
            #t2 = new Triangle([@B(), @B().add(@a().nor().mul(b*Math.sqrt(2))), @A().add(@c().nor().mul(d1/Math.sqrt(2)))])

            tr1 = t1.cover(buckets[0])
            tr2 = t2.cover(buckets[1])

            return [t1, t2].concat(tr1).concat(tr2)

    packArea: ->
        @rotateLargestAngleUp()
        s = (@a().len() + @b().len() + @c().len()) / 2
        area = Math.sqrt(s * (s - @a().len()) * (s - @b().len()) * (s - @c().len()))
        rad = area / s
        incirclearea = Math.PI * rad * rad
        r2 = @c().len() / (2 + 1 / Math.tan(@alpha() / 2) + 1 / Math.tan(@beta() / 2))
        twocirclearea = 2 * Math.PI * r2 * r2
        if incirclearea > twocirclearea
            return twocirclearea
        else
            return incirclearea

    coverArea: ->
        @rotateLargestAngleUp()
        Math.PI*(@c().len()/2)**2


class Rect
    constructor: (w, h) ->
        @vertices = [new Vertex [w/2,-h/2]]
        @color = Color.rand()
    w: -> @vertices[0].pos[0]*2
    h: -> @vertices[0].pos[1]*-2
    symmetric: -> false
    draw: ->
        ctx.fillStyle = @color.string()
        ctx.fillRect(-@w()/2, -@h()/2, @w(), @h())
    tikz: ->
        "\\draw ("+(-@w()/2)+","+(-@h()/2)+") rectangle ("+@w()/2+","+@h()/2+");\n"
    packArea: -> Math.min((new Triangle([[0,0], [@w(),0], [@w(),@h()]])).packArea()*2, Math.PI*(Math.min(@w(), @h())/2)**2)
    coverArea: -> (new Triangle([[0,0], [@w(),0], [@w(),@h()]])).coverArea()*2
    pack: (instance) ->
        if instance.length() == 1
            x = r(instance.circles[0].a)
            instance.circles[0].pos = [-@w()/2+x,-@h()/2+x]
            instance.circles[0].rot = -Math.PI/4
            instance.circles[0].flip = null
            return []
        else if instance.length() > 1
            a = (new Triangle([[0,0], [@w(),0], [@w(),@h()]])).packArea()
            buckets = instance.split([1, 1])

            sum1 = buckets[0].sum()
            sum2 = buckets[1].sum()

            # put larger bucket left
            if (sum1 < sum2)
                [sum1, sum2] = [sum2, sum1]
                [buckets[0], buckets[1]] = [buckets[1], buckets[0]]

            f1 = Math.sqrt(sum1/a)
            f2 = Math.sqrt(sum2/a)

            t1 =new Triangle([
                [-@w()/2,-@h()/2]
                [-@w()/2,-@h()/2+@h()*f1]
                [-@w()/2+@w()*f1,-@h()/2]
            ])

            t2 = new Triangle([
                [@w()/2,@h()/2]
                [@w()/2,@h()/2-@h()*f2]
                [@w()/2-@w()*f2,@h()/2]
            ])

            t1.mina = buckets[0].mina
            t2.mina = buckets[1].mina
            t1.flip = null
            t2.flip = null

            tr1 = t1.pack(buckets[0])
            tr2 = t2.pack(buckets[1])

            return [t1, t2].concat(tr1).concat(tr2)
    packsRubies: ->
        Math.abs(@w() - @h()) < 0.002*@w()
    alpha: -> Math.PI/2-@beta()
    beta: -> Math.atan2(@h(), @w())
    gamma: -> Math.PI/2
    a: -> [-@w(), 0]
    b: -> [0, -@h()]
    c: -> @vertices[0].pos.mul(2)
    cover: -> []#nop

draw = ->
    ctx.clearRect 0, 0, canvas.width, canvas.height

    ctx.save()
    for instance in instances
        instance.draw3()
        ctx.translate(0, instanceHeight*instanceScale)
    ctx.restore()

    ctx.save()
    ctx.translate(canvas.width/2, yShift)
    shape.draw()
    for vertex in shape.vertices
        ctx.strokeStyle = "black"
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.rect(vertex.pos[0]-3, vertex.pos[1]-3, 6, 6)
        ctx.stroke()
    for instance in instances when instance.visible
        instance.draw()
    if active and (active.instance? or not active.object.a?) and Mouse.didReallyMove
        for helper in helpers
            helper.drawHelper()
    ctx.restore()


drawLoop = ->
    requestAnimationFrame drawLoop
    if window.updateCanvas
        draw()
        window.updateCanvas = false

Array::add = (vector) ->
    [
        @[0] + vector[0]
        @[1] + vector[1]
    ]

Array::sub = (vector) ->
    [
        @[0] - (vector[0])
        @[1] - (vector[1])
    ]

Array::mul = (scalar) ->
    [
        @[0] * scalar
        @[1] * scalar
    ]

Array::div = (scalar) ->
    [
        @[0] / scalar
        @[1] / scalar
    ]

Array::len = -> Math.sqrt @[0] * @[0] + @[1] * @[1]

Array::nor = -> @mul 1 / @len()

Array::sum = -> @reduce ((a, b) -> a + b.a), 0

Array::rot = (theta) ->
    [
        @[0] * Math.cos(theta) - (@[1] * Math.sin(theta))
        @[0] * Math.sin(theta) + @[1] * Math.cos(theta)
    ]


canvas = document.getElementById("canvas")
ctx = canvas.getContext("2d")
active = null
shape = null
strategy = null
object = null
helpers = []

# DRAW LOOP
window.requestAnimationFrame = window.requestAnimationFrame ? window.webkitRequestAnimationFrame ? window.mozRequestAnimationFrame ? window.msRequestAnimationFrame
window.updateCanvas = true

# MOUSE
Mouse =
    pos: [
        canvas.width / 2
        canvas.height / 2
    ]
    down: false
    didMove: false
    didReallyMove: false
    wheel: 0

canvas.onmousemove = (event) =>
    Mouse.pos = [
        event.clientX
        event.clientY
    ]
    Mouse.didMove = true
    Mouse.didReallyMove = true

    if active != null
        if active.object? # dragging something in the lower half
            active.object.pos = Mouse.pos.sub([canvas.width/2,yShift])
            if not active.object.a? # dragging a corner
                rebuildAll()
            window.updateCanvas = true
        else if active.instance? # dragging in the upper half
            if active.i?
                instance = active.instance
                a1 = instance.sum(0, active.i)
                a2 = instance.sum(active.i+1, -1)

                b1 = (Mouse.pos[0])*instance.height()
                b2 = instance.sum()-(Mouse.pos[0])*instance.height()

                if b2 < 0 or b1 < 0
                    active = null
                    return

                for circle in instance.circles[0..active.i]
                    circle.a = circle.a*(b1/a1)
                for circle in instance.circles[active.i+1..-1]
                    circle.a = circle.a*(b2/a2)

                rebuild(instance)
                window.updateCanvas = true
            else
                instanceScale = (Mouse.pos[1]/instances.length)/instanceHeight
                rebuildAll()
                window.updateCanvas = true

canvas.onmousedown = (event) =>
    if event.which == 1 # left
        Mouse.down = true
        Mouse.didMove = false
        Mouse.didReallyMove = false

        if Mouse.pos[1] > instances.length*instanceHeight*instanceScale-10 and Mouse.pos[1] < instances.length*instanceHeight*instanceScale+10
            active = {instance: instances[instances.length-1]}

        if active == null
            for i in [0..instances.length-1]
                instance = instances[i]
                if Mouse.pos[1] > i*instanceHeight*instanceScale and Mouse.pos[1] <= (i+1)*instanceHeight*instanceScale
                    x = 0
                    j = 0
                    for circle in instance.circles
                        x += circle.a/instance.height()
                        if Math.abs(Mouse.pos[0] - x) < 10
                            active = {instance: instance, i: j}
                        j++
                    if active == null
                        x = 0
                        j = 0
                        for circle in instance.circles
                            nextX = x+circle.a/instance.sum()*instance.width()
                            if Mouse.pos[0] >= x and Mouse.pos[0] <= nextX
                                h = instance.height()
                                circle.a = (Mouse.pos[0]-x)*h
                                c = new Circle (nextX-(Mouse.pos[0]))*h
                                instance.circles.splice(j+1, 0, c)
                                active = {instance: instance, i: j}
                                Mouse.didMove = true
                                rebuild(instance)
                                window.updateCanvas = true
                                break
                            x = nextX
                            j++
        if active == null
            movable = shape.vertices
            for instance in instances when instance.visible
                movable = movable.concat instance.circles

            bestD = 999999999999999
            for obj in movable
                d = Mouse.pos.sub([canvas.width/2,yShift]).sub(obj.pos).len()
                if d <= Math.sqrt((obj.a ? 200)/Math.PI) and d <= bestD
                    bestD = d
                    active = {object: obj}
    if event.which == 2 # middle
        movable = []
        for instance in instances when instance.visible
            movable = movable.concat instance.circles

        bestD = 999999999999999
        o = null
        for obj in movable
            d = Mouse.pos.sub([canvas.width/2,yShift]).sub(obj.pos).len()
            if d <= Math.sqrt((obj.a ? 200)/Math.PI) and d <= bestD
                bestD = d
                o = obj
        if o != null
            o.rot += Math.PI/4

canvas.onmouseup = (event) =>
    if not Mouse.didMove and active != null and active.i?
        a1 = active.instance.circles[active.i].a
        a2 = active.instance.circles[active.i+1].a
        active.instance.circles[active.i].a = a1+a2
        active.instance.circles.splice(active.i+1, 1)
        rebuild(active.instance)
        window.updateCanvas = true
    Mouse.down = false
    active = null
    window.updateCanvas = true

window.onkeydown = (event) =>
    if event.keyCode == 38 # up
        scrollInstance -1
    if event.keyCode == 40 # down
        scrollInstance 1
    if event.keyCode == 49 # 1
        scrollContainer 1
    if event.keyCode == 50 # 2
        if shape.packsRubies()
            scrollObject 1
    if event.keyCode == 51 # 3
        scrollStrategy 1
    if event.keyCode == 52 # 4
        exportTikz(false)
    if event.keyCode == 53 # 5
        exportTikz(true)

download = (filename, text) ->
  element = document.createElement('a')
  element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(text))
  element.setAttribute('download', filename)
  element.style.display = 'none'
  document.body.appendChild(element)
  element.click()
  document.body.removeChild(element)

exportTikz = (helpers=true) ->
    text = shape.tikz()

    if helpers
        for helper in helpers
            text += helper.tikzHelper()
    i = 1
    for instance in instances
        if instance.visible
            text += instance.tikz()
            break
        i++
    download("split-packing-"+i+".tex", text)

canvas.onmousewheel = (event) =>
    Mouse.wheel += event.wheelDelta

    for instance in instances
        instance.visible = false

    instances[Math.round(-Mouse.wheel/500).mod(instances.length)].visible = true
    window.updateCanvas = true

scrollInstance = (delta) =>
    i = 0
    for instance in instances
        if instance.visible
            a = i
            instance.visible = false
        i++

    instances[(instances.length+a+delta)%instances.length].visible = true
    window.updateCanvas = true

scrollContainer = (delta) =>
    i = shapes.indexOf(shape)
    shape = shapes[(shapes.length+i+delta)%shapes.length]
    document.getElementById("container").innerHTML = shapeNames[(shapes.length+i+delta)%shapes.length]
    rebuildAll()
    window.updateCanvas = true

scrollStrategy = (delta) =>
    i = strategies.indexOf(strategy)
    strategy = strategies[(strategies.length+i+delta)%strategies.length]
    rebuildAll()
    window.updateCanvas = true
    document.getElementById("strategy").innerHTML = strategy

scrollObject = (delta) =>
    i = objects.indexOf(object)
    object = objects[(objects.length+i+delta)%objects.length]
    window.updateCanvas = true
    document.getElementById("object").innerHTML = object

window.onresize = (event) =>
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    window.updateCanvas = true

strategies = [
    "pack"
    "manual"
]
strategy = strategies[0]

objects = [
    "circle"
    "octagon"
    "square"
    "ruby"
]
object = objects[0]

instances = [
    Instance.rand()
    new Instance ((new Circle a) for a in [1])
    new Instance ((new Circle a) for a in [1,1])
    new Instance ((new Circle 2**-a) for a in [1..50])
    new Instance ((new Circle a**15) for a in [50..1])
    new Instance ((new Circle a) for a in [1..50])
]


instances[0].visible = true

shapes = [
    #new Circle 100000
    new Rect(400, 400)
    #new Rect(400, 400/1.5607)
    new Triangle [[-400, 200], [400, 200], [0, -200]]
    #new Triangle [[-231, 200], [231, 200], [0, -200]]
    #new Triangle [[-311, 200], [204, 200], [0, -52]]
]

shapeNames = [
    "rectangle"
    "triangle"
]

for shape in shapes
    shape.color = new Color 0, 0, 80, 1

width = canvas.width / instances.length
height = canvas.height / (1 + shapes.length)

rebuild = (instance) ->
    instance.clearMinA()
    instance.sort()
    if strategy == "pack"
        h = shape.pack(instance)
    else if strategy == "cover"
        h = shape.cover(instance)
    else # manual
        h = []
    if instance.visible
        helpers = h

rebuildAll = ->
    if not shape.packsRubies()
        while object != "circle"
            scrollObject(1)
    console.log(object)
    for instance in instances
        instance.normalize(targetArea())
        rebuild(instance)

targetArea = ->
    instanceScale *
        if strategy == "pack"
            shape.packArea()
        else if strategy == "cover"
            shape.coverArea()
        else # manual
            shape.packArea()

shape = shapes[0]

scrollContainer(0)
scrollObject(0)
scrollStrategy(0)

rebuildAll()
window.onresize()
drawLoop()
