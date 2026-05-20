import type { Language } from '../types/trucking'

type Props = {
  visible: boolean
  language?: Language
}

export function PhoneCall({ visible, language = {} }: Props) {
  if (!visible) return null

  return (
    <div className="phone-call">
      <div className="phone-call__shell">
        <span className="phone-call__speaker" />
        <div>
          <p>{language.unknown_caller ?? '非通知'}</p>
          <h2>{language.special_freight_call ?? '特別貨物の依頼'}</h2>
          <span>{language.phone_accept_decline ?? 'Y 受ける / N 断る'}</span>
        </div>
      </div>
    </div>
  )
}
