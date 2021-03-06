require 'spec_helper'

describe Hoodoo::Presenters::Integer do

  before do
    @inst = Hoodoo::Presenters::Integer.new('one',:required => false)
  end

  describe '#validate' do
    it 'should return [] when valid integer' do
      expect(@inst.validate(12).errors).to eq([])
    end

    it 'should return correct error when data is not a integer' do
      errors = @inst.validate('adskncasc')

      err = [  {'code'=>"generic.invalid_integer", 'message'=>"Field `one` is an invalid integer", 'reference'=>"one"}]
      expect(errors.errors).to eq(err)
    end

    it 'should not return error when not required and absent' do
      expect(@inst.validate(nil).errors).to eq([])
    end

    it 'should return error when required and absent' do
      @inst.required = true
      expect(@inst.validate(nil).errors).to eq([
        {'code'=>"generic.required_field_missing", 'message'=>"Field `one` is required", 'reference'=>"one"}
      ])
    end

    it 'should return correct error with non integer types' do
      err = [  {'code'=>"generic.invalid_integer", 'message'=>"Field `one` is an invalid integer", 'reference'=>"one"}]

      expect(@inst.validate('asckn').errors).to eq(err)
      expect(@inst.validate(34534.234).errors).to eq(err)
      expect(@inst.validate(true).errors).to eq(err)
      expect(@inst.validate({}).errors).to eq(err)
      expect(@inst.validate([]).errors).to eq(err)
    end

    it 'should return correct error with path' do
      errors = @inst.validate('scdacs','ordinary')
      expect(errors.errors).to eq([
        {'code'=>"generic.invalid_integer", 'message'=>"Field `ordinary.one` is an invalid integer", 'reference'=>"ordinary.one"}
      ])
    end
  end

end
