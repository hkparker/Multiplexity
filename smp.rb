require 'openssl'
require 'securerandom'

class SMP
	attr_reader :match

	def initialize(secret)
		@mod = 27873122967077383472629612948290218983052772013912715030762384915163730848179109162916200140950167974322121603877943061344949068748193737681903388326031959168304363657088299266617274804516574306608768408800100715569981872302461841007958897409801928720667995454009123583647705484196771471277543268306877585412977336934255271643526517084621971739051653268390388716434173334584654327809476072966555536152922349363152764165996889082246058783557309145489911470325599083222835770181574967652383490951242213410243247947104087750388834635327620922781223875106693831120369677828563650184177272786061239763438124394335896596333
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
		ra = mulm(qa, invm(qb), @mod).to_bn.mod_exp(@a3, @mod)
		return "#{@pa},#{qa},#{ra}"
	end

	def step4(params)
		params = params.split(",")
		pa = params[0].to_i
		qa = params[1].to_i
		ra = params[2].to_i.to_bn
		rb = mulm(qa, invm(@qb), @mod).to_bn.mod_exp(@b3, @mod)
		rab = ra.mod_exp(@b3, @mod)
		@match = true if (rab == mulm(pa, invm(@pb), @mod))
		return "#{rb}"
	end

	def step5(rb)
		rb = rb.to_i.to_bn
		rab = rb.mod_exp(@a3, @mod)
		@match = true if (rab == mulm(@pa, invm(@pb), @mod))
	end

	private

	def random_exponent
		return SecureRandom.hex(1024).to_i(16)
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
