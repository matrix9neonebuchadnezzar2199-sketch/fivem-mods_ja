import type { Language, Mission, PlayerData } from '../types/trucking'
import { fetchNui } from '../utils/nui'

const companies = [
  '国立転送・保管株式会社（NTS）',
  '真実の穀物会社',
  'レッドウッド・タバコ会社',
  'You Tool 株式会社',
  'プレミアム・デラックス・モータースポーツ',
  'フルーツ・コンピューターズ',
  'ロン石油',
  'メリー・ウェザー・セキュリティ',
]

type Props = {
  missions: Mission[]
  playerData: PlayerData
  language: Language
  selectedCompany: number
  onCompanyChange: (company: number) => void
}

export function CompaniesView({ missions, playerData, language, selectedCompany, onCompanyChange }: Props) {
  const companyMissions = missions.filter((mission) => mission.companyIndex === selectedCompany)
  const trust = playerData.points?.[String(selectedCompany)] ?? 0

  return (
    <div className="companies-view">
      <aside className="company-sidebar">
        {companies.map((company, index) => (
          <button className={selectedCompany === index ? 'is-active' : ''} key={company} onClick={() => onCompanyChange(index)}>
            <img src={`./assets/images/logo_${index + 1}.png`} alt="" />
            <span>{company}</span>
          </button>
        ))}
      </aside>
      <section className="company-content">
        <div className="company-title">
          <div>
            <p>{language.company_trust ?? '企業の信頼'}</p>
            <h2>{companies[selectedCompany]}</h2>
          </div>
          <strong>{trust} {language.trust_point ?? 'Trust Point'}</strong>
        </div>
        <div className="company-missions">
          {companyMissions.map((mission) => {
            const unlocked = playerData.unlockedMissions?.[String(mission.id)] === true
            return (
              <article className={`company-mission ${unlocked ? '' : 'is-locked'}`} key={mission.id}>
                <img src={`./assets/images/${mission.image}`} alt="" />
                <div>
                  <span>{mission.routes.length} ルート / ${mission.payment.toLocaleString()}</span>
                  <h3>{mission.header}</h3>
                  <p>{mission.requirementsLabel.map((item) => item.label).join(' / ')}</p>
                </div>
                <button onClick={() => void fetchNui('UnlockMission', { mission })}>
                  {unlocked ? language.unlocked ?? 'Unlocked' : language.locked ?? 'Locked'}
                </button>
              </article>
            )
          })}
        </div>
      </section>
    </div>
  )
}
