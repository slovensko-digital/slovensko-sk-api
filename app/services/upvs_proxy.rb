class UpvsProxy < SimpleDelegator
  def initialize(properties)
    super digital.slovensko.upvs.UpvsProxy.new(properties)
  end

  # TODO methods may have misleading names consider this change:
  # sktalk (Štandard pre komunikáciu prostredníctvom ÚPVS) -> urp (Univerzálne integračné rozhranie s asynchrónne rozhranie na príjem správ do ÚPVS)
  # ez (Externá zbernica) -> usr (Univerzálne synchrónne rozhranie pre sprístupnenie ostatných synchrónnych služieb modulov ÚPVS – z pohľadu SP ide o rozhranie externej zbernice)
  # eks (?) -> ekr (Externé komunikačné rozhranie)
  # iam / sts -> seems ok
  # TODO search for file names / directories / paths etc.
end
