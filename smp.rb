require 'openssl'
require 'securerandom'

class SMP
	attr_reader :match

	def initialize(secret)
		@mod = 2410312426921032588552076022197566074856950548502459942654116941958108831682612228890093858261341614673227141477904012196503648957050582631942730706805009223062734745341073406696246014589361659774041027169249453200378729434170325843778659198143763193776859869524088940195577346119843545301547043747207749969763750084308926339295559968882457872412993810129130294592999947926365264059284647209730384947211681434464714438488520940127459844288859336526896320919633919
		@gen = 2.to_bn
		@match = false
		if secret.class == String
			@secret = (secret.each_byte.map { |b| b.to_s(16) }.join).to_i(16)
		elsif secret.class == Fixnum
			@secret = secret
		else
			raise "Secret must be string or int, not #{secret.class}"
		end
	end

	def step1
		@a2 = random_exponent
		@a3 = random_exponent
		g2a = @gen.mod_exp(@a2,@mod)
		g3a = @gen.mod_exp(@a3,@mod)
		return "#{g2a},#{g3a}"
	end

	def step2(params)
		params = params.split(",")
		g2a = params[0].to_i.to_bn
		g3a = params[1].to_i.to_bn
		b2 = random_exponent
		@b3 = random_exponent
		g2b = @gen.mod_exp(b2, @mod)
		g3b = @gen.mod_exp(@b3, @mod)
		g2 = g2a.mod_exp(b2, @mod)
		g3 = g3a.mod_exp(@b3, @mod)
		r = random_exponent
		@pb = g3.mod_exp(r, @mod)
		@qb = mulm(@gen.mod_exp(r, @mod), g2.mod_exp(@secret, @mod), @mod)
		return "#{g2b},#{g3b},#{@pb},#{@qb}"
	end

	def step3(params)
		params = params.split(",")
		g2b = params[0].to_i.to_bn
		g3b = params[1].to_i.to_bn
		@pb = params[2].to_i
		qb = params[3].to_i
		g2 = g2b.mod_exp(@a2, @mod)
		g3 = g3b.mod_exp(@a3, @mod)
		s = random_exponent
		@pa = g3.to_bn.mod_exp(s, @mod)
		qa = mulm(@gen.mod_exp(s, @mod), g2.to_bn.mod_exp(@secret, @mod), @mod)
		ra = mulm(qa, invm(qb), @mod).to_bn.mod_exp(@a3, @mod)	# ra = (qa/qb).to_bn.mod_exp(@x3, @mod)
		return "#{@pa},#{qa},#{ra}"
	end

	def step4(params)
		params = params.split(",")
		pa = params[0].to_i
		qa = params[1].to_i
		ra = params[2].to_i.to_bn
		rb = mulm(qa, invm(@qb), @mod).to_bn.mod_exp(@b3, @mod)	# rb = (qa/@qb).to_bn.mod_exp(@b3, @mod)
		rab = ra.mod_exp(@b3, @mod)
		@match = true if (rab == mulm(pa, invm(@pb), @mod)) # (rab == pa/pb)
		return "#{rb}"
	end

	def step5(rb)
		rb = rb.to_i.to_bn
		rab = rb.mod_exp(@a3, @mod)
		@match = true if (rab == mulm(@pa, invm(@pb), @mod)) # (rab == pa/pb)
	end

	private

	def random_exponent
		rand = ""
		463.times do |i|
			rand += SecureRandom.random_number(9).to_s
		end
		return rand.to_i
	end
	
	def mulm(x, y, mod)
		return x * y % mod
	end
	
	def subm(x, y, mod)
		return (x - y) % mod
	end
	
	def invm(x)
        return x.to_bn.mod_exp(@mod-2, @mod)
    end

end
