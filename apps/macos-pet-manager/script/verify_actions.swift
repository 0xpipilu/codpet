import Foundation

@main
struct VerifyActions {
    static func main() async {
        let workspaceRoot = URL(fileURLWithPath: "/Users/chen/Documents/codex pet 0524")
        let repository = PetRepository()
        let codexController = CodexController()
        
        let originalActiveSlug = codexController.currentActiveSlug()
        print("当前 Codex pet: \(originalActiveSlug ?? "nil")")
        
        let catalog = repository.loadCatalog(from: workspaceRoot)
        let installedPets = repository.loadInstalledPets(
            repoRoot: workspaceRoot,
            catalog: catalog,
            activeSlug: originalActiveSlug
        )
        print("已安装 pet 数量: \(installedPets.count)")
        print("发现页 catalog 数量: \(catalog.count)")
        
        if let installCandidate = catalog.first(where: { entry in
            !installedPets.contains(where: { $0.normalizedSlug == entry.slug.lowercased() })
        }) {
            print("安装测试 pet: \(installCandidate.slug)")
            do {
                try repository.installFromRepository(slug: installCandidate.slug, repoRoot: workspaceRoot)
                let installedURL = repository.petsDir.appendingPathComponent(installCandidate.slug)
                let installedExists = FileManager.default.fileExists(atPath: installedURL.path)
                print("安装结果: \(installedExists ? "成功" : "失败")")
                
                try repository.uninstall(slug: installCandidate.slug)
                let removedExists = FileManager.default.fileExists(atPath: installedURL.path)
                print("删除结果: \(removedExists ? "失败" : "成功")")
            } catch {
                print("安装/删除测试失败: \(error.localizedDescription)")
            }
        } else {
            print("没有找到可用于安装/删除测试的未安装 pet，跳过。")
        }
        
        if let alternatePet = installedPets.first(where: { $0.normalizedSlug != originalActiveSlug }) {
            print("应用测试 pet: \(alternatePet.slug)")
            do {
                try codexController.writeSelectedPet(slug: alternatePet.slug)
                let afterWrite = codexController.currentActiveSlug()
                print("写配置后当前 pet: \(afterWrite ?? "nil")")
                
                let immediateResult = await codexController.apply(slug: alternatePet.slug, mode: .immediate)
                print("即时应用结果: \(immediateResult)")
            } catch {
                print("应用测试失败: \(error.localizedDescription)")
            }
        } else {
            print("没有找到可用于应用测试的备用已安装 pet，跳过。")
        }
        
        if let originalActiveSlug {
            do {
                try codexController.writeSelectedPet(slug: originalActiveSlug)
                print("已恢复原始 pet: \(originalActiveSlug)")
            } catch {
                print("恢复原始 pet 失败: \(error.localizedDescription)")
            }
        }
    }
}
